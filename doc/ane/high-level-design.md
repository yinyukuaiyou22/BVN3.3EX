# High-Level Design — ANE 原生文件读取子系统

## 架构概览

```
┌─────────────────────────────────────────────────────────┐
│                    AS3 Application Layer                │
│  GameLoader.as  │  GameData.as  │  AssetManager.as     │
│       │                │                                  │
│       ▼                ▼                                  │
│  loadFighterFromPath()  scanExternalAssets()             │
│  scanExternalFighters() loadExternalConfigs()           │
│  scanExternalMaps()    tryLoadExternalXML()             │
└───────────────┬─────────────────────────────────────────┘
                │ 单例调用
                ▼
┌─────────────────────────────────────────────────────────┐
│              ANE Wrapper Layer (AS3)                     │
│              ANEFileReader.as                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │ ANE_ENABLED toggle → ExtensionContext OR File API│   │
│  │ resolveExternalPath() / hasExternalAsset()       │   │
│  │ readBytes() / listDir() / exists()               │   │
│  │ readBytesFallback() / listDirFallback() /        │   │
│  │   existsFallback()                               │   │
│  └──────────────────────────────────────────────────┘   │
└───────┬───────────────────────┬─────────────────────────┘
        │ ANE enabled            │ ANE disabled
        ▼                        ▼
┌───────────────────┐   ┌───────────────────┐
│  ExtensionContext │   │ flash.filesystem   │
│  "com.bvn.        │   │ File / FileStream  │
│   filereader"      │   │ (sandbox-limited)  │
└────────┬──────────┘   └───────────────────┘
         │ FRE (Flash Runtime Extension)
         ▼
┌─────────────────────────────────────────────────────────┐
│              ANE Library Layer (AS3 → SWC)               │
│           BVNFileReaderLib.as                            │
│  readBytes(path):ByteArray                               │
│  listDir(path):Array                                     │
│  exists(path):Boolean                                    │
└───────────────┬─────────────────────────────────────────┘
                │ ExtensionContext.call()
                ▼
┌─────────────────────────────────────────────────────────┐
│            ANE Native Layer (Java, Android)              │
│     BVNFileReaderExtension → BVNFileReaderExtensionContext│
│  ┌──────────────────────────────────────────────────┐   │
│  │ ReadBytesFunction: FileInputStream → FREByteArray │   │
│  │ ListDirFunction:   File.list() → FREArray        │   │
│  │ ExistsFunction:    File.exists() → FREBoolean     │   │
│  └──────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────┘
                        │ java.io.File
                        ▼
              Android File System
       /storage/emulated/0/Android/data/
         air.com.bvn.yinyu/files/BVN/assets/
```

## 模块边界

| 模块 | 文件 | 职责 |
|------|------|------|
| **Native Java** | `extensions/BVNFileReader/Android/src/` (2 `.java`) | 原生文件 I/O：读字节、列目录、存在检查 |
| **ANE 构建** | `extensions/BVNFileReader/build_ane.bat` | Java→JAR→SWC→ANE 五步自动化流水线 |
| **ANE 描述** | `extensions/BVNFileReader/extension.xml` | 平台声明、初始化类、nativeLibrary |
| **ANE 库** | `extensions/BVNFileReader/as3/BVNFileReaderLib.as` | AS3 ↔ Java FRE 桥接（ExtensionContext） |
| **ANE 封装** | `BVNscripts/.../mob/utils/ANEFileReader.as` | 单例包装：ANE 开关、降级策略、路径解析 |
| **资源加载** | `BVNscripts/.../ctrl/GameLoader.as` | 外部扫描/注册/配置合并（5个公开方法） |
| **启动调用** | `BVNscripts/.../data/GameData.as` | 启动时触发 `scanExternalAssets()` + `loadExternalConfigs()` |
| **应用配置** | `tools/Test/application.xml` | `<extensionID>com.bvn.filereader</extensionID>` |
| **打包脚本** | `tools/script/debug_mob.bat` | ADT 打包含 `-extdir "."` |

## 数据流

### 启动加载流

```
GameData.loadConfig()
  │
  ├─[1] loadXML("fighter.xml") → FighterModel.initByXML()
  │      └─[2] GameLoader.scanExternalAssets()  // setTimeout 2s
  │            ├─ ensureExternalDirs()   → 创建 fighter/map/face/bgm/config
  │            ├─ scanExternalFighters()  → listDir → 注册 FighterVO
  │            └─ scanExternalMaps()      → listDir → 注册 MapVO
  │
  ├─[3] loadXML("assist.xml") → AssisterModel.initByXML()
  ├─[4] loadXML("select.xml") → config.select_config.setByXML()
  ├─[5] loadXML("map.xml") → MapModel.initByXML()
  ├─[6] loadXML("mission.xml") → MessionModel.initByXML()
  │      └─[7] GameLoader.loadExternalConfigs()  // setTimeout 3s
  │            ├─ tryLoadExternalXML("fighter.xml") → FighterModel.mergeByXML()
  │            ├─ tryLoadExternalXML("assist.xml")  → AssisterModel.mergeByXML()
  │            ├─ tryLoadExternalXML("map.xml")     → MapModel.mergeByXML()
  │            └─ tryLoadExternalXML("mission.xml") → MessionModel.mergeByXML()
  │
  └─ back() → 继续启动流程
```

