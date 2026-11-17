# 相机控制器：3.7 单类 `GameCamera` 与主项目三件套

**一句话**：相机不是镜头对象，而是每帧把焦点包围盒换算成容器 `scrollRect` 与 `scale` 的纯函数。
**源码基准**：`BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/`（V3.7，只读参考，本册未改动其中任何文件）。
**对照基准**：`BVNscripts/scripts/net/play5d/game/bvn/`（3.3 主项目，已含 TAG 换人与 GPU 滤镜代理分支，同样未改动）。

> **引用约定**：正文中的 `路径:类.方法()` 若不带前缀，路径相对 `BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/`；
> 以 **主项目** 开头的引用，路径相对 `BVNscripts/scripts/net/play5d/game/bvn/`。行号一律不写死，确需定位处标注「参考 :N」并声明只是参考。

---

## 1. 一句话结论

3.7 的 `state/GameCamera.as` 是**普通实例类**，由 `GameState.camera` 这个公开字段持有，每帧在 `GameState.render()` 里被调用一次；它不创建任何显示对象，只往宿主容器 `_gameLayer` 上写两个属性——`scrollRect`（平移 + 视口尺寸）和 `scaleX/scaleY`（缩放）。所谓「跟随、缩放、钳制、震屏」全部是这一对属性的算术结果。

主项目把这套算术拆成了三件：`GameCameraCtrler`（无策略门面）、`FighterCameraCtrler`（角色侧子类，提供 `focusSelf()` / `focusTarget()`）、`GameCameraFocusWatch`（必杀特写撤销看门狗）。拆分带来的是**归属与追责**，不是新算法：主项目 `GameCamera` 的几何实现比 3.7 **更旧**，缺 3.7 的包围盒全量统计、留白钳制、震屏/冲击缩放、电影锁与缩放专用缓动。

---

## 2. 领域术语

| 术语 | 本册含义 | 代码对应物 |
|---|---|---|
| 相机 | 一个只写宿主容器变换的几何计算器，不是 `Camera` 类、不是矩阵栈 | `state/GameCamera.as:GameCamera` |
| 宿主 / stage | 被相机改写的那个容器（不是 Flash 的 `Stage`） | `GameState._gameLayer`，经 `GameCamera._stage` 持有 |
| 视口矩形 | 相机「此刻看到」的世界矩形，等于 `scrollRect` | `_rect`（内部当前值）、`_displayRect`（写完抖动的最终值）、`_noTweenRect`（目标值） |
| 缩放 `_zoom` | 目标缩放（容器 `scale`） | `GameCamera._zoom`，读：`getZoom()` |
| 显示缩放 `_stageScale` | 当帧真正写到容器上的缩放，按帧缓动逼近 `_zoom` | `GameCamera._stageScale`，读：`getZoom(true)` |
| 焦点 | 被跟随的 `DisplayObject` 数组（角色 MC），或一个固定点 | `_focus:Array` / `_point:Point` |
| 焦点中心 | 多焦点时的包围盒中心 | `renderMulti()` 写入的 `_point` |
| 留白 | 焦点允许贴边的像素比例，防止角色被切边 | `framePaddingX` / `frameHeadroom` / `frameFootroom` |
| 边界矩形 | 视口允许落位的范围（错误命名，字段叫 `_fbR` 且其 `width/height` 被当作最大 x/y 用） | `GameCamera._fbR` |
| trauma | 震屏「剂量」，0~1 线性衰减，振幅取其平方 | `_trauma`，读：`trauma` |
| punchZoom | 打击冲击缩放，弹簧系统叠在 `_stageScale` 上 | `_punchZoomOffset` / `_punchZoomVel` |
| 电影锁 | 锁住「单人自动缩放 + 留白钳制 + 缩放减速」三处行为 | `_cinematicLock`，读：`isCinematic` |
| owner / 发起方 | 是谁摆的镜头：引擎、必杀、还是人物包自己 | 主项目 `GameCamera.FOCUS_OWNER_ENGINE` / `FOCUS_OWNER_BISHA` |
| 门面 | 只做空判 + 转发的语义化包装，不含策略 | `主项目 ctrl/game_ctrls/GameCameraCtrler.as` |
| 看门狗 | 每帧检查「特写该收回了吗」，收回即回调 | `主项目 state/GameCameraFocusWatch.as` |

---

## 3. 结构与数据流

### 3.1 谁持有谁

| 角色 | 3.7 | 主项目 |
|---|---|---|
| 相机实例 | `GameState.camera`（`public var`，类型 `GameCamera`） | 同名字段 `GameState.camera` |
| GameState 实例 | `bvn/MainGame.as` 里 `new GameState()`，再交给 `GameCtrl.initlize()`（`GameCtrl.gameState`） | 同 |
| 全局入口 | `GameCtrl.I`（`private static var _i` + `public static function get I()`） | 同 |
| 相机创建点 | `state/GameState.as:GameState.initCamera()` 内 `new GameCamera(_gameLayer,GameConfig.GAME_SIZE,stageSize,true)` | `主项目 state/GameState.as:GameState.initCamera()` 内同一句 |
| 相机生命周期终点 | `GameState.destory()` 里 `camera = null`（`GameCamera` 无销毁方法） | `GameCamera.destory()` 显式置空引用 |
| 额外持有点 | `ctrl/GameLogic.as:GameLogic.initGameLogic()` 把相机存进 `private static var _camera`，**全文再无读取**（死字段） | 无 |

结论（对应问题 1）：**不是静态单例**。全树只有一处 `new GameCamera`，就是 `GameState.initCamera()`；相机跟着 `GameState` 生灭，`GameState` 跟着一局战斗生灭。

### 3.2 每帧调用链（3.7）

```text
flash Stage.ENTER_FRAME
  └─ ctrl/GameRender.as:GameRender.render(e)          // 任务表，按 priority 升序
       └─ ctrl/game_ctrls/GameCtrl.as:GameCtrl.render() // GameRender.add(render)，默认 priority=100
            ├─ EffectCtrl.I.render()                      // 特效 / 黑幕 / 时停
            ├─ gameState.render()                         // ← 相机在这里
            │    ├─ updateSurvivorFocus()                 // 多人模式存活者重建焦点（原地改 _cameraFocus 内容）
            │    ├─ enforceFighterTether()                // 只重建 _tetherPrev
            │    ├─ camera.render()                       // ← 唯一每帧入口
            │    │    ├─ renderMulti() | solo 分支        // 算 _point、算 _zoom
            │    │    ├─ renderX() / renderY()            // 算目标 _rect.x/y（带缓动）
            │    │    ├─ renderZoom()                     // 推进 _stageScale，刷新 _rect.w/h
            │    │    ├─ keepFocusInFrame()                // 视口兜底 + 边界钳制
            │    │    └─ applySet()                       // 写 _displayRect → stage.scrollRect、stage.scale
            │    ├─ gameUI.render()
            │    └─ _map.render(-screenRect.x, -screenRect.y, camera.getZoom(true))  // 图层视差
            └─ _mainLogicCtrl.render()                    // 角色 AI / 移动 / 判定
```

三条可以从代码直接读出的事实：

1. **相机先于角色更新**。`GameState.render()` 在 `GameCtrl.render()` 前半段，角色位移在 `_mainLogicCtrl.render()` 里；因此相机每帧跟的是**上一帧**的角色坐标，恒定 1 帧延迟。
2. **地图视差吃的是相机输出**。`MapMain.render(param1,param2,param3)` 收到的就是 `-screenRect.x/-screenRect.y`，`frontLayer.x = param1 * 0.1 + _defaultFrontPos.x`——前景层只走相机位移的 10%。
3. **HUD 不在相机里**。`gameUI.getUIDisplay()` 挂在 `GameState` 上，不挂在 `_gameLayer` 上；因此相机平移/缩放/震动都**不影响 HUD**。

### 3.3 数据流（谁喂给相机，相机喂给谁）

```text
角色 MC.x/.y ──┐
               ├─→ GameCamera._focus[] ─→ renderMulti() ─→ _point(中心)
地图尺寸 ──────┘                                  │
   MapMain.getStageSize() ─→ GameCamera.stageSize │
   setStageBounds(Rectangle) ─→ _stageBounds ─→ _fbR(钳制范围)
                                                  ↓
                                   _zoom ─→ _stageScale ─→ stage.scaleX/Y
                                     │                        ↑
                                     └→ _rect(w/h = screen/scale)
                                                  ↓
                        _displayRect ─→ stage.scrollRect ─→ 玩家看到的画面
                                                  ↓
                    getScreenRect(true) ─→ MapMain.render()（视差）
                                        ─→ GameCtrl（换人入场点、特效定位）
                                        ─→ GameState.getGameSpriteGlobalPosition()
```

### 3.4 两个坐标空间，别混

