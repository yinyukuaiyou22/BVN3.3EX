@echo off
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect AIR SDK (for fdb.bat) ----
if not exist "%FLEX_HOME%\bin\fdb.bat" (
    if exist "%PROJ%\AIRSDK5\AIRSDK_51.3.2\bin\fdb.bat" (
        set FLEX_HOME=%PROJ%\AIRSDK5\AIRSDK_51.3.2
    )
)
set FLEX_BIN=%FLEX_HOME%\bin

if not exist "%FLEX_BIN%\fdb.bat" (
    echo [ERROR] fdb.bat not found.
    echo Set FLEX_HOME to AIR SDK root or ensure AIRSDK5 exists.
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
