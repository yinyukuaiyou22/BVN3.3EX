# Plan: 选人界面排版工具 — 单文件 HTML Demo

## Goal

实现一个浏览器端纯前端 demo：导入或内嵌 `select.xml` → 在 Canvas 上模拟 3.9 模式游戏内排版 → 拖动 / 侧边栏编辑修改 `item.offset` → 导出回 `select.xml`。用于排版时可视化预演，无需编译游戏即可调位置。

## Architecture

- **单文件 SPA**：`select-layout-tool.html`（内联 CSS + JS + 默认 xml 数据）
- **零依赖**：纯原生 JS + Canvas 2D + DOM File API + Blob
- **无服务端**：双击 .html 即可用
- **数据流单向**：state → render → mouse/keyboard → state → render；导出 = state → XML string
- **与 AS3 项目零耦合**：不导入任何 AS3 模块；只读 `select.xml` 的格式约定

## Tech Stack

| 项 | 选型 |
|---|---|
| 语言 | 原生 JavaScript (ES2017+) |
| 渲染 | Canvas 2D |
| 样式 | 原生 CSS（Grid + Flexbox） |
| 文件 IO | `FileReader`（导入）+ `Blob` + `<a download>`（导出） |
| XML 解析 | `DOMParser` |
| XML 序列化 | 手写（与 select.xml 当前缩进风格一致，tab 缩进） |
| 状态管理 | 单个 `state` 对象 + 不可变快照数组（撤销栈） |
| 测试 | 浏览器手动 + 控制台日志 + 导出 xml 文本人工对照 |

## Baseline/Authority Refs

- `tools/Test/assets/config/select.xml` — 内嵌默认数据（14 行 char_list + 10 行 assist_list）
- `BVNscripts/现代参考3.9/CORE_KernelLogic/src/net/play5d/game/bvn/data/vos/SelectStageConfigVO.as` 行 458-467 — 3.9 模式 `gapX/gapY` 自适应公式
- `BVNscripts/现代参考3.9/CORE_KernelLogic/src/net/play5d/game/bvn/stage/SelectFighterStage.as` 行 453-501 — `buildList` 完整逻辑
- `BVNscripts/现代参考3.9/CORE_KernelLogic/src/net/play5d/game/bvn/data/vos/SelectCharListItemVO.as` — `moreFighter` 字段（**demo 不实现**，Q15）

## Compatibility Boundary

- **不修改任何 BVNscripts/ 下的 AS3 代码**
- **不修改 select.xml 本身**（demo 只读写，不持久化）
- **不修改 tools/Test/ 任何内容**
- **唯一新增**：`选人界面排版工具/select-layout-tool.html` 单文件
- **可独立分发**：HTML 文件 + 用户提供的 select.xml，不依赖其他资源

## TDD Route

```text
TDD Route:
- Mode: off
- Decision: skipped
- Strict authority: not applicable
- Strict signals: none (single-file UI demo, no shared core, no contract)
- Light eligibility: tiny single-owner, no behavior change to existing system
- TDD-fit exception: vanilla JS UI demo, no test harness
- Test posture: post-change manual verification
- Reason: User asked for "simple pure front-end demo", no project test infrastructure exists for HTML5 demos
- Verification: browser open HTML → render shows embedded xml → drag changes offset → export downloads valid xml matching import format
```

## Verification

| 维度 | 验证方式 |
|---|---|
| 默认数据加载 | 打开 HTML，14 行 char_list + 10 行 assist_list 全部渲染为 60×60 圆角矩形 + 角色 ID |
| 拖动 | mousedown 任意 item → 拖动 → 鼠标位置变化跟随；mouseup 后 item 位置固定 |
| 选中态 | 点击 item 红色高亮 + 侧边栏段 2 填充该 item 数据 |
| 方向键微调 | 选中 item 后，焦点在侧边栏按方向键 → offset 实时变化 |
| Shift+方向键 | offset 变化 10px |
| 单元大小 | 改 W/H → 画布所有 item 立即按新尺寸重绘 |
| 撤销/重做 | 改 21 次 → Ctrl+Z 20 次回到起点；Ctrl+Shift+Z 重做 5 次 |
| 越界 | 拖动 item 超过 GAME_SIZE → 虚线轮廓 + "OUT" 角标 |
| 导出 | 点导出 → 下载 select.xml，结构与原文件完全一致，offset 数值已更新 |
| 导入 | 点导入 → 选新 xml → 画布重建；可与导出文件互逆验证 |
| 错误处理 | 导入无效 xml → 顶部红条显示错误信息，3 秒消失 |
| 列表概览 | 切换 char_list / assist_list → 卡片网格更新；点击卡片 → 画布选中对应 item |
| 性能 | 60 个 item 拖动时 ≥50 FPS（DevTools Performance 面板） |

---

## Files

**Create**:
- `E:\BaiduNetdiskDownload\BVNY\选人界面排版工具\select-layout-tool.html` — 单文件 demo

**Modify**: 无

**Test**: 手动浏览器验证（无需自动化测试）

---

## Tasks (7 个，每个 2-5 分钟)

### Task 1 — 骨架 + 顶部栏 + 默认数据

**Files**: `选人界面排版工具/select-layout-tool.html` (create)

**Why**: 建立文件骨架 + 顶部工具栏 + 嵌入默认 xml 数据，让用户开箱即用

**Change Necessity**: 新建单文件；最小边界 = 一个 HTML 文件

**Steps**:

1. 创建文件，写入 `<!DOCTYPE html>` + `<html lang="zh">` + 标题 `选人界面排版工具`
2. 内嵌 `<style>` CSS Grid 布局：`grid-template-columns: 1fr 360px; grid-template-rows: 48px 1fr;` 四象限
3. 内嵌 `<script type="application/xml" id="default-xml">` 完整 `select.xml`（从 `tools/Test/assets/config/select.xml` 复制粘贴，去掉外部注释）
4. 顶部工具栏（48px 高）：
   - `[导入 XML]` button
   - `[导出 XML]` button
   - `<select id="mode">` 含 `3.9模式（推荐）` 选项（**只有 3.9**，Q2 决定）
   - `<label><input type="checkbox" id="paged">分页模式（PAGE_HEIGHT=600）</label>`
   - `<input type="range" id="zoom" min="50" max="300" value="100">` 缩放
   - `<span id="cursor-coord">坐标: -, -</span>` 实时坐标
5. 留空主体（主画布 + 侧边栏 div 占位）

**Verification**: 浏览器打开 → 看到顶部栏 + 两个空 div，无报错

---

