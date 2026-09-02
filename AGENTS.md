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
11. **修改前必须手动备份**：本项目无 Git 版本控制。每次使用 `edit_file` / `create_file` 修改任何文件之前，必须先将原始文件复制到 `.backup/` 目录下（文件名加时间戳后缀，如 `.backup/Foo.as.2026-07-28-1945`），确认备份成功后再执行修改。修改后如需回退，直接从此备份恢复。
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

## 安卓端开发要点

安卓端（AIR Android 运行时）与 PC 端（AIR Desktop 运行时）行为差异显著，以下是在移动端开发中必须注意的关键事项。

### 0. 工具调用方法（正确写法，减少重试次数）

**工具参数有严格的顺序与格式要求**，乱序/缺失参数是重试的最常见原因。以下为实测有效写法：

| 工具 | 正确调用格式（参数顺序从前往后） | 易错点 |
|------|----------------------------------|--------|
| `read_file` | `path` → `environment` | `environment` 必须写 `android`；`path` 必须是 `/storage/emulated/0/BVN3.3EX-master/...` 绝对路径 |
| `find_files` | `path` → `pattern` → `environment` | 三个参数都必要；`pattern` 支持 `*.as`、`GameMode.as` 等 glob |
| `edit_file` | `path` → `environment` → `old` → `new` | 缺 `old` 或缺 `new` 都会报 `Both 'old' and 'new' are required`；`old` 必须与文件内容**逐字符精确匹配**（含缩进、Tab） |
| `copy_file` | `source` → `destination` → `environment` | 必须同时传 `source` 和 `destination`，否则报 `Missing required parameters` |
| `super_admin:terminal` | `command` → `timeoutMs` | `timeoutMs` 必须显式传（建议 ≥10000），否则前台默认 15 秒超时；禁止用 `set -e` |
| `grep_code` | `path` → `pattern` → `environment` → `case_insensitive` → `max_results` | `pattern` 是正则表达式，特殊字符需转义 |
| `read_file_part` | `path` → `environment` → `start_line` → `end_line` | 行号从 1 开始，`end_line` 可选（默认 start+99） |

**通用规则**：
1. **XML 标签必须用 `<param name="...">` 格式**，每个参数单独一行，参数名与参数值严格对应；不要使用 `<parameter>` 或属性传参，会导致参数被丢弃
2. **`path` 参数永远放在第一位**。多个工具实测：`path` 放最后会出现 `path parameter is required` 假报错
3. **绝对路径**：所有文件工具一律用 `/storage/emulated/0/BVN3.3EX-master/` 开头，禁止相对路径
4. **修改前必须备份**（规则 11）：若 `copy_file` 连续报参数错误，改用 `super_admin:terminal` 执行 `cp` 命令备份，命令格式：
   ```bash
   cd /storage/emulated/0/BVN3.3EX-master && cp <目标文件> .backup/<文件名>.$(date +%Y-%m-%d-%H%M)
   ```
5. **编译验证必须后台执行**：手机端 mxmlc 编译需 30-60 秒，前台终端 15 秒必超时。正确做法：
   ```bash
   cd /storage/emulated/0/BVN3.3EX-master && nohup java -jar flex4.16.1-air51.0.1.1/lib/mxmlc.jar \
     +flexlib=flex4.16.1-air51.0.1.1/frameworks -debug=true -swf-version=37 -strict=false \
     -source-path+=BVNscripts/scripts \
     -library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/core.swc \
     -external-library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/air/airglobal.swc \
     -output=tools/Test/launch.swf -- BVNscripts/scripts/launch.as \
     > /sdcard/build_log.txt 2>&1 &
   ```
   然后分轮 `sleep 20 && tail -30 /sdcard/build_log.txt` 轮询，见 `launch.swf (xxx bytes)` 即编译成功
6. **编译前检查资源一致性**：若 `EmbeddedAssets.as` 引用的 `_assets/*.png` 在手机端不存在（只有同名 `.jpg`），编译必失败。先 `ls BVNscripts/scripts/_assets/` 核对，缺则用 `cp` 补同名文件（不要修改 `EmbeddedAssets.as` 源码）
7. **一次只传一项任务**：不要在同一轮内混用多个工具包（`extended_file_tools:copy_file` 与 `super_admin:terminal` 交替时，先确保前一个工具返回成功再调用下一个）

### 1. 编译参数（缺一不可）

移动端编译必须携带以下两个参数，否则编译不通过或 SWF 不产出：

```bash
java -jar flex4.16.1-air51.0.1.1/lib/mxmlc.jar \
  +flexlib=flex4.16.1-air51.0.1.1/frameworks \
  -debug=true -swf-version=37 -strict=false \
  -source-path+=BVNscripts/scripts \
  -library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/core.swc \
  -external-library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/air/airglobal.swc \
  -output=tools/Test/launch.swf -- BVNscripts/scripts/launch.as
```

