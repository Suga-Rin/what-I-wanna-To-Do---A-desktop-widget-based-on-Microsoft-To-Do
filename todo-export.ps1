# todo-export.ps1 -- fetch open To Do tasks from Graph, cache to tasks.json, then render the skin.
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$dir=$PSScriptRoot; if(-not $dir){$dir=Split-Path -Parent $MyInvocation.MyCommand.Definition}
$clientId='14d82eec-204b-4c2f-b7e8-296a70dab67e'
$tokFile=Join-Path $dir 'token.dat'
$scope='https://graph.microsoft.com/Tasks.ReadWrite offline_access'
function San($s){ if($null -eq $s){return ''}; ($s -replace '[\r\n\t]',' ') }

# --- access token ---
$sec=Get-Content $tokFile|ConvertTo-SecureString
$b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec); $rt=[Runtime.InteropServices.Marshal]::PtrToStringAuto($b); [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)
$tok=Invoke-RestMethod -Method Post -TimeoutSec 25 -Uri 'https://login.microsoftonline.com/common/oauth2/v2.0/token' -Body @{grant_type='refresh_token';client_id=$clientId;refresh_token=$rt;scope=$scope}
if($tok.refresh_token){$tok.refresh_token|ConvertTo-SecureString -AsPlainText -Force|ConvertFrom-SecureString|Out-File $tokFile -Encoding ascii}
$hdr=@{Authorization='Bearer '+$tok.access_token}

# --- fetch + tier-sort ---
$today=(Get-Date).Date
$lists=(Invoke-RestMethod -TimeoutSec 25 -Uri 'https://graph.microsoft.com/v1.0/me/todo/lists' -Headers $hdr).value
$out=New-Object System.Collections.ArrayList
foreach($lst in $lists){
  try{$tasks=(Invoke-RestMethod -TimeoutSec 25 -Uri "https://graph.microsoft.com/v1.0/me/todo/lists/$($lst.id)/tasks?`$top=100" -Headers $hdr).value}catch{$tasks=@()}
  foreach($t in @($tasks)){
    if($t.status -eq 'completed'){continue}
    $hasDue=[bool]($t.dueDateTime -and $t.dueDateTime.dateTime); $dd=$null
    if($hasDue){ try{ $naive=[datetime]::Parse($t.dueDateTime.dateTime,[Globalization.CultureInfo]::InvariantCulture); $tzid=$t.dueDateTime.timeZone; if(-not $tzid){$tzid='UTC'}; $src=[System.TimeZoneInfo]::FindSystemTimeZoneById($tzid); $dd=([System.TimeZoneInfo]::ConvertTimeToUtc([datetime]::SpecifyKind($naive,'Unspecified'),$src)).ToLocalTime() }catch{ $dd=[datetime]::Parse($t.dueDateTime.dateTime,[Globalization.CultureInfo]::InvariantCulture) } }
    $imp=($t.importance -eq 'high'); $isNear=$hasDue -and $dd.Date -le $today.AddDays(2)
    $tier=if($isNear){0}elseif($imp){1}elseif($hasDue){2}else{3}
    $sub=if($isNear){if($imp){0}else{1}}elseif($imp){if($hasDue){0}else{1}}else{0}
    $sd=if($hasDue){$dd}else{[datetime]::MaxValue}
    $due=''
    if($hasDue){ $fmt=if($dd.Year -ne $today.Year){'yyyy-MM-dd'}else{'MM-dd'}; $due=if($dd.Date -lt $today){$dd.ToString($fmt)+'(已逾期)'}elseif($dd.Date -eq $today){'今天'}elseif($dd.Date -eq $today.AddDays(1)){'明天'}else{$dd.ToString($fmt)} }
    [void]$out.Add([pscustomobject]@{Title=San $t.title;Due=$due;Star=$imp;Near=$isNear;ListId=$lst.id;TaskId=$t.id;Tier=$tier;Sub=$sub;SortDue=$sd})
  }
}
$sorted=@($out|Sort-Object Tier,Sub,SortDue,Title)
$near=@($sorted|Where-Object{$_.Near}).Count; $impc=@($sorted|Where-Object{$_.Star}).Count; $total=$sorted.Count

# --- cache to tasks.json (strip sort-only fields) ---
$slim=@($sorted|ForEach-Object{ [pscustomobject]@{Title=$_.Title;Due=$_.Due;Star=[bool]$_.Star;Near=[bool]$_.Near;ListId=$_.ListId;TaskId=$_.TaskId} })
$payload=[pscustomobject]@{near=$near;impc=$impc;total=$total;tasks=$slim}
[IO.File]::WriteAllText((Join-Path $dir 'tasks.json'), ($payload|ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))

# --- render the skin from the fresh cache ---
& (Join-Path $dir 'todo-render.ps1')
