# Bir marta ishga tushiring: Flutter platforma papkalarini yaratadi va Android ruxsatlarini sozlaydi.
# Ishlatish (PowerShell, app papkasida):  .\prepare_android.ps1
$ErrorActionPreference = 'Stop'

flutter create --project-name mob_kassa --org uz.mobkassa --platforms android .
flutter pub get

$manifest = Join-Path $PSScriptRoot 'android\app\src\main\AndroidManifest.xml'
$xml = Get-Content $manifest -Raw -Encoding UTF8

if ($xml -notmatch 'android.permission.INTERNET') {
    $xml = $xml -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
}
if ($xml -notmatch 'usesCleartextTraffic') {
    # http:// manzil bilan ishlash uchun (ichki tarmoq). Faqat https bo'lsa, bu qatorni olib tashlang.
    $xml = $xml -replace '<application', '<application android:usesCleartextTraffic="true"'
}
if ($xml -match 'android:label="[^"]*"') {
    $xml = $xml -replace 'android:label="[^"]*"', 'android:label="Mobil kassa"'
}
Set-Content $manifest $xml -Encoding UTF8

Write-Host 'Tayyor. Tekshirish: flutter analyze   |   APK: flutter build apk --release'
