# GPU 渲染模式下的滤镜位图代理层

> 适用场景：手机端 `renderMode=gpu`，外部人物包（不可改源码）在运行时给自己或场景节点挂 `filters`。
> 代码位置：`BVNscripts/scripts/net/play5d/game/bvn/views/filter/` + `utils/BlendModeCompat.as`
> 总开关：`GameConfig.GPU_FILTER_PROXY`（默认 `true`）
> 建立日期：2026-10-23

---

## 1. 要解决的问题

`tools/Test/application.xml` 是 `<renderMode>gpu</renderMode>`。Adobe 官方《移动设备 GPU 呈现》明确 GPU 模式**不支持滤镜**，但没写清楚"不支持"到底是什么表现。真机实测（见 §2）是：

- **合成器完全不渲染滤镜**——不是慢、不是降质，是一点效果都没有；
- 更关键的是，**带滤镜的对象在 GPU 模式下会整个不被绘制**。所以外部包一旦给某个节点挂了 `filters`，那个节点就直接消失——这就是"咲夜时停时对手凭空不见"的直接原因。

外部人物包不能改源码，所以只能在引擎侧拦截：把「带滤镜的节点」用位图代理的方式自己画出来。

同一个限制还波及混合模式：GPU 模式不支持 `layer / alpha / erase / overlay / hardlight / lighten / darken`。工程原本有三处踩线，真机上静默失效，现由 `utils/BlendModeCompat.map()` 统一映射。

---

## 2. 真机实测事实（2026-10-23）

实验台：`tools/Test/filter_probe/`（GPU 包 + **CPU 正对照包**），完整结论见
`tools/Test/_report/2026-10-23_GPU滤镜探针结论.md`，原始数据 `_report/filter_probe_{gpu,cpu}.json`。

| # | 问题 | 结论 |
|---|---|---|
| F1 | GPU 合成器是否渲染 `DisplayObject.filters` | **否**（GPU 组绿像素 0 / CPU 组 1130） |
| F2 | `BitmapData.draw()` 是否包含源对象自身的 filters | **是** |
| F2b | 源 `alpha=0`（隐藏）时 `draw()` 是否仍含滤镜 | **是** |
| F3 | `draw()` 是否吃源对象 `alpha=0` | **否**（照样画） |
| F3b | `draw()` 是否吃源对象 `visible=false` | **否** |
| F4 | 链式 `applyFilter` 叠加 | 正确（内核青 + 外圈品红） |
| F5 | `draw()` 是否吃源对象 `colorTransform` | **否** |
| F6 | 源 alpha=0 + 逐帧改内容，`draw()` 结果是否跟随 | **是**（无"滤镜缓存冻结"） |
| — | GlowFilter(blur 24, q1, strength 2) 实际外扩 | 仅 10–15px（远小于 `1.5×blur`），且四边不对称 |

**最重要的推论**：烘焙一个带滤镜的节点只需要**一次 `draw()`**，**绝不能再 `applyFilter`**——否则每个滤镜算两遍（双倍辉光/模糊）。

> 工程里 `KyoUtils.drawBitmapFilter`（钢身辉光）是 `draw + applyFilter`，那是因为它传入的滤镜**不在**目标对象上（`FighterMain._mainMc.filters` 始终为 null）。别把这个写法套到"目标自己带 filters"的场景。

复现方法：

```bash
python tools/Test/filter_probe/build_filter_probe.py      # 出两个 APK（gpu / cpu 正对照）
python tools/Test/filter_probe/run_filter_probe.py gpu cpu
```

判定前提：`valid_red_blocks=true` 且 CPU 组 `F1_filters_rendered=true`。这两条不成立时，GPU 组的结论一律不可信。

---

## 3. 架构：原位兄弟位图代理

```
父容器（例如 _playerLayer / 某个动作 mc / GameState）
├── target 节点            ← 原地不动，只把 alpha 置 0
└── Bitmap "__fproxy"      ← 紧跟 target 之后，z 序 = index(target)+1
        bitmapData  = 在 target 本地坐标系里 draw 出来的结果（滤镜已被 draw 烘进去）
        transform   = target.transform.matrix × T(bounds.x - pad, bounds.y - pad) × S(1/bakeScale)
```

