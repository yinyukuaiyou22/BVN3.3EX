# BVN 项目文档索引

> **AI 检索入口。** 本文件是 `doc/` 的唯一目录，找文档先看这里。
> 整理日期：2026-11-19（补 4 份决策/清单、2 份计划与 archive 实际条目，链接零失效）；上一轮 2026-10-11 收拢根目录散落文档与 `docs/` 双根目录。

## 0. 先读哪几个

| 顺序 | 文件 | 什么时候读 |
|---|---|---|
| 1 | [`CLAUDE.md`](../CLAUDE.md)（项目根） | **每次开工先读**：目标与边界、关键源码表、外部资源契约、ANE 现状、触控坑、提交与验收 |
| 2 | [`AGENTS.md`](../AGENTS.md)（项目根） | **每次开工先读**：行为合同——11 条红线、冲突后的优先级、指针 |
| 3 | [`agent-rules.md`](agent-rules.md) | 查分支策略 / 工作流判定与四约束 / 变更台账 / 自维护规则全文时 |
| 3 | [`runtime-pitfalls.md`](runtime-pitfalls.md) | 改移动端 UI / 触控 / 手柄 / 选人 / Debugger / 打包前读（GPU 不刷新、点不动、按钮消失的机理与代码） |
| 3 | 本文件 | 需要按主题定位具体设计/专题文档时 |
| 4 | [`doc/architecture.md`](architecture.md) | 需要工程结构、模块清单、路径依赖图时 |

项目根目录**只保留** `CLAUDE.md` / `AGENTS.md` / `README.md` 三个入口文件；另有一个 `docs/` 目录专放**用户向**文档（见 §3），开发向文档不再散落到根目录。

## 1. 目录树

