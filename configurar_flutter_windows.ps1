# Ejecuta desde PowerShell en la raíz de este ZIP, con Flutter SDK instalado.
$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter no está en PATH. Ejecuta flutter doctor y configura Flutter SDK.' }
if (Test-Path 'mobile_flutter') { throw 'La carpeta mobile_flutter ya existe. Respalda o elimina esa carpeta antes de continuar.' }
flutter create --project-name votacion_segura mobile_flutter
if ($LASTEXITCODE -ne 0) { throw 'flutter create falló.' }
Copy-Item -Path 'flutter_codigo\lib\*' -Destination 'mobile_flutter\lib' -Recurse -Force
Copy-Item -Path 'flutter_codigo\pubspec.yaml' -Destination 'mobile_flutter\pubspec.yaml' -Force
Copy-Item -Path 'flutter_codigo\android_debug_AndroidManifest.xml' -Destination 'mobile_flutter\android\app\src\debug\AndroidManifest.xml' -Force
$manifest = 'mobile_flutter\android\app\src\main\AndroidManifest.xml'
$content = Get-Content $manifest -Raw
if ($content -notmatch 'android.permission.INTERNET') {
  $replacement = '<uses-permission android:name="android.permission.INTERNET" />' + "`n    <application"
  $content = $content -replace '<application', $replacement
  Set-Content -Path $manifest -Value $content -Encoding UTF8
}
Push-Location 'mobile_flutter'
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get falló.' }
} finally { Pop-Location }
Write-Host 'Proyecto Flutter creado. Abre mobile_flutter en Android Studio y ejecuta el emulador.' -ForegroundColor Green
