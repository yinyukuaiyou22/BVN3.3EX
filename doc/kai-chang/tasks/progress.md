# 开场修复 · 任务进度（唯一真相来源）

Feature：全模式第一局不播开场（根因：`GameCtrl.buildGame()` 开场分支条件恒真）
Proposal：`doc/kai-chang/proposal.md`
进度：**3 / 5 已完成，等 t4 实测**

## 任务

| # | 任务 | 文件 | 状态 | 说明 |
|---|---|---|---|---|
| t1 | P0：恢复原版开场条件 `if(mode == 40)`，删掉恒真的 `mode != 40 \|\|` 前缀，改写注释 | `launch-fla/src/net/play5d/game/bvn/ctrl/game_ctrls/GameCtrl.as`（318-326） | ✅ 完成 | 见 §改动摘要 |
| t2 | P2：1v2 第 2/3 局也走镜头开场（`doBuildNextRound` 内 `param1 \|\| is1v2Mode()`，HP 继承仍只认 `param1`） | 同上（434-445） | ✅ 完成 | 同文件，与 t1 一次改完 |
| t3 | 编译 + 静态检查 | — | ✅ 完成 | 见 §已运行命令 |
| t4 | 实测（**需用户操作**） | — | ☐ **待用户执行** | 见下方清单 |
| t5 | 收尾 | — | ☐ 待办 | 按 t4 结果决定是否追加 P1 超时兜底；把本文件与 proposal 状态改「已完成」 |

## 改动摘要（相对 `.backup/2026-09-18-1615/GameCtrl.as`）

```
318,324c318,326     // 注释重写 + 条件：!= 40 || (== 40 && !SAY_INTRO)  →  == 40
432c434,436         // doBuildNextRound: if(param1)  →  if(param1 || is1v2Mode())
434c438             //   HP 继承改成 if(param1) 单独门控
```

只动一个文件、两处逻辑，无其它改动（`diff` 已确认）。

## t4 实测清单（运行 `PC版工程/launch/debug.bat`）

按优先级从上往下测，**第 1 项不过就停，直接回退并转 t5**：

1. **【阻断项】闯关单(20) 第一局**：开场是否自动走完（镜头拉近 P1 → P1 姿态 → 镜头转 P2 → P2 姿态 → 镜头拉回 → READY/FIGHT）？全程不按键。
   - 通过 → 继续
   - 卡住（角色停在姿态、无法操作、ESC 不出暂停菜单）→ **立即回退 P0**（`cp .backup/2026-09-18-1615/GameCtrl.as` 覆盖回去，重跑编译），转 t5 追加 P1 兜底
2. 练习模式(40)：无开场、立即可操作、ESC 能弹暂停菜单（**回归项，不得复发**）
3. 1v2(24) 第一局：有开场；`fighter2` 站位可接受
4. 1v2(24) 战至第 2 局：出现镜头开场（只播上一局败方姿态），且双方**回满血**
5. 2v2(14) 第一局：有开场
6. VS 人(11) / VS CPU(22) / 观战(23) 第一局：有开场；观战双方均 AI 时无异常
7. 各模式第 2 局行为与改动前一致（不回归）
8. 读 `launch/log.log`：无新增 `TypeError` / `Error #1065`

## 阻塞项

- **待用户实测**（t4 第 1 项是唯一放行闸门）
- **已知未消解风险**：开场「自动结束」在静态代码里找不到明确出口（`actionState == 60` 只有 `idle()` 会清，开场期间 `actionEnable=false` 使 `renderFloorAction` 禁用分支不命中 `开场` 帧名）。已按决策 Q3 选择"不加兜底、先实测"。

## 已运行命令

| 命令 | 结果 |
|---|---|
| `cp src/.../GameCtrl.as .backup/2026-09-18-1615/` | ✅ md5 一致（`69fcd8b6…`） |
| mxmlc（= `build.bat` 全参数，java 21） | ✅ **错误 0 / 警告 55**（与基线一致），`tmp_cws.swf` 3025405 字节 |
| `tools/swf2zws.py` | ✅ `launch.swf` 2948742 字节（ZWS） |
| mxmlc `-strict=true`（= `lint.bat` 全参数） | ✅ **错误 0 / 警告 55**（与 baseline `lint.log` 逐项一致） |

> 说明：本机安全策略禁止从 bash/PowerShell 调 `cmd.exe`，故 `.bat` 内容被逐参数等价复现后用 `java` 直接执行，参数与 `build.bat` / `lint.bat` 完全一致（含 `-default-size 800 600` 与三个 `-source-path`）。日志仍写入原 `build.log` / `lint.log`。