| 参数 | 必要性 | 缺失后果 |
|------|:---:|------|
| `-strict=false` | **必须** | 预存反编译类型不匹配错误（ScreenRotater、GameInputer、JsonUtils、ANEFileReader 等）阻止 SWF 产出；mxmlc 仍返回 exitCode=0 但无产物 |
| `-external-library-path+=airglobal.swc` | **必须** | ANEFileReader、FileUtils 等 AIR 库类报 `Type was not found`，编译失败 |

### 2. GPU 渲染模式下的纹理刷新陷阱

AIR Android 使用 GPU 渲染模式，`Bitmap.bitmapData` 属性直接赋值**不保证立即刷新 GPU 纹理缓存**。这是手机端最常见的 UI 显示不同步根因。

**错误做法**（看起来正确但实际不刷新）：
```actionscript
// 只替换 bitmapData —— GPU 纹理缓存不会刷新，显示仍为旧图
display.bitmapData = new BitmapData(...);
display.width = w;
display.height = h;
```

**正确做法**：直接创建全新 `Bitmap` 对象替换整个 `display` 属性：
```actionscript
// 创建全新 Bitmap 对象替换 display —— GPU 将重新上传纹理
var newBmp:Bitmap = new NewAssetClass();
newBmp.scaleX = ScreenPadUtils.scale;
newBmp.scaleY = ScreenPadUtils.scale;
newBmp.alpha = display.alpha;
newBmp.x = display.x;
newBmp.y = display.y;
container.display = newBmp;  // 替换整个对象
```

> **案例**：`ScreenPadGame._switchPlayer()` 中 P1/P2 切换按钮图片始终显示 p1 图标，根因就是替换 `bitmapData` 后纹理缓存未刷新。修复方案：直接替换 `_playerSwitchBtn.display`（`ScreenPadBtn.display` 是 `Bitmap` 类型）为全新 Bitmap 对象。

### 3. Sprite 尺寸清零陷阱（手机端按钮"消失"的根因）

`Sprite.graphics.clear()` 执行后，`width`/`height` 属性变为 **0**。如果在重绘时依赖这两个动态属性，将画出 0×0 的空矩形，按钮不可见。

**错误做法**：
```actionscript
btn.graphics.clear();                          // width/height → 0
btn.graphics.drawRect(0, 0, btn.width, btn.height);  // 画 0×0 空矩形！
```

**正确做法**：用静态常量存储按钮尺寸，重绘时用常量：
```actionscript
private static var _closeBtnSize:int = 0;  // initDebug 中初始化为 int(14 * _scale)

// toggle 重绘时用常量而非动态属性
btn.graphics.clear();
btn.graphics.beginFill(color);
btn.graphics.drawRect(0, 0, _closeBtnSize, _closeBtnSize);  // 正确
btn.graphics.endFill();
```

> **案例**：Debugger 面板的绿色/红色折叠/展开方块按钮，点击后因 `_toggleLogBody` 中 `clear()` 后尺寸归零，`drawRect(0,0,btn.width,btn.height)` 画出空矩形，按钮"消失"。PERF 面板的 `_togglePerfBody` 更是完全没有按钮重绘逻辑。修复：引入 `_closeBtnSize` 静态常量，两个 toggle 函数都用它重绘（展开=绿色 `0x00AA00`，收起=红色 `0xCC0000`）。

### 4. 调试面板（Debugger）移动端注意事项

`Debugger.as` 是运行时调试面板，在手机端有以下特殊问题：

| 问题 | 根因 | 修复 |
|------|------|------|
| 面板重复创建 | `launch.as` 第 63 行和第 239 行各调用一次 `initDebug()` | `_inited` 静态守卫变量，开头即 return |
| 折叠后无法展开 | 绿色小方块按钮极小（`14 * _scale` px），仅响应 `MouseEvent.CLICK` | 正常——手机触摸也触发 CLICK，需确保按钮重绘正确（见上条） |
| 按钮点击后消失 | `graphics.clear()` 后 `width/height=0`，重绘 0×0 空矩形 | 用 `_closeBtnSize` 常量（见「Sprite 尺寸清零陷阱」） |
| PERF toggle 无重绘 | `_togglePerfBody` 未写按钮重绘逻辑 | 补全重绘（展开绿色，收起红色） |

**交互原则**：仅使用原始绿色方块按钮触发折叠/展开，**不要在标题栏整条上添加点击监听**（会与按钮监听冲突，且不符合原版设计）。

