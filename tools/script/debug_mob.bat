@echo off
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect AIR SDK (for fdb.bat + adt.bat) ----
if not exist "%FLEX_HOME%\bin\fdb.bat" (
    if exist "%PROJ%\AIRSDK5\AIRSDK_51.3.2\bin\fdb.bat" (
        set FLEX_HOME=%PROJ%\AIRSDK5\AIRSDK_51.3.2
    )
)
set FLEX_BIN=%FLEX_HOME%\bin

set ADT=%FLEX_BIN%\adt.bat
set CERT=%FLEX_BIN%\mycert.p12
set APP_XML=%PROJ%\tools\Test\application.xml
set SWF_FILE=%PROJ%\launch.swf
set APK_FILE=%PROJ%\tools\Test\死神vs火影银鱼改.apk

set DBG_ID=com.bvn.yinyu
set DBG_PACKAGE=air.%DBG_ID%
set DBG_PORT=7936

if not exist "%FLEX_BIN%\fdb.bat" (
    echo [ERROR] fdb.bat not found.
    echo Set FLEX_HOME to AIR SDK root or ensure AIRSDK5 exists.
    goto END
)

:: ---- Package APK ----
echo [PACKAGE] Creating debug APK...
if not exist "%SWF_FILE%" (
    echo [ERROR] SWF not found: %SWF_FILE%
    echo Run debug.bat first to compile.
    goto END
)
if not exist "%APP_XML%" (
    echo [ERROR] App descriptor not found: %APP_XML%
    goto END
)

if exist "%ADT%" (
    "%ADT%" -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%CERT%" -storepass yinyu7798 "%APK_FILE%" "%APP_XML%" "%SWF_FILE%"
    if %errorlevel%==0 (
        echo [OK] APK created: %APK_FILE%
    ) else (
        echo [ERROR] ADT package failed.
        goto END
    )
) else (
    echo [ERROR] adt.bat not found: %FLEX_BIN%
    goto END
)

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
echo Device: %DEVICE_ID%

:: ---- Setup ----
set PATH=%FLEX_BIN%;%PATH%

:: ---- Install + Launch ----
adb -s "%DEVICE_ID%" uninstall %DBG_PACKAGE% >nul 2>&1
adb -s "%DEVICE_ID%" install "%APK_FILE%"
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
