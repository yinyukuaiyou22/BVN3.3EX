# BVN V3.3 — 项目技术架构与目录结构

> 最后更新：2026-11-19（对齐 ANE 停用后的现状；工程事实以 [`CLAUDE.md`](../CLAUDE.md) 为准，本文只讲结构与路径）

## 一、项目概述

BVN（死神vs火影）是 5dplay 出品的 2D Flash 格斗游戏，基于 ActionScript 3 + Apache Flex 4.16.1 + AIR 51.0 构建。源码从 SWF 反编译后经手动修复，现基于可编译基线持续开发。支持 PC (adl) 和 Android (APK Captive Runtime) 双平台。

## 二、技术栈

| 层级     | 技术                                  | 版本     |
| -------- | ------------------------------------- | -------- |
| 语言     | ActionScript 3 / Java 8               | —        |
| 编译器   | mxmlc (Flex SDK)                      | 4.16.1   |
| 运行时   | Adobe AIR（编译 SDK `flex4.16.1-air51.0.1.1`，打包 ADT 用 `AIRSDK/AIRSDK_51.1.2`） | 51.x |
| ANE 原生 | Java (FRE API) + Android SDK 33（**已停用**，源码保留） | — |
| 构建工具 | bat 脚本 + ADT + Android build-tools  | 33.0.2   |
| 包管理   | 无（手动依赖）                        | —        |
| 版本控制 | Git，双远端：`origin`=BVN3.3EX、`mobile`=3.3BVNmobile（策略见 `doc/agent-rules.md`） | — |

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
│        ANE 原生扩展层（已停用）            │
│  BVNFileReader: 源码保留，运行时加载不到   │
│  （AIR 侧 Error #2113，详见 CLAUDE.md）   │
│  外置读取实际走 AIR File API 降级路径      │
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
  └─ 外部目录: /storage/emulated/0/Android/media/air.com.bvn.yy798/BVN/assets/config/
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

### 4.3 外置文件读取流（ANE 停用后的实际路径）

```
AS3: ANEFileReader.I.readBytes(path)
  └─ ANE_ENABLED=false → hasANE 恒为 false
       └─ 直接走 AIR File API（沙箱内，能读 Android/media/<包名>/ 下自建目录）
```

> 曾经的 `FREContext.call("readBytes", …)` 分支保留在源码里但走不到：`createExtensionContext()` 恒抛 `Error #2113`。开关职责见 `CLAUDE.md`「ANE 现状」：`EXTERNAL_ENABLED` 是外置资源总开关，`ANE_ENABLED` 只管是否尝试创建原生上下文。

## 五、目录结构

### 5.1 目录分类（按用途）

| 分类           | 目录                        | 用途                                 | 构建依赖 |
| -------------- | --------------------------- | ------------------------------------ | :------: |
| **源码**       | `BVNscripts/scripts/`       | AS3 游戏源码（唯一提交基准）          |    ✅    |
| **ANE 扩展**   | `extensions/BVNFileReader/` | ANE Java + AS3 + 构建（**运行时已停用**） |    ✅    |
| **构建产物**   | `tools/Test/`               | SWF / APK / ANE / 运行时资源         |    ✅    |
| **构建脚本**   | `tools/script/`             | debug.bat / debug_mob.bat / fdbg.bat |    ✅    |
| **平台工具**   | `tools/platform-tools/`     | adb / fastboot / sqlite3             |    ✅    |
| **SDK — Flex** | `flex4.16.1-air51.0.1.1/`   | mxmlc + Flex 框架                    |    ✅    |
| **SDK — AIR**  | `AIRSDK/AIRSDK_51.1.2/`     | ADT / adl / fdb / 证书               |    ✅    |
| **SDK — 平台库** | `android-platform-33/`    | Android 平台库（android.jar）        |    ✅    |
| **文档（开发向）** | `doc/`                   | 架构 / 专题 / 决策 / 归档（入口 `doc/README.md`） |    —     |
| **文档（用户向）** | `docs/`                  | 安装发布 / 外置资源 / 子框 / 常见问题 / 发行说明 |    —     |
| **参考代码**   | `BVNscripts/3.7扩展版参考/`、`BVNscripts/3.8竞技参考/`、`reference/` | 只读参考，不作提交源 |    —     |
| **UI 源**      | `FlaUi/`                    | fight.fla 等 UI 源（终极回滚源）      |    —     |
| **反编译工具** | `FFDEC/`                    | 反编译链路与导出物                   |    —     |
| **独立工具**   | `选人界面排版工具/`          | 单文件 HTML 排版工具（自带文档）       |    —     |
| **本地快照**   | `.backup/`                  | 改动前单文件快照，不进提交            |    —     |
| **IDE 元数据** | `.codegraph/` `.claude/` `.agents/` | 知识图谱 / 会话缓存 / 技能 |    —     |

