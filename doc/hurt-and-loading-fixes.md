# 受击 / 灵爆 / 开局加载：三个卡死的根因与修复（2026-10-21）

> 本文记录 2026-10-21 处理的三条「看起来都是卡死、其实根因完全不同」的问题。
> 三条都在真机上出现过，都改在 `BVNscripts/scripts/`（手机端主项目）。
> **改 fighter / ctrl / state 目录前先看第 5 节「不许回退的点」。**

## 0. 速查

| 现象 | 根因落点 | 一句话 |
|---|---|---|
| A. 受击中按 SPECIAL（灵爆）后**永久僵直 + 永久金身**，对手还能动，点暂停继续也救不回 | `GameMainLogicCtrler.renderGameSprite` + `FighterMain.renderAnimate` + `FighterMcCtrler.renderHurt` | `render()` 抛异常 → 同帧 `renderAnimate()` 被跳过 → 三个计时器同时停摆；而"安全网"又被同一个计时器门控（自锁） |
| B. 某个角色**一选就崩 / 开局黑屏**（`#1009 at GameState/cameraResume`） | `EffectCtrl.cancelJustRender*` | 人物包在 `人物_1/frame1` 无条件调 `endBisha()`；`cancelJustRenderAnimate` 把"从没登记过"误判成"合法收尾" |
| C. `创建游戏失败` 每帧刷屏 + 黑屏 + 切后台后永久黑屏 | `TransUI.renderAnimate` + `GameCtrl.pause` | 转场回调"先调后清"，一抛异常就每帧重试；`GameUI.getUI()` 为 null 时 `pause(true)` 半途崩，`_isPauseGame` 粘住 |

---

## 1. 问题 A：灵爆后永久金身 + 永久僵直

### 1.1 因果链

```
render() 抛异常（最可能是 renderHurtBreak 解引用空 _actionCtrler）
  └─ GameMainLogicCtrler.renderGameSprite:296 与 :299 在同一个 try
       → renderAnimate() 本帧被整块跳过
          ├─ FighterMcCtrler.renderHurtAnimate  _hurtHoldFrame--   ← 停 → 永久僵直
          ├─ FighterMain.renderAnimate          --_explodeSteelFrame ← 停 → 永久金身
          └─ FighterMain.renderAnimate          --_explodeHitFrame   ← 停 → 到不了 idle()
```

**死锁点**：`FighterMcCtrler.renderHurt()` 的两道安全网（旧 `:1922` / `:1946`）都以
`_fighter.explodeSteelFrame <= 0` 为门控，而 `_explodeSteelFrame` 的唯一递减点正是被跳过的那条
`renderAnimate()`。**计数器一停，保护它的安全网自己也失效** —— 这是上一轮修复（`ca46d10` 加了两道网）
为什么没救回来的原因。

### 1.2 判定三问（现场区分用）

| 问 | 答 | 结论 |
|---|---|---|
| 卡死时全场定格还是单角色？ | 单角色（对手能动） | 排除全局 `_isRenderGame`，锁定单角色 render 链路 |
| 暂停→继续 能救吗？ | 不能 | `resume(true)` 只重置 `_isRenderGame`，不碰该角色的计数器 |
| 哪一侧？ | 死神侧（灵爆，黄色辉光） | 走 `energyExplode()`，不是 `replaceSkill()` |

### 1.3 为什么「火/冰/雷重击」几乎必现

| 因素 | 证据 | 作用 |
|---|---|---|
| 7/8/9 是唯一 `freeze:400` 的 hitType（轻击只有 50） | `data/EffectModel.as:156-197` | 每次命中多 400ms 全局 `GameCtrl.pause()`，与灵爆 0.7s 窗口大面积交叠 |
| 7/8/9 唯一带 `specialEffectId`，会改写受害者 `ColorTransform` | `EffectModel.as:307-324`、`views/effects/SpecialEffectView.as:57-66` | 只在 `actionState ∈ {0,23,24}` 才 `resumeColor()`；卡在 21/22 就**永久染色**（火=发黑），叠加辉光就是"变金身" |
| 受击期每帧 4 条同步写盘的日志 | `Debugger.log` 每次 `writeUTFBytes + flush`（`Debugger.as:245-251`） | 手机上直接吃掉帧时间，放大所有暂停窗口的错位概率 ← **"真机尤其明显"的直接原因** |

### 1.4 修复

| 文件 | 改动 |
|---|---|
| `ctrl/game_ctrls/GameMainLogicCtrler.as` | `render()` / `renderAnimate()` **拆成两个独立 try**；`logRenderError()` 按「角色+阶段」去重记首条带堆栈（原实现整局只记第一条，真异常被更早的无关异常挡掉） |
| `fighter/ctrler/FighterMcCtrler.as` | `renderHurtBreak` / `renderHurtFlying` 补 `_actionCtrler` 判空；安全网门控 `explodeSteelFrame` → **`explodeHitFrame`**；`idle()` 补 `_hurtHoldFrame = 0`；`hurtResume` 改 `public` |
| `fighter/FighterMain.as` | `_explodeHitFrame == 8` → 幂等 `<= 8 && !_explodeIdled`；新增 `_explodeSteelWatchdog`（150 帧强解金身）；控制器动画链独立 try；新增 `explodeHitFrame` getter 与 `resetExplodeState()` |
| `fighter/FighterMC.as` | `renderHurtFly` case 3 起身后加 12 帧引擎兜底（case 4）：`_action.isHurtFlying` 全工程只有 `clearState()` 能清，不能只靠角色 SWF 帧脚本的 `parent.$mc_ctrler.idle()` |
| `ctrl/game_ctrls/GameCtrl.as` | `removeGameSprite` 先 `resetExplodeState()`：`destory(false)` 是早退实现，辉光的 `BitmapFilterView` 是**独立 sprite**，不在这里解就会留一尊永久残像 |
| `Debugger.as` | 新增 `DIAG_HURT`（默认 false）；逐帧日志全部收进开关，只保留低频判据 |

---

## 2. 问题 B：`#1009 at GameState/cameraResume`（开局崩）

```
人物_1/frame1  →  FighterEffectCtrl.endBisha()
               →  EffectCtrl.endBisha()
               →  GameCtrl.I.gameState.cameraResume()   ← this.camera 还是 null
```

`camera` 在 `initFight → initCamera` 才创建，而角色是在更早的 `buildGame:287` 的 `addFighter` 里初始化的。
根因是 `EffectCtrl.cancelJustRender(Animate)` 的误判：

```as
// 旧实现：indexOf == -1 也返回 length < 1
if(_loc2_ != -1) this._justRenderAnimateTargets.splice(_loc2_,1);
return this._justRenderAnimateTargets.length < 1;   // 从没登记过 → 也返回 true
```

于是人物包里漏出来的 `endBisha()` 被当成"合法收尾"。**对局中**同样会误触发：`GameCtrl.resume()` +
`setRenderHit(true)` + `_blackBack.fadOut()` + 地图设可见 —— 随时强行打断别人的灵爆/替身术/瞬步黑幕。

修复：

- `cancelJustRender` / `cancelJustRenderAnimate`：**未登记 → `return false`**（根因，3 个调用点全走这里）
- `endBisha` / `endWanKai`：`setRenderHit(true)` **提到最前**（这行漏掉＝全场打不动，看起来完全是"永久金身"）
- `GameState.cameraResume` / `cameraFocusOne`：`if(!this.camera) return;`

> 人物包侧建议顺手修：删掉 `人物_1` 第 1 帧的 `parent.$effect_ctrler.endBisha()`。
> 引擎侧现在已能兜住，但脏帧脚本还会在别的调用点惹事。

---

## 3. 问题 C：`创建游戏失败` 刷屏 + 黑屏

### 3.1 三段因果

1. `buildGame()` 的 null 保护触发（`p1/p2.currentFighter` 或 `map` 为 null）→ 原实现 `throw`。
2. `throw` 穿过 `startGame → goGame` 落进 `TransUI.renderAnimate` 的 `_fadOutBack`。
   原实现**先调回调、后置 null** → 回调抛异常后 `_fadOutBack` 永久保留 → **每帧重试一次** → 黑屏 + 同一个错误刷屏。
3. `buildGame` 中断 ⇒ `initFight` 从未执行 ⇒ `GameUI.getUI()` 为 null ⇒ 切后台
   `MobileCtrler.pause → GameCtrl.pause(true) → getUI().pause()` **#1009**（`_isPauseGame` 已置 true、
   对话框没建出来）⇒ 回前台无人 `resume(true)` ⇒ **永久黑屏，只能杀进程**。

### 3.2 修复

| 文件 | 改动 |
|---|---|
| `ui/TransUI.as` | **先摘回调再调用**（黑屏 + 刷屏的根因） |
| `ctrl/game_ctrls/GameCtrl.as` | `pause/resume` 对 `GameUI.I.getUI()` 判空；无 UI 时不进"菜单暂停"，只停渲染 |
| `mob/ctrls/MobileCtrler.as` | 新增 `_pausedByDeactive`，回前台只撤销**自己造成**的那次暂停（原先 `resume()` 从不调 `GameCtrl.resume(true)`） |
| `ctrl/game_ctrls/GameCtrl.as` | `buildGame(): void → Boolean`，null 保护改为**点名日志 + `return false`**；`doStartGame` 失败则 `MainGame.I.goMenu()`，不再 throw 打断转场 |

### 3.3 待确认

下一次失败只需看这一行：

```
[GameCtrl] buildGame ABORT — p1.currentFighter=? p2.currentFighter=? map=?
```

- `p1=null` ⇒ `getP1Order()[0]` 为空，问题在选人/加载，与角色状态机无关
- `map=null` ⇒ 地图项没加载完（看 `[LoadingState]` 行）

---

## 4. 真机验收断言

| 场景 | 通过标准 |
|---|---|
| 受击中按 SPECIAL ×20（死神侧 + 火/冰/雷 对手） | 每次金身 ≤ 2s 结束，**不出现** `【钢体看门狗】` |
| 同上，看日志 | 每次灵爆必现 `【僵直归零】→【僵直恢复】` |
| 任意异常 | 出现 `RENDER_ERR[render]` / `RENDER_ERR[renderAnimate]` / `FIGHTER_ANIM_ERR` 时带角色 id + 堆栈 |
| KO 前 2 秒内灵爆 ×5 | 换人/结算后无黄色辉光残像 |
| 对局中切后台再回前台 ×10 | 自动回到战斗（不再需要点「继续」）；无 `#1009 at GameCtrl/pause` |
| 选人进局失败 | 回菜单 + 一行 `[GameCtrl] buildGame ABORT — ...`，**不再**黑屏刷屏 |

需要逐帧细节时把 `Debugger.DIAG_HURT` 改 `true` 重编（默认 false，别长期开着，同步 flush 很贵）。

---

## 5. 不许回退的点

1. `renderGameSprite` 里 `render()` / `renderAnimate()` **必须是两个独立 try**，不得合回一个。
2. `FighterMain.renderAnimate` 调 `_fighterCtrl.renderAnimate()` 的 try 不得删。
3. `renderHurt()` 安全网门控是 **`explodeHitFrame`**（灵爆命中窗口），**不是** `explodeSteelFrame`。
4. `cancelJustRender*` 未登记必须返回 `false`。
5. `TransUI` 的转场回调必须**先摘再调**。
6. `GameUI.I.getUI()` 在 `initFight` 之前是 null，任何 UI 调用前都要判空。
7. 逐帧日志一律走 `Debugger.DIAG_HURT`；`Debugger.log()` 是同步 flush 写盘。
