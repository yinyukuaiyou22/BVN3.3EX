# `select.xml` 解析流程速查

> 本文档从 xml 出发，逐步映射到代码，给"想从 xml 一边改、一边查代码"的人使用。

---

## 1. xml 节点 → 代码接收者 总图

```
select.xml
│
├── <select_config>                          SelectStageConfigVO                (data/SelectStageConfigVO.as)
│   │
│   ├── <stage_setting>
│   │   └── <layout x y w h left right top bottom />
│   │                                                                       ↑ SelectStageConfigVO.x/y/width/height/left/right/top/bottom
│   │
│   ├── <char_list>                          SelectCharListConfigVO            (data/SelectCharListConfigVO.as)
│   │   └── <row offset="X,Y">                                                  (SelectStageConfigVO.charList)
│   │       └── <item offset="a,b">fighter_id
│   │           └── <plugin id="..."/>                                        SelectCharListItemVO (data/SelectCharListItemVO.as)
│   │                                                                          ↑ SelectCharListItemVO.{x, y, fighterID, offset, pluginIDs}
│   │
│   └── <assist_list>                        SelectCharListConfigVO            (SelectStageConfigVO.assistList)
│       └── ... 同上结构
│
│
│  运行时数据：
│  SelectVO (data/SelectVO.as)
│  ├── p1Select: { fighter1, fighter2, fighter3, fuzhu }     ← 玩家选完后的结果
│  └── p2Select: { fighter1, fighter2, fighter3, fuzhu }
```

---

## 2. 调用链详解

### 2.1 加载阶段

```
GameData.loadConfig()
   [data/GameData.as:44]
   │
   ├── loadXML("assets/config/fighter.xml")   → FighterModel.I.initByXML()
   ├── loadXML("assets/config/assist.xml")    → AssisterModel.I.initByXML()
   ├── loadXML("assets/config/select.xml")    → config.select_config.setByXML()   ← 关键入口
   │                                                │
   │                                                ▼
   │                                       SelectStageConfigVO.setByXML()
   │                                       [data/SelectStageConfigVO.as:35]
   │                                       │
   │                                       ├── param1.stage_setting.layout
   │                                       │     → SelectStageConfigVO.{x, y, width, height,
   │                                       │                              top, bottom, left, right}
   │                                       │
   │                                       ├── param1.char_list
   │                                       │     → newListByXML() → SelectCharListConfigVO
   │                                       │     → SelectStageConfigVO.charList
   │                                       │
   │                                       └── param1.assist_list
   │                                             → newListByXML() → SelectCharListConfigVO
   │                                             → SelectStageConfigVO.assistList
   │
   ├── loadXML("assets/config/map.xml")       → MapModel.I.initByXML()
   └── loadXML("assets/config/mission.xml")   → MessionModel.I.initByXML()
```

### 2.2 `newListByXML()` 详细流程

```as3
// data/SelectStageConfigVO.as:50
private function newListByXML(param1:XMLList) : SelectCharListConfigVO {
   var list:SelectCharListConfigVO = new SelectCharListConfigVO();
   list.VCount = param1.children().length();   // row 数

   for each (var row:XML in param1.row) {            // 遍历所有 <row>
      var rowOffset:Point = parseOffset(row.@offset); // "X,Y" → Point(X, Y)

      list.HCount = max(list.HCount, row.children().length()); // 记录最大行宽

      for each (var item:XML in row.children()) {    // 遍历每个 <item>
         var fighterID:String = item.text();         // ⚠️ 批次 6.6 修复：必须 .text() 不能 .toString()
         var itemOffset:Point = parseOffset(item.@offset); // "a,b"

         // 合并 row + item offset（累加）
         var finalOffset:Point = (rowOffset) ?
            rowOffset.clone().add(itemOffset) : itemOffset;

         // item 的 x/y 是它在网格中的位置（不是从 xml 读，是循环 index）
         var itemVO:SelectCharListItemVO =
            new SelectCharListItemVO(colIndex, rowIndex, fighterID, finalOffset);

         // 批次 6.1：plugin 子节点
         if (item.plugin.length() > 0) {
            itemVO.pluginIDs = [];
            for each (var plugin:XML in item.plugin) {
               itemVO.pluginIDs.push(plugin.@id);
            }
         }

         list.list.push(itemVO);
      }
   }

   return list;
}
```