| 量 | 空间 | 依据 |
|---|---|---|
| `_rect.x` / `_rect.y` | **世界坐标**（与角色 `.x/.y` 同一空间） | `renderX()` 用 `focus.x - _screenSize.x/2/_zoom`，即「焦点世界坐标 − 半屏世界宽度」 |
| `_rect.width` / `_rect.height` | 世界单位 | `_screenSize.x / _stageScale` |
| `stage.scrollRect` | 局部坐标，但因为直接等于 `_displayRect`（世界值），所以实际按世界值用 | `applySet()` 直写 |
| `stage.scaleX/scaleY` | 纯倍率 | `applySet()` |
| `_fbR.x/_fbR.y` | 世界坐标 **乘过 `_zoom`** | `setZoom()` 内 `_stageBounds.x * _zoom` |

---

## 4. 关键机制逐条拆解

> 本节覆盖问题清单的 1~8：4.1→Q1（归属与调用链）、4.2→Q2（公开成员全表）、4.3~4.5→Q3+Q5（缩放算法与手感）、4.6~4.7→Q4（跟随与钳制）、4.8→Q6（震动）、4.9→Q7（stageSize 来源）、4.10~4.14→Q8（三件套职责与拆分理由）。
> Q9（逐能力对照表）在 §6.1，Q10（移植后果）在 §6.2~§6.3。

### 4.1 实例归属与每帧入口（问题 1）

**结论**：实例；由 `GameState` 持有；每帧由 `GameState.render()` 调用；调用顺序见 3.2。

**代码引用**：`state/GameState.as:GameState.initCamera()`、`state/GameState.as:GameState.render()`、`state/GameState.as:GameState.destory()`。

**为什么这么做**：相机不 new 显示对象，只改容器属性，所以「相机对象」和「画面」是解耦的——一个容器可以换任意多个相机实例而不用重建显示树；`GameState.destory()` 只需 `camera = null` 就能断开全部引用。

`initCamera()` 建立相机后的完整初始化序列（顺序有意义，逐句都对得上代码）：

| 步 | 语句 | 效果 |
|---|---|---|
| 1 | `new GameCamera(_gameLayer,GameConfig.GAME_SIZE,stageSize,true)` | `_screenSize=(800,600)`，第 4 参 `true` 才创建 `_fbR`（**钳制框**） |
| 2 | `camera.focusX = true; camera.focusY = true` | 双轴跟随（`focusY` 类默认是 `false`） |
| 3 | `camera.offsetY = _map.getMapBottomDistance()` | 把「角色地面线」抬到屏幕中下 |
| 4 | `camera.setStageBounds(new Rectangle(0,-1000,stageSize.x,stageSize.y))` | 覆盖自动测得的容器 bounds，顶部多给 1000 世界单位余量 |
| 5 | `camera.autoZoom = true` | 开启按包围盒反推缩放 |
| 6 | `camera.setCloseZoom(GameCamera.zoomForLevel(config.cameraDistLevel))` | 把「镜头距离」档位翻译成 min/max 缩放区间 |
| 7 | `camera.tweenSpd = 2.5 / GameConfig.SPEED_PLUS_DEFAULT` | 位置缓动除数（`SPEED_PLUS_DEFAULT = 30/FPS_GAME`，FPS_GAME=60 ⇒ **5**） |
| 8 | `camera.setZoom(autoZoomMin)` → `setX(-camX)` → `setY(-camY)` → `updateNow()` | 把画面直接摆到开局位置并跳过缓动 |

### 4.2 公开字段与方法全表（问题 2）

字段（名字与默认值逐字核对自 `state/GameCamera.as` 的声明）：

| 字段 | 类型 | 初值 | 语义 | 谁写它 |
|---|---|---|---|---|
| `DISTANCE_ZOOMS` | `static const Array` | `[1.8,2.3,2.8,3.4]` | 镜头距离四档的缩放值 | 常量 |
| `tweenSpd` | `int` | 0（未显式初始化） | 位置缓动除数，越大越慢 | `GameState.initCamera()`（5）、`GameCtrl.slow()`、`GameState.cameraFocusOne()`、`GameState.cameraResume()` |
| `stageSize` | `Point` | ctor 第 3 参；缺省时由 `setStageSizeFromDisplay()` 推 | 舞台（地图）尺寸，**类内只有 `moveCenter()` 读** | ctor |
| `focusX` | `Boolean` | `true` | 是否跟随 X | `initCamera()` |
| `focusY` | `Boolean` | `false` | 是否跟随 Y | `initCamera()` 置 `true` |
| `offsetX` | `Number` | 0 | 焦点 X 偏移（世界单位），**3.7 全文无人写** | — |
| `offsetY` | `Number` | 0 | 焦点 Y 偏移，会被 `focusOffsetScale()` 乘（单焦点且带缩放时才乘） | `initCamera()`；3.7 `ctrl/EffectCtrl.as` 做必杀缩放时存/恢复原值 |
| `autoZoom` | `Boolean` | `false` | 是否每帧按包围盒重算 `_zoom` | `initCamera()`、`cameraResume()`、`EffectCtrl`（开场结束恢复） |
| `autoZoomMin` | `Number` | **1.5** | 自动缩放的下界（视角最远） | `setCloseZoom()` |
| `autoZoomMax` | `Number` | **5** | 自动缩放的上界（视角最近） | `setCloseZoom()` |
| `zoomMaxRatio` | `Number` | 1.25 | `setCloseZoom()` 内 `max = min * ratio` | 无外部写入 |
| `zoomHardMinRatio` | `Number` | 0.6 | `renderAutoZoom()` 的硬下界倍率 | 无外部写入 |
| `framePaddingX` | `Number` | 0.045 | 左右留白，按屏宽比例 | 无外部写入 |
| `frameHeadroom` | `Number` | 0.2 | 顶部留白，按屏高比例 | 无外部写入 |
| `frameFootroom` | `Number` | 0.03 | 底部留白 | 无外部写入 |
| `keepFocusInView` | `Boolean` | `true` | 是否启用 `keepFocusInFrame()` | 无外部写入 |
| `shakeEnabled` | `Boolean` | `true` | 震屏总开关 | `shake()` 与 `applySet()` 都判它 |
| `maxShakeOffset` | `Number` | 24 | 最大位移振幅（世界单位） | 无外部写入 |
| `maxShakeZoom` | `Number` | 0.05 | 最大缩放振幅 | 无外部写入 |
| `traumaDecay` | `Number` | 0.035 | 每帧 trauma 线性衰减量 | 无外部写入 |
| `punchZoomStiffness` | `Number` | 0.22 | 冲击缩放弹簧刚度 | 无外部写入 |
| `punchZoomDamping` | `Number` | 0.62 | 冲击缩放弹簧阻尼 | 无外部写入 |
| `soloAutoZoom` | `Boolean` | `false` | 单人聚焦时也自动缩放（否则单人保持当前倍率） | 只有 `mosou_ctrls/MosouCtrl.as` 写 |
| `soloZoomRatio` | `Number` | 0.9 | 单人自动缩放的相对倍率 | 无外部写入 |
| `scaleAwareFocus` | `Boolean` | `true` | 留白是否按角色缩放系数放大 | 无外部写入 |
| `maxMarginScale` | `Number` | 3 | 上述放大系数的上限 | 无外部写入 |

**为什么这么多参数都是 `public`**：3.7 把它们当「逐地图 / 逐模式的调参旋钮」，但真正有外部写入点的只有 `autoZoomMin/Max`（`setCloseZoom()`）、`soloAutoZoom`（`MosouCtrl`）、`offsetY`（`initCamera()` 与 `EffectCtrl`）；本表最后两列已逐个标注「无外部写入」，读代码时不要把「可写」当成「会变」。

方法（全量，含 private，因为 private 才是算法本体）：

