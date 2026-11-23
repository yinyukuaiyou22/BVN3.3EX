# 拼招机制 实施方案

> 状态：**方案（未实现）**。本文只写设计与改动，不含代码。
> 依据：用户 2026-11-23 给出的规则口径；代码事实取自 `BVNscripts/scripts/net/play5d/game/bvn/`（行号以 2026-11-23 当天的源码为准）。
> 规则改动时：先改 §3，再看 §8 的改动清单与 §13 的任务分解是否需要跟着调。

---

## 1. 目标

在两方攻击判定同时接触的那一拍插入一次裁决，把现在的「双中」（两边一起进受击）改成有明确胜负的拼招：赢家拿一次全技能纽带窗口，输家吃打防效果，同级同时出则双方弹开。

### 1.1 为什么必须改代码

现状没有这个机制，也不是配置或数据能表达的：`checkHit()` 把两向命中都算出来之后**无条件分别应用**（`GameMainLogicCtrler.as:384-395`），谁都不会取消对方。所以拼招只能是新的判定与结算逻辑，落在主循环里。

### 1.2 范围

- 只改主项目 `BVNscripts/scripts/`；不加美术资源也能跑（特效可降级）。
- 不改角色包契约：138 个角色包一行都不用动。
- 不改必杀、抓取、子弹、辅助的既有结算。

### 1.3 非目标

- 不做「刀锋对撞」（攻击盒互撞但都没打到身体）判定。
- 不做网络预测/回滚；LAN 帧锁只要求两端同拍同序。
- 不重做受击/防御状态机，只复用它们的数值口径。

---

## 2. 术语

| 术语 | 含义 | 代码锚点 |
|---|---|---|
| 拼招 | 同一逻辑拍内，双方攻击判定都命中对方身体 | `checkHit` 的 A→B 与 B→A 同时成立 |
| 面长 | 命中瞬间，攻击盒在朝向上的外沿到角色根的横向距离 | `HitVO.currentArea` + `FighterMain.x` |
| 后出 | 招式起手更晚（全局渲染帧号更大） | `doAction` 时的 `GameCtrl.renderFrame` |
| 同时出 | 两侧起手帧差在容差内 | `CLASH_SIM_WINDOW` |
| 打防效果 | 防御受创的数值与表现：掉 5%、扣气、硬直、后退、不倒地 | `doDefenseHit` 的口径 |
| 全技能纽带 | 一段窗口内把普攻/砍技/招式的动作槽全部打开 | `setClashLinkAct`（组合既有 setXxx） |
| 弹开 | 双方后退、短暂不可打、无伤害、无纽带 | 新增 `doClashRecoil` |

---

## 3. 已确认规则（用户拍板，2026-11-23）

### 3.1 优先级：四级字典序

前一级分出胜负就不再往下比。全相等才判同时出。

| 级 | 规则 | 数据来源 |
|---|---|---|
| 1 | 重击 > 轻击 | `HitType.isHeavy(hitType)`，重击类 = 6/3/5/7/8/9 |
| 2 | 击倒 > 不击倒 | `HitVO.hurtType == 1` |
| 3 | 面长 > 面短 | 实际攻击盒外沿 − 角色根 x，容差 2px 内算相同 |
| 4 | 后出 > 先出 | 起手帧号大者胜；差 ≤1 渲染帧算同时 |
| 5 | 全相等 | 同时出 → 双方弹开 |

### 3.2 参与范围

只让「角色本人的近身判定」与「攻击体 `FighterAttacker`」参与。以下一律不参与，照旧走原来的双中：

- 必杀：`actionState` 为 12/13，或命中区来自 `bsmian/kbsmian/sbsmian/cbsmian`；
- 抓取摔技：`hitType == 11` 或 `HitVO.isCatch()`；
- 子弹 `Bullet`、辅助 `Assister`；
- 处于无敌态的一方（钢体/冲刺/替身术/换人无敌）——身体矩形本来就是 null，不构成候选。

### 3.3 奖励与惩罚

