@echo off
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect AIR SDK (for fdb.bat) ----
set "SDK_HOME=%PROJ%\AIRSDK\flex4.16.1-air51.0.1.1"
if not defined FLEX_HOME set "FLEX_HOME=%SDK_HOME%"
if not exist "%FLEX_HOME%\bin\fdb.bat" (
    if exist "%SDK_HOME%\bin\fdb.bat" (
        set "FLEX_HOME=%SDK_HOME%"
    )
)
set FLEX_BIN=%FLEX_HOME%\bin

if not exist "%FLEX_BIN%\fdb.bat" (
    echo [ERROR] fdb.bat not found at %FLEX_BIN%\fdb.bat
    echo Ensure the AIR SDK is at %SDK_HOME% or set FLEX_HOME.
    pause
    goto END
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
    pause
    goto END
)

echo AIR SDK: %FLEX_HOME%
echo Target: %SWF_FILE%
echo.

set PATH=%FLEX_BIN%;%PATH%

(
    echo run "%SWF_FILE%"
    echo continue
) | fdb -unit

goto END

:END
pause
goto :EOF
