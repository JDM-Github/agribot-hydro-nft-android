@echo off
setlocal

echo Building optimized Flutter APKs...
flutter build apk --release --obfuscate --split-debug-info=build/debug_info --split-per-abi

for /f "tokens=*" %%A in ('adb shell getprop ro.product.cpu.abi') do set ABI=%%A

set APK=build\app\outputs\flutter-apk\app-%ABI%-release.apk

if exist "%APK%" (
    echo Installing %APK% on device...
    adb install -r "%APK%"
) else (
    echo ABI %ABI% not found! Installing arm64-v8a by default.
    adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
)
