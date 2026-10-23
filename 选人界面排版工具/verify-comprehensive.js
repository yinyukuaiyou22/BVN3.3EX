// Comprehensive test: edge cases for sanitize
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ENTITY_RE = /&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/g;
const ANGLE_RE = /<(?!\/?[a-zA-Z][a-zA-Z0-9]*\s*\/?>|!\[CDATA\[|!--|\?|!DOCTYPE|!ELEMENT)/g;
function sanitizeItemText(t) {
  return t.replace(ENTITY_RE, '&amp;').replace(ANGLE_RE, '&lt;');
}
function sanitizeXMLText(text) {
  let out = text.replace(/<item(\s[^>]*)?>([\s\S]*?)<\/item>/g, (m, attrs, content) => {
    return `<item${attrs || ''}>${sanitizeItemText(content)}</item>`;
  });
  const cdataOpens = (out.match(/<!\[CDATA\[/g) || []).length;
  const cdataCloses = (out.match(/\]\]>/g) || []).length;
  if (cdataOpens > cdataCloses) {
    out = out.replace(/<\/select_config>\s*$/, (']]>'.repeat(cdataOpens - cdataCloses)) + '\n</select_config>');
  }
  return out;
}

function check(name, input, expectInOut) {
  const out = sanitizeXMLText(input);
  const ok = expectInOut.every(e => out.includes(e)) && !expectInOut.some(e => !input.includes(e) === false);
  // also verify no raw &
  const hasRawAmp = /&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/.test(out);
  const status = hasRawAmp ? '✗ raw &' : (ok ? '✓' : '?');
  console.log(`[${status}] ${name}`);
  if (status !== '✓') console.log('  in :', input);
  if (status !== '✓') console.log('  out:', out);
}

// 1. Bare &
check('bare & only', '<item>依神&紫</item>', ['依神&amp;紫']);
// 2. Already escaped &
check('escaped &amp; preserved', '<item>依神&amp;紫</item>', ['依神&amp;紫']);
// 3. Mixed bare + escaped
check('mixed & and &amp;', '<item>A & B &amp; C</item>', ['A &amp; B &amp; C']);
// 4. CDATA present
check('cdata round-trip', '<item><![CDATA[raw & text]]></item>', ['raw &amp; text']);
// 5. Real & in CDATA
check('real & not in CDATA', '<item>1 < 2</item>', ['1 &lt; 2']);
// 6. Self-closing
check('self-close item', '<item offset="0,0"/>', []);
// 7. Multiple bare &
check('multiple bare &', '<item>A & B & C</item>', ['A &amp; B &amp; C']);
// 8. Numeric entity
check('numeric entity', '<item>&#65; &amp; B</item>', ['&#65; &amp; B']);
// 9. Hex entity
check('hex entity', '<item>&#x41; &amp; B</item>', ['&#x41; &amp; B']);
// 10. CDATA unmatched
{
  const out = sanitizeXMLText('<select_config><item><![CDATA[unfinished</item></select_config>');
  const opens = (out.match(/<!\[CDATA\[/g) || []).length;
  const closes = (out.match(/\]\]>/g) || []).length;
  console.log(`[${closes >= opens ? '✓' : '✗'}] cdata unmatched: opens=${opens} closes=${closes}`);
}
// 11. <item> with bare < in offset attr (should NOT touch attribute)
{
  // bare < in attr would already be invalid, so just verify attr is left alone if it has bare <
  const out = sanitizeXMLText('<item offset="0,0">hello</item>');
  console.log(`[${out === '<item offset="0,0">hello</item>' ? '✓' : '✗'}] normal item preserved`);
}
// 12. <row> not touched
{
  const out = sanitizeXMLText('<row offset="0,0"><item>text</item></row>');
  console.log(`[${out.includes('<row offset="0,0">') ? '✓' : '✗'}] row not broken`);
}
// 13. Real target file
const targetFile = path.join(__dirname, '解析素材', 'select.xml');
const targetText = fs.readFileSync(targetFile, 'utf8');
const out = sanitizeXMLText(targetText);
const rawAmp = (out.match(/&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/g) || []).length;
const items = (out.match(/<item[^>]*>[\s\S]*?<\/item>/g) || []).length;
console.log(`[${rawAmp === 0 ? '✓' : '✗'}] target file sanitized: raw & = ${rawAmp} (want 0), items = ${items}`);

console.log('\nDone');