param(
    [string]$BuildDir = "build",
    [string]$OutDir = "dist",
    [string]$QtBin = "C:/msys64/clangarm64/bin",
    [string]$QmlDir = "C:/msys64/clangarm64/share/qt6/qml"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DistDir = "$ScriptDir/$OutDir/Piki"
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

Write-Host "=== Step 1: Copy piki.exe ==="
Copy-Item "$ScriptDir/$BuildDir/bin/piki.exe" $DistDir -Force

Write-Host "=== Step 2: windeployqt ==="
& "$QtBin/windeployqt.exe" --release "$DistDir/piki.exe" 2>&1 | Out-Null

Write-Host "=== Step 3: Copy KF6/Piqi/QCoro DLLs ==="
$dlls = @(
    "libKF6I18nQml.dll","libKF6I18n.dll","libKF6BreezeIcons.dll",
    "libKF6CoreAddons.dll","libKF6ConfigGui.dll","libKF6ConfigCore.dll",
    "libKF6Purpose.dll","libKF6ConfigQml.dll","libKF6I18nLocaleData.dll",
    "libKF6WindowSystem.dll","libKF6Service.dll",
    "libKirigamiPlatform.dll","libKirigami.dll","libKirigamiControls.dll",
    "libKirigamiDelegates.dll","libKirigamiDialogs.dll","libKirigamiLayouts.dll",
    "libKirigamiTemplates.dll","libKirigamiPrimitives.dll",
    "piqi.dll","libqt6keychain.dll","libfuturesql6.dll",
    "libc++.dll","libunwind.dll"
)
foreach ($d in $dlls) {
    $src = "$QtBin/$d"
    if (Test-Path $src) { Copy-Item $src $DistDir -Force }
}

Write-Host "=== Step 4: Copy ALL system QML modules ==="
# Copy ALL QML modules from system (including Qt, QtQuick, org.kde, io, etc.)
Get-ChildItem $QmlDir -Directory | ForEach-Object {
    $target = "$DistDir/qml/$($_.Name)"
    Copy-Item -Recurse $_.FullName $target -Force
}

# Overwrite the app's own QML module with the build output (compiled version)
Copy-Item -Recurse "$ScriptDir/$BuildDir/io/github/micro/piki" "$DistDir/qml/io/github/micro/piki" -Force

Write-Host "=== Step 5: qt.conf ==="
@"
[Paths]
Prefix = .
Plugins = .
Qml2Imports = qml
"@ | Out-File -FilePath "$DistDir/qt.conf" -Encoding ASCII

Write-Host "=== Step 6: Create 7z archive ==="
$archive = "$ScriptDir/$OutDir/Piki-windows-arm64.7z"
Remove-Item $archive -Force -ErrorAction SilentlyContinue
& 7z a $archive "$DistDir/*" -mx3 -r 2>&1 | Select-Object -Last 2

Write-Host "=== Done ==="
Write-Host "Package: $archive"