### 2.3 运行时使用阶段

```
MainGame.goSelect() → KyoStageCtrl → SelectFighterStage.build()
   [state/SelectFighterStage.as:95]
   │
   ├── ResUtils.I.createDisplayObject(select.swf)  ← 整张背景 + UI 容器
   ├── GameData.I.config.select_config            ← 拿到 SelectStageConfigVO（已含 charList + assistList）
   ├── GameRender.add(this.render)                ← 注册每帧回调
   ├── GameInputer.enabled = false                ← 先禁用输入
   └── nextStep()                                 ← step 0 → initFighter()
        │
        └── initFighter()
             │
             ├── this._selectState = 0  (角色阶段)
             ├── SELECT_STATE = 0      (静态，供 select.swf 帧脚本 clear() 读)
             ├── buildList(this._config.charList)
             │    │
             │    ├── 计算 PAGE_HEIGHT / TOTAL_PAGES / CURRENT_PAGE
             │    │
             │    ├── for each (itemVO in charList.list) {
             │    │      var item = addFighterItem(itemVO);
             │    │      // 落点公式：
             │    │      //   pageIdx   = item.y / rowsPerPage
             │    │      //   yInPage   = item.y % rowsPerPage
             │    │      //   finalX    = config.x + config.left + 45 * item.x + item.offset.x
             │    │      //   finalY    = config.y + config.top  + 60 * yInPage + pageIdx * PAGE_HEIGHT
             │    │      //                                                       + item.offset.y
             │    │      TweenLite.to(item.ui, 0.3, { x: finalX, y: finalY, scaleX: 1, scaleY: 1, ease: Back.easeOut });
             │    │
             │    │      // 批次 6.8 plugin 子框构建
             │    │      if (fighterVO.pluginIDs?.length > 0) {
             │    │         for (i; i < pluginIDs.length) {
             │    │            var pItemVO = new SelectCharListItemVO(col, row, pluginId, offset);
             │    │            var pItem = addFighterItem(pItemVO, isPlugin=true, parent=item, pluginIndex=i);
             │    │            pItem.gridOffset = [8方位][i];
             │    │            pItem.pendingTweenParams = { x: 主X+45*gridOffset.x, y: 主Y+60*gridOffset.y };
             │    │         }
             │    │         item.updateBadge(pluginIDs.length);
             │    │      }
             │    │   }
             │    │
             │    └── 重新计算 _pagArr = [0, -PAGE_HEIGHT, -2*PAGE_HEIGHT, ...]
             │
             ├── GameData.I.p1Select = new SelectVO();
             ├── if (isVsPeople || isVsCPU) GameData.I.p2Select = new SelectVO();
             ├── GameInputer.enabled = false;
             └── setTimeout(initSelecter, 500);   ← 延迟 500ms 启用输入
        │
        └── initSelecter()
             │
             ├── if (isVsPeople) {
             │      initSelecterP1();
             │      initSelecterP2();
             │   } else {
             │      initSelecterP1();
             │   }
             │
             ├── initSelecterP1()
             │    ├── SelectUIFactory.createSelecter(1) → SelecterItemUI
             │    │    └── new SelectedFighterGroup("selected_item_p1_mc")
             │    │           position: (100, GAME_SIZE.y - 265)
             │    └── moveSlt(p1Slt, 0, 0)  ← 选择框初始在 (0,0)
             │
             └── initSelecterP2()
                  ├── SelectUIFactory.createSelecter(2)
                  └── moveSlt(p2Slt, 9, 0)  ← P2 选择框初始在右下角
```

---

## 3. xml 字段全表

### 3.1 `<stage_setting>` 容器布局

