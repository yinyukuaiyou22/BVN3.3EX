# BVN（死神vs火影）— AS3 格斗游戏

## 项目概述

本项目是 **5dplay 出品的"死神vs火影" V3.3** — 一款基于 ActionScript 3（AS3）开发的 2D Flash 格斗游戏。源码从 SWF 反编译后经过手动修复，现正在进行逐步修改。

- **`BVNscripts/scripts/`** — 修复后的原始源码（342 个 `.as` 文件）
- **`Outscripts/`** — 修改后脚本的导出目录（目前为空，保持与源码相同的目录结构）

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
├── com/
│   ├── greensock/                     # TweenLite 补间动画库
│   │   ├── TweenLite.as               # 核心补间类
│   │   ├── core/                      # TweenCore、SimpleTimeline、PropTween
│   │   └── easing/                    # Back、Elastic 缓动函数
│   └── adobe/utils/StringUtil.as      # Adobe 字符串工具
├── fl/
│   └── motion/                        # Flash 运动辅助（ColorMatrix、DynamicMatrix）
├── flash/compiler/embed/              # EmbeddedMovieClip.as（Flash 编译器嵌入用）
├── net/play5d/
│   ├── game/bvn/                      # === 主游戏代码 ===
│   │   ├── MainGame.as                # 游戏状态机（版本 "V3.3"）
│   │   ├── GameConfig.as              # 所有游戏常量和物理参数调节
│   │   ├── GameQuailty.as             # 画质设置
│   │   ├── Debugger.as                # 调试面板（日志 + FPS/内存性能监视器）
│   │   ├── ctrl/                      # 核心控制器层
│   │   │   ├── GameLoader.as          # 加载角色/地图/辅助 SWF 资源
│   │   │   ├── GameLogic.as           # 物理、碰撞、计分、命中逻辑
│   │   │   ├── GameRender.as          # EnterFrame 渲染循环（回调注册表）
│   │   │   ├── AssetLoader.as         # 底层资源加载
│   │   │   ├── AssetManager.as        # SWF/XML 加载管理器
│   │   │   ├── EffectCtrl.as          # 视觉效果管理器（打击火花等）
│   │   │   ├── SoundCtrl.as           # BGM 和音效控制
│   │   │   ├── StateCtrl.as           # 游戏状态控制
│   │   │   └── game_ctrls/            # 游戏子控制器
│   │   │       ├── GameCtrl.as        # 中央游戏控制器（主渲染循环）
│   │   │       ├── GameStartCtrl.as   # 回合开场序列（登场动画）
│   │   │       ├── GameEndCtrl.as     # 回合结束序列（KO、胜负）
│   │   │       ├── GameMainLogicCtrler.as  # 逐帧逻辑（物理、碰撞检测）
│   │   │       ├── FighterEventCtrl.as     # 角色事件处理
│   │   │       └── TrainingCtrler.as       # 训练模式
│   │   ├── data/                      # 数据模型和 VO（Value Objects）
│   │   │   ├── GameData.as            # 中央数据存储（配置、选择、分数）
│   │   │   ├── ConfigVO.as            # 玩家配置/设置 VO
│   │   │   ├── FighterVO.as           # 角色定义（id、名称、文件、BGM 等）
│   │   │   ├── FighterModel.as        # 角色注册表（从 fighter.xml 加载）
│   │   │   ├── AssisterModel.as       # 辅助角色注册表（assist.xml）
│   │   │   ├── MapModel.as            # 地图/场景注册表（map.xml）
│   │   │   ├── MapVO.as               # 地图定义
│   │   │   ├── MessionModel.as        # 闯关模式数据（mission.xml）
│   │   │   ├── MessionVO.as / MessionStageVO.as  # 关卡定义
│   │   │   ├── EffectModel.as / EffectVO.as      # 效果定义
│   │   │   ├── GameMode.as            # 游戏模式常量（组队、单人、闯关等）
│   │   │   ├── GameRunDataVO.as       # 运行时比赛数据
│   │   │   ├── GameRunFighterGroup.as # 比赛中角色组状态
│   │   │   ├── HitType.as             # 攻击类型常量
│   │   │   ├── TeamVO.as / TeamMap.as # 队伍管理
│   │   │   ├── SelectVO.as            # 选人数据
│   │   │   ├── SelectCharListConfigVO.as / SelectCharListItemVO.as  # 选人界面配置
│   │   │   ├── SelectStageConfigVO.as # 选场景配置
│   │   │   ├── KeyConfigVO.as         # 按键绑定配置
│   │   │   └── BitmapDataCacheVO.as   # 位图数据缓存
│   │   ├── fighter/                   # === 角色系统（核心）===
│   │   │   ├── FighterMain.as         # 主角色实体（HP、气、能量、状态）
│   │   │   ├── FighterAction.as       # 各状态下可用动作（存放帧标签名）
│   │   │   ├── FighterActionState.as  # 动作状态常量（NORMAL、HURT_ING 等）
│   │   │   ├── FighterMC.as           # MovieClip 包装器（帧控制、攻击判定区）
│   │   │   ├── FighterAttacker.as     # 子攻击者实体（如剑气、残影等）
│   │   │   ├── FighterHitRange.as     # 攻击范围定义
│   │   │   ├── FighterDefenseType.as  # 防御类型枚举
│   │   │   ├── Assister.as            # 辅助角色实体
│   │   │   ├── Bullet.as              # 飞行道具实体
│   │   │   ├── ctrler/                # 角色控制器
│   │   │   │   ├── FighterCtrler.as   # 主角色控制器（门面模式）
│   │   │   │   ├── FighterMcCtrler.as # MovieClip/动画控制器（~2260 行，最核心）
│   │   │   │   ├── FighterKeyCtrl.as  # 玩家输入控制器（实现 IFighterActionCtrl）
│   │   │   │   ├── FighterAICtrl.as   # AI 输入控制器（实现 IFighterActionCtrl）
│   │   │   │   ├── FighterAttackerCtrler.as  # 子攻击者控制器
│   │   │   │   ├── FighterBuffCtrler.as      # Buff/减益系统
│   │   │   │   ├── FighterEffectCtrl.as      # 角色专属特效（发光、残影、震屏）
│   │   │   │   ├── FighterVoice.as / FighterVoiceCtrler.as  # 语音/音效
│   │   │   │   ├── AssisiterCtrler.as        # 辅助角色控制器
│   │   │   │   └── ai/
│   │   │   │       ├── FighterAILogic.as     # AI 行为逻辑
│   │   │   │       └── FighterAILogicBase.as # AI 基类
│   │   │   ├── events/
│   │   │   │   ├── FighterEvent.as           # 角色事件类型
│   │   │   │   └── FighterEventDispatcher.as # 事件分发器
│   │   │   ├── models/
│   │   │   │   ├── FighterHitModel.as        # 攻击判定注册表
│   │   │   │   └── HitVO.as                  # 单次攻击判定数据（伤害、类型等）
│   │   │   ├── utils/McAreaCacher.as         # 按帧缓存攻击/身体判定区域
│   │   │   └── vos/
│   │   │       ├── FighterBuffVO.as          # Buff 数据
│   │   │       └── MoveTargetParamVO.as      # 移动目标参数
│   │   ├── state/                     # 游戏状态（均实现 Istage 接口）
│   │   │   ├── LogoState.as           # Logo 画面
│   │   │   ├── MenuState.as           # 主菜单
│   │   │   ├── LoadingState.as        # 战斗前加载
│   │   │   ├── GameLoadingState.as    # 初始资源加载
│   │   │   ├── SelectFighterStage.as  # 角色选择界面
│   │   │   ├── GameState.as           # ** 主战斗状态 **（精灵、图层、摄像机）
│   │   │   ├── GameCamera.as          # 摄像机（自动缩放、跟随、补间）
│   │   │   ├── SettingState.as        # 设置菜单
│   │   │   ├── HowToPlayState.as      # 教程/操作说明
│   │   │   ├── GameOverState.as       # 游戏结束/继续
│   │   │   ├── WinnerState.as         # 胜利画面
│   │   │   ├── CongratulateState.as   # 闯关完成
│   │   │   └── CreditsState.as        # 制作人员
│   │   ├── ui/                        # UI 组件
│   │   │   ├── GameUI.as              # 主 UI 容器
│   │   │   ├── IGameUI.as             # UI 接口
│   │   │   ├── fight/                 # 战斗中 UI
│   │   │   │   ├── FightUI.as         # 战斗 HUD
│   │   │   │   ├── FighterHpBar.as    # 血条
│   │   │   │   ├── QiBar.as / EnergyBar.as  # 气条/能量条
│   │   │   │   ├── FightBar.as        # 底部栏
│   │   │   │   ├── FightFaceUI.as / FightFaceGroup.as  # 角色头像显示
│   │   │   │   ├── FightTimeUI.as     # 计时器
│   │   │   │   ├── FightScoreUI.as    # 分数显示
│   │   │   │   ├── HitsUI.as          # 连击计数器
│   │   │   │   └── FightQiBarMode.as  # 气条模式
│   │   │   ├── select/                # 选人 UI
│   │   │   │   ├── SelectFighterItem.as      # 角色选项
│   │   │   │   ├── SelectIndexUI.as          # 选人索引
│   │   │   │   ├── SelectIndexUIGroup.as     # 选人索引组
│   │   │   │   ├── SelectUIFactory.as        # 选人 UI 工厂
│   │   │   │   ├── SelectedFighterGroup.as   # 已选角色组
│   │   │   │   ├── SelectedFighterUI.as      # 已选角色 UI
│   │   │   │   ├── SelecterItemUI.as         # 选择器项
│   │   │   │   └── MapSelectUI.as            # 地图选择
│   │   │   ├── dialog/                # 弹窗
│   │   │   │   ├── AlertUI.as         # 提示框
│   │   │   │   └── ConfrimUI.as       # 确认框
│   │   │   ├── PauseDialog.as         # 暂停对话框
│   │   │   ├── WinUI.as               # 胜利 UI
│   │   │   ├── KeyMapping.as          # 按键映射
│   │   │   ├── MenuBtn.as / MenuBtnGroup.as  # 菜单按钮
│   │   │   ├── MoveListSp.as          # 出招表
│   │   │   ├── QuickTransUI.as / TransUI.as  # 过渡动画
│   │   │   ├── SetBtn.as / SetBtnDialog.as / SetBtnGroup.as / SetBtnLine.as  # 按钮设置
│   │   │   ├── SetCtrlBtnUI.as        # 控制器按钮设置
│   │   │   └── UIUtils.as             # UI 工具
│   │   ├── events/                    # 全局事件
│   │   │   ├── GameEvent.as           # 游戏事件
│   │   │   └── SetBtnEvent.as         # 按钮设置事件
│   │   ├── input/                     # 输入抽象层
│   │   │   ├── GameInputer.as         # 输入管理器（路由分发）
│   │   │   ├── GameInputType.as       # 输入类型常量
│   │   │   ├── GameKeyInput.as        # 键盘输入
│   │   │   └── IGameInput.as          # 输入接口
│   │   ├── interfaces/                # 接口和基类
│   │   │   ├── BaseGameSprite.as      # ** 核心 ** 基础实体（物理、速度、HP）
│   │   │   ├── IGameSprite.as         # 游戏精灵接口
│   │   │   ├── GameInterface.as       # 平台接口（Web/移动端桥接）
│   │   │   ├── IFighterActionCtrl.as  # 角色输入控制器接口
│   │   │   ├── IGameInterface.as      # 游戏平台接口
│   │   │   ├── IAssetLoader.as        # 资源加载接口
│   │   │   ├── IExtendConfig.as       # 扩展配置接口
│   │   │   ├── IInnerSetUI.as         # 内部设置 UI 接口
│   │   │   └── ILoger.as              # 日志接口
│   │   ├── map/                       # 地图/场景系统
│   │   │   ├── MapMain.as             # 地图实体
│   │   │   └── FloorVO.as             # 地板定义
│   │   ├── mob/                       # === 移动端支持 ===
│   │   │   ├── MobileCtrler.as        # 移动端控制器
│   │   │   ├── GameInterfaceManager.as # 平台桥接实现
│   │   │   ├── ScreenRotater.as       # 屏幕旋转
│   │   │   ├── ctrls/                 # LAN 局域网多人
│   │   │   │   ├── LANServerCtrl.as / LANClientCtrl.as       # 服务器/客户端
│   │   │   │   ├── LANGameCtrl.as / LanGameMenuCtrl.as       # LAN 游戏/菜单控制
│   │   │   │   ├── LockFrameServerLogic.as / LockFrameClientLogic.as  # 锁帧同步
│   │   │   │   ├── MobileCtrler.as    # 移动端主控制
│   │   │   │   └── SelectFighterServerLogic.as / SelectFighterClientLogic.as
│   │   │   ├── input/                 # 移动端输入
│   │   │   │   ├── InputManager.as    # 输入管理器
│   │   │   │   ├── GameJoystickInput.as  # 游戏摇杆输入
│   │   │   │   ├── GameSocketInput.as    # 网络输入
│   │   │   │   ├── ScreenPadInput.as     # 屏幕触控输入
│   │   │   │   ├── JoySticker.as         # 摇杆控件
│   │   │   │   ├── JoyStickConfigVO.as   # 摇杆配置
│   │   │   │   └── JoyStickSetVO.as      # 摇杆设置
│   │   │   ├── screenpad/             # 屏幕触控按钮
│   │   │   │   ├── ScreenPadManager.as     # 触控管理器
│   │   │   │   ├── ScreenPadGame.as        # 游戏触控
│   │   │   │   ├── ScreenPadSelectFighter.as  # 选人触控
│   │   │   │   ├── ScreenPadArrow.as       # 方向键
│   │   │   │   ├── ScreenPadBtn.as / ScreenPadBtnBase.as  # 按钮
│   │   │   │   ├── ScreenPadAsset.as       # 触控资源
│   │   │   │   └── ScreenPadUtils.as       # 触控工具
│   │   │   ├── sockets/               # TCP/UDP 网络
│   │   │   │   ├── SocketClient.as / SocketServer.as    # 客户端/服务器
│   │   │   │   ├── PacketBuffer.as / PacketUtils.as     # 数据包处理
│   │   │   │   ├── events/SocketEvent.as                # Socket 事件
│   │   │   │   └── udp/               # UDP 通信
│   │   │   │       ├── UDPSocket.as / UDPDataVO.as / UdpDataType.as
│   │   │   ├── views/                 # 移动端视图
│   │   │   │   ├── ViewManager.as     # 视图管理器
│   │   │   │   ├── AdPauseView.as     # 广告暂停视图
│   │   │   │   ├── CustomScreenBtnView.as   # 自定义屏幕按钮
│   │   │   │   ├── CustomSetBtnItemUI.as    # 自定义按钮项
│   │   │   │   ├── GameSideBg.as      # 游戏侧边背景
│   │   │   │   ├── JoyStickSetUI.as   # 摇杆设置 UI
│   │   │   │   ├── SetScreenBtnView.as      # 屏幕按钮设置
│   │   │   │   └── lan/               # LAN 视图
│   │   │   │       ├── HostDialogItem.as       # 主机列表项
│   │   │   │       ├── LANExitDialog.as        # LAN 退出对话框
│   │   │   │       ├── LANGameState.as         # LAN 游戏状态
│   │   │   │       └── LANHostCreateDialog.as  # 创建主机对话框
│   │   │   ├── data/                  # 移动端数据
│   │   │   │   ├── ClientVO.as        # 客户端数据
│   │   │   │   ├── ExtendConfig.as    # 扩展配置
│   │   │   │   ├── HostVO.as          # 主机数据
│   │   │   │   ├── ScreenPadConfigVO.as  # 屏幕触控配置
│   │   │   │   └── SocketInputData.as    # Socket 输入数据
│   │   │   ├── events/                # 移动端事件
│   │   │   │   ├── LanEvent.as        # LAN 事件
│   │   │   │   └── ScreenPadEvent.as  # 触控事件
│   │   │   └── utils/                 # 移动端工具
│   │   │       ├── AdManager.as       # 广告管理
│   │   │       ├── FileUtils.as       # 文件工具
│   │   │       ├── JsonUtils.as       # JSON 工具
│   │   │       ├── LANUtils.as        # LAN 工具
│   │   │       ├── LanSyncType.as     # LAN 同步类型
│   │   │       ├── LockFrameLogic.as  # 锁帧逻辑
│   │   │       ├── MsgType.as         # 消息类型
│   │   │       ├── SelectFighterDataType.as  # 选人数据类型
│   │   │       ├── SocketMsgFactory.as       # Socket 消息工厂
│   │   │       ├── UIAssetUtil.as     # UI 资源工具
│   │   │       └── UMengAneManager.as # 友盟 ANE 管理
│   │   ├── utils/                     # 通用工具
│   │   │   ├── ResUtils.as            # 资源初始化
│   │   │   ├── EffectManager.as       # 效果辅助
│   │   │   ├── KeyBoarder.as          # 键盘焦点
│   │   │   ├── MCUtils.as             # MovieClip 工具
│   │   │   ├── GameLoger.as           # 日志器
│   │   │   ├── BitmapAssetLoader.as   # 位图资源加载
│   │   │   └── URL.as                 # URL 常量
│   │   └── views/effects/             # 视觉特效视图
│   │       ├── EffectView.as          # 基础特效
│   │       ├── ShadowEffectView.as    # 残影特效
│   │       ├── ShineEffectView.as     # 闪光特效
│   │       ├── BuffEffectView.as      # Buff 特效
│   │       ├── BishaFaceEffectView.as # 必杀特写
│   │       ├── SteelHitEffect.as      # 钢身打击特效
│   │       ├── BlackBackView.as       # 黑背景
│   │       ├── BitmapFilterView.as    # 位图滤镜
│   │       └── SpecialEffectView.as   # 特殊效果
│   └── kyo/                           # === KYO 框架（5dplay 自研）===
│       ├── stage/
│       │   ├── KyoStageCtrl.as        # 状态/场景管理器
│       │   ├── Istage.as              # 场景接口（build/destory/afterBuild）
│       │   ├── effect/IStageFadEffect.as / ZoomEffect.as  # 场景切换特效
│       │   └── events/KyoStageEvent.as
│       ├── display/
│       │   ├── BitmapText.as          # 位图文本渲染
│       │   ├── MCNumber.as            # 通过 MC 显示数字
│       │   ├── bitmap/                # 位图字体系统
│       │   │   ├── BitmapFont.as / BitmapFontLoader.as / BitmapFontText.as
│       │   └── shapes/Box.as          # 矩形图形
│       ├── input/
│       │   ├── KyoKeyCode.as          # 键码常量
│       │   └── KyoKeyVO.as            # 按键 VO
│       ├── loader/                    # 资源加载器
│       │   ├── KyoClassLoader.as      # 类加载器
│       │   ├── KyoSoundLoader.as      # 声音加载器
│       │   ├── KyoURLoader.as         # URL 加载器
│       │   └── BitmapLoader.as        # 位图加载器
│       ├── sound/KyoBGSounder.as      # 背景音乐播放器
│       └── utils/
│           ├── KyoUtils.as            # 通用工具（num_wake 数值衰减、setValueByObject 等）
│           ├── KyoMath.as             # 数学工具
│           ├── KyoRandom.as           # 随机工具
│           ├── UUID.as                # UUID 生成
│           ├── WebUtils.as            # Web 工具
│           └── setFrameOut.as         # 延迟帧执行
└── [根目录嵌入资源 .as 文件]
    ├── *_png$*.as                     # 嵌入的 PNG 位图
    ├── *_swf$*.as / *ByteArray.as     # 嵌入的 SWF MovieClip 及其二进制数据
    ├── snd_*.as                       # 嵌入的声音文件
    └── script_NNN.as                  # 嵌入 MovieClip 的时间轴脚本
