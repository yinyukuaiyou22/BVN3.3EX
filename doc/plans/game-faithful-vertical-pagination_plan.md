# 垂直分页对齐游戏内模型 实施计划（select-layout-tool）

## Summary

工具当前页 0 渲染 13~14 行（末行被裁切），而游戏内（主程序 `SelectFighterStage.buildList`）页 0 只显示 **7 行**——即用户截图红框部分；红框以下的行在游戏里属于第 2 页及以后。根因：工具仍用「3.9 整列直排」模型（gapY 由整幅 layout.height ÷ 总行数、按像素窗切页），而主程序已于 2026-10-10 改为「按页」模型。本计划把工具的垂直布局 + 分页公式整体切换为主程序口径，保证显示效果与游戏内相同。

## 游戏内权威公式（唯一真相源）

`BVNscripts/scripts/net/play5d/game/bvn/state/SelectFighterStage.as:261-322`（`CELL_SIZE=(60,60)` 见 :45，`GAME_SIZE=(800,600)` 见 `GameConfig.as:140`）：

```text
viewportH      = min(layout.height, GAME_SIZE.y)              // = min(6300,600) = 600
usableH        = viewportH - top - bottom                     // 600-60-110 = 430（< CELL_SIZE.y 时取 CELL_SIZE.y）
rowsPerPage    = floor(usableH / CELL_SIZE.y)                 // floor(430/60) = 7
maxY           = 最大行号(gridY)
displayedVCount= min(VCount, rowsPerPage, maxY+1)
gapX           = (width - unitSize.x - left - right)/(HCount-1)
gapY           = (viewportH - unitSize.y - top - bottom)/(displayedVCount-1)   // 380/6 = 63.33
                 钳制 gapY >= CELL_SIZE.y；displayedVCount==1 时 gapY = CELL_SIZE.y
PAGE_HEIGHT    = viewportH                                    // 600
TOTAL_PAGES    = ceil((maxY+1)/rowsPerPage)                   // char: ceil(138/7)=20；assist: ceil(13/7)=2
item.y         = y+top + gapY*(gridY % rowsPerPage) + floor(gridY/rowsPerPage)*PAGE_HEIGHT + offset.y
item.x         = x+left + gapX*gridX + offset.x               // 与现状一致
```

代入当前 `解析素材/select.xml`（layout 900×6300, top=60, bottom=110）：页 0 = 7 行（与红框完全吻合）、char 共 20 页（末页 5 行）、assist 共 2 页（7+6 行）。

## Current State Analysis（工具侧差异点，行号为 select-layout-tool.html）

| 位置 | 现状 | 问题 |
|---|---|---|
| `calcGap` L2279-2285 | gapY=(layout.height-unitSize.y-top-bottom)/(V-1)=44.38 | 整列公式 ❌ 应为按页公式 63.33 |
| `calcItemPos` L2286-2293 | y=startY+gapY*gridY+offset.y | 无按页回绕 ❌ |
| `totalPagesFor` L1827-1830 | ceil(contentExtent/PAGE_HEIGHT)=11 | ❌ 应为 ceil(V/rowsPerPage)=20 |
| `contentExtent` L1817-1826 | 内容底边 | 新模型下废弃（导出表 L3365 同步删） |
| `isOnCurrentPage` L2294-2302 | bottom=min(top+ph, layout.height) | 新世界高=20×600=12000>6300，该钳制会把 6300 以后各页的行错误排除 ❌ |
| `drawItem` OOB L2387 | 垂直比 layout.height | world y>6300 的行全部误报 OUT ❌ |
| `applySpacing` L2904-2907 | offset.y += delta*gridY | 按页回绕下整页块被推出窗口 ❌ 应用 gridY%rowsPerPage |
| `renderGridInfo` L2748-2750 | 垂直 OUT 警告比 layout.height | 判据失效 ❌ |
| `#page-step` L3292-3304 | PAGE_HEIGHT 手动覆盖，初值写死 600 | 游戏为推导值 min(layout.height,600)；加载 XML 后需回写输入框 |
| `解析素材/select.xml` assist_list | row offset y = -433…-5181 | 为旧整列模型调的值；游戏模型下行全部飞出屏幕（游戏内同样坏）❌ |

## Proposed Changes

**文件 1：`选人界面排版工具/select-layout-tool.html`**