| 方法 | 可见性 | 做什么 |
|---|---|---|
| `zoomForLevel(int):Number` | static | 档位→缩放，越界被夹进 `[0, 3]` |
| `setCloseZoom(Number)` | public | `autoZoomMin = v; autoZoomMax = v*zoomMaxRatio` |
| `getMaxFighterDistance():Number` | public | 按 `autoZoomMin` 反算「同屏能容纳的角色间距」；**全树无调用者** |
| `effectiveZoom(Number):Number` | private | 按角色缩放系数把缩放「放宽」，见 4.5 |
| `closeUpZoom`（getter） | public | `max(autoZoomMax*1.35, 3.5)` 再经 `effectiveZoom` |
| `closeUpZoomFor(Number)` | public | 同上但除以角色 `scale`，并夹到 `cameraMinZoom` |
| `closeUpZoomForTarget(Object)` | public | 取 `FighterScaleModel.I.scaleOfTarget()` 后转调；**全树无调用者** |
| `marginScaleOf(Object):Number` | private | 取对象缩放系数并夹到 `maxMarginScale` |
| `updateFocusScales()` | private | 统计 `_scTop`（最大系数）与 `_scL/_scR`（最左/最右者的系数） |
| `focusOffsetScale():Number` | private | 单焦点时返回该焦点系数，否则 1 |
| `getScreenRect(Boolean)` | public | `true` 返回 `_displayRect`（含抖动），`false` 返回 `_noTweenRect`（目标） |
| `updateNow()` / `applyInstant()` | public / private | 临时把 `tweenSpd=0` 与 `_zoomTweenSpdOverride=-1` 后跑一次 `render()`，再还原 |
| `setStageBounds(Rectangle=null)` | public | 无参时取 `_stage.getBounds(_stage)`；随后 `setZoom(_zoom)` 重算 `_fbR` |
| `setStageSizeFromDisplay(DisplayObject)` | public | 由容器宽高推 `stageSize`（**依赖 `_stageBounds`，见 §5**） |
| `getZoom(Boolean)` / `setZoom(Number)` | public | 读 `_zoom`/`_stageScale`；写 `_zoom` 并重算视口尺寸、半屏偏移、`_fbR` |
| `zoomTweenSpd`（get/set） | public | 缩放专用缓动除数；`>=0` 时覆盖 `tweenSpd` |
| `resetZoomTweenSpd()` | public | 把覆盖值复位为 `-1` |
| `isCinematic` / `setCinematicLock(Boolean)` | public | 电影锁读写；置 `true` 时顺手 `resetZoomTweenSpd()` |
| `focusCount`（getter） | public | `_focus` 长度 |
| `isFocusing(Array)` | public | **引用相等**比较 `_focus == list` |
| `focusAt(int)` | public | 取 `_focus[i]`，越界返 `null` |
| `trauma`（getter） | public | 读 `_trauma`（诊断用） |
| `focus(Array, Boolean=false)` | public | 设焦点；`_focus.length>1` 时新建 `_point`，否则 `_point=null`；`true` 立即生效 |
| `move(Number,Number)` / `moveCenter()` | public | 清空焦点，改跟固定点（后者用 `stageSize/2`） |
| `shake(Number)` / `punchZoom(Number)` / `impact(Number=0.5)` | public | 见 4.8 |
| `render()` | public | 每帧总入口 |
| `keepFocusInFrame()` | private | 视口兜底 + `_fbR` 钳制，见 4.7 |
| `applySet()` | private | 衰减 trauma、推进弹簧、算抖动、写 `_displayRect`/`scrollRect`/`scale` |
| `updateTrauma()` / `updatePunchSpring()` | private | 见 4.8 |
| `renderMulti()` | private | 多焦点：包围盒中心 + 双轴缩放需求 |
| `renderAutoZoom(Number)` | private | 夹范围后 `setZoom()` |
| `renderX()` / `renderY()` | private | 目标 `_rect.x/y` = 焦点 − 半屏 − offset |
| `setX(Number)` / `setY(Number)` | public | 钳制后按 `tweenSpd` 缓动推进 `_rect` |
| `renderZoom()` | private | 按 `zoomTweenSpd` 推进 `_stageScale`，刷新 `_rect.w/h` |

### 4.3 视口尺寸、半屏偏移与钳制框的三联计算

**结论**：`setZoom()` 一改三样东西——视口尺寸、半屏偏移、钳制边界。

**代码引用**：`state/GameCamera.as:GameCamera.setZoom()`。

```text
_noTweenRect.w/h = _screenSize.x|y / _zoom        // 目标视口（世界单位）
_foffsetX/Y      = _screenSize.x|y / 2 / _zoom    // 半屏偏移
_fbR.x/y         = _stageBounds.x|y * _zoom       // 钳制下界（注意乘了 zoom）
_fbR.w/h         = _stageBounds.w|h - _screenSize.x|y / _zoom  // 钳制上界
```

**为什么这么做**：`_foffsetX/_foffsetY` 让「焦点居中」退化成一次减法（`renderX()` 只做 `焦点 - 半屏`），避免每帧算矩阵；`_fbR` 预先把边界换算好，`setX/setY` 和 `keepFocusInFrame()` 里就只剩比较。

**注意**：`_fbR.width/height` 存的是「最大 x/y」而不是宽度/高度——这是 3.7 与主项目共有的命名噪音，读代码时极易误解。

### 4.4 跟随：双轴开关 + 缓动除数

**结论**：`focusX`/`focusY` 是**独立的轴开关**，关掉的轴当帧完全不写，画面停在上一帧位置。

**代码引用**：`state/GameCamera.as:GameCamera.render()`、`GameCamera.renderX()`、`GameCamera.renderY()`。

```text
render()：
  if(!_focus && !_point) return;      // 没焦点也没固定点 → 一个字节都不写
  ...算 _point / _zoom...
  if(focusX) renderX();
  if(focusY) renderY();
  if(_stageScale != _zoom) renderZoom();
  keepFocusInFrame();
  applySet();
```

- `focusX=true, focusY=false`（类默认）：横版卷轴，纵向定死。
- 3.7 的 `initCamera()` 把两个都设 `true`，靠 `offsetY = getMapBottomDistance()` 把纵向拉回地面附近；纵向真正能动的范围见 4.7。
- `offsetX/offsetY` 是**世界单位**的偏置，直接加在目标位置里：`target = focus - 半屏 - offset`。`offsetY` 还会被 `focusOffsetScale()` 放大（单焦点 + `scaleAwareFocus` 时），让高个子角色多留头部空间。
- `renderY()` 与 `renderX()` 唯一差别就是这一层乘子；其余逐行相同。

**tweenSpd 的单位（问题 5）**：不是「每秒多少像素」，也不是「第几阶缓动」，而是**指数逼近的除数**：

```text
_rect.x += (target - _rect.x) / tweenSpd     // tweenSpd > 1
_rect.x  = target                            // tweenSpd <= 1（直接吸附）
```

- 单位是「帧」，与 FPS 强耦合；`tweenSpd=5` 每帧消掉 20% 误差，约 14 帧剩 5%。
- 因字段是 `int`，写 2.5 会被截成 2、写 1.6 会被截成 1（见 §5）。
- **无死区**：`setX/setY` 没有 epsilon，误差永远按比例缩小但不归零；视觉上 ≤1 世界单位时已不可辨。
- 真正带「死区」语义的是 `keepFocusInFrame()` 的留白：只要焦点在留白框内，它一次都不改 `_rect`。

### 4.5 缩放算法：三处入口、一条夹取链（问题 3）

**结论**：`DISTANCE_ZOOMS` 只用来**定档**（把 0~3 档翻成一个缩放值），不参与插值；运行时缩放是连续量，由包围盒反推，再被 `[硬下界, autoZoomMax]` 夹住。

**代码引用**：`state/GameCamera.as:GameCamera.zoomForLevel()`、`GameCamera.setCloseZoom()`、`GameCamera.renderMulti()`、`GameCamera.renderAutoZoom()`、`GameCamera.effectiveZoom()`、`GameCamera.renderZoom()`。

三步串起来：

**① 定档 → 区间**（一次性，`initCamera()` 里调）

```text
zoomForLevel(level) = DISTANCE_ZOOMS[clamp(level,0,3)]     // 1.8 / 2.3 / 2.8 / 3.4
setCloseZoom(v)     → autoZoomMin = v;  autoZoomMax = v * 1.25
```

档位来自配置：`data/ConfigVO.as` 的 `cameraDistLevel`（默认 **2** ⇒ min 2.8 / max 3.5），由 `ui/OptionsData.as` 暴露成 4 选项菜单 `Far / Normal / Close / Very Close`。

**② 每帧反推**（只在 `_focus.length > 1` 时跑）

```text
_xZoom = screenW / (bboxW + (scL+scR) * framePaddingX * screenW)
_yZoom = screenH / (bboxH + (headroom*scTop + footroom) * screenH)
candidate = min(_xZoom, _yZoom)         // 取更小的 = 更远的视角，保证两个都装得下
```

**③ 夹取 + 缓动**

```text
renderAutoZoom(v):
  lo = effectiveZoom(autoZoomMin * zoomHardMinRatio)   // 默认 2.8*0.6 = 1.68
  hi = effectiveZoom(autoZoomMax)                      // 默认 3.5
  cm = FighterScaleModel.I.cameraMaxZoom
  if(cm > 0){ hi = min(hi, cm);  lo = min(lo, hi) }    // 两个方向都夹，防 lo > hi
  v  = clamp(v, lo, hi);  setZoom(v)
```

而 `effectiveZoom(v)` 做的是「角色被放大过，镜头就按同比例放宽」：

```text
div = FighterScaleModel.I.cameraDivisor        // = 本局最大角色缩放系数，未启用时为 1
if(div<=0||div==1||div==Inf) return v
z = v / div;  z = max(z, cameraMinZoom/*恒 1*/);  z = min(z, v)
```

`renderZoom()` 才是真正落到容器上的那一步，并且**拉远快、推近慢**：

```text
spd = zoomTweenSpd                       // 默认 = tweenSpd
if(_zoom < _stageScale && !_cinematicLock && spd > 2) spd = 2;   // 拉远最快用 2
_stageScale += (_zoom - _stageScale) / spd;   // spd<=1 时直接吸附
```

