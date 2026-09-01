# BVN（死神vs火影）— AS3 格斗游戏

> **AI 开发助手**：请同时阅读 [AGENTS.md](AGENTS.md) 获取本项目专属的开发行为准则和工具配置。简单工作优先交给 `deepseek-v4-flash` 执行。

## 项目概述

本项目是 **5dplay 出品的"死神vs火影" V3.3** — 基于 ActionScript 3 开发的 2D Flash 格斗游戏。源码从 SWF 反编译后经手动修复，现基于可编译基线持续开发。

| 目录                         | 说明                                                        |
| ---------------------------- | ----------------------------------------------------------- |
| `BVNscripts/scripts/`        | 可编译源码（含 `_assets/` 嵌入资源、`mx/` Flex 框架桩）     |
| `Outscripts/`                | 修改后脚本导出目录（git 忽略，`sync.py` 同步回 BVNscripts） |
| `tools/Test/`                | 编译产物与运行时资源                                        |
| `tools/Test/assets/`         | 运行时加载资源：角色 SWF / 地图 / BGM / 头像 / 配置文件     |
| `tools/script/`              | 调试/打包/同步脚本                                          |
| `extensions/BVNFileReader/`  | ANE 原生扩展（Java + AS3）                                  |
| `reference/BVN3.9/`          | BVN 3.9 参考源码（只读，多模块 CORE/LIB/SHELL 结构）        |
| `build.bat`                  | 一键编译脚本（`Ctrl+Shift+B` 或直接运行）                   |
| `asconfig.json` / `.vscode/` | VSCode 构建配置                                             |

## 构建与调试

### 环境配置

| 变量           | 位置                                           | 用途                                                   |
| -------------- | ---------------------------------------------- | ------------------------------------------------------ |
| Flex + AIR SDK | `AIRSDK\flex4.16.1-air51.0.1.1\`               | mxmlc 编译 + ADT 打包 + fdb 调试（合并包）             |
| JDK 8          | `D:\JDK8\`                                     | ANE Java 编译（必须 JDK 8 兼容 build-tools d8）        |
| Android SDK    | `D:\Android\SDK\`                              | ADT `-platformsdk`（platform-33 + build-tools 33.0.2） |
| `FLEX_HOME`    | 自动检测 → 合并 SDK                            | 调试脚本定位 `bin\fdb.bat`、`bin\adt.bat`              |
| `JAVA_HOME`    | JDK 17                                         | mxmlc 运行时                                           |
| ADB            | `tools\platform-tools\adb.exe`                 | 手机真机调试                                           |
| 证书           | `AIRSDK\flex4.16.1-air51.0.1.1\bin\mycert.p12` | APK 签名（密码 yinyu7798）                             |
| App 描述       | `tools\Test\application.xml`                   | AIR 应用配置（`<id>com.bvn33.y36</id>`）— Android 端包名派生为 `air.com.bvn.yy798`，私有目录内 ID 又是 `com.bvn.yy798`（与 applicationID 不一致，详见下方「应用包名澄清」）|

### PC 端开发

```bash
# 编译（VSCode: Ctrl+Shift+B 或直接运行）
./build.bat

# 编译器：mxmlc (Flex SDK)
# 源文件：BVNscripts/scripts/launch.as
# 输出：tools/Test/launch.swf（~4.6MB）
```

#### 调试工具

| 工具            | 位置            | 用途                                                      |
| --------------- | --------------- | --------------------------------------------------------- |
| `build.bat`     | 项目根          | 编译 tools/Test/launch.swf                                |
| `debug.bat`     | `tools/script/` | 编译 + adl 启动（启动时询问 SWF 路径，回车使用默认）      |
| `debug_mob.bat` | `tools/script/` | 编译 → ADT 打包 → ADB 安装 → adb logcat 实时日志          |
| `fdbg.bat`      | `tools/script/` | 通用 fdb 连接 SWF 断点调试（支持命令行参数指定 SWF 路径） |

| `add_asset.py` | `tools/script/` | 自动添加角色/辅助/地图到游戏（向导/快速/批量模式） |

`tools/script/lang/` 目录包含多代码页包装脚本（437/932/936/949），解决系统编码兼容。

### 移动端开发（Android）

#### 前置条件

- `FLEX_HOME` 指向合并 SDK 根目录（`AIRSDK\flex4.16.1-air51.0.1.1\`）
- `adb` 在 PATH 中（或使用 `tools/platform-tools/adb.exe`）
- 手机启用「USB 调试」并连接电脑

#### APK 打包与调试

```bash
# 一键：编译 + 打包 + 安装 + logcat 实时日志（debug_mob.bat 自动完成全部）
tools/script/debug_mob.bat

# 手动打包（Captive Runtime, armv8, 从 tools/Test 目录执行）
cd tools/Test
adt -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%FLEX_HOME%\bin\mycert.p12" -storepass yinyu7798 bvn.apk application.xml -platformsdk "D:/Android/SDK" launch.swf -C . assets\effect.swf -C . assets\movelist.jpg -C . assets\swf -C . assets\sounds -C . assets\font -C . assets\config
```

> **APK 白名单打包**：仅 `effect.swf` + `movelist.jpg` + `swf/` + `sounds/` + `font/` + `config/` 进 APK。fighter/map/face/bgm 从外部存储加载。BGM 瘦身逻辑已注释保留。

#### 纯 Android 端打包（Termux 原生，armv8）

当没有 PC 可用时，可直接在 Android 手机 Termux 中完成打包。以下为已验证的完整流程：

**0. 前置准备**

- Termux（F-Droid 版，Play Store 版不兼容）
- 项目代码已位于 `~/storage/shared/BVN3.3EX-master/`
- `launch.swf` 已通过 `./build.bat`（PC 端）编译产出并放置在 `tools/Test/`

**1. 安装依赖**

```bash
# Java 17（ADT 运行时）
pkg install -y openjdk-17

# Android SDK 命令行工具
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
curl -O https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*.zip
mv cmdline-tools latest

# 安装 platform-33 和 build-tools
yes | ~/android-sdk/cmdline-tools/latest/bin/sdkmanager "platforms;android-33"
yes | ~/android-sdk/cmdline-tools/latest/bin/sdkmanager "build-tools;33.0.0"
```

**2. 处理 aapt 架构兼容性（关键步骤）**

sdkmanager 安装的 build-tools 中的 `aapt` 是 **x86 二进制**，无法在 aarch64 Termux 中运行。需要用 Termux 原生 aapt 替换：

```bash
# 安装 Termux 原生 aapt
pkg install -y x11-repo
pkg install -y aapt

# 覆盖 SDK 中的 x86 版 aapt
rm ~/android-sdk/build-tools/*/aapt
ln -s /data/data/com.termux/files/usr/bin/aapt ~/android-sdk/build-tools/33.0.0-*/aapt
```

> ⚠️ **注意**：sdkmanager 安装的 build-tools 实际目录名可能带后缀（如 `33.0.0-2`），请用 `ls ~/android-sdk/build-tools/` 确认后替换路径。

**2.5 编译 SWF（手机端直接编译，无需 PC）**

在 Termux 中即可用 Flex SDK 的 `mxmlc.jar` 把源码编译成 `launch.swf`，只要装了 **Java 17**（步骤 1 已装），**不需要 Android SDK**。修改 `BVNscripts/scripts/` 下的 `.as` 源码后，在项目根目录执行：

```bash
cd ~/storage/shared/BVN3.3EX-master

# 单行版（复制整行执行）
java -jar flex4.16.1-air51.0.1.1/lib/mxmlc.jar +flexlib=flex4.16.1-air51.0.1.1/frameworks -debug=true -swf-version=37 -strict=false -source-path+=BVNscripts/scripts -library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/core.swc -external-library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/air/airglobal.swc -output=tools/Test/launch.swf -- BVNscripts/scripts/launch.as
```

> **关键参数**（漏一个都可能失败，详见 AGENTS.md「安卓端开发要点」）：
> - `-strict=false` **必须**：预存反编译的类型不匹配错误（ScreenRotater、GameInputer、JsonUtils、ANEFileReader 等）会阻止 SWF 产出，且 mxmlc 静默返回 exitCode=0 但无产物。
> - `-external-library-path+=airglobal.swc` **必须**：提供 AIR 运行时类（ANEFileReader、FileUtils 等），否则报 `Type was not found`。
> - `-library-path+=core.swc`：Flash 核心库依赖。
> - `-swf-version=37`：对应 AIR 51.0。

**编译成功**：`tools/Test/launch.swf` 生成（手机端约 30+MB），编译过程无 error/warning 输出。
**排查**：若进程刚启动就退出但仍 return 0 且无 SWF，多半是丢了 `-strict=false`。

- 若需在后台编译避免前台超时，可在命令后追加 `> /sdcard/build_log.txt 2>&1 &`，随后用 `tail -30 /sdcard/build_log.txt` 轮询进度。
- 编译随后按 **步骤 3** 打包 APK。

**3. 打包 APK**

```bash
cd ~/storage/shared/BVN3.3EX-master/tools/Test

java -jar ../../flex4.16.1-air51.0.1.1/lib/adt.jar \
  -package -target apk-captive-runtime \
  -arch armv8 \
  -storetype pkcs12 \
  -keystore ../../flex4.16.1-air51.0.1.1/bin/mycert.p12 \
  -storepass yinyu7798 \
  bvn.apk application.xml \
  -platformsdk "$HOME/android-sdk" \
  launch.swf
```

成功后输出 `NOTE: The application has been packaged with a captive runtime.`，APK 产出在 `tools/Test/bvn.apk`。

**4. 安装到手机**

```bash
# 如果装了 ADB（USB/WiFi 调试）
adb install bvn.apk

# 或直接用 Android 文件管理器点击 bvn.apk 安装
```

**常见问题排查**

| 错误 | 原因 | 解决 |
|------|------|------|
| `java: command not found` | 未装 Java | `pkg install -y openjdk-17` |
| `Unable to find build tools folder` | 缺 build-tools 或目录不完整 | 用 sdkmanager 安装 `build-tools;33.0.0` |
| `aapt tool failed: Syntax error: "(" unexpected` | SDK 的 aapt 是 x86 二进制 | 用 Termux 原生 aapt 替换（见步骤 2） |
| `Could not locate Android SDK` | `-platformsdk` 路径错误 | 确认 `~/android-sdk/platforms/android-33/android.jar` 存在 |
| `aapt: No such file or directory` | 替换后链接断裂 | `which aapt` 确认，重新 `ln -s` |

### 运行时资源结构（`tools/Test/assets/`）

编译产物 `launch.swf` 在运行时从此目录加载外部资源：

```
tools/Test/assets/
├── swf/                  # UI SWF（common_ui/fight/gameover/howtoplay/loading/select/setting/title）
├── config/               # 游戏配置 XML（被 git 追踪）
│   ├── fighter.xml       # 角色定义（~3488行）
│   ├── select.xml        # 选人界面布局
│   ├── map.xml           # 地图列表
│   ├── mission.xml       # 闯关模式关卡
│   ├── assist.xml        # 辅助角色定义
│   └── preload.xml       # 预加载列表
├── fighter/              # 角色 SWF 文件
├── face/                 # 角色头像图片
├── bgm/                  # 背景音乐
├── map/                  # 地图 SWF 文件
├── sounds/               # 音效文件
└── font/                 # 字体文件
```

## 交流语言

**所有回答必须使用中文**。仅代码标识符、文件路径、技术术语缩写（如 API/ANE/SDK/ADT/XML/SWF）可保留英文。禁止整段英文输出。

## 整体架构

```
launch.as（入口，继承 Sprite，Flash 文档类）
  └─ MainGame.as（游戏状态机，单例 MainGame.I）
       └─ KyoStageCtrl（场景/状态管理器，KyoStageEvent 驱动）
            └─ 各状态: Logo → Menu → SelectFighter → Loading → GameState → GameOver/Winner/Congratulate
