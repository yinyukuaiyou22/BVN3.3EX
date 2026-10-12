# BVN 3.8 竞技版「独立规则设置界面」实现详解

> 参考源码：`BVNscripts/3.8竞技参考/竞技改代码/scripts/net/play5d/game/bvn/`（3.8 竞技版，只读参考）
> 该工程的完整索引见：`BVNscripts/3.8竞技参考/竞技改代码/CLAUDE.md`
> PC版工程（3.3）如何照此实现独立规则页：见 [plan.md](plan.md)

---

## 0. 一句话概括

3.8 把「竞技规则」从常规设置里**拆成独立页面**：场景类 `RuleStage` 继承通用设置基类 `SettingStageBase`，UI 背景取运行时加载的 `rule.swf`，按钮组 `SetBtnGroup(true)` 用构造参数切到「规则态」，14 个选项通过 `optoinKey` 字符串键与 `ConfigVO` 字段双向绑定，改值只写内存，点「应用」或返回确认时才落盘 JSON 存档。

---

## 1. 入口调用链

```
win/GameInterfaceManager.as  L183-191   getGameMenu(): SETTINGS → children: [GAME CFG, RULE CFG]
        ↓
ui/MenuBtnGroup.as           L521-524   case "RULE CFG" → MainGame.I.goRule()
        ↓
MainGame.as                  L229       goRule() → stageCtrl.goStage(new RuleStage())
        ↓
stage/RuleStage.as           L18-34     build()
```

对比常规设置页：`case "GAME CFG"` → `MainGame.goOption()` L221 → `new SettingStage()`。
**两者共用同一套 `SettingStageBase` + `SetBtnGroup`，只是数据源与背景 SWF 不同。**

---

## 2. 界面三层拆解

### 2.1 场景层 `stage/RuleStage.as`（全文 36 行）

```as3
override public function build() : void {
   super.build();                                                   // GameRender.add(render)
   _ui = AssetManager.I.createObject(ResUtils.RULE,"subswfs/rule.swf") as MovieClip;  // 背景 UI
   _btnGroup = new SetBtnGroup(true);                               // ← true = 规则态
   _btnGroup.startX = 50;  _btnGroup.startY = 30;  _btnGroup.endY = 550;  _btnGroup.gap = 70;
   _btnGroup.initMainSet();
   _btnGroup.initScroll(GameConfig.GAME_SIZE.x,600);                // 800×600 滚动视口
   _btnGroup.addEventListener("SELECT",onBtnSelect);
   _btnGroup.addEventListener("OPTION_CHANGE",onOptionChange);
   _ui.addChild(_btnGroup);
   _man = _ui.naruto as MovieClip;                                  // 背景角色动画
   SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
}
```

四个关键点：
1. `ResUtils.RULE = "stg_rule_ui"`，来自 **运行时加载**的 `subswfs/rule.swf`（`AssetManager.loadSubSwfPath` L113）
2. `new SetBtnGroup(true)` 是**唯一的分支开关**——3.8 相对 3.3 就多了这一个构造参数
3. 布局参数与设置页一致（纵向列表，gap=70，滚动区 800×600）
4. `_man` 是 rule.swf 内的角色 MC（3.8 用 `naruto`），键位子页弹出时播放 `key_fadin` / `key_fadout`

### 2.2 基类层 `stage/base/SettingStageBase.as`

| 成员 | 作用 |
|---|---|
| `onOptionChange(e)` L35-39 | **静态**：`config.setValueByKey(e.optionKey, e.optionValue)` —— 改选项只写内存 |
| `applyConfig()` L41-47 | `GameData.I.saveData()` + `config.applyConfig()` + `GameInputer.updateConfig()` + `MainGame.I.goMenu()` |
| `render()` L171-189 | 每帧监听 `back(1)` / `jump("MENU",1)`：有对话框则取消，否则弹 `GameUI.confrim("保存并返回")` → `applyConfig` |
| `onBtnSelect()` L59-72 | 按 `selectedLabel` 分发：P1/P2 KEY SET → 键位子页；APPLY → `applyConfig()` |
| `goInnerSetPage()` L81-100 / `goMainSetting()` L121-140 | 键位子页进出（TweenLite 把按钮组移出屏幕，`_man.gotoAndPlay("key_fadin")`） |
| `destory()` L151-169 | 摘监听、销毁按钮组、销毁子页 |

### 2.3 控件层 `ui/SetBtnGroup.as`（规则态分支 L190-323）

`initMainBtns()` 开头先取 `GameInterface.instance.getSettingMenu()`；若 `_isConfigState == true`，**丢弃它、改取硬编码规则数组**：