**开启方式**：
- `launch.as` 中设 `DEBUG_PANEL_ENABLED:Boolean = true`
- 游戏内按 `P→L→A→Y` 序列键（Konami 式密技）也可触发

### 5. 手柄路由（单手柄模型，2026-08-15 重构）

**核心模型**：手机端只连一个手柄（Xbox 布局），手柄输入**固定走 "P1" 通道**（`joy_p1` 恒启用、`joy_p2` 恒禁用）。控制哪个角色由 `GameCtrl.switchControlPlayer()` 依据 **joyTarget** 决定（通过交换 FighterKeyCtrl.inputType 实现）。

- `refreshJoystickRouting()`：观战 → joy_p1/joy_p2 双禁用；**其余（vs CPU/闯关/对战）→ `joy_p1.enabled=true`、`joy_p2.enabled=false`**
- `switchControlPlayer(controlP1)`：按 `GameInterfaceManager.config.joyTarget` 决定实际控制方：
  - `joyTarget=0`（跟随切换）→ 用 `controlP1`（当前控制角色读 "P1" 通道）
  - `joyTarget=1`（固定 P1）→ 永远控制 P1（P1←"P1"、P2←"P2"）
  - `joyTarget=2`（固定 P2）→ 永远控制 P2（P1←"P2"、P2←"P1"）
- vs CPU/闯关：P2 是 AI，`_switchPlayer` 直接 return，手柄自然只控制 P1

**调用链**：`ScreenPadGame._switchPlayer()` → `GameCtrl.switchControlPlayer()` → `GameInterfaceManager.refreshJoystickRouting()`

**joyTarget 设置入口**：`SetBtnGroup.as`（设置菜单「手柄控制权」：跟随切换/P1/P2，optoinKey=`joyTarget`）

**历史 Bug**：旧版 `refreshJoystickRouting` 按 controllingP1 切换 joy_p1/joy_p2 启用，与 `switchControlPlayer` 交换 inputType 的模型冲突 → 切换后手柄控制对面角色；现统一为单手柄模型后消除。

### 5.5 多手柄配置与批次 4/5 操作规范（2026-08）

**批次背景**：原始 `joy_p1`/`joy_p2` 共享 `joy1Config`，P2 改键覆盖 P1、设备号重连失效。批次 1-5 重构为「单手柄模型 + P2 独立配置 `joy2Config` + 双手柄时 P2 独立改键 UI」。**核心链路见 CLAUDE.md「多手柄配置重构」专节。**

**涉及文件与职责**：
| 文件 | 职责 |
|------|------|
| `ViewManager.as` | `goP1JoyStickSet()`/`goP2JoyStickSet()` → `goJoyStickSet(playerNum, joyConfigVO)`；`isMultiplePads()`/`refreshMultiPadCache()`/`_multiPadCache` 双手柄检测 |
| `GameInterfaceManager.as` | `getSettingMenu()` 加 P2 条件入口（`isMultiplePads() ? {...} : null`）；`updateInputConfig` 绑定 `joy_p2.setConfig(joy2Config)` |
| `SelectFighterStage.as` | `build()` 末尾调 `ViewManager.I.refreshMultiPadCache()`（选人时检测一次双手柄） |
| `ExtendConfig.as` | `joy2Config` 字段 + `toSaveObj/readSaveObj/setDefaultDevice(joy2Config,1)` 独立存档 |
| `GameJoystickInput.as` | `_prevKeys` 设备级隔离、`_joyLog` 设备感知、`anyKey` 接 `_checkEdge` |

**操作规范（维护时务必遵守）**：
1. **P2 APPLY 不调 `updateJoyConfig`**：只 `readObj` 直存，与 P1 解耦。改 P2 存档逻辑时勿让 P2 覆盖 P1 设备号。
2. **双手柄检测只在选人时做一次**（`SelectFighterStage.build()`），不订阅设备热插拔事件。若将来要支持游戏中途热插拔，需在 `refreshMultiPadCache` 加事件订阅——**这是当前唯一留白**。
3. **单手柄时 P2 入口完全隐藏**（不灰显）：用 `isMultiplePads() ? {...} : null` 三元运算符，`null` 元素被设置菜单渲染层过滤，不会显示空白项。
4. **保留历史拼写错误**：`getAllDeivces`（Deivces）、`wankai/waikai`——不要"修正"，与既有反编译代码风格一致。
5. **改键 UI 已参数化多玩家**：`JoyStickSetUI.setConfig(playerNum, configVO)`、`IInnerSetUI` 接口——新增入口时复用此模式，勿新增重复实现。
6. **编译产物 SWF 字节数变化应控制在 ±1KB 内**：若单批次改动导致 SWF 变化过大，检查是否误嵌入资源（见 `EmbeddedAssets.as`）。
7. **日志分流**：手柄日志统一带 `P{n}` 前缀（`JOY:P1`/`JOY:P2`）+ `dev=` 设备号，用于多手柄真机定位（批次 5 已实现 `_joyLog` 设备感知）。

