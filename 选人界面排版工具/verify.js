// Pure-JS smoke test — no external deps
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const html = fs.readFileSync(path.join(__dirname, 'select-layout-tool.html'), 'utf8');

// 1. Extract default xml
const m = html.match(/<script type="application\/xml" id="default-xml">([\s\S]*?)<\/script>/);
if (!m) { console.error('FAIL: default-xml not found'); process.exit(1); }
const xml = m[1].trim();
console.log('[1] default xml extracted, length =', xml.length);

// 2. Count rows + items
const rowCount = (xml.match(/<row /g) || []).length;
const itemCount = (xml.match(/<item/g) || []).length;
console.log('[2] row count =', rowCount, ' (expect 151: 138 char + 13 assist)');
console.log('[3] item count =', itemCount, ' (expect 751: 690 char + 61 assist)');
if (rowCount !== 151) { console.error('FAIL: row count mismatch'); process.exit(1); }
if (itemCount !== 751) { console.error('FAIL: item count mismatch'); process.exit(1); }

// 3. Check key layout attrs present
const layoutAttrs = ['x', 'y', 'width', 'height', 'left', 'right', 'top', 'bottom'];
for (const a of layoutAttrs) {
  if (!new RegExp(`${a}="`).test(xml.split('<layout')[1].split('/>')[0])) {
    console.error(`FAIL: layout missing attr ${a}`); process.exit(1);
  }
}
console.log('[4] all 8 layout attrs present');

// 4. Check first/last character names
const names = [...xml.matchAll(/<item(?:[^>]*)>([^<]*)<\/item>/g)].map(m => m[1]);
console.log('[5] sample names:', names.slice(0, 5), '...', names.slice(-3));
console.log('[5] total non-empty names:', names.filter(n => n.length > 0).length);

// 5. Verify well-formedness (strip comments, just confirm DOMParser-style XML is parseable
//    via simple regex-balance since real DOMParser needs xmldom)
// Simpler check: every <row> has matching </row>, every <item> has matching </item>
const stripped = xml.replace(/<!--[\s\S]*?-->/g, '');
function countPairs(name) {
  const open = (stripped.match(new RegExp(`<${name}(\\s[^>]*)?>`, 'g')) || []).length;
  const close = (stripped.match(new RegExp(`</${name}>`, 'g')) || []).length;
  return { open, close };
}
for (const name of ['select_config', 'stage_setting', 'char_list', 'assist_list', 'row', 'item']) {
  const { open, close } = countPairs(name);
  if (open !== close) { console.error(`FAIL: <${name}> open=${open} close=${close}`); process.exit(1); }
  console.log(`[6] <${name}>: open=${open} close=${close} ✓`);
}

// 6. Verify the main JS block syntax (extract & quick balance check)
const jsStart = html.indexOf('<script>', html.indexOf('Main script')) + '<script>'.length;
const jsEnd = html.indexOf('</script>', jsStart);
const js = html.substring(jsStart, jsEnd);
console.log('[7] main JS length =', js.length);
// 朴素括号计数会被字符串/正则/注释里的括号误伤，改用 vm.Script 编译做真实语法检查
try {
  new vm.Script(js);
  console.log('[8] JS syntax valid (vm.Script compile OK)');
} catch (e) {
  console.error('FAIL: JS syntax error:', e.message); process.exit(1);
}

// 7. Confirm key Task features present
const features = [
  ['parseXML', /function parseXML/],
  ['parseList', /function parseList/],
  ['calcGap (3.9 mode)', /function calcGap/],
  ['calcItemPos (3.9)', /function calcItemPos/],
  ['drawItem', /function drawItem/],
  ['drawSelection', /function drawSelection/],
  ['hitTest', /function hitTest/],
  ['applyZoom', /function applyZoom/],
  ['MAX_UNDO = 20', /MAX_UNDO = 20/],
  ['Ctrl+Z handler', /key.toLowerCase\(\) === 'z'/],
  ['Ctrl+S handler', /e.key.toLowerCase\(\) === 's'/],
  ['Escape handler', /e.key === 'Escape'/],
  ['Delete/Backspace handler', /Delete' \|\| e.key === 'Backspace'/],
  ['exportXML', /function exportXML/],
  ['serializeXML', /function serializeXML/],
  ['importXML', /function importXML/],
  ['showError toast (auto-hide)', /toastTimer = setTimeout/],
  ['pushUndoSnap', /function pushUndoSnap/],
  ['Q24 wheel handler', /'wheel'/],
  ['renderSegmentLayout', /function renderSegmentLayout/],
];
for (const [name, re] of features) {
  if (!re.test(html)) { console.error(`FAIL: missing feature ${name}`); process.exit(1); }
  console.log(`[OK] ${name}`);
}

console.log('\n=== ALL SMOKE CHECKS PASS ===');