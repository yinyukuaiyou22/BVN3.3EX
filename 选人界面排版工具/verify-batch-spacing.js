// 批量选择整行/整列 + 格子间距（offset 均匀增量）— 逻辑验证
// 用 stub DOM + 真实加载工具脚本（沿用 verify-grid-reshape.js 范式）
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const HTML_PATH = path.join(__dirname, 'select-layout-tool.html');
const html = fs.readFileSync(HTML_PATH, 'utf8');

// ---------- stub DOM ----------
const stubCtx = {
  save(){}, restore(){}, clearRect(){}, beginPath(){}, closePath(){},
  moveTo(){}, lineTo(){}, quadraticCurveTo(){}, fill(){}, stroke(){},
  fillText(){}, strokeRect(){}, setLineDash(){}, fillRect(){}, strokeText(){},
  measureText(){ return { width: 10 }; }, rect(){}, arc(){}, ellipse(){}, translate(){},
  scale(){}, rotate(){}, clip(){}, drawImage(){}, createLinearGradient(){ return { addColorStop(){} }; },
  fillStyle:'', strokeStyle:'', lineWidth:1, font:'', textAlign:'', textBaseline:'',
};
const ELS = {};
function makeEl(id) {
  const el = {
    id, tagName: 'DIV', value: '', checked: false, textContent: '', innerHTML: '',
    title: '', style: {}, children: [], childNodes: [], _listeners: {},
    scrollTop: 0, scrollHeight: 0, scrollLeft: 0, disabled: false,
    classList: { _s: new Set(), add(c){ this._s.add(c); }, remove(c){ this._s.delete(c); }, contains(c){ return this._s.has(c); } },
    appendChild(c){ this.childNodes.push(c); this.children.push(c); return c; },
    removeChild(c){ const i = this.childNodes.indexOf(c); if (i >= 0) this.childNodes.splice(i, 1); return c; },
    scrollTo(){}, click(){}, getContext: () => stubCtx,
    addEventListener(t, fn){ (el._listeners[t] = el._listeners[t] || []).push(fn); },
    removeEventListener(t, fn){ const a = el._listeners[t] || []; const i = a.indexOf(fn); if (i >= 0) a.splice(i, 1); },
    fire(t, ev){ (el._listeners[t] || []).forEach(fn => fn(ev || { target: el, preventDefault(){}, key: '' })); },
  };
  return el;
}
function getEl(id) { return (ELS[id] = ELS[id] || makeEl(id)); }

const defaultXml = html.match(/<script type="application\/xml" id="default-xml">([\s\S]*?)<\/script>/)[1];
global.document = {
  getElementById: (id) => id === 'default-xml' ? { textContent: defaultXml } : getEl(id),
  createElement: () => makeEl('_new'),
  addEventListener(){}, body: { appendChild(){}, removeChild(){} },
  activeElement: { tagName: 'BODY' },
};
global.window = { addEventListener(){} };
global.requestAnimationFrame = () => {};
global.Blob = function(){};
global.URL = { createObjectURL: () => '', revokeObjectURL(){} };
global.FileReader = function(){};

// ---------- minimal DOMParser ----------
global.DOMParser = class {
  parseFromString(text) {
    const bad = text.includes('<parsererror') || !text.includes('<select_config>');
    function parseList(scope) {
      const rowRe = /<row(?:\s+offset="([^"]*)")?\s*>([\s\S]*?)<\/row>/g;
      const rows = [...scope.matchAll(rowRe)].map(rm => ({
        tagName: 'row',
        getAttribute: (a) => a !== 'offset' ? null : (rm[1] || ''),
        children: (() => {
          const itemRe = /<item(?:\s+offset="([^"]*)")?\s*>([^<]*)<\/item>/g;
          return [...rm[2].matchAll(itemRe)].map(im => ({
            tagName: 'item',
            getAttribute: (a) => a !== 'offset' ? null : (im[1] || ''),
            textContent: im[2] || '',
            children: [],
          }));
        })(),
      }));
      return { tagName: 'list', children: rows, querySelector: () => null };
    }
    const layoutAttrs = (text.match(/<layout([^>]*)\/>/) || [null, ''])[1];
    const layoutNode = { tagName: 'layout', getAttribute: (a) => {
      const m = layoutAttrs.match(new RegExp(a + '="([^"]*)"'));
      return m ? m[1] : null;
    } };
    const charC = text.match(/<char_list>([\s\S]*?)<\/char_list>/);
    const assistC = text.match(/<assist_list>([\s\S]*?)<\/assist_list>/);
    return {
      querySelector: (sel) => {
        if (sel === 'parsererror') return bad ? {} : null;
        if (sel === 'stage_setting > layout') return layoutNode;
        if (sel === 'char_list') return charC ? parseList(charC[1]) : null;
        if (sel === 'assist_list') return assistC ? parseList(assistC[1]) : null;
        return null;
      },
      querySelectorAll: () => [], getElementsByTagName: () => [],
    };
  }
};