**批次 6.7 治本修复备份清单**（黑屏选人界面 face 资源加载失败根因 — BitmapAssetLoader 不派发 Event → SelectFighterItem 加 ENTER_FRAME 监听 + _refreshFace 私有方法）：
| 文件 | 备份记录 |
|------|----------|
| `SelectFighterItem.as` | `.backup/SelectFighterItem.as.batch67fix.$TS`（治标态：face MISS else + TextField fallback + ENTER_FRAME 监听 + _refreshFace）→ `.backup/SelectFighterItem.as.batch67fix.$TS.predestory`（destory 注入前）→ `.backup/SelectFighterItem.as.batch67fix.$TS.zhiben_ok`（治本终态：destory 也清理 ENTER_FRAME = 28 行总量） |
| `SelectFighterStage.as` | `.backup/SelectFighterStage.as.batch67fix.$TS`（治标：buildList 行 280-282 `_itemObj.length` 统计） |
| `tools/Test/launch.swf` | `.backup/launch.swf.6.7zhiben.$TS`（治本编译产物 34608882B / 0 error 1 warning，+208B vs 治标 34608674B） |
| `SelectStageConfigVO.as` | `.backup/SelectStageConfigVO.as.bugfix.2026-08-26-1854`（批次 6.6 BUG FIX：行 88 `.toString()` → `.text()`） |

### 6. P1/P2 切换按钮（ScreenPadGame._switchPlayer）

切换按钮是 `ScreenPadBtn.display` 属性（类型为 `Bitmap`）承载的图片。切换流程：

1. 用户点击 `_playerSwitchBtn`（`ScreenPadBtn` 类型）
2. `_switchPlayer()` 调用 `GameCtrl.I.switchControlPlayer(!_controllingP1)`
3. 替换按钮图片：根据新状态 `_controllingP1` 选择 `ScreenPadAsset.p1` 或 `ScreenPadAsset.p2`
4. **必须**创建全新 `Bitmap` 对象（不能仅替换 `bitmapData`，原因见 GPU 纹理刷新陷阱）
5. 设置 `newBmp.scaleX/Y = ScreenPadUtils.scale`，复制 `alpha`、`x`、`y` 位置
6. 调用 `_playerSwitchBtn.initArea()` 刷新触摸热区

**资源类**：`ScreenPadAsset.p1`（`EmbeddedAssets.p1_png`，1067B）、`ScreenPadAsset.p2`（`EmbeddedAssets.p2_png`，2552B）

### 7. 调试输出（文件日志系统，2026-08-15 启用）

移动端 AIR trace 默认**不输出到 logcat**（需 fdb 连接，logcat 抓不到游戏日志）。项目已内置**文件日志系统**：`launch.as` 无条件调用 `Debugger.initFileLog(stage)`（不依赖 `DEBUG_PANEL_ENABLED` 面板开关），所有 `Debugger.log()` 自动缓冲落盘（每 5 帧刷盘）。

**日志文件路径**（AIR 应用私有目录）：
```
/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log
```
> 注意：路径为 `/data/user/0/<包名>/<applicationID>/Local Store/`（applicationID = application.xml 的 `<id>`，如 `com.bvn.yy798`），不是纯包名目录。

**读取方式（root / shizuku / run-as）**：
```bash
run-as air.com.bvn.yy798 cat '/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log'
```

**日志类型**（排查手柄/输入问题）：
| 前缀 | 含义 |
|------|------|
| `JOY_IN: DOWN/UP device=... control=N value=...` | 手柄 control 边沿（设备侧实际输入，`JoySticker.pollInputLog()` 每帧轮询） |
| `INPUT: P1.attack = true` | GameInputer 查询按下边沿（**哪个通道收到输入**，`GameInputer.call()` 内置） |
| `JOY_ROUTE: singlePad joy_p1=true joy_p2=false` | 手柄路由状态（`refreshJoystickRouting()`） |
| `JOY:P1 up dev=xxx [1:AXIS=0.5]` | `GameJoystickInput._joyLog()` 按键实时扫描（**设备切换感知**，批次 5 起按 `config.deviceId` 匹配设备，P1/P2 用不同设备时各自指向正确设备） |
| `JOY:P1 EDGE DOWN/UP key=attack dev=xxx ctrl=15,` | `GameJoystickInput._checkEdge()` 边沿（批次 5 起带 `ctrl=` 组合；`key=any` 表示任意键边沿，来自 `anyKey()`） |
| `goJoyStickSet: enter player=2 deviceId=yyy` | `ViewManager.goJoyStickSet()` 进入改键页（批次 4/5，标注玩家号+设备号，排查 P1/P2 改键分流） |
| `refreshMultiPadCache: devices=N multiPad=true` | `ViewManager.refreshMultiPadCache()` 双手柄检测（批次 4，选人时执行一次） |
| `connected / button:N:ID` | 设备连接 + control 布局（核对键位 index） |
| `initFileLog: <路径>` | 日志文件路径确认（首行） |

