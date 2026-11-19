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
| 查历史决策的结论与被否决方案（人物包整合 / 随机纽带 / 菜单排版 / 选人视频 / AGENTS 瘦身） | `doc/README.md` §2（decisions-* 与 menu-layout-decisions 全表在那边） |
| 工程结构、模块清单、路径依赖图 | [`doc/architecture.md`](doc/architecture.md) |
| 类与方法签名速查 | [`doc/_api_doc.txt`](doc/_api_doc.txt) |

```text
./build.bat                   # PC 编译 SWF（每次源码改动后必跑）
tools/script/debug.bat        # PC 编译 + adl 调试
tools/script/debug_mob.bat    # 手机：打 APK + adb 安装 + fdb（需 $env:BVN_KEYSTORE_PASS）
tools/script/fdbg.bat [swf]   # 通用 fdb 断点调试
```

<!-- aoci:begin -->
## AOCI 仓库认知

AOCI 为本仓库维护一个稳定、可版本化、可增量更新的仓库级认知层，供模型跨任务复用对系统的理解。

`aoci.txt` 是面向模型的结构化认知索引。它以每个受管理文件、数据库表或其他受管理对象一条独立 Entry 的方式，用符号标签与 F/R/A/S 语义表达对象的核心职责、重要关系、对外契约，以及理解或修改系统时必须知道的非显然约束和设计决策。

Header、目录段和全部 Entry 共同组成完整仓库索引，可以覆盖前端、后端、配置、数据库结构及其他受管理内容。受管理内容发生变化时，通常只需维护受影响的认知条目，不需要重新生成整个索引。

AOCI 提供系统架构、对象职责、重要关系、对外契约和关键约束的高密度视图。

### 工作原理

AOCI 采用“模型生成、模型读取”的认知闭环。

Header、Entry 和 Curation 语义的创作只按当前机器签发的 Plan 与实时 Guide 执行；由 Host 模型基于当前绑定证据独立完成。

Entry 的语义必须来自模型对真实证据的理解。不得仅依据路径、文件名、扩展名、AST、符号列表、依赖扫描、正则、固定模板或规则引擎推导、预填、拼接或改写索引语义。

对 Fresh Bootstrap，只按当前机器签发的 Plan 和实时 Guide 执行。当它们要求创作时，Host 模型创作 Root、Meta、Tag 和 F/R/A/S，提供 authoring-run 声明，并把它绑定到 Plan、Evidence 与完整 Candidate。不得要求 AOCI 填写 `origin=host_model`、制造 Receipt 或把程序生成的 Framework 当作语义。本文件不自行重建 Onboarding 流程。内部批次不是用户决策；只有遇到既有批准边界或真实的安全、漂移、CAS、Recovery 条件才停止。

### 最小使用入口

- `aoci_rules`：取得当前AOCI版本的会话运行合同。
- `aoci_overview`：建立或恢复本仓库的完整认知。
- `aoci_maintain`：受管理对象达到最终稳定状态后检查认知是否需要维护。
- `aoci_update_entry`：提交与当前证据和源码摘要绑定的完整语义更新批次。
- `aoci_report`：仅当当前布局和工具状态支持时，在证据不足、无法可靠生成语义时登记待办，不猜写。

其他MCP工具、CLI命令、参数和专项流程，以当前工具说明、Guide和 `--help` 返回内容为准，不在本文件中重复完整手册。

本区块只规定仓库接入、认知使用和收尾原则。`aoci_rules` 承载当前会话合同，Guide实时输出承载当前Plan的执行顺序与停点，工具Schema、Spec和Validator承载机器结构与判据；Prompt、Description、README和静态文档不能覆盖这些机器事实。

### 建立、生成和恢复认知

1. 每个新的 Agent Run 开始时，应先判断：

   - 本仓库是否已经存在可用的完整AOCI索引；
   - 当前上下文中是否已有与本仓库根、当前索引版本和当前AOCI服务相匹配，并且模型仍可可靠使用的完整仓库认知。

