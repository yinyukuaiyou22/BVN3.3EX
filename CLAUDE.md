# BVN（死神vs火影）— AS3 格斗游戏

> **AI 开发助手**：请同时阅读 [AGENTS.md](AGENTS.md) 获取本项目专属的开发行为准则和工具配置。

## 项目概述

本项目是 **5dplay 出品的"死神vs火影" V3.3** — 基于 ActionScript 3 开发的 2D Flash 格斗游戏。源码从 SWF 反编译后经手动修复，现基于可编译基线 (`last/`) 持续开发。

- **`BVNscripts/scripts/`** — 可编译源码（含 `_assets/` 嵌入资源和 `mx/` Flex 框架桩）
- **`Outscripts/`** — 修改后脚本导出目录（git 忽略，`sync.py` 同步）
- **`build.bat`** — 编译脚本，`Ctrl+Shift+B` 或直接运行
- **`asconfig.json` / `.vscode/`** — VSCode 构建配置
- **`assets/swf/`** — UI SWF 运行时资源（外部加载）

## 构建与调试

### 环境

| 变量 | 位置 | 用途 |
|------|------|------|
| Flex SDK | `项目根\flex4.16.1-air51.0.1.1\` | mxmlc 编译器 + Flex 框架 + AIR 运行时 |
| AIR SDK | `项目根\AIRSDK5\AIRSDK_51.3.2\` | ADT 打包 / fdb 调试（签名证书位于 `bin\mycert.p12`） |
| `FLEX_HOME` | 自动检测（`flex4.16.1-air51.0.1.1`） | debug 脚本定位 `bin\fdb` |
| `JAVA_HOME` | JDK 17 | mxmlc 运行时 |
| ADB | Android SDK platform-tools | 手机真机调试 |
| 证书 | `AIRSDK5\...\bin\mycert.p12` | APK 签名（密码 123456） |
| App 描述 | `tools\Test\application.xml` | AIR 应用配置（`com.bvn.yinyu`） |

### PC 端编译

```bash
# 编译（VSCode: Ctrl+Shift+B 或直接运行）
./build.bat

# 编译器：mxmlc (Flex SDK)
# 输出：launch.swf（~4.6MB）
```

### PC 端调试

| 工具 | 位置 | 用法 |
|------|------|------|
| `build.bat` | 项目根 | 编译 launch.swf |
| `adl.exe` | `%FLEX_HOME%\bin\` | AIR Debug Launcher，双击 SWF 直接调试 |
| `fdb.bat` | `%FLEX_HOME%\bin\` | Flex 命令行调试器，断点/单步/变量检查 |

```bash
# ADL 启动 SWF（带调试输出）
adl launch.swf

# fdb 调试 FighterTester
tools/script/debug.bat
```

### 手机真机调试（Android APK）

**前置条件**：
- `FLEX_HOME` 指向 AIR SDK 根目录
- `adb` 在 PATH 中
- 手机启用「USB 调试」并连接电脑

```bash
# 1. 打包 APK（ADT Debug Over USB）
adt -package -target apk-debug -storetype pkcs12 -keystore cert.p12 launch.apk launch-app.xml launch.swf

# 2. 一键安装 + 启动 + fdb 实时调试
tools/script/debug_mob.bat
```

脚本自动完成：ADB 设备检测 → 卸载旧版 → 安装 APK → 端口转发 → 启动应用 → fdb 控制台实时回显

**调试脚本组**（位于 `tools/script/`）：

| 脚本 | 目标 | 说明 |
|------|------|------|
| `debug.bat` | PC | 编译 + adl 启动 FighterTester |
| `debug_mob.bat` | 手机 | adb 安装 APK + fdb 实时调试 |
| `fdbg.bat` | 通用 | fdb 连接任意 SWF 进行断点调试 |

## 交流语言

**所有对话必须使用中文**（技术术语、代码标识符、文件路径等可保留英文）。

## 整体架构

```
launch.as（入口，继承 Sprite）
  └─ MainGame.as（游戏状态机，单例）
       └─ KyoStageCtrl（场景/状态管理器）
            └─ 各状态: Logo → Menu → SelectFighter → Loading → GameState → GameOver/Winner
