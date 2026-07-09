# todo-render.ps1 -- read cache + settings + pending -> generate ToDo.ini -> refresh. NO network.
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot; if(-not $dir){$dir=Split-Path -Parent $MyInvocation.MyCommand.Definition}
$skinDir=Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins\ToDo'
$rmExe='C:\Program Files\Rainmeter\Rainmeter.exe'
if(-not (Test-Path $skinDir)){ New-Item -ItemType Directory -Path $skinDir -Force | Out-Null }

# --- settings: alpha, width, vis rows, locked, fontsz% ---
$alpha=236; $width=300; $vis=10; $locked=0; $fontsz=100
$sf=Join-Path $dir 'settings.txt'
if(Test-Path $sf){ $sl=@(Get-Content $sf -Encoding UTF8); if($sl.Count -ge 1 -and $sl[0]){$alpha=[int]$sl[0]}; if($sl.Count -ge 2 -and $sl[1]){$width=[int]$sl[1]}; if($sl.Count -ge 3 -and $sl[2]){$vis=[int]$sl[2]}; if($sl.Count -ge 4 -and $sl[3]){$locked=[int]$sl[3]}; if($sl.Count -ge 5 -and $sl[4]){$fontsz=[int]$sl[4]} }
function RF($p,$def){ $v=$def; $f=Join-Path $dir $p; if(Test-Path $f){ $x=@(Get-Content $f -Encoding UTF8); if($x.Count -ge 1 -and $x[0] -ne $null -and $x[0] -ne ''){$v=[int]$x[0]} }; $v }
$tips=RF 'tips.txt' 1
$panel=RF 'panel.txt' 0
$off=RF 'scroll.txt' 0

# --- pending add-state ---
$pend=Join-Path $dir 'pending.txt'
$pImp=$false; $pLabel=''
if(Test-Path $pend){ $pl=@(Get-Content $pend -Encoding UTF8); if($pl.Count -ge 1){$pImp=($pl[0] -eq '1')}; if($pl.Count -ge 3){$pLabel=$pl[2]} }

# --- tasks from cache ---
$cache=Join-Path $dir 'tasks.json'
$sorted=@(); $near=0; $impc=0; $total=0
if(Test-Path $cache){ try{ $d=Get-Content $cache -Raw -Encoding UTF8|ConvertFrom-Json; $sorted=@($d.tasks); $near=[int]$d.near; $impc=[int]$d.impc; $total=[int]$d.total }catch{} }

