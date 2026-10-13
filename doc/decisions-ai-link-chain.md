# 决策记录：HELL/CRAZY 随机纽带连招 + 2026-10-12 进度提交

> 日期：2026-10-12 ｜ 强度：细问 ｜ 状态：**提交已执行；AI 功能仅存档计划，暂未实现**

## 一、背景

用户要求两件事：① 把当前工作区进度提交上传 GitHub；② 给 HELL（地狱，AI_level=6）与 CRAZY（疯狂，AI_level=7）人机加「只要当前有可用纽带，就随机挑一个非基础动作（除走跑跳）的纽带执行」。

## 二、关键事实（调研结论）

| 事实 | 出处 |
|---|---|
| 「纽带」= `FighterAction` 上的 24 个 String 帧标签槽，非 null = 可用；源码无「纽带」一词，仅 `doc/_api_doc.txt` 用此称呼 | `fighter/FighterAction.as:25-81` |
| **`doAction()` 每次起手都 `clearAction()`**，出招进行中所有纽带槽为 null ——「读当前招式的纽带」在出招中读不到 | `FighterMcCtrler.as:1226` |
| 站立/移动态槽才是满的（`setMoveAction()` 填 attack/zhao1/zhao3/skill2/jump/dash/bisha/bishaUP/defense/catch1/catch2） | `FighterMcCtrler.as:1238-1253` |
| 纽带消费走 `renderFloorAction()`/`renderAirAction()` 的 if 链：槽非空 && `_actionCtrler.槽()==true` → `doXxx()` | `FighterMcCtrler.as:777-894 / 989-1075` |
| AI 只产出 Boolean 标志，由 `FighterAICtrl` 转发进按键路径 | `FighterAICtrl.as:58-206` |
| `_contOrder` 用 `sortOn("order", 2\|0x10)` 降序仲裁：order 大者胜，其余被置 false | `FighterAILogicBase.as:98-115` |
| HELL 走 `case 6` 读 param6，CRAZY 走 `default` 读 param7（NaN 回落 param6） | `FighterAILogicBase.as:136-161` |
| `doBisha` 有 `useQi` 兜底、`doAirAttack/doAirSkill` 有 `airHitTimes` 兜底（执行层防呆，入池仍需先筛） | `FighterMcCtrler.as:1541/1574/1587` |
| 没有「跑」：移动只有 走(`doMove`) 与 瞬步(`doDash`) | 全仓「跑」0 命中 |
| PC 端 `SetBtnGroup.as:560-587` 菜单只到 HELL=6，**CRAZY 只能手机端选** | `mob/GameInterfaceManager.as:235-266` |

## 三、已确认决策（9 条）

1. **路线先丙后丁**：本期只做丙（站立/空中非出招态随机挑一个可用非基础纽带执行）；丁（复用 `setHitTarget` 命中即接）留作后续，不统计覆盖率。
   - 理由：`doAction()` 清槽使出招中读不到纽带；乙方案（全局 `招式→可接招式` 映射表）需为 52 角色逐招填表，工作量巨大。
2. **候选池含必杀/空中技，按 AI 面判定**：有 `AImain` 的角色信任其范围；无 `AImain` 用标准判定面 `targetInRange`；W 系对空、K 系空中反制由判定面/isInAir 自然覆盖。
   - `attack→kanmian`、`skill1/2→kj1mian/kj2mian`、`zhao1/2/3→zh1mian/zh2mian/zh3mian`
   - `catch1/2→getTargetDistance(_target).x < 50`（抄 `updateCache` :834）
   - `bisha/bishaUP/bishaSUPER→bsmian/sbsmian/cbsmian` + **入池前 qi 必须够**（否则选中后因 useQi 静默失败白掷）
   - `attackAIR/skillAIR/bishaAIR→仅 isInAir`，判定面 `tkanmian/tzmian/kbsmian`，bishaAIR 加 qi 闸
   - 排除基础槽：moveLeft/moveRight/jump/jumpQuick/jumpDown/dash/defense/hurtAction/waiKai 三件套/touchFloor/hitTarget
3. **order 给最高值 999** 压过同帧其它候选，避免掷中后被 `updateContOrder()` 静默置 false。
4. **每招一次 + 概率门**：用 `doActionTimes` 快照做当前招式只触发一次；HELL 6/10、CRAZY 10/10。
5. **只改 `FighterAILogic.as`**，`AILevel < 6` 直接 return，1~5 档零影响；HELL 与 CRAZY 共用逻辑、仅概率门不同。
6. **提交侧补 .gitignore 规则**排除 `_assets/swf` 漏网二进制（已验证该目录 0 个已跟踪文件，32 个已跟踪 png 在 `_assets/` 根不受影响）。
7. **根目录 `AI-SYSTEM-DOC.md` / `_api_doc.txt` 的删除保留并提交**（`doc/` 下有替代品）。
8. **丙与原概率链叠加不替换**：现有按距离出招的智能保留，随机纽带只是多了一个最高 order 候选。
9. **本期不碰丁、不统计 `setHitTarget` 覆盖率。**

