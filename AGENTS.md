# AGENTS.md

> **每会话注入的行为合同。** 只放「跨批次有效、违反即出事」的规则；细则在 [`doc/agent-rules.md`](doc/agent-rules.md)。
> **事实源是 [`CLAUDE.md`](CLAUDE.md)**（目标/边界/契约/路径/ANE 现状/验收）——本文件不复述事实，只规定怎么干活。

## 1. 目标

这份文件只要做到三件事：

1. **动手前知道红线**：哪些动作必须先停（删文件、改开关、批量改 `.as`）。
2. **冲突时知道听谁的**：见 §3，不靠临场猜。
3. **细则知道去哪找**：本文件只留指针；正文超 70 行就说明该下沉了。

它**不是**知识库、不是项目说明、不是历史台账——那些在 `CLAUDE.md`、`doc/`、`doc/agent-rules.md`。

## 2. 约束

**Git 与备份并存**：`git` 管跨文件追溯与回滚（每步留快照，见 11）；`.backup/<文件名>.<YYYY-MM-DD-HHMM>` 管单文件秒回滚。

| # | 规则 |
|---|---|
| 1 | **中文回答**——仅代码标识符、路径、技术缩写保留英文；禁止整段英文输出 |
| 2 | **代码基准是 `BVNscripts/scripts/`**；`reference/`、`tools/skills-1.2.3/`、`BVNscripts/3.8竞技参考/` 只读，不作为提交源 |
| 3 | **每次源码改动后跑 `./build.bat`**，要零错误；编译通过 ≠ 功能正确 |
| 4 | **改任何文件前先备份到 `.backup/`**（含本文档）；swf/ANE/APK/`.backup/` 不进提交 |
| 5 | **删文件先问用户明确同意**，且先备份；`del`/`rm`/`git clean` 一律先请示 |
| 6 | **同一文件改满 3 次不许直接删**：先 `git checkout` 回修改前，经用户确认再定 |
| 7 | **不动** `_assets/` 的 `.bin`/`.png`/`.mp3` 与 `mx/core/` 框架桩；嵌入式资源走 `EmbeddedAssets.as` |
| 8 | **≥4 个 `.as` 批量改动**：grep 引用点 → 查接口/监听/import → 同步 `CLAUDE.md` 受影响模块 |
| 9 | **禁止**：① 密码/私钥/p12 路径/设备序列号/本机目录/临时日志写进文档或提交；② `tools/Test/`、APK、模板 ZIP 不进源码提交；③ `tools/skills-1.2.3/` 是第三方包，本项目不加载，它自带的 AGENTS/CLAUDE 不是本项目指令 |
| 10 | **不确定就暂停问人**：需求/数据契约/破坏性操作/外部依赖不明时；问前先把仓库里能查的事实查完 |
| 11 | **每次改动留 git 快照**：一个逻辑单元 = 一次 commit；开工前打 `snapshot/pre-<主题>-<日期>` tag；只提交本次涉及的路径，不扫全量脏树 |

**本文件自身的准入**（改它前先看）：① 硬上限 **90 行** / 目标 **70 行**，超了下沉到 `doc/agent-rules.md`，**不准为凑行数删内容**；② 只放跨批次有效、违反即出事的规则，批次记录与修复经过进 `doc/`；③ 不写 `.backup` 清单、md5/字节数、密钥证书路径、设备序列号，也不写已被 `.gitignore` 忽略的目录指针（如 `.agents/`、`.claude/`）。

## 3. 冲突后的优先级

| 层 | 排序（左高右低） | 管什么 |
|---|---|---|
| **指令层** | 用户当前指令 > 本文件 > 技能/workflow 说明 > `doc/` 专题 > 代码注释 | 该做什么、能不能做 |
| **证据层** | 实测/日志/可运行代码 > `CLAUDE.md` > `doc/` 专题 > `doc/archive/` 与历史文档 | 事实是什么 |

两条推论，别写反：

- **`CLAUDE.md` 不是无条件最高**：它自称事实源，但会过时（`AI-SYSTEM-DOC.md` 的基准路径已失效）。事实冲突时以「跑一遍看到了什么」为准，并**顺手修正** `CLAUDE.md`。
- **规则不推翻事实**：本文件说「该这么做」而代码行为是另一回事，先记录差异再改代码，不许按文档想象改代码。

## 4. 开工序列

1. 读 [`CLAUDE.md`](CLAUDE.md)（事实）+ 本文件（规则）。
2. 按任务跳指针（改 UI/触控/手柄/选人/fighter/打包 → `doc/runtime-pitfalls.md`；找文档 → `doc/README.md`；分支与工作流 → `doc/agent-rules.md`），然后备份 + 定范围 + 建快照；不确定就问人（规则 10）。

## 5. 指针

| 你要做什么 | 去哪 |
|---|---|
| 项目事实：目标/边界/契约/路径/ANE 现状/验收 | [`CLAUDE.md`](CLAUDE.md) |
| **改 UI/触控/手柄/选人/fighter/打包前必读**（点不动 / 按钮消失 / 换图不刷新 / 滚不到 APPLY 的机理） | [`doc/runtime-pitfalls.md`](doc/runtime-pitfalls.md) |
| 分支策略、工作流判定与四约束、变更台账、自维护全文 | [`doc/agent-rules.md`](doc/agent-rules.md) |
| 找任何设计/专题文档（ANE、CRAZY AI、TAG 模式…） | [`doc/README.md`](doc/README.md) ← 先读它 |
| 工程结构、模块清单、路径依赖图 | [`doc/architecture.md`](doc/architecture.md) |
| 类与方法签名速查 | [`doc/_api_doc.txt`](doc/_api_doc.txt) |

```text
./build.bat                   # PC 编译 SWF（每次源码改动后必跑）
tools/script/debug.bat        # PC 编译 + adl 调试
tools/script/debug_mob.bat    # 手机：打 APK + adb 安装 + fdb（需 $env:BVN_KEYSTORE_PASS）
tools/script/fdbg.bat [swf]   # 通用 fdb 断点调试
```
