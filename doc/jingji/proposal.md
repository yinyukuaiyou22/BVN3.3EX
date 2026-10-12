# 竞技规则移植 Proposal（主菜单结构 + 6 项竞技设置）

日期：2026-09-09
状态：已确认（需求访谈完成）

## 目标

把 `BVNscripts/3.3竞技项`（PC win 版）中主项目缺失的两部分移植到主项目 `BVNscripts/scripts`（mob 版）：

1. 主菜单按 fork 的 TEAM PLAY / SINGLE PLAY 两级模式组重组，保留主项目独有模式与中文标签，不加 LAN。
2. OPTION 设置菜单补齐 6 项对战规则设置，并让它们真实生效：
   - `initialQi` 初始气量（默认 100）
   - `isSteelBodyFreeze` 刚身停顿（默认 false）
   - `allowWankai` 允许变身（默认 true）
   - `isAllowRepeatAttack` 允许重复连（默认 false）
   - `cameraMaxSize` 镜头最大大小（默认 1）
   - `isChangeSpecialKey` 修改灵替按键 ↑/↓+special（默认 true）

## 非目标

- 不做 LAN 联机、UDP/房间/主机列表。
- 不做 fork 设置菜单中其余项：显示模式（isFullScreen）、按键操作模式入口（keyInputMode 机制已存在，不补菜单）、P1/P2 KEY SET、MITSUNE/SURVIVOR 等。
- 不做对局中实时热切换：设置项在进入下一场对局初始化时生效（与 fork 行为一致）。

## 运行时上下文

- 主项目 launch.as 使用 mob 包，PC 调试（build.bat）与 Android（debug_mob.bat）共用同一份源码。
- 主菜单与设置菜单都由 `GameInterface.instance`（mob/GameInterfaceManager）提供 JSON。
- 本移植对两个运行目标同时生效，验收按用户要求只做 `build.bat` 编译验证。

## 功能需求

- `ConfigVO` 增加 6 字段，默认值 = fork 原值；`toSaveObj` 落盘；老存档缺字段时保留类声明默认值（自动补齐）。
- mob `getGameMenu()`：重组为 TEAM PLAY / SINGLE PLAY / OPTION / TRAINING / CREDITS / EXIT GAME。
- mob `getSettingMenu()`：追加 6 个设置项（fork 选项值）。
- 行为消费点逐文件与 fork 对齐。

## 约束与假设

- 遵守 AGENTS.md：修改前备份 `.backup/`、≥4 文件联动时更新 CLAUDE.md、编译零错误验收。
- 新默认值会改变当前对战手感（气起始 0→100、刚身冻结恒开→默认关、无重复连限制→默认限制、灵替纯 special→默认需要方向组合），已与用户确认接受。
- 文档、注释用中文，代码标识符保持反编译原样。

## 成功标准 / 验收检查

1. `./build.bat` 编译零错误。
2. `rg` 静态确认 6 个 optoinKey 都出现在 ConfigVO 与 getSettingMenu，且各行为文件存在对应消费点。
3. `getGameMenu()` 顶层为 TEAM PLAY → SINGLE PLAY → OPTION → TRAINING → CREDITS → EXIT GAME，无 MISC / LAN。
4. 老存档（无新键）加载后新字段为默认值，再次保存写入 6 键。

## 待决问题（已闭环）

- 范围：6 项核心规则 + 菜单结构（用户确认）。
- 平台：仅编译验证（用户确认）。
- 默认值：fork 原值 + 老存档兼容（用户确认）。