- 赢家：一次性「全技能纽带」窗口，默认 8 拍（30Hz 节拍，约 0.27s）；地面开放普攻/砍技1/砍技2/招1/招2/招3，空中只开放跳砍/跳招；**不消耗气**。
- 输家：打防效果，不倒地、不进受击状态；掉血 5%、扣气 `伤害/5`（上限 50）、硬直 5~10 拍、按 `hitx` 后退；气不足走破防。
- 同时出：双方弹开，都不拿纽带，都不掉血。

### 3.4 口径说明

- 面长用**命中瞬间的实际攻击盒**，不是 `AImain` 的声明范围：玩家眼里的「谁手长」就是这一下实际打到多远。
- 重击统一按 `HitType.isHeavy`，不按数值大小比较（`hitType=10` 石化不在重击表里，按数值比会把它判成重击）。
- 2P 补偿不靠猜：机制本身不依赖遍历顺序，另有 1 帧同时窗口与可配置的每侧偏移常数，常数默认 0，实测后再填（见 §12）。

---

## 4. 现状事实（代码）

这一节是方案的地基，改之前先核一遍；行号变了以源码为准。

### 4.1 伤害唯一收口

`GameMainLogicCtrler.checkHit(A,B)`（`GameMainLogicCtrler.as:345-396`）是全工程唯一的伤害判定入口：

- 双循环遍历 `teamMap.teams[i].children[k]` 与 `teams[j].children[l]`，`j > i`，所以 P1 恒为 `param1`；
- 先把两向命中都算出来：`_loc7_ = getHitObj(A 的判定, B 的身体)`、`_loc8_ = getHitObj(B 的判定, A 的身体)`（384-385）；
- 再依次应用：先 `B.beHit(...)`+`A.hit(...)`，后 `A.beHit(...)`+`B.hit(...)`（386-395）。

推论：**今天同帧互殴是双中**，且 P1 先落地。

### 4.2 攻击体、子弹、辅助也在队伍里

`GameCtrl.addGameSprite(teamId, sprite)` 会 `team.addChild(sprite)`（`GameCtrl.as:213-237`），`FighterEventCtrl` 造的攻击体（`addAttacker`, 54-67）与子弹（`fireBullet`, 36-47）、辅助都走这条路。所以上面的双循环同样覆盖它们——拼招必须显式排除，否则「一次普攻 + 一个残影」会被判两次。

### 4.3 判定跑在 30Hz

`GameCtrl` 初始化：`_renderAnimateGap = ceil(FPS_GAME/30) - 1`（`GameCtrl.as:105`，60fps 时为 1）；`checkRenderAnimate()` 隔帧才调 `renderAnimate()` 置 `_renderAnimate = true`（850-864）；`checkHit` 只在该标志为真时执行（129-131），循环末尾复位（143）。

推论：**一拍 = 33ms**。所以「同一帧」的容差要按 60Hz 渲染帧号量，不能按 30Hz 逻辑帧量。

### 4.4 受击与打防

- `FighterMain.beHit` 第一行就是 `!isAllowBeHit` 早退（`FighterMain.as:600-605`），无敌态天然不参与；
- `FighterMcCtrler.beHit`（1655-1711）分三支：防御态 → `doDefenseHit`（2119-2181，掉 5%、扣气、硬直、`isDefenseHiting`）；钢体 → `doSteelHurt`；其余 → `doHurt`（1798-1893，`hurtType==1` 走击飞）；
- `doDefenseHit` 只在 `_isDefense` 为真时被调用，且气不足时转 `doBreakDefense`（2183-2226）。

### 4.5 纽带就是动作槽

`FighterAction` 上有 24 个 String 槽（attack/skill1/skill2/zhao1..3/catch1..2/bisha…，`FighterAction.as:47-93`），角色帧脚本按帧写槽；全槽位开放已有现成方法：`setAllAct()`（地面，`FighterMcCtrler.as:259`）、`setAirAllAct()`（空中，280）。各 `setXxx()` 都先 `_mc.checkFrame(name)`，缺帧静默 return（351-479）。

**寿命是难点**：`doAction()` 每次起手都 `clearAction()` 把 24 个槽清空（1269），且角色帧脚本每帧还会重写自己的槽。所以纽带只能做成「窗口内每帧重放一层覆盖」，不能一次赋值了事。

### 4.6 全仓库没有拼招

`拼招|拼刀|对拼|clash` 只命中 `FighterAILogic.as` 里一处注释。这是纯新增，没有历史实现要兼容。

