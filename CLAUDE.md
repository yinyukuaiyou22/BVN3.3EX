# BVN（死神vs火影）— AS3 格斗游戏

> **AI 开发助手**：请同时阅读 [AGENTS.md](AGENTS.md) 获取本项目专属的开发行为准则和工具配置。

---

## 1. 项目概述

本项目是 **5dplay 出品的"死神vs火影" V3.3** — 基于 ActionScript 3 开发的 2D Flash 格斗游戏。源码从 SWF 反编译后经手动修复，现基于可编译基线 (`last/`) 持续开发。

| 目录 | 说明 |
|------|------|
| `BVNscripts/scripts/` | 可编译源码（含 `_assets/` 嵌入资源、`mx/` Flex 框架桩） |
| `Outscripts/` | 修改后脚本导出目录（git 忽略，`sync.py` 同步） |
| `build.bat` | 编译脚本（`Ctrl+Shift+B` 或直接运行） |
| `asconfig.json` / `.vscode/` | VSCode 构建配置 |
| `assets/swf/` | UI SWF 运行时资源（外部加载） |

---

## 2. 构建与调试

### 2.1 环境变量

| 变量 | 位置 | 用途 |
|------|------|------|
| Flex SDK | `项目根\flex4.16.1-air51.0.1.1\` | mxmlc 编译器 + Flex 框架 + AIR 运行时 |
| AIR SDK | `项目根\AIRSDK5\AIRSDK_51.3.2\` | ADT 打包 / fdb 调试 |
| `FLEX_HOME` | 自动检测 → AIR SDK | 脚本定位 `bin\fdb`、`bin\adl.exe` |
| `JAVA_HOME` | JDK 17 | mxmlc 运行时 |
| ADB | Android SDK platform-tools | 手机真机调试 |
| 证书 | `AIRSDK5\...\bin\mycert.p12` | APK 签名（密码 `yinyu7798`） |
| App 描述 | `tools\Test\application.xml` | AIR 应用配置（`com.bvn.yinyu`） |

### 2.2 PC 端编译

```bash
# 编译（VSCode: Ctrl+Shift+B）
./build.bat
# 编译器: mxmlc (Flex SDK) → 输出: tools/Test/launch.swf（~4.6MB）
```

### 2.3 PC 端调试

| 工具 | 位置 | 用途 |
|------|------|------|
| `adl.exe` | `%FLEX_HOME%\bin\` | AIR Debug Launcher |
| `fdbg.bat` | `tools/script/` | 项目自定义 fdb 调试脚本 |

```bash
# 直接启动（带控制台输出）
adl tools/Test/launch.swf

# 断点调试 FighterTester
tools/script/debug.bat
```

### 2.4 手机真机调试（Android）

**前置条件**：`FLEX_HOME` 指向 AIR SDK 根目录 / `adb` 在 PATH 中 / 手机 USB 调试已开启

```bash
# 打包 APK（ADT Captive Runtime, armv8）
adt -package -target apk-captive-runtime -arch armv8 \
  -storetype pkcs12 -keystore mycert.p12 -storepass yinyu7798 \
  tools/Test/死神vs火影银鱼改.apk \
  tools/Test/application.xml \
  tools/Test/launch.swf

# 一键：打包 + 安装 + 启动 + fdb 实时调试
tools/script/debug_mob.bat
```

**调试脚本组**（`tools/script/`）：

| 脚本 | 目标 | 说明 |
|------|------|------|
| `debug.bat` | PC | 编译 + adl 启动 FighterTester |
| `debug_mob.bat` | 手机 | adb 安装 APK + fdb 实时调试 |
| `fdbg.bat` | 通用 | fdb 连接任意 SWF 进行断点调试 |

---

## 3. 整体架构

### 3.1 启动流程

```
launch.as（入口，继承 Sprite）
  └─ MainGame.as（游戏状态机，单例）
       └─ KyoStageCtrl（场景/状态管理器）
            └─ Logo → Menu → SelectFighter → Loading → GameState → GameOver/Winner
```

**设计模式**：大量使用单例的类 MVC 架构，核心类通过 `.I` 静态 getter 访问（`GameData.I`、`GameCtrl.I` 等）。

### 3.2 启动链路

```
launch() → initlize() → initGame()
  → ScreenRotater.init / ScreenPadManager.initlize / UIAssetUtil.initalize
  → buildGame() → MainGame.initlize()
    → ResUtils.initalize（外部 SWF 加载）
    → GameRender.initlize → GameInputer.initlize
    → GameData.I.loadData → applyConfig → updateConfig
    → GameLoadingState → loadGame → EffectModel.I.initlize
    → goLogo() → LogoState