```

**设计模式**: 大量使用单例的类 MVC 架构。核心类通过 `.I` 静态 getter 访问（如 `GameData.I`、`GameCtrl.I`、`MainGame.I`）。

## 目录结构

```
BVNscripts/scripts/
├── launch.as                            # 主入口（Flash 文档类）
├── EmbeddedAssets.as                    # 嵌入式资源统一管理（[Embed] 元标签）
├── mx/core/                             # Flex 框架桩（BitmapAsset/ByteArrayAsset/FlexBitmap）
├── mx/utils/                            # Flex 工具桩
├── com/
│   ├── greensock/                       # TweenLite 补间动画库（core/easing）
│   └── adobe/utils/                     # Adobe 字符串工具
├── fl/motion/                           # Flash 运动辅助（ColorMatrix/DynamicMatrix）
├── flash/compiler/embed/                # EmbeddedMovieClip
├── net/play5d/
│   ├── game/bvn/                        # === 主游戏代码 ===
│   │   ├── MainGame.as                  # 游戏状态机（版本 "V3.3"）
│   │   ├── GameConfig.as                # 游戏常量（TOUCH_MODE/G/物理参数/FPS/气力/防御参数）
│   │   ├── GameQuailty.as               # 画质设置
│   │   ├── Debugger.as                  # 调试面板（DEBUG_PANEL_ENABLED 开关 + FPS/内存监视器）
│   │   ├── ctrl/                        # 核心控制器层
│   │   │   ├── GameLoader.as            # 角色/地图/辅助 SWF 加载 + 外部角色扫描（loadFighterFromPath）。兼容新式 main_mc 人物包：loadFighter/loadFighterFromPath 用 applicationDomain.getDefinition("main_mc") 解析，成功用 main_mc 实例作角色主 MC，失败回退旧式 SWF 根
│   │   │   ├── GameLogic.as             # 物理、碰撞、计分
│   │   │   ├── GameRender.as            # EnterFrame 渲染循环
│   │   │   ├── EffectCtrl.as            # 视觉效果控制
│   │   │   ├── SoundCtrl.as             # BGM/音效控制
│   │   │   ├── StateCtrl.as             # 状态控制
│   │   │   ├── AssetLoader.as           # 资源加载器接口
│   │   │   ├── AssetManager.as          # 资源管理器
│   │   │   └── game_ctrls/              # 游戏子控制器
│   │   │       ├── GameCtrl.as          # 中央控制器（addFighter/setFighterActionCtrl/toggleFighterAI）
│   │   │       ├── GameStartCtrl.as     # 开场序列
│   │   │       ├── GameEndCtrl.as       # 回合结束
│   │   │       ├── GameMainLogicCtrler.as  # 逐帧逻辑（碰撞检测/攻击判定）
│   │   │       ├── FighterEventCtrl.as  # 角色事件分发
│   │   │       └── TrainingCtrler.as    # 训练模式控制器
│   │   ├── data/                        # 数据模型
│   │   │   ├── GameData.as              # 中央数据存储（单例）
│   │   │   ├── ConfigVO.as              # 用户配置 VO（AI_level/按键等）
│   │   │   ├── FighterVO.as             # 角色定义 VO
│   │   │   ├── FighterModel.as          # 角色数据模型
│   │   │   ├── AssisterModel.as         # 辅助角色模型
│   │   │   ├── MapVO.as / MapModel.as   # 地图数据
│   │   │   ├── MessionVO.as / MessionModel.as / MessionStageVO.as  # 闯关模式
│   │   │   ├── GameMode.as              # 游戏模式
│   │   │   ├── GameRunDataVO.as / GameRunFighterGroup.as  # 运行数据
│   │   │   ├── SelectVO.as / SelectCharListConfigVO.as / SelectCharListItemVO.as / SelectStageConfigVO.as  # 选人数据
│   │   │   ├── TeamVO.as / TeamMap.as   # 组队数据
│   │   │   ├── EffectVO.as / EffectModel.as  # 特效数据
│   │   │   ├── KeyConfigVO.as           # 按键配置
│   │   │   ├── BitmapDataCacheVO.as     # 位图缓存
│   │   │   └── HitType.as               # 攻击类型常量
│   │   ├── fighter/                     # === 角色系统 ===
│   │   │   ├── FighterMain.as           # 角色实体（继承 BaseGameSprite）
│   │   │   ├── FighterMC.as             # 角色 MovieClip 封装
│   │   │   ├── FighterAction.as         # 动作配置（帧标签/气力消耗）
│   │   │   ├── FighterActionState.as    # 动作状态常量 + isAttacking() 等静态工具
│   │   │   ├── FighterAttacker.as       # 攻击者逻辑
│   │   │   ├── FighterDefenseType.as    # 防御类型枚举
│   │   │   ├── FighterHitRange.as       # 攻击判定范围
│   │   │   ├── Assister.as              # 辅助角色实体
│   │   │   ├── Bullet.as                # 飞行道具
│   │   │   ├── ctrler/                  # 角色控制器
│   │   │   │   ├── FighterMcCtrler.as   # 动作状态机（核心：doBisha/doWaiKai/useQi/setAction）
│   │   │   │   ├── FighterCtrler.as     # 角色综合控制器（initFighter 双注入：优先 param1.mc.initFighter({fighter_ctrler,mc_ctrler,effect_ctrler})，失败回退 setEffectCtrler/setFighterMcCtrler，兼容新旧人物包）
│   │   │   │   ├── FighterKeyCtrl.as    # 玩家键盘/触控输入 → 实现 IFighterActionCtrl
│   │   │   │   ├── FighterAICtrl.as     # AI 输入适配器
│   │   │   │   ├── FighterAttackerCtrler.as  # 攻击者控制
│   │   │   │   ├── FighterBuffCtrler.as # Buff 控制
│   │   │   │   ├── FighterEffectCtrl.as # 角色特效控制
│   │   │   │   ├── FighterVoice.as      # 角色语音
│   │   │   │   ├── FighterVoiceCtrler.as # 语音控制
│   │   │   │   ├── AssisiterCtrler.as   # 辅助角色控制
│   │   │   │   └── ai/                  # AI 行为逻辑
│   │   │   │       ├── FighterAILogic.as      # AI 行为实现（1146行，12+子系统）
│   │   │   │       └── FighterAILogicBase.as  # AI 概率决策引擎基类（302行，含 AImain 集成）
│   │   │   ├── events/                  # 角色事件
│   │   │   │   ├── FighterEvent.as
│   │   │   │   └── FighterEventDispatcher.as
│   │   │   ├── models/                  # 角色模型
│   │   │   │   ├── FighterHitModel.as
│   │   │   │   └── HitVO.as
│   │   │   ├── utils/                   # 角色工具
│   │   │   │   └── McAreaCacher.as      # MovieClip 判定区缓存
│   │   │   └── vos/                     # 角色 VO
│   │   │       ├── FighterBuffVO.as
│   │   │       └── MoveTargetParamVO.as
│   │   ├── state/                       # 游戏状态
│   │   │   ├── LogoState.as / MenuState.as / HowToPlayState.as / SettingState.as
│   │   │   ├── SelectFighterStage.as    # 选人界面（含分页布局）
│   │   │   ├── LoadingState.as / GameLoadingState.as
│   │   │   ├── GameState.as / GameCamera.as
│   │   │   ├── GameOverState.as / WinnerState.as / CongratulateState.as
│   │   │   └── CreditsState.as
│   │   ├── ui/                          # UI 组件
│   │   │   ├── GameUI.as / IGameUI.as
│   │   │   ├── KeyMapping.as            # 按键映射
│   │   │   ├── MenuBtn.as / MenuBtnGroup.as  # 菜单按钮系统
│   │   │   ├── PauseDialog.as           # 暂停菜单（含 MoveListSp）
│   │   │   ├── MoveListSp.as            # 出招表
│   │   │   ├── SetCtrlBtnUI.as          # 按键设置界面
│   │   │   ├── SetBtn.as / SetBtnGroup.as / SetBtnDialog.as / SetBtnLine.as
│   │   │   ├── QuickTransUI.as / TransUI.as  # 过渡动画
│   │   │   ├── WinUI.as                 # 胜利 UI
│   │   │   ├── UIUtils.as
│   │   │   ├── fight/                   # 战斗 UI
│   │   │   │   ├── FightUI.as           # 战斗主 UI
│   │   │   │   ├── FighterHpBar.as / FightBar.as / EnergyBar.as / QiBar.as / FightQiBarMode.as
│   │   │   │   ├── FightFaceUI.as / FightFaceGroup.as  # 头像
│   │   │   │   ├── FightScoreUI.as / FightTimeUI.as / HitsUI.as
│   │   │   ├── select/                  # 选人 UI
│   │   │   │   ├── SelectFighterItem.as / SelecterItemUI.as
│   │   │   │   ├── SelectedFighterUI.as / SelectedFighterGroup.as
│   │   │   │   ├── SelectIndexUI.as / SelectIndexUIGroup.as
│   │   │   │   ├── MapSelectUI.as / SelectUIFactory.as
│   │   │   └── dialog/                  # 弹窗
│   │   │       ├── AlertUI.as / ConfrimUI.as
│   │   ├── events/                      # 全局事件
│   │   │   ├── GameEvent.as / SetBtnEvent.as
│   │   ├── input/                       # 输入抽象层
│   │   │   ├── GameInputer.as / GameInputType.as / GameKeyInput.as / IGameInput.as
│   │   ├── interfaces/                  # 接口和基类
│   │   │   ├── BaseGameSprite.as        # 基础物理实体（x/y/vx/vy/g 等）
│   │   │   ├── IGameSprite.as / GameInterface.as / IAssetLoader.as
│   │   │   ├── IExtendConfig.as / IFighterActionCtrl.as / IGameInterface.as
│   │   │   ├── IInnerSetUI.as / ILoger.as
│   │   ├── map/                         # 地图系统
│   │   │   ├── MapMain.as / FloorVO.as
│   │   ├── mob/                         # === 移动端支持 ===
│   │   │   ├── GameInterfaceManager.as  # 平台桥接（菜单/设置/INFINITE_ENERGY 同步）
│   │   │   ├── ScreenRotater.as         # 屏幕旋转
│   │   │   ├── ctrls/                   # 移动端控制器
│   │   │   │   ├── MobileCtrler.as / LANClientCtrl.as / LANServerCtrl.as
│   │   │   │   ├── LANGameCtrl.as / LanGameMenuCtrl.as
│   │   │   │   ├── LockFrameClientLogic.as / LockFrameServerLogic.as  # 锁帧同步
│   │   │   │   └── SelectFighterClientLogic.as / SelectFighterServerLogic.as
│   │   │   ├── data/                    # 移动端数据
│   │   │   │   ├── ExtendConfig.as      # 扩展配置（INFINITE_ENERGY 三值联动）
│   │   │   │   ├── ScreenPadConfigVO.as / SocketInputData.as
│   │   │   │   ├── ClientVO.as / HostVO.as
│   │   │   ├── events/                  # 移动端事件
│   │   │   │   ├── LanEvent.as / ScreenPadEvent.as
│   │   │   ├── input/                   # 移动端输入
│   │   │   │   ├── InputManager.as / ScreenPadInput.as / GameJoystickInput.as
│   │   │   │   ├── GameSocketInput.as / JoySticker.as / JoyStickConfigVO.as / JoyStickSetVO.as
│   │   │   ├── screenpad/               # 屏幕触控按钮
│   │   │   │   ├── ScreenPadManager.as / ScreenPadGame.as / ScreenPadSelectFighter.as
│   │   │   │   ├── ScreenPadBtn.as / ScreenPadBtnBase.as / ScreenPadArrow.as
│   │   │   │   ├── ScreenPadAsset.as    # 按钮素材（light 修复：真实 light.png）
│   │   │   │   └── ScreenPadUtils.as
│   │   │   ├── sockets/                 # 网络通信（TCP + UDP 混合）
│   │   │   │   ├── SocketClient.as / SocketServer.as
│   │   │   │   ├── PacketBuffer.as / PacketUtils.as
│   │   │   │   ├── events/SocketEvent.as
│   │   │   │   └── udp/UDPSocket.as / UDPDataVO.as / UdpDataType.as
│   │   │   ├── utils/                   # 移动端工具
│   │   │   │   ├── ANEFileReader.as     # ANE 文件读取封装（降级到 flash.filesystem）
│   │   │   │   ├── FileUtils.as / JsonUtils.as / LANUtils.as / LockFrameLogic.as
│   │   │   │   ├── SocketMsgFactory.as / UIAssetUtil.as
│   │   │   │   ├── AdManager.as / UMengAneManager.as
│   │   │   │   ├── LanSyncType.as / MsgType.as / SelectFighterDataType.as
│   │   │   └── views/                   # 移动端视图
│   │   │       ├── ViewManager.as / GameSideBg.as
│   │   │       ├── CustomScreenBtnView.as / CustomSetBtnItemUI.as / SetScreenBtnView.as
│   │   │       ├── JoyStickSetUI.as / AdPauseView.as
│   │   │       └── lan/LANGameState.as / LANHostCreateDialog.as / HostDialogItem.as / LANExitDialog.as
│   │   ├── utils/                       # 通用工具
│   │   │   ├── ResUtils.as              # UI SWF 运行时加载（从 assets/swf/ 加载）
│   │   │   ├── EffectManager.as / GameLoger.as / KeyBoarder.as
│   │   │   ├── MCUtils.as / BitmapAssetLoader.as / URL.as
│   │   └── views/                       # 视觉效果视图
│   │       └── effects/
│   │           ├── EffectView.as / BishaFaceEffectView.as / BitmapFilterView.as
│   │           ├── BlackBackView.as / BuffEffectView.as / ShadowEffectView.as
│   │           ├── ShineEffectView.as / SpecialEffectView.as / SteelHitEffect.as
│   └── kyo/                             # === KYO 框架 ===
│       ├── stage/KyoStageCtrl.as / Istage.as / KyoStageEvent.as
│       │   └── effect/IStageFadEffect.as / ZoomEffect.as
│       ├── display/BitmapText.as / MCNumber.as
│       │   ├── bitmap/BitmapFont.as / BitmapFontLoader.as / BitmapFontText.as
│       │   └── shapes/Box.as
│       ├── input/KyoKeyCode.as / KyoKeyVO.as
│       ├── loader/KyoURLoader.as / KyoSoundLoader.as / KyoClassLoader.as / BitmapLoader.as
│       ├── sound/KyoBGSounder.as
│       └── utils/KyoMath.as / KyoRandom.as / KyoUtils.as / setFrameOut.as / UUID.as / WebUtils.as
├── _assets/                             # 嵌入资源（PNG/JPG/MP3，编译进 SWF）
├── snd_*.as                             # 独立音效嵌入文件
└── [嵌入资源].as                         # *_png$*.as / *_swf$*.as 资源嵌入类
```

### 其他重要目录

| 目录                                                       | 说明                                                                                                                          |
| ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `extensions/BVNFileReader/`                                | ANE 原生扩展完整实现（Android Java + AS3 库 + 构建脚本）                                                                      |
| `extensions/BVNFileReader/Android/src/com/bvn/filereader/` | Java 源码：Extension / ExtensionContext / ReadBytesFunction / ListDirFunction / ExistsFunction                                |
| `extensions/BVNFileReader/as3/com/bvn/filereader/`         | AS3 库：BVNFileReaderLib.as                                                                                                   |
| `tools/ane/`                                               | 旧版 ANE 实现（功能已由 extensions/BVNFileReader 取代）                                                                       |
| `tools/platform-tools/`                                    | Android SDK 工具（adb/fastboot/sqlite3）                                                                                      |
| `tools/script/lang/`                                       | 多代码页 bat 包装（437/932/936/949 编码适配）                                                                                 |
| `reference/BVN3.9/`                                        | BVN 3.9 参考源码（CORE_Components/CORE_KernelLogic/CORE_Shared/CORE_Utils/LIB_KyoLib/LIB_Other/SHELL_Dev/SHELL_Mob/SHELL_Pc） |
| `.codegraph/`                                              | Codegraph 知识图谱索引                                                                                                        |
| `.claude/`                                                 | Claude Code 会话数据                                                                                                          |

## 核心系统

### 角色系统

#### 动作状态常量（FighterActionState）

| 常量              | 值  | 含义        |
| ----------------- | --- | ----------- |
| `NORNAL`          | 0   | 站立        |
| `ATTACK_ING`      | 10  | 攻击中      |
| `SKILL_ING`       | 11  | 技能中      |
| `BISHA_ING`       | 12  | 必杀中      |
| `BISHA_SUPER_ING` | 13  | 超必杀中    |
| `JUMP_ING`        | 14  | 跳跃中      |
| `DASH_ING`        | 15  | 冲刺/瞬步中 |
| `JUSHOU_ING`      | 16  | 受身中      |
| `DEFENCE_ING`     | 20  | 防御中      |
| `HURT_ING`        | 21  | 受伤中      |
| `HURT_FLYING`     | 22  | 击飞中      |
| `HURT_DOWN`       | 23  | 倒地中      |
| `DEAD`            | 30  | 死亡        |
| `ATTACK_AIR`      | 40  | 空中攻击    |
| `WAN_KAI_ING`     | 50  | 卍解中      |
| `KAI_CHANG`       | 60  | 开场        |
| `WIN`             | 61  | 胜利        |
| `LOSE`            | 62  | 失败        |

静态工具方法：`isAttacking(state)`, `isHurt(state)`, `isNormal(state)` 等。

#### IFighterActionCtrl 接口（31 方法）

PC 版在原始 26 方法基础上扩展了 5 个：

- **方向移动**: `moveLEFT()` / `moveRIGHT()` / `moveUP()` / `moveDOWN()`
- **跳跃**: `jump()` / `jumpQuick()` / `jumpDown()`
- **瞬步**: `dash()` / `dashJump()`
- **攻击**: `attack()` / `attackAIR()` / `holdAttack()`
- **技能**: `skill1()` / `skill2()` / `holdSkill()` / `skillAIR()`
- **必杀**: `bisha()` / `bishaUP()` / `bishaSUPER()` / `bishaAIR()` / `holdBisha()`
- **其他**: `defense()` / `waiKai()` / `catch1()` / `catch2()` / `ghostStep()` / `ghostJump()` / `ghostJumpDown()` / `assist()` / `specailSkill()`
- **招式**: `zhao1()` / `zhao2()` / `zhao3()`
- **万解变体**: `waiKaiW()` / `waiKaiS()`

#### AI 系统（双层决策架构）

```
IFighterActionCtrl (接口)
       |
 FighterKeyCtrl (玩家输入)    FighterAICtrl (AI 输入适配器)
                                    |
                              FighterAILogic (内置概率 AI, 1146 行)
                                    |
                              FighterAILogicBase (概率决策引擎, 302 行)
                                    |
                            [AImain 元件] (角色 SWF 内嵌自定义 AI, level >= 6 激活)
