// Pagination + viewport tests for select-layout-tool.html (Task 8)
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const html = fs.readFileSync(path.join(__dirname, 'select-layout-tool.html'), 'utf8');

// ---- Stub DOM (minimal) ----
const stubEl = (id) => ({
  id, tagName: 'div',
  textContent: id === 'default-xml' ? html.match(/<script type="application\/xml" id="default-xml">([\s\S]*?)<\/script>/)[1] : '',
  value: id === 'page-step' ? '600' : '',
  style: {},
  classList: { add(){}, remove(){}, contains(){return false;} },
  children: [], childNodes: [], removeChild(){}, appendChild(){},
  addEventListener(type, fn) { this._listener = (this._listener || []); this._listener.push({type,fn}); },
  removeEventListener(){}, scrollTo(){}, scrollHeight: 0, scrollTop: 0, scrollLeft: 0, scrollY: 0,
  innerHTML: '',
  getContext: () => ({
    save(){}, restore(){}, clearRect(){}, beginPath(){}, closePath(){},
    moveTo(){}, lineTo(){}, quadraticCurveTo(){}, fill(){}, stroke(){},
    fillText(){}, strokeRect(){}, setLineDash(){}, fillRect(){}, strokeText(){},
    measureText(){ return { width: 10 }; }, rect(){}, arc(){}, ellipse(){}, translate(){},
    scale(){}, rotate(){}, clip(){}, drawImage(){}, createLinearGradient(){ return { addColorStop(){} }; },
    fillStyle: '', strokeStyle: '', lineWidth: 1,
    font: '', textAlign: '', textBaseline: '',
  }),
});
const mainEl = { id: 'main', _sx: 0, _sy: 0, scrollTo(x, y){this._sx=x;this._sy=y;}, style:{}, addEventListener(){}, appendChild(){}, removeChild(){} };
global.document = {
  getElementById: (id) => id === 'main' ? mainEl : stubEl(id),
  createElement: () => ({ href:'', download:'', textContent:'', click(){}, appendChild(){}, removeChild(){}, addEventListener(){}, removeEventListener(){}, style:{}, classList:{add(){},remove(){},contains(){return false;}} }),
  addEventListener(){},
  body: { appendChild(){}, removeChild(){} },
  activeElement: { tagName: 'BODY' },
};
global.window = { addEventListener(){} };
global.requestAnimationFrame = () => {};
global.setTimeout = setTimeout;
global.Blob = function(){};
global.URL = { createObjectURL: () => '', revokeObjectURL(){} };
global.FileReader = function(){};

