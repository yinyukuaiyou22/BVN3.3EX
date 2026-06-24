# AGENTS.md

本文件为 AI 开发助手（Claude Code / DeepSeek）提供项目专属的开发上下文和行为准则。每次开发会话开始时，AI 应首先阅读本文件与 [CLAUDE.md](CLAUDE.md)。

## 模型配置

本项目采用「高-低搭配」模型策略，主力模型处理核心逻辑，轻量模型完成大量重复性工作：

```json
{
  "ANTHROPIC_SMALL_FAST_MODEL": "deepseek-v4-flash",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash"
}
```

| 角色 | 模型              | 用途                           |
| ---- | ----------------- | ------------------------------ |
| 主力 | DeepSeek V4 Pro   | 核心逻辑、架构设计、Bug 排查   |
| 轻量 | deepseek-v4-flash | 批量搜索、简单修改、子任务分发 |

> **注意**：Claude Opus 4.8 暂不使用，路由系统仅在两档之间切换（Pro ↔ Flash）。

### 模型主动路由

使用 `tools/route_model.py` 分析任务复杂度，自动推荐最佳模型：

```bash
# 获取推荐（文本输出）
python tools/route_model.py "修复 4 个文件中的 INFINITE_ENERGY bug"

# JSON 输出（供程序解析）
python tools/route_model.py "你的任务描述" --json

# 指定涉及文件数
python tools/route_model.py "重构 AI 系统" --files=6 --json
```

**路由策略**：详见 [.claude/skills/route-model.md](.claude/skills/route-model.md)

可临时切换：简单任务直接用 Flash，不必一直用 Pro。

## Vibe Coding 工作流（`/vibe-coding-workflow`）

复杂功能（≥3 个文件修改、涉及新模块、或架构变更）应使用 `/vibe-coding-workflow` 技能，按以下阶段推进：

```
需求澄清 → 高层设计 → 详细设计 → 任务拆分 → 多 Agent 实现 → 测试验收
```

### 使用时机

| 场景 | 是否使用 |
|------|----------|
| 单文件小修（typo/常量/注释） | 直接修改 |
| 已有明确方案、2 文件内改动 | 直接修改 |
| 新功能 / 新模块 / 跨层修改 | 必用 |
| ANE / 构建脚本 / 打包流程变更 | 必用 |
| 重构 / 多文件联动 / API 接口变更 | 必用 |
| 用户明确说 "vibe coding" | 必用 |

### 工作流规则

1. **先文档后代码**：实现前必须有 `doc/<feature>/proposal.md`（目标/成功标准/待决问题）
2. **设计产出供下一阶段消费**：`high-level-design.md` → `detailed-design.md` → `tasks/*.md` → `progress.md`
3. **小任务独立审查**：每个任务 ≤ 3 个文件，完成后 `git diff` 审查 + 编译验证
4. **不确定时暂停询问**：需求/数据契约/破坏性操作/外部依赖不明确时，先问用户
5. **progress.md 是唯一真相来源**：任务状态、阻塞项、已运行命令全部记录
6. **AI 输出视为草稿**：直到通过 `./build.bat` 编译 + diff 审查才算完成

### 规划文档结构

```
doc/<feature>/
  proposal.md            # 目标、非目标、需求、成功标准、待决问题
  high-level-design.md   # 架构、模块边界、数据流、设计决策、风险
  detailed-design.md     # 文件结构、接口契约、算法、错误处理、测试计划
  tasks/
    progress.md          # checklist 任务状态、阻塞项、已运行命令
```

> **示例**：ANE 子系统的完整规划文档见 `doc/ane/`

### 与 Claude Code 工具链的配合

- **Phase 1-4（规划）**：主 Agent 独立完成，Codegraph `explore`/`callers` 辅助调研
- **Phase 5-6（实现）**：主 Agent 协调，简单任务委派给 `deepseek-v4-flash` 子 Agent
- **Phase 7（验证）**：`./build.bat` 编译 + `/verify` 冒烟测试 + `/code-review` diff 审查