| 属性 | 默认 | 含义 | 代码字段 |
|---|---|---|---|
| `x` | `0` | 整体偏移 X | `SelectStageConfigVO.x` |
| `y` | `0` | 整体偏移 Y | `SelectStageConfigVO.y` |
| `width` | `800` | 网格总宽 | `SelectStageConfigVO.width` |
| `height` | `600` | 网格总高（=**PAGE_HEIGHT**） | `SelectStageConfigVO.height` |
| `left` | `415` | 左边距（叠加 x） | `SelectStageConfigVO.left` |
| `right` | `0` | 右边距（暂未使用） | `SelectStageConfigVO.right` |
| `top` | `50` | 上边距（叠加 y） | `SelectStageConfigVO.top` |
| `bottom` | `100` | 下边距（暂未使用） | `SelectStageConfigVO.bottom` |

### 3.2 `<char_list>` / `<assist_list>` 行布局

每个 row：

| 字段 | 含义 | 解析位置 |
|---|---|---|
| `offset="X,Y"` | 整行相对 `_config.x + _config.left` 的额外偏移 | `newListByXML` 行 70-75 |

### 3.3 `<item>` 单个角色/辅助

| 字段 | 含义 | 代码字段 |
|---|---|---|
| 文本节点 | 角色 ID（对应 `fighter.xml` / `assist.xml` 的 fighter.id） | `SelectCharListItemVO.fighterID` |
| `offset="a,b"` | 相对 row 的额外偏移 | 累加进 `SelectCharListItemVO.offset` |
| `<plugin id="..."/>` | 子角色 ID 列表（**当前未启用**，当前 select.xml 无 plugin 节点） | `SelectCharListItemVO.pluginIDs:Array` |

**重要：item 的网格坐标 (x, y) 不是从 xml 读的，是循环 index**：
- `itemVO.x` = 当前 row 中 item 的列下标（0, 1, 2, 3）
- `itemVO.y` = row 在父列表中的行下标（0, 1, 2, ...）

---

## 4. xml 解析的 3 个修复点

### 4.1 批次 6.6 — fighterID 解析修复
```diff
- _loc9_ = _loc8_.toString();   // ❌ 会序列化整段 XML（含 plugin 子节点），导致 FighterModel 查不到
+ _loc9_ = _loc8_.text();       // ✅ 只取 <item> 文本节点
```
位置：`SelectStageConfigVO.as:87`

### 4.2 批次 6.1 — plugin 子节点解析新增
```as3
// SelectStageConfigVO.as:110-117
if (_loc8_.plugin.length() > 0) {
   _loc13_.pluginIDs = [];
   for each (var _loc15_:XML in _loc8_.plugin) {
      _loc13_.pluginIDs.push(String(_loc15_.@id));
   }
}
```

### 4.3 批次 6.7 — face 缺失占位
```as3
// SelectFighterItem.as:80-92
if (!_loc3_) {
   // 用 TextField 显示角色名（治标）
   var _loc3a_:TextField = new TextField();
   _loc3a_.text = this.fighterData.id;
   ...
   this.ui.ct.addChild(_loc3a_);
   // 治本：ENTER_FRAME 轮询缓存，命中后自动刷新
   this.addEventListener(Event.ENTER_FRAME, this._refreshFace);
}
```

---

## 5. xml 修改 → 代码修改 速查

| 想做的事 | 只改 xml | 需改代码 |
|---|---|---|
| 增/删/换角色 | ✅ | — |
| 调整角色位置 | ✅（改 row/item offset） | — |
| 调整单格宽度/行距 | ❌ | ✅ `SelectFighterStage.buildList` 行 244-245 |
| 调整分页高度 | ❌ | ✅ `SelectFighterStage.buildList` 行 267 + 静态 32 |
| 调整 P1/P2 已选框位置 | ❌ | ✅ `SelectUIFactory.createSelecter` 行 24-25 |
| 启用 plugin 子框 | ✅（加 `<plugin id="..."/>`） | — |
| 调整 plugin 8 方位 | ❌ | ✅ `SelectFighterStage.buildList` 行 315 |
| 调整 map 选图位置 | ❌ | ✅ `MapSelectUI.build` 行 97-98 |

> **tip**: 改完 xml 必须重新编译 (`./build.bat`) → 产出 `tools/Test/launch.swf` → 打包 APK 生效。