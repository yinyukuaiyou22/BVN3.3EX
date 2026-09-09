# 任务：Android 集成验证

- 目标：验证 ANE 路径和真实设备行为。
- 输入：`application.xml`、`debug_mob.bat`、`extensions/BVNFileReader/`。
- 步骤：核对三开关；准备外部目录；打包安装；检查 `ANE init`、扫描、解析来源和失败日志；覆盖作用域存储、缓存和重启。
- 命令：`./build.bat`；`tools/script/debug_mob.bat`；按项目日志方案读取 `bvn_debug.log`。
- 完成定义：内置、外部、回退、损坏、ANE 禁用五组场景通过。
- 依赖：前三个任务。
