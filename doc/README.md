# BVN 项目文档索引

> **AI 检索入口。** 本文件是 `doc/` 的唯一目录，找文档先看这里。
> 整理日期：2026-10-11（把根目录散落文档、`docs/` 双根目录、第三方技能包统一收拢）。

## 0. 先读哪几个

| 顺序 | 文件 | 什么时候读 |
|---|---|---|
| 1 | [`CLAUDE.md`](../CLAUDE.md)（项目根） | **每次开工先读**：目标与边界、关键源码表、外部资源契约、ANE 现状、触控坑、提交与验收 |
| 2 | [`AGENTS.md`](../AGENTS.md)（项目根） | **每次开工先读**：AI 工作流规则、硬规则、静默失败陷阱判据、文件速查 |
| 3 | [`runtime-pitfalls.md`](runtime-pitfalls.md) | 改移动端 UI / 触控 / 手柄 / 选人 / Debugger / 打包前读（GPU 不刷新、点不动、按钮消失的机理与代码） |
| 3 | 本文件 | 需要按主题定位具体设计/专题文档时 |
| 4 | [`doc/architecture.md`](architecture.md) | 需要工程结构、模块清单、路径依赖图时 |

项目根目录**只保留** `CLAUDE.md` / `AGENTS.md` / `README.md` 三个入口，不再散落文档。

## 1. 目录树

```
doc/
├── README.md                     ← 本文件（文档总索引）
├── AI-SYSTEM-DOC.md              PC 分支全量 AI 系统说明〔历史文档〕
├── architecture.md               工程结构、模块清单、路径依赖图
├── ane-dev-guide.md              ANE 开发指南
├── runtime-pitfalls.md           运行时踩坑速查：GPU/触控/选人/手柄/打包/受击灵爆/开局加载〔改移动端或 fighter 前必读〕
├── _api_doc.txt                  API 文档 dump（类/方法签名速查）
├── 38-rule-stage/                3.8「独立规则设置界面」专题
│   ├── rule-stage.md               实现详解 + 3.3↔3.8 规则项对照 + 移植要点
│   └── plan.md                     PC 工程新增独立规则页的实现计划（含坑）
├── ane/                          ANE 专题（已停用路线的完整记录）
│   ├── proposal.md                 立项说明
│   ├── high-level-design.md        高层设计
│   ├── detailed-design.md          详细设计
│   └── tasks/progress.md           任务与进展
├── crazy-ai/                     CRAZY 人机难度移植〔手机端主项目，重点〕
│   └── crazy-ai.md                 档位机制、逐项移植对照、调参坑、回滚
├── external-fighter-37/          外置人物/外置资源迁移
│   ├── proposal.md / high-level-design.md / detailed-design.md
│   ├── source-comparison.md        源码差异对照
│   ├── external-ane-user-guide.md  外置资源使用说明（给玩家/作者）
│   ├── tasks/                      android-validation / asset-resolution /
│   │                               fighter-registration / metadata-and-assets / progress
│   ├── template-package/           外置人物模板包（config/*.xml + README + MANIFEST）
│   └── external-fighter-template-package.zip
├── jingji/                       竞技项（规则/行为/卍解/重复选取等）
│   ├── proposal.md / high-level-design.md / detailed-design.md / prompt.md
│   └── tasks/                      progress + t1-config … t7-final（分任务实施记录）
├── kai-chang/                    开场
│   ├── proposal.md
│   └── tasks/progress.md
├── adr/                          架构决策记录（原 docs/adr/ 并入）
│   ├── README.md
│   └── ADR-001-单页窗口与翻页交互.md
├── plans/                        实施计划
│   └── 2026-09-07-选人界面工具-单页窗口与翻页.md
└── archive/                      归档：过时 / 重复 / 第三方 / 日志
    ├── AI-SYSTEM-DOC.root-stale-2026-09-01.md   根目录旧版（已被 doc/ 内 10-09 版取代）
    ├── _api_doc.root-duplicate.txt              与 doc/_api_doc.txt 完全相同
    ├── CONTEXT.md                               mattpocock 工作流术语表
    ├── grill-me-SKILL.md                        第三方技能定义文件
    └── logs/
        ├── build_output.txt                     构建日志
        ├── mob_build.log                        打包日志
        └── mob_lint.log                         lint 日志
```

## 2. 按主题快速定位

