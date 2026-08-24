@echo off
title Radio Charu - Fast Android Emulator Launcher
echo ====================================================
echo Cleaning locks and starting Pixel 7 Emulator...
echo ====================================================

:: Clean any stale locks
del /s /q "%USERPROFILE%\.android\avd\Pixel_7.avd\*.lock" 2>nul

:: Launch Emulator in a separate GUI window with Host GPU
start "" "%LOCALAPPDATA%\Android\sdk\emulator\emulator.exe" -avd Pixel_7 -no-snapshot-load -gpu host

echo.
echo Emulator window is opening on your desktop screen!
echo Waiting for Android to boot...
"%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" wait-for-device

:check_boot
for /f "tokens=*" %%a in ('"%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" shell getprop sys.boot_completed 2^>nul') do set BOOT=%%a
if "%BOOT%"=="1" goto ready
ping 127.0.0.1 -n 3 >nul
goto check_boot

:ready
echo.
echo ====================================================
echo [OK] Pixel 7 is fully booted and ready on your screen!
echo ====================================================
