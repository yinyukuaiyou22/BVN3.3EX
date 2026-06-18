@echo off
chcp 65001 >nul
cd /d %~dp0
java -jar AIRSDK\flex4.16.1-air51.0.1.1\lib\mxmlc.jar +flexlib=AIRSDK\flex4.16.1-air51.0.1.1\frameworks -debug=true -swf-version=37 -strict=false -source-path+=E:/BaiduNetdiskDownload/BVNY/BVNscripts/scripts -library-path+=AIRSDK\flex4.16.1-air51.0.1.1\frameworks\libs\core.swc -external-library-path+=AIRSDK\flex4.16.1-air51.0.1.1\frameworks\libs\air\airglobal.swc -output=tools\Test\launch.swf -- E:/BaiduNetdiskDownload/BVNY/BVNscripts/scripts/launch.as
echo Exit: %ERRORLEVEL%