// ---------- run tool script ----------
const jsStart = html.indexOf('<script>', html.indexOf('Main script')) + '<script>'.length;
const jsEnd = html.indexOf('</script>', jsStart);
const js = html.substring(jsStart, jsEnd);
const ctx = vm.createContext({
  document: global.document, window: global.window, requestAnimationFrame,
  setTimeout, Blob, URL, FileReader, DOMParser: global.DOMParser, console,
  Date, JSON, Object, Array, Number, Math, String, Boolean, parseInt, parseFloat,
  setInterval, clearInterval, clearTimeout, isNaN,
});
vm.runInContext(js, ctx);
const tool = ctx.__layoutTool || (ctx.window && ctx.window.__layoutTool);
if (!tool) { console.error('FAIL: __layoutTool 未导出'); process.exit(1); }
// 2026-10-19b：数据断言与内嵌默认（138 行真实数据）解耦，换回旧 56 格 fixture
tool.setState(tool.parseXML(fs.readFileSync(path.join(__dirname, 'verify-fixture-56.xml'), 'utf8')));

// ---------- 断言小工具 ----------
let pass = 0;
function ok(cond, msg) {
  if (cond) { pass++; console.log('  ✓ ' + msg); }
  else { console.error('  ✗ FAIL: ' + msg); process.exitCode = 1; throw new Error('assert: ' + msg); }
}
function eq(a, b, msg) { ok(a === b, msg + ' (期望 ' + JSON.stringify(b) + ', 实际 ' + JSON.stringify(a) + ')'); }
const L = () => tool.currentItems();
const at = (x, y) => L().find(i => i.gridX === x && i.gridY === y);

console.log('=== 0. 静态检查 ===');
ok(/id="seg-spacing"/.test(html), 'HTML 含 #seg-spacing');
ok(/id="gap-x"/.test(html), 'HTML 含 #gap-x');
ok(/id="gap-y"/.test(html), 'HTML 含 #gap-y');
ok(/function getSelectedItems/.test(js), '脚本含 getSelectedItems');
ok(/function applySpacing/.test(js), '脚本含 applySpacing');
ok(/function selectCol/.test(js), '脚本含 selectCol');
ok(/function selectRow/.test(js), '脚本含 selectRow');

console.log('=== 1. 整列选择 ===');
const colItems = tool.selectCol(2, 0);
eq(colItems.length, 14, '整列 x=2 选中 14 格（char_list 14 行）');
ok(colItems.every(i => i.gridX === 2), '整列内所有格子 gridX===2');
eq(tool.getSelectedItems().length, 14, 'getSelectedItems() 返回整列');
eq(tool.isItemSelected(at(2, 0)), true, 'isItemSelected(2,0)=true');
eq(tool.isItemSelected(at(0, 0)), false, 'isItemSelected(0,0)=false');

console.log('=== 2. 整行选择 ===');
const rowItems = tool.selectRow(0, 0);
eq(rowItems.length, 4, '整行 y=0 选中 4 格');
ok(rowItems.every(i => i.gridY === 0), '整行内所有格子 gridY===0');
eq(tool.isItemSelected(at(3, 0)), true, 'isItemSelected(3,0)=true');

