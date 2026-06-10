@echo off
chcp 65001 >/dev/null
set AIR_LIB=E:\BaiduNetdiskDownload\BVNY\AIRSDK5\AIRSDK_51.3.2\libndroid\FlashRuntimeExtensions.jar
set ANE_DIR=E:\BaiduNetdiskDownload\BVNY	oolsne
set ADT=E:\BaiduNetdiskDownload\BVNY\AIRSDK5\AIRSDK_51.3.2indt.bat
set OUT_ANE=E:\BaiduNetdiskDownload\BVNY	ools\Test\ANEFileReader.ane

echo ========================================
echo   Build ANE: com.bvn.filereader
echo ========================================

echo [1/3] Compiling Java...
if not exist "%AIR_LIB%" ( echo [ERROR] %AIR_LIB% not found & pause & exit /b 1 )
if exist "%ANE_DIR%\classes" rmdir /s /q "%ANE_DIR%\classes"
mkdir "%ANE_DIR%\classes"
javac -cp "%AIR_LIB%" -d "%ANE_DIR%\classes" "%ANE_DIR%ndroid\*.java"
if %errorlevel% neq 0 ( echo [ERROR] Compile failed & pause & exit /b 1 )
echo [OK] Java compiled

echo [2/3] Creating JAR...
cd /d "%ANE_DIR%\classes"
jar cf "%ANE_DIR%\ANEFileReader.jar" .
cd /d "%ANE_DIR%"
rmdir /s /q "%ANE_DIR%\classes"
echo [OK] JAR created

echo [3/3] Packaging ANE...
call "%ADT%" -package -target ane "%OUT_ANE%" "%ANE_DIR%\extension.xml" -platform Android-ARM -C "%ANE_DIR%" ANEFileReader.jar
if %errorlevel% neq 0 ( echo [ERROR] ANE failed & pause & exit /b 1 )
echo [OK] ANE: %OUT_ANE%

echo.
echo === ANE built successfully! ===
echo Now run debug_mob.bat to package with ANE.
pause
