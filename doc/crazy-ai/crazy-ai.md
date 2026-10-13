# 手机端主项目 AI 难度移植记录 —— CRAZY（疯狂）人机档

> **移植方向**：`BVNscripts/3.7扩展版参考/Shonen-Clash-main/`（只读参考，未修改） → **`BVNscripts/scripts/`（手机端主项目，可编译源码基准）**
> **移植内容**：把参考工程"最难档"里比主项目更激进的那几项决策门槛，移植进主项目的 AI 概率决策引擎，并为 `CRAZY`（疯狂，`AI_level = 7`）开出真正独立的档位。
> **本轮实际改动文件仅 2 个**：
> - `BVNscripts/scripts/net/play5d/game/bvn/fighter/ctrler/ai/FighterAILogicBase.as`
> - `BVNscripts/scripts/net/play5d/game/bvn/fighter/ctrler/ai/FighterAILogic.as`
> **落地日期**：2026-10-09
>
> 本文只描述**手机端主项目**这一棵树。PC 分支的 AI 说明另见 `doc/AI-SYSTEM-DOC.md`（历史文档，基准路径已失效），两者不是同一份代码。

---

## 0. 一句话概括

改造前 `getAIResult()` 的 `switch` 只有 `case 0~5` + `default`，设置里的 **6（HELL/地狱）与 7（CRAZY/疯狂）落进同一个分支读同一个 `param6`**，两档行为逐位相同，"疯狂"根本不比"地狱"难。本轮给概率表加了**第 7 列**（`param7`）与一组 **CRAZY 专属门槛常量**，把参考工程最难档比主项目更激进的那几项移植进来，使 CRAZY 成为真正独立的最难档；**等级 1~6 的取值与改造前逐位一致**。

---

## 1. 移植背景与问题定位

### 1.1 两档同源

`FighterAILogicBase.getAIResult()`（改造前）:

```as3
switch(int(this.AILevel)) {
   case 0: case 1: return _loc7_ < param1;
   case 2:         return _loc7_ < param2;
   case 3:         return _loc7_ < param3;
   case 4:         return _loc7_ < param4;
   case 5:         return _loc7_ < param5;
   default:        return _loc7_ < param6;   // ← 等级 6 与 7 都在这里
}
```

菜单里 7 档来自 `mob/GameInterfaceManager.as` 的 `getSettingMenu()`（`HELL=6`、`CRAZY=7`）；档位链路是
`GameInterfaceManager` → `ConfigVO.AI_level` → `MessionModel.AI_LEVEL` → `GameCtrl` 赋给 `FighterAICtrl.AILevel` → `new FighterAILogic(AILevel, fighter)`。
链路本身没问题，**问题只在于 7 没有自己的取值列**。

### 1.2 参考工程的最难档

`Shonen-Clash-main` 的设置菜单只到 `HELL=6`，即它的 `param6`。逐项比对后发现两侧各有更激进的一处，方向如下（**主项目更保守的项**才是本轮要移植的）：

| 决策点 | 主项目（移植前） | 参考工程最难档 | 谁更激进 | 本轮处理 |
|---|---|---|---|---|
| 必杀可用气量门槛 | 200（超必杀 300） | 100（超必杀 300） | 参考 | ✅ 移植（CRAZY 取 100） |
| 必杀"终结过滤" | 有四条件过滤，实战几乎不出 | 无过滤 | 参考 | ✅ 移植（CRAZY 跳过） |
| 追击时起跳落差门槛 | `_jumpKeep = 300` | 50 | 参考 | ✅ 移植（CRAZY 取 50） |
| 远距离冲刺触发距离 / 能量门槛 | 250 / 60 | 200 / 40 | 参考 | ✅ 移植 |
| 远距离冲刺概率 | 5.5 | 9 | 参考 | ✅ 移植（第 7 列 = 9） |
| 对子弹/攻击体/助战的防御反应距离 | 125，超出降为 0.2 | 200，且攻击体/助战不判距离 | 参考 | ✅ 移植（取 200 / 远距 1.0） |
| 出手命中守卫 | 无（对无敌帧空挥） | 有命中守卫 | 参考 | ✅ 移植（CRAZY 加守扩） |
| 超必杀在连招队列里的优先级 | 100（低于普通必杀 115，被顶掉） | bishaSUPER 200 / bishaAIR 210 | 参考 | ✅ 移植（CRAZY 取 210） |
| 击倒技与普通技能的优先级区分 | 不区分（统一 +100） | `isHitDownAct ? order : order+100` | 参考 | ✅ 移植（CRAZY 区分） |
| 逐状态概率覆盖表（目标攻击中仍移动等） | 有，更激进 | 无 | 主项目 | ❌ 保留主项目（不反向移植） |
| 残影步取消（攻击落空后取消） | 有 | 无 | 主项目 | ❌ 保留主项目 |
| 防御槽见底停止防御（防破防） | 有 | 无 | 主项目 | ❌ 保留主项目（参考的行为属更差而非更难） |

