::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Copyright (C) 2021-2026, 5DPLAY Game Studio
:: All rights reserved.
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Usage:
::   debug_mob.bat            minimal one-click test package (default)
::   debug_mob.bat min        same as above
::   debug_mob.bat full       full package  -> tools\Test\bvn.apk
::   debug_mob.bat restore    re-attach the device's external assets dir
::
:: Why two package shapes
:: ----------------------
:: The APK carries NO fighter/face/map/bgm files: every character, map and BGM
:: is read from the phone's external dir. What decides how long the selection
:: list is, is the APK's *built-in* config (fighter.xml 659 / select.xml 606 /
:: map.xml 146), and GameLoader.appendMissingExternalFightersToSelect()
:: (GameLoader.as:411) re-appends every fighter missing from the select list.
:: Trimming the external dir alone therefore changes nothing.
::
:: "min" therefore packages a purpose-built minimal config + assets
:: (tools\Test\min_assets, produced by tools\Test\build_min_assets.py) and
:: renames the device's external assets dir aside, so the running game is
:: fully defined by the APK: 2 fighters / 2 assists / 2 maps / 2 battle BGMs.
:: The rename is reversible and never deletes user files.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set BAT_HOME=%~dp0
set PROJ=%BAT_HOME%..\..

:: ---- Mode ----
set "MODE=%~1"
if "%MODE%"=="" set "MODE=min"
if /i "%MODE%"=="min"     goto MODE_OK
if /i "%MODE%"=="full"    goto MODE_OK
if /i "%MODE%"=="restore" goto MODE_OK
echo [ERROR] unknown mode: %MODE%
echo   usage: debug_mob.bat [min ^| full ^| restore]
goto END
:MODE_OK

call :ECHO_LANG :TITLE ""

:: ---- Auto-detect or verify FLEX_HOME ----
:: Always prefer local SDK over environment variable
set "SDK_HOME=%PROJ%\flex4.16.1-air51.0.1.1"
set "FALLBACK=%PROJ%\AIRSDK_51.1.2"

if exist "%SDK_HOME%\bin\fdb.bat" (
    set "FLEX_HOME=%SDK_HOME%"
    echo [AUTO] FLEX_HOME detected: !FLEX_HOME!
    goto FLEX_OK
)
if exist "%FALLBACK%\bin\fdb.bat" (
    set "FLEX_HOME=%FALLBACK%"
    echo [AUTO] FLEX_HOME fallback: !FLEX_HOME!
    goto FLEX_OK
)
call :ECHO_LANG :UNDEFINE "FLEX_HOME"
echo   Set it via: setx FLEX_HOME "E:\BaiduNetdiskDownload\BVNY\AIRSDK\flex4.16.1-air51.0.1.1"
goto END
:FLEX_OK
call :EXIST "%FLEX_HOME%" || goto END
echo FLEX_HOME: %FLEX_HOME%

set FLEX_BIN=%FLEX_HOME%\bin
call :EXIST "%FLEX_BIN%" || goto END

set "ADT=%FLEX_BIN%\adt.bat"
set "CERT=%FLEX_BIN%\mycert.p12"

:: ---- Signing password: optional, defaults to the bundled one for one-click packaging ----
:: BVN_KEYSTORE_PASS (when set) always wins; otherwise fall back to the default below,
:: restoring the pre-refactor one-click behavior (password was historically hardcoded here).
if not defined BVN_KEYSTORE_PASS set "BVN_KEYSTORE_PASS=yinyu7798"

:: ---- Auto-detect Android SDK ----
set "ANDROID_SDK="
for %%d in ("D:\Android\SDK" "C:\Android\SDK" "E:\Android\SDK" "%ANDROID_HOME%") do (
    if exist %%d\platforms (
        if not defined ANDROID_SDK set "ANDROID_SDK=%%~d"
    )
)
if not defined ANDROID_SDK (
    echo [ERROR] Android SDK not found! Set ANDROID_HOME or place SDK at D:\Android\SDK
    goto END
)
echo [AUTO] ANDROID_SDK: %ANDROID_SDK%

set "PLATFORM_TOOLS=%PROJ%\tools\platform-tools"
set "PATH=%PLATFORM_TOOLS%;%FLEX_BIN%;%PATH%"

:: ---- Paths ----
set "TEST_DIR=%PROJ%\tools\Test"
set "SWF_FILE=%TEST_DIR%\launch.swf"
set "APP_XML=%TEST_DIR%\application.xml"
set "MIN_DIR=%TEST_DIR%\min_assets"

:: ---- App info ----
set DBG_ID=com.bvn.yy798
set DBG_PACKAGE=air.%DBG_ID%
set DBG_PORT=7936

