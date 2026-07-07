# Microsoft To Do widget - device code auth (one-time). Pure PowerShell, no external modules.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dir=$PSScriptRoot; if(-not $dir){$dir=Split-Path -Parent $MyInvocation.MyCommand.Definition}
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

$clientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'   # Microsoft Graph Command Line Tools (public client)
$tenant   = 'common'
$scope    = 'https://graph.microsoft.com/Tasks.ReadWrite offline_access openid profile'

# 1) request a device code
$dc = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant/oauth2/v2.0/devicecode" -Body @{ client_id = $clientId; scope = $scope }

@{ verification_uri = $dc.verification_uri; user_code = $dc.user_code; expires_in = $dc.expires_in } | ConvertTo-Json | Out-File (Join-Path $dir 'auth-code.json') -Encoding utf8
Write-Output ('VERIFICATION_URI=' + $dc.verification_uri)
Write-Output ('USER_CODE=' + $dc.user_code)
Write-Output ('EXPIRES_IN=' + $dc.expires_in)
Write-Output '---waiting for sign-in---'

# 2) poll the token endpoint
$interval = [int]$dc.interval; if ($interval -lt 5) { $interval = 5 }
$deadline = (Get-Date).AddSeconds([int]$dc.expires_in)
$token = $null
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds $interval
  try {
    $token = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token" -Body @{
      grant_type  = 'urn:ietf:params:oauth:grant-type:device_code'
      client_id   = $clientId
      device_code = $dc.device_code
    }
    break
  } catch {
    $msg = $_.ErrorDetails.Message
    $e = $null; if ($msg) { $e = ($msg | ConvertFrom-Json -ErrorAction SilentlyContinue).error }
    if ($e -eq 'authorization_pending') { continue }
    elseif ($e -eq 'slow_down') { $interval += 5; continue }
    else { Write-Output ('AUTH_ERROR=' + $e); break }
  }
}

if ($token -and $token.refresh_token) {
  $token.refresh_token | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File (Join-Path $dir 'token.dat') -Encoding ascii
  Remove-Item (Join-Path $dir 'auth-code.json') -ErrorAction SilentlyContinue
  # quick sanity check: pull display name / list count
  try {
    $me = Invoke-RestMethod -Uri 'https://graph.microsoft.com/v1.0/me' -Headers @{ Authorization = 'Bearer ' + $token.access_token }
    Write-Output ('SIGNED_IN_AS=' + $me.userPrincipalName + ' (' + $me.displayName + ')')
  } catch {}
  # first-run convenience: create a Desktop launcher shortcut (with icon if present)
  try {
    $vbs = Join-Path $dir 'open-widget.vbs'
    if (Test-Path $vbs) {
      $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Microsoft To Do Widget.lnk'
      $wsh = New-Object -ComObject WScript.Shell
      $sc = $wsh.CreateShortcut($lnk)
      $sc.TargetPath = 'wscript.exe'
      $sc.Arguments = '"' + $vbs + '"'
      $sc.WorkingDirectory = $dir
      $ico = Join-Path $dir 'icon.ico'
      if (Test-Path $ico) { $sc.IconLocation = $ico + ',0' }
      $sc.Description = 'Microsoft To Do desktop widget'
      $sc.Save()
      Write-Output ('SHORTCUT_CREATED=' + $lnk)
    }
  } catch {}
  Write-Output 'AUTH_SUCCESS'
} else {
  Write-Output 'AUTH_FAILED'
}