---

## 5. 目标架构

### 5.1 三层

1. **判定层（只读数值）**：新增 `ClashResolver`，输入两个命中 VO 与两个角色，输出「A 赢 / B 赢 / 同时 / 不算拼招」。不碰显示对象、不改状态，纯函数，将来可搬去做离线用例。
2. **调度层**：`GameMainLogicCtrler.checkHit` 改成三段：收集 → 裁决 → 应用。裁决不改变「不拼招时」的既有行为。
3. **执行层**：赢家 `grantClashLink`、输家 `doClashGuard`、同时出 `doClashRecoil`；三者都在 `FighterMcCtrler` 上，复用既有受击/防御的状态字段。

### 5.2 为什么不放在 beHit 里

`beHit` 是「事后」。先应用的一方已经把对手打进受击并把 `isAllowBeHit` 置 false，此时再判拼招，拿到的是被污染的状态。唯一正确的位置是两向都算完、尚未应用的那一段。

### 5.3 为什么要全局帧号

`_doActionFrame` 只能在同一角色内比大小（起手时清零、每拍 +1），跨角色不可比；`doActionTimes` 是每角色自增，也不能跨角色比。要在两侧之间比「谁后出」，必须有一个全局单调的渲染帧号。

### 5.4 影响面

改动落在核心判定链（`checkHit`）与角色状态机（`FighterMcCtrler`），属于跨模块改动：所有角色、所有模式、AI、TAG、LAN 都会经过这条路径。因此开关默认给「关掉即完全等于今天」，并且第一版不做设置页，只留 `ConfigVO`。

---

## 6. 关键算法

### 6.1 三段式

```as
// GameMainLogicCtrler.checkHit(A, B)
// 1 收集：语义与今天完全一致
var a2b:Object = getHitObj(A.getCurrentHits(), bodyB);
var b2a:Object = getHitObj(B.getCurrentHits(), bodyA);

// 2 裁决：只有两向都成立才可能是拼招
var v:ClashVerdictVO = null;
if (a2b && b2a && !claimed(A) && !claimed(B))
    v = ClashResolver.I.judge(a2b.hitVO, A, b2a.hitVO, B, GameCtrl.I.renderFrame);

// 3 应用
if (v == null) {                       // 非拼招：与今天逐行一致
    if (a2b) { B.beHit(a2b.hitVO, a2b.hitRect); A.hit(a2b.hitVO, B); }
    if (b2a) { A.beHit(b2a.hitVO, b2a.hitRect); B.hit(b2a.hitVO, A); }
} else {
    claim(A); claim(B);                // 每角色每拍最多一次
    if (v.type == WIN_A)      { A.grantClashLink(); B.doClashGuard(v.hitVO, v.rect); }
    else if (v.type == WIN_B) { B.grantClashLink(); A.doClashGuard(v.hitVO, v.rect); }
    else                      { A.doClashRecoil(B, v.rect); B.doClashRecoil(A, v.rect); }
}
```

`claimed` 用「角色 → 帧号」的戳，换帧即失效。多对多（2v2/TAG）时先到先得，排序键是全确定性的（优先级 → team id → 精灵下标），保证两端一致。

### 6.2 资格过滤

```text
eligible(vo, fighter):
  vo != null && fighter != null
  且 !vo.isBisha()
  且 !vo.isCatch() && vo.hitType != HitType.CATCH
  且 fighter.actionState 属于 {10 ATTACK_ING, 11 SKILL_ING}   // 12/13 必杀不在内
```

不用 `vo.id` 字符串判必杀：角色包命名不统一，`isBisha()` 只认 `bs/sbs/cbs/kbs` 子串。

### 6.3 排序键

```text
key(vo, f) = [ heavy(vo) ? 1 : 0,
               vo.hurtType == 1 ? 1 : 0,
               reach(vo, f),
               effectiveStart(vo, f) ]

reach = (f.direct > 0) ? (vo.currentArea.right - f.x) : (f.x - vo.currentArea.left)
effectiveStart = startFrame(vo) - CLASH_SIDE_LAG[f.team.id]

startFrame: FighterMain / FighterAttacker → 该角色当前动作的起手帧；
            其他 owner（Bullet / Assister）→ 不合格，直接返回「不算拼招」。
```