**缩放专用缓动的唯一外部写入点**：`GameState.cameraFocusOne()` 里 `camera.zoomTweenSpd = 1.6 / GameConfig.SPEED_PLUS_DEFAULT`（`1.6/0.5 = 3.2` → `int` 截断为 **3**），随后 `camera.tweenSpd = 2.5 / SPEED_PLUS_DEFAULT`。也就是说特写时「位置缓动 5、缩放缓动 3」——缩放比位置先到位。`cameraResume()` 与 `setCinematicLock(true)` 都会调 `resetZoomTweenSpd()` 把这个覆盖清掉，回到与位置同速。

**autoZoom 与手动档位谁优先**：

| 情形 | 谁生效 | 依据 |
|---|---|---|
| `autoZoom = false` | 只有 `setZoom()` 的显式值 | `renderMulti()` 的 `if(autoZoom)` 整块跳过 |
| `autoZoom = true` 且 2 人以上 | 包围盒反推，**但被档位区间夹住** | `renderAutoZoom()` 的 clamp |
| `autoZoom = true` 且单人 | 什么都不做（保持当前 `_zoom`），除非 `soloAutoZoom` | `render()` 的 `else if(soloAutoZoom ...)` |
| 任何情形下 `setCinematicLock(true)` | 单人缩放分支与留白钳制都被跳过 | 两处 `_cinematicLock` 判断 |

也就是说：**档位是「夹子」，不是「设定值」**。手动 `setZoom()` 只在下一帧多焦点计算前有效；而 `GameState.cameraResume()` 会把 `autoZoom` 重新置 `true`，手动关闭自动缩放无法跨过 `cameraResume()` 存活。

### 4.6 留白钳制：keepFocusInFrame()（问题 4 的一半）

**结论**：这是「焦点不许被切出画面」的兜底，按三条分支改 `_rect.x`（纵向同理），且在 `_rect` 上**硬写**，不缓动。

**代码引用**：`state/GameCamera.as:GameCamera.keepFocusInFrame()`。

```text
viewW = screenW / _stageScale
padL  = framePaddingX*screenW*_scL ; padR = framePaddingX*screenW*_scR
若 bboxW + padL + padR >= viewW :  _rect.x = 中心 + (padR-padL)/2 - viewW/2   // 装不下 → 居中
否则若 _rect.x > minX - padL   :  _rect.x = minX - padL                     // 左边界越界 → 顶住
否则若 _rect.x + viewW < maxX + padR : _rect.x = maxX + padR - viewW        // 右边界越界 → 顶住
```

**为什么这么做**：`renderX()` 永远把焦点摆正中，视觉上「死板」；`keepFocusInFrame()` 把居中改成「先居中、越界才顶」，观感更接近人工运镜。它同时是**纵向唯一的有效约束**（因为 `focusY` 的居中会让角色贴屏幕中线，而地面/天际线并不在中线）。

**留白分工**：横向左右各 4.5% 屏宽；纵向上方 20% 屏高（`frameHeadroom`，给跳跃/浮空）、下方 3% 屏高（`frameFootroom`，脚下几乎不留给空）。顶部留白又乘 `_scTop`（最大角色缩放系数），所以放大过的角色头顶空间同比变大。

### 4.7 地图边界钳制公式（问题 4 的另一半）

**结论**：边界钳制发生在**两个地方**——`setX/setY` 入口（软钳制）与 `keepFocusInFrame()` 末尾（硬钳制），两处用的是同一个 `_fbR`。

**代码引用**：`state/GameCamera.as:GameCamera.setX()`、`GameCamera.setY()`、`GameCamera.setZoom()`、`GameCamera.keepFocusInFrame()`。

代入 `initCamera()` 的实际参数（`_stageBounds = (0,-1000,mapW,600)`、`_screenSize = (800,600)`、缩放 `z`）：

| 轴 | 允许区间 | 代入后 |
|---|---|---|
| x | `[_stageBounds.x*z, _stageBounds.width - 800/z]` | `[0, mapW - 800/z]` |
| y | `[_stageBounds.y*z, _stageBounds.height - 600/z]` | `[-1000z, 600 - 600/z]` |

三点可读出的行为：

1. **x 轴无余量**：左边界恰好是 0，右边界恰好让最后 800/z 个世界单位贴住地图右沿——标准横版卷轴。
2. **y 轴几乎不能动**，除非拉近：`z=1` 时上界 `600-600=0`、下界 `-1000`；`z=2` 时上界 `600-300=300`。也就是「只有拉近之后纵向才有运镜空间」。
3. **y 下界乘了 `z`**（`_stageBounds.y * _zoom`），与 x 的写法不对称。`_stageBounds.y=-1000` 时下界随缩放变成 `-1800 ~ -3400`，即上方多留的空白随缩放变大。这是 3.7 与主项目**完全相同**的写法，不是本册笔误（见 §5 与 §7）。

### 4.8 震屏与打击反馈（问题 6）

**结论**：3.7 有**两套并存**的震动：`GameCamera` 内的 trauma+弹簧（只动世界层），和 `EffectCtrl` 的整屏位移（连 HUD 一起动）。且 3.7 的相机震动**不在每次命中触发**，只在换人演出与回合结束时触发。

**代码引用**：`state/GameCamera.as:GameCamera.shake()`、`punchZoom()`、`impact()`、`updateTrauma()`、`updatePunchSpring()`、`applySet()`；调用侧 `state/GameState.as:GameState.shakeCamera()`、`ctrl/game_ctrls/GameCtrl.as:GameCtrl.cameraImpact()`。

**剂量与衰减**

```text
shake(t):   _trauma = min(1, _trauma + t); 重掷两个随机相位种子
impact(t):  t = clamp(t,0,1);  shake(0.3 + t*0.7);  punchZoom(0.05 + t*0.22)
updateTrauma():  _trauma -= 0.035  每帧一次，到 0 止
```

trauma=1 起算，29 帧（60fps 下约 0.48s）归零。

**位移曲线**（`_trauma` 取平方，所以是「快起慢收」）

```text
a = _trauma * _trauma
dx = 24 * a * (sin(t*2.3+sx)*0.6 + sin(t*4.1+sx*1.7)*0.4)
dy = 24 * a * (sin(t*2.7+sy)*0.6 + sin(t*3.3+sy*1.9)*0.4)
dz = 0.05 * a * sin(t*5.2+sx+sy)          // 缩放抖动
```

两个正弦叠加（0.6/0.4 权重）+ 每帧 `_shakeTime+1` 作相位，所以是**连续噪声式的抖动**，不是固定频率摇晃；两个种子在构造时与每次 `shake()` 时重掷，避免每次震屏完全同形。

**冲击缩放**（半隐式欧拉，欠阻尼弹簧）

```text
vel += (-0.22 * offset - 0.62 * vel)
offset += vel
if(|offset| < 0.0008 && |vel| < 0.0008) offset = vel = 0
```

由常量算得阻尼比 `ζ = 0.62 / (2*√0.22) ≈ 0.66`（这是代数结果，不是实测），故会回弹一次再收敛；`punchZoom(x)` 只是往 `vel` 里加初速。

**最终写屏**

```text
_displayScale = _stageScale + _punchZoomOffset + dz      // 下限 0.05
_displayRect.x = _rect.x + dx ; .y = _rect.y + dy
_displayRect.w/h = (screen/scale + 1) >> 0
_stage.scrollRect = _displayRect ; _stage.scaleX = _stage.scaleY = _displayScale
```

**触发点（全树只此三处）**

| 位置 | 参数 | 场景 |
|---|---|---|
| `GameCtrl.cameraImpact(0.25)` | trauma≈0.475、punch≈0.105 | TAG 换人起手 |
| `GameCtrl.cameraImpact(0.35)` | trauma≈0.545、punch≈0.127 | TAG 换人落地 |
| `GameState.shakeCamera(1)` | trauma=1、punch=0.27 | 回合结束（`GameCtrl` 判胜负分支） |

`GameState.shakeCamera()` 还有一道门：`!EffectCtrl.I.fxHeavyGate()`——性能模式或自适应判定为中等/重度负载时**整段不震**（`fxHeavyGate()` = `PERFORMANCE_MODE || AdaptiveEngine.I.isMedium || isHeavy`）。

**与旧的整屏震动的关系**：`EffectCtrl.shake(x,y,ms)` 改的是 `_gameStage.x/.y`，即把整个 `GameState`（含 HUD）挪位，逐帧按 `_shakeLose` 递减并隔帧反号。两套机制互不知情，同时触发会叠加。3.7 的命中特效走的是旧的这套（`fighter/Bullet.as`、`fight/FightUI.as` 调 `EffectCtrl.I.shake`）。

### 4.9 stageSize 从哪来（问题 7）

**结论**：相机自己不测地图；`stageSize` 由 `MapMain.getStageSize()` 提供，且**只用于 `moveCenter()`**。真正决定取景范围的是 `setStageBounds()` 传进来的矩形。

