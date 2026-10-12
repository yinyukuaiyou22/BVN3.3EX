# AGENTS.md

本文件是 **AI 开工第一步**。它规定「怎么干活」；`CLAUDE.md` 规定「项目是什么」。

**分工铁律**：`CLAUDE.md` 是事实的唯一真相源（目标/边界/契约/路径/ANE 现状/验收）。本文件**不复述事实**，只给指针。**两份冲突时以 `CLAUDE.md` 为准**——本文件已从 770 行压到本版本，被删掉的旧章节里与本版本冲突的内容一概作废。

## 自维护规则（改本文件前必读）

本文件之所以会退化成 770 行沉积物，根因是缺这几条。改它的人（人或 AI）必须遵守：

1. **上限 200 行**。超了就把内容下沉到 `doc/`，在这里留指针——**不准为了凑行数删内容**。
2. **准入清单**：只放**跨批次有效、违反即出事**的规则与陷阱。批次性记录、某一次的修复经过、某个 swf 的字节数，一律进 `doc/`。
3. **禁止写入**：`.backup` 文件名清单、编译产物 md5/字节数、密钥与证书路径、设备序列号、已被 `.gitignore` 忽略的目录里的指针（如 `.claude/`）。
4. **改了 `CLAUDE.md` 的事实也要回头看这里**：本文件的指针必须始终指向真实存在且未被忽略的路径。
5. 新专题文档一律放 `doc/`，同步更新 `doc/README.md`。

## 开工序列

1. 读 [`CLAUDE.md`](CLAUDE.md)（事实），读本文件（规则）。
2. 按任务类型读指针：改 UI/触控/手柄/选人 → `doc/runtime-pitfalls.md`；找设计文档 → [`doc/README.md`](doc/README.md)。
3. 动手前备份、明确的范围、遇到不确定就问人。

## 硬规则

**Git 与备份（两者并存）**：本项目**在 Git 管控下**（仓库根有 `.git`，`.gitignore` 已生效）。`git` 用于跨文件版本追溯与提交，`.backup/<文件名>.<YYYY-MM-DD-HHMM>` 用于单文件秒回滚。**单次改动 ≥4 个 `.as` 文件前，先 `git status` 确认基线。**

| # | 规则 |
|---|---|
| 1 | **中文回答**——仅代码标识符、路径、技术缩写保留英文。禁止整段英文输出 |
| 2 | **代码基准是 `BVNscripts/scripts/`**；参考目录（`reference/`、`tools/skills-1.2.3/`、`BVNscripts/3.8竞技参考/`）只读不作为提交源 |
| 3 | **每次源码改动后跑 `./build.bat`**，要零错误；编译通过不等于功能正确 |
| 4 | **改任何文件前先备份到 `.backup/`**（含本文档）；swf/ANE/APK/`.backup/` 不进提交 |
| 5 | **删除文件必须先问用户明确同意**，且先备份。`del` / `rm` / `git clean` 一律先请示 |
| 6 | **同一文件改满 3 次不许直接删**：先 `git checkout` 回到修改前，经用户确认再定 |
| 7 | **不动** `_assets/` 里的 `.bin`/`.png`/`.mp3` 与 `mx/core/` 框架桩；嵌入式资源走 `EmbeddedAssets.as` |
| 8 | **≥4 个 `.as` 文件的批量改动**：联动排查三项——grep 被改类名/方法/常量的引用点 → 检查接口实现/事件监听/import 遗漏 → 同步更新 `CLAUDE.md` 受影响模块的描述 |
| 9 | **禁止**：① 私密内容不得提交也不得写进任何文档——密码、私钥、p12 证书路径、设备序列号、本机用户目录、临时日志；② 不要把 `tools/Test/`、APK、模板 ZIP 加入源码提交；③ `tools/skills-1.2.3/` 是第三方参考包，**本项目不加载它**，它自带的 `AGENTS.md`/`CLAUDE.md` 不是本项目的指令 |
| 10 | **不确定就暂停问人**：需求/数据契约/破坏性操作/外部依赖不明确时。问之前先把在本仓库里能查到的事实查完 |

**删掉了什么、为什么**（防止有人从旧备份里捡回来）：

| 旧章节 | 处置 | 原因 |
|---|---|---|
| Android 目录用 `/storage/emulated/0/BVN3.3EX-master/` | ❌ 删 | 旧 Termux 路径，早已不适用。现行路径见 `CLAUDE.md` |
| 「本项目无 Git 版本控制」 | ❌ 改 | 事实错误，与 `CLAUDE.md` 的 git 规程冲突 |
| §9 备份台账（54 行文件名清单） | ❌ 删 | 是历史沉积物，`.backup/` 目录本身已足够检索 |
| Headroom 上下文压缩 | ❌ 删 | 仓库内零落地痕迹 |
| 模型配置 / `tools/route_model.py` 路由 | ❌ 删 | 宿主专有且与本仓库干活无关 |
| 调用格式表（`read_file`/`edit_file`/`super_admin:terminal`） | ❌ 删 | 指名了不属于本项目的宿主工具名 |

