$ErrorActionPreference = 'Stop'
Write-Host 'Preparando Indoor Nav piloto...' -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter no esta instalado o no esta en PATH.' }
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$temporary = Join-Path $env:TEMP 'indoor_nav_flutter_scaffold'
if (Test-Path $temporary) { Remove-Item $temporary -Recurse -Force }
flutter create --platforms android --project-name indoor_nav_pilot $temporary
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el proyecto Flutter.' }
Copy-Item (Join-Path $temporary 'android') (Join-Path $root 'android') -Recurse -Force
Copy-Item (Join-Path $temporary 'analysis_options.yaml') $root -Force
Copy-Item (Join-Path $temporary '.metadata') $root -Force
Remove-Item $temporary -Recurse -Force
$manifest = Join-Path $root 'android/app/src/main/AndroidManifest.xml'
$xml = Get-Content $manifest -Raw
$xml = $xml.Replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">' + [Environment]::NewLine + '    <uses-permission android:name="android.permission.CAMERA" />')
Set-Content -Path $manifest -Value $xml -Encoding utf8
Push-Location $root
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'Error en flutter pub get' }
  flutter build apk --debug
  if ($LASTEXITCODE -ne 0) { throw 'Error compilando APK' }
  Write-Host 'APK: build/app/outputs/flutter-apk/app-debug.apk' -ForegroundColor Green
} finally { Pop-Location }