| 我要做什么 | 看哪个 |
|---|---|
| 编译 / 打包 / 装机 | [`CLAUDE.md`](../CLAUDE.md)「交付验收」+ [`ane-dev-guide.md`](ane-dev-guide.md) |
| 外置人物为什么没出现在选人列表 | [`external-fighter-37/detailed-design.md`](external-fighter-37/detailed-design.md)、[`tasks/fighter-registration.md`](external-fighter-37/tasks/fighter-registration.md)、`CLAUDE.md`「外部资源契约」 |
| 外置资源路径 / 外置优先解析 | [`external-fighter-37/tasks/asset-resolution.md`](external-fighter-37/tasks/asset-resolution.md)、`CLAUDE.md`「外部资源契约」 |
| ANE 为什么不能用 | [`ane/tasks/progress.md`](ane/tasks/progress.md) + `CLAUDE.md`「ANE 现状：已按设计停用」 |
| 改 PC 端 AI 等级 / 难度 | [`crazy-ai/crazy-ai.md`](crazy-ai/crazy-ai.md)（**手机端主项目**）、[`AI-SYSTEM-DOC.md`](AI-SYSTEM-DOC.md)（PC 分支，历史） |
| 规则设置界面（3.8 独立规则页） | [`38-rule-stage/rule-stage.md`](38-rule-stage/rule-stage.md) → [`38-rule-stage/plan.md`](38-rule-stage/plan.md) |
| 竞技项（规则/行为/卍解/重复） | [`jingji/detailed-design.md`](jingji/detailed-design.md) + [`jingji/tasks/`](jingji/tasks/) |
| 开场演出 | [`kai-chang/proposal.md`](kai-chang/proposal.md) |
| 选人界面翻页 / 单页窗口决策 | [`adr/ADR-001-单页窗口与翻页交互.md`](adr/ADR-001-单页窗口与翻页交互.md)、[`plans/2026-09-07-选人界面工具-单页窗口与翻页.md`](plans/2026-09-07-选人界面工具-单页窗口与翻页.md) |
| 类/方法签名速查 | [`_api_doc.txt`](_api_doc.txt) |
| 走查工程结构 / 模块清单 | [`architecture.md`](architecture.md) |
| 改移动端 UI / 触控 / 手柄 / 选人 / Debugger / 打 APK | [`runtime-pitfalls.md`](runtime-pitfalls.md)（无法解释的点不动 / 旧图不刷新 / 按钮消失 / 日志抓不到，先看它） |
| 受击僵直 / 灵爆金身 / 替身术 / 开局黑屏 / `创建游戏失败` | [`runtime-pitfalls.md`](runtime-pitfalls.md) **§7**（三计数器自锁、人物包脏帧脚本、转场回调重试 + 验收断言） |

## 3. 相关但不在 `doc/` 下的文档

| 路径 | 用途 |
|---|---|
| [`BVNscripts/scripts/REGRESSION_TEST_MATRIX_BATCH6.5.md`](../BVNscripts/scripts/REGRESSION_TEST_MATRIX_BATCH6.5.md) | 选人界面人物子框回归测试矩阵（改 `SelectFighterItem/SelectFighterStage/SelectStageConfigVO/MenuBtn` 时须同步刷新，含已知失效章节说明） |
| [`BVNscripts/3.8竞技参考/竞技改代码/CLAUDE.md`](../BVNscripts/3.8竞技参考/竞技改代码/CLAUDE.md) | 3.8 竞技版参考代码索引（**只读参考，不改造**） |
| `tools/Test/_report/` | 真机诊断报告（如 `2026-10-09_ANE-诊断报告.md`） |
| [`tools/skills-1.2.3/`](../tools/skills-1.2.3/) | 第三方技能包（mattpocock/skills v1.2.3，原样留存，**非本项目文档**） |
| `.backup/` | 本地改动前快照（**不进提交**，见 `CLAUDE.md` 与 `.gitignore`） |

## 4. 维护约定

1. **新增文档一律放 `doc/` 下**，按主题建子目录；**不要再建第二个顶层 `docs/`**。
2. 新增/移动文档后，**同步更新本文件的目录树与快速定位表**，并在 `CLAUDE.md` 的「文档地图」里登记（如果新增了顶层分类）。
3. **过期但仍有参考价值的文档移入 `doc/archive/`**，不要直接删除；在本文件里标注被谁取代。
4. 构建日志（`build_output.txt`、`mob_*.log`）属**临时产物**，不进提交；需要留档时放 `doc/archive/logs/`。
5. 第三方/工具类资料（技能包、SDK 说明）**不要混进 `doc/`**，放 `tools/`。

### 4.1 约定例外：mattpocock/skills 工作流的产物路径

`.agents/skills/`、`.claude/skills/` 下的 [mattpocock/skills](https://github.com/mattpocock/skills) 类技能（`grill-with-docs`、`domain-modeling` 等）按**上游约定**写入：

- 仓库根 `CONTEXT.md`（领域术语表）
- `docs/adr/`、`docs/grill-with-docs/{plans,decisions,reviews}/`

**这不是本项目文档，也不要试图收拢进 `doc/`**：这些技能会从上游覆盖，路径改不动；一旦使用就会重新生成上述路径。

> 现状（2026-10-11 归档时）：已有产物已收拢 —— `docs/adr/` 的 ADR 与 README 归入 [`doc/adr/`](adr/)、计划归入 [`doc/plans/`](plans/)、根目录 `CONTEXT.md` 归入 [`doc/archive/`](archive/CONTEXT.md)。
> 若再次运行这些技能，`docs/`（小写复数）可能重新出现 —— **属预期，不必再合并**；只把其中有长期价值的 ADR/计划按上表搬进 `doc/` 即可。
