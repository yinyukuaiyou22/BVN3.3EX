
import xml.etree.ElementTree as ET, os
root = ET.parse(r'tools\Test\assets_pack\config\select.xml').getroot()
def ids(listname):
    out=[]
    for r in root.find(listname).findall('row'):
        for it in r.findall('item'):
            out.append((it.text or '').strip())
    return out
chars = ids('char_list'); ass = ids('assist_list')
base = r'tools\Test\assets_pack\fighter'
have = set()
for dirpath, dirnames, filenames in os.walk(base):
    for f in filenames:
        have.add(os.path.splitext(f)[0])
print('char items:', len(chars), 'unique:', len(set(chars)))
print('assist items:', len(ass), 'unique:', len(set(ass)))
print('char random count:', sum(1 for c in chars if c=='random'))
missing_c = [c for c in dict.fromkeys(chars) if c not in have]
missing_a = [a for a in dict.fromkeys(ass) if a not in have]
print('char ids with no matching swf name:', len(missing_c))
print('  sample:', missing_c[:15])
print('assist ids with no matching swf name:', len(missing_a))
print('  sample:', missing_a[:15])
