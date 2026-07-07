param([int]$year=0,[int]$month=0)
# Generates a clickable month-calendar Rainmeter skin (ToDoCal) and shows/refreshes it.
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot; if(-not $dir){$dir=Split-Path -Parent $MyInvocation.MyCommand.Definition}
$rmExe='C:\Program Files\Rainmeter\Rainmeter.exe'
$rmIni=Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
$skinDir=Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins\ToDoCal'
if(-not(Test-Path $skinDir)){ New-Item -ItemType Directory -Path $skinDir -Force|Out-Null }
$latin='Lucida Sans Unicode'; $cjk='幼圆'; $font=$cjk; $mdl='Segoe MDL2 Assets'

$isOpen = ($year -le 0)                     # no explicit month => opened from widget; else nav
$today=(Get-Date).Date
if($year -le 0){$year=$today.Year}; if($month -le 0){$month=$today.Month}
$first=Get-Date -Year $year -Month $month -Day 1
$year=$first.Year; $month=$first.Month
$daysIn=[DateTime]::DaysInMonth($year,$month)
$startDow=[int]$first.DayOfWeek             # 0=Sunday
$pm=$first.AddMonths(-1); $nm=$first.AddMonths(1); $py=$first.AddYears(-1); $ny=$first.AddYears(1)

$padX=8; $cell=30
$W=$padX*2 + $cell*7
$midX=[int]($W/2)
$lblY=6; $navY=28; $dowY=52; $gridY=74
$rowsN=[Math]::Ceiling(($startDow+$daysIn)/7.0)
$H=$gridY + $rowsN*$cell + 8

function Nav($name,$x,$glyph,$ty,$ttip){
  $script:L.Add("[$name]"); $script:L.Add('Meter=String'); $script:L.Add("X=$x"); $script:L.Add("Y=$navY"); $script:L.Add('StringAlign=CenterTop'); $script:L.Add("FontFace=$latin"); $script:L.Add('FontSize=15'); $script:L.Add('FontColor=200,205,215,235'); $script:L.Add('AntiAlias=1'); $script:L.Add('Text='+$glyph); $script:L.Add('LeftMouseUpAction=["#Dir#\run-cal.vbs" "'+$ty.Year+'" "'+$ty.Month+'"]'); $script:L.Add('ToolTipText='+$ttip); $script:L.Add('')
}

