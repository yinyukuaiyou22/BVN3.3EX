@echo off
chcp 65001 >nul 2>nul
setlocal enabledelayedexpansion
REM =============================================
REM Build BVNFileReader ANE for BVN
REM Full pipeline: Java - JAR - SWC - ANE - Copy to Test
REM =============================================
set PROJ=%~dp0
set SRC=%PROJ%Android\src
set LIB=%PROJ%Android\lib
set AS3=%PROJ%as3
set BUILD=%PROJ%build
set PLATFORM=Android-ARM64

REM ---- Env checks ----
REM JDK 8 required for d8 compatibility
set JAVA_HOME=
for %%d in ("D:\JDK8") do (
    if exist %%d\bin\javac.exe set JAVA_HOME=%%~d
)
if not defined JAVA_HOME (
    echo [ERROR] JDK 8 not found! Required for d8.
    echo   Expected at: D:\JDK8
    pause & goto :EOF
)
set JAVAC=%JAVA_HOME%\bin\javac.exe
set JAR=%JAVA_HOME%\bin\jar.exe

:: Always prefer local AIR SDK over environment variable
	for %%d in ("%~dp0..\..\AIRSDK\AIRSDK_51.3.2") do (
	    if exist %%d\bin\adt.bat set FLEX_HOME=%%~d
	)
	if not defined FLEX_HOME (
	    echo [ERROR] AIR SDK not found at: %~dp0..\..\AIRSDK\AIRSDK_51.3.2
	    echo   Set FLEX_HOME or ensure the SDK directory exists.
	    pause & goto :EOF
	)
set ADT=%FLEX_HOME%\bin\adt.bat

set FLEX_SDK=%~dp0..\..\flex4.16.1-air51.0.1.1
set COMPC_JAR=%FLEX_SDK%\lib\compc.jar
REM Use AIR 33 airglobal.swc for ANE library.swf compatibility
	set AIR_GLOBAL=%FLEX_HOME%\frameworks\libs\air\airglobal.swc

REM ---- Clean build dirs ----
if exist "%BUILD%" rd /s /q "%BUILD%"
mkdir "%BUILD%\java"
mkdir "%BUILD%\%PLATFORM%"
mkdir "%BUILD%\swc"

REM ---- [1/5] Compile Java ----
echo [1/5] Compiling Java...
set JAVA_SRC=%SRC%\com\bvn\filereader
"%JAVAC%" -d "%BUILD%\java" -cp "%LIB%\FlashRuntimeExtensions.jar" -sourcepath "%SRC%" "%JAVA_SRC%\BVNFileReaderExtension.java" "%JAVA_SRC%\BVNFileReaderExtensionContext.java"
if %errorlevel% neq 0 (
    echo [ERROR] Java compile failed.
    pause & goto :EOF
)

REM ---- [2/5] Package JAR ----
echo [2/5] Packaging JAR...
cd "%BUILD%\java"
"%JAR%" cf "%BUILD%\%PLATFORM%\BVNFileReader.jar" .
cd "%PROJ%"

REM ---- [3/5] Compile AS3 into SWC ----
echo [3/5] Compiling SWC...
java -jar "%COMPC_JAR%" +flexlib="%FLEX_SDK%\frameworks" -source-path "%AS3%" -include-classes com.bvn.filereader.BVNFileReaderLib -external-library-path="%AIR_GLOBAL%" -output "%BUILD%\swc\BVNFileReader.swc" -swf-version 37
if %errorlevel% neq 0 (
    echo [ERROR] SWC compile failed.
    pause & goto :EOF
)

REM ---- Extract library.swf from SWC ----
echo   Extracting library.swf...
set SWC_ZIP=%BUILD%\swc\BVNFileReader.swc
set LIB_SWF=%BUILD%\%PLATFORM%\library.swf
powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead('%SWC_ZIP%'); [System.IO.Compression.ZipFileExtensions]::ExtractToFile($z.GetEntry('library.swf'), '%LIB_SWF%', $true); $z.Dispose()"
if not exist "%LIB_SWF%" (
    echo [ERROR] library.swf extraction failed.
    pause & goto :EOF
)

REM ---- [4/5] Package ANE ----
echo [4/5] Packaging ANE...
call "%ADT%" -package -target ane "%PROJ%BVNFileReader.ane" "%PROJ%extension.xml" -swc "%BUILD%\swc\BVNFileReader.swc" -platform %PLATFORM% -C "%BUILD%\%PLATFORM%" .
if %errorlevel% neq 0 (
    echo [ERROR] ANE package failed.
    pause & goto :EOF
)

REM ---- [5/5] Copy to tools\Test ----
echo [5/5] Copying to tools\Test...
set TEST_DIR=%~dp0..\..\tools\Test
copy /y "%PROJ%BVNFileReader.ane" "%TEST_DIR%\BVNFileReader.ane" >nul
if %errorlevel%==0 (
    echo [OK] %PROJ%BVNFileReader.ane
    echo [OK] Copied to %TEST_DIR%\BVNFileReader.ane
) else (
    echo [WARN] ANE built but copy to tools\Test failed.
)

pause
goto :EOF