:: External assets root owned by the app (ANEFileReader.EXTERNAL_BASE minus "assets/").
:: Directory creation there is allowed without any permission (2026-10-09 device test).
set "EXT_ROOT=/storage/emulated/0/Android/media/%DBG_PACKAGE%/BVN"

:: ---- ADB must be reachable before anything else (restore mode needs it, and so does install) ----
call :CHK_CMD adb || goto END
adb start-server >nul 2>nul
:: ping instead of timeout: timeout aborts when stdin is redirected, silently
:: skipping the wait between am force-stop and the assets rename.
ping -n 3 127.0.0.1 >nul

:: ---- Find device ----
set TMP_ADB_DEVICES=%TEMP%\adb_devices.txt
adb devices >"%TMP_ADB_DEVICES%"

set DEVICE_COUNT=0
set "DEVICE_ID="
for /f "usebackq skip=1 delims=" %%L in ("%TMP_ADB_DEVICES%") do (
    set "LINE=%%L"
    echo !LINE! | findstr "device" >nul
    if !errorlevel!==0 (
        set /a DEVICE_COUNT+=1
        call :GET_DEVICE_ID "!LINE!"
        goto :NEXT
    )
)

:NEXT
set PATH=%FLEX_BIN%;%PATH%
del "%TMP_ADB_DEVICES%" >nul 2>nul

if !DEVICE_COUNT!==0 (
    call :ECHO_LANG :NO_DEVICE ""
    if /i "%MODE%"=="restore" goto END
    echo [WARN] No device: packaging will still run, install will be skipped.
)

:: ---- restore exits here (no build, no package) ----
if /i "%MODE%"=="restore" (
    if !DEVICE_COUNT! neq 0 call :SWAP_RESTORE
    goto END
)

echo.
echo =============================================
echo   MODE: %MODE%
echo =============================================

:: ---- APK target name (full keeps the release artifact name) ----
set "APK_FILE=%TEST_DIR%\bvn_min.apk"
if /i "%MODE%"=="full" set "APK_FILE=%TEST_DIR%\bvn.apk"
echo [MODE] output: %APK_FILE%

:: ---- Build SWF ----
call :ECHO_LANG :BUILD_MSG ""
call "%PROJ%\build.bat"
if %errorlevel% neq 0 (
    call :ECHO_LANG :BUILD_FAIL ""
    goto END
)
call :EXIST "%SWF_FILE%" || goto END
call :EXIST "%APP_XML%" || goto END

:: ---- Package APK ----
call :ECHO_LANG :PACKAGE_MSG ""
call :EXIST "%ADT%" || goto END
cd /d "%TEST_DIR%"

if /i "%MODE%"=="min" goto PACK_MIN

:: ================= full package =================
:: ---- Pre-check: every packaged path must exist, otherwise ADT prints usage and exits 2 ----
:: Historical failures this guard catches early:
::   1. ExternalSample.swf/.png were moved out of assets/ to tools\Test\external-sample\;
::      stale -C entries made ADT fail with "no such file" + usage dump -> exit 2.
::   2. assets\config\ packed as a whole directory hits backup\trash_unused\*.png
::      (1388 files, 540 with CJK names) -> ADT exit 12.
::      Only the 7 runtime-consumed XMLs are packed instead. (backup/ is user data - not deleted.)
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
if %PACK_MISSING%==1 (
    echo [ERROR] One or more packaged paths are missing. Fix the whitelist above.
    call :ECHO_LANG :PACKAGE_FAIL ""
    goto END
)

:: ---- Whitelist: effect.swf + movelist.jpg + sounds/ + font/ + 7 runtime config XMLs ----
:: NOTE: a single -C . precedes ALL file args. Multiple -C flags each reset the base dir,
::       so "-C . a\b.xml -C . b.xml" resolves the second against "." and fails "no such file".
call "%ADT%" -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%CERT%" -storepass "%BVN_KEYSTORE_PASS%" "bvn.apk" "application.xml" -platformsdk "%ANDROID_SDK%" -extdir "%TEST_DIR%" "launch.swf" -C . assets\effect.swf assets\movelist.jpg assets\sounds assets\font assets\config\preload.xml assets\config\fighter.xml assets\config\assist.xml assets\config\select.xml assets\config\salect.xml assets\config\map.xml assets\config\mission.xml
set ADT_RESULT=%errorlevel%
goto PACK_DONE

:: ================= minimal package =================
:PACK_MIN
if not exist "%MIN_DIR%\assets\config\select.xml" (
    echo [MIN] min_assets not found - trying to generate it...
    pushd "%TEST_DIR%"
    python build_min_assets.py
    popd
)
if not exist "%MIN_DIR%\assets\config\select.xml" (
    echo [ERROR] %MIN_DIR% is missing.
    echo         Generate it first:  cd tools\Test ^&^& python build_min_assets.py
    call :ECHO_LANG :PACKAGE_FAIL ""
    goto END
)

