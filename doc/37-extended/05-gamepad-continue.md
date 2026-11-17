# 手柄适配与局内重开（Continue）

一句话：3.7 参考的手柄走「IGameInput 四实现 + 全局轮询 + 设备层直读」三层，局内重开走「销毁整局重建」；主项目两侧都已另起炉灶。
源码基准：`BVNscripts/3.7扩展版参考/scripts/`（AS3 反编译产物 + 人工后处理，只读，不入提交）。
对照基准：`BVNscripts/scripts/` 主项目 3.3（现场读取，未改动任何文件）。

> **引用约定**：`路径:类.方法()`。不带前缀的路径相对 `BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/`；
> `M:` 前缀表示主项目，路径相对 `BVNscripts/scripts/net/play5d/game/bvn/`。行号一律不写死（反编译重编会漂）。

---

## 1. 一句话结论

**手柄**：3.7 的手柄是「设备层 `JoySticker` 直读 `GameInputControl.value` → 抽象层 `GameJoystickInput` 实现 `IGameInput` → 调度层 `GameInputer` 每帧轮询三个通道」的三层结构；键位表是 17 个 `JoyStickSetVO`，随 `ExtendConfig` 塞进 `ConfigVO.extend_config` 落到 `bvnsave.sav`。真正生效的切换路径只有两条（实例 `enabled` 与全局闸门），另两条是死代码。

**局内重开**：3.7 没有「原地重置」，它的 `LoadingState.restartBattle()` 是**把整局销毁再从 `LoadingState` 走一遍加载进 `GameState`**，所有状态靠「新对象」而非「复位字段」得到干净值；主项目走相反路线——`M:ctrl/game_ctrls/GameCtrl.as:GameCtrl.restartBattle()` 原地逐项复位，两条路线的代价完全不同。

**四个「Continue」不是一个东西**：`ContinueBtn`（回合结束的继续按钮）、`GameOverState.showContinue()`（街机败北续关扣分）、`VersusLoadingUI.showContinue()`（加载完按任意键）。本册的「局内重开」对应第二条的 YES 分支与暂停菜单的 RESTART BATTLE。

---

## 2. 领域术语

| 术语 | 本册含义 | 代码对应物 |
|---|---|---|
| 输入通道 | 三组逻辑输入源集合：`MENU` / `P1` / `P2`，用字符串键存在 `Dictionary` 里 | `input/GameInputer.as:GameInputer._inputMap` |
| 输入实现 | 实现 `IGameInput` 的具体源，共 4 个：键盘 / 虚拟摇杆 / 手柄 / 网络 | `input/GameKeyInput.as`、`mob/input/ScreenPadInput.as`、`mob/input/GameJoystickInput.as`、`mob/input/GameSocketInput.as` |
| 边沿三态 | `state=0` 按住 / `state=1` 单帧按下 / `state=2` 按下后带 0.1 秒保持窗 | `input/GameInputer.as:GameInputer.isDown()` 的第三参 |
| 设备层 | 直接包 `flash.ui.GameInput` 的静态类，管设备池、热插拔、阈值判定 | `mob/input/JoySticker.as:JoySticker` |
| 键位槽 | 一个「控件索引 + 方向」二元组，手柄按键的全部信息就这两个字段 | `mob/input/JoyStickSetVO.as:JoyStickSetVO`（`id:int`、`value:Number`） |
| 手柄配置 | 17 个键位槽 + 设备 id + 是否被玩家手动指定 | `mob/input/JoyStickConfigVO.as:JoyStickConfigVO` |
| 三份手柄配置 | 菜单 / P1 / P2 各一份，菜单那份是从 P1 拷贝出来的 | `mob/data/ExtendConfig.as:ExtendConfig.joyMenuConfig` / `joy1Config` / `joy2Config` |
| 改键 UI | 手柄改键页：选玩家 → 选设备 → Set All 逐键录制 | `mob/views/GamePadSetUI.as:GamePadSetUI` |
| 内嵌设置页 | 设置界面里叠开的一层子页面，靠事件 `APPLY_SET` / `CANCEL_SET` 退出 | `interfaces/IInnerSetUI.as` + `state/SettingState.as:SettingState.goInnerSetPage()` |
| 续关 | 街机模式败北后的 YES/NO 画面，YES 扣 10000 分再回选人 | `state/GameOverState.as:GameOverState.showContinue()` |
| 局内重开 | 把当前这一局重置到开局可操作状态 | 3.7：`state/LoadingState.as:LoadingState.restartBattle()`；主项目：`M:ctrl/game_ctrls/GameCtrl.as:GameCtrl.restartBattle()` |
| 快速重开标记 | 一个只活一次调用的静态开关，让新 `LoadingState` 跳过片头直接加载 | `state/LoadingState.as:LoadingState.QUICK_RESTART` |
| 局内重建 | 销毁 `GameState` 与 `GameCtrl` 全部子控制器，重新 `new` 一遍 | `state/GameState.as:GameState.destory()` + `ctrl/game_ctrls/GameCtrl.as:GameCtrl.destory()` |

---

## 3. 结构与数据流

### 3.1 手柄侧分层

| 层 | 类 | 职责 | 是否持有状态 |
|---|---|---|---|
| 契约层 | `input/IGameInput.as:IGameInput` | 20 条成员声明：14 个动作布尔查询 + `initlize` / `setConfig` / `focus` / `clear` + `enabled` 的 get/set | 否（纯接口） |
| 实现层 | `GameKeyInput` / `ScreenPadInput` / `GameJoystickInput` / `GameSocketInput` | 把某种物理输入翻译成 14 个动作的布尔值 | 是（各自缓存按键状态） |
| 设备层 | `mob/input/JoySticker.as:JoySticker` | 设备池 + 热插拔 + 阈值判定 + 改键录制 | 是（全静态字段） |
| 调度层 | `input/GameInputer.as:GameInputer` | 通道→实现列表，每帧轮询，做边沿 / 宽限 / 键位抢占 | 是（静态字段） |
| 装配层 | `mob/GameInterfaceManager.as:GameInterfaceManager.getGameInput()` | 决定每个通道由哪几个实现组成 | 否 |
| 单例池 | `mob/input/InputManager.as:InputManager` | 输入实现实例的唯一持有者 | 是 |
| UI 层 | `mob/views/GamePadSetUI.as`（+ `ui/GamePadArt.as` + `ui/OptList.as`） | 改键交互 | 是（临时配置副本） |

### 3.1.1 `InputManager` 的十个实例（3.7 七个 / 主项目十个）

| 实例 | 类型 | 3.7 | 主项目 | 说明 |
|---|---|---|---|---|
| `key_menu` | `GameKeyInput` | 无 | 有 | 主项目把键盘接进通道；3.7 的键盘实例只在死兜底里出现 |
| `key_p1` | `GameKeyInput` | 无 | 有 | 同上 |
| `key_p2` | `GameKeyInput` | 无 | 有 | 同上 |
| `screen_menu` | `ScreenPadInput` | 有 | 有 | 虚拟摇杆的菜单通道 |
| `screen_p1` | `ScreenPadInput` | 有 | 有 | 虚拟摇杆的 P1 通道 |
| `joy_menu` | `GameJoystickInput` | `GameJoystickInput(1)` | `GameJoystickInput(0)` | `player` 只用于日志；设备取自 `_config.deviceId` |
| `joy_p1` | `GameJoystickInput` | `GameJoystickInput(1)` | `GameJoystickInput(1)` | |
| `joy_p2` | `GameJoystickInput` | `GameJoystickInput(2)` | `GameJoystickInput(2)` | 构造参数只是 `player` 字段（仅日志用）。3.7 的 `updateInputConfig()` 无条件把 `joy_p2.enabled` 置 true；主项目改成由 `refreshJoystickRouting()` 决定（单手柄模型下永远禁 P2） |
| `socket_input_p1` | `GameSocketInput` | 有 | 有 | LAN 输入，默认 `enabled = false` |
| `socket_input_p2` | `GameSocketInput` | 有 | 有 | 同上 |

### 3.2 手柄侧数据流（文字箭头图）

```text
[物理手柄]
   │ flash.ui.GameInput 的 deviceAdded / deviceRemoved / deviceUnusable
   ▼
JoySticker.joystickHandler(event)
   ├─ deviceAdded   且 GameInput.numDevices < 3 → addDeivce(device)（device.enabled = true）
   │                → GameInterfaceManager.config.updateJoyConfig()   // 补 deviceId
   │                → GameInterfaceManager.updateInputConfig()        // 重灌 setConfig + 改 enabled
   │                → ScreenPadManager.setTouchEnabled(false)         // 藏虚拟摇杆
   ├─ deviceRemoved → removeDevice → updateInputConfig
   │                → _gameDeivces.length == 0 时 setTouchEnabled(true)
   └─ deviceUnusable→ 同 removed

[每帧] GameRender → GameInputer.render()
   ├─ 递减 _justDownDelayKeys（宽限窗）
   └─ renderListenKeys() → 对 _listenKeys 里登记的 (type, ids, justDown) 逐个 isDown(...) 预热

[业务查询] GameInputer.attack("P1", 1)
   └─ isDown("P1","attack",1)
        state=1 → isJustDown → call("P1","attack")
                    └─ call(): enabled? → _inputMap["P1"] 逐个实现
                         ├─ impl.enabled?   （实例级闸门）
                         └─ impl["attack"]()  → true 就短路返回

[手柄实现] GameJoystickInput.attack()
   └─ JoySticker.isDown(_config.deviceId, _config.attack)
        └─ _deivceMap[deviceId] → device.getControlAt(setVO.id).value
             按 setVO.value 的符号 → 与 ±0.5 比较 → Boolean
```

### 3.3 改键页数据流