比较：heavy、knockdown 逐位比；reach 差在 ±2px 内算相等；effectiveStart 差在 ±1 帧内算相等；四项全平 → 同时。

### 6.4 面长的锚点

必须用**角色根 x**，不能用攻击体自身的 x：跟随目标（`followTargetX`）与位移（`moveToTargetX`）的攻击体会把自己挪到目标身上，用它的 x 作锚会让「贴身飞行道具」判成手最长。锚点定在角色根，量的是「从人到打击点」的距离。

### 6.5 赢家：纽带窗口

```text
grantClashLink():
   _clashLinkFrame = CLASH_LINK_TICKS          // 8 拍

FighterMcCtrler.render()：在封输入检查之后、输入轮询之前
   if (_clashLinkFrame > 0) setClashLinkAct(_fighter.isInAir)

FighterMcCtrler.renderAnimate()：与其它计时器同节拍
   if (_clashLinkFrame > 0) --_clashLinkFrame

doAction()：任何起手都清零（起手即消费）
   _clashLinkFrame = 0
```

`setClashLinkAct(inAir)` 只组合技能槽，不动移动/跳跃/防御/瞬步/万解/摔技：

```text
地面：setAttack() setSkill1() setSkill2() setZhao1() setZhao2() setZhao3()
空中：setAttackAIR() setSkillAIR()
```

每次调用都走既有 `checkFrame` 保护：角色包缺某个帧标签，那一格自动跳过，不报错、不崩，表现为「奖励缩水」。

### 6.6 输家：打防 + 判定压制

`doClashGuard(hitVO, rect)` 从 `doDefenseHit` 抽出，去掉 `_isDefense` 前置，其余口径不变：5% 掉血、扣气 `伤害/5`（上限 50）、`_defenseHoldFrame` 5~10、`_beHitGap` 4（`hurtType==1` 时 8）、`hitx` 方向后退、气不足转 `doBreakDefense`、`doDefenseEffect` 火花。

同时置 `_clashGuardFrame = _defenseHoldFrame`，窗口内：

- `FighterMain.getCurrentHits()` 直接返回 null；
- `FighterAttacker.getCurrentHits()` 在主人的 `isClashGuardLocked()` 为真时返回 null。

否则会出现「拼输了但同一招下一拍又打中对方」——观感上等于没输。

### 6.7 同时出：弹开

`doClashRecoil(other, rect)`：

```text
_clashGuardFrame = CLASH_RECOIL_FRAMES      // 6 拍，判定压制同上
_action.isDefenseHiting = true; _defenseHoldFrame = 6
setVelocity(±CLASH_RECOIL_SPEED, 0); setDamping(0.1, 0)
isAllowBeHit = false（_beHitGap = 6，结束自动恢复）
EffectCtrl doClashEffect(rect, direct) —— 找不到资源时降级到 doDefenseEffect
```

不扣血、不扣气、不给纽带。

---

## 7. 常量与开关

新增到 `GameConfig`（沿用既有命名风格，见 `DEFENSE_LOSE_HP_RATE` 一带）：

| 常量 | 默认 | 说明 |
|---|---|---|
| `CLASH_SIM_WINDOW` | 1 | 起手帧差 ≤ 此值算同时（渲染帧） |
| `CLASH_REACH_EPS` | 2 | 面长相等的容差（px） |
| `CLASH_SIDE_LAG` | `[0,0]` | 每侧起手帧偏移补偿，下标 = team id；实测后填 |
| `CLASH_LINK_TICKS` | 8 | 纽带窗口长度（30Hz 拍） |
| `CLASH_GUARD_HOLD_MIN/MAX` | 5 / 10 | 输家硬直下限/上限 |
| `CLASH_RECOIL_FRAMES` | 6 | 弹开后的判定压制与硬直 |
| `CLASH_RECOIL_SPEED` | 6 | 弹开后退速度 |

开关：`ConfigVO` 加 `clashEnabled:Boolean = true`（沿用 `optoinKey` 绑定约定，注意是错拼）。第一版不改设置页，只留字段与训练模式入口。

