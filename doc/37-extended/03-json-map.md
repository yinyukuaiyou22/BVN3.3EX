# JSON 关卡：MUGEN stage 转换产物与运行时重绘

**一句话**：JSON 关卡把 MUGEN 的 BG 层编译成 stage.json + PNG，运行时由独立渲染器逐层重绘。
**源码基准**：BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/（V3.7 只读参考树，本册未改动其中任何文件）。
**对照基准**：BVNscripts/scripts/net/play5d/game/bvn/（3.3 主项目，XML map.xml + SWF 地图，同样未改动）。

> **引用约定**：正文中 `路径:类.方法()` 不带前缀时，路径相对 `BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/`；
> 以 **主项目** 开头的引用，路径相对 `BVNscripts/scripts/net/play5d/game/bvn/`。行号一律不写死，确需定位处标注「参考 :N」并声明只是参考。
> 数据侧结论一律标出取证方式（PowerShell `ConvertFrom-Json` 统计 / 正则计数 / 代码阅读），不做目测推断。

---

## 1. 一句话结论

JSON 关卡不是「地图格式换皮」，而是**把 MUGEN 的 BG 层语义整体搬进运行时**：转换器把 .def 的 `[BGdef]` 层、AIR 动作、trans/alpha/tile/delta 全部展开成一份扁平 JSON（`stage.json`）加一堆切好的 PNG；运行时 `JsonMapMain` 负责把 MUGEN 的「层坐标 + 相机 delta」换算成 800×600 画布上的逐层位置，`JsonLayerRenderer` 负责三条截然不同的绘制路径（普通 / 平铺 / 切片视差）与窗口蒙版，`JsonStageFx` 负责混合模式、透明度与舞台控制器（`controllers`）。

三者职责边界清楚且**单向依赖**：`JsonMapMain` 依赖另外两个；`JsonLayerRenderer` 与 `JsonStageFx` **不 import `JsonMapMain`、不 import `GameConfig`、不 import `MapMain`**，只吃普通 Object（层运行时状态 `L` 与视图参数 `v`）——这是它们能被整体搬走的前提。

对主项目而言，JSON 关卡的技术含量在「渲染器」，不在「格式」：主项目连 `MapLayer` 这个包装类都没有（主项目 `map/` 下只有 `MapMain.as` 与 `FloorVO.as`），要接 JSON 关卡最省的路径是**连渲染器带一个裁剪版 MapLayer 一起搬**，而不是把主项目改造成 MUGEN 解释器。

---

## 2. 领域术语

| 术语 | 本册含义 | 代码对应物 |
|---|---|---|
| stage.json | 一张 JSON 地图的全部数据：舞台元信息 + 层表 + 动作表 + 控制器表 | 文件本身；读入口 `map/JsonMapLoader.as:JsonMapLoader.load()` |
| layer（层） | MUGEN 的一个 BG 元素（一张图、一段逐帧动画、或一列视差切片） | `stage.json` 的 `layers[]`；运行期对象 `L`（`JsonMapMain.newLayer()` 里构造的匿名 Object） |
| layerno | 层属于背景还是前景：0=背景、1=前景 | `JsonMapMain.newLayer()` 里 `L.layerno`；装进 `_bgBox` 或 `_frontBox` |
| sprite | 层引用的那张图（`img_ref` 指向同目录 PNG） | `_cache[img_ref]` 里的 `Bitmap`；层的 `L.bitmap` 共用同一份 `bitmapData` |
| action / frames | MUGEN 的 AIR 动作，展开成帧数组；每帧一张图 + 若干数值 | `stage.json` 的 `actions[actionno]`；`L.actionFrames` |
| delta | 相机位移传递到该层的比例：0=完全钉在屏幕上，1=与舞台同速 | `L.deltaX/deltaY`，参与 `finalX/finalY` 的 `-camX*deltaX` 项 |
| scalestart / scaledelta | 层的基础缩放，以及「随相机横向位移线性变化」的假透视系数 | `L.scaleStartX/Y`、`cfg.scaledelta`，在 `JsonLayerRenderer.draw()` 里合成 `dynSX` |
| tile / tilespacing | 是否横向/纵向铺满，以及铺块之间的间距 | `L.tileX/tileY/tileSpacingX`，走 `drawTiled()` |
| parallax | 一种层类型：按行切片，每片按自己的 delta/宽度比例绘制，做出透视地面 | `type=="parallax"`，走 `drawParallax()` |
| trans | MUGEN 的混合声明，字符串形态（`none` / `a` / `addalpha` / `as<src>d<dst>` / `sub` 等） | `map/JsonStageFx.as:JsonStageFx.applyTrans()` |
| alpha | 长度 2 的整数数组 `[src,dst]`，值域 0~256（不是 0~1） | `applyTrans()` 的 `a256()` 与 `addalpha` 分支 |
| window / maskwindow | 层只在这些矩形内可见（MUGEN 的 `window` / `maskwindow` 参数） | `L.windowArr/L.maskWindowArr`，蒙版图形在 `JsonLayerRenderer.updateMask()` |
| controller | MUGEN 的舞台控制器（位移、速度、正弦、调色板、显隐、切动作） | `stage.json` 的 `controllers[]`；`JsonStageFx.applyController()` |
| localcoord | MUGEN 舞台的本地坐标尺寸；决定层坐标到 800×600 的换算比 | `_lsx/_lsy`（`JsonMapMain.initByJSON()`） |
| 视图参数 v | 每帧算一次的只读参数包（游戏尺寸、换算比、相机位置、缩放） | `JsonMapMain.readView()` 填的 `_viewBg/_viewFront`，交给 `JsonLayerRenderer.draw()` |
| v2.5 runtime patch | 转换器 audit.txt 里点名的两处运行时修复（addalpha 变黑纱、未平铺视差层被铺满） | `JsonStageFx.applyTrans()` 的 `addalpha&&alpha[1]<250` 分支、`drawParallax()` 的 `repeatX` 判定 |

---

## 3. 结构与数据流

### 3.1 谁是谁（类与职责）

| 角色 | 类 / 方法 | 职责 |
|---|---|---|
| 配置声明 | `data/MapVO.as:MapVO.initByXML()` + `data/MapModel.as:MapModel.initByXML()` | 读 `config/map.xml` 的 `<map><file url>`，把 `maps/temple/stage.json` 存进 `MapVO.fileUrl` |
| URL 判据 | `map/JsonMapLoader.as:JsonMapLoader.isJsonMapUrl()` | 去掉 `?` 查询串、转小写后判 `.json` 结尾；这是「这张图是不是 JSON」的唯一开关 |
| 预载（可选） | `ctrl/game_stage_loader/GameStageLoadCtrl.as:GameStageLoadCtrl.startLoadingMaps()` | 判据为真 → `JsonMapLoader.load()` → 结果塞进 `_mapCache[url]={json,bitmaps}` |
| 直载（另一条路） | `ctrl/GameLoader.as:GameLoader.loadMap()` | 判据为真 → 直接 `load` + `JsonMapMain.create()`，不经过缓存；两条路并存 |
| 解析与取图 | `map/JsonMapLoader.as:JsonMapLoader.load()/onJsonLoaded()/loadImage()` | 解析 JSON、收集 `img_ref`、4 路并发拉 PNG、克隆进 `_cache` |
| 建图 | `map/JsonMapMain.as:JsonMapMain.create()→initByJSON()` | 解析 `stageinfo/camera/playerinfo/bound/shadow/music`，算舞台尺寸，逐层 `newLayer()` |
| 层构造 | `map/JsonMapMain.as:JsonMapMain.newLayer()` | 把层 JSON 摊平成运行时 `L`（约 45 个键），建 `Sprite`+`Bitmap`，必要时建蒙版 Sprite |
| 帧状态机 | `JsonMapMain.applyFrame()/stepFrames()/nextIndex()` | 按 `ticks` 推进帧、处理 `interpolate_*` 插值 |
| 几何绘制 | `map/JsonLayerRenderer.as:JsonLayerRenderer.draw()` | 三条路径选一（普通/平铺/切片视差）+ 蒙版矩形 + 容器坐标系换算 |
| 混合与颜色 | `map/JsonStageFx.as:JsonStageFx.applyTrans()/applyController()` | 写 `blendMode/alpha/colorTransform`；不碰几何 |
| 控制器调度 | `JsonMapMain.updateTick()/runControllers()` | 按 `time` 窗口决定这一 tick 是否执行控制器；每次推进 `_stageTick` |
| 挂载 | `state/GameState.as:GameState.initFight()` | `bgLayer` 挂到 GameState 自身（屏幕空间），`frontLayer/mapLayer` 挂到 `_gameLayer`（相机容器） |
| 相机 | `state/GameState.as:GameState.initCamera()` + `state/GameCamera.as` | 用 `getStageSize()` 与 `getMapBottomDistance()` 建相机；JSON 层不改相机 |
| 战斗边界 | `ctrl/GameLogic.as` 读 `_map.left/right/bottom/playerBottom` | 出界判定、贴地、把对手拉回 |
| 地面命中 | `map/JsonMapMain.as:JsonMapMain.getFloorHitTest()` + `map/FloorVO.as:FloorVO.hitTest()` | JSON 关卡只有**一块**地面（见 §4.10） |
| 背景模糊 | `ctrl/EffectCtrl.as:EffectCtrl.bgBlur()` | 首行判 `getMap() is JsonMapMain` → 直接 return，JSON 关卡永不参与 KO 模糊 |
| BGM | `ctrl/SoundCtrl.as:SoundCtrl.playFighterBGM()` ← `data/MapModel.as:MapModel.getMapBGM()` | 走 `map.xml` 的 `<bgm>`；`stage.json` 的 `music` 块**没人读**（见 §4.11） |

### 3.2 数据从哪来到哪去

