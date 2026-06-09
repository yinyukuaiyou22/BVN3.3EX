@echo off
setlocal enabledelayedexpansion
:: =============================================
:: BVN PC Debug Script
:: 编译 + 启动 launch.swf
:: =============================================

set BAT_HOME=%~dp0
set PROJ_HOME=%BAT_HOME%..\..

:: ---- Build SWF first ----
echo [BUILD] Compiling...
call "%PROJ_HOME%\build.bat"
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    pause >nul
    exit 1
)

:: ---- Check SWF ----
set SWF_FILE=%PROJ_HOME%\launch.swf
if not exist "%SWF_FILE%" (
    echo [ERROR] SWF not found: %SWF_FILE%
    pause >nul
    exit 1
)

:: ---- Launch ----
echo [RUN] Starting %SWF_FILE% ...
start "" "%SWF_FILE%"

echo.
echo Game launched. Close this window or press any key to exit.
pause >nul
