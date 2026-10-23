// Logic test using __layoutTool exposure
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const html = fs.readFileSync(path.join(__dirname, 'select-layout-tool.html'), 'utf8');

// Stub DOM
const stubEl = (id) => ({
  id, tagName: 'div',
  textContent: '', value: '', style: {},
  classList: { add(){}, remove(){}, contains(){return false;} },
  children: [], childNodes: [],
  appendChild(){}, removeChild(){},
  addEventListener(){}, removeEventListener(){},
  scrollTop: 0, scrollHeight: 0, scrollTo(){}, scrollLeft: 0, scrollY: 0,
  innerHTML: '',
  getContext: () => stubCtx,
});
const stubCtx = {
  save(){}, restore(){}, clearRect(){}, beginPath(){}, closePath(){},
  moveTo(){}, lineTo(){}, quadraticCurveTo(){}, fill(){}, stroke(){},
  fillText(){}, strokeRect(){}, setLineDash(){}, fillRect(){}, strokeText(){},
  measureText(){ return { width: 10 }; }, rect(){}, arc(){}, ellipse(){}, translate(){},
  scale(){}, rotate(){}, clip(){}, drawImage(){}, createLinearGradient(){ return { addColorStop(){} }; },
  fillStyle: '', strokeStyle: '', lineWidth: 1,
  font: '', textAlign: '', textBaseline: '',
};
global.document = {
  getElementById: (id) => id === 'default-xml'
    ? { textContent: html.match(/<script type="application\/xml" id="default-xml">([\s\S]*?)<\/script>/)[1] }
    : stubEl(id),
  createElement: () => ({
    href: '', download: '', textContent: '',
    click(){}, appendChild(){}, removeChild(){},
    addEventListener(){}, removeEventListener(){},
    style: {}, classList: { add(){}, remove(){}, contains(){return false;} },
  }),
  addEventListener(){}, body: { appendChild(){}, removeChild(){} },
  activeElement: { tagName: 'BODY' },
};
global.window = { addEventListener(){} };
global.requestAnimationFrame = (cb) => {};
global.setTimeout = setTimeout;
global.Blob = function(){};
global.URL = { createObjectURL: () => '', revokeObjectURL() {} };
global.FileReader = function(){};

// Minimal DOMParser stub matching html's needs
global.DOMParser = class {
  parseFromString(text) {
    const errCheck = text.includes('<parsererror') || !text.includes('<select_config>');
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
        if (sel === 'parsererror') return errCheck ? {} : null;
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

// Extract main JS
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

try {
  vm.runInContext(js, ctx);
  console.log('[1] JS executed without throw');
} catch (e) {
  console.error('THROW:', e.message);
  console.error(e.stack);
  process.exit(1);
}

const api = ctx.__layoutTool;
console.log('[2] __layoutTool on ctx =', api ? 'set' : 'NOT SET');
console.log('[2b] ctx keys (sample):', Object.keys(ctx).slice(-10));
const api2 = ctx.window && ctx.window.__layoutTool;
console.log('[2c] window.__layoutTool =', api2 ? 'set' : 'NOT SET');
if (!api2 && !api) { console.error('FAIL: __layoutTool not exposed anywhere'); process.exit(1); }
const tool = api || api2;
// 2026-10-19b：数据断言与内嵌默认（138 行真实数据）解耦，换回旧 56 格 fixture
tool.setState(tool.parseXML(fs.readFileSync(path.join(__dirname, 'verify-fixture-56.xml'), 'utf8')));
console.log('[2] __layoutTool exposed');

const state = tool.getState();
if (!state) { console.error('FAIL: state is null'); process.exit(1); }
console.log('[3] state built:');
console.log('    layout:', JSON.stringify(state.layout));
console.log('    charList:', state.charList.length, 'items');
console.log('    assistList:', state.assistList.length, 'items');
console.log('    currentList:', state.currentList);

if (state.charList.length !== 56) { console.error('FAIL: char count'); process.exit(1); }
if (state.assistList.length !== 40) { console.error('FAIL: assist count'); process.exit(1); }

// === Test calcGap (3.9 mode) ===
const gap = tool.calcGap(state.charList);
console.log('[4] calcGap:', gap);
if (gap.H !== 4 || gap.V !== 14) { console.error('FAIL: H/V'); process.exit(1); }
// Expected (2026-10-19b 按页模型, fixture 14 行 → displayedVCount=7): gapX=(800-50-415-0)/3≈111.67, gapY=(600-50-50-100)/6≈66.67
console.log('[4b] expected gapX≈111.67, gapY≈66.67; got:', gap.gapX.toFixed(2), gap.gapY.toFixed(2));

// === Test calcItemPos ===
const pos = tool.calcItemPos(state.charList[0], gap);
console.log('[5] charList[0,0] pos:', pos);
if (Math.abs(pos.x - 415) > 0.5 || Math.abs(pos.y - 50) > 0.5) {
  console.error('FAIL: position mismatch'); process.exit(1);
}

// === Test undo stack ===
const undo = tool.getUndoStack(), redo = tool.getRedoStack();
console.log('[6] initial undo=', undo.length, 'redo=', redo.length);

// Modify + push
const origOff = { ...state.charList[0].offset };
api_pushUndoSnap = tool.pushUndoSnap;
api_pushUndoSnap();
state.charList[0].offset.x += 5;
state.charList[0].offset.y -= 3;
console.log('[7] after push + modify, undo.length =', undo.length);
if (undo.length < 1) { console.error('FAIL: undo not pushed'); process.exit(1); }

// Undo
redo.push(JSON.parse(JSON.stringify(state)));
const popped = undo.pop();
Object.assign(state, popped);
console.log('[8] after manual undo, char[0].offset =', state.charList[0].offset);
if (state.charList[0].offset.x !== origOff.x || state.charList[0].offset.y !== origOff.y) {
  console.error('FAIL: undo did not restore offset'); process.exit(1);
}

// === Test serializeXML ===
const out = tool.serializeXML();
console.log('[9] serializeXML length:', out.length);
if (!out.includes('<select_config>')) { console.error('FAIL: serialize missing root'); process.exit(1); }
if (!out.includes('小恶魔')) { console.error('FAIL: serialize missing first name'); process.exit(1); }

// === Round-trip ===
const reparsed = tool.parseXML(out);
console.log('[10] reparsed char=', reparsed.charList.length, 'assist=', reparsed.assistList.length);
if (reparsed.charList.length !== state.charList.length) { console.error('FAIL: char count'); process.exit(1); }
if (reparsed.assistList.length !== state.assistList.length) { console.error('FAIL: assist count'); process.exit(1); }
let allMatch = true;
for (let i = 0; i < state.charList.length; i++) {
  const a = state.charList[i], b = reparsed.charList[i];
  if (a.offset.x !== b.offset.x || a.offset.y !== b.offset.y || a.fighterID !== b.fighterID) {
    allMatch = false; console.error(`mismatch at ${i}: ${JSON.stringify(a)} vs ${JSON.stringify(b)}`); break;
  }
}
for (let i = 0; i < state.assistList.length; i++) {
  const a = state.assistList[i], b = reparsed.assistList[i];
  if (a.offset.x !== b.offset.x || a.offset.y !== b.offset.y || a.fighterID !== b.fighterID) {
    allMatch = false; console.error(`assist mismatch at ${i}: ${JSON.stringify(a)} vs ${JSON.stringify(b)}`); break;
  }
}
if (!allMatch) { console.error('FAIL: roundtrip'); process.exit(1); }
console.log('[11] all 96 items preserved through serialize/parse ✓');

console.log('\n=== FULL LOGIC TEST PASS ===');