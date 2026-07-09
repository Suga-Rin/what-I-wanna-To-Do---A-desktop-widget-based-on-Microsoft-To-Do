# remove-plus-button.ps1
# Remove the '+' (AddBtn) from the widget; tasks are added with Enter only.
# Edits the git SOURCE (E:\_test) then copies render to the DEPLOYED copy and
# re-renders. ASCII-only string ops so this script needs no CJK / no BOM concerns.
#
# Three changes to todo-render.ps1:
#   1) reclaim the 20px the '+' reserved:  $ibW=$W-$inX-$padX-20  ->  $ibW=$W-$inX-$padX
#   2) update the section comment
#   3) delete the whole [AddBtn] meter line

$ErrorActionPreference = 'Stop'
$srcRender = 'E:\_test\microsoft-todo-desktop-widget\todo-render.ps1'
$dstRender = 'C:\Users\Administrator\ToDoWidget\todo-render.ps1'

if (-not (Test-Path -LiteralPath $srcRender)) { throw "source render missing: $srcRender" }

# read source exactly (UTF-8; BOM stripped on read)
$raw  = [IO.File]::ReadAllText($srcRender, [Text.Encoding]::UTF8)
$orig = $raw

# 1) width: give the input box back the +'s 20px
if ($raw.Contains('$ibW=$W-$inX-$padX-20;')) {
  $raw = $raw.Replace('$ibW=$W-$inX-$padX-20;', '$ibW=$W-$inX-$padX;')
  Write-Output '1) width: reclaimed 20px  [APPLIED]'
} elseif ($raw.Contains('$ibW=$W-$inX-$padX;')) {
  Write-Output '1) width: already reclaimed  [SKIP]'
} else {
  Write-Output '1) width: pattern NOT FOUND  [WARN]'
}

# 2) comment
if ($raw.Contains('# add bar (star/cal left, plus right)')) {
  $raw = $raw.Replace('# add bar (star/cal left, plus right)', '# add bar (star/cal left; task added via Enter only)')
  Write-Output '2) comment: updated  [APPLIED]'
} else {
  Write-Output '2) comment: original not present  [SKIP]'
}

# 3) delete the entire line that defines [AddBtn]  (regex, ASCII-only)
if ([regex]::IsMatch($raw, '(?m)^.*\[AddBtn\].*\r?\n')) {
  $raw = [regex]::Replace($raw, '(?m)^.*\[AddBtn\].*\r?\n', '')
  Write-Output '3) [AddBtn] line: removed  [APPLIED]'
} else {
  Write-Output '3) [AddBtn] line: not present  [SKIP]'
}

if ($raw -ne $orig) {
  # write back UTF-8 WITH BOM (required for PS 5.1 + CJK content in the file)
  [IO.File]::WriteAllText($srcRender, $raw, (New-Object System.Text.UTF8Encoding($true)))
  Write-Output ('source written. BOM=' + (([IO.File]::ReadAllBytes($srcRender))[0..2] -join ','))
} else {
  Write-Output 'source unchanged (nothing to do).'
}

# sanity: source must no longer contain [AddBtn]
if ([regex]::IsMatch(([IO.File]::ReadAllText($srcRender, [Text.Encoding]::UTF8)), '\[AddBtn\]')) {
  throw 'ABORT: [AddBtn] still present in source after edit.'
}

# copy patched render to the deployed widget, then re-render
Copy-Item -LiteralPath $srcRender -Destination $dstRender -Force
Write-Output ('copied render -> deployed. BOM=' + (([IO.File]::ReadAllBytes($dstRender))[0..2] -join ','))

Write-Output '--- re-rendering + refreshing widget ---'
& $dstRender

# verify the generated skin has no + button
$ini = 'C:\Users\Administrator\Documents\Rainmeter\Skins\ToDo\ToDo.ini'
if (Test-Path -LiteralPath $ini) {
  $iniText = Get-Content -LiteralPath $ini -Encoding Unicode -Raw
  if ($iniText -match '\[AddBtn\]') {
    Write-Output 'CHECK: ToDo.ini STILL has [AddBtn]  [FAIL]'
  } else {
    Write-Output 'CHECK: ToDo.ini has NO [AddBtn]  [OK]'
  }
}
Write-Output '--- DONE: + button removed. Test the widget: type text, press Enter. ---'