**写入方式**：`Debugger.log("msg")` → `trace()` + 文件缓冲。`GameInputer.call()` 内置按下边沿日志（`INPUT:` 前缀）。`JoySticker.pollInputLog()` 每帧轮询手柄变化（`JOY_IN:` 前缀）。

### 8. ANE 子系统

当前 **ANE 已禁用**（`ANE_ENABLED = false`），源文件保留备用。重新启用需打开三开关：`ANEFileReader.as:ANE_ENABLED` + `application.xml:extensionID` + `debug_mob.bat:-extdir`。详见 CLAUDE.md ANE 开发规范。

### 8.5 人物子框扩展（plugin sub-frame，批次 6.8 方案 B，2026-09-01）

> 选人界面角色挂载"子框"（plugin 角色）功能。完整方案对比/数据契约/已知问题见 **CLAUDE.md「人物子框扩展」专节**。本节为操作速查。

**快速结论**：
- 当前主源码 = **方案 B（badge + TweenLite 动画）**，参考实现 `BVNscripts/人物子框3.3/`（基于旧基线，不可整体覆盖，本次为选择性移植）
- 方案 A（showPluginSub 静态小方块，批次 6.2-6.5）**已移除**——批次 6.12 回退时 Stage 触发逻辑已丢失，本次从 SelectFighterItem 中一并清除

**数据契约（仅 fighter.xml 通道）**：
```xml
<fighter id="溯源拉赫莱蒂" plugins="灵梦,xxx" ...>  <!-- 逗号分隔 plugin 角色 id -->
```
`FighterVO.initByXML` 解析 `@plugins` → `FighterVO.pluginIDs` → `SelectFighterStage.buildList` 构建子框（8 方位 gridOffset）。select.xml `<plugin>` 子节点通道（批次 6.1 遗留，`SelectStageConfigVO`）保留但未启用。

**交互**：右键 / 手柄 special（LB）展开子框（`doShow`）；**触屏长按 1.3s 展开**（批次 6.9，`LONG_PRESS_MS=1300`，`SelectFighterItem.touchLongPress*Handler` + `onLongPress` 回调）；子框展开时方向键走 `movePluginSelect`（8 方位子框 + 主角色间导航）；hover/select 组外角色或选中角色时收起（closePlugins）。TOUCH_MODE 点击其他角色框 → doHover → isBelongToPluginGroup 判断自动收起子框。

**维护要点**：
1. `SelectFighterItem` 的 badge 角标（`updateBadge`）与 face 占位 TextField（批次 6.7 `_refreshFace`）分属 `ui` 顶层与 `ui.ct` 子容器，无冲突
2. plugin 子角色 `_itemObj` 键 = `x,y.N` 后缀（避免与主网格 `x,y` 冲突）；`addFighterItem` 判空防御已就位（plugin id 无效 → null 跳过）
3. 子框坐标复用分页 `_loc5_/_loc6_`（含 `pageIdx*PAGE_HEIGHT`），且子框 ui 挂在 `_ui.bg` 容器内 → 翻页兼容（L5 待真机验证）
4. `clear()`/`destory()` 已做 `closePlugins()` + 引用置空 + `TweenLite.killTweensOf(_badge)` 防泄漏
5. **不要**把参考版 `SelecterItemUI.as` 合入——它带 `KyoVoiceSounder` 语音调用，主源码无此类（L4）
6. **触屏长按监听走 ui 原生路径**（`ui.addEventListener("touchBegin"...`），**不要**改走 override addEventListener（该路径单回调 + 移除 bug）；`onLongPress` 回调由 Stage 在 `addFighterItem` 注入；长按后松手由 `touchTapGuardHandler` 用 `_longPressed` 标志 + `stopImmediatePropagation()` 屏蔽误触（L7/L8）
7. **批次 6.10 教训**：
   - `SelectFighterItem` 用 `GameConfig` 必须 import（`#1065`：`-strict=false` 静默通过编译，运行时炸 → 新引入跨包符号先核对 import）
   - **render 分页吸附段必须跳过子框展开状态**（`p1/p2FocusedOnPlugin` + `isBelongToPluginGroup` 守卫）——否则 hover 子框被每帧吸附弹回主体、键盘 moveSlt 查不到子框（`_itemObj` 键 `x,y.N` 与主体 `x,y` 不同）
   - **`select.swf` 帧脚本依赖 `SelectFighterStage.SELECT_STATE` 静态变量**——**该变量必须恒为 0**！批次 6.10 曾在 `initAssist` 设 `SELECT_STATE=1`，导致帧脚本 `clear()` 每帧 `removeChild(up/down)` 第二次起抛 `#2025` 刷屏（批次 6.11 已修复：不再赋值，保持 0；辅助界面翻页由主程序 render 分页段支持）。**教训：主程序静态变量会被 select.swf 帧脚本每帧消费，赋非 0 值前必须确认帧脚本消费方式（此处 clear() 无守卫地每帧 removeChild）**