```

**设计模式**: 大量使用单例的类 MVC 架构。核心类通过 `.I` 静态 getter 访问（如 `GameData.I`、`GameCtrl.I`）。

## 目录结构

```
BVNscripts/scripts/
├── launch.as                          # 主入口（Flash 文档类）
├── build.bat                          # 编译脚本
├── EmbeddedAssets.as                  # 嵌入式资源统一管理（所有 PNG/JPG/SWF 的 [Embed]）
├── mx/core/                           # Flex 框架桩（BitmapAsset、ByteArrayAsset 等）
├── com/
│   ├── greensock/                     # TweenLite 补间动画库
│   └── adobe/utils/StringUtil.as      # Adobe 字符串工具
├── fl/motion/                         # Flash 运动辅助
├── flash/compiler/embed/              # EmbeddedMovieClip
├── net/play5d/
│   ├── game/bvn/                      # === 主游戏代码 ===
│   │   ├── MainGame.as                # 游戏状态机（版本 "V3.3"）
│   │   ├── GameConfig.as              # 游戏常量（TOUCH_MODE=true, INFINITE_ENERGY）
│   │   ├── Debugger.as                # 调试面板（日志 + FPS/内存监视器，647 行）
│   │   ├── ctrl/                      # 核心控制器层
│   │   │   ├── GameLoader.as          # 角色/地图/辅助 SWF 加载
│   │   │   ├── GameLogic.as           # 物理、碰撞、计分
│   │   │   ├── GameRender.as          # EnterFrame 渲染循环
│   │   │   ├── AssetLoader/AssetManager  # 资源加载
│   │   │   ├── EffectCtrl.as          # 视觉效果
│   │   │   ├── SoundCtrl.as           # BGM/音效
│   │   │   ├── StateCtrl.as           # 状态控制
│   │   │   └── game_ctrls/            # 游戏子控制器
│   │   │       ├── GameCtrl.as        # 中央控制器（含 toggleFighterAI）
│   │   │       ├── GameStartCtrl.as   # 开场序列
│   │   │       ├── GameEndCtrl.as     # 回合结束
│   │   │       ├── GameMainLogicCtrler.as  # 逐帧逻辑
│   │   │       ├── FighterEventCtrl.as
│   │   │       └── TrainingCtrler.as
│   │   ├── data/                      # 数据模型
│   │   │   ├── GameData.as            # 中央数据存储
│   │   │   ├── ConfigVO.as            # 配置 VO（含 INFINITE_ENERGY）
│   │   │   ├── FighterVO/FighterModel # 角色数据
│   │   │   ├── GameMode.as            # 游戏模式常量
│   │   │   ├── HitType.as             # 攻击类型
│   │   │   └── ...（Mession/Map/Select/Team/Effect 等）
│   │   ├── fighter/                   # === 角色系统 ===
│   │   │   ├── FighterMain.as         # 角色实体
│   │   │   ├── FighterAction.as       # 动作配置（含 INFINITE_ENERGY render sync）
│   │   │   ├── FighterActionState.as  # 动作状态常量
│   │   │   ├── FighterMC.as           # MovieClip 包装器
│   │   │   ├── ctrler/
│   │   │   │   ├── FighterMcCtrler.as # 动作状态机（含 INFINITE_ENERGY/sayIntro checkFrame）
│   │   │   │   ├── FighterKeyCtrl.as  # 玩家输入
│   │   │   │   ├── FighterAICtrl.as   # AI 输入
│   │   │   │   ├── FighterEffectCtrl.as
│   │   │   │   └── ai/FighterAILogic.as  # AI 行为逻辑
│   │   │   ├── models/（FighterHitModel/HitVO）
│   │   │   └── events/
│   │   ├── state/                     # 游戏状态（实现 Istage）
│   │   │   ├── LogoState / MenuState / SelectFighterStage
│   │   │   ├── LoadingState / GameLoadingState
│   │   │   ├── GameState / GameCamera
│   │   │   ├── SettingState / HowToPlayState
│   │   │   ├── GameOverState / WinnerState / CongratulateState
│   │   │   └── CreditsState
│   │   ├── ui/                        # UI 组件
│   │   │   ├── GameUI.as              # 主 UI 容器
│   │   │   ├── fight/                 # 战斗 UI（血条/气条/计时/分数）
│   │   │   ├── select/                # 选人 UI
│   │   │   ├── dialog/                # 弹窗（Alert/Confirm）
│   │   │   ├── PauseDialog.as         # 暂停菜单（返回选人/AI 开关/出招表）
│   │   │   ├── MenuBtn/MenuBtnGroup   # 菜单按钮组
│   │   │   ├── SetBtn/SetBtnGroup     # 设置按钮组
│   │   │   └── SetCtrlBtnUI.as        # 按键设置界面（含 cleanupKeyInput）
│   │   ├── events/                    # 全局事件
│   │   ├── input/                     # 输入抽象层（GameInputer/GameKeyInput）
│   │   ├── interfaces/                # 接口和基类
│   │   │   ├── BaseGameSprite.as      # 基础物理实体
│   │   │   ├── IGameSprite.as         # 游戏精灵接口
│   │   │   └── GameInterface.as       # 平台接口（含 getDefaultMenu）
│   │   ├── map/                       # 地图系统（MapMain/FloorVO）
│   │   ├── mob/                       # === 移动端支持 ===
│   │   │   ├── GameInterfaceManager.as # 平台桥接（菜单/设置/INFINITE_ENERGY）
│   │   │   ├── ScreenRotater.as       # 屏幕旋转
│   │   │   ├── ScreenPadManager.as    # 触控管理器
│   │   │   ├── ctrls/                 # LAN 局域网多人
│   │   │   ├── input/                 # 触控/摇杆/网络输入
│   │   │   ├── screenpad/             # 屏幕触控按钮（ScreenPadAsset 等）
│   │   │   ├── sockets/               # TCP/UDP 网络
│   │   │   ├── views/                 # 移动端视图
│   │   │   └── utils/                 # 移动端工具
│   │   ├── utils/                     # 通用工具
│   │   │   ├── ResUtils.as            # UI SWF 外部运行时加载
│   │   │   └── ...（EffectManager/MCUtils/GameLoger 等）
│   │   └── views/effects/             # 视觉特效
│   └── kyo/                           # === KYO 框架 ===
│       ├── stage/（KyoStageCtrl/Istage）
│       ├── display/（BitmapText/MCNumber/BitmapFont）
│       ├── input/（KyoKeyCode）
│       ├── loader/（KyoURLoader/KyoSoundLoader）
│       ├── sound/（KyoBGSounder）
│       └── utils/（KyoUtils/KyoMath/KyoRandom）
├── _assets/                           # 嵌入资源（PNG/JPG/MP3/BIN）
├── snd_*.as                           # 音效嵌入文件
└── [嵌入资源 .as 文件]                  # *_png$*.as / *_swf$*.as
```

## 核心系统详解

### 1. 启动流程

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

### 2. 游戏状态机

- 非战斗状态 30fps，GameState 60fps
- 流转：Logo → Menu → SelectFighter → Loading → GameState → GameOver/Winner/Congratulate
- 切换：`MainGame.I.goXxx()`

### 3. 角色系统

#### 动作状态常量（FighterActionState）
```
NORNAL=0（站立）  ATTACK_ING=10  SKILL_ING=11  BISHA_ING=12
BISHA_SUPER_ING=13  JUMP_ING=14  DASH_ING=15  HURT_ACT_ING=16
DEFENCE_ING=20  HURT_ING=21  HURT_FLYING=22  HURT_DOWN=23
HURT_DOWN_TAN=24  DEAD=30  FREEZE=40  WAN_KAI_ING=50
KAI_CHANG=60（开场）  WIN=61  LOSE=62
```

#### INFINITE_ENERGY 系统
- `GameConfig.INFINITE_ENERGY` + `ConfigVO.INFINITE_ENERGY` + `ExtendConfig.INFINITE_ENERGY` 三值联动
- `FighterMcCtrler.setBisha*()` — 开启时 qi 消耗设为 0
- `FighterMcCtrler.doBisha()` / `doWaiKaiAction()` — 开启时跳过 `useQi()` 检查
- `FighterAction.render()` — 每帧同步 qi 显示值保持 UI 正常
- `GameInterfaceManager.applyConfig()` — 同步 `superSkillAutoHide` 屏幕按钮显示

#### Ghost Step
- 消耗 60 气 + 80 体力，持续 12 帧
- 三种类型：水平（移速 8）、跳跃（移速 -12）、下落（移速 15）
- 过程无敌（isAllowBeHit=false）且可穿越对手（isCross=true）

### 4. 移动端特性

- **TOUCH_MODE** 默认 `true`（GameConfig）
- **ScreenPadManager** — 屏幕触控按钮管理
- **ScreenPadAsset** — 按钮图片（通过 EmbeddedAssets 引用）
- **GameInterfaceManager** — 移动端菜单/设置（自定义菜单结构）
- **LAN 多人** — ctrls/sockets 局域网对战
- **屏幕旋转** — ScreenRotater

### 5. 关键 Bug 修复记录

| 修复 | 文件 | 说明 |
|------|------|------|
| PauseDialog visible | PauseDialog.as | showMoveList 隐藏按钮组，hideMoveList 恢复 |
| 训练模式 AI 开关 | GameCtrl.as + PauseDialog.as | `toggleFighterAI()` 绕过模式强制 AI |
| 开场帧检查 | FighterMcCtrler.as | sayIntro/doWin/doLose 先 checkFrame |
| INFINITE_ENERGY | FighterMcCtrler + FighterAction | setBisha/doBisha/doWaiKai/render 全部检查 |
| 嵌入式资源 | EmbeddedAssets.as | 统一 [Embed] 管理，直接指向 _assets/ |
| 外部 SWF 加载 | ResUtils.as | UI SWF 从 assets/swf/ 运行时加载 |
| 调试器富功能 | Debugger.as | FPS/内存监视器/游戏状态（647 行） |

### 6. 构建环境

- **SDK**: Apache Flex 4.16.1 + AIR 51.0（`D:\flex4.16.1-air51.0.1.1`）
- **额外 SWC**: `core.swc`（AIR SDK）、`airglobal.swc`（AIR 运行时类）
- **编译器**: `mxmlc`（Java 17 驱动）
- **编辑器**: VSCode + ActionScript & MXML 插件
- **构建**: `Ctrl+Shift+B` 或 `./build.bat`

## 文件变更表格式

每次代码修改后输出：
```
| # | 文件 | BVNscripts | Outscripts |
|---|------|:---:|:---:|
| 1 | path/to/File.as | ✓ | ✓ |
```

## 版本信息

- **游戏版本**：V3.3（2019.3.32）
- **开发商**：5dplay（net.play5d）
- **平台**：Flash Web + Android/iOS 移动端，支持 LAN 局域网对战
- **第三方库**：GreenSock TweenLite、自研 Kyo 框架
- **许可**：GPL-3.0
