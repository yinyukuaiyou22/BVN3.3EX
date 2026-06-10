@echo off
chcp 65001 >nul
echo ========================================
echo   Build ANE: com.bvn.filereader
echo ========================================

set ANE_DIR=%~dp0
set AIR_LIB=%FLEX_HOME%\lib\android

:: Step 1: Compile Java sources against AIR FRE classes
echo [1/3] Compiling Java...
javac -cp "%AIR_LIB%\FlashRuntimeExtensions.jar" -d "%ANE_DIR%classes" "%ANE_DIR%android\*.java"
if %errorlevel% neq 0 (
    echo [ERROR] Java compilation failed
    pause & exit /b 1
)
echo [OK] Java compiled

:: Step 2: Package into JAR
echo [2/3] Creating JAR...
cd /d "%ANE_DIR%classes"
jar cf "%ANE_DIR%ANEFileReader.jar" .
cd /d "%ANE_DIR%"
rmdir /s /q "%ANE_DIR%classes"
echo [OK] JAR created

:: Step 3: Package ANE
echo [3/3] Packaging ANE...
set ADT=%FLEX_HOME%\bin\adt.bat
"%ADT%" -package -target ane "%ANE_DIR%..\..\tools\Test\ANEFileReader.ane" "%ANE_DIR%extension.xml" -platform Android-ARM -C "%ANE_DIR%" ANEFileReader.jar
if %errorlevel% neq 0 (
    echo [ERROR] ANE packaging failed
    pause & exit /b 1
)
echo [OK] ANE created: tools\Test\ANEFileReader.ane

echo.
echo ========================================
echo   Done! ANE ready.
echo ========================================
pause
