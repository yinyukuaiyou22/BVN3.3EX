# 批次 6.5 回归测试矩阵

> 本文档记录人物子框（plugin sub-frame）功能在批次 6.0–6.4 实施后，于批次 6.5 阶段沉淀的边界 case 防御矩阵。
> 目标：**真机测试时按 C1–C4 + 4 输入场景表逐项验证**，每项标注代码行号便于快速定位。
> 维护约定：未来批次若修改 `SelectFighterItem.as` / `SelectFighterStage.as` / `SelectStageConfigVO.as` / `MenuBtn.as`，需同步刷新本表行号。

> [!IMPORTANT]
> **2026-10-10 行号与实现现状说明（读前必看）**
> 本文档的 §1、§3、§4、§5、§6 是**批次 6.2–6.5 时期**的快照，描述的是一套**已被替换**的 plugin 子框实现
> （`_pluginContainer:Sprite` / `_initPluginSubUI()` / `showPluginSub()` / `hidePluginSub()` / `isPluginSubVisible()` /
> `_hideAllPluginExcept()` / `_PLUGIN_GLOW_COLOR` / 肩键 LB·RB 展开）。
> 现行实现见 §2：子框是**独立 `SelectFighterItem` 实例集合**（`pluginFighters` + `showPlugins()`/`closePlugins()`），
> 由**触屏长按 1200ms**（`onLongPress` → `SelectFighterStage.touchLongPressHandler`）或鼠标右键触发。
> **§3/§4/§6 的场景名与"期望"列仍可作为回归意图参考，但其"代码行号"列与提及的私有方法名已失效**，
> 按行号定位会指到无关代码；请以 §2 的现行方法索引为准。后续批次应择机整表重写。

---

## 1. 核心数据结构

| 数据层级 | 字段 | 类型 | 来源 | 说明 |
|----------|------|------|------|------|
| `FighterVO` | `pluginIDs:Array` | Array | 批次 6.0 新增 | FighterVO 层占位，select.xml 不解析时为 null |
| `SelectCharListItemVO` | `pluginIDs:Array` | Array | 批次 6.0 新增 | 由 SelectStageConfigVO 解析 select.xml plugin 子节点填充 |
| `SelectCharListItemVO` | `_cloneKey` 末尾 | - | 批次 6.0 | clone() 透传 pluginIDs，null 安全 |
| `SelectFighterItem` | `pluginIDs:Array` | Array | 构造器透传 | 直接持有 SelectCharListItemVO.pluginIDs 引用 |
| `SelectFighterItem` | `pluginFighters:Vector.<SelectFighterItem>` | Vector | **批次 6.8 方案B** | 子框角色实例集合（现行实现，取代 §5 的 `_pluginContainer`） |
| `SelectFighterItem` | `gridOffset:Point` | Point | **批次 6.8 方案B** | 子框相对主角色的 8 方位网格偏移（0,-1 / 0,1 / 1,0 / -1,0 / 对角） |
| `SelectFighterStage` | `_itemObj:Object` | Object | 行 52-60 字段 / 行 248 初始化 | 键 = `x + "," + y` 网格坐标字符串；子框用 `x,y.N` 键（行 407-408） |

---

## 2. 核心方法索引

> 行号口径：2026-10-10 修复后。工具校验方式：按行匹配 `function xxx(` 定义行。

### 2.1 SelectFighterItem.as（555 行）

| 方法 | 行号 | 作用 | 防御点 |
|------|------|------|--------|
| 构造器 | 76-123 | 透传 `pluginIDs`；face 命中则挂 `ui.ct`，未命中则挂名字占位 + ENTER_FRAME 轮询 | 行 82-86 pluginIDs 空防御；行 118-122 `if(this.ui)` 后才注册 ENTER_FRAME |
| `_refreshFace()` | 139-163 | **face 就绪后替换占位**（批次 6.7 治本；2026-10-10 两次修签名） | **首参必须是 `String`**：`(param1:String, param2:Object = null)`（行 139）。`selfHandler` 按 `callback(param1.type, this)` 派发，首参恒为 `"enterFrame"` 这类**字符串**；写成 `Event` 会在进入函数体前抛 #1034 并打断整个回调。解绑在方法开头（行 145）；`ui.ct` 已有同一 face 则直接返回（行 149-152） |
| `initBadge()` | 166-193 | 构造 plugin 数量角标 TextField | 行 187-192 `if(this.ui)` 守卫 |
| `updateBadge()` | 193-222 | 设置/动画角标（`N+`） | 行 196 `_badge` 空防御 + 行 200-203 动画互斥 |
| `showPlugins()` | 302-331 | 展开子框：显示 + 冷浅青光 + TweenLite 弹到 `pendingTweenParams` | 行 304 `pluginFighters` 空防御 |
| `closePlugins()` | 334-361 | 收起子框：清光 + 回收到 `pendingBack` + 恢复 badge | 行 336 `pluginFighters` 空防御 |
| `touchLongPressBeginHandler()` | 363-380 | touchBegin 启动 1200ms 长按计时 | 行 369 `TOUCH_MODE` 早退；`_longPressTimer` 复用不重建 |
| `touchLongPressMoveHandler()` | 382-393 | 手指滑出 20px 阈值则取消计时 | 行 384 计时器状态防御 |
| `touchLongPressEndHandler()` | 395-410 | touchEnd 结算一次性 `_suppressTapOnce` 标志 | 行 403-409 手势结束即清 `_longPressed`（不跨手势残留） |
| `longPressTimerHandler()` | 412-426 | 计时到点 → 调 `onLongPress` 回调，无回调则自展开 | 行 417-424 `onLongPress` 空防御 + try/catch |
| `touchTapGuardHandler()` | 428-444 | 长按后屏蔽本次 touchTap（防误选中） | 行 435-443 标志 + 800ms 时间窗兜底 |
| `addEventListener()`（重写） | 449-461 | 外部回调转挂到 `ui` 上的 `selfHandler` | 行 451 判据用登记表 `_listeners[type] == null`（**不能用 `ui.hasEventListener`**） |
| `removeEventListener()`（重写） | 463-476 | 对称注销 | 行 469 `_listeners` 空防御 + 行 471-474 `this.ui == null` 守卫（2026-10-10 新增，防 #1009） |
| `removeAllEventListener()` | 478-494 | 快照 key 后逐个注销 | 行 480-483 先快照再 delete，避免遍历中漏项 |
| `selfHandler()` | 495-498 | 统一派发：`callback(param1.type, this)` | **派发契约的唯一事实来源**：首参 `String`、次参 `this`。任何注册进本类 `addEventListener` 的回调都必须按此签名（既有正确范例：`SelectFighterStage.selectFighterMouseHandler(param1:String, param2:SelectFighterItem)`） |
| `destory()` | 500-554 | 销毁清理 | 行 513-521 触屏监听 + **ENTER_FRAME 注销（行 518，必须在 `this.ui = null` 之前）**；行 522-532 badge 清理；行 533-543 摘除 ui |

### 2.2 SelectFighterStage.as（1380 行）

| 方法 | 行号 | 作用 | 防御点 |
|------|------|------|--------|
| `CELL_SIZE` 常量 | 45 | 单格物理尺寸 (60,60)，**只表示格子多大** | 每页行数由它和视口推导，代码中不再有固定行数 |
| `buildList(param1)` | 242-398 | 建网格：算步距/页数/子框，建全部 `SelectFighterItem` | 行 271-288 **页高与每页行数全部由 select.xml 的 layout 推导**（2026-10-10：行 273 `PAGE_HEIGHT = min(layout.height, 视口高)`、行 276 `rowsPerPage = floor((页高-top-bottom)/格子高)`，代码中无固定值）；行 295 gapY 只用页高；行 304 `PAGE_HEIGHT = viewportH` 与容器定位共用同一量 |
| `addFighterItem(param1, isPlugin, parentItem, pluginIndex)` | 392-439 | 建单格；子框复用主人坐标并入 `_itemObj["x,y.N"]` | 行 394-402 fighterID / FighterVO 空防御；行 427-434 `ui.bg` 三态兜底 |
| `selectFighterMouseHandler(type, target)` | 441-459 | 鼠标 mouseOver / click / rightClick 分发 | 行 443-446 `target.selectData` 空防御 |
| `selectFighterTouchHandler(type, target)` | 461-503 | 触屏 touchTap 分发（首点预览、同格再点确认） | 行 463-466 空防御；行 468-478 P1/P2 选择器兜底；行 480 `isHoverFighter` 判定 |
| `doHover(param1)` | 505-539 | hover → 移动选择框 | 行 508-512 / 526-530 hover 到子框组外时收起子框 |
| `doShow(param2, pW)` | 541-577 | 展开子框（右键 / 手柄 special / 长按） | 行 543-546 空防御；归属 P1/P2 由 `pW` 决定 |
| `touchLongPressHandler(param1)` | 579-589 | 触屏长按 → `doShow` | 行 581-584 **无子框角色静默返回（设计行为）** |
| `movePluginSelect(params1, plug, direction)` | 591-646 | 手柄在子框 8 方位网格间移动 | 行 593 展开态空防御；行 599-604 目标方位无子角色 → 收起并回主网格 |
| `doSelect(param1)` | 648-681 | 确认选中 + 收起子框 | 行 650-654 / 666-670 `isSelected` 早退出 |
| `getFighterItem(x, y)` | 683-691 | 网格坐标 → SelectFighterItem | 键 = `x + "," + y` 字符串；行 685-688 `_itemObj` 空防御 |
| `moveSlt(param1, x, y, param4)` | 727-845 | 十字/环绕移动 + 已选跳过 | 行 731-739 目标格空或已选时环绕查找 |
| `isHoverFighter(param1, param2)` | 847-862 | 判断 target 是否为"光标所在格" | 行 856-858 **子框格复用主人坐标 → 必须再校验 fighterVO 身份**，否则点子框会误选主角色 |
| `moveToSelectFighter(param1, param2)` | 864-894 | 移动选择框到 target | 行 867-871 叠加 `_ui.bg.y` 分页偏移（否则翻页后选择框错位） |
| `render()` | 969-1155 | 每帧输入处理 | 行 971-1022 分页吸附段（子框展开期间不吸附回主网格）；行 1024-1080 P1 段；行 1081-1127 P2 段；行 1128-1148 地图段 |

### 2.3 SelectStageConfigVO.as（137 行）

| 代码段 | 行号 | 作用 | 防御点 |
|--------|------|------|--------|
| `unitSize` 声明 | 28-37 | 单格占位尺寸（60,60） | 2026-10-10 语义澄清：只表示格子多大，**每页行数不在此配置** |
| `setByXML(param1)` | 44-57 | 读 `stage_setting/layout` 八个属性 + 两张表 | 行 45 `Number(@x)` 强转，缺属性得 0 |
| `newListByXML(param1)` | 59-135 | 逐 `<row>`/`<item>` 建 VO，解析 `offset` 与 `<plugin>` | 行 119-121 plugin 子节点守卫；行 113 `.text()` 只取文本节点（**不能用 `toString()`**，会序列化整段 XML 导致查不到角色） |

---

## 3. 边界 case 矩阵（C1-C4）

> ⚠️ 本表为批次 6.5 时期记录，**"代码行号"列已失效**（见文首说明）；场景名与"期望"列仍可作为回归意图参考。

| 编号 | 场景 | 期望 | 代码行号 | 已防御？ |
|------|------|------|----------|----------|
| **C1** | `pluginIDs == null` 角色按 LB | 无响应（光不亮、无容器显示） | `isPluginSubVisible` 行 151-153 + `showPluginSub` 行 96-99 双重 null 守卫 | ✅ |
| **C1b** | `pluginIDs.length == 0` 角色按 LB | 无响应 | 同 C1（行 96 长度检查） | ✅ |
| **C2** | P 已选过某角色，再 hover 同一角色 | select 不重入（isSelected 早退出），但 plugin 子框保持显示 | `doSelect` 行 398-401 / 411-413 `isSelected` 早退出 + doSelect 末尾 showPluginSub | ✅ |
| **C2b** | P 已选过某角色，按 LB 再次展开 | toggle 风格，已展开则关闭（**注意**：批次 6.4 现状 = 边沿 LB 强制 show，重复按 LB 会保持 show，需配合 RB 关闭） | `render` P1 段行 790-794 边沿触发调 showPluginSub | ⚠️ 当前行为是"LB 总是 show"，关闭需 RB |
| **C3** | P1 与 P2 同时 hover 同一角色 | 两 P 子框都可见（无冲突，因为各 P 走独立 getFighterItem 查询） | `_itemObj` 字典按网格坐标全局共享；`getFighterItem` 行 442-449 返回同一实例；`_hideAllPluginExcept` 仅在 doHover 时被调 | ✅ |
| **C3b** | P1 hover 角色 A → P2 hover 角色 A | 角色 A 子框保持显示（`_hideAllPluginExcept(param1)` 不影响 param1 自己） | `_hideAllPluginExcept` 行 425-440 显式跳过 param1 | ✅ |
| **C4** | 选人取消时 P 段销毁 | `_pluginContainer` 清理，无内存泄漏 | `destory` 行 178-186 遍历 _listeners + 行 183 `_pluginContainer = null` | ✅ |
| **C4b** | 选人确认后切到游戏 stage，SelectFighterStage 销毁 | 所有 SelectFighterItem 销毁，_itemObj 字典随之释放 | 由 stage 销毁链触发 | ✅ |

---

## 4. 输入场景矩阵（4 输入 × 多状态）

> ⚠️ 同上：**代码位置列已失效**，场景意图仍有效。现行子框触发为「触屏长按 1200ms」或「鼠标右键 / 手柄 special」。

| 输入 | 触发条件 | 视觉响应 | 代码位置 |
|------|----------|----------|----------|
| **鼠标 hover** | `doHover` 调用 | 角色 A 子框显示（墨绿光 + 容器）；其他角色子框全部隐藏 | `doHover` 行 392 |
| **鼠标 select（点击）** | `doSelect` 调用（isSelected 早退出后） | 角色 A 子框显示；其他角色全部隐藏 | `doSelect` 行 422 |
| **手柄 LB（special=17）** | `GameInputer.special(_loc1_, 1)` 边沿 param=1 | **当前 P** 选中项子框显示 | `render` P1 段行 790-794 / P2 段行 838-842 |
| **手柄 RB（superSkill=18）** | `GameInputer.superSkill(_loc1_, 1)` 边沿 param=1 | **当前 P** 选中项子框隐藏 | `render` P1 段行 798-806 / P2 段行 846-855 |

### 4.1 手柄输入与鼠标交互的交叉

| 场景 | 期望 | 实际 |
|------|------|------|
| 鼠标 hover 角色 A → P1 按 LB 切到角色 B | 角色 B 子框显示（**P1 已选 B**），A 子框保持显示（**hover 仍触发**）| 当前实现：A 和 B 子框**同时显示**（因为 doHover 与 P1 段独立触发，doHover 只 hideAllPluginExcept(A 之外的)） |
| P1 鼠标选 A → P1 按 RB | A 子框隐藏（P1 RB 触发） | ✅ |
| P1 hover A → P2 hover A | 两 P 共享同角色 A 实例，子框显示一次（addChild 幂等） | ✅ |

---

## 5. 视觉参数常量

> ⚠️ 前三行常量属于**已被替换**的批次 6.2 实现（`_pluginContainer` 方案），现行实现不再使用；
> 现行子框视觉参数见 `SelectFighterItem.applyGlow()`（冷浅青 `0xB8E6E6`，blur 8/8，strength 0.8，行 288-294）。

| 常量 | 值 | 行号 | 说明 |
|------|----|------|------|
| `_PLUGIN_GLOW_COLOR` | `0x1B5E20`（墨绿色） | SelectFighterItem 行 24 | 批次 6.2 用户拍板 — **仅历史** |
| `_PLUGIN_SUB_SIZE` | `18`（像素） | SelectFighterItem 行 25 | 子框 18×18 — **仅历史** |
| `_PLUGIN_SUB_GAP` | `2`（像素） | SelectFighterItem 行 26 | 子框间距 — **仅历史** |
| GlowFilter 参数 | `0.85, 5, 5, 2, 1, false, false` | `showPluginSub` 行 102 | 批次 6.2 设计 — **仅历史** |
| 现行子框高亮 | `0xB8E6E6`，`0.8, 8, 8, 3` | `applyGlow` 行 288-294 | 2026-09-01 与 badge 角标色系统一 |
| 现行 badge 数字色 | `0xB8E6E6` + 描边 `0x1A4040` | `initBadge` 行 167-178 | 2026-09-01 冷色调统一 |
| **`CELL_SIZE`（选人格单格尺寸）** | `(60, 60)` | `SelectFighterStage` 行 45 | **2026-10-10 新增**：每页行数 = `floor((视口高 - top - bottom - 60) / 60) + 1`，代码中不再有固定行数 |
| **`PAGE_HEIGHT`（翻页步长，非行距）** | `min(layout.height, 600)` | `SelectFighterStage` 行 273 / 304 | **2026-10-10 起由 select.xml 推导，不再硬编码**；实测 `select.swf` 帧脚本常量池无 `PAGE_HEIGHT` 字样、仅引用 `SELECT_STATE`，即帧脚本读的是**编译期字面量（≈600）** → 保持 ≤600 时与推导值一致，不会错位 |

---

## 6. 批次 6.5 select.xml 多角色扩展（视觉验证用例）

> ⚠️ 本表行号对应**批次 6.5 时期的简化版 select.xml**，与当前 `tools/Test/assets/config/select.xml` 不一致。

| 行号 | 角色 | plugin 数量 | plugin id |
|------|------|-------------|-----------|
| 14 | [终末之谷]宇智波.佐助(和道) | 3 | `...·天照` / `...·须佐能乎` / `...·完全体` |
| 15 | [重粒子模式]漩涡.鸣人（JawBreaker） | 2 | `...·重粒子爆发` / `...·九尾查克拉` |

**真机验证要点**：
1. hover 角色 14（佐助）→ 3 个子框显示，沿主 ui 右侧 0/20/40 px 排列
2. hover 角色 15（鸣人）→ 2 个子框显示，沿主 ui 右侧 0/20 px 排列
3. hover 角色 14 后立即 hover 角色 15 → 14 子框立即消失，15 子框显示
4. 按 LB 展开当前 P 选中项子框 + RB 关闭子框
5. 选中带 plugin 的角色进入对局后返回选人 → plugin 子框仍可正常 hover/select 展开

---

## 7. 已知问题与限制

| 编号 | 描述 | 影响 | 缓解 |
|------|------|------|------|
| **L1** | 批次 6.4 肩键 LB 是"总是 show"，无 toggle 关闭 | 关闭需 RB 配合 | 批次 6.6 可考虑改为 toggle（先 isPluginSubVisible 再决定 show/hide） |
| **L2** | 手柄输入与鼠标 hover 同时存在时，子框可能同时显示多角色 | 不算 bug，是设计选择 | 当前实现下不会错乱 |
| **L3** | plugin id 在 FighterVO 中不存在时，子框仍显示（只是空图标） | 视觉无图标但不影响逻辑 | 若需 icon 需扩展批次 6.6 引入 `pluginFaceUrl` 字段 |
| **L4** | select.xml 当前是简化版（16481B），原完整版（32532B）在 `.backup/select.xml.batch6.1.2026-08-26-1733` | 批次 6.1 注入的 plugin 解析代码**当前 select.xml 不触发** | 批次 6.5 已挂 2 角色 + 5 plugin，触发验证已就绪 |
| **L5** | §1/§3/§4/§5/§6 描述的是已被替换的 `_pluginContainer` 子框方案 | 按其中行号定位会指到无关代码 | 见文首 IMPORTANT 说明；以 §2 现行索引为准，择机整表重写 |
| **L6** | `select.swf` 内嵌帧脚本（唯一 `DoABC`，3481B）的翻页步长是**编译期字面量 ≈600**，并不真的读取 `SelectFighterStage.PAGE_HEIGHT`（常量池实测无该字样，仅 `SELECT_STATE`）。`tools/script/patch_pagination.as` 是它的反编译留档，且**工程内零引用、从未注入** | 把 select.xml 的 `layout.height` 设到 >600 时，程序侧 `PAGE_HEIGHT` 会被上限钳到 600 保持一致；若将来想真正支持「一页高于视口」，必须改帧脚本而不是改代码 | 现行做法：`PAGE_HEIGHT = min(layout.height, 视口高)`，保证 ≤600 时两端恒等，不会翻页错位。要启用大页需重做帧脚本并接受页内滚动 |

---

## 8. 真机测试 checklist

- [ ] C1: 选一个无 plugin 的角色（如"sasuke_ninjia"），按 LB 无响应
- [ ] C2: 选带 plugin 的角色，鼠标 hover → select → 再 hover，无重复音效/移动
- [ ] C3: P1 与 P2 同时 hover 同一带 plugin 角色，子框正常显示无错位
- [ ] C4: 进入对局后返回选人界面，hover 同一角色子框仍能正常展开
- [ ] 输入-鼠标：hover 角色 A → select 角色 A → 子框保持显示
- [ ] 输入-手柄：连接手柄 → P1 选中角色 14 → 按 LB → 3 个子框展开 → 按 RB → 3 个子框收起
- [ ] 视觉-多 plugin：hover 角色 14（3 个 plugin）→ 子框 3 个，间距 2px 整齐排列
- [ ] 视觉-墨绿色：墨绿光强度 0.85 + blurX/Y=5，无白边残留
- [ ] **2026-10-10 新增** #1063：进选人界面后日志无 `ArgumentError #1063 ... _refreshFace`
- [ ] **2026-10-10 新增** face 缺失角色（日志 `face MISS`）在面图就绪后只出现一次 `face REFRESHED (治本)`，且不会每帧重复
- [ ] **2026-10-10 新增** 行距：日志 `[SelectFighterStage] ... rowsPerPage: ... gapY: ...` 中 gapY 落在 60~90 区间（不再出现 232 级数值），首屏可见整行数不再只有 2 行
- [ ] **2026-10-10 第三版** #1034：日志无 `TypeError #1034 ... cannot convert "enterFrame"`；`selfHandler` 派发只走 `String` 首参契约
- [ ] **2026-10-10 第三版** face 占位能被真正替换：曾经出现 `face MISS` 的角色，等面图加载完成后角色格显示为头像而非 ID 文字（旧错误下这里会永久停在占位文字）

---

## 9. 维护记录

| 日期 | 维护内容 | 维护人 |
|------|----------|--------|
| 2026-08-26 | 批次 6.5 初始化（C1-C4 + 4 输入场景 + 5 项常量 + 多角色扩展记录） | Claude (批次 6.5 闭环) |
| 2026-10-10 | 刷新 §2 全表行号至修复后实况（`SelectFighterItem` 555 行 / `SelectFighterStage` 1380 行 / `SelectStageConfigVO` 137 行）；§5 补 `CELL_SIZE` 与 `PAGE_HEIGHT` 语义；§1 补现行 `pluginFighters`/`gridOffset` 字段；文首加 IMPORTANT 说明 §3/§4/§6 行号已失效；§7 登记 L5；§8 补 #1063 与行距三项验收 | DeepSeek (选人界面 #1063 + 行距修复) |
| 2026-10-10（第二版） | 按「页尺寸交给 select.xml、程序自己识别」重做分页口径：`PAGE_HEIGHT` 不再硬编码 600，改为 `min(layout.height, 视口高)`；`rowsPerPage = floor((页高−top−bottom)/格子高)`（600 配置下 7 行 / gapY 63.33，原为 6 行 / 76）；同步更正 §5 与 `buildList` 行号；新增 L6 记录「帧脚本步长是编译期字面量、`patch_pagination.as` 从未注入」这一实测结论 | DeepSeek |
| 2026-10-10（第三版） | 修 #1034：`_refreshFace` 首参类型由 `Event` 改回 **`String`**。根因是本类 `selfHandler` 按 `callback(param1.type, this)` 派发、首参恒为字符串；写 `Event` 会在进入函数体前抛 `TypeError #1034`，导致 face 替换逻辑永不执行（占位文字永久停留）且 ENTER_FRAME 监听永久残留。已全库审计：经 `SelectFighterItem`/`MenuBtn` 包装类注册的全部 4 个回调首参均为 `String`（正确），`SelectedFighterUI.ui` 是纯 `Sprite`（收真事件，其 `Event` 首参正确）；§2.1 补 `selfHandler` 为「派发契约唯一事实来源」，§8 补 #1034 与占位替换两项验收 | DeepSeek |

> 本次源码改动对应文件：`SelectFighterItem.as`（#1063 双参签名 → 修正首参类型为 `String` + 监听目标统一 + 幂等刷新 + 诊断日志清理）、
> `SelectFighterStage.as`（页高与每页行数改为由 select.xml 推导、诊断日志清理）、
> `MenuBtn.as`（`removeEventListener` 空引用守卫）、`SelectStageConfigVO.as`（`unitSize` 注释语义澄清）。