**代码引用**：`map/MapMain.as:MapMain.getStageSize()`、`map/JsonMapMain.as:JsonMapMain.getStageSize()`、`state/GameState.as:GameState.initCamera()`。

| 地图类型 | `getStageSize()` 返回 | 高度来源 |
|---|---|---|
| 普通 SWF 地图 | `new Point(mapLayer.width, GameConfig.GAME_SIZE.y)` | 恒定 `GAME_SIZE.y = 600` |
| JSON（MUGEN）地图 | `new Point(_stageWidth, GameConfig.GAME_SIZE.y)` | 同上 |

JSON 地图的 `_stageWidth` 在 `JsonMapMain.initByJSON()` 里算：

```text
_lsx = 800 / localcoord[0]              // localcoord 缺省 [1280,720]
viewZoom = min(cameraZoomMin>0?cameraZoomMin:1, minGameZoom/*默认 1*/)
halfSpan = 800 * 0.5 / viewZoom
_stageWidth = (boundright - boundleft) * _lsx + halfSpan * 2
```

其中 `boundleft/boundright` 取自 `stage.json` 的 `camera` 段（缺省 -500/500），`camera.zoomout/zoomin/startzoom` 一并读出为 `cameraZoomMin/Max/StartZoom`。同时算出 `camLimitLeft/camLimitRight`（相机软限位，供 `JsonMapMain` 自身与 AJ 逻辑使用，不进 `GameCamera`）。

纵向同理：`playerBottom = zoffset * _lsy`（`zoffset` 缺省 320 ⇒ `266.7`），`bottom = max(600, playerBottom)`。`GameState.initCamera()` 里 `offsetY = _map.getMapBottomDistance()` = `bottom - playerBottom`，JSON 地图即 `600 - 266.7 = 333.3`；这一步把「角色脚线」压在屏幕下三分之一处，而不是正中。

普通地图走 `MapMain.initlize()`：从 `map` 元件里取四个标记元件 `line_left / line_right / line_bottom / line_player_bottom`，并整体做一次 `_loc2_ = GAME_SIZE.y - bottom` 的纵向归一，使 `bottom` 恰好等于 600；`getMapBottomDistance()` 返回归一前后的 `bottom - playerBottom`（差值不变）。

### 4.10 3.7 的换人聚焦：swapFighterFocus 与 survivor（问题 8 的 3.7 侧）

**结论**：3.7 有 TAG，但没有独立 TAG 控制器；换人时**原地替换数组元素**（保持数组引用不变），因此相机不重新 `focus()`、倍率不重置。

**代码引用**：`state/GameState.as:GameState.swapFighterFocus()`、`GameState.setupSurvivorFocus()`、`GameState.rebuildTrackedFocus()`、`GameState.updateSurvivorFocus()`；调用侧 `ctrl/game_ctrls/GameCtrl.as:GameCtrl.renderTag()` 分支内。

两种机制：

1. **换人（TAG）**：`swapFighterFocus(oldF,newF,g1,g2)` 找到 `oldF.getDisplay()` 在 `_cameraFocus` 里的下标，**赋值为新 display**。数组引用不变 ⇒ `GameCamera._focus` 同一份 ⇒ 相机下一帧自动跟新人，`_zoom` 不动。
2. **存活者重建（2v2 / 1v2）**：`setupSurvivorFocus()` 把双方存活成员记进 `_focusGroupP1/P2`，并令 `_managedFocus = _cameraFocus`（**同一引用**）；`rebuildTrackedFocus()` 每次把 `_managedFocus` 内容 `length=0` 后重填存活者。于是 `GameState.updateSurvivorFocus()` 每帧都能在「不换数组、不重设 zoom」的前提下改焦点集合；`camera.isCinematic` 或 `!GameCtrl.I.actionEnable` 时整段跳过。

而 `isFocusing(list)` 是引用比较，所以这套「保持同一数组」的做法同时让 `cameraDrifted()` 的判据成立（引擎不会把自己的维护误判成「镜头被抢」）。

**换人入场点的计算依赖相机输出**：`GameCtrl` 取 `camera.getScreenRect(true)`，把入场角色放到 `view.x - 80` 或 `view.x + view.width + 80`（屏幕外），落地位置再夹进 `[view.x+60, view.x+view.width-60]`。这是「相机接口被玩法代码消费」的最直接例子。

### 4.11 3.7 没有看门狗，但有三道等效保险

**结论**：3.7 没有 `GameCameraFocusWatch` 这个类，特写镜头的收尾全靠 `EffectCtrl` 内部的三道自检。

**代码引用**：`ctrl/EffectCtrl.as:EffectCtrl.checkCameraLockLeak()`、`EffectCtrl.fxHeavyGate()`、`state/GameState.as:GameState.cameraDrifted()`。

| 保险 | 判据 | 动作 |
|---|---|---|
| 锁泄漏 | `camera.isCinematic` 连续 >30 帧，且不在必杀/动态镜头/开场/收尾里 | `cameraResume()` |
| 开场/收尾锁泄漏 | `_introLockActive`/`_outroLockActive` 且战斗已可操作超过 `INTRO_LEAK_SECONDS` | `forceEndIntro()` / `forceEndOutro()` |
| 镜头漂移 | `!camera.isFocusing(_cameraFocus)` 或（多人时）`!autoZoom` 或 `zoom > autoZoomMax+0.01` | `cameraResume()`（受 `sceneBusy/_dynCamActive/_introLockActive/...` 门控） |

这三道都是**按帧计数 + 状态标志**，不看角色帧标签、也不看黑幕是否还在——这正是主项目后来要补 `GameCameraFocusWatch` 的原因：角色包漏调 `endBisha()` 时，3.7 只有 30 帧超时这一条路（`_lockLeakFrames > 30`）能把镜头拉回，而角色包若在同一帧之后又调 `focus()`，拉回的结果会被下一次 `focus()` 直接覆盖。

### 4.12 主项目三件套：各自管什么、为什么拆（问题 8）

**结论**：三件套里没有一行新几何算法，全部是「归属、入口、追责」。

**代码引用**：`主项目 ctrl/game_ctrls/GameCameraCtrler.as`、`主项目 fighter/ctrler/FighterCameraCtrler.as`、`主项目 state/GameCameraFocusWatch.as`。

| 类 | 管什么 | 不管什么 | 关键成员 |
|---|---|---|---|
| `GameCameraCtrler` | 语义化门面：`setCamera/getCamera/destory/setTweenSpd/getTweenSpd/setStageSize/setFocusX/setFocusY/setOffsetX/setOffsetY/setAutoZoom/setAutoZoomMin/getAutoZoomMin/setAutoZoomMax/getScreenRect/updateNow/setStageBounds/setStageSizeFromDisplay/getZoom/setZoom/focus/move/moveCenter/setX/setY`，每个方法都以 `if(!this._camera) return` 开头 | 任何策略、任何默认值决策 | `_camera` |
| `FighterCameraCtrler` | 角色级入口：`setTarget/getTarget/focusSelf/focusTarget`，并把 `IGameSprite` 转成 `getDisplay()` 后再交给相机 | 不碰 `_cameraFocus`、不碰 zoom | `_target:IGameSprite` |
| `GameCameraFocusWatch` | 必杀特写撤销看门狗：`tick()` 每帧跑，四条判据任一成立即 `release()` → 回调 `GameState.cameraResume` | 不接管人物包自己摆的镜头（只看 `focusOwner == FOCUS_OWNER_BISHA`） | `_frames/_labelLeft/_blackGone/_cooldown/_labelReleased` |

**为什么必须拆三个**（每条都有代码依据）：