**备份链（2026-09-01）**：`.backup/{FighterVO,SelectFighterItem,SelectFighterStage}.as.pluginB.2026-09-01-1829`、`.backup/{CLAUDE,AGENTS}.md.pluginB.2026-09-01-1829`；**批次 6.9 触屏长按**：`.backup/{SelectFighterItem,SelectFighterStage}.as.touchlongpress.2026-09-01-1846`、`.backup/{CLAUDE,AGENTS}.md.touchlongpress.2026-09-01-1846`；**批次 6.10 选人崩溃+子框修复**：`.backup/{SelectFighterItem,SelectFighterStage}.as.bugfix610.2026-09-01-1905`、`.backup/{CLAUDE,AGENTS}.md.bugfix610.2026-09-01-1905`；**批次 6.11 #2025 刷屏修复**：`.backup/SelectFighterStage.as.bugfix611.2026-09-01-1911`、`.backup/{CLAUDE,AGENTS}.md.bugfix611.2026-09-01-1911`

### 9. 备份文件查找

本项目无 Git 版本控制，每次修改前自动备份到 `.backup/` 目录，格式为 `文件名.时间戳`。如需回退，从此目录恢复对应文件。本次对话全部备份：

| 文件 | 备份文件名 |
|------|-----------|
| `ScreenPadGame.as` | `.backup/ScreenPadGame.as.2026-07-29-1023` |
| `GameInterfaceManager.as` | `.backup/GameInterfaceManager.as.2026-07-29-1023` |
| `Debugger.as` | `.backup/Debugger.as.2026-07-29-1042` |
| `CLAUDE.md` | `.backup/CLAUDE.md.2026-07-29-1057` 以及 `.backup/CLAUDE.md.2026-07-29-1059` 以及 `.backup/CLAUDE.md.2026-08-11-1621` 以及 `.backup/CLAUDE.md.2026-08-11-1653` |
| `AGENTS.md` | `.backup/AGENTS.md.2026-07-29-1057` 以及 `.backup/AGENTS.md.2026-08-11-1621` 以及 `.backup/AGENTS.md.2026-08-11-1653` |
| `MessionModel.as` | `.backup/MessionModel.as.2026-08-11-1619`（闯关一局即通关修复） |
| `GameCtrl.as` | `.backup/GameCtrl.as.2026-08-11-1619` |
| `WinnerState.as` | `.backup/WinnerState.as.2026-08-11-1652`（胜利结算 BGM 不停修复） |
| `SelectUIFactory.as` | `.backup/SelectUIFactory.as.2026-08-11-1659`（选人界面 2P 显示框移 P1 正上方） |
| `CLAUDE.md` | `.backup/CLAUDE.md.2026-08-11-1701` |
| `AGENTS.md` | `.backup/AGENTS.md.2026-08-11-1701` |
| `FighterMain.as` | `.backup/FighterMain.as.2026-08-11-1808`（僵直 Bug 修复——新增 explodeSteelFrame getter） |
| `FighterMcCtrler.as` | `.backup/FighterMcCtrler.as.2026-08-11-1808`（僵直 Bug 修复——doHurt 钢体窗口守卫 + renderHurtBreak 空指针防护 + renderHurt 兜底） |
| `GameLoader.as` | `.backup/GameLoader.as.2026-08-12-1130`（新式 main_mc 人物包兼容——loadFighter/loadFighterFromPath 解析 main_mc） |
| `FighterCtrler.as` | `.backup/FighterCtrler.as.2026-08-12-1130`（新式 main_mc 人物包兼容——initFighter 双注入分支） |
| `CLAUDE.md` | `.backup/CLAUDE.md.2026-08-12-1134`（新式包兼容器录写入：GameLoader/FighterCtrler 修改方法 + EffectCtrl/SoundCtrl/GameCtrl 单例检查结论） |
| `AGENTS.md` | `.backup/AGENTS.md.2026-08-12-1134` |
| `FighterMcCtrler.as` | `.backup/FighterMcCtrler.as.fix.2026-08-15-1648`（灵压爆发钢体卡死修复——撤销 doHurt 钢体窗口守卫 + renderHurt 兜底加 explodeSteelFrame 条件） |
| `GameCtrl.as` | `.backup/GameCtrl.as.joyfix.2026-08-15-1703`（手柄路由单手柄模型——switchControlPlayer 按 joyTarget 决定控制方） |
| `GameInterfaceManager.as` | `.backup/GameInterfaceManager.as.joyfix.2026-08-15-1703`（refreshJoystickRouting 单手柄化 + 设置菜单接入 JoyStickSetUI） |
| `JoySticker.as` | `.backup/JoySticker.as.joyfix.2026-08-15-1703`（isDown/checkDownValue 边界 `>=` 修复 + pollInputLog 输入轮询） |
| `ExtendConfig.as` | `.backup/ExtendConfig.as.joyfix.2026-08-15-1703`（备份，未修改） |
| `JoyStickConfigVO.as` | `.backup/JoyStickConfigVO.as.remap.2026-08-15-1745`（键位重映射为 Xbox 实际布局） |
| `Debugger.as` | `.backup/Debugger.as.filelog.2026-08-15-*`（文件日志系统：log 落盘不依赖面板 + initFileLog + ENTER_FRAME 轮询） |
| `launch.as` | `.backup/launch.as.filelog.2026-08-15-*`（无条件调用 Debugger.initFileLog） |
| `FighterKeyCtrl.as` | `.backup/FighterKeyCtrl.as.fix.2026-08-15-*`（移除 listenKeys 注册——修复按钮边沿抢占无效） |
| `GameInputer.as` | `.backup/GameInputer.as.fix.2026-08-15-*`（call() 加 INPUT 按下边沿日志） |
| `CLAUDE.md` / `AGENTS.md` | `.backup/CLAUDE.md.docs.2026-08-15-*` / `.backup/AGENTS.md.docs.2026-08-15-*`（本文档更新备份） |
| `ViewManager.as` | `.backup/ViewManager.as.2026-08-27-1613.batch4.goP2`（批次 4 起点）→ `.backup/ViewManager.as.2026-08-27-1638.batch4.end`（批次 4 终态：goP2JoyStickSet + isMultiplePads + refreshMultiPadCache）→ `.backup/ViewManager.as.2026-08-28-0010.batch5.start` / `.2026-08-28-0030.batch5.end`（批次 5 改键进入日志） |
| `GameInterfaceManager.as` | `.backup/GameInterfaceManager.as.2026-08-27-1613.batch4.goP2`（批次 4 起点）→ `.backup/GameInterfaceManager.as.2026-08-27-1625.batch4.menugoP2.mid`（菜单 P2 入口中间态）→ `.backup/GameInterfaceManager.as.2026-08-27-1638.batch4.end`（批次 4 终态） |
| `SelectFighterStage.as` | `.backup/SelectFighterStage.as.2026-08-27-1632.batch4.refreshCache.mid`（选人 refreshMultiPadCache 中间态）→ `.backup/SelectFighterStage.as.2026-08-27-1638.batch4.end`（批次 4 终态） |
| `GameJoystickInput.as` | `.backup/GameJoystickInput.as.2026-08-28-0010.batch5.start`（批次 5 起点）→ `.backup/GameJoystickInput.as.2026-08-28-0030.batch5.end`（批次 5 终态：_joyLog 设备感知 + anyKey 接 _checkEdge + EDGE ctrl 组合） |
| `CLAUDE.md` / `AGENTS.md` | `.backup/CLAUDE.md.2026-08-28-0045.docs` / `.backup/AGENTS.md.2026-08-28-0045.docs`（批次 1-5 文档更新备份） |
| `Debugger.as` | `.backup/Debugger.as.buildtag.2026-08-27-1602`（版本号机制初版）→ `.backup/Debugger.as.buildtag.injected.2026-08-27-1607`（sed 注入后含 BUILD_TAG `BVN-3.3EX-batch6.14-2026-08-27-1604`） |
| `build.bat` | `.backup/build.bat.buildtag.2026-08-27-1604`（PowerShell 自动注入 BUILD_TAG 日期时间，批次号 `batch6.14` 硬编码于脚本） |
| `tools/Test/launch.swf` | `.backup/launch.swf.batch614.2026-08-27-1606` (34611060B) + `.backup/launch.swf.batch614.2026-08-27-1607` (34611060B) — md5 `52f76b80407023419f7daacecedbb0e4`，比 6.13 增 487B（30+ 行 BUILD_TAG/SESSION 写入），0 error 0 warning，编译 70s（swfdump `-abc` 反汇编验证 `BVN-3.3EX-batch6.14-2026-08-27-1604` 字面量在 SWF 中） |
| `AGENTS.md` | `.backup/AGENTS.md.batch614.2026-08-27-1623`（本批次文档追加前备份） |
| `FighterVO.as` / `SelectFighterItem.as` / `SelectFighterStage.as` | `.backup/{FighterVO,SelectFighterItem,SelectFighterStage}.as.pluginB.2026-09-01-1829`（人物子框方案 B 移植起点：FighterVO 解析 @plugins + SelectFighterItem 整体替换 badge 动画版 + SelectFighterStage 移植 doShow/movePluginSelect 保留分页） |
| `CLAUDE.md` / `AGENTS.md` | `.backup/CLAUDE.md.pluginB.2026-09-01-1829` / `.backup/AGENTS.md.pluginB.2026-09-01-1829`（人物子框专节写入前备份） |