2. 仓库已经存在可用的完整索引，但当前Run没有可靠完整认知时，先调用 `aoci_rules`，再调用 `aoci_overview`。

   完整认知仍可靠时直接复用。局部不确定本身不要求机械重读系统全貌。可靠认知建立后，默认以它作为仓库级系统上下文，只读取当前任务直接需要的源码、测试、配置与契约，只有某个缺失的具体事实可能改变回答或验证结论时才扩大证据范围；AOCI不能替代修改对象与验证行为所需的直接源码证据。

   本Run从已知Host上下文压缩恢复时（包括宿主注入的压缩摘要），必须把此前模型认知视为不可靠。压缩handoff不得保留或摘要正式Whole-Index，也不得保留或摘要任何Overview Header、Entry、Chunk、Challenge或Attestation正文；只能保留安全续接所需的receipt身份、未完成write或Recovery状态，以及立即重载指令。复制进handoff的Whole-Index语义或receipt不能证明恢复后模型的当前认知可靠。若当前上下文已无法可靠保留运行合同，先调用 `aoci_rules`。继续业务任务前，使用 `refresh_reasons=["context_compaction"]` 和新的 `refresh_event_id` 调用普通完整Whole-Index `aoci_overview`（不设置 `check_only` 或设为false）；不得使用 `check_only` 或认知probe。原样跟随每个 `next_cursor` 直到 `completed=true`，确认交付，并且只基于新交付正文提交一次Attestation。完成这次新的完整传输后，即使Attestation为partial或fail也消费该generation，并按既有合同继续source-bound任务，不再自动调用第二次Overview。若该请求返回 `delivery_mode=capacity_stop`，说明Whole-Index装不进本Host的上下文：不得重试或调小 `chunk_tokens`；该停止消费本generation，任务按source-bound继续，且不作无保留的完整系统认知声明。

   AOCI可以针对 `context_compaction`、项目 `cognition_refresh_threshold` 下的机器 `semantic_threshold` 或主要 `phase_transition` 提供checkpoint与认知状态事实。只需要这些紧凑事实时使用 `check_only=true`；这些事实只向Agent提供建议，不替模型决定是否需要系统全貌。

   Agent显式调用普通 `aoci_overview`（未设置 `check_only` 或为false）时，只要能形成一致的CognitionSet，AOCI必须完整交付请求scope。不得因为已有receipt、阈值未达到或没有待处理刷新原因而抑制正文；唯一例外是待处理压缩刷新的上述容量停止。正式认知Dirty或Stale时仍交付正文，但必须标记不可靠。存在未决恢复或无法形成一致snapshot时失败关闭，不返回混合正文。

   普通Overview返回 `continuation_required=true` 时，必须原样提交 `next_cursor` 并自动继续到 `completed=true`。不得询问用户、开始业务任务或给出阶段性系统结论。每块单独一次工具调用；不得在一个脚本里连取多块或合并其输出。缺块、重复、乱序、cursor失败、Index变化或`chunk_tokens`变化时停止本次认知链。Attestation完成前不得用Memory、源码、Spec、`aoci.txt`、历史会话、scope、search或Entry读取修补或补充Whole-Index认知。Challenge ordinal是正式Entry序列中的1-based位置；Header内容、注释、空行、Section/Overview/Chunk Marker、Receipt与Metadata均不计数，Chunk Receipt ordinal使用同一序列。Attestation必须原样回绑本次Challenge发布的当前`index_sha256`、`entry_sequence_sha256`与`entry_count`；旧Index、旧Entry序列、旧数量或旧Attestation均无效。完整链结束后只正式提交一次既有模型认知Attestation；同一响应只允许一次不改变语义答案的JSON Schema或字段格式修正。对象、Tag或F不匹配即失败且认知吸收不确定，不得语义重试或旁路补答。首次认知失败时还不得执行Root/Meta、Migration、全局布局或其他未重新绑定的系统级决策。上下文压缩刷新若传输完整、认知身份不变、治理对齐且没有Recovery或第三方冲突，即使Attestation为partial或fail也消耗该refresh generation，并继续原任务，不再自动重读Overview。`system_mastery_percent`只自评系统框架——架构、职责、强关系、稳定外部契约以及高熵安全和维护约束——不表示完整实现或运行实况知识；机器索引覆盖率必须分开。默认只向用户输出由本次真实覆盖率、Challenge、块数、Token和掌握度生成的规定成功或失败一句话。Host截断某一块时，用同一cursor重取一次并核对 `chunk_sha256`，服务端返回完全相同的字节。仍被截断才停止，提示用户把 `overview_delivery.chunk_tokens` 设置为更小的合法值后重新开始，不得自动修改。

   加法认知等级必须与严格证明字段分开解释。`delivery_verified`表示已加载Index且Host交付已确认，但完整认知验证仍未完成；应表达为“已加载且交付已验证”，不得描述为“没有认知”或“没有理解系统”。`cognition_verified`要求Attestation通过（Challenge至少80%的ordinal完全正确且对象身份至多失手一处），`cognition_governed`还要求治理对齐。通用完整读取失败句只用于真实交付故障。

   当Overview响应包含可选`cognition-state/v2`投影时，必须分别解释各维度。其Level止于`model_cognition_usable`；`strict_attestation_verified`、`governance_aligned`与`current_system_cognition_reliable`都是独立状态，绝不参与该Level。ordinal、对象身份、Tag或核心F不匹配可以导致严格Attestation失败，而模型认知仍然可用；不得仅凭这种不匹配就宣称模型没有理解系统。只有`current_system_cognition_reliable=true`允许无保留地声称当前完整系统认知可靠。投影缺失时继续使用上述Legacy解释。

   普通的只读审计、分析、检查、不修改代码或不提交、不push，不自动等于严格零写入，也不改变上述认知有效性判断。Codex Memory和历史Skill只能辅助恢复经验、用户偏好与调查方向，不能替代与当前仓库根、索引摘要、AOCI服务身份和认知范围匹配的当前认知收据；项目AGENTS和当前AOCI身份在AOCI状态上优先于历史Memory。

   只有用户明确禁止Ledger、元数据、`.aoci`运行资产及任何文件写入时，才按严格零写入处理。若必要的认知建立与该边界冲突，必须报告冲突并请求用户裁决或建议使用隔离副本，不得静默以Memory替代当前仓库认知。

