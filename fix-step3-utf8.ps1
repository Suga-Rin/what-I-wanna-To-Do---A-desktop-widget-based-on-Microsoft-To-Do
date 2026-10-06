# fix-step3-utf8.ps1
# STEP 3 ONLY: fix "Chinese (simplified & traditional) becomes ? when adding a task".
# Root cause: in todo-action.ps1, Invoke-RestMethod is given a STRING body, so
# PowerShell 5.1 encodes the request body as ISO-8859-1 -> every non-ASCII char
# becomes '?'. Fix = send the JSON as a UTF-8 BYTE ARRAY + declare charset=utf-8.
#
# This edits ONLY the network-send encoding. It does NOT touch the add-flow
# parameter passing (the Enter-can-add mechanism restored in step 1).
#
# Applies the SAME fix to BOTH the deployed copy AND the E:\_test git source,
# so a future re-deploy/render won't reintroduce the bug.

$ErrorActionPreference = 'Stop'

$targets = @(
  'C:\Users\Administrator\ToDoWidget\todo-action.ps1',
  'E:\_test\microsoft-todo-desktop-widget\todo-action.ps1'
)

# exact old -> new fragments (all three are the same UTF-8 encoding fix)
$edits = @(
  @{ old = "'Content-Type'='application/json'}";
     new = "'Content-Type'='application/json; charset=utf-8'}" },

  # complete: status patch
  @{ old = "-Headers `$hdr -Body (@{status='completed'}|ConvertTo-Json)|Out-Null";
     new = "-Headers `$hdr -Body ([System.Text.UTF8Encoding]::new(`$false).GetBytes((@{status='completed'}|ConvertTo-Json)))|Out-Null" },

  # add: new task post
  @{ old = "-Headers `$hdr -Body (`$body|ConvertTo-Json -Depth 5)|Out-Null";
     new = "-Headers `$hdr -Body ([System.Text.UTF8Encoding]::new(`$false).GetBytes((`$body|ConvertTo-Json -Depth 5)))|Out-Null" }
)

foreach ($path in $targets) {
  Write-Output ("===== " + $path + " =====")
  if (-not (Test-Path -LiteralPath $path)) { Write-Output "  MISSING - skipped"; continue }

  # read as UTF-8 (files have BOM); preserve content exactly
  $raw = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
  $orig = $raw
  $allApplied = $true

  foreach ($e in $edits) {
    if ($raw.Contains($e.new)) {
      Write-Output ("  already-applied: " + $e.new.Substring(0, [Math]::Min(40,$e.new.Length)) + "...")
      continue
    }
    if ($raw.Contains($e.old)) {
      $raw = $raw.Replace($e.old, $e.new)
      Write-Output ("  APPLIED: ..." + $e.old.Substring([Math]::Max(0,$e.old.Length-38)))
    } else {
      Write-Output ("  NOT FOUND (stop, investigate): " + $e.old.Substring(0,[Math]::Min(40,$e.old.Length)) + "...")
      $allApplied = $false
    }
  }

  if ($raw -ne $orig -and $allApplied) {
    # write back as UTF-8 WITH BOM (PS 5.1 requires BOM for CJK scripts)
    $enc = New-Object System.Text.UTF8Encoding($true)
    [IO.File]::WriteAllText($path, $raw, $enc)
    $chk = [IO.File]::ReadAllBytes($path)[0..2] -join ','
    Write-Output ("  WRITTEN. BOM=" + $chk + " (expect 239,187,191)")
  } elseif (-not $allApplied) {
    Write-Output "  NOT written (some fragment missing) - left untouched."
  } else {
    Write-Output "  no change needed."
  }
}

Write-Output "===== re-rendering + refreshing widget ====="
& 'C:\Users\Administrator\ToDoWidget\todo-render.ps1'
Write-Output "===== DONE (step 3). Now add a task with Chinese text to test. ====="
