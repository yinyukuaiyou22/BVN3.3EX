# 3.7 与主项目源码对照

| 能力 | 3.7 参考 | 主项目现状 | 迁移判断 |
|---|---|---|---|
| 整包更新 | `launchWUFAN.as::checkAndLoadExternal()` 读取 `assets/update/launchWUFAN.swf`，校验 `VERSION_CODE` 后 `loadBytes` | 无同等入口 | 排除；另立热更新课题 |
| 路径解析 | `mob/AssetLoader.as::getFullUrl()`：公共存储→应用存储→APK | `AssetLoader` 直接加载 URL；`ANEFileReader` 处理绝对外部路径 | 增加统一解析层 |
| 人物发现 | 由 XML 的 `file/@url` 间接发现 | `GameLoader.scanExternalFighters()` 扫描 `fighter/*.swf` 并建占位 VO | 保留主项目扫描 |
| 元数据 | `FighterModel.initByXML()` 直接建立 VO | `FighterModel.mergeByXML()` 覆盖占位条目 | 保留两阶段，固定优先级 |
| SWF 加载 | `KyoLoaderLite.loadBytes()` | `AssetManager→AssetLoader→Loader`，另有绝对路径加载 | 统一相对/绝对路径入口 |
| 附属资源 | XML、SWF、Bitmap、Sound 共用 `getFullUrl()` | 头像/BGM 外部链路仍需适配 | 作为迁移重点 |
| 目录初始化 | 3.7 `initModDirectory()` 创建公共和应用目录 | `GameLoader.ensureExternalDirs()` 经 ANE 创建 | 以 ANE 应用私有目录为主 |
| 缓存 | `AssetLoader` 字节缓存 | 主项目有 SWF/资源缓存 | 缓存键改用规范化路径 |

## 调用链

3.7：`GameData.loadConfig()` → `AssetLoader.loadXML()` → `getFullUrl()`；人物 `file/@url` 后续由 `GameLoader.loadFighter()` 加载。

主项目：`GameData.loadConfig()` → 内置 `FighterModel.initByXML()` → `GameLoader.scanExternalAssets()` → 外部 SWF 占位 VO → `loadExternalConfigs()` → `FighterModel.mergeByXML()` → 选人阶段 `GameLoader.loadFighter()`。

## 结论

3.7 的外部人物本质是“统一资源 URL 覆盖”；主项目已有“目录扫描 + XML 合并”。迁移不应抄入 `launchWUFAN` 热更新或替换 `GameLoader`，而应把路径决策集中到加载层。