```text
assets/assets/config/map.xml
   └─ <map id="map_2"><file url="maps/temple/stage.json"/><img .../><bgm .../></map>
        └─ data/MapVO.as:MapVO.initByXML()        → MapVO{ id, name, fileUrl, picUrl, bgm }
             └─ data/MapModel.as:MapModel.initByXML()  → _mapObj[id] = MapVO

选图/开局 → MapModel.I.getMap(id) → MapVO.fileUrl
   ├─ JsonMapLoader.isJsonMapUrl(fileUrl) == true
        ├─ 预载路径：GameStageLoadCtrl.startLoadingMaps()
        │     └─ JsonMapLoader.load(fileUrl, cb, onLoadError, onLoadProcess)
        │           ├─ AssetManager.I.loadJSON(url)          → JSON.parse → Object
        │           ├─ 收集 layers[].img_ref + actions[*][*].img_ref（跳过 group==-1）
        │           ├─ 去重后按 MAX_PARALLEL=4 拉 AssetManager.I.loadBitmap(baseUrl+ref)
        │           └─ cb(cfg, cache)  → _mapCache[url] = { json, bitmaps }
        │     └─ 开局：GameRunFactory.createMapByData(MapVO)
        │           └─ JsonMapMain.create(vo, jsonData.json, jsonData.bitmaps)
        └─ 直载路径：GameLoader.loadMap(mapId, back)
              └─ JsonMapLoader.load(...) → JsonMapMain.create(mv, cfg, bitmaps) → back(map)

JsonMapMain.create()
   └─ initByJSON(cfg, bitmapCache)
        ├─ _actions = cfg.actions / _ctrls = cfg.controllers || cfg.bgctrls
        ├─ stageinfo.localcoord → _lsx=800/scW, _lsy=600/scH
        ├─ camera.boundleft/boundright/zoomout → _stageWidth / left / right / camLimit*
        ├─ stageinfo.zoffset → playerBottom；bottom = max(600, playerBottom)
        ├─ playerinfo → p1pos/p2pos + p1..p4Facing（facing 无人读）
        ├─ _bgBox/_frontBox + MapLayer 包装（bgLayer/frontLayer/mapLayer/frontFixLayer）
        ├─ layers[] → newLayer() × N  （每层：Sprite + Bitmap + L + 蒙版）
        └─ _floorList = [ 一块横跨 left-2000 ~ right+2000 的地面 ]

GameState.initFight(groups, map)
   ├─ addChild(map.bgLayer)                ← 屏幕空间（不随相机缩放）
   ├─ _gameLayer.addChild(map.mapLayer)    ← 空壳，只为过 null 检查
   ├─ _gameLayer.addChild(map.frontFixLayer) ← MapLayer(null)，enabled=false
   ├─ _gameLayer.addChild(map.frontLayer)  ← 相机空间（抵消缩放）
   └─ initCamera() → getStageSize()/getMapBottomDistance() → GameCamera

每帧：GameState.render()
   ├─ camera.render()
   └─ _map.render(-screenRect.x, -screenRect.y, camera.getZoom(true))
        └─ JsonMapMain.render(cameraX, cameraY, cameraZoom)   ← 三个入参全部忽略
             ├─ updateTick()   ：_step = clamp((now-_lastTime)*0.06, 0, 4)，推进控制器
             ├─ readView()     ：从 gameState.camera 重读 screenRect/zoom → camX/camY
             └─ for each layer：
                  ├─ stepFrames()   ：推进帧、插值轴心/alpha/缩放/角度
                  ├─ velPos/sinOff  ：速度积分 + 正弦偏移
                  └─ JsonLayerRenderer.draw(L, 该层所属的 view, _layers)
                       ├─ planSlices()（仅当 L === _layers[0]）
                       ├─ updateMask()：写红色矩形做窗口蒙版
                       └─ 三选一：drawPlain / drawTiled / drawParallax
```

### 3.3 三个数据来源（别混）

| 来源 | 内容 | 谁读 |
|---|---|---|
| `stage.json` | 舞台几何、层、动作、控制器、MUGEN 原始元信息 | `JsonMapLoader` → `JsonMapMain` |
| 同目录 PNG | `layers[].img_ref` / `actions[*][*].img_ref` 指向的切图 | `JsonMapLoader.loadImage()` → `_cache` |
| `config/map.xml` | 地图注册：id/显示名/文件 URL/预览图/BGM | `MapVO` → `MapModel`，与 JSON 内部数据**互不覆盖** |

补一条实测口径：20 个地图目录里各有**两份** JSON——`stage.json`（真正被加载）与 `stages.json`（120~154 字节的注册存根，形如 `{id,name,file,img,bgm}`）。运行时代码里 grep 不到 `stages.json` 的任何引用，它是转换器给「将来的 JSON 地图注册表」留的产物，实际注册仍由 `map.xml` 承担。

---

## 4. 关键机制逐条拆解

### 4.1 加载器：判据、并发、缓存、失败路径

**结论**：`JsonMapLoader` 是纯静态工具（只有一个静态入口 `load()`），自己不做 URL 前缀，把「目录 + 文件名」拼成相对路径交给 `AssetManager`；真正的路径解析在 `mob/AssetLoader.as:AssetLoader.getFullUrl()` 里补 `assets/` 前缀。

代码引用：`map/JsonMapLoader.as:JsonMapLoader.load()/start()/isJsonMapUrl()/onJsonLoaded()/loadImage()/finish()/fail()`。

关键事实（全部来自代码）：

