# t1：配置层 ConfigVO

- 目标：新增 6 字段（fork 默认值）+ toSaveObj 落盘。
- 文件：`BVNscripts/scripts/net/play5d/game/bvn/data/ConfigVO.as`（1 个）
- 依赖：无。
- 检查：build.bat 零错误；老存档缺键场景由字段默认值覆盖（读代码确认 KyoUtils 路径不删键）。
- 完成定义：6 字段存在且默认值 = isSteelBodyFreeze=false, initialQi=100, allowWankai=true, isAllowRepeatAttack=false, isChangeSpecialKey=true, cameraMaxSize=1；toSaveObj 写 6 键。
