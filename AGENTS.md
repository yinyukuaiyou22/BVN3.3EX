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

| 角色 | 模型 | 用途 |
|------|------|------|
| 主力 | DeepSeek V4 Pro | 核心逻辑、架构设计、Bug 排查 |
| 轻量 | deepseek-v4-flash | 批量搜索、简单修改、子任务分发 |

可临时切换：简单任务直接用 Flash，不必一直用 Pro。

## 开发环境

| 工具 | 用途 |
|------|------|
| VSCode | 代码编辑 |
| Claude Code | AI 辅助开发 |
| `build.bat` | PC 编译 SWF（`Ctrl+Shift+B` 或直接运行） |
| `tools/script/debug.bat` | PC 端编译 + adl 启动调试 |
| `tools/script/debug_mob.bat` | 手机端打包 APK + ADB 安装 + fdb 调试 |
| `tools/script/fdbg.bat` | 通用 SWF fdb 断点调试 |
| Java 17 | mxmlc 编译器运行时 |
| Flex SDK | `flex4.16.1-air51.0.1.1/`（项目根相对路径） |
| AIR SDK | `AIRSDK5/AIRSDK_51.3.2/`（ADT/fdb/adl/证书） |

## 关键规则

1. **响应语言**：中文（技术术语/代码标识符/文件路径可保留英文）
2. **代码基准**：`BVNscripts/scripts/` 为可编译源码
3. **编译验证**：每次修改后运行 `./build.bat`，确认零错误
4. **不要动**：`_assets/` 目录中的 `.bin`/`.png`/`.mp3` 文件、`mx/core/` 框架桩
5. **嵌入式资源**：统一通过 `EmbeddedAssets.as` 的 `[Embed]` 管理
6. **UI SWF**：从 `assets/swf/` 运行时加载，由 `ResUtils.as` 处理
7. **不要提交**：`*.swf`、`assets/`、`OLD/`、`last/`、`Outscripts/`、`BVN3.9/`、`flex4.16.1-air51.0.1.1/`、`AIRSDK5/`、`tools/Test/`
8. **精确指定上下文**：避免"分析整个项目"，改为指定文件/模块。先列出相关文件再逐步处理，而非一次性加载全部
9. **分步执行**：大型任务拆分为多个小步骤，每次修改后手动审核，减少反复重跑整个项目
10. **利用会话缓存**：相关修改在同一会话中完成，避免频繁开新会话重复加载

## Token 优化策略

大项目消耗 token 多，以下策略可降低 **40%–70%** 的 token 消耗：

### 1. 精确指定上下文
- ✅ "优化 `fighter/ctrler/FighterMcCtrler.as` 中的 INFINITE_ENERGY 处理"
- ❌ "看看整个项目哪里写得不好"
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
flex4.16.1-air51.0.1.1/
AIRSDK5/
last/
OLD/
BVN3.9/
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

| 内容类型 | 压缩器 | 预计节省 |
|----------|--------|----------|
| Grep 搜索结果（大量 JSON） | SmartCrusher | 70-90% |
| ActionScript 源码 | CodeCompressor (tree-sitter AST) | 40-70% |
| 构建日志 | LogCompressor | 80-95% |
| 工具输出 | SearchCompressor | 60-80% |
| 纯文本 | Kompress (ModernBERT) | 30-50% |

### 文件排除

`.claudeignore` 已排除：`*.swf` / `*.png` / `*.mp3` / `*.bin` / `_assets/` / `flex4.16.1-air51.0.1.1/` / `AIRSDK5/` / `last/` / `OLD/` / `Outscripts/`。

### 常用命令

| 命令 | 用途 |
|------|------|
| `headroom proxy --port 8787` | 启动本地压缩代理 |
| `headroom wrap claude` | 直接包装 Claude Code |
| `headroom perf` | 查看压缩统计和性能 |
| `headroom learn` | 从失败会话学习，写入 CLAUDE.md/AGENTS.md |
| `curl http://localhost:8787/stats` | 查看实时压缩统计 |

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
- commit message 末尾加：`Co-Authored-By: DeepSeek V4 Pro <noreply@deepseek.com>`
- 不提交 `*.swf`、参考/蓝图目录

## 关键文件速查

| 需求 | 优先查看 |
|------|---------|
| 编译 | `build.bat`、`asconfig.json` |
| 调试 | `tools/script/debug.bat`、`tools/script/debug_mob.bat` |
| 入口/初始化 | `launch.as`、`MainGame.as` |
| 物理参数 | `GameConfig.as` |
| 角色动作 | `FighterMcCtrler.as`、`FighterAction.as` |
| AI | `fighter/ctrler/ai/FighterAILogic.as` |
| 碰撞 | `GameMainLogicCtrler.as` |
| 菜单/按钮 | `MenuBtnGroup.as`、`MenuBtn.as` |
| 暂停菜单 | `PauseDialog.as` |
| 设置 | `SetBtnGroup.as`、`SettingState.as` |
| 输入 | `GameInputer.as`、`FighterKeyCtrl.as` |
| 配置/存档 | `GameData.as`、`ConfigVO.as` |
| 嵌入式资源 | `EmbeddedAssets.as`、`mx/core/` |
| UI SWF | `ResUtils.as` |
| 移动端 | `mob/GameInterfaceManager.as`、`mob/screenpad/` |
| 调试 | `Debugger.as`（`DEBUG_PANEL_ENABLED` 开关） |
| 网络 | `mob/sockets/`、`mob/ctrls/LAN*.as` |
