@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: pack_only.bat —— 只编译 + 打包，**绝不碰真机**（2026-11-12）
::
:: 为什么需要它
::   debug_mob.bat full 打完包会自动挑一台设备安装，而 adb 会优先挑到 USB
::   连着的真机（V2073A / 306383853300549），于是真机上弹安装框、报
::   INSTALL_FAILED_ABORTED: User rejected permissions。日常验证一律用 MuMu，
::   真机只在用户明确要安装包时才涉及。
::
:: 用法
::   pack_only.bat            只编译 + 打 tools\Test\bvn.apk
::   pack_only.bat mumu       打完顺手装到 MuMu（127.0.0.1:16416）
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..
set FLEX_HOME=%PROJ%\flex4.16.1-air51.0.1.1
set FLEX_BIN=%FLEX_HOME%\bin
set "ADT=%FLEX_BIN%\adt.bat"
set "CERT=%FLEX_BIN%\mycert.p12"
if not defined BVN_KEYSTORE_PASS set "BVN_KEYSTORE_PASS=yinyu7798"

set "ANDROID_SDK="
for %%d in ("D:\Android\SDK" "C:\Android\SDK" "E:\Android\SDK" "%ANDROID_HOME%") do (
    if exist %%d\platforms (
        if not defined ANDROID_SDK set "ANDROID_SDK=%%~d"
    )
)
if not defined ANDROID_SDK (
    echo [ERROR] Android SDK not found
    exit /b 1
)

set "PLATFORM_TOOLS=%PROJ%\tools\platform-tools"
set "PATH=%PLATFORM_TOOLS%;%FLEX_BIN%;%PATH%"
set "TEST_DIR=%PROJ%\tools\Test"

:: ---- 1) 编译 ----
call "%PROJ%\build.bat"
if errorlevel 1 (
    echo [ERROR] build failed
    exit /b 1
)

:: ---- 2) 打包（工作目录必须是 tools\Test，-C . 依赖相对路径）----
cd /d "%TEST_DIR%"
set PACK_MISSING=0
for %%f in (
    "assets\effect.swf"
    "assets\movelist.jpg"
    "assets\sounds"
    "assets\font"
    "assets\config\preload.xml"
    "assets\config\fighter.xml"
    "assets\config\assist.xml"
    "assets\config\select.xml"
    "assets\config\salect.xml"
    "assets\config\map.xml"
    "assets\config\mission.xml"
) do (
    if not exist "%%~f" (
        echo [ERROR] Packaged path missing: %%~f
        set PACK_MISSING=1
    )
)
if %PACK_MISSING%==1 exit /b 1

call "%ADT%" -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%CERT%" -storepass "%BVN_KEYSTORE_PASS%" "bvn.apk" "application.xml" -platformsdk "%ANDROID_SDK%" -extdir "%TEST_DIR%" "launch.swf" -C . assets\effect.swf assets\movelist.jpg assets\sounds assets\font assets\config\preload.xml assets\config\fighter.xml assets\config\assist.xml assets\config\select.xml assets\config\salect.xml assets\config\map.xml assets\config\mission.xml
if errorlevel 1 (
    echo [ERROR] package failed
    exit /b 1
)
echo [OK] APK: %TEST_DIR%\bvn.apk

:: ---- 3) 可选：只装 MuMu，永不装真机 ----
if /i "%~1"=="mumu" (
    echo [MUMU] installing to 127.0.0.1:16416 ...
    adb -s 127.0.0.1:16416 install -r "%TEST_DIR%\bvn.apk"
)
endlocal