```
第 1 项：一键竞技/娱乐切换   func = GameData.I.config.switchAllRuleConfig   （无 options）
第 2-14 项：13 个规则项，每项 { txt, cn, options:[{label,cn,value}...], optoinKey }
末尾自动追加：APPLY 按钮（L345）
```

- **回显**：`_loc8_.optionKey = 项.optoinKey` → `setOptionByValue(config.getValueByKey(key))`（L338-342）
- **改值**：`SetBtn` 左右切 → `SetBtnEvent(OPTION_CHANGE)` → `SetBtnGroup.onChangeOption` 转发 → `SettingStageBase.onOptionChange` → `config.setValueByKey`
- **一键项**：无 options，走 `onSelect` → 调 `func()`（即 `switchAllRuleConfig`），**不触发 OPTION_CHANGE**
- **交互**：键盘 ↑↓ 选行 / ←→ 切选项 / attack 确认；鼠标点 `prevArrow`/`nextArrow`；`TOUCH_MODE` 时整体 1.1 倍缩放 + 单指滑动滚动（`touchMoveHandler` L59-100，`scrollRect` 平滑滚动）
- **选项池复用**：`_loc5_` 是 启用/禁用 两选项池，`_loc3_` 是 0-60 帧数池（规则页未使用）

---

## 3. 数据层

### 3.1 载体：`data/ConfigVO.as`（单例 `GameData.I.config`，实现 `ISaveData`）

反射式读写，UI 与字段靠字符串键解耦：

```as3
getValueByKey(k)  L165  → hasOwnProperty(k) ? this[k] : extendConfig[k]
setValueByKey(k,v) L184 → this[k] = v;  switch(k){ case "bgmVolume": …即时生效… }
```

### 3.2 一键切换与竞技校验

```as3
switchAllRuleConfig() L252  → setAllRuleConfig(!isSportsEnabled())   // 已竞技则切娱乐，反之切竞技
setAllRuleConfig(b)   L262  → isBankai = !b; isGodLevel = !b; isInfiniteAttack = b;
                              isStandardLimit = b; if(b){ isComboBurden = false; … }
isSportsEnabled(strict=false) L287 → isBankai==false && isInfiniteAttack && isStandardLimit
                                     && (strict ? originalQi==100 && !originalAssist && fighterHP==2 : true)
```

### 3.3 持久化（**不是 SharedObject，也不是 XML**）

```
改选项 → 仅内存
点 APPLY / 返回确认 → applyConfig() → GameData.saveData()                      (data/GameData.as:246)
                                    → GameInterface.instance.saveGame(obj)     (win/GameInterfaceManager.as:104)
                                    → JSON.stringify → FileUtils.writeAppStorageFloderFile
                                    → File.applicationStorageDirectory/bvnsave{版本号}.json   (L55-58)
读档：GameData.loadSaveData() L255 → loadGame() L110 → JSON.parse → config.readSaveObj()
兜底：存档损坏 → releaseSaveData() L64 释放内嵌默认存档 _assets/1_default_json$f8664e08….bin 后重读
```

⚠️ **默认值有两个来源**，必须同步：① `ConfigVO` 字段声明处（L30-98）② 内嵌默认存档 bin。

---

## 4. 规则页全部 14 项（3.8 实际清单）

| # | 显示键（lang key） | `optoinKey` | 类型 / 默认 | 主要消费点 |
|---|---|---|---|---|
| 1 | `stage_rule.switch` | —（func） | 一键切换 | `ConfigVO.switchAllRuleConfig` |
| 2 | `stage_rule.bankai` | `isBankai` | Boolean **false** | `FighterActionLogic.as:263/272/281`（waiKai/waiKaiW/waiKaiS） |
| 3 | `stage_rule.god_level` | `isGodLevel` | Boolean false | `SelectFighterStage.as:455/879/912/1065/1118`（VS 人禁选神级） |
| 4 | `stage_rule.exact_moving` | `isExactMoving` | Boolean false | `ConfigVO.applyConfig L218`（60/30 fps） |
| 5 | `stage_rule.infinite_atk_chk` | `isInfiniteAttack` | Boolean true | `FighterMcCtrler.as:2441`（重复受击检测） |
| 6 | `stage_rule.standard_limit` | `isStandardLimit` | Boolean true | `FighterMain.as:930`（限气）、`SelectFighterStage.as:1510`（禁另我）、`HitsUI.as:89`、`MapSelectUI.as:203`、`KyoRandom.as:29` |
| 7 | `stage_rule.combo_burden` | `isComboBurden` | Boolean false | `FighterMcCtrler.as:2336`（受击硬直 +=2/4） |
| 8 | `stage_rule.original_qi` | `originalQi` | Number 100（0/100/200/300） | `FighterMain.as:27` |
| 9 | `stage_rule.original_assist` | `originalAssist` | Boolean false | `FighterMain.as:69`（`fzqi = ?100:0`） |
| 10 | `stage_rule.special_skill` | `isSpecialSkill` | Boolean true | `FighterMcCtrler.as:2486`（耗气脱身） |
| 11 | `stage_rule.replace_special` | `isReplaceSpecial` | Boolean false | `FighterKeyCtrl.as:191-195` |
| 12 | `stage_rule.special_mis_prot` | `isSpecialMisProt` | Boolean true | `FighterKeyCtrl.as:178/187` |
| 13 | `stage_rule.camera_zoom_rate` | `cameraZoomRate` | Number 0.6（0.5~1.0，语义取倒数） | `GameStage.as:393`（`autoZoomMin = 1/rate`） |
| 14 | `stage_rule.upload_record` | `isUploadRecord` | Boolean true | 战绩上传链路 |