# --- fonts (scaled) + geometry ---
$latin='Lucida Sans Unicode'; $cjk='幼圆'; $font=$cjk; $mdl='Segoe MDL2 Assets'; $sym='Segoe UI Symbol'
if($fontsz -lt 80){$fontsz=80}; if($fontsz -gt 140){$fontsz=140}
$fsc=$fontsz/100.0
function Zf($v){ $r=[int][Math]::Round($v*$fsc); if($r -lt 6){6}else{$r} }
$fsT=Zf 13; $fsTask=Zf 12; $fsDue=Zf 11; $fsInfo=Zf 10; $fsUpd=Zf 9; $fsPh=Zf 11; $fsEmpty=Zf 12; $fsBul=Zf 13; $fsLbl=Zf 9; $fsB=11
$W=$width; if($W -lt 240){$W=240}; if($W -gt 460){$W=460}
$padX=16; $headY=12; $listY=46
$rowH=(Zf 13)+17
$inX=$padX+48; $ibW=$W-$inX-$padX-20; if($ibW -lt 90){$ibW=90}
if($vis -lt 3){$vis=3}; if($vis -gt 20){$vis=20}
$visN=$vis   # fixed box height (empty space if fewer tasks; scroll if more)
$maxOff=[Math]::Max(0,$total-$visN)
if($off -gt $maxOff){$off=$maxOff}; if($off -lt 0){$off=0}
$overflow=($total -gt $visN)
$listH=$visN*$rowH
$addBarY=$listY+$listH+10
$footY=$addBarY+38
$togY=$footY+18
if($panel){ $s1=$togY+18; $s2=$s1+18; $s3=$s2+18; $s4=$s3+18; $H=$s4+22 } else { $H=$togY+20 }
$scrollU='MouseScrollUpAction=["#Dir#\run-action.vbs" "scroll" "up"]'
$scrollD='MouseScrollDownAction=["#Dir#\run-action.vbs" "scroll" "down"]'
$L=New-Object System.Collections.Generic.List[string]
$L.Add('[Rainmeter]'); $L.Add('Update=1000'); $L.Add('AccurateText=1'); $L.Add('DynamicWindowSize=1'); $L.Add('')
$L.Add('[Variables]'); $L.Add('Dir='+$dir); $L.Add('')
$L.Add('[MeasureAuto]'); $L.Add('Measure=Calc'); $L.Add('Formula=(MeasureAuto+1)'); $L.Add('IfCondition=(MeasureAuto>=180)'); $L.Add('IfTrueAction=["#Dir#\run-export.vbs"]'); $L.Add('')
$L.Add('[MeasureInput]'); $L.Add('Measure=Plugin'); $L.Add('Plugin=InputText'); $L.Add("X=$inX"); $L.Add("Y=$addBarY"); $L.Add("W=$ibW"); $L.Add('H=26'); $L.Add('SolidColor=40,40,50,255'); $L.Add('FontColor=245,245,245,255'); $L.Add("FontFace=$font"); $L.Add("FontSize=$fsTask"); $L.Add('DefaultValue='); $L.Add('Command1=["#Dir#\run-action.vbs" "add" "$UserInput$"]'); $L.Add('')
$L.Add('[MeterBg]'); $L.Add('Meter=Shape'); $L.Add("Shape=Rectangle 0,0,$W,$H,12 | Fill Color 27,27,34,$alpha | StrokeWidth 1 | Stroke Color 255,255,255,28"); $L.Add('')
# header
$L.Add('[Title]'); $L.Add('Meter=String'); $L.Add("X=$padX"); $L.Add("Y=$headY"); $L.Add("FontFace=$latin"); $L.Add("FontSize=$fsT"); $L.Add('FontWeight=700'); $L.Add('FontColor=255,255,255,255'); $L.Add('AntiAlias=1'); $L.Add('Text=To Do'); $L.Add('LeftMouseDoubleClickAction=["#Dir#\run-auth.vbs"]'); $L.Add('ToolTipText=双击切换/登录账号'); $L.Add('')
$tipColor=if($tips){'255,255,255,150'}else{'242,199,102,220'}
$L.Add('[BtnTips]'); $L.Add('Meter=String'); $L.Add("X=$($W-$padX-72)"); $L.Add("Y=$($headY+1)"); $L.Add('StringAlign=RightTop'); $L.Add("FontFace=$mdl"); $L.Add("FontSize=$fsB"); $L.Add("FontColor=$tipColor"); $L.Add('AntiAlias=1'); $L.Add('Text='+[char]0xE897); $L.Add('LeftMouseUpAction=["#Dir#\run-action.vbs" "tips"]'); $L.Add('ToolTipText=开关悬停说明'); $L.Add('')
$lockGlyph=if($locked){[char]0xE72E}else{[char]0xE785}; $lockColor=if($locked){'242,199,102,235'}else{'255,255,255,140'}
$L.Add('[BtnLock]'); $L.Add('Meter=String'); $L.Add("X=$($W-$padX-48)"); $L.Add("Y=$($headY+1)"); $L.Add('StringAlign=RightTop'); $L.Add("FontFace=$mdl"); $L.Add("FontSize=$fsB"); $L.Add("FontColor=$lockColor"); $L.Add('AntiAlias=1'); $L.Add('Text='+$lockGlyph); $L.Add('LeftMouseUpAction=["#Dir#\run-action.vbs" "lock"]'); $L.Add('ToolTipText=锁定位置/透明度/大小'); $L.Add('')
$L.Add('[BtnRefresh]'); $L.Add('Meter=String'); $L.Add("X=$($W-$padX-24)"); $L.Add("Y=$($headY+1)"); $L.Add('StringAlign=RightTop'); $L.Add("FontFace=$mdl"); $L.Add("FontSize=$fsB"); $L.Add('FontColor=255,255,255,150'); $L.Add('AntiAlias=1'); $L.Add('Text='+[char]0xE72C); $L.Add('LeftMouseUpAction=["#Dir#\run-export.vbs"]'); $L.Add('ToolTipText=刷新'); $L.Add('')
$L.Add('[BtnClose]'); $L.Add('Meter=String'); $L.Add("X=$($W-$padX)"); $L.Add("Y=$($headY+1)"); $L.Add('StringAlign=RightTop'); $L.Add("FontFace=$mdl"); $L.Add("FontSize=$fsB"); $L.Add('FontColor=255,255,255,150'); $L.Add('AntiAlias=1'); $L.Add('Text='+[char]0xE8BB); $L.Add('LeftMouseUpAction=[!DeactivateConfig]'); $L.Add('ToolTipText=关闭（用桌面快捷方式重开）'); $L.Add('')
# tasks (viewport)
$twid=$W-$padX-70; if($overflow){$twid-=8}
if($total -eq 0){
  $L.Add('[Empty]'); $L.Add('Meter=String'); $L.Add("X=$($W/2)"); $L.Add("Y=$listY"); $L.Add('StringAlign=CenterTop'); $L.Add("FontFace=$font"); $L.Add("FontSize=$fsEmpty"); $L.Add('FontColor=255,255,255,140'); $L.Add('AntiAlias=1'); $L.Add('Text=暂无待办事项'); $L.Add('')
} else {
  for($k=0;$k -lt $visN;$k++){
    $i=$off+$k; if($i -ge $total){break}
    $t=$sorted[$i]; $y=$listY + $k*$rowH
    $star=if($t.Star){[char]0x2605+' '}else{''}
    $tcolor=if($t.Star){'242,199,102,255'}else{'238,238,238,255'}
    $dcolor=if($t.Near){'240,112,90,255'}else{'242,180,92,220'}
    $tfont=if($t.Title -match '[一-鿿]' -and $t.Title -notmatch '[A-Za-z]'){$cjk}else{$latin}
    $dfont=if($t.Due -match '[一-鿿]' -and $t.Due -notmatch '[A-Za-z]'){$cjk}else{$latin}
    $L.Add("[B$k]"); $L.Add('Meter=String'); $L.Add("X=$padX"); $L.Add("Y=$y"); $L.Add("FontFace=$sym"); $L.Add("FontSize=$fsBul"); $L.Add('FontColor=255,255,255,160'); $L.Add('AntiAlias=1'); $L.Add('Text='+[char]0x25CB); $L.Add('LeftMouseUpAction=["#Dir#\run-action.vbs" "complete" "'+$t.ListId+'" "'+$t.TaskId+'"]'); $L.Add("MouseOverAction=[!SetOption B$k Text `"$([char]0x25CF)`"][!UpdateMeter B$k][!Redraw]"); $L.Add("MouseLeaveAction=[!SetOption B$k Text `"$([char]0x25CB)`"][!UpdateMeter B$k][!Redraw]"); if($overflow){$L.Add($scrollU); $L.Add($scrollD)}; $L.Add('ToolTipText=标记完成'); $L.Add('')
    $L.Add("[T$k]"); $L.Add('Meter=String'); $L.Add("X=$($padX+20)"); $L.Add("Y=$y"); $L.Add("W=$twid"); $L.Add('ClipString=1'); $L.Add("FontFace=$tfont"); $L.Add("FontSize=$fsTask"); $L.Add("FontColor=$tcolor"); $L.Add('AntiAlias=1'); $L.Add('Text='+$star+$t.Title); if($overflow){$L.Add($scrollU); $L.Add($scrollD)}; $L.Add('')
    if($t.Due -ne ''){ $L.Add("[D$k]"); $L.Add('Meter=String'); $L.Add("X=$($W-$padX)"); $L.Add("Y=$y"); $L.Add('StringAlign=RightTop'); $L.Add("FontFace=$dfont"); $L.Add("FontSize=$fsDue"); $L.Add("FontColor=$dcolor"); $L.Add('AntiAlias=1'); $L.Add('Text='+$t.Due); $L.Add('') }
  }
}
if($overflow){
  $thmH=[Math]::Max(16,[int]($listH*$visN/$total)); $thmY=$listY+[int](($listH-$thmH)*($off/[double]$maxOff))
  $L.Add('[SbTrack]'); $L.Add('Meter=Shape'); $L.Add("Shape=Rectangle $($W-7),$listY,3,$listH,1 | Fill Color 255,255,255,26 | StrokeWidth 0"); $L.Add($scrollU); $L.Add($scrollD); $L.Add('')
  $L.Add('[SbThumb]'); $L.Add('Meter=Shape'); $L.Add("Shape=Rectangle $($W-7),$thmY,3,$thmH,1 | Fill Color 205,205,212,150 | StrokeWidth 0"); $L.Add($scrollU); $L.Add($scrollD); $L.Add('')
}
# add bar (star/cal left, plus right)
$ph='添加任务…'; if($pLabel){ $ph=$ph+'   · '+$pLabel }
$starGlyph=if($pImp){[char]0xE735}else{[char]0xE734}; $starColor=if($pImp){'242,199,102,255'}else{'255,255,255,150'}
$calColor=if($pLabel){'143,208,255,255'}else{'255,255,255,150'}
$L.Add('[InputBox]'); $L.Add('Meter=Shape'); $L.Add("Shape=Rectangle $inX,$addBarY,$ibW,26,6 | Fill Color 40,40,50,255 | StrokeWidth 1 | Stroke Color 255,255,255,30"); $L.Add('LeftMouseUpAction=[!CommandMeasure "MeasureInput" "ExecuteBatch 1"]'); $L.Add('ToolTipText=点此输入任务名，回车添加'); $L.Add('')
$L.Add('[Placeholder]'); $L.Add('Meter=String'); $L.Add("X=$($inX+9)"); $L.Add("Y=$($addBarY+6)"); $L.Add("FontFace=$font"); $L.Add("FontSize=$fsPh"); $L.Add('FontColor=200,200,205,170'); $L.Add('AntiAlias=1'); $L.Add('Text='+$ph); $L.Add('LeftMouseUpAction=[!CommandMeasure "MeasureInput" "ExecuteBatch 1"]'); $L.Add('')
$L.Add('[StarBtn]'); $L.Add('Meter=String'); $L.Add("X=$($padX+8)"); $L.Add("Y=$($addBarY+4)"); $L.Add('StringAlign=CenterTop'); $L.Add("FontFace=$mdl"); $L.Add('FontSize=12'); $L.Add("FontColor=$starColor"); $L.Add('AntiAlias=1'); $L.Add('Text='+$starGlyph); $L.Add('LeftMouseUpAction=["#Dir#\run-action.vbs" "togglestar"]'); $L.Add('ToolTipText=重要（星标）'); $L.Add('')
$L.Add('[CalBtn]'); $L.Add('Meter=String'); $L.Add("X=$($padX+32)"); $L.Add("Y=$($addBarY+4)"); $L.Add('StringAlign=CenterTop'); $L.Add("FontFace=$mdl"); $L.Add('FontSize=12'); $L.Add("FontColor=$calColor"); $L.Add('AntiAlias=1'); $L.Add('Text='+[char]0xE787); $L.Add('LeftMouseUpAction=["#Dir#\run-cal.vbs"]'); $L.Add('RightMouseUpAction=["#Dir#\run-action.vbs" "setdate" ""]'); $L.Add('ToolTipText=点选日期（右键清除）'); $L.Add('')
$L.Add('[AddBtn]'); $L.Add('Meter=String'); $L.Add("X=$($W-$padX-8)"); $L.Add("Y=$($addBarY+4)"); $L.Add('StringAlign=CenterTop'); $L.Add("FontFace=$mdl"); $L.Add('FontSize=13'); $L.Add('FontColor=143,208,255,235'); $L.Add('AntiAlias=1'); $L.Add('Text='+[char]0xE710); $L.Add('LeftMouseUpAction=[!CommandMeasure "MeasureInput" "ExecuteBatch 1"]'); $L.Add('ToolTipText=添加任务'); $L.Add('')
# footer: counts + time
$info='注意 '+$near+'  重要 '+$impc+'  全部 '+$total
$L.Add('[Info]'); $L.Add('Meter=String'); $L.Add("X=$padX"); $L.Add("Y=$footY"); $L.Add("FontFace=$font"); $L.Add("FontSize=$fsInfo"); $L.Add('FontColor=255,255,255,150'); $L.Add('AntiAlias=1'); $L.Add('Text='+$info); $L.Add('')
$L.Add('[Upd]'); $L.Add('Meter=String'); $L.Add("X=$($W-$padX)"); $L.Add("Y=$footY"); $L.Add('StringAlign=RightTop'); $L.Add("FontFace=$latin"); $L.Add("FontSize=$fsUpd"); $L.Add('FontColor=255,255,255,90'); $L.Add('AntiAlias=1'); $L.Add('Text='+(Get-Date).ToString('HH:mm')); $L.Add('')
# collapse/expand toggle (bottom-left)
$togGlyph=if($panel){[char]0xE70D}else{[char]0xE76C}
$L.Add('[BtnPanel]'); $L.Add('Meter=String'); $L.Add("X=$padX"); $L.Add("Y=$togY"); $L.Add("FontFace=$mdl"); $L.Add('FontSize=10'); $L.Add('FontColor=200,205,215,190'); $L.Add('AntiAlias=1'); $L.Add('Text='+$togGlyph); $L.Add('LeftMouseUpAction=["#Dir#\run-action.vbs" "panel"]'); $L.Add('ToolTipText=展开/收起调节条'); $L.Add('')
# sliders (only when expanded)
if($panel){
  $Tx=$padX+34; $Tw=$W-$Tx-$padX; $thumbR=5
  function Slider($name,$labY,$lab,$frac,$verb){
    $tcy=$labY+8; $thx=[int]($Tx+$frac*$Tw)
    $script:L.Add("[Lb$name]"); $script:L.Add('Meter=String'); $script:L.Add("X=$padX"); $script:L.Add("Y=$($labY+2)"); $script:L.Add("FontFace=$cjk"); $script:L.Add("FontSize=$fsLbl"); $script:L.Add('FontColor=255,255,255,120'); $script:L.Add('AntiAlias=1'); $script:L.Add('Text='+$lab); $script:L.Add('')
    $script:L.Add("[Tk$name]"); $script:L.Add('Meter=Shape'); $script:L.Add("Shape=Rectangle $Tx,$($tcy-1),$Tw,3,1 | Fill Color 255,255,255,45 | StrokeWidth 0"); $script:L.Add('')
    $script:L.Add("[Fl$name]"); $script:L.Add('Meter=Shape'); $script:L.Add("Shape=Rectangle $Tx,$($tcy-1),$($thx-$Tx),3,1 | Fill Color 205,205,210,110 | StrokeWidth 0"); $script:L.Add('')
    $script:L.Add("[Th$name]"); $script:L.Add('Meter=Shape'); $script:L.Add("Shape=Ellipse $thx,$tcy,$thumbR | Fill Color 235,238,245,240 | StrokeWidth 1 | Stroke Color 90,90,100,200"); $script:L.Add('')
    $script:L.Add("[$name]"); $script:L.Add('Meter=Shape'); $script:L.Add("Shape=Rectangle $Tx,$labY,$Tw,16 | Fill Color 0,0,0,1 | StrokeWidth 0")
    if(-not $locked){
      $script:L.Add('LeftMouseDownAction=["#Dir#\run-action.vbs" "set'+$verb+'" "$MouseX$" "'+$Tx+'" "'+$Tw+'"]')
      $script:L.Add('MouseScrollUpAction=["#Dir#\run-action.vbs" "'+$verb+'" "up"]')
      $script:L.Add('MouseScrollDownAction=["#Dir#\run-action.vbs" "'+$verb+'" "down"]')
    }
    $script:L.Add('ToolTipText='+$(if($locked){'已锁定'}else{'点轨道设定 / 滚轮微调'})); $script:L.Add('')
  }
  $afrac=($alpha-40)/215.0; if($afrac -lt 0){$afrac=0}; if($afrac -gt 1){$afrac=1}
  $wfrac=($W-240)/220.0; if($wfrac -lt 0){$wfrac=0}; if($wfrac -gt 1){$wfrac=1}
  $hfrac=($vis-3)/17.0; if($hfrac -lt 0){$hfrac=0}; if($hfrac -gt 1){$hfrac=1}
  $ffrac=($fontsz-80)/60.0; if($ffrac -lt 0){$ffrac=0}; if($ffrac -gt 1){$ffrac=1}
  Slider 'SlOpa' $s1 '透明' $afrac 'opacity'
  Slider 'SlFnt' $s2 '字体' $ffrac 'font'
  Slider 'SlWid' $s3 '宽度' $wfrac 'width'
  Slider 'SlHgt' $s4 '高度' $hfrac 'height'
}

if(-not $tips){ $L=@($L | Where-Object {$_ -notmatch '^ToolTipText='}) }
[IO.File]::WriteAllText((Join-Path $skinDir 'ToDo.ini'), ($L -join "`r`n"), [System.Text.Encoding]::Unicode)
if(Test-Path $rmExe){ & $rmExe '!Refresh' 'ToDo' 2>$null }
Write-Output ('rendered total='+$total+' vis='+$visN+' off='+$off+' panel='+$panel+' font='+$fontsz+' (w='+$W+' a='+$alpha+' lk='+$locked+')')