1. **角色包比相机先存在**。`FighterCtrler` 构造函数里就 `new FighterCameraCtrler(null)`，`initFighter()` 把这个句柄塞进角色包（`{fighter_ctrler, mc_ctrler, effect_ctrler, camera_ctrler}`），而相机要到 `GameState.initCamera()` 才创建，随后由 `bindCameraToFighters()` 回填。所以门面**必须容忍 `_camera == null`**——这是三件套里唯一硬性的工程约束。
2. **外部人物包只能看到门面**。人物包帧脚本写的是 `parent.$fighter_ctrler.getCameraCtrler().focusSelf()`；裸调 `GameState.camera.focus()` 属于「老人物包兼容路径」，仍然可用但没人收尾。
3. **追责需要 owner**。`GameCamera.focus(Array, Boolean, String)` 多了第三个参数 `owner`；`cameraFocusOne()` 打 `FOCUS_OWNER_ENGINE`，`cameraFocusBisha()` 打 `FOCUS_OWNER_BISHA`，人物包直调时为 `null`。`GameCameraFocusWatch.tick()` 首件事就是 `if(_camera.focusOwner != FOCUS_OWNER_BISHA) resetState()`——没有 owner 就没有「谁该被撤销」。
4. **撤销必须在 `camera.render()` 之前**。`GameState.render()` 里 `_cameraFocusWatch.tick()` 写在 `camera.render()` 前面，注释明确写了原因：撤销改的是 `focus` 数组，同一帧就要生效。
5. **黑幕探针不能反向依赖**。`EffectCtrl.initlize()` 把 `isBlackBackShowing` 注册进 `GameState.bishaBlackProbe`，`GameState.probeBlackBack()` 再转成看门狗的第 3 个构造参数。这样 `state` 层不 import `ctrl` 层。
6. **TAG 换人要有唯一重建点**。主项目把 TAG 拆成 `ctrl/game_ctrls/TagModeCtrler.as`，换人后调自己的 `updateCameraFocus()`：从 `gameRunData` 的两个 `currentFighter` 重建**恰好 2 元素**的数组，再走 `GameState.updateCameraFocus(array)`（`focus(array, false, ENGINE)` + `setZoom(_cameraDefaultZoom)`）。与 3.7 的「原地替换、不动 zoom」相反：主项目换人后倍率**归位到 2**。
7. **GPU 滤镜代理只认 scrollRect**。`GameState` 在 `initFight()` 里 `FilterProxyManager.I.registerRoot(this)`，并把 HUD 子树 `excludeSubtree(gameUI.getUIDisplay())`。代理烘焙时 `FilterNodeProxy.computeBounds()` 对带 `scrollRect` 的目标**直接返回 scrollRect**（注释点名「战斗相机作用在 _gameLayer 上」）；而 `FilterNodeProxy.displayScale()` 用 `concatenatedMatrix` 取倍率，注释点名「父链的 `_gameSprite`(≈1.8) 与相机 zoom 全在里面」，并**量化到 0.25 步长**，理由正是「相机 zoom 是逐帧插值的」。相机因此被约束成一个**只写几何、不写滤镜、不换容器**的角色。

### 4.13 主项目的每帧顺序差异

**为什么这个顺序动不得**：`GameState.render()` 在 `camera.render()` 之后立刻把 `camera.getScreenRect(true)` 交给 `_map.render()`，同帧的地图视差必须与本帧视口一致；把 `camera.render()` 挪到后面，地图就会用上一帧的视口画视差。

| 项 | 3.7 | 主项目 |
|---|---|---|
| 帧入口 | `GameRender.render()` → `GameCtrl.render()` | 同 |
| 相机前 | `updateSurvivorFocus()`、`enforceFighterTether()` | `_cameraFocusWatch.tick()` |
| 相机 | `camera.render()` | `camera.render()` |
| 相机后 | `gameUI.render()` → `_map.render(...)` | 同 |
| 相机前是否可改焦点 | 是（survivor 重建） | 是（看门狗撤销） |

两版的共同硬约束：**`GameState.render()` 一定早于 `_mainLogicCtrl.render()`**，所以相机永远落后角色一帧。要消掉这一帧，只能把 `camera.render()` 挪到角色更新之后（属于行为改动，不在本册讨论范围）。

补一条 3.7 侧的小事实：相机前面那两句里，`enforceFighterTether()` 的函数体只有 `_tetherPrev = new Dictionary(true)`，而 `_tetherPrev` 全树**只被赋值、从不被读**；`compressSpawn()` 的函数体是空的（`initFight()` 与 `resetFight()` 各调一次），常量 `SPAWN_GAP_RATIO` 也无人使用。三处都是未完工/被剪掉的功能残留，搬相机时不要顺手带走。

### 4.14 一次必杀特写的完整时序（主项目，逐方法）

把三件套串起来看一遍，这最能说明「为什么拆三个」：

```text
① EffectCtrl（引擎侧）
   GameState.cameraFocusBisha(display)
     → camera.focus([d], false, GameCamera.FOCUS_OWNER_BISHA)   // 打 owner
     → camera.setZoom(3.5)
     → camera.tweenSpd = CAMERA_TWEEN_SPD / SPEED_PLUS_DEFAULT

② 每帧 GameState.render()
   _cameraFocusWatch.tick()
     ├─ _cooldown > 0            → --_cooldown；若已不是单焦点则 resetState；return
     ├─ !_camera.isSingleFocus   → resetState；return
     ├─ focusOwner != BISHA      → resetState；return            // 人物包自己摆的镜头一律不碰
     ├─ focusTarget == null      → return
     ├─ 目标变了                 → bind()：记起始标签、记黑幕是否在、清零全部计数
     ├─ ++_frames；parent == null → release("目标已离场")
     ├─ 读 currentLabel：与起始标签同族 → 清零；异族连续 6 帧 → release("帧标签已切换")
     ├─ 黑幕曾经在：连续 2 帧不在 → release("必杀黑幕已结束")
     └─ _frames > (必杀族标签或黑幕 ? 360 : 600) → release("锁定超时")
   camera.render()                                                // 看门狗先动焦点，同一帧生效

③ release(reason)
   _cooldown = 20（RELEASE_COOLDOWN）
   _target 刻意保留（换目标时 bind() 重新武装）
   _onRelease() → GameState.cameraResume()
        → focus(_cameraFocus, false, FOCUS_OWNER_ENGINE)
        → 若 _cameraFocus.length < 2 才 setZoom(_cameraDefaultZoom)
        → tweenSpd 复位
```

四个设计点，逐条能对上代码：

1. **只认 `FOCUS_OWNER_BISHA`**：`focusOwner` 不是 BISHA 就 `resetState()` 直接返回，所以人物包 `camera.focus([...])`（owner=`null`）永远不被抢——这是「不能断角色包 API」的硬约束在代码里的落点。
2. **判据一次性**：`_labelReleased` 与 `_blackWasOn` 用完即关，配合 `RELEASE_COOLDOWN=20`，避免「角色包每帧又把镜头拉回来 → 冷却一帧就抖一次」。
3. **两条超时分开**：必杀族标签或黑幕在场用 `MAX_FRAMES_BISHA=360`（30fps×12s），否则 `MAX_FRAMES_EXTERNAL=600`（×20s）。注释给的理由是长演出（举例 `ult` 约 12.6 秒）中途没有任何标签变化，靠标签判据兜不住，只能靠足够长的保险丝。
4. **`singleFocusFrames` 不参与判定**：`GameCamera` 自己也有一个单焦点帧计数，但 `GameCameraFocusWatch` 用的是自己的 `_frames`；注释写明原因是「有的包在 ENTER_FRAME 里每帧调 `focus()`，那个计数会一直是 0」。

---

## 5. 陷阱与反编译噪音

### 5.1 会真的咬人的（按坑的严重度排）

| # | 现象 | 根因（代码级） | 规避 |
|---|---|---|---|
| 1 | `new GameCamera(disp, size)` 直接抛 `#1009` | ctor 里先 `setStageSizeFromDisplay(_stage)`，而该函数读 `_stageBounds.x`；`_stageBounds` 要到后面的 `setStageBounds()` 才赋值 | ctor 第 3 参 `stageSize` **必须给**；两版同一 bug |
| 2 | 缓动速度「写 2.5 实际是 2」 | `tweenSpd` / `zoomTweenSpd` 都是 `int`，AS3 赋 Number 向零截断 | 要 2.5 的效果就写 `3` 或改字段类型（后者影响 `slow()` 全都得重算） |
| 3 | 慢放期间相机瞬移、慢放结束后跟随变快 | `GameCtrl.slow(rate)` 写 `camera.tweenSpd = 2.5 * rate`；`int` 字段截断后只要 **rate ≤ 0.4 就变成 ≤1**，`setX/setY` 走吸附分支（`tweenSpd>1` 才缓动）。入口是 `EffectCtrl.slowDown(rate,ms)` → `GameCtrl.I.slow(rate)`，3.7 的 `playCinematicOutro()` 直接传 `0.1`。恢复时 `slowResume()` 写回 **2.5**，而 `initCamera()` 原本是 **5**（`2.5/SPEED_PLUS_DEFAULT`） | 要保住手感，`slowResume()` 得写回 `2.5/SPEED_PLUS_DEFAULT`（主项目 3.3 侧同一处也有同一问题，见 5.3） |
| 4 | 镜头「自己抖」 | 两套震动叠加：`GameCamera.impact` 改 scrollRect，`EffectCtrl.shake` 改 `_gameStage.x/.y` | 移植前先决定保留哪一套 |
| 5 | 顶部能滚出很远空白 | `_fbR.y = _stageBounds.y * _zoom`（乘了缩放） | 想收紧就改成 `_stageBounds.y`（行为改动） |
| 6 | `cameraResume()` 抛 `#1009` | 3.7 版 `GameState.cameraResume()` 无 `_cameraFocus` 空判，`camera.focus(null)` 内 `_focus.length` 崩 | 主项目已加 `if(!this._cameraFocus) this._cameraFocus = []` |
| 7 | `focus([])` 后第一帧崩 | `_focus=[]`、`_point=null`，`renderX()` 走 `_focus[0].x` ⇒ `undefined.x` | 传空数组等价于「取消跟随」，需先 `move()`/`moveCenter()` |
| 8 | `cameraDrifted()` 误判 | `isFocusing()` 是**引用比较**，传一份等价副本永远返回 `false` | 维护「同一份数组」的约定（3.7 survivor、主项目 `_cameraFocus`） |
| 9 | 单人场景镜头不还原 | `render()` 只对 `_focus.length>1` 跑 autoZoom；单人时 `_zoom` 保持上一次 `setZoom()` | 两版都在收尾里显式 `setZoom()`（主项目 `cameraResume()` 还判了 `length<2`） |
| 10 | 相机不动 | `render()` 首行 `if(!_focus && !_point) return`——`move()` 之前、`focus()` 之前什么都不会发生 | 正常：未初始化即静止 |

