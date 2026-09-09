# 任务：统一资源解析

- 目标：复现 3.7 的外部优先回退，同时复用主项目 ANE。
- 输入：`ctrl/AssetLoader.as`、`ctrl/AssetManager.as`、`mob/utils/ANEFileReader.as`。
- 步骤：规范化路径；实现外部/内置探测；接入 XML、SWF、Bitmap、Sound；统一缓存键和来源日志。
- 检查：相对、绝对、缺失、ANE 降级四类路径用例；`./build.bat`。
- 完成定义：无重复路径逻辑，失败回调兼容。
- 依赖：无；被人物注册和附属资源任务依赖。