### Task 2 — 状态对象 + 解析默认数据

**Files**: 同上

**Why**: 数据流核心；所有渲染/编辑依赖此 state

**Steps**:

1. 定义 `const DEFAULT_XML_TEXT = document.getElementById('default-xml').textContent;`
2. 写 `parseXML(text)` 函数：
   ```js
   function parseXML(text) {
     const doc = new DOMParser().parseFromString(text, 'text/xml');
     if (doc.querySelector('parsererror')) throw new Error('XML 解析错误');
     const layout = doc.querySelector('stage_setting > layout');
     const state = {
       layout: {
         x: +layout.getAttribute('x') || 0,
         y: +layout.getAttribute('y') || 0,
         width: +layout.getAttribute('width') || 800,
         height: +layout.getAttribute('height') || 600,
         left: +layout.getAttribute('left') || 0,
         right: +layout.getAttribute('right') || 0,
         top: +layout.getAttribute('top') || 0,
         bottom: +layout.getAttribute('bottom') || 0,
         unitSize: { x: 50, y: 50 },        // 3.9 默认
         renderSize: { w: 60, h: 60 },       // 渲染尺寸（Q8 决定，初始 60×60）
       },
       charList: parseList(doc.querySelector('char_list')),
       assistList: parseList(doc.querySelector('assist_list')),
       currentList: 'charList',
       selectedKey: null,                    // "x,y" 字符串
     };
     return state;
   }
   ```
3. 写 `parseList(xmlList)`：
   ```js
   function parseList(node) {
     if (!node) return [];
     const items = [];
     let rowIdx = 0;
     for (const row of node.children) {
       if (row.tagName !== 'row') continue;
       const rowOff = parseOffset(row.getAttribute('offset'));
       let colIdx = 0;
       for (const item of row.children) {
         if (item.tagName !== 'item') continue;
         const itemOff = parseOffset(item.getAttribute('offset'));
         const merged = {
           x: rowOff.x + (itemOff?.x || 0),
           y: rowOff.y + (itemOff?.y || 0),
         };
         items.push({
           gridX: colIdx, gridY: rowIdx,
           fighterID: (item.textContent || '').trim() || null,
           offset: { x: merged.x, y: merged.y },
           listKey: null,    // 运行时填
         });
         colIdx++;
       }
       rowIdx++;
     }
     items.forEach((it, i) => { it.listKey = `${it.gridX},${it.gridY}`; });
     return items;
   }
   ```
4. 写 `parseOffset(str)`：split(',') → `{ x: +a, y: +b }`，空返 `{x:0,y:0}`
5. 初始化 `state = parseXML(DEFAULT_XML_TEXT)`，console.log 出来人工核对

**Verification**: 控制台看到 state.layout = `{x:0, y:0, width:800, ...}`，state.charList.length === 60（14+10 行 × 4 列 = 96 中前 14+10 中有的角色）

---

### Task 3 — Canvas 渲染 + 3.9 排版公式

**Files**: 同上

**Why**: 模拟游戏内排版是 demo 的核心

**Steps**:

1. HTML 中加 `<canvas id="canvas" width="800" height="600">`
2. JS 拿 ctx，定义 `render()`：
   ```js
   function render() {
     const ctx = canvas.getContext('2d');
     ctx.clearRect(0, 0, 800, 600);
     drawGrid(ctx);
     drawLayoutBounds(ctx);
     const items = state.currentList === 'charList' ? state.charList : state.assistList;
     items.forEach(it => drawItem(ctx, it));
     if (state.selectedKey) drawSelection(ctx, items.find(i => i.listKey === state.selectedKey));
   }
   ```
3. `drawGrid(ctx)` — 画 25px 浅灰网格（仅 `0xeeeeee` 描边）
4. `drawLayoutBounds(ctx)` — 根据 `state.layout` 画红色虚线框表示 layout 范围
5. `calcGap(list)` — **3.9 模式公式**：
   ```js
   function calcGap(list) {
     const H = Math.max(...list.map(i => i.gridX + 1));
     const V = Math.max(...list.map(i => i.gridY + 1));
     const gapX = H > 1 ? (state.layout.width - state.layout.unitSize.x - state.layout.left - state.layout.right) / (H - 1) : 0;
     const gapY = V > 1 ? (state.layout.height - state.layout.unitSize.y - state.layout.top - state.layout.bottom) / (V - 1) : 0;
     return { gapX, gapY, H, V };
   }
   ```
6. `calcItemPos(item, gap)` — **3.9 落点公式**：
   ```js
   function calcItemPos(item, gap) {
     const startX = state.layout.x + state.layout.left;
     const startY = state.layout.y + state.layout.top;
     const x = startX + gap.gapX * item.gridX + item.offset.x;
     const y = startY + gap.gapY * item.gridY + item.offset.y;
     return { x, y };
   }
   ```
7. `drawItem(ctx, item)` — 60×60 圆角矩形（`renderSize.w/h`）+ 角色 ID 文字（10px 居中）+ 网格坐标 `(gridX, gridY)` 角标
8. 越界检测：`if (x + w > 800 || y + h > 600 || x < 0 || y < 0) drawOutOfBounds(ctx, item, x, y)` — 虚线轮廓 + "OUT" 文字
9. 首次调用 `render()` 验证画布显示

**Verification**: 打开 HTML → 看到所有 item 按 3.9 公式排列，圆角矩形 + 文字

---

### Task 4 — 鼠标交互：选中 + 拖动

**Files**: 同上

**Why**: 拖动是核心编辑方式（Q3）

**Steps**:

1. 命中测试 `hitTest(mx, my)`：遍历当前 list，遍历每个 item 的 `calcItemPos` + 60×60 矩形，返回命中的 item
2. `canvas.addEventListener('mousedown', e => { ... })`：
   - 计算 canvas 内坐标：`(e.offsetX, e.offsetY)`（CSS 缩放不影响 `offsetX/Y` — 它们始终是画布内坐标）
   - hitTest 命中 → `state.selectedKey = item.listKey; dragState = { item, startX, startY, origOffset: {...item.offset} }`
   - pushUndoSnapshot() — **拖动合并为一步**（Q13）
3. `canvas.addEventListener('mousemove', e => { ... })`：
   - 若 `dragState` 存在 → 算新 offset：
     ```js
     const dx = (e.offsetX / scale) - dragState.startX;
     const dy = (e.offsetY / scale) - dragState.startY;
     dragState.item.offset = {
       x: dragState.origOffset.x + dx,
       y: dragState.origOffset.y + dy,
     };
     scheduleRender();  // requestAnimationFrame 节流
     ```