- 判据只认后缀：`clean.length > 5 && clean.lastIndexOf(".json") == clean.length - 5`，并且先剥掉 `?` 之后的部分。所以 `maps/x/stage.json?v=2` 也算 JSON 地图。
- 基准目录来自 JSON 自己的 URL：`_baseUrl` 取最后一个 `/` 或 `\` 之前的部分，取图时 `url = _baseUrl + ref`。这与 `stage.json` 里 `img_ref` 只写文件名（如 `18_0.png`）互相配合。
- 并发上限 `MAX_PARALLEL = 4`；`_queue` 用 `seen` 去重，所以 700+ 层里重复引用的同一张图只下一次。
- 每张图落缓存时做了一次 **`bitmapData.clone()`**（`_cache[ref] = new Bitmap(bmp.bitmapData.clone())`）。关卡内部所有层共享同一份克隆数据；`JsonMapLoader.disposeCache()` 逐项 `dispose()`。
- 失败分两级：JSON 拉不到 → `onJsonFail()` → `fail("Gagal memuat stage.json: assets/" + _jsonUrl)`；JSON 里没有 `layers` → `fail("stage.json tidak punya layers")`；解析异常 → `fail("stage.json bermasalah: " + err.message)`。图片缺失**不算失败**，只写一条日志并继续（`onBad` → `imageDone()`）。
- 日志前缀固定 `JsonMapLoader: `，并且支持外部注入 `public static var logFn:Function`（被 `ScreenLog` 之类接管）。印尼语不是乱码：`baca` = 读、`gambar` = 图、`GAGAL` = 失败。

**为什么这么做**：MUGEN 一张图能切出上百个 sprite，转换器把它们平铺成独立 PNG；若串行加载，temple（81 层 / 184 张 PNG）会在开局卡很久。4 路并发 + 去重 + 克隆缓存，是把「一张舞台」压成「一次上限 4 的批处理」的最简做法。

### 4.2 stage.json 顶层结构：有哪些键、谁读、必填/可选

实测（20 张图的 `ConvertFrom-Json` 键并集，20/20 完全一致）：**12 个顶层键**——`format, info, camera, playerinfo, bound, stageinfo, shadow, reflection, music, controllers, layers, actions`。

| 键 | 语义 | 代码读者 | 必填 |
|---|---|---|---|
| `format` | 转换器版本标记，实测恒为 `starblast_stage_v1` | **无** | 可选 |
| `info` | MUGEN 元信息：`name/displayname/author/versiondate/mugenversion` | **无** | 可选 |
| `camera` | `boundleft/boundright/zoomout/zoomin/startzoom` + 一批 MUGEN 相机键 | 只读 4 个（见 §4.10） | 可选（全走 `num()` 默认值） |
| `playerinfo` | `p1..p4startx/starty/facing`、`leftbound/rightbound` | 读 `p1/p2 startx/starty`、`p1..p4 facing`、`leftbound/rightbound` | 可选 |
| `bound` | `screenleft/screenright` | 读入 `screenLeft/screenRight` 后**无人使用** | 可选 |
| `stageinfo` | `zoffset/autoturn/resetBG/localcoord/xscale/yscale/hires` | 读 `zoffset/localcoord/xscale/yscale/autoturn` | 可选 |
| `shadow` | `intensity/color/yscale/fade_range` | 读入 `shadowIntensity/shadowColor/shadowYScale` 后**无人使用** | 可选 |
| `reflection` | `intensity` | 读入 `reflectionIntensity` 后**无人使用** | 可选 |
| `music` | `bgmusic/bgmvolume/bgmloopstart/bgmloopend` | 读入 4 个字段后**无人使用**（见 §4.11） | 可选 |
| `controllers` | 舞台控制器数组（也可写成 `bgctrls`） | `runControllers()` | 可选 |
| `layers` | 层数组 | `initByJSON()` / `newLayer()` | **必填**（缺了直接 `fail`） |
| `actions` | 动作表：`"<actionno>" → 帧数组` | `applyFrame()/stepFrames()/applyController("anim")` | 代码里非必填，但见下方注意 |

注意（由代码边界推出）：`onJsonLoaded()` 里 `for(key in actions)` 位于同一个 `try` 内，异常会被兜成 `fail("stage.json bermasalah")`。AS3 里 `for-in` 遍历 `undefined` 会抛 TypeError，因此**缺 `actions` 的 JSON 会走进失败分支**——这一条需要运行时确认，已列进 §7。

**为什么这么做**：`layers` 是唯一「没有默认值可填」的结构性数据；其余块都能用 `num(o,key,def)` 兜底。转换器把 MUGEN 的 `[StageInfo]/[Camera]/[PlayerInfo]/[Bound]/[Shadow]/[Reflection]/[Music]` 逐节映射成同名对象，键名基本沿用 MUGEN 拼写（`boundleft`、`zoffset`、`bgmloopstart`），所以看 MUGEN 文档能直接对上。

### 4.3 层模型：type 只有 3 个值，但只有 1 个影响分支

实测 20 张图共 **729 层**：`normal` 451、`anim` 178、`parallax` 100；`layerno==1` 78 层；`tile[0]!=0` 251 层、`tile[1]!=0` 18 层；带 `window` 93 层。

**结论**：`JsonLayerRenderer.draw()` 只判一个 `type` 值——`cfg.type == "parallax"`。`anim` 与 `normal` 走完全相同的绘制路径，区别只在于 `anim` 层带 `actionno`、会在 `stepFrames()` 里逐帧换图；不带 `actionno` 的 `anim` 层等价于静态层。

代码引用：`map/JsonLayerRenderer.as:JsonLayerRenderer.draw()`（分支只有 `parallax` / `tileX!=0 || tileY!=0` / 其余）；`map/JsonMapMain.as:JsonMapMain.newLayer()`（`actionno != -1` 才查 `_actions`）。

所以「层类型」在运行时是**绘制路径标记**，不是 MUGEN 的类型学。

### 4.4 一个 sprite/层的字段全集

转换器对每一层输出**固定 33 个键**（20 张图一致，无缺键）；运行时 `newLayer()` 只读其中约 20 个。下表「落到 L」= 运行时对象上的键名，「谁读」= 第一个读它的代码位置。

| JSON 字段 | 语义 | 落到 L / 处理 | 谁读 |
|---|---|---|---|
| `id` / `name` | 层标识、MUGEN 注释 | **丢弃** | — |
| `type` | `normal` / `anim` / `parallax` | `L.config.type` | `draw()` 判 `parallax` |
| `spriteno` / `width` / `height` | MUGEN sprite 组号与原始尺寸 | **丢弃**（尺寸以实际 PNG 为准） | — |
| `layerno` | 0 背景 / 1 前景 | `L.layerno`；决定进 `_bgBox` 还是 `_frontBox` | `newLayer()`、`render()` |
| `img_ref` | 引用哪张 PNG | 查 `_cache` 建 `Bitmap`（共用 `bitmapData`，不 clone） | `newLayer()`、`applyFrame()` |
| `start` | MUGEN 层起点 `[x,y]` | `L.startX/startY` | `draw()` 的 `stX/stY` |
| `delta` | 相机传递比例 `[dx,dy]` | `L.deltaX/deltaY` | `draw()`、`drawParallax()` |
| `scalestart` | 基础缩放 `[sx,sy]` | `L.scaleStartX/scaleStartY`（负值 = 翻转，见 §4.6） | `draw()` |
| `scaledelta` | 随相机线性变化的缩放（假透视）；实测 196 层有 | `draw()` 里现取 `cfg.scaledelta` | `draw()` |
| `axis_x` / `axis_y` | 轴心（像素） | `L.axisX/axisY`，会被帧覆盖 | `draw()` 的 `axX/axY` |
| `trans` / `alpha` | 层级混合与透明度 | 建层时先 `applyTrans()` 一次；无帧动画时是唯一来源 | `JsonStageFx.applyTrans()` |
| `tile` / `tilespacing` | 铺满标记与间距 | `L.tileX/tileY/tileSpacingX` | `drawTiled()` |
| `velocity` | 每 tick 位移 `[vx,vy]` | `L.velX/velY` → 积分进 `velPosX/velPosY` | `render()` |
| `sin_x` / `sin_y` | 正弦摆动 `[振幅, 周期tick, 相位度]`；实测 88 / 76 层 | `L.sin_x/sin_y` + `sinTickX/Y` | `stepSin()` |
| `xshear` | 斜切；实测全 0 | `L.xshear` | `drawPlain()/drawTiled()/drawParallax()` |
| `angle` / `xangle` / `yangle` | 旋转（x/y 两个轴实测全 0，转换器未实现） | `L.curAngle`（初始 0，帧可覆盖） | `stepFrames()/drawPlain()` |
| `positionlink` + `link_idx` | 跟随另一层的正弦偏移；实测 0 层为 true、`link_idx` 从未出现 | `L.positionlink/L.linkIndex` | `render()/drawParallax()` |
| `autoresizeparallax` | 开关；实测 729 层全为 false，代码也不读 | **丢弃** | — |
| `zoomdelta` | 缩放传递比 `[zx,zy]`；实测 129 层有 | 现取 `cfg.zoomdelta` | `zoomDelta()` |
| `actionno` | 关联的动作号；实测 179 层有 | `L.actionno` → `_actions[String(actionno)]` | `newLayer()` |
| `window` / `windowdelta` | 可见窗口 `[x1,y1,x2,y2]` + 窗口的相机传递比；实测 93 / 93 层 | `L.windowArr/L.windowDeltaX/Y` | `updateMask()` |
| `mask` | MUGEN 的透明色键开关（实测 0/1） | **代码完全不读**（PNG 已带 alpha） | — |
| `ctrl_id` | 把层挂到某个控制器下；实测仅 MossGrotto 9 层 | `L.ctrlId` | `applyController()` |
| `merged_rgb` | 转换器标记：R/G/B 三通道已合并（cometrain 1 层） | **丢弃** | — |

注意 `flip`：`newLayer()` 里有 `"flip": lc.flip ? String(lc.flip).toUpperCase() : ""`，但**层 JSON 从不输出 `flip`**（729 层里 0 次），所以层级翻转永远走空串；翻转只由帧提供（见 §4.5）。同理 `link_idx` 在代码里被读、在数据里不存在。

### 4.5 帧/动作模型：时间基准不是帧数

**结论**：帧动画的时间基准是**按真实帧间隔缩放出来的 `_step`**，不是固定 60fps 的帧计数；掉帧时动画会加速（上限 4 倍）。

代码引用：`map/JsonMapMain.as:JsonMapMain.updateTick()`（`_step = Math.min(4,Math.max(0,(now - _lastTime) * 0.06))`）、`stepFrames()`、`nextIndex()`、`applyFrame()`。

帧字段全集（20 张图 4446 帧的键并集）：`group, number, img_ref, width, height, axis_x, axis_y, ticks, flip, trans, src_alpha, dst_alpha, xscale, yscale, angle, loopstart, loop_start, interpolate_blend, interpolate_angle, interpolate_offset, interpolate_scale`。

| 帧字段 | 运行时行为 | 代码 |
|---|---|---|
| `img_ref` + `group` | `group == -1` → 本帧不显示（`L.hidden = true`）；实测 2 帧 | `applyFrame()` |
| `ticks` | 正数=停留 tick；`<0` 表示**永久停在这一帧**（实测 23 帧为 -1）；实测正数最小 1、最大 4800 | `stepFrames()` |
| `loop_start` | 只在 `frames[0]` 上被读；实测 20 张图 4446 帧里**全部为 0**，等价「回到第 0 帧」 | `nextIndex()` |
| `loopstart`（boolean） | 转换器的冗余标记，159 次出现，**代码不读** | — |
| `xscale` / `yscale` | 乘进 `L.frameXScale/YScale`；任一为 0 → 本帧隐藏；实测各 81/82 帧非 1 | `applyFrame()`、`draw()` |
| `flip` | 写 `L.flip`（`H` 404 帧、`V` 7 帧、空 4035 帧） | `applyFrame()`、`draw()` |
| `trans` | 非 `none` 时覆盖层级 trans；`none` 时**回落到层级 trans** | `applyFrame()` |
| `src_alpha` / `dst_alpha` | 只在 `interpolate_blend` 时用 `src_alpha` 做插值端点；实测 1957 帧带这两个键 | `stepFrames()` |
| `angle` + `interpolate_angle` | 角度或角度插值；实测非 0 角度 2 帧、`interpolate_angle` 2 帧 | `stepFrames()`/`drawPlain()` |
| `interpolate_offset` | 轴心插值；实测 **0 帧**为 true → 分支永不触发 | `stepFrames()` |
| `interpolate_scale` | 缩放插值；实测 0 帧 | `stepFrames()` |

`stepFrames()` 的推进逻辑（代码直译）：

```text
cur = frames[curFrameIdx]
if (cur.ticks < 0) { curFrameTick = 0 }        // 冻结帧：不再累加
else {
  curFrameTick += _step
  ticks = cur.ticks > 0 ? cur.ticks : 1
  while (curFrameTick >= ticks && guard < frames.length) {
     curFrameTick -= ticks
     curFrameIdx = nextIndex(frames, curFrameIdx)
     applyFrame(L, frames[curFrameIdx])       // 换帧时立即套用帧参数
     if (frames[curFrameIdx].ticks < 0) { curFrameTick = 0; break }
     ticks = ...
  }
}
p = min(1, curFrameTick / ticks)
```

**为什么这么做**：MUGEN 的 AIR 用「游戏 tick」计时，转换器把 `Time` 直接抄成 `ticks`。运行时若用固定 +1 推进，在 30fps 掉帧时整张舞台的动画会慢一半；`_step` 让动画跟真实时间走（并且 clamp 到 4 防止卡顿后暴冲）。代价是：**动画相位与角色帧不同步**——角色帧脚本按游戏帧走，舞台按真实时间走。

另一个副作用：`_step` 同时驱动 `velPos` 与 `sinTick`，所以位移/摆动也是时间基而不是帧基。

### 4.6 坐标换算与视差公式（代码里的实际算式）

先给「相机 → 舞台」的两个中间量（`readView()`，其中 `gw = GameConfig.GAME_SIZE.x = 800`）：

```text
camX = (rect.x + gw / (2*z) - _stageHalf) / _lsx
camY = (rect.y + playerBottom * (1/z - 1)) / _lsy
   // rect = gameState.camera.getScreenRect(true)，z = getZoom(true)
```

非视差层的横轴（`JsonLayerRenderer.draw()`）：

```text
zdx  = cfg.zoomdelta[0]（缺省 1；ZOOMDELTA_DEFAULT_FROM_DELTA==true 时改用 L.deltaX）
zsx  = z + (1 - z) * (1 - zdx)                 // zdx=1 → 跟随缩放；zdx=0 → 尺寸恒定
rawSX= L.scaleStartX + scaledelta.x * camX * L.deltaX
dynSX= |rawSX|（< 0.01 则 0.01）* v.sx * L.frameXScale
stX  = L.startX*v.sx - camX*L.deltaX + L.velPosX + L.sinOffX - axX*dynSX
finalX = v.gameW*0.5 + stX * (v.lsx * zsx)
```

纵轴：

```text
dynSY = |L.scaleStartY| + scaledelta.y * camY * L.deltaY     // 只对第一项取绝对值
        （< 0.01 则 0.01）* v.sy * L.frameYScale
