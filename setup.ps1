# setup.ps1 -- one-time setup for the Microsoft To Do (Rainmeter) widget.
# Installs Rainmeter if missing, enables auto-start, signs you in, and activates the widget.
$ErrorActionPreference='Stop'
$dir=$PSScriptRoot; if(-not $dir){$dir=Split-Path -Parent $MyInvocation.MyCommand.Definition}
function Say($m,$c){ Write-Host $m -ForegroundColor $c }
Say '== Microsoft To Do (Rainmeter) - setup ==' Cyan

# 1) Rainmeter present? install silently if not.
$rmExe='C:\Program Files\Rainmeter\Rainmeter.exe'
if(-not (Test-Path $rmExe)){ $rmExe='C:\Program Files (x86)\Rainmeter\Rainmeter.exe' }
if(-not (Test-Path $rmExe)){
  Say 'Rainmeter not found - downloading & installing...' Yellow
  $rmExe='C:\Program Files\Rainmeter\Rainmeter.exe'
  $ver='4.5.22'; $url="https://github.com/rainmeter/rainmeter/releases/download/v$ver/Rainmeter-$ver.exe"
  $tmp=Join-Path $env:TEMP "Rainmeter-$ver.exe"
  try{
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    Start-Process -FilePath $tmp -ArgumentList '/S' -Wait
    Start-Sleep 3
  }catch{ Say ('  download/install failed: '+$_.Exception.Message) Red }
  if(-not (Test-Path $rmExe)){ Say 'Could not install Rainmeter automatically. Please install it from https://www.rainmeter.net then re-run setup.ps1.' Red; return }
  Say 'Rainmeter installed.' Green
} else { Say 'Rainmeter already installed.' Green }

# 2) start Rainmeter (initialises Rainmeter.ini on a fresh install) + enable auto-start at login
Start-Process $rmExe; Start-Sleep 3
try{
  New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'Rainmeter' -Value ('"'+$rmExe+'"') -PropertyType String -Force | Out-Null
  Say 'Auto-start enabled (Rainmeter launches at login; the widget loads with it).' Green
}catch{ Say '  (could not set auto-start; Rainmeter may already start with Windows)' Yellow }

# 3) default state files (only if missing)
foreach($p in @(@('settings.txt',"236`n300`n10`n0`n100"),@('tips.txt','1'),@('panel.txt','0'),@('scroll.txt','0'),@('pending.txt',"0`n`n"))){
  $f=Join-Path $dir $p[0]; if(-not(Test-Path $f)){ [IO.File]::WriteAllText($f, $p[1], (New-Object Text.UTF8Encoding($false))) }
}

# 4) sign in (device code) if there is no token yet
if(-not (Test-Path (Join-Path $dir 'token.dat'))){
  Say 'Sign in to Microsoft To Do - a URL + code will appear below:' Yellow
  & (Join-Path $dir 'todo-auth.ps1')
}
if(-not (Test-Path (Join-Path $dir 'token.dat'))){ Say 'Not signed in. Re-run setup.ps1 (or todo-auth.ps1) to finish.' Red; return }

# 5) build the skin from your tasks, then register + activate it in Rainmeter
Say 'Building the widget from your tasks...' Yellow
& (Join-Path $dir 'todo-export.ps1') | Out-Null
Start-Sleep 1
& $rmExe '!RefreshApp'; Start-Sleep 2
& $rmExe '!ActivateConfig' 'ToDo' 'ToDo.ini'

# 6) desktop shortcut to re-open the widget after you close it (X)
try{
  $lnk=Join-Path ([Environment]::GetFolderPath('Desktop')) 'To Do Widget.lnk'
  $w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut($lnk)
  $s.TargetPath='wscript.exe'; $s.Arguments='"'+(Join-Path $dir 'open-widget.vbs')+'"'; $s.WorkingDirectory=$dir
  $ico=Join-Path $dir 'icon.ico'; if(Test-Path $ico){ $s.IconLocation=$ico+',0' }
  $s.Description='Open the Microsoft To Do widget'; $s.Save()
}catch{}

Say '' White
Say 'Done! The To Do widget is on your desktop and will start with Windows.' Green
Say 'Double-click the "To Do" title to switch account. Footer: ? = tooltips, lock, and the >/v panel with Opacity/Font/Width/Height sliders.' Cyan