4. `canvas.addEventListener('mouseup', () => { dragState = null; })` — 不再入栈（已在 mousedown 入过）
5. `canvas.addEventListener('mousemove', e => { document.getElementById('cursor-coord').textContent = `坐标: ${e.offsetX}, ${e.offsetY}`; })` — 实时坐标（Q25）
6. 缩放联动（Q24 — 鼠标光标位置为中心）：
   - 监听 `id="zoom"` 的 input；缩放时不能简单改 `canvas.style.width/height`（CSS transform 缩放更优）
   - 用 `canvas.style.transformOrigin` + `transform: scale(s)`，保持画布内部坐标系不变
   - 缩放时以鼠标光标位置为缩放中心 — 但因 canvas 内部坐标系固定 800×600（**不随缩放变**，所有坐标计算都用原始坐标），缩放中心只需让光标在视觉上保持原位
   - **实现**：用 CSS `transform: scale(s)` + 调整 canvas 的 margin/left 偏移使光标在屏幕坐标固定
     ```js
     function applyZoom(newScale, mouseX, mouseY) {
       // mouseX/mouseY 是画布内坐标（offsetX/offsetY）
       // 用 transform-origin: top left + translate 补偿
       const oldScale = canvasScale;
       canvas.style.transform = `scale(${newScale})`;
       canvas.style.transformOrigin = '0 0';
       // 让 (mouseX, mouseY) 在屏幕上保持原位
       const dx = (mouseX * newScale) - (mouseX * oldScale);
       const dy = (mouseY * newScale) - (mouseY * oldScale);
       canvas.style.left = (parseFloat(canvas.style.left || '0') - dx) + 'px';
       canvas.style.top = (parseFloat(canvas.style.top || '0') - dy) + 'px';
       canvasScale = newScale;
     }
     ```
   - 滚轮事件额外支持：监听 `canvas.addEventListener('wheel', e => { e.preventDefault(); applyZoom(currentScale + e.deltaY * -0.001, e.offsetX, e.offsetY); })`
   - 所有命中测试/拖动仍用 canvas 内坐标 (offsetX, offsetY)，不受 CSS 缩放影响

**Verification**: 拖动 item → 实时跟随；松开后位置固定；坐标显示更新

---

### Task 5 — 侧边栏 4 段

**Files**: 同上

**Why**: 侧边栏是数据编辑入口（Q5-Q11）

**Steps**:

1. HTML 加 `<aside id="sidebar">` 4 段：
   ```html
   <section id="seg-layout">
     <h3>网格布局</h3>
     <label>x <input type="number" id="lx"></label>
     <label>y <input type="number" id="ly"></label>
     ...
     <label>unitW <input type="number" id="uw"></label>
     <label>unitH <input type="number" id="uh"></label>
     <label>renderW <input type="number" id="rw"></label>
     <label>renderH <input type="number" id="rh"></label>
   </section>
   <section id="seg-item">
     <h3>选中 item</h3>
     <span id="sel-id"></span>
     <span id="sel-grid"></span>
     <label>offsetX <input type="number" id="ox"></label>
     <label>offsetY <input type="number" id="oy"></label>
     <button id="up">↑</button><button id="down">↓</button>
     <button id="left">←</button><button id="right">→</button>
     <button id="reset">重置 offset=0,0</button>
   </section>
   <section id="seg-list">
     <h3>列表概览</h3>
     <select id="list-sel"><option value="charList">char_list</option><option value="assistList">assist_list</option></select>
     <div id="cards"></div>
   </section>
   <section id="seg-log">
     <h3>操作日志</h3>
     <div id="log"></div>
   </section>
   ```
2. JS 写 `bindSegmentLayout()`：每个 input 的 `oninput` 改 `state.layout.*` + scheduleRender + pushUndoSnapshot (100ms 节流)
3. JS 写 `bindSegmentItem()`：
   - offset 字段 `oninput` → `state.item.offset` + scheduleRender
   - 4 微调按钮 click → `step = e.shiftKey ? 10 : 1`，按方向改 offset
   - **关键**：input/button `onkeydown` 监听方向键 → 同样微调（Q11 焦点绑定，**canvas 永不吃方向键**）
   - 重置按钮 → `item.offset = {x:0, y:0}`
   - `e.preventDefault()` 屏蔽浏览器默认行为（Q12 补充）
4. JS 写 `bindSegmentList()`：
   - 切换 select → `state.currentList` + scheduleRender + 重建卡片
   - 卡片是 `<button>` 列表（60×24 文字），`onclick` → `state.selectedKey = item.listKey; renderSegmentItem(); scheduleRender();`
5. JS 写 `renderSegmentItem()`：根据 `state.selectedKey` 填字段或灰显
6. JS 写 `log(text)`：往 `#log` 推一行，max 100 行

**Verification**: 改 layout 字段 → 画布实时变；选中 item → 段 2 显示数据；方向键微调生效；Shift+方向键 10px

---

### Task 6 — 撤销 / 重做 + 键盘快捷键

**Files**: 同上

**Why**: 20 步撤销是 Q12 决定

**Steps**:

1. 定义：
   ```js
   const undoStack = [];
   const redoStack = [];
   const MAX_UNDO = 20;
   function snapshot() { return JSON.parse(JSON.stringify(state)); }
   function pushUndoSnap() { undoStack.push(snapshot()); if (undoStack.length > MAX_UNDO) undoStack.shift(); redoStack.length = 0; }
   ```
2. 把 Task 4 mousedown / Task 5 各 oninput 结尾改成调 `pushUndoSnap()`，**oninput 用 100ms 节流**（一个拖动期间最多入栈 1 次）
3. 全局 `window.addEventListener('keydown', e => { ... })`：
   ```js
   if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) {
     e.preventDefault();
     if (undoStack.length === 0) return;
     redoStack.push(snapshot());
     Object.assign(state, undoStack.pop());
     render(); renderSegmentItem();
   } else if ((e.ctrlKey || e.metaKey) && (e.key === 'Z' || (e.shiftKey && e.key === 'z'))) {
     e.preventDefault();
     if (redoStack.length === 0) return;
     undoStack.push(snapshot());
     Object.assign(state, redoStack.pop());
     render(); renderSegmentItem();
   } else if ((e.ctrlKey || e.metaKey) && e.key === 's') {
     e.preventDefault();
     exportXML();
   } else if (e.key === 'Escape') {
     state.selectedKey = null;
     render(); renderSegmentItem();
   } else if ((e.key === 'Delete' || e.key === 'Backspace') && state.selectedKey) {
     // 仅当焦点在 body 而非 input
     if (document.activeElement.tagName !== 'INPUT') {
       e.preventDefault();
       const item = findSelectedItem();
       if (item) { pushUndoSnap(); item.fighterID = null; render(); log('清空 fighterID'); }
     }
   }
   ```