### 单个文件读取流

```
loadFighterFromPath("/path/to/fighter.swf")
  → ANEFileReader.I.readBytes(path)
    ├─ [ANE enabled]  → ExtensionContext.call("readBytes", path)
    │   → BVNFileReaderExtensionContext.ReadBytesFunction
    │   → FileInputStream → FREByteArray → ByteArray
    └─ [ANE disabled] → readBytesFallback(path)
        → flash.filesystem.File → FileStream → ByteArray
  → Loader.loadBytes(ba)
  → contentLoaderInfo complete → FighterMain(mc)
```

### 配置合并流

```
tryLoadExternalXML("fighter.xml", callback)
  → ANEFileReader.I.exists(path)  // 先检查存在
  → ANEFileReader.I.readBytes(path)  // 读取字节
  → ba.readUTFBytes(ba.length)  // ByteArray → String
  → new XML(xmlStr)  // String → XML
  → FighterModel.mergeByXML(xml)  // 追加合并（内置优先，重复跳过）
```

## 外部依赖

| 依赖 | 版本 | 位置 |
|------|------|------|
| FlashRuntimeExtensions.jar | AIR 51 | `extensions/BVNFileReader/Android/lib/` |
| airglobal.swc | AIR 51.3.2 | `AIRSDK5/AIRSDK_51.3.2/frameworks/libs/air/` |
| compc.jar | Flex 4.16.1 | `flex4.16.1-air51.0.1.1/lib/` |
| Android SDK platform-33 | 33 | `D:/Android/SDK/` |
| JDK 8 | 1.8 | `D:/JDK8/` |

## 主要设计决策

| 决策 | 选择 | 原因 |
|------|------|------|
| ANE vs 纯 AIR File API | ANE（可降级） | AIR 沙箱限制无法访问应用私有目录外部 |
| 单例封装 ANEFileReader | 单例 `ANEFileReader.I` | 统一管理 ANE 生命周期 + 降级策略 |
| 异步扫描 | `setTimeout(doScan, 2000)` | 防止启动时 ANR（外部存储 I/O 可能阻塞） |
| 配置合并而非替换 | 追加（内置优先） | 保证核心内容不被外部错误配置破坏 |
| EXTERNAL_BASE 路径 | 应用私有目录 `Android/data/` | Android 10+ 作用域存储要求 |
| ANE 构建流水线 | JDK 8 + AIR 51 | class v52 兼容 Android build-tools d8 |
| 调试日志策略 | `Debugger.log` + `trace` 双输出 | 确保 logcat 实时可见 + 调试面板可查 |

## 考虑过的备选方案

| 方案 | 评价 |
|------|------|
| 使用 `/storage/emulated/0/BVN/assets/` 公共目录 | ❌ Android 10+ 分区存储限制；曾使用后改为应用私有目录 |
| MANAGE_EXTERNAL_STORAGE 权限 | ❌ Google Play 审核风险；用户体验差 |
| 纯 AIR File API（无 ANE） | ❌ 沙箱限制，无法访问外部目录 |
| AIR 33.1 + 旧 ANE | ❌ ANE 不兼容 AIR 33.1，必须 AIR 51+ |

## 风险与未知项

| 风险 | 影响 | 缓解 |
|------|------|------|
| `tryLoadExternalXML` 作用域 bug | 外部配置 XML 加载失败（运行时错误） | 修复：将 `basePath` 作为参数传入 |
| 应用私有目录用户不可见 | 用户无法手动放置外部资源 | 需提供 PC 端文件传输工具或引导说明 |
| ANE 三开关不一致 | ANE 静默失败（降级后功能受限） | 增加启动时自检：`ANE_ENABLED && hasANE` 状态校验 |
| APK 瘦身与 ANE 路径协调 | 外部路径改变后瘦身逻辑可能不同步 | 瘦身仅影响 APK 内置 assets，外部路径独立 |

## 高层测试策略

| 层级 | 测试方法 |
|------|----------|
| Java 函数 | 手动测试：通过 AS3 调用验证 readBytes/listDir/exists |
| ANE 集成 | `debug_mob.bat` 真机打包 + logcat 日志断点 |
| 降级策略 | PC 端 `ANE_ENABLED=false` 编译测试 |
| 外部扫描 | 手机文件管理器放置 SWF，检查 logcat 中注册日志 |
| 配置合并 | 在外部目录放置测试 XML，验证选人列表变化 |
