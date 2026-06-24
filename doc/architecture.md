# BVN V3.3 — 项目技术架构与目录结构

> 最后更新：2026-06-11

## 一、项目概述

BVN（死神vs火影）是 5dplay 出品的 2D Flash 格斗游戏，基于 ActionScript 3 + Apache Flex 4.16.1 + AIR 51.0 构建。源码从 SWF 反编译后经手动修复，现基于可编译基线持续开发。支持 PC (adl) 和 Android (APK Captive Runtime) 双平台。

## 二、技术栈

| 层级     | 技术                                  | 版本     |
| -------- | ------------------------------------- | -------- |
| 语言     | ActionScript 3 / Java 8               | —        |
| 编译器   | mxmlc (Flex SDK)                      | 4.16.1   |
| 运行时   | Adobe AIR                             | 51.3.2.2 |
| ANE 原生 | Java (FRE API) + Android SDK 33       | —        |
| 构建工具 | bat 脚本 + ADT + Android build-tools  | 33.0.2   |
| 包管理   | 无（手动依赖）                        | —        |
| 版本控制 | Git (GitHub: yinyukuaiyou22/BVN3.3EX) | —        |

## 三、分层架构

```
┌─────────────────────────────────────────┐
│              应用入口层                    │
│  launch.as → MainGame.as → KyoStageCtrl  │
├─────────────────────────────────────────┤
│              状态机层                      │
│  Logo → Menu → SelectFighter → Loading   │
│  → GameState → GameOver/Winner           │
├─────────────────────────────────────────┤
│              控制器层 (ctrl/)              │
│  GameCtrl / GameLogic / GameRender       │
│  GameLoader / AssetManager / SoundCtrl   │
├─────────────────────────────────────────┤
│              数据层 (data/)               │
│  GameData / FighterModel / MapModel      │
│  ConfigVO / FighterVO / SelectVO         │
├─────────────────────────────────────────┤
│              角色系统 (fighter/)           │
│  FighterMain → FighterMcCtrler (状态机)   │
│  ← FighterKeyCtrl (玩家) / FighterAICtrl │
├─────────────────────────────────────────┤
│              平台抽象层                    │
│  PC: Keyboard → FighterKeyCtrl           │
│  Mob: ScreenPad / Joystick / Socket      │
├─────────────────────────────────────────┤
│            ANE 原生扩展层                  │
│  BVNFileReader: Java FREExtension        │
│  → java.io.File (readBytes/listDir/...)  │
│  BVNDataFilesProvider: DocumentsProvider │
│  → SAF 文件管理器集成                     │
├─────────────────────────────────────────┤
│            Flex 框架桩 (mx/)              │
│  BitmapAsset / ByteArrayAsset / ...      │
└─────────────────────────────────────────┘
```

## 四、数据流

### 4.1 配置加载流

```
GameData.loadConfig()
  │
  ├─ APK内置? assets/config/fighter.xml
  │   ├─ 成功 → FighterModel.initByXML()
  │   └─ 失败 → 短路 → loadExternalConfigsNow()
  │
  ├─ APK内置? assist.xml → AssisterModel
  ├─ APK内置? select.xml  → SelectStageConfigVO
  ├─ APK内置? map.xml     → MapModel
  ├─ APK内置? mission.xml → MessionModel
  │
  └─ 外部目录: /Android/data/air.com.bvn.yinyu/BVN/assets/config/
      ├─ fighter.xml  → FighterModel.mergeByXML()
      ├─ assist.xml   → AssisterModel.mergeByXML()
      ├─ select.xml   → GameData.I.config.select_config.setByXML()
      ├─ map.xml      → MapModel.mergeByXML()
      └─ mission.xml  → MessionModel.mergeByXML()
```

### 4.2 外部资源加载流

```
GameLoader.scanExternalAssets()
  ├─ ensureExternalDirs()  → 创建 fighter/map/face/bgm/config 目录
  ├─ scanExternalFighters() → *.swf → FighterVO → FighterModel
  └─ scanExternalMaps()     → *.swf → MapVO → MapModel

GameLoader.loadExternalConfigs()
  └─ ANEFileReader.readBytes() → XML.parse() → Model.mergeByXML()
```

### 4.3 ANE 文件读取流

```
AS3: ANEFileReader.I.readBytes(path)
  └─ Java: FREContext.call("readBytes", path)
       └─ BVNFileReaderExtensionContext$ReadBytesFunction
            ├─ hasANE==true  → new FileInputStream(path)  (无沙箱)
            └─ hasANE==false → AIR File API fallback       (沙箱内)
```

## 五、目录结构

### 5.1 目录分类（按用途）