日志：`Debugger` 加 `DIAG_CLASH`（默认 false，逐帧候选与完整数值）；另加一条**常开**的低频判据日志，每次拼招一行：

```text
【拼招】f=1832 A=鸣人[3] h=1 k=0 r=132.0 s=1830 | B=佐助[3] h=0 k=1 r=140.5 s=1830 => B 赢(击倒)
```

---

## 8. 逐文件改动清单

路径都相对 `BVNscripts/scripts/net/play5d/game/bvn/`。

| # | 文件 | 改动 | 行为影响 | 风险 |
|---|---|---|---|---|
| 1 | `GameConfig.as` | 新增 §7 的 8 个常量 | 无（未读） | 低 |
| 2 | `data/ConfigVO.as` | `clashEnabled` 字段 + 存取 | 默认 true | 中（设置项要接 `optoinKey`） |
| 3 | `Debugger.as` | `DIAG_CLASH` | 无 | 低 |
| 4 | `ctrl/game_ctrls/GameCtrl.as` | `renderFrame:uint`，`render()` 里 pause 早退之后自增 | 新增只读计数 | 低 |
| 5 | `fighter/ctrler/ClashResolver.as` | **新增**：`judge` + 比较 + 面长 + 资格过滤 | 纯逻辑 | 中 |
| 6 | `fighter/models/ClashVerdictVO.as` | **新增**：结果对象（类型/赢家/输家/理由/数值快照） | 无 | 低 |
| 7 | `fighter/ctrler/FighterMcCtrler.as` | `_actionStartFrame`（`doAction` 埋点）、`_clashLinkFrame`、`_clashGuardFrame` 相关、`grantClashLink`、`setClashLinkAct`、`doClashGuard`、`doClashRecoil` | 中 | 高（状态机敏感） |
| 8 | `fighter/FighterMain.as` | `getActionStartFrame()` 转发、`getCurrentHits()` 压制早退、`_clashGuardFrame` 递减、`resetClashState()`（离场/重开清窗口） | 中 | 中 |
| 9 | `fighter/FighterAttacker.as` | `getCurrentHits()` 在主人被压制时返回 null | 低 | 低 |
| 10 | `ctrl/game_ctrls/GameMainLogicCtrler.as` | `checkHit` 三段式化；`claim` 戳；拼招日志 | 高 | **高（核心）** |
| 11 | `ctrl/EffectCtrl.as` | `doClashEffect`（缺资源降级） | 低 | 低 |
| 12 | `doc/` | 本文 + `doc/README.md` 索引 + `CLAUDE.md` 参考表一行 | 无 | 低 |

不改：`FighterAction`（沿用现成槽位）、`FighterMC`（判定区缓存不动）、`EffectModel`（第一版不新增特效定义）、任何角色包。

---

## 9. 实现难点

按「现象 / 原因 / 对策」写。这一节是实现时真正会卡住的地方。

### 9.1 时序类

**D1 注入点晚一步就废**
现象：在 `beHit` 里判拼招，永远判不出双赢，或者只能判出「后到的那个」。
原因：先应用的一方已经把对手打进受击并把 `isAllowBeHit` 置 false；等到第二向应用时，状态已被污染。
对策：只在 `checkHit` 两向都算完、尚未应用的窗口裁决（§5.2）。

**D2 判定是 30Hz，「同帧」不等于 16.7ms**
现象：按 30Hz 逻辑帧写容差，手感上会变成「差两拍还判同时」，拼招会抢掉正常连招的先手。
原因：`_renderAnimateGap` 让 `checkHit` 隔帧执行（§4.3）。
对策：起手帧号取 60Hz 渲染帧，容差 1 帧（≈16.7ms）。

**D3 单线程 + 遍历顺序**
现象：P1 恒先结算；任何「谁先到谁判赢」的写法都天然偏 P1；同时出会被写成两个人都赢。
原因：`checkHit` 的双循环顺序固定，P1 是 `param1`（§4.1）。
对策：裁决只读数值、不比顺序；多对拼用确定性排序键（优先级 → team id → 精灵下标）。

**D4 一人多判定体**
现象：普攻判定 + 残影/攻击体同拍命中，会被判两次拼招，屏幕上出现两次火花与两份纽带。
原因：攻击体、子弹都是独立精灵、独立 `checkHit` 配对（§4.2）。
对策：每角色每拍一次 `claim`，其余接触回落普通结算；子弹/辅助本就不合格。

