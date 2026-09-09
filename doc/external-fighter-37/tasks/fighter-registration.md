# 任务：外部人物注册与加载

- 目标：保证扫描占位 VO、XML 合并和 SWF 加载时序稳定。
- 输入：`ctrl/GameLoader.as`、`data/GameData.as`、`data/FighterModel.as`、`data/FighterVO.as`。
- 步骤：确认扫描目录和 ID 规则；固定内置优先；规范 `fileUrl`；验证 `main_mc`/根 MovieClip；确认选人列表刷新点。
- 检查：仅 SWF、仅 XML、二者都有、重复 ID、损坏 SWF；编译。
- 完成定义：外部人物可选并可进入战斗，错误不影响内置内容。
- 依赖：asset-resolution。