每帧只做三件事：**拷变换**、**拷 alpha/visible/colorTransform/blendMode**、**必要时重烘像素**。

### 3.1 为什么不用"两层镜像树"

| 能力 | 原位兄弟代理（本实现） | 镜像树 |
|---|---|---|
| 嵌套滤镜合成 | **天然正确**：子节点的代理本身就是父节点的子显示对象，父级重烘时自动包含 | 要自己串行重烘 |
| 结构同步（addChild/removeChild） | **不用管**：节点没动 | 必须每帧 diff |
| 帧脚本读 `parent/getChildIndex/numChildren` | 只多一个兄弟节点，语义不变 | 重挂后全错 |
| 变换 | 每帧拷一次矩阵（rotation / 负缩放免费） | 要自己重算祖先链 |
| hitTest | 不需要（本工程受击判定走 `HitVO` + 矩形，与显示树无关） | 要反向映射 |
| 脏标记维度 | 只剩「动画帧号 + filters 签名」 | 草案列了 5 个维度 |

### 3.2 类职责

| 文件 | 职责 |
|---|---|
| `FilterProxyManager.as` | 扫描 / 注册 / 每帧驱动 / 预算 / 自愈 / 诊断 |
| `FilterNodeProxy.as` | 单节点代理：挂摘、签名、烘焙、变换与视觉同步 |
| `FilterPad.as` | 按滤镜类型估算外扩像素（多滤镜**求和**） |
| `FilterSignature.as` | filters 数组 → uint 哈希（双种子，零分配）、动画帧号、诊断摘要 |
| `BitmapDataPool.as` | BitmapData 复用池（32px 分档，单桶 2 张、总量 24） |
| `utils/BlendModeCompat.as` | GPU 安全 blendMode 映射 + 一次告警 |

---

## 4. 关键机制

### 4.1 扫描

- 根：`GameState` 自身（`initFight` 里注册）。**不能只用 `_playerLayer`**——时停这类效果是给 `bgLayer` / `mapLayer` / HUD 挂滤镜，挂在场景层。
- 深度 8，每帧最多 40 个节点（`FPROXY_SCAN_NODES_PER_FRAME`），DFS 双栈 + `Dictionary(true)` 弱键 + `passId` 戳记，不分配新对象。
- 新出现的滤镜节点最迟 `FPROXY_SCAN_INTERVAL`（10 帧）被发现。
- **排除项**：
  - `name == "__fproxy"`（防自噬）
  - HUD 整棵子树（`GameState.initFight` 里 `excludeSubtree(gameUI.getUIDisplay())`，见 §6.2）
  - 被 `EffectCtrl.isFilterTarget()` 占用的节点（给钢身链路让位）

### 4.2 脏标记

只有两个维度会触发重烘：

1. **`frameKey`** — 自身是 MovieClip 用 `currentFrame`；否则取最近 MC 祖先，再混入前两个 MC 子节点的帧号。
2. **`filters` 签名** — 按类型取关键字段（Glow: color/alpha/blur/strength/quality/inner/knockout；ColorMatrix: 20 个系数；Gradient*: 再加 colors/alphas/ratios…），双 32 位哈希同时不等才算变。

盲区兜底：`_contentEpoch`（`invalidate()` / 父级代理增删 / `restartBattle` 时 `++`）。

变换、alpha、染色、blendMode **不参与脏标记**——它们每帧直接拷给代理位图，零烘焙。

### 4.3 烘焙

```as
var sr = target.scrollRect;                          // 有裁剪就只烘可视区
var b  = sr != null ? sr : target.getBounds(target); // 本地坐标系
var pad = FilterPad.sumOf(filters, qCap, maxPad);    // 多滤镜求和
// 降采样：重节点长边 ≤ 512；否则按 maxTex / 像素预算缩
bd.draw(target, M(s, s, (pad-b.x)*s, (pad-b.y)*s), null, null, null, true);
```