## 开发环境

| 工具                         | 用途                                         |
| ---------------------------- | -------------------------------------------- |
| VSCode                       | 代码编辑                                     |
| Claude Code                  | AI 辅助开发                                  |
| `build.bat`                  | PC 编译 SWF（`Ctrl+Shift+B` 或直接运行）     |
| `tools/script/debug.bat`     | PC 端编译 + adl 启动调试                     |
| `tools/script/debug_mob.bat` | 手机端打包 APK + ADB 安装 + fdb 调试         |
| `tools/script/fdbg.bat`      | 通用 SWF fdb 断点调试                        |
| Java 17                      | mxmlc 编译器运行时                           |
| Flex + AIR SDK               | `AIRSDK/flex4.16.1-air51.0.1.1/`（合并包）  |

## 关键规则

1. **响应语言**：所有回答必须使用中文呈现，仅代码标识符、文件路径、技术术语（如 API/ANE/SDK 等缩写）可保留英文。禁止整段英文输出
2. **代码基准**：`BVNscripts/scripts/` 为可编译源码
3. **编译验证**：每次修改后运行 `./build.bat`，确认零错误
4. **不要动**：`_assets/` 目录中的 `.bin`/`.png`/`.mp3` 文件、`mx/core/` 框架桩
5. **嵌入式资源**：统一通过 `EmbeddedAssets.as` 的 `[Embed]` 管理
6. **UI SWF**：从 `assets/swf/` 运行时加载，由 `ResUtils.as` 处理
7. **不要提交**：`*.swf`、`assets/`、`OLD/`、`last/`、`Outscripts/`、`reference/BVN3.9/`、`AIRSDK/`、`tools/Test/`
8. **文件删除必须确认**：删除任何文件（包括 `rm`/`rm -rf`/`Move-Item`/`del`）必须有用户明确指令，或在过程中询问确认后执行。严禁自行判断删除。违反此规则是最高优先级错误。
9. **删除前必须备份**：执行删除操作前，必须先将目标文件/目录复制到 `.backup/` 或用户指定位置。备份完成后再执行删除。
10. **三次修改累积保护**：同一文件或目录经过 3 次及以上修改操作后，不得直接彻底删除。必须先回退到修改前状态（`git checkout`），经用户确认后再决定是否删除。
12. **精确指定上下文**：避免"分析整个项目"，改为指定文件/模块。先列出相关文件再逐步处理，而非一次性加载全部
13. **分步执行**：大型任务拆分为多个小步骤，每次修改后手动审核，减少反复重跑整个项目
14. **利用会话缓存**：相关修改在同一会话中完成，避免频繁开新会话重复加载
15. **批量修改联动排查**：当单次修改涉及 >=4 个代码文件（`.as` 源码）时，必须执行以下流程：
    - 梳理所有关联文件（通过 Grep 搜索被修改类名/方法名/常量的引用位置）
    - 检查是否有遗漏的联动修改点（如接口实现、事件监听、import 引用）
    - 同步更新 [CLAUDE.md](CLAUDE.md) 中受影响模块的文档描述

## Token 优化策略

大项目消耗 token 多，以下策略可降低 **40%–70%** 的 token 消耗：

### 1. 精确指定上下文

- [正确] "优化 `fighter/ctrler/FighterMcCtrler.as` 中的 INFINITE_ENERGY 处理"
- [错误] "看看整个项目哪里写得不好"
- 先 `Grep` 定位相关文件，再逐文件处理

### 2. CLAUDE.md 提供「地图」而非细节

CLAUDE.md 写入架构概览和关键文件位置即可，**不要粘贴大量代码**。AI 读取它作为全局指引，避免每次扫描整个项目。

### 3. 排除无关文件

通过项目根目录的 `.claudeignore`（语法同 `.gitignore`）排除无用文件，避免送入 token 消耗：