set PACK_MISSING=0
for %%f in (
    "min_assets\assets\effect.swf"
    "min_assets\assets\movelist.jpg"
    "min_assets\assets\sounds"
    "min_assets\assets\font"
    "min_assets\assets\config"
    "min_assets\assets\fighter"
    "min_assets\assets\face"
    "min_assets\assets\map"
    "min_assets\assets\bgm"
) do (
    if not exist "%%~f" (
        echo [ERROR] Packaged path missing: %%~f
        set PACK_MISSING=1
    )
)
if %PACK_MISSING%==1 (
    echo [ERROR] Minimal payload incomplete. Re-run: python tools\Test\build_min_assets.py
    call :ECHO_LANG :PACKAGE_FAIL ""
    goto END
)

:: Every directory below is already minimal inside min_assets, and every file name is
:: ASCII-only (ADT rejects non-ASCII asset names - measured exit 12).
call "%ADT%" -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%CERT%" -storepass "%BVN_KEYSTORE_PASS%" "bvn_min.apk" "application.xml" -platformsdk "%ANDROID_SDK%" -extdir "%TEST_DIR%" "launch.swf" -C min_assets assets\effect.swf assets\movelist.jpg assets\sounds assets\font assets\config assets\fighter assets\face assets\map assets\bgm
set ADT_RESULT=%errorlevel%

:PACK_DONE
if %ADT_RESULT% neq 0 (
    echo [ERROR] ADT packaging failed with code %ADT_RESULT%
    call :ECHO_LANG :PACKAGE_FAIL ""
    goto END
)
call :EXIST "%APK_FILE%" || goto END
for %%A in ("%APK_FILE%") do echo [OK] APK: %%~nxA  %%~zA bytes  %%~tA

if !DEVICE_COUNT!==0 goto END

echo.
call :ECHO_LANG :TITLE_ADB "!DEVICE_ID!"
call :ECHO_LANG :CONNECT "!DEVICE_ID!"

:: ---- Minimal mode: detach external assets so the APK fully defines the game ----
if /i "%MODE%"=="min" (
    call :SWAP_MIN
    if !errorlevel! neq 0 goto END
)

:: ---- Install: ALWAYS force-overwrite, so the phone really runs this build ----
:: (The previous "skip install when the package is already present" branch meant the
::  device kept running an old APK while the script reported success.)
echo [ADB] Installing (force overwrite) ...
adb -s "!DEVICE_ID!" install -r "%APK_FILE%"
if !errorlevel! neq 0 (
    echo [WARN] install -r failed, retrying with -r -d ...
    adb -s "!DEVICE_ID!" install -r -d "%APK_FILE%"
    if !errorlevel! neq 0 (
        echo [ERROR] Install failed. If the signature changed, uninstall first:
        echo         adb uninstall %DBG_PACKAGE%
        goto END
    )
)

adb -s "!DEVICE_ID!" shell am force-stop %DBG_PACKAGE% >nul
adb -s "!DEVICE_ID!" shell am start -n %DBG_PACKAGE%/.AppEntry >nul

:: ---- Launch persistent logcat console ----
set "LOG_HELPER=%TEMP%\bvn_logcat_console.bat"
(
    echo @echo off
    echo chcp 65001 ^>nul
    echo title BVN Logcat
    echo echo.
    echo echo =============================================
    echo echo   BVN Logcat - real-time trace output
    echo echo =============================================
    echo echo.
    echo echo Starting logcat... Ctrl+C to stop
    echo echo Filter: air bvn trace flash DEBUG
    echo echo.
    echo adb -s "!DEVICE_ID!" logcat -v time ^| findstr /i "air bvn trace flash DEBUG"
    echo echo.
    echo echo Logcat stopped. Close this window or press any key.
    echo pause
) > "%LOG_HELPER%"

start "BVN Logcat" cmd /k "%LOG_HELPER%"

echo.
echo =============================================
echo   Logcat window opened.
echo   If no new window, check TEMP: %TEMP%
if /i "%MODE%"=="min" echo   External assets are detached. Restore:  debug_mob.bat restore
echo =============================================
echo.
goto END

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:END
	echo.
	echo =============================================
	echo   Script finished. Press any key to exit.
	echo =============================================
	pause
	goto :EOF

:EXIST
:: NOTE: must `exit /b`, not `goto END`. Inside a called subroutine `goto END` only
:: prints the footer and hands control back to the caller, which then keeps running
:: with unset variables. Callers use `call :EXIST "x" || goto END`.
if not exist %1 (
    call :ECHO_LANG :NOT_EXIST %1
    exit /b 1
)
exit /b 0

