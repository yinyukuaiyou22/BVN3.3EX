@echo off
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect FLEX_HOME ----
if "%FLEX_HOME%"=="" set FLEX_HOME=%PROJ%\flex4.16.1-air51.0.1.1
set FLEX_BIN=%FLEX_HOME%\bin

if not exist "%FLEX_BIN%\fdb.bat" (
    echo [ERROR] fdb.bat not found: %FLEX_BIN%
    pause >nul
    goto :EOF
)

:: ---- SWF argument ----
if "%~1"=="" (
    set SWF_FILE=%PROJ%\launch.swf
) else (
    set SWF_FILE=%~1
)
if not exist "%SWF_FILE%" (
    echo [ERROR] SWF not found: %SWF_FILE%
    echo Usage: %~nx0 [swf_file]
    pause >nul
    goto :EOF
)

echo FLEX_HOME: %FLEX_HOME%
echo Target: %SWF_FILE%
echo.

set PATH=%FLEX_BIN%;%PATH%

(
    echo run "%SWF_FILE%"
    echo continue
) | fdb -unit

exit /b 0
