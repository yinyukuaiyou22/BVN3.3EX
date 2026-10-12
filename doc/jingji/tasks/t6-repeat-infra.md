# t6：防重复连依赖基础设施

- 目标：FighterMain/Bullet/FighterAttacker 提供 getDoingAction 快照。
- 文件：`fighter/FighterMain.as`、`fighter/Bullet.as`、`fighter/FighterAttacker.as`（3 个）
- 依赖：t5。
- 检查：build.bat 零错误；三文件均有 getDoingAction；destory 清引用。
