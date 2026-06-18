::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Copyright (C) 2021-2026, 5DPLAY Game Studio
:: All rights reserved.
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

call :ECHO_LANG :TITLE ""

:: ---- Auto-detect or verify FLEX_HOME ----
set "SDK_HOME=%PROJ%\AIRSDK\flex4.16.1-air51.0.1.1"
REM always check local SDK first
if exist "%SDK_HOME%\bin\fdb.bat" (
    set "FLEX_HOME=%SDK_HOME%"
    echo [AUTO] FLEX_HOME detected: !FLEX_HOME!
    goto FLEX_OK
)
:: Fallback: check common paths
for %%d in (
    "%PROJ%\AIRSDK\AIRSDK_51.3.2"
    "E:\BaiduNetdiskDownload\BVNY\AIRSDK\flex4.16.1-air51.0.1.1"
) do (
    if exist %%d\bin\fdb.bat (
        set "FLEX_HOME=%%~d"
        echo [AUTO] FLEX_HOME found: !FLEX_HOME!
        goto FLEX_OK
    )
)
call :ECHO_LANG :UNDEFINE "FLEX_HOME"
echo   Set it via: setx FLEX_HOME "E:\BaiduNetdiskDownload\BVNY\AIRSDK\flex4.16.1-air51.0.1.1"
goto END
:FLEX_OK
call :EXIST "%FLEX_HOME%"
echo FLEX_HOME: %FLEX_HOME%

set FLEX_BIN=%FLEX_HOME%\bin
call :EXIST "%FLEX_BIN%"

set "ADT=%FLEX_BIN%\adt.bat"
set "CERT=%FLEX_BIN%\mycert.p12"
set "PLATFORM_TOOLS=%PROJ%\tools\platform-tools"
set "PATH=%PLATFORM_TOOLS%;%FLEX_BIN%;%PATH%"

:: ---- Paths ----
set "TEST_DIR=%PROJ%\tools\Test"
set "SWF_FILE=%TEST_DIR%\launch.swf"
set "APP_XML=%TEST_DIR%\application.xml"
set "APK_FILE=%TEST_DIR%\bvn.apk"

:: ---- App info ----
set DBG_ID=com.bvn.yinyu
set DBG_PACKAGE=air.%DBG_ID%
set DBG_PORT=7936

:: ---- Build SWF ----
call :ECHO_LANG :BUILD_MSG ""
call "%PROJ%\build.bat"
if %errorlevel% neq 0 (
    call :ECHO_LANG :BUILD_FAIL ""
    goto END
)
call :EXIST "%SWF_FILE%"
call :EXIST "%APP_XML%"

:: ---- Package APK ----
call :ECHO_LANG :PACKAGE_MSG ""
call :EXIST "%ADT%"
cd /d "%TEST_DIR%"
:: ---- Slim APK DISABLED (ANE disabled — resources must stay in APK) ----
REM for %%D in (fighter map face bgm config) do (
REM     REM recover dangling backup from previous interrupted run
REM     if exist "_bakslim_%%D" (
REM         if exist "assets\%%D\.gdummy" del "assets\%%D\.gdummy"
REM         if exist "assets\%%D" rd /s /q "assets\%%D"
REM         move "_bakslim_%%D" "assets\%%D"
REM     )
REM     if exist "assets\%%D" (
REM         move "assets\%%D" "_bakslim_%%D"
REM         mkdir "assets\%%D"
REM         echo. > "assets\%%D\.gdummy"
REM     )
REM )

	:: ---- Strip .fla source files from swf/ (only .swf needed at runtime) ----
	if exist "assets\swf\*.fla" (
	    mkdir "_bakslim_fla" 2>nul
	    move "assets\swf\*.fla" "_bakslim_fla\" >nul 2>nul
	    echo [FLA] Stripped .fla files from APK
	)

	call "%ADT%" -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%CERT%" -storepass yinyu7798 "bvn.apk" "application.xml" -platformsdk "D:/Android/SDK" "launch.swf" -C . assets
	set ADT_RESULT=%errorlevel%

	:: ---- Restore backed-up content dirs (ALWAYS run, even on ADT failure) ----
	REM for %%D in (fighter map face bgm config) do (
	REM     if exist "assets\%%D\.gdummy" del "assets\%%D\.gdummy"
	REM     if exist "assets\%%D" rd /s /q "assets\%%D"
	REM     if exist "_bakslim_%%D" move "_bakslim_%%D" "assets\%%D"
	REM )
	:: ---- Restore .fla files ----
	if exist "_bakslim_fla\*.fla" (
	    move "_bakslim_fla\*.fla" "assets\swf\" >nul 2>nul
	    rd "_bakslim_fla" 2>nul
	)

	if %ADT_RESULT% neq 0 (
	    echo [ERROR] ADT packaging failed with code %ADT_RESULT%
	    call :ECHO_LANG :PACKAGE_FAIL ""
	    goto END
	)
	call :EXIST "%APK_FILE%"

