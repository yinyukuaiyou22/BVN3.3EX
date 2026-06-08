@echo off
cd /d E:\BaiduNetdiskDownload\BVNY
java -jar D:\flex4.16.1-air51.0.1.1\lib\mxmlc.jar +flexlib=D:\flex4.16.1-air51.0.1.1\frameworks -debug=true -swf-version=37 -strict=false -source-path+=E:/BaiduNetdiskDownload/BVNY/BVNscripts/scripts -library-path+=D:\flex4.16.1-air51.0.1.1\frameworks\libs\core.swc -external-library-path+=D:\flex4.16.1-air51.0.1.1\frameworks\libs\air\airglobal.swc -output=launch.swf -- E:/BaiduNetdiskDownload/BVNY/BVNscripts/scripts/launch.as
echo Exit: %ERRORLEVEL%
