# AGENTS.md

本文件为 AI 开发助手（Claude Code / DeepSeek）提供项目专属的开发上下文和行为准则。每次开发会话开始时，AI 应首先阅读本文件与 [CLAUDE.md](CLAUDE.md)。

## 开发环境

| 工具 | 用途 |
|------|------|
| VSCode | 代码编辑 |
| Claude Code | AI 辅助开发（主模型 DeepSeek V4 Pro，简单任务可切换 flash 模型） |
| build.bat | 编译脚本（`Ctrl+Shift+B` 或直接运行） |
| Java 17 | mxmlc 编译器运行时 |
| Flex SDK 4.16.1 + AIR 51.0 | AS3 编译工具链 |

## 关键规则

1. **响应语言**：中文（技术术语/代码标识符/文件路径可保留英文）
2. **代码基准**：`BVNscripts/scripts/` 为可编译源码，`last/` 为参考基线
3. **编译验证**：每次修改后运行 `./build.bat`，确认零错误
4. **不要动**：`_assets/` 目录中的 `.bin`/`.png`/`.mp3` 文件、`mx/core/` 框架桩
5. **嵌入式资源**：统一通过 `EmbeddedAssets.as` 的 `[Embed]` 管理
6. **UI SWF**：从 `assets/swf/` 运行时加载，由 `ResUtils.as` 处理
7. **不要提交**：`*.swf`、`assets/`、`OLD/`、`last/`、`Outscripts/`、`BVN3.9/`、`launch-fla/`

## 编译命令

```bash
# 完整编译（项目根目录）
./build.bat

# 或直接调用：
java -jar D:\flex4.16.1-air51.0.1.1\lib\mxmlc.jar \
  +flexlib=D:\flex4.16.1-air51.0.1.1\frameworks \
  -debug=true -swf-version=37 -strict=false \
  -source-path+=E:/.../BVNscripts/scripts \
  -library-path+=.../core.swc \
  -external-library-path+=.../airglobal.swc \
  -output=launch.swf -- .../launch.as
```

## 反编译代码特征

- **参数名**：`param1`、`param2`…（无意义，保持与同文件一致）
- **局部变量**：`_loc1_`、`_loc2_`…（同上）
- **内联匿名函数**：大量 `function():void { ... }` 回调模式
- **单例访问**：`ClassName.I` 静态 getter
- **拼写错误**：`NORNAL`（NORMAL）、`destory`（destroy）、`Mession`（Mission）— 保持原样
- **`this.` 前缀**：`last/` 基线使用 `this.` 前缀风格，保持一致

## 常见任务指南

### 修改游戏逻辑
1. 确认涉及的类（参考 CLAUDE.md）
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
| 编译 | `build.bat`、`asconfig.json`、`.vscode/tasks.json` |
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
| UI SWF | `ResUtils.as`、`assets/swf/` |
| 移动端 | `mob/GameInterfaceManager.as`、`mob/screenpad/` |
| 调试 | `Debugger.as`（DEBUG_PANEL_ENABLED 开关） |
| 网络 | `mob/sockets/`、`mob/ctrls/LAN*.as` |