- **`draw()` 传 `colorTransform = null`**：染色留到运行时镜像，避免固化。
- 首次烘焙做 `getColorBoundsRect` 非空校验；**全透明视为失败，且失败时绝不接管显示**。
- 单边 / 像素超限时**降采样**而不是跳过（跳过等于让 GPU 把整屏吞掉）。

### 4.4 alpha 与 colorTransform 的顺序（踩过，别再改回去）

`DisplayObject.alpha` 与 `transform.colorTransform.alphaMultiplier` **是同一个值**。

```as
var ct = target.transform.colorTransform;   // ① 必须先读（此时 alpha 还是真值）
var a  = target.alpha;
if (a != 0) _wantedAlpha = a;
if (!_hiding) { target.alpha = 0; _hiding = true; }
ct.alphaMultiplier = 1;                     // ② alpha 只由 display.alpha 承担
display.transform.colorTransform = ct;
display.alpha = _wantedAlpha;               // ③ 最后兜底
```

写反的后果：把源置 0 之后再读 CT，读到的 `alphaMultiplier` 就是 0，赋给代理 → **代理也变透明，烘得再对也看不见**（表现为"滤镜一出现角色就消失"）。

### 4.5 变换同步

```as
var inv = 1 / _bakeScale;
_m.a = nm.a * inv;  _m.b = nm.b * inv;  _m.c = nm.c * inv;  _m.d = nm.d * inv;
_m.tx = nm.a * dx + nm.c * dy + nm.tx;      // dx = bounds.x - pad
_m.ty = nm.b * dx + nm.d * dy + nm.ty;
```

平移只由 `T` 承担、不参与 `S(1/bakeScale)`，所以右乘顺序必须是 `Mt × T × S`。

### 4.6 安全不变量（三条，缺一条就会出"消失"）

1. **`syncVisual()` 在 `display.bitmapData == null` 时必须 `showSource()`，且不置 `target.alpha = 0`。**
   这是"源被藏 + 替身空 = 角色凭空消失"的唯一防线；分帧烘焙期间完全靠它兜底。
2. **只有烘焙成功之后才允许调 `syncVisual()`。**
3. **`syncTransform()` 每帧对所有代理都要跑**，不受烘焙预算影响（否则快移时拖影）。

### 4.7 自愈

每帧 O(代理数)：`target.stage == null` → 回收；代理被误摘 → 重挂；父容器不一致 → 重挂；z 序被打乱 → 复位到 `index(target)+1`；命中 `EffectCtrl.isFilterTarget()` → 让位并恢复源 alpha。

### 4.8 预算（分帧烘焙）

`register()` **不再同步烘焙**，只登记入 `_pending`；由 `tickProxies()` 两段式排空：

- 第一段：`_pending` FIFO，受 `FPROXY_BAKE_BUDGET_MS`（8ms）+ 次数 + 像素三层约束；
- 第二段：稳态刷新，复用同一份预算，**预算耗尽只置标志、不 break**。

`bakes == 0 ||` 是反饥饿：设备本来就跑不到 60fps 时也要保证每帧至少烘一个。

单次 `BitmapData.draw()` 不可分割，所以**单帧峰值 ≈ max(单节点最大耗时, 预算)**，不可能压到预算以内。

---

## 5. 可调参数（`GameConfig.as`，**不进存档**）

| 参数 | 默认 | 说明 |
|---|---|---|
| `GPU_FILTER_PROXY` | `true` | 总开关；`false` = 完全回到没有兼容层的行为 |
| `FPROXY_MAX_PROXIES` | 12 | 并发代理上限（含 pending）；按画质档位覆盖（low 4 / medium 12 / high 16） |
| `FPROXY_MAX_BAKE_PER_FRAME` | 2 | 每帧最多烘几个（兜底） |
| `FPROXY_BAKE_BUDGET_MS` | 8 | 每帧烘焙时间预算（主控）；0 = 不限 |
| `FPROXY_MAX_BAKE_PIXELS_PER_FRAME` | 1000000 | 每帧像素预算（兜底） |
| `FPROXY_SCAN_NODES_PER_FRAME` | 40 | 每帧扫描节点数 |
| `FPROXY_SCAN_INTERVAL` | 10 | 全量重扫间隔（帧） |
| `FPROXY_MAX_DEPTH` | 8 | 扫描深度上限 |
| `FPROXY_BLUR_QUALITY_CAP` | 2 | Blur/Glow quality 上限，只用于估外扩 |
| `FPROXY_MAX_NODE_PIXELS` | 1100000 | 单节点像素上限 |
| `FPROXY_MAX_TEXTURE` | 1024 | 单边纹理上限 |
| `FPROXY_MAX_PAD` | 64 | 外扩像素上限 |
| `FPROXY_DEBUG` | `false` | **诊断总开关**：开后才做 PNG 导出 / 亮度采样 / 全字段 diag |

`FilterNodeProxy` 内部常量：`HEAVY_AREA=200000`（面积）、`HEAVY_MS=16`（≥ 一帧就不逐帧刷）、`HEAVY_SLOW_MS=120`（≥ 3 帧则永不自动重烘）、`HEAVY_MAX_SIDE=512`（重节点烘焙长边）。

---

## 6. 踩过的坑（按时间顺序，都是真机踩出来的）

### 6.1 整屏级节点被"尺寸超限"跳过 → 场景整体消失

第一版把 `FPROXY_MAX_NODE_PIXELS` 定为 36 万，而时停给 `_gameLayer` / `map` / HUD 挂灰度，这些节点 800×600 = 48 万像素 → 全部被跳过 → 源节点仍是"带滤镜"，GPU 不渲染 → 整个画面消失。

**修复**：超限不跳过、改降采样（长边 ≤ 512，最小 0.2×）。

### 6.2 HUD 代理泄漏 → 时停结束后 UI 永久不回来

日志：`+ .../ui_fight bake=512x275` 之后 `-` 只回收了另外 3 个，`proxies` 一直停在 4 —— `ui_fight` 的代理再没被回收，源 alpha 恒为 0，UI 就永久消失。

而且把 HUD 烘成静态图本身也不合理：既糊，又不会跟数值刷新。

**修复**：新增 `FilterProxyManager.excludeSubtree()`，`GameState.initFight` 里把 `gameUI.getUIDisplay()` 整棵子树排除出代理范围。

> ⚠️ 调用时机：`GameUI.getUIDisplay()` = `_ui.getUI()`，`_ui` 要等 `gameUI.initFight()` 之后才存在。放在 `initFight` 开头会抛空引用 → **整个开局中断、卡在加载**。必须放在 `addChild(gameUI.getUIDisplay())` 之后，并且外层加 try/catch。

### 6.3 调试代码留在热路径 → 每次滤镜出现卡一下

同一批节点、同一滤镜签名，两次会话的 `ms` 对比：

| 节点 | 无调试导出 | 有调试导出 |
|---|---|---|
| `map` 1024×456 | 17 / 23 ms | **1224 / 1178 ms** |
| `instance6480` | 28 / 29 ms | 106 / 67 ms |
| `instance6481` | 17 ms | 143 ms |
| 单次时停合计 | **77 ms** | **1647 ms** |

主因：`bake()` 的计时区间里塞了 `BitmapData.encode(PNG)` + 写 345KB 到 `/storage/emulated/0/Android/media/`（Android 11+ 走 FUSE，单次数百毫秒），而 `debugDumpPath` 是**无条件**赋值的。

次因：`register()` 同步烘焙，绕过每帧预算，一次扫描发现 4 个整屏节点就同帧全烘完。

**修复**：诊断整段抽成 `buildDiag()`，只在 `FPROXY_DEBUG` 时调用；`register()` 改入队 + 分帧预算。

> 附带教训：诊断串里 `this.diag = " px=..."` 是**赋值**不是 `+=`，把前面拼好的 `png= / ink= / lum=` 全冲掉了 —— 所以日志里从没出现过 `png=`，这也是没第一时间发现 IO 在跑的原因。

### 6.4 混合模式静默失效

