
import xml.etree.ElementTree as ET
from collections import Counter

def load(p):
    root = ET.parse(p).getroot()
    st = root.find('stage_setting/layout')
    out = {'stage': {k: st.get(k) for k in ('x','y','width','height','left','right','top','bottom')}, 'lists': {}}
    for name in ('char_list','assist_list'):
        el = root.find(name); rows = el.findall('row'); items = []
        for r in rows:
            for it in r.findall('item'):
                items.append(((it.text or '').strip(), it.get('offset'), r.get('offset')))
        out['lists'][name] = {'rows': len(rows), 'items': items}
    return out

ref = load(r'tools\Test\assets\config\select.xml')
tgt = load(r'tools\Test\assets_pack\config\select.xml')

print('--- REF char: first item of each of first 8 rows ---')
for r in ref['lists']['char_list']['items'][:40]:
    if r[1] is None or r[2].endswith(',0') or True:
        pass
# first item per row (offset None)
seen=[]
prev=None
for name,off,ro in ref['lists']['char_list']['items']:
    if off is None: seen.append((ro,name))
print('row0-items (offset=None) count:', len(seen))
print('  first 8:', seen[:8])

print()
print('--- REF char: all distinct item offsets (non-None) ---')
c = Counter(o for _,o,_ in ref['lists']['char_list']['items'] if o is not None)
print(sorted(c.items())[:40])
print('distinct count:', len(c))

print()
print('--- REF assist: distinct item offsets ---')
c2 = Counter(o for _,o,_ in ref['lists']['assist_list']['items'] if o is not None)
print(sorted(c2.items())[:30])

print()
print('--- TARGET char rows: item count + names (first 3 rows) ---')
trows=[]
for name,off,ro in tgt['lists']['char_list']['items']:
    pass
# regroup by row
import itertools
root = ET.parse(r'tools\Test\assets_pack\config\select.xml').getroot()
for i,r in enumerate(root.find('char_list').findall('row')[:4]):
    print(i, r.get('offset'), [ (it.text or '').strip() for it in r.findall('item') ])
print()
print('--- TARGET assist rows ---')
for i,r in enumerate(root.find('assist_list').findall('row')):
    print(i, r.get('offset'), len(r.findall('item')))
print()
print('--- REF chr count by page under template ---')
rows=138
top,bot,phone=50,110,1380
vp=min(int(ref['stage']['height']),600)
usable=vp-top-bot
rpp=usable//60
print('viewportH',vp,'usableH',usable,'rowsPerPage',rpp)
gapY=(vp-60-top-bot)/(min(rows,rpp)-1)
print('gapY',gapY)
print('total pages', -(-rows//rpp))
print('colgap if 5 cols w=900 left10 right20 unit60:', (900-60-10-20)/4)
print('colgap if 15 cols:', (900-60-10-20)/14)