```

## 核心系统详解

### 1. 启动流程

```
launch() 构造函数
  → initlize()（addedToStage 事件触发）
    → ScreenRotater.init（屏幕旋转）
    → ScreenPadManager.initlize（屏幕触控初始化）
    → UIAssetUtil.I.initalize → buildGame()
      → MainGame.initlize()
        → ResUtils.initalize（加载 fighter.xml、assist.xml、select.xml、map.xml、mission.xml）
        → GameRender.initlize（注册 enterFrame 循环）
        → GameInputer.initlize（输入系统初始化）
        → GameData.I.loadData（读取存档）
        → GameData.I.config.applyConfig（应用配置）
        → GameLoadingState → loadGame（加载游戏资源）
        → EffectModel.I.initlize（效果初始化）
          → goLogo() → LogoState（进入 Logo 画面）
```

### 2. 游戏状态机

`MainGame` 拥有 `KyoStageCtrl` 实例来管理状态切换。每个状态实现 `Istage` 接口：

- `build()` — 进入状态时调用，初始化 UI 和逻辑
- `destory()` — 离开状态时调用，清理资源
- `afterBuild()` — build 完成后调用
- `display` — getter，返回该状态的 DisplayObject/Sprite

状态流转链：**Logo → Menu → SelectFighter → Loading → GameState → GameOver / Winner / Congratulate**

切换方法：`MainGame.I.goXxx()`。非战斗状态运行在 30fps，`GameState` 运行在 `GameConfig.FPS_GAME`（默认 60fps）。

KyoStageCtrl 还支持图层叠加（`addLayer`）和切换特效（`IStageFadEffect`，如 ZoomEffect）。

### 3. 渲染循环

`GameRender` 是一个静态回调注册表，注册的函数在 `stage.enterFrame` 时调用。函数按 key 分组管理。

- `GameRender.add(func, key)` — 注册
- `GameRender.remove(func, key)` — 移除

主渲染入口：`GameCtrl.render()`，在 `doStartGame()` 中注册。

**帧率管理**：

- `GameConfig.FPS_GAME` 控制游戏速度（默认 60）
- `GameConfig.SPEED_PLUS = 30 / FPS_GAME` — 帧归一化因子，所有移动速度乘以这个值
- 物理运算在 `FPS_GAME` 下运行，动画在 `FPS_ANIMATE`（30fps）下运行
- 通过 `_renderAnimateGap = ceil(FPS_GAME / 30) - 1` 控制动画更新频率

### 4. 角色系统（核心中的核心）

#### 实体继承体系

```
BaseGameSprite（实现 IGameSprite — 基础物理实体）
  ├── FighterMain     — 可控角色（HP、气、能量、状态）
  ├── Assister        — 辅助角色
  ├── Bullet          — 飞行道具
  └── FighterAttacker — 子攻击者（剑气、分身等附加攻击判定）