### 5.2 根目录文件

| 文件               | 用途                               |
| ------------------ | ---------------------------------- |
| `build.bat`        | PC 编译入口（VSCode Ctrl+Shift+B） |
| `asconfig.json`    | VSCode ActionScript 插件配置（不是构建入口） |
| `sync.py`          | 同步脚本（它读的 `Outscripts/` 目录当前不存在） |
| `push-to-github.ps1` | 推送辅助脚本                     |
| `CLAUDE.md`        | 项目事实源（目标/边界/契约/路径/ANE 现状/验收） |
| `AGENTS.md`        | 每会话注入的行为合同（红线 + 冲突优先级 + 指针） |
| `README.md`        | 面向玩家与作者的入口说明           |

> **2026-10-11 文档归档**：根目录不再散落文档，只保留 `CLAUDE.md` / `AGENTS.md` / `README.md` 三个入口。
> `AI-SYSTEM-DOC.md` 归入 `doc/`；`build_output.txt` / `mob_*.log` 归入 `doc/archive/logs/`；
> 原 `docs/`（ADR、plans）并入 `doc/adr/`、`doc/plans/`；第三方技能包移出到 `tools/skills-1.2.3/`。
> **全部文档检索入口见 [`doc/README.md`](README.md)。**

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
  → AIRSDK/AIRSDK_51.1.2/           (adl/fdb/ADT)
  → tools/Test/                      (SWF/APK)
  → tools/platform-tools/            (adb)

build_ane.bat (extensions/BVNFileReader/)
  → <JDK 8 安装路径>                 (Java 编译，脚本里锁定 JDK 8)
  → <Android SDK>/platforms/android-33/android.jar
  → ../../flex4.16.1-air51.0.1.1/   (compc)
  → ../../AIRSDK/AIRSDK_51.1.2/     (ADT)
  → ../../tools/Test/                (ANE 输出)

sync.py
  → Outscripts/scripts/              (源，该目录当前不存在)
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
│       ├── BVNDataFilesProvider.java            # DocumentsProvider（599 行，当前未启用）
│       └── BVNDataFilesWakeUpActivity.java      # 进程唤醒 Activity
└── as3/com/bvn/filereader/
    └── BVNFileReaderLib.as                      # AS3 SWC 源
```

### 6.2 三个开关的现状（都已不具备启用条件）

| #   | 文件                         | 现状                                                                |
| --- | ---------------------------- | ------------------------------------------------------------------- |
| 1   | `ANEFileReader.as`           | `ANE_ENABLED = false`（尝试创建原生上下文）、`EXTERNAL_ENABLED = true`（外置资源总开关，不影响外置功能） |
| 2   | `tools/Test/application.xml` | `<extensions><extensionID>com.bvn.filereader</extensionID></extensions>` 整段已注释 |
| 3   | `debug_mob.bat`              | 打包不再需要 ANE 的 `-extdir` 指向                                  |

> 要重启这条路线，前提不是改这三个开关，而是先找到能加载扩展的工具链（`createExtensionContext()` 在本工具链上恒抛 `Error #2113`，早于任何 Java 代码），并在真机上看到 `createContext() called`。详见 `CLAUDE.md`「ANE 现状」与 `doc/archive/_report/2026-10-09_ANE-诊断报告.md`。

### 6.3 APK 瘦身机制

打包时备份并恢复的目录: `fighter/` `map/` `face/` `bgm/` `config/`
实际内容部署在外部: `/storage/emulated/0/Android/media/air.com.bvn.yy798/BVN/assets/`

## 七、关键路径常量

| 常量                 | 位置                  | 值                                                               |
| -------------------- | --------------------- | ---------------------------------------------------------------- |
| `EXTERNAL_ENABLED`   | `ANEFileReader.as:28` | `true`（外置资源总开关）                                          |
| `ANE_ENABLED`        | `ANEFileReader.as:37` | `false`（原生上下文一律不尝试）                                   |
| `EXTERNAL_BASE`      | `ANEFileReader.as:121` | `/storage/emulated/0/Android/media/air.com.bvn.yy798/BVN/assets/` |
| `PROVIDER_AUTHORITY` | `ANEFileReader.as:125` | `air.com.bvn.yinyu.BVNDataFilesProvider`（历史值；provider 已注释，无实际调用） |
| 证书路径             | `debug_mob.bat`       | `%FLEX_HOME%\bin\mycert.p12`                                     |
| 证书密码             | 环境变量              | `BVN_KEYSTORE_PASS`（不写进文档或脚本）                           |
| App ID               | `application.xml`     | `com.bvn.yy798`（ADT 会前缀 `air.`）                              |
| APK 包名             | —                     | `air.com.bvn.yy798`                                              |
