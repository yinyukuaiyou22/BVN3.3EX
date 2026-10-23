// 人物页/辅助页双画布切换 — 端到端验证
// 覆盖：按内容算页数（两列表独立/空列表保底1页/PAGE_HEIGHT全局共享）、
// 切换后页码/选中/参考背景图各自记忆、顶部钮与侧栏下拉双向同步、
// pageView 入撤销栈、切换不标脏、导出回读不变
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const HTML_PATH = path.join(__dirname, 'select-layout-tool.html');
const html = fs.readFileSync(HTML_PATH, 'utf8');

// ---------- stub DOM（与 verify-grid-reshape.js 同款） ----------
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
    scrollTop: 0, scrollHeight: 0, scrollLeft: 0,
    classList: { _s: new Set(), add(c){ this._s.add(c); }, remove(c){ this._s.delete(c); }, contains(c){ return this._s.has(c); } },
    appendChild(c){ this.childNodes.push(c); this.children.push(c); return c; },
    removeChild(c){ const i = this.childNodes.indexOf(c); if (i >= 0) this.childNodes.splice(i, 1); return c; },
    scrollTo(){}, getContext: () => stubCtx,
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
const WIN_L = {};
global.window = { addEventListener(t, fn){ (WIN_L[t] = WIN_L[t] || []).push(fn); } };
global.requestAnimationFrame = () => {};
global.Blob = function(){};
global.URL = { createObjectURL: () => '', revokeObjectURL(){} };
global.FileReader = function(){};

// ---------- minimal DOMParser（只服务 parseXML 需要的选择器） ----------
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

// ---------- 断言小工具 ----------
let pass = 0;
function ok(cond, msg) {
  if (cond) { pass++; console.log('  ✓ ' + msg); }
  else { console.error('  ✗ FAIL: ' + msg); process.exitCode = 1; throw new Error('assert: ' + msg); }
}
function eq(a, b, msg) { ok(a === b, msg + ' (期望 ' + JSON.stringify(b) + ', 实际 ' + JSON.stringify(a) + ')'); }
function type(el, v) { el.value = String(v); el.fire('input'); }
function fireChange(el) { el.fire('change'); }
function clickBtn(id) { getEl(id).fire('click'); }
function ctrlZ(shift) {
  (WIN_L.keydown || []).forEach(fn => fn({ ctrlKey: true, metaKey: false, shiftKey: !!shift, key: 'z', preventDefault(){} }));
}

console.log('=== 0. 静态检查（顶栏切换钮在位，mode-badge 已删） ===');
ok(html.includes('id="page-switch"'), '#page-switch 容器存在');
ok(html.includes('id="sw-charList"'), '#sw-charList 按钮存在');
ok(html.includes('id="sw-assistList"'), '#sw-assistList 按钮存在');
ok(!html.includes('mode-badge'), 'mode-badge 已完全移除');
ok(/id="sw-charList" class="active"/.test(html), '默认人物页带 active');

const st = tool.getState();

console.log('=== 1. 初始状态与 pageView 结构 ===');
eq(st.currentList, 'charList', '初始活动列表 charList');
ok(st.pageView && st.pageView.charList && st.pageView.assistList, 'state.pageView 含两列表条目');
eq(st.pageView.charList.page, 0, 'charList 初始页 0');
eq(st.pageView.assistList.page, 0, 'assistList 初始页 0');
eq(st.currentPage, 0, '活动镜像页 0');
eq(tool.totalPages(), tool.totalPagesFor(st.currentList), 'totalPages() 委托当前列表');

console.log('=== 2. 页数按游戏内口径 ceil(行数/每页行数)（2026-10-19b 语义更新） ===');
const PH = st.PAGE_HEIGHT;
const gapC0 = tool.calcGap(st.charList);
const VC0 = st.charList.reduce((m, i) => Math.max(m, i.gridY + 1), 0);
const VA0 = st.assistList.reduce((m, i) => Math.max(m, i.gridY + 1), 0);
eq(gapC0.rowsPerPage, 7, '每页行数 = floor((600-60-110)/60) = 7');
eq(tool.totalPagesFor('charList'), Math.max(1, Math.ceil(VC0 / gapC0.rowsPerPage)), 'charList 页数 = ceil(行数/每页行数)');
eq(tool.totalPagesFor('charList'), 20, '默认 charList 138 行 → 20 页');
eq(tool.totalPagesFor('assistList'), 2, '默认 assistList 13 行 → 2 页');

