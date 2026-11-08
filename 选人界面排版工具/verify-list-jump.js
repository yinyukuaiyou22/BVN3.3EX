// 列表 → 画布定位（2026-11-08）端到端验证
// 覆盖：卡片点击 = 跳到该格所在页 + 选中 + 页指示同步；跨列表仍按各自 rowsPerPage 计算；
//       itemPageIndex 与行分页公式一致；跳转不标脏；当前页点击不跳页
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const HTML_PATH = path.join(__dirname, 'select-layout-tool.html');
const html = fs.readFileSync(HTML_PATH, 'utf8');

// ---------- stub DOM（与 verify-page-switch.js 同款） ----------
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

let pass = 0;
function ok(cond, msg) {
  if (cond) { pass++; console.log('  ✓ ' + msg); }
  else { console.error('  ✗ FAIL: ' + msg); process.exitCode = 1; throw new Error('assert: ' + msg); }
}
function eq(a, b, msg) { ok(a === b, msg + ' (期望 ' + JSON.stringify(b) + ', 实际 ' + JSON.stringify(a) + ')'); }

// 找卡片：stub 的 innerHTML='' 不清 children，所以取最后一个 title 前缀匹配的
function findCard(gx, gy) {
  const cards = getEl('cards');
  const prefix = '[' + gx + ',' + gy + ']';
  for (let i = cards.children.length - 1; i >= 0; i--) {
    const b = cards.children[i];
    if (String(b.title || '').indexOf(prefix) === 0) return b;
  }
  return null;
}
function listOf(t, key) { return key === 'charList' ? t.charList : t.assistList; }

const st = tool.getState();
const gap = tool.calcGap(st.charList);
const rpp = gap.rowsPerPage;

console.log('=== 1. 页号公式 ===');
ok(rpp >= 3, 'rowsPerPage 合理 (' + rpp + ')');
const target = st.charList.find(i => i.gridY === rpp && !!i.fighterID);
ok(!!target, '找到第 2 页（gridY=' + rpp + '）的非空格');
eq(tool.itemPageIndex(target), 1, 'itemPageIndex(gridY=' + rpp + ') = 1');
eq(tool.itemPageIndex(st.charList[0]), 0, '首行页号 = 0');
const lastItem = st.charList[st.charList.length - 1];
eq(tool.itemPageIndex(lastItem), Math.floor(lastItem.gridY / rpp), '末行页号与公式一致');

console.log('=== 2. 卡片点击 → 跳到该格所在页并选中 ===');
eq(st.currentPage, 0, '跳转前在第 1 页');
const dirtyBefore = tool.isDirty();
const card = findCard(target.gridX, target.gridY);
ok(!!card, '卡片存在 [' + target.gridX + ',' + target.gridY + ']');
card.fire('click');
eq(tool.getState().currentPage, 1, '点击后跳到第 2 页');
eq(tool.getState().selectedKey, target.listKey, '同时选中该格');
eq(getEl('page-indicator').textContent, '第 2 / ' + tool.totalPages() + ' 页', '页指示同步');
eq(getEl('pill-page').textContent, '2/' + tool.totalPages(), '页码胶囊同步');
eq(tool.isDirty(), dirtyBefore, '跳转不标脏');

console.log('=== 3. 当前页的卡片不跳页 ===');
const samePageItem = st.charList.find(i => i.gridY < rpp && !!i.fighterID);
const card2 = findCard(samePageItem.gridX, samePageItem.gridY);
ok(!!card2, '当前页卡片存在');
// 先回第 1 页
tool.gotoPage(0);
card2.fire('click');
eq(tool.getState().currentPage, 0, '当前页点击不改变页号');
eq(tool.getState().selectedKey, samePageItem.listKey, '仍然选中');

console.log('=== 4. 辅助页各自按自己的 rowsPerPage 定位 ===');
tool.switchList('assistList');
const aSt = tool.getState();
const aGap = tool.calcGap(aSt.assistList);
const aRpp = aGap.rowsPerPage;
const aTarget = aSt.assistList.find(i => i.gridY === aRpp && !!i.fighterID) || aSt.assistList[aSt.assistList.length - 1];
const aPage = Math.floor(aTarget.gridY / aRpp);
const card3 = findCard(aTarget.gridX, aTarget.gridY);
ok(!!card3, '辅助页卡片存在 [' + aTarget.gridX + ',' + aTarget.gridY + ']');
card3.fire('click');
eq(tool.getState().currentPage, aPage, '辅助页跳到 gridY=' + aTarget.gridY + ' 的页 (页号 ' + aPage + ')');
eq(tool.getState().selectedKey, aTarget.listKey, '辅助页同时选中');
tool.switchList('charList');

console.log('=== 5. 越界/空列表安全 ===');
const emptyPageItem = { gridX: 0, gridY: 9999, fighterID: null, offset: { x: 0, y: 0 }, listKey: '0,9999' };
eq(tool.itemPageIndex(emptyPageItem), Math.floor(9999 / rpp), '极小 gridY 页号按公式');
const bigPage = tool.itemPageIndex(emptyPageItem);
tool.jumpToItem(emptyPageItem);
eq(tool.getState().currentPage, Math.min(bigPage, tool.totalPages() - 1), '页号被钳到最后一页');

console.log('\n=== LIST-JUMP PASS（' + pass + ' 项断言） ===');