stY   = L.startY*v.sy - camY*L.deltaY + L.velPosY + L.sinOffY
yBase = v.lsy * (stY - axY * axSY)                            // 视差层 axSY 另算
finalY= v.playerBottom + (yBase - v.playerBottom) * zsy       // 以 playerBottom 为缩放锚点
```

视差层的纵轴（`parallaxUniY()`，MUGEN 的 `yscalestart` 语义）：

```text
ysv = yscalestart（缺省 100） + yscaledelta（缺省 0）* camY
if (yscalestart * ysv < 0) ysv = -ysv        // 保持与 yscalestart 同号
|ysv| < 0.01 → 0.01
uniY = 100 / ysv * |L.scaleStartY| * v.sy * L.frameYScale
axSY = uniY + scaledelta.y * camY * L.deltaY * v.sy * L.frameYScale
```

视差层的逐行切片（`drawParallax()`，nSlices 行）：

```text
topRatio = parallax_width[0]/bmpW（无 parallax_width 时退化为 parallax_xscale[0]）
botRatio = parallax_width[1]/bmpW（或 parallax_xscale[1]）
deltaTop = delta[0]；deltaBot = deltaTop * botRatio / topRatio
totalY   = v.lsy * uniY * zsy
sliceH   = bmpH / nSlices；rowH = sliceH * totalY
对每一行 t = i/(nSlices-1)：
   ratio = topRatio + (botRatio - topRatio) * t
   dX    = deltaTop + (deltaBot - deltaTop) * t
   zsX   = z + (1 - z) * (1 - zoomDelta(cfg,true,dX))
   tsX   = v.lsx * dynSX * zsX * ratio
   lsX   = L.startX*v.sx + xofs - (camX + linkOffX/v.lsx)*dX + L.velPosX + L.sinOffX
   sliceX= v.gameW/2 + lsX * (v.lsx * zsX)
```

**为什么这么做**：MUGEN 的 `parallax` 参数描述的是一块「上窄下宽」的梯形屏幕，靠两个宽度比例 + 两个 delta 定义。Flash 没有梯形贴图，所以用**行切片 + 每行独立 x 缩放**逼近；`xofs` 项（`|scaleStartX| * (-topW*0.5 + axisX*(topW/bmpW)) * sx`）负责把轴心折算到梯形上沿。

### 4.7 平铺：三种铺法，判据各不相同

| 情形 | 判据 | 实现 | 结果 |
|---|---|---|---|
| 不铺 | `tileX==0 && tileY==0 && type!="parallax"` | `drawPlain()`：整块 `Bitmap` 用 `transform.matrix` 摆位（含翻转/斜切/旋转） | 一张图，宽度=图片宽 |
| 铺 + 有间距 | `tileX!=0` 且 `tilespacing[0] > 0` | `drawTiled()` 第一条分支：显式循环 `beginBitmapFill`，步长 `stride` | 每块单独绘制，`stride` 决定密度 |
| 铺 + 无间距 | `tileX!=0` 或 `tileY!=0`，`spacing <= 0` | `drawTiled()` 第二条分支：一次 `beginBitmapFill(..., true, false)` + 覆盖矩形 | 横向铺满 `0..gameW`、纵向铺满 `0..gameH` |
| 视差 + 平铺 | `type=="parallax"` 且（`tileX!=0` 或 `xshear!=0`） | `drawParallax()` 里 `repeatX = true` → 每行 `beginBitmapFill(..., true, ...)` + 整屏宽矩形 | 逐行整屏重复 |
| 视差 + 不平铺 | `type=="parallax"` 且 `tileX==0` 且 `xshear==0` | `drawParallax()` 里 `repeatX = false` → `beginBitmapFill(..., false, ...)` + 只画 `drawW = bmpW*tsX` 宽 | 只画自己的宽（v2.5 修复点，见 §4.13） |

`tilespacing` 的两套步长（代码原文）：

```text
stride = (L.actionno != -1) ? tilespacing[0] : bmpW + tilespacing[0]
```

即：**动画层**的间距就是「块间距」本身（帧图尺寸变化不影响节拍），**静态层**的间距是「图片宽 + 间距」。起始相位用 `curX = finalX % strideX` 再向前对齐，因此平铺图案随层移动而无缝滑动（GreatCanyon 的 `BG Fog`：`tile=[1,0]`、`velocity=[-0.8,0]` 就是靠这个滚）。

### 4.8 混合模式与 trans：两个类怎么分工

**分工结论**：`JsonStageFx` 只写 `DisplayObject` 的**状态**（`blendMode/alpha/colorTransform`），`JsonLayerRenderer` 只写**几何**（`transform.matrix` 或 `Graphics` 的 `beginBitmapFill`）。两者通过同一个 `Sprite` 复合：平铺/视差路径把 `Bitmap` 隐藏（`bmp.visible=false`）改用 `Graphics` 画，但 `blendMode/alpha` 依然作用在这个 `Sprite` 上，所以 trans 对三条路径同时有效。

`applyTrans()` 的分支表（`map/JsonStageFx.as:JsonStageFx.applyTrans()`，全部按代码顺序）：

| trans 形态 | 判定 | 结果 |
|---|---|---|
| `none` / 空 | `t=="none" \|\| t==""` | `NORMAL`，`alpha=1`（**并清掉此前的 tint**） |
| `addalpha` 且 `alpha[1] < 250` | `t=="addalpha" && alphaArr.length>1 && alphaArr[1]<250` | `NORMAL` + `colorTransform` 提亮 `gain` + `alpha = cover`（§4.13） |
| `add` / `addalpha` / `a` | 三值同分支 | `ADD`，`alpha = alpha[0]/256` |
| `add1` / `a1` | — | `ADD`，固定 `alpha=0.5` |
| `sub` / `s` | — | `SUBTRACT`，`alpha = alpha[0]/256` |
| `as<src>d<dst>` | `t.indexOf("as")==0` 且能找到 `d` | `dst>=256` → `ADD`，否则 `NORMAL`；`alpha = src/256` |
| 其它任意串 | 落到函数底部 | `NORMAL`，`alpha = alpha[0]/256` |

实测帧级 trans 分布（4446 帧）：`none` 1510、`a` 979，其余是把 `AS<src>D<dst>` 直接小写成 `as252d256` 这类**约 250 种不同取值**，其中 `dst<256` 的组合真实存在（如 `as150d100`、`as256d0`、`as10d255`）。也就是说：`as` 分支的两种去向都被真实数据用到，不是死代码。

三条优先规则（容易踩，见 §5）：

1. 层建好时若没有 `actionno`，立即 `applyTrans(spr, lc.trans, lc.alpha)` 一次；有 `actionno` 则由首帧 `applyFrame()` 决定。
2. 有帧动画时，帧 `trans != "none"` 用帧的，否则**回落到层级 trans**。
3. `applyTrans()` 开头会检查弱键字典 `_tinted[target]`：只要之前 tint 过，就先清空 `colorTransform`。于是**控制器 `palfx` 写的 colorTransform 会被下一次 `applyTrans()` 抹掉**（两者争用同一属性）。

### 4.9 控制器：MUGEN 的 stage controller 子集

`stage.json` 的 `controllers[]` 元素形态（唯一有真实数据的样本 MossGrotto）：

```json
{"name":"BGCtrl Bloom_Pos_reset","type":"PosAdd","ctrl_id":1161,
 "ctrl_ids":[1161],"time":[719,719,720],"x":-5760.0,"y":4320.0}
```

调度（`JsonMapMain.runControllers()`）：

```text
t0=time[0], t1=time[1], lp=time[2]（缺省 -1）
若 t0 < 0 → 整条跳过；若 lp >= 0 且 t0 >= lp → 整条跳过
if (lp > 0 && t1 > lp) t1 = lp                     // 夹到循环上界
on = (_stageTick >= t0) && (lp > 0 ? (_stageTick - t0) % lp <= t1 - t0
                                : _stageTick <= t1)