console.log('=== 3. 行数只改 charList → 只影响 charList 页数 ===');
const baseLen = st.charList.length;
for (let c = 0; c < 5; c++) st.charList.push({ gridX: c, gridY: VC0, fighterID: 'tmp' + c, offset: { x: 0, y: 0 }, listKey: 'tmp' + c });
st.charList.push({ gridX: 0, gridY: VC0 + 1, fighterID: 'tmpA', offset: { x: 0, y: 0 }, listKey: 'tmpA' });
st.charList.push({ gridX: 0, gridY: VC0 + 2, fighterID: 'tmpB', offset: { x: 0, y: 0 }, listKey: 'tmpB' });
eq(tool.totalPagesFor('charList'), 21, 'charList 141 行 → 21 页');
eq(tool.totalPagesFor('assistList'), 2, 'assistList 页数不受影响 (仍 2)');
st.charList.length = baseLen;
eq(tool.totalPagesFor('charList'), 20, '还原后 20 页');

console.log('=== 4. 空列表保底 1 页 ===');
const assistBackup = st.assistList;
st.assistList = [];
eq(tool.totalPagesFor('assistList'), 1, '空列表保底 1 页');
st.assistList = assistBackup;
eq(tool.totalPagesFor('assistList'), 2, '还原后恢复按行数算');

console.log('=== 5. PAGE_HEIGHT 覆盖 → 每页行数与页数都重算 ===');
const psEl = getEl('page-step');
psEl.value = '300'; fireChange(psEl);
eq(st.PAGE_HEIGHT, 300, '翻页步高已改为 300');
eq(tool.calcGap(st.charList).rowsPerPage, 2, '步高 300 → 每页行数 floor((300-60-110)/60)=2');
eq(tool.totalPagesFor('charList'), 69, 'charList 138/2 → 69 页');
eq(tool.totalPagesFor('assistList'), 7, 'assistList 13/2 → 7 页');
psEl.value = '600'; fireChange(psEl);
eq(tool.totalPagesFor('charList'), 20, '步高改回 600 → charList 20 页');
eq(tool.totalPagesFor('assistList'), 2, '步高改回 600 → assistList 2 页');

console.log('=== 6. 切换：页码/选中各自记忆 + 双向同步 + 不标脏 ===');
// assist 默认 13 行 = 2 页，直接互测
eq(tool.totalPagesFor('assistList'), 2, 'assistList 默认 2 页');
tool.selectItem(st.charList[0]);
eq(st.selectedKey, st.charList[0].listKey, 'charList 选中第 1 格');
tool.gotoPage(1);
eq(st.currentPage, 1, 'charList 翻到第 2 页');
const dirtyBefore = tool.isDirty();
clickBtn('sw-assistList');
eq(st.currentList, 'assistList', '顶栏钮切换 → assistList');
eq(st.currentPage, 0, 'assistList 恢复到自己的第 1 页');
eq(getEl('list-sel').value, 'assistList', '侧栏下拉同步为 assistList');
ok(getEl('sw-assistList').classList.contains('active'), '顶栏「辅助页」带 active');
ok(!getEl('sw-charList').classList.contains('active'), '顶栏「人物页」无 active');
eq(tool.isDirty(), dirtyBefore, '切换不产生未保存标记');
eq(getEl('sel-id').textContent, '-', '切走后 charList 的选中不串台');
tool.selectItem(st.assistList[0]);
eq(st.selectedKey, st.assistList[0].listKey, 'assistList 选中第 1 格');
tool.gotoPage(1);
eq(st.currentPage, 1, 'assistList 翻到第 2 页');
clickBtn('sw-charList');
eq(st.currentList, 'charList', '切回 charList');
eq(st.currentPage, 1, 'charList 记住第 2 页');
eq(st.selectedKey, st.charList[0].listKey, 'charList 记住自己的选中');
eq(getEl('list-sel').value, 'charList', '下拉同步回 charList');
// 侧栏下拉 → 顶栏钮 反向同步
getEl('list-sel').value = 'assistList'; fireChange(getEl('list-sel'));
eq(st.currentList, 'assistList', '#list-sel change 也能切换');
eq(st.currentPage, 1, 'assistList 仍记住第 2 页');
eq(st.selectedKey, st.assistList[0].listKey, 'assistList 记住自己的选中');
ok(getEl('sw-assistList').classList.contains('active'), '反向切换后顶钮 active 跟随');
// 同列表重复切换 = no-op
clickBtn('sw-assistList');
eq(st.currentList, 'assistList', '同列表切换无副作用');
// 越界页码钳制：assist 存个 99 页再切回来
clickBtn('sw-charList');
st.pageView.assistList.page = 99;
clickBtn('sw-assistList');
eq(st.currentPage, 1, 'pageView 里 99 页被钳到该列表末页 (1)');
st.pageView.assistList.page = 1;