```

#### FighterMain 关键属性

| 属性                 | 类型              | 说明                                  |
| -------------------- | ----------------- | ------------------------------------- |
| `hp / hpMax`         | Number            | 生命值（默认 1000）                   |
| `qi / qiMax`         | Number            | 气量（上限 300），用于必杀技          |
| `energy / energyMax` | Number            | 体力（上限 100），用于瞬步/幽灵步     |
| `fzqi / fzqiMax`     | Number            | 辅助槽（上限 100），用于召唤辅助      |
| `speed`              | Number            | 移动速度                              |
| `jumpPower`          | Number            | 跳跃力度                              |
| `heavy`              | Number            | 重量（影响击飞距离）                  |
| `actionState`        | int               | 当前动作状态（见 FighterActionState） |
| `defenseType`        | int               | 防御类型（0=普通）                    |
| `airHitTimes`        | int               | 空中可攻击次数                        |
| `jumpTimes`          | int               | 可跳跃次数                            |
| `isSteelBody`        | Boolean           | 是否钢身状态                          |
| `isSuperSteelBody`   | Boolean           | 是否超级钢身                          |
| `direct`             | int               | 朝向（1=右，-1=左）                   |
| `isCross`            | Boolean           | 是否可穿越对手                        |
| `isAllowBeHit`       | Boolean           | 是否可被攻击                          |
| `targetTeams`        | Vector.\<TeamVO\> | 敌对队伍列表                          |

#### 动作状态常量（FighterActionState）

```
NORMAL = 0          普通/站立
ATTACK_ING = 10     正在普通攻击
SKILL_ING = 11      正在技能
BISHA_ING = 12      正在必杀
BISHA_SUPER_ING = 13 正在超必杀
JUMP_ING = 14        正在跳跃
DASH_ING = 15        正在瞬步
HURT_ACT_ING = 16    受身动作中
DEFENCE_ING = 20     正在防御
HURT_ING = 21        受击中
HURT_FLYING = 22     被击飞中
HURT_DOWN = 23       倒地中
HURT_DOWN_TAN = 24   弹地中
DEAD = 30            死亡
FREEZE = 40          冻结
WAN_KAI_ING = 50     万解中
KAI_CHANG = 60       开场中
WIN = 61             胜利
LOSE = 62            失败
```

**关键静态判断方法**：

- `isAttacking(state)` → state 在 [10, 11, 12, 13]
- `isHurting(state)` → state 在 [21, 22, 23, 24]
- `isBishaIng(state)` → state 在 [12, 13]
- `allowGhostStep(state)` → 非必杀且非万解

#### 控制器架构

```
FighterMain（角色实体）
  └── FighterCtrler（门面控制器）
        ├── FighterMcCtrler       — 动画和动作状态机（~2260 行，最复杂的类）
        ├── FighterHitModel       — 按帧定义的攻击判定数据
        ├── FighterEffectCtrl     — 角色专属视觉效果（发光、残影、震屏）
        ├── FighterVoiceCtrler    — 语音/音效控制
        └── IFighterActionCtrl    — 输入接口
              ├── FighterKeyCtrl  — 玩家键盘/手柄输入
              └── FighterAICtrl   — AI 输入
```

##### FighterMcCtrler — 动作系统（最核心的类）

管理角色所有可执行动作及其触发逻辑。通过 `FighterAction` 对象存储当前可用的动作（帧标签名），接收 `IFighterActionCtrl` 的输入信号来触发动作。

**动作映射机制**：

1. 每个动作（走、跳、攻击、技能、必杀…）在 `FighterAction` 中以字符串存储对应的 MovieClip 帧标签
2. 调用 `checkFrame(帧标签)` 验证 SWF 中是否存在该标签帧
3. `setAllAct()` 设置地面动作，`setAirAllAct()` 设置空中动作
4. `renderFloorAction()` 和 `renderAirAction()` 逐帧检查输入并触发对应动作

**默认帧标签名**（各角色 SWF 中按需定义）：

- **地面动作**：`走`、`防御`、`跳`、`落`、`瞬步`、`砍1`、`砍技1`、`砍技2`、`招1`、`招2`、`招3`、`摔1`、`摔2`、`必杀`、`上必杀`、`超必杀`、`万解`
- **空中动作**：`跳砍`、`跳招`、`空中必杀`
- **特殊动作**：`开场`、`胜利`、`失败`、`站立`、`落地`、`击飞`、`击飞_弹`、`击飞_倒`、`击飞_起`、`被打`、`防御恢复`

**动作状态优先级**（地面）：

```
catch → 超必杀 → 上必杀 → 必杀 → 技能2 → 技能1 → 招3 → 招2 → 攻击 → 招1
→ 防御 → 瞬步 → 移动 → 跳跃 → 下落
```

**幽灵步（Ghost Step）**：

- 通用机制，消耗 60 气 + 80 体力
- 三种类型：水平幽灵步、幽灵跳跃、幽灵下落
- 瞬移到对手身后，过程无敌

**受身/爆气系统**：

- `hurtBreak`：受击中满足条件可消耗 100 气 + 50 体力爆气脱身
- 死神方角色（comicType==1）使用 `replaceSkill`（替身术），其他角色使用 `energyExplode`（爆气）

### 5. 物理系统

`BaseGameSprite` 实现速度/阻尼模型：

```
render() → renderVelocity() → move()
  - 每帧应用速度到位置
  - 阻尼逐帧衰减速度（通过 KyoUtils.num_wake）
  - 重力（G=12, G_ADD=1.2）在空中时施加
  - 双速度层：_velocity/_damping（主层）和 _velocity2/_damping2（副层，用于击退）
  - KyoUtils.num_wake 将速度向 0 收敛