> **注意**：3.3 的两项 `isSteelBodyFreeze`（刚身停顿）与 `isSlowDown`（击杀慢镜头）在 3.8 被挪到**常规设置页**（`win/GameInterfaceManager.getSettingMenu()` L457-465），**不在规则页**。

---

## 5. 3.3 ↔ 3.8 规则项对照表

| 3.3 / PC版工程 字段 | 3.8 字段 | 默认值变化 | 备注 |
|---|---|---|---|
| `isSteelBodyFreeze` | `isSteelBodyFreeze` | true（PC 版默认 false） | 3.8 移到常规设置页 |
| `initialQi` | **`originalQi`** | 100（一致） | 改名 |
| `allowWankai` | **`isBankai`** | **true → false** | 改名 + **默认翻转** |
| `isAllowRepeatAttack` | **`isInfiniteAttack`** | PC 版 false / 3.8 true | 改名 + 语义反转（3.8 表示「启用重复连检测」= 禁止重复连） |
| `isChangeSpecialKey` | **`isReplaceSpecial`** | false（PC 版 true） | 改名 |
| `cameraMaxSize` | **`cameraZoomRate`** | 0.6（PC 版 1） | 改名 + 取值语义取倒数 |
| — | `isGodLevel` / `isStandardLimit` / `isComboBurden` / `originalAssist` / `isSpecialSkill` / `isSpecialMisProt` / `isExactMoving` / `isUploadRecord` | — | **3.8 新增 8 项（本次不实现）** |

⚠️ 语义陷阱：`allowWankai=true` 表示**允许变身**；3.8 的 `isBankai=true` 也表示允许卍解，但默认 false，且 3.8 的 `isInfiniteAttack=true` 在代码里是「**启用重复连检测**」即**禁止**重复连（与 PC 版 `isAllowRepeatAttack=true` 表示允许相反）。做移植时不要只按字面搬。

---

## 6. 移植到 PC版工程（3.3）的要点与坑

见 [plan.md](plan.md)。此处只列 3.8 侧暴露出的**结构性差异**（必须靠适配而非照抄解决）：

| 差异 | 3.8 | PC版工程（3.3） | 适配方式 |
|---|---|---|---|
| 场景基类 | 有 `stage/base/SettingStageBase` | **没有**，只有 `state/SettingState`（独立实现，且**无返回键处理**） | 复制 SettingState 骨架新建 `state/RuleState`，自行补 render 返回确认 |
| SetBtnGroup 分支 | 构造参数 `_isConfigState` | **无参**，数据源写死 `getSettingMenu()` | 新增 `initRuleSet()`（数据源改 `getRuleMenu()`），不要照抄 3.8 的硬编码数组 |
| UI 资源 | 运行时加载 `subswfs/rule.swf` | **编译期内嵌** `[Embed]`（改 SWF 后必须重跑 build） | 复用同一 setting.swf 内的新链接名 `rule_ui`，省掉新增 embed |
| 文案 | `GetLangText(key)` 外部 lang json | 写死中英字符串 | 直接写死 |
| 多语言/版本 | 有 | 无 | 忽略 |
| 一键切换 | `switchAllRuleConfig` + `isSportsEnabled` | 无 | 简易版：ConfigVO 加 `switchAllRuleConfig()`，切换后重建按钮组刷新 |
| 角色实例名 | `_ui.naruto` | 设置页 `_ui.ichigo`，**新规则页 `_ui.yuna`** | 写错 → `_man == null` → 子页 `gotoAndPlay` 报空 |
