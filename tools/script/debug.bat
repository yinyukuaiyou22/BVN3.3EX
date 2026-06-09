@echo off
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect AIR SDK (for adl.exe) ----
if not exist "%FLEX_HOME%\bin\adl.exe" (
    if exist "%PROJ%\AIRSDK5\AIRSDK_51.3.2\bin\adl.exe" (
        set FLEX_HOME=%PROJ%\AIRSDK5\AIRSDK_51.3.2
    )
)
set FLEX_BIN=%FLEX_HOME%\bin

if not exist "%FLEX_BIN%\adl.exe" (
    echo [ERROR] adl.exe not found.
    echo Set FLEX_HOME to AIR SDK root or ensure AIRSDK5 exists.
    pause >nul
    goto :EOF
)

:: ---- Build ----
echo [BUILD] Compiling...
call "%PROJ%\build.bat"
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    pause >nul
    goto :EOF
)

:: ---- Launch via ADL ----
set SWF_FILE=%PROJ%\launch.swf
set TEST_DIR=%PROJ%\tools\Test
set APP_XML=%TEST_DIR%\application.xml

if not exist "%SWF_FILE%" (
    echo [ERROR] SWF not found: %SWF_FILE%
    pause >nul
    goto :EOF
)

:: Copy SWF to Test dir (required by application.xml content path)
copy /Y "%SWF_FILE%" "%TEST_DIR%\launch.swf" >nul

set PATH=%FLEX_BIN%;%PATH%

echo [RUN] adl "%APP_XML%"
adl "%APP_XML%"

pause >nul