```text
ViewManager.I.goGamePadSet()
   └─ 要求 MainGame.stageCtrl.currentStage is SettingState，否则直接 return
      └─ goGamePadSetInner(1, GameInterfaceManager.config.joy1Config)
           └─ SettingState.goInnerSetPage(new GamePadSetUI())
                ├─ GamePadSetUI.setConfig(1, joy1Config)
                │    └─ _tmpJoy1Config.readObj(joy1Config.toObj())   // 深拷到临时副本
                └─ OptionsScreen.showPage(ui)  → _pageOpen = true（外层导航全部静默）

[玩家操作] OptList.onChange / onActivate
   ├─ "player"    → _currentPlayer 切换 → refreshList()
   ├─ "deviceId"  → currentTmpConfig.deviceId = 选中值；把对方从同一设备踹下来
   ├─ "switch"    → 1↔2 互换编辑目标
   ├─ "setall"    → _setIndex = -1 → setNextKey() → GameRender.add(renderSet) 逐键录制
   ├─ "setdefault"→ new JoyStickConfigVO() + deviceId = JoySticker.getDeviceId(player-1)
   ├─ "apply"     → _p1JoyConfig.readObj(_tmpJoy1Config.toObj())
   │                → GameInterfaceManager.config.updateJoyConfig()
   │                → dispatchEvent("APPLY_SET")（SettingState 只负责销毁本页）
   │                → GameInterfaceManager.updateInputConfig()
   └─ "cancel" / onBack → dispatchEvent("CANCEL_SET")（_tmp 被丢弃即回滚）

[落盘] 只有离开整个设置界面时才发生：
SettingState.applyAndExit()  ← 由 OptionsScreen.onBack 与 "apply" 行触发
   └─ GameData.I.saveData()
        └─ GameInterfaceManager.saveGame(obj) → JSON.stringify → bvnsave.sav
```

### 3.4 局内重开（3.7 重建式）数据流

```text
[触发] PauseDialog.menuSelectHandler("RESTART BATTLE") / GameEndCtrl（胜利界面 ui.onMore）
   └─ GameUI.confrim(...) 确认
      └─ LoadingState.restartBattle()
           ├─ SoundCtrl.I.resetBGM()
           ├─ GameInputer.enabled = false
           └─ StateCtrl.I.transIn(cb, false)     // 黑场转场
                QUICK_RESTART = true             // 打标记
                try   { MainGame.I.loadGame() }  // 内部同步构造新 LoadingState
                finally{ QUICK_RESTART = false } // 标记立刻撤回

MainGame.loadGame()
   └─ stageCtrl.goStage(new LoadingState(), sameChange = true)
        ├─ new LoadingState() → _quick = QUICK_RESTART；QUICK_RESTART = false（消费掉）
        ├─ _curStage.destory()（同步：buildAfterDestory = false）
        │    └─ GameState.destory() → GameCtrl.destory()
        │         ├─ GameRender.remove(render)；GameLogic.clear()
        │         ├─ GameInputer.clearInput()
        │         ├─ FighterEventCtrl / GameMainLogicCtrler / TrainingCtrler
        │         │  / GameStartCtrl / GameEndCtrl / MosouCtrl 全部 destory()
        │         ├─ gameRunData.p1FighterGroup.destory() / p2... / gameRunData.clear()
        │         └─ GameLoader.dispose()；_gameRunning = false
        └─ newStage(): build() + addChild + afterBuild()
             └─ afterBuild(): _quick 为真 → setTimeout(startQuickRestart, RESTART_HOLD_MS)

startQuickRestart()
   └─ RESTART_SKIP_LOAD ? finish() : startLoad()
        └─ GameStageLoadCtrl.I.loadGame(地图, 人物, 辅助, 全量, onLoadFinish)

finish()
   ├─ if(!AUTO_START_GAME && !_quick) return;   // _quick 跳过"等你按开始"
   ├─ ensureOrder()；按 order 长度把 fighter2 / fighter3 置 null
   └─ gotoGame(p1Order, p2Order)
        ├─ 重新 FighterModel.getFighter(id,true) 填 p1/p2 的 fighter1..3
        ├─ AssisterModel.getAssister(...) 重新取辅助
        ├─ gameRunData.map = MapModel.getMap(GameData.I.selectMap)
        └─ StateCtrl.I.transIn(MainGame.I.goGame, false)

MainGame.goGame()
   ├─ new GameState() → goStage → GameState.build()
   │    ├─ GameCtrl.I.initlize(this)   // _isPauseGame=false, _isRenderGame=true, _gameRunning=true
   │    ├─ EffectCtrl.I.initlize(this,_playerLayer)
   │    └─ ShadowCtrl.init(_shadowLayer)
   └─ GameCtrl.I.startGame() → doStartGame()
        ├─ _isPauseGame = false；GameInputer.enabled = true
        ├─ EffectCtrl.I.clearCinematicAll()
        ├─ gameRunData.reset()          // 见 4.6 的逐项表
        ├─ resetTagRuntime()；initTeam()；buildGame()
        └─ dispatchEvent("GAME_START")；GameRender.add(render)
```

### 3.5 局内重开（主项目原地重置式）数据流

```text
[触发] M:ui/PauseDialog.as:PauseDialog.showRestartConfirm()
       → GameCtrl.I.pause(true) → GameUI.confrim("CHARACTER RESET", ...)
   └─ confirmRestartYes() → GameCtrl.I.restartBattle()
        ├─ 门：isResetting / _gameRunning / gameState 任一为假则直接 return
        ├─ isResetting = true；_isPauseGame = true；_isRenderGame = false
        ├─ 快照 p1Wins / p2Wins
        ├─ clearDynamicSprites()      // 只留 FighterMain 与 Assister
        ├─ EffectCtrl.I.clearAll()；FilterProxyManager.I.invalidateAll()（try 包裹）
        ├─ GameLogic.clearAllHits()
        ├─ gameRunData 的计时 / 胜负 / continueLoser / fightFinished 复位
        ├─ gameState.resetFight(p1Group, p2Group)   // 位置 / 朝向 / idle / HP / UI / 相机焦点
        ├─ GameUI.I.getUI().hideHits(1/2) + clearStartAndEnd()
        ├─ resetAllFighterCtrls()     // 气 / 能量 / 辅助槽 / 钢体 / 受击缓存 / 输入控制器 / Buff
        ├─ 回填 p1Wins / p2Wins
        ├─ TrainingCtrler.SAY_INTRO 为假且练习模式 → actionEnable = true
        │  否则 new GameStartCtrl(...).startNextRound()；actionEnable = false
        ├─ dispatchEvent("ROUND_START")；GameInputer.clearInput()
        └─ isResetting = false；resume(true)     // 内部 _isRenderGame = true
```

---

## 4. 关键机制逐条拆解

### 4.1 `IGameInput` 契约：20 条声明、14 个动作、边沿不在接口里

**结论**：`IGameInput` 一共 20 条成员声明——14 个无参布尔动作（`anyKey` / `back` / `select` / `up` / `down` / `left` / `right` / `attack` / `jump` / `dash` / `skill` / `superSkill` / `special` / `wankai`）+ `initlize(Stage)` + `setConfig(Object)` + `enabled` 的 get/set + `focus()` + `clear()`。**接口层不表达「按下 / 持续 / 抬起」三态**，它只回答一个问题：「这一帧这个动作是否按住」。

**代码引用**：`input/IGameInput.as:IGameInput`。

**边沿三态在哪**：在 `input/GameInputer.as:GameInputer.isDown(type, action, state, skipListen)` 的第三参：

| `state` | 走哪条分支 | 语义 | 实现依据 |
|---|---|---|---|
| 0（默认） | `call(type, action)` | 按住就一直 true | 直接问实现 |
| 1 | `isJustDown(type, action)` | 只在 false→true 的那一帧 true | `_justDownKeys[key]` 锁存 |
| 2 | `isJustDownDelay(type, action, x)` | 按下后额外保持 `0.1 × MainGame.I.getFPS()` 帧 | `_justDownDelayKeys[key]` 计数，`render()` 每帧递减 |

**「抬起」没有专门查询**：`isJustDown` 在实现返回 false 时把锁存写回 `_justDownKeys[key] = false`，所以「抬起」只能由调用方自己保存上一帧的查询结果推出。3.7 整棵树里没有 `getKeyUp()` 一类方法。

**为什么这么做**：

1. 因为 `GameInputer` 是**每帧轮询**而不是事件派发，同一帧内 `attack()` 会被 `FighterKeyCtrl` 的十几个判定分支反复调用。若边沿逻辑放实现层、每次查询各自记账，同一次按键会被判成多次「刚按下」。锁存必须放在唯一的查询入口上，所以三态做成 `isDown` 的参数。
2. `state=2` 的存在是因为出招判定分散在多条链路里，某条链路晚几帧才轮到查询；0.1 秒窗口把这次按键「续命」到那几帧之后。
3. `listenKeys()` 是为 `state=2` 服务的预热点：它把 `(type, ids, justDown)` 存进 `_listenKeys`，`render()` 每帧调 `renderListenKeys()` 对这些 id 主动查询一次，把 `_justDownDelayKeys` 提前点亮。`fighter/ctrler/FighterKeyCtrl.as:FighterKeyCtrl.initlize()` 就是给 `attack` / `jump` / `dash` / `skill` / `superSkill` 登记 `justDown=2`，`destory()` 里 `unListenKeys` 撤销。注意 `listenKeys` 对 `justDown` 只接受 1 与 2，其它值直接 `return`。

**实现侧的不变量**：每个动作方法都必须返回「当前帧是否按住」，并且要在方法内自己判 `_enabled`（`GameJoystickInput` 每个方法第一行都是 `if(!_enabled) return false;`）。`GameKeyInput` 反而不判，靠 `GameInputer.call()` 的实例级闸门兜住。

**14 个动作在两套实现里的取值来源**（字段名照抄源码，含三处命名不一致）：

