@echo off
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect AIR SDK ----
if not defined FLEX_HOME set "FLEX_HOME="
if not exist "%FLEX_HOME%\bin\fdb.bat" (
    if exist "%PROJ%\AIRSDK5\AIRSDK_51.3.2\bin\fdb.bat" (
        set "FLEX_HOME=%PROJ%\AIRSDK5\AIRSDK_51.3.2"
    )
)
set "FLEX_BIN=%FLEX_HOME%\bin"
set "ADT=%FLEX_BIN%\adt.bat"
set "CERT=%FLEX_BIN%\mycert.p12"

set "APP_XML=%PROJ%\tools\Test\application.xml"
set "TEST_DIR=%PROJ%\tools\Test"
set "SWF_SRC=%PROJ%\launch.swf"
set "SWF_FILE=%TEST_DIR%\launch.swf"
set "APK_FILE=%TEST_DIR%\死神vs火影银鱼改.apk"

set "DBG_ID=com.bvn.yinyu"
set "DBG_PACKAGE=air.%DBG_ID%"
set "DBG_PORT=7936"

echo ========================================
echo   BVN 真机调试一键脚本
echo ========================================
echo.

:: ---- Step 1: Verify AIR SDK ----
if not exist "%FLEX_BIN%\fdb.bat" (
    echo [ERROR] fdb.bat not found: %FLEX_BIN%
    echo Set FLEX_HOME to AIR SDK root or ensure AIRSDK5 exists.
    goto END
)
echo [OK] AIR SDK: %FLEX_HOME%

:: ---- Step 2: Build SWF ----
echo.
echo [BUILD] Compiling...
call "%PROJ%\build.bat"
if %errorlevel% neq 0 (
    echo [ERROR] Build failed (errorlevel=%errorlevel%).
    goto END
)
if not exist "%SWF_SRC%" (
    echo [ERROR] Build output not found: %SWF_SRC%
    goto END
)
echo [OK] Build complete: %SWF_SRC%

:: ---- Step 3: Copy SWF to Test dir ----
copy /Y "%SWF_SRC%" "%SWF_FILE%" >nul
if not exist "%SWF_FILE%" (
    echo [ERROR] Failed to copy SWF to %SWF_FILE%
    goto END
)
echo [OK] SWF ready: %SWF_FILE%

:: ---- Step 4: Verify app descriptor ----
if not exist "%APP_XML%" (
    echo [ERROR] App descriptor not found: %APP_XML%
    goto END
)
echo [OK] App descriptor: %APP_XML%

:: ---- Step 5: Package APK ----
echo.
echo [PACKAGE] Creating debug APK...
if not exist "%ADT%" (
    echo [ERROR] adt.bat not found: %FLEX_BIN%
    goto END
)
"%ADT%" -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%CERT%" -storepass yinyu7798 "%APK_FILE%" "%APP_XML%" "%SWF_FILE%"
if %errorlevel% neq 0 (
    echo [ERROR] ADT package failed (errorlevel=%errorlevel%).
    goto END
)
echo [OK] APK created: %APK_FILE%

:: ---- Step 6: Check ADB ----
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] adb not found in PATH.
    goto END
)
adb start-server >nul 2>nul
timeout /t 2 >nul

:: ---- Step 7: Find Android device ----
set "DEVICE_ID="
for /f "usebackq skip=1 tokens=1" %%D in (`adb devices 2^>nul ^| findstr "device$"`) do (
    if "!DEVICE_ID!"=="" set "DEVICE_ID=%%D"
)

if "%DEVICE_ID%"=="" (
    echo [ERROR] No Android device detected. Check USB connection.
    goto END
)
echo [OK] Device: %DEVICE_ID%

:: ---- Step 8: Install + Launch + Debug ----
set "PATH=%FLEX_BIN%;%PATH%"

echo.
echo [INSTALL] Uninstalling old version...
adb -s "%DEVICE_ID%" uninstall %DBG_PACKAGE% >nul 2>&1

echo [INSTALL] Installing APK...
adb -s "%DEVICE_ID%" install "%APK_FILE%"
if %errorlevel% neq 0 (
    echo [ERROR] APK install failed.
    goto END
)

echo [DEBUG] Forwarding port %DBG_PORT%...
adb -s "%DEVICE_ID%" forward tcp:%DBG_PORT% tcp:%DBG_PORT% >nul

echo [DEBUG] Launching app...
adb -s "%DEVICE_ID%" shell am start -n %DBG_PACKAGE%/.AppEntry >nul

echo.
echo ========================================
echo   Debugger starting (Ctrl+C to stop)
echo ========================================
(
    echo connect
    echo continue
    echo quit
    echo y
) | fdb -unit

echo.
echo [DONE] Debug session ended.
goto END

:END
echo.
pause
exit /b