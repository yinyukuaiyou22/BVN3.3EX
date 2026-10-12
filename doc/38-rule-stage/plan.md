# PC版工程（3.3）新增「独立规则设置界面」实现计划

> 状态：**代码已实现并编译通过（2026-09-29）**；仅剩 FLA 发布这一步需人工完成，见文末「待办」。
> 参照实现：`BVNscripts/3.8竞技参考/`（详解见 [rule-stage.md](rule-stage.md)）
> 改造目标工程：`BVNscripts/PC版工程/`（`launch-fla/src/`，3.3 原版 PC 源码，win 包）

---

## 0. 需求边界（已与用户确认）

| 项 | 决定 |
|---|---|
| 规则页承载内容 | **只放 PC 版已有的 6 个竞技项**，不算新规则项 |
| 3.8 新增 8 项（神级/标准限制/连击负担/初始辅助气/特殊技/误触保护/精准移动） | **不实现** |
| 战绩上传（isUploadRecord） | **不实现** |
| 6 项与现有设置页的关系 | **从设置页移走**（不重复显示），实现 3.8 那样 GAME CFG / RULE CFG 分家 |
| 入口 | 主菜单 **OPTION 加子项**：GAME CFG / RULE CFG |
| UI | **借用现有设置界面框架**；AS 链接名 `rule_ui`，元件在 setting.fla 内，角色图舞台实例名 `yuna` |
| 一键竞技标准切换 | **要**（简易版，纯快捷设置现有 6 项） |

---

## 1. 现状基线（已实测）

| 事实 | 位置 |
|---|---|
| 设置页场景：`ResUtils.I.createDisplayObject(ResUtils.I.setting, ResUtils.SETTING)`；`new SetBtnGroup()`（**无参**）；`_man = _ui.ichigo`；BGM "back"；SELECT 分支 P1/P2 KEY SET / APPLY；**无返回键处理** | `state/SettingState.as:41-79` |
| `SETTING = "stg_set_ui"`；`setting:Class = setting_swf`（embed 编译期内嵌） | `utils/ResUtils.as:14,38` |
| 6 个竞技项混在设置菜单里：isSteelBodyFreeze / initialQi / cameraMaxSize / allowWankai / isAllowRepeatAttack / isChangeSpecialKey | `win/GameInterfaceManager.as:325-424` |
| `goOption()` → `new SettingState()` | `MainGame.as:164-168` |
| 菜单分发：`selectBtn()` **有 children 先展开子菜单**，否则按 label 取函数；`case "OPTION"` → goOption | `ui/MenuBtnGroup.as:240-249, 385-390` |
| 主菜单 OPTION 当前是叶子项（无 children） | `win/GameInterfaceManager.as:128-130` |
| FLA：元件「规则设置」已建好，`linkageClassName="rule_ui"`，内含 `name="yuna"` 的角色实例；现有设置页元件是「元件 16」`stg_set_ui` | `FlaUi/设置/setting.fla/LIBRARY/规则设置.xml` |
| PC 版 `SetBtnGroup.setBtnData()` **已修复 clearBtns**，可安全重复调用 | `ui/SetBtnGroup.as:83-112` |

---

## 2. 改动清单（按顺序执行）

### 0. 备份（硬性规范，项目无 Git）
所有待改文件先复制到 `BVNscripts/PC版工程/.backup/<YYYY-MM-DD-HHMM>/`。

### 1. FLA 发布
用 Animate 打开 `FlaUi/设置/setting.fla` → 发布 SWF → 覆盖 `PC版工程/launch-fla/swfs/setting.swf`。
⚠️ UI SWF 是**编译期内嵌**的，发布后**必须重跑 build.bat**，否则游戏里仍是旧副本。

### 2. `utils/ResUtils.as`
L14 旁新增：`public static var RULE:String = "rule_ui";`