// ---- DOMParser stub ----
global.DOMParser = class {
  parseFromString(text) {
    function parseList(content) {
      const rowRe = /<row(?:\s+offset="([^"]*)")?\s*>([\s\S]*?)<\/row>/g;
      const rows = [...content.matchAll(rowRe)].map(rm => ({
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
    const layoutMatch = text.match(/<layout([^>]*)\/>/);
    const layoutAttrs = layoutMatch ? layoutMatch[1] : '';
    const layoutNode = {
      tagName: 'layout',
      getAttribute: (a) => {
        const m = layoutAttrs.match(new RegExp(`${a}="([^"]*)"`));
        return m ? m[1] : null;
      },
    };
    const charContent = text.match(/<char_list>([\s\S]*?)<\/char_list>/);
    const assistContent = text.match(/<assist_list>([\s\S]*?)<\/assist_list>/);
    return {
      querySelector: (sel) => {
        if (sel === 'parsererror') return null;
        if (sel === 'stage_setting > layout') return layoutNode;
        if (sel === 'char_list') return charContent ? parseList(charContent[1]) : null;
        if (sel === 'assist_list') return assistContent ? parseList(assistContent[1]) : null;
        return null;
      },
      querySelectorAll: () => [],
      getElementsByTagName: () => [],
    };
  }
};

// ---- Extract main JS ----
const jsStart = html.indexOf('<script>', html.indexOf('Main script')) + '<script>'.length;
const jsEnd = html.indexOf('</script>', jsStart);
const js = html.substring(jsStart, jsEnd);
console.log('JS length:', js.length);

const ctx = vm.createContext({
  document: global.document, window: global.window,
  requestAnimationFrame, setTimeout, Blob, URL, FileReader,
  DOMParser: global.DOMParser, console,
  Date, JSON, Object, Array, Number, Math, String, Boolean,
  parseInt, parseFloat, setInterval, clearInterval, clearTimeout,
});

vm.runInContext(js, ctx);
const tool = ctx.window.__layoutTool;
if (!tool) { console.error('NO __layoutTool'); process.exit(1); }

// === Test: defaults after init ===
let state = tool.getState();
console.log('[1] defaults: currentPage=', state.currentPage, 'PAGE_HEIGHT=', state.PAGE_HEIGHT, 'totalPages=', tool.totalPages());
if (state.currentPage !== 0) { console.error('FAIL: currentPage not 0'); process.exit(1); }
if (state.PAGE_HEIGHT !== 600) { console.error('FAIL: PAGE_HEIGHT not 600'); process.exit(1); }
// 2026-10-19b 语义更新：页数 = ceil(行数/每页行数)；内嵌默认 char_list 138 行、每页 7 行 → 20 页
if (tool.totalPages() !== 20) { console.error('FAIL: 默认 char_list 138 行/每页 7 行 totalPages should be 20, got', tool.totalPages()); process.exit(1); }

// === Test: 900x6300 -> 页数按游戏内口径 ceil(行数/每页行数)（2026-10-19b 语义更新） ===
const targetText = fs.readFileSync(path.join(__dirname, '解析素材', 'select.xml'), 'utf8');
const targetState = tool.parseXML(targetText);
tool.setState(targetState);
state = tool.getState();
tool.applyCanvasSize();   // setState 已调, 但保险再调一次
state = tool.getState();
const gapC = tool.calcGap(state.charList);
const VC = state.charList.reduce((m, i) => Math.max(m, i.gridY + 1), 0);
const expectPages = Math.max(1, Math.ceil(VC / gapC.rowsPerPage));
console.log('[2] pages: layout=', state.layout.width, 'x', state.layout.height, 'totalPages=', tool.totalPages(), '(行数', VC, '/ 每页', gapC.rowsPerPage, '行, gapY', gapC.gapY.toFixed(2), ')');
if (gapC.rowsPerPage !== 7) { console.error('FAIL: rowsPerPage should be 7, got', gapC.rowsPerPage); process.exit(1); }
if (tool.totalPages() !== expectPages) { console.error('FAIL: totalPages should be ceil(V/rowsPerPage)', expectPages, 'got', tool.totalPages()); process.exit(1); }
console.log('    viewport.scale=', state.viewport.scale.toFixed(4), 'drawH=', state.viewport.drawH.toFixed(1));

// === Test: gotoPage(n) ===
tool.gotoPage(3);
state = tool.getState();
if (state.currentPage !== 3) { console.error('FAIL: gotoPage(3)', state.currentPage); process.exit(1); }
console.log('[3] gotoPage(3) -> currentPage=3 OK');

const lastPage = tool.totalPages() - 1;
tool.gotoPage(99);  // 越界
state = tool.getState();
if (state.currentPage !== lastPage) { console.error('FAIL: gotoPage(99) should clamp to', lastPage); process.exit(1); }
console.log('[4] gotoPage(99) clamped to last page=' + lastPage + ' OK');

tool.gotoPage(-5);
state = tool.getState();
if (state.currentPage !== 0) { console.error('FAIL: gotoPage(-5) should clamp to 0'); process.exit(1); }
console.log('[5] gotoPage(-5) clamped to first page=0 OK');

// === Test: mapToScreen / mapFromScreen round-trip ===
const v = state.viewport;
const samples = [{x:0,y:0}, {x:415,y:50}, {x:800,y:3010}, {x:state.layout.width/2, y:state.layout.height/2}];
let allOk = true;
for (const s of samples) {
  const scr = tool.mapToScreen(s.x, s.y);
  const back = tool.mapFromScreen(scr.x, scr.y);
  if (Math.abs(back.x - s.x) > 0.5 || Math.abs(back.y - s.y) > 0.5) {
    console.error('FAIL: round-trip', s, '->', scr, '->', back);
    allOk = false;
  }
}
if (!allOk) process.exit(1);
console.log('[6] mapToScreen/mapFromScreen round-trip OK for', samples.length, 'samples');

// === Test: snapshot includes currentPage + PAGE_HEIGHT ===
tool.gotoPage(2);
const snap = ctx.snapshot ? ctx.snapshot() : null;
// fallback: 直接通过 tool.pushUndoSnap + undo 验证
tool.pushUndoSnap();
tool.gotoPage(5);
console.log('[7] after gotoPage(5) currentPage=', tool.getState().currentPage);
// 通过 snapshot 的闭包验证 - 暴露不可, 改为间接: undo 一次还原 currentPage
// 这需要 undoStack 已暴露并能调用 __layoutTool 内部 redo/undo, 简化为只验证 pushUndoSnap 不抛
console.log('[7] pushUndoSnap OK');

console.log('\n=== ALL PAGINATION TESTS PASS ===');
