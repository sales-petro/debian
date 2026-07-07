# Instala 2 serviços ngrok no Windows (NSSM).
# Requer: ngrok no PATH e NSSM (https://nssm.cc/)
#
# Uso (PowerShell como Admin):
#   $env:NGROK_BACKEND_TOKEN = '...'
#   $env:NGROK_FRONTEND_TOKEN = '...'
#   .\install-ngrok-windows.ps1

$ErrorActionPreference = 'Stop'

$backendToken  = $env:NGROK_BACKEND_TOKEN
$frontendToken = $env:NGROK_FRONTEND_TOKEN

if (-not $backendToken -or -not $frontendToken) {
    throw @'
Defina os tokens antes de executar:
  $env:NGROK_BACKEND_TOKEN = "..."
  $env:NGROK_FRONTEND_TOKEN = "..."
'@
}

$services = @{
    'hubsaas-backend' = @{
        Authtoken = $backendToken
        Port      = 3021
        WebAddr   = '127.0.0.1:4040'
    }
    'sales-petro-frontend' = @{
        Authtoken = $frontendToken
        Port      = 3020
        WebAddr   = '127.0.0.1:4041'
    }
}

$ngrok = (Get-Command ngrok -ErrorAction Stop).Source
$nssm  = (Get-Command nssm -ErrorAction SilentlyContinue).Source

if (-not $nssm) {
    throw 'NSSM não encontrado no PATH. Instale: https://nssm.cc/download'
}

$configRoot = Join-Path $env:USERPROFILE '.config\ngrok'
New-Item -ItemType Directory -Force -Path $configRoot | Out-Null

function Install-NgrokService {
    param(
        [string]$Name,
        [string]$Authtoken,
        [int]$Port,
        [string]$WebAddr
    )

    $configFile = Join-Path $configRoot "$Name.yml"
    @"
version: "3"
agent:
  authtoken: $Authtoken
  web_addr: $WebAddr
"@ | Set-Content -Path $configFile -Encoding UTF8

    $args = "http $Port --config `"$configFile`" --log stdout"

    & $nssm stop $Name 2>$null
    & $nssm remove $Name confirm 2>$null

    & $nssm install $Name $ngrok $args
    & $nssm set $Name AppDirectory (Split-Path $ngrok -Parent)
    & $nssm set $Name DisplayName "ngrok $Name (porta $Port)"
    & $nssm set $Name Description "Túnel ngrok HubSaaS porta $Port"
    & $nssm set $Name Start SERVICE_AUTO_START
    & $nssm set $Name AppStdout (Join-Path $env:TEMP "ngrok-$Name.log")
    & $nssm set $Name AppStderr (Join-Path $env:TEMP "ngrok-$Name.err.log")
    & $nssm set $Name AppRotateFiles 1
    & $nssm set $Name AppRotateBytes 1048576

    & $nssm start $Name
    Write-Host "OK $Name -> ngrok http $Port ($WebAddr)"
}

foreach ($entry in $services.GetEnumerator()) {
    Install-NgrokService -Name $entry.Key `
        -Authtoken $entry.Value.Authtoken `
        -Port $entry.Value.Port `
        -WebAddr $entry.Value.WebAddr
}

Write-Host ""
Write-Host "Backend:  http://127.0.0.1:4040/api/tunnels"
Write-Host "Frontend: http://127.0.0.1:4041/api/tunnels"