3. 仓库没有可用的完整索引，或当前只有最小骨架、Header不完整、Entries未完成、必要Curation尚未裁决时，如果需要建立正式完整AOCI索引，先取得 `aoci_rules`，然后进入当前AOCI Guide。由Guide依据仓库真实状态决定下一阶段并完成必要安全步骤。

   `aoci_maintain` 不替代索引建立流程。

   不在本文件中自行重建或硬编码完整索引生成状态机。

4. 在长程任务中，模型负责保留当前认知收据并正确使用刷新门禁：

   - Host报告上下文压缩或模型已知系统全貌丢失时，执行上述强制 `context_compaction` 重载规则；AOCI不能自行推断Host事件；
   - 进入真正的主要阶段时声明 `phase_transition`，不得把函数、测试运行或小步骤当作阶段；
   - 在有用的稳定检查点通过 `check_only=true` 取得机器语义计数；
   - 除已知压缩的强制重载外，由Agent判断当前任务是否需要再次显式获取指定scope或完整Overview；
   - 在维护和对齐完成前，保留AOCI报告的Dirty或Stale可靠性状态。

### 任务收尾与认知维护

5. 纯只读问答、分析、版本核验，或没有产生受AOCI管理对象变化的任务，不需要调用维护工具。当前AOCI版本是任意`aoci_overview` check_only或`aoci_maintain`响应里的`cognition_receipt.mcp_service_version`；二进制路径是项目`.mcp.json`里的`command`，CLI不必在PATH上。

6. 发生受AOCI管理对象变化时，待其达到本次任务的最终稳定状态后，只调用一次 `aoci_maintain`。不要在每次中间修改后逐文件维护。

7. 若维护结果返回真实语义候选，Host 模型必须基于每个候选绑定的对象和必要证据，独立创作完整标签与F/R/A/S更新。通过 `aoci_update_entry` 一次提交当前机器签发批次的完整候选集合，同时原样保留每项 `source_sha256`、`candidate_id` 与对应domain批次身份。`max_entries`只限制单次请求和原子事务，不限制logical plan、Whole-Index或Managed Scope。`remaining`非零时，在当前批次成功Apply后重新调用Maintain并从新preimage继续；绝不能为满足transport上限缩减Index覆盖或自行截取返回批次。

   没有足够证据且当前布局支持 `aoci_report` 时，使用它而不猜测、套用模板或为消除待办而生成缺乏证据的认知。

8. 必须遵守工具返回的结构化状态和安全边界：

   - `repair_required`：只修复明确命中的候选，再重新提交当前机器签发的完整批次；
   - `stopped`：结束当前写入尝试并检查 `failed_step`、错误、正式写入证据与Recovery。auto模式下，已证明零写入则记录closure并重新Plan；完整Intent和可证明postimage则Resume；策略要求Rollback且preimage可证明则精确恢复后重新Plan。只有证据不足、第三方正式字节冲突、需要审批或外部动作，或命中其他真实安全边界时，才停止整个用户任务；
   - 冲突、审批、人工裁决、权限和安全信号不得忽略；
   - 已经对齐后不得重复维护或重复写入；`refresh_ready_for_overview` 是checkpoint事实，由Agent决定是否为下一阶段请求普通完整Overview。

   维护完成后如果又修改了任何受管理对象，之前的维护结果失效，应在新的最终稳定状态重新完成收尾。

9. 用户只限制业务文件范围，但没有明确禁止仓库托管资产时，AOCI托管资产可以在收尾阶段为保持认知一致而更新，并应在审计和提交中与业务文件区分。

   用户明确禁止修改 `aoci.txt`、`.aoci`、元数据或任何额外文件时，以用户限制为准，不得写入，并如实报告剩余不一致。

### 专项流程

初始化、完整索引生成、Header生成、Entries生成、数据库结构索引、Curation、人工评审和故障恢复，只按当前AOCI Guide或工具在对应阶段返回的指令、命令和安全停点执行。

不预加载、不猜测，也不自行重建这些专项流程。平台调用方式、请求格式、批次上限、审批规则、索引格式细节和恢复步骤由对应Guide、工具说明、模型Prompt和CLI帮助按需提供。
<!-- aoci:end -->