### 9.2 数据口径类

**D5 面长的锚点会骗人**
现象：用攻击体 x 作锚，「跟随目标」的攻击体会被判成手最长。
原因：`followTargetX/moveToTargetX` 会把攻击体挪到目标身上（`FighterAttacker.init`, 211-267）。
对策：锚点固定为角色根 x（§6.4）。

**D6 重击口径**
现象：按 `hitType` 数值大小比，`hitType=10`（石化）会被判成比重击还重；但 `HitType.isHeavy` 里没有 10。
原因：`heavyTypes = [6,3,5,7,8,9]`（`HitType.as:28`）。
对策：统一用 `isHeavy`，并把这条口径写进文档与训练模式提示。

**D7 打防被 `_isDefense` 门控**
现象：直接调 `doDefenseHit`，非防御态下什么都不发生，或者只弹一下不掉血。
原因：它只在 `beHit` 的防御分支里被调用（1686-1702）。
对策：抽 `doClashGuard`，去掉前置判断，保留 5%/扣气/硬直/破防分支。

**D8 输家「输了还打中」**
现象：只给硬直不压制判定，输家同一招下一拍的判定还会命中赢家。
原因：判定来自角色 MC 与攻击体，硬直不回收它们。
对策：`_clashGuardFrame` 窗口内 `getCurrentHits()` 与其攻击体一律返回 null（§6.6）。

### 9.3 状态机类

**D9 纽带的寿命**
现象：一次性写槽，下一次 `doAction` 或角色帧脚本就把它擦掉，玩家几乎点不出来。
原因：`clearAction()` 在每次起手（1269），帧脚本每帧重写槽位。
对策：窗口内每帧在输入轮询前重放覆盖层；起手即消费（§6.5）。

**D10 空中/地面两套槽**
现象：在空中给地面槽，角色会在空中起手地面招式；多数角色包缺对应帧标签，静默哑火甚至卡帧。
原因：`setAirAllAct` 只有跳砍/跳招/空中必杀（280-287）。
对策：按 `isInAir` 分套；`setXxx` 自带 `checkFrame` 保护，缺帧自动降级。

**D11 无敌门有两个 owner**
现象：只判 `isAllowBeHit` 会把换人无敌当成可打；只判 `tagInvincibleFrame` 会漏钢体与替身术。
原因：`checkHit` 里「不可被打」由控制器标志与 TAG 谓词共同表达（366-383）。
对策：候选资格照抄现有写法，身体矩形为 null 就天然不参与，不另立一套。

**D12 必杀与抓取的边界**
现象：必杀自带时停与无敌，参与拼招会把整段演出截断；抓取 `hitType=11` 且 `isBreakDef` 会走破防分支。
原因：两者都不是「对撞」语义。
对策：按 `actionState(12/13)` 与 `isCatch()` 双重排除，不依赖 `id` 字符串。

### 9.4 兼容类

**D13 AI**
现象：AI 在同一拍「后手」出招会系统性赢拼招，难度失真；CRAZY 档尤其明显。
原因：AI 走同一 `checkHit`，但它的出招时机由概率表决定，不承担拼招风险。
对策：第一版不特殊化，先观察；若出现「贴脸必拼赢」，在 `FighterAILogic` 加拼招回避（后排他），不改 AI 概率表结构。

**D14 LAN 帧锁**
现象：两端遍历顺序或帧号不同，同一拍会判出不同结果，直接表现为「对面赢了但我这边没掉血」。
原因：裁决依赖帧号与配对顺序。
对策：只读数值 + 全确定性排序键 + 在帧锁同一拍内完成收集与裁决；不引入额外的「延迟结算」。

**D15 表现资源**
现象：没有 clash 专属特效与音效，做不出「叮」的那一下。
原因：`EffectModel` 只有 hit/defense/steel 三类。
对策：第一版降级复用 `doDefenseEffect` 火花；`doClashEffect` 找不到资源就静默降级，绝不因为缺特效而影响结算。

