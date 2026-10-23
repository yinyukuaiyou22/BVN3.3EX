
import xml.etree.ElementTree as ET, os
fv = ET.parse(r'tools\Test\assets_pack\config\fighter.xml').getroot()
field = ET.parse(r'tools\Test\assets_pack\config\select.xml').getroot()
ids = []
for f in fv.iter():
    if f.tag == 'fighter':
        ids.append(f.get('id'))
print('fighter.xml entries:', len(ids))
sel = []
for r in field.find('char_list').findall('row'):
    for it in r.findall('item'):
        sel.append((it.text or '').strip())
print('select.xml char items:', len(sel))
uniq_sel = list(dict.fromkeys(sel))
print('unique select ids:', len(uniq_sel))
print('select ids NOT in fighter.xml:', len([s for s in uniq_sel if s not in set(ids)]))
print('  sample:', [s for s in uniq_sel if s not in set(ids)][:10])
print('fighter.xml ids NOT in select:', len([i for i in ids if i not in set(uniq_sel)]))
print()
print('--- first 3 fighter.xml <fighter> lines ---')
import re
txt = open(r'tools\Test\assets_pack\config\fighter.xml', encoding='utf-8').read()
for m in list(re.finditer(r'<fighter\b[^>]*>', txt))[:3]:
    print(m.group(0))
print()
print('--- fighter dir file count by subdir ---')
for d in sorted(os.listdir(r'tools\Test\assets_pack\fighter')):
    p = os.path.join(r'tools\Test\assets_pack\fighter', d)
    if os.path.isdir(p):
        print(' ', d, len([f for f in os.listdir(p) if f.lower().endswith('.swf')]))
