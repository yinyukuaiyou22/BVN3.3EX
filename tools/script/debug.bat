@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect AIR SDK (for adl.exe) ----
:: Always prefer local SDK over environment variable
set "SDK_HOME=%PROJ%\AIRSDK\flex4.16.1-air51.0.1.1"
set "FALLBACK=%PROJ%\AIRSDK\AIRSDK_51.1.2"

if exist "%SDK_HOME%\bin\adl.exe" (
    set "FLEX_HOME=%SDK_HOME%"
) else if exist "%FALLBACK%\bin\adl.exe" (
    set "FLEX_HOME=%FALLBACK%"
)
set FLEX_BIN=%FLEX_HOME%\bin

if not exist "%FLEX_BIN%\adl.exe" (
    echo [ERROR] adl.exe not found at %FLEX_BIN%\adl.exe
    echo Ensure the AIR SDK is at %SDK_HOME% or set FLEX_HOME.
    pause
    goto END
)

:: ---- Build ----
echo [BUILD] Compiling...
call "%PROJ%\build.bat"
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    pause
    goto END
)

:: ---- Launch via ADL ----
set SWF_FILE=%PROJ%\tools\Test\launch.swf
set APP_XML=%PROJ%\tools\Test\application.xml

if not exist "%SWF_FILE%" (
    echo [ERROR] SWF not found: %SWF_FILE%
    pause
    goto END
)

set PATH=%FLEX_BIN%;%PATH%

echo [RUN] adl "%APP_XML%"
adl "%APP_XML%"

:END
pause
goto :EOF