## 静默失败陷阱（不报错、不打日志，只能靠预先知道）

完整机理与可抄代码见 [`doc/runtime-pitfalls.md`](doc/runtime-pitfalls.md)。这里是让你**在写错之前想起**它的判据表。

| 陷阱 | 症状 | 判据 / 正确写法 |
|---|---|---|
| **包装类监听判据**<br>`SelectFighterItem` / `MenuBtn` | 选人界面能显示但**点不动**，无任何日志 | 判据用本类登记表 `_listeners[type] == null`，**不能用 `ui.hasEventListener(type)`**；且**必须**同时重写 `removeEventListener`（否则 `ENTER_FRAME` 永不注销 → 每帧 `addChild` + 每帧写日志 = 卡顿与刷屏的根因）。通用教训：包装类的"已注册"判据只能以自己登记表为准 |
| **设置列表滚不到 APPLY**<br>`SetBtnGroup.moveScroll()` / `enableScrollDrag()` | 设置存不了**也退不出**（同一原因） | 视口要按 `GameConfig.GAME_SIZE.y / scaleY ≈ 545`（**不是** `_scrollRect.height=600`，本类 `TOUCH_MODE` 下 `scale=1.1`）；`launch.FULL_SCREEN_SIZE` 是**设备像素**，别在本地单位混算里用。`scrollRect.y` 增大 = 显示更靠下，改前对照 `moveScroll` |
| **GPU 纹理不刷新** | 换了 `bitmapData`，显示**仍是旧图** | 创建**全新 Bitmap 对象**替换整个 `display` 属性（如 `_switchPlayer` 的 P1/P2 按钮） |
| **`graphics.clear()` 尺寸归零** | 按钮点一下之后**消失** | `clear()` 后 `width/height` 变 0 → 别用动态属性画矩形，用静态常量（如 `_closeBtnSize`） |
| **`SELECT_STATE` 必须恒为 0** | 选人界面第二次起 `#2025` 刷屏 | `select.swf` 帧脚本每帧消费它。教训：主程序静态变量会被帧脚本每帧消费，赋非 0 前先查帧脚本怎么读 |
| **长按只对 2 个角色生效** | 长按子框没反应，怀疑是 bug | 只有配了 `plugins=` 的角色（52 个里仅 `灵梦,妹红`、`早苗,妹红`）才展开子框。**测长按必须用这两个**；其余是设计的静默 return |
| **ANE 两个开关别混用** | 关了 `ANE_ENABLED` 后外置资源整体失效 | `EXTERNAL_ENABLED`（默认 true）才是外置资源总开关；`ANE_ENABLED`（默认 false）只管是否创建扩展上下文。**不要主动改这两个开关**（尤其别用 `ANE_ENABLED` 去"打开/关闭"外置资源，曾经踩过）。路线现状是"已按设计停用"，见 `CLAUDE.md` |
| **`-strict=false` 放过不存在的方法** | 编译零错误，运行时 `TypeError #1006`，且**这一行的日志也没写出去** | 调用跨类静态方法前**先 grep 确认方法存在**。真实事故：`GameMode.getCurMode()` 整个项目不存在（只有 `getTeams()` 等 10 个），害整个 `Debugger.log()` 表达式求值前就抛错 → 选人黑屏且入口日志缺失。详见 `doc/runtime-pitfalls.md` §1B |
| **`-strict=false` 放过缺 import** | 编译过、运行时炸 `#1065` | 跨包引入新符号**先手工核对 import**，别指望编译器 |
| **trace 不进 logcat** | 真机看不到任何游戏日志 | 读文件日志（路径与抓取命令见 `CLAUDE.md`「真机日志」） |

## 导航

