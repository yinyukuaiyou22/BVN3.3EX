# BVN AI 系统完整分析文档（PC 版）

> 基于 `BVNscripts/PC/scripts/` 最新代码。仅涵盖核心 AI 系统：`FighterAICtrl` + `FighterAILogic` + `FighterAILogicBase`。

## 1. 架构总览

```
                     IFighterActionCtrl (接口)
                           |
         ┌─────────────────┴─────────────────┐
         |                                   |
  FighterKeyCtrl                       FighterAICtrl
  (玩家键盘输入)                     (AI 输入适配器)
                                            |
                                      FighterAILogic
                                      (内置概率 AI)
                                            |
                                  FighterAILogicBase
                                  (概率决策引擎 + AImain 桥接)
```

## 2. 文件清单

| 文件 | 版本 | 行数 | 职责 |
|------|------|------|------|
| `fighter/ctrler/FighterAICtrl.as` | PC 修改 | 247 | IFighterActionCtrl 适配器：桥接 FighterAILogic 布尔字段给 FighterMcCtrler；PC 版新增 holdAttack/holdSkill/holdBisha/moveUP/moveDOWN |
| `fighter/ctrler/ai/FighterAILogicBase.as` | PC 修改 | 302 | 概率决策引擎基类：AI 等级映射、距离/范围判定、连招排序；PC 版新增 AImain 集成、_attackAction 映射、多方法改为 final/static |
| `fighter/ctrler/ai/FighterAILogic.as` | PC 修改 | 1146 | 具体 AI 行为实现：所有子系统大幅扩展，每个行为先委托 AImain 再执行内置逻辑 |
| `fighter/FighterAction.as` | 不变 | 200 | 动作定义 VO：存储角色当前可用的帧标签名，AI 据此判断动作是否可用 |
| `data/MessionModel.as` | 不变 | 113 | 闯关模式数据：持有 AI_LEVEL 并从 ConfigVO 同步 |
| `data/ConfigVO.as` | 不变 | 209 | 用户配置持久化：AI_level 默认值 1，可存档 |
| `ctrl/game_ctrls/GameCtrl.as` | 不变 | 430+ | 中央游戏控制器：addFighter/setFighterActionCtrl 中创建 FighterAICtrl 并注入 AI 等级 |

## 3. IFighterActionCtrl 接口（PC 版扩展）

PC 版在原始 26 个方法基础上新增 5 个：

```
新增:
  moveUP()        — 上方向移动
  moveDOWN()      — 下方向移动
  holdAttack()    — 蓄力攻击
  holdSkill()     — 蓄力技能
  holdBisha()     — 蓄力必杀
```

完整 31 个方法：

```
方向移动:   moveLEFT()  moveRIGHT()  moveUP()  moveDOWN()
跳跃系统:   jump()  jumpQuick()  jumpDown()
瞬步系统:   dash()  dashJump()
防御:       defense()
普通攻击:   attack()  attackAIR()
技能:       skill1()  skill2()
招式:       zhao1()  zhao2()  zhao3()
投技:       catch1()  catch2()
必杀技:     bisha()  bishaUP()  bishaSUPER()  bishaAIR()
空中技能:   skillAIR()
万解:       waiKai()  waiKaiW()  waiKaiS()
幽灵步:     ghostStep()  ghostJump()  ghostJumpDown()
辅助:       assist()
特殊技能:   specailSkill()
蓄力:       holdAttack()  holdSkill()  holdBisha()
```

## 4. AI 等级概率系统（核心决策引擎）

### 4.1 概率映射表

```
AI 等级    概率阈值来源     说明
────────────────────────────────────
  0-1      第 1 个参数     最低概率，几乎不行动
   2       第 2 个参数     低概率
   3       第 3 个参数     中等概率
   4       第 4 个参数     较高概率
   5       第 5 个参数     高概率
   6+      第 6 个参数     最高概率，极具攻击性
```

### 4.2 核心算法 (FighterAILogicBase.getAIResult, 行 165-184)

```as3
getAIResult(p1, p2, p3, p4, p5, p6):
  r = Math.random() * 10        // [0, 10) 均匀分布
  switch(AILevel):
    case 0,1: return r < p1     // 例如 p1=0.5 → 5% 概率触发
    case 2:   return r < p2
    case 3:   return r < p3
    case 4:   return r < p4
    case 5:   return r < p5
    default:  return r < p6     // 等级 6+
```