执行后统一 ++_stageTick                          // 注意：在循环外，一次 pass 只加 1
```

作用对象判定（`JsonStageFx.matches()`）：控制器 `ctrl_ids`（或 `ctrl_id`，标量/数组均可，经 `targetIds()` 归一）逐个与层的 `ctrlId` 比；**只要列表里出现 `-1` 就匹配所有层**。

支持的 `type`（`applyController()`，全部转小写后 switch）：

| type | 效果 | 字段 |
|---|---|---|
| `velset` | 覆盖 `L.velX/velY` | `x/y` |
| `veladd` | 累加 `L.velX/velY` | `x/y` |
| `posset` | 覆盖 `L.velPosX/velPosY` | `x/y` |
| `posadd` | 累加 `L.velPosX/velPosY` | `x/y` |
| `sinx` / `siny` | 重设正弦参数与相位 | `value:[振幅,周期,相位度]` |
| `palfx` | 写 `colorTransform`（`mul/256` 乘法 + `add` 偏移） | `mul:[r,g,b]`、`add:[r,g,b]` |
| `visible` | 写 `L.ctrlVisible` 与 `sprite.visible` | `value`（非 0 可见） |
| `anim` | **不走 `JsonStageFx`**：在 `JsonMapMain.applyController()` 里切动作 | `value` = 新 actionno |

注意 `anim` 是特例：它换的是 `L.actionFrames` 并把 `curFrameIdx/curFrameTick` 归零，等于「换一条动画轨」；其余 type 都只是写 `L` 上的数值。数据侧：20 张图里只有 MossGrotto 有 1 条控制器（`PosAdd`），所以除 `posadd` 外的分支**在本批资源里没有真实调用**。

### 4.10 舞台尺寸与相机边界（只给结论）

`initByJSON()` 里的尺寸推导（`gw=800, gh=600`）：

```text
scW/scH = stageinfo.localcoord（缺省 1280×720）
_lsx = gw / scW；_lsy = gh / scH
viewZoom = min(camera.zoomout > 0 ? zoomout : 1, minGameZoom=1)
halfSpan = gw * 0.5 / viewZoom
_stageWidth = (boundright - boundleft) * _lsx + halfSpan * 2
_stageHalf  = _stageWidth * 0.5
left  = _stageHalf + boundleft  * _lsx - halfSpan      // 化简 = _lsx*(bl+br)/2
right = _stageHalf + boundright * _lsx + halfSpan
playerBottom = stageinfo.zoffset * _lsy
bottom = max(gh, playerBottom)
playerinfo.leftbound/rightbound → 夹紧 left/right（若两键都存在）
```

实测三档（照上式代数字）：

| 图 | localcoord | lsx / lsy | zoomout | _stageWidth | left / right | playerBottom | bottom |
|---|---|---|---|---|---|---|---|
| temple | 1280×720 | 0.625 / 0.8333 | 0.6 | 2000*0.625 + 1333.3 = **2583.3** | 0 / 2583.3 | 650*0.8333 = 541.7 | 600 |
| GreatCanyon | 850×480 | 0.9412 / 1.25 | 0.5 | 40*0.9412 + 1600 = **1637.6** | 0 / 1637.6 | 467*1.25 = 583.75 | 600 |
| kanto | 1280×720 | 0.625 / 0.8333 | 0.7 | 1140*0.625 + 1142.9 = **1855.4** | 0 / 1855.4 | 670*0.8333 = 558.3 | 600 |

边界对称时 `left` 恒等于 0（上面三张都是），因为 `left = _lsx*(bl+br)/2`，而三张图的 `bl+br = 0`。

相机侧（`state/GameState.as:GameState.initCamera()`，与主项目同构）：

- `getStageSize()` 返回 `Point(_stageWidth, GameConfig.GAME_SIZE.y)`——**高度恒为 600**，与 `localcoord` 无关。
- `camera.setStageBounds(new Rectangle(0,-1000,stageSize.x,stageSize.y))`——水平范围正好是 `[0,_stageWidth]`，与 `left=0` 对齐。
- `camera.offsetY = getMapBottomDistance() = bottom - playerBottom`（temple 58.3、GreatCanyon 16.25、kanto 41.7）。
- 结论：**JSON 的垂直边界信息进不了相机**。`camera.boundhigh/boundlow/verticalfollow/tension/tensionhigh/tensionlow/floortension/overdrawhigh/overdrawlow/cuthigh/cutlow/startx/starty` 全部只在 `initByJSON()` 里被忽略（没有一处读取）。

`getFloorHitTest()` 只查一块地面：`_floorList = [xFrom=left-2000, xTo=right+2000, y=playerBottom]`。MUGEN 舞台本来也没有多层地面，这是等价映射，不是缺失。

### 4.11 BGM / 音效声明在哪、怎么播

**结论**：`stage.json` 的 `music` 块是**纯死数据**。真正播的 BGM 来自 `map.xml`。

证据链：

1. `JsonMapMain.initByJSON()` 把 `music.bgmusic/bgmvolume/bgmloopstart/bgmloopend` 分别写进 `bgMusic/bgmVolume/bgmLoopStart/bgmLoopEnd`（4 个 public 字段）。
2. 全树 grep 这四个字段：只有 `JsonMapMain` 自己的声明与赋值，**没有任何读取点**。
3. 真正播歌的链路是：`map.xml` 的 `<bgm url>` → `MapVO.bgm` → `MapModel.getMapBGM(id)` 造一个 `BgmVO{id:"map", rate:1}` → `SoundCtrl` 把它塞进 `_bgmObj["map"]` → 开局 `GameCtrl.smartPlayGameBGM("map")` → `SoundCtrl.playFighterBGM("map")` → `BGM(sound)`。
4. 主项目同样如此：`主项目 state/LoadingState.as` 在 `GameLoader.loadMap` 回调里读 `param1.data.bgm` 造 `{id:"map",url,rate:1}` 推进 `_fightBGMs`。

`stage.json` 里没有「音效」概念：12 个顶层键里没有任何 sfx/sound 字段，MUGEN 的 `[Sound]` 段在转换器里也没落地。

副作用（真实后果）：`map.xml` 的 `<bgm rate="70">` 属性没有读者——3.7 的 `MapVO.initByXML()` 只取 `@url`，`rate` 硬编码 1；全树只有 `FighterVO.initByXML()` 读 `@rate` 并除以 100。所以 JSON 地图的 BGM 音量永远是 1.0，与 audit.txt 里反复出现的「`bgmvolume = 255` 比 100 大」提醒无关——那条音量根本没有进入播放链。

### 4.12 与 MUGEN .def 的对应：audit.txt 每一类行是什么意思

audit.txt 是转换器写给人看的对账单，20 张图各一份。四类行：

| audit 行 | 含义 | 例（temple） |
|---|---|---|
| `BG layers in .def: N \| in stage.json: M` | .def 的 `[BGdef]` 层数 vs 导出层数。相等=一层不落 | `81 \| 81` |
| `Frame features used: {...}` | 这批 AIR 帧里实际出现了哪些 MUGEN 帧特性（`trans as` / `trans a` / `xscale` / `yscale` / `interpolate blend` / `interpolate angle` / `angle`）。是**能力清单**，不是错误 | `{'trans as': 763, 'interpolate blend': 4}` |
| `Runtime note: ...` | 运行时行为提醒：这类层在旧版运行时上会画错，需要 v2.5 的两个文件（§4.13） | `addalpha with a destination value below 250 ... darkens what is behind it` |
| `NOT SUPPORTED / CHECK THESE` | 转换器的**已知缺口**：拿不准或主动放弃的东西逐条列出 | 见 §4.14 |

对应关系（MUGEN → JSON → 运行时）挑主要的几条：

| MUGEN | JSON | 运行时 |
|---|---|---|
| `[BGdef] bg ...` 每个 `bg` 段 | 一个 `layers[]` 元素 | 一个 `L` + 一个 `Sprite` |
| `trans = addalpha` / `AS<src>D<dst>` | `trans:"addalpha"` / `"as252d256"` + `alpha` | `applyTrans()` 分支 |
| AIR 动画 | `actions[actionno]` 帧数组，`layerno` 层用 `actionno` 挂上 | `stepFrames()` |
| `delta = x,y` | `delta:[x,y]` | `-camX*deltaX` 项 |
| `tile = 1,0` / `tilespacing` | `tile` / `tilespacing` | `drawTiled()` |
| `trans` 的 `mask` 参数（色键） | `mask:0/1` | **不实现**（PNG 自带 alpha） |
| `window` / `maskwindow` | `window:[x1,y1,x2,y2]` / `maskwindow` | `updateMask()` |
| `[BGctrl]` | `controllers[]` | `runControllers()` |
| `[StageInfo] localcoord/zoffset` | `stageinfo` | 尺寸换算 |
| `[Camera] boundleft/boundright` | `camera` | 只用于算 `_stageWidth` |
| `[Music] bgmusic` | `music` | **不播**（走 map.xml） |

「时间 0 帧被跳过」这条要单独说清：temple 的 audit 写着 `6 frame(s) with time 0 were skipped (actions 9,10,11,12,13,14)`，样例 `action 9: 15,3,0,0,0,1,0,AS120D256`。

- MUGEN 里 `Time = 0` 的帧不占时间，语义上「列出但不显示」。
- 转换器**直接删掉**这些帧，而不是导出成 `ticks:0`。理由是运行时的兜底是 `ticks = cur.ticks > 0 ? cur.ticks : 1`——若保留 0，它会被当成 1 tick 显示一帧，反而多出停顿，且总时长 +1。
- 后果：这些 action 的**帧序列与循环长度变了**（少了 1 帧），如果原 AIR 依赖该帧做轴心/缩放跳变，动画细节会变钝。audit 把它列入「与 MUGEN 观感不同」的检查项，属于**已知损失**而不是 bug。
- 数据侧印证：20 张图 4446 帧里 `ticks` 的取值只有 `-1` 与 ≥1（最小 1），没有 0。

### 4.13 v2.5 runtime patch：两条修复在代码里长什么样

audit 点名两处运行时差异，要求「v2.5 runtime patch 的 `JsonStageFx.as` / `JsonLayerRenderer.as`」。下面逐条对照代码，并给出「哪些细节支持、哪些只能部分支持」。

#### 4.13.1 addalpha 变黑纱

audit 原文（temple / HiddenRain / Training 三份）：`addalpha with a destination value below 250 (...) darkens what is behind it. JsonStageFx.as from the v2.5 runtime patch is needed, an older one draws it as a plain alpha veil and the whole stage looks too dark.`

代码事实（`JsonStageFx.applyTrans()`）：

```text
if (t == "addalpha" && alphaArr && alphaArr.length > 1 && Number(alphaArr[1]) < 250) {
   cover = 1 - clamp(alphaArr[1]/256, 0, 1)
   gain  = max(0, alphaArr[0]/256) / cover
   blendMode = NORMAL
   colorTransform = (gain, gain, gain, 1, 0,0,0,0)   // 只提亮，不动 alpha 通道
   alpha = cover
   return
}
```

**支持这条 audit 的三点**：

1. 分支存在，且判据用的阈值正是 **250**，与 audit 的「below 250」逐字对上——这是转换器作者与运行时作者共享的同一个常数。
2. 行为确实是「把目标 alpha 折算成不透明度 + 亮度补偿」而不是「叠加」：`blendMode = NORMAL`。不加补偿的话（旧版按普通 alpha 罩一层），黑色图会变成半透明黑纱压在背景上——正是 audit 说的 `looks too dark`。
3. `alpha[1]` 正好对应 MUGEN 的 `AS<src>D<dst>` 里的 `D` 分量；`dst<250` 意味着「目标被压暗」，代码把这层暗化折进 `cover/gain`。

**只能部分支持的部分（要诚实说）**：这是一种**近似**，不是 MUGEN 的精确合成。MUGEN 的 `addalpha` 是「加法混合，且目标 alpha 参与衰减」；这里换成 `NORMAL` + 提亮 + `cover` 不透明度，只有在目标几乎均匀时才接近。数值上：temple 的 `bg_1`（`alpha:[256,32]`，name `BG 0,black orb`）→ `cover = 1-32/256 = 0.875`、`gain = 1/0.875 ≈ 1.143`，即「87.5% 不透明 + 提亮 14.3%」。这与 MUGEN 原式的差值需要对比截图才能量化（§7）。

**边界**：`dst >= 250` 时**不**走这条分支，落到普通 `ADD` + `alpha=src/256`。所以 `dst=250..255` 的层仍然是「纯叠加」；数据里 `d256` 占绝大多数，`d<250` 的 `as` 组合与 `addalpha` 层才是这条分支的实际用户。

#### 4.13.2 未平铺的视差层被重复铺满整屏

audit 原文（temple / HiddenRain / destiny）：`N parallax layer(s) are not tiled (...). JsonLayerRenderer.as from the v2.5 runtime patch is needed: an older one repeats such a sprite across the whole screen width.`；HiddenRain 还多一句：`strong perspective, bottom much wider than top (...): an older renderer draws it as a staircase.`

代码事实（`JsonLayerRenderer.drawParallax()`）：

```text
repeatX = (L.tileX != 0) || (L.xshear != 0)
if (repeatX) { beginBitmapFill(bd, m, true,  false); rect(g, v, 0, accY, v.gameW, destH) }
else        { beginBitmapFill(bd, m, false, false); rect(g, v, flipH ? trX-drawW : trX, accY, drawW, destH) }
```

**支持这条 audit 的三点**：

1. `repeatX` 的判据是 `tileX`（以及 `xshear`），**不是**「类型是 parallax」——所以「视差层是否平铺」是逐层决定的，与 audit 的「7 个视差层不平铺」口径一致；temple 实测：15 个 parallax 层、12 层 `tile!=0,0`、3 层不平铺 + 4 个非视差层平铺 = 12 个非零 tile，与统计吻合。
2. 不平铺分支的矩形只有 `drawW = bmpW * tsX` 宽，起点是 `trX`（或翻转时的 `trX-drawW`），**不会横跨整屏**。旧版若统一用 `repeat=true` + 整屏矩形，就会把「本该只有自己那一块」的图横向重复到全屏——正是 audit 描述的错法。
3.「阶梯」问题对应的是**切片数**：旧版没有逐行 ratio，一块图只有一个 `tsX`，上窄下宽的梯形只能画成矩形，「底部远宽于顶部」时相邻层之间出现明显台阶。新版每行重算 `ratio/dX/zsX`，切片越多越接近梯形。

**切片预算是这套修复的另一半**（`wantedSlices()/planSlices()`）：

```text
n    = max(32, ceil(gameW * span / low / 8 * zf) + 1)   // span=|botRatio-topRatio|, low=min(|top|,|bot|)
rows = ceil(bmpH * lsy * parallaxUniY * zf)
want = max(1, min(min(n, MAX_SLICES=96), min(rows, bmpH)))
// 跨层总预算 SLICE_BUDGET=240：先给每层保底 min(32,want)，余量按比例分配
sliceN = base + int((want - base) * f)
```

阈值常量 `SLICES=32`、`STEP_PX=8`、`MAX_SLICES=96`、`SLICE_BUDGET=240` 说明这是**先保正确、再保帧率**的设计：一行一切片，切片数直接等于每帧 `beginBitmapFill` 次数。

**反证检查**（防止把「新代码」当成「一直如此」）：

- 代码里没有任何版本号或开关标注「v2.5」。快照只有一份，无法从源码断定另一代实现长什么样；能断定的只有「当前实现符合 audit 描述的新行为」。
- 唯一可见的兼容开关是 `JsonLayerRenderer.ZOOMDELTA_DEFAULT_FROM_DELTA`（默认 `false`）：关时未提供 `zoomdelta` 的层按 1 处理（跟随缩放），开时改用 `delta` 当 `zoomdelta`。两种口径的视觉差很大，但开关的**来由**不在代码里。
- `JsonMapMain.MUGEN_BLUR`（默认 `false`）与 `MapLayer.OPTICAL_OPT`（默认 `true`）也是同类静态开关，属于「留了后路但默认关」的痕迹。

### 4.14 转换器没支持的东西（NOT SUPPORTED 汇总）

20 份 audit.txt 逐条归类，计数为「出现该条的地图数」：

| 类别 | audit 文案（原文节选） | 张数 | 图 |
|---|---|---|---|
| 音乐文件缺失 | `music file not found next to the .def: Sound/Rooftop.mp3` | 6 | Rooftop, Training, cometrain, GreatCanyon, memorial, mountainpath |
| BGM 音量越界 | `[Music] bgmvolume = 255 is above 100` | 7 | cairo, Desert, forest_quiet, HiddenRain, mountainpath, Rooftop, Training |
| SFF 路径不符 | `[BGdef] spr = stages/xxx.sff was not found; used yyy.sff` | 4 | cometrain, GreatCanyon, memorial, Suki |
| SFF 压缩格式存疑 | `this SFF stores sprites as lz5 (n bersih / 0 mencurigakan): ... belum pernah dicocokkan dengan gambar aslinya` | 4 | cairo, forest_quiet, GreatCanyon, memorial |
| 相机键不支持 | `[Camera] key not supported: boundhighzoomdelta` | 1 | karakura |
| 相机边界反向 | `boundleft = 20 is greater than boundright = -20 (reversed): the camera is fixed; exported both as 0` | 1 | forest_quiet |
| sprite 不存在 | `sprite 7,0 is not in the SFF (used by: action 1)` / `sprite -1,-1 is not in the SFF` | 2 | kurama, night_forest |
| 时间 0 帧被删 | `6 frame(s) with time 0 were skipped (MUGEN shows them for no time)` | 1 | temple |
| 层数减少（非错误） | `in stage.json: 7  (fewer = R/G/B layers merged)` | 1 | cometrain |

另有 5 张图完全干净（`AUDIT: nothing unsupported found`）：building、kanto、MossGrotto、rainy_moon、destiny。

几条后果要说清（都由代码或数据佐证）：

- **音乐缺失/BGM 越界**：因为 BGM 根本不走 `stage.json`（§4.11），这两类在 BVN 里**不产生后果**——真正决定听感的是 `map.xml` 的 `<bgm>`。
- **相机边界反向被折成 0**：forest_quiet 导出后 `boundleft=boundright=0`，代入 §4.10 公式得 `_stageWidth = 0 + 800/zoomout`，舞台宽度就等于一屏，镜头无法横移——这正是 audit 想要的「固定镜头」。
- **sprite 不存在**：`JsonMapLoader` 对缺失图只记日志不失败（`onBad` → `imageDone()`），该帧 → `_cache[ref]` 为空 → `applyFrame()` 里 `src` 为 null → `L.hidden = true`。结果是那一帧变成「空白帧」而不是报错。
- **层数减少（RGB 合并）**：cometrain 的 9 层导出成 7 层，被合并的层带 `merged_rgb` 标记；运行时既不读该标记也不还原分层，所以合并是不可逆的（画面等价，只是少了单独调参的余地）。

---

## 5. 陷阱与反编译噪音

### 5.1 会让人踩坑的运行时行为

| # | 陷阱 | 证据 | 后果 |
|---|---|---|---|
| 1 | `GameState.initFight()` 末尾必须 `_map.mapLayer` 为真，否则 `throw new Error("map is error! :: mapLayer is null!")` | `state/GameState.as:GameState.initFight()`（同一检查在 `initMosouFight()` 重复一次） | JSON 路径靠 `mapLayer = new MapLayer(new Sprite())` 这个**空壳**过关；移植时若把它置 null，开局直接抛错 |
| 2 | `mapMc` 是空壳：`initByJSON()` 里 `mapMc.addChild(bgLayer/frontLayer)`，随后 `GameState.initFight()` 又对同样两个对象 `addChild` 到别处（Flash 会自动从原父级摘除） | `map/JsonMapMain.as:JsonMapMain.initByJSON()` 末尾 + `GameState.initFight()` | 真正的父级是 `GameState`（bg）与 `_gameLayer`（front）；跳过 GameState 挂载 = 全黑 |
| 3 | 前景层不再有「挡角色时半透明」 | `map/MapLayer.as:MapLayer.rebuildOpticalCache()` 只收 `c is MovieClip`；JSON 层是 `Sprite` | JSON 关卡的前景（`layerno==1`）永不淡出，人物会被树/柱子挡住 |
| 4 | 背景模糊对 JSON 关卡永久关闭，两道闸 | `JsonMapMain.MUGEN_BLUR=false` → `setSmoothing()` 立即 return；`ctrl/EffectCtrl.as:EffectCtrl.bgBlur()` 里 `if(_gameStage.getMap() is JsonMapMain) return` | KO/必杀时的背景虚化在这类图上不出现（主项目本来也没有这套，见 §6） |
| 5 | 帧 `trans:"none"` 不能「关掉」层级叠加 | `applyFrame()` 里 `if(ft != "none") ... else applyTrans(L.config.trans, ...)` | 想让某几帧恢复普通混合，只能改层级 trans |
| 6 | `interpolate_blend` 直接写 `L.sprite.alpha`，会覆盖 `applyTrans()` 设的透明度 | `stepFrames()` 里 `L.sprite.alpha = min(1,max(0,(a0+(a1-a0)*p)/256))` | 一个既 `addalpha` 又 `interpolate blend` 的动画层，其 alpha 由插值说了算 |
| 7 | 循环点只读 `frames[0].loop_start` | `nextIndex()` | 数据里恒为 0，看起来无害；一旦某张图的循环点非 0，这条实现会忽略它 |
| 8 | 掉帧会加速动画、控制器落后 | `updateTick()` 的 `_step` 与 `_accum`（clamp 2，每帧最多两轮控制器） | 舞台上「云在飘」的速度随设备帧率变化；低端机控制器节拍慢于真实时间 |
| 9 | `dynSY` 只对第一项取绝对值 | `draw()` 里 `Math.abs(L.scaleStartY) + sdy*camY*L.deltaY` | 当 `scaledelta.y*camY*deltaY` 为大负数时，整体可跌破 0.01 被夹成 0.01，层在纵向上「塌成一条线」；`rawSX` 则整式取绝对值，两者口径不一致 |
| 10 | 窗口蒙版的 `+1` 补偿只给 `window` 不给 `maskwindow` | `updateMask()` 里 `w = isMaskWin ? (win[2]-x1) : (win[2]-x1+1)`（高度同理） | 两种窗口在右/下边界差 1px；`maskwindow` 在 20 张图里 0 层使用，属于未跑过的分支 |
| 11 | 蒙版 Sprite 是红色的 | `updateMask()` 里 `g.beginFill(16711680,1)` | 一旦蒙版没生效（父级不在显示列表、`mask` 被覆盖），屏幕上会出现纯红矩形——排障时先看有没有红块 |
| 12 | `palfx` 与 `applyTrans()` 争 `colorTransform` | `applyTrans()` 开头 `if(_tinted[target]) delete ...; colorTransform = new ColorTransform()` | 调色板效果会被下一次换帧抹掉（换帧 → `applyFrame()` → `applyTrans()`） |
| 13 | 前景层（`layerno==1`）走的是「相机空间」路径 | `JsonMapMain.frontInCameraSpace=true` → `fillView()` 写 `v.z=zoom, v.ox=rx, v.oy=ry` → `toContainer()` 除以 `v.z` | 前景层在缩放时保持屏幕尺寸（算式上：`tsx ∝ zsx = zoom`，随后再除以 `zoom`）；普通层没有这一步 |
| 14 | `render(cameraX, cameraY, cameraZoom)` 三个入参被完全忽略 | `JsonMapMain.render()` 开头直接 `readView()` 从 `gameState.camera` 重读 | 想通过改 `GameState` 的传参来偏移地图，对 JSON 关卡无效 |
| 15 | `camLimitLeft/camLimitRight/screenLeft/screenRight/p1Facing..p4Facing/stageAutoTurn/shadowIntensity/shadowColor/shadowYScale/reflectionIntensity/bgMusic/bgmVolume/bgmLoopStart/bgmLoopEnd` 全是「写而不读」 | 全树 grep 后每个符号只有 `JsonMapMain` 内的声明与赋值 | 想调这些参数（倒影、影子、舞台自动转向、角色朝向）会发现完全没反应 |
| 16 | `JsonMapLoader` 只认 `.json` 后缀，不认内容 | `isJsonMapUrl()` | 把 JSON 存成 `.txt` 不会被识别；反过来，`map.xml` 里写 `.json` 但文件是 SWF 会走到 JSON 分支并失败 |
| 17 | 图片缺失被静默吞掉 | `loadImage()` 的 `onBad` 只 `log` 后 `imageDone()` | 少图不会报错，只会「某些层不显示」；排查要看 `JsonMapLoader` 日志 |
| 18 | 外置目录创建清单不含 `maps` | `mob/AssetLoader.as` 里 `foldersToCreate = ["assets","assets/fighter", ... "assets/map"]`（单数 `map`） | 外置发行时若只跑过一键建目录，`assets/maps/<id>/` 仍需手工创建 |

### 5.2 反编译噪音（看着像 bug，其实不是 / 看着对，其实不是）

| # | 现象 | 真相 |
|---|---|---|
| 1 | `MapMain.setVisible()` 开头 `if(false && param1) { return; }`（参考 :98） | 反编译保留的死分支，永假。别照抄 |
| 2 | `MapMain.render()` 里孤立一行 `_loc4_ < _defaultFrontPos.y && _loc4_;`（参考 :350） | 无副作用的表达式语句，反编译产物；真实行为是下一行 `frontLayer.y = _loc4_` |
| 3 | `if(L.windowArr && L.windowArr.length >= 4 \|\| L.maskWindowArr && L.maskWindowArr.length >= 4)` | 依赖 `&&` 高于 `\|\|`，含义是「两者任一够长」，不是漏括号 |
| 4 | `_loc1_/_loc2_/param1/param2` 满天飞 | 局部变量名被反编译重命名，方法与字段原名保留 |
| 5 | `int(int(a[1]) * Number(a[2]) / 360) % int(a[1])` | 先乘后除再取整（截断），不是四舍五入；相位按 360 度折算成 tick |
| 6 | `alpha` 用 0~256、除以 256 | MUGEN 的 alpha 值域就是 0~256，不是笔误 |
| 7 | `shadowColor = uint(col[0]) << 16 \| uint(col[1]) << 8 \| uint(col[2])` | 位或优先级低于移位，写法正确；但 MUGEN 的 color 可到 256，`256<<16` 会溢出 24 位（GreatCanyon 的 `[256,256,256]` 会算成 `0x01010100`）。该字段无人读，暂不产生后果 |
| 8 | `isAdditiveAS()` 里 `trans.indexOf("d")`，`d == -1` 时返回 `true` | 「没有 D 就当加法」的兜底；真正的 `as` 分支还要求 `t.indexOf("as")==0` |
| 9 | `JsonMapLoader` 日志里的 `baca json` / `GAGAL` / `gambar kosong` | 印尼语，作者母语，不是编码错误 |
| 10 | `_viewBg/_viewFront` 是 `{}` 而非类型化对象，靠 `gameW/lsx/camX/zoom/playerBottom/z/ox/oy` 约定 | `fillView()` 是唯一写入口、`draw()` 是唯一读出口；字段名写错不会编译报错 |
| 11 | `MapLayer.renderOptical()` 的 `if(_optCount != n \|\| ++_optTick >= OPTICAL_REFRESH)` | 自增写在条件里（短路副作用），`OPTICAL_REFRESH=8` 时每 8 帧重建一次缓存 |
| 12 | `stageinfo.localcoord` 缺失时按 `[1280,720]` 兜底 | 不是 800×600——兜底值来自 MUGEN 常见分辨率，与游戏画布尺寸无关 |
| 13 | `_ctrls = cfg.controllers \|\| cfg.bgctrls \|\| []` | 两个键名并存（历史命名），数据里全是 `controllers` |
| 14 | `JsonMapMain.destory()` 拼写（不是 destroy） | 与基类 `MapMain.destory()` 一致，是项目内的既有拼写 |
| 15 | `MapLayer.setSmoothing()` 里 `if(param1<=0 && param2<=0){ show(_view); return }` | 0 表示「取消模糊并复原」，不是「不处理」 |

---

## 6. 移植可行性

### 6.1 逐组件判定

| 组件 | 能搬 / 要改 / 搬不了 | 原因与改动点 |
|---|---|---|
| `map/JsonLayerRenderer.as` | **能搬（零改动）** | 只 import `flash.display.Bitmap/BitmapData/Graphics`、`flash.geom.Matrix`；全部数据从入参 `L`/`v` 来，不引用 `GameConfig`、不引用 `MapMain` |
| `map/JsonStageFx.as` | **能搬（零改动）** | 只 import `BlendMode/DisplayObject/ColorTransform/Dictionary` |
| `map/JsonMapLoader.as` | **要改（1 处依赖）** | 依赖 `AssetManager.I.loadJSON()` 与 `AssetManager.I.loadBitmap()`；**主项目缺 `loadJSON`**：`主项目 interfaces/IAssetLoader.as` 只有 `loadXML/loadSwf/loadSound/loadBitmap/dispose/needPreLoad/loadPreLoad`，`主项目 ctrl/AssetManager.as` 也没有 `loadJSON`。需补 3 处：接口 + 实现 + 门面（实现可直接用 `URLLoader` + `JSON.parse`，主项目已有 `mob/utils/JsonUtils.as:JsonUtils.str2json()` 可复用解析） |
| `map/JsonMapMain.as` | **要改（3 类差异）** | ①父类不同：3.7 `MapMain` 的四个层字段是 `MapLayer` 类型，主项目是 `MovieClip/Sprite/Bitmap`；②`setSmoothing()/getSmoothing()/prewarmBlurStep()` 在主项目 `MapMain` **不存在**，AS3 里 `override` 不存在的成员会编译报错——要么给主项目补这三个空实现，要么在移植版里删掉这些 `override`；③`render()` 签名（`Number,Number,Number`）两边一致，可直接 `override` |
| `map/MapLayer.as` | **要裁（约 40 行）** | 主项目没有这个类。JSON 路径只用到 `enabled`、构造、`destory()`、被 `addChild`；`renderOptical()` 对 JSON 层无效（§5.1-3），`setSmoothing()/prewarmBlur()/normalize()` 是 SWF 地图专用 |
| `map/FloorVO.as` | **已有，无需搬** | 主项目 `map/FloorVO.as` 的字段（`y/xFrom/xTo`）与 `hitTest()` 与 3.7 完全同构 |
| `map/MapMain.as`（基类） | **不需要搬，但建议加 3 个空方法** | 见上一行②；加 `getSmoothing():Point`、`setSmoothing(a:Number,b:Number):void`、`prewarmBlurStep(s:int,b:Number):Boolean` 的空实现，能让 `JsonMapMain` 原样 `override` |
| `ctrl/GameLoader.as` | **要加分支（约 10 行）** | 3.7 在 `loadMap()` 里判 `isJsonMapUrl(mv.fileUrl)` → `JsonMapLoader.load()` → `JsonMapMain.create()` → `back(jsonMap)`；主项目同一位置插同样分支即可（主项目 `loadMap()` 的回调签名是 `back(MapMain)`，`JsonMapMain extends MapMain` 天然兼容） |
| `state/LoadingState.as`（主项目） | **要加预载（可选）** | 3.7 的 JSON 预载在 `GameStageLoadCtrl.startLoadingMaps()` + `_mapCache{json,bitmaps}`，主项目没有 `GameStageLoadCtrl` 也没有 `GameRunFactory`，对应位置是 `主项目 state/LoadingState.as` 的 item 分支与缓存字典。**不接预载也能跑**（走 `GameLoader.loadMap` 直载），代价是开局那一刻才拉图 |
| `data/MapVO.as` / `MapModel.as` | **不用改** | `fileUrl` 本就是字符串；主项目 `MapModel.mergeByXML()` 已被 `主项目 ctrl/GameLoader.as:GameLoader._loadExternalConfigsImpl()` 调用来合并外置 `map.xml`，JSON 条目可直接进 |
| `config/map.xml` | **加条目** | `<file url="maps/<id>/stage.json"/>`。注意 3.7 里 url **不带 `assets/` 前缀**（由 `getFullUrl()` 补），主项目 `主项目 ctrl/AssetLoader.as` 的前缀规则不同（有自己的外置解析与 `assets/` 剥离），实际前缀需按主项目 `AssetLoader` 实测 |
| `state/GameCamera.as` | **不用改** | 只要 `getStageSize()` 与 `getMapBottomDistance()` 返回值正确；主项目 `GameCamera` 同样有 `getScreenRect(Boolean)` 与 `getZoom(Boolean)`，`JsonMapMain` 通过 `gameState.camera` 动态取用 |
| `ctrl/EffectCtrl.as`（背景模糊） | **不用改** | 主项目全树没有 `bgBlur/BG_BULR/setSmoothing`（grep 0 命中），这套机制在主项目本就不存在，因此「JSON 关卡不参与模糊」自动成立 |
| `data/FighterScaleModel.as` | **可选，建议搬判定** | 3.7 在 `GameRunFactory.createMapByData()` 里对 JSON 地图置 `FighterScaleModel.I.mugenStage = true`，让 MUGEN 出身的角色按 `localcoord` 缩放。主项目 `FighterScaleModel` 若有同类开关，同样在「这张图是 JSON」时置位，否则人物比例会与预期不符 |

### 6.2 最小改动清单（按文件）

```text
新增：map/JsonLayerRenderer.as        （原样搬）
新增：map/JsonStageFx.as              （原样搬）
新增：map/JsonMapLoader.as            （改 1 处：loadJSON 来源）
新增：map/JsonMapMain.as              （改 3 处：父类层字段类型 / override 集合 / 无 setSmoothing 家族）
新增：map/MapLayer.as                 （裁到最小：enabled + 构造 + destory）
改：  map/MapMain.as                  （+3 个空方法：getSmoothing/setSmoothing/prewarmBlurStep）
改：  interfaces/IAssetLoader.as      （+loadJSON）
改：  ctrl/AssetLoader.as             （+loadJSON 实现）
改：  ctrl/AssetManager.as            （+loadJSON 门面）
改：  ctrl/GameLoader.as              （loadMap 内 +JSON 分支，约 10 行）
配置：assets/config/map.xml           （+<file url="maps/<id>/stage.json"/>）
资源：assets/maps/<id>/               （stage.json + PNG）
```

### 6.3 代价：算得出来的部分

| 项 | 量 | 取证 |
|---|---|---|
| 新增/改动文件 | 5 新增 + 6 改动（含配置） | §6.2 清单 |
| 新增代码量 | 渲染器 439 行 + 特效 251 行 + 加载器 306 行 + 建图 769 行 = 1765 行（反编译体量，手写会更短） | 各文件行数（`(Get-Content).Count`） |
| 资源体积（20 张图） | **211.3 MB** PNG（1998 张）+ 2.0 MB JSON + 64.8 MB 音频（16 首） | `Get-ChildItem -Recurse` 求和 |
| 单图最大 | temple 415 KB JSON / 184 张 PNG；Rooftop 331 KB JSON；Suki 671 张 PNG | 目录清点 |
| 与主项目冲突面 | 只有 `MapMain.as`、`IAssetLoader.as`、`AssetLoader.as`、`AssetManager.as`、`GameLoader.as` 五个既有文件，且都是**追加**而非替换 | 主项目 grep |

### 6.4 「只搬渲染器、不搬格式」可行吗

**可行，但要写一层适配器；判断依据如下。**

渲染器的输入契约只有两样东西：层运行时对象 `L` 与视图参数 `v`。`L` 的键由 `JsonMapMain.newLayer()` 造，`v` 的键由 `JsonMapMain.fillView()` 造；`JsonLayerRenderer` 与 `JsonStageFx` 不认识 JSON、不认识 MUGEN、不认识 `MapMain`。所以完全可以：

1. **保留主项目的 SWF 地图格式**，另写一个 `SwfToLayerAdapter`：把 SWF 里的 `bg/map/front/front_fix` 四个元件（主项目 `主项目 map/MapMain.as:MapMain.initlize()` 就是按名字取 `"line_left"/"map"/"front"/"bg"/"floor"`）展开成若干 `L`，每个 `L` 的 `img_ref` 换成直接持有的 `BitmapData`，其余字段按 MUGEN 缺省值填（`delta=[1,1]`、`tile=[0,0]`、`trans="none"` 等）。
2. 保留 `JsonMapMain` 的「每帧 readView + 逐层 draw」骨架，但不读 `stage.json`——舞台尺寸改从 SWF 的 `line_left/line_right/line_player_bottom` 推（主项目 `MapMain` 已有这套读取）。
3. 收益：SWF 地图获得 MUGEN 式的 `delta/tile/parallax` 能力；代价：SWF 地图本来就是美术画好的整块背景，天然不需要这些能力。

**结论口径**：技术上可拆，工程上不划算——收益只在「想让 SWF 地图也支持视差/平铺」，而 JSON 地图的收益来自**资源产能**（直接把 MUGEN 舞台批量转进来，211 MB / 20 张图），不是来自渲染器本身。真正值得先做的是 §6.2 的最小清单。

### 6.5 明确搬不了 / 不该搬

| 项 | 原因 |
|---|---|
| `MapLayer.renderOptical()` 的「前景挡人半透明」 | 对 JSON 层无效（子项不是 `MovieClip`）；搬过去只会带来每帧 `getBounds` 开销 |
| `MapLayer.getBlurBitmap()/prewarmBlur()` 与 `MapMain.prewarmBlurStep()` 的模糊预热 | 主项目没有背景模糊机制，`MUGEN_BLUR` 默认 false，搬来是纯死代码 |
| `GameStageLoadCtrl` / `GameRunFactory` 的整套加载工厂 | 主项目的加载编排在 `LoadingState`，两套并存会重复加载；只取「缓存结构 `{json,bitmaps}`」这一条 |
| `stages.json` 注册存根 | 代码零引用；注册仍走 `map.xml` |
| `mob/AssetLoader.getFullUrl()` 的 Android 固定路径（`/storage/emulated/0/assets/...`） | 主项目外置根是 `Android/media/air.com.bvn.yy798/BVN/assets/`，路径契约不同（见 CLAUDE.md 外置资源契约），必须换成主项目 `AssetLoader` 的解析 |

---

## 7. 未实测清单

以下每一条都**没有运行验证**，不可当作已知事实继续推演。

- [ ] **缺 `actions` 的 stage.json 是否真的走失败分支**：正文结论由 `for(key in actions)` 位于 `try` 内 + AS3 `for-in` 对 `undefined` 抛 TypeError 推出。验证手段：造一份删掉 `actions` 的最小 JSON，在 PC 上跑 `GameLoader.loadMap`，看日志是 `json OK` 还是 `stage.json bermasalah`。
- [ ] **`addalpha` 近似与 MUGEN 原画的差异量**：需要同一张图在 MUGEN（或 Ikemen GO）与 BVN 下各截一帧同机位画面做像素差；重点是 temple 的 `BG 0,black orb`（`alpha:[256,32]`）与 Training 的 `BG Floor Reflex`。
- [ ] **`dst=250..255` 的层是否「太亮或太透」**：`addalpha` 分支的 `<250` 门槛意味着 250~255 落到普通 `ADD`。需要挑一张含该区间的图（temple 的 `alpha:[128,255]` 层）比对。
- [ ] **切片数对帧率的影响**：`SLICE_BUDGET=240` 是设计值，手机上每帧 240 次 `beginBitmapFill` 的代价未测。手段：在 temple / HiddenRain 上用 `Debugger` 打点统计 `drawParallax` 的 `nSlices` 总和与帧时间。
- [ ] **`as` 帧的 alpha 是否被 `interpolate_blend` 覆盖**：§5.1-6 是代码层结论，需要一张同时具备两者的地图（night_forest 有 `interpolate blend` 18 帧）实测观感。
- [ ] **`loop_start` 非 0 的行为**：现有 20 张图全为 0，`nextIndex()` 只读 `frames[0]` 这一点无法被现有资源证伪；需手工改一份 JSON 造 `loop_start=5` 观察。
- [ ] **`maskwindow` 分支（含 `+1` 差异）**：20 张图 0 层使用，属完全未跑过的代码；需手工造层验证 1px 差异是否肉眼可见。
- [ ] **`positionlink` 行为**：代码支持（`render()` 里叠加父层正弦偏移、`drawParallax()` 里对齐 `lastFinalX/lastFinalY`），数据 0 层使用；需手工构造两层验证。
- [ ] **`left < 0` 时的相机表现**：三张样本图的 `boundleft+boundright=0` 使 `left=0`；若某图不对称（如 `boundleft=-800, boundright=200`），`left` 会为负，而 `setStageBounds(Rectangle(0,...))` 的下界是 0，人物可走出相机可视区。需要一张不对称图或改参数实测。
- [ ] **`bottom - playerBottom` 为 0 的情况**：`bottom = max(600, playerBottom)` 保证非负；当 `zoffset*_lsy >= 600` 时 `bottom == playerBottom`，`getMapBottomDistance()==0`，相机 `offsetY` 归零，纵向构图会变。需要一张 zoffset 很大的图实测。
- [ ] **`SUBTRACT` 混合模式在移动端 / GPU 模式的表现**：`applyTrans()` 对 `sub`/`s` 用 `BlendMode.SUBTRACT`；主项目有 `utils/BlendModeCompat.as` 与 GPU 滤镜代理层，二者是否兼容未测。
- [ ] **`bmp.smoothing = false` 的观感**：`newLayer()` 里硬编码关闭平滑，MUGEN 像素风依赖硬边；但在高 DPI 手机上放大倍率非整数时会出现锯齿，需要真机截图判断。
- [ ] **211 MB 位图常驻的内存曲线**：`JsonMapLoader` 对每张图 `clone()` 一份放缓存，20 张图全预载时的峰值内存未测（尤其 Suki 671 张、memorial 290 张）。手段：真机 `System.totalMemory` 采样。
- [ ] **`disposeCache()` 的时机**：只在 `JsonMapMain.destory()`（`disposeCacheOnDestroy=true`）与 `GameStageLoadCtrl.clearCacheDict()` 调用；连打多张图是否泄漏需长跑验证。
- [ ] **帧 `angle` 非 0 的旋转轴心**：`drawPlain()` 里 `translate(dpx-pvx, dpy-pvy) → rotate → translate(pvx,pvy)`，轴心用的是 `finalX+axX*tsx`；night_forest 仅 2 帧非 0，观感未核。
- [ ] **`as` 字符串缺 `d` 的兜底**：`applyTrans()` 的 `as` 分支要求能找到 `d`，否则落到函数底部；现有数据全部形如 `as###d###`，该兜底路径未执行过。
- [ ] **反编译结论的编译可行性**：整棵参考树不可编译（缺 `net.play5d.kyo.*` 与宿主入口），因此本册所有「能搬（零改动）」都是**源码级**判断，未经编译验证。第一步验证手段：把三个类拷进主项目后跑 `./build.bat`。

---

_本册仅覆盖 JSON 地图子系统；相机内部行为见 [02-camera.md](02-camera.md)，类清单与「别覆盖清单」见 [01-diff-inventory.md](01-diff-inventory.md)。_
