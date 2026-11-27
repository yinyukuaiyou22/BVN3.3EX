# 拼招机制 实现记录

日期：2026-11-27
依据：[plan.md](plan.md)（方案 T0~T9）
状态：**代码已实现、build 通过；未实机验收**。

## 1. 这次落了什么

### 开关（T0）

- `ConfigVO.clashEnabled`（默认 true = 娱乐/默认开），进 `toSaveObj()`；
- `isSportRuleEnabled()` 加 `!clashEnabled`，`setAllRuleConfig()`：竞技关、娱乐开；
- `GameInterfaceManager.getRuleMenu()` 加一行 `CLASH / 拼招`（OFF/ON，`optoinKey=clashEnabled`）；
- `HostVO` 末尾加 1 字节下发，旧端按 `bytesAvailable` 判空回落默认；`LANGameCtrl.gameStart()` 写入本地 config。

### 裁决（T1~T4）

- `GameConfig` 新增 8 个常量（`CLASH_SIM_WINDOW_MS=20` 等），`Debugger.DIAG_CLASH`；
- `GameCtrl.renderFrame`：每帧 +1，作为「后出」与「每帧一次」的时序基准；
- `FighterMcCtrler._actionStartFrame`：`doAction()` 时记帧号，`FighterMain.getActionStartFrame()` 转发；
- 新增 `ClashResolver`（纯裁决）与 `ClashVerdictVO`（结果快照）；
- `GameMainLogicCtrler.checkHit()` 改三段式：两向先算 → 都命中且未裁决才 `judge` → 有结论走 `applyClash`，否则原样应用。

### 结果（T5~T7）

- 赢家：`grantClashLink()` 开 8 拍窗口，`render()` 在输入轮询前重放 `setClashLinkAct()`（地面六槽 / 空中两槽），`doAction` 起手即消费；
- 输家：`doClashGuard()` 复用打防口径（5% 掉血、扣气、5~10 拍硬直、后退、气不足破防），不要求处于防御态；
- 同时出：双方 `doClashRecoil()`，后退 + 6 拍硬直，不扣血不扣气不给纽带；
- 判定压制：`FighterMain._clashGuardFrame` 窗口内自身 `getCurrentHits()` 与 `FighterAttacker` 一律返回 null，杜绝「输了还打中」；
- 重置：`GameCtrl.removeGameSprite()` 与 `GameState.resetFight()` 清窗口；
- 特效：`EffectCtrl.doClashEffect()` 暂时复用防御火花，不新增资源。

## 2. 验证做到哪一步

- `./build.bat` 通过（exit 0，`tools/Test/launch.swf` 已生成）；
- 裁决规则用同构脚本跑过 8 组边界（全同 / 重击 / 击倒 / 面长 / 差 3 帧 / 差 1 帧 / 面长差 1px / 30fps 严格），全部符合预期；
- **未做**：实机对局验收（plan.md §11.2 的 16 条场景）、2P 补偿实测（§12）。

## 3. 实机验收怎么走

1. 首次进游戏先看 RULE CFG 是否有 `CLASH` 行，切换后重启仍保持；
2. 双人同拍互殴：同重同击倒同面 → 双方弹开、无伤害；重击打轻击 → 重击方赢且拿到纽带（地面能连砍技/招式，空中只有跳砍/跳招）；
3. 输了之后 5~10 拍内该角色打不出判定；
4. 打防分支：把气打空再拼输一次，应走破防（42 拍硬直 + break_def 特效）；
5. 日志：每次拼招一行 `【拼招】… => 重击/击倒/面长/后出/同时`；逐帧明细开 `Debugger.DIAG_CLASH`。

## 4. 已知限制

- 2P「落后一帧」未实测：机制本身不依赖遍历顺序，容差按毫秒折算，实测若确认固定偏移再填 `GameConfig.CLASH_SIDE_LAG`；
- 弹开/打防没有专属美术与音效，暂复用防御火花；
- 拼招不计分、不计连击（方案 §14 未决）；
- LAN 只下发开关，不下发容差与窗口长度（两端都用本地常量，发布时保持一致）。

## 5. 回滚

- 运行时：RULE CFG 关掉 `CLASH` 即回到旧行为（`judge` 直接返回 null）；
- 代码：`git revert` 对应提交，或从 `.backup/*.2026-11-27-1330` 取回单文件；
- 开工前快照：`snapshot/pre-clash-impl-2026-11-27`。
