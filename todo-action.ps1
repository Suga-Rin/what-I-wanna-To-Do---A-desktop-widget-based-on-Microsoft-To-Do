param([string]$act,[string]$a1,[string]$a2,[string]$a3)
# complete: a1=listId a2=taskId | add: a1=title | togglestar | setdate: a1=dateText | opacity: a1=up/down
$ErrorActionPreference='SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$dir=$PSScriptRoot; if(-not $dir){$dir=Split-Path -Parent $MyInvocation.MyCommand.Definition}
$clientId='14d82eec-204b-4c2f-b7e8-296a70dab67e'
$tokFile=Join-Path $dir 'token.dat'
$scope='https://graph.microsoft.com/Tasks.ReadWrite offline_access'
$pend=Join-Path $dir 'pending.txt'
$sf=Join-Path $dir 'settings.txt'
$rmExe='C:\Program Files\Rainmeter\Rainmeter.exe'
function LoadPend { if(Test-Path $pend){ $l=@(Get-Content $pend -Encoding UTF8); @{Imp=($l.Count -ge 1 -and $l[0] -eq '1'); Due=$(if($l.Count -ge 2){$l[1]}else{''}); Label=$(if($l.Count -ge 3){$l[2]}else{''})} } else { @{Imp=$false;Due='';Label=''} } }
function SavePend($imp,$due,$label){ (@(([int][bool]$imp),$due,$label) -join "`n") | Out-File $pend -Encoding UTF8 }
function LoadSet { $a=236;$w=300;$v=10;$k=0;$fo=100; if(Test-Path $sf){ $l=@(Get-Content $sf -Encoding UTF8); if($l.Count -ge 1 -and $l[0]){$a=[int]$l[0]}; if($l.Count -ge 2 -and $l[1]){$w=[int]$l[1]}; if($l.Count -ge 3 -and $l[2]){$v=[int]$l[2]}; if($l.Count -ge 4 -and $l[3]){$k=[int]$l[3]}; if($l.Count -ge 5 -and $l[4]){$fo=[int]$l[4]} }; @{Alpha=$a;Width=$w;Vis=$v;Locked=$k;Font=$fo} }
function SaveSet($h){ (@($h.Alpha,$h.Width,$h.Vis,$h.Locked,$h.Font) -join "`n") | Out-File $sf -Encoding UTF8 }
function SetDraggable($locked){
  $rmIni=Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
  if(-not(Test-Path $rmIni)){return}
  $val=if($locked){'0'}else{'1'}
  $lines=Get-Content $rmIni
  $out=New-Object System.Collections.Generic.List[string]
  $inTo=$false; $set=$false
  foreach($l in $lines){
    if($l -match '^\['){ if($inTo -and -not $set){ $out.Add("Draggable=$val"); $set=$true }; $inTo=($l -match '^\[ToDo\]') }
    if($inTo -and $l -match '^Draggable='){ $out.Add("Draggable=$val"); $set=$true; continue }
    $out.Add($l)
  }
  if($inTo -and -not $set){ $out.Add("Draggable=$val") }
  [IO.File]::WriteAllText($rmIni, ($out -join "`r`n"), [System.Text.Encoding]::Unicode)
}