1. `calcGap(list)`：按游戏公式重写。`pageH = state.PAGE_HEIGHT`；`usableH = max(pageH-top-bottom, renderSize.h)`；`rowsPerPage = max(1, floor(usableH/renderSize.h))`；`V = max gridY+1`；`displayedVCount = max(1, min(V, rowsPerPage))`；`gapY = displayedVCount>1 ? (pageH-unitSize.y-top-bottom)/(displayedVCount-1) : renderSize.h`，钳 `gapY = max(gapY, renderSize.h)`；返回 `{gapX, gapY, H, V, rowsPerPage, displayedVCount, pageH}`。gapX 不变。
2. `calcItemPos(item, gap)`：`y = startY + gap.gapY*(item.gridY % gap.rowsPerPage) + Math.floor(item.gridY/gap.rowsPerPage)*gap.pageH + item.offset.y`；x 不变。
3. `totalPagesFor(listKey)`：`max(1, ceil(V/rowsPerPage))`（V 取自 list 的 max gridY+1，空列表=1）；删除 `contentExtent` 函数及其在 L3365 导出表中的条目。
4. `isOnCurrentPage(pos)`：`bottom = top + ph`（删除 `layout.height` 钳制）。
5. `drawItem` OOB（L2387）：垂直判据改为页内窗口——`pageIdx = floor(item.gridY/gap.rowsPerPage)`、`localY = tpos.y - pageIdx*pageH`；`out = tpos.x<0 || tpos.x+w>layout.width || localY<0 || localY+h>pageH`。
6. `applySpacing` y 轴：`it.offset.y += delta * (it.gridY % gap.rowsPerPage)`。
7. `renderGridInfo`：垂直 OUT 警告改页内窗口判据；信息行追加 `每页 ${rowsPerPage} 行 · 共 ${totalPages} 页`。
8. PAGE_HEIGHT 推导：`parseXML`/`applyLoadedState` 完成后设 `state.PAGE_HEIGHT = Math.min(layout.height, 600)` 并回写 `#page-step` 输入框值；`#page-step` 保留为预览覆盖（change 时照现有逻辑更新 state.PAGE_HEIGHT，rowsPerPage/gapY/页数经 calcGap/totalPages 自动跟随）。
9. 注释同步：calcGap/calcItemPos/totalPages 处注明权威来源 `SelectFighterStage.as:261-322`。

**文件 2：`选人界面排版工具/解析素材/select.xml` + HTML 内嵌 default-xml**

10. assist_list 所有 `<row offset="x,y">` 的 y 归零（保留 x）；item offset 不动；char_list 已零不动。同步替换 HTML `<script id="default-xml">` 内容（脚本处理，保持缩进）。

**文件 3：verify 脚本语义更新**

11. `verify-pagination.js`：页数语义改 `ceil(V/rowsPerPage)`；`verify-page-switch.js`：页数断言更新（char 20 / assist 2）；`verify-batch-spacing.js`：y 轴增量改 yInPage；`verify-grid-reshape.js`：涉及 gapY/页数的断言更新；其余 verify 全跑对比退出码。

**文件 4：`选人界面排版工具/plan.md`**

12. 追加「修复（2026-10-19b）— 垂直分页对齐游戏内按页模型」章节（根因/公式/ADR/前后对比）。

## Assumptions & Decisions（ADR，grill-with-docs）

| # | 决策 | 理由 |
|---|---|---|
| Q1 | 采用主程序「按页」模型，弃 3.9 整列公式 | 用户要求与游戏内相同；主程序注释明令禁止改回整列公式（SelectFighterStage.as:292-293） |
| Q2 | CELL_SIZE 取 `layout.renderSize`（默认 60×60） | 游戏硬编码 (60,60)；工具 renderSize 承担同一角色，默认值下两者一致 |
| Q3 | assist row offset y 归零 | 该负值为旧整列模型补偿值；游戏模型下游戏内/工具内均离屏，无法「与游戏相同」地保留；归零后 assist=2 页×7+6 行 |
| Q4 | `#page-step` 保留为覆盖项，默认=推导值 | 保留既有功能；默认路径与游戏完全一致 |
| Q5 | 间距 y 轴按 yInPage 施加 | 防止累计增量把整页块推出页窗口；每页自洽 |
| Q6 | 页数/页码记忆（pageView、撤销栈）不改结构 | 恢复路径已有 `Math.min(currentPage, totalPages()-1)` 钳制（applyCanvasSize L1875-1877、loadCurPageView），页数变 20 后自动安全 |

## Verification

1. Node 分析脚本（临时，用完即删）：读 HTML 内嵌 XML → char_list=20 页（19 页×7 行 + 末页 5 行）、assist=2 页（7+6）；每页末行底边 = top+gapY*(rowsPerPage-1)+renderSize.h = 500 ≤ 600（不变量成立，无裁切）。
2. 既有 verify 脚本全量运行：更新后 exit 0；未涉及分页的脚本退出码与改前一致。
3. 浏览器/headless 冒烟：打开工具页 0 仅 7 行（与红框一致）、翻到第 20 页正常、无 JS 报错。
4. 备份：改动前 `.backup/select-layout-tool.html.<ts>`、`.backup/select.xml.<ts>`。

## Risks

| 风险 | 处理 |
|---|---|
| 页数 11→20 后旧撤销快照/页码记忆越界 | 恢复路径已有钳制；验证步骤 2 覆盖 |
| 参考背景图为会话级按页对位，页数变化后需重新对位 | 不写入 XML、无数据损失；在交付说明中提示 |
| verify stub 引用 contentExtent | 步骤 3 删除导出表条目后全量跑 verify 暴露并同步修 |
| 用户已在旧模型下调好的 item offset 视觉位移 | item offset 为自由微调量，游戏同口径叠加，语义不变；仅 row offset 参与模型 |