4. 拖动 mousedown 入栈一次；mousemove 不入栈；mouseup 不入栈（**Q13 拖动合并**）

**Verification**: 改 21 次 → Ctrl+Z 20 次回起点；Ctrl+Shift+Z 重做 5 次；Ctrl+S 触发导出

---

### Task 7 — 导入 / 导出 / 错误条

**Files**: 同上

**Why**: demo 闭环 — 改完能保存

**Steps**:

1. `exportXML()`：
   ```js
   function exportXML() {
     const text = serializeXML();
     const blob = new Blob([text], { type: 'application/xml' });
     const a = document.createElement('a');
     a.href = URL.createObjectURL(blob);
     a.download = 'select.xml';
     a.click();
     URL.revokeObjectURL(a.href);
     log('导出 select.xml');
   }
   ```
2. `serializeXML()` 手写（与 select.xml 当前风格一致，tab 缩进）：
   ```js
   function serializeXML() {
     const lines = [];
     lines.push('<!-- Generated by select-layout-tool @ ' + new Date().toISOString() + ' -->');
     lines.push('<select_config>');
     lines.push('\t<stage_setting>');
     const l = state.layout;
     lines.push(`\t\t<layout x="${l.x}" y="${l.y}" width="${l.width}" height="${l.height}" left="${l.left}" right="${l.right}" top="${l.top}" bottom="${l.bottom}"/>`);
     lines.push('\t</stage_setting>');
     lines.push('');
     lines.push(serializeList('char_list', state.charList));
     lines.push('');
     lines.push(serializeList('assist_list', state.assistList));
     lines.push('</select_config>');
     return lines.join('\n');
   }
   ```
3. `serializeList(name, items)` — 按 `gridY` 分组 row，每个 row 内 4 个 item（同 row 内 gridX 一定连续 0-3）；还原 row offset = `rowOffset = items[0].offset`，item offset = `items[i].offset - rowOffset`
4. `importXML()`：`<input type="file" id="file-input" accept=".xml" style="display:none">` + 按钮触发 + `FileReader` 读 text + `parseXML` + 替换 state + render + log
5. 错误条：`<div id="error-bar" style="display:none">` + 3 秒自动消失；任何 `throw new Error()` 的地方 try/catch 显示

**Verification**: 导出文件用文本编辑器打开，结构与原 select.xml 一致；offset 数值已更新；导入新文件画布重建；故意改坏 xml 看到红条

---

## Self-Review

| 检查 | 状态 |
|---|---|
| Spec coverage (Q1-Q26) | ✅ Task 1-7 覆盖所有需求（含 Q24 鼠标中心缩放更新） |
| Placeholder scan | ✅ 无 TBD/TODO |
| Type consistency | ✅ state 单一对象；item list key 始终是 string |
| Compatibility | ✅ 不修改 BVNscripts/tools/Test |
| Change necessity | ✅ 唯一新文件 |
| Existence check | ✅ 新工具无重叠 |
| Plan-time complexity | ✅ 单文件 ~700 行 |
| Architecture integrity | ✅ 单 owner 无 overlap |
| Verification | ✅ 浏览器手动验证清单 |
| Dual-track / ADR | N/A（demo 无架构决策） |
| 延期项 | Q22 多选 / Q23 对齐工具 → 留作后续扩展（注释标记） |

## Risks

| 风险 | 缓解 |
|---|---|
| 单文件 ~700 行可能臃肿 | Demo 阶段可接受；后续若需扩展再拆分 |
| 手写 XML 序列化可能与原文件字节级不同 | 风格对齐（tab 缩进）即可；语义正确性优先 |
| 跨浏览器 Canvas 文本测量差异 | 用 `ctx.font` + `measureText`；只在 Chrome/Edge/Firefox 验证 |
| 撤销栈 JSON 深拷贝性能 | 60 个 item × 几个字段 << 1ms，无瓶颈 |

## Retirement

N/A（新增 demo，无旧逻辑要退役）

---

## 追加功能（2026-10-09）— 行列数量：每行 / 每列实时重排

### 需求

> 把修改每行和每列的数量增加上，输入后会实时改变行数列数，多出来的列变成行。

### 设计

- **入口**：侧边栏新增 `#seg-grid`「行列数量（当前列表）」，位于「网格布局 (layout)」下方
  - `#grid-cols`「每行」= 每行放几个 = **列数**（HCount）
  - `#grid-rows`「每列」= 每列放几个 = **行数**（VCount）
  - `#grid-info` 信息行：`char_list · 56 格 → 8 列 × 7 行 · 列距 47.9 / 行距 66.7`，重叠/出界时追加红字警告
  - `#grid-zero-offset`（默认勾选）：重排时把 `item.offset` 归零，得到干净的自适应网格；取消勾选则保留各 item 原 offset
- **作用域**：只作用于**当前列表**；char_list 与 assist_list 的形状互相独立，列表在下方「列表概览」切换
- **算法**（`reshapeList`）：按「行优先」读出全部格子（`sort by (gridY, gridX)`，原下标兜底保证稳定排序），第 k 个 → `(k % cols, floor(k / cols))`
  - 列数变少 → 原来靠右的列自然折成下面的新行（**多出来的列变成行**）
  - `rows = ceil(N / cols)`，末行可以不满（56 格 / 3 列 → 末行 2 格）
- **两个输入框互为反函数**：改「每行」→ `rows = ceil(N/cols)`；改「每列」→ `cols = ceil(N/rows)`。
  N=56 时：4 列↔14 行、3 列↔19 行、8 列↔7 行、12 列↔5 行。从任一轴都能驱动形状，且**往返稳定**（4→3→5→4 回到原排布，逐格比对一致）
- **实时性**：`input` 事件即刻重排 + 重绘，另一侧输入框同步派生值；`change`（失焦 / 回车）回填真实值
- **容错**：空 / 非数字输入本次不动画布；被夹到 `[1, min(99, N)]` 时才回写（不打断连续输入）
- **不可达值回写**：「每列」输入的值不一定可达（56 格输入每列 9 → `cols=ceil(56/9)=7` → 实际只能 8 行）。
  此时把真实行数回写给输入框并在日志注明「每列 N 装不满，取最接近的 M 行」，避免输入框与信息行各说各话；可达值（如每列 6 → 10 列 × 6 行）保持用户输入不变