```
*.swf
*.png
*.mp3
*.bin
_assets/
assets/swf/
AIRSDK/
last/
OLD/
reference/BVN3.9/
reference/MTDataFilesProvider/
Outscripts/
node_modules/
dist/
```

### 4. 分步执行大任务

1. 先让 AI 找出需要修改的文件列表
2. 逐个文件提出修改请求
3. 每次修改后编译验证，减少反复

### 5. 调整推理强度

简单任务降低推理强度以减少 token 消耗：

```
CLAUDE_CODE_EFFORT_LEVEL=medium   # 或 low（简单任务）
```

### 6. 善用 MCP 或外部工具预处理

通过外部脚本（如 `sync.py`、静态分析工具）获取摘要信息，让 AI 处理摘要而非直接阅读全部代码。

### 7. 利用会话记忆

在同一会话中处理所有相关修改，Claude Code 会缓存部分上下文，显著降低每次重新加载项目的 token 开销。

## Headroom 上下文压缩

本项目已集成 [Headroom](https://github.com/chopratejas/headroom) v0.24.0，自动压缩工具输出/日志/搜索结果，降低 **60-95%** token 消耗后送达 LLM。

### 启动方式

```bash
# 方式 1：代理模式（推荐，零代码改动）
# 终端 1：启动代理
headroom proxy --port 8787

# 终端 2：通过代理启动 Claude Code
$env:ANTHROPIC_BASE_URL = "http://localhost:8787"
claude

# 方式 2：直接包装（一键启动）
headroom wrap claude

# 方式 3：查看压缩统计
curl http://localhost:8787/stats
```

### 压缩效果

| 内容类型                   | 压缩器                           | 预计节省 |
| -------------------------- | -------------------------------- | -------- |
| Grep 搜索结果（大量 JSON） | SmartCrusher                     | 70-90%   |
| ActionScript 源码          | CodeCompressor (tree-sitter AST) | 40-70%   |
| 构建日志                   | LogCompressor                    | 80-95%   |
| 工具输出                   | SearchCompressor                 | 60-80%   |
| 纯文本                     | Kompress (ModernBERT)            | 30-50%   |

### 文件排除

`.claudeignore` 已排除：`*.swf` / `*.png` / `*.mp3` / `*.bin` / `_assets/` / `AIRSDK/` / `last/` / `OLD/` / `Outscripts/`。

### 常用命令

| 命令                               | 用途                                     |
| ---------------------------------- | ---------------------------------------- |
| `headroom proxy --port 8787`       | 启动本地压缩代理                         |
| `headroom wrap claude`             | 直接包装 Claude Code                     |
| `headroom perf`                    | 查看压缩统计和性能                       |
| `headroom learn`                   | 从失败会话学习，写入 CLAUDE.md/AGENTS.md |
| `curl http://localhost:8787/stats` | 查看实时压缩统计                         |

---

## 编译命令

```bash
# PC 编译（项目根目录）
./build.bat

# PC 调试（编译 + 启动）
tools/script/debug.bat

# 手机真机调试（打包 + 安装 + fdb）
tools/script/debug_mob.bat

# 通用 fdb 调试
tools/script/fdbg.bat [swf_file]
```

## 反编译代码特征

- **参数名**：`param1`、`param2`…（无意义，保持与同文件一致）
- **局部变量**：`_loc1_`、`_loc2_`…（同上）
- **内联匿名函数**：大量 `function():void { ... }` 回调模式
- **单例访问**：`ClassName.I` 静态 getter
- **拼写错误**：`NORNAL`（NORMAL）、`destory`（destroy）、`Mession`（Mission）— 保持原样

## ANE 开发规范

ANE（BVNFileReader）是本项目最敏感的子系统——涉及 Java → AS3 → AIR 三层跨语言调用 + 原生文件系统访问 + APK 打包管线。**当前 ANE 已禁用（`ANE_ENABLED = false`），源文件保留备用。** 重新启用需同时打开三开关。任何 ANE 相关修改必须严格遵守以下规范。

### 三开关机制（缺一不可）

ANE 启用需要三个独立开关同时生效，任一缺失将**静默降级**为 AIR File API（不崩溃但功能受限）：

| 开关 | 文件 | 设置 | 验证方式 |
|------|------|------|----------|
| 1 | `ANEFileReader.as` | `ANE_ENABLED = true` | logcat: `ANE init: OK` |
| 2 | `application.xml` | `<extensionID>com.bvn.filereader</extensionID>` 取消注释 | ADT 打包时含 `-extdir "."` |
| 3 | `debug_mob.bat` | ADT 命令含 `-extdir "."` | 打包成功且 ANE 被引用 |

> ⚠️ **修改任一开关后必须真机验证，不可仅 PC 编译。** PC 端无 ANE 运行时，ExtensionContext 创建永远失败（降级模式），无法暴露问题。

### ANE 修改规则

1. **改 Java → 重走完整构建链**：`build_ane.bat` (Java→JAR→SWC→ANE) → `debug_mob.bat` (打包→安装→验证)
2. **改 AS3 封装层 (`ANEFileReader.as`) → 至少真机验证一次**：PC 编译通过不代表手机端正常
3. **改 `EXTERNAL_BASE` 路径 → 必须同步更新**：
   - `ANEFileReader.as:56` 常量定义
   - `GameLoader.as:167` `resolveExternalPath()` 调用
   - `CLAUDE.md` ANE 启用三开关表
   - `doc/ane/high-level-design.md` 架构图
4. **新增 FREFunction → 同步修改**：
   - Java: `BVNFileReaderExtensionContext.getFunctions()` 注册
   - AS3 库: `BVNFileReaderLib.as` 新增对应方法
   - AS3 封装: `ANEFileReader.as` 新增 + 降级方法
   - 文档: `doc/ane/detailed-design.md` 更新 API 列表
5. **改 `build_ane.bat` → 遵守 bat 脚本强制规范**（见 CLAUDE.md bat 规范表）
6. **ANE 调试必须通过 logcat**：`Debugger.log()` + `trace()` 双输出（`debug_mob.bat` 自动启动 `adb logcat`）

### ANE 构建故障排查

优先级排查清单（从 CLAUDE.md）：

| 优先级 | 排查项 | 症状 |
|:---:|--------|------|
| 1 | `exit /b` | cmd 窗口一闪而过 |
| 2 | 调用子 bat 缺 `call` | 子 bat 退出时连带终止主脚本 |
| 3 | `()` 块内 `)` 未转义 | `-- was unexpected at this time.` |
| 4 | JDK 版本错误（须 JDK 8） | d8 不兼容 class v55+ |
| 5 | AIR SDK 版本不匹配 | 编译/打包时找不到 airglobal.swc |
| 6 | ANE 文件缺失 | 运行时 `implementation not found` |

### ANE 相关文件清单

```
# 修改 ANE 时需关注的所有文件（按修改频率排序）
BVNscripts/scripts/net/play5d/game/bvn/mob/utils/ANEFileReader.as  # 封装层（最常改）
BVNscripts/scripts/net/play5d/game/bvn/ctrl/GameLoader.as          # 外部扫描（经常改）
extensions/BVNFileReader/Android/src/com/bvn/filereader/           # Java 层（偶尔改）
extensions/BVNFileReader/as3/com/bvn/filereader/BVNFileReaderLib.as # AS3 库（偶尔改）
extensions/BVNFileReader/extension.xml                              # ANE 描述（极少改）
extensions/BVNFileReader/build_ane.bat                              # 构建脚本（极少改）
tools/Test/application.xml                                          # 应用配置（开关2）
tools/script/debug_mob.bat                                          # 打包脚本（开关3）
BVNscripts/scripts/net/play5d/game/bvn/data/GameData.as             # 启动集成
```

### 已知问题

| 问题 | 位置 | 严重性 | 状态 |
|------|------|--------|------|
| ~~`tryLoadExternalXML` 作用域 bug~~ | ~~`GameLoader.as:335`~~ | ~~🔴 高~~ | ✅ 已修复 — 添加 basePath 参数 |
| ~~外部角色无头像属性~~ | ~~`GameLoader.as:199-206` + `*Model.mergeByXML`~~ | ~~🟡 中~~ | ✅ 已修复 — 修正 3 个 Model 的 mergeByXML 去掉 skip-duplicate 守卫，外部 XML 覆盖 SWF 扫描占位条目 |
| ~~应用私有目录用户不可见~~ | ~~`ANEFileReader.as:56`~~ | ~~🟡 中~~ | ✅ 已修复 — 注释添加 adb push 命令引导 + 路径说明 |

> 完整 ANE 规划文档见 [`doc/ane/`](doc/ane/) — proposal / high-level-design / detailed-design / tasks/progress

## 常见任务指南

### 修改游戏逻辑

1. 确认涉及的类（参考 CLAUDE.md 或 Grep 定位）
2. 阅读目标文件，理解当前实现
3. 保持与现有代码风格一致
4. 编译验证 `./build.bat`

### 排查 Bug

1. 从现象反推代码路径
2. `Grep` 搜索关键方法名/常量名定位文件
3. 必要时添加 `Debugger.log()` 调试输出
4. 修复后解释根因

### Git 提交

- 仅当用户明确要求时执行
- commit message 末尾加：`Co-Authored-By: Claude <noreply@anthropic.com>`
- 不提交 `*.swf`、参考/蓝图目录

## 关键文件速查

| 需求        | 优先查看                                               |
| ----------- | ------------------------------------------------------ |
| 编译        | `build.bat`、`asconfig.json`                           |
| 调试        | `tools/script/debug.bat`、`tools/script/debug_mob.bat` |
| 入口/初始化 | `launch.as`、`MainGame.as`                             |
| 物理参数    | `GameConfig.as`                                        |
| 角色动作    | `FighterMcCtrler.as`、`FighterAction.as`               |
| AI          | `fighter/ctrler/ai/FighterAILogic.as`                  |
| 碰撞        | `GameMainLogicCtrler.as`                               |
| 菜单/按钮   | `MenuBtnGroup.as`、`MenuBtn.as`                        |
| 暂停菜单    | `PauseDialog.as`                                       |
| 设置        | `SetBtnGroup.as`、`SettingState.as`                    |
| 输入        | `GameInputer.as`、`FighterKeyCtrl.as`                  |
| 配置/存档   | `GameData.as`、`ConfigVO.as`                           |
| 嵌入式资源  | `EmbeddedAssets.as`、`mx/core/`                        |
| UI SWF      | `ResUtils.as`                                          |
| 移动端      | `mob/GameInterfaceManager.as`、`mob/screenpad/`        |
| 调试        | `Debugger.as`（`DEBUG_PANEL_ENABLED` 开关）            |
| 网络        | `mob/sockets/`、`mob/ctrls/LAN*.as`                    |
| ANE 扩展    | `mob/utils/ANEFileReader.as`、`ctrl/GameLoader.as`、`doc/ane/` |
| ANE 构建    | `extensions/BVNFileReader/build_ane.bat`、`extension.xml` |
| 资产工具    | `tools/script/add_asset.py`（自动添加角色/辅助/地图） |
| 分页/选人   | `SelectFighterStage.as`、`select.xml` |
| 游戏模式    | `GameMode.as`（含 2v2/1v2 TEAM_DUO/SINGLE_VS_DUO） |

## 分支策略

| 分支 | 用途 | 远程 |
|------|------|------|
| `master` | 完整开发版（含 P1/P2 切换等实验功能） | `mobile` (3.3BVNmobile) |
| `公开部分` | 公开稳定版 | `origin` (BVN3.3EX) |

公共 bug 修复先提交到 master，再 cherry-pick 到公开部分。