结论：**只按单侧对齐会两头丢东西**。因此本轮的做法是"移植参考更激进的门槛，同时保留主项目更聪明的结构"，而不是整文件替换。


---

## 2. 改造设计

### 2.1 新增第 7 列（`FighterAILogicBase.as`）

| 位置 | 内容 |
|---|---|
| `L42` | 新增 `protected function get isCrazy() : Boolean { return this.AILevel >= 7; }` |
| `L121` | `getAIByFighterState()` 追加第 7 个实参：`_loc2_.length > 6 ? Number(_loc2_[6]) : NaN` |
| `L136` | `getAIResult(..., param6:Number, param7:Number = NaN)`；函数开头 `if(isNaN(param7)) param7 = param6;` |
| `L156-159` | `case 6: return _loc7_ < param6;` / `default: return _loc7_ < param7;` |

**兼容性契约（重要）**：概率表仍是 6 元素时 `getAIByFighterState()` 传回 `NaN`，`param7` 回落成 `param6`，即

> **没写第 7 列 = CRAZY 沿用 HELL 的取值。**

所以只有显式补了第 7 列的决策点，CRAZY 才会与 HELL 分档；等级 1~6 的取值不可能被影响（它们根本不读 `param7`）。
本轮全文件**只有 1 处**补了第 7 列：远距离冲刺（`FighterAILogic.as:409` 的 `[0.5,1,1.5,2.5,4,5.5,9]`）。
其余 CRAZY 增量全部走"门槛/守卫"而不是"概率值"——因为概率是**每帧重掷**的，8 与 10 在实战中几乎等价，真正决定行为的是门槛。

### 2.2 CRAZY 专属常量（`FighterAILogic.as:36-63`）

```as3
private var _crazyDashKeep:Number        = 200;  // 原 _dashKeep 250
private var _crazyDashEnergy:Number      = 40;   // 原 60
private var _crazyJumpKeep:Number        = 50;   // 原 _jumpKeep 300
private var _crazyBishaQi:int            = 100;  // 原 200（超必杀仍 300）
private var _crazyBishaSuperOrder:int    = 210;  // 原 100
private var _crazyDefenseReact:Number    = 200;  // 原 125
private var _crazyDefenseFarRate:Number  = 1;    // 原 0.2
```

取值规则是**逐项取主项目 HELL 与参考工程 HELL 中更激进的一侧**，并非"一律高于参考"：
`_crazyBishaQi / _crazyDashEnergy / _crazyJumpKeep / _crazyDefenseReact` 取自参考值；
`_crazyBishaSuperOrder` 则刻意取 210（参考的 bishaSUPER 是 200、bishaAIR 是 210），以便同时盖过本工程普通必杀的 115。

### 2.3 逐项改动

| 函数 | 改法 | 位置 |
|---|---|---|
| `updateJumpAI` | 局部取 `jumpKeep`，CRAZY 用 50 | `L299` |
| `updateDashAI` | 局部取 `dashKeep`/`dashEnergy`；远距分支第 7 列 = 9 | `L365`、`L409` |
| `updateDefenseAI` | 局部取 `reactDist`/`farRate`，三处（子弹/攻击体/助战）共用 | `L463`、`L515/529`、`L532/546`、`L549/563` |
| `updateAttackAI` | 新增 `if(this.isCrazy && !canHitTarget()) return;` | `L615` |
| `getSkillAI` | 同上（返回 false）；击倒技优先级区分 | `L698`、`L732` |
| `updateBisha` | 局部取 `bishaQi`（100）与 `superOrder`（210） | `L742`、`L747` |
| `getBishaAI` | 新增命中守卫；CRAZY **跳过终结过滤** | `L762`、`L793` |
| `updateGhostStep` | 补 `ghostJumpDowm` 判据（原为死代码） | `L982` |

`updateDashAI` 刻意**只取局部值、不改 `_dashKeep` 字段本身**，因为 `updateAssist()` 也在读该字段。

### 2.4 超必杀优先级为什么要动