**关键性质**: 6 个参数单调递增时（`p1 <= p2 <= ... <= p6`），AI 等级越高触发行为概率越大。

### 4.3 基于对手状态的概率选择 (getAIByFighterState, 行 153-163)

```as3
getAIByFighterState(rateObj):
  defaultArr = rateObj["defult"]
  stateArr   = rateObj[targetActionState]  // 对手当前动作状态
  arr = stateArr ?? defaultArr
  if arr == null → return false            // PC 版新增 null 检查
  return getAIResult(arr[0]...arr[5])
```

**设计意图**: AI 根据对手当前状态（站立/攻击/受击/防御/必杀中等，对应 FighterActionState 的 int 值）选择不同的 6 元概率数组。

### 4.4 连招连续系统 (_isConting / ContOrder)

```
_isConting = FighterActionState.isAttacking(_fighter.actionState)
// PC 版改用静态方法，等价于 state in [10, 11, 12, 13]
```

当角色正在执行攻击动作时，`_isConting = true`。此时：
- 每个子系统的概率数组切换到"连招模式"——数值整体更高
- 成功触发的行动通过 `addContOrder(id, priority)` 加入队列
- PC 版新增随机微调：`priority + int(Math.random() * 10)`
- `updateContOrder()` 按 priority **降序**排序（PC 版改为 `2 | 0x10`），只保留最高优先级行动，其余重置为 false

## 5. AImain 集成系统（PC 版新增）

### 5.1 角色 SWF 中的 AImain 元件

每个角色 SWF 可选包含一个名为 `AImain` 的子 MovieClip，提供以下函数接口：

```
AImain 接口:
  init(setAction, addContOrder, getAIByFighterState):void  — 初始化，注入回调
  setBishaAction(bishaObj):void  — 设置哪些必杀可用
  preRender():void       — 每帧在 updateActionAI 最前调用
  afterRender():void     — 每帧在 render 最后调用
  updateActionAI(actionName:String):Boolean  — 覆盖特定行为的 AI 决策
  getActionAI(actionName:String):Object      — 返回特定行为的概率调参对象
```

### 5.2 AImain 懒加载 (FighterAILogicBase, 行 219-232)

```as3
get AImain():MovieClip {
    if (_AImain == null) {
        mc = _fighter.getMC();
        if (mc == null) return null;
        _AImain = mc.getChildByName("AImain") as MovieClip;
    }
    return _AImain;
}
```

### 5.3 执行流程中的 AImain 钩子

```
FighterAILogic.render()
  → super.render()  // FighterAILogicBase.render()
  → updateHurtAI()       → 先调 updateAImainAction("hurt")
  → updateGhostStep()    → 先调 updateAImainAction("ghostStep")
  → AImain.afterRender() ← PC 版新增钩子

FighterAILogic.updateActionAI()
  → updateAImain()       ← AI level >= 6 时激活 AImain
      → AImain.init(setAIAction, addContOrder, getAIByFighterState)
      → AImain.setBishaAction(_isNeedBishaAction)
      → AImain.preRender()
  → updateDashAI()       → 先调 updateAImainAction("dash")
  → updateAttackAI()     → 先调 updateAImainAction("attack")
  → updateSkill()        → 每个技能先调 updateAImainAction(name)
  → updateBisha()        → 每个必杀先调 updateAImainAction(name)
  → updateCatch()        → 先调 updateAImainAction("catch")
  → updateAssist()       → 先调 updateAImainAction("assist")
  → updateMoveAI()       → 先调 updateAImainAction("move")
  → updateJumpAI()       → 先调 updateAImainAction("jump")
  → updateJumpDownAI()   → 先调 updateAImainAction("jumpDown")
  → updateDefenseAI()    → 先调 updateAImainAction("defense")
  → updateSpecialSkill() → 先调 updateAImainAction("specialSkill")
```

### 5.4 角色级概率调参: setAIByMain (FighterAILogicBase, 行 234-249)

```as3
setAIByMain(rateObj, actionName):
  fn = AImain.getActionAI as Function
  if AImain == null || fn == null → return
  result = fn(actionName)
  // result 格式: {"defult": [0.5,1,2,3,4,5], "21": [1,2,3,4,5,6]}
  // 合并到 rateObj (mergeRateObject 取每项最大值)
```

### 5.5 角色级行为覆盖: updateAImainAction (FighterAILogic, 行 207-219)