:CHK_CMD
:: See the :EXIST note above - same reason.
where %1 >nul 2>nul
if %errorlevel%==1 (
    call :ECHO_LANG :NO_CMD %1
    exit /b 1
)
exit /b 0

:GET_DEVICE_ID
set "STRING=%~1"
set "DEVICE_ID=!STRING:	device=!"
goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  External assets swap (reversible rename only - never deletes user files)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:SWAP_MIN
echo.
echo [MIN] Detaching external assets (assets -^> assets_full) ...
adb -s "!DEVICE_ID!" shell am force-stop %DBG_PACKAGE% >nul 2>nul
ping -n 2 127.0.0.1 >nul

set "SWAP_STATE="
for /f "usebackq delims=" %%R in (`adb -s "!DEVICE_ID!" shell "if [ -d %EXT_ROOT%/assets_full ]; then echo ALREADY; else echo CLEAR; fi"`) do set "SWAP_STATE=%%R"

if /i "!SWAP_STATE!"=="ALREADY" (
    :: Re-running "min" is the normal iteration loop: the first run moved assets aside,
    :: and the app then re-created an empty assets/ skeleton. That is exactly the state
    :: we want, so only bail out when assets/ unexpectedly holds files again.
    set "LEFTOVER="
    for /f "usebackq delims=" %%R in (`adb -s "!DEVICE_ID!" shell "find %EXT_ROOT%/assets -type f -print -quit 2>/dev/null"`) do set "LEFTOVER=%%R"
    if defined LEFTOVER (
        echo [ERROR] Ambiguous state: assets_full exists AND assets/ still holds files:
        echo         !LEFTOVER!
        echo         Inspect manually, or run:  tools\script\debug_mob.bat restore
        exit /b 1
    )
    echo [MIN] External assets already detached - continuing.
    exit /b 0
)

adb -s "!DEVICE_ID!" shell "mv %EXT_ROOT%/assets %EXT_ROOT%/assets_full" 2>nul
if !errorlevel! neq 0 (
    echo [MIN] No external assets dir on device - nothing to detach.
) else (
    echo [MIN] assets -^> assets_full ^(reversible^)
)
exit /b 0

:SWAP_RESTORE
echo.
echo [RESTORE] Re-attaching external assets ...
adb -s "!DEVICE_ID!" shell am force-stop %DBG_PACKAGE% >nul 2>nul
ping -n 2 127.0.0.1 >nul

set "RESTORE_STATE="
for /f "usebackq delims=" %%R in (`adb -s "!DEVICE_ID!" shell "if [ -d %EXT_ROOT%/assets_full ]; then echo YES; else echo NO; fi"`) do set "RESTORE_STATE=%%R"

if /i "!RESTORE_STATE!"=="NO" (
    echo [RESTORE] Nothing to restore ^(assets_full not found^).
    exit /b 0
)

:: The app re-creates an empty assets/ skeleton on every launch. Only remove it when it
:: provably holds no files; otherwise rename it aside and report the path.
set "FIRSTFILE="
for /f "usebackq delims=" %%R in (`adb -s "!DEVICE_ID!" shell "find %EXT_ROOT%/assets -type f -print -quit 2>/dev/null"`) do set "FIRSTFILE=%%R"

if defined FIRSTFILE (
    echo [WARN] %EXT_ROOT%/assets still holds files; keeping them as assets.app_generated
    adb -s "!DEVICE_ID!" shell "mv %EXT_ROOT%/assets %EXT_ROOT%/assets.app_generated" 2>nul
) else (
    adb -s "!DEVICE_ID!" shell "rm -rf %EXT_ROOT%/assets" 2>nul
)

adb -s "!DEVICE_ID!" shell "mv %EXT_ROOT%/assets_full %EXT_ROOT%/assets" 2>nul
if !errorlevel! neq 0 (
    echo [ERROR] Failed to move assets_full back to assets.
    exit /b 1
)
echo [RESTORE] assets_full -^> assets
exit /b 0

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:ECHO_LANG
for /f "tokens=2 delims=:" %%a in ('chcp') do (
    for /f "tokens=1" %%b in ("%%a") do set CURRENT_CODEPAGE=%%b
)

set SUPPORT_LANG=437 932 936 949
set IS_SUPPORT=0
for %%a in (%SUPPORT_LANG%) do (
    if "%%a"=="%CURRENT_CODEPAGE%" (
        set IS_SUPPORT=1
        goto LANG_CHK
    )
)
:LANG_CHK
if %IS_SUPPORT%==0 (
    set CURRENT_CODEPAGE=437
)

set LANG_BAT=%BAT_HOME%lang\%~n0\%CURRENT_CODEPAGE%.bat
if not exist "%LANG_BAT%" (
    echo ECHO_LANG [N/A]
    goto :EOF
)

call "%LANG_BAT%" %1 %2
goto :EOF
