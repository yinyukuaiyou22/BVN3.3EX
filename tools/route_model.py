#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BVN 项目模型主动路由器

根据任务描述分析复杂度，推荐应使用的 AI 模型。
由 Claude Code Skill `/route-model` 调用，或手动运行。

用法:
  python tools/route_model.py "分析 FighterMcCtrler 的 INFINITE_ENERGY bug"
  python tools/route_model.py --stdin              # 从标准输入读取
  python tools/route_model.py --json               # JSON 格式输出
"""

import sys
import re
import json
import os

# ── 模型池 ──────────────────────────────────────────────
MODELS = {
    "flash":  {"name": "deepseek-v4-flash", "description": "轻量 — 简单修改/搜索/单文件编辑"},
    "pro":    {"name": "deepseek-v4-pro",   "description": "主力 — 多文件重构/复杂逻辑/Bug 排查"},
}

# ── 复杂度权重 ──────────────────────────────────────────
# 注: 中文关键词不用 \b（Python \b 对 CJK 不生效），改用直接匹配
SIGNALS_PRO = [
    (r"(?:debug|排查|调查|追踪|trace|investigate)", 3),
    (r"(?:重构|refactor|重写|rewrite|架构|architecture)", 4),
    (r"(?:多文件|multi.*file|联动|连锁|关联)", 3),
    (r"\b(?:AI|人工智能|机器学习|neural)\b", 2),
    (r"(?:性能|优化|optimize|perf)", 2),
    (r"(?:安全|security|注入|injection|漏洞)", 2),
    (r"(?:兼容|compat|迁移|migrate|升级)", 2),
    # 文件数
    (r"(\d+)\s*(?:个|处|files?)", lambda m: min(int(m.group(1)) // 2, 5)),
]

SIGNALS_FLASH = [
    (r"(?:typo|拼写|格式|format|注释|comment|简单|simple)", 3),
    (r"(?:改名|rename|移动|move file)", 2),
    (r"(?:文档|doc|readme|CLAUDE\.md)", 3),
    (r"(?:单行|one.?line|一行)", 4),
    (r"(?:复制|copy|替换|replace.*all)", 1),
]

def analyze(task: str, file_count: int = 0) -> dict:
    """
    分析任务文本，返回模型推荐。
    file_count: 已知涉及的文件数（来自上下文统计），0 = 不确定
    """
    text = task.lower()
    score = 0  # 正 = 倾向 pro/opus，负 = 倾向 flash
    reasons = []

    # Phase 1: 关键词信号
    for pattern, weight in SIGNALS_PRO:
        m = re.search(pattern, text)
        if m:
            pts = weight(m) if callable(weight) else weight
            score += pts
            reasons.append(f"+{pts} pro: {m.group(0)[:40]}")

    for pattern, weight in SIGNALS_FLASH:
        if re.search(pattern, text):
            score -= weight
            reasons.append(f"-{weight} flash: {pattern[:40]}")

    # Phase 2: 文件数推断
    if file_count > 0:
        if file_count >= 6:
            score += 4
            reasons.append(f"+4 (files >= 6: {file_count})")
        elif file_count >= 4:
            score += 2
            reasons.append(f"+2 (files >= 4: {file_count})")
        elif file_count <= 1:
            score -= 1
            reasons.append(f"-1 (single file)")

    # Phase 3: 文本长度（长描述往往意味着复杂任务）
    if len(task) > 500:
        score += 1
        reasons.append("+1 (long description)")
    elif len(task) < 50:
        score -= 1
        reasons.append("-1 (short description)")

    # Phase 4: 判断（仅 Pro ↔ Flash 两档，Opus 暂不使用）
    if score >= 3:
        recommendation = "pro"
    else:
        recommendation = "flash"

    model = MODELS[recommendation]
    return {
        "score": score,
        "model_key": recommendation,
        "model_name": model["name"],
        "model_desc": model["description"],
        "reasons": reasons,
        "advice": f"推荐: /model {model['name']} ({model['description']})"
    }


def main():
    args = sys.argv[1:]
    use_json = "--json" in args
    use_stdin = "--stdin" in args
    file_count = 0

    # Parse --files=N
    for a in args:
        if a.startswith("--files="):
            file_count = int(a.split("=")[1])

    # Parse task text
    if use_stdin:
        task = sys.stdin.read().strip()
    else:
        # Filter out flags
        text_args = [a for a in args if not a.startswith("--")]
        task = " ".join(text_args) if text_args else ""
        if not task:
            # No args, try to read from stdin anyway
            if not sys.stdin.isatty():
                task = sys.stdin.read().strip()

    if not task:
        result = {
            "error": "No task description provided.",
            "usage": "python tools/route_model.py '<task description>' [--files=N] [--json]"
        }
        if use_json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            print(result["usage"])
        return

    result = analyze(task, file_count)

    if use_json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"任务: {task[:80]}{'...' if len(task)>80 else ''}")
        print(f"评分: {result['score']}  |  推荐: {result['model_name']}")
        print(f"说明: {result['model_desc']}")
        if result['reasons']:
            print(f"依据: {', '.join(result['reasons'])}")
        print()
        print(result['advice'])


if __name__ == "__main__":
    main()
