param(
    [string]$BuildDir = "build",
    [string]$OutDir = "dist",
    [string]$Msys2Root = $null
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Auto-detect MSYS2 root
if (-not $Msys2Root) {
    $guesses = @(
        "C:/msys64",
        "D:/msys64",
        "C:/msys2",
        "D:/msys2",
        "$env:USERPROFILE/msys64",
        "$env:USERPROFILE/msys2"
    )
    foreach ($g in $guesses) {
        if (Test-Path "$g/msys2.exe") {
            $Msys2Root = $g
            break
        }
    }
    if (-not $Msys2Root) {
        Write-Error "MSYS2 not found. Set -Msys2Root <path> or ensure MSYS2 is at C:/msys64"
        exit 1
    }
}

# Detect MSYS2 environment (clangarm64 or mingw64)
$MsysEnv = if (Test-Path "$Msys2Root/clangarm64") { "clangarm64" } elseif (Test-Path "$Msys2Root/mingw64") { "mingw64" } else { $null }
if (-not $MsysEnv) {
    Write-Error "No MSYS2 environment found (checked clangarm64, mingw64)"
    exit 1
}

$QtBin = "$Msys2Root/$MsysEnv/bin"
$QmlDir = "$Msys2Root/$MsysEnv/share/qt6/qml"
$SevenZip = "$Msys2Root/$MsysEnv/bin/7z.exe"

Write-Host "MSYS2: $Msys2Root ($MsysEnv)"
Write-Host "Qt:    $QtBin"
Write-Host "QML:   $QmlDir"

$DistDir = "$ScriptDir/$OutDir/Piki"
Remove-Item $DistDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

Write-Host "=== Step 1: Copy piki.exe ==="
Copy-Item "$ScriptDir/$BuildDir/bin/piki.exe" $DistDir -Force

Write-Host "=== Step 2: windeployqt ==="
$null = & "$QtBin/windeployqt.exe" --release "$DistDir/piki.exe" 2>&1

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
Get-ChildItem $QmlDir -Directory | ForEach-Object {
    Copy-Item -Recurse $_.FullName "$DistDir/qml/$($_.Name)" -Force
}
Copy-Item -Recurse "$ScriptDir/$BuildDir/io/github/micro/piki" "$DistDir/qml/io/github/micro/piki" -Force

Write-Host "=== Step 5: Copy locale (translations) ==="
Copy-Item -Recurse "$ScriptDir/$BuildDir/locale" "$DistDir/" -Force

Write-Host "=== Step 6: qt.conf ==="
@"
[Paths]
Prefix = .
Plugins = .
Qml2Imports = qml
"@ | Out-File -FilePath "$DistDir/qt.conf" -Encoding ASCII

Write-Host "=== Step 6: Create 7z archive ==="
$archive = "$ScriptDir/$OutDir/Piki-windows-arm64.7z"
Remove-Item $archive -Force -ErrorAction SilentlyContinue

if (Test-Path $SevenZip) {
    & $SevenZip a $archive "$DistDir/*" -mx3 -r
} else {
    # Fallback: try system 7z or PowerShell Compress-Archive (zip)
    $sevenZipSys = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($sevenZipSys) {
        & 7z a $archive "$DistDir/*" -mx3 -r
    } else {
        Write-Host "7z not found, creating zip instead"
        Compress-Archive -Path "$DistDir/*" -DestinationPath "$ScriptDir/$OutDir/Piki-windows-arm64.zip" -Force
    }
}

Write-Host "=== Done ==="
Write-Host "Package: $archive (or .zip)"
