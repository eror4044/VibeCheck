param(
  [int]$Port = 5173,
  [string]$ApiBaseUrl = "https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com",
  [string]$GoogleClientId = "",
  [int]$Retries = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Remove-FlutterAssets {
  $assets = Join-Path $PSScriptRoot "..\build\flutter_assets"
  $assets = (Resolve-Path -LiteralPath $assets -ErrorAction SilentlyContinue)

  if (-not $assets) {
    return
  }

  $assetsPath = $assets.Path
  Write-Host "Cleaning $assetsPath" -ForegroundColor Cyan

  for ($i = 0; $i -lt 3; $i++) {
    try {
      attrib -R -S -H "$assetsPath\*" /S /D 2>$null
      Remove-Item -LiteralPath $assetsPath -Recurse -Force -ErrorAction Stop
      return
    } catch {
      Start-Sleep -Milliseconds 400
      if ($i -eq 2) {
        throw
      }
    }
  }
}

$clientDir = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $clientDir

if ([string]::IsNullOrWhiteSpace($GoogleClientId)) {
  Write-Warning "GoogleClientId is empty. Pass -GoogleClientId <id> or run flutter with --dart-define=GOOGLE_CLIENT_ID=..."
}

for ($attempt = 0; $attempt -le $Retries; $attempt++) {
  Remove-FlutterAssets

  Write-Host "Starting Flutter (attempt $($attempt+1)/$($Retries+1)) on port $Port" -ForegroundColor Green
  $args = @(
    "run",
    "-d",
    "chrome",
    "--web-port=$Port",
    "--dart-define=API_BASE_URL=$ApiBaseUrl"
  )

  if (-not [string]::IsNullOrWhiteSpace($GoogleClientId)) {
    $args += "--dart-define=GOOGLE_CLIENT_ID=$GoogleClientId"
  }

  & flutter @args
  if ($LASTEXITCODE -eq 0) {
    exit 0
  }

  Write-Warning "flutter exited with code $LASTEXITCODE"
  if ($attempt -eq $Retries) {
    exit $LASTEXITCODE
  }

  Start-Sleep -Milliseconds 600
}