- **联动**：撤销重做（100ms 节流把连续输入合并成一步）、列表切换、导入 XML、`setState`、选中态（`selectedKey` 按对象本体跨重排跟随，不会跳格）
- **导出**：`serializeList` 按 gridY 分组 → 重排后的形状可直接导出并回读一致

### 代码位置（`select-layout-tool.html`）

| 符号 | 作用 |
|---|---|
| `#seg-grid` 面板 | 每行 / 每列输入 + 信息行 + offset 选项 |
| `currentItems()` / `setCurrentItems()` | 当前列表读写 |
| `gridCounts(list)` | 返回 `{N, H, V}` |
| `reshapeList(list, cols, {zeroOffset})` | 行优先重排，返回按网格顺序的新数组 |
| `renderGridInfo(list, N, H, V)` | 信息行 + 重叠 / 出界警告 |
| `renderSegmentGrid({force})` | 回填输入框 + 信息行 |
| `applyGridCount(which)` | `input` 事件主入口（校验 → 重排 → 联动） |
| `bindSegmentGrid()` | 事件绑定 |

### 验证

- `node 选人界面排版工具/verify-grid-reshape.js` → **77 项断言全部通过**（stub DOM + 真实事件派发，覆盖重排 / 反函数 / 往返 / 不可达回写 / 容错 / 撤销 / 列表隔离 / 导出回读 / 选中跟随）
- 真实浏览器（Edge headless，`--dump-dom` + `--screenshot`）：`errors: 0`，四个用例实测
  | 输入 | 输入框变为 | 网格 | 关键断言 |
  |---|---|---|---|
  | 每行 3 | 3 / 19 | 3 列 × 19 行 | `上海人偶` 由 `(3,0)` → `(0,1)`；`若鹭姬` 仍在 `(2,0)`；offset 全归零 |
  | 每行 8 | 8 / 7 | 8 列 × 7 行 | 56 格恰好铺满 8×7 |
  | 每列 9 | 7 / 8 | 7 列 × 8 行 | 9 行不可达 → 输入框回写 8，与信息行一致 |
  | 每列 6 | 10 / 6 | 10 列 × 6 行 | 正好对齐游戏一页 6 行 |
- 截图证据：`.backup/preview-before-4x14.png`、`.backup/preview-reshape-8x7.png`、`.backup/preview-reshape-3x19.png`、`.backup/preview-reshape-10x6.png`
- 顶栏清理后复测：77 项断言仍全通过；headless 探针 `errors=0`、`模式：3.9 自由网格` 徽标在位；被删的两个 id 全文件已无引用
- 既有脚本回归：9 个 `verify*.js` 改动前后退出码完全一致（其中 5 个失败项是既有 stub 陈旧问题，与本次无关）

### 模式决策（2026-10-09）：只保留 3.9 自由网格

用户决定：**工具只做 3.9 样式排版这一种模式**，主程序的行分页变体不建模（理由：主程序也是和 3.9 样式类似的）。

逐项比对 3.9 权威源码后确认，工具现有实现**已经是 3.9 原样**，无需改动模型：

| 项 | 3.9 权威 | 工具实现 |
|---|---|---|
| 起点 | `startX = x + left`、`startY = y + top` | `calcItemPos` ✅ |
| 列距 | `gapX = (width - unitSize.x - left - right) / (HCount - 1)` | `calcGap` ✅ |
| 行距 | `gapY = (height - unitSize.y - top - bottom) / (VCount - 1)`（**全表行数**） | `calcGap` ✅ |
| 落点 | `tx = startX + gapX*x + offset.x`、`ty = startY + gapY*y + offset.y`（**无分页偏移**） | `calcItemPos` ✅ |
| `unitSize` | `(50,50)`（`SelectStageConfigVO.as:46`） | `layout.unitSize` 默认 `(50,50)` ✅ |
| offset | row offset **加上** item offset（`SelectStageConfigVO.as:101-112`） | `parseList` ✅ |
| `HCount` / `VCount` | 最大行宽 / `<row>` 数量（`:71`、`:84-86`） | `gridCounts` ✅ |
| fighterID | 3.9 用 `item.toString()`（旧 bug，会把整段 XML 当 ID） | 用 `.text()`/`textContent`（主程序批次 6.6 的修复版，**有意保留修复**） |

- 唯一权威：`BVNscripts/现代参考3.9/CORE_KernelLogic/src/net/play5d/game/bvn/stage/SelectFighterStage.as:453-501` + `.../data/vos/SelectStageConfigVO.as:46,68-123`
- **明确不建模**：主程序 `BVNscripts/scripts/.../SelectFighterStage.as:252-268` 的 `rowsPerPage = 6` / `displayedVCount = min(VCount, rowsPerPage)` / 行分页。因此「每列 > 6」时工具预览会行重叠（信息行已给红字警告），要看分页效果请以主程序为准。
- 顶栏同时清掉两个**断线控件**：「模式下拉（只有一个 3.9 选项）」与「分页（PAGE_HEIGHT=600）复选框」——两者都没有任何 JS 接线，纯装饰；现在只留一个静态徽标「模式：3.9 自由网格」，翻页步高由 `#page-step` 输入框负责。
- 遗留待定：顶栏「缩放」滑块同样是断线的（`input` 里直接回写 100，viewport 模式自动等比缩放），本次未动。

---

## 追加功能（2026-10-10）— 拖拽覆盖导入 + 批量行/列选择移动 + 格子间距

### 需求

1. 拖拽 `select.xml` 到页面自动识别并覆盖当前显示的 XML；非默认实例且已修改未导出时先确认。
2. 修饰键批量选择整行/整列并整体移动（鼠标 + 键盘均可）。
3. 修改格子之间上下左右间距，用 offset 算（水平/垂直两轴，作用于当前列表）。

### 设计

- **拖拽覆盖导入**：`window` 级 `dragenter/dragover/dragleave/drop/dragend`（`dragDepth` 计数消抖），`#drop-overlay` 半透明遮罩；`handleDroppedFile` 校验 `.xml`/`select.xml` → `parseXML` → `needsConfirmOverwrite()` 为真则弹 `#overwrite-modal` 确认。`importXML` 与拖拽共用 `applyLoadedState`。
  - 状态：`isDefaultInstance`（来源是否内嵌默认）、`dirty`（自上次加载/导出后有无未导出改动）；`markDirty()` 埋在所有「会导出」的改动点（拖动/layout/重排/item offset/清空）；`exportXML` 成功后清 `dirty`。
  - 确认谓词 `needsConfirmOverwrite() = !isDefaultInstance && dirty`。
