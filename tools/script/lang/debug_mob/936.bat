@echo off

if "%1"=="" (
    echo 标签为空！
    goto :EOF
)

goto %1

:NOT_EXIST
echo 文件不存在：%~2
goto :EOF

:UNDEFINE
echo 环境变量 %~2 未定义！
goto :EOF

:TITLE
title Apache fdb（Flash Player 调试器）
goto :EOF

:TITLE_ADB
title Apache fdb（Flash Player 调试器） - [%~2]
goto :EOF

:NO_DEVICE
echo 未检测到设备连接...
goto :EOF

:NO_CMD
echo 未找到 %~2 命令！
goto :EOF

:CONNECT
echo 已连接设备：[%~2]
goto :EOF

:NOT_INSTALLED
echo 应用 [%~2] 未安装！
goto :EOF

:INSTALLING
echo 正在安装应用 [%~2] ...
goto :EOF

:BUILD_MSG
echo [BUILD] 正在编译...
goto :EOF

:BUILD_FAIL
echo [ERROR] 编译失败！
goto :EOF

:PACKAGE_MSG
echo [PACKAGE] 正在打包 APK...
goto :EOF

:PACKAGE_FAIL
echo [ERROR] APK 打包失败！
goto :EOF

:START_MSG
echo 正在启动 Flash 调试器...
goto :EOF

:END_MSG
echo 调试会话完成。
goto :EOF