| 动作方法 | `GameKeyInput` 读什么 | `GameJoystickInput` 读什么 | 命名坑 |
|---|---|---|---|
| `anyKey()` | 遍历 `_downKeys` 找任何一个值为 1 | `JoySticker.isDownAnyKey(deviceId)` | — |
| `back()` | 硬编码 `isDown(27)`（ESC） | `_config.back` | 键盘的 BACK 不可改键 |
| `select()` | 遍历 `_config.selects`（`Array`） | 3.7：`_config.jump`；主项目：`_config.select` | 同一方法两棵树读不同字段 |
| `up()` / `down()` / `left()` / `right()` | `_config.up` / `down` / `left` / `right`（`uint` 键码） | `_config.up` 或 `_config.up2`（两个槽位任一命中即可） | 手柄方向键有 D-Pad 与摇杆两组 |
| `attack()` / `jump()` / `dash()` / `skill()` | `_config.attack` / `jump` / `dash` / `skill` | 同名字段 | — |
| `superSkill()` | `_config.superKill` | `_config.superSkill` | **键盘字段是 `superKill`，手柄字段是 `superSkill`** |
| `special()` | `_config.beckons` | `_config.special` | **键盘字段是 `beckons`，手柄字段是 `special`** |
| `wankai()` | `isDown(_config.attack) && isDown(_config.jump)`（组合键） | `_config.waikai` | **方法名 `wankai` 与字段名 `waikai` 差一个字母**；键盘侧没有独立键位 |
| `clear()` | `_downKeys = {}` | 空实现 | 见 §5.1 |

这张表解释一个常见误会：**键盘侧的 `wankai()` 是「攻击+跳跃同按」，手柄侧是独立键**。所以给手柄单独做改键时，`waikai` 槽位的存在与键盘的键位表无关；反过来，只改 `KeyConfigVO` 也不会影响手柄的任何动作。

### 4.2 `GameInputer` 全局路由：装配一次、切换五条路、两条是死代码

**结论**：通道只有三个字符串键（`MENU` / `P1` / `P2`），装配只发生在 `initInput()` 一次；运行时的「切换」实际是**改 `enabled` 与重灌 `setConfig`**，不是换实现对象。

**代码引用与通道组成**：

| 通道 | 3.7 组成（`mob/GameInterfaceManager.as:GameInterfaceManager.getGameInput()`） | 主项目组成（`M:mob/GameInterfaceManager.as:GameInterfaceManager.getGameInput()`） |
|---|---|---|
| `MENU` | `screen_menu` + `joy_menu` | `key_menu` + `screen_menu` + `joy_menu` |
| `P1` | `screen_p1` + `joy_p1` + `socket_input_p1` | `key_p1` + `screen_p1` + `joy_p1` + `socket_input_p1` |
| `P2` | `joy_p2` + `socket_input_p2` | `key_p2` + `joy_p2` + `socket_input_p2` |

**四条切换路径 + 一条闸门，逐条判定**：

| # | 路径 | 入口 | 是否生效 |
|---|---|---|---|
| 1 | 装配 | `GameInputer.initInput()` → `getGameInput()` → `setInput()` | 生效（只在 `initlize()` 里跑一次） |
| 2 | `enabled` 重配 | `GameInterfaceManager.updateInputConfig()`：给 3 个 joy 实例 `setConfig` + 改 `enabled`，并关掉两个 socket | 生效。触发者：`JoySticker.joystickHandler()`、`GamePadSetUI` 的 Apply 行、`SettingState.applyAndExit()`（经 `GameInputer.updateConfig()`）、`LANServerCtrl` / `LANClientCtrl` |
| 3 | 键位配置 | `GameInputer.updateConfig()`：`if(GameInterface.instance.updateInputConfig()) return;` 之后的三个 `setConfig(...key_menu / key_p1 / key_p2)` | **死路径**。`GameInterfaceManager.updateInputConfig()` 无条件 `return true`，这三行在 3.7 永不执行 |
| 4 | 焦点路由 | `mob/input/GameInputRouter.as:GameInputRouter.applyFocus()` + `mob/input/GameInputFocus.as:GameInputFocus` | **死代码**。整棵树对这两者的引用只有这两个文件自身 |
| 5 | 全局闸门 | `public static var enabled:Boolean`，`call()` 第一道判据 | 生效。各 State 频繁开关（`LoadingState` / `MenuState` / `SelectFighterStage` / `WinnerState` / `GameCtrl` / `GameEndCtrl`） |

**键实际是硬编码字符串**：`input/GameInputType.as:GameInputType` 声明了 `MENU` / `P1` / `P2` 三个 `String` 常量，但整棵树对它的引用只有它自己的构造函数。`_inputMap` 的键是字面量。

**为什么这么做**：

1. 因为「一个玩家可以同时有多种输入源」（手指、手柄、网络），通道里放的是 `Vector.<IGameInput>` 而不是单个实例；`call()` 顺序遍历、命中即 `break`，所以列表顺序就是优先级（`screen` 在手柄之前 = 触屏优先命中）。
2. 因为装配依赖 `GameInterface.instance`（平台注入点），`initInput()` 写了 `getGameInput()` 返回 null 时的兜底：`new Vector.<IGameInput>([new GameKeyInput(), new GameJoystickInput(1), new GameJoystickInput(2)])`。但 3.7 的移动端入口 `launchWUFAN.as:initGame()` 在 `MainGame.initlize()` 之前就 `GameInterface.instance = new GameInterfaceManager()`，所以兜底不执行——**`GameKeyInput` 在 3.7 移动端是死实例**（`new GameKeyInput` 全树只出现在这三行兜底里）。主项目把 `key_menu` / `key_p1` / `key_p2` 直接塞进 `InputManager` 并接进通道，键盘才真的通。

**`callVoid()` 也查 `enabled`**：`initlize(stage)` / `focus()` / `clear()` 都走 `callVoid()`，而它同样有实例级 `enabled` 判据。因此「启动时被 disable 的实现，其 `initlize` 会被静默跳过」——`JoySticker.initlize()` 就是在 `GameJoystickInput.initlize()` 里调用的，一旦在 `GameInputer.initlize()` 之前有代码把某个 joy 实例关掉，设备层就永远不会初始化。

### 4.3 手柄设备层 `JoySticker`：包装 `flash.ui.GameInput`、两套阈值、静态录制键

**结论**：`JoySticker` 是纯静态类，持有「设备 Vector + id→设备 map + 一个录制用槽位」，向上暴露 `isDown(deviceId, setVO)`、`isDownAnyKey(deviceId)`、`getDownKey(deviceId, consume)`、`getAllDeivces()`、`getDeviceId(index)`、`isActive(deviceId)`、`hasController()`。

**初始化与平台能力判定**：`mob/input/JoySticker.as:JoySticker.initlize()` 先过 `_inited` 幂等门，再 `if(!GameInput.isSupported) { trace("该平台不支持手柄！"); return; }`——**注意它是在给 `_gameDeivces` / `_deivceMap` 赋值之前 return 的**，两个字段保持 null。通过判定后才 `_inited = true`、建 Vector 与 map、`new GameInput()` 并挂三个事件。

**热插拔**：见 §3.2 箭头图。要点三条：

1. `deviceAdded` 有 `GameInput.numDevices < 3` 的容量上限，即最多接 2 个手柄（`numDevices` 含本次新增的那个）。
2. 新增设备会顺带 `ScreenPadManager.setTouchEnabled(false)`（有手柄就藏虚拟摇杆），最后一个设备移除 / 失效时 `setTouchEnabled(true)` 恢复。
3. `deviceUnusable` 与 `deviceRemoved` 走完全相同的清理，区别只在 trace 文本。

**死区与轴归一化：两套阈值并存，且不是同一套**：

| 函数 | 判据 | 用途 |
|---|---|---|
| `JoySticker.checkDownValue(device, index)` | 绝对值 < `DEAD_ZONE`(0.35) → 0；`v >= DIGITAL_THRESHOLD`(0.75) → +1；`v <= -ANALOG_THRESHOLD`(0.6) → −1；其余 → 0 | `isDownAnyKey()`、`getDownKey()`（任意键与改键录制） |
| `JoySticker.isDown(deviceId, setVO)` | 按 `setVO.value` 符号：正 → `control.value > 0.5`；负 → `control.value < -0.5`；0 → false | 游戏动作查询的全部路径（`GameJoystickInput` 的 14 个方法） |

三个常量 `DEAD_ZONE = 0.35`、`DIGITAL_THRESHOLD = 0.75`、`ANALOG_THRESHOLD = 0.6` **只被 `checkDownValue` 使用**，`isDown` 里一个都没用。正负阈值不对称（+0.75 / −0.6）。

**没有归一化代码**：`GameInputControl.value` 由运行时给出 [-1, 1] 区间值，`JoyStickSetVO.value` 只存 ±1 或 ±0.5 的方向选择子，代码只做阈值比较，不做缩放。

**映射表存哪**：`mob/input/JoyStickConfigVO.as:JoyStickConfigVO`——`deviceId:String`、`deviceIsSet:Boolean`，加 17 个 `JoyStickSetVO` 字段（`up2` / `down2` / `left2` / `right2` / `up` / `down` / `left` / `right` / `attack` / `jump` / `dash` / `skill` / `superSkill` / `special` / `waikai` / `back` / `select`）。字段初始值就是默认键位表：

| 语义 | 默认 `id` | 默认 `value` | 源码给出的判定方式 | 常见 Xbox 布局下的物理含义（未实测，见 §7） |
|---|---|---|---|---|
| `up` / `down` / `left` / `right` | 16 / 17 / 18 / 19 | +1 | `control.value > 0.5` | D-Pad 四向 |
| `up2` | 1 | +0.5 | `control.value > 0.5` | 左摇杆 Y 轴正方向 |
| `down2` | 1 | −0.5 | `control.value < -0.5` | 同一轴反方向 |
| `left2` | 0 | −0.5 | `control.value < -0.5` | 左摇杆 X 轴负方向 |
| `right2` | 0 | +0.5 | `control.value > 0.5` | 同一轴正方向 |
| `attack` / `jump` / `dash` | 6 / 4 / 5 | +1 | `control.value > 0.5` | 按键 |
| `skill` / `special` / `superSkill` | 7 / 8 / 9 | +1 | `control.value > 0.5` | 按键 |
| `waikai` | 10 | +1 | `control.value > 0.5` | 按键（字段名与 `wankai()` 差一个字母，见 §5） |
| `back` / `select` | 12 / 13 | +1 | `control.value > 0.5` | 按键（3.7 只读 `back`，见下） |