```

**核心机制**:

- **6 元概率数组** `[p0,p1,p2,p3,p4,p5]` 对应 AI 等级 1,2,3,4,5,6+
- **对手状态感知**: `getAIByFighterState()` 根据对手 actionState 动态选择概率数组
- **连招连续性**: `_isConting` 状态 + `ContOrder` 优先级队列（降序 + 随机微调）
- **AImain 集成**: 每个角色 SWF 可含 `AImain` MovieClip，提供 `updateActionAI()`（覆盖内置逻辑）和 `getActionAI()`（微调概率数组）两个钩子

AI 等级：
| 等级 | 说明 |
|------|------|
| 0-1 | 最低概率，几乎不行动 |
| 2 | 低概率 |
| 3 | 中等概率 |
| 4 | 较高概率 |
| 5 | 高概率 |
| 6 | 最高概率 + AImain 激活 |
| 7 (CRAZY) | 疯狂难度（需额外代码支持） |

> 详细 AI 系统文档见 [AI-SYSTEM-DOC.md](AI-SYSTEM-DOC.md)

#### INFINITE_ENERGY（无限能量）

涉及文件：`GameConfig` / `ConfigVO` / `ExtendConfig` / `FighterMcCtrler` / `FighterAction` / `GameInterfaceManager`

- 三值联动：`GameConfig.INFINITE_ENERGY` ↔ `ConfigVO.INFINITE_ENERGY` ↔ `ExtendConfig.INFINITE_ENERGY`
- `FighterMcCtrler.setBisha*()` — 开启时 qi 消耗设为 0
- `FighterMcCtrler.doBisha()` / `doWaiKaiAction()` — 开启时跳过 `useQi()` 检查
- `FighterAction.render()` — 每帧同步 qi 显示值

#### Ghost Step（鬼步）

- 消耗：60 气 + 80 体力，持续 12 帧
- 类型：水平（移速 8）/ 跳跃（移速 -12）/ 下落（移速 15）
- 过程无敌 + 可穿越对手

### 游戏模式

| 模式        | 常量                  | 值  | 菜单     | 选人数 |
| ----------- | --------------------- | --- | -------- | ------ |
| 小队闯关    | `TEAM_ACRADE`         | 10  | 小队模式 | 3v3    |
| 小队对战    | `TEAM_VS_PEOPLE`      | 11  | 小队模式 | 3v3    |
| 小队vsCPU   | `TEAM_VS_CPU`         | 12  | 小队模式 | 3v3    |
| 小队观战    | `TEAM_WATCH`          | 13  | 小队模式 | 3v3    |
| 小队2v2     | `TEAM_DUO`            | 14  | 小队模式 | 2v2    |
| 小队2v2观战 | `TEAM_DUO_WATCH`      | 15  | 小队模式 | 2v2    |
| 单人闯关    | `SINGLE_ACRADE`       | 20  | 单人模式 | 1v1    |
| 单人2P      | `SINGLE_VS_PEOPLE`    | 21  | 单人模式 | 1v1    |
| 单人vsCPU   | `SINGLE_VS_CPU`       | 22  | 单人模式 | 1v1    |
| 单人观战    | `SINGLE_WATCH`        | 23  | 单人模式 | 1v1    |
| 单人1v2     | `SINGLE_VS_DUO`       | 24  | 单人模式 | 1v2    |
| 单人1v2观战 | `SINGLE_VS_DUO_WATCH` | 25  | 单人模式 | 1v2    |
| 生存模式    | `SURVIVOR`            | 30  | 其他     | 1v1    |
| 练习模式    | `TRAINING`            | 40  | 主菜单   | 1v1    |

> 2v2/1v2 模式复用原版预留的 Debugger.\_getModeName 槽位。`GameMode.getSelectCount(playerId)` 参数化选人数。
> 2v2 多人同屏：`buildGame()` 额外 `addFighter(fighter2)`，同队偏移 ±60px。

### 观战模式（Watch / Spectator Mode）实现方案

> **重要前提**：观战模式**不是从零开发**，而是**已存在但被隐藏/不完整**的功能修复 + 体验增强方案。
> 当前代码已经具备 4 个观战模式常量（13/15/23/25）、`GameMode.isWatch()` 判断、`GameCtrl.addFighter` AI 接管分支、手柄路由观战双禁用逻辑，但**用户从主菜单无法触达**（PC 版主菜单 `MenuBtnGroup.as` 缺观战入口，移动端 `GameInterfaceManager.as` 入口依赖"小队模式"→"2P对战"挂载点未列出观战），且部分边界场景未跑通验证。

#### 1. 现状盘点（已实现的 8 个组件）

| # | 组件 | 位置 | 状态 |
|---|---|---|:---:|
| 1 | 4 个观战常量 `TEAM_WATCH(13) / TEAM_DUO_WATCH(15) / SINGLE_WATCH(23) / SINGLE_VS_DUO_WATCH(25)` | `data/GameMode.as:13/18/26/30` | ✅ |
| 2 | `GameMode.isWatch(param1)` 判定（默认含 TRAINING=40） | `data/GameMode.as:92-95` | ✅ |
| 3 | `GameMode.isVsCPU()` 内联调用 `isWatch(param1)`，自动让 P2 走 AI | `data/GameMode.as:87-90` | ✅ |
| 4 | `GameCtrl.addFighter` case 0/1 都判 `isWatch(false)`，双方都用 `FighterAICtrl` 接管 | `ctrl/game_ctrls/GameCtrl.as:321/333` | ✅ |
| 5 | AI 等级用 `MessionModel.I.AI_LEVEL`（闯关关卡配置） | `GameCtrl.as:324/336` | ⚠️ 见 §6.3 |
| 6 | `GameCtrl.fightFinish` 走 `isVsCPU() \|\| isVsPeople()` 分支 → 触发"返回选人" | `GameCtrl.as:323` | ✅ |
| 7 | `refreshJoystickRouting` 观战时 `joy_p1.enabled=false; joy_p2.enabled=false;` | `mob/GameInterfaceManager.as:543-548` | ✅ |
| 8 | `Debugger._getModeName` 已支持所有观战常量（13/15/23/25） | `Debugger.as:843-860` | ✅ |
| 9 | `FighterKeyCtrl` 边沿抢占 + 移动端单手柄路由（批次 4/5） | — | ✅ |
| 10 | `scripts_cut/` 阉割版有 `SINGLE_WATCH / TEAM_WATCH / 1VS2 WATCH` 入口 | `scripts_cut/mob/GameInterfaceManager.as:91-114` | ✅ 参考 |

#### 2. 待补全的 6 项（核心问题）

| # | 问题 | 影响 | 涉及文件 |
|---|---|---|---|
| ① | **主菜单缺观战入口**（PC 端） | 用户从主菜单点不到"观战"按钮 | `ui/MenuBtnGroup.as:314-330` |
| ② | **移动端主菜单挂载点缺失**（mobile 端） | 手机用户从主菜单点不到 | `mob/GameInterfaceManager.as:75-122` |
| ③ | **选人界面 P1/P2 都允许选角色** | 观战本质只需 P1 选 1 个对手 + P2 选 1 个对手（演示对战），但当前会走完整 P1+P2 选人流程 | `state/SelectFighterStage.as:84-130` |
| ④ | **选人 step 1→3 P1 禁用逻辑不全** | `isWatch` 没在 step 1→3 显式禁用 P1 输入 | `state/SelectFighterStage.as:111-128` |
| ⑤ | **AI 等级用闯关关卡配置不直观** | 观战应该用独立"观战 AI 等级"或随机等级 | `GameCtrl.as:324` |
| ⑥ | **观战结束回主菜单路径未优化** | 当前走 vsCPU 路径 → "返回选人"，体验上不如直接回主菜单 | `GameCtrl.as:323-326` |

#### 3. 详细实现步骤

##### 步骤 1：扩展 `GameMode.as`（不动，已有）

```actionscript
// 已有 4 个观战常量 + isWatch() + isVsCPU() 内联
// 不需要新增常量或方法
```

##### 步骤 2：主菜单入口 — PC 端（`ui/MenuBtnGroup.as`）

在 "TEAM PLAY" → 子菜单、"SINGLE PLAY" → 子菜单分别加观战入口：

```actionscript
// 行 290 附近：TEAM PLAY 子菜单当前只有 4 个，加 1 个观战
{
   "txt":"TEAM WATCH",        // mode=13
   "cn":"观战小队"
},{
   "txt":"TEAM DUO WATCH",    // mode=15（已有 6.14 验证）
   "cn":"2v2观战"
}