`_contOrder` 的排序是 `sortOn("order", 2 | 0x10)`：

- `2` = `Array.DESCENDING`（降序）
- `0x10` = `Array.NUMERIC`（数值比较）

降序后 `updateContOrder()` 从索引 1 起把动作置 `false`，**只有索引 0（order 最大）留下** ⇒ **order 越大优先级越高**。
（旁证：3.9 官方版本同一处写的是 `sortOn('order', Array.DESCENDING)`，具名常量无歧义。）

主项目原先 `bishaSUPER` 的 order 是 100，低于普通必杀的 115，于是两招同帧同时掷中时**超必杀必被顶掉**。CRAZY 档取 210 修正该问题。

> ⚠ 调参方向别写反：想"更容易放出来"要**调大** order；想"给它让路"要**调小**。

### 2.5 击倒技优先级的方向

`getSkillAI` 里 CRAZY 用 `addContOrder(param1, param4 + (isHitDownAct(param2) ? 0 : 100))`。
结合上面的降序语义：**击倒技拿低优先级（+0）→ 给同帧的普通技能让路**，避免连招中途用击倒技断连。
这正是参考工程 `isHitDownAct(param2) ? param4 : param4 + 100` 的语义，**不是**"给击倒技加优先级"。

### 2.6 `canHitTarget()` 与 `targetCanBeHit()` 的区别

CRAZY 的出手守卫用的是新增的 `canHitTarget()`（`FighterAILogicBase.as:325`），**不是**原有的 `targetCanBeHit()`（`L286`）。原因：

- `isAllowBeHit` 声明在 `interfaces/BaseGameSprite.as:23`（`public var isAllowBeHit:Boolean = true;`），`FighterMain`/`Assister`/`FighterAttacker` 都继承它；只有 `Bullet`（`implements IGameSprite`）没有该字段。
- 本工程 `FighterAILogicBase.render()` 里写的是 `this._targetFighter = this._target;`（**没有** `as FighterMain`；参考工程有），字段类型也是 `*`。
- 于是当目标是 `Bullet` 时，`targetCanBeHit()` 会走 `_targetFighter.isAllowBeHit` 分支取到 `undefined` 而被判为"不可命中"。

`canHitTarget()` 用 `this._targetFighter is FighterMain` 分流，补回参考工程的语义。

**实践量级**：`FighterMain.getCurrentTarget()` 的择优顺序把存活 `FighterMain` 排在 order 0 最前，且 `Bullet` 不是 `TeamVO` 的子节点，所以正常对局里 `_target` 几乎总是对方 `FighterMain`，两者差别只在边缘情况体现。写新方法是为了语义与参考一致，**不是因为现网经常踩到**。

原有的 `targetCanBeHit()` **刻意未改**：它还被 `updateCache()` 的投技判定使用，改掉会波及 HELL 及以下。若要彻底修，应把 `_targetFighter` 声明为 `FighterMain` 类型并把 `render()` 改成 `_target as FighterMain`——那会改变 1~6 档行为，**必须另开一轮**，不能塞进本轮。

---

## 3. 顺带修掉的既有缺陷

| 缺陷 | 位置 | 说明 |
|---|---|---|
| `isHitDownAct()` 缓存串味 | `FighterAILogicBase.as:278/282` | 原先误写 `_breakActCache`，会污染 `isBreakAct()` 的缓存（把非破防技标成破防）。本修复消除交叉污染，并让 CRAZY 的击倒技判定可用 |
| `mergeRateObject()` 漏比 | `FighterAILogicBase.as:233` | `_loc4_` 只在函数开头初始化一次，第二个 key 起带着上一个 key 的越界下标继续比对 → 除首个 key 外全部漏比。**当前无调用点**（`setAIByMain` 走覆盖而非合并），所以无运行时效果，属预防性修复 |
| `ghostJumpDowm` 死代码 | `FighterAILogic.as:982` | 全方法只有开头 `= false`，无任何赋值点，`FighterAICtrl.ghostJumpDown()` 恒为 false。3.7 参考与 3.9 官方版同样存在（其判据 `_target.y - _fighter.y < 80 && > 100` 数学上不可能成立）。已按"三个残影步变体各管一个方向"补判据 |

---

## 4. 改这个子系统必须先知道的 4 个坑

### 4.1 `_contOrder` 是降序，order 越大越优先

见 §2.4。这是本轮最容易写反的地方。

### 4.2 Flash 的 y 轴向下为正

