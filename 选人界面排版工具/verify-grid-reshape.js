// 行列数量重排（每行/每列实时改行列数，多出来的列变成行）— 端到端验证
// 用 stub DOM + 真实事件监听：直接给 #grid-cols / #grid-rows 派发 input 事件，走完整绑定链路
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
global.window = { addEventListener(){} };
global.requestAnimationFrame = () => {};
global.Blob = function(){};
global.URL = { createObjectURL: () => '', revokeObjectURL(){} };
global.FileReader = function(){};

// ---------- minimal DOMParser (只服务 parseXML 需要的 4 个选择器) ----------
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
const colsEl = () => getEl('grid-cols');
const rowsEl = () => getEl('grid-rows');
function type(el, v) { el.value = String(v); el.fire('input'); }
function commit(el) { el.fire('change'); }
function grid(list) { return tool.gridCounts(list); }
function arrGrid(list) { return list.map(i => i.gridX + ',' + i.gridY).join(' '); }
function snapshotGrid(list) { return list.map(i => i.gridX + ',' + i.gridY + ':' + (i.fighterID || '')); }

console.log('=== 0. 静态检查（HTML 默认值） ===');
ok(/id="grid-cols"[^>]*min="1"/.test(html), '#grid-cols 有 min=1');
ok(/id="grid-rows"[^>]*min="1"/.test(html), '#grid-rows 有 min=1');
ok(/id="grid-zero-offset"\s+checked/.test(html), '#grid-zero-offset 默认勾选');
getEl('grid-zero-offset').checked = true;   // stub 不解析 html 属性，按默认勾选建模

const state0 = tool.getState();
const origArrangement = snapshotGrid(state0.charList);
const origAssistOffsets = state0.assistList.map(i => i.offset.x + ',' + i.offset.y);

console.log('=== 1. 初始网格 & init 绑定 ===');
eq(grid(state0.charList).N, 56, 'char_list 56 格');
eq(grid(state0.charList).H, 4, 'char_list 初始 4 列');
eq(grid(state0.charList).V, 14, 'char_list 初始 14 行');
eq(grid(state0.assistList).N, 40, 'assist_list 40 格');
eq(grid(state0.assistList).H, 4, 'assist_list 初始 4 列');
eq(grid(state0.assistList).V, 10, 'assist_list 初始 10 行');
eq(colsEl().value, 4, 'init 回填 每行=4');
eq(rowsEl().value, 14, 'init 回填 每列=14');
ok(/56 格/.test(getEl('grid-info').innerHTML), '信息行显示 56 格');
ok(/4 列 × 14 行/.test(getEl('grid-info').innerHTML), '信息行显示 4 列 × 14 行');

console.log('=== 2. 每行=3：多出来的列变成行 ===');
type(colsEl(), 3);
const L = () => tool.currentItems();
eq(grid(L()).H, 3, '重排后 3 列');
eq(grid(L()).V, 19, '重排后 19 行 (ceil(56/3))');
eq(rowsEl().value, 19, '每列输入框实时显示派生值 19');
eq(L().find(i => i.fighterID === '上海人偶').gridX + ',' + L().find(i => i.fighterID === '上海人偶').gridY, '0,1', '原第 4 列「上海人偶」折到 (0,1) 新行');
eq(L().find(i => i.fighterID === '若鹭姬').gridX + ',' + L().find(i => i.fighterID === '若鹭姬').gridY, '2,0', '「若鹭姬」仍在第 1 行末列 (2,0)');
eq(L()[0].fighterID, '小恶魔', '顺序保持：首个仍是 小恶魔');
eq(L()[56 - 1].fighterID, 'random', '顺序保持：末个仍是 random');
ok(L().every(i => i.offset.x === 0 && i.offset.y === 0), '默认选项下 offset 全部清零');
ok(L().every((i, k) => i.gridX === k % 3 && i.gridY === Math.floor(k / 3)), '第 k 格落点 = (k%3, k/3)');