// 行 320 附近：SINGLE PLAY 子菜单当前只有 4 个，加 2 个观战
{
   "txt":"SINGLE WATCH",      // mode=23
   "cn":"观战单人"
},{
   "txt":"SINGLE VS DUO WATCH", // mode=25（已有 6.14 验证）
   "cn":"1v2观战"
}
```

**对应 `case` 分支**（`MenuBtnGroup.as:317-348` 已实现）：
```actionscript
case "TEAM WATCH":
   func = function():void { GameMode.currentMode = 13; MainGame.I.goSelect(); };
   break;
case "TEAM DUO WATCH":   // 已有
   func = function():void { GameMode.currentMode = 15; MainGame.I.goSelect(); };
   break;
case "SINGLE WATCH":
   func = function():void { GameMode.currentMode = 23; MainGame.I.goSelect(); };
   break;
case "SINGLE VS DUO WATCH":  // 已有
   func = function():void { GameMode.currentMode = 25; MainGame.I.goSelect(); };
   break;
```

**验证**：`grep -n "TEAM WATCH\|SINGLE WATCH\|case.*WATCH" BVNscripts/scripts/net/play5d/game/bvn/ui/MenuBtnGroup.as`

##### 步骤 3：主菜单入口 — 移动端（`mob/GameInterfaceManager.as`）

参考 `scripts_cut/` 阉割版已实现的 4 个观战入口（行 91-114）：

```actionscript
// mob/GameInterfaceManager.as 在 "TEAM PLAY" / "SINGLE PLAY" children 数组追加：
{
   "txt":"SINGLE WATCH",
   "cn":"观战单人",
   "func":function():void {
      GameMode.currentMode = 23;
      MainGame.I.goSelect();
   }
},{
   "txt":"1VS2 WATCH",
   "cn":"观战(1v2)",
   "func":function():void {
      GameMode.currentMode = 25;
      MainGame.I.goSelect();
   }
},{
   "txt":"TEAM WATCH",
   "cn":"观战小队",
   "func":function():void {
      GameMode.currentMode = 13;
      MainGame.I.goSelect();
   }
},{
   "txt":"TEAM DUO WATCH",
   "cn":"观战(2v2)",
   "func":function():void {
      GameMode.currentMode = 15;
      MainGame.I.goSelect();
   }
}
```

##### 步骤 4：选人流程适配（`state/SelectFighterStage.as`）

**问题 1**：`initFighter()` 行 116 用 `isVsPeople() || isVsCPU()` 决定是否初始化 P2 SelectVO，观战模式 `isVsCPU()` 已为 `true`（行 89 内联 `isWatch`），所以 **P2 SelectVO 会被正确初始化**。✅ 无需改。

**问题 2**：`nextStep()` 行 111 / 118 `isVsCPU()` 分支已处理 P1 选完后禁用 P1、走 P2 选人 — 观战也走这条路径。✅ 但**需补一个观战专用 step 跳跃**：

```actionscript
// state/SelectFighterStage.as nextStep() case 1 附近
case 1:
   if(GameMode.isWatch() || GameMode.isVsCPU())
   {
      this._p1Slt.removeSelecter();
      this._p1Slt.enabled = false;
      // 观战模式：P1 选完直接进选图（不需要 P2 选人 step 3）
      this._curStep = 4;   // 跳到选图（跳 step 3 的 P2 选人）
      this.fadOutList(this.initMap);
      break;
   }
   // ... 原有 P1 vs P1 选人逻辑
case 3:
   // 观战模式不应进入此 step
   if(GameMode.isWatch()) { this._curStep = 4; this.fadOutList(this.initMap); break; }
   // ... 原有 P2 选人逻辑
```

**问题 3**：选人步数对观战无意义。观战只需 P1 选 1 人（让 P1 选 P2 的对手），P2 由 P1 选 1 人（让 P1 选 P1 的对手）。两步走完后直接进选图。

##### 步骤 5：AI 等级可配置（`data/GameData.as` / `MessionModel.as`）

观战模式当前用 `MessionModel.I.AI_LEVEL`（闯关关卡 AI 等级），不直观。改为支持独立"观战 AI 等级"：

```actionscript
// 方案 A（最简）：在 GameMode 加一个静态变量
// data/GameMode.as
public static var watchAILevel:int = 1;  // 0=简单, 1=普通, 2=困难, 3=疯狂

// 改 GameCtrl.as:324/336
(_loc3_ as FighterAICtrl).AILevel = GameMode.isWatch(false) ? GameMode.watchAILevel : MessionModel.I.AI_LEVEL;
```

或者 **方案 B**（更动态）：从 `MessionModel.I.AI_LEVEL` 取一个固定值（避免增加新配置）：
```actionscript
// 观战时 P1/P2 AI 用关卡配置的 AI 等级
// 不改 MessionModel，观战前默认从 MessionModel 取一个中等值
// （现状就是这样，已可用）
```

**推荐用方案 A**，原因是观战用户对 AI 强度敏感（看对战录像就是看 AI 表现）。

##### 步骤 6：观战结束回主菜单（`GameCtrl.fightFinish`）

```actionscript
// ctrl/game_ctrls/GameCtrl.as fightFinish() 行 313-326
public function fightFinish() : void {
   this.fightFinished = true;
   if(GameMode.isAcrade()) { /* 不变 */ }
   if(Boolean(GameMode.isWatch()))
   {
      Debugger.log("观战结束 → 返回选人");
      GameEvent.dispatchEvent("GAME_END");  // 复用 vsCPU 路径走"返回选人"
      // 或者更友好：直接回主菜单
      // MainGame.I.goMenu();
      return;
   }
   if(Boolean(GameMode.isVsCPU()) || Boolean(GameMode.isVsPeople())) { /* 不变 */ }
}
```

**决策点**：观战结束后回选人界面（连续看不同 AI 对战）还是回主菜单（更干净）？**推荐回选人**，理由是观战用户通常想多看几场。

#### 4. 端到端验证清单（每步必须做）

| 步骤 | 验证方法 | 通过标准 |
|---|---|---|
| 步骤 1 | 编译 | 0 error 0 warning |
| 步骤 2 | PC 端主菜单 4 个观战入口可见 | `MenuBtnGroup.as` 行 314-348 全部 4 个 case 分支就位 |
| 步骤 3 | 移动端主菜单 4 个观战入口可见 | `GameInterfaceManager.as` 4 个 func 都注册 |
| 步骤 4 | 选人 step 1→4 直接跳，P2 SelectVO 仍初始化 | 走通 `nextStep` case 1→4 |
| 步骤 5 | 观战 AI 等级生效 | P1/P2 AI 行为符合 `watchAILevel` |
| 步骤 6 | 观战结束回选人 | 日志 `观战结束 → 返回选人` + 选人界面重现 |
| 步骤 7 | 手柄在观战时无响应 | 日志 `JOY_ROUTE: singlePadWatch joy_p1=false joy_p2=false` |
| 步骤 8 | `Debugger.log("GameMode.currentMode", GameMode.currentMode)` 输出 13/15/23/25 之一 | 日志含 `TEAM_WATCH/TEAM_DUO_WATCH/SINGLE_WATCH/SINGLE_VS_DUO_W` 字符串 |
| 步骤 9 | 双方都走 AI（无键入） | `bvn_debug.log` 无 `INPUT: P1.attack` 类日志 |
| 步骤 10 | 选人界面手柄正常（P1 选 2 个对手） | `_joyLog` 设备感知日志正常输出 |

#### 5. 风险点与规避

| 风险 | 触发条件 | 规避方案 |
|---|---|---|
| **P1 键入误触发观战 AI 接管前的 P1 控制器** | 观战瞬间 P1 按键缓冲未清 | `GameCtrl.addFighter` 切到 AI 前 `FighterKeyCtrl.enabled=false` + `InputManager.I.joy_p1.enabled=false`（手柄路由已处理，键盘需手动清） |
| **AI 双方同时 KO 出现"平局"** | 观战时双方可能同时 HP=0 | `GameLogic` 已有 tie 处理逻辑（沿用 vsCPU 即可） |
| **手柄路由观战双禁用后，回到选人手柄仍禁用** | `refreshJoystickRouting` 选人阶段未重跑 | 选人 `build()` 末尾调 `ViewManager.I.refreshMultiPadCache()` 之后需再调一次 `GameInterfaceManager.I.refreshJoystickRouting()` |
| **多人模式（2v2/1v2）观战选人数错误** | `getSelectCount` 已对 duo/1v2 处理，但观战 variant 没测 | 步骤 4 调试时跑 `TEAM_DUO_WATCH(15) / SINGLE_VS_DUO_WATCH(25)` 两种模式 |
| **AI 等级过低观战秒结束** | 双方 AI 等级一致，无观赏性 | 步骤 5 方案 A：`watchAILevel=2`（困难）做默认；或者让 P1/P2 用不同 AI 等级 |
| **阉割版 scripts_cut/ 与主项目菜单不同步** | 阉割版有观战入口但主项目未来加了新模式 | 改完主项目后必须 `diff BVNscripts/scripts/net/play5d/game/bvn/mob/GameInterfaceManager.as BVNscripts/scripts_cut/net/play5d/game/bvn/mob/GameInterfaceManager.as` 看是否需同步 |

#### 6. 推荐实施顺序（Vibe Coding 拆分）

```
任务 6.15.1（< 3 文件，半小时）
├─ GameMode.as：加 watchAILevel 静态变量 + 注释
├─ GameCtrl.as：addFighter case 0/1 用 watchAILevel
└─ 编译验证