```as3
updateAImainAction(actionName):
  fn = AImain.updateActionAI
  if fn == null → return false  // 不覆盖，使用内置逻辑
  return fn(actionName)
  // true = "已处理，跳过内置逻辑"
  // false = "使用内置逻辑"
```

**生效条件**: AI level >= 6。

### 5.6 setAIAction 辅助方法 (FighterAILogic, 行 196-205)

```as3
setAIAction(actionName, value=true):
  try { this[actionName] = value; }  // 反射设置任意布尔字段
  catch(e) {}
```

AImain.init() 接收此方法作为回调，可在角色自定义逻辑中直接设置攻击/技能/必杀等布尔值。

## 6. FighterAILogicBase PC 版变更对照

| 项目 | 原版 | PC 版 |
|------|------|-------|
| `_attackAction` 映射 | 无 | 帧标签→范围名: `{"砍1":"kanmian", "招1":"zh1mian", ...}` |
| `mergeRateObject` | 实例方法 | `static` 静态方法 |
| `updateConting()` | 手动比较 actionState | `FighterActionState.isAttacking()` |
| `addContOrder` jitter | 无 | `+ int(Math.random() * 10)` |
| `updateContOrder` 排序 | `sortOn("order", 2)` (升序) | `sortOn("order", 2 \| 0x10)` (降序) |
| `render()` 空检查 | 先检查后赋值 | 先赋值 `_targetFighter` 后检查两者 |
| `getAIByFighterState` | 不检查 null | 数组为 null 返回 false |
| `targetInDistance` | `protected` | `final public` |
| `targetInRange` | `protected` | `final public` |
| `get AImain` | 无 | 懒加载 AImain 元件 |
| `setAIByMain` | 无 | 调用 AImain.getActionAI 角色调参 |
| `targetCanBeHit` | `isAllowBeHit` | `actionState == 21 \|\| isAllowBeHit` |
| `isHitDownAct` bug | 错误写入 `_breakActCache` | **未修复** |

### _attackAction 映射表

```as3
_attackAction = {
   "招1":"zh1mian", "砍1":"kanmian", "招2":"zh2mian", "招3":"zh3mian",
   "砍技1":"kj1mian", "砍技2":"kj2mian", "跳砍":"tzmian", "跳招":"tkanmian"
};
```

用于幽灵步 AI：若当前攻击动作对应的判定区未命中目标（`!targetInRange(range)`），且距离近，则触发幽灵步绕后。

## 7. FighterAILogic PC 版各子系统变更详解

### 7.1 总体结构变化

**原版**: `render()` 内顺序执行 move→jump→jumpDown→hurt→defense→specialSkill→ghostStep，`updateActionAI()` 内执行 dash→attack→skill→bisha→cache→assist。

**PC 版**: `render()` 内只剩 hurt→ghostStep→afterRender 钩子。`updateActionAI()` 顺序变更为 AImain→dash→attack→skill→bisha→catch→assist→move→jump→jumpDown→defense→specialSkill。**移动和防御移到攻击决策之后**，确保攻击冲动优先于防御退缩。

### 7.2 常量变化

| 常量 | 原版 | PC 版 | 影响 |
|------|------|-------|------|
| `_moveKeep` | 40 | 40 (const) | 不变 |
| `_catchMoveKeep` | 15 | 15 (const) | 不变 |
| `_dashKeep` | 200 | 250 (const) | 瞬步触发距离阈值提高 25% |
| `_dashInKeep` | 无 | 125 (const) | 新增近距离瞬步阈值 |
| `_jumpKeep` | 50 | 300 (const) | 跳跃高度差阈值提高 6 倍 |
| `_jumpDownKeep` | 无 | 50 (const) | 新增下跳阈值 |

### 7.3 移动 AI (updateMoveAI)

```
新增:
  1. _hurtDownMoveType 倒地追击策略:
     - 对手击飞中 + 距离 > 125: 70% type=2(迂回绕侧), 30% type=1(贴身)
     - 对手击飞中 + 距离 <= 125: 55% type=2, 45% type=1
     - type=1: 保持在对手朝向侧
     - type=2: 绕到 125px 距离处

  2. 超级钢身反转: 对手超钢身且自身非钢身 → 反转移动方向(后退)

  3. 空中反转: 角色在空中且空中攻击次数用完 → 反转移动方向
```

### 7.4 跳跃 AI (updateJumpAI)

```
新增空中攻击判定:
  1. targetInRange("tkanmian") + 目标可被攻击 + 非钢身 + 非受身 + 非钢身Hit
     → defult = [0.1,0.5,1,3,1.9,1.3]
     (level 4 时 30% 跳跃概率，level 5-6 回落至 19%/13%——高等级反而克制)

  2. targetInRange("tzmian") + 同上
     → defult = [0.1,0.5,1,3,1.5,1]

  3. _jumpKeep 从 50 → 300:
     - 对手在地面时 fighter.y > target.y + 50 即触发
     - 对手在空中时需 fighter.y > target.y + 300

  4. 连招跳跃新增 order 自定义支持
```

### 7.5 瞬步 AI (updateDashAI) — 最大重构

原版 3 分支。PC 版 6 场景：

```
场景1: 自身倒地刚起身或倒地中 (_justStandUp || state==23)
  → 距离 <= 60:  defult = [2,3,4,5,6,9]  (最高，紧急脱身)
  → 距离 <= 180: defult = [1,2,3,4,4,4]
  → 距离 > 180:  defult = [1,2,3,2,1,0.5]

场景2: 正在攻击中 (state 10-13)
  → defult = [0,0,0.2,0.5,2,8]
  → 目标受击中(21): [0,0,0.1,0.5,0,0] (降低，不打断连招)

场景3: 体力 < 60，远距离 (>250) 且同向
  → 低概率接近: [0,0,0.1,0.5,0,0]
  → 对手攻击中(10/11): [0,0.05,0.3,1,1.7,2.5] (防守性瞬步)

场景4: 体力 < 60，近距离 (<125) 且体力 > 20 且 y 差 <= 75
  → [0,0,0.05,1,1,1] + 攻击状态加成 → 进入连招队列

场景5: 体力充足，远距离 (>250) 且背向
  → defult = [0.5,1,1.5,2.5,4,5.5]
  → 瞬步中(15): [0,0,0.1,0.5,0.05,0.05] (避免连续瞬步)

场景6: 体力充足，近距离 (<125) 且 y 差 <= 75
  → 极进攻性: 对手必杀中(12/13) [0.5,1,1.5,2.5,6,9]
```

**新增硬条件**: 对手倒地/击飞中直接禁止瞬步 (`dash=false`)。

### 7.6 防御 AI (updateDefenseAI)

```
新增退出条件:
  - energy <= 20 → 强制停止防御
  - isSteelBody → 钢身不需要防御
  - hpRate > 0.5 && 对手无当前攻击 → 高血量无威胁不防御

新增对手状态感知:
  - 跳跃中(14): [9,6,2,1,0.5,0] (低等级高防，高等级不防——高级 AI 选择反打)
  - 瞬步中(15): [2,1,1,0,0,0]

新增低气场景:
  - qi <= 10 → 扩大防御范围
    攻击中(10/11): [1,2,3,2,1,0.5]
    必杀中(12/13): [2,3,3.5,4,5,6.5]

新增 doInDefense() 辅助函数:
  - 防御优先级 115-120
  - 自动转向面对对手
```

### 7.7 攻击 AI (updateAttackAI)

```
新增钢身Hit检测:
  目标 hurtHit.id 含 "sh" 且 AI 背向 → 受击中(21): [1,0.5,0.2,0,0,0]
  正常受击中 → (21): [10,10,10,10,10,10] (100% 追击)

自身防御中(20):
  → 攻击概率降低: [0.5,1,1,0,0,0]

连招模式增强:
  - "砍1" → 优先级 200
  - 目标受击中(21) → 优先级 117
  - 其他 → 需要 targetInRange 判定

attack 和 attackAIR 独立注册（非互斥）
```

### 7.8 技能 AI (getSkillAI)

```
新增对手受击中追击:
  破防技能(21): [0.5,1,3,5,8,10] (连招) / [0,0.2,0.5,2,1,0.5] (非连招)
  普通技能(21): [1,2,3,5,7,10] (连招) / [0.1,0.5,1,3,1.5,1] (非连招)

自身防御中 → [0.5,1,1,0,0,0]
对手钢身Hit(21) → [1,0.5,0.2,0,0,0]

连招优先级: _isConting 或 目标受击中(21) 时 +100 优先级
```

### 7.9 必杀 AI (updateBisha/getBishaAI)