| 你要做什么 | 去哪 |
|---|---|
| 项目事实：目标/边界/契约/路径/ANE 现状/验收 | [`CLAUDE.md`](CLAUDE.md) |
| 找任何设计/专题文档 | [`doc/README.md`](doc/README.md) —— **先读它** |
| 改移动端 UI / 触控 / 手柄 / 选人 / Debugger / 打 APK | [`doc/runtime-pitfalls.md`](doc/runtime-pitfalls.md) |
| 工程结构、模块清单、路径依赖图 | [`doc/architecture.md`](doc/architecture.md) |
| ANE（已停用路线的完整记录） | [`doc/ane/`](doc/ane/)、[`doc/ane-dev-guide.md`](doc/ane-dev-guide.md) |
| AI 难度档位 / CRAZY 移植细节 | [`doc/crazy-ai/crazy-ai.md`](doc/crazy-ai/crazy-ai.md)（手机端主项目）；PC 分支 [`doc/AI-SYSTEM-DOC.md`](doc/AI-SYSTEM-DOC.md)〔历史，基准路径已失效〕 |
| 类与方法签名速查 | [`doc/_api_doc.txt`](doc/_api_doc.txt) |

**常用命令**（详见 `CLAUDE.md`）：

```text
./build.bat                      # PC 编译 SWF（每次源码改动后必跑）
tools/script/debug.bat           # PC 编译 + adl 调试
tools/script/debug_mob.bat       # 手机：打 APK + adb 安装 + fdb（需 $env:BVN_KEYSTORE_PASS）
tools/script/fdbg.bat [swf]      # 通用 fdb 断点调试
tools/script/add_asset.py        # 资产工具：自动添加角色/辅助/地图
```

> **手机端 trace 不进 logcat**（这是"零日志"场景的第一步）。真机游戏日志要读文件：
> `adb exec-out run-as air.com.bvn.yy798 cat "/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log"`
>
> 若能直接 adb root/shell，路径同上；这一行解决不了时再查 `CLAUDE.md`「真机日志」。

**复杂功能走工作流**：≥3 个文件、涉及新模块或架构变更时，用 `.agents/skills/vibe-coding-workflow/`。**阶段数以该 SKILL.md 为准，本文件不复述**（避免再次出现文档写 6 段、skill 实际 7 段的漂移）。

| 场景 | 是否启用 |
|---|---|
| 单文件小修 / 已有明确方案且 ≤2 文件 | 直接改 |
| 新功能 / 新模块 / 跨层修改 | 必用 |
| ANE / 构建脚本 / 打包流程变更 | 必用 |
| 重构 / 多文件联动 / API 接口变更 | 必用 |

四条工作流硬约束：① 先有 `doc/<feature>/proposal.md`（目标/成功标准/待决问题）再写码；② 每个任务 ≤3 个文件，完成后 `git diff` 审查 + `./build.bat`；③ `progress.md` 是唯一真相源（状态/阻塞/跑过的命令）；④ AI 输出在通过编译 + diff 审查前**只算草稿**。

## 文件速查

| 需求 | 看哪 |
|---|---|
| 编译 / 入口 | `build.bat`、`asconfig.json`、`BVNscripts/scripts/launch.as`、`MainGame.as` |
| 物理参数 / 碰撞 | `GameConfig.as`、`GameMainLogicCtrler.as` |
| 角色动作 / AI | `FighterMcCtrler.as`、`FighterAction.as`、`net/play5d/game/bvn/fighter/ctrler/ai/FighterAILogic.as` |
| 资源加载 / 外置扫描 | `ctrl/AssetLoader.as`、`ctrl/GameLoader.as`、`mob/utils/ANEFileReader.as` |
| 菜单 / 设置 / 暂停 | `MenuBtnGroup.as`、`MenuBtn.as`、`SetBtnGroup.as`、`SettingState.as`、`PauseDialog.as` |
| 选人 / 分页 | `SelectFighterStage.as`、`SelectStageConfigVO.as`（回归矩阵见 `BVNscripts/scripts/REGRESSION_TEST_MATRIX_BATCH6.5.md`） |
| 输入 / 手柄 | `GameInputer.as`、`FighterKeyCtrl.as`、`mob/GameInterfaceManager.as`、`mob/screenpad/` |
| 配置存档 / UI SWF / 嵌入式资源 | `data/GameData.as`、`ConfigVO.as`、`utils/ResUtils.as`、`EmbeddedAssets.as` |
| 调试面板 / 网络 | `Debugger.as`（`DEBUG_PANEL_ENABLED`）、`mob/sockets/`、`mob/ctrls/LAN*.as` |
| 安卓打包 | `tools/Test/application.xml`、`tools/script/debug_mob.bat` |

> 路径未标目录的，均在 `BVNscripts/scripts/net/play5d/game/bvn/` 下。

## 分支策略

| 分支 | 用途 | 远程 |
|---|---|---|
| `master` | 完整开发版（含实验功能） | `mobile` (3.3BVNmobile) |
| `公开部分` | 公开稳定版 | `origin` (BVN3.3EX) |

公共 bug 修复先提交到 `master`，再 cherry-pick 到 `公开部分`。
