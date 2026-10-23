
import xml.etree.ElementTree as ET, sys, json

def load(p):
    t = ET.parse(p); root = t.getroot()
    st = root.find('stage_setting/layout')
    out = {'stage': {k: st.get(k) for k in ('x','y','width','height','left','right','top','bottom')}, 'lists': {}}
    for name in ('char_list','assist_list'):
        el = root.find(name)
        rows = el.findall('row')
        items = []
        for r in rows:
            for it in r.findall('item'):
                items.append(((it.text or '').strip(), it.get('offset')))
        out['lists'][name] = {'rows': len(rows), 'items': len(items),
                              'row_offsets': [r.get('offset') for r in rows],
                              'per_row': [len(r.findall('item')) for r in rows],
                              'names': [i[0] for i in items]}
    return out

ref = load(r'tools\Test\assets\config\select.xml')
tgt = load(r'tools\Test\assets_pack\config\select.xml')
for tag, d in (('REF', ref), ('TARGET', tgt)):
    print('=====', tag, '=====')
    print('stage:', d['stage'])
    for k, v in d['lists'].items():
        print(f"  {k}: rows={v['rows']} items={v['items']} per_row={v['per_row'][:8]}...{v['per_row'][-3:]}")
        print(f"    row_offsets head={v['row_offsets'][:4]} tail={v['row_offsets'][-3:]}")
print()
print('REF char names == TARGET char names ?', ref['lists']['char_list']['names'] == tgt['lists']['char_list']['names'])
print('REF assist names == TARGET assist names ?', ref['lists']['assist_list']['names'] == tgt['lists']['assist_list']['names'])
sr = set(ref['lists']['char_list']['names']); st = set(tgt['lists']['char_list']['names'])
print('char: only-in-REF count', len(sr-st), 'only-in-TARGET count', len(st-sr))
print('  sample only-in-REF:', sorted(sr-st)[:10])
print('  sample only-in-TARGET:', sorted(st-sr)[:10])
print('target char first 5:', tgt['lists']['char_list']['names'][:5])
print('target char last 5:', tgt['lists']['char_list']['names'][-5:])
print('target assist count:', tgt['lists']['assist_list']['items'])