console.log('=== 7. pageView 入撤销栈（Ctrl+Z / Ctrl+Shift+Z 跨列表恢复） ===');
clickBtn('sw-charList');                   // 确保从 charList 开始
eq(st.currentList, 'charList', '第 7 节起点：charList');
const undoLen0 = tool.getUndoStack().length;
tool.pushUndoSnap();                       // 快照：charList 第2页 + 选中0,0
clickBtn('sw-assistList');                 // 切走（本身不入栈）
eq(st.currentList, 'assistList', '切换后活动列表 assistList');
ctrlZ(false);
eq(st.currentList, 'charList', '撤销 → 回到 charList');
eq(st.currentPage, 1, '撤销 → 页码回到快照时的 1');
eq(st.selectedKey, st.charList[0].listKey, '撤销 → 选中恢复');
ok(getEl('sw-charList').classList.contains('active'), '撤销后顶钮 active 跟随');
eq(getEl('list-sel').value, 'charList', '撤销后下拉跟随');
ctrlZ(true);
eq(st.currentList, 'assistList', '重做 → assistList');
eq(st.currentPage, 1, '重做 → 页码恢复');
eq(st.selectedKey, st.assistList[0].listKey, '重做 → assist 的选中恢复');
ok(tool.getUndoStack().length === undoLen0 + 1, '撤销栈长度按预期 +1');

console.log('=== 8. 参考背景图按页独立 + 控件回填 ===');
// 当前活动 assist：缩放 250%
getEl('bg-scale').value = '250'; getEl('bg-scale').fire('input');
eq(tool.getRefState().bg.scale, 2.5, 'assist 背景缩放 2.5');
clickBtn('sw-charList');
eq(tool.getRefState().bg.scale, 1, 'char 背景用自己的 1.0');
eq(getEl('bg-scale').value, 100, '控件回填 char 的 100');
getEl('bg-scale').value = '180'; getEl('bg-scale').fire('input');
clickBtn('sw-assistList');
eq(tool.getRefState().bg.scale, 2.5, 'assist 的 2.5 未被覆盖');
eq(getEl('bg-scale').value, 250, '控件回填 assist 的 250');
// 显示开关独立
getEl('bg-show').checked = false; fireChange(getEl('bg-show'));
eq(tool.getRefState().bg.visible, false, 'assist 关闭背景显示');
clickBtn('sw-charList');
eq(tool.getRefState().bg.visible, true, 'char 背景仍显示');
clickBtn('sw-assistList');
eq(tool.getRefState().bg.visible, false, 'assist 仍记住关闭');
getEl('bg-show').checked = true; fireChange(getEl('bg-show'));
// 调整模式独立
getEl('bg-edit').checked = true; fireChange(getEl('bg-edit'));
eq(tool.getRefState().bg.edit, true, 'assist 开启调整模式');
clickBtn('sw-charList');
eq(tool.getRefState().bg.edit, false, 'char 调整模式独立为关');
clickBtn('sw-assistList');
eq(tool.getRefState().bg.edit, true, 'assist 仍记住开启');
getEl('bg-edit').checked = false; fireChange(getEl('bg-edit'));

console.log('=== 9. 导出回读不变（游戏可识别格式不受影响） ===');
const ser1 = tool.serializeXML();
ok(/<stage_setting>[\s\S]*<\/stage_setting>/.test(ser1), '仍含单一 stage_setting');
ok(/<char_list>[\s\S]*<\/char_list>/.test(ser1) && /<assist_list>[\s\S]*<\/assist_list>/.test(ser1), '仍含 char_list + assist_list');
ok((ser1.match(/<layout /g) || []).length === 1, 'layout 节点只有 1 个');
const reparsed = tool.parseXML(ser1);
// 时间戳注释每次生成不同，剥掉首行注释再比内容
const stripTs = s => s.replace(/^<!--[\s\S]*?-->\n/, '');
eq(reparsed.charList.length, st.charList.length, '回读 charList 格数一致');
eq(reparsed.assistList.length, st.assistList.length, '回读 assistList 格数一致');
eq(reparsed.charList[0].offset.y, st.charList[0].offset.y, '回读 offset 数值一致');
ok(reparsed.pageView && reparsed.pageView.charList.page === 0, '重新解析得到全新 pageView（页 0）');

console.log('=== 10. 导入后状态复位 + 视图同步 ===');
tool.setState(reparsed);   // 换装回读状态（含 afterStateRestore 视图同步）
const st2 = tool.getState();
const ser2 = stripTs(tool.serializeXML());
eq(ser2, stripTs(ser1), 'serialize→parse→serialize 恒等（格式稳定）');
eq(st2.currentList, 'charList', '导入后活动列表复位 charList');
eq(st2.currentPage, 0, '导入后页码复位 0');
ok(getEl('sw-charList').classList.contains('active'), '导入后顶钮 active 复位');
eq(getEl('list-sel').value, 'charList', '导入后下拉复位');

console.log(`\n共 ${pass} 项断言全部通过`);
process.exit(process.exitCode || 0);