这些数字是**硬编码的控件索引**：源码里没有任何「名字 → 物理键」的映射表，`JoyStickConfigVO` 只存 `id` 与方向。同一索引在不同手柄上不保证是同一物理键——所以才有改键界面，也所以默认表能不能直接玩必须实测（§7）。

**3.7 的 `select()` 读的是 `jump`**：`mob/input/GameJoystickInput.as:GameJoystickInput.select()` 返回 `JoySticker.isDown(_config.deviceId, _config.jump)`，`back()` 只读 `_config.back`。**`_config.select`（默认 13）在 3.7 整棵树里没有被任何动作方法读取**，所以改键页那行 SELECT 改了不生效。主项目反过来：`select()` 读 `_config.select`，`back()` 读 `back || select`。

**录制键 `_downKey` 是静态字段**：`getDownKey(deviceId, consume)` 用它实现「同一控件同一方向不要连帧重复返回」；`consume=true` 时同一个键第二次进入直接返回 null。因为它是静态的，跨实例共享。

**为什么这么做**：

1. 设备池与 map 双份存储，是因为「按索引取」和「按 id 取」两种使用方式同时存在：改键页按索引列设备（`getAllDeivces()`），游戏按 id 读值（`isDown()`）。
2. `isDown` 里先 `if(param2.id > device.numControls) return false;` 再 `getControlAt(param2.id)`——边界写成 `>` 而不是 `>=`，越界值靠 `getControlAt` 返回 null 兜住（下一行有 `if(!_loc3_) return false;`）。`checkDownValue` 里写的是正确的 `>=`。
3. 两套阈值并存是历史叠加：`checkDownValue` 那套带死区，为「任意键」与「录制」服务；`isDown` 那套 ±0.5 为游戏手感服务。`setVO.value` 只表达方向，所以 `isDown` 拿不到模拟量大小。

### 4.4 改键 UI `GamePadSetUI`：临时副本 + 抢占式冲突 + 无按键级冲突检测

**结论**：改键页一律操作 `_tmpJoy1Config` / `_tmpJoy2Config` 两个**临时副本**，Apply 才写回 `GameInterfaceManager.config`；冲突处理只到「设备排他」这一层，按键层面只做了「同一个键不要连帧重复写入下一个映射」。

**交互流程（7 行列表）**：

| 行 | `type` | `key` / `id` | 行为 |
|---|---|---|---|
| Target Player | choice | `key = "player"` | 切 `_currentPlayer`，`refreshList()` |
| Gamepad Name | choice | `key = "deviceId"` | 选项 = `None (Screenpad)` + `JoySticker.getAllDeivces()` 逐个 `dev.name`（`subString(name, 15)` 截断） |
| Switch P1/P2 | action | `id = "switch"` | 1↔2 |
| Set All | action | `id = "setall"` | 进入逐键录制 |
| Set Default | action | `id = "setdefault"` | 重置为默认表 |
| Apply | action | `id = "apply"` | 写回 + 通知重装输入 |
| Cancel | action | `id = "cancel"` | 丢弃临时副本 |

**录制状态机（Set All）**：

```text
_setIndex = -1
_list.enabled = false          // 外层导航全静默
GameRender.add(renderSet)

renderSet() 每帧：
  waitRelease()                      // 门 1：必须先把所有键松开（_startSet 由 false 变 true）
  getTimer() - _lastMapTime < 400    // 门 2：每个键之间 400ms 冷却
  waitNextKey()
     └─ JoySticker.getDownKey(deviceId, true)
          ├─ null（没键按下）       → _lastKey = null（重置防抖记忆）
          └─ 非 null → isDuplicateKey(key)
                ├─ 与 _lastKey 相同 → 返回 null（同一个键按住不重复取）
                └─ 不同             → 返回该 key
  saveCurrentKey(key)   → currentTmpConfig[MAPPINGS[_setIndex].id] = key
  setNextKey()          → nextMapping(): ++_setIndex → MAPPINGS[_setIndex]
        └─ 越界 → finishMapping()：关 dialog、_pad.highlight(null)、_list.enabled = true、
                   GameRender.remove(renderSet)
```

**冲突检测**：

| 层面 | 函数 | 做什么 | 不做什么 |
|---|---|---|---|
| 设备 | `onRowChange("deviceId")`、`onActivate("setall" / "setdefault")` | 把被抢的一方 `deviceId = null`、`deviceIsSet = true`（强制降级成屏幕按键） | 不报错、不提示、不阻止 |
| 按键 | `isDuplicateKey(key)` | 只比 `_lastKey`（`id + "_" + value`），防「按住不放时连帧重复写入下一个映射」 | **没有**「这个控件已经绑给 ATTACK 了」这类跨字段冲突检测；同一个控件可以同时绑 `attack` 与 `jump` |

**重置**：`setdefault` 分支 `new JoyStickConfigVO()`（回到字段初始值表，等于 §4.3 的默认键位表）+ `deviceId = JoySticker.getDeviceId(_currentPlayer - 1)` + `deviceIsSet = true`，顺带把另一方从同设备上踹下来。

**保存**：**`GamePadSetUI` 自己不落盘**。`apply` 只做三件事：写回 `GameInterfaceManager.config`、`dispatchEvent(new SetBtnEvent("APPLY_SET"))`、`GameInterfaceManager.updateInputConfig()`。真正写盘发生在 `state/SettingState.as:SettingState.applyAndExit()` → `GameData.I.saveData()`（见 §4.5）。

**退出**：`onBackKey()` 与 `cancel` 都 `dispatchEvent(new SetBtnEvent("CANCEL_SET"))`；`SettingState.innerSetHandler()` 收到任一事件都只做 `destoryInnerSetUI()`，**不做脏数据回滚**——脏数据根本不存在，因为改动都在 `_tmp*` 里。

**为什么这么做**：

1. 副本 + Apply 是为了让 CANCEL 成立：`setConfig()` 用 `readObj(other.toObj())` 做深拷，丢弃副本即回滚。
2. 设备冲突用「踹」不用「拒绝」，是因为一个手柄不能同时被两方用；把对方降级成屏幕按键比弹窗更容易收场，代价是玩家的配置被静默改写。
3. 录制期 `_list.enabled = false` 让 `ui/OptList.as:OptList.renderInner()` 的 `if(!_enabled || now < _lockUntil) return;` 直接短路——连带 `GameInputer.back(1)` 那一行也不会执行。**录制期间没有 BACK 出口**，唯一结束方式是 17 个键全部录完（见 §5.4 第 5 条）。
4. 400ms 冷却与「先松手」两道门，是因为手柄的 D-Pad 与摇杆常在按下一个键时同时越过阈值，不加门会一次按下录进两三个映射。

### 4.5 存档同步：`ExtendConfig` 的字段与写盘时机

**结论**：手柄配置存在 `ExtendConfig` 里，序列化为 `ConfigVO.extend_config`，整包 `JSON.stringify` 写进 `File.applicationStorageDirectory/bvnsave.sav`。**写盘只发生在设置界面退出 / 应用时**，战斗与重开过程不写盘。

**字段**：

| 字段 | 类型 | 落盘键 | 说明 |
|---|---|---|---|
| `joyMenuConfig` | `JoyStickConfigVO` | `joy_menu` | 菜单用，`updateJoyConfig()` 从 `joy1Config` 拷贝 |
| `joy1Config` | `JoyStickConfigVO` | `joy_p1` | P1 |
| `joy2Config` | `JoyStickConfigVO` | `joy_p2` | P2（3.7 有独立 VO，但路由上 `joy_p2` 与 `joy_p1` 同为 `GameJoystickInput(1)`，见 §5.4） |
| `screenMode` | `int` | `screenMode` | 屏幕缩放模式，`SettingState.readConfig("screenMode")` 特判走 `extendConfig` |
| `screenPadConfig` | `ScreenPadConfigVO` | `screenPadConfig` | 虚拟摇杆布局 |

**写盘链路**：

```text
SettingState.applyAndExit()            // OptionsScreen.onBack 与 "apply" 行都走这里
  └─ GameData.I.saveData()  (data/GameData.as:GameData.saveData)
       obj = { id:"bvn3.5A", config: config.toSaveObj(), mosou: mosouData.toSaveObj() }
       └─ GameInterface.instance.saveGame(obj)
            └─ mob/GameInterfaceManager.as:GameInterfaceManager.saveGame()
                 JSON.stringify(obj) → File.applicationStorageDirectory/bvnsave.sav
                 → FileUtils.writeFile(nativePath, text)
```

`ConfigVO.toSaveObj()` 里手柄那一段是 `if(extendConfig) _loc1_.extend_config = extendConfig.toSaveObj();`。

**读盘链路**：`GameData.initData()` → `loadSaveData()`（校验 `id != "bvn3.5A"` 即丢弃）→ `config.readSaveObj(obj.config)` → `extendConfig.readSaveObj(param1.extend_config)` → 末尾 `updateJoyConfig()`。

**`updateJoyConfig()` 做两件事**：`initDefaultDevices()`（一次性守卫 `_isInitDefaultJoystick`，随后 `setDefaultDevice(joy1Config, 0)` / `setDefaultDevice(joy2Config, 1)`）+ 把 `joy1Config` 的 `deviceId` / `deviceIsSet` 与 10 个键位（`up2` / `down2` / `left2` / `right2` / `up` / `down` / `left` / `right` / `jump` / `back`）逐个 `readObj(...toObj())` 拷到 `joyMenuConfig`。

**`saveData()` 的触发点**（全树 grep 结果）：

| 触发点 | 场景 |
|---|---|
| `state/SettingState.as:SettingState.applyAndExit()` | 设置界面 Back / APPLY |
| `mob/views/SetViewBase.as:SetViewBase.onBtnSelect()` 的 APPLY 分支 | 另一套设置页基类（虚拟摇杆等） |
| `ctrl/mosou_ctrls/MosouLogic.as`（两处） | 无双模式进度 |
| `ui/dialog/MosouStateDialog.as` / `ui/dialog/MosouSelectDialog.as` | 无双存档对话框 |

**为什么这么做**：

