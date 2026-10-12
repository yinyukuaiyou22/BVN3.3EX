# 实现控制 Prompt（doc/jingji）

## 主 Agent 角色

- 负责按 `tasks/progress.md` 顺序执行；每个代码任务前先备份原文件到 `.backup/`（文件名+时间戳）。
- 每个任务完成后运行 `./build.bat`，记录输出到 progress。
- 审查改动：只动任务文件；无 git 时用备份 diff 对照。
- 全程中文注释；保留反编译标识符（_locN_/paramN/拼写错误）原样。

## 验证命令

```text
./build.bat                                  # 编译零错误
rg <各 optoinKey> 对应文件                    # 静态断言
diff 备份 vs 修改后文件（或无 git 时对照）
```

## 护栏

- 有歧义或发现计划外联动：暂停，更新 progress 后询问用户。
- 不做无关重构；不删任何文件；不改 _assets/ 与 mx/core/。
- 老存档兼容必须保留：readSaveObj 不删键逻辑。
- 最终交付：CLAUDE.md 索引更新 + progress.md 全部勾选 + 最终编译零错误。

## 输入文档

- doc/jingji/proposal.md
- doc/jingji/high-level-design.md
- doc/jingji/detailed-design.md
- doc/jingji/tasks/*.md
- doc/jingji/tasks/progress.md
