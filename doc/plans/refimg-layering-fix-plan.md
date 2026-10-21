# 参考图图层修正计划（定稿）

> grilling 答复：**Q1=C**（透明格自动联动背景显示，不加控件）、**Q2=A**（文本加深色描边）、**Q3=C**（红箭头仅强调，无追加任务）。
> 执行约束：本计划**审批后仅保存在工作区待命**，未经用户另行下达「开工」指令不实施。

## Summary

修正 [select-layout-tool.html](../../选人界面排版工具/select-layout-tool.html) 参考图功能的两个图层问题，单文件改动：

1. **背景图每页显示**：背景坐标语义从「layout 绝对坐标」改为「页内坐标」，每页同一位置重复显示同一张自定义背景图（用户原话需求「每页都要是这个自定背景图」）。
2. **透明格**（Q1=C）：背景图存在且「显示」勾选时，drawItem 跳过深色 `ctx.fill()`，背景图从格子相框（p1.png 透明内部）透出；取消「显示」即恢复深色底。
3. **文本描边**（Q2=A）：透明态下格内所有文本加对比色描边，保证木桌/旧书等浅底上可读。

## Current State Analysis（已核实事实）

| 位置 | 现状 |
|---|---|
| [drawRefBg L1126-1135](../../选人界面排版工具/select-layout-tool.html#L1126-L1135) | 用 `mapToScreen(refBg.x, refBg.y)`；[mapToScreen L875-879](../../选人界面排版工具/select-layout-tool.html#L875-L879) 减 `pageTopY`（=currentPage×pageH，L871-874）→ 背景是 layout 绝对坐标，翻页即移出视口 |
| [drawItem L1395-1431](../../选人界面排版工具/select-layout-tool.html#L1395-L1431) | L1399 `fillStyle = fighterID ? '#152238' : emptyFill` → L1421-1422 `roundRect+fill` → L1424-1429 格子图 clip+drawImage → L1430 stroke。黑底即 `#152238` 透过相框透明内部 |
| 文本 L1435-1460 | fighterID `#cfe0fb`(亮)、`(空)` `#43506b`(暗)、角标 `badge #5b6b88` / `badgeOffset #ffb020` |
| 侧栏 [#seg-ref L443-460](../../选人界面排版工具/select-layout-tool.html#L443-L460) | `bg-show` checkbox 已存在；hint 文案 L457 |
| [render L1506-1523](../../选人界面排版工具/select-layout-tool.html#L1506-L1523) | clearRect → drawRefBg → drawGrid → items，图层顺序无需改 |
| 拖动/滚轮/重置 | mousemove L1573-1579（增量已 /v.scale）、wheel L1616-1619、reset L1148 —— 坐标语义改为页内后**数值逻辑均无需改** |
| [getRefState L2271-2274](../../选人界面排版工具/select-layout-tool.html#L2271-L2274) | 验证 API 入口 |

## Proposed Changes（仅改 select-layout-tool.html）

### 0. 备份（AGENTS.md 硬规则 4）
复制为 `.backup/select-layout-tool.html.<YYYY-MM-DD-HHMM>` 后再动手。

### 1. drawRefBg 改页内坐标（每页显示）
不再经 `mapToScreen`（避开 pageTopY 减法），直接页内→屏幕：

```js
function drawRefBg() {
  if (!refBg.img || !refBg.visible || !state.viewport) return;
  const v = state.viewport;
  const w = refBg.img.width * refBg.scale, h = refBg.img.height * refBg.scale;
  const sx = refBg.x * v.scale + v.offX, sy = refBg.y * v.scale + v.offY + slide.dy;
  ctx.save();
  ctx.globalAlpha = refBg.alpha;
  ctx.drawImage(refBg.img, sx, sy, w * v.scale, h * v.scale);
  ctx.restore();
}
```

- refBg.x/y 语义=页内偏移；拖动（已 /v.scale）、滚轮、重置按钮逻辑不变。
- 保留 `slide.dy` 与翻页滑动动画一致。

### 2. 透明格（Q1=C 自动联动）
drawItem 内：

```js
const transparentCells = !!(refBg.img && refBg.visible);
```

- L1421-1422 改为：`roundRect(s.x, s.y, sw, sh, 5); if (!transparentCells) ctx.fill();`
  （roundRect 路径保留——格子图 clip 与 stroke 依赖它；仅跳过 fill）。
- hover/拖拽 shadow、stroke、越界虚线逻辑全部不动。
- 取消「显示」或无背景图时 `transparentCells=false`，恢复深色底（正常编辑可读性）。

### 3. 文本对比描边（Q2=A，仅透明态生效）
新增小助手（drawItem 前）：

```js
function outlinedText(txt, x, y, fill, outline) {
  ctx.save();
  ctx.lineJoin = 'round'; ctx.miterLimit = 2;
  ctx.strokeStyle = outline; ctx.lineWidth = Math.max(2, Math.round(3 * (state.viewport ? state.viewport.scale : 1)));
  ctx.strokeText(txt, x, y);
  ctx.fillStyle = fill; ctx.fillText(txt, x, y);
  ctx.restore();
}
```

透明态下替换 4 处 fillText（非透明态保持原样，零视觉变化）：
| 分支 | fill | outline |
|---|---|---|
| fighterID (L1436-1441) | `#cfe0fb` | `rgba(12,16,26,0.9)` 深 |
| (空) (L1443-1447) | `#43506b` | `rgba(240,246,255,0.85)` 浅 |
| 网格角标 (L1451-1455) | `#5b6b88` | 浅 |
| offset 角标 (L1458-1460) | `#ffb020`/`#5b6b88` | 亮色→深、暗色→浅（按现 fillStyle 二选一） |

### 4. getRefState 增字段
bg 对象加 `perPage: true`；顶层加 `transparentCells`，供浏览器实测断言。

### 5. hint 文案（L457）
追加一句：「背景每页重复显示；背景显示期间格子底色自动透明以透出背景图。」

## Assumptions & Decisions
- Q1=C：不新增 checkbox；透明态 = 有背景图 ∧ bg-show 勾选。会话级、不写 XML（与参考图设计一致）。
- Q2=A：描边硬编码每分支颜色，不做亮度自动检测（避免过度工程）。
- Q3=C：不追加格子图宽高比/裁切任务。
- verify 脚本无需改期望（stub 不断言 fill/文本像素），verify.js 的 `vm.Script` 语法检查覆盖新代码。

## Verification Steps（实施后）
1. 12 个 verify 脚本全绿（`node verify.js` 等，fail count = 0）。
2. 浏览器实测（node 静态服务器 + browser 代理，或 file:// 直开）：
   - 默认加载：格子内部透出木桌背景（非 #152238）；文本带描边可读；
   - 翻到第 2/3 页：背景同位置出现（每页重复）；
   - 取消「显示」：恢复深色底；再勾选恢复透明；
   - 「调整」模式拖动/滚轮后翻页：背景位置/缩放每页一致；重置按钮归零；
   - `__layoutTool.getRefState().transparentCells` 随开关翻转；控制台零错误。
3. 汇报后**待命**，不主动做范围外改动。

## 执行节奏（用户指定）
审批通过 → 计划留存工作区 → **等待用户后续「开工」指令才实施**。
