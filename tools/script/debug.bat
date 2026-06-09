@echo off
setlocal enabledelayedexpansion
:: =============================================
:: BVN PC Debug Script
:: 编译 + adl 启动 launch.swf
:: =============================================

set BAT_HOME=%~dp0
set PROJ_HOME=%BAT_HOME%..\..

:: ---- Check FLEX_HOME ----
if "%FLEX_HOME%"=="" (
    echo [ERROR] FLEX_HOME not set. Point to AIR SDK root.
    echo Example: set FLEX_HOME=E:\BaiduNetdiskDownload\BVNY\AIRSDK5\AIRSDK_51.3.2
    goto END
)
set FLEX_BIN=%FLEX_HOME%\bin
set RUNTIME=%FLEX_HOME%\runtimes\air\win
if not exist "%FLEX_BIN%\adl.exe" (
    echo [ERROR] adl.exe not found at %FLEX_BIN%
    goto END
)

:: ---- Build ----
echo [BUILD] Compiling...
call "%PROJ_HOME%\build.bat"
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    goto END
)

:: ---- Launch via ADL ----
set SWF_FILE=%PROJ_HOME%\launch.swf
if not exist "%SWF_FILE%" (
    echo [ERROR] SWF not found: %SWF_FILE%
    goto END
)
set PATH=%FLEX_BIN%;%PATH%

echo [RUN] Starting via adl...
adl -runtime "%RUNTIME%" "%SWF_FILE%"

:END
pause >nul