**D16 重开与换人**
现象：换人/重开/回合结束没清窗口，下一场带着「纽带」或「判定压制」进场。
原因：`_clashLinkFrame`/`_clashGuardFrame` 是新计时器。
对策：`FighterMain.resetClashState()` 在 `destory`、`resetExplodeState`、回合重置三处调用；TAG 换出的角色必须清零。

---

## 10. 兼容与回归边界

- **开关关闭 = 今天**：`clashEnabled=false` 时 `judge` 直接返回 null，`checkHit` 走原分支，逐行等价。
- **不改 `beHit` 语义**：拼招不调用 `beHit`，受击/钢体/替身/灵爆的既有链路完全不动。
- **角色包零改动**：缺帧静默降级；没有 AImain 的角色包不受影响（面长不用 AImain）。
- **模式**：VS / 竞技 / 剧情 / 1v2 / 2v2 / TAG 全走同一路径；TAG 换人无敌不入拼招。
- **训练模式**：可开拼招判据可视化（第二版），第一版只在日志里看。
- **录像/重开**：`GameLogic.clearAllHits()` 不受影响；新计时器必须随角色重置（§D16）。

---

## 11. TDD 路线与验收

### 11.1 路线

```text
TDD Route: mode=off, decision=skipped, authority=项目现状（AS3 无单测框架，验收靠 ./build.bat + 训练模式用例 + 回归矩阵）
```

但 `ClashResolver.judge()` 写成只吃数值的纯函数（不 import 显示对象），将来若引入单测可直接搬。

### 11.2 必现场景清单

| # | 布置 | 期望判定 | 期望表现 | 日志判据 |
|---|---|---|---|---|
| 1 | 同级同重同长，同拍命中 | 同时 | 双方弹开、无伤、无纽带 | `=> 同时` |
| 2 | 重击 vs 轻击，同拍 | 重击方赢 | 输家 5% + 扣气 + 硬直，赢家 8 拍窗口 | `=> A 赢(重击)` |
| 3 | 同为重击，击倒 vs 不击倒 | 击倒方赢 | 同上 | `=> A 赢(击倒)` |
| 4 | 同重同击倒，长面 vs 短面 | 长者赢 | 同上 | `=> A 赢(面长)` |
| 5 | 同重同击倒同面，差 3 帧 | 后出赢 | 同上 | `=> B 赢(后出)` |
| 6 | 其余全同，差 1 帧 | 同时 | 双方弹开 | `=> 同时` |
| 7 | 空中对撞 | 按四级判 | 赢家只拿到跳砍/跳招，按地面键无反应 | `inAir=1` |
| 8 | 必杀 vs 普攻 | 不算拼招 | 原逻辑：普攻打在无敌上 | 无【拼招】行 |
| 9 | 抓取 vs 普攻 | 不算拼招 | 原逻辑 | 无【拼招】行 |
| 10 | 子弹 vs 普攻 | 不算拼招 | 原逻辑 | 无【拼招】行 |
| 11 | 拼输后 6~10 拍内 | — | 输家判定全部失效，不会反打中 | `guardLock=1` |
| 12 | 钢体 / 替身 / 换人无敌中 | 不算拼招 | 走原无敌链路 | 无【拼招】行 |
| 13 | TAG 2v2 两人同时贴身 | 每角色每拍最多一次 | 不出现两次火花 | 单拍内【拼招】≤ 对数 |
| 14 | AI vs AI 高难度 | 同规则 | 无明显「必拼赢」 | 统计 20 次胜负分布 |

### 11.3 验收判据

1. `./build.bat` 零错误（改动含 4 个以上 `.as`，按规则先查基线）。
2. 关闭开关时，同一段对拼录像的受击帧与改动前一致（逐帧比对日志）。
3. 场景 1~14 全过；`【拼招】` 日志能一眼看出是哪个维度决出的胜负。
4. 真机（MuMu）30 分钟对局无新增异常日志、无永久硬直、无永久不可打。

---

## 12. 2P 一帧：实测探针

用户观察到「2P 落后一帧渲染」。代码里没找到每侧固定延迟的分支：两侧走同一个 `FighterKeyCtrl`、同一次 `renderGameSprite` 循环，差异只有遍历顺序（P1 恒 `param1`）。所以先测再补，不拍脑袋。

### 12.1 探针