- **批量行/列选择**：`Ctrl+点击 = 整列`、`Alt+点击 = 整行`、普通点击 = 单选；状态字段 `selectedRow/selectedCol` 与 `selectedKey` 互斥。`getSelectedItems()` 统一取选中格数组（单选退化为 `[it]`）。拖动 `dragState.items` 整组同步位移；顶层 `nudge()` 对整组做方向键/箭头按钮微调；窗口方向键在存在整组选中且焦点不在表单控件时改为移动整组（`PageUp/Down/Home/End/滚轮` 仍翻页）。
- **格子间距**：`state.spacingDelta = { charList:{x,y}, assistList:{x,y} }` 记录累计增量；`#gap-x/#gap-y` 显示「自适应间距 + 增量」，`applySpacing` 按 `offset += Δ×gridX/gridY` 均匀施加到当前列表；重排「清零 offset」时同步归零该列表 `spacingDelta`。
- 三者均入 `snapshot()`（`selectedRow/selectedCol/spacingDelta` 已纳入），撤销/重做可正确回退。

### 代码位置（`select-layout-tool.html`）

| 符号 | 作用 |
|---|---|
| `isDefaultInstance/dirty/pendingDrop/dragDepth` | 拖拽覆盖状态 |
| `markDirty/needsConfirmOverwrite/applyLoadedState/handleDroppedFile/commitPendingDrop/cancelPendingDrop` | 脏标记与覆盖确认 |
| `bindDragDrop/bindOverwriteModal` | 拖拽 + 确认框事件绑定 |
| `getSelectedItems/isItemSelected/selectCol/selectRow/selectItem/clearSelection` | 整组选择 |
| `nudge`（顶层） | 整组微调（单选退化为单个） |
| `renderSegmentSpacing/applySpacing/bindSegmentSpacing` | 格子间距（offset 均匀增量） |
| `#seg-spacing` 面板 | 水平/垂直间距输入 + 信息行 |
| `#drop-overlay` / `#overwrite-modal` | 拖拽遮罩 / 覆盖确认框 |

### 验证

- `node 选人界面排版工具/verify-dragdrop.js` → **22 项断言全通过**（默认/脏/导入/导出四态 + `needsConfirmOverwrite` 四组合 + `exportXML` 清脏）。
- `node 选人界面排版工具/verify-batch-spacing.js` → **31 项断言全通过**（整列/整行选取、`nudge` 整组位移、`applySpacing` 按列号/行号线性施加、`snapshot`/撤销覆盖 `selectedRow/selectedCol/spacingDelta`）。
- 回归：`verify-grid-reshape.js` **77 项断言全通过**；其余既有 `verify*.js` 退出码不变（其中 `verify.js/verify-canvas-size.js/verify-logic.js/verify-pagination.js/verify-target-fix.js` 5 个失败项为既有 stub 陈旧问题，与本次无关）。

### 已知限制

- 撤销/重做后 `dirty` 保持 `true`（保守方向：只会多确认一次，不丢数据）；`spacingDelta` 已入 snapshot，撤销可正确回退间距。
- `btn-reset` 只清选中格 offset、不动 `spacingDelta`（列表级概念）；重排「清零 offset」会同步归零 `spacingDelta`。
- 「导入 XML」按钮仍为直接替换（不加确认），与拖拽的确认逻辑不同；如需统一可在 `applyLoadedState` 前加同一谓词。

---

## 追加功能（2026-10-13）— 顶部栏人物页 / 辅助页双画布切换

辅助表（assist_list）排版纳入画布编辑，顶部栏可切换人物页/辅助页。两个画布独立、页数独立；切换按钮占用原「显示模式」徽标（mode-badge）的位置，徽标本身删除。

### 决策（ADR）

| # | 问题 | 决策 | 理由 |
|---|---|---|---|
| Q1 | 页数怎么算 | **按内容算**：每列表按自己最底格子的底边 ÷ 翻页步高（`PAGE_HEIGHT` 全局共享），空列表保底 1 页 | layout.height 只是一个容纳框，实际内容（间距/重排/offset）决定玩家要翻几页 |
| Q2 | 两画布怎么建 | **一个 `<canvas>` 元素 + 每列表独立状态**（`state.pageView[key] = {page, selKey, selRow, selCol}`）；`currentPage/selectedKey/...` 继续作「活动列表镜像」，既有 32 处引用不动 | 最小改动；渲染管线、翻页、滚轮、键盘全部零迁移 |
| Q3 | 参考背景图 | **按页独立**：`refBgStore = {charList, assistList}` 各存一份位置/缩放/透明度/显示/调整模式；内嵌默认图两份都给 | 人物表和辅助表的底图对位参考不同 |

另两项自行决定：侧栏 `#list-sel` 下拉保留并与顶部钮**双向同步**；`layout` 两页共享（XML 格式硬约束，`stage_setting/layout` 只有 1 个，不改动）。

### 设计

- **switchList(key)**：`saveCurPageView()`（镜像写回旧列表）→ 换 `currentList` → `loadCurPageView()`（恢复页码/选中，钳到该列表内容页数内）→ `loadActiveRefBg()` → `syncPageSwitchUI()`（顶钮 active + 下拉）→ 重渲染系列 + `snapMainScrollToPage()`。切换**不 markDirty**。
- **页数**：`contentExtent(list)`（calcGap + calcItemPos 遍历取最底格子底边）→ `totalPagesFor(listKey)` → `totalPages()` 委托当前列表；`applyCanvasSize` 的页号钳制改用 `totalPages()`。
- **撤销**：`snapshot()` 纳入 `pageView`；新增 `afterStateRestore()`（撤销/重做/`applyLoadedState`/`setState` 共用）：`syncRefBgToActive` + `syncPageSwitchUI` + `renderPageIndicator` + `snapMainScrollToPage`。切换本身不入栈（不可逆的只有内容改动）。
- **语义变更（重要）**：totalPages 从 `ceil(layout.height / PAGE_HEIGHT)` 改为 `ceil(contentExtent / PAGE_HEIGHT)`。自适应间距下内容底边 ≈ `height - unitSize.y - bottom + renderSize.h`，通常比 layout.height 小一点 → 同一 XML 页数可能少 1（例：800×3010 素材旧 6 页 → 新 5 页，内容底边 2970）。`verify-pagination.js` 已按新语义更新。

### 代码位置（`select-layout-tool.html`）

