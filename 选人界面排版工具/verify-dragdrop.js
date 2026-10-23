// 拖拽覆盖导入 — 状态机验证（默认实例/脏标记/确认谓词/导出清脏）
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
global.URL = { createObjectURL: () => 'blob:x', revokeObjectURL(){} };
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

// ---------- 断言小工具 ----------
let pass = 0;
function ok(cond, msg) {
  if (cond) { pass++; console.log('  ✓ ' + msg); }
  else { console.error('  ✗ FAIL: ' + msg); process.exitCode = 1; throw new Error('assert: ' + msg); }
}
function eq(a, b, msg) { ok(a === b, msg + ' (期望 ' + JSON.stringify(b) + ', 实际 ' + JSON.stringify(a) + ')'); }

console.log('=== 0. 静态检查（HTML 标记与新函数） ===');
ok(/id="drop-overlay"/.test(html), 'HTML 含 #drop-overlay');
ok(/id="overwrite-modal"/.test(html), 'HTML 含 #overwrite-modal');
ok(/id="overwrite-confirm"/.test(html), 'HTML 含 #overwrite-confirm');
ok(/id="overwrite-cancel"/.test(html), 'HTML 含 #overwrite-cancel');
ok(/function bindDragDrop/.test(js), '脚本含 bindDragDrop');
ok(/function handleDroppedFile/.test(js), '脚本含 handleDroppedFile');
ok(/function needsConfirmOverwrite/.test(js), '脚本含 needsConfirmOverwrite');

console.log('=== 1. 初始状态 ===');
eq(tool.isDefaultInstance(), true, '初始 isDefaultInstance=true');
eq(tool.isDirty(), false, '初始 isDirty=false');
eq(tool.needsConfirmOverwrite(), false, '初始 needsConfirmOverwrite=false');

console.log('=== 2. markDirty 标脏 ===');
tool.markDirty();
eq(tool.isDirty(), true, 'markDirty() 后 isDirty=true');
eq(tool.needsConfirmOverwrite(), false, '默认实例即使脏也不需确认');

console.log('=== 3. applyLoadedState 来源切换与清脏 ===');
const parsed = tool.parseXML(defaultXml);
tool.applyLoadedState(parsed, { isDefault: false, label: 'test.xml' });
eq(tool.isDefaultInstance(), false, '导入后 isDefaultInstance=false');
eq(tool.isDirty(), false, '导入后 isDirty=false');
eq(tool.needsConfirmOverwrite(), false, '导入但未改动 → 不需确认');
tool.markDirty();
eq(tool.needsConfirmOverwrite(), true, '导入且已改动 → 需确认');

console.log('=== 4. 恢复默认实例 ===');
tool.applyLoadedState(tool.parseXML(defaultXml), { isDefault: true });
eq(tool.isDefaultInstance(), true, '恢复默认后 isDefaultInstance=true');
eq(tool.isDirty(), false, '恢复默认后 isDirty=false');
tool.markDirty();
eq(tool.needsConfirmOverwrite(), false, '默认实例即使脏也不需确认');

console.log('=== 5. 导出清除脏标记 ===');
tool.applyLoadedState(tool.parseXML(defaultXml), { isDefault: false });
tool.markDirty();
eq(tool.isDirty(), true, '导出前 isDirty=true');
tool.exportXML();
eq(tool.isDirty(), false, 'exportXML() 后 isDirty=false');
eq(tool.needsConfirmOverwrite(), false, '导出后不需确认');

console.log('\n=== 全部 ' + pass + ' 项断言通过 ===');