任务 6.15.2（< 2 文件，半小时）
├─ MenuBtnGroup.as：加 4 个 case 分支（其实 case 已就位，只缺菜单 JSON）
└─ GameInterface.as / GameInterfaceManager.as：加 4 个 children 入口

任务 6.15.3（< 2 文件，一小时）
├─ SelectFighterStage.as：nextStep case 1 加 isWatch() 短路
├─ SelectFighterStage.as：initFighter 加 isWatch() 显式初始化 P2 SelectVO
└─ 选人界面 + 真机验证

任务 6.15.4（一小时）
├─ GameCtrl.fightFinish 加 isWatch 分支
├─ 选人 → refreshJoystickRouting 重新触发
└─ 真机端到端验证
```

每个任务完成后用 `diff` 审查 + `build.bat` 编译，按批次 6.13/6.14 流程做备份 + 日志验证。

#### 7. 相关文件清单

```
# 实现观战模式涉及的所有文件（按修改频率排序）
BVNscripts/scripts/net/play5d/game/bvn/data/GameMode.as                    # watchAILevel 新增（极少改）
BVNscripts/scripts/net/play5d/game/bvn/ctrl/game_ctrls/GameCtrl.as          # AI 等级 + fightFinish 分支（偶尔改）
BVNscripts/scripts/net/play5d/game/bvn/ui/MenuBtnGroup.as                  # 4 个 case 分支（已存在，只缺菜单 JSON）
BVNscripts/scripts/net/play5d/game/bvn/interfaces/GameInterface.as         # PC 端菜单 JSON 加 4 个 children
BVNscripts/scripts/net/play5d/game/bvn/mob/GameInterfaceManager.as         # 移动端菜单 JSON 加 4 个 children
BVNscripts/scripts/net/play5d/game/bvn/state/SelectFighterStage.as         # nextStep case 1 加 isWatch 短路
BVNscripts/scripts/net/play5d/game/bvn/ViewManager.as                      # 选人 build() 末尾触发 refreshJoystickRouting
BVNscripts/scripts/net/play5d/game/bvn/Debugger.as                          # _getModeName 已支持（无需改）
BVNscripts/scripts_cut/... (上述文件副本)                                  # 同步阉割版修改
```

> **参考实现**：`scripts_cut/net/play5d/game/bvn/mob/GameInterfaceManager.as:91-114` 已有完整 4 个观战入口的 func 写法，可直接复用 JSON 结构到主项目。

#### 8. 已验证的现状（无需再做）

| 验证项 | 验证命令 | 结果 |
|---|---|:---:|
| `isWatch()` 函数逻辑 | `BVNscripts/scripts/net/play5d/game/bvn/data/GameMode.as:92-95` | ✅ 正确覆盖 13/15/23/25 + TRAINING(40) |
| `isVsCPU()` 内联 `isWatch` | `GameMode.as:89` | ✅ vsCPU 自动覆盖观战 |
| `addFighter` AI 接管 | `GameCtrl.as:321, 333` | ✅ 双方都走 FighterAICtrl |
| 手柄路由观战双禁用 | `GameInterfaceManager.as:543-548` | ✅ logcat 见 `JOY_ROUTE: singlePadWatch` |
| Debugger 模式名 | `Debugger.as:843-860` | ✅ 4 个 WATCH 常量全覆盖 |
| 阉割版入口参考 | `scripts_cut/mob/GameInterfaceManager.as:91-114` | ✅ 有 4 个完整 func |

#### 9. 用户体验设计建议（非必须，但推荐）

1. **观战时显示"AI vs AI"提示** — 在 `FightUI` 顶部加一个半透明 `SpectatorMode` 文字标签（用 `FightUI.initlize` 行 70 附近）
2. **观战暂停菜单加"切换观战对象"按钮** — 暂停时按 RB 切换 P1/P2 关注视角（camera 跟随）
3. **观战结束加"再看一场"按钮** — 在结算界面 `WinnerState` 加按钮直接重玩当前对战（不重选人）
4. **观战回放控制** — 加 `speed` 倍速（1x/2x/4x）让用户快进看对战
5. **观战 AI 等级可视化** — 选人阶段选完双方后弹一个 "选择 AI 等级" 子菜单（简单/普通/困难/疯狂）

### 移动端特性

- **TOUCH_MODE** — 默认 `true`
- **ScreenPadManager** — 屏幕触控按钮管理（游戏内 + 选人界面）
- **GameInterfaceManager** — 移动端菜单/设置/INFINITE_ENERGY 配置同步
- **ScreenRotater** — 屏幕旋转
- **InputManager** — 多种输入源管理（触控 + 摇杆 + 键盘 + 网络）
- **LAN 多人** — `sockets/` + `ctrls/` 局域网对战（TCP + UDP 混合，含锁帧同步）
- **ANEFileReader（已禁用）** — 源文件保留，运行时开关 `ANE_ENABLED = false`，全部走 APK 内置资源

#### 安卓端编译注意事项

**`-strict=false` 参数必须携带**：`build.bat` 中使用了 `-strict=false` 编译参数。Flex 严格模式（默认）下，预存的类型不匹配错误（`ScreenRotater`、`GameInputer`、`JsonUtils`、`SocketServer/SocketClient`、`ANEFileReader`、`FileUtils`、`KyoClassLoader` 等反编译代码）会阻止 SWF 输出。手动编译时务必包含此参数。完整编译命令：

```bash
java -jar flex4.16.1-air51.0.1.1/lib/mxmlc.jar \
  +flexlib=flex4.16.1-air51.0.1.1/frameworks \
  -debug=true -swf-version=37 -strict=false \
  -source-path+=BVNscripts/scripts \
  -library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/core.swc \
  -external-library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/air/airglobal.swc \
  -output=tools/Test/launch.swf -- BVNscripts/scripts/launch.as
```

> ⚠️ 缺少 `-strict=false` 时 mxmlc 仍返回 exitCode=0（JVM 正常退出），但 SWF 不会产出。

**TrainingCtrler 类型转换问题**：反编译代码中 `TrainingCtrler.as` 第 59/76/93 行存在 `--this._trainAddDelay[stringKey]` 写法，对 `Object` 类型（键为 `String`）的值使用递减操作符 `--`，Flex 严格模式报隐式类型转换错误。修复方式：

```actionscript
// 旧（第 59/76/93 行）：
--this._trainAddDelay[_locN_];

// 新：
this._trainAddDelay[_locN_] = int(this._trainAddDelay[_locN_]) - 1;
```

#### 移动端文件日志调试（2026-08-15 启用）

**背景**：AIR Android 的 `trace()` 默认**不输出 logcat**（需 fdb 连接），logcat 抓不到游戏日志。项目已内置**文件日志系统**：`launch.as` 无条件调用 `Debugger.initFileLog(stage)`（不依赖 `DEBUG_PANEL_ENABLED`），所有 `Debugger.log()` 缓冲落盘（每 5 帧刷盘）。

**日志路径**（AIR 私有目录，注意是 applicationID 目录不是包名）：
```
/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log
```

**读取**（root/shizuku/run-as）：
```bash
run-as air.com.bvn.yy798 cat '/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log'
```

**输入排查日志**（手柄问题三件套）：
| 日志 | 来源 | 用途 |
|------|------|------|
| `JOY_IN: DOWN/UP device=... control=N value=...` | `JoySticker.pollInputLog()` 每帧轮询 | 设备侧实际输入（确认 control index/value） |
| `INPUT: P1.attack = true` | `GameInputer.call()` 按下边沿 | 哪个通道收到输入（P1/P2 绑定定位） |
| `JOY_ROUTE: singlePad joy_p1=true joy_p2=false` | `refreshJoystickRouting()` | 手柄路由状态 |
| `connected / button:N:ID` | `JoySticker.joystickHandler` | 设备 control 布局（换手柄先核对此处再改键位） |

**注意**：修改 `JoyStickConfigVO` 默认键位只影响**无存档**时；已有存档会覆盖（`readSaveObj` → `joy1Config.readObj`）。调试时若键位与代码不符，先检查存档 `extend_config.joy_p1`。

### 多手柄配置重构（批次 1-5，2026-08）

**背景**：原始 `joy_p1`/`joy_p2` 共享 `joy1Config`，导致 P2 改键会覆盖 P1、P2 设备号重连后失效。经多批次重构为「单手柄模型 + P2 独立配置 + 双手柄时 P2 独立改键 UI」。

**核心架构（单手柄模型）**：手机端只连一个手柄（Xbox 布局），手柄输入**固定走 `joy_p1` 通道**（`joy_p1` 恒启用、`joy_p2` 恒禁用）。控制哪个角色由 `GameCtrl.switchControlPlayer()` 依据 `joyTarget`（0=跟随/1=固定P1/2=固定P2）决定（通过交换 FighterKeyCtrl.inputType 实现）。

**批次记录**：

| 批次 | 内容 | 涉及文件 | 关键改动 |
|------|------|----------|----------|
| 批次 1 | 核心输入/改键重构 | `GameJoystickInput.as` / `InputManager.as` | `_prevKeys` 设备级按下历史（key=`dev:deviceId:ctrl:N:keyName`），跨实例隔离（joy_p1/joy_p2 各自维护），EDGE 边沿日志 |
| 批次 2 | P2 独立配置 + 存档兼容 | `ExtendConfig.as` / `GameInterfaceManager.as` | 新增 `joy2Config` 字段，`toSaveObj/readSaveObj/setDefaultDevice(joy2Config,1)` 独立存档；`updateInputConfig` 运行时绑定 `joy_p2.setConfig(joy2Config)` |
| 批次 3 | 路由注释清理 + JSDoc + 日志精化 | `GameInterfaceManager.as` | `refreshJoystickRouting()` 单手柄化：观战双禁用，其余 joy_p1 恒启用、joy_p2 恒禁用；双分支日志 |
| 批次 4 | P2 改键 UI + 双手柄检测 | `ViewManager.as` / `GameInterfaceManager.as` / `SelectFighterStage.as` | `goP2JoyStickSet()` + `isMultiplePads()` + `_multiPadCache` + `refreshMultiPadCache()`；设置菜单加 P2 条件入口（`isMultiplePads() ? {...} : null`）；选人 `build()` 末尾检测一次双手柄 |
| 批次 5 | 日志增强（跟上批次 4） | `GameJoystickInput.as` / `ViewManager.as` | `_joyLog()` 设备切换感知（按 `config.deviceId` 匹配设备）；`anyKey()` 接 `_checkEdge("any",[],r)`；EDGE 日志加 `ctrl=` 组合；`goJoyStickSet()` 进入/跳过日志 |

**批次 4 完整链路**（P2 改键）：
```
用户进入选人 → SelectFighterStage.build() 第96行
  → ViewManager.I.refreshMultiPadCache()  （JoySticker.getAllDeivces() 检测 >1 = 双手柄）
  → 缓存 _multiPadCache
  → 打开设置菜单 → GameInterfaceManager.getSettingMenu()
  → 读 ViewManager.I.isMultiplePads() 决定 P2 入口显隐（单手柄隐藏，null 元素被渲染层过滤）
  → 点击 P2 入口 → ViewManager.I.goP2JoyStickSet()
  → goJoyStickSet(2, joy2Config) → JoyStickSetUI.setConfig(2, joy2Config) → P2 改键界面
