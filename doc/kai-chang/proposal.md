# 第一局开场缺失修复 Proposal（全模式第一局不播开场）

日期：2026-09-18
状态：**✅ 代码已施工（P0+P2），编译/静态检查通过，等 t4 实测**
影响工程：`BVNscripts/PC版工程/launch-fla/`
施工文件：`src/net/play5d/game/bvn/ctrl/game_ctrls/GameCtrl.as`（**单文件，2 处逻辑**）

## 施工记录（2026-09-18 16:16）

- 备份：`PC版工程/.backup/2026-09-18-1615/GameCtrl.as`（md5 `69fcd8b694e8d73b3f5fb18785ab1379`，与改动前一致）
- 改动：`buildGame()` 318-326（条件 `!= 40 || (== 40 && !SAY_INTRO)` → `== 40` + 注释重写）；`doBuildNextRound()` 434-445（`if(param1 || GameMode.is1v2Mode())`，HP 继承单独由 `if(param1)` 门控）
- 验证：mxmlc `build.bat` 等价命令 **错误 0 / 警告 55**（与基线一致）→ `launch.swf` 2948742 字节（ZWS）；mxmlc `-strict=true`（= `lint.bat`）**错误 0 / 警告 55**（与 baseline `lint.log` 逐项一致）
- 未做：P1 超时兜底（按 Q3 决策）；`TrainingCtrler.SAY_INTRO` 声明保留
- 待办：t4 实测（见 `doc/kai-chang/tasks/progress.md`）

---

## 0. 决策记录（2026-09-18 grilling）

| # | 议题 | 决定 |
|---|---|---|
| Q1 | 第一局开场覆盖范围 | **全部非练习模式**（与原版 3.3 一致：仅 TRAINING(40) 跳过） |
| Q2 | `TrainingCtrler.SAY_INTRO` 死开关 | **从条件中删掉，回归纯 `== 40`**（声明保留，见 §3.4） |
| Q3 | 是否加「开场超时兜底」(P1) | **不加**，严格最小改动；风险与补偿测试见 §4 |
| Q4 | 1v2 第 2/3 局是否镜头开场 | **改为也播**（2v2 不在本次范围） |

---

## 1. 结论（根因）

`buildGame()` 里的开场分支条件被写成了**恒真表达式**，导致 `else`（播开场）分支成为**死代码**：

```as
// GameCtrl.as:324（当前）
if(GameMode.currentMode != 40 || GameMode.currentMode == 40 && !TrainingCtrler.SAY_INTRO)
```

`TrainingCtrler.SAY_INTRO` 在 PC 版工程 / `scripts` / `3.3竞技项` 中**均只有声明、无任何赋值**（恒 `false`）。真值表：

| currentMode | `!= 40` | `== 40 && !SAY_INTRO` | 整体 | 走的分支 |
|---|---|---|---|---|
| 10 / 12 / 14 / 20 / 22 / 24 / 30 … | true | false | **true** | 跳过开场 |
| 40（练习） | false | true（`!false`） | **true** | 跳过开场 |

→ **任何模式、任何第一局都不会创建 `_startCtrl`**：既没有「镜头拉近 + 角色开场姿态」，也没有 `showStart` 的 FIGHT 提示。这就是「闯关和 1v2 等模式第一局不播放开场」的直接原因。

### 1.1 与原版对照

| 参考实现 | 路径 | 开场分支条件 |
|---|---|---|
| **3.3 PC 原版**（同一 build：`V3.3 / 2019.3.32`） | `BVNscripts/3.3竞技项/scripts/.../game_ctrls/GameCtrl.as:297` | `if(GameMode.currentMode == 40)` |
| 3.7 PC（FFDEC 导出） | `FFDEC/export/scripts/.../GameCtrl.as:355` | `if(GameMode.currentMode == 40)` |
| 3.7（待移植） | `BVNscripts/待移植/scripts/.../GameCtrl.as:297` | `if(GameMode.currentMode == 40)` |
| 3.9（现代参考） | `reference/BVN3.9/CORE_KernelLogic/.../GameStartCtrl.as:162` | 同构（仅训练跳过） |
| 主项目 mob 版 | `BVNscripts/scripts/.../GameCtrl.as:295` | `if(GameMode.currentMode == 40 && !TrainingCtrler.SAY_INTRO)` |

**5 个独立参考实现一致：只有 TRAINING(40) 跳过开场。**

### 1.2 引入时间与来源

- `.backup/2026-09-18-0905/GameCtrl.as:296`、`.backup/2026-09-18-0916/GameCtrl.as:318` 保存的是改动前写法：
  `if(currentMode != 40 || currentMode == 40 && TrainingCtrler.SAY_INTRO)`
- `.backup/2026-09-18-0935/GameCtrl.as:324` 是本次改动后写法（`SAY_INTRO` → `!SAY_INTRO`）。

上一轮「练习模式暂停菜单失效」的修复**只做了布尔取反，没有去掉前面那个 `mode != 40 ||` 前缀**，整个条件因此塌缩为恒真、`else` 分支死亡。练习模式的暂停问题被"绕过"了（它现在也走跳过分支），代价是**所有模式的第一局开场全部消失**。

---

## 2. 影响面（逐模式现状）

| 模式 | 常量 | 第 1 局 | 第 2 局及以后 |
|---|---|---|---|
| 闯关（单） | `SINGLE_ACRADE` 20 | ❌ 无开场、无 FIGHT 提示 | FIGHT 提示（无镜头开场） |
| 闯关（团） | `TEAM_ACRADE` 10 | ❌ 同上 | 镜头开场 + FIGHT 提示 |
| VS CPU / VS 人 / 观战（团） | 11 / 12 / 13 | ❌ 同上 | 镜头开场 + FIGHT 提示 |
| 2v2 / 2v2 观战 | 14 / 15 | ❌ 同上 | FIGHT 提示（无镜头开场） |
| **1v2 / 1v2 观战** | 24 / 25 | ❌ 同上 | FIGHT 提示（无镜头开场）→ **本次改为镜头开场** |
| 生还者 | 30 | ❌ 同上 | — |
| 练习 | 40 | 无开场（**保持**） | 无开场（**保持**） |

附带副作用：第一局 BGM 走 `SoundCtrl.playFightBGM("map")`（地图曲），而原版非练习模式第一局由 `GameStartCtrl.start1v1()` 播**角色 BGM**。修好条件后 BGM 行为一并回归原版。

---

## 3. 最终修复方案（已按决策定稿）

### 3.1 P0 — 恢复原版开场条件（`GameCtrl.as` 318–335）

```as
         // 只有练习模式(TRAINING=40)跳过开场；其余模式第一局一律播放开场。
         // 注意：这里必须写 "== 40"。若写成 "mode != 40 || ..."，条件恒真，
         // else（播开场）分支会成为死代码 —— 所有模式第一局都没有开场。
         if(GameMode.currentMode == 40)
         {
            this.actionEnable = true;
            GameUI.I.fadIn();
            SoundCtrl.I.playFightBGM("map");
         }
         else
         {
            this._startCtrl = new GameStartCtrl(this.gameState);
            this.actionEnable = false;
            this._startCtrl.start1v1(_loc2_,_loc1_);
         }
```

**练习模式暂停菜单不会复发**：新条件下 mode 40 走 `actionEnable = true`、不创建 `_startCtrl`，正是上一轮想达到的效果。

### 3.2 P2 — 1v2 第 2/3 局也播镜头开场

**⚠ 落点更正**：`GameCtrl.startNextRound()`（public）在 PC 版工程**没有任何调用者**（死方法）；1v2/2v2 跨局的真实路径是
`runNext()` → `this.buildNextRound(false)`（`GameCtrl.as:754`）→ `doBuildNextRound(false)`。
而 2v2/1v2 的「三局两胜 + 第 2 局回满血」依赖 `param1 == false`（不执行 `lastWinner.hp = lastWinnerHp`），
所以**不能**简单改 `runNext()` 的入参，否则会连带改掉 1v2 的 HP 继承规则。

因此改成「镜头开场」与「队伍模式 HP 继承」解耦，只改 `doBuildNextRound()`（`GameCtrl.as:427-451`）：

```as
      private function doBuildNextRound(param1:Boolean) : void
      {
         var _loc2_:* = 0;
         this.gameState.resetFight(this.gameRunData.p1FighterGroup,this.gameRunData.p2FighterGroup);
         this._startCtrl = new GameStartCtrl(this.gameState);
         // param1 仍只表示「队伍模式的 HP 继承」；1v2 换局也走镜头开场
         if(param1 || GameMode.is1v2Mode())
         {
            if(param1)
            {
               if(this.gameRunData.lastWinner)
               {
                  this.gameRunData.lastWinner.hp = this.gameRunData.lastWinnerHp;
               }
            }
            _loc2_ = -1;
            if(this.gameRunData.lastWinnerTeam)
            {
               _loc2_ = this.gameRunData.lastWinnerTeam.id == 1 ? 2 : 1;
            }
            this._startCtrl.start1v1(this.gameRunData.p1FighterGroup.currentFighter,this.gameRunData.p2FighterGroup.currentFighter,_loc2_);
         }
         else
         {
            this._startCtrl.startNextRound();
         }
         this.gameRunData.isDrawGame = false;
         GameEvent.dispatchEvent("ROUND_START");
      }
```

行为变化（1v2 第 2/3 局）：
- 由 `startNextRound()`（淡出 + FIGHT 提示）改为 `start1v1(p1, p2, _loc2_)`：镜头拉近 **上一局败方**（`_introTeamId` = 败方）→ 该选手姿态 → 镜头拉回 → FIGHT 提示。
- BGM 切到该选手角色曲（与队伍模式第 2 局一致）。
- **HP 仍然回满**（`param1` 为 `false`，不继承），保持现有「第 2 局回满血」设计不变。
- 2v2（`isDuoMode()`）**不在本次范围**，仍走 `startNextRound()`；如需一并改，条件扩成 `|| GameMode.isDuoMode()` 即可。

### 3.3 明确不做

- **不做 P1「开场超时兜底」**（用户 Q3 选择严格最小改动）。风险见 §4.1。
- 不动 `GameStartCtrl`、`GameState`、`FighterMcCtrler`、`FighterMC` 等任何其它文件。

### 3.4 关于 `TrainingCtrler.SAY_INTRO`

- 本次**只从判断条件中移除引用**，`TrainingCtrler.as:15` 的 `public static var SAY_INTRO:Boolean = false;` 声明保留。
- 依据：全工程 `grep SAY_INTRO` 仅命中该声明与 `GameCtrl.as:324`，删除条件引用后即为无引用字段，保留无副作用。
- 删除声明属额外清理动作，**需单独确认后**再做（AGENTS.md 第 8/9 条）。

---

## 4. 风险与验证

### 4.1 【最高风险，必须实测】开场能否自然结束

`GameStartCtrl.renderStart1v1()` 第 105 行：

```as
if(_p1.actionState == 60 || _p2.actionState == 60) return false;
```

`actionState == 60`（`FighterActionState.KAI_CHANG`）**全工程只有 `FighterMcCtrler.idle()` 会清掉**。静态排查结论：

- 开场期间 `GameCtrl.render()` 每帧强制 `actionEnable = false`；
- `FighterMcCtrler.renderFloorAction()` 的禁用分支只在 `_mc.currentFrameName` 为 `走` / `防御` 时 `idle()`，而开场时是 `开场`，**不命中**；
- 全工程 `.idle(` 的调用点中，开场期间可用的只有 `GameStartCtrl.skip()`（由 `GameCtrl.renderPause()` 在按 ESC / MENU 选择键时触发）。

即：**「开场自动结束」这一步在静态代码里找不到明确出口**（这正是上一轮练习模式暂停失效的现象来源）。3.3 原版在非练习模式走的就是这条路径，理论上应能自行推进，因此按「最小改动」先实测：

- ✅ 实测通过 → 收工。
- ❌ 实测卡住（角色停在开场姿态、无法操作、ESC 不出暂停菜单）→ 立即回退 P0，并追加 P1 超时兜底（`doc/kai-chang/tasks/t4-debug.md` 记录现象）。

### 4.2 其它需目测项

1. **1v2 / 2v2 第一局多角色**：`start1v1(p1, p2)` 只让双方 1 号位摆姿态，`fighter2` 原地站立（出生点已由 `GameState.initFight` 设为 p1pos.x+30 / p2pos.x-30），镜头只对 p1/p2 做 `cameraFocusOne`。
2. **观战模式(13/15/23/25)**：双方均 AI，第一局现在会播开场。
3. **暂停菜单回归**：开场期间按 ESC 应走 `skip()` 而不是弹暂停菜单；开场结束后 `_gameStartAndPause` 逻辑正常。
4. **`GameUI.I.fadIn()` 不再被调用**：非练习模式第一局改由 `FightUI.showStart()` 内部 `fadIn()`（`FightUI.as:277`）接管，确认无黑屏残留。
5. **BGM**：非练习模式第一局会先切到角色曲。

---

## 5. 验收标准

1. `launch-fla/build.bat` 零错误；`launch-fla/lint.bat` 无新增错误（56 条"变量没有类型声明"为反编译风格，忽略）。
2. 逐模式第一局目测出现「镜头拉近 → 角色开场 → 镜头拉回 → FIGHT」：闯关单(20)、闯关团(10)、1v2(24)、2v2(14)、VS CPU(22/12)、VS 人(21/11)、观战(23)、生还者(30)。
3. **练习模式(40) 仍无开场、可直接操作、ESC 能正常弹出暂停菜单（不得复发）**。
4. 1v2 第 2/3 局出现镜头开场（只播败方姿态），且**仍回满血**。
5. 其它模式第 2 局行为与改动前一致（不回归）。
6. `launch/log.log` 无新增 `TypeError` / `Error #1065`。

---

## 6. 任务拆分

见 `doc/kai-chang/tasks/progress.md`。

| 任务 | 内容 | 文件 |
|---|---|---|
| t1 | P0 条件修复 + 注释改写 | `GameCtrl.as` |
| t2 | P2 1v2 换局镜头开场 | `GameCtrl.as`（同文件） |
| t3 | `build.bat` + `lint.bat` 验证 | — |
| t4 | `debug.bat` 逐模式实测（**需用户执行**，见 §5 清单） | — |
| t5 | 收尾：按实测结果决定是否追加 P1 兜底；更新本 doc 状态 | — |

**注**：t1+t2 合计只动 1 个 `.as`，未触发 AGENTS.md「≥4 文件联动更新 CLAUDE.md」条款；CLAUDE.md 仅需在追加 P1 后再评估。

---

## 7. 变更纪律（AGENTS.md）

- 改文件前先 `cp` 到 `PC版工程/.backup/<YYYY-MM-DD-HHMM>/`，确认成功再改。
- 只允许 `replace` 级精确编辑；不得顺手重构。
- 固定流程：`build.bat` → `lint.bat` → `debug.bat` 实测 → 读 `launch/log.log`。
- 实测不通过即从 `.backup/` 原样回退，不做"试试看"式叠加修改。
