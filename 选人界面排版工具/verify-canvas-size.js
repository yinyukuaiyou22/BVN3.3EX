// Test canvas size dynamically follows layout (7-page 840x4100 case)
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const html = fs.readFileSync(path.join(__dirname, 'select-layout-tool.html'), 'utf8');
const targetText = fs.readFileSync(path.join(__dirname, '解析素材', 'select.xml'), 'utf8');

// Track canvas attribute changes
let lastWidth = 0, lastHeight = 0, widthHistory = [], heightHistory = [];
let canvasLeft = '', canvasTop = '', canvasTransform = '';

const stubCanvas = {
  id: 'canvas', tagName: 'canvas',
  get width() { return lastWidth; },
  set width(v) { lastWidth = v; widthHistory.push(v); },
  get height() { return lastHeight; },
  set height(v) { lastHeight = v; heightHistory.push(v); },
  get style() {
    return new Proxy({}, {
      set: (t, k, v) => {
        if (k === 'left') canvasLeft = v;
        if (k === 'top') canvasTop = v;
        if (k === 'transform') canvasTransform = v;
        t[k] = v;
        return true;
      },
      get: (t, k) => t[k] || '',
    });
  },
  getContext: () => ({
    save(){}, restore(){}, clearRect(){}, beginPath(){}, closePath(){},
    moveTo(){}, lineTo(){}, quadraticCurveTo(){}, fill(){}, stroke(){},
    fillText(){}, strokeRect(){}, setLineDash(){}, fillRect(){}, strokeText(){},
    measureText(){ return { width: 10 }; }, rect(){}, arc(){}, ellipse(){}, translate(){},
    scale(){}, rotate(){}, clip(){}, drawImage(){}, createLinearGradient(){ return { addColorStop(){} }; },
    fillStyle: '', strokeStyle: '', lineWidth: 1,
    font: '', textAlign: '', textBaseline: '',
  }),
  addEventListener(){}, removeEventListener(){},
};

// Element cache so vm and host share the SAME canvas object
const elCache = { canvas: stubCanvas };
const stubEl = (id) => {
  if (elCache[id]) return elCache[id];
  elCache[id] = {
    id, tagName: 'div',
    textContent: id === 'default-xml'
      ? html.match(/<script type="application\/xml" id="default-xml">([\s\S]*?)<\/script>/)[1]
      : '',
    value: '', style: {},
    classList: { add(){}, remove(){}, contains(){return false;} },
    children: [], childNodes: [],
    appendChild(){}, removeChild(){},
    addEventListener(){}, removeEventListener(){},
    scrollTop: 0, scrollHeight: 0, innerHTML: '',
    getContext: () => stubCanvas.getContext(),
  };
  return elCache[id];
};

const mainEl = {
  id: 'main', tagName: 'div',
  scrollTo(x, y) { this._sx = x; this._sy = y; },
  get _scroll() { return [this._sx || 0, this._sy || 0]; },
  addEventListener(){}, appendChild(){}, removeChild(){},
  style: {},
};