1. 手柄配置挂在 `ConfigVO` 的 `extend_config` 上，而不是独立文件，是为了让「一次 APPLY = 一次完整落盘」，避免设置项之间出现半保存状态。
2. 一次性守卫 `_isInitDefaultJoystick` 的意图是「只补一次默认 deviceId，别覆盖玩家手动指定的」。但它在**读档时**就会置真：读档早于手柄插入，`JoySticker.getDeviceId(0)` 返回 null，`deviceId` 留空、守卫锁死，之后手柄插上也不会再分配。主项目在 `M:mob/data/ExtendConfig.as:ExtendConfig.initDefaultDevices()` 里把这行守卫删掉并写了注释，改成「每次调用都重试，靠 `deviceIsSet` / `isActive` 守卫」。
3. `setDefaultDevice` 只在 `!deviceIsSet && deviceId == null` 时赋值，所以玩家在改键页手动选的设备不会被自动覆盖。

### 4.6 四个「Continue」与局内重开的逐项责任

**结论**：Continue 在 3.7 里对应四个互不相干的机制，混用会导致完全错误的移植结论。

| # | 名字 | 触发 | 做什么 | 与「局内重开」的关系 |
|---|---|---|---|---|
| 1 | `ui/ContinueBtn.as:ContinueBtn`（经 `ui/fight/FightUI.as:FightUI.showContinue(cb)`） | 回合结束、`GameEndCtrl.SHOW_CONTINUE` 为真时挂到战斗 UI 上 | 点击只把 `GameEndCtrl._holdFrame = 0`，让结算流程往下走 | 无。它是「继续看结算」的按钮 |
| 2 | `state/GameOverState.as:GameOverState.showContinue()`（入口 `MainGame.MainGame.goContinue()`） | `GameCtrl.fightFinish()` 判定街机模式且 P2 赢 | YES → `GameLogic.loseScoreByContinue()`（score −10000，floor 0）→ `MainGame.I.goSelect()`；NO → `showGameOver()` | 相关但**不是**重开：它回到选人界面重打一整局 |
| 3 | `ui/loading/VersusLoadingUI.as:VersusLoadingUI.showContinue()` | 加载完成后 | 显示「按 CONTINUE 进入」提示，玩家确认才 `confirm()` | 无。纯加载提示 |
| 4 | `state/LoadingState.as:LoadingState.restartBattle()` | 暂停菜单 RESTART BATTLE、胜利界面 `VictoryUI.onMore` | 销毁整局 + 重走加载 | **本册的「局内重开」** |

**`SHOW_CONTINUE` 的赋值**：`ctrl/GameLogic.as:GameLogic.setGameMode(mode)` 里 `switch(param1 - 1)`：`case 0`（`GameData.I.loadSelect("config/salect.xml")`）与 `case 1`（`loadDebugSelect("salect.xml")`）置 true，`default` 置 false。

**续关画面的输入是怎么读的**：`state/GameOverState.as:GameOverState.handleInput()` 每帧读三个查询——`GameInputer.left("MENU",1)`、`GameInputer.right("MENU",1)`、`GameInputer.select("MENU",1)`，然后**自己用 `_lP` / `_rP` / `_sP` 三个布尔字段保存上一帧值**，靠 `l && !_lP` 这样的写法手搓边沿。这一段是 §4.1 「接口不提供抬起查询」的直接证据：真正要边沿的地方，调用方自己记账。

画面内还有两条并行输入：`_btnA` / `_btnB` 的 `MouseEvent.CLICK` + `ROLL_OVER`（`onContClick()` / `onBackClick()`），以及触摸二次确认 `_armed`。`_touch = Multitouch.supportsTouchEvents` 决定走哪条：触摸时第一次点击只把 `_armed = i` 并置 `_armT = 0`，`render()` 里 `_armT > 3000` 就撤销；非触摸时 `_armed` 参与 `hlOf(i)` 的高亮计算（`_armed == i ? 1 : 0`）。

**`SHOW_CONTINUE` 为真时的两个副作用**：

1. `GameEndCtrl.renderEND()` / `renderDrawGame()` 的 `case 1` 把 `_holdFrame` 从 `1 * FPS_GAME` 抬到 `600 * FPS_GAME`，即等玩家点 CONTINUE。
2. `GameEndCtrl.skip()` 第一行 `if(SHOW_CONTINUE) return;`——暂停键的 skip 通道被禁用，玩家必须点按钮。

**局内重开（重建式）的逐项重置责任表**：

| 对象 | 谁重置 | 怎么重置 |
|---|---|---|
| 玩家输入 | `restartBattle()` 里 `GameInputer.enabled = false`；`GameCtrl.destory()` 里 `GameInputer.clearInput()`；`doStartGame()` 里 `enabled = true` | 全局闸门关→开 + 清两组边沿锁存 |
| 血量 / 气 / 能量 | 不显式重置 | 由 `buildGame()` 重新 `GameRunFactory.createFighterByData()` 造新 `FighterMain`，字段取默认值 |
| 回合计时 | `GameRunDataVO.reset()` | `gameTimeMax = GameData.I.config.fightTime`；`gameTime = gameTimeMax`；`isTimerOver = false` |
| 胜场 | `GameRunDataVO.reset()` | `p1Wins = p2Wins = 0`、`round = 1` |
| 上一回合残留 | `GameRunDataVO.reset()` | `lastWinner` / `lastWinnerTeam` / `lastLoserData` / `lastLoserQi` / `continueLoser` 全清；`lastWinnerHp = GameData.I.config.fighterHP` |
| 场景对象 | `GameState.destory()` 逐 `IGameSprite.destory(true)`；`GameLogic.clear()` | 全部销毁 |
| 地图 | `buildGame()` 的 `GameRunFactory.createMapByData(gameRunData.map)` | 新建 `MapMain` |
| 特效 / 滤镜 | `GameCtrl.destory()` 里 `EffectCtrl.I.clearCinematicAll()`；`doStartGame()` 再调一次；`GameState.build()` 里 `EffectCtrl.I.initlize(this, _playerLayer)` | 清空 + 重建 |
| 相机 | 新 `GameState` 实例自带新 camera；`initFight()` 重建 `_cameraFocus` | 重建 |
| 阴影 / 舞台层 | `GameState.build()` 的 `ShadowCtrl.init(_shadowLayer)` | 重新 init |
| 团队表 | `doStartGame()` 的 `initTeam()` → `_teamMap.clear()` + 按模式重建 `TeamVO` | 重建 |
| 手柄 / 键盘配置 | 不参与 | 保持（配置在 `GameData`，不在 `GameCtrl`） |
| 设置项 | 不参与 | 保持 |

**`QUICK_RESTART` 为什么能穿过一次调用**：`restartBattle()` 先置 `QUICK_RESTART = true`，`MainGame.I.loadGame()` 内部**同步**执行 `new LoadingState()`（构造器里 `_quick = QUICK_RESTART` 并立刻写回 false），外层 `finally` 再兜一次。`goStage` 的销毁是同步的（`buildAfterDestory = false` 走 `_curStage.destory(); detoryComplete();`），所以「先构造新 stage、再销毁旧 stage」的顺序是确定的。

**`sameChange = true` 的意义**：`kyo/stage/KyoStageCtrl.as:KyoStageCtrl.goStage(stg, sameChange, buildAfterDestory)` 在 `sameChange == false` 时会对同类 stage 直接 `return false`（`getQualifiedClassName(stg) == getQualifiedClassName(_curStage)` 就放弃）。`MainGame.loadGame()` 传 true，所以「从 `LoadingState` 再开一个 `LoadingState`」才是合法操作。

### 4.7 主项目对照：手柄与重开都是另一套实现

**结论**：主项目**有**手柄全套（且比 3.7 更稳）、**有**街机续关、**有**局内重开；缺的是 3.7 的「设备图改键页 `GamePadSetUI`」与「回合结束的 CONTINUE 按钮」。

**同文件对比**：

| 文件 | 3.7 | 主项目 | 差异要点 |
|---|---|---|---|
| `input/IGameInput.as` | 20 条声明 | 20 条声明 | 逐条一致 |
| `input/GameInputer.as` | 静态路由 | 增 `isResetting` 短路、手柄暂停屏蔽、`setKeyState()` 新 API、输入日志、固定 3 帧宽限 | 见下 |
| `mob/input/JoySticker.as` | 无空引用保护、三常量死区 | `getDeviceId` / `getDeive` 都判 null；无三常量，`checkDownValue` 只用 ±0.5；新增 `pollInputLog()` / `getControlValuesDebug()` / Android 按键拦截 | 主项目更稳 |
| `mob/input/GameJoystickInput.as` | 14 个方法直查 `JoySticker` | 每个方法加 `_checkEdge()` 与 `_joyLog()`（实例级 `_prevKeys`）；`select()` 改用 `_config.select` | 主项目修掉了 SELECT 死键位 |
| `mob/data/ExtendConfig.as` | 有 `_isInitDefaultJoystick` 一次性守卫 | 删守卫 + 加 `ENABLE_KEYBOARD` / `joyTarget` 字段 + `isActive` 校验 | 主项目修掉了「读档早于插手柄导致 deviceId 永久为空」 |
| `mob/input/InputManager.as` | 7 个实例，`joy_menu` 与 `joy_p1` 都是 `GameJoystickInput(1)` | 10 个实例，含 `key_menu` / `key_p1` / `key_p2`，`joy_menu = GameJoystickInput(0)` | 主项目键盘可用 |
| `state/GameOverState.as` | 代码自绘（`BwBackdrop` + `CodeDraw` + 触摸二次确认 `_armed`） | SWF 帧（`ResUtils.I.gameover` + `gotoAndPlay("continue")` + `initBtn("btn_yes")`） | 两套完全不同的 UI 技术路线 |

**主项目独有（3.7 无）**：

