// Find unescaped & in item text
const fs = require('fs');
const path = require('path');
const file = path.join(__dirname, '解析素材', 'select.xml');
const text = fs.readFileSync(file, 'utf8');

// Match <item ...>...</item> and check content for raw & not followed by amp; / lt; / gt; / quot; / apos; / #
const itemRe = /<item(?:\s+offset="[^"]*")?>([^<]*)<\/item>/g;
let m, count = 0, bad = 0;
const badList = [];
while ((m = itemRe.exec(text)) !== null) {
  count++;
  const content = m[1];
  // Find raw & not followed by valid entity
  if (/&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/.test(content)) {
    bad++;
    const before = text.substring(0, m.index);
    const lineNum = before.split('\n').length;
    badList.push({ line: lineNum, content });
  }
}
console.log(`Total items: ${count}, with raw & : ${bad}`);
badList.forEach(b => console.log(`  Line ${b.line}: "${b.content}"`));

// Also check <row> for same
const rowRe = /<row(?:\s+offset="[^"]*")?\s*>([\s\S]*?)<\/row>/g;
let badRows = 0;
const badRowList = [];
while ((m = rowRe.exec(text)) !== null) {
  const content = m[1];
  if (/&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/.test(content)) {
    badRows++;
    const before = text.substring(0, m.index);
    const lineNum = before.split('\n').length;
    badRowList.push({ line: lineNum, content: content.substring(0, 60) });
  }
}
console.log(`\nRows with raw & (but only inside item content): ${badRows}`);

// Also check overall file for raw & in non-entity context
const allAmp = [...text.matchAll(/&(?!(amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/g)];
console.log(`\nTotal raw & in file: ${allAmp.length}`);
allAmp.slice(0, 30).forEach(a => {
  const before = text.substring(0, a.index);
  const lineNum = before.split('\n').length;
  const line = text.split('\n')[lineNum - 1];
  console.log(`  Line ${lineNum}: "${line.trim()}"`);
});
