@echo off

if "%1"=="" (
    echo The tag is empty!
    goto :EOF
)

goto %1

:NOT_EXIST
echo File does not exist: %~2
goto :EOF

:UNDEFINE
echo Environment variable %~2 is undefined!
goto :EOF

:TITLE
title Apache fdb (Flash Player Debugger)
goto :EOF

:TITLE_ADB
title Apache fdb (Flash Player Debugger) - [%~2]
goto :EOF

:NO_DEVICE
echo No device connection detected...
goto :EOF

:NO_CMD
echo Command %~2 not found!
goto :EOF

:CONNECT
echo Connected devices: [%~2]
goto :EOF

:NOT_INSTALLED
echo Application [%~2] is not installed!
goto :EOF

:INSTALLING
echo Installing application [%~2] ...
goto :EOF

:BUILD_MSG
echo [BUILD] Compiling...
goto :EOF

:BUILD_FAIL
echo [ERROR] Build failed!
goto :EOF

:PACKAGE_MSG
echo [PACKAGE] Creating APK...
goto :EOF

:PACKAGE_FAIL
echo [ERROR] ADT package failed!
goto :EOF

:START_MSG
echo Starting Flash Debugger...
goto :EOF

:END_MSG
echo Debug session completed.
goto :EOF