## 四、Part B 实现计划（存档，暂未执行）

唯一改动文件：`BVNscripts/scripts/net/play5d/game/bvn/fighter/ctrler/ai/FighterAILogic.as`

1. 新增私有字段（放现有 `_crazy*` 参数块旁）：`_linkOrder:int = 999`、`_linkCooldown:int = 0`、`_linkFiredTimes:uint = 0`
2. 新增 `private function updateLinkAI():void`，在 `updateActionAI()`（:140-158）末尾 `updateSpecialSkill()` 之后调用：
   - `if(this.AILevel < 6) return;`
   - 状态闸：仅 `_fighter.actionState == FighterActionState.NORNAL(0) || JUMP_ING(14)`
   - 冷却安全网：已置标志但 `getMcCtrl().doActionTimes` 30 帧未变（doAction 未消费，如 doCatch/useQi 静默失败）→ 清标志重掷
   - 概率门：`getAIResult(0,0,0,0,0,6,10)`（HELL 读 param6=6、CRAZY 读 param7=10）
   - 建候选池（按决策 2 逐槽判定）→ `Math.random()` 均匀挑一个 → `this[槽]=true; addContOrder(槽, 999);` 记录快照与冷却
3. 施工前 grep 核查 `FighterMain.getDoingAction`（:663）、`FighterMcCtrler.doActionTimes`（:71）、`FighterActionState.NORNAL/JUMP_ING`、`isInAir` 存在（-strict=false 不拦不存在方法）
4. 验收：`./build.bat` 零错误；HELL/CRAZY 出招多样化；1~5 档不变；CRAZY 需手机端验证

## 五、待定问题

- 丁方案（命中即接）是否启动：待丙验收后由用户决定，届时需统计 `setHitTarget` 在角色 SWF 的覆盖率。
- CRAZY 真机验证：PC 菜单无 CRAZY 档，需手机端（`GameInterfaceManager` 菜单）验证。
- 67 个已跟踪文件中的 6→7 空格缩进漂移：本次照原样提交，属已知遗留。

## 六、本次提交执行情况（已回填 · 2026-10-13）

| 步骤 | 结果 |
|---|---|
| commit 1 chore | `9d51c1b` 移出误入库二进制（platform-tools / android-platform-33 / launch.as.bak / SetBtnGroup.pcode / add_asset_log.txt）+ .gitignore 补规则（21 文件，-22729 行） |
| commit 2 docs | `22b0ef9` 收拢文档到 doc/ + 新增 13 个专题/索引 + 本决策记录；根 AI-SYSTEM-DOC.md、_api_doc.txt 被 git 识别为重命名进 doc/archive/（34 文件） |
| commit 3 feat | `e3e2532` 当前开发进度（CRAZY 难度档、选人/设置/资源加载、3 个新源码、config XML）（61 文件，+15054 行） |
| commit 4 chore | `c70a4ce` BUILD_TAG 构建时间戳 |
| merge | `55e96e5` 并入 origin/master（cf48010 / e3b6f43 外置资源兼容层）；6 个冲突文件按「本地实现为准」解决：CLAUDE.md / README.md / AssetLoader.as / GameLoader.as / GameData.as / ANEFileReader.as |
| push | ✅ `e3b6f43..55e96e5 master -> master`；核验 `origin/master = 55e96e5`，本地/远端 0/0 一致 |
| build | ✅ `./build.bat` 零错误，launch.swf 生成（35480273 字节） |

### 执行中发现的额外事实

- `git add tools/script/` 会误吞 `tools/script/其他版本/`（含 adl.exe、数十首 mp3、数百张 face png 的完整资源包），已 `git reset` 退出；**勿对 tools/ 用目录级 add**，须逐条白名单。
- 远端 2 个提交与本地同改外置资源 4 件套，属**同一功能的两条并行实现线**；本地版为当前在用的实现，远端版保留在 merge 历史中可随时取回。
- 未推送内容：`BVNscripts/3.x参考/`、`PC版工程/`、`神卡3.6源文件.fla`、`选人界面排版工具/`、`tools/script/其他版本/`、`push-to-github.ps1` 等，均为参考/临时/本机资源，符合 gitignore 与提交边界。