`_fighter.y > _target.y + keep` 表示**自己在目标下方**（数值大 = 屏幕位置低）。
`updateJumpAI` 里 `_fighter.y > _target.y + jumpKeep` 的含义是"自己在目标下方且落差够大 → 起跳追上去"；
`updateGhostStep` 里 `_fighter.y < _target.y - _jumpDownKeep` 的含义是"自己在目标上方 → 目标在下方 → 改走残影步下跳"。

### 4.3 `ghostJumpDown` 只在空中路径被消费

`FighterMcCtrler.as:724` 按 `isInAir` / `_doingAirAction` 分派：

| 路径 | 入口 | 消费的残影步 |
|---|---|---|
| `renderFloorAction()` | `:777` | `ghostStep()`（`:870`）、`ghostJump()`（`:874`） |
| `renderAirAction()` | `:989` | `ghostJump()`（`:1067`）、`ghostJumpDown()`（`:1071`） |

所以在地面把 `ghostJump` 换成 `ghostJumpDowm` 只会**白丢一次上跳**。本轮判据已加 `Boolean(_fighter.isInAir)` 限定。
另：该判据复用 `ghostJump` 同一掷骰，而 `_loc3_` 表的 CRAZY 列没补（回落 `param6 = 0.01`，约 1%/帧），所以它是**低频修正**，别当成明显提升。

### 4.4 概率是每帧重掷的

`FighterAILogic.render()` 每帧执行一次，`getAIByFighterState()` 每帧重新 `Math.random()*10`。
所以取值 8 / 9.5 / 10 在实战中差别极小（都在 1~2 帧内必触发），**调这些数字基本没有手感收益**；真正决定行为的是门槛与守卫。
反过来说，`0`、`0.1`、`0.5` 这类低位取值才是有意义的"稀有度旋钮"。

---

## 5. HELL 及以下不变的论证

CRAZY 增量全部由两类实现，且都带 `this.isCrazy` 短路：

1. **CRAZY 专属常量**：非 CRAZY 时局部变量取原值（`250`/`60`/`300`/`125`/`0.2`/`200`/`100`/`100`），逐位等价。
2. **新增守卫 / 跳过判定**：`this.isCrazy && ...` 或 `!this.isCrazy && ...`，非 CRAZY 时求值结果与原逻辑相同。
3. **第 7 列**：等级 1~6 的分支不读 `param7`；等级 6 由新增的 `case 6` 显式读 `param6`，取值与改造前的 `default` 完全一致。
4. **三处缺陷修复**：`isHitDownAct` 在改造前是**全工程无调用点**的死方法（`isBreakAct` 才是被用的那个），修好它本身不改变任何等级的行为；`mergeRateObject` 同样是死代码；`ghostJumpDowm` 的新判据带 `isCrazy`。

> 结论：**等级 1~6（含 HELL）的判定结果与改造前逐位一致。** 这与"只让 CRAZY 变难"的约定相符。

---

## 6. 验证证据

| 项 | 结果 |
|---|---|
| `./build.bat` | **Exit 0**，`tools/Test/launch.swf` 35,472,699 字节（2026-10-09 20:31） |
| mxmlc 告警 | 日志无任何 error / warning |
| 档位映射自检 | 等级 1~6 → 列 0~5（不变）；等级 7 → 6 元素表取列 5、7 元素表取列 6 |
| 7 元素表数量 | 全文件仅 1 处（远距离冲刺），其前 6 位与改造前逐位相同 |
| 意外删除 | 与备份逐行 diff：改动全部在清单内，无清单外的删除或改写 |
| 独立复核 | 2 个只读子代理复核：**方向写反 / 漏改 / 误删 / 等级回归 四类问题均未发现**；提出的 4 条 MINOR（注释事实错误、`ghostJumpDowm` 地面路径、注释数值依据、防御率隐式回落通道）已全部闭环 |

### 6.1 复核纠正过的一处自我错误（留档）

初版注释声称"`isAllowBeHit` 只定义在 `FighterMain` 上（已核对：Assister、FighterAttacker、BaseGameSprite 均无该字段）"。
**该结论是错的**——字段就在 `BaseGameSprite.as:23`。当时的核查只 grep 了 `fighter/` 目录就下了"已核对"的结论。
代码写法本身没错（`is FighterMain` + bodyArea 兜底与参考语义一致），但注释已改写为事实版本。
> 教训：`已核对` 这类断言必须给出被检索的确切文件，而不是只 grep 一个目录。

---

## 7. 回滚方式