### 3. 新建 `state/RuleState.as`（照 `SettingState.as` 骨架，用 State 后缀与 PC 版命名一致）
```as3
_ui = ResUtils.I.createDisplayObject(ResUtils.I.setting, ResUtils.RULE);  // 同一 setting.swf，不同链接名
_btnGroup = new SetBtnGroup();
_btnGroup.startY = 30;  _btnGroup.endY = 550;  _btnGroup.gap = 70;
_btnGroup.initRuleSet();                        // 新增：数据源改 getRuleMenu()
_btnGroup.initScroll(GameConfig.GAME_SIZE.x,600);
_btnGroup.addEventListener("SELECT",onBtnSelect);
_btnGroup.addEventListener("OPTION_CHANGE",onOptionChange);
_ui.addChild(_btnGroup);
_man = _ui.yuna;                                // ← 实例名 yuna（设置页 ichigo / 3.8 naruto）
SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
```
- `onBtnSelect`：`"RULE SWITCH"` → 一键竞技；`"APPLY"` → `saveData() + applyConfig() + GameInputer.updateConfig() + MainGame.I.goMenu()`
- `onOptionChange`：`config.setValueByKey(e.optionKey, e.optionValue)`
- **补返回键处理**（3.8 有、PC 版 SettingState 没有）：`GameRender.add(render)`；`GameInputer.back(1) || jump("MENU",1)` → `GameUI.confrim("保存并返回")` → applyConfig；`destory()` 里 `GameRender.remove`
- 健壮性：取 UI / 取角色失败要 try/catch 降级，**不能让空引用进 render**

### 4. `ui/SetBtnGroup.as`
新增 `initRuleSet()`：与 `initMainBtns()` 对称，数据源改为 `GameInterface.instance.getRuleMenu()`，末尾同样追加 APPLY 按钮。

### 5. `interfaces/IGameInterface.as`
L26 `getSettingMenu():Array;` 后加 `function getRuleMenu() : Array;`

### 6. `win/GameInterfaceManager.as`
- 新增 `getRuleMenu()`：1 项「RULE SWITCH」（无 options）+ 6 个竞技项；6 项数据从 L325-424 **搬迁**过来
- `getSettingMenu()`：删除 L325-424 这 6 段
- `getGameMenu()`：L128-130 的 OPTION 改为带 children
  ```js
  {"txt":"OPTION","cn":"游戏设置","children":[
     {"txt":"GAME CFG","cn":"常规设置"},
     {"txt":"RULE CFG","cn":"规则设置"}]}
  ```

### 7. `ui/MenuBtnGroup.as`
`getFucByLabel` 新增两个 case（放 `case "OPTION"` L385 附近）：
- `case "GAME CFG"` → `MainGame.I.goOption()`
- `case "RULE CFG"` → `MainGame.I.goRule()`
- 原 `case "OPTION"` 保留作兜底（加 children 后不再触发）

### 8. `MainGame.as`
L164 `goOption()` 后新增，并加 import：
```as3
public function goRule() : void { stageCtrl.goStage(new RuleState()); setFPS(30); }
```

### 9. 一键竞技标准值（简易版，执行前请最终确认）

| 项 | 竞技标准值 |
|---|---|
| `allowWankai`（允许变身） | false |
| `isAllowRepeatAttack`（允许重复连） | false |
| `initialQi`（初始气） | 100 |
| `cameraMaxSize`（镜头最大大小） | 1 |
| `isChangeSpecialKey`（灵替改键） | false |
| `isSteelBodyFreeze`（刚身停顿） | true |

实现：ConfigVO 新增 `switchAllRuleConfig()`（仿 3.8：判定当前是否已竞技标准 → 取反批量赋值）；RuleState 切换后重建按钮组刷新显示（PC 版 `setBtnData` 已可重复调用）。

---

## 3. 验证步骤

1. `build.bat` → `lint.bat`（**必须 0 错误**）
   - ⚠️ 本项目 `cmd.exe` 被封禁，`.bat` 不能直接跑：把 mxmlc 参数等价复现后用 java 直接执行，再跑 `tools/swf2zws.py`；路径用 `E:/...` 正斜杠
   - 当前基线：build 与 lint 均为 **错误 0 / 警告 55**
2. `debug.bat` 实测 → 读 `launch/log.log`
3. 实测清单：
   - 主菜单 OPTION 能展开两个子项，GAME CFG 仍进原设置页
   - RULE CFG 进新规则页，背景与角色 yuna 正常显示
   - 6 项能左右切换、APPLY 后退出重进保持（存档生效）
   - 设置页已无这 6 项，滚动边界正常
   - RULE SWITCH 一键切换后界面选项显示随之刷新
   - 返回键弹「保存并返回」确认框，保存生效

---

## 4. 已知坑

