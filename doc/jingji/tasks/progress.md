# progress.md（唯一真相来源）

## 状态

- [x] 需求澄清（用户确认：菜单结构 + 6 项核心规则、fork 原默认值 + 老存档兼容、仅编译验收）
- [x] t1 配置层 ConfigVO
- [x] t2 GameInterfaceManager 菜单
- [x] t3 简单行为（气/刚身/镜头/灵替键）
- [x] t4 允许变身守卫
- [x] t5 防重复连子系统（FighterMcCtrler）
- [x] t6 防重复连依赖基础设施
- [x] t7 索引更新与终验

## 已运行命令记录

| 时间 | 命令 | 结果 |
|---|---|---|
| 2026-09-09 | 规划期静态调研（ConfigVO/GameInterfaceManager/行为消费点全量核对） | 通过 |
| 2026-09-09 09:21 | `./build.bat`（t1 后） | Exit 0，launch.swf 35079735B |
| 2026-09-09 09:22 | `./build.bat`（t2 后） | Exit 0，launch.swf 35080387B |
| 2026-09-09 09:23 | `./build.bat`（t3 后） | Exit 0，launch.swf 35080780B |
| 2026-09-09 09:24 | `./build.bat`（t4+t5 后） | Exit 0，launch.swf 35081528B |
| 2026-09-09 09:25 | `./build.bat`（t6 后） | Exit 0，launch.swf 35081950B |
| 2026-09-09 09:26 | `./build.bat`（纠正 EffectCtrl 落点后） | Exit 0，launch.swf 35081944B |
| 2026-09-09 09:26 | CLAUDE.md 索引更新 | 完成 |

## 过程备注

- 期间发现 t3 补丁把「刚身停顿」分支误插入 `EffectCtrl.doHitEffect`（普通命中特效）而非 `doSteelHitEffect`，已在 09:26 修复并编译验证（消费点唯一）。备份见 `.backup/EffectCtrl.as.jingji.*`。
- 防重复连实际还需 `getDoingAction` 基础设施（FighterMain/Bullet/FighterAttacker），超出原计划 3 文件，已追加 t6 并在详细设计/CLAUDE.md 记录。

## 阻塞项

- 无。
