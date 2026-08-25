@echo off
title Radio Charu - 1-Click Smart App and Emulator Launcher
echo ====================================================
echo   Radio Charu - 1-Click Smart Launcher and Runner
echo ====================================================
echo.

set "EMULATOR_PATH=%LOCALAPPDATA%\Android\sdk\emulator\emulator.exe"
set "ADB_PATH=%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe"

if not exist "%EMULATOR_PATH%" (
    echo [ERROR] Android SDK Emulator not found at: "%EMULATOR_PATH%"
    echo Please ensure Android Studio SDK is installed on this PC.
    echo.
    pause
    exit /b 1
)

:: Step 1: Check if an Android device/emulator is ALREADY connected and ready
set "RUNNING_DEVICE="
for /f "tokens=1,2" %%a in ('"%ADB_PATH%" devices 2^>nul ^| findstr /v "List"') do (
    if "%%b"=="device" (
        set "RUNNING_DEVICE=%%a"
    )
)

if not "%RUNNING_DEVICE%"=="" (
    echo [OK] Active Android device detected: %RUNNING_DEVICE%
    echo [INFO] Emulator is already running! Skipping launch step...
    echo.
    goto run_flutter
)

:: Step 2: Dynamically detect installed AVD (Priority: Pixel_8 / Pixel_7 -> Any available AVD)
set "TARGET_AVD="
for /f "tokens=*" %%i in ('"%EMULATOR_PATH%" -list-avds 2^>nul') do (
    if not defined TARGET_AVD set "TARGET_AVD=%%i"
    if /i "%%i"=="Pixel_8" set "TARGET_AVD=%%i"
    if /i "%%i"=="Pixel_7" set "TARGET_AVD=%%i"
)

if "%TARGET_AVD%"=="" (
    echo [ERROR] No Android Virtual Device found on this PC!
    echo Please create an AVD in Android Studio Device Manager.
    echo.
    pause
    exit /b 1
)

echo [INFO] Detected AVD on this PC: %TARGET_AVD%
echo [INFO] Cleaning stale lock files and lock folders...
del /s /q "%USERPROFILE%\.android\avd\%TARGET_AVD%.avd\*.lock" 2>nul
for /d /r "%USERPROFILE%\.android\avd\%TARGET_AVD%.avd" %%d in (*.lock) do rmdir /s /q "%%d" 2>nul

echo [INFO] Launching %TARGET_AVD% Emulator in GUI window...
start "" "%EMULATOR_PATH%" -avd %TARGET_AVD% -no-snapshot-load -gpu host

echo.
echo Emulator window is opening on your desktop screen!
echo Waiting for Android device to boot...
"%ADB_PATH%" wait-for-device

:check_boot
set "BOOT=0"
for /f "tokens=*" %%a in ('"%ADB_PATH%" shell getprop sys.boot_completed 2^>nul') do set "BOOT=%%a"
if "%BOOT%"=="1" goto ready
ping 127.0.0.1 -n 3 >nul
goto check_boot

:ready
echo.
echo ====================================================
echo [OK] %TARGET_AVD% is fully booted and ready on screen!
echo ====================================================
echo.

:run_flutter
echo [INFO] Launching Radio Charu app via Flutter Run...
echo.
flutter run

pause