| 坑 | 说明 |
|---|---|
| `rule_ui` 取不到 | setting.swf 没重新发布或没重编译 → `getItemClass("rule_ui")` 拿不到类 → 必须 try/catch 降级，别让空引用进 render |
| 角色实例名 | 是 `yuna`，不是 `ichigo`/`naruto`；写错 → `_man == null` → 子页 `gotoAndPlay` 报空 |
| OPTION 加 children | `MenuBtnGroup._showIngChildrenBtn` 的滚动/箭头索引逻辑要实测，避免二级菜单索引错位 |
| 设置页删 6 项 | 按钮数与滚动高度变化，需实测滚动边界（超过 8 个按钮才滚动） |
| 语义反转 | 3.8 `isInfiniteAttack=true` = 启用重复连检测 = **禁止**重复连；PC 版 `isAllowRepeatAttack=true` = 允许。移植时不要按字面搬 |
| 编译期内嵌 | 改过 setting.swf 后必须重跑 build，否则看不到新元件 |

---

## 5. 执行记录（2026-09-29）——**已全部回退**

> ⚠️ 本节记录的是 **PC 版（误改）** 的执行过程。该套改动已于同日**回退**：7 个文件从 `PC版工程/.backup/2026-09-29-1528-rule/` 恢复（diff 全部一致），新建的 `PC版工程/launch-fla/src/.../state/RuleState.as` 已删除（回退前的版本存于 `.backup/2026-09-29-1947-rule-pc-revert/`），PC 版重新编译为 错误 0 / 警告 55（基线），`launch/launch.swf` 已重新产出。
> 真正落地的实现见第 6 节（主项目手机版）。下文保留作过程记录。

已按上文改动 7 个文件 + 新建 `state/RuleState.as`，备份在 `PC版工程/.backup/2026-09-29-1528-rule/`。

- build（`-strict=false`）：**错误 0 / 警告 55**；lint（strict）：**错误 0 / 警告 55** —— 与项目基线一致；已跑 `tools/swf2zws.py` 产出 `launch/launch.swf`
- 与 3.8 的两处适配差异（实现时踩到）：
  - PC 版 `SetBtn.select()` **只派发 SELECT 事件、不调用 `onSelect`**，所以一键切换不能用 3.8 的 `func` 字段，改由 `RuleState.onBtnSelect` 按 `selectedLabel == "RULE SWITCH"` 处理
  - PC 版取消确认框是 `GameUI.closeConfrim()`（3.8 是 `cancelConfrim`）；`GameUI.confrim(title,msg,ok,cancel)` 仍支持第 4 个取消回调

## 6. 补充：真正的改造目标是**主项目手机版**（`BVNscripts/scripts/`）

上一节里的 PC 版改动属**误改**（用户 2026-09-29 纠正：要改的是主项目的手机版工程，不是 PC 版）。手机版已按同一套方案重做一遍，两份改动互不依赖。

手机版对应位置（与 PC 版一一对应，包名换成 `mob`）：

| 关注点 | 手机版路径 |
|---|---|
| 设置场景 | `BVNscripts/scripts/net/play5d/game/bvn/state/SettingState.as`（额外有 `enableScrollDrag()` 触屏拖拽滚动、`Joystick Setting` 子页） |
| 新建规则场景 | `.../state/RuleState.as` |
| 资源常量 | `.../utils/ResUtils.as`（`SETTING="stg_set_ui"`，新增 `RULE="rule_ui"`） |
| 控件 | `.../ui/SetBtnGroup.as`（`initRuleSet()` / `refreshOptionValues()` / `buildBtnsByData()`） |
| 菜单数据 | `.../mob/GameInterfaceManager.as`（`getSettingMenu()` / 新增 `getRuleMenu()` / `getGameMenu()` 的 OPTION 子项） |
| 菜单分发 | `.../ui/MenuBtnGroup.as`（`case "GAME CFG"` / `case "RULE CFG"`） |
| 场景入口 | `.../MainGame.as` 的 `goRule()` |
| 一键切换 | `.../data/ConfigVO.as` 的 `isSportRuleEnabled()` / `switchAllRuleConfig()` |