```

**关键物理常量**（GameConfig）：
| 常量 | 值 | 说明 |
|------|----|------|
| `G` | 12 | 重力加速度 |
| `G_ADD` | 1.2 | 重力递增量 |
| `G_ON_FLOOR` | 4 | 着地时初始重力 |
| `HURT_DAMPING_X` | 0.1 | 受击 X 轴阻尼 |
| `HURT_DAMPING_Y` | 0.5 | 受击 Y 轴阻尼 |
| `DEFENSE_DAMPING_X` | 1 | 防御 X 轴阻尼 |
| `HIT_DOWN_FRAME` | 15 | 普通倒地帧数 |
| `HIT_DOWN_FRAME_HEAVY` | 30 | 重击倒地帧数 |
| `JUMP_DELAY_FRAME` | 2 | 跳跃延迟帧 |

### 6. 碰撞检测系统

基于 MovieClip 帧的碰撞检测流程：

1. 角色 SWF 中包含子 MovieClip：`atm` 前缀（攻击标记，如 `atm1`、`atm_bs`）和 `bdmn`（身体标记）
2. `FighterHitModel` 将显示对象名映射到 `HitVO` 定义（攻击力、攻击类型、受伤类型等）
3. 每帧 `FighterMC.findHitArea()` 读取当前帧的攻击判定区
4. `GameMainLogicCtrler` 遍历攻击判定矩形，与对手身体区域做碰撞检测
5. 命中后调用：`beHit()` → `FighterMcCtrler.beHit()` → 分三种情况处理：
   - 防御中：`doDefenseHit()`（扣 5% 伤害 + 体力消耗）
   - 钢身中：`doSteelHurt()`（扣 65%/30% 伤害，不中断动作）
   - 普通受击：`doHurt()`（完整伤害 + 击退 + 受伤状态）

**HitVO 属性**：`id`、`owner`、`power`（伤害值）、`hitType`、`hurtType`（0=普通硬直, 1=击飞）、`hitx`、`hity`、`hurtTime`、`isBreakDef`（破防）、`checkDirect`（检查方向）、`currentArea`（当前判定矩形）

**必杀判断**：`isBisha()` 检查 id 是否包含 `bs`/`sbs`/`cbs`/`kbs`
**投技判断**：`isCatch()` = hitType==11（破防投技）且 isBreakDef

### 7. AI 系统

`FighterAICtrl` + `FighterAILogic` — AI 实现与键盘输入完全相同的 `IFighterActionCtrl` 接口。AI 难度由 `MessionModel.I.AI_LEVEL` 控制。

AI 在以下模式自动启用：

- 闯关模式（Arcade）敌方
- VS CPU 模式敌方
- 观战模式（Watch）双方
- 2v2 / 1v2 模式中的辅助角色

#### 7.1 AI 必杀决策与气量消耗流程

AI 释放必杀涉及**两套独立的气量检查机制**，分别在决策层和执行层：

```
决策层 (FighterAILogic.getBishaAI)
  └─ 检查 _fighter.qi >= param4（硬编码阈值: 普通必杀/上必杀/空中必杀=100, 超必杀=300）
  └─ 不参考 GameConfig.INFINITE_ENERGY
  └─ 通过概率判定 + targetCanBeHit + targetInRange → 返回 Boolean
        │
        ▼
