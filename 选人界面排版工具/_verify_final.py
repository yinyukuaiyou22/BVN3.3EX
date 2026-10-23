
import xml.etree.ElementTree as ET
import hashlib
for p in (r'tools\Test\assets_pack\config\select.xml', r'tools\Test\apk_assets\assets\config\select.xml'):
    root = ET.parse(p).getroot()
    st = root.find('stage_setting/layout')
    cl = root.find('char_list'); al = root.find('assist_list')
    ci = sum(len(r.findall('item')) for r in cl.findall('row'))
    ai = sum(len(r.findall('item')) for r in al.findall('row'))
    h = hashlib.md5(open(p,'rb').read()).hexdigest()
    print(p.split(chr(92))[-1], '| stage x=%s w=%s h=%s l=%s r=%s | char %d rows / %d items | assist %d rows / %d items | md5=%s' % (
        st.get('x'), st.get('width'), st.get('height'), st.get('left'), st.get('right'),
        len(cl.findall('row')), ci, len(al.findall('row')), ai, h))
