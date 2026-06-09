@echo off
setlocal enabledelayedexpansion
:: =============================================
:: fdbg - Flex Debugger for any SWF
:: Usage: fdbg.bat [path\to\file.swf]
:: =============================================

:: ---- Check FLEX_HOME ----
if "%FLEX_HOME%"=="" (
    echo [ERROR] FLEX_HOME not set. Point to AIR SDK root.
    echo Example: set FLEX_HOME=E:\BaiduNetdiskDownload\BVNY\AIRSDK5\AIRSDK_51.3.2
    goto END
)
set FLEX_BIN=%FLEX_HOME%\bin
if not exist "%FLEX_BIN%\fdb.bat" (
    echo [ERROR] fdb.bat not found at %FLEX_BIN%
    goto END
)

:: ---- SWF argument ----
if "%~1"=="" (
    set SWF_FILE=%~dp0..\..\launch.swf
) else (
    set SWF_FILE=%~1
)
if not exist "%SWF_FILE%" (
    echo [ERROR] SWF not found: %SWF_FILE%
    echo Usage: %~nx0 [swf_file]
    goto END
)

echo FLEX_HOME: %FLEX_HOME%
echo Target: %SWF_FILE%
echo.

set PATH=%FLEX_BIN%;%PATH%

(
    echo run "%SWF_FILE%"
    echo continue
) | fdb -unit

:END
exit /b 0