手机版额外注意：
- UI SWF 由 `EmbeddedAssets.as` 用 `[Embed(source="_assets/swf/setting.swf")]` 编译期内嵌，所以**改 SWF 后必须重新编译**
- 规则页必须调 `enableScrollDrag()`（手机端没有虚拟方向键，否则滚不到末尾 APPLY）
- 实测 `_assets/swf/setting.swf` **已包含 `rule_ui` 与 `yuna`**，无需再发布 FLA
- `SettingState` 与 `_man` 相关逻辑**保持原样不动**（`_man = _ui.ichigo`、`gotoAndPlay` 不判空）：曾因当时 SWF 里取不到 `ichigo` 而加过 `ichigo ? ichigo : yuna` 兜底与判空，经用户确认属 UI 侧临时失误、已修正，这部分兜底已按要求移除
- 编译：`-strict=false` 下 **错误 0 / 警告 0**；strict 模式的 11 个报错全部是既有文件（JsonUtils/GameJoystickInput/ANEFileReader/KyoClassLoader/ScreenPadGame），与本次改动无关

## 7. 待办（需人工）

- **PC 版无需处理**：其改动已全部回退，`PC版工程/launch-fla/swfs/setting.swf` 本来就没被改过（不需要发布 FLA）
- **手机版也无需发布 FLA**：实测 `_assets/swf/setting.swf` 里已有 `rule_ui` 与 `yuna`
- 剩下的是**真机实测**：主菜单 OPTION → GAME CFG / RULE CFG；规则页 7 项（含迁入的无限气）+ 一键切换；APPLY 后重进确认存档生效；设置页已无这 6 项与无限气

---

## 8. 后续一轮：设置界面四项问题修复（2026-09-29 晚）

规则页落地后，实测暴露的四个问题已在同一轮修完（详情见当日工作记忆与 `doc/38-rule-stage/` 同目录说明）：

| 问题 | 根因 | 修法（文件） |
|---|---|---|
| 键盘只能操作一级菜单、子页只响音效 | `GameInputer` 的按下边沿是**进程级静态**表，多个 `SetBtnGroup` 同帧争抢 | `ui/SetBtnGroup.as` 加静态仲裁栈 `_regGroups` + `inputOwner`，`render()` 首行判所有权；注册 claim / `destory` release |
| 一级 APPLY 退出后键盘失效、卡在某菜单 | 覆盖层 `SetScreenBtnView` 挂 `_gameSprite`（**不在场景栈**）不随场景销毁，持续吃按键 | `launch.as` 覆盖层登记表 + `clearGameSpriteOverlays()`（订阅 `KyoStageEvent.CHANGE_STATE`）；`SetScreenBtnView.closeSelf()` 转 public |
| APPLY 后键盘"突然"失效 | `GameKeyInput._enabled` 默认 true vs `ENABLE_KEYBOARD` 默认 false，APPLY 时被同步关掉 | `mob/data/ExtendConfig.as` 默认改 **true**；`state/MenuState.as` 500ms 回调加 try/catch + 无条件恢复总闸 |
| 设置页/规则页右侧被裁 | `SetBtn.updateOption()` 顺排**无右边界**，触屏 `scale=1.1` 下可用宽只有 ≈727 | `SetBtn` 加 `rightX`/`setRightX()` 改**右对齐**；`SetBtnGroup` 下发 `getOptionRightX()` 并抽出 `TOUCH_SCALE` 常量 |

附带清理：`Joystick Setting` 菜单项去掉重复的 `select` 回调（原来会连开 JoyStickSetUI + ControlSetUI）；无限气从设置页迁到规则页 `INITIAL QI` 之后（不参与一键竞技切换）；`SetScreenBtnView.initScroll` 参数量纲从设备像素改为游戏单位。
编译：手机版 **错误 0 / 警告 0**（strict 仅剩既有 11 个报错，与本次无关）。踩坑记录：`SetBtn.select()` 只派发 SELECT、不调 `onSelect`；`ControlSetUI` 的 `keyEnable` 恒 true 是"覆盖层关闭后能收回输入"的隐式依赖，**不要**给它补 `keyEnable=false`。

> ⚠️ **PC 版这套改动是误改**（用户要的是手机版），**已于 2026-09-29 回退**：7 个文件从 `PC版工程/.backup/2026-09-29-1528-rule/` 恢复，新建的 `PC版工程/launch-fla/src/.../state/RuleState.as` 已删除。PC 版当前不含任何规则页代码（已 grep 确认无残留），重新编译 错误 0 / 警告 55。