### 5.2 反编译造成的假象

| 假象 | 实际 |
|---|---|
| `_loc1_`…`_loc11_` 之类变量名 | 局部变量名被重命名，语义只能靠上下文推；本册所有结论都对应到字段/方法名层面的代码 |
| `map/MapMain.as` 里 `_loc4_ < _defaultFrontPos.y && _loc4_;` 这类「裸表达式语句」 | 反编译残留的死语句，无副作用 |
| `GameLogic._camera` 被赋值后从不读 | 死字段（`initGameLogic` 的第 2 参形同虚设） |
| `GameCamera.getMaxFighterDistance()` 无人调用 | 3.7 独有但未接线；`closeUpZoomForTarget()` 同样无调用者 |
| `FighterScaleModel.cameraMinZoom` 永远返回 1 | 有字段、有夹取逻辑，但值写死；`effectiveZoom` 里那次 `max(z, cameraMinZoom)` 等价于 `max(z,1)` |
| `GameCamera.render()` 看似「单人也会自动缩放」 | 单人分支要求 `soloAutoZoom`，而它只有 `MosouCtrl` 会置 `true` |
| `setCinematicLock(true)` 看似「冻结相机」 | 它只跳过三处：单人缩放分支、`keepFocusInFrame()`、缩放减速上限；`renderX/renderY/renderZoom/applySet` 照常跑 |
| `_scTop/_scL/_scR` 看起来一直在维护 | 只在 `updateFocusScales()` 里更新，而它只在 `keepFocusInFrame()` 与 `renderMulti()`（且 `autoZoom` 为真）里被调 |
| `applySet()` 里 `+ 1 >> 0` | `+` 先于 `>>`，等价于 `Math.floor(w + 1)`（正数域），不是「右移一位」 |
| `getScreenRect(true)` 语义两版不同 | 3.7：`_displayRect`（含震动）；主项目：`_rect`（就是 scrollRect 本身，因为主项目没有 `_displayRect`） |
| `GameState.enforceFighterTether()` 看着像「拉回角色」的机制 | 函数体只有 `_tetherPrev = new Dictionary(true)`，而 `_tetherPrev` 从不被读；等于每帧白造一个 Dictionary |
| `GameState.compressSpawn()` 有四个 `FighterMain` 形参 | 函数体为空，`initFight()`/`resetFight()` 各调一次，什么都不做 |
| `GameState.SPAWN_GAP_RATIO` 常量 | 声明后无任何引用 |

### 5.3 两版共有的缺陷（改一处就够，别当成「分支差异」）

下表每一行都核对过两侧的同一段方法体，行为一致；遇到时不要以为是 3.7 独有而去找「主项目怎么做的」。

| 缺陷 | 3.7 位置 | 主项目位置 | 说明 |
|---|---|---|---|
| ctor 不给 `stageSize` 就抛错 | `state/GameCamera.as:GameCamera()` | `主项目 state/GameCamera.as:GameCamera()` | 两者都是「先 `setStageSizeFromDisplay()` 后 `setStageBounds()`」，而前者要读 `_stageBounds.x` |
| `tweenSpd` / `zoomTweenSpd` 是 `int` | 字段声明 | 字段声明 | 写 2.5→2、1.6→1；`slow()` 里 0.25→0 |
| 慢放结束后复位到 2.5 而非 5 | `GameCtrl.slowResume()` | `主项目 GameCtrl.slowResume()`（用 `GameConfig.CAMERA_TWEEN_SPD`=2.5） | 只有 `initCamera()` 用 `2.5/SPEED_PLUS_DEFAULT` |
| `_fbR.y = _stageBounds.y * _zoom` | `setZoom()` | `setZoom()` | 纵向钳制下界随缩放放大 |
| `focus([])` 后首帧解引用 `undefined` | `renderX()` | `renderX()` | 两版都写作 `_point ? _point.x : _focus[0].x` |
| `isFocusing()` 引用比较 | `isFocusing()` | `isFocusing()` | 传副本必返 `false` |
| `autoZoom` 只在 `length>1` 生效 | `renderMulti()` 内的 `if(autoZoom)` | `renderTwo()` 内的 `if(autoZoom)` | 主项目注释也写明「单人视角 renderTwo 不执行、autoZoom 不接管」 |
| `renderZoom()` 的 `throw` 只防 0 | `_zoom <= 0` 抛 `Error` | 同 | 负值不会被拦（会得到翻转的 scrollRect） |

---

## 6. 移植可行性

### 6.1 能力逐项对照（问题 9）

| 能力 | 3.7 `GameCamera` 单类 | 主项目 `GameCamera` + 三件套 | 差在哪 |
|---|---|---|---|
| 双人跟随 | `renderMulti()` 统计**全部**焦点 bbox | `renderTwo()` 只取数组**首尾两个** | 3.7 支持 3~4 人同框；主项目在 2v2 时只盯首尾 |
| 缩放需求式 | `screen/(bbox+留白)`，取双轴更小值 | `screen/span*0.8`，取双轴更小值 | 3.7 的留白可独立调；主项目的 `*0.8` 是等价但不可拆的写死留白 |
| 缩放夹取 | `effectiveZoom` + `zoomHardMinRatio` + `cameraMaxZoom` | 直接夹 `[autoZoomMin, autoZoomMax]` | 3.7 多一层「按角色缩放放宽」 |
| 档位 | `DISTANCE_ZOOMS[4]` + `zoomForLevel()` + `config.cameraDistLevel` | 无档位；`autoZoomMin = 1/config.cameraMaxSize`、`autoZoomMax = 2.5` 写死 | 3.7 是四档常量表；主项目是一条规则字段 + 写死上限 |
| 留白钳制 | `keepFocusInFrame()`（横 4.5%、上 20%、下 3%，随缩放放大） | 无 | 主项目只有居中 + 边界钳制 |
| 边界钳制 | `setX/setY` + `keepFocusInFrame()` 双重 | `setX/setY` 单重（`_fbR` 算法相同） | 主项目少一道兜底 |
| 震屏 | trauma 平方 + 双正弦 + 缩放抖动 + punch 弹簧 | 无（靠 `EffectCtrl` 整屏位移） | 3.7 只抖世界层；主项目连 HUD 一起抖 |
| 缩放专用缓动 | `zoomTweenSpd` 覆盖 + 拉远限速 | 无（与位置共用 `tweenSpd`） | 3.7 能做出「推近慢、拉远快」 |
| 电影锁 | `setCinematicLock` 三处门控 | 无该概念 | 主项目靠 `EffectCtrl` 的锁泄漏计数兜 |
| 特写倍率 | `closeUpZoom`/`closeUpZoomFor()`（含角色缩放） | 写死 `3.5` | 3.7 的倍率随角色体量自适应 |
| 单人特写撤销 | 无专门类；`EffectCtrl` 30 帧锁泄漏 + `cameraDrifted()` | `GameCameraFocusWatch` 四判据 + 冷却 20 帧 | 主项目能识别「帧标签已切走」「黑幕已撤」，3.7 不能 |
| 换人聚焦 | `swapFighterFocus()` 原地替换，倍率不动 | `TagModeCtrler.updateCameraFocus()` 重建 2 元素数组，倍率归位 2 | 行为不同，不是优劣 |
| 存活者重建 | `setupSurvivorFocus()`/`updateSurvivorFocus()` | 无（2v2 靠 TAG/回合流程重建） | 3.7 每帧自愈 |
| 性能 | 相机自身无对象分配（`_point` 复用），但**相机前一步** `enforceFighterTether()` 每帧 `new Dictionary()` | 相机自身无分配，也没有那一次 Dictionary | 3.7 每帧多一次 Dictionary 分配 + 一次 `updateFocusScales()` 遍历；后者只在多焦点且 `autoZoom` 时跑 |

### 6.2 要搬 3.7 的 `GameCamera.as`，会废掉哪三个类（问题 10）

**直接覆盖的后果，逐条按代码推**：

| 类 | 覆盖后 | 原因 |
|---|---|---|
| `GameCameraCtrler` | **编译失败** | `destory(true)` 分支调 `this._camera.destory()`，3.7 的 `GameCamera` 没有 `destory()`；另外 `setStageSize()` 写 `_camera.stageSize` 仍可用 |
| `FighterCameraCtrler` | **能编译，但 owner 丢失** | 它 `override focus(param1,param2)` 后调 `super.focus(_loc3_,param2)` → `GameCameraCtrler.focus()` → `_camera.focus(array,param2)`，3.7 的 `focus` 没有第 3 个 owner 参数，镜头全部变成 `owner=null` |
| `GameCameraFocusWatch` | **静默失效** | `tick()` 依赖 `_camera.isSingleFocus`、`_camera.focusOwner`、`_camera.focusTarget`、`GameCamera.FOCUS_OWNER_BISHA` 四个成员，3.7 一个都没有 ⇒ 编译失败；若为省事删掉这些判断，看门狗就永远 `resetState()`，等于关掉 |

**结论**：不能「整个文件覆盖」。可行路线是**把 3.7 的算法搬进主项目 `GameCamera`，同时保留主项目的四个额外接口**：`destory()`、`focus(array, instant, owner)`、`isSingleFocus/focusOwner/focusTarget/singleFocusFrames`、以及 `FOCUS_OWNER_*` 常量。

### 6.3 TAG 双人聚焦与滤镜代理会不会被破坏

| 风险 | 会不会破 | 依据与改动点 |
|---|---|---|
| TAG 双人聚焦 | **会，若同时改 `updateCameraFocus` 的语义** | 主项目换人靠 `TagModeCtrler.updateCameraFocus()` → `camera.focus(array)+setZoom(2)`；3.7 的 `focus()` 同样接受数组，接口兼容。但 3.7 的 `renderMulti()` 会立刻按 bbox 重算 `_zoom` 并覆盖 `setZoom(2)`（因为 `autoZoom` 为真）⇒ 「换人后倍率归位 2」这一行为会消失，变成「立刻贴合双人 bbox」 |
| 3~4 人同框 | 不会破，且统计范围变大 | 3.7 统计全 bbox，主项目只取 `_focus[0]` 与 `_focus[length-1]`；中间那名角色是否落在画面内，主项目这一版不进判据（见 §7 对应条目） |
| `_cameraFocus` 引用约定 | 不会破 | 两版都用「保持同一数组」的做法（3.7 `_managedFocus`、主项目 `_cameraFocus`），`isFocusing()` 引用比较照旧成立 |
| GPU 滤镜代理 | **会变差，不破** | `FilterNodeProxy.computeBounds()` 返回 `scrollRect` ⇒ 3.7 的震动会把抖动写进烘焙区域；`displayScale()` 用 `concatenatedMatrix` ⇒ 3.7 的 `_displayScale`（含 punch zoom 与缩放抖动）会改变超采样倍率。已有 0.25 量化与 `FPROXY_TWEEN_SCALE_MAX` 兜底，但「零震动」变「每帧小数变化」。改动点：或关 `shakeEnabled`，或把抖动放到 `_gameLayer` 的父容器上 |
| 3.7 `EffectCtrl` 的 `offsetY` 存档写法 | 仅在同时移植 3.7 必杀缩放逻辑时成立 | 3.7 `ctrl/EffectCtrl.as` 用 `camera.hasOwnProperty("offsetY")` 判断后读写 `camera["offsetY"]`；3.7 的 `offsetY` 会被 `focusOffsetScale()` 乘，存档值在单人缩放前后的含义不同。主项目 `EffectCtrl` 侧无此存档（grep `offsetY` 无命中） |
| 缓动手感 | 会 | 主项目 `initCamera()` 用 `2.5/SPEED_PLUS_DEFAULT`（=5），3.7 的 `renderZoom()` 对拉远另有 2 的上限；移植后拉远会明显变快 |

### 6.4 建议的最小移植顺序

1. 先只搬 `keepFocusInFrame()` + 三个留白常量（不动 `setX/setY` 语义）——纯增量，风险最低。
2. 再搬 `renderMulti()` 的 bbox 全量统计（替换 `renderTwo` 的首尾取样），保留原有 `*0.8` 缩放式以维持手感。
3. 然后搬 `zoomTweenSpd` 与拉远限速（纯缩放通道）。
4. 最后才考虑 `shake/punchZoom`（要先决定是否退役 `EffectCtrl` 的整屏抖动，并同步 `FilterNodeProxy` 的预算参数）。
5. `effectiveZoom`/`closeUpZoomFor` 与 `FighterScaleModel` 一起搬或一起不搬——主项目没有 `data/FighterScaleModel.as`，单搬这些方法会全部走 `cameraDivisor==1` 的直通分支。

---

## 7. 未实测清单

> 以下每一条都**不能**当已知事实继续推演。列的是「要确认它需要什么手段」。

- [ ] **相机落后角色一帧的实际观感**。代码可证调用顺序（`gameState.render()` 早于 `_mainLogicCtrl.render()`），但「快角色高速横移时是否可见拖影」需要真机 60fps 录屏逐帧比对角色 x 与 `scrollRect.x`。
- [ ] **`_fbR.y` 乘 `_zoom` 的实际后果**。需要一个高缩放档（Very Close，3.4）地图，手动把角色推到地图顶部，观察能否滚出地图外露出空背景；纯读代码只能证明「下界随缩放线性放大」。
- [ ] **`tweenSpd` 被截断到 ≤1 时的视觉表现**。需要触发一次 `EffectCtrl.slowDown(0.1,ms)`（3.7 的必杀收尾 `playCinematicOutro()` 就是这条路）并逐帧抓 `GameState.cameraDebug()` 输出（它会打印 `spd=...`），确认慢放期间 `spd` 确实落到 0、画面是否变成硬吸附。代码只能证明截断与分支走向。
- [ ] **两套震动叠加的实际幅度**。需要一次同时触发 `EffectCtrl.shake`（命中特效）与 `GameState.shakeCamera`（回合结束）的时机，抓帧量 `_gameStage.x` 与 `scrollRect.x` 的偏移。
- [ ] **`impact(0.25/0.35)` 在真机上的可感度**。trauma≈0.475/0.545、振幅≈`24*a`≈5.4/7.1 世界单位，是否「看得见」需要 60fps 录屏；数值本身来自代码，观感不属于代码事实。
- [ ] **`DISTANCE_ZOOMS` 四档的实际取景差异**。需要同一张 JSON 地图分别用 `cameraDistLevel=0/1/2/3`（`Far/Normal/Close/Very Close`）各截一张静止画面，量化可见宽度比例；本册只能给出常量与夹取公式。
- [ ] **`FighterScaleModel` 打开后 `effectiveZoom` 的真实影响**。需要 `config/fighter_scale.json`（`FighterScaleModel.DEFAULT_URL`）实际存在且 `apply` 不是 `off`，并让某个角色 `scale>1`，再读 `getZoom()` 是否真的变小。
- [ ] **`FilterNodeProxy` 在震动开启后的烘焙节奏**。`needsBake()` 的判据是 `_bakedEpoch`/`frameKey`/内容签名/最小间隔，**不比对 bounds**；因此「scrollRect 每帧变」是否导致烘焙区域滞后，需要开 `GameConfig.FPROXY_DEBUG` 抓 [FPROXY] 日志逐帧核对。
- [ ] **`displayScale()` 的 0.25 量化在 punch zoom 下是否抖动分桶**。需要开调试日志观察 `BitmapDataPool` 分桶是否在 `_displayScale` 变化时切换。
- [ ] **主项目 `renderTwo()` 只取首尾是否真的裁掉中间角色**。需要 2v2（模式 14/15）让三名角色分散站开，截图检查中间那位是否在框外；代码只能证明「只统计 `_focus[0]` 与 `_focus[length-1]`」。
- [ ] **`cameraResume()` 在 `_cameraFocus` 为 null 时是否真的抛错**。需要构造「`endBisha()` 早于 `initFight()`」的时序（主项目已加空判，3.7 未加），在 3.7 侧无法运行（该树不可编译），只能在主项目里临时回退空判复现。
- [ ] **`GameCameraFocusWatch` 的 6 帧 / 2 帧保持窗口在真机上是否够稳**。`LABEL_LEFT_HOLD=6`、`BLACK_GONE_HOLD=2` 是常量，实际是否会误撤/漏撤需要拿一个「帧标签在必杀中途来回跳」的角色包实测。
- [ ] **3.7 的 `EffectCtrl` 30 帧锁泄漏阈值是否覆盖真实必杀时长**。`checkCameraLockLeak()` 用 `_lockLeakFrames > 30`，而必杀动辄数十帧；需要真机跑一次长必杀，确认没有被提前 `cameraResume` 打断。
- [ ] **`swapFighterFocus()` 之后 `_focus` 数组元素顺序是否影响 `renderMulti()` 的 `_scL/_scR` 归属**。代码按 `d.x` 最小/最大分配左右留白系数，换人后顺序不变但坐标变了；需要实测「大个子在左 vs 在右」的留白是否符合预期。

---

_本册基于两份源码逐行核对，未运行任何一侧工程（3.7 参考树不可编译）。所有行为结论均可由引用的方法体推出；推不出的已列入第 7 节。_
