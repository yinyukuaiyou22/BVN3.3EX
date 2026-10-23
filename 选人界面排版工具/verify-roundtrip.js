// Round-trip test — load html default xml, simulate parse→modify→serialize→reparse
const fs = require('fs');
const path = require('path');

const html = fs.readFileSync(path.join(__dirname, 'select-layout-tool.html'), 'utf8');

// Extract default xml from script tag
const m = html.match(/<script type="application\/xml" id="default-xml">([\s\S]*?)<\/script>/);
const xmlText = m[1].trim();

// === Re-implement the JS parser/serializer to verify roundtrip ===
function parseOffset(str) {
  if (!str) return { x: 0, y: 0 };
  const p = str.split(',');
  return { x: +p[0] || 0, y: +p[1] || 0 };
}
function parseList(regex, xmlBody) {
  const rows = [...xmlBody.matchAll(regex)];
  return rows.map(rowM => {
    const rowOff = parseOffset(rowM[1]);
    // match all <item ...>...</item> in row
    const itemRe = /<item(?:\s+offset="([^"]*)")?\s*>([^<]*)<\/item>/g;
    const items = [...rowM[2].matchAll(itemRe)].map(im => {
      const itemOff = parseOffset(im[1]);
      return {
        offX: rowOff.x + (itemOff.x || 0),
        offY: rowOff.y + (itemOff.y || 0),
        id: (im[2] || '').trim() || null,
      };
    });
    return { rowOff, items };
  });
}

// Parse char_list
const charSection = xmlText.match(/<char_list>([\s\S]*?)<\/char_list>/)[1];
const charRows = parseList(/<row(?:\s+offset="([^"]*)")?\s*>([\s\S]*?)<\/row>/g, charSection);
console.log('[1] parsed char_list:', charRows.length, 'rows');
const charItemCount = charRows.reduce((s, r) => s + r.items.length, 0);
console.log('[2] char items:', charItemCount);

// Parse assist_list
const assistSection = xmlText.match(/<assist_list>([\s\S]*?)<\/assist_list>/)[1];
const assistRows = parseList(/<row(?:\s+offset="([^"]*)")?\s*>([\s\S]*?)<\/row>/g, assistSection);
console.log('[3] parsed assist_list:', assistRows.length, 'rows');
const assistItemCount = assistRows.reduce((s, r) => s + r.items.length, 0);
console.log('[4] assist items:', assistItemCount);

if (charRows.length !== 138) { console.error('FAIL: char rows'); process.exit(1); }
if (assistRows.length !== 13) { console.error('FAIL: assist rows'); process.exit(1); }
if (charItemCount !== 690) { console.error('FAIL: char items'); process.exit(1); }
if (assistItemCount !== 61) { console.error('FAIL: assist items'); process.exit(1); }

// === Modify: bump item[0,0] offset by (10, 20) and serialize back ===
charRows[0].items[0].offX += 10;
charRows[0].items[0].offY += 20;

// Re-serialize
function serializeList(name, rows) {
  const out = [`\t<${name}>`];
  rows.forEach(r => {
    out.push(`\t\t<row offset="${r.rowOff.x},${r.rowOff.y}">`);
    r.items.forEach(it => {
      const dx = it.offX - r.rowOff.x;
      const dy = it.offY - r.rowOff.y;
      const offAttr = (dx === 0 && dy === 0) ? '' : ` offset="${dx},${dy}"`;
      out.push(`\t\t\t<item${offAttr}>${it.id || ''}</item>`);
    });
    out.push('\t\t</row>');
  });
  out.push(`\t</${name}>`);
  return out.join('\n');
}

const newChar = serializeList('char_list', charRows);
const newAssist = serializeList('assist_list', assistRows);
const newXml = '<select_config>\n\n' +
  '\t<stage_setting>\n' +
  '\t\t<layout x="0" y="0" width="800" height="600" left="415" right="0" top="50" bottom="100"/>\n' +
  '\t</stage_setting>\n\n' +
  newChar + '\n\n' +
  newAssist + '\n\n' +
  '</select_config>\n';

console.log('[5] serialized, length =', newXml.length);

// Re-parse and verify item[0,0] was modified
const charSection2 = newXml.match(/<char_list>([\s\S]*?)<\/char_list>/)[1];
const charRows2 = parseList(/<row(?:\s+offset="([^"]*)")?\s*>([\s\S]*?)<\/row>/g, charSection2);
const item00 = charRows2[0].items[0];
console.log('[6] after roundtrip, char[0,0] =', item00);

// 2026-10-19b：select.xml 的 char_list <row offset="435,0"> 保留 x（清洗只归零 y），
// 因此 item 的绝对 offset = 行 offset + item offset；断言相对增量，避免把行偏移误判成回归。
const expX = charRows2[0].rowOff.x + 10;
const expY = charRows2[0].rowOff.y + 20;
if (item00.offX !== expX) { console.error('FAIL: offX not preserved, expected', expX, 'got', item00.offX); process.exit(1); }
if (item00.offY !== expY) { console.error('FAIL: offY not preserved, expected', expY, 'got', item00.offY); process.exit(1); }
console.log('[7] offset modification preserved through round-trip ✓');

console.log('\n=== ROUND-TRIP PASS ===');