`EffectModel.as:52` 用 `lighten`、`:186` 用 `hardlight`、`ShineEffectView` 暗闪用 `darken`，GPU 模式全不支持。修法**只改赋值处**，数据层不动：

| 源值 | 映射 |
|---|---|
| `lighten` / `hardlight` / `overlay` | `add` |
| `darken` | `multiply` |
| `layer` / `alpha` / `erase` / 其余未知 | `normal` |

33 处 `add` 映射恒等 → 视觉零变化。

---

## 7. 与钢身/金身链路的关系（一字不改）

`FighterEffectCtrl.startGlow/endGlow` → `EffectCtrl.startFilter/endFilter` → `BitmapFilterView` 这条链路**语义完全不动**。它烘的是 `FighterMain.getDisplay()`，与"目标自己带 filters"是两回事。

代理层每帧查 `EffectCtrl.isFilterTarget()`（新增的只读方法），命中就 `detach` 并恢复源 alpha，否则辉光会烘出一片空白。

`FighterMain.changeColor` 写的是 `_mainMc.transform.colorTransform`，代理只镜像不固化 → **改发光颜色 / 取消发光零影响**。

---

## 8. 验收与回归判据

真机日志（`adb exec-out 'run-as air.com.bvn.yy798 cat "…/bvn_debug.log"'`，读之前先 `KEYCODE_HOME` 切后台一次）：

| 断言 | 期望 |
|---|---|
| `[FPROXY] + … ms=` | 小节点 0–5；中等 5–15；整屏级 ≤35。**出现三位数说明还有 IO 在热路径** |
| `png=` | 默认**完全不出现** |
| `+` 行时间戳 | 一次效果里的多个节点应分散在 3–4 个不同毫秒（分帧生效） |
| `scan … pending=` | 稳定态 0；触发峰值 ≤4，3–4 帧内回 0 |
| `live` 行 | `sc=` 非 `null`、`srcA=0`、`dxy≈0` |
| `-` 行 | `restored=true`、`nodeAlpha=1` |

回归必测：① 灵爆/金身黄光正常且结束后无残像；② 换人/重开/退出后 `proxies` 回 0；③ 受击判定不变（命中次数与基线一致）；④ 两人重叠时前后关系正确。

---

## 9. 已知限制

- **重节点内容会"定格"**：≥120ms 的节点只在建立/签名变化/显式 invalidate 时烘一次。时停期间场景本来静止，可接受；若遇到长期挂滤镜且需要动的场景，把 `HEAVY_SLOW_MS` 调大或降到 2fps 刷新。
- **无跨「效果出现/消失」的内容缓存**：每次效果重新出现都会重烘（实测第二次仍是满价）。`BitmapDataPool` 只复用像素缓冲区，不复用内容。
- **镜像节点（`scaleX = -1`）有少量横向偏移**：日志里 `dxy = -23 ~ -37`，只出现在 `m=-1.00` 的行上，与烘焙时的姿态有关，尚未修。
- **没有 mask 支持**：本工程战斗角色不使用 `mask`，遇到会按可见矩形裁剪处理。
- 分辨率与清晰度是折中：`HEAVY_MAX_SIDE=512`，嫌糊可调到 768（代价是烘焙更慢）。

---

## 10. 相关文件

| 路径 | 说明 |
|---|---|
| `BVNscripts/scripts/net/play5d/game/bvn/views/filter/*.as` | 兼容层本体（5 个文件） |
| `BVNscripts/scripts/net/play5d/game/bvn/utils/BlendModeCompat.as` | blendMode 映射 |
| `BVNscripts/scripts/net/play5d/game/bvn/GameConfig.as` | `FPROXY_*` 开关 |
| `GameState.as` | `initFight` 注册根 + 排除 HUD；`destory` 第一行注销 |
| `GameCtrl.as` | `removeGameSprite` 前 `releaseSubtree`；`restartBattle` 后 `invalidateAll`；`pause/resume` 的 `setPaused` |
| `EffectCtrl.as` | 新增只读 `isFilterTarget()` |
| `EffectView.as` / `ShineEffectView.as` | blendMode 改走 `BlendModeCompat.map()` |
| `tools/Test/filter_probe/` | 真机探针实验台（GPU + CPU 正对照） |
| `tools/Test/_report/2026-10-23_GPU滤镜探针结论.md` | 探针完整结论与踩坑 |
| `doc/runtime-pitfalls.md` §2.0 | 结论速查（改移动端前必读） |

---

## 附录 A：改动履历（2026-10-23，按时间顺序）

从立项到可用一共 8 轮，每一轮都是真机反馈驱动的。**记在这里的目的是：下次遇到同类现象能直接对上号，不用再从零猜。**

| 轮 | 现象 | 根因 | 修法 |
|---|---|---|---|
| A0 探针 | —— | 前提全是猜的：GPU 到底渲不渲滤镜、`draw()` 吃不吃滤镜、`applyFilter` 能不能用，全凭经验 | 做 `tools/Test/filter_probe/`（GPU 包 + **CPU 正对照包**），钉死 7 条事实（见 §2）。**其中一条推翻了原设计**：`draw()` 会把源对象的 filters 一起烘进去 → 原计划「draw + 逐滤镜 applyFilter」会算两遍 |
| A1 首版 | 时停时对手/场景**整体消失** | 整屏节点（`_gameLayer`/`map`/HUD，800×600=48 万像素）超过 `FPROXY_MAX_NODE_PIXELS=36万` → 被"安全跳过" → 源节点仍带 filters → GPU 不渲染 | 超限**不跳过，改降采样**（长边 ≤512、像素 ≤110 万、最小 0.2×），并把 `1/s` 还原进显示矩阵 |
| A2 | 时停期间反复冻结 1.2 秒 | 重节点设成「每 10 帧刷新」，而整屏 `draw()` 极慢 → 6 秒里反复冻 | 重节点只烘一次：`_heavySlow`（≥120ms）永不自动重烘，其余按 2fps 兜底 |
| A3 | 时停结束后**UI 永久不回来** | `ui_fight`（HUD，17 个子节点）的滤镜包在效果结束后没清 → 代理常驻 → 源 `alpha` 恒 0 | 新增 `excludeSubtree()`，把 `gameUI.getUIDisplay()` 整棵子树排除出代理范围（HUD 烘静态图本身也没意义） |
| A4 | **卡在加载**，地图出来了但没有角色和 HUD | A3 的 `excludeSubtree(this.gameUI.getUIDisplay())` 放在了 `initFight` **开头**；`getUIDisplay()` = `_ui.getUI()`，`gameUI.initFight()` 之前 `_ui` 是 null → 空引用 → `initFight` 中断 | 挪到 `addChild(gameUI.getUIDisplay())` 之后；并给**所有**外部接入点包 try/catch（兼容层出错不许影响开局） |
| A5 | 烘得对但**看不见**（时停黑屏、I 系技能打中敌人后敌人消失） | `alpha` 与 `transform.colorTransform.alphaMultiplier` **是同一个值**：先把源 `alpha=0` 再读它的 CT，读到的 `alphaMultiplier` 就是 0，赋给代理 → 代理也透明 | 先读 CT → 再藏源 → `ct.alphaMultiplier = 1` → 最后 `display.alpha = _wantedAlpha` 兜底（日志特征：`live … a=0 srcA=0`） |
| A6 | **滤镜每出现一次就卡一次** | 为排查加的 `BitmapData.encode(PNG)` + 写 345KB 到 `/storage/emulated/0/Android/media/`（Android 11+ 走 FUSE）留在 `bake()` 热路径，且 `debugDumpPath` 是**无条件**赋值；次要原因：`register()` 同步烘焙绕过每帧预算 | 诊断整段抽成 `buildDiag()`，只在 `FPROXY_DEBUG` 时调；`register()` 改入队 + `FPROXY_BAKE_BUDGET_MS=8` 分帧预算。**单次 1224ms → 17~29ms，单帧峰值 77ms → ≈29ms** |
| A7 | 三处混合模式**静默失效** | GPU 模式不支持 `layer/alpha/erase/overlay/hardlight/lighten/darken`；工程用了 `lighten`(EffectModel:52)、`hardlight`(:186)、`darken`(ShineEffectView 暗闪) | 只改赋值处、不动数据层：`utils/BlendModeCompat.map()`（lighten/hardlight/overlay→add，darken→multiply，其余→normal）。33 处 `add` 映射恒等，视觉零变化 |

