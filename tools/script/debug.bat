@echo off
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect FLEX_HOME ----
if "%FLEX_HOME%"=="" set FLEX_HOME=%PROJ%\flex4.16.1-air51.0.1.1
set FLEX_BIN=%FLEX_HOME%\bin
set RUNTIME=%FLEX_HOME%\runtimes\air\win

if not exist "%FLEX_BIN%\adl.exe" (
    echo [ERROR] adl.exe not found: %FLEX_BIN%
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
if not exist "%SWF_FILE%" (
    echo [ERROR] SWF not found: %SWF_FILE%
    pause >nul
    goto :EOF
)
set PATH=%FLEX_BIN%;%PATH%

echo [RUN] adl -runtime "%RUNTIME%" "%SWF_FILE%"
adl -runtime "%RUNTIME%" "%SWF_FILE%"

pause >nul
