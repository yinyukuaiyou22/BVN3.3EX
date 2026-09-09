# 3.7 外部人物读取迁移提案

## 目标

研究 `BVNscripts/3.7扩展版参考/scripts/` 的外部人物读取机制，并为 Android 主项目制定可实施的迁移方案：外部 `fighter/*.swf`、`config/fighter.xml`、头像和 BGM 可被发现、读取，并在缺失时回退到 APK 内置资源。

## 边界

- `launchWUFAN.as::checkAndLoadExternal()` 是整包 SWF 热更新，不纳入人物资源迁移。
- Continue、Gamepad、`AdaptiveEngine` 仅作背景，不纳入本功能。
- 不重设计 ANE Java API；复用当前 `ANEFileReader`。
- 目标平台为 AIR Android；PC 仅承担编译和静态验证。

## 当前基线与选型

3.7 的关键机制在 `mob/AssetLoader.as::getFullUrl()`：`/storage/emulated/0/assets/...` → `File.applicationStorageDirectory` → `File.applicationDirectory`。主项目则由 `GameLoader.scanExternalFighters()` 扫描外部 SWF、创建占位 `FighterVO`，再由外部 XML `mergeByXML()` 补全元数据。

采用“兼容层统一”：保留扫描/合并两阶段，新增集中式路径解析，让 XML、SWF、头像、BGM 使用同一外部优先规则。

## 成功标准

- 外部 SWF 能出现在选人列表并进入战斗。
- 外部 XML 覆盖名称、头像、BGM、起始帧等占位字段。
- `assets/...`、不带 `assets/` 的相对路径和绝对路径均按规范解析。
- 外部资源缺失时回退 APK；损坏资源有明确失败日志且不破坏内置资源。
- ID 冲突、XML 缺失、`main_mc`/旧式根 MovieClip 均有确定行为。
- `./build.bat` 通过，并完成 Android 真机验证。

## 待验证问题

公共存储在 Android 新版本的可访问性、`EXTERNAL_BASE` 与 3.7 路径的兼容、头像/BGM 缺省策略、扫描与选人 UI 的竞态、两种人物 SWF 格式均需在实现阶段验证并记录。
