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
if not "%FLEX_HOME%"=="" goto FLEX_OK
if exist "%PROJ%\AIRSDK5\AIRSDK_51.3.2\bin\fdb.bat" (
    set "FLEX_HOME=%PROJ%\AIRSDK5\AIRSDK_51.3.2"
    echo [AUTO] FLEX_HOME detected: !FLEX_HOME!
    goto FLEX_OK
)
:: Last resort: check common paths
for %%d in (
    "C:\AIRSDK5\AIRSDK_51.3.2"
    "D:\AIRSDK5\AIRSDK_51.3.2"
    "E:\AIRSDK5\AIRSDK_51.3.2"
) do (
    if exist %%d\bin\fdb.bat (
        set "FLEX_HOME=%%~d"
        echo [AUTO] FLEX_HOME found: !FLEX_HOME!
        goto FLEX_OK
    )
)
call :ECHO_LANG :UNDEFINE "FLEX_HOME"
echo   Set it via: setx FLEX_HOME "E:\BaiduNetdiskDownload\BVNY\AIRSDK5\AIRSDK_51.3.2"
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
set "APK_FILE=%TEST_DIR%\死神vs火影银鱼改.apk"

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
:: Include ANE if present (check multiple locations)
set "ANE_EXTDIR="
set "ANE_FILE="
if exist "%TEST_DIR%\BVNFileReader.ane" (
    set "ANE_FILE=%TEST_DIR%\BVNFileReader.ane"
    set "ANE_EXTDIR=-extdir %TEST_DIR%"
)
if exist "%PROJ%\extensions\BVNFileReader\BVNFileReader.ane" (
    set "ANE_FILE=%PROJ%\extensions\BVNFileReader\BVNFileReader.ane"
    set "ANE_EXTDIR=-extdir %PROJ%\extensions\BVNFileReader"
)
if "%ANE_EXTDIR%"=="" (
    echo [WARN] BVNFileReader.ane NOT FOUND - ANE will NOT be included.
    echo   Build it: extensions\BVNFileReaderuild_ane.bat
    echo   Place it: tools\Test\BVNFileReader.ane
) else (
    echo [ANE] Found: !ANE_FILE!
)

:: ---- Slim APK: backup heavy content, create empty dir placeholders ----
for %%D in (fighter map face bgm) do (
    :: recover dangling backup from previous interrupted run
    if exist "assets\_bakslim_%%D" (
        if exist "assets\%%D\.gdummy" del "assets\%%D\.gdummy"
        if exist "assets\%%D" rd /s /q "assets\%%D"
        ren "assets\_bakslim_%%D" "%%D"
    )
    if exist "assets\%%D" (
        ren "assets\%%D" "_bakslim_%%D"
        mkdir "assets\%%D"
        echo. > "assets\%%D\.gdummy"
    )
)

"%ADT%" -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%CERT%" -storepass yinyu7798 %ANE_EXTDIR% "死神vs火影银鱼改.apk" "application.xml" "launch.swf" -C . assets
	set ADT_RESULT=%errorlevel%

	:: ---- Restore backed-up content dirs (ALWAYS run, even on ADT failure) ----
	for %%D in (fighter map face bgm) do (
	    if exist "assets\%%D\.gdummy" del "assets\%%D\.gdummy"
	    if exist "assets\%%D" rd "assets\%%D"
	    if exist "assets\_bakslim_%%D" ren "assets\_bakslim_%%D" "%%D"
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
exit /b

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