| 成员 | 位置 | 作用 |
|---|---|---|
| `isResetting:Boolean` | `M:ctrl/game_ctrls/GameCtrl.as` | 重开专用的重入闸门 |
| `GameCtrl.restartBattle()` | 同上 | 原地重置式局内重开 |
| `GameCtrl.clearDynamicSprites()` | 同上 | 只留 `FighterMain` 与 `Assister`，其余 `removeGameSprite(s, true)` |
| `GameCtrl.resetAllFighterCtrls()` | 同上 | 逐个 `resetOneFighterCtrl()`：气、能量、辅助槽、钢体、受击缓存、`setFighterActionCtrl()`、`getBuffCtrl().reset()` |
| `GameCtrl.isPauseGame()` | 同上 | 公开暂停查询，供 `GameInputer.call()` 屏蔽手柄 |
| `GameInputer.setKeyState(type, keyCode, isDown)` | `M:input/GameInputer.as` | 外部注入按键状态 |
| `JoySticker.pollInputLog()` | `M:mob/input/JoySticker.as` | 每帧扫所有 control 打边沿日志 |
| `JoySticker.getControlValuesDebug(deviceId)` | 同上 | 单设备全部 control 值的调试串 |

**3.7 独有（主项目无）**：

| 成员 | 状态 |
|---|---|
| `mob/input/GameInputRouter.as` + `GameInputFocus.as` | 死代码，见 §4.2 |
| `mob/views/GamePadSetUI.as` + `ui/GamePadArt.as` | 设备图改键页，主项目只有 `JoyStickSetUI` 这一类简版 |
| `ui/ContinueBtn.as` + `GameEndCtrl.SHOW_CONTINUE` | 回合结束的 CONTINUE 按钮；主项目 `M:ctrl/game_ctrls/GameEndCtrl.as` 无此字段 |

**主项目 `GameInputer.call()` 的两处硬改**（都能从代码读到，不靠猜）：

1. `if(GameCtrl.I.isResetting) return false;`——重开过程中所有输入查询一律返回 false，防止重置途中的半初始化状态被输入打断。
2. `if(_loc6_[_loc4_] is GameJoystickInput && GameCtrl.I.isPauseGame()) { _loc4_++; continue; }`——暂停时跳过所有手柄实现，键盘与屏幕按钮不受影响。源码注释写的是「1P手柄暂停阻塞：游戏暂停时跳过所有 GameJoystickInput 实例，确保『手柄仅在游戏未暂停时可用』」。注意它按**类型**判断（`is GameJoystickInput`），所以 `key_*` 与 `screen_*` 三条通道照旧可用。

---

## 5. 陷阱与反编译噪音

以下每条都对照过两侧源码；凡「看起来像 bug」的，标明是反编译丢信息还是真缺陷。

### 5.1 空实现与空方法体

| 位置 | 现象 | 判定 |
|---|---|---|
| `mob/input/GameJoystickInput.as:GameJoystickInput.clear()` | 方法体全空 | **真·空实现**。手柄实现没有本地缓存，`GameInputer.clearInput()` 对它无事可做。主项目在这里改成清 `_prevKeys`（因为它自己加了边沿缓存），两侧行为不同 |
| `mob/input/GameJoystickInput.as:GameJoystickInput.focus()` | 空 | 真·空实现。手柄靠 `device.enabled`，没有「焦点」概念 |
| `mob/input/ScreenPadInput.as` 的 `initlize` / `setConfig` / `focus` | 三个方法都空 | 真·空实现。虚拟摇杆由 `ScreenPadManager` 主动 `setDown()` 推值 |
| `mob/GameInterfaceManager.as` 的 `initTitleUI` / `submitScore` / `showRank` / `getFighterCtrl` | 空体或只 `return null` | 真·空实现（广告 / 排行 / 外置人物控制器未接） |
| `state/LoadingState.as:LoadingState.build()` / `state/GameOverState.as:GameOverState.build()` | 空 | 真·空实现。两者都在构造器里建完 UI |

### 5.2 被注释掉 / 永不执行的旧路径

| 位置 | 内容 | 影响 |
|---|---|---|
| `input/GameInputer.as:GameInputer.updateConfig()` | `if(GameInterface.instance.updateInputConfig()) return;` 之后的三个 `setConfig(...key_menu / key_p1 / key_p2)` | 3.7 恒真 ⇒ 死路径。**这是 `KeyConfigVO` 在 3.7 移动端不生效的根因** |
| `input/GameInputer.as:GameInputer.initInput()` | 三段 `if(!_loc1_) _loc1_ = new Vector.<IGameInput>([new GameKeyInput(), ...])` 兜底 | `GameInterface.instance` 已被 `launchWUFAN.as:initGame()` 赋值 ⇒ 兜底不执行 ⇒ 键盘实例是死的 |
| `mob/input/GameInputRouter.as` 整个文件 + `mob/input/GameInputFocus.as` 整个文件 | 按焦点（MENU / CHARACTER_SELECT / STAGE_SELECT / BATTLE / PAUSE / RESULT）改 `InputManager.I.*.enabled` 的并行路由 | **整条死代码**：除彼此外零引用 |
| `mob/input/InputManager.as:InputManager.joy_menu` | 与 `joy_p1` 都是 `new GameJoystickInput(1)` | 两个实例、同一个 `player = 1`。`player` 字段只被 trace 用，设备来自 `_config.deviceId`，所以「两个实例」只是两份独立的 `enabled` 与 `_config` |
| `input/GameInputType.as` 整个文件 | `MENU` / `P1` / `P2` 三个 `String` 常量 | 除自身构造器外零引用，键实际是字面量 |

### 5.3 反编译假象：看着像 bug，其实是丢信息

| 现象 | 真实原因 | 证据 |
|---|---|---|
| `new Vector.<IGameInput>([new GameKeyInput(), ...])` | `Vector.<T>` 的构造器只接受 `length:int`，不接受数组 | AS3 语言规则；这一行是反编译器把 `Vector` 的 push 序列压成「数组字面量」的产物 |
| `isDown(type, action, state, param4)` 的 `param4` 无任何可观测效果 | `param4` 只影响局部 `_loc5_`，`_loc5_` 只传给 `isJustDownDelay` 的第三参，而那个参数在函数体里从未被读 | 三处签名与调用点都在；`renderListenKeys()` 是唯一传 true 的地方 |
| `JoyStickConfigVO.toObj()` 里 `_loc4_` 逐字段拼好之后被丢弃，`return KyoUtils.itemToObject(this)` | 反编译把「拼对象」与「反射导出」两段都保留了；`itemToObject` 用 `describeType().variable` 导出同名结果 | 两条路径产出形状相同，只差嵌套的 `JoyStickSetVO` 是实例还是纯对象；`JSON.stringify` 与 `readObj` 对两种形状等价 |
| `JoyStickConfigVO.toObj()` 里 `_loc3_ = KyoUtils.getItemVaribles(this)` 也是死变量 | 同上，`for each` 循环的产物 | grep `getItemVaribles` 只有这一处调用 |
| `GameInputer.call()` 里 `_loc4_.apply(null, rest)` | 反编译把方法值当 `Function` 取出来再 `apply`，等价于 `impl[action](...)` | 参数透传（`setConfig` 走同一条路）需要它 |
| `JoySticker.isDown()` 的边界写成 `param2.id > device.numControls`（应为 `>=`） | 反编译常见的 `>=` / `>` 混淆 | 主项目同一行是 `>=`；且 `getControlAt` 返回 null 有下一行兜住，越界不崩 |
| `GameInputer` 里 `_loc1_` / `_loc3_` / `_loc4_` 等变量名 | 反编译重命名，原始语义名丢失 | 全体 `.as` 一致现象 |
| 主项目 `M:input/GameInputer.as:GameInputer.call()` 里 `while` 内部多出一个裸 `{ ... }` 块 | 人工插入暂停屏蔽 `if` 时把原循环体整体包进了一个块语句 | 语法合法（AS3 允许块语句），不是 bug，但读起来像括号错位 |
| `data/KeyConfigVO.as:KeyConfigVO.setKeys()` 里 `this.dash = param7;` 连续出现两次 | 反编译把同一条赋值复制了一份（第 7 参同时写 `dash`） | 两次赋值目标与值相同，幂等，无副作用；但会让人误以为有两个 dash 参数 |

### 5.4 真缺陷（代码推出来的，不是反编译噪音）

| # | 位置 | 缺陷 | 后果 |
|---|---|---|---|
| 1 | `mob/input/JoySticker.as:JoySticker.initlize()` | `GameInput.isSupported` 为假时**在给 `_gameDeivces` 赋值之前 return** | `getAllDeivces()` 返回 null；`getDeviceId(i)` 内 `_gameDeivces.length` 直接抛 `TypeError #1009`。调用链上 `ExtendConfig.readSaveObj → updateJoyConfig → setDefaultDevice → JoySticker.getDeviceId` 与 `GameInterfaceManager.updateInputConfig` 都会踩到。主项目两处都加了判空 |
| 2 | `mob/views/GamePadSetUI.as:GamePadSetUI.buildList()` | `var devices = JoySticker.getAllDeivces(); while(i < devices.length)` 未判空 | 同上，平台不支持手柄时打开改键页即崩 |
| 3 | `mob/input/GameJoystickInput.as:GameJoystickInput.select()` | 读 `_config.jump`，`_config.select` 成为死字段 | 改键页的 SELECT 行改了不生效 |
| 4 | `mob/data/ExtendConfig.as:ExtendConfig.initDefaultDevices()` | `_isInitDefaultJoystick` 一次性守卫，读档（此时无手柄）就把守卫锁死 | 手柄晚插则 `deviceId` 永远为空 |
| 5 | `mob/views/GamePadSetUI.as:GamePadSetUI` 的 Set All 流程 | 录制期 `_list.enabled = false`，而 `OptList.renderInner()` 的 BACK 轮询就在这个 `enabled` 判据之后 | 录制期间**没有退出键**；手柄中途断连或某控件始终达不到阈值时，只能杀进程。`GamePadSetUI.destory()` 会 `GameRender.remove(renderSet)`，但 `destory` 只能由 `SettingState` 调到 |
| 6 | `mob/views/GamePadSetUI.as:GamePadSetUI.onBackKey()` | 只 dispatch `CANCEL_SET` | 录制中按 BACK 也不中断录制（因为 BACK 根本没被轮询到），与第 5 条同源 |
| 7 | `mob/input/JoySticker.as:JoySticker._downKey` | 静态字段，`getDownKey` 跨调用共享 | 改键页与游戏若同时调用会互相污染；3.7 里只有改键页调用，所以只是潜在问题 |
| 8 | `mob/input/InputManager.as` + `ExtendConfig.updateJoyConfig()` | `joy_menu` 与 `joy_p1` 共享同一物理设备，但键位来自两份 VO；`updateJoyConfig()` 只拷 10 个字段 | `attack` / `dash` / `skill` / `superSkill` / `special` / `waikai` / `select` 这 7 个键位在菜单侧仍是字段默认值，改键页改 P1 的 ATTACK 不会同步到菜单 |

