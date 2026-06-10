# BVN（死神vs火影）— AS3 格斗游戏

> **AI 开发助手**：请同时阅读 [AGENTS.md](AGENTS.md) 获取本项目专属的开发行为准则和工具配置。简单工作优先交给 `deepseek-v4-flash` 执行。

## 项目概述

本项目是 **5dplay 出品的"死神vs火影" V3.3** — 基于 ActionScript 3 开发的 2D Flash 格斗游戏。源码从 SWF 反编译后经手动修复，现基于可编译基线持续开发。

| 目录 | 说明 |
|------|------|
| `BVNscripts/scripts/` | 可编译源码（含 `_assets/` 嵌入资源、`mx/` Flex 框架桩） |
| `Outscripts/` | 修改后脚本导出目录（git 忽略，`sync.py` 同步回 BVNscripts） |
| `tools/Test/` | 编译产物与运行时资源 |
| `tools/Test/assets/` | 运行时加载资源：角色 SWF / 地图 / BGM / 头像 / 配置文件 |
| `tools/script/` | 调试/打包/同步脚本 |
| `extensions/BVNFileReader/` | ANE 原生扩展（Java + AS3） |
| `BVN3.9/` | BVN 3.9 参考源码（只读，多模块 CORE/LIB/SHELL 结构） |
| `build.bat` | 一键编译脚本（`Ctrl+Shift+B` 或直接运行） |
| `asconfig.json` / `.vscode/` | VSCode 构建配置 |

## 构建与调试

### 环境配置

| 变量 | 位置 | 用途 |
|------|------|------|
| Flex SDK | `项目根\flex4.16.1-air51.0.1.1\` | mxmlc 编译器 + Flex 框架 + AIR 运行时 |
| AIR SDK | `项目根\AIRSDK5\AIRSDK_51.3.2\` | ADT 打包 / adl 启动 / fdb 调试（签名证书 `bin\mycert.p12`） |
| `FLEX_HOME` | 自动检测 → AIR SDK | 调试脚本定位 `bin\fdb`、`bin\adl.exe` |
| `JAVA_HOME` | JDK 17 | mxmlc 运行时 |
| ADB | `tools\platform-tools\adb.exe` | 手机真机调试 |
| 证书 | `AIRSDK5\AIRSDK_51.3.2\bin\mycert.p12` | APK 签名（密码 yinyu7798） |
| App 描述 | `tools\Test\application.xml` | AIR 应用配置（`com.bvn.yinyu`） |

### PC 端开发

```bash
# 编译（VSCode: Ctrl+Shift+B 或直接运行）
./build.bat

# 编译器：mxmlc (Flex SDK)
# 源文件：BVNscripts/scripts/launch.as
# 输出：tools/Test/launch.swf（~4.6MB）
```

#### 调试工具

| 工具 | 位置 | 用途 |
|------|------|------|
| `build.bat` | 项目根 | 编译 tools/Test/launch.swf |
| `debug.bat` | `tools/script/` | 编译 + adl 启动（自动复制 SWF + 使用 application.xml） |
| `debug_mob.bat` | `tools/script/` | 编译 → ADT 打包 → ADB 安装 → adb logcat 实时日志 |
| `fdbg.bat` | `tools/script/` | 通用 fdb 连接 SWF 进行断点调试 |

`tools/script/lang/` 目录包含多代码页包装脚本（437/932/936/949），解决系统编码兼容。

### 移动端开发（Android）

#### 前置条件
- `FLEX_HOME` 指向 AIR SDK 根目录
- `adb` 在 PATH 中（或使用 `tools/platform-tools/adb.exe`）
- 手机启用「USB 调试」并连接电脑

#### APK 打包与调试

```bash
# 一键：编译 + 打包 + 安装 + logcat 实时日志（debug_mob.bat 自动完成全部）
tools/script/debug_mob.bat

