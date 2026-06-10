@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Auto-detect AIR SDK (for adl.exe) ----
if not exist "%FLEX_HOME%\bin\adl.exe" (
    if exist "%PROJ%\AIRSDK\AIRSDK_33.1.1\bin\adl.exe" (
        set FLEX_HOME=%PROJ%\AIRSDK\AIRSDK_33.1.1
    )
)
set FLEX_BIN=%FLEX_HOME%\bin

if not exist "%FLEX_BIN%\adl.exe" (
    echo [ERROR] adl.exe not found.
    echo Set FLEX_HOME to AIR SDK root or ensure AIRSDK exists.
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