| 符号 | 作用 |
|---|---|
| `#page-switch`（`#sw-charList` / `#sw-assistList`） | 顶栏分段切换钮（原 mode-badge 位置，含 3.9 公式 title） |
| `state.pageView` | 每列表独立页视图 `{page, selKey, selRow, selCol}` |
| `saveCurPageView / loadCurPageView` | 活动镜像 ↔ pageView 双向搬运（带页码钳制） |
| `switchList / bindPageSwitch / syncPageSwitchUI` | 切换主入口 / 顶钮绑定 / 顶钮+下拉同步 |
| `contentExtent / totalPagesFor / totalPages` | 按内容算页数（PAGE_HEIGHT 全局共享） |
| `refBgDefaults / refBgStore / loadActiveRefBg / syncRefBgToActive` | 背景图按列表独立（`refBg` 改为指向活动条目的引用） |
| `renderSegmentRef` | 活动 refBg 状态回填侧栏控件（`bg-show/bg-edit/bg-scale/bg-alpha`） |
| `afterStateRestore` | 状态恢复后的镜像视图统一同步 |
| CSS `#topbar #page-switch` | 分段钮样式（active 高亮沿用原徽标配色）；响应式里 `#mode-badge{display:none}` 规则随徽标删除 |

### 验证

- `node 选人界面排版工具/verify-page-switch.js` → **85 项断言全部通过**：页数按内容算（两列表独立/空列表保底/步高全局改两列表都变）、切换后页码与选中各自记忆、顶钮↔下拉双向同步、越界页码钳制、`pageView` 入撤销栈（Ctrl+Z/Ctrl+Shift+Z 跨列表恢复页码/选中/active）、切换不标脏、参考背景图按页独立（缩放/显示/调整模式 + 控件回填）、导出回读恒等（serialize→parse→serialize，去掉时间戳注释）、导入后状态复位。
- 既有回归：`verify-grid-reshape`(77)/`verify-dragdrop`(22)/`verify-batch-spacing`(31)/`verify-roundtrip`/`verify.js`/`verify-canvas-size.js`/`verify-logic.js`/`verify-target-fix.js` 全部 exit=0；`verify-pagination.js` 按页数新语义更新后 exit=0（改前备份 HTML 下旧版即通过，确认非回归）。
- Edge headless 冒烟（TEMP 副本注入探针 `--dump-dom`）：`SMOKE errors=0 ready=1 badge=0 clickA{sel=assistList,ind=第 1 / 1 页,active=1} clickC{sel=charList,active=1}`——零 JS 错误、mode-badge 无残留、双钮切换与同步正常。
- 备份：`.backup/select-layout-tool.html.2026-10-13-1838`、`.backup/plan.md.2026-10-13-1838`。

### 已知限制

- 切换按钮不撤回（撤销栈不含切换动作）：Ctrl+Z 恢复的是**快照时刻**的活动列表与页视图，不回退「点了哪个钮」本身。
- `#main` 滚动镜像（`scroll → currentPage` 换算）仍按 `PAGE_HEIGHT` 单位，两列表步高一致所以天然正确；若未来想让两列表步高独立，此处需一并迁移。

---

## 修复（2026-10-19）— select.xml 分页清洗 + 内嵌默认数据

### 问题

工具打开 `解析素材/select.xml` 后，"第二页的内容出现在第一页底部"。

### 根因

**char_list** 的 `<row offset="x,y">` 中 `y` 值被错误写入了累积行距 / 大负跳变（0, 20.54, 41.08... 递增；后续出现 -2822、-446.67 等极端负值）。3.9 模式 item 渲染公式 `y = startY + gapY * gridY + offset.y` 中 offset.y 本应是微调量（±几 px），但 XML 里写成了绝对值/累积值，导致后续页的行被拉回 page 0 渲染窗口 [0, 600)。

具体数据：138 行的 char_list 清洗前 item 渲染 y 范围 60~8508（maxBottom=9035），15 页中几乎每页底部都有越界/跨页泄漏。

**assist_list 的负 offset（-433, -880, ... -5181）是有意设计**——用于抵消 gapY=506.67（13 行 × 6300px 分摊）的稀疏，把 item 压缩到 2 页 × 8+5 行。不动它。

### 修复

- `解析素材/select.xml`：char_list 所有 `<row>` 的 offset y 归零（保留 x），浮点噪声（2.84e-14、-1.13e-13）清零为 0。assist_list 不动。
- `select-layout-tool.html`：内嵌 `<script id="default-xml">` 数据替换为清洗后的 select.xml。

### 清洗前后分页对比

| 指标 | 清洗前 | 清洗后 |
|---|---|---|
| char_list 页数 | 15 | **11** |
| char_list 每页行数 | 8~10（乱） | **13~14（均匀）** |
| 跨页泄漏 | 几乎每页都有 | **0（干净）** |
| assist_list | 2 页 × 8+5 行 | **不变** |
| item 渲染 y 范围 | 60 ~ 8508 | **60 ~ 5999** |

### 剩余 15 个"越界"说明

每页最后一个 item 的底部因 `PAGE_HEIGHT=600` 不能被 `gapY=44.38` 整除而溢出 8~52px——canvas 自动裁剪超出部分。这是**正常分页效果**（底部被轻微截断），不是跨页泄漏。

### 备份

- `.backup/select-layout-tool.html.2026-10-19-1318`
- `.backup/select.xml.2026-10-19-1318`

---

## 修复（2026-10-19b）— 垂直分页对齐游戏内「按页」模型

### 问题

工具页 0 渲染 13~14 行（末行被裁切），主程序选人界面页 0 只显示 **7 行**（用户截图红框）；红框以下的行在游戏里属于第 2 页及以后。工具仍用 3.9「整列直排」模型（`gapY` 按整幅 `layout.height` ÷ 总行数、按像素窗切页），而主程序已于 2026-10-10 改为「按页」模型。

### 根因

`calcGap()` 用整幅 `layout.height` 分摊全部行；`calcItemPos()` 直接 `gapY*gridY`，没有页内回绕；`totalPagesFor()` 按内容高度 ÷ `PAGE_HEIGHT`；`isOnCurrentPage()` / `drawItem()` / `renderGridInfo()` 仍按 `layout.height` 判断越界。页数、行距、行落点三者不同源。

### 权威公式（唯一真相源）

`BVNscripts/scripts/net/play5d/game/bvn/state/SelectFighterStage.as:261-322`（`CELL_SIZE=(60,60)` 见 :45，`GAME_SIZE=(800,600)` 见 `GameConfig.as:140`）：