$L=New-Object System.Collections.Generic.List[string]
$L.Add('[Rainmeter]'); $L.Add('Update=1000'); $L.Add('AccurateText=1'); $L.Add('DynamicWindowSize=1'); $L.Add('')
$L.Add('[Variables]'); $L.Add('Dir='+$dir); $L.Add('')
$L.Add('[MeterBg]'); $L.Add('Meter=Shape'); $L.Add("Shape=Rectangle 0,0,$W,$H,12 | Fill Color 24,24,30,246 | StrokeWidth 1 | Stroke Color 255,255,255,34"); $L.Add('')
# row 1: label + close
$L.Add('[MonLbl]'); $L.Add('Meter=String'); $L.Add("X=$midX"); $L.Add("Y=$lblY"); $L.Add('StringAlign=CenterTop'); $L.Add("FontFace=$font"); $L.Add('FontSize=12'); $L.Add('FontWeight=700'); $L.Add('FontColor=245,245,245,255'); $L.Add('AntiAlias=1'); $L.Add("Text=$year 年 $month 月"); $L.Add('')
$L.Add('[Close]'); $L.Add('Meter=String'); $L.Add("X=$($W-$padX)"); $L.Add("Y=$lblY"); $L.Add('StringAlign=RightTop'); $L.Add("FontFace=$mdl"); $L.Add('FontSize=10'); $L.Add('FontColor=230,120,110,220'); $L.Add('AntiAlias=1'); $L.Add('Text='+[char]0xE8BB); $L.Add('LeftMouseUpAction=[!DeactivateConfig "ToDoCal"]'); $L.Add('ToolTipText=关闭'); $L.Add('')
# row 2: « ‹  › »  (prev year / prev month / next month / next year)
Nav 'PrevY' ($midX-52) ([char]0x00AB) $py '上一年'
Nav 'PrevM' ($midX-26) ([char]0x2039) $pm '上一月'
Nav 'NextM' ($midX+26) ([char]0x203A) $nm '下一月'
Nav 'NextY' ($midX+52) ([char]0x00BB) $ny '下一年'
# weekday header
$dows=@('日','一','二','三','四','五','六')
for($c=0;$c -lt 7;$c++){
  $cx=$padX + $c*$cell + [int]($cell/2)
  $wc=if($c -eq 0 -or $c -eq 6){'235,150,140,220'}else{'190,190,200,210'}
  $L.Add("[Dow$c]"); $L.Add('Meter=String'); $L.Add("X=$cx"); $L.Add("Y=$dowY"); $L.Add('StringAlign=CenterTop'); $L.Add("FontFace=$font"); $L.Add('FontSize=10'); $L.Add("FontColor=$wc"); $L.Add('AntiAlias=1'); $L.Add('Text='+$dows[$c]); $L.Add('')
}
# day cells: clickable full-cell bg + number (both carry the action)
for($d=1;$d -le $daysIn;$d++){
  $idx=$startDow + ($d-1); $row=[int][Math]::Floor($idx/7); $col=$idx%7
  $lx=$padX + $col*$cell; $cx=$lx + [int]($cell/2); $cyTop=$gridY + $row*$cell
  $isToday=($year -eq $today.Year -and $month -eq $today.Month -and $d -eq $today.Day)
  $iso=('{0:D4}-{1:D2}-{2:D2}' -f $year,$month,$d)
  $act='LeftMouseUpAction=["#Dir#\run-action.vbs" "setdate" "'+$iso+'"][!DeactivateConfig "ToDoCal"]'
  if($isToday){ $fill='143,208,255,55 | StrokeWidth 1 | Stroke Color 143,208,255,190' } else { $fill='255,255,255,1 | StrokeWidth 0' }
  $L.Add("[C$d]"); $L.Add('Meter=Shape'); $L.Add("Shape=Rectangle $($lx+1),$($cyTop-1),$($cell-2),26,6 | Fill Color $fill"); $L.Add($act); $L.Add('ToolTipText='+$iso); $L.Add('')
  $dcol=if($col -eq 0 -or $col -eq 6){'235,175,165,235'}else{'232,232,236,255'}
  $L.Add("[Day$d]"); $L.Add('Meter=String'); $L.Add("X=$cx"); $L.Add("Y=$($cyTop+3)"); $L.Add('StringAlign=CenterTop'); $L.Add("FontFace=$latin"); $L.Add('FontSize=12'); $L.Add("FontColor=$dcol"); $L.Add('AntiAlias=1'); $L.Add("Text=$d"); $L.Add($act); $L.Add('')
}

[IO.File]::WriteAllText((Join-Path $skinDir 'ToDoCal.ini'), ($L -join "`r`n"), [System.Text.Encoding]::Unicode)

# show / refresh
$marker=Join-Path $skinDir '.registered'
if(-not(Test-Path $marker)){ & $rmExe '!RefreshApp' 2>$null; Start-Sleep -Milliseconds 500; '' | Out-File $marker -Encoding ascii }
if($isOpen){
  $wx=1500; $wy=80
  if(Test-Path $rmIni){ $ln=Get-Content $rmIni; $inTo=$false; foreach($l in $ln){ if($l -match '^\[ToDo\]'){$inTo=$true;continue}; if($l -match '^\['){$inTo=$false}; if($inTo -and $l -match '^WindowX=(\d+)'){$wx=[int]$Matches[1]}; if($inTo -and $l -match '^WindowY=(\d+)'){$wy=[int]$Matches[1]} } }
  & $rmExe '!ActivateConfig' 'ToDoCal' 'ToDoCal.ini' 2>$null
  Start-Sleep -Milliseconds 250
  & $rmExe '!Move' "$wx" "$($wy+150)" 'ToDoCal' 2>$null
  & $rmExe '!Refresh' 'ToDoCal' 2>$null
} else {
  & $rmExe '!Refresh' 'ToDoCal' 2>$null   # nav: reload the regenerated month
}
Write-Output ('cal '+$year+'-'+$month+' open='+$isOpen)
