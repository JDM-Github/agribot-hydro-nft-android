@echo off
setlocal

echo Building optimized Flutter APKs...
flutter build apk --release --obfuscate --split-debug-info=build/debug_info --split-per-abi
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