console.log('=== 3. nudge 整组移动 ===');
tool.selectRow(0, 0);
const beforeNudge = L().filter(i => i.gridY === 0).map(i => ({ x: i.offset.x, y: i.offset.y }));
tool.nudge(1, 2, 1);   // 全部 + (1,2)
const afterNudge = L().filter(i => i.gridY === 0);
ok(afterNudge.every((i, k) => i.offset.x === beforeNudge[k].x + 1 && i.offset.y === beforeNudge[k].y + 2), 'nudge(1,2) 后整行各格 offset 同步 +(1,2)');
ok(afterNudge.every(i => i.gridY === 0), '移动后仍是整行选中');

console.log('=== 4. clearSelection ===');
tool.clearSelection();
eq(tool.getSelectedItems().length, 0, 'clearSelection 后选中为空');

console.log('=== 5. 间距 applySpacing（水平，按列号线性施加） ===');
const gap = tool.calcGap(L());
const st = tool.getState();
const d0 = st.spacingDelta.charList.x;
const off0 = at(0, 0).offset.x, off1 = at(1, 0).offset.x, off2 = at(2, 0).offset.x, off3 = at(3, 0).offset.x;
const targetX = gap.gapX + d0 + 10;   // 目标 = 当前 + 10（全精度，避免显示舍入误差）
getEl('gap-x').value = String(targetX);
getEl('gap-x').fire('input');
ok(Math.abs(at(0, 0).offset.x - off0) < 1e-6, '列0 offset.x 不变');
ok(Math.abs(at(1, 0).offset.x - (off1 + 10)) < 1e-6, '列1 offset.x +10');
ok(Math.abs(at(2, 0).offset.x - (off2 + 20)) < 1e-6, '列2 offset.x +20');
ok(Math.abs(at(3, 0).offset.x - (off3 + 30)) < 1e-6, '列3 offset.x +30');
ok(Math.abs(tool.getState().spacingDelta.charList.x - (d0 + 10)) < 1e-6, 'spacingDelta.charList.x 累计 +10');

console.log('=== 6. 间距 applySpacing（垂直，按行号线性施加） ===');
const d1y = tool.getState().spacingDelta.charList.y;
const oy0 = at(0, 0).offset.y, oy1 = at(0, 1).offset.y, oy7 = at(0, 7).offset.y;
const targetY = gap.gapY + d1y + 5;   // 全精度，避免显示舍入误差
getEl('gap-y').value = String(targetY);
getEl('gap-y').fire('input');
ok(Math.abs(at(0, 0).offset.y - oy0) < 1e-6, '行0 offset.y 不变');
ok(Math.abs(at(0, 1).offset.y - (oy1 + 5)) < 1e-6, '行1 offset.y +5');
// 2026-10-19b 按页模型：y 增量按 gridY % rowsPerPage 施加，行 7 是下一页的页内行 0，不应移动
ok(Math.abs(at(0, 7).offset.y - oy7) < 1e-6, '行7（页内行0）offset.y 不变（按页回绕）');
ok(Math.abs(tool.getState().spacingDelta.charList.y - (d1y + 5)) < 1e-6, 'spacingDelta.charList.y 累计 +5');

console.log('=== 7. snapshot 覆盖 selectedRow/selectedCol/spacingDelta ===');
tool.selectCol(1, 0);
tool.pushUndoSnap();
const snap = tool.getUndoStack()[tool.getUndoStack().length - 1];
eq(snap.selectedCol, 1, 'snapshot 记录 selectedCol');
eq(snap.selectedRow, null, 'snapshot 记录 selectedRow=null');
ok(snap.spacingDelta && snap.spacingDelta.charList && typeof snap.spacingDelta.charList.x === 'number', 'snapshot 记录 spacingDelta');

console.log('=== 8. 撤销恢复整组选择与间距 ===');
const undoStack = tool.getUndoStack();
const popped = undoStack.pop();
Object.assign(tool.getState(), popped);
eq(tool.getState().selectedCol, 1, '撤销后 selectedCol 恢复');
ok(Math.abs(tool.getState().spacingDelta.charList.x - (d0 + 10)) < 1e-6, '撤销后 spacingDelta 恢复');

console.log('\n=== 全部 ' + pass + ' 项断言通过 ===');