# 手动打包（Captive Runtime, armv8, 从 tools/Test 目录执行）
cd tools/Test
adt -package -target apk-captive-runtime -arch armv8 -storetype pkcs12 -keystore "%FLEX_HOME%\bin\mycert.p12" -storepass yinyu7798 死神vs火影银鱼改.apk application.xml launch.swf assets
```

> **APK 瘦身**：`debug_mob.bat` 打包时自动将 fighter/map/face/bgm 备份，以空目录打包进 APK，打包后恢复。实际内容部署在 `/sdcard/BVN/assets/` 外部存储。

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
│   │   │   ├── GameLoader.as            # 角色/地图/辅助 SWF 加载 + 外部角色扫描（loadFighterFromPath）
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
│   │   │   │   ├── FighterCtrler.as     # 角色综合控制器
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

| 目录 | 说明 |
|------|------|
| `extensions/BVNFileReader/` | ANE 原生扩展完整实现（Android Java + AS3 库 + 构建脚本） |
| `extensions/BVNFileReader/Android/src/com/bvn/filereader/` | Java 源码：Extension / ExtensionContext / ReadBytesFunction / ListDirFunction / ExistsFunction |
| `extensions/BVNFileReader/as3/com/bvn/filereader/` | AS3 库：BVNFileReaderLib.as |
| `tools/ane/` | 旧版 ANE 实现（功能已由 extensions/BVNFileReader 取代） |
| `tools/platform-tools/` | Android SDK 工具（adb/fastboot/sqlite3） |
| `tools/script/lang/` | 多代码页 bat 包装（437/932/936/949 编码适配） |
| `BVN3.9/` | BVN 3.9 参考源码（CORE_Components/CORE_KernelLogic/CORE_Shared/CORE_Utils/LIB_KyoLib/LIB_Other/SHELL_Dev/SHELL_Mob/SHELL_Pc） |
| `.codegraph/` | Codegraph 知识图谱索引 |
| `.claude/` | Claude Code 会话数据 |

## 核心系统

### 角色系统

#### 动作状态常量（FighterActionState）

| 常量 | 值 | 含义 |
|------|----|------|
| `NORNAL` | 0 | 站立 |
| `ATTACK_ING` | 10 | 攻击中 |
| `SKILL_ING` | 11 | 技能中 |
| `BISHA_ING` | 12 | 必杀中 |
| `BISHA_SUPER_ING` | 13 | 超必杀中 |
| `JUMP_ING` | 14 | 跳跃中 |
| `DASH_ING` | 15 | 冲刺/瞬步中 |
| `JUSHOU_ING` | 16 | 受身中 |
| `DEFENCE_ING` | 20 | 防御中 |
| `HURT_ING` | 21 | 受伤中 |
| `HURT_FLYING` | 22 | 击飞中 |
| `HURT_DOWN` | 23 | 倒地中 |
| `DEAD` | 30 | 死亡 |
| `ATTACK_AIR` | 40 | 空中攻击 |
| `WAN_KAI_ING` | 50 | 卍解中 |
| `KAI_CHANG` | 60 | 开场 |
| `WIN` | 61 | 胜利 |
| `LOSE` | 62 | 失败 |

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

### 移动端特性

- **TOUCH_MODE** — 默认 `true`
- **ScreenPadManager** — 屏幕触控按钮管理（游戏内 + 选人界面）
- **GameInterfaceManager** — 移动端菜单/设置/INFINITE_ENERGY 配置同步
- **ScreenRotater** — 屏幕旋转
- **InputManager** — 多种输入源管理（触控 + 摇杆 + 键盘 + 网络）
- **LAN 多人** — `sockets/` + `ctrls/` 局域网对战（TCP + UDP 混合，含锁帧同步）
- **ANEFileReader** — 原生文件读取，支持 SD 卡外部资源加载
- **外部资源加载** — 启动时自动扫描 `/sdcard/BVN/assets/fighter/` + `/sdcard/BVN/assets/map/`，追加到内置资源后

### 资源加载架构

游戏资源分为三个层级：

1. **嵌入资源**：`_assets/` 中的 PNG/MP3/JPG/BIN 通过 `[Embed]` 标签嵌入 SWF（`EmbeddedAssets.as` 统一管理）
2. **APK 内置资源**：`tools/Test/assets/` 打包进 APK（sounds/font/config/swf/effect.swf/movelist.jpg）
3. **SD 卡外部资源**：`/sdcard/BVN/assets/{fighter,map,face,bgm}/` 运行时加载（追加到内置资源后）

#### 双路径加载（手机端）

```
加载资源 → 先查 SD 卡: /sdcard/BVN/assets/fighter/xxx.swf (ANEFileReader)
         → 不存在: assets/fighter/xxx.swf (APK 内置)