```
1. 动态气量门槛:
   - 目标 HP <= 300: qi 门槛 100 (斩杀线)
   - 目标 HP > 300:  qi 门槛 200

2. 超必杀智能:
   - 目标 HP > 500 且需求 >200 气: [0.05,0.02,0.01,0,0,0] (不浪费)

3. 必杀可用性控制 (_isNeedBishaAction):
   - AImain.setBishaAction() 设置四种必杀的启用/禁用
   - bisha = getBishaAI(...) && (_isNeedBishaAction["bisha"] ? _fighterAction.bisha : true)

4. 确认识别断:
   - 目标受击中(21):
     → 目标 qi < 100 || energyOverLoad || hurtBreakHit() || 累计伤害 > 210
     → 条件满足才确认释放（防止被受身爆气打断）
   - 目标非受击:
     → energyOverLoad || (必杀中 && isAllowBeHit) && !isSuperSteelBody

5. 新增状态参数:
   - 瞬步中(15): [0.2,0.5,0,0,0,0]
   - 站立中(0): [0,0,0.1,0,0.01,0.02]
```

### 7.10 投技 AI (updateCatch, 原 updateCache)

```
重命名: updateCache → updateCatch

新增强化:
  - _justStandUp 感知（倒地刚起身时增强）
  - catch1 和 catch2 分离概率数组
  - catch2 仅在 !catch1 时触发
  - 冻结状态(40) 特殊加成: [1,2,4,5,7,10]
  - 受身(16)/受击中(21) 大幅降低
```

### 7.11 特殊技能 AI (updateSpecialSkill) — 完全重写

```
原版条件: actionState==21, HP<60%, qi>=150
PC 版条件: actionState==21, qi>=100 (移除 HP 限制)

新增严格条件:
  1. 目标存在且为 FighterMain
  2. 目标在攻击状态中 (FighterActionState.isAttacking)
  3. 目标有当前攻击判定 (getCurrentHits() 非空)
  4. 目标非受身(16)
  5. 死神方角色: 额外距离 < 80px 限制

概率: defult [0.5,2,4,7,9,9.5]
      对手技能中(11): [0.5,1.5,4,6,8,9]
      对手必杀中(12/13): [0.5,3,6,8,9.25,9.75]

设计意图转变: HP 保命机制 → 针对对手攻击的主动反制
```

### 7.12 辅助召唤 AI (updateAssist)

```
新增前置条件:
  - actionState 必须 0(站立) 或 20(防御)
  - 目标非击飞状态
  - 必须面向目标: (target.x - fighter.x) * fighter.direct <= 0

新增 assistmian 范围检测:
  - 非首次召唤: 目标必须在角色 assistmian 判定区内

距离相关:
  近距离 (<=250): defult [0,0.5,1,1.5,2,2.5], 对手防御(20) [0,0.5,1,1.75,2.5,3.5]
  远距离: [0,0.02,0.05,0.1,0.1,0.1]

_isFirstAssister 首次召唤后置 false
```

### 7.13 幽灵步 AI (updateGhostStep) — 完全重写

```
原版条件: 距离<80px, qi>=200, state==10||11
PC 版条件: 距离<100px, qi>=60, _isConting||state==40, !isSteelBody, isAllowBeHit

核心变更:
  1. qi 门槛 200 → 60 (使用频率大幅增加)
  2. 新增 _attackAction 判定: 当前攻击动作未命中目标时才触发
     → _attackAction[curAction] && !targetInRange(_attackAction[curAction])
  3. 冻结状态(40) 特殊加成: [0,0,0.1,0.3,0.75,1.5]~[0,0,0.1,0.3,0.75,2]
  4. ghostJump 独立判定，ghostJumpDowm 移除
```

## 8. 完整数据流（PC 版）

```
用户设置存档 (ConfigVO.AI_level, 默认 1)
         |
         v
GameData.I.config.AI_level
         |
         v
MessionModel.I.AI_LEVEL     ← initMession() 赋值
         |
         v
GameCtrl.addFighter()
  → new FighterAICtrl()
  → AILevel = MessionModel.I.AI_LEVEL
  → fighter = param1
  → param1.setActionCtrl()
         |
         v
FighterAICtrl.initlize()
  → new FighterAILogic(AILevel, fighter)
         |
         v
FighterMcCtrler 每帧调用 ctrl.moveLEFT()/attack()/...
         |
         v
┌─ FighterAILogic ────────────────────────────┐
│  render():                                  │
│    super.render() → getCurrentTarget()      │
│    updateHurtAI()    → AImain hook          │
│    updateGhostStep() → AImain hook          │
│    AImain.afterRender()                     │
│                                             │
│  updateActionAI():                          │
│    AI level >= 6 → updateAImain()          │
│      → AImain.init()                        │
│      → AImain.preRender()                   │
│    dash→attack→skill→bisha→catch→assist    │
│    move→jump→jumpDown→defense→specialSkill │
│    每个行为:                                │
│      1. updateAImainAction(name) 覆盖?      │
│      2. setAIByMain(rateObj, name) 调参?    │
│      3. 内置概率判定                        │
└─────────────────────────────────────────────┘
```