### 10. 手柄键位映射（Xbox Wireless Controller 实际布局，2026-08-15）

`JoyStickConfigVO.as` 默认键位按 **Xbox Wireless Controller 实测 control 布局**（AIR GameInput API 报告，24 control）：

```
control 0/1  = D-pad HAT 轴（AXIS_16 上下 / AXIS_15 左右）
control 8/9  = 左摇杆（AXIS_1=Y 正1=下拉 / AXIS_0=X）
control 13=A  14=B  15=X  16=Y
control 17=LB  18=RB  19=LS  21=Start  22=Select
control 10/11/12 = D-pad 按钮（BUTTON_19/21/22，缺 down）
```

| 配置项 | control | 物理键 | 配置项 | control | 物理键 |
|--------|---------|--------|--------|---------|--------|
| up2 | (8,-0.5) | 左摇杆上 | attack | (15,1) | X |
| down2 | (8,0.5) | 左摇杆下（正1=下拉） | jump | (13,1) | A |
| left2 | (9,-0.5) | 左摇杆左 | dash | (14,1) | B |
| right2 | (9,0.5) | 左摇杆右 | skill | (16,1) | Y |
| up | (0,-0.5) | D-pad 上（HAT） | superSkill | (18,1) | RB |
| down | (0,0.5) | D-pad 下（HAT） | special | (17,1) | LB |
| left | (1,-0.5) | D-pad 左（HAT） | waikai | (19,1) | LS 按下 |
| right | (1,0.5) | D-pad 右（HAT） | back | (21,1) | Start（暂停） |
| | | | select | (22,1) | Select（确认） |

