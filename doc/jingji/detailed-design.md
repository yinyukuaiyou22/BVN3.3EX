# 竞技规则移植 详细设计

## 文件改动总览

| 文件 | 改动 |
|---|---|
| `data/ConfigVO.as` | 6 字段 + toSaveObj 写入 |
| `mob/GameInterfaceManager.as` | getGameMenu 重组 + getSettingMenu 追加 6 项 |
| `fighter/FighterMain.as` | qi 初值 + getDoingAction() |
| `ctrl/EffectCtrl.as` | doSteelHitEffect 刚身停顿分支 |
| `fighter/ctrler/FighterMcCtrler.as` | doWaiKaiAction 守卫 + 防重复连子系统 |
| `state/GameState.as` | initCamera autoZoomMin 公式 |
| `fighter/ctrler/FighterKeyCtrl.as` | assist/specailSkill 分支 + GameData import |
| `fighter/Bullet.as` | _ownerDoingAction 缓存 + getDoingAction() |
| `fighter/FighterAttacker.as` | _ownerDoingAction 缓存 + getDoingAction() |
| `CLAUDE.md` | 设置菜单/ConfigVO 索引更新 |

## 接口 / 类型契约

### ConfigVO（`net.play5d.game.bvn.data.ConfigVO`）

新增公开字段（默认值 = fork）：

```actionscript
public var isSteelBodyFreeze:Boolean = false;
public var initialQi:Number = 100;
public var allowWankai:Boolean = true;
public var isAllowRepeatAttack:Boolean = false;
public var isChangeSpecialKey:Boolean = true;
public var cameraMaxSize:Number = 1;
```

`toSaveObj()` 追加 `o.initialQi / o.isSteelBodyFreeze / o.allowWankai / o.isAllowRepeatAttack / o.isChangeSpecialKey / o.cameraMaxSize`。`readSaveObj()` 不改（KyoUtils 只覆盖已存在键，缺键保留字段默认值）。

### mob/GameInterfaceManager.getGameMenu()

顶层顺序与分组：

```text
TEAM PLAY(小队模式)   → TEAM ACRADE(10), TEAM VS PEOPLE(11), TEAM VS CPU(12),
                        TEAM WATCH(13), TEAM DUO(14), TEAM DUO WATCH(15)
SINGLE PLAY(单人模式) → SINGLE ACRADE(20), SINGLE VS PEOPLE(21), SINGLE VS CPU(22),
                        SINGLE WATCH(23), 1VS2(24), 1VS2 WATCH(25)
OPTION → TRAINING → CREDITS → EXIT GAME
```

删除 MISC；每个子项保留原 txt/cn/func；CREDITS 从 MISC 升为根项。无 LAN PLAY。

### mob/GameInterfaceManager.getSettingMenu()

在现有数组追加 6 个 entry；optoinKey 与选项值照搬 fork `win/GameInterfaceManager.getSettingMenu()` 中同名项（txt 保留 fork 英文键名，cn 用中文）。

### getDoingAction 链路（防重复连依赖）

`FighterMain`：新增 `getDoingAction():Object`，返回
`{ "action": <currentFrameName + "_" + getCurrentFrame() + "_" + data.id>, "times": _fighterCtrl.getMcCtrl().doActionTimes }`；守卫 `_fighterCtrl/getMcCtrl/getMC/data` 任一为空返回 null。

`Bullet`：新增 `_ownerDoingAction:Object` 字段；`setHitVO()` 中 `owner is FighterMain` 分支内缓存 `(owner as FighterMain).getDoingAction()`；新增 `getDoingAction()`；destory 置 null。

`FighterAttacker`：同上，缓存点在 `setOwner()` 的 FighterMain 分支；getter 同；destory 置 null。

`FighterMcCtrler`：新增公开 `doActionTimes:uint=1`（doAction 末尾 `++`）、公开 `beHitActions:Object=null`、私有 `_hasBadAction:Boolean=false`、私有 `_lastHurtActionTimes:uint=0`；新增 `hurtActionCheck/hurtActionRepeatCheck/hurtActionClear`；`doHurt` 接入判定；`idle()` 末尾清状态。

