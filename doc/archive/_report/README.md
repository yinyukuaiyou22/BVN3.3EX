# doc/archive/_report —— 历史真机诊断报告（归档）

2026-11-17 从 `tools/Test/_report/` 迁入。原目录（4.2 GB，主要是真机截图、编译日志与一个 3.88 GB 的 `assets_slim.tar`）已清理；
只保留结论性文档与原始对照数据。

| 文件 | 说明 |
|---|---|
| `2026-10-09_ANE-诊断报告.md` | ANE `#2113` 的 8 类变量实测排除（CLAUDE.md「ANE 现状」引用） |
| `2026-10-09_分支B验收报告.md` | 外置资源迁到 `Android/media` 的真机验收 |
| `2026-10-23_GPU滤镜探针结论.md` | GPU 模式滤镜行为实测（doc/gpu-filter-proxy.md 引用） |
| `2026-10-08_资源迁移与精简包.md` | 精简包 3.892 GB / 1620 文件口径的原始记录 |
| `filter_probe_{gpu,cpu}.json` | GPU 滤镜探针原始对照数据 |
| `key-log-lines.txt` / `AB-evidence.txt` | 2026-11-12 滤镜开关 A/B 证据摘录（原根目录 `_report/filter-switch-2026-11-12/`） |

> 说明：正文里出现的 `tools/Test/_report/xxx` 是**当时**的路径，保留原样以维持历史可读性；现行路径见本文件。
