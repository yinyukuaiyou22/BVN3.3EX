@echo off
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect paths ----
if "%FLEX_HOME%"=="" set FLEX_HOME=%PROJ%\flex4.16.1-air51.0.1.1
set FLEX_BIN=%FLEX_HOME%\bin

set ADT=%FLEX_BIN%\adt.bat
set CERT=%FLEX_BIN%\mycert.p12
set APP_XML=%PROJ%\tools\Test\application.xml
set SWF_FILE=%PROJ%\tools\Test\launch.swf
set APK_FILE=%PROJ%\tools\Test\launch.apk

set DBG_ID=com.bvn.yinyu
set DBG_PACKAGE=air.%DBG_ID%
set DBG_PORT=7936

if not exist "%FLEX_BIN%\fdb.bat" (
    echo [ERROR] fdb.bat not found: %FLEX_BIN%
    goto END
)

:: ---- Package APK from Test SWF ----
echo [BUILD] Packaging APK...
copy /Y "%PROJ%\launch.swf" "%SWF_FILE%" >nul
if exist "%ADT%" (
    "%ADT%" -package -target apk-debug -storetype pkcs12 -keystore "%CERT%" -storepass 123456 "%APK_FILE%" "%APP_XML%" "%SWF_FILE%"
    if %errorlevel%==0 (
        echo [OK] APK created: %APK_FILE%
    ) else (
        echo [WARN] ADT package failed, trying existing APK...
    )
) else (
    echo [WARN] adt.bat not found, using existing APK if present
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
echo Found device: %DEVICE_ID%

:: ---- Setup PATH for fdb ----
set PATH=%FLEX_BIN%;%PATH%

:: ---- Install APK ----
adb -s "%DEVICE_ID%" uninstall %DBG_PACKAGE% >nul 2>&1
if not exist "%APK_FILE%" (
    echo [ERROR] APK not found: %APK_FILE%
    goto END
)
echo Installing...
adb -s "%DEVICE_ID%" install "%APK_FILE%"

:: ---- Launch + debug ----
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