| 分类           | 目录                        | 用途                                 | 构建依赖 |
| -------------- | --------------------------- | ------------------------------------ | :------: |
| **源码**       | `BVNscripts/scripts/`       | AS3 游戏源码                         |    ✅    |
| **ANE 扩展**   | `extensions/BVNFileReader/` | ANE Java + AS3 + 构建                |    ✅    |
| **构建产物**   | `tools/Test/`               | SWF / APK / ANE / 运行时资源         |    ✅    |
| **构建脚本**   | `tools/script/`             | debug.bat / debug_mob.bat / fdbg.bat |    ✅    |
| **平台工具**   | `tools/platform-tools/`     | adb / fastboot / sqlite3             |    ✅    |
| **SDK — Flex** | `flex4.16.1-air51.0.1.1/`   | mxmlc + Flex 框架                    |    ✅    |
| **SDK — AIR**  | `AIRSDK/AIRSDK_51.3.2/`     | ADT / adl / fdb / 证书               |    ✅    |
| **文档**       | `doc/`                      | 架构/ANE 规划/进度                   |    —     |
| **参考代码**   | `BVN3.9/`                   | BVN 3.9 参考源码（只读）             |    —     |
| **参考代码**   | `MTDataFilesProvider-main/` | DocumentsProvider 参考               |    —     |
| **同步暂存**   | `Outscripts/`               | sync.py 修改后脚本导出               |    —     |
| **IDE 元数据** | `.codegraph/` `.claude/`    | 知识图谱 / 会话缓存                  |    —     |
| **SDK 工具**   | `commandlinetools-win-*/`   | Android CLI 工具                     | ⚠️ 冗余  |

### 5.2 根目录文件

| 文件               | 用途                               |
| ------------------ | ---------------------------------- |
| `build.bat`        | PC 编译入口（VSCode Ctrl+Shift+B） |
| `asconfig.json`    | VSCode ActionScript 插件配置       |
| `sync.py`          | Outscripts → BVNscripts 同步脚本   |
| `CLAUDE.md`        | AI 开发助手指南（全局）            |
| `AGENTS.md`        | AI 开发工作流规则 + ANE 规范       |
| `AI-SYSTEM-DOC.md` | AI 系统详细文档                    |
| `README.md`        | 项目简介                           |
| `build_output.txt` | 构建日志（应被 gitignore）         |

### 5.3 路径依赖图

```
build.bat
  → flex4.16.1-air51.0.1.1/          (mxmlc + frameworks)
  → BVNscripts/scripts/              (源码，绝对路径!)
  → tools/Test/launch.swf            (输出)

asconfig.json
  → BVNscripts/scripts               (source-path)
  → tools/Test                       (extdir)

debug.bat / debug_mob.bat / fdbg.bat
  → build.bat                        (编译)
  → AIRSDK/AIRSDK_51.3.2/           (adl/fdb/ADT)
  → tools/Test/                      (SWF/APK)
  → tools/platform-tools/            (adb)

build_ane.bat (extensions/BVNFileReader/)
  → D:\JDK8                          (Java 编译)
  → D:\Android\SDK                   (android.jar)
  → ../../flex4.16.1-air51.0.1.1/   (compc)
  → ../../AIRSDK/AIRSDK_51.3.2/     (ADT)
  → ../../tools/Test/                (ANE 输出)

sync.py
  → Outscripts/scripts/              (源)
  → BVNscripts/scripts/              (目标)
```

## 六、ANE 扩展子系统

### 6.1 组件清单

```
extensions/BVNFileReader/
├── extension.xml                                # ANE 描述符
├── build_ane.bat                                # 5步构建: javac→jar→swc→ane→copy
├── BVNFileReader.ane                            # 构建产物
├── Android/
│   ├── lib/FlashRuntimeExtensions.jar           # FRE API 依赖
│   ├── AndroidManifest.xml                      # Provider 声明(备选)
│   └── src/com/bvn/filereader/
│       ├── BVNFileReaderExtension.java          # FREExtension 入口
│       ├── BVNFileReaderExtensionContext.java   # 3 FREFunctions + registerProvider
│       ├── BVNDataFilesProvider.java            # DocumentsProvider (~380行)
│       └── BVNDataFilesWakeUpActivity.java      # 进程唤醒 Activity
└── as3/com/bvn/filereader/
    └── BVNFileReaderLib.as                      # AS3 SWC 源
```

### 6.2 ANE 三开关

| #   | 文件                         | 设置                                                                |
| --- | ---------------------------- | ------------------------------------------------------------------- |
| 1   | `ANEFileReader.as`           | `ANE_ENABLED = true`                                                |
| 2   | `tools/Test/application.xml` | `<extensionID>com.bvn.filereader</extensionID>` + manifestAdditions |
| 3   | `debug_mob.bat`              | ADT 命令含 `-extdir "."`                                            |

### 6.3 APK 瘦身机制

打包时备份并恢复的目录: `fighter/` `map/` `face/` `bgm/` `config/`
实际内容部署在外部: `/storage/emulated/0/Android/data/air.com.bvn.yinyu/BVN/assets/`

## 七、关键路径常量

| 常量                 | 位置                  | 值                                                               |
| -------------------- | --------------------- | ---------------------------------------------------------------- |
| `EXTERNAL_BASE`      | `ANEFileReader.as:60` | `/storage/emulated/0/Android/data/air.com.bvn.yinyu/BVN/assets/` |
| `PROVIDER_AUTHORITY` | `ANEFileReader.as:64` | `air.com.bvn.yinyu.BVNDataFilesProvider`                         |
| `ANE_ENABLED`        | `ANEFileReader.as:22` | `true`                                                           |
| 证书路径             | `debug_mob.bat`       | `%FLEX_HOME%\bin\mycert.p12`                                     |
| 证书密码             | `debug_mob.bat`       | `yinyu7798`                                                      |
| App ID               | `application.xml`     | `com.bvn.yinyu`                                                  |
| APK 包名             | —                     | `air.com.bvn.yinyu`                                              |