对应提交：`7ca5365 feat(render): GPU 模式滤镜位图代理层 + 3 处 blendMode 修正`，tag `gpu-filter-proxy-2026-10-23`。

**一键回滚**：`GameConfig.GPU_FILTER_PROXY = false` → 完全回到没有兼容层的行为（此时带滤镜的节点会重新变成"消失"，但其他一切照旧）。

---

## 附录 B：错误经验清单（用踩坑换来的规矩）

这几条不只适用于滤镜，**改这个项目的任何热路径都该先过一遍**。

1. **生产热路径里不许有 IO / 编码 / 回读。**
   这次是 `encode(PNG)` + 写 FUSE 把单次烘焙从 17ms 抬到 1224ms。诊断代码一律走默认关闭的开关。

2. **开关判断必须包住整段，不能只包住调用点。**
   `debugDumpPath` 由管理器**无条件**下发，`bake()` 里再判 `!= ""` —— 看起来有开关，实际永远为真。开关要在一处决定、在下游整段生效。

3. **同一个属性只允许一个 owner。**
   `DisplayObject.alpha` 与 `transform.colorTransform.alphaMultiplier` 是同一个槽位。凡是"接管 alpha"的写法，读必须在写之前，且只能有一个通道承担。

4. **"先隐藏源、再显示替代品"必须配一条不变量：没有替代品就不许隐藏。**
   `syncVisual()` 里 `bitmapData == null → showSource()` 这一条，挡住了后面所有的"角色凭空消失"。分帧烘焙、烘焙失败、纹理超限都靠它兜底。

5. **全透明不等于成功。**
   烘焙后必须验非空（`getColorBoundsRect`）；空结果不得接管显示，且要冷却后重试（可能只是"这一刻还没内容"）。

6. **不要在生命周期的早期解引用 UI。**
   `GameUI.getUIDisplay()` 在 `gameUI.initFight()` 之前是 null，放在 `initFight` 开头会**中断整个开局**（表现是卡在加载、地图有但没角色没 HUD，日志里 `scan hit=0`）。

7. **兼容层/观测层出错不许影响主流程。**
   所有外部接入点（`registerRoot` / `excludeSubtree` / `unregisterRoot` / `releaseSubtree` / `invalidateAll` / `setPaused`）全部 try/catch 吞掉。

8. **先做真机探针，再写实现。**
   这次 7 条事实里有 2 条直接改变了设计：`draw()` 含滤镜（砍掉一半工作量、避开"双倍滤镜"）、`draw()` 不吃 `alpha=0`（`alpha=0` 隐藏成为可行的接管手段）。探针必须带 **CPU 正对照组**，否则"GPU 看不见"根本无从判断。

9. **判定要用"整格统计"，不要用固定单点采样。**
   光晕实测只有 10–15px 且四边不对称，采样点差 5px 就落到全透明区，会得出完全相反的结论。

10. **中间产物要能"看见"。**
    把 `BitmapData` 导成 PNG 直接看图，比对着参数猜 20 次都管用（`fp5`/`fp7` 一眼就证明滤镜链路是对的，问题在别处）。但导出必须默认关闭，且不要放在被测的热路径里。

11. **计数字段要对齐语义。**
    `ms` 一度把 PNG 编码和写盘也算了进去，导致"draw 很慢"这个误判持续了两轮。计时区间要明确：这次改成只含 `acquire → fillRect → draw → (首次)非空校验 → 换图`。

12. **别把"能跑通"当成"对了"。**
    第 5 轮之前，代理全都建成功、`live` 行也都正常、日志零报错 —— 但画面就是不显示。最后是靠 `live` 里的 `a=0` 这个字段发现的。**观测字段要能指向"显示状态"，不能只看"是否创建成功"。**