```

**关键设计决策**：
- **P2 APPLY 不调 `updateJoyConfig`**：只 `readObj` 直存，与 P1 解耦（P1 才调 updateJoyConfig 同步 menu 设备号）
- **双手柄检测仅在选人时做一次**（`SelectFighterStage.build()`），不订阅设备热插拔事件（决策 J 明确不考虑）
- **单手柄时 P2 入口完全隐藏**（不灰显），用三元运算符 `isMultiplePads() ? {...} : null` 实现
- **保留历史拼写错误**：`getAllDeivces`（Deivces）、`wankai/waikai`——与 `wankai/waikai` 同处理，避免 ABI 变动

**批次 5 新增日志**（真机排查用）：
| 日志 | 来源 | 用途 |
|------|------|------|
| `JOY:P1 up dev=xxx [1:AXIS=0.5]` | `GameJoystickInput._joyLog()` | 设备切换感知——P1/P2 配置不同设备时日志指向各自设备 |
| `JOY:P1 EDGE DOWN/UP key=any dev=xxx ctrl=` | `GameJoystickInput._checkEdge("any",[])` | 任意键边沿 |
| `JOY:P1 EDGE DOWN key=attack dev=xxx ctrl=15,` | `GameJoystickInput._checkEdge()` | EDGE 标准化（带 ctrl 组合） |
| `goJoyStickSet: enter player=2 deviceId=yyy` | `ViewManager.goJoyStickSet()` | P1/P2 改键页进入分流 |
| `refreshMultiPadCache: devices=N multiPad=true` | `ViewManager.refreshMultiPadCache()` | 双手柄检测结果 |

### 资源加载架构

游戏资源分为两个层级（ANE 禁用后）：

1. **嵌入资源**：`_assets/` 中的 PNG/MP3/JPG/BIN 通过 `[Embed]` 标签嵌入 SWF（`EmbeddedAssets.as` 统一管理）
2. **APK 内置资源**：`tools/Test/assets/` 打包进 APK（sounds/font/config/swf/effect.swf/movelist.jpg/fighter/map/face/bgm）

> **外部资源加载已禁用**：原 `app-storage://BVN/assets/` 外部路径扫描逻辑保留但受 `ANEFileReader.ANE_ENABLED` 守卫，当前不执行。重新启用 ANE 后自动恢复。

#### 启动流程

```
GameData.loadConfig()
  → 加载 APK 内置 fighter.xml → FighterModel.initByXML()
  → 加载 APK 内置 assist.xml / select.xml / map.xml / mission.xml
  → 完成（外部扫描受 ANE_ENABLED 守卫跳过）
```

## ANE 原生扩展（当前已禁用）

### BVNFileReader（`extensions/BVNFileReader/`）

突破 AIR 沙箱限制，访问 Android 外部存储。**当前 `ANE_ENABLED = false`，源文件保留备用**。

**重新启用需同时打开三开关**：
| 开关 | 文件 | 设置 |
|------|------|------|
| 1 | `application.xml` | `<extensionID>com.bvn.filereader</extensionID>` 取消注释 |
| 2 | `ANEFileReader.as` | `ANE_ENABLED = true` |
| 3 | `debug_mob.bat` | ADT 命令恢复 `-extdir "."` |

**ANE 构建（`build_ane.bat`）**：

- Java：**必须 JDK 8**（class v52 兼容 build-tools d8）
- 平台名：`Android-ARM64`（armv8 架构）
- airglobal.swc：使用合并 SDK 的 `frameworks/libs/air/airglobal.swc`
- 输出：`BVNFileReader.ane` → 复制到 `tools/Test/`

**ANE 未安装时**自动降级为 AIR `flash.filesystem.File` API。

#### 文件位置

- `mob/utils/ANEFileReader.as` — AS3 封装层（`ANE_ENABLED` 开关 + `EXTERNAL_BASE` 路径）
- `extensions/BVNFileReader/as3/com/bvn/filereader/BVNFileReaderLib.as` — ANE 库接口
- `extensions/BVNFileReader/Android/src/com/bvn/filereader/` — Java 原生实现（JDK 8 编译）
- `extensions/BVNFileReader/build_ane.bat` — ANE 构建脚本（Java→JAR→SWC→ANE）

## 关键 Bug 修复记录

| 修复                     | 涉及文件                                                  | 说明                                                  |
| ------------------------ | --------------------------------------------------------- | ----------------------------------------------------- |
| PauseDialog visible      | `PauseDialog.as`                                          | showMoveList 隐藏按钮组，hideMoveList 恢复            |
| 训练模式 AI 开关         | `GameCtrl.as` + `PauseDialog.as`                          | `toggleFighterAI()` 绕过模式强制 AI                   |
| 开场帧检查               | `FighterMcCtrler.as`                                      | sayIntro/doWin/doLose 先 checkFrame                   |
| INFINITE_ENERGY          | `FighterMcCtrler` + `FighterAction`                       | setBisha/doBisha/doWaiKai/render 全部检查             |
| AI 无限气关闭时必杀      | 3 处修复                                                  | 关闭时角色仍可无视条件释放必杀                        |
| trace() → Debugger.log() | 全局                                                      | 全面替换，支持 logcat 实时输出 + 面板显示             |
| Debugger 面板            | `Debugger.as` + `launch.as`                               | _inited 静态守卫防重复创建、_closeBtnSize 常量修复按钮消失、PERF toggle 补全重绘、标题栏监听回滚 |
| 选人分页布局             | `SelectFighterStage.as`                                   | 分页集成：键盘/滚轮/触控翻页 + 辅助界面归位           |
| fighter.xml 语法错误     | `fighter.xml:1026`                                        | XML 格式修复，解决手机端白屏                          |
| ScreenPadAsset.light     | `ScreenPadAsset.as`                                       | 使用真实 light.png 替代 skill_png                     |
| build.bat SWF 输出       | `build.bat` + `debug.bat`                                 | 直出 tools/Test/launch.swf                            |
| ADT 打包 assets          | `debug_mob.bat`                                           | slim APK： fighter/map/face/bgm 空目录 + 打包后恢复   |
| .bat UTF-8 BOM           | 所有 .bat                                                 | CRLF + BOM 编码修复解决双击闪退                       |
| SetBtn 重入              | `SetBtn.as`                                               | 全局静态重入守卫 + deferred dispatchEvent             |
| debug_mob.bat            | 多次迭代                                                  | FLEX_HOME 自动检测 + PATH 方式 adb + 基于 BVN3.9 重写 |
| ANE 禁用                 | `ANEFileReader` + `GameData` + `application.xml`          | 三开关全关，统一 APK 内部资源优先                     |
| SDK 路径统一             | `build.bat` + `debug*.bat` + `fdbg.bat` + `build_ane.bat` | 合并到 `AIRSDK/flex4.16.1-air51.0.1.1`，本地优先检测  |
| 证书丢失                 | `adt.bat` + `mycert.p12`                                  | filter-branch 清除后重新生成签名证书                  |
| FighterModel 过滤器      | `FighterModel.as`                                         | `\|\|` → `&&`（与 BVN3.9 对比修复逻辑错误）           |
| 闯关 null 崩溃           | `MessionModel.as`                                         | initMession() 加 fighter/mission null 守卫            |
| AssetManager NPE         | `AssetManager.as`                                         | getFighterFaceWin 加 param1 null 检查                 |
| FighterAttacker NPE      | `FighterAttackerCtrler.as`                                | owner_fighter_ctrler getter 加 null 保护              |
| 1v2/2v2 模式             | `GameMode` + `MenuBtnGroup` 等 4 文件                     | 启用原版预留 TEAM_DUO(14/15) + SINGLE_VS_DUO(24/25)   |
| 翻页抽搐                 | `SelectFighterStage.as`                                   | PAGE_HEIGHT=500 对齐，timeline speed 同步             |
| 训练模式开场             | `GameCtrl.as`                                             | buildGame + doBuildNextRound 跳过 GameStartCtrl       |
| APK config 缺失          | `debug_mob.bat`                                           | 白名单补上 assets\config 防 URLLoader 挂起            |
| add_asset 工具           | `tools/script/add_asset.py`                               | 自动添加角色/辅助/地图到游戏                          |
| P1/P2 切换按钮图片       | `ScreenPadGame.as`                                        | 替换 `_playerSwitchBtn.display` 为全新 Bitmap 对象（GPU 纹理刷新陷阱），修复按钮始终显示 p1 图标 |
| 手柄路由 1P/2P 错误       | `GameInterfaceManager.as`                                 | `joyTarget=0` 分支按 `controllingP1` 单选 joy，避免同时启用导致控制错位 |
| 调试面板标题栏监听       | `Debugger.as`                                             | 回滚标题栏整条 CLICK 监听，仅保留绿色方块按钮触发折叠/展开 |
| 闯关一局即通关           | `MessionModel.as`                                         | `missionAllComplete()` 对 null/空 stageList 误判通关；新增 `getMessionFallback` 回退到可用关卡，`initMession` 匹配失败不再静默置空 |
| 胜利结算 BGM 不停         | `WinnerState.as`                                          | `destory()` 补 `SoundCtrl.I.BGM(null)`，停止 winloop 残留（与 HowToPlay/Loading/SelectFighter 状态一致） |
| 选人界面 2P 显示框位置     | `SelectUIFactory.as`                                       | P2 框(`selected_item_p2_mc`) 从右下角 `x=GAME_SIZE.x-265` 移到 P1 正上方：x 与 P1 对齐设为 10，y 从 `GAME_SIZE.y-80` 上移一框高+间距(`-85`，框高约65px)，保证不互相遮挡 |
| 僵直异常（灵压爆发卡死）   | `FighterMain.as` + `FighterMcCtrler.as`                    | 场景1：doHurt() 关钢体加 explodeSteelFrame 窗口守卫，保住 60 帧无敌刚体设计；场景2：renderHurtBreak 空指针防护 + renderHurt `_hurtHoldFrame<=0` 递减兜底（详见下方专节） |
| 新式 main_mc 人物包兼容     | `GameLoader.as` + `FighterCtrler.as`                       | 加载阶段 getDefinition("main_mc") 识别（成功用 main_mc 实例，失败回退根）；initFighter 双注入（先 initFighter({...}) 新式，回退 setter 旧式）（详见下方专节） |
| 灵压爆发钢体卡死（回归）   | `FighterMcCtrler.as`                                       | 2026-08-15：撤销 doHurt「explodeSteelFrame>0 不关钢体」守卫（恢复无条件 setSteelBody(false)，消除钢体+受击并存）；renderHurt 兜底加 `explodeSteelFrame<=0` 条件（灵压爆发窗口内交 FighterMain.renderAnimate 正常递减链路恢复） |
| 手柄路由 1P/2P 错乱（重构） | `GameCtrl.as` + `GameInterfaceManager.as`                  | 2026-08-15 单手柄模型：手柄固定走 "P1" 通道（joy_p1 恒启用、joy_p2 恒禁用）；switchControlPlayer 按 joyTarget（0=跟随/1=固定P1/2=固定P2）决定控制方；vs CPU 天然只控 P1 |
| 手柄按钮全部无效           | `FighterKeyCtrl.as`                                        | 2026-08-15：移除 listenKeys 注册——renderListenKeys 每帧预查询抢占 isJustDown 边沿，justDown=2 查询（attack/jump/dash/skill/superSkill）永远非边沿 → 按钮无效；方向键（justDown=0 实时查询）不受影响 |
| 手柄键位全错位             | `JoyStickConfigVO.as`                                      | 2026-08-15：按 Xbox Wireless Controller 实测 control 布局重映射（左摇杆 8/9、D-pad HAT 0/1、按钮 13-22）；旧映射 back=8 实为左摇杆 Y 轴 → 下拉左摇杆触发暂停 |
| 文件日志系统               | `Debugger.as` + `launch.as` + `JoySticker.as` + `GameInputer.as` | 2026-08-15：launch.as 无条件 `Debugger.initFileLog(stage)`（不依赖面板开关），日志落盘应用私有目录 `bvn_debug.log`（AIR trace 默认不进 logcat）；`JOY_IN`（手柄边沿轮询）+ `INPUT`（查询按下边沿）+ `JOY_ROUTE`（路由）三类输入日志 |

### 新式 main_mc 人物包兼容（V3.6/3.9 人物包加载到 V3.3）

> 目标：让 V3.3 引擎能加载**高版本（3.6/3.9）「main_mc 包裹」新式人物 SWF**，同时**不破坏旧式 3.3 人物包**。双路径共存。

#### 两种人物包格式的本质区别

| 维度 | 旧式 3.3 人物包 | 新式 main_mc 人物包（3.6/3.9） |
|------|----------------|-------------------------------|
| 角色主 MC 来源 | SWF **根**（`loader.content`）即角色 | SWF 内部库元件 `main_mc`（链接名 `main_mc`），用 `ApplicationDomain.getDefinition('main_mc')` 取类实例化 |
| 注入接口 | `setEffectCtrler()` + `setFighterMcCtrler()` 两个 setter | 单个 `initFighter({fighter_ctrler, mc_ctrler, effect_ctrler, camera_ctrler})` 函数 |
| 时间轴访问逻辑 | 通过 setter 存下的私有变量 | 全局 `$fighter_ctrler/$mc_ctrler/$effect_ctrler/$camera_ctrler`（`CORE_Components` IDE 组件依赖）+ 全局单例 `EffectCtrl.I`/`SoundCtrl.I`/`GameCtrl.I` |