```text
viewportH       = min(layout.height, GAME_SIZE.y)              // min(6300,600) = 600
usableH         = max(viewportH - top - bottom, CELL_SIZE.y)   // 600-60-110 = 430
rowsPerPage     = max(1, floor(usableH / CELL_SIZE.y))         // 7
maxY            = 最大 gridY
displayedVCount = max(1, min(VCount, rowsPerPage, maxY + 1))
gapX            = (width - unitSize.x - left - right) / (HCount - 1)
gapY            = displayedVCount>1 ? (viewportH - unitSize.y - top - bottom)/(displayedVCount-1) : CELL_SIZE.y
                  // 钳制 gapY >= CELL_SIZE.y
PAGE_HEIGHT     = viewportH                                    // 600
TOTAL_PAGES     = max(1, ceil((maxY + 1) / rowsPerPage))       // char 20；assist 2
item.y          = y+top + gapY*(gridY % rowsPerPage) + floor(gridY/rowsPerPage)*PAGE_HEIGHT + offset.y
item.x          = x+left + gapX*gridX + offset.x
```

代入 `解析素材/select.xml`（layout 900×6300，left=10 / right=20 / top=60 / bottom=110，V=138/13）：char_list = **20 页**（19×7 + 末页 5）、assist_list = **2 页**（7+6），页 0 = 7 行。

### 改动

| 文件 | 改动 |
|---|---|
| `select-layout-tool.html` | `calcGap()` 改按页公式（rowsPerPage/displayedVCount/pageH）；`calcItemPos()` 增加页内回绕；`totalPagesFor()` 改 `ceil(V/rowsPerPage)` 并删除 `contentExtent`；`isOnCurrentPage()` 改用 `[top, top+pageH]` 页窗口；`drawItem()` 越界改页内 `localY`；`applySpacing('y')` 按 `gridY % rowsPerPage` 施加；`renderGridInfo()` 改页内判据并显示「每页 N 行 · 共 M 页」；`parseXML()` 设 `PAGE_HEIGHT=min(layout.height,600)`，`applyLoadedState()` / `init()` / `afterStateRestore()` 回写 `#page-step`；`#page-step` 变更时先按旧值入撤销栈，再重算视口、页数与画布；右侧页进度轨改用 `totalPages()`；顶部注释与「人物页/辅助页」title 同步按页公式。 |
| `解析素材/select.xml` + HTML 内嵌 `default-xml` | assist_list 所有 `<row offset>` 的 y 归零（保留 x；char_list 早已为 0），item offset 不动。 |
| verify 脚本 | `verify-pagination.js` / `verify-page-switch.js` / `verify-batch-spacing.js` / `verify-grid-reshape.js` 页数断言改 `ceil(V/rowsPerPage)`（char 20 / assist 2）；`verify-batch-spacing.js` 增加「行 7 页内行 0 不动」的 yInPage 回绕断言；`verify-canvas-size.js` 目标数据改为当前 900×6300；`verify-roundtrip.js` 断言计入 row offset。 |

### ADR

| # | 决策 | 理由 |
|---|---|---|
| Q1 | 采用主程序「按页」模型，弃 3.9 整列公式 | 用户要求与游戏内相同；主程序注释明令禁止改回整列公式（SelectFighterStage.as:292-293） |
| Q2 | rowsPerPage 的 CELL_SIZE 取 `layout.renderSize.h`（默认 60） | 游戏硬编码 (60,60)；工具 renderSize 承担同一角色 |
| Q3 | assist row offset y 归零 | 该负值是旧整列模型补偿值；按页模型下 item 全部飞出屏幕 |
| Q4 | `#page-step` 保留为预览覆盖，默认 = 推导值 | 保留既有功能；默认路径与游戏一致 |
| Q5 | 间距 y 轴按 yInPage 施加 | 防止累计增量把整页块推出页窗口 |
| Q6 | 页数/页码记忆（pageView、撤销栈）结构不变 | 恢复路径已有 `Math.min(currentPage, totalPages()-1)` 钳制 |

### 前后对比

| 指标 | 旧整列模型 | 新按页模型 |
|---|---|---|
| 页 0 行数 | 13~14（末行裁切） | **7** |
| char_list 页数 | 11 | **20**（19×7 + 末页 5） |
| assist_list | 负数 row offset 压缩 | **2**（7 + 6） |
| gapY | 44.38（6300 整幅分摊） | **63.33**（(600-50-60-110)/6） |
| 满页末行底边 | 溢出 8~52px | **500 ≤ 600**（无裁切） |
| item 世界 y（顶边） | 60 ~ 5999 | 60 ~ 11713（20×600 页高） |

### 验证

- Node 独立分析（读 HTML 内嵌 XML，按权威公式复算）：char_list 138 行/690 格、assist 13 行/61 格；rowsPerPage=7；页数 20/2；页 0 各 7 行；所有 item 页内底边 ≤600（out=0）；满页末行底边 500。
- 全量 verify：13 个脚本全部 exit=0（batch-spacing 32 项、page-switch 82 项、grid-reshape 77 项、pagination/logic/dragdrop/roundtrip/canvas-size/target-fix 等）。
- Headless Chrome（`--headless=old --dump-dom` + 注入探针）：`ready=true, charPages=20, assistPages=2, rowsPerPage=7, gapY=63.33, charP0={rows:7,items:35}, charP1={7,35}, charP19={5,25}, assistP0={7,35}, assistP1={6,26}, ind19="第 20 / 20 页", err=""`；无 JS 异常。
- 备份：`.backup/select-layout-tool.html.2026-10-19-1453`、`.backup/verify-batch-spacing.js.2026-10-19-1453`、`.backup/verify-canvas-size.js.2026-10-19-1453`、`.backup/verify-roundtrip.js.2026-10-19-1453`、`.backup/plan.md.2026-10-19-1453`、`.backup/select.xml.2026-10-19-1453`（本轮变更后的基线副本）。

### 已知差异 / 风险

- 工具 `layout.unitSize` 默认 `(50,50)`（侧栏可改），主程序 `SelectStageConfigVO.unitSize=(60,60)`；本计划按工具现值计算 `gapY=63.33`。若要与主程序像素级一致，可只把「单格占位高」改为 60 → `gapY=(600-60-60-110)/6=61.67`；列距若要一致还需把宽也改 60（会改 gapX，本计划按 Q1/Q2 未做）。
- 页数 11→20 后旧撤销快照/页码记忆越界：恢复路径已有钳制，全量 verify 覆盖。
- 参考背景图为会话级按页对位，页数变化后需重新对位（不写入 XML、无数据损失）。
- item offset 是自由微调量，游戏同口径叠加；仅 row offset 参与分页模型。


