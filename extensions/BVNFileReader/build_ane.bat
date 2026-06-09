@echo off
setlocal
:: =============================================
:: Build BVNFileReader ANE for BVN
:: =============================================
set PROJ=%~dp0
set SRC=%PROJ%Android\src
set LIB=%PROJ%Android\lib
set BUILD=%PROJ%build
set PLATFORM=Android-ARM

if exist "%BUILD%" rd /s /q "%BUILD%"
mkdir "%BUILD%\java"
mkdir "%BUILD%\%PLATFORM%"

:: ---- Compile Java ----
echo [1/3] Compiling Java...
javac -d "%BUILD%\java" -cp "%LIB%\FlashRuntimeExtensions.jar" -sourcepath "%SRC%" "%SRC%\com\bvn\filereader\*.java"
if %errorlevel% neq 0 (
    echo [ERROR] Java compile failed.
    pause & exit 1
)

:: ---- Package JAR ----
echo [2/3] Packaging JAR...
cd "%BUILD%\java"
jar cf "%BUILD%\%PLATFORM%\BVNFileReader.jar" .
cd "%PROJ%"

:: ---- Package ANE ----
echo [3/3] Packaging ANE...
call adt -package -target ane "%PROJ%BVNFileReader.ane" "%PROJ%extension.xml" -platform %PLATFORM% -C "%BUILD%\%PLATFORM%\" .
if %errorlevel%==0 (
    echo [OK] %PROJ%BVNFileReader.ane
) else (
    echo [ERROR] ANE package failed. Ensure adt is in PATH (set FLEX_HOME).
)

pause