> **历史坑**：旧默认映射（left2/right2=0/1、back=8 等）基于另一设备调试，与 Xbox Wireless Controller 完全错位——back=8 实为左摇杆 Y 轴 → **下拉左摇杆触发暂停**；按钮全部无效。**更换手柄设备时务必先看 `connected/button:N:ID` 日志核对 control 布局再改映射**。
> 按键设置 UI：设置菜单「控制设置」→ `ViewManager.goP1JoyStickSet()`（JoyStickSetUI，可重新映射）。

> **scripts_cut/ 独立阉割版副本（2026-08-12）**：为产出阉割版 launch.swf，在 `BVNscripts/scripts_cut/` 完整复制主项目源码并做阉割修改（主项目 `BVNscripts/scripts/` **零改动**）。编译素材（12 内嵌 UI SWF + 20 图像）全部反编译自 `FFDEC/面板改.swf`（源见 `FFDEC/_ui_extract_test/`、`FFDEC/_img_extract_test/`）。编译产物 `BVNscripts/_cut_output/launch.swf`（5242613 字节，0 error，独立不覆盖主项目 `tools/Test/launch.swf`）。
> **阉割项**：隐藏双人玩法(21/11/24/14/23/25/13/15)、制作组(CREDITS)、键盘输入开关(ENABLE_KEYBOARD)、无限气开关(INFINITE_ENERGY)、手柄控制开关(joyTarget 设置项，保留 refreshJoystickRouting 切换逻辑)；暂停菜单新增「出招表 MOVE LIST」按钮与「返回选人 BERAK SELECT」同组；广告(**保持现状**)；设置界面无返回选人按钮(用户澄清"只移除按钮"，实际原无)。
> **保留项**：练习40、单闯20、单VS CPU22、小闯10、小队VS CPU12、3.6新式 main_mc 兼容(GameLoader/FighterCtrler)、控制权切换(ScreenPadGame/_switchPlayer/refreshJoystickRouting)。
> **本次副本修改备份**（源文件在 `scripts_cut/` 内，备份于根 `.backup/`）：`GameInterfaceManager.as`、`SetBtnGroup.as`、`PauseDialog.as`、`MenuBtnGroup.as`、`GameInterface.as`（后缀 `.2026-08-12-1629`）。

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