执行层 (FighterMcCtrler.doBisha / doAirBisha)
  └─ 若 INFINITE_ENERGY=true → 跳过扣气，直接执行
  └─ 若 INFINITE_ENERGY=false → _fighter.useQi(_action.bishaQi)
  └─ _action.bishaQi 在 setBisha()/setBishaUP()/setBishaSUPER()/setBishaAIR() 中设定
       = GameConfig.INFINITE_ENERGY ? 0 : 默认消耗
  └─ 保护逻辑: 若 param2≤0 且非无限气，回退使用默认值（超必杀300/普通100/空中100）
```

**关键点**: 决策层阈值（hardcoded `param4`）与执行层消耗量（`_action.bishaQi`）是独立的两个值，在 `GameConfig.INFINITE_ENERGY` 切换时可能短暂不同步。

### 7.2 无限气系统 (INFINITE_ENERGY)

`GameConfig.INFINITE_ENERGY` (静态) 和 `ConfigVO.INFINITE_ENERGY` (实例) 双值控制。

**同步路径**:
| 操作 | ConfigVO | GameConfig | 同步方式 |
|------|:---:|:---:|------|
| 用户切换设置 | ✓ | ✓ | `setValueByKey("INFINITE_ENERGY", v)` |
| 加载存档 | ✓ | ✓ (修复后) | `readSaveObj()` 末尾同步 |
| applyConfig | ✓ | ✓ (修复后) | `applyConfig()` 末尾同步 |
| 静态初始化 | - | `false` | GameConfig 类加载 |

**影响范围**:
- `setBisha/setBishaUP/setBishaSUPER/setBishaAIR`: 控制 `_action.bishaQi` (0 或默认消耗)
- `doBisha/doAirBisha/doWaiKaiAction`: 跳过扣气 (true) 或正常消耗 (false)
- `getBishaAI` (修复后): 跳过 AI 气量检测 (true) 或正常检测 (false)

### 8. 输入系统

```
GameInputer（静态输入管理器，轮询模式）
  ├── GameKeyInput       — 键盘输入
  ├── GameJoystickInput  — 移动端摇杆
  ├── GameSocketInput    — LAN 网络输入
  └── ScreenPadInput     — 屏幕触控按钮