```

### 3.3 游戏状态机

- 非战斗状态 30fps，GameState 60fps
- 状态切换：`MainGame.I.goXxx()`

### 3.4 目录结构

```
BVNscripts/scripts/
├── launch.as                            # 主入口（Flash 文档类）
├── build.bat                            # 编译脚本
├── EmbeddedAssets.as                    # 嵌入式资源统一管理
├── mx/core/                             # Flex 框架桩
├── com/
│   ├── greensock/                       # TweenLite 补间动画库
│   └── adobe/utils/StringUtil.as        # Adobe 字符串工具
├── fl/motion/                           # Flash 运动辅助
├── flash/compiler/embed/                # EmbeddedMovieClip
├── net/play5d/
│   ├── game/bvn/                        # === 主游戏代码 ===
│   │   ├── MainGame.as                  # 游戏状态机（版本 "V3.3"）
│   │   ├── GameConfig.as                # 游戏常量
│   │   ├── Debugger.as                  # 调试面板（FPS/内存/日志，647行）
│   │   ├── ctrl/                        # 核心控制器层
│   │   │   ├── GameLoader.as            # 角色/地图/辅助 SWF 加载
│   │   │   ├── GameLogic.as             # 物理、碰撞、计分
│   │   │   ├── GameRender.as            # EnterFrame 渲染循环
│   │   │   ├── AssetLoader/             # 资源加载管理
│   │   │   ├── EffectCtrl.as            # 视觉效果
│   │   │   ├── SoundCtrl.as             # BGM/音效
│   │   │   ├── StateCtrl.as             # 状态控制
│   │   │   └── game_ctrls/              # 游戏子控制器
│   │   │       ├── GameCtrl.as          # 中央控制器（toggleFighterAI）
│   │   │       ├── GameStartCtrl.as     # 开场序列
│   │   │       ├── GameEndCtrl.as       # 回合结束
│   │   │       ├── GameMainLogicCtrler.as # 逐帧逻辑
│   │   │       ├── FighterEventCtrl.as
│   │   │       └── TrainingCtrler.as
│   │   ├── data/                        # 数据模型
│   │   │   ├── GameData.as              # 中央数据存储
│   │   │   ├── ConfigVO.as              # 配置 VO
│   │   │   ├── FighterVO/FighterModel   # 角色数据
│   │   │   ├── GameMode.as              # 游戏模式常量
│   │   │   └── HitType.as               # 攻击类型
│   │   ├── fighter/                     # === 角色系统 ===
│   │   │   ├── FighterMain.as           # 角色实体
│   │   │   ├── FighterAction.as         # 动作配置
│   │   │   ├── FighterActionState.as    # 动作状态常量
│   │   │   ├── FighterMC.as             # MovieClip 包装器
│   │   │   └── ctrler/
│   │   │       ├── FighterMcCtrler.as   # 动作状态机
│   │   │       ├── FighterKeyCtrl.as    # 玩家输入
│   │   │       ├── FighterAICtrl.as     # AI 输入
│   │   │       ├── FighterEffectCtrl.as
│   │   │       └── ai/FighterAILogic.as # AI 行为逻辑
│   │   ├── state/                       # 游戏状态（实现 Istage）
│   │   │   ├── LogoState / MenuState / SelectFighterStage
│   │   │   ├── LoadingState / GameLoadingState
│   │   │   ├── GameState / GameCamera
│   │   │   ├── GameOverState / WinnerState / CongratulateState
│   │   │   └── SettingState / HowToPlayState / CreditsState
│   │   ├── ui/                          # UI 组件
│   │   │   ├── GameUI.as                # 主 UI 容器
│   │   │   ├── fight/                   # 战斗 UI（血条/气条/计时/分数）
│   │   │   ├── select/                  # 选人 UI
│   │   │   ├── dialog/                  # 弹窗（Alert/Confirm）
│   │   │   ├── PauseDialog.as           # 暂停菜单
│   │   │   ├── MenuBtn/MenuBtnGroup     # 菜单按钮组
│   │   │   ├── SetBtn/SetBtnGroup       # 设置按钮组
│   │   │   └── SetCtrlBtnUI.as          # 按键设置界面
│   │   ├── events/                      # 全局事件
│   │   ├── input/                       # 输入抽象层
│   │   ├── interfaces/                  # 接口和基类
│   │   │   ├── BaseGameSprite.as        # 基础物理实体
│   │   │   ├── IGameSprite.as           # 游戏精灵接口
│   │   │   └── GameInterface.as         # 平台接口
│   │   ├── map/                         # 地图系统（MapMain/FloorVO）
│   │   ├── mob/                         # === 移动端支持 ===（见 §4）
│   │   ├── utils/                       # 通用工具
│   │   │   └── ResUtils.as              # UI SWF 运行时加载
│   │   └── views/effects/               # 视觉特效
│   └── kyo/                             # === KYO 框架 ===
│       ├── stage/（KyoStageCtrl/Istage）
│       ├── display/（BitmapText/MCNumber/BitmapFont）
│       ├── input/（KyoKeyCode）
│       ├── loader/（KyoURLoader/KyoSoundLoader）
│       ├── sound/（KyoBGSounder）
│       └── utils/（KyoUtils/KyoMath/KyoRandom）
├── _assets/                             # 嵌入资源（PNG/JPG/MP3/BIN）
├── snd_*.as                             # 音效嵌入文件
└── [嵌入资源].as                         # *_png$*.as / *_swf$*.as
```

---

## 4. 核心系统详解

### 4.1 角色系统

#### 动作状态常量（FighterActionState）

| 常量 | 值 | 含义 |
|------|----|------|
| `NORNAL` | 0 | 站立 |
| `ATTACK_ING` | 10 | 攻击中 |
| `SKILL_ING` | 11 | 技能中 |
| `BISHA_ING` | 12 | 必杀中 |
| `BISHA_SUPER_ING` | 13 | 超必杀中 |
| `JUMP_ING` | 14 | 跳跃中 |
| `DASH_ING` | 15 | 冲刺中 |
| `HURT_ACT_ING` | 16 | 受击动作 |
| `DEFENCE_ING` | 20 | 防御中 |
| `HURT_ING` | 21 | 受伤中 |
| `HURT_FLYING` | 22 | 击飞中 |
| `HURT_DOWN` | 23 | 倒地中 |
| `HURT_DOWN_TAN` | 24 | 弹地中 |
| `DEAD` | 30 | 死亡 |
| `FREEZE` | 40 | 冻结 |
| `WAN_KAI_ING` | 50 | 卍解中 |
| `KAI_CHANG` | 60 | 开场 |
| `WIN` | 61 | 胜利 |
| `LOSE` | 62 | 失败 |

#### INFINITE_ENERGY（无限能量）系统

涉及文件：`GameConfig` / `ConfigVO` / `ExtendConfig` / `FighterMcCtrler` / `FighterAction` / `GameInterfaceManager`

- 三值联动：`GameConfig.INFINITE_ENERGY` ↔ `ConfigVO.INFINITE_ENERGY` ↔ `ExtendConfig.INFINITE_ENERGY`
- `FighterMcCtrler.setBisha*()` — 开启时 qi 消耗设为 0
- `FighterMcCtrler.doBisha()` / `doWaiKaiAction()` — 开启时跳过 `useQi()` 检查
- `FighterAction.render()` — 每帧同步 qi 显示值
- `GameInterfaceManager.applyConfig()` — 同步屏幕按钮显示

#### Ghost Step（鬼步）

- 消耗：60 气 + 80 体力，持续 12 帧
- 类型：水平（移速 8）/ 跳跃（移速 -12）/ 下落（移速 15）
- 特性：过程无敌（`isAllowBeHit=false`）+ 可穿越对手（`isCross=true`）

### 4.2 移动端特性

- **TOUCH_MODE** — 默认 `true`（GameConfig）
- **ScreenPadManager** — 屏幕触控按钮管理
- **ScreenPadAsset** — 按钮图片（通过 EmbeddedAssets 引用）
- **GameInterfaceManager** — 移动端菜单/设置/配置同步
- **ScreenRotater** — 屏幕旋转
- **LAN 多人** — `ctrls/` + `sockets/` 局域网对战

#### ANE 扩展（文件读取）

`ANEFileReader` 通过 AIR Native Extension 访问 Android 外部存储，突破 AIR 沙箱限制。

```as3
// 读取外部文件
var ba:ByteArray = ANEFileReader.I.readBytes("/sdcard/BVN/fighters/ichigo.swf");
// 列出目录
var files:Array = ANEFileReader.I.listDir("/sdcard/BVN/fighters/");
// 检查存在
if (ANEFileReader.I.exists("/sdcard/BVN/fighters/")) { ... }
// 从路径加载角色（集成 GameLoader）
GameLoader.loadFighterFromPath("/sdcard/BVN/fighters/ichigo.swf", callback, failCallback);
```

**降级策略**：ANE 未安装时自动降级为 AIR `flash.filesystem.File` API（仅沙箱内可用）。

**Android 侧接口**（待实现原生 Java）：

| 方法 | 输入 | 输出 |
|------|------|------|
| `readBytes` | 文件绝对路径 | `ByteArray` |
| `listDir` | 目录路径 | `Array<String>` |
| `exists` | 路径 | `Boolean` |

**关键文件**：
- `mob/utils/ANEFileReader.as` — AS3 封装
- `ctrl/GameLoader.as::loadFighterFromPath()` — 加载集成
- `tools/Test/application.xml` — 声明扩展 ID `com.bvn.filereader`

### 4.3 关键 Bug 修复记录

| 修复 | 涉及文件 | 说明 |
|------|----------|------|
| PauseDialog visible | `PauseDialog.as` | showMoveList 隐藏按钮组，hideMoveList 恢复 |
| 训练模式 AI 开关 | `GameCtrl.as` + `PauseDialog.as` | `toggleFighterAI()` 绕过模式强制 AI |
| 开场帧检查 | `FighterMcCtrler.as` | sayIntro/doWin/doLose 先 checkFrame |
| INFINITE_ENERGY | `FighterMcCtrler` + `FighterAction` | setBisha/doBisha/doWaiKai/render 全部检查 |
| 嵌入式资源 | `EmbeddedAssets.as` | 统一 [Embed] 管理，直接指向 _assets/ |
| 外部 SWF 加载 | `ResUtils.as` | UI SWF 从 assets/swf/ 运行时加载 |
| 调试器增强 | `Debugger.as` | FPS/内存监视器/游戏状态（647 行） |

---

## 5. 开发规范

### 5.1 交流语言

**所有对话使用中文**，技术术语、代码标识符、文件路径可保留英文。

### 5.2 文件变更表格式

每次代码修改后输出：

```
| # | 文件 | BVNscripts | Outscripts |
|---|------|:---:|:---:|
| 1 | path/to/File.as | ✓ | ✓ |
```

---

## 6. Headroom 上下文压缩

本项目集成 [Headroom](https://github.com/chopratejas/headroom) — AI 上下文压缩层，可降低 **60-95%** token 消耗。

### 启动方式

```bash
# 方式 1：代理模式（推荐，零代码改动）
headroom proxy --port 8787
# 另一个终端
ANTHROPIC_BASE_URL=http://localhost:8787 claude