console.log('=== 3. 每列=5 → 列数反向推导 ===');
type(rowsEl(), 5);
eq(grid(L()).V, 5, '每列=5 → 5 行');
eq(grid(L()).H, 12, '每列=5 → 12 列 (ceil(56/5))');
eq(colsEl().value, 12, '每行输入框实时显示派生值 12');
ok(L().every((i, k) => i.gridX === k % 12 && i.gridY === Math.floor(k / 12)), '12 列落点正确');

console.log('=== 4. 形状往返：回到 4 列 = 原始排布 ===');
type(colsEl(), 4);
eq(grid(L()).H, 4, '回到 4 列');
eq(grid(L()).V, 14, '回到 14 行');
ok(JSON.stringify(snapshotGrid(L())) === JSON.stringify(origArrangement), '4→3→5→4 往返后网格与初始完全一致');

console.log('=== 5. 选中态跨重排跟随 ===');
type(colsEl(), 4);
const mid = L()[10];                       // 初始 (2,2) 帕秋莉
const midName = mid.fighterID;
state0.selectedKey = mid.listKey;
eq(mid.listKey, '2,2', '第 11 格初始在 (2,2)');
eq(midName, '帕秋莉', '第 11 格是 帕秋莉');
type(colsEl(), 3);
eq(state0.selectedKey, '1,3', '重排后选中键跟随到新坐标 (1,3)');
eq(L().find(i => i.listKey === state0.selectedKey).fighterID, midName, '选中的仍是同一个角色');
type(colsEl(), 8);
eq(state0.selectedKey, '2,1', '再重排到 8 列后选中键为 (2,1)');
eq(L().find(i => i.listKey === state0.selectedKey).fighterID, midName, '选中的仍是同一个角色');
eq(getEl('sel-id').textContent, midName, '侧边栏「选中 item」显示该角色');

console.log('=== 5b. 末行残缺时行数向上取整 ===');
type(colsEl(), 3);
eq(arrGrid(L()).split(' ').filter(g => g.endsWith(',18')).length, 2, '56 格 / 3 列 → 末行只有 2 格');
type(colsEl(), 8);
eq(arrGrid(L()).split(' ').filter(g => g.endsWith(',6')).length, 8, '56 格 / 8 列 → 7 行整行');

console.log('=== 6. 撤销 / 重做 ===');
const undoLen = tool.getUndoStack().length;
ok(undoLen > 0, '重排已入撤销栈 (' + undoLen + ' 步)');
tool.pushUndoSnap();                       // 模拟一次操作前的快照
const before = JSON.parse(JSON.stringify(tool.currentItems().map(i => i.gridX + ',' + i.gridY)));
type(colsEl(), 2);
eq(grid(L()).H, 2, '重排为 2 列');
const popped = tool.getUndoStack().pop();
Object.assign(state0, popped);
eq(arrGrid(tool.currentItems()), before.join(' '), '撤销后网格恢复');

console.log('=== 7. 列表隔离：assist_list 独立形状 ===');
tool.setState(JSON.parse(JSON.stringify(tool.getState())));
type(colsEl(), 4);
eq(grid(tool.getState().charList).H, 4, 'char_list 4 列');
const listSel = getEl('list-sel');
listSel.value = 'assistList';
listSel.fire('change');
eq(colsEl().value, 4, '切到 assist_list 后 每行=4');
eq(rowsEl().value, 10, '切到 assist_list 后 每列=10');
eq(tool.getState().selectedKey, null, '切换列表后选中已清空');
eq(getEl('sel-id').textContent, '-', '选中面板复位');

console.log('=== 8. offset 保留模式（取消勾选） ===');
getEl('grid-zero-offset').checked = false;
type(colsEl(), 5);
eq(grid(tool.currentItems()).H, 5, 'assist_list → 5 列');
eq(grid(tool.currentItems()).V, 8, 'assist_list → 8 行 (ceil(40/5))');
ok(tool.currentItems().some((i, k) => (i.offset.x + ',' + i.offset.y) === '35,0'), '取消勾选后 item offset 被保留');
ok(tool.currentItems().some((i, k) => (i.offset.x + ',' + i.offset.y) === '105,0'), '取消勾选后 105,0 也保留');
getEl('grid-zero-offset').checked = true;
type(colsEl(), 4);
ok(tool.currentItems().every(i => i.offset.x === 0 && i.offset.y === 0), '重新勾选后 offset 归零');

