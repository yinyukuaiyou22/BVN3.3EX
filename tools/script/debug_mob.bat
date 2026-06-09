@echo off
setlocal enabledelayedexpansion
:: =============================================
:: BVN Mobile Debug Script
:: 自动安装 APK 到手机 + fdb 实时调试
:: =============================================

set BAT_HOME=%~dp0
set DBG_FILE=%BAT_HOME%..\..\out\launch.apk
set DBG_ID=net.play5d.game.bvn
set DBG_PACKAGE=air.%DBG_ID%
set DBG_PORT=7936

:: ---- Check FLEX_HOME ----
if "%FLEX_HOME%"=="" (
    echo [ERROR] FLEX_HOME environment variable not set.
    echo Set it to AIR SDK root, e.g.: set FLEX_HOME=E:\BaiduNetdiskDownload\BVNY\AIRSDK5\AIRSDK_51.3.2
    goto END
)
if not exist "%FLEX_HOME%\bin\fdb.bat" (
    echo [ERROR] fdb.bat not found at %FLEX_HOME%\bin\
    goto END
)
echo FLEX_HOME: %FLEX_HOME%

:: ---- Check ADB ----
where adb >nul 2>nul
if %errorlevel%==1 (
    echo [ERROR] adb not found in PATH.
    goto END
)
adb start-server >nul 2>nul
timeout /t 2 >nul

:: ---- Find Android device ----
set DEVICE_COUNT=0
set "DEVICE_ID="
for /f "usebackq skip=1 tokens=1" %%D in ('adb devices ^| findstr "device$"') do (
    if "!DEVICE_ID!"=="" set "DEVICE_ID=%%D"
    set /a DEVICE_COUNT+=1
)

if %DEVICE_COUNT%==0 (
    echo [ERROR] No Android device detected.
    goto END
)
echo Found device: %DEVICE_ID%

:: ---- Setup PATH for fdb/adt ----
set PATH=%FLEX_HOME%\bin;%PATH%

:: ---- Check/Install APK ----
adb -s "%DEVICE_ID%" shell pm path %DBG_PACKAGE% >nul 2>&1
if %errorlevel%==0 (
    echo Already installed. Launching...
    goto LAUNCH
)

if not exist "%DBG_FILE%" (
    echo [WARN] APK not found: %DBG_FILE%
    echo Build via: adt -package -target apk-debug ...
    goto LAUNCH
)
echo Installing APK...
adb -s "%DEVICE_ID%" install "%DBG_FILE%"

:LAUNCH
adb -s "%DEVICE_ID%" forward tcp:%DBG_PORT% tcp:%DBG_PORT% >nul
adb -s "%DEVICE_ID%" shell am start -n %DBG_PACKAGE%/.AppEntry >nul

echo.
echo === Debugger connected (Ctrl+C to stop) ===

:LOOP
(
    echo connect
    echo continue
    echo quit
    echo y
) | fdb -unit
timeout /t 2 >nul
goto LOOP

:END
pause >nul
exit 1