#### 本次改动的 .as 文件与修改方法

**文件 1：`BVNscripts/scripts/net/play5d/game/bvn/ctrl/GameLoader.as`** — 加载阶段识别 main_mc
- 改动点：`loadFighter`（loadComplete 回调）与 `loadFighterFromPath`（complete 监听回调）各加一段 main_mc 解析
- 修改方法（两处同构）：
```actionscript
// loadFighter 内（param1 = loader.content）：
var _loc2_:MovieClip = param1 as MovieClip;         // 旧式：SWF 根即角色
try {
    var _loc3_:Class = param1.loaderInfo.applicationDomain.getDefinition("main_mc") as Class;  // 新式识别
    if(_loc3_) _loc2_ = new _loc3_() as MovieClip;  // 成功：用 main_mc 实例作角色主 MC
} catch(e:Error) { }                                // 失败：保持旧式根
var _loc4_:FighterMain = new FighterMain(_loc2_);   // 后续统一用 _loc4_
```
- `loadFighterFromPath` 改法相同，但用 `loader.contentLoaderInfo.applicationDomain`（回调直接持有 `loader`）
- 注意：`loadSWF` 只回传 `param1.content`（根），拿不到 Loader；故用 `param1.loaderInfo.applicationDomain`（MovieClip 自带 loaderInfo，等价可拿到 Domain）

**文件 2：`BVNscripts/scripts/net/play5d/game/bvn/fighter/ctrler/FighterCtrler.as`** — initFighter 双注入
- 改动点：`initFighter(param1:FighterMain)` 在旧式 `setEffectCtrler` 分支**之前**新增新式 `initFighter({...})` 分支
- 修改方法（双路径并行，先新式后旧式）：
```actionscript
// —— 新式 main_mc 注入（优先）——
if(Boolean(param1.mc.initFighter)) {
    this._effectCtrl   = new FighterEffectCtrl(param1);
    this._fighterMcCtrl = new FighterMcCtrler(param1);
    this._fighterMcCtrl.effectCtrler = this._effectCtrl;
    param1.mc.initFighter({fighter_ctrler:this, mc_ctrler:this._fighterMcCtrl, effect_ctrler:this._effectCtrl});
    return;
}
// —— 旧式 setter 注入（回退，兼容旧包）—— 原逻辑原样保留
if(Boolean(param1.mc.setEffectCtrler)) { ... }
```
- V3.3 无 camera 概念，新式 `initFighter` 只注入 3 个（fighter/mc/effect），不传 camera_ctrler

#### 关键判断 / 指导：EffectCtrl / SoundCtrl / GameCtrl（三全局单例检查结论）

检查确认：**新式人物包运行时通过 `EffectCtrl.I`/`SoundCtrl.I`/`GameCtrl.I` 三个全局单例调用特效/音效/游戏控制的能力在 V3.3 内核已全部齐备，无需为这三个类额外改动**。本次加载层 + 注入层兼容已覆盖新式包主路径。

| 单例 | V3.3 已具备（新式包调用面） | V3.9 有而 V3.3 无（均为内核/全局 BGM 级 API，**非角色时间轴调用面**，无需补） |
|------|------------------------------|--------------------------------------|
| `EffectCtrl.I` | `doEffectById`/`doEffectVO`/`doHitEffect`/`freeze`/`shake`/`shine`/`slowDown`/`replaceSkill`/`energyExplode`/`ghostStep`/`bisha`/`wanKai`/`startFilter`/`startShadow`/`BGEffect` 等（特效调用面**基本完整**） | `enemyBirthEffect`/`removeEnemyEffect`/`startRenderBlackBack`/`bgBlur`/`cancelBgBlur`（内核特效钩子） |
| `SoundCtrl.I` | `playAssetSound`/`playEffectSound`/`playAssetSoundRandom`/`playSwcSound`/`BGM`/`pauseBGM`/`resumeBGM`/`playFightBGM` 等（音效调用面齐备） | `playSound`/`playBossBGM`/`playFighterBGM`/`smartPlayGameBGM`（全局 BGM 管理） |
| `GameCtrl.I` | `pause`/`slow`/`slowResume`/`resume`/`setRenderHit`/`fightFinish`/`startNextRound`/`gameEnd`/`drawGame` 等（游戏控制调用面齐备） | `startMusouGame`/`initMusouGame`/`getMusouCtrl`/`addFighter`/`removeFighter`/`initStart`/`initMainLogic` 等（内核级 API，游戏主逻辑内部用） |

> 结论约束：若新式包时间轴只用 `EffectCtrl.I`/`SoundCtrl.I`/`GameCtrl.I` 的标准特效/音效/控制接口，V3.3 已原生支持，无需改这三个类。**仅当角色 SWF 时间轴显式调用 V3.9 独有内核级 API（如 `startMusouGame`）时**才需要另行评估，通常角色包不会这么做。

#### 验收标准
- [x] GameLoader 加载新式包能取到 main_mc 实例；旧式包回退根，行为不变
- [x] FighterCtrler.initFighter 对两种包均能完成注入，旧角色包不回归
- [x] 编译通过（launch.swf 产出，34604677 字节无 error）
- [ ] （待材料）真机加载新式角色 SWF 正常出招/表现 —— 需 Adobe 打开 `BVNscripts/神卡3.6源文件.fla` 确认是否为 new main_mc 包，导出 SWF 放 `app-storage://BVN/assets/fighter/` 后真机验证

## 构建脚本故障排查

本节汇集 `build_ane.bat` 和 `debug_mob.bat` 常见崩溃（闪退/报错）的系统性排查流程。

### 优先级排查清单

出现 `双击闪退` 或 `报错后立即关闭` 时，按以下顺序排查：

| 优先级 | 排查项                             | 症状                                       | 修复法                                                                              |
| :----: | ---------------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------- |
| **1**  | `exit /b`                          | cmd 窗口一闪而过                           | 全部改为 `goto :EOF`，末尾加 `pause`                                                |
| **2**  | 调用其他 `.bat` 缺 `call`          | 子 bat 退出时连带终止主脚本                | `call "%ADT%"` 而非 `"%ADT%"`                                                       |
| **3**  | `()` 块内 `)` 未转义               | `-- was unexpected at this time.`          | 批处理 `()` 内的文字 `)` 须用 `^)` 转义；或避免在 `if ()` 块中嵌入含 `)` 的多行命令 |
| **4**  | `-C "path\"` 末尾反斜杠            | `No such directory: ..." .`                | Windows 命令行 `\"` 会被解析为转义引号 → 去掉末尾 `\`                               |
| **5**  | `::` 注释含特殊字符                | `'xxx' 不是内部或外部命令`                 | 中文/Unicode 字符多时改用 `REM`                                                     |
| **6**  | javac 不认 `*.java` 通配符         | `无效文件名: ...\*.java`                   | 显式列出 `.java` 源文件                                                             |
| **7**  | powershell 内联 `^` 续行           | `-- was unexpected`                        | 内联 PowerShell 的在 `if ()` 块中极易破坏括号匹配 → 改用独立 `.ps1` 文件或简化逻辑  |
| **8**  | `pause >nul`                       | 看不到 "按任意键继续"                      | 去掉 `>nul`                                                                         |
| **9**  | ANE 文件缺失                       | 运行时 `implementation not found`          | 先运行 `build_ane.bat` 生成 ANE                                                     |
| **10** | 上次中断遗留 `_bakslim_*`          | `already exists`                           | 打包前先检查并恢复遗留备份目录                                                      |
| **11** | APK 文件名含中文                   | `no such file ...死神vs火影.apk`           | ADT 不认中文输出路径 → 改用纯英文名如 `bvn.apk`                                     |
| **12** | `enabledelayedexpansion` + `%VAR%` | `implementation not found`（ANE 未被传入） | `setlocal enabledelayedexpansion` 下运行时设的变量须用 `!VAR!`                      |

### bat 脚本强制规范

**所有项目 `.bat` 脚本必须遵守以下模板**，确保双击运行时窗口停留、错误可见：

```bat
@echo off
setlocal
...脚本主体...

:: 所有错误出口统一用 goto END
if errorlevel 1 goto END

:END
echo.
echo =============================================
echo   Script finished. Press any key to exit.
echo =============================================
pause
goto :EOF
```

**禁止事项**：
| 禁止 | 原因 | 替代 |
|------|------|------|
| `exit /b` | 双击时关闭窗口 | `goto END` |
| `pause >nul` | 用户看不到提示 | `pause` |
| 直接调用 `.bat` 不加 `call` | 子 bat 退出时连带终止主脚本 | `call xxx.bat` |
| `::` 注释在 `()` 块内 | 括号匹配错误 → 闪退 | `REM` |
| 内联 PowerShell 含 `)` `$` `^` | 批处理括号逃逸灾难 | 独立 `.ps1` 文件 |
| APK/文件输出用中文名 | ADT 不认非 ASCII 路径 | 纯英文名 |

**例外**：`build.bat` 作为被调用的叶子工具脚本，不加 `pause`（由调用方处理）。

### 安全修改模式

修改 `.bat` 文件时必须遵守：

1. **先备份后可回滚**：用 `git checkout -- <file>` 恢复
2. **每次只改一个点**：改完双击测试，确认无误再改下一个
3. **用 `goto END` 而非 `exit /b`**：统一汇聚到 `:END` 标签执行 `pause`
4. **用 `call` 调子 bat**：永不直接调用另一个 `.bat`
5. **避免内联 PowerShell**：涉及 `)`、`$`、`^` 时极易出问题 → 写独立 `.ps1` 文件

### 调试技巧

```bash
# 1. 命令行直接运行（绕过 bat 看原始错误）
adt -package -target ane ...

# 2. 查看 bat 文件中的隐藏字符
python3 -c "print(open('x.bat','rb').read().hex())"

# 3. 从 git 恢复干净版本
git checkout HEAD -- tools/script/debug_mob.bat
```

## 开发规范

### 交流语言

**所有对话使用中文**，技术术语、代码标识符、文件路径可保留英文。

### Git 提交

- 仅当用户明确要求时执行
- commit message 末尾加：`Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- 不提交 `*.swf`、`*.apk`、SDK、参考/蓝图目录

### .gitignore / .claudeignore

排除：`*.swf` / `*.swc` / `*.apk` / `*.png` / `*.jpg` / `*.mp3` / `*.bin` / `_assets/` / `assets/swf/` / `AIRSDK/` / `flex4.16.1-air51.0.1.1/` / `tools/Test/` / `last/` / `OLD/` / `reference/BVN3.9/` / `Outscripts/` / `node_modules/` / `dist/`

**例外**：`tools/Test/assets/config/` 被 git 追踪（XML 配置文件需版本控制）。

### 文件变更表格式

每次代码修改后输出：

```
| # | 文件 | BVNscripts | Outscripts |
|---|------|:---:|:---:|
| 1 | path/to/File.as | ✓ | ✓ |
```

### 反编译代码特征

- **参数名**：`param1`、`param2`…（无意义，保持与同文件一致）
- **局部变量**：`_loc1_`、`_loc2_`…（同上）
- **内联匿名函数**：大量 `function():void { ... }` 回调模式
- **单例访问**：`ClassName.I` 静态 getter
- **拼写错误**：`NORNAL`（NORMAL）、`destory`（destroy）、`Mession`（Mission）、`Confrim`（Confirm）— 保持原样

### 关键文件速查

