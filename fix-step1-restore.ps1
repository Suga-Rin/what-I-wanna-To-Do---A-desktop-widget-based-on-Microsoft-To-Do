# fix-step1-restore.ps1
# STEP 1 ONLY: restore the DEPLOYED widget (C:\Users\Administrator\ToDoWidget)
# to the stable "Enter-can-add" state by copying stable code files from the
# E:\_test git working copy (currently at stable commit cf91639).
# It ONLY overwrites code (.ps1/.vbs). It NEVER touches data/privacy files
# (token.dat, settings.txt, pending.txt, tasks.json, *.log, etc.).
# Then it re-renders ToDo.ini and refreshes the widget.

$ErrorActionPreference = 'Stop'
$src = 'E:\_test\microsoft-todo-desktop-widget'
$dst = 'C:\Users\Administrator\ToDoWidget'

$codeFiles = @(
  'todo-render.ps1','todo-action.ps1','todo-export.ps1','todo-cal.ps1','todo-auth.ps1',
  'run-action.vbs','run-auth.vbs','run-cal.vbs','run-export.vbs','open-widget.vbs'
)

Write-Output '--- copying stable code files (data files untouched) ---'
foreach ($f in $codeFiles) {
  $s = Join-Path $src $f
  $d = Join-Path $dst $f
  if (-not (Test-Path -LiteralPath $s)) { Write-Output ("MISSING SOURCE: " + $f); continue }
  Copy-Item -LiteralPath $s -Destination $d -Force
  Write-Output ("copied  " + $f)
}

Write-Output '--- verifying UTF-8 BOM on deployed .ps1 (expect 239,187,191) ---'
foreach ($f in @('todo-render.ps1','todo-action.ps1','todo-export.ps1','todo-cal.ps1','todo-auth.ps1')) {
  $bytes = [IO.File]::ReadAllBytes((Join-Path $dst $f))
  $head = ($bytes[0..2] -join ',')
  $ok = if ($head -eq '239,187,191') { 'OK-BOM' } else { 'NO-BOM!!' }
  Write-Output ("  {0,-18} {1}  [{2}]" -f $f, $head, $ok)
}

Write-Output '--- verifying deployed todo-render.ps1 add-flow is the STABLE single-Command1 form ---'
$renderText = Get-Content -LiteralPath (Join-Path $dst 'todo-render.ps1') -Encoding UTF8
$hasSaveadd = $renderText | Select-String -SimpleMatch 'saveadd' -Quiet
$cmdLine = ($renderText | Select-String -SimpleMatch 'MeasureInput' | Select-Object -First 1)
if ($hasSaveadd) {
  Write-Output '  RESULT: STILL BROKEN (saveadd present) -- copy did not take, STOP.'
} else {
  Write-Output '  RESULT: STABLE (no saveadd) -- good.'
}

Write-Output '--- re-rendering ToDo.ini from stable render script + refreshing widget ---'
& (Join-Path $dst 'todo-render.ps1')

Write-Output '--- DONE: step 1 restore complete ---'