`DIAG_CLASH` 打开时，在 `checkHit` 的接触点打一行：

```text
[HIT] f=1832 atk=鸣人[P1] st=1830 vs 佐助[P2] st=1831 | 30Hz拍=916
```

字段：渲染帧号、攻击方、起手帧、受击方、受击方起手帧、逻辑拍号。

### 12.2 采样

训练模式或双人同键盘，同一拍对按攻击（或用两台虚拟手柄同时按），录 20 次同拍对拼。

### 12.3 判据

- 20 次里 ≥18 次差值恒定同号同值（例如永远是 P2 的起手帧大 1）→ 存在固定偏移，`CLASH_SIDE_LAG[2] = 1`；
- 差值在 0/±1 之间随机分布 → 属于采样抖动，常数保持 0，只靠 1 帧容差；
- 出现 ±2 以上 → 不是「一帧」问题，回到 `FighterMcCtrler` 的输入路径另查（`_jumpDelayFrame`/`_defenseFrameDelay` 一带）。

### 12.4 兜底

即使偏移存在且未填常数，1 帧同时窗口也会把它吸收成「同时弹开」，不会变成 P1 稳赢——这是选 1 帧容差而不是严格同帧的主要理由。

---

## 13. 任务分解

依赖按行看，T5/T6/T7 可并行。

| # | 任务 | 文件 | 验收 | 依赖 |
|---|---|---|---|---|
| T1 | 常量、开关、日志通道 | `GameConfig` `ConfigVO` `Debugger` | 编译过；开关关掉行为不变 | — |
| T2 | 全局帧号 + 动作起手帧埋点 | `GameCtrl` `FighterMcCtrler` `FighterMain` | 日志打出两侧起手帧 | T1 |
| T3 | 裁决器（纯逻辑） | `ClashResolver` `ClashVerdictVO` | 手工构造 6 组数值得到预期 verdict | T1 |
| T4 | `checkHit` 三段式 + claim | `GameMainLogicCtrler` | 不拼招时与改动前逐帧一致 | T2 T3 |
| T5 | 赢家纽带窗口 | `FighterMcCtrler` | 场景 2/3/4/5/7 拿到窗口且能连 | T4 |
| T6 | 输家打防 + 判定压制 | `FighterMcCtrler` `FighterMain` `FighterAttacker` | 场景 11 通过，输了打不出 | T4 |
| T7 | 同时出弹开 | `FighterMcCtrler` `EffectCtrl` | 场景 1/6 通过 | T4 |
| T8 | 日志与表现打磨 | `GameMainLogicCtrler` `EffectCtrl` | 判据行可读、特效可降级 | T5 T6 T7 |
| T9 | 回归与真机 | 全链路 | §11.3 四条 | T8 |

每个任务独立提交，只提本次涉及的路径。

---

## 14. 风险与未决

| 风险 | 影响 | 处置 |
|---|---|---|
| 拼招改变「压起身/对拼」节奏，可能影响平衡 | 高 | 开关兜底；先训练模式观察；数值全在 `GameConfig` |
| 老角色包缺帧 → 纽带「缩水」 | 中 | 设计上接受；日志里记「开放了几个槽」 |
| 2P 偏移实测不是恒定 1 帧 | 中 | 只靠 1 帧容差；不做常数补偿（§12.3） |
| 多对多时先到先得可能吃掉更该赢的一对 | 低 | 排序键确定性；必要时升级为全局最优配对（暂不做） |
| `checkHit` 重构引入回归 | 高 | T4 单独一步，关开关逐帧比对 |

未决（实现前可再定）：

1. 必杀要不要作为纽带奖励的一部分（当前否，改一行常量即可放开）；
2. 拼招是否计分/计连击（当前否）；
3. 是否进设置页（当前只在 `ConfigVO`，第二版再做 UI）。

---

## 15. 回滚

1. 运行时：`ConfigVO.clashEnabled = false` 即回到今天。
2. 代码：改动按 T1~T9 分提交，回滚 = revert 对应提交。
3. 开工前打 `snapshot/pre-clash-doc-2026-11-23`，实现前再打 `snapshot/pre-clash-impl-<日期>`。
4. 单文件回退走 `.backup/<文件名>.<时间戳>`。