console.log('=== 9. 输入容错：空 / 非数字 / 越界 ===');
const shapeBefore = grid(tool.currentItems()).H + 'x' + grid(tool.currentItems()).V;
type(colsEl(), '');
eq(grid(tool.currentItems()).H + 'x' + grid(tool.currentItems()).V, shapeBefore, '空输入不改动网格');
type(colsEl(), 'abc');
eq(grid(tool.currentItems()).H + 'x' + grid(tool.currentItems()).V, shapeBefore, '非数字输入不改动网格');
type(colsEl(), 0);
eq(colsEl().value, 1, '输入 0 被夹到 1 并回写');
eq(grid(tool.currentItems()).H, 1, '1 列生效');
eq(grid(tool.currentItems()).V, 40, '40 格 → 40 行');
type(rowsEl(), 999);
eq(rowsEl().value, 40, '超过格子总数的输入被夹到 40 并回写');
eq(grid(tool.currentItems()).H, 1, '1 列');
type(colsEl(), 4);
eq(grid(tool.currentItems()).H + 'x' + grid(tool.currentItems()).V, '4x10', '恢复 4 列 × 10 行');

console.log('=== 9a. 「每列」不可达时输入框回写真实值（当前 assist_list，40 格）===');
type(colsEl(), 4);
eq(grid(tool.currentItems()).N, 40, '当前仍是 40 格');
type(rowsEl(), 9);                          // 40 格 / 每列 9 → cols=ceil(40/9)=5 → 实际 rows=ceil(40/5)=8
eq(grid(tool.currentItems()).H, 5, '每列 9 → 5 列');
eq(grid(tool.currentItems()).V, 8, '每列 9 → 实际 8 行（9 行装不满）');
eq(rowsEl().value, 8, '输入框实时回写真实行数 8，不与信息行矛盾');
eq(colsEl().value, 5, '每行同步为 5');
type(rowsEl(), 6);
eq(grid(tool.currentItems()).H + 'x' + grid(tool.currentItems()).V, '7x6', '每列 6 → 7 列 × 6 行（正好对齐游戏一页 6 行）');
eq(rowsEl().value, '6', '每列 6 可达，输入框保持 6');

console.log('=== 9b. change(失焦/回车) 强制回填真实值 ===');
type(colsEl(), 7);
eq(grid(tool.currentItems()).H, 7, '40 格 → 7 列');
eq(grid(tool.currentItems()).V, 6, '40 格 → 6 行');
rowsEl().value = '9';                       // 直接改值但不派发 input（模拟中途被打断的输入）
commit(rowsEl());
eq(rowsEl().value, 6, 'change 后 每列 回填真实值 6');
eq(colsEl().value, 7, 'change 后 每行 保持 7');

console.log('=== 10. 重叠/出界提示 ===');
ok(/会上下重叠|会左右重叠|OUT/.test(getEl('grid-info').innerHTML), '信息行给出重叠/出界警告');

console.log('=== 11. 导出 → 回读：形状可持久化 ===');
type(colsEl(), 7);
const exported = tool.serializeXML();
ok(/<row offset="/.test(exported), '导出包含 row 节点');
const reparsed = tool.parseXML(exported);
eq(grid(reparsed.assistList).H, 7, '回读后仍是 7 列');
eq(grid(reparsed.assistList).V, 6, '回读后仍是 6 行 (ceil(40/7))');
ok(JSON.stringify(snapshotGrid(reparsed.assistList)) === JSON.stringify(snapshotGrid(tool.currentItems())),
   'assist_list 全部格子坐标 + 角色 ID 往返一致');

console.log('=== 12. char_list 未受 assist 操作影响 ===');
const st = tool.getState();
ok(st.charList.length === 56, 'char_list 仍是 56 格');
ok(st.charList.every((i, k) => i.gridX === k % 4 && i.gridY === Math.floor(k / 4)), 'char_list 仍是 4 列 14 行');

console.log('\n=== 全部 ' + pass + ' 项断言通过 ===');
