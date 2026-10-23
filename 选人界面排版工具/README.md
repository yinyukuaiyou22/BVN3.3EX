# 选人界面排版工具 — 索引文档

> 本文档梳理 `select.xml`（选人界面布局配置）相关的所有解析与布局控制代码，便于在排版/调参时快速定位入口。
>
> 维护范围：`BVNscripts/scripts/` 下与选人/选图界面相关的所有 `.as` 文件 + `assets/config/select.xml` 配置本身。

---

## 目录

1. [配置文件入口](#1-配置文件入口)
2. [数据模型 VO 层](#2-数据模型-vo-层)
3. [选人状态控制器（核心布局逻辑）](#3-选人状态控制器核心布局逻辑)
4. [UI 组件层](#4-ui-组件层)
5. [关键常量与排版参数速查](#5-关键常量与排版参数速查)
6. [数据加载链路](#6-数据加载链路)
7. [xml 字段 ↔ 代码映射表](#7-xml-字段--代码映射表)
8. [常见修改场景索引](#8-常见修改场景索引)

---

## 1. 配置文件入口

| 文件 | 行数 | 说明 |
|---|---|---|
| `BVNscripts/scripts/../tools/Test/assets/config/select.xml` | 189 | 选人界面布局主配置（角色网格 + 辅助网格 + 容器布局） |

### 1.1 `select.xml` 顶层结构

```xml
<select_config>
   <stage_setting>
      <layout x="0" y="0" width="800" height="600" left="415" right="100" top="50" bottom="40"/>
   </stage_setting>
   <char_list>...</char_list>   <!-- 角色网格 -->
   <assist_list>...</assist_list> <!-- 辅助网格 -->
</select_config>
```

### 1.2 `<row>` 行节点
- 属性 `offset="X,Y"`：整行相对锚点的偏移（**每个 item 的 offset 是叠加在 row offset 之上的累加值**）。
- 子节点 `<item>`：单个角色/辅助。

### 1.3 `<item>` 节点
- 属性 `offset="X,Y"`：相对当前 row 的额外偏移（与 `row offset` 累加后决定最终落点）。
- 文本节点：角色 ID 字符串（即 `fighter.id`，对应 `fighter.xml` / `assist.xml` 中定义的角色）。
- 文本为空 → 留空占位（仍占网格位，但 `SelectFighterStage.addFighterItem` 会跳过）。
- 子节点 `<plugin id="...">`（批次 6.1+）：子角色 ID 列表（展开式 sub-frame，本项目当前 select.xml 未触发）。

---

## 2. 数据模型 VO 层

所有解析后的数据通过 VO 流转，VO 是 xml 字段在代码中的最终归宿。

| VO | 文件 | 用途 | 关键字段 |
|---|---|---|---|
| `SelectStageConfigVO` | `data/SelectStageConfigVO.as` | 顶层容器：layout + charList + assistList | `x/y/width/height/top/bottom/left/right` + `charList/assistList/unitSize` |
| `SelectCharListConfigVO` | `data/SelectCharListConfigVO.as` | 单列表（角色列表 / 辅助列表）的容器 | `list:Array` + `HCount`（行最大宽度） + `VCount`（行数） |
| `SelectCharListItemVO` | `data/SelectCharListItemVO.as` | 单个 item 数据 | `x/y`(网格坐标) + `fighterID` + `offset:Point` + `pluginIDs:Array`（批次 6.1+） |
| `SelectVO` | `data/SelectVO.as` | 玩家已选数据（运行时） | `fighter1/2/3` + `fuzhu` |

---

## 3. 选人状态控制器（核心布局逻辑）

### 3.1 主文件

**`BVNscripts/scripts/net/play5d/game/bvn/state/SelectFighterStage.as`**（1323 行）

整个选人流程的中央控制器。xml 解析 → 列表构建 → 玩家移动 → 选图 → 完成，全在这一个类里。

### 3.2 关键方法（按调用链）

| 方法 | 行号 | 作用 | xml/排版相关 |
|---|---|---|---|
| `build()` | 95 | 入口：`ResUtils.I.createDisplayObject(ResUtils.I.select, ResUtils.SELECT)` 加载 `select.swf` + 注册渲染 | — |
| `initFighter()` | 114 | 初始化角色选人阶段，调用 `buildList(charList)` | — |
| `initAssist()` | 136 | 初始化辅助选人阶段，调用 `buildList(assistList)` | — |
| **`buildList(SelectCharListConfigVO)`** | **233** | **核心布局函数：遍历 item、计算坐标、生成 `SelectFighterItem`、添加到 UI** | **√** |
| `addFighterItem(...)` | 361 | 单个 item 的工厂：从 `FighterModel` / `AssisterModel` 取数据 + 构造 `SelectFighterItem` + 挂事件 | — |
| `moveSlt(SelecterItemUI, x, y)` | 696 | 选择框移动（带环绕 + 跳过已选） | — |
| `moveToSelectFighter(...)` | 821 | 选择框吸附到目标角色 | — |
| `render()` | 926 | 每帧：处理方向键输入 + 选择框位置吸附 | — |
| `nextStep()` | 1165 | 选人阶段状态机（角色 → 辅助 → 地图 → 完成） | — |
| `initMap()` | 1220 | 进入选图 | — |
| `clear()` | 179 | 清空所有 item / selecter / 地图选择 | — |

### 3.3 `buildList()` 排版公式（核心）——**自由网格（2026-09-30 起，照 3.9）**

```
_loc8_  = _config.x + _config.left          ← 起始 X（来自 layout left）
_loc9_  = _config.y + _config.top           ← 起始 Y（来自 layout top）
_loc10_ = gapX = (width  - unitSize.x - left - right) / (HCount - 1)   ← 列距（自适应）
_loc11_ = gapY = (height - unitSize.y - top  - bottom) / (页内行数 - 1) ← 行距（自适应）
_loc12_ = param1.list                        ← 全部 item VO

每个 item 落点：
  pageIdx   = item.y / rowsPerPage         ← 分页号（rowsPerPage = 6）
  yInPage   = item.y % rowsPerPage         ← 页内行号
  baseX     = _loc8_ + _loc10_ * item.x     ← item.x 是 grid X（列号）
  baseY     = _loc9_ + _loc11_ * yInPage + pageIdx * PAGE_HEIGHT
  finalX    = baseX + item.offset.x         ← offset.x 是 row+item 累加
  finalY    = baseY + item.offset.y
```

- **不再有 `45` / `60` 硬编码**：列距/行距由 `layout` 尺寸、`unitSize(60,60)` 与 `HCount/VCount` 算出
- `PAGE_HEIGHT = 600`（行 272，与 select.xml layout height 一致）；**页数按行数算**：`TOTAL_PAGES = ceil((maxY+1) / rowsPerPage)`
- **当前参数（2026-09-30）**：`rowsPerPage = 6`、每行 4 个（`select.xml` 已按 4 个/行重排）、`layout left=415 right=100 top=50 bottom=40`、`unitSize=(60,60)`
  → `gapX = (800-60-415-100)/3 = 75`（列间约 15px）、`gapY = (600-60-50-40)/5 = 90`（行间约 30px）；两个列表一致
  → 网格占位 `x 415..700`、`y 50..560`（右侧 700..800 留给翻页箭头条；末行下缘 560，距屏底 40）
- **`select.xml` 里的 `offset` 已全部清零/删除**：那些 `item offset="35,0"/70,0/105,0` 与 `row offset="0,30..."` 是给旧固定网格（45/60）补间距用的，会和自适应步距**叠加**导致间距 118、最后一列出屏；解析器对缺失 offset 容忍（`SelectStageConfigVO.newListByXML` 行 77/101 有 `length > 0` 守卫，null 时不偏移）
- 格子自身 ≈60×60：步距 75 → 约 15px 间隙，不再有裁切或重叠
- plugin 子框的 8 方位环绕偏移就是 `offsetRatio.x * gapX / offsetRatio.y * gapY`（行 324-325），**自动跟随网格步距**

---

## 4. UI 组件层

### 4.1 选人界面组件清单

| 组件 | 文件 | 行数 | 作用 |
|---|---|---|---|
| **`SelectFighterItem`** | `ui/select/SelectFighterItem.as` | 474 | 单个角色格子（含 face、batch6+badge 子框角标、批次6.8 plugin 展开/收起） |
| `SelecterItemUI` | `ui/select/SelecterItemUI.as` | 225 | 选择框（P1/P2 高亮选择框，含 SelectedFighterGroup） |
| `SelectedFighterGroup` | `ui/select/SelectedFighterGroup.as` | 79 | 已选角色横排容器（带缩放/淡入动画） |
| `SelectedFighterUI` | `ui/select/SelectedFighterUI.as` | 192 | 单个已选角色框（含 BitmapText 名称 + 大头像） |
| `SelectUIFactory` | `ui/select/SelectUIFactory.as` | 32 | 选择框工厂（创建 `SelecterItemUI` + `SelectedFighterGroup`） |
| `SelectIndexUI` | `ui/select/SelectIndexUI.as` | 193 | 已选角色排序界面（确认时弹出的"123号位"排序） |
| `SelectIndexUIGroup` | `ui/select/SelectIndexUIGroup.as` | 405 | P1/P2 排序分组（上下方向键切换 + 攻击确认） |
| `MapSelectUI` | `ui/select/MapSelectUI.as` | 218 | 地图选择界面（左右切换 + 确认） |

### 4.2 组件依赖关系

```
SelectFighterStage
├─ SelectFighterItem[]            ← 网格中所有可选角色
│   └─ pluginFighters (Vector)    ← 批次 6.8 子框角色
│       └─ SelectFighterItem[]    ← 子框也是同一种 item
├─ SelecterItemUI (_p1Slt)        ← P1 选择框
│   └─ SelectedFighterGroup       ← 已选列表容器
│       └─ SelectedFighterUI[]    ← 已选单个角色
└─ MapSelectUI (_mapSelectUI)     ← 选图界面
```

### 4.3 关键 UI 容器引用

| 容器 | 来源 swf 资源名 | 出现位置 |
|---|---|---|
| `select.swf` (整张背景) | `ResUtils.SELECT` | `SelectFighterStage.build()` |
| `slt_item_mc` | `SelectFighterItem.ui` | 单个角色格子 |
| `select_item_mc` | `SelecterItemUI.ui` | 选择框（mc gotoAndStop 1=P1 / 2=P2） |
| `selected_item_p1_mc` | `SelectedFighterUI.ui` (P1 已选框) | 选人左下角 |
| `selected_item_p2_mc` | `SelectedFighterUI.ui` (P2 已选框) | P1 正上方 |
| `select_map_mc` | `MapSelectUI._mapmc` | 地图选择 |
| `select_arrow_mc_1/2` | `SelectIndexUI` | 排序界面箭头 |
| `seltwzmc` | `SelectIndexUI` | 排序数字标号（gotoAndStop 1/2/3/4） |

---

## 5. 关键常量与排版参数速查

### 5.1 硬编码排版常量（来自 `SelectFighterStage`）

| 常量 | 值 | 位置 | 说明 |
|---|---|---|---|
| `_loc10_`（gapX） | **计算值**（当前 75） | 行 266 | 列距 = `(width - unitSize.x - left - right) / (HCount - 1)`，改 layout 或列数即变 |
| `_loc11_`（gapY） | **计算值**（当前 75） | 行 268 | 行距 = `(height - unitSize.y - top - bottom) / (页内行数 - 1)` |
| `unitSize` | `(60,60)` | `SelectStageConfigVO` 字段 | 单格占位尺寸（**xml 未解析，代码常量**）；必须≈格子实际宽度，否则最后一列会被挤出屏 |
| `PAGE_HEIGHT` | `600` | 行 272 / 静态 32 | 分页高度，**与 select.xml layout height 一致**（必同步） |
| `rowsPerPage` | `6` | 行 253 | 每页最多行数；`TOTAL_PAGES = ceil((maxY+1)/rowsPerPage)` |
| `_tweenTime` | `500` ms | 行 66 | 选人淡入动画时长 |
| `_pagSpeed` | `100` | 行 79 | FLA 翻页 timeline speed |

### 5.2 SelectFighterStage 静态状态

```as3
public static var AUTO_FINISH:Boolean = true;
public static var SELECT_STATE:int = 0;       // 0=角色 1=辅助
public static var PAGE_HEIGHT:Number = 600;
public static var TOTAL_PAGES:int = 5;
public static var CURRENT_PAGE:int = 0;
```

### 5.3 选人框 P1/P2 位置（`SelectUIFactory`）

```as3
// 行 24-25
_loc5_.x = param1 == 1 ? 100 : 100;                              // P1/P2 都用 x=100
_loc5_.y = param1 == 1 ? GAME_SIZE.y - 265 : GAME_SIZE.y - 265 - 260;
//                                  ↑P1 在左下角    ↑P2 在 P1 正上方（框高+间距 260）
```

### 5.4 GameConfig 常量

| 常量 | 说明 |
|---|---|
| `GameConfig.GAME_SIZE.x = 800`, `GameConfig.GAME_SIZE.y = 600` | 画布尺寸（用于居中计算） |
| `GameConfig.TOUCH_MODE` | true 时走触屏事件，否则走鼠标事件 |

---

## 6. 数据加载链路

### 6.1 主加载链（`GameData.loadConfig`）

```
GameData.loadConfig()                            ← BVNscripts/scripts/.../data/GameData.as:44
   ↓
AssetManager.I.loadXML("assets/config/fighter.xml", ...)    ← FighterModel.I.initByXML()
   ↓
AssetManager.I.loadXML("assets/config/assist.xml", ...)     ← AssisterModel.I.initByXML()
   ↓
AssetManager.I.loadXML("assets/config/select.xml", ...)     ← config.select_config.setByXML()  ← 本文档关注
   ↓
AssetManager.I.loadXML("assets/config/map.xml", ...)        ← MapModel.I.initByXML()
   ↓
AssetManager.I.loadXML("assets/config/mission.xml", ...)    ← MessionModel.I.initByXML()
```

### 6.2 单文件重载入口

```as3
GameData.I.loadSelect("assets/config/select.xml");   ← GameData.as:154
GameData.I.setSelectData(xml);                        ← GameData.as:166 → config.select_config.setByXML()
```

### 6.3 XML → VO 解析（`SelectStageConfigVO.setByXML` + `newListByXML`）

```
<select_config>
   <stage_setting><layout .../></stage_setting>          → SelectStageConfigVO.{x,y,w,h,top,bottom,left,right}
   <char_list>                                            → SelectCharListConfigVO
      <row offset="X,Y">                                  → 行偏移（累加基准）
         <item offset="a,b">角色名</item>                → SelectCharListItemVO
            <plugin id="..."/>                            → item.pluginIDs.push(id)  (批次 6.1+)
         </item>
      </row>
   </char_list>
   <assist_list>...</assist_list>                        → 同上结构，生成另一个 SelectCharListConfigVO
</select_config>
```

**关键代码位置**：
- `SelectStageConfigVO.setByXML()` — 行 35：解析 layout + 调用 `newListByXML`
- `SelectStageConfigVO.newListByXML()` — 行 50：双层循环（rows × items）→ 生成 `SelectCharListItemVO[]`
- 行 87（批次 6.6 修复）：`_loc9_ = _loc8_.text()` 而非 `.toString()`（避免序列化 plugin 子节点）
- 行 110-117（批次 6.1）：plugin 子节点解析

---

## 7. xml 字段 ↔ 代码映射表

| xml 字段 | 路径 | 代码字段 | 位置 |
|---|---|---|---|
| `<select_config>` | 根 | `SelectStageConfigVO` | — |
| `<stage_setting><layout>` | 1 级 | `SelectStageConfigVO.x/y/width/height/left/right/top/bottom` | `SelectStageConfigVO.setByXML` 行 37-45 |
| `<char_list>` | 1 级 | `SelectStageConfigVO.charList` | 行 46 |
| `<assist_list>` | 1 级 | `SelectStageConfigVO.assistList` | 行 47 |
| `<row offset="X,Y">` | 2 级 | 行级 offset（_loc4_:Point） | `newListByXML` 行 70-75 |
| `<item offset="a,b">` | 3 级 | `SelectCharListItemVO.offset:Point` | 行 94-107 |
| `<item>角色名</item>` | 3 级 | `SelectCharListItemVO.fighterID` | 行 87（批次 6.6 修复 .text()） |
| `<item><plugin id="X"/></item>` | 4 级 | `SelectCharListItemVO.pluginIDs:Array` | 行 110-117（批次 6.1） |
| item 的位置（`item.x, item.y`） | — | 由 xml 解析时的双层循环 index 决定 | 行 108：`new SelectCharListItemVO(colIndex, rowIndex, ...)` |
| `HCount`（最大行宽） | — | `SelectCharListConfigVO.HCount` | 行 76-79 |
| `VCount`（行数） | — | `SelectCharListConfigVO.VCount` | 行 65 |
| `unitSize` | — | `SelectStageConfigVO.unitSize:Point` | 初始化 `(60,60)`（**xml 未解析，代码常量**） |

---

## 8. 常见修改场景索引

### 8.1 改列距 / 行距 / 网格范围（**改 select.xml 的 `<layout>`**）

- 列距/行距是**自适应**的，两个"旋钮"就是 `<layout>` 的 `right` 与 `bottom`（越大 → 网格越紧）：
  - `right = 800 - unitSize.x - left - 3 × 目标列距`（当前 `right=100` → 列距 75）
  - `bottom = 600 - unitSize.y - top - 5 × 目标行距`（当前 `bottom=40` → 行距 90；想回 75 就设 `bottom=190`）
  - `top` / `left` 决定网格左上角起点（当前 `left=415`、`top=50`）
- 想改**列数/行数**：改 `<row>` 里 `<item>` 的个数（`HCount` = 最大列数）、行数（`VCount`）；每页行数上限改代码 `rowsPerPage`（行 253，当前 6）
- **不要再往 `<item>`/`<row>` 写 `offset`**：那会和自适应步距叠加导致间距紊乱（历史遗留已清零）
- 想**可视化试排（建议先在这里试）**：双击 `选人界面排版工具/select-layout-tool.html` → 侧边栏「行列数量」输入「每行 / 每列」即刻重排网格（多出来的列自动折成行，信息行给出列距/行距与重叠警告）→ 满意后「导出 XML」直接得到 `select.xml`
  - 该工具**只实现 3.9 自由网格一种模式**（`gapX/gapY` 自适应、无行分页），与 `现代参考3.9` 逐项对齐；主程序的 `rowsPerPage=6` 行分页变体不在此工具内建模

### 8.2 调整 P1/P2 已选框位置

- 修 `SelectUIFactory.createSelecter` 行 24-25：
  - `_loc5_.x` 控制水平位置
  - `_loc5_.y` 控制垂直位置（P2 = P1.y - 260 即可保证不互遮）

### 8.3 调整选人阶段状态机流程（角色 → 辅助 → 地图 → 完成）

- 修 `SelectFighterStage.nextStep()` 行 1165 的 switch case 0-5
- 状态转移由 `GameMode.isVsCPU() / isVsPeople()` 决定

### 8.4 调整 xml 解析字段

- 修 `SelectStageConfigVO.setByXML` 行 35（layout 字段解析）
- 修 `SelectStageConfigVO.newListByXML` 行 50（item 解析逻辑）

### 8.5 调整排序确认界面（123号位）

- `SelectIndexUI`（行 193）+ `SelectIndexUIGroup`（行 405）
- `SelectedFighterUI.setFighterIndex` 行 157（标号位置）

### 8.6 调整地图选择界面

- `MapSelectUI.build` 行 93（地图 swf 资源 `select_map_mc`）
- `MapSelectUI` 行 97-98：地图水平居中，y = `GAME_SIZE.y * 0.25`

### 8.7 子框 (plugin) 调参

- 子框数据：`SelectCharListItemVO.pluginIDs`
- 子框 8 方位偏移：`SelectFighterStage.buildList` 行 315
  ```as3
  var offsets:Array = [new Point(0,-1), new Point(0,1), new Point(1,0), new Point(-1,0),
                       new Point(1,1), new Point(-1,1), new Point(-1,-1), new Point(1,-1)];
  ```
- 子框展开/收起：`SelectFighterItem.showPlugins/closePlugins` 行 272/304
- 子框手柄导航：`SelectFighterStage.movePluginSelect` 行 560
- 子框角标 badge：`SelectFighterItem.updateBadge` 行 163（数字字号 14 / 字色 `#B8E6E6` / 描边 `#1A4040`）

---

## 附录：版本与已知事项

| 项 | 状态 | 说明 |
|---|---|---|
| 批次 6.1 | ✅ | plugin 子框解析逻辑 |
| 批次 6.6 | ✅ | `.text()` 修复（避免 plugin 节点被序列化进 fighterID） |
| 批次 6.7 | ✅ | face 加载失败的占位 + ENTER_FRAME 重试治本 |
| 批次 6.8（方案 B） | ✅ | plugin 8 方位展开 + 手柄导航 + badge 角标 |
| 批次 6.9 | ✅ | 触屏长按 1.2s 展开 plugin（防误触 20px 阈值） |
| 批次 6.10/6.11 | ✅ | 辅助阶段分页不归位（避免 `#2025` 帧脚本 ArgumentError 刷屏） |
| 批次 6.12 | ✅ | GameEvent 单例派发替代 stage.dispatchEvent |
| ANE 外部资源 | ⚠️ 当前禁用 | `select.xml` 受 `ANEFileReader.ANE_ENABLED` 守卫（默认 false，从 APK 内置加载） |

> **重要：修改 `select.xml` 后必须重新编译**（`build.bat`）→ `tools/Test/launch.swf` → 打包 APK 才会生效。
> 真机路径：`/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log`