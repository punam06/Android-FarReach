# Run FarReach on this PC

The checkout is `D:\Code\Projects\Android-FarReach`. The installed debug app uses `http://10.0.2.2:3000`, which reaches the local Docker API from Android.

## Installed emulator

- Name: `FarReach_Travel_API_36`
- Device: Pixel 6, 1080 × 2400, Android 16 / API 36, Google APIs x86_64
- Emulator SDK: `D:\AndroidSdk`
- AVD data: `D:\AndroidAVD\FarReach_Travel_API_36.avd`
- Flutter build SDK remains `C:\Android\Sdk`.
- Windows Hypervisor Platform acceleration and the NVIDIA GPU were detected during launch.

The image was downloaded from Google's Android repository and verified against its published SHA-1: `c6bf44bdcd885bb902b4ba752d111a073ad7a817`. The existing accepted SDK license was reused. Emulator files were placed on D: because C: had about 2 GiB free.

## Start the backend

```powershell
Set-Location 'D:\Code\Projects\Android-FarReach'
docker compose up -d --build
Invoke-RestMethod 'http://127.0.0.1:3000/api/health'
```

## Start Android

Skip this step if `adb devices` already shows `emulator-5554`.

```powershell
$env:ANDROID_HOME = 'D:\AndroidSdk'
$env:ANDROID_SDK_ROOT = 'D:\AndroidSdk'
& 'D:\AndroidSdk\emulator\emulator.exe' -avd FarReach_Travel_API_36 -gpu auto -memory 2048 -cores 2 -no-snapshot-load -no-snapshot-save -no-boot-anim
```

Leave that terminal running. In another terminal, wait until boot completes:

```powershell
& 'C:\Android\Sdk\platform-tools\adb.exe' devices
& 'C:\Android\Sdk\platform-tools\adb.exe' -s emulator-5554 shell getprop sys.boot_completed
```

The boot property must return `1` before installing. The first boot took about two minutes. Android's first-use keyboard handwriting tutorial interfered with automated text entry; handwriting was disabled in this test AVD with `adb shell settings put secure stylus_handwriting_enabled 0`.

## Run the existing APK with Flutter

```powershell
Set-Location 'D:\Code\Projects\Android-FarReach\mobile'
& 'C:\src\flutter\bin\flutter.bat' run -d emulator-5554 --use-application-binary='D:\Code\Projects\Android-FarReach\mobile\build\app\outputs\flutter-apk\app-debug.apk'
```

To rebuild after source edits, use a fresh terminal with the original build SDK:

```powershell
$env:ANDROID_HOME = 'C:\Android\Sdk'
$env:ANDROID_SDK_ROOT = 'C:\Android\Sdk'
Set-Location 'D:\Code\Projects\Android-FarReach\mobile'
& 'C:\src\flutter\bin\flutter.bat' run -d emulator-5554
```

See [verification results](VERIFICATION.md) for exercised app flows. Local screenshots, UI XML and logs are in `test-results/emulator/`, which Git ignores.

The [Android emulator command-line guide](https://developer.android.com/studio/run/emulator-commandline) describes the emulator launch options.