## 行为算法（逐点）

### 1. initialQi

`FighterMain.as`：`public var qi:Number = 0;` → `public var qi:Number = GameData.I.config.initialQi;`。FighterMain 已 import 非通配（仅 FighterVO/TeamVO），需补 `net.play5d.game.bvn.data.*` 或单独 GameData import，二选一，编译为准。

### 2. isSteelBodyFreeze

`EffectCtrl.doSteelHitEffect`：在 `doEffectVO` 调用前追加：

```actionscript
if(!GameData.I.config.isSteelBodyFreeze)
{
   _loc4_ = _loc4_.clone();
   _loc4_.freeze = 0;
   _loc4_.shine = {};
}
```

EffectCtrl 已 import data.*。

### 3. allowWankai

`FighterMcCtrler.doWaiKaiAction` 方法体最前面追加：

```actionscript
if(!GameData.I.config.allowWankai)
{
   return;
}
```

FighterMcCtrler 已 import data.*。

### 4. isAllowRepeatAttack（防重复连）

移植 fork `doHurt` 判定：重复命中时无伤害、走受击飞行并削减击飞 y；`isAllowRepeatAttack=true` 时跳过判定。具体：

- `doHurt` 开头：`this._hasBadAction = this.hurtActionCheck(param1);`
- `loseHp` 用 `if(!this._hasBadAction){ ... }` 包裹。
- `hurtType==0` 分支加 `&& !this._hasBadAction`。
- 飞行分支条件改 `hurtType==1 || this._hasBadAction`；bad 时 `playHurtFly(_loc3_, _loc4_ > 0 ? 0 : _loc4_)`，分支结束调 `hurtActionClear()`。
- `idle()` 方法末尾加 `this.hurtActionClear();`。
- `hurtActionCheck/hurtActionRepeatCheck/hurtActionClear` 三个方法放在 doHurt 之后、renderHurt 之前，逻辑照 fork。

### 5. cameraMaxSize

`GameState.initCamera`：`this.camera.autoZoomMin = 1;` → `this.camera.autoZoomMin = Number(Math.floor(100 * (1 / GameData.I.config.cameraMaxSize)) / 100);`。GameState 需已有 data.* import（编译验证）。

### 6. isChangeSpecialKey

`FighterKeyCtrl.assist/specailSkill` 替换为 fork 逻辑；新增 `import net.play5d.game.bvn.data.GameData;`。

## 错误处理

- 老存档无新键：依赖默认值，无异常路径。
- `getDoingAction` 在对象未初始化时返回 null，调用侧（hurtActionCheck）判空返回 false，不影响正常受击。
- destory 全部清引用，避免跨局残留（_hasBadAction/beHitActions/doActionTimes 生命周期在 FighterMcCtrler 实例内，随角色销毁重建）。

## 边界情况

- 连段中多段命中同一次动作：action 含帧号，帧变化不触发重复标记；同一动作起手帧再次出现且 doActionTimes 已变才触发（fork 语义）。
- 2v2/1v2：每个 FighterMain/Bullet/FighterAttacker 实例独立缓存，判定作用于命中方当前攻击者，天然支持多目标。
- AI 角色同走 FighterKeyCtrl/FighterMcCtrler，规则同样生效。

## 测试计划

每个任务：`./build.bat` 零错误；diff/备份核对；rg 静态断言。最终：

```text
rg "initialQi|isSteelBodyFreeze|allowWankai|isAllowRepeatAttack|isChangeSpecialKey|cameraMaxSize" data/ConfigVO.as
rg "INITIAL QI|STEEL FREEZE|ALLOW WANKAI|ALLOW REATTACK|CHANGE SPECIAL KEY|CAMERA MAX SIZE" mob/GameInterfaceManager.as
rg "getDoingAction" fighter/FighterMain.as fighter/Bullet.as fighter/FighterAttacker.as
rg "hurtActionRepeatCheck|doActionTimes" fighter/ctrler/FighterMcCtrler.as
```