```

#### 启动流程

```
GameData.loadConfig()
  → 加载 APK 内置 fighter.xml → FighterModel.initByXML()
  → GameLoader.scanExternalAssets()
  │   ├─ scanExternalFighters(): /sdcard/BVN/assets/fighter/*.swf → 追加到 FighterModel
  │   └─ scanExternalMaps(): /sdcard/BVN/assets/map/*.swf → 追加到 MapModel
  → 加载 APK 内置 assist.xml / select.xml / map.xml / mission.xml
  → GameLoader.loadExternalConfigs()
      ├─ /sdcard/BVN/assets/config/fighter.xml → FighterModel.mergeByXML()
      ├─ /sdcard/BVN/assets/config/assist.xml → AssisterModel.mergeByXML()
      ├─ /sdcard/BVN/assets/config/map.xml → MapModel.mergeByXML()
      └─ /sdcard/BVN/assets/config/mission.xml → MessionModel.mergeByXML()
```

SD 卡外部目录结构（与 APK 内 `assets/` 一致）：
```
/sdcard/BVN/assets/
├── fighter/    # 额外角色 SWF
├── map/        # 额外地图 SWF
├── face/       # 额外头像 PNG
├── bgm/        # 额外 BGM MP3
└── config/     # 额外配置 XML（追加合并，不替换内置配置）
    ├── fighter.xml   # 额外角色定义
    ├── assist.xml    # 额外辅助角色
    ├── map.xml       # 额外地图
    └── mission.xml   # 额外关卡
```

> **config 合并规则**：SD 卡 XML 中的条目追加到 APK 内置条目之后，ID 冲突时内置优先（SD 卡重复条目被跳过）。

UI SWF 加载流程：
```
ResUtils.as → 从 assets/swf/ 加载 UI SWF（仅 APK 内置） → 创建 UI 实例
GameLoader.as → 从 assets/fighter/ 或 SD 卡加载角色 SWF → FighterMain 实例化
```

## ANE 原生扩展

### BVNFileReader（`extensions/BVNFileReader/`）

突破 AIR 沙箱限制，访问 Android 外部存储：

```as3
// AS3 端（mob/utils/ANEFileReader.as 封装）
var ba:ByteArray = ANEFileReader.I.readBytes("/sdcard/BVN/assets/fighter/ichigo.swf");
var files:Array = ANEFileReader.I.listDir("/sdcard/BVN/assets/fighter/");
if (ANEFileReader.I.exists("/sdcard/BVN/assets/fighter/")) { ... }

// 路径映射工具
var extPath:String = ANEFileReader.resolveExternalPath("assets/fighter/ichigo.swf");
// → "/sdcard/BVN/assets/fighter/ichigo.swf"
var exists:Boolean = ANEFileReader.hasExternalAsset("assets/fighter/ichigo.swf");

// 从绝对路径加载角色（集成 GameLoader）
GameLoader.loadFighterFromPath("/sdcard/BVN/assets/fighter/ichigo.swf", callback, failCallback);
```

**ANE 未安装时**自动降级为 AIR `flash.filesystem.File` API（仅沙箱内可用）。

#### 文件位置
- `mob/utils/ANEFileReader.as` — AS3 封装层（含 debug 日志）
- `extensions/BVNFileReader/as3/com/bvn/filereader/BVNFileReaderLib.as` — ANE 库接口
- `extensions/BVNFileReader/Android/src/com/bvn/filereader/` — Java 原生实现
- `extensions/BVNFileReader/build_ane.bat` — ANE 构建脚本
- `tools/Test/application.xml` — 已启用 `<extensionID>com.bvn.filereader</extensionID>`

## 关键 Bug 修复记录

| 修复 | 涉及文件 | 说明 |
|------|----------|------|
| PauseDialog visible | `PauseDialog.as` | showMoveList 隐藏按钮组，hideMoveList 恢复 |
| 训练模式 AI 开关 | `GameCtrl.as` + `PauseDialog.as` | `toggleFighterAI()` 绕过模式强制 AI |
| 开场帧检查 | `FighterMcCtrler.as` | sayIntro/doWin/doLose 先 checkFrame |
| INFINITE_ENERGY | `FighterMcCtrler` + `FighterAction` | setBisha/doBisha/doWaiKai/render 全部检查 |
| AI 无限气关闭时必杀 | 3 处修复 | 关闭时角色仍可无视条件释放必杀 |
| trace() → Debugger.log() | 全局 | 全面替换，支持 logcat 实时输出 + 面板显示 |
| Debugger 面板 | `Debugger.as` | 修复空白行 + 文本复制 + 折叠/展开 + 手机端自适应 |
| 选人分页布局 | `SelectFighterStage.as` | 固定 rowsPerPage=3 + FLA 翻页联动 + _ui.bg |
| fighter.xml 语法错误 | `fighter.xml:1026` | XML 格式修复，解决手机端白屏 |
| ScreenPadAsset.light | `ScreenPadAsset.as` | 使用真实 light.png 替代 skill_png |
| build.bat SWF 输出 | `build.bat` + `debug.bat` | 直出 tools/Test/launch.swf |
| ADT 打包 assets | `debug_mob.bat` | slim APK： fighter/map/face/bgm 空目录 + 打包后恢复 |
| .bat UTF-8 BOM | 所有 .bat | CRLF + BOM 编码修复解决双击闪退 |
| SetBtn 重入 | `SetBtn.as` | 全局静态重入守卫 + deferred dispatchEvent |
| debug_mob.bat | 多次迭代 | FLEX_HOME 自动检测 + PATH 方式 adb + 基于 BVN3.9 重写 |

## 构建脚本故障排查

本节汇集 `build_ane.bat` 和 `debug_mob.bat` 常见崩溃（闪退/报错）的系统性排查流程。

### 优先级排查清单

出现 `双击闪退` 或 `报错后立即关闭` 时，按以下顺序排查：

| 优先级 | 排查项 | 症状 | 修复法 |
|:---:|--------|------|--------|
| **1** | `exit /b` | cmd 窗口一闪而过 | 全部改为 `goto :EOF`，末尾加 `pause` |
| **2** | 调用其他 `.bat` 缺 `call` | 子 bat 退出时连带终止主脚本 | `call "%ADT%"` 而非 `"%ADT%"` |
| **3** | `()` 块内 `)` 未转义 | `-- was unexpected at this time.` | 批处理 `()` 内的文字 `)` 须用 `^)` 转义；或避免在 `if ()` 块中嵌入含 `)` 的多行命令 |
| **4** | `-C "path\"` 末尾反斜杠 | `No such directory: ..." .` | Windows 命令行 `\"` 会被解析为转义引号 → 去掉末尾 `\` |
| **5** | `::` 注释含特殊字符 | `'xxx' 不是内部或外部命令` | 中文/Unicode 字符多时改用 `REM` |
| **6** | javac 不认 `*.java` 通配符 | `无效文件名: ...\*.java` | 显式列出 `.java` 源文件 |
| **7** | powershell 内联 `^` 续行 | `-- was unexpected` | 内联 PowerShell 的在 `if ()` 块中极易破坏括号匹配 → 改用独立 `.ps1` 文件或简化逻辑 |
| **8** | `pause >nul` | 看不到 "按任意键继续" | 去掉 `>nul` |
| **9** | ANE 文件缺失 | 运行时 `implementation not found` | 先运行 `build_ane.bat` 生成 ANE |
| **10** | 上次中断遗留 `_bakslim_*` | `already exists` | 打包前先检查并恢复遗留备份目录 |

### 安全修改模式

修改 `.bat` 文件时必须遵守：
1. **先备份后可回滚**：用 `git checkout -- <file>` 恢复
2. **每次只改一个点**：改完双击测试，确认无误再改下一个
3. **避免内联 PowerShell**：涉及 `)`、`$`、`^` 时极易出问题 → 写独立 `.ps1` 文件
4. **用 `call` 调子 bat**：永不直接调用另一个 `.bat`
5. **用 `goto :EOF` 而非 `exit /b`**：前者返回调用方，后者会关闭最外层 cmd 窗口

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
排除：`*.swf` / `*.swc` / `*.apk` / `*.png` / `*.jpg` / `*.mp3` / `*.bin` / `_assets/` / `assets/swf/` / `flex4.16.1-air51.0.1.1/` / `AIRSDK5/` / `tools/Test/` / `last/` / `OLD/` / `BVN3.9/` / `Outscripts/` / `node_modules/` / `dist/`

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

| 需求 | 优先查看 |
|------|---------|
| 编译 | `build.bat`、`asconfig.json` |
| 调试 | `tools/script/debug.bat`、`tools/script/debug_mob.bat` |
| 入口/初始化 | `launch.as`、`MainGame.as` |
| 物理参数 | `GameConfig.as` |
| 角色动作状态机 | `FighterMcCtrler.as` |
| 角色动作定义 | `FighterAction.as`、`FighterActionState.as` |
| AI 系统 | `fighter/ctrler/ai/FighterAILogic.as`、`fighter/ctrler/ai/FighterAILogicBase.as` |
| AI 控制适配器 | `fighter/ctrler/FighterAICtrl.as` |
| AI 系统完整文档 | `AI-SYSTEM-DOC.md` |
| 碰撞检测 | `GameMainLogicCtrler.as` |
| 角色实体 | `fighter/FighterMain.as` |
| 菜单/按钮 | `MenuBtnGroup.as`、`MenuBtn.as` |
| 暂停菜单 | `PauseDialog.as` |
| 设置 | `SetBtnGroup.as`、`SettingState.as` |
| 输入 | `GameInputer.as`、`FighterKeyCtrl.as` |
| 配置/存档 | `GameData.as`、`ConfigVO.as` |
| 嵌入式资源 | `EmbeddedAssets.as`、`mx/core/` |
| UI SWF 加载 | `ResUtils.as` |
| 角色加载 | `ctrl/GameLoader.as`、`ctrl/AssetManager.as` |
| 移动端 | `mob/GameInterfaceManager.as`、`mob/ScreenRotater.as` |
| 触控 | `mob/screenpad/ScreenPadManager.as` |
| 网络 | `mob/sockets/`、`mob/ctrls/LAN*.as` |
| 外部角色 | `mob/utils/ANEFileReader.as`、`ctrl/GameLoader.as::scanExternalAssets()` |
| 调试面板 | `Debugger.as`（`DEBUG_PANEL_ENABLED` 开关） |
| 运行时配置 | `tools/Test/assets/config/fighter.xml`、`select.xml` |
| ANE 扩展 | `extensions/BVNFileReader/` |
| 代码同步 | `sync.py` |
| 模型路由 | `tools/route_model.py`、`.claude/skills/route-model.md` |

## 版本信息

| 项目 | 内容 |
|------|------|
| 游戏版本 | V3.3（2019.3.32） |
| 开发商 | 5dplay（net.play5d） |
| 平台 | Flash Web + Android/iOS + LAN 局域网对战 |
| SDK | Apache Flex 4.16.1 + AIR 51.0 |
| 编译器 | mxmlc.jar（Java 17） |
| 编辑器 | VSCode + ActionScript & MXML 插件 |
| ANE 扩展 | BVNFileReader（com.bvn.filereader）— Android 外部存储读取 |
| 调试 | fdb 断点调试 + adb logcat 实时日志 |
| 许可 | GPL-3.0 |
