// Test the stub DOMParser alone
const path = require('path'); const html = require('fs').readFileSync(path.join(__dirname, 'select-layout-tool.html'), 'utf8');
const m = html.match(/<script type="application\/xml" id="default-xml">([\s\S]*?)<\/script>/);
const xmlText = m[1].trim();
console.log('xml length:', xmlText.length);

// Reproduce stub
const DOMParser = class {
  parseFromString(text) {
    const errCheck = text.includes('<parsererror') || !text.includes('<select_config>');
    function parseList(content) {
      const rowRe = /<row(?:\s+offset="([^"]*)")?\s*>([\s\S]*?)<\/row>/g;
      const rows = [...content.matchAll(rowRe)].map(rm => {
        const rowOffsetStr = rm[1] || '';
        return {
          tagName: 'row',
          getAttribute: (a) => a !== 'offset' ? null : rowOffsetStr,
          children: (() => {
            const itemRe = /<item(?:\s+offset="([^"]*)")?\s*>([^<]*)<\/item>/g;
            return [...rm[2].matchAll(itemRe)].map(im => ({
              tagName: 'item',
              getAttribute: (a) => a !== 'offset' ? null : im[1] || '',
              textContent: im[2] || '',
              children: [],
            }));
          })(),
        };
      });
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

const doc = new DOMParser().parseFromString(xmlText);
console.log('parsererror:', doc.querySelector('parsererror'));
console.log('layout:', doc.querySelector('stage_setting > layout'));
const charList = doc.querySelector('char_list');
console.log('char_list children:', charList.children.length);
const firstRow = charList.children[0];
console.log('first row offset:', firstRow.getAttribute('offset'));
console.log('first row items:', firstRow.children.length);
console.log('first item text:', firstRow.children[0].textContent);
console.log('first item offset:', firstRow.children[0].getAttribute('offset'));