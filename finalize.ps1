# finalize.ps1
# Two things, ASCII-only (no CJK -> no BOM pitfalls in THIS helper):
#  (A) remove the '+' (AddBtn) button; tasks added via Enter only
#      - edit git SOURCE, copy render to DEPLOYED, re-render, verify
#  (B) tidy .gitignore so the 3 one-off helper scripts + leftover draft
#      are excluded from the repo (user will commit the rest themselves)

$ErrorActionPreference = 'Stop'
$root      = 'E:\_test\microsoft-todo-desktop-widget'
$srcRender = Join-Path $root 'todo-render.ps1'
$dstRender = 'C:\Users\Administrator\ToDoWidget\todo-render.ps1'

# ============ (A) remove '+' button ============
if (-not (Test-Path -LiteralPath $srcRender)) { throw "source render missing: $srcRender" }
$raw  = [IO.File]::ReadAllText($srcRender, [Text.Encoding]::UTF8)
$orig = $raw

if ($raw.Contains('$ibW=$W-$inX-$padX-20;')) {
  $raw = $raw.Replace('$ibW=$W-$inX-$padX-20;', '$ibW=$W-$inX-$padX;')
  Write-Output 'A1) input width: reclaimed +20px  [APPLIED]'
} elseif ($raw.Contains('$ibW=$W-$inX-$padX;')) {
  Write-Output 'A1) input width: already reclaimed  [SKIP]'
} else {
  Write-Output 'A1) input width: pattern NOT FOUND  [WARN]'
}

if ($raw.Contains('# add bar (star/cal left, plus right)')) {
  $raw = $raw.Replace('# add bar (star/cal left, plus right)', '# add bar (star/cal left; add via Enter only)')
  Write-Output 'A2) comment: updated  [APPLIED]'
} else {
  Write-Output 'A2) comment: original not present  [SKIP]'
}

if ([regex]::IsMatch($raw, '(?m)^.*\[AddBtn\].*\r?\n')) {
  $raw = [regex]::Replace($raw, '(?m)^.*\[AddBtn\].*\r?\n', '')
  Write-Output 'A3) [AddBtn] line: removed  [APPLIED]'
} else {
  Write-Output 'A3) [AddBtn] line: not present  [SKIP]'
}

if ($raw -ne $orig) {
  [IO.File]::WriteAllText($srcRender, $raw, (New-Object System.Text.UTF8Encoding($true)))
  Write-Output ('A) source written. BOM=' + (([IO.File]::ReadAllBytes($srcRender))[0..2] -join ','))
} else {
  Write-Output 'A) source unchanged.'
}
if ([regex]::IsMatch(([IO.File]::ReadAllText($srcRender, [Text.Encoding]::UTF8)), '\[AddBtn\]')) {
  throw 'ABORT: [AddBtn] still present in source after edit.'
}

Copy-Item -LiteralPath $srcRender -Destination $dstRender -Force
Write-Output ('A) copied render -> deployed. BOM=' + (([IO.File]::ReadAllBytes($dstRender))[0..2] -join ','))

Write-Output '--- re-rendering + refreshing widget ---'
& $dstRender

$ini = 'C:\Users\Administrator\Documents\Rainmeter\Skins\ToDo\ToDo.ini'
if (Test-Path -LiteralPath $ini) {
  if ((Get-Content -LiteralPath $ini -Encoding Unicode -Raw) -match '\[AddBtn\]') {
    Write-Output 'A) CHECK ToDo.ini: STILL has [AddBtn]  [FAIL]'
  } else {
    Write-Output 'A) CHECK ToDo.ini: no [AddBtn]  [OK]'
  }
}

# ============ (B) tidy .gitignore ============
$gi = Join-Path $root '.gitignore'
$giRaw = [IO.File]::ReadAllText($gi, [Text.Encoding]::UTF8)
$block = @"

# one-off repair/maintenance scripts (not part of the product)
fix-step1-restore.ps1
fix-step3-utf8.ps1
remove-plus-button.ps1
finalize.ps1

# leftover draft from the (now-removed) saveadd experiment
add-draft.txt
"@
if ($giRaw -notmatch 'one-off repair/maintenance scripts') {
  # normalize to CRLF, append
  $giRaw = $giRaw.TrimEnd() + "`r`n" + ($block -replace "`r?`n","`r`n")
  [IO.File]::WriteAllText($gi, $giRaw, (New-Object System.Text.UTF8Encoding($false)))
  Write-Output 'B) .gitignore: helper-scripts block appended  [APPLIED]'
} else {
  Write-Output 'B) .gitignore: block already present  [SKIP]'
}

Write-Output '--- DONE. Test widget (type + Enter). Then check git status. ---'