global.document = {
  getElementById: (id) => id === 'main' ? mainEl : stubEl(id),
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
global.requestAnimationFrame = () => {};
global.setTimeout = setTimeout;
global.Blob = function(){};
global.URL = { createObjectURL: () => '', revokeObjectURL() {} };
global.FileReader = function(){};

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

const jsStart = html.indexOf('<script>', html.indexOf('Main script')) + '<script>'.length;
const jsEnd = html.indexOf('</script>', jsStart);
const js = html.substring(jsStart, jsEnd);

const ctx = vm.createContext({
  document: global.document, window: global.window,
  requestAnimationFrame, setTimeout, Blob, URL, FileReader,
  DOMParser: global.DOMParser, console,
  Date, JSON, Object, Array, Number, Math, String, Boolean,
  parseInt, parseFloat, setInterval, clearInterval, clearTimeout,
});

try {
  vm.runInContext(js, ctx);
  console.log('JS executed OK');
} catch (e) {
  console.error('THROW:', e.message);
  process.exit(1);
}

const tool = ctx.__layoutTool || ctx.window.__layoutTool;
if (!tool) { console.error('NO __layoutTool'); process.exit(1); }
// 2026-10-19b：数据断言与内嵌默认（138 行真实数据）解耦，换回旧 56 格 fixture
tool.setState(tool.parseXML(fs.readFileSync(path.join(__dirname, 'verify-fixture-56.xml'), 'utf8')));

// Test 1: after init with default 800x600
console.log('\n[TEST 1] init with default xml (800x600)');
console.log('  state.layout:', JSON.stringify(tool.getState().layout));
console.log('  canvas.width:', lastWidth, 'expected 800');
console.log('  canvas.height:', lastHeight, 'expected 600');
console.log('  canvas.style.transform:', canvasTransform);
console.log('  canvas.style.left:', canvasLeft);
console.log('  canvas.style.top:', canvasTop);
if (lastWidth !== 800 || lastHeight !== 600) { console.error('FAIL: canvas size mismatch'); process.exit(1); }
if (canvasTransform !== 'scale(1)') { console.error('FAIL: zoom not reset'); process.exit(1); }

// stubCanvas already IS the canvas — its getter/setter record history directly
let vmW = lastWidth, vmH = lastHeight;

// Test 2: parse target file（当前 解析素材/select.xml: 900x6300，PAGE_HEIGHT=600）
console.log('\n[TEST 2] parse target (900x6300, single-page viewport)');
const result = tool.parseXML(targetText);
console.log('  state.layout:', JSON.stringify(result.layout));
// Use setState which mutates vm-internal state AND calls applyCanvasSize+resetCanvasView
tool.setState(result);
console.log('  after setState: vm-canvas=' + lastWidth + 'x' + lastHeight);
console.log('  widthHistory:', widthHistory);
console.log('  heightHistory:', heightHistory);
// viewport 模式: 物理画布永远 800x600; 视口按「单页」(PAGE_HEIGHT) 拟合, 而非整张 layout 高度
  if (lastWidth !== 800 || lastHeight !== 600) { console.error('FAIL: viewport canvas should be 800x600'); process.exit(1); }
  // 验证 viewport 已正确填充
  const tool2 = ctx.window.__layoutTool;
  const vp = tool2.getState().viewport;
  if (!vp) { console.error('FAIL: viewport not set'); process.exit(1); }
  // 单页拟合：scale = min(800/layout.width, 600/PAGE_HEIGHT)
  // 当前 select.xml：min(800/900, 600/600)=0.8889 → drawW=800, drawH≈533.3
  const expScale = Math.min(800 / result.layout.width, 600 / result.PAGE_HEIGHT);
  const expDrawW = result.layout.width * expScale;
  const expDrawH = result.PAGE_HEIGHT * expScale;
  if (Math.abs(vp.scale - expScale) > 1e-9) { console.error('FAIL: scale expected', expScale, 'got', vp.scale); process.exit(1); }
  if (Math.abs(vp.drawW - expDrawW) > 1e-6) { console.error('FAIL: drawW expected', expDrawW, 'got', vp.drawW); process.exit(1); }
  if (Math.abs(vp.drawH - expDrawH) > 1e-6) { console.error('FAIL: drawH expected', expDrawH, 'got', vp.drawH); process.exit(1); }
  console.log('  viewport ok: scale=' + vp.scale.toFixed(4) + ' drawW=' + vp.drawW.toFixed(1) + ' drawH=' + vp.drawH.toFixed(1) + ' offX=' + vp.offX + ' offY=' + vp.offY);

// Test 3: modify layout.width/height triggers canvas resize
console.log('\n[TEST 3] modify layout.width/height → canvas resize');
// Need to mutate the vm-internal state. Re-parse + setState
const s3 = tool.getState();
s3.layout.width = 1000;
s3.layout.height = 500;
ctx.applyCanvasSize();
console.log('  canvas.width:', lastWidth, 'expected 1000');
console.log('  canvas.height:', lastHeight, 'expected 500');
// viewport 模式: 修改 layout.width/height 不再 resize canvas (画布固定 800x600)
  if (lastWidth !== 800 || lastHeight !== 600) { console.error('FAIL: canvas should stay 800x600'); process.exit(1); }
  const tool3 = ctx.window.__layoutTool;
  const vp3 = tool3.getState().viewport;
  if (!vp3) { console.error('FAIL: viewport'); process.exit(1); }
  console.log('  viewport ok after layout change: scale=' + vp3.scale.toFixed(4));

// Test 4: minimum size guard
console.log('\n[TEST 4] zero width/height → minimum 50');
const s4 = tool.getState();
s4.layout.width = 0;
s4.layout.height = 0;
ctx.applyCanvasSize();
// viewport 模式: layout 最小保留 1 (避免除以 0); canvas 物理仍 800x600
console.log('  layout after guard:', s4.layout.width, 'x', s4.layout.height);
console.log('  canvas:', lastWidth, 'x', lastHeight);
if (s4.layout.width !== 1 || s4.layout.height !== 1) { console.error('FAIL: layout guard', s4.layout.width, s4.layout.height); process.exit(1); }
if (lastWidth !== 800 || lastHeight !== 600) { console.error('FAIL: canvas should stay 800x600'); process.exit(1); }
console.log('  viewport.min=1 guard ok')

// Test 5: widthHistory shows canvas was sized multiple times
console.log('\n[TEST 5] canvas resize history:');
console.log('  width history:', widthHistory);
console.log('  height history:', heightHistory);

console.log('\n=== ALL CANVAS-SIZE TESTS PASS ===');