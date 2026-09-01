# 批次 6.5 回归测试矩阵

> 本文档记录人物子框（plugin sub-frame）功能在批次 6.0–6.4 实施后，于批次 6.5 阶段沉淀的边界 case 防御矩阵。
> 目标：**真机测试时按 C1–C4 + 4 输入场景表逐项验证**，每项标注代码行号便于快速定位。
> 维护约定：未来批次若修改 `SelectFighterItem.as` / `SelectFighterStage.as` / `SelectStageConfigVO.as`，需同步刷新本表行号。

---

## 1. 核心数据结构

| 数据层级 | 字段 | 类型 | 来源 | 说明 |
|----------|------|------|------|------|
| `FighterVO` | `pluginIDs:Array` | Array | 批次 6.0 新增 | FighterVO 层占位，select.xml 不解析时为 null |
| `SelectCharListItemVO` | `pluginIDs:Array` | Array | 批次 6.0 新增 | 由 SelectStageConfigVO 解析 select.xml plugin 子节点填充 |
| `SelectCharListItemVO` | `_cloneKey` 末尾 | - | 批次 6.0 | clone() 透传 pluginIDs，null 安全 |
| `SelectFighterItem` | `pluginIDs:Array` | Array | 构造器透传 | 直接持有 SelectCharListItemVO.pluginIDs 引用 |
| `SelectFighterItem` | `_pluginContainer:Sprite` | Sprite | 批次 6.2 新增 | 容器装 N 个 18×18 子 Sprite |
| `SelectFighterItem` | `_PLUGIN_GLOW_COLOR` | uint = 0x1B5E20 | 批次 6.2 常量 | 墨绿色光 |
| `SelectFighterStage` | `_itemObj:Dictionary` | Dictionary | 行 22-51 初始化 | 键 = `x + "," + y` 网格坐标字符串 |

---

## 2. 核心方法索引

### 2.1 SelectFighterItem.as（206 行，批次 6.5 后）

| 方法 | 行号 | 作用 | 防御点 |
|------|------|------|--------|
| 构造器 | 40-59 | 透传 `pluginIDs` + 调 `_initPluginSubUI()` | 行 50-54 addChild 主 ui |
| `_initPluginSubUI()` | 62-91 | 构造 `_pluginContainer`（**不 addChild**，默认隐藏） | 行 64-67 pluginIDs 空防御 |
| `showPluginSub()` | 94-108 | 加墨绿光 + addChild 容器 | 行 96-99 容器/pluginIDs 防御 + 行 100-103 filter 幂等 + 行 104-107 addChild 幂等 |
| `hidePluginSub()` | 110-145 | 精细清空 + removeChild 容器 | **行 116-134 精细清空**（批次 6.5 修复，只清自己 plugin 的 GlowFilter）+ 行 137-140 removeChild 幂等 |
| `isPluginSubVisible()` | 148-156 | 公共查询方法 | 行 151-153 容器/pluginIDs 防御 |
| `destory()` | 158-186 | 销毁（沿用反编译拼写） | 行 169-186 清理 `_listeners` + `_pluginContainer` |

### 2.2 SelectFighterStage.as（1086 行，批次 6.4 后）

| 方法 | 行号 | 作用 | 防御点 |
|------|------|------|--------|
| `doHover(param1)` | 364-386 | 鼠标 hover 触发 | 行 392 末尾调 `param1.showPluginSub()` + `_hideAllPluginExcept(param1)` |
| `doSelect(param1)` | 388-410 | 选中触发（含 `isSelected` 早退出） | 行 416-422 末尾调 show/hide |
| `_hideAllPluginExcept(param1)` | 425-440 | 隐藏除 param1 外所有 plugin | 行 444-449 `_itemObj` 空防御 |
| `getFighterItem(x, y)` | 442-449 | 网格坐标 → SelectFighterItem | 键 = `x + "," + y` 字符串 |
| `render()` P1 段 | 761-808 | P1 选中项 + **肩键 LB/RB** | 行 789-806 肩键块（`special` 调 show + `superSkill` 调 hide） |
| `render()` P2 段 | 809-856 | P2 选中项 + **肩键 LB/RB** | 行 838-855 肩键块（独立 `_loc6_/_loc7_`） |

### 2.3 SelectStageConfigVO.as（124 行，批次 6.1 后）

| 代码段 | 行号 | 作用 | 防御点 |
|--------|------|------|--------|
| plugin 解析 | 102-115 | 解析 `<item>` 下 `<plugin id="..." />` 子节点 | 行 103 `_loc8_.plugin.length() > 0` 守卫；行 108 `String()` 强转防 null |

---

## 3. 边界 case 矩阵（C1-C4）

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

| 常量 | 值 | 行号 | 说明 |
|------|----|------|------|
| `_PLUGIN_GLOW_COLOR` | `0x1B5E20`（墨绿色） | SelectFighterItem 行 24 | 批次 6.2 用户拍板 |
| `_PLUGIN_SUB_SIZE` | `18`（像素） | SelectFighterItem 行 25 | 子框 18×18 |
| `_PLUGIN_SUB_GAP` | `2`（像素） | SelectFighterItem 行 26 | 子框间距 |
| GlowFilter 参数 | `0.85, 5, 5, 2, 1, false, false` | `showPluginSub` 行 102 | 批次 6.2 设计 |

---

## 6. 批次 6.5 select.xml 多角色扩展（视觉验证用例）

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

---

## 9. 维护记录

| 日期 | 维护内容 | 维护人 |
|------|----------|--------|
| 2026-08-26 | 批次 6.5 初始化（C1-C4 + 4 输入场景 + 5 项常量 + 多角色扩展记录） | Claude (批次 6.5 闭环) |