```
doc/
├── README.md                     ← 本文件（文档总索引）
├── agent-rules.md                AGENTS.md 的细则层（分支策略 / 工作流 / 变更台账 / 自维护全文）
├── AI-SYSTEM-DOC.md              PC 分支全量 AI 系统说明〔历史文档〕
├── architecture.md               工程结构、模块清单、路径依赖图
├── ane-dev-guide.md              ANE 开发指南
├── runtime-pitfalls.md           运行时踩坑速查 + 主项目开发日志（§9）：GPU/触控/选人/手柄/打包/受击灵爆/开局加载〔改移动端或 fighter 前必读〕
├── gpu-filter-proxy.md           GPU 模式滤镜位图代理层（设计 + 实测 + 附录 A 改动履历 / 附录 B 12 条错误经验）〔外部包滤镜 / 时停灰度必读〕
├── select-regression-matrix.md   选人界面回归测试矩阵（原 `BVNscripts/scripts/REGRESSION_TEST_MATRIX_BATCH6.5.md`，2026-10-21 移入）
├── _api_doc.txt                  API 文档 dump（类/方法签名速查）
├── decisions-select-video.md    选人/加载界面视频（25s 上限、进选人释放 StageVideo 槽、循环、翻页兼容）D1~D5
├── menu-layout-decisions.md      主菜单排版决策记录（左侧竖列 + 二级独立列 + 放不下时的两列网格，D1~D14；含菜单条目/跳转的唯一改动点）
├── release-branding.md           版本号改哪几处 + 制作组页署名与链接（唯一事实源，2026-11-21 建）
├── decisions-人物包整合.md       人物包按作者分组重写 fighter.xml/select.xml 的结论与待定问题（select 排版不变）
├── decisions-ai-link-chain.md   HELL/CRAZY 随机纽带连招的决策与执行记录（2026-10-12/13）
├── decisions-agents-md-slim.md  AGENTS.md 精简决策（三段骨架的来源；基线 tag snapshot/pre-agents-slim-2026-11-02-1034）
├── 未入包角色清单.md            精简包缺口：2026-11-01 基准下 352 个 / 5612 MB 未入包，附作者与体积
├── 37-extended/                  3.7 扩展版参考源码的拆解与移植参考（6 册 + 术语表，2026-11-17 建）
│   ├── 00-README.md                目标/约束/优先级 + 事实基线 + 六册导航
│   ├── 01-diff-inventory.md        3.7 独有 227 类逐类清单 + 主项目独有 39 类「别覆盖清单」+ 同名陷阱
│   ├── 02-camera.md                相机：3.7 单类 vs 主项目三件套（含不能整文件覆盖的原因）
│   ├── 03-json-map.md              特殊格式地图：MUGEN def → stage.json → 渲染器（含 v2.5 patch 差异）
│   ├── 04-selfdrawn-ui.md          自绘 UI：分层与契约（145/152 纯代码绘制，7 个类按名取 SWF 元件）
│   ├── 05-gamepad-continue.md      手柄四实现路由 + 改键 UI + 局内重开重置链
│   ├── 06-updater.md               自动更新：检查 / 分块下载 / 落盘 / 重试
│   └── glossary.md                 术语表（含四个「Continue」不是同一件事）
├── 38-rule-stage/                3.8「独立规则设置界面」专题
│   ├── rule-stage.md               实现详解 + 3.3↔3.8 规则项对照 + 移植要点
│   └── plan.md                     PC 工程新增独立规则页的实现计划（含坑）
├── gamepad/                      手柄支持专题（2026-11-19 建）
│   └── gamepad.md                  现状 / 入口路径 / 默认表与设备差异 / 虚拟手柄测试台 / 日志判据 / 待办
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
├── tag-mode/                     换人模式（TAG，模式 16/17）：每方 2 人、场上只出场 1 人
│   ├── proposal.md                 目标/成功标准/已定决策（D1~D13）/已核实的代码事实
│   ├── plan.md                     实施计划（9 个任务、换人时序、共享池、时停、验收）
│   ├── decisions-2026-10-30.md     反修决策：封输入 / 残影清理 / 先发顺序（D1~D5）
│   └── progress.md                 执行台账（改过的文件、跑过的命令、偏差与待验项）
├── clash/                        拼招机制（对拼裁决）
│   ├── plan.md                     方案：四级字典序 / 打防 / 全技能纽带 / 2P 一帧补偿
│   └── progress.md                 实现记录：改了哪些文件、验证到哪、实机验收清单
├── adr/                          架构决策记录（原 docs/adr/ 并入）
│   ├── README.md
│   └── ADR-001-单页窗口与翻页交互.md
├── plans/                        实施计划
│   ├── 2026-09-07-选人界面工具-单页窗口与翻页.md
│   ├── game-faithful-vertical-pagination_plan.md   工具垂直分页对齐游戏内（原 .trae/documents/）
│   ├── refimg-layering-fix-plan.md                 工具参考图图层修正（原 .trae/documents/）
│   ├── 2026-11-08-选人界面工具-触摸版.md            选人排版工具触摸版（手势替代鼠标）
│   ├── 2026-11-12-MuMu幽灵步与滤镜实验开关.md       MuMu 幽灵步与滤镜实验开关
│   └── select-xml-paging-fix-plan.md               select.xml 分页清洗（原 .trae/documents/）
└── archive/                      归档：过时 / 重复 / 第三方 / 日志
    ├── cleanup-2026-11-17.md                    工作区清理记录（只删可再生产物 + 回收站策略 + 结果）
    ├── _report/                                 历史真机诊断报告（ANE / 分支B / GPU 滤镜 / 资源迁移，8 个文件）
    ├── AI-SYSTEM-DOC.root-stale-2026-09-01.md   根目录旧版（已被 doc/ 内 10-09 版取代）
    ├── push-guide-2026-10-11.md                 原根目录 PUSH-操作手册（当时沙箱不能写 git，已过时）
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
| **3.7 参考里有什么值得搬 / 相机·JSON 地图·自绘 UI·手柄·自动更新怎么实现的** | [`37-extended/00-README.md`](37-extended/00-README.md) 先读导航 → 对应册；**动手前必看** [`01-diff-inventory.md`](37-extended/01-diff-inventory.md) §4.2「别覆盖清单」 |
| 竞技项（规则/行为/卍解/重复） | [`jingji/detailed-design.md`](jingji/detailed-design.md) + [`jingji/tasks/`](jingji/tasks/) |
| 开场演出 | [`kai-chang/proposal.md`](kai-chang/proposal.md) |
| **改主菜单排版 / 二级菜单摆位 / 菜单条目与跳转** | [`menu-layout-decisions.md`](menu-layout-decisions.md)（D1~D14，含被否决方案）。**改动点只有两处**：条目与二级子项 = `GameInterfaceManager.getGameMenu()`；label→页面 = `MenuBtnGroup.getFucByLabel()`。旧 PC 菜单（`GameInterface.getDefaultMenu()` 静态表）已废弃 |
| **选人/加载界面视频（黑底、不循环、第二次没画面）** | [decisions-select-video.md](decisions-select-video.md)（D1~D5：25s 上限、进选人释放视频槽、循环、翻页兼容兜底） |
| **换人模式（TAG）：辅助键换人 / 共享血池 / 空中时停换人** | [`tag-mode/proposal.md`](tag-mode/proposal.md) → [`tag-mode/plan.md`](tag-mode/plan.md) → [`tag-mode/progress.md`](tag-mode/progress.md) |
| **拼招（对拼裁决）：重击>击倒>面长>后出 / 同时出弹开 / 赢家全技能纽带 / 输家吃打防** | [`clash/plan.md`](clash/plan.md)（方案：16 条难点、改动清单、2P 探针）→ [`clash/progress.md`](clash/progress.md)（实现记录，2026-11-27，待实机验收） |
| 选人界面翻页 / 单页窗口决策 | [`adr/ADR-001-单页窗口与翻页交互.md`](adr/ADR-001-单页窗口与翻页交互.md)、[`plans/2026-09-07-选人界面工具-单页窗口与翻页.md`](plans/2026-09-07-选人界面工具-单页窗口与翻页.md) |
| **外部包挂滤镜没效果 / 时停变黑白屏 / 角色凭空消失** | [`gpu-filter-proxy.md`](gpu-filter-proxy.md)：§2 实测事实、§3 架构、§5 参数、§6 踩坑、**附录 A 改动履历**、**附录 B 12 条错误经验** |
| 哪个角色还没进精简包 / 包体怎么凑 | [`未入包角色清单.md`](未入包角色清单.md)（2026-11-01 基准：352 个 / 5612 MB 未入包，含作者与体积） |
| 人物包整合（按作者分组重写 fighter.xml/select.xml） | [`decisions-人物包整合.md`](decisions-人物包整合.md) |
| HELL/CRAZY 随机纽带连招 | [`decisions-ai-link-chain.md`](decisions-ai-link-chain.md) + `CLAUDE.md`「随机纽带连招约定」 |
| AGENTS.md 为什么这么瘦 / 三段骨架怎么来的 | [`decisions-agents-md-slim.md`](decisions-agents-md-slim.md) |
| 类/方法签名速查 | [`_api_doc.txt`](_api_doc.txt) |
| 走查工程结构 / 模块清单 | [`architecture.md`](architecture.md) |
| 改移动端 UI / 触控 / 手柄 / 选人 / Debugger / 打 APK | [`runtime-pitfalls.md`](runtime-pitfalls.md)（无法解释的点不动 / 旧图不刷新 / 按钮消失 / 日志抓不到，先看它） |
| 受击僵直 / 灵爆金身 / 替身术 / 开局黑屏 / `创建游戏失败` | [`runtime-pitfalls.md`](runtime-pitfalls.md) **§7**（三计数器自锁、人物包脏帧脚本、转场回调重试 + 验收断言） |
| 改选人界面 / 查已有回归用例 | [`select-regression-matrix.md`](select-regression-matrix.md)（改 `SelectFighterItem/SelectFighterStage/SelectStageConfigVO/MenuBtn` 时同步刷行号） |
| **查"这批改了什么" / 补开发记录** | [`runtime-pitfalls.md`](runtime-pitfalls.md) **§9 开发日志**（按日期倒序，只记结论 + 指向） |
| 选人界面排版工具的形成过程 | [`plans/`](plans/)（4 份计划）+ `选人界面排版工具/` 自带文档 |

## 3. 相关但不在 `doc/` 下的文档

| 路径 | 用途 |
|---|---|
| [`BVNscripts/3.8竞技参考/3.8.8.6新版/CLAUDE.md`](../BVNscripts/3.8竞技参考/3.8.8.6新版/CLAUDE.md) | 3.8 竞技版参考代码索引（**只读参考，不改造**；唯一源码树 `src/` + 原版 `launch.swf`） |
| [`doc/archive/_report/`](archive/_report/) | 历史真机诊断报告（ANE / 分支B / GPU 滤镜 / 资源迁移）；原 `tools/Test/_report/` 已于 2026-11-17 清理 |
| [`docs/`](../docs/) | **用户向**文档（README + 01 安装发布 / 02 外置资源与配置 / 03 人物子框 / 04 常见问题 / 05 发行说明）；与 `doc/` 分开维护，不互相搬 |
| [`tools/skills-1.2.3/`](../tools/skills-1.2.3/) | 第三方技能包（mattpocock/skills v1.2.3，原样留存，**非本项目文档**） |
| `选人界面排版工具/` | 独立 HTML 工具，自带 README/plan/xml解析流程/代码索引（**工具文档，不并入 doc/**） |
| `.backup/` | 本地改动前快照（**不进提交**，见 `CLAUDE.md` 与 `.gitignore`） |

## 4. 维护约定

1. **开发向文档一律放 `doc/` 下**，按主题建子目录；**用户向文档放根目录 `docs/`**（2026-11-18 用户拍板：README + 01 安装发布 / 02 外置资源与配置 / 03 人物子框 / 04 常见问题 / 05 发行说明），两边不互相搬。
2. 新增/移动文档后，**同步更新本文件的目录树与快速定位表**，并在 `CLAUDE.md` 的「文档地图」里登记（如果新增了顶层分类）。
3. **过期但仍有参考价值的文档移入 `doc/archive/`**，不要直接删除；在本文件里标注被谁取代。
4. 构建日志（`build_output.txt`、`mob_*.log`）属**临时产物**，不进提交；需要留档时放 `doc/archive/logs/`。
5. 第三方/工具类资料（技能包、SDK 说明）**不要混进 `doc/`**，放 `tools/`。
6. **常驻注入的规则细则统一放 [`agent-rules.md`](agent-rules.md)**；`AGENTS.md` 只留红线与指针，超 70 行即下沉。

### 4.1 约定例外：mattpocock/skills 工作流的产物路径

`.agents/skills/`、`.claude/skills/` 下的 [mattpocock/skills](https://github.com/mattpocock/skills) 类技能（`grill-with-docs`、`domain-modeling` 等）按**上游约定**写入：

- 仓库根 `CONTEXT.md`（领域术语表）
- `docs/adr/`、`docs/grill-with-docs/{plans,decisions,reviews}/`

**这不是本项目文档，也不要试图收拢进 `doc/`**：这些技能会从上游覆盖，路径改不动；一旦使用就会重新生成上述路径。

> 现状（2026-10-11 归档时）：已有产物已收拢 —— `docs/adr/` 的 ADR 与 README 归入 [`doc/adr/`](adr/)、计划归入 [`doc/plans/`](plans/)、根目录 `CONTEXT.md` 归入 [`doc/archive/`](archive/CONTEXT.md)。
> 若再次运行这些技能，`docs/`（小写复数）可能重新出现 —— **属预期，不必再合并**；只把其中有长期价值的 ADR/计划按上表搬进 `doc/` 即可。