# 方式 2：直接包装 Claude Code
headroom wrap claude

# 方式 3：查看统计
curl http://localhost:8787/stats
```

### 压缩效果（本项目）

| 内容类型 | 压缩器 | 预计节省 |
|----------|--------|----------|
| JSON 数据（构建输出/日志） | SmartCrusher | 70-90% |
| ActionScript 源码 | CodeCompressor | 40-70% |
| 构建日志 | LogCompressor | 80-95% |
| Grep 搜索结果 | SearchCompressor | 60-80% |

### 排除文件

项目根目录 `.claudeignore` 已排除：`*.swf` / `*.png` / `*.mp3` / `*.bin` / `_assets/` / `flex4.16.1-air51.0.1.1/` / `AIRSDK5/` 等。

---

## 7. 版本信息

| 项目 | 内容 |
|------|------|
| 游戏版本 | V3.3（2019.3.32） |
| 开发商 | 5dplay（net.play5d） |
| 平台 | Flash Web + Android/iOS + LAN 局域网对战 |
| 第三方库 | GreenSock TweenLite、自研 Kyo 框架 |
| SDK | Apache Flex 4.16.1 + AIR 51.0 |
| 编译器 | mxmlc.jar（Java 17） |
| 编辑器 | VSCode + ActionScript & MXML 插件 |
| 许可 | GPL-3.0 |