$needFetch=$false; $needApp=$false
# optimistic complete: remove task from cache + render instantly, then confirm to Graph below
if($act -eq 'complete' -and $a2){
  try{
    $cf=Join-Path $dir 'tasks.json'
    if(Test-Path $cf){
      $d=Get-Content $cf -Raw -Encoding UTF8|ConvertFrom-Json
      $keep=@($d.tasks|Where-Object{$_.TaskId -ne $a2})
      $nn=@($keep|Where-Object{$_.Near}).Count; $ii=@($keep|Where-Object{$_.Star}).Count
      [IO.File]::WriteAllText($cf, ([pscustomobject]@{near=$nn;impc=$ii;total=$keep.Count;tasks=$keep}|ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
      & (Join-Path $dir 'todo-render.ps1') | Out-Null
    }
  }catch{}
}
if($act -eq 'togglestar'){ $p=LoadPend; SavePend (-not $p.Imp) $p.Due $p.Label }
elseif($act -eq 'setdate'){ $p=LoadPend; $due='';$label=''; if($a1){ try{ $d=[datetime]$a1; $due=$d.ToString('yyyy-MM-dd'); $label=if($d.Date -eq (Get-Date).Date){'今天'}elseif($d.Date -eq (Get-Date).Date.AddDays(1)){'明天'}else{$d.ToString('MM-dd')} }catch{} }; SavePend $p.Imp $due $label }
elseif($act -eq 'opacity'){ $s=LoadSet; $a=$s.Alpha + $(if($a1 -eq 'up'){22}else{-22}); if($a -gt 255){$a=255}; if($a -lt 40){$a=40}; $s.Alpha=$a; SaveSet $s }
elseif($act -eq 'setopacity'){ $s=LoadSet; $mx=[double]$a1; $tx=[double]$a2; $tw=[double]$a3; $frac=if($tw -gt 0){($mx-$tx)/$tw}else{0}; if($frac -lt 0){$frac=0}; if($frac -gt 1){$frac=1}; $s.Alpha=[int](40+$frac*215); SaveSet $s }
elseif($act -eq 'font'){ $s=LoadSet; $v=$s.Font + $(if($a1 -eq 'up'){6}else{-6}); if($v -gt 140){$v=140}; if($v -lt 80){$v=80}; $s.Font=$v; SaveSet $s }
elseif($act -eq 'setfont'){ $s=LoadSet; $mx=[double]$a1; $tx=[double]$a2; $tw=[double]$a3; $frac=if($tw -gt 0){($mx-$tx)/$tw}else{0}; if($frac -lt 0){$frac=0}; if($frac -gt 1){$frac=1}; $s.Font=[int](80+$frac*60); SaveSet $s }
elseif($act -eq 'width'){ $s=LoadSet; $v=$s.Width + $(if($a1 -eq 'up'){12}else{-12}); if($v -gt 460){$v=460}; if($v -lt 240){$v=240}; $s.Width=$v; SaveSet $s }
elseif($act -eq 'setwidth'){ $s=LoadSet; $mx=[double]$a1; $tx=[double]$a2; $tw=[double]$a3; $frac=if($tw -gt 0){($mx-$tx)/$tw}else{0}; if($frac -lt 0){$frac=0}; if($frac -gt 1){$frac=1}; $s.Width=[int](240+$frac*220); SaveSet $s }
elseif($act -eq 'height'){ $s=LoadSet; $v=$s.Vis + $(if($a1 -eq 'up'){1}else{-1}); if($v -gt 20){$v=20}; if($v -lt 3){$v=3}; $s.Vis=$v; SaveSet $s }
elseif($act -eq 'setheight'){ $s=LoadSet; $mx=[double]$a1; $tx=[double]$a2; $tw=[double]$a3; $frac=if($tw -gt 0){($mx-$tx)/$tw}else{0}; if($frac -lt 0){$frac=0}; if($frac -gt 1){$frac=1}; $s.Vis=[int](3+$frac*17); SaveSet $s }
elseif($act -eq 'scroll'){ $ofp=Join-Path $dir 'scroll.txt'; $cur=0; if(Test-Path $ofp){ $x=@(Get-Content $ofp -Encoding UTF8); if($x.Count -ge 1 -and $x[0]){$cur=[int]$x[0]} }; $cur=$cur + $(if($a1 -eq 'up'){-1}else{1}); $s=LoadSet; $tot=0; $cf=Join-Path $dir 'tasks.json'; if(Test-Path $cf){try{$tot=[int]((Get-Content $cf -Raw -Encoding UTF8|ConvertFrom-Json).total)}catch{}}; $mo=[Math]::Max(0,$tot-$s.Vis); if($cur -lt 0){$cur=0}; if($cur -gt $mo){$cur=$mo}; $cur|Out-File $ofp -Encoding UTF8 }
elseif($act -eq 'lock'){ $s=LoadSet; $nl=1-$s.Locked; $s.Locked=$nl; SaveSet $s; SetDraggable $nl; $needApp=$true }
elseif($act -eq 'tips'){ $tf=Join-Path $dir 'tips.txt'; $cur=1; if(Test-Path $tf){ $x=@(Get-Content $tf -Encoding UTF8); if($x.Count -ge 1 -and $x[0] -ne $null -and $x[0] -ne ''){$cur=[int]$x[0]} }; ($(1-$cur))|Out-File $tf -Encoding UTF8 }
elseif($act -eq 'panel'){ $pf=Join-Path $dir 'panel.txt'; $cur=0; if(Test-Path $pf){ $x=@(Get-Content $pf -Encoding UTF8); if($x.Count -ge 1 -and $x[0] -ne $null -and $x[0] -ne ''){$cur=[int]$x[0]} }; ($(1-$cur))|Out-File $pf -Encoding UTF8 }
else {
  try{
    $sec=Get-Content $tokFile|ConvertTo-SecureString
    $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec);$rt=[Runtime.InteropServices.Marshal]::PtrToStringAuto($b);[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)
    $tok=Invoke-RestMethod -Method Post -TimeoutSec 25 -Uri 'https://login.microsoftonline.com/common/oauth2/v2.0/token' -Body @{grant_type='refresh_token';client_id=$clientId;refresh_token=$rt;scope=$scope}
    if($tok.refresh_token){$tok.refresh_token|ConvertTo-SecureString -AsPlainText -Force|ConvertFrom-SecureString|Out-File $tokFile -Encoding ascii}
    $hdr=@{Authorization='Bearer '+$tok.access_token;'Content-Type'='application/json'}
    if($act -eq 'complete' -and $a1 -and $a2){
      Invoke-RestMethod -Method Patch -TimeoutSec 25 -Uri "https://graph.microsoft.com/v1.0/me/todo/lists/$a1/tasks/$a2" -Headers $hdr -Body (@{status='completed'}|ConvertTo-Json)|Out-Null
      $needFetch=$true
    }
    elseif($act -eq 'add' -and $a1){
      $p=LoadPend; $text=$a1.Trim()
      if($text){
        $lists=(Invoke-RestMethod -TimeoutSec 25 -Uri 'https://graph.microsoft.com/v1.0/me/todo/lists' -Headers $hdr).value
        $def=($lists|Where-Object{$_.wellknownListName -eq 'defaultList'}|Select-Object -First 1); if(-not $def){$def=$lists|Select-Object -First 1}
        $body=@{title=$text; importance=$(if($p.Imp){'high'}else{'normal'})}
        if($p.Due){ $body.dueDateTime=@{dateTime=([datetime]$p.Due).ToString('yyyy-MM-ddT00:00:00.0000000'); timeZone=(Get-TimeZone).Id} }
        Invoke-RestMethod -Method Post -TimeoutSec 25 -Uri "https://graph.microsoft.com/v1.0/me/todo/lists/$($def.id)/tasks" -Headers $hdr -Body ($body|ConvertTo-Json -Depth 5)|Out-Null
        SavePend $false '' ''
      }
      $needFetch=$true
    }
  }catch{}
}
if($needFetch){ & (Join-Path $dir 'todo-export.ps1') | Out-Null } else { & (Join-Path $dir 'todo-render.ps1') | Out-Null }
if($needApp){ Start-Sleep -Milliseconds 150; & $rmExe '!RefreshApp' 2>$null }
