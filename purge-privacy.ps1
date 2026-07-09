# purge-privacy.ps1
# Delete ONLY personal/privacy data files from the E:\_test git dev folder.
# Does NOT touch the deployed widget (C:\Users\Administrator\ToDoWidget) -> your
# login token there stays intact and the widget keeps working.
# Code (.ps1/.vbs), images, README/LICENSE/.gitignore are never touched.

$ErrorActionPreference = 'Stop'
$root = 'E:\_test\microsoft-todo-desktop-widget'

# exact privacy/personal-data files to remove (only these)
$privacy = @(
  'token.dat',      # login refresh token (DPAPI)
  'tasks.json',     # cached task contents
  'settings.txt',   # personal UI settings
  'pending.txt',    # add-state
  'tips.txt',       # UI state
  'panel.txt',      # UI state
  'scroll.txt'      # scroll position
)

# safety guard: never delete anything that isn't in the allow-list above
Write-Output '--- deleting privacy files from E:\_test only ---'
$deleted = 0
foreach ($name in $privacy) {
  $p = Join-Path $root $name
  if (Test-Path -LiteralPath $p) {
    Remove-Item -LiteralPath $p -Force
    Write-Output ("  deleted  " + $name)
    $deleted++
  } else {
    Write-Output ("  (absent) " + $name)
  }
}
Write-Output ("--- removed " + $deleted + " file(s) ---")

# show what privacy files (if any) remain, to prove the folder is clean
Write-Output '--- re-scan: any privacy files still present? ---'
$stillHere = @()
foreach ($name in $privacy) {
  if (Test-Path -LiteralPath (Join-Path $root $name)) { $stillHere += $name }
}
if ($stillHere.Count -eq 0) {
  Write-Output '  none. E:\_test is clean of the listed privacy files.  [OK]'
} else {
  Write-Output ('  STILL PRESENT: ' + ($stillHere -join ', ') + '  [WARN]')
}

# confirm the deployed token is untouched (so the widget still works)
$depTok = 'C:\Users\Administrator\ToDoWidget\token.dat'
Write-Output ('--- deployed token intact? ' + (Test-Path -LiteralPath $depTok) + ' (expect True) ---')
Write-Output '--- DONE ---'