```powershell
# 文件级回滚（改造前原件）
Copy-Item "BVNscripts\.backup\2026-10-09-1935-crazy-ai\FighterAILogic.as"     "BVNscripts\scripts\net\play5d\game\bvn\fighter\ctrler\ai\FighterAILogic.as" -Force
Copy-Item "BVNscripts\.backup\2026-10-09-1935-crazy-ai\FighterAILogicBase.as" "BVNscripts\scripts\net\play5d\game\bvn\fighter\ctrler\ai\FighterAILogicBase.as" -Force

# 或走 git 快照分支
git checkout backup/crazy-ai-2026-10-09-1935 -- BVNscripts/scripts/net/play5d/game/bvn/fighter/ctrler/ai/
```

改造前原件 SHA256（前 16 位）：`FighterAILogic.as = ED01605F347A154F`、`FighterAILogicBase.as = 17456444329A94F3`。

---

## 8. 调参速查（想改手感时看这里）

| 想要的效果 | 改哪个 | 方向 |
|---|---|---|
| CRAZY 更龟 / 更敢防 | `_crazyDefenseReact`（200）、`_crazyDefenseFarRate`（1） | 距离调小、概率调小 = 更收敛 |
| CRAZY 更早放必杀 | `_crazyBishaQi`（100） | 调小 |
| 超必杀更常出 | `_crazyBishaSuperOrder`（210） | 调大（注意 300 是攻击兜底档） |
| CRAZY 少跳一点 | `_crazyJumpKeep`（50） | 调大 |
| CRAZY 远距离冲刺更凶 | 第 7 列 9、`_crazyDashKeep`（200） | 概率调大、距离调小 |
| 整档拉平回 HELL | 删掉常量并用 `AILevel >= 7` 之外的条件，或直接把第 7 列去掉 | —— |

---

## 9. 未验证 / 后续

1. **实战强度只能真机体感确认**。静态证明的是"逐分支 CRAZY ≥ HELL"，不是"胜率更高"。最需要试的是 `_crazyDefenseReact = 200` 让 125~200px 距离每帧必防，可能让 CRAZY 变被动；若太龟，调回 150 即可。
2. **角色 SWF 里的 `AImain` 自定义概率表**是二进制内容，静态无法确认它是否给某些 `actionState` 返回 ≥7 元素的表。若返回 7 元素表，CRAZY 会读它的第 7 列并**覆盖**内联表；元素不是数字时 `Number()` → `NaN` → 回落到 `param6`，安全。要确认只能运行期打日志。
3. **`ghostJumpDowm` 全链路**（`FighterAICtrl.ghostJumpDown()` → `FighterMcCtrler` 的 `doGhostJumpDown()`）的实际位移与落地表现需真机验证。
4. **`build.bat` 会覆盖 `Debugger.as` 的批号**：其正则把批号硬编码成 `6.14`，所以每次构建都会把手工写的 `batch6.15-*` 改回 `batch6.14-*`。这是既有行为，本轮未改 `build.bat`。

---

## 10. HELL / CRAZY 随机纽带连招（2026-10-13 新增）

> 决策与工期记录见 [`doc/decisions-ai-link-chain.md`](../decisions-ai-link-chain.md)。本节只记实现事实与调参入口。

### 10.1 需求与落点

需求原文：「只要此招式有纽带可用（即允许某个技能或动作）时，随机选择一个非基础动作（除走跑跳）的纽带执行」。

落点：`FighterAILogic.as` 新增 `updateLinkAI()`，在 `updateActionAI()` 最后调用（`updateSpecialSkill()` 之后）。**只改这一个文件**；`AILevel < 6` 时第一句就 `return`，所以等级 1~5 行为与改造前逐位一致，HELL 与 CRAZY 共用同一套逻辑、只有概率门不同。

### 10.2 为什么只能做在「非出招态」（关键前提）

「纽带」= `FighterAction` 上的动作槽（`attack`/`skill1`/`zhao1`/`bisha`…），帧脚本用 `setXxx()` 填入帧标签即为可用，由 `FighterMcCtrler.renderFloorAction()`/`renderAirAction()` 的 if 链消费。

**`doAction()`（FighterMcCtrler.as:1226）每次起手都会先 `clearAction()` 把 24 个槽全部置 null** ⇒ 出招进行中读不到任何纽带，"某招式的纽带"这个概念在出招期间不存在。因此本功能做在 `NORNAL(0)` / `JUMP_ING(14)` 两个非出招状态：把「当前可用且够得着」的非基础纽带随机挑一个置 true，走引擎原有的 if 链执行。

