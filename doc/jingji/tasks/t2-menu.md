# t2：GameInterfaceManager 菜单

- 目标：主菜单重组 + 设置菜单追加 6 项。
- 文件：`BVNscripts/scripts/net/play5d/game/bvn/mob/GameInterfaceManager.as`（1 个）
- 依赖：t1（字段存在才显示当前值/可写）。
- 检查：build.bat 零错误；getGameMenu 顶层无 MISC/LAN；6 个 optoinKey 与 fork 选项一致。