### 5.5 旧稿此处已过时

旧稿 `3.7扩展-局内重开与手柄适配实现参考.md` 与本册冲突的地方（以代码为准）：

| 旧稿说法 | 代码事实 |
|---|---|
| 「Continue 弹窗倒计时」 | **没有倒计时**。`GameOverState` 的 `_armed` 是「触摸模式下的二次确认」：`onContClick()` 第一次只把 `_armed = i`，`render` 里 `_armT > 3000` 就撤销高亮。没有超时自动选 NO |
| 「`IGameInput` 19 方法」 | 20 条成员声明。按「`enabled` 计一个属性」折算才是 19 个语义成员，写 19 方法会与源码对不上 |
| 「3.3 缺 `goContinue` / `loseScoreByContinue` / `continueLoser` / `GameOverState.showContinue`」 | 主项目**四个都有**（`M:MainGame.as`、`M:ctrl/GameLogic.as`、`M:data/GameRunDataVO.as`、`M:state/GameOverState.as`），缺的只有 `ContinueBtn` 与 `SHOW_CONTINUE` |
| 「3.3 闯关战败直接走 `goSelect()`」 | 已变：`M:ctrl/game_ctrls/GameCtrl.as:GameCtrl.fightFinish()` 在街机模式走 `MainGame.I.goContinue()` |
| 「3.3 无局内重开」 | 主项目有 `GameCtrl.restartBattle()`（原地重置式），入口 `M:ui/PauseDialog.as:PauseDialog.showRestartConfirm()` |
| 「`JoySticker.isDown` 用死区 0.35」 | 死区常量只用于 `checkDownValue()`；游戏路径 `isDown()` 用 ±0.5 |
| 旧稿的手柄层次图没有 `GameInputRouter` | 该文件存在但整棵死树，本册 §4.2 单列 |

### 5.6 读这套代码最容易误判的六点

1. **「手柄已实现」不等于「手柄可用」**。`GameJoystickInput` 的 14 个方法、`JoySticker` 的整套设备管理、`ExtendConfig` 的存档字段都在，但把链条串起来的 `GameInterfaceManager.getGameInput()` 是唯一入口；只要 `GameInterface.instance` 没被赋值或 `getGameInput` 返回 `null`，走的就是「只有 `GameKeyInput`」的兜底，手柄完全不存在。判据是 `launchWUFAN.as:initGame()` 里那一行赋值，而不是 `JoySticker.as` 有没有内容。

2. **「有改键界面」不等于「改键会保存」**。`GamePadSetUI` 的 Apply 只改内存；落盘在 `SettingState.applyAndExit()`。若把改键页的入口从 `SettingState` 挪到别处（例如暂停菜单），配置将永不落盘——这条路径不会报错，只会「下次启动还是旧键位」。

3. **「`select` 是确认键」在手柄侧不成立（3.7）**。3.7 的 `GameJoystickInput.select()` 读 `_config.jump`，所以菜单里按手柄的 A（jump 槽位）等于确认；`_config.select` 那个槽位是装饰。看代码时若只读 `GamePadSetUI` 的 MAPPINGS 表（有 `select` 行），会得出「SELECT 键可改」的结论。

4. **`_inputMap` 的键是字面量，不是 `GameInputType` 常量**。改通道名时改 `GameInputType` 无效，必须改 `GameInputer` 与 `GameInterfaceManager.getGameInput()` 里的字符串。

5. **`enabled` 有三层，别只看一层**。全局 `GameInputer.enabled`（各 State 开关）→ 通道是否存在（`_inputMap[type]`）→ 实例 `enabled`。任何一层为假，`call()` 都返回 false，而三层都没有日志（3.7 版本）。排查「按键没反应」必须三层逐查。

6. **`LoadingState.restartBattle()` 不是「重开这一回合」，是「重开整场」**。它走 `gameRunData.reset()`，`p1Wins` / `p2Wins` 归零、`round` 归 1。想保留胜场就得换主项目那条 `GameCtrl.restartBattle()` 路线（它显式快照并回填两个 `Wins`）。

---

## 6. 移植可行性

### 6.1 手柄（设备层 + 改键 UI + 存档）

| 组件 | 能搬 / 要改 / 搬不了 | 原因与改动点 |
|---|---|---|
| `input/IGameInput.as` | **无需搬** | 主项目同文件逐条一致 |
| `input/GameInputer.as`（三态 + listenKeys） | **要改（增量）** | 主项目已有等价实现，但宽限窗口径不同：3.7 是 `0.1 × MainGame.I.getFPS()` 帧（`FPS_GAME` 与 `FPS_UI` 都是 60 ⇒ 6 帧 ≈ 100ms），主项目固定 3 帧（`FPS_GAME = 60` ⇒ 50ms；菜单 `FPS_UI = 30` ⇒ 100ms）。要统一就改 `isJustDownDelay` 一行，两种取值的差别是菜单连打的手感 |
| `GameInputer.JUST_DOWN_DELAY` 常量 | **搬不了（无意义）** | 3.7 自己也没用它，字面量 0.1 写在 `isJustDownDelay` 里 |
| `mob/input/JoySticker.as` 三常量（0.35 / 0.75 / 0.6） | **要改** | 主项目 `checkDownValue` 已简化成 ±0.5。搬回三常量会改变「任意键」与「改键录制」的灵敏度，录制更容易被摇杆误触发 |
| `mob/input/JoySticker.as` 判空保护 | **必须搬（反向）** | 主项目已有、3.7 没有。方向是「别拿 3.7 版本盖主项目」 |
| `JoySticker.joystickHandler()` 里的 `setTouchEnabled` | **要改** | 主项目对应逻辑在 `M:mob/ctrls/ControllerHudManager.as` 的 `setTouchEnabled(finalTouch)`。直接搬会在两处争夺最终值 |
| `mob/input/GameJoystickInput.as` | **无需搬** | 主项目版本是超集（多 `_checkEdge` / `_joyLog` / `clear` 实现） |
| `mob/input/GameInputRouter.as` + `GameInputFocus.as` | **别搬** | 死代码。搬进来会多一层 `enabled` 写入源，与 `updateInputConfig()` 打架 |
| `mob/views/GamePadSetUI.as` + `ui/GamePadArt.as` | **搬（要改）** | 依赖 `ui/OptList.as`（主项目有）、`ui/SetBtnDialog.as`、`ui/GamePadArt.as`（主项目无）。必须补：① `buildList()` 判空；② 录制期加 BACK 出口（`renderSet()` 里自己轮询 `GameInputer.back(1)`）；③ 若主项目路由是「单手柄固定 P1」，`Target Player` / `Switch P1/P2` 两行要按 `M:mob/GameInterfaceManager.as:GameInterfaceManager.refreshJoystickRouting()` 的实际语义改写 |
| `ui/GamePadArt.as` | **搬（无依赖）** | 纯绘制 + `highlight(id)` / `dispose()` / `artHeight`，只依赖 `GameConfig` |
| `ExtendConfig.updateJoyConfig()` 的拷贝清单 | **要改** | 3.7 只拷 10 个字段（见 §5.4 第 8 条），搬来后菜单侧 7 个键位仍是默认值。移植时要补全 17 个 |
| 存档字段 `joy_menu` / `joy_p1` / `joy_p2` | **能搬（兼容）** | 主项目 `M:mob/data/ExtendConfig.as:ExtendConfig.toSaveObj()` 已用同名键，旧档可直接读 |
| 落盘时机（只有设置界面退出时写） | **别搬** | 主项目这条路一样，但 `GamePadSetUI` 单独搬来之后，若从非 `SettingState` 的入口打开改键页，配置只改内存不落盘。`ViewManager.goGamePadSetInner()` 的 `is SettingState` 判据必须一起搬 |
| `flash.ui.GameInput` 在 Android 的可用性 | **搬不了（需实测）** | 代码里只有 `GameInput.isSupported` 一处分支；见 §7 |

### 6.2 Continue（状态重置链）