## 9. AI 原理总结

### 9.1 概率驱动而非规则驱动

每帧对 26+ 个行动信号各做 `Math.random()*10 < threshold` 独立判定。6 元参数数组控制各 AI 等级下的行为触发率。优势：行为不可预测、自然感强；代价：无策略规划。

### 9.2 双层决策架构（PC 版新增）

- **内置层**: `FighterAILogic` 提供通用格斗 AI，通过 6 元概率数组 + 对手状态感知 + 空间范围判定做决策
- **角色层**: SWF 中的 `AImain` 元件（AI level >= 6 激活）可覆盖或调参任意行为

两层关系：`updateAIAction` 返回值决定是否覆盖内置逻辑；`getActionAI` 返回值微调内置概率数组。

### 9.3 六维参数空间

每个行为定义一个 6 元组 `[p0, p1, p2, p3, p4, p5]`，对应 AI 等级 0-1, 2, 3, 4, 5, 6+。这是 AI 调参的核心接口。

### 9.4 对手状态感知

`getAIByFighterState()` 根据对手 `actionState` 动态选择概率数组。对手攻击中 → 倾向防御和回避；对手受击中 → 倾向追击和连招；对手防御中 → 倾向投技和破防技能。

### 9.5 空间感知

- `getTargetDistance()`: 计算与目标 x/y 距离
- `targetInRange()`: 利用 MovieClip 帧中的攻击判定区与对手身体区做矩形碰撞检测
- `targetCanBeHit()`: PC 版增加 `actionState==21` 直接返回 true（受击中必可被攻击）

### 9.6 连招连续性

`_isConting` 状态 + `ContOrder` 优先级系统（PC 版降序排列 + 随机微调）确保攻击命中后高概率追击，同时通过优先级排序解决冲突。

### 9.7 PC 版整体设计倾向

相比原版，PC 版 AI 表现出更激进的特征：跳跃阈值 6 倍、瞬步门槛降低且场景细化为 6 种、幽灵步 qi 门槛从 200 降至 60、特殊技能从保命变为反制、防御增加多个退出条件。总体方向是"少防御、多进攻、更智能使用资源"。

## 10. 新增 AI 难度等级示例（PC 版适用）

当前 AI 等级 0-5+ 共 6 个有效档位。若需新增 level 7（"地狱"难度），修改 `getAIResult`：

```as3
// 原代码:
protected function getAIResult(param1:Number, param2:Number, param3:Number,
    param4:Number, param5:Number, param6:Number) : Boolean
{
    var _loc7_:Number = Math.random() * 10;
    switch(AILevel)
    {
        case 0:
        case 1:  return _loc7_ < param1;
        case 2:  return _loc7_ < param2;
        case 3:  return _loc7_ < param3;
        case 4:  return _loc7_ < param4;
        case 5:  return _loc7_ < param5;
        default: return _loc7_ < param6;
    }
}

// 修改为 (新增 2 参数 + 1 case):
protected function getAIResult(param1:Number, param2:Number, param3:Number,
    param4:Number, param5:Number, param6:Number,
    param7:Number, param8:Number) : Boolean
{
    var _loc7_:Number = Math.random() * 10;
    switch(AILevel)
    {
        case 0:     return _loc7_ < param1;
        case 1:     return _loc7_ < param2;
        case 2:     return _loc7_ < param3;
        case 3:     return _loc7_ < param4;
        case 4:     return _loc7_ < param5;
        case 5:     return _loc7_ < param6;
        case 6:     return _loc7_ < param7;   // 新增
        default:    return _loc7_ < param8;    // level 7+
    }
}
```

然后在 `FighterAILogic` 中所有 6 元数组末尾追加 2 个参数。同时调整 `updateAImain()` 门槛：

```as3
// 原:
if (GameData.I.config.AI_level < 6) return;
// 改为:
if (GameData.I.config.AI_level >= 6) { /* 初始化 AImain */ }

// level 7+ 额外行为:
if (GameData.I.config.AI_level >= 7) {
    _allowAImainOverride = true;  // 让 AImain 真正覆盖所有内置行为
}
```