```

`FighterKeyCtrl` 从 `GameInputer` 读取输入，实现 `IFighterActionCtrl` 接口：

- `moveLEFT()`、`moveRIGHT()` — 方向移动
- `jump()`、`jumpQuick()`、`jumpDown()` — 跳跃相关
- `attack()`、`skill1()`、`skill2()` — 攻击技能
- `zhao1()`、`zhao2()`、`zhao3()` — 招式
- `catch1()`、`catch2()` — 投技
- `bisha()`、`bishaUP()`、`bishaSUPER()`、`bishaAIR()` — 必杀技
- `dash()` — 瞬步
- `defense()` — 防御
- `ghostStep()`、`ghostJump()` — 幽灵步
- `waiKai()`、`waiKaiW()`、`waiKaiS()` — 万解
- `assist()` — 召唤辅助

按键配置存储在 `GameData.I.config`（KeyConfigVO），支持经典模式和现代模式。

### 9. 游戏模式（GameMode）

```
组队模式：10=闯关, 11=VS人对战, 12=VS CPU, 13=观战
双人组队：14=2v2, 15=2v2观战
单人模式：20=闯关, 21=VS人对战, 22=VS CPU, 23=观战
一打二：  24=1v2, 25=1v2观战
特殊模式：30=生存模式, 40=训练模式
```

**模式判断方法**：

- `isTeamMode()` → mode 在 [10, 11, 12, 13]
- `isSingleMode()` → mode 在 [14, 15, 20-25]
- `isAcrade()` → mode 在 [10, 20, 30]
- `isVsCPU()` → mode 在 [12, 13, 14, 15, 22-25, 40]
- `isWatch()` → mode 在 [13, 15, 23, 25]
- `isVsPeople()` → mode 在 [11, 21]

### 10. 配置数据流

启动时加载的 XML 配置文件：

| 文件                        | 加载到                 | 内容                                       |
| --------------------------- | ---------------------- | ------------------------------------------ |
| `assets/config/fighter.xml` | FighterModel           | 角色定义（id、名称、SWF路径、头像、BGM等） |
| `assets/config/assist.xml`  | AssisterModel          | 辅助角色定义                               |
| `assets/config/select.xml`  | SelectCharListConfigVO | 选人界面配置                               |
| `assets/config/map.xml`     | MapModel               | 地图/场景定义                              |
| `assets/config/mission.xml` | MessionModel           | 闯关模式关卡数据                           |

加载链是串行的：fighter → assist → select → map → mission

另有 `assets/config/salect.xml`（注意拼写不同）用于组队模式的选人配置。

## 反编译特征识别

代码中存在典型的 AS3 反编译痕迹，修改时需注意：

- **参数名**：反编译器生成 `param1`、`param2`…（无意义）
- **局部变量**：使用 `_loc1_`、`_loc2_`…命名
- **switch 语句**：被转换为 if/else 链（用 `switch(param - 1)` + `case` 的形式是手修后的结果）
- **内联匿名函数**：大量 `function():void { ... }` 作为回调
- **文件名特殊字符**：`§` 表示 Flash 编译器特殊嵌入；`$` 分隔资源名和哈希值（`name$hash.as`）
- **ByteArray 后缀**：对应的二进制数据伴生文件
- **`script_NNN.as`**：根目录下的编号脚本，通常是嵌入 MovieClip 的时间轴代码

## 修改指南

### 常见需求对应文件

| 目标                  | 文件                                                                                           |
| --------------------- | ---------------------------------------------------------------------------------------------- |
| 调整游戏物理/平衡性   | `GameConfig.as`                                                                                |
| 增加/修改角色动作状态 | `FighterActionState.as`                                                                        |
| 修改角色行为/机制     | `FighterMcCtrler.as`（最核心）                                                                 |
| 修改 AI 行为          | `fighter/ctrler/ai/FighterAILogic.as` / `FighterAILogicBase.as`                                |
| 修改战斗 UI           | `ui/fight/*.as`                                                                                |
| 修改选人界面          | `ui/select/*.as`、`SelectFighterStage.as`                                                      |
| 新增游戏模式          | `GameMode.as`、`GameCtrl.as`                                                                   |
| 修改按键处理          | `FighterKeyCtrl.as`、`input/*.as`                                                              |
| 修改碰撞检测逻辑      | `GameMainLogicCtrler.as`                                                                       |
| 修改加载流程          | `GameLoader.as`、`MainGame.as`                                                                 |
| 修改场景/地图行为     | `MapMain.as`、`FloorVO.as`                                                                     |
| 修改特效              | `EffectCtrl.as`、`views/effects/*.as`                                                          |
| 修改角色数据模型      | `FighterVO.as`、`FighterModel.as`                                                              |
| 修改音效 BGM          | `SoundCtrl.as`                                                                                 |
| 启用/修改调试面板     | `Debugger.as`、`launch.as`（`DEBUG_PANEL_ENABLED`）                                            |
| 修改移动端触控        | `mob/screenpad/*.as`、`mob/input/*.as`                                                         |
| 修改网络对战          | `mob/sockets/*.as`、`mob/ctrls/LAN*.as`                                                        |
| 修改资源加载/内存管理 | `AssetLoader.as`、`AssetManager.as`、`GameLoader.as`、`BitmapAssetLoader.as`、`KyoURLoader.as` |
| 修改战斗状态清理      | `GameState.as`、`FighterMain.as`                                                               |

### 资源内存管理

**核心原则**：每局战斗结束后释放本局所有 Loader 和 MovieClip，避免多次对战后内存耗尽闪退。

- `GameState.destory()` — 战斗退出时调用 `GameLoader.dispose()` 释放本局所有角色/地图/辅助的 SWF Loader，`removeGameSprite()` 中对 FighterMain 额外调用 `disposeFighter()` 释放其 MovieClip
- `AssetLoader` — `_loaderPool` 按 URL 跟踪所有 Loader，`dispose(url)` 调用 `unloadAndStop(true)` 真正释放
- `GameLoader` — `dispose()` 遍历 `_loaderCache` 逐个 `unloadAndStop` 后重建空 Vector，`disposeFighter()` 对 FighterMain 的 MovieClip 做 `stop()` + `dispose()`
- `FighterMain.destory()` — 清理 `_mainMc.filters` 后调用 `_mainMc.dispose()` 释放角色 SWF 矢量内容
- `BitmapAssetLoader.dispose()` — 遍历 `_cacheObj` 对每个 BitmapData 调用 `.dispose()` 后清空
- `KyoURLoader` — `load()`/`post()` 回调中 `removeEventListener` 后再置 null
- **不清理的永久资源**：`loadBasic` 加载的字体、特效 SWF 类、preload 音效、主角头像/地图预览 — 这些全局复用

### 修改规范

**每次修改代码后必须：**

1. **同时更新两份副本**：
   - `BVNscripts/scripts/` — 直接将修改写入源文件
   - `Outscripts/scripts/` — 保持相同目录结构，复制一份到此处

2. **输出文件变更表**，格式如下：

   ```
   | # | 文件 | BVNscripts | Outscripts |
   |---|------|:---:|:---:|
   | 1 | path/to/File.as | ✓ | ✓ |
   ```

3. **修改 `CLAUDE.md`**：如果改动涉及架构、新增系统、或对已有的核心系统描述产生影响，必须同步更新本文档中的相关内容。

### 导出规则

如果可自动化则使用自动化修改BVNY中的launch否咋修改BVNscript的相关代码然后单独列出用于手动替换

自动化工具等仅作为指导不进行参与直接改动文件

修改后的脚本放在 `Outscripts/` 目录下，保持与 `BVNscripts/scripts/` 相同的目录结构。原始文件保留在 `BVNscripts/` 作为参照。

使用项目根目录的 `sync.py` 脚本将导出代码同步覆盖到源码目录：

```bash
python sync.py           # 交互式同步（逐文件确认 / 全部覆盖 / 取消）
python sync.py --check   # 非交互式检查（仅列出待同步文件）
```

交互模式三种选项：

- `y` — 逐文件确认
- `a` — 全部覆盖
- `n` — 取消

#### Claude Code Hooks 集成

`.claude/settings.json` 配置了 `PostToolUse` Hook：每次 `Write`/`Edit` 操作后自动运行 `sync.py --check`，提示当前待同步文件数量。用户可按需执行 `python sync.py` 完成合并。

### 角色 SWF 接口规范

每个角色/辅助的 SWF 文件必须：

1. 根 MovieClip 上定义 `setFighterCtrler(FighterCtrler)` 方法
2. 定义 `setEffectCtrler(FighterEffectCtrl)` 方法
3. 定义 `setFighterMcCtrler(FighterMcCtrler)` 方法
4. 包含与 `FighterAction` 中配置对应的帧标签
5. 子 MovieClip 命名规范：`atm` 前缀 = 攻击判定区，`bdmn` = 身体判定区
6. 包含 `AImain` 子 MovieClip，内含 AI 用的攻击范围参考图

### 地图 SWF 接口规范

1. 提供 `bgLayer`、`mapLayer`、`frontLayer`、`frontFixLayer` 属性（Sprite）
2. 定义 `playerBottom`、`left`、`right`、`bottom` 边界值
3. 定义 `p1pos`、`p2pos`（Point，角色出生位置）
4. 实现 `getFloorHitTest(x, y, range)` 方法，返回 `FloorVO`

### Flash/AS3 编译说明

- **目标平台**：Flash Player 11+（使用 `flash.display.MovieClip`、`flash.utils.Dictionary` 等 API）
- **原始编译方式**：Flash Professional / Flash Builder（无外部构建系统）
- **编译器**：`mxmlc`（Apache Flex SDK）或 Flash Professional IDE
- **嵌入资源**：`[Embed]` 元标签在编译时被处理为根目录的 `.as` 类文件
- **角色/地图资源**：作为独立的 SWF 文件在运行时通过 `GameLoader` 加载
- **AS3 方言**：使用 `Vector.<T>`、`for each`、默认参数值、包级函数
- **推荐反编译工具**：JPEXS Free Flash Decompiler (FFDec) — AS3/SWF 反编译的标准工具

## 调试系统

### 启用方式

`launch.as` 中 `DEBUG_PANEL_ENABLED` 常量控制调试模式开关：

```as3
private static const DEBUG_PANEL_ENABLED:Boolean = false;  // 改为 true 启用
```

启用后，`Debugger.initDebug(stage)` 在 `initBackHandler()` 中被调用，创建两个调试面板。

### 日志面板（原有）

- 位置：左上角 (10, 40)
- 尺寸：400 × (30 + 180) px
- 样式：深色半透明背景 (alpha=0.85)，灰色标题栏（"DEBUG LOG"），绿色/红色文本
- 功能：`Debugger.log(...)` 输出日志，支持拖拽移动
- 日志队列：最多 300 条，每 3 帧刷新一次
- 全局错误捕获：监听 `UncaughtErrorEvent`

### 性能监视器（新增 - Outscripts 版本）

- 位置：日志面板下方 (10, 255)
- 尺寸：200 × (22 + 120) px
- 样式：与日志面板相同风格（深色背景、灰色标题栏、绿色文字）
- 功能：
  - **FPS 显示**：当前/平均/最小/最大帧率，每 10 帧采样一次（参考博客 `getTimer()` 方案）
  - **内存显示**：`System.totalMemory`，自适应 B/KB/MB 单位
  - **FPS 走势图**：60×40 微型柱状图（绿色>80%, 黄色>50%, 红色<50%）
  - **内存走势图**：60×40 微型柱状图（蓝色），参考值 300MB
  - **游戏状态**：当前模式、双方角色 ID/HP/Qi/actionState/坐标/朝向
  - **版本信息**：游戏版本号和 stage.frameRate
  - **折叠按钮**：标题栏右侧红色按钮可折叠/展开面板内容
  - **拖拽移动**：支持标题栏拖拽调整位置
  - **可折叠面板**：点击红点按钮可收起/展开面板内容

### 使用方法

```as3
// 在 launch.as 中启用
private static const DEBUG_PANEL_ENABLED:Boolean = true;

// 代码中输出日志
Debugger.log("自定义日志信息");
Debugger.log("变量值:", someVar);

// 错误日志（红色显示）
Debugger.errorMsg("错误描述");
```

### 文件位置

| 文件                                                 | 说明                            |
| ---------------------------------------------------- | ------------------------------- |
| `BVNscripts/scripts/net/play5d/game/bvn/Debugger.as` | 原始调试器（仅日志面板）        |
| `Outscripts/scripts/net/play5d/game/bvn/Debugger.as` | 增强版（日志面板 + 性能监视器） |

## 版本信息

- **游戏版本**：V3.3（2019.3.32）
- **开发商**：5dplay（net.play5d）
- **原始发布平台**：Flash Web + Android/iOS 移动端，支持 LAN 局域网对战
- **第三方库**：GreenSock TweenLite（补间动画引擎）、自研 Kyo 框架