| 组件 | 能搬 / 要改 / 搬不了 | 原因与改动点 |
|---|---|---|
| `LoadingState.restartBattle()`（重建式） | **要改** | 它靠 `MainGame.I.loadGame()` + `QUICK_RESTART` 静态标记穿透。主项目 `M:MainGame.as` 没有同名同序实现，`M:state/LoadingState.as` 也没有 `QUICK_RESTART` / `RESTART_SKIP_LOAD` / `RESTART_HOLD_MS` 三个静态字段，需整段补 |
| `QUICK_RESTART` 的 try/finally 传参 | **搬（模式可复用）** | 核心是「置标记 → 同步构造消费方 → finally 撤回」。前提是构造确实同步，`goStage()` 的 `buildAfterDestory = false` 分支保证了这点 |
| `sameChange = true` | **必须搬** | 漏了它，`LoadingState` 重启同类 stage 会被 `goStage` 的同类判定挡掉，表现为「点重开没反应」 |
| `GameState.destory()` 的逐 sprite 销毁 | **要改** | 主项目 `M:state/GameState.as` 的销毁路径掺了 GPU 滤镜代理（`FilterProxyManager`）与 TAG 共享血池，直接套 3.7 的顺序会漏 `invalidateAll()` |
| `GameRunDataVO.reset()` | **能搬** | 两边字段同名同义（`p1Wins` / `p2Wins` / `round` / `lastWinner*` / `gameTime*` / `isTimerOver` / `isDrawGame` / `continueLoser`） |
| `GameCtrl.doStartGame()` 的重置序列 | **搬不了（已被替代）** | 主项目用 `GameCtrl.restartBattle()` 原地重置。取舍：重建式彻底但重载地图 / 资源（黑场一闪）；原地式快但**必须逐项列全**，漏一项就是残留状态 |
| `GameEndCtrl.SHOW_CONTINUE` + `ui/ContinueBtn.as` | **搬（要改）** | `ContinueBtn` 依赖 `ui/SetBtnGroup.as`（主项目有）。改动点：`FightUI.showContinue()` 里用的 `_legacy` 容器在主项目 `M:ui/fight/FightUI.as` 的对应字段需现场核对；`GameEndCtrl.skip()` 的 `if(SHOW_CONTINUE) return;` 门必须一起搬，否则暂停键能绕过按钮 |
| `GameLogic.setGameMode()` 里的 `SHOW_CONTINUE` 赋值 | **要改** | 3.7 按 `switch(mode - 1)` 的 `case 0/1` 赋值；主项目模式编号体系不同，需按 `M:ctrl/GameLogic.as` 现有编号重排 |
| `GameOverState` 自绘版 | **搬不了** | 3.7 是 `BwBackdrop` + `CodeDraw` + `_slashFx` 的整套自绘；主项目是 SWF 帧（`ResUtils.I.gameover` + `gotoAndPlay("continue")`）。换 UI 技术路线属于重做，不是移植 |
| `loseScoreByContinue()`（−10000，floor 0） | **无需搬** | 主项目同函数同数值 |
| `continueLoser` 字段 | **无需搬** | 主项目已有，且在 `GameCtrl.destory()` 的 `destoryFighters(continueLoser)` 里承担「把战败角色从组里摘掉」的职责 |

### 6.3 平台坑（能由代码确定的）

| 事实 | 依据 |
|---|---|
| 手柄 API 走 `flash.ui.GameInput`，代码只判 `GameInput.isSupported` 一处 | `mob/input/JoySticker.as:JoySticker.initlize()` |
| 3.7 在 `GameJoystickInput.initlize()` 里对 `Stage` 与 `NativeApplication` 都挂 `KEY_DOWN` / `KEY_UP` 拦截，只 `preventDefault()` 掉 27 与 16777238（Android BACK），整段裹在 `try/catch` 里 | `mob/input/GameJoystickInput.as:GameJoystickInput.preventAndroidBack()` |
| 主项目把拦截扩到 10 个 keyCode（167 / 165 / 97 / 108 / 109 / 4 / 3 / 19~22），注释说明「手柄按键同时产生 KeyboardEvent」 | `M:mob/input/JoySticker.as:JoySticker.onPreventDefaultKeys()`。这条是主项目作者的运行观察，不是 3.7 的结论 |
| 存档写盘用 `flash.filesystem.File.applicationStorageDirectory`，Android 上落在应用私有目录 | `mob/GameInterfaceManager.as:GameInterfaceManager.saveGame()` + `mob/utils/FileUtils` |
| `GameInput.numDevices < 3` 是硬上限（最多 2 个手柄） | `mob/input/JoySticker.as:JoySticker.joystickHandler()` |
| 设备 id 是运行时分给设备的字符串，代码只把它当 key 用 | `JoySticker.addDeivce()` 用 `param1.id` 作 map 键；`ExtendConfig` 持久化它 |

---

## 7. 未实测清单

以下条目**不能**当已知事实继续推演。每条都写明验证手段。

- [ ] **`GameInput.isSupported` 在目标 Android 设备上的取值**。
      手段：真机跑一个只打 `trace(GameInput.isSupported)` 的探针 SWF，或直接在现有 APK 里看 `JoySticker.initlize()` 的「该平台不支持手柄！」trace 是否出现。
      为什么必须验：为假时 §5.4 第 1、2 条会直接崩在 `getAllDeivces()` 上，而不是「手柄不能用」这么温和。

- [ ] **`GameInputControl` 的索引到物理键的对应关系**（默认表里 `attack=6 / jump=4 / dash=5 / skill=7` 等）。
      手段：接上手柄跑 `JoySticker.outputDeviceInfo()`，逐个按物理键记录 `button:index:id` 输出，与默认表比对。
      为什么必须验：默认表是 Xbox 布局的猜测值，不同手柄索引不同；这决定了「不改键能不能玩」。

- [ ] **`GameInputControl.value` 对 D-Pad 与扳机键的取值范围**。
      手段：同上探针，打印 `control.value`（不要用 `>0.5` 过滤）。
      为什么必须验：`isDown()` 用 ±0.5、`checkDownValue()` 用 +0.75 / −0.6，两个判据在「扳机输出 0~1」与「输出 −1~1」两种设备上结论不同。

- [ ] **热插拔事件在 Android 上的实际触发情况**（应用启动前已连接的手柄是否补发 `deviceAdded`）。
      手段：三种时序各跑一次——启动前插好 / 启动后插 / 游戏中拔插——观察 `joystickHandler` 的 trace 与虚拟摇杆显隐。
      为什么必须验：`ExtendConfig.initDefaultDevices()` 的一次性守卫能否被绕过，完全取决于 `getDeviceId(0)` 在读档那一刻返回什么。

- [ ] **手柄按键是否真的同时产生 `KeyboardEvent`，以及具体 keyCode 集合**。
      手段：在 Android 上跑主项目 `onPreventDefaultKeys()`，看 `KEY_DOWN code=...` 折叠日志里的实际值。
      为什么必须验：3.7 只拦 27 / 16777238，主项目拦 10 个；哪一组必要只能靠真机日志判定。

- [ ] **`GamePadSetUI` 的 Set All 在目标手柄上能否走完 17 个键**。
      手段：真机打开改键页 → Set All → 依次按 17 个键，观察是否每次进入下一映射；再故意在中途拔掉手柄，确认是否卡死（按 §5.4 第 5 条，代码层面没有出口）。
      为什么必须验：§5.4 第 5 条是静态推断，缺少「卡死」的现场复现记录。

- [ ] **`LoadingState.restartBattle()` 重建式重开的实际耗时与黑场时长**。
      手段：真机跑暂停菜单 → RESTART BATTLE，用计时器打 `StateCtrl.transIn` 到 `GAME_START` 的毫秒差，并录屏确认 `_quickHolder` 期间是否白闪。
      为什么必须验：`RESTART_HOLD_MS = 250` 与 `RESTART_SKIP_LOAD = false` 是预设值，代码看不出这 250ms 够不够。

- [ ] **`QUICK_RESTART` 静态标记在「转场被跳过」时是否泄漏**。
      手段：把 `StateCtrl.transEnabled` 置假（或让 `transIn` 直接回调），跑一次重开，检查下一次正常进入战斗是否被误判为 quick（表现为跳过片头直接开打）。
      为什么必须验：`transIn` 在 `!transEnabled` 时是**同步**回调，此时 `QUICK_RESTART` 的置位与 `new LoadingState()` 的先后顺序与正常路径不同，静态读代码无法排除竞态。

- [ ] **主项目 `GameCtrl.restartBattle()` 的重置是否完整**。
      手段：真机在下列状态各重开一次，逐项比对开局快照：受击僵直中 / 灵爆钢体中 / 必杀特写中 / TAG 换人无敌中 / 训练模式 / 2v2 第二人未出场 / 时停中。
      为什么必须验：原地重置靠「逐项列全」，`M:ctrl/game_ctrls/GameCtrl.as:GameCtrl.resetOneFighterCtrl()` 列了 12 项，代码无法自证「没有第 13 项」。

- [ ] **主项目 `isResetting` 期间 `GameInputer.call()` 全返回 false 的副作用**。
      手段：在重置耗时里观察菜单 / 触摸按钮是否有一次点击被吞。
      为什么必须验：`restartBattle()` 是同步执行，吞输入窗口只有一帧长，静态分析算不出玩家能否感知。

- [ ] **旧档兼容**：3.7 的 `bvnsave.sav`（`id = "bvn3.5A"`）直接喂给主项目会怎样。
      手段：把 3.7 真机产生的 `bvnsave.sav` 放到主项目 `applicationStorageDirectory`，启动后看 `GameInterfaceManager.loadGame()` 的 id 校验是否命中、`extendConfig.readSaveObj()` 是否报错。
      为什么必须验：两工程 `ConfigVO` 字段集不同，`readSaveObj` 末尾还有 `KyoUtils.setValueByObject(this, param1)` 的反射灌入，越界字段的处置只能实跑。

- [ ] **重建式重开后 `GameRunDataVO.map` 与 `MapMain` 实例是否 1:1**。
      手段：重开前后各打印一次 `GameCtrl.I.gameRunData.map` 与 `GameCtrl.I.gameState.getMap()` 的身份（或用 `Debugger` 输出对象引用），确认没有残留旧地图的图层被 `cacheAsBitmap` 挂在显示树上。
      为什么必须验：`gotoGame()` 用 `MapModel.I.getMap(GameData.I.selectMap)` 重取 VO，`buildGame()` 再 `createMapByData`，两次取的是不是同一个 VO 由 `MapModel` 的缓存策略决定，代码里读不到缓存是否复用实例。

- [ ] **连续重开的资源泄漏**：重开 10 次后 `System.totalMemory` 是否单调上升。
      手段：真机连点 10 次 RESTART BATTLE，每轮记录 `System.totalMemory` 与 `System.privateMemory`。
      为什么必须验：重建式重开每轮都 `new FighterMain` / `new MapMain` / `new GameState`，而 `MainGame.cleanMemoryWithActiveFighters()` 只从菜单路径调用（`goMenu` / `goSelect`），重开路径不经过它。

- [ ] **`JoySticker` 静态 `_downKey` 在「改键页开着 + 战斗输入同时轮询」时的相互污染**。
      手段：改键页 Set All 录制中，让 P1 侧 `GameJoystickInput.attack()` 也处于轮询（例如把改键页做成暂停菜单的子页），观察录制是否跳键。
      为什么必须验：3.7 当前架构里改键页在 `SettingState`（无战斗），这条路径现在走不到；一旦改键页挪进暂停菜单就会暴露。