| 需求            | 优先查看                                                                         |
| --------------- | -------------------------------------------------------------------------------- |
| 编译            | `build.bat`、`asconfig.json`                                                     |
| 调试            | `tools/script/debug.bat`、`tools/script/debug_mob.bat`                           |
| 入口/初始化     | `launch.as`、`MainGame.as`                                                       |
| 物理参数        | `GameConfig.as`                                                                  |
| 角色动作状态机  | `FighterMcCtrler.as`                                                             |
| 角色动作定义    | `FighterAction.as`、`FighterActionState.as`                                      |
| AI 系统         | `fighter/ctrler/ai/FighterAILogic.as`、`fighter/ctrler/ai/FighterAILogicBase.as` |
| AI 控制适配器   | `fighter/ctrler/FighterAICtrl.as`                                                |
| AI 系统完整文档 | `AI-SYSTEM-DOC.md`                                                               |
| 碰撞检测        | `GameMainLogicCtrler.as`                                                         |
| 角色实体        | `fighter/FighterMain.as`                                                         |
| 菜单/按钮       | `MenuBtnGroup.as`、`MenuBtn.as`                                                  |
| 暂停菜单        | `PauseDialog.as`                                                                 |
| 设置            | `SetBtnGroup.as`、`SettingState.as`                                              |
| 输入            | `GameInputer.as`、`FighterKeyCtrl.as`                                            |
| 配置/存档       | `GameData.as`、`ConfigVO.as`                                                     |
| 嵌入式资源      | `EmbeddedAssets.as`、`mx/core/`                                                  |
| UI SWF 加载     | `ResUtils.as`                                                                    |
| 角色加载        | `ctrl/GameLoader.as`、`ctrl/AssetManager.as`                                     |
| 移动端          | `mob/GameInterfaceManager.as`、`mob/ScreenRotater.as`                            |
| 触控            | `mob/screenpad/ScreenPadManager.as`                                              |
| 网络            | `mob/sockets/`、`mob/ctrls/LAN*.as`                                              |
| 外部角色        | `mob/utils/ANEFileReader.as`、`ctrl/GameLoader.as::scanExternalAssets()`         |
| 调试面板        | `Debugger.as`（`DEBUG_PANEL_ENABLED` 开关）                                      |
| 运行时配置      | `tools/Test/assets/config/fighter.xml`、`select.xml`                             |
| ANE 扩展        | `extensions/BVNFileReader/`                                                      |
| 代码同步        | `sync.py`                                                                        |
| 模型路由        | `tools/route_model.py`、`.claude/skills/route-model.md`                          |
| SWF 反编译/查改 | `FFDEC/ffdec-mcp-main/BVN-OPERATION-GUIDE.md`（ffdec-mcp 43 工具，DSH 当前无 MCP 协议栈，需配 Claude Desktop/Cline）|

## 版本信息

| 项目     | 内容                                                      |
| -------- | --------------------------------------------------------- |
| 游戏版本 | V3.3（2019.3.32）                                         |
| 开发商   | 5dplay（net.play5d）                                      |
| 平台     | Flash Web + Android/iOS + LAN 局域网对战                  |
| SDK      | Apache Flex 4.16.1 + AIR 51.0                             |
| 编译器   | mxmlc.jar（Java 17）                                      |
| 编辑器   | VSCode + ActionScript & MXML 插件                         |
| ANE 扩展 | BVNFileReader（com.bvn.filereader）— Android 外部存储读取 |
| 调试     | fdb 断点调试 + adb logcat 实时日志                        |
| 许可     | GPL-3.0                                                   |

## 应用包名澄清（2026-08-27 纠正）

本项目有**三个不同的标识符**，不能混用。历史对话中曾长期混为一谈，必须澄清：

| 标识符 | 值 | 出现位置 | 作用 |
|--------|-----|---------|------|
| **Android 包名** | `air.com.bvn.yy798` | `pm path` / `pm install` / `adb shell run-as` / APK 文件路径 | Android 系统识别应用的唯一 ID |
| **AIR applicationID** | `com.bvn33.y36` | `tools/Test/application.xml` 的 `<id>` 标签 | AIR 配置文件声明的逻辑 ID（与 Android 包名无强制对应关系） |
| **AIR 私有目录内 ID** | `com.bvn.yy798` | `/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/...` | AIR 运行时在 Android 私有目录下使用的子目录名 |

**真实文件路径**（手机端日志位置）：
```
/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log
                 ↑               ↑
            Android 包名        AIR 私有目录内 ID（与 applicationID 不一致！）
```

**读取命令**（root / shizuku / run-as）：
```bash
run-as air.com.bvn.yy798 cat 'com.bvn.yy798/Local Store/bvn_debug.log'
```

> ⚠️ **重要**：历史 CLAUDE.md/AGENTS.md 中部分位置曾写 `com.bvn.yinyu`（旧 application.xml 内容），已纠正为 `com.bvn33.y36`。但私有目录内的 `com.bvn.yy798` 是 AIR 实际使用的，**不要**改成 `com.bvn33.y36` —— 改了之后路径会找不到。

---

## 批次 6 选人界面黑屏治本总结（2026-08-27）

**问题**：进入选人界面黑屏（含 23 个 `BitmapAssetLoader.loadFail` face 资源缺失 + 选人界面崩溃）。

### 根因（按发现顺序）

| 根因编号 | 描述 | 定位方法 | 修复批次 | 修复文件 |
|---------|------|---------|---------|---------|
| **根因 A** | `MenuBtn.addEventListener("click", ...)` 覆盖 bug：MenuBtn 自定义基类已有 `click` 监听器，子类重复注册导致旧监听器被覆盖 | 排查 MenuBtnGroup / MenuBtn 基类链 | 批次 6.7 治本 | `SelectFighterItem.as` 加 `ENTER_FRAME` 监听 + `_refreshFace()` 私有方法 |
| **根因 B** | `BitmapAssetLoader` 加载 face 资源路径找不到 23 个 PNG（路径大小写/扩展名不匹配） | 日志 `BitmapAssetLoader.loadFail :: assets/face/xxx.png` | 治标（face MISS else 兜底 + TextField fallback） | `SelectFighterItem.as` |
| **根因 C** | `ViewManager.refreshMultiPadCache()` 第 50 行 `var pads:Array = JoySticker.getAllDeivces()` — `JoySticker.getAllDeivces()` 实际返回 `Vector.<GameInputDevice>`，赋给 `Array` 类型变量触发 AS3 隐式 cast 失败 → `TypeError #1006` | 日志 `[MainGame] goSelect FAILED: Error #1006` 完整调用链 → KyoStageCtrl → SelectFighterStage.build() | 批次 6.9 | `ViewManager.as`：`var pads:Array` → `var pads:*` |
| **根因 D** | `SelectFighterStage.build()` 第 97 行 `MainGame.I.stage.dispatchEvent(new DataEvent("5d_message", ...))` 中 `MainGame.I.stage` 在某些时序下为 null → #1006；3.9 风格的 `GameEvent.dispatchEvent` 是更稳的单例 EventDispatcher 派发 | 排查 MainGame.goSelect + stage 时序 | 批次 6.10 | `SelectFighterStage.as`：改用 `GameEvent.dispatchEvent("SELECT_FIGHTER", null, false, false)` |
| **根因 E（终极根因）** | `SelectFighterStage.build()` 第 86 行 `Debugger.log("[SelectStage]", "build() enter, gameMode=" + GameMode.getCurMode())` —— `GameMode.getCurMode()` **整个项目根本不存在**（只有 `getTeams()` / `isVsCPU()` / `isAcrade()` 等）！批次 6.10 添加时**未核实方法是否存在**，`-strict=false` 静默通过编译，但 AS3 运行时调用未定义方法 → `TypeError #1006`，**整个 `Debugger.log` 表达式未执行就抛错** | 用 Python zlib 解压 SWF 验证 4 个 `build() enter` 位置都在 SWF 内 + 确认 APK 内 SWF md5 = 本地 SWF md5 完全一致 + 但运行时 build 入口 log 缺失 → 反推 `Debugger.log(...)` 表达式求值时就抛错 | 批次 6.11 | `SelectFighterStage.as`：删除 `getCurMode()` 调用，改用 `GameMode.getTeams()`（同样 try-catch 兜底） |

### 关键调试方法论（黑屏排查 23 轮迭代沉淀）

1. **完整堆栈捕获**：`MainGame.goSelect()` 用 `try { ... } catch(e:Error) { try { _st = e.getStackTrace(); } catch(_e:Error) {} Debugger.log(...); }` 包裹所有 `stageCtrl.goStage(...)` 调用，输出到 `bvn_debug.log`
2. **SWF 内容核验**：
   - **APK 内 SWF md5 vs 本地 SWF md5** 完全一致 → 注入成功
   - 用 Python zlib 解压 SWF（CWS 格式 → 35309281B FWS），搜索关键字符串（`build() enter` × N、`SELECT_FIGHTER` × N）→ 确认编译产物包含目标代码
   - **不要相信 strings / grep** — SWF 是 CWS 压缩，字符串在 zlib payload 内，strings 找不到
3. **运行时 vs 编译期语义差异**：`-strict=false` 模式下，**调用未定义方法**（`getCurMode()` 这种）会**静默通过编译**，但运行时 #1006
4. **方法存在性核实**：修改任何文件前 `grep -rn 'MethodName(' /storage/emulated/0/BVN3.3EX-master/BVNscripts/scripts/` 先看方法是否真的存在
5. **APK 注入一致性**：注入脚本用 Python `zipfile` 替换 `assets/launch.swf`（单层路径，不是 `assets/launch/launch.swf`），注入后用 `unzip -p base.apk assets/launch.swf | md5sum` 验证
6. **APK 路径变化检测**：每次 APK 重新签名后，Android 系统会自动重装到新路径（如 `~~7Ho_cwT9RzmwoRsw0CLLUg==` → `~~p3DYIcsMh4wv1gE3r92RrQ==`），需用 `pm path air.com.bvn.yy798` 重新查询

### 批次演进时间线

| 批次 | SWF 大小 | 关键改动 | 状态 |
|------|---------|---------|------|
| 6.7 治本 | 34608882B | `SelectFighterItem.as` face 资源加载失败兜底（ENTER_FRAME 监听 + `_refreshFace`） | ✅ face MISS 已兜底 |
| 6.8 | 34610748B | 12 文件 19 处 Debugger.log 增强（选人/设置 UI 增强） | ✅ 日志可观测 |
| 6.9 | 34611364B | `ViewManager.as` `var pads:Array` → `var pads:*`（治标） | ✅ 根因 C 修复 |
| 6.10 | 34611800B | `SelectFighterStage.build()` 11 步 try-catch 防御 + `GameEvent` 改造 | ⚠️ 引入新 bug 根因 E |
| **6.11** | **34611901B** | `SelectFighterStage.build()` 第 86 行删除 `GameMode.getCurMode()`（方法不存在），改用 `getTeams()` 兜底 | ✅ 根因 E 修复（待 APK 注入真机验证） |

### 备份清单（本轮所有变更）

| 文件 | 备份名 |
|------|--------|
| `SelectFighterStage.as` | `.backup/SelectFighterStage.as.batch610.tryc.2026-08-27-1409`（批次 6.10 起点）|
| `SelectFighterStage.as` | `.backup/SelectFighterStage.as.batch611.getCurMode_fix.<时间戳>`（批次 6.11 起点）|
| `tools/Test/launch.swf` | `.backup/launch.swf.batch610.getCurMode_bug.<时间戳>`（批次 6.10 编译产物，已确认含 bug）|
| `inject_apk_611.py` | `.backup/inject_apk_611.py`（批次 6.11 APK 注入脚本，路径 `assets/launch.swf`）|
| `CLAUDE.md` | `.backup/CLAUDE.md.2026-08-27-*`（本次文档更新）|
| `AGENTS.md` | `.backup/AGENTS.md.2026-08-27-*`（本次文档更新）|

### 重要教训（避免再犯）

1. **写新代码前先 `grep` 验证 API 存在** —— `GameMode.getCurMode()` 不存在 → #1006
2. **`-strict=false` 会让未定义方法静默通过编译** —— 不要迷信"编译通过 = 代码对"
3. **复杂表达式 `Debugger.log(... + unknownMethod())` 要 try-catch 包裹** —— 表达式求值时抛错会跳过整行 log
4. **每步加 try-catch 是好事，但 try-catch 不能弥补根本 bug** —— 批次 6.10 的 11 步 try-catch 没拦到第 86 行的 `getCurMode`，因为它在第一个 `try` 块之外
5. **APK 注入 + md5 一致 ≠ bug 修复** —— 真机运行才是金标准
6. **应用包名有三层** —— Android 包名 / AIR applicationID / AIR 私有目录内 ID，三个值不同，混用会迷路