**与原概率链是叠加关系**：`updateAttackAI`/`updateSkill`/`updateBisha` 的距离判定与概率全部不动，本方法只是额外多出一个高优先级候选。

### 10.3 实现要点

| 项 | 取值 | 说明 |
|---|---|---|
| `_linkOrder` | **999** | `updateContOrder()` 用 `sortOn("order",2\|0x10)` 降序仲裁，999 稳定压过既有最大值（attack 的 300、超必杀的 210），保证掷中不被顶掉 |
| `_linkRateHell` / `_linkRateCrazy` | **6 / 10** | 走 `getAIResult(0,0,0,0,0,6,10)`：HELL 读 param6=6（约 60%/帧），CRAZY 读 param7=10（必中） |
| `_linkFallbackDist` | **140** | 判定面不可用时的通用距离闸 |
| `_linkCooldown` | **30 帧** | 掷中但 `doAction` 未被消费（`doCatch` 不允许 / `useQi` 不足）时清标志重掷，避免该槽被永久占住 |
| 状态闸 | `NORNAL(0)` / `JUMP_ING(14)` | 其余状态（受击/防御/出招中/死亡/变身）一律不触发 |

**候选池**（地面）：`attack, skill1, skill2, zhao1, zhao2, zhao3, catch1, catch2, bisha, bishaUP, bishaSUPER`；**空中**：`attackAIR, skillAIR, bishaAIR`（仅 `isInAir` 时入池）。

**排除项**：基础动作 `moveLeft/moveRight/jump/jumpQuick/jumpDown/dash/defense`、落地与碰撞跳帧 `touchFloor/hitTarget`、被动反制 `hurtAction`、变身 `waiKai/waiKaiW/waiKaiS`。

**入池三重闸**：① 槽非空；② 气量够（`bisha/bishaUP/bishaSUPER/bishaAIR` 前置判 `_fighter.qi >= _fighterAction.xxxQi` —— 执行层 `doBisha` 虽有 `useQi` 兜底，但不前置筛就会"掷中了却放不出来"）；③ 够得着。

### 10.4 AImain 缺失的隐患（本轮修掉的一个真实风险）

判定面（`kanmian`/`kj1mian`/`bsmian`…）来自角色 MC 里的 **`AImain` 子元件**：`FighterMC.initHitRange()`（FighterMC.as:575-592）会对 `getChildByName("AImain")` 取到的对象调 `gotoAndStop(2)`，**AImain 缺失时那里会取到 null 并抛错**。

所以 `linkRangeOK()` 写成 `if(!this.AImain || !_fighter.getHitRange(面)) → 退回通用距离判定`，靠短路求值保证没有 AImain 时**根本不会调到 `getHitRange`**。第二种回退是"有 AImain 但该面没定义"（`_hitRangeObj` 取到 undefined），此时 `targetInRange` 恒为 false，不退回距离判定的话缺面的角色永远掷不出该招。

### 10.5 调参速查

| 想要的效果 | 改哪个 | 方向 |
|---|---|---|
| HELL 少接招 / 更自然 | `_linkRateHell`（6） | 调小（0 = 关闭 HELL 侧） |
| CRAZY 不要每帧必接 | `_linkRateCrazy`（10） | 调小 |
| 降低抢招优先级（让原概率链赢） | `_linkOrder`（999） | 调到 300 以下 |
| 拉开/拉近"够得着"的兜底距离 | `_linkFallbackDist`（140） | 调大 = 更远就敢出 |
| 整体关闭本功能 | `updateLinkAI()` 首句改成无条件 `return`，或把 `AILevel < 6` 改成 `< 99` | —— |

### 10.6 回滚

```powershell
# 本轮改造前原件（时间戳见 .backup/）
Copy-Item ".backup/FighterAILogic.as.<YYYY-MM-DD-HHMM>" "BVNscriptsscripts
etplay5dgamevnighterctrleraiFighterAILogic.as" -Force
```

### 10.7 未验证项

1. **实战强度未验证**：`./build.bat` 零错误、逻辑静态自查通过，但"AI 是否真的更爱连招""会不会显得抽搐"只能真机体感确认。
2. **CRAZY 只能手机端验证**：PC 端 `SetBtnGroup.as` 菜单只到 HELL=6，CRAZY=7 的入口在 `mob/GameInterfaceManager.as`。
3. **`_linkFallbackDist` 是否合适**：缺 `AImain` 的角色实际有多少、140 这个量级是否合理，需真机遇到缺面角色时才能确认。
