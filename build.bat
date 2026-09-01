@echo off
cd /d %~dp0

REM === Batch 6.14: Auto-inject build version ===
REM 1. Use PowerShell to get current date-time (YYYY-MM-DD-HHMM)
REM 2. Use PowerShell to replace BUILD_TAG date-time in Debugger.as (batch number stays manual)
REM 3. Compile
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd-HHmm'"') do set BUILD_DT=%%a
echo [build.bat] Injecting BUILD_TAG date-time: %BUILD_DT%

powershell -NoProfile -Command "$f='BVNscripts\scripts\net\play5d\game\bvn\Debugger.as'; $c=Get-Content $f -Raw -Encoding UTF8; $c2=[regex]::Replace($c, 'public static const BUILD_TAG:String = \"BVN-3.3EX-batch[0-9.]+-\d{4}-\d{2}-\d{2}-\d{4}\";', ('public static const BUILD_TAG:String = \"BVN-3.3EX-batch6.14-%BUILD_DT%\";')); Set-Content -Path $f -Value $c2 -Encoding UTF8 -NoNewline"

java -jar flex4.16.1-air51.0.1.1\lib\mxmlc.jar +flexlib=flex4.16.1-air51.0.1.1\frameworks -debug=true -swf-version=37 -strict=false -source-path+=BVNscripts\scripts -library-path+=flex4.16.1-air51.0.1.1\frameworks\libs\core.swc -external-library-path+=flex4.16.1-air51.0.1.1\frameworks\libs\air\airglobal.swc -output=tools\Test\launch.swf -- BVNscripts\scripts\launch.as
echo Exit: %ERRORLEVEL%