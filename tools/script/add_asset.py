#!/usr/bin/env python3
"""
BVN 自动添加角色/辅助/地图工具
用法:
  python add_asset.py --mode wizard                          # 向导模式
  python add_asset.py --swf path/to/char.swf --name "角色名"  # 快速添加
  python add_asset.py --scan ./new_fighters/                 # 批量扫描
  python add_asset.py --mode config --config my_config.json  # 配置模式
"""

import argparse
import io
import json
import os
import re
import sys
import shutil
import logging
from datetime import datetime
from pathlib import Path
from PIL import Image

# ============================================================
# 路径常量
# ============================================================
PROJ_ROOT = Path(__file__).resolve().parent.parent.parent
ASSETS = PROJ_ROOT / "tools" / "Test" / "assets"
CONFIG_DIR = ASSETS / "config"
FACE_DIR = ASSETS / "face"
FIGHTER_DIR = ASSETS / "fighter"
ASSIST_DIR = ASSETS / "assist"
MAP_DIR = ASSETS / "map"

CONFIG_FILES = {
    "fighter": CONFIG_DIR / "fighter.xml",
    "select": CONFIG_DIR / "select.xml",
    "assist": CONFIG_DIR / "assist.xml",
    "map": CONFIG_DIR / "map.xml",
    "mission": CONFIG_DIR / "mission.xml",
}

LOG_FILE = Path(__file__).resolve().parent / "add_asset_log.txt"

# ============================================================
# 日志
# ============================================================
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("add_asset")

# ============================================================
# 配置
# ============================================================
DEFAULT_CONFIG = {
    "comic_type": "0",
    "face_format": "png",
    "bgm_url": "assets/bgm/ichigo.mp3",
    "bgm_rate": "70",
    "auto_backup": True,
}

# 占位图标准尺寸
FACE_SIZES = {
    "": (50, 50),       # 小头像
    "_b": (245, 62),    # 大头像
    "_m": (102, 64),    # 血条头像
    "_w": (300, 250),   # 胜利头像
}

# select.xml 中 item 的 X 偏移（仅填充中间可用槽位 -65 到 -155）
ITEM_X_OFFSETS = [-65, -80, -95, -110, -125, -140, -155]
# 行 Y 偏移步长
ROW_Y_STEP = 30

DRY_RUN = False

# ============================================================
# Step 2: XML 备份
# ============================================================
def backup_xml(xml_path):
    """创建 .bak 备份"""
    bak = Path(str(xml_path) + ".bak")
    if not DRY_RUN:
        shutil.copy2(xml_path, bak)
    log.info(f"  Backup: {xml_path.name} -> {bak.name}")
    return bak

# ============================================================
# Step 3: SWF 处理
# ============================================================
def gen_id(swf_path):
    """从 SWF 文件名生成 ID（去扩展名，空格→下划线）"""
    name = Path(swf_path).stem
    return name.replace(" ", "_")

def copy_swf(src, asset_type="fighter"):
    """复制 SWF 到目标目录，返回目标路径"""
    target_dir = {"fighter": FIGHTER_DIR, "assist": ASSIST_DIR, "map": MAP_DIR}[asset_type]
    if not DRY_RUN:
        target_dir.mkdir(parents=True, exist_ok=True)
    dst = target_dir / Path(src).name
    if dst.exists():
        return str(dst.relative_to(PROJ_ROOT)), True  # 已存在
    if not DRY_RUN:
        shutil.copy2(src, dst)
    log.info(f"  Copy SWF: {Path(src).name} -> {dst}")
    return str(dst.relative_to(PROJ_ROOT)), False

def check_duplicate(asset_id, config_name="fighter"):
    """检查 ID 是否已在 XML 中存在"""
    xml_path = CONFIG_FILES[config_name]
    content = xml_path.read_text(encoding="utf-8")
    pattern = rf'<{_xml_tag(config_name)}\s+id="{re.escape(asset_id)}"'
    return bool(re.search(pattern, content))

def _xml_tag(config_name):
    """返回 XML 中的节点标签名"""
    return {"fighter": "fighter", "select": "item", "assist": "fighter", "map": "map"}[config_name]

# ============================================================
# Step 4: fighter.xml 更新
# ============================================================
def add_to_fighter_xml(asset_id, name, comic_type, face_base, bgm_url=None, bgm_rate=None, start_frame="1"):
    """在 fighter.xml 末尾插入新角色"""
    xml_path = CONFIG_FILES["fighter"]
    backup_xml(xml_path)
    content = xml_path.read_text(encoding="utf-8")

    # 检查重复
    if check_duplicate(asset_id, "fighter"):
        log.error(f"  ID '{asset_id}' already exists in fighter.xml!")
        return False, "DUPLICATE"

    fmt = DEFAULT_CONFIG["face_format"]
    face_url = f"assets/face/{face_base}.{fmt}"
    bgm = bgm_url or DEFAULT_CONFIG["bgm_url"]
    rate = bgm_rate or DEFAULT_CONFIG["bgm_rate"]

    new_fighter = f'''
<fighter id="{asset_id}" name="{name}" comic_type="{comic_type}">
    <file url="assets/fighter/{asset_id}.swf" startFrame="{start_frame}"/>
    <face url="{face_url}" big_url="assets/face/{face_base}_b.{fmt}" bar_url="assets/face/{face_base}_m.{fmt}" win_url="assets/face/{face_base}_w.{fmt}"/>
    <contact>
        <friend></friend>
        <enemy></enemy>
    </contact>
    <bgm url="{bgm}" rate="{rate}"/>
</fighter>'''

    # 插入到 </fighter_config> 之前
    insert_pos = content.rfind("</fighter_config>")
    if insert_pos == -1:
        log.error("  fighter.xml: </fighter_config> not found!")
        return False, "PARSE_ERROR"

    new_content = content[:insert_pos] + new_fighter + "\n" + content[insert_pos:]
    if not DRY_RUN:
        xml_path.write_text(new_content, encoding="utf-8")
    log.info(f"  fighter.xml: added '{asset_id}' (name='{name}', comic_type={comic_type})")
    return True, "OK"

# ============================================================
# Step 5: select.xml 更新
# ============================================================
def add_to_select_xml(asset_id, comic_type):
    """优先填空 item，无空位追加新行。comic_type='0'→死神区，'1'→火影区"""
    xml_path = CONFIG_FILES["select"]
    backup_xml(xml_path)
    content = xml_path.read_text(encoding="utf-8")

    if check_duplicate(asset_id, "select"):
        log.error(f"  ID '{asset_id}' already exists in select.xml!")
        return False, "DUPLICATE"

    # 定位 faction 区域
    section_start, section_end = _find_select_section(content, comic_type)
    if section_start == -1:
        log.error("  select.xml: faction section not found!")
        return False, "PARSE_ERROR"

    section = content[section_start:section_end]
    rows = re.findall(r'<row\s+offset="([^"]+)"[^>]*>(.*?)</row>', section, re.DOTALL)

    # 1) 优先填空位
    for y_offset, row_content in rows:
        items = re.findall(r'<item\s+offset="([^"]+)">(.*?)</item>', row_content)
        for x_off, item_text in items:
            x_val = int(x_off.split(",")[0])  # offset="-65,0" -> -65
            if item_text.strip() == "" and x_val in ITEM_X_OFFSETS:
                old = f'<item offset="{x_off}"></item>'
                new = f'<item offset="{x_off}">{asset_id}</item>'
                if old in content:
                    if not DRY_RUN:
                        xml_path.write_text(content.replace(old, new, 1), encoding="utf-8")
                    log.info(f"  select.xml: filled empty slot (x={x_off}, y={y_offset}) -> '{asset_id}'")
                    return True, "FILLED"

    # 2) 无空位 → 追加新行
    last_y = max((int(r[0].split(",")[1]) for r in rows if "," in r[0]), default=0)
    new_y = last_y + ROW_Y_STEP
    # 前4个空位 + 第5个填入角色 + 后11个空位
    all_offsets = [-5, -20, -35, -50, -65, -80, -95, -110, -125, -140, -155, -170, -185, -200, -215]
    row_parts = []
    for x_val in all_offsets:
        if x_val == ITEM_X_OFFSETS[0]:  # -65: 第一个可用位填入角色
            row_parts.append(f'            <item offset="{x_val},0">{asset_id}</item>')
        else:
            row_parts.append(f'            <item offset="{x_val},0"></item>')
    new_row_items = "\n".join(row_parts)

    new_row = f'\n        <row offset="0,{new_y}">\n            <item offset="-5,0"></item>\n            <item offset="-20,0"></item>\n            <item offset="-35,0"></item>\n            <item offset="-50,0"></item>\n{new_row_items}\n        </row>'

    # 插入到所属 faction 区域末尾、下一 faction 注释之前
    insert_pos = section_end
    new_content = content[:insert_pos] + new_row + "\n" + content[insert_pos:]
    if not DRY_RUN:
        xml_path.write_text(new_content, encoding="utf-8")
    log.info(f"  select.xml: appended new row (y={new_y}) -> '{asset_id}'")
    return True, "APPENDED"

def _find_select_section(content, comic_type):
    """定位 select.xml 中的 faction 区域"""
    if comic_type == "0":
        pattern = r'<!-- =+.*死神.*=+ -->'
    else:
        pattern = r'<!-- =+.*火影.*=+ -->'
    matches = list(re.finditer(pattern, content))
    if not matches:
        return -1, -1
    start = matches[0].start()
    # 找下一个 faction 注释或 char_list 结束
    next_faction = re.search(r'<!-- =+.*(?:火影|JOJO|东方|其他).*=+ -->', content[start + 10:])
    if next_faction:
        end = start + 10 + next_faction.start()
    else:
        end = content.find("</char_list>", start)
    return start, end

# ============================================================
# Step 6: 占位图生成
# ============================================================
def generate_placeholder_images(base_name):
    """生成 4 张标准尺寸占位图"""
    fmt = DEFAULT_CONFIG["face_format"]
    results = []
    for suffix, size in FACE_SIZES.items():
        filename = f"{base_name}{suffix}.{fmt}"
        filepath = FACE_DIR / filename
        if filepath.exists():
            log.warning(f"  Face exists, skipping: {filename}")
            results.append((filename, True))
            continue
        if not DRY_RUN:
            img = Image.new("RGBA", size, (128, 128, 128, 255))
            img.save(filepath, format="PNG" if fmt == "png" else "JPEG")
        log.info(f"  Created placeholder: {filename} ({size[0]}x{size[1]})")
        results.append((filename, False))
    return results

# ============================================================
# 核心流程
# ============================================================
def add_asset(swf_path, name, asset_type="fighter", comic_type="0"):
    """添加单个资源的主流程"""
    asset_id = gen_id(swf_path)
    base_name = asset_id  # face 图片基础名同 ID

    log.info(f"--- Adding {asset_type}: id='{asset_id}', name='{name}' ---")

    # 1) 复制 SWF
    dst_path, existed = copy_swf(swf_path, asset_type)
    if existed:
        log.warning(f"  SWF already exists: {dst_path}")

    # 2) 生成占位图（fighter/assist 需要）
    if asset_type in ("fighter", "assist"):
        generate_placeholder_images(base_name)

    # 3) 更新 XML
    if asset_type == "fighter":
        ok, reason = add_to_fighter_xml(asset_id, name, comic_type, base_name)
        if ok:
            ok2, _ = add_to_select_xml(asset_id, comic_type)
            if not ok2:
                log.error("  select.xml update failed!")
        else:
            log.error(f"  fighter.xml update failed: {reason}")
            return False
    elif asset_type == "assist":
        ok, reason = add_to_assist_xml(asset_id, name, comic_type, base_name)
        if not ok:
            log.error(f"  assist.xml update failed: {reason}")
            return False
    elif asset_type == "map":
        ok, reason = add_to_map_xml(asset_id, name)
        if not ok:
            log.error(f"  map.xml update failed: {reason}")
            return False

    log.info(f"--- Done: {asset_id} ---")
    return True


# ============================================================
# assist.xml / map.xml / mission.xml 支持
# ============================================================
def add_to_assist_xml(asset_id, name, comic_type, face_base):
    """在 assist.xml 末尾插入新辅助角色"""
    xml_path = CONFIG_FILES["assist"]
    backup_xml(xml_path)
    content = xml_path.read_text(encoding="utf-8")

    if check_duplicate(asset_id, "assist"):
        log.error(f"  ID '{asset_id}' already exists in assist.xml!")
        return False, "DUPLICATE"

    fmt = DEFAULT_CONFIG["face_format"]
    new_entry = f'''
<fighter id="{asset_id}" name="{name}" comic_type="{comic_type}">
    <file url="assets/fighter/{asset_id}.swf" startFrame="1"/>
    <face url="assets/face/{face_base}.{fmt}" big_url="assets/face/{face_base}_b.{fmt}"/>
</fighter>'''

    insert_pos = content.rfind("</assist_config>")
    if insert_pos == -1:
        log.error("  assist.xml: </assist_config> not found!")
        return False, "PARSE_ERROR"

    new_content = content[:insert_pos] + new_entry + "\n" + content[insert_pos:]
    if not DRY_RUN:
        xml_path.write_text(new_content, encoding="utf-8")
    log.info(f"  assist.xml: added '{asset_id}'")
    return True, "OK"


def add_to_map_xml(asset_id, name):
    """在 map.xml 末尾插入新地图"""
    xml_path = CONFIG_FILES["map"]
    backup_xml(xml_path)
    content = xml_path.read_text(encoding="utf-8")

    if check_duplicate(asset_id, "map"):
        log.error(f"  ID '{asset_id}' already exists in map.xml!")
        return False, "DUPLICATE"

    new_entry = f'''
<map id="{asset_id}" name="{name}">
    <file url="assets/map/{asset_id}.swf"/>
    <img url="assets/map/{asset_id}.png"/>
    <bgm url="assets/bgm/32.mp3"/>
</map>'''

    insert_pos = content.rfind("</map_config>")
    if insert_pos == -1:
        log.error("  map.xml: </map_config> not found!")
        return False, "PARSE_ERROR"

    new_content = content[:insert_pos] + new_entry + "\n" + content[insert_pos:]
    if not DRY_RUN:
        xml_path.write_text(new_content, encoding="utf-8")
    log.info(f"  map.xml: added '{asset_id}'")
    return True, "OK"


# ============================================================
# 向导模式
# ============================================================
def wizard_mode():
    """交互式向导模式"""
    log.info("=== 向导模式 ===")

    # 1) SWF 路径
    swf_input = input("SWF 文件路径（或目录路径批量扫描）: ").strip().strip('"')
    if not swf_input or not Path(swf_input).exists():
        log.error(f"文件不存在: {swf_input}")
        return

    swf_path = Path(swf_input)
    swf_files = []
    if swf_path.is_dir():
        swf_files = sorted(swf_path.glob("*.swf"))
        log.info(f"扫描到 {len(swf_files)} 个 SWF 文件")
        if not swf_files:
            log.error(f"目录中无 .swf 文件: {swf_input}")
            return
    else:
        swf_files = [swf_path]

    # 2) 类型
    atype = input("添加类型 [fighter/assist/map]（默认 fighter）: ").strip() or "fighter"
    if atype not in ("fighter", "assist", "map"):
        log.error(f"无效类型: {atype}")
        return

    # 3) 阵容
    ctype = input("阵容 [0=死神 / 1=火影]（默认 0）: ").strip() or "0"
    if ctype not in ("0", "1"):
        log.error(f"无效阵容: {ctype}")
        return

    # 4) 处理每个 SWF
    for sf in swf_files:
        asset_id = gen_id(sf)
        log.info(f"\n处理: {sf.name} -> ID: {asset_id}")
        name_input = input(f"  中文名（回车使用 '{asset_id}'）: ").strip()
        name = name_input if name_input else asset_id

        # 确认
        confirm = input(f"  添加 {atype} '{asset_id}' ({name})? [Y/n]: ").strip().lower()
        if confirm and confirm != "y":
            log.info(f"  跳过: {asset_id}")
            continue

        add_asset(str(sf), name, atype, ctype)

    log.info("\n=== 完成 ===")


# ============================================================
# 图片后缀自动识别（为已有图片自动加 _b/_m/_w 后缀）
# ============================================================
def auto_detect_face_suffixes():
    """扫描 face/ 目录，按尺寸自动识别图片类型并重命名"""
    log.info("=== 图片后缀自动识别 ===")
    renamed = 0
    for f in sorted(FACE_DIR.glob("*")):
        if not f.suffix.lower() in (".png", ".jpg", ".jpeg"):
            continue
        try:
            img = Image.open(f)
            w, h = img.size
        except Exception:
            continue

        stem = f.stem
        # 已带后缀的跳过
        if stem.endswith(("_b", "_m", "_w")):
            continue

        detected = None
        for suffix, (tw, th) in FACE_SIZES.items():
            if suffix == "":
                continue
            if abs(w - tw) <= 10 and abs(h - th) <= 10:
                detected = suffix
                break

        if detected:
            new_name = f"{stem}{detected}{f.suffix}"
            new_path = f.parent / new_name
            if new_path.exists():
                log.warning(f"  目标已存在，跳过: {f.name} -> {new_name}")
                continue
            if not DRY_RUN:
                f.rename(new_path)
            log.info(f"  Renamed: {f.name} -> {new_name} ({w}x{h})")
            renamed += 1

    log.info(f"共重命名 {renamed} 个文件")


# ============================================================
# 命令行
# ============================================================
def build_parser():
    p = argparse.ArgumentParser(description="BVN 自动添加角色/辅助/地图工具")
    p.add_argument("--mode", choices=["wizard", "config", "auto", "detect-faces"], default="wizard",
                   help="运行模式（默认 wizard）")
    p.add_argument("--swf", help="单个 SWF 文件路径")
    p.add_argument("--scan", help="批量扫描目录")
    p.add_argument("--name", help="角色中文名（--swf 时使用）")
    p.add_argument("--type", choices=["fighter", "assist", "map"], default="fighter",
                   help="添加类型（默认 fighter）")
    p.add_argument("--comic-type", choices=["0", "1"], default=None,
                   help="阵容: 0=死神, 1=火影")
    p.add_argument("--config", default=None, help="JSON 配置文件路径")
    p.add_argument("--save-config", default=None, help="保存当前设置到 JSON 文件")
    p.add_argument("--dry-run", action="store_true", help="仅预览，不实际修改")
    return p


def main():
    global DRY_RUN
    parser = build_parser()
    args = parser.parse_args()
    DRY_RUN = args.dry_run

    if DRY_RUN:
        log.info("*** DRY-RUN MODE — 不会修改任何文件 ***")

    log.info("=" * 60)
    log.info(f"BVN Asset Adder — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # 验证 XML 文件
    for name, path in CONFIG_FILES.items():
        if path.exists():
            log.info(f"  [OK] {name}: {path}")
        else:
            log.error(f"  [MISSING] {name}: {path}")

    log.info("=" * 60)

    if args.mode == "detect-faces":
        auto_detect_face_suffixes()
        return

    # 快速模式：--swf / --scan 优先于向导模式
    if args.swf or args.scan:
        if args.swf:
            swfs = [args.swf]
        else:
            scan_dir = Path(args.scan)
            if not scan_dir.is_dir():
                log.error(f"Not a directory: {args.scan}")
                return
            swfs = sorted(str(p) for p in scan_dir.glob("*.swf"))
            log.info(f"扫描到 {len(swfs)} 个 SWF 文件")

        comic_type = args.comic_type or DEFAULT_CONFIG["comic_type"]
        for sf in swfs:
            name = args.name or gen_id(sf)
            add_asset(sf, name, args.type, comic_type)
        return

    if args.mode == "wizard":
        wizard_mode()
        return

    # 无操作
    parser.print_help()


if __name__ == "__main__":
    main()

