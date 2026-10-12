# t5：防重复连子系统（FighterMcCtrler）

- 目标：doHurt 接入重复命中判定（无伤飞行 + 减击飞 y + 状态清除），doActionTimes 递增。
- 文件：`fighter/ctrler/FighterMcCtrler.as`
- 依赖：t1、t4 完成后同文件连续编辑。
- 检查：build.bat 零错误；isAllowRepeatAttack=true 时 hurtActionRepeatCheck 首行直接 false。