:: ---- Check: ADB ----
call :CHK_CMD adb
adb start-server >nul 2>nul
timeout /t 2 >nul

:: ---- Find device ----
adb devices >nul 2>nul
timeout /t 1 >nul

set TMP_ADB_DEVICES=%TEMP%\adb_devices.txt
adb devices >"%TMP_ADB_DEVICES%"

set DEVICE_COUNT=0
set "DEVICE_ID="
for /f "usebackq skip=1 delims=" %%L in ("%TMP_ADB_DEVICES%") do (
    set "LINE=%%L"
    echo !LINE! | findstr "device" >nul
    if !errorlevel!==0 (
        set /a DEVICE_COUNT+=1
        call :GET_DEVICE_ID "!LINE!"
        goto :NEXT
    )
)

:NEXT
set PATH=%FLEX_BIN%;%PATH%
del "%TMP_ADB_DEVICES%" >nul 2>nul

if !DEVICE_COUNT!==0 (
    call :ECHO_LANG :NO_DEVICE ""
    goto :END
)

echo.
call :ECHO_LANG :TITLE_ADB "!DEVICE_ID!"
call :ECHO_LANG :CONNECT "!DEVICE_ID!"

:: ---- Install if needed ----
adb shell pm path %DBG_PACKAGE% | findstr "package:" >nul 2>nul
if %errorlevel%==0 (
    goto :INSTALLED
)

call :ECHO_LANG :NOT_INSTALLED "%DBG_PACKAGE%"
call :ECHO_LANG :INSTALLING "%DBG_PACKAGE%"
adb -s "!DEVICE_ID!" install "%APK_FILE%"

:INSTALLED
adb -s "!DEVICE_ID!" shell am force-stop %DBG_PACKAGE% >nul
adb -s "!DEVICE_ID!" shell am start -n %DBG_PACKAGE%/.AppEntry >nul

:: ---- Launch persistent logcat console ----
set "LOG_HELPER=%TEMP%\bvn_logcat_console.bat"
(
    echo @echo off
    echo chcp 65001 ^>nul
    echo title BVN Logcat
    echo echo.
    echo echo =============================================
    echo echo   BVN Logcat - real-time trace output
    echo echo =============================================
    echo echo.
    echo echo Starting logcat... Ctrl+C to stop
    echo echo Filter: air bvn trace flash DEBUG
    echo echo.
    echo adb -s "!DEVICE_ID!" logcat -v time ^| findstr /i "air bvn trace flash DEBUG"
    echo echo.
    echo echo Logcat stopped. Close this window or press any key.
    echo pause
) > "%LOG_HELPER%"

echo [DEBUG] Helper created: %LOG_HELPER%
echo [DEBUG] Device: !DEVICE_ID!

start "BVN Logcat" cmd /k "%LOG_HELPER%"

echo.
echo =============================================
echo   Logcat window opened.
echo   If no new window, check TEMP: %TEMP%
echo =============================================
echo.
goto END

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:END
	echo.
	echo =============================================
	echo   Script finished. Press any key to exit.
	echo =============================================
	pause
	goto :EOF

:EXIST
if not exist %1 (
    call :ECHO_LANG :NOT_EXIST %1
    goto END
)
goto :EOF

:CHK_CMD
where %1 >nul 2>nul
if %errorlevel%==1 (
    call :ECHO_LANG :NO_CMD %1
    goto END
)
goto :EOF

:GET_DEVICE_ID
set "STRING=%~1"
set "DEVICE_ID=!STRING:	device=!"
goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:ECHO_LANG
for /f "tokens=2 delims=:" %%a in ('chcp') do (
    for /f "tokens=1" %%b in ("%%a") do set CURRENT_CODEPAGE=%%b
)

set SUPPORT_LANG=437 932 936 949
set IS_SUPPORT=0
for %%a in (%SUPPORT_LANG%) do (
    if "%%a"=="%CURRENT_CODEPAGE%" (
        set IS_SUPPORT=1
        goto LANG_CHK
    )
)
:LANG_CHK
if %IS_SUPPORT%==0 (
    set CURRENT_CODEPAGE=437
)

set LANG_BAT=%BAT_HOME%lang\%~n0\%CURRENT_CODEPAGE%.bat
if not exist "%LANG_BAT%" (
    echo ECHO_LANG [N/A]
    goto :EOF
)

call "%LANG_BAT%" %1 %2
goto :EOF
