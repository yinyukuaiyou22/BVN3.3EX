# 3.7 扩展版 vs 主项目 3.3：双向差异清单
> 一句话：3.7 独有 227 类、主项目独有 39 类，别拿 3.7 覆盖后者。
> 源码基准：`BVNscripts/3.7扩展版参考/scripts/net/play5d/`，442 个 `.as`，只读、已被 `.gitignore` 忽略。
> 对照基准：`BVNscripts/scripts/net/play5d/`，254 个 `.as`，工作区另有 66 个未提交改动，本册一个字节都没碰。
## 1. 一句话结论
两棵树已经分叉成两条产品线：3.7 的独有类是一个**闭合岛**（未解析的 `net.play5d.*` import 为 0，主项目对它们的引用也是 0），
所以「3.7 少了什么」不是风险；风险全在 **215 个同名文件**上——75 个行数差 ≥ 40，单文件最大差 1738 行，按路径覆盖等于把主项目的 TAG、GPU 滤镜代理、外置资源链路整条回退。
本册只做地图：227 个独有类逐类给评级，39 个主项目独有类进「别覆盖清单」，机制细节留给 02~06 册。
## 2. 领域术语
| 术语     | 本册含义                                            | 代码对应物                                   |
| -------- | --------------------------------------------------- | -------------------------------------------- |
| 独有类   | 只在一边存在的 `.as`（按相对路径判定，不看类名）    | 3.7 独有 227 / 主项目独有 39                 |
| 共享文件 | 两边同相对路径都存在、但内容不同                    | 215 个，其中 75 个行数差 ≥ 40                |
| 挂载点   | 3.7 用共享文件把新子系统接进引擎的位置              | `ctrl/game_ctrls/GameCtrl.as` → `MosouCtrl`  |
| 闭合岛   | 独有类之间的依赖只指向岛内                          | 227 类对 `net.play5d.*` 的 import 全部可解析 |
| 值得拆   | 有独立设计价值、依赖可满足，能单独搬                | 例：`map/JsonMapLoader.as`                   |
| 胶水     | 纯适配 / 包装 / 常量 / 值对象                       | 例：`mob/ads/utils/AdType.as`                |
| 别碰     | 与主项目能力同位冲突，或依赖主项目没有的东西        | 例：`net/LANManager.as`、`mob/ads/CSJAd.as`  |
| 同名陷阱 | 路径相同、类名相同，实现已是两个东西                | `state/GameCamera.as`（413 vs 807）          |
| 外置链路 | APK 外 `Android/media/<pkg>/BVN/assets/` 的读写通路 | 主项目 `mob/utils/ANEFileReader.as`          |
## 3. 结构与数据流
### 3.1 方法论（一句话）
取两边 `play5d` 下全部 `.as` 的相对路径做 `Compare-Object` 得三集合，再对每个独有类读 行数 / `class` 声明 / 类顶注释 / `import` 表；用「引用到的 3.7 独有类个数」当移植成本、「引用到的非 flash 外部库」当编译缺口，据此定三档。
### 3.2 双树事实（本册全部数字的出处）
| 维度                           | 3.7 扩展版 | 主项目 3.3 | 取证方式                                      |
| ------------------------------ | ---------- | ---------- | --------------------------------------------- |
| `play5d` 下 `.as`              | 442        | 254        | 递归文件计数                                  |
| 独有 `.as`                     | 227        | 39         | 相对路径 `Compare-Object`                     |
| 共享 `.as`（同名）             | 215        | 215        | 同上                                          |
| 同名且行数差 ≥ 40              | 75         | 75         | 逐文件行数相减取绝对值                        |
| `kyo` 包规模                   | 28         | 24         | 目录计数                                      |
| 未解析的 `net.play5d.*` import | 0          | —          | 全树 import 与类文件集合比对                  |
### 3.3 关系图：谁调用谁、东西从哪来
```text
比对：ref 442 ┐
              ├─ Compare-Object ─┬─ 3.7 独有 227 ─→ 行数/class/import ─→ 三档评级
     main 254 ┘                 ├─ 共享 215 ────→ 行数相减 ────→ 同名陷阱
                                └─ main 独有 39 ─→ 方法表 ──────→ 别覆盖清单

3.7 侧接线（共享文件当挂载点）：MosouCtrl→GameCtrl｜MosouUI→GameUI｜JsonMapMain→GameLoader 与 EffectCtrl｜WorldMapState→MainGame
```
### 3.4 挂载点对照（3.7 挂什么 / 主项目在同一文件上改了什么）
| 共享文件                      | 3.7 侧挂载                               | 主项目侧同文件的改动                                          | 冲突点                       |
| ----------------------------- | ---------------------------------------- | ------------------------------------------------------------- | ---------------------------- |
| `ctrl/game_ctrls/GameCtrl.as` | `_mosouCtrl` 字段 + `getMosouCtrl()`     | `_tagCtrl = TagModeCtrler.I`、`FilterProxyManager.I` 三处调用 | 两套「第二控制器」抢同一位置 |
| `ui/GameUI.as`                | `_ui = new MosouUI()` 分支               | HUD 走 `FightUI`                                              | `IGameUI` 实现二选一         |
| `ctrl/GameLoader.as`          | `JsonMapMain.create(mv,cfg,bitmaps)`     | 外置 SWF/XML 扫描、`ANEFileReader.resolveExternalPath()`      | 地图创建口径不同             |
| `ctrl/EffectCtrl.as`          | `if(_gameStage.getMap() is JsonMapMain)` | 滤镜/时停/黑幕探测（`GameCameraFocusWatch` 依赖）             | 地图类型判定写进特效层       |
| `MainGame.as`                 | `stageCtrl.goStage(new WorldMapState())` | `goStage(new RuleState())` 等入口                             | 舞台入口表不同               |
## 4. 关键机制逐条拆解
### 4.0 六条结构性结论（下面所有表格都由这六条推出）
**M1 · 3.7 独有集是闭合岛。** 结论：227 个独有类对 `net.play5d.*` 的 import 全部能在 3.7 树内解析（未解析数 0）。
引用：`map/JsonMapLoader.as`、`ctrl/mosou_ctrls/MosouCtrl.as` 的 import 表。为什么这么做：逐类可搬性只取决于它自己，不必先补一堆垫片。
**M2 · 但它不是孤岛——3.7 用 5 个共享文件把它接进引擎。** 结论：`GameCtrl`→`MosouCtrl`、`GameUI`→`MosouUI`、`GameLoader`/`EffectCtrl`→`JsonMapMain`、`MainGame`→`WorldMapState`。
引用：§3.4 表。为什么这么做：3.7 作者选了「改共享文件加分支」而不是「插件注册」，所以搬子系统必然要动共享文件。
**M3 · 两边在共享文件上的改动方向不重叠。** 结论：主项目树对 `Mosou`/`JsonMap`/`WorldMapState`/`OptKit`/`ISaveData`/`FighterScaleModel`/`ShadowSprite` 的引用数实测全为 0。
为什么这么做：合并是「同文件不同段」，理论上可手工并；但 `GameCtrl` 两侧已差 1239 行，实际应按重写处理。
**M4 · 同名 ≠ 同义。** 结论：215 个共享文件里 75 个行数差 ≥ 40，最大 `ui/MenuBtnGroup.as` 708 vs 2446。
引用：§4.3 同名陷阱表。为什么这么做：这类覆盖往往**能编译**，错在运行时（HUD 接线、触摸判据、AI 档位）。
**M5 · 3.7 的 LAN 是骨架，主项目的 LAN 是成品。** 结论：`net/LANManager.as` 只 import `flash.events.EventDispatcher` 与 `flash.utils.getTimer`，没有 `flash.net.Socket`；主项目 `mob/sockets` 有服务端/客户端/UDP/拆包全套。为什么这么做：拿 3.7 的 net 包换主项目联机是净损失。
**M6 · 外部库缺口集中在加密与广告。** 结论：独有类引用到的非 flash 库只有 `com.greensock`（两边都有）、`com.adobe.crypto` 与 `com.hurlant`（只有 3.7 树有）、`com.game.ttads.TTAdManager`（**两边都没有 `.as`**）。
引用：`utils/GameEncriptUtils.as`、`mob/ads/CSJAd.as`、`mob/ctrls/GamePolyCtrl.as`。为什么这么做：这三处是硬约束，不是风格问题。
### 4.1 3.7 独有的 227 个（按包分组，每类一行）
行数为文件实际行数（含空行）。路径相对 `game/bvn/`；`kyo/` 组按相对 `scripts/net/play5d/` 计。
#### ui（116 类）
| 路径                                  | 行数 | 一句话职责                                       | 评级   |
| ------------------------------------- | ---- | ------------------------------------------------ | ------ |
| ui/BleachTransition.as                | 938  | 标题转场：遮片/印章式动画                        | 值得拆 |
| ui/ChangelogPopup.as                  | 146  | 更新日志弹窗                                     | 胶水   |
| ui/ContinueBtn.as                     | 53   | 继续按钮                                         | 胶水   |
| ui/GamePadArt.as                      | 246  | 手柄外观绘制                                     | 胶水   |
| ui/MosouPauseDialog.as                | 136  | 无双暂停菜单                                     | 别碰   |
| ui/OptionsData.as                     | 233  | 设置数据源（Tab/选项表）                         | 胶水   |
| ui/OptionsScreen.as                   | 894  | 设置界面壳（Tab 分页/showPage）                  | 胶水   |
| ui/OptKit.as                          | 527  | 自绘控件工具箱（pickFont/makeField/fitAligned）  | 值得拆 |
| ui/OptList.as                         | 698  | 选项列表：焦点/锁定/滚动                         | 值得拆 |
| ui/OptRow.as                          | 436  | 单行控件：滑条/步进/百分比（setPctFromX）        | 值得拆 |
| ui/PauseMenuUI.as                     | 532  | 暂停菜单（主项目 PauseDialog 同位）              | 胶水   |
| ui/SetBackdrop.as                     | 321  | 设置页背景与标题框                               | 胶水   |
| ui/SetUIKit.as                        | 267  | 设置页绘制工具（与 OptKit 部分重叠）             | 胶水   |
| ui/SkewBtn.as                         | 253  | 斜切按钮 + 跑马灯                                | 值得拆 |
| ui/Text.as                            | 27   | BitmapText 子类（Arial + 投影）                  | 胶水   |
| ui/TitleScreenUI.as                   | 798  | 标题画面（主项目 MenuState 同位）                | 别碰   |
| ui/VictoryUI.as                       | 2139 | 胜利结算（主项目 WinnerState 同位）              | 别碰   |
| ui/bigmap/BigmapAtmosphere.as         | 302  | 大地图大气层与粒子                               | 别碰   |
| ui/bigmap/BigmapClould.as             | 102  | 云层组                                           | 别碰   |
| ui/bigmap/CloudView.as                | 31   | 单朵云渲染                                       | 别碰   |
| ui/bigmap/LeaderFace.as               | 127  | 队长头像                                         | 别碰   |
| ui/bigmap/MapNodeView.as              | 586  | 地图节点（开锁/进度/抖动）                       | 别碰   |
| ui/bigmap/SlashButton.as              | 208  | 斩击风格按钮                                     | 别碰   |
| ui/bigmap/WorldMapPointUI.as          | 227  | 地图点交互与事件                                 | 别碰   |
| ui/bigmap/WorldMapScreen.as           | 953  | 大地图主屏（setPositions/confirm）               | 别碰   |
| ui/dialog/BaseDialog.as               | 124  | 对话框基类生命周期（onShow/onResume/onDestory）  | 值得拆 |
| ui/dialog/DialogManager.as            | 144  | 对话框栈与淡入淡出                               | 值得拆 |
| ui/dialog/MosouSelectDialog.as        | 197  | 无双选人对话框                                   | 别碰   |
| ui/dialog/MosouStateDialog.as         | 259  | 无双状态对话框                                   | 别碰   |
| ui/dialog/StyleDialogBase.as          | 425  | 样式对话框（Sprite 版）                          | 胶水   |
| ui/dialog/StyleDialogView.as          | 444  | 样式对话框（MovieClip 版）                       | 胶水   |
| ui/dialog/mosou_state/BigFaceUI.as    | 132  | 无双大头像（updateLeader）                       | 别碰   |
| ui/dialog/select/DotItemUI.as         | 33   | 分页点单元                                       | 值得拆 |
| ui/dialog/select/DotsGroupUI.as       | 93   | 分页点组（updateByPage）                         | 值得拆 |
| ui/dialog/select/SelectFighterList.as | 232  | 无双选人列表                                     | 别碰   |
| ui/dialog/select/SelectFighterUI.as   | 101  | 无双选人条目                                     | 别碰   |
| ui/fight/AssistStrip.as               | 589  | 3.7 援助条（layersOf/setWins）                   | 别碰   |
| ui/fight/EnergyMiniBar.as             | 215  | 迷你能量条                                       | 别碰   |
| ui/fight/FightAnnounce.as             | 553  | 战斗播报大字/横幅                                | 值得拆 |
| ui/fight/FightNotice.as               | 842  | 战斗提示层（接 FightUI）                         | 别碰   |
| ui/fight/FightRaster.as               | 284  | 扫描线/故障后处理（glitch）                      | 值得拆 |
| ui/fight/FightSfx.as                  | 607  | 战斗音效池 + 自动闪避 duck/unduck                | 值得拆 |
| ui/fight/FightSfxData.as              | 150  | 音效名规范化与查表（canon/lookup）               | 值得拆 |
| ui/fight/FightText.as                 | 128  | 位图战斗文字                                     | 胶水   |
| ui/fight/FightTheme.as                | 190  | 自绘战斗 UI 的配色与形状主题                     | 值得拆 |
| ui/fight/FlameFx.as                   | 960  | 火焰粒子烘焙（bakeInto）                         | 值得拆 |
| ui/fight/GlitchPulse.as               | 127  | 故障脉冲（kick/humStep）                         | 值得拆 |
| ui/fight/HitBgTrigger.as              | 206  | 命中背景触发                                     | 胶水   |
| ui/fight/InkFx.as                     | 297  | 水墨线条与撕裂（bakeTear）                       | 值得拆 |
| ui/fight/KoBgFx.as                    | 1024 | KO 背景字效（buildWords）                        | 值得拆 |
| ui/fight/LowHpFx.as                   | 311  | 残血暗角/边缘（bakeVignette）                    | 值得拆 |
| ui/fight/MiniHpBar.as                 | 549  | 3.7 迷你血条（setData/drawKo）                   | 别碰   |
| ui/fight/PlayerMarker.as              | 55   | P1/P2 标识                                       | 胶水   |
| ui/fight/SpiritAura.as                | 944  | 灵气光环描边（依赖 display/ShadowSprite）        | 值得拆 |
| ui/fight/SpiritBar.as                 | 480  | 灵气条                                           | 别碰   |
| ui/fight/SpiritBarFx.as               | 55   | 灵气条特效                                       | 胶水   |
| ui/fight/SpiritBurst.as               | 448  | 灵气爆发演出                                     | 别碰   |
| ui/fight/SpiritDrive.as               | 755  | 灵气驱动（含 tagSwitch，与 TAG 冲突）            | 别碰   |
| ui/fight/TagBgFx.as                   | 1069 | 换人背景件                                       | 别碰   |
| ui/fight/VText.as                     | 234  | 竖排文字（Shape）                                | 胶水   |
| ui/loading/BladeBar.as                | 452  | 刀锋进度条（bladePath/buildTrack）               | 值得拆 |
| ui/loading/BleachBackground.as        | 533  | 死神风背景（网点/圆盘）                          | 值得拆 |
| ui/loading/ConfirmInput.as            | 50   | 开始键轮询（poll/reset）                         | 胶水   |
| ui/loading/FighterBrief.as            | 67   | 角色三行摘要格式化                               | 胶水   |
| ui/loading/FighterCard.as             | 280  | VS 卡面                                          | 胶水   |
| ui/loading/GlitchTitle.as             | 192  | 故障标题（applyGlitch/restore）                  | 值得拆 |
| ui/loading/LoadingScreenUI.as         | 1047 | 载入屏总装（setProgress/playIntro）              | 别碰   |
| ui/loading/LoadingTheme.as            | 143  | 字体探测与配色（scan/findFont）                  | 值得拆 |
| ui/loading/LoadingUIConfig.as         | 30   | 载入 UI 常量                                     | 胶水   |
| ui/loading/LoadingView.as             | 372  | 载入层装配                                       | 别碰   |
| ui/loading/MissionBrief.as            | 34   | 任务摘要格式化                                   | 胶水   |
| ui/loading/MissionCard.as             | 282  | 任务卡面                                         | 胶水   |
| ui/loading/RasterText.as              | 323  | 字形栅格化缓存（glyphOf/layout）                 | 值得拆 |
| ui/loading/VersusArtSide.as           | 436  | VS 立绘侧                                        | 胶水   |
| ui/loading/VersusFighter.as           | 35   | VS 名字                                          | 胶水   |
| ui/loading/VersusLoadingUI.as         | 1542 | VS 载入总装                                      | 别碰   |
| ui/loading/VersusText.as              | 169  | 对位大字排版（advanceOf）                        | 值得拆 |
| ui/loading/VerticalMarquee.as         | 148  | 竖向滚动条                                       | 值得拆 |
| ui/mosou/CoinUI.as                    | 51   | 金币显示                                         | 别碰   |
| ui/mosou/LittleHpBar.as               | 67   | 小血条                                           | 别碰   |
| ui/mosou/MosouBanner.as               | 447  | 无双横幅（hazard/renderAt）                      | 别碰   |
| ui/mosou/MosouBossBar.as              | 135  | 首领条                                           | 别碰   |
| ui/mosou/MosouEnemyBars.as            | 167  | 敌方血条组                                       | 别碰   |
| ui/mosou/MosouEnergyBar.as            | 254  | 能量条（overLoad/flash）                         | 别碰   |
| ui/mosou/MosouEnergyMeter.as          | 174  | 能量表盘                                         | 别碰   |
| ui/mosou/MosouFace.as                 | 152  | 头像缓存                                         | 别碰   |
| ui/mosou/MosouFightBarUI.as           | 89   | 战斗条 UI                                        | 别碰   |
| ui/mosou/MosouHitsCounter.as          | 95   | 连击计数                                         | 别碰   |
| ui/mosou/MosouHpBar.as                | 101  | 血条                                             | 别碰   |
| ui/mosou/MosouHpMeter.as              | 226  | 血条仪表                                         | 别碰   |
| ui/mosou/MosouInfoStrip.as            | 191  | 信息条（时间/波次）                              | 别碰   |
| ui/mosou/MosouPlayerPanel.as          | 189  | 玩家面板                                         | 别碰   |
| ui/mosou/MosouQiBar.as                | 127  | 气条                                             | 别碰   |
| ui/mosou/MosouQiMeter.as              | 174  | 气表盘                                           | 别碰   |
| ui/mosou/MosouStyle.as                | 191  | 无双配色与单位换算                               | 别碰   |
| ui/mosou/MosouTimeUI.as               | 33   | 时间显示                                         | 别碰   |
| ui/mosou/MosouUI.as                   | 414  | 无双 HUD 总装（implements IGameUI）              | 别碰   |
| ui/mosou/MosouWaveUI.as               | 50   | 波次显示                                         | 别碰   |
| ui/mosou/MousouKOsUI.as               | 28   | KO 数显示                                        | 别碰   |
| ui/mosou/enemy/BossHpUI.as            | 150  | 首领血条                                         | 别碰   |
| ui/mosou/enemy/EnemyHpFollowUI.as     | 81   | 跟随式敌方血条                                   | 别碰   |
| ui/mosou/enemy/EnemyHpUI.as           | 63   | 敌方血条                                         | 别碰   |
| ui/mosou/enemy/EnemyHpUIGroup.as      | 115  | 敌方血条组（sortUI）                             | 别碰   |
| ui/select/FighterCardView.as          | 603  | 选人卡面与切换特效                               | 胶水   |
| ui/select/FighterIdleLoader.as        | 690  | SWF 缓存 + 引用计数逐出（trimSwfCache/evictSwf） | 值得拆 |
| ui/select/FighterIdleView.as          | 604  | 待机动画视图（attachClip/onFitFrame）            | 胶水   |
| ui/select/FighterTile.as              | 318  | 选人格子                                         | 胶水   |
| ui/select/HDText.as                   | 163  | 高清文本渲染                                     | 值得拆 |
| ui/select/SelectBackButton.as         | 534  | 返回按钮（含触摸态）                             | 胶水   |
| ui/select/SelectBackdrop.as           | 723  | 选人背景绘制                                     | 胶水   |
| ui/select/SelectCursor.as             | 408  | 光标与确认爆点                                   | 胶水   |
| ui/select/SelectFx.as                 | 28   | 缓动常量                                         | 胶水   |
| ui/select/SelectIndexArrow.as         | 64   | 索引箭头                                         | 胶水   |
| ui/select/SelectStyle.as              | 202  | 选人配色与文本构造（sideColor/makeText）         | 值得拆 |
| ui/select/SelectText.as               | 321  | 位图文字 + 跑马灯                                | 值得拆 |
| ui/select/SelectTransition.as         | 154  | 转场条纹                                         | 胶水   |
小结：值得拆的是**自绘控件三件套 `ui/OptKit.as` / `ui/OptList.as` / `ui/OptRow.as`**，加 `ui/select/SelectText.as`、`ui/select/SelectStyle.as`、`ui/select/HDText.as`、`ui/select/FighterIdleLoader.as`、`ui/loading/RasterText.as`、`ui/loading/VersusText.as`、`ui/loading/GlitchTitle.as`、`ui/loading/BladeBar.as`、`ui/loading/BleachBackground.as`、`ui/loading/LoadingTheme.as`、`ui/loading/VerticalMarquee.as`、`ui/dialog/BaseDialog.as`、`ui/dialog/DialogManager.as`、`ui/dialog/select/DotItemUI.as`、`ui/dialog/select/DotsGroupUI.as`、`ui/BleachTransition.as`、`ui/SkewBtn.as`，以及战斗特效件 FlameFx / InkFx / KoBgFx / LowHpFx / GlitchPulse / FightRaster / FightSfx / FightSfxData / FightTheme / FightAnnounce / SpiritAura。整屏类（`TitleScreenUI` / `VictoryUI` / `MosouUI` / 大地图 / 选人屏）一律别碰。
#### mob（32 类）
| 路径                              | 行数 | 一句话职责                                       | 评级   |
| --------------------------------- | ---- | ------------------------------------------------ | ------ |
| mob/AssetLoader.as                | 350  | 3.7 版资源加载（字节缓存 12MB/3 条），无 `ANEFileReader` 外置分支 | 别碰   |
| mob/RootSprite.as                 | 219  | 屏幕缩放三档壳（拉伸/原生/16:9）                 | 胶水   |
| mob/ads/AdConfigCode.as           | 24   | 广告配置码常量                                   | 胶水   |
| mob/ads/AdManager.as              | 314  | 广告总入口，import com.game.ttads.TTAdManager    | 别碰   |
| mob/ads/BaseAd.as                 | 163  | 广告基类：rank/rate/enabled 策略                 | 胶水   |
| mob/ads/CSJAd.as                  | 190  | 穿山甲实现，直调 TTAdManager.Instance            | 别碰   |
| mob/ads/ctrl/AdConfDir.as         | 33   | 广告配置目录                                     | 胶水   |
| mob/ads/ctrl/AdCtrler.as          | 299  | 广告调度与初始化（initAD/updatePolity）          | 胶水   |
| mob/ads/ctrl/AdGroup.as           | 505  | 广告组权重轮播（testRate/initNext）              | 胶水   |
| mob/ads/utils/AdAction.as         | 28   | 广告动作常量                                     | 胶水   |
| mob/ads/utils/AdEvent.as          | 27   | 广告事件                                         | 胶水   |
| mob/ads/utils/AdEventListener.as  | 61   | 广告事件适配器                                   | 胶水   |
| mob/ads/utils/AdType.as           | 22   | 广告类型常量                                     | 胶水   |
| mob/ads/utils/IAd.as              | 59   | 广告接口                                         | 胶水   |
| mob/ctrls/ControllerHudManager.as | 140  | 手柄 HUD 提示与原生键转发                        | 胶水   |
| mob/ctrls/GamePolyCtrl.as         | 155  | 版本/广告配置拉取（MD5 校验）                    | 胶水   |
| mob/ctrls/UpdateCtrl.as           | 203  | 检查更新→下载→退出                               | 值得拆 |
| mob/data/AdConfVO.as              | 25   | 广告配置 VO                                      | 胶水   |
| mob/data/VersionInfoVO.as         | 22   | 版本信息 VO                                      | 胶水   |
| mob/input/GameInputFocus.as       | 91   | 输入焦点枚举与状态（MENU~RESULT）                | 值得拆 |
| mob/input/GameInputRouter.as      | 72   | 按焦点开关输入路由（applyFocus）                 | 值得拆 |
| mob/screenpad/ScreenPadDebug.as   | 115  | 软键盘调试绘制                                   | 胶水   |
| mob/screenpad/ScreenPadFx.as      | 445  | 按键特效（涟漪/环）                              | 胶水   |
| mob/screenpad/ScreenPadHaptics.as | 85   | 按键震动反馈（主项目无同类）                     | 值得拆 |
| mob/screenpad/ScreenPadSkin.as    | 480  | 软键盘皮肤绘制                                   | 胶水   |
| mob/screenpad/ScreenPadStyle.as   | 174  | 皮肤配色与字号策略                               | 胶水   |
| mob/utils/TimerOutUtils.as        | 151  | 可暂停的定时器集合（pauseAllTimer）              | 值得拆 |
| mob/views/GamePadSetUI.as         | 601  | 手柄改键页，需 OptKit/OptList/OptRow 同搬        | 值得拆 |
| mob/views/SetAudioView.as         | 79   | 音频设置页（SetViewBase 子类）                   | 胶水   |
| mob/views/SetGameplayView.as      | 111  | 玩法设置页                                       | 胶水   |
| mob/views/SetGraphicsView.as      | 161  | 画面设置页                                       | 胶水   |
| mob/views/SetViewBase.as          | 81   | 设置页基类（onBtnSelect/closeSelf）              | 胶水   |
小结：只有 `mob/ctrls/UpdateCtrl.as`、`mob/input/GameInputFocus.as`、`mob/input/GameInputRouter.as`、`mob/utils/TimerOutUtils.as`、`mob/screenpad/ScreenPadHaptics.as`、`mob/views/GamePadSetUI.as` 值得拆；`mob/ads` 12 类整包别碰（`TTAdManager` 两棵树都没有），`mob/AssetLoader.as` 与主项目 `ctrl/AssetLoader.as` 同名不同包，也别碰。
#### data（21 类）
| 路径                                           | 行数 | 一句话职责                                   | 评级   |
| ---------------------------------------------- | ---- | -------------------------------------------- | ------ |
| data/BgmVO.as                                  | 18   | BGM 值对象                                   | 胶水   |
| data/FighterScaleModel.as                      | 385  | 角色显示缩放模型与绑定（load/applyToSprite） | 值得拆 |
| data/ISaveData.as                              | 11   | 存档契约 toSaveObj()/readSaveObj()           | 值得拆 |
| data/mosou/LevelModel.as                       | 39   | 等级经验曲线（getLevelUpExp）                | 别碰   |
| data/mosou/MosouEnemyVO.as                     | 95   | 敌人配置 VO（createByJSON）                  | 别碰   |
| data/mosou/MosouFighterLogic.as                | 150  | 我方角色属性与行动权限                       | 别碰   |
| data/mosou/MosouFighterModel.as                | 168  | 角色池与队伍模型                             | 别碰   |
| data/mosou/MosouFighterSellVO.as               | 25   | 角色售价 VO                                  | 别碰   |
| data/mosou/MosouMissionVO.as                   | 159  | 任务/波次配置（initByJsonObject）            | 别碰   |
| data/mosou/MosouModel.as                       | 123  | 无双总模型：地图与区域装载                   | 别碰   |
| data/mosou/MosouWaveRepeatVO.as                | 36   | 波次重复规则                                 | 别碰   |
| data/mosou/MosouWaveVO.as                      | 137  | 波次 VO（敌人/首领统计）                     | 别碰   |
| data/mosou/MosouWorldMapAreaVO.as              | 58   | 大地图区域 VO                                | 别碰   |
| data/mosou/MosouWorldMapVO.as                  | 69   | 大地图路径 VO                                | 别碰   |
| data/mosou/MousouGameRunDataVO.as              | 19   | 单局运行时数据（KO 数/时间）                 | 别碰   |
| data/mosou/player/MosouFighterVO.as            | 152  | 角色养成与伤害成长                           | 别碰   |
| data/mosou/player/MosouMissionPlayerVO.as      | 32   | 任务进度存档                                 | 别碰   |
| data/mosou/player/MosouPlayerData.as           | 348  | 玩家总存档（initMap/addFighter）             | 别碰   |
| data/mosou/player/MosouWorldMapAreaPlayerVO.as | 97   | 区域进度存档                                 | 别碰   |
| data/mosou/player/MosouWorldMapPlayerVO.as     | 82   | 大地图开放进度存档                           | 别碰   |
| data/mosou/utils/MosouFighterFactory.as        | 21   | 角色工厂 create()                            | 别碰   |
小结：只有 `data/FighterScaleModel.as` 与 `data/ISaveData.as` 值得拆，剩下 19 个是 mosou 数据层，同属一个系统工程，单独搬没有意义。
#### utils（14 类）
| 路径                      | 行数 | 一句话职责                             | 评级   |
| ------------------------- | ---- | -------------------------------------- | ------ |
| utils/BtnUtils.as         | 131  | 按钮装配与触摸判定                     | 胶水   |
| utils/BwBackdrop.as       | 289  | 黑白背景字效（灰烬/环）                | 值得拆 |
| utils/CodeDraw.as         | 348  | 代码绘图套件（字形/刀锋/段落）         | 值得拆 |
| utils/EffectCacheVO.as    | 18   | 特效缓存 VO                            | 胶水   |
| utils/EffectPool.as       | 83   | 特效对象池（popFree/pushFree）         | 值得拆 |
| utils/GameEncriptUtils.as | 79   | AES/MD5（com.adobe.crypto 主项目无）   | 别碰   |
| utils/GameSafeKeeper.as   | 123  | 配置文件校验与加密存档                 | 值得拆 |
| utils/GithubUpdater.as    | 547  | GitHub 版本检查与下载                  | 值得拆 |
| utils/PoolMaintenance.as  | 93   | 池收缩维护（shrinkShinePool）          | 值得拆 |
| utils/TouchMoveEvent.as   | 38   | 拖拽事件                               | 胶水   |
| utils/TouchUtils.as       | 384  | 单/双指手势路由                        | 值得拆 |
| utils/UpdateManager.as    | 383  | 热更新文件流（loadUpdate/drainStream） | 值得拆 |
| utils/UpdateURL.as        | 40   | 更新地址混淆（xorDecode）              | 胶水   |
| utils/WrapInteger.as      | 37   | 整数回绕                               | 胶水   |
小结：本册性价比最高的一包——`CodeDraw.as`、`EffectPool.as`、`PoolMaintenance.as`、`TouchUtils.as`、`GithubUpdater.as`、`UpdateManager.as` 都是 0~1 依赖的独立件；`GameEncriptUtils.as` 是唯一硬缺口。
#### ctrl（13 类）
| 路径                                          | 行数 | 一句话职责                                    | 评级   |
| --------------------------------------------- | ---- | --------------------------------------------- | ------ |
| ctrl/AdaptiveEngine.as                        | 453  | 帧率采样 60 帧分级降级（LEVEL_NORMAL~HEAVY）  | 值得拆 |
| ctrl/MemoryCleaner.as                         | 52   | 清理入口：effects/filters/shadow/runtimePool  | 胶水   |
| ctrl/RenderTask.as                            | 31   | 未知（仅见类名，无可提取的 public 方法）      | 胶水   |
| ctrl/ShadowCtrl.as                            | 268  | 影子注册/更新/批量隐藏调度器                  | 值得拆 |
| ctrl/game_ctrls/BaseFighterEventCtrl.as       | 105  | 战斗事件基类：子弹与攻击者登记                | 值得拆 |
| ctrl/game_ctrls/TagCutIn.as                   | 1081 | 换人 cut-in 演出，依赖 ui/fight/KoBgFx        | 别碰   |
| ctrl/game_ctrls/TagFX.as                      | 959  | 换人特效组，依赖 ui/fight/TagBgFx             | 别碰   |
| ctrl/game_stage_loader/GameStageLoadCtrl.as   | 609  | 关卡级 MC/BGM 缓存与强制卸载                  | 值得拆 |
| ctrl/game_stage_loader/GameStageLoadDefine.as | 20   | 阶段加载常量定义                              | 胶水   |
| ctrl/mosou_ctrls/MosouCtrl.as                 | 747  | 无双主控：关卡/波次/敌我切换（13 个独有依赖） | 别碰   |
| ctrl/mosou_ctrls/MosouEnemyBarCtrl.as         | 81   | 无双敌方血条调度                              | 别碰   |
| ctrl/mosou_ctrls/MosouFighterEventCtrl.as     | 172  | 无双战斗事件：出生/受击/死亡                  | 别碰   |
| ctrl/mosou_ctrls/MosouLogic.as                | 313  | 无双进度：区域解锁/任务通过                   | 别碰   |
小结：`ctrl/ShadowCtrl.as`（配 `display/ShadowSprite.as`、`display/ShadowData.as` 三件套）、`ctrl/game_stage_loader/GameStageLoadCtrl.as`、`ctrl/AdaptiveEngine.as`、`ctrl/game_ctrls/BaseFighterEventCtrl.as` 值得拆；4 个 `mosou_ctrls` 与 2 个 `Tag*` 别碰。
#### kyo（6 类）
| 路径                        | 行数 | 一句话职责                               | 评级   |
| --------------------------- | ---- | ---------------------------------------- | ------ |
| kyo/loader/KyoLoaderLite.as | 292  | 轻量加载器（swf/bytes/display）          | 值得拆 |
| kyo/utils/ArrayMap.as       | 53   | 数组 + 字典双索引容器                    | 值得拆 |
| kyo/utils/KyoDrawUtils.as   | 100  | 环形/扇形绘制                            | 胶水   |
| kyo/utils/KyoTimeout.as     | 92   | 帧计时器（setFrameout/setTimeout）       | 值得拆 |
| kyo/utils/KyoTimerFormat.as | 101  | 时间格式化（secToTime）                  | 胶水   |
| kyo/utils/MemoryCleaner.as  | 136  | fighter/GC 清理（cleanFighters/forceGC） | 值得拆 |
小结：6 个都是主项目 kyo 没有的补充件，`KyoLoaderLite.as`、`ArrayMap.as`、`KyoTimeout.as`、`MemoryCleaner.as` 值得拆（前两个还被别处依赖）。
#### net（5 类）
| 路径                   | 行数 | 一句话职责                             | 评级 |
| ---------------------- | ---- | -------------------------------------- | ---- |
| net/LANConfig.as       | 22   | LAN 常量（MAGIC=BVN37 / PORT=22888）   | 别碰 |
| net/LANManager.as      | 115  | LAN 状态骨架：无 flash.net.Socket 实现 | 别碰 |
| net/LANPacket.as       | 21   | LAN 包结构 opcode/frame/data           | 别碰 |
| net/LANProtocol.as     | 34   | LAN 操作码 1~11                        | 别碰 |
| net/events/LANEvent.as | 32   | LAN 事件                               | 别碰 |
小结：整包别碰——`LANManager.as` 无 socket 实现，主项目已有 `mob/sockets` 8 类 + `mob/views/lan` 4 类 + `mob/ctrls` 8 个联机控制器。
#### map（5 类）
| 路径                     | 行数 | 一句话职责                               | 评级   |
| ------------------------ | ---- | ---------------------------------------- | ------ |
| map/JsonLayerRenderer.as | 439  | JSON 图层绘制：视差/切片/裁剪            | 值得拆 |
| map/JsonMapLoader.as     | 306  | JSON 地图加载与引用缓存（addRef/pump）   | 值得拆 |
| map/JsonMapMain.as       | 769  | 继承 MapMain，按 JSON 建层（initByJSON） | 值得拆 |
| map/JsonStageFx.as       | 251  | JSON 舞台特效：滤镜与正弦位移            | 值得拆 |
| map/MapLayer.as          | 389  | 单层视图：模糊/光效/命中判定             | 值得拆 |
小结：整包值得拆，且是本册**第一优先**：主项目 `map/` 只有 `MapMain.as` 与 `FloorVO.as`，JSON 地图整条链在主项目不存在（详见 03 册）。
#### video（4 类）
| 路径                        | 行数 | 一句话职责                       | 评级   |
| --------------------------- | ---- | -------------------------------- | ------ |
| video/LogoIntroView.as      | 449  | Logo 开场演出                    | 值得拆 |
| video/OpeningVideoPlayer.as | 552  | 开场视频播放（跳过与资源清理）   | 值得拆 |
| video/SlashFx.as            | 148  | 斩击/撕裂遮片（slash/torn/wipe） | 值得拆 |
| video/VectorText.as         | 203  | 矢量文字绘制                     | 值得拆 |
小结：4 个全值得拆，`OpeningVideoPlayer.as` 与 `SlashFx.as` 还被 3.7 的 mosou 界面复用。
#### fighter（4 类）
| 路径                                 | 行数 | 一句话职责                                | 评级   |
| ------------------------------------ | ---- | ----------------------------------------- | ------ |
| fighter/ctrler/EnemyBossAICtrl.as    | 67   | 首领 AI（继承 FighterAICtrl）             | 别碰   |
| fighter/ctrler/EnemyFighterAICtrl.as | 309  | 杂兵 AI（implements IFighterActionCtrl）  | 别碰   |
| fighter/ctrler/FighterActionLogic.as | 291  | 动作决策→动作派发（绑 MosouFighterLogic） | 值得拆 |
| fighter/ctrler/TagActionCtrl.as      | 261  | 换人模式动作控制                          | 别碰   |
小结：`FighterActionLogic.as` 值得拆（要先摘掉对 `MosouFighterLogic` 的依赖）；两个 `Enemy*AI` 是 mosou 专用，`TagActionCtrl.as` 与主项目 TAG 冲突，都别碰。
#### debug（2 类）
| 路径               | 行数 | 一句话职责                                    | 评级 |
| ------------------ | ---- | --------------------------------------------- | ---- |
| debug/Debugger.as  | 114  | 3.7 调试开关常量集（DEBUG_ENABLED/SAFE_MODE） | 别碰 |
| debug/ScreenLog.as | 102  | 屏上滚动日志，MAX_LINES=14                    | 胶水 |
小结：`debug/Debugger.as` 别碰——它与主项目根包 `Debugger.as` 同名不同包，IDE 自动 import 会挑错；`ScreenLog.as` 是可搬但不必搬（主项目 `Debugger` 自带面板）。
#### state（2 类）
| 路径                       | 行数 | 一句话职责                    | 评级 |
| -------------------------- | ---- | ----------------------------- | ---- |
| state/LoadingMosouState.as | 305  | 无双载入流程（10 个独有依赖） | 别碰 |
| state/WorldMapState.as     | 199  | 大地图舞台（7 个独有依赖）    | 别碰 |
小结：两个都是 mosou 系统入口，别碰。
#### display（2 类）
| 路径                    | 行数 | 一句话职责                                    | 评级   |
| ----------------------- | ---- | --------------------------------------------- | ------ |
| display/ShadowData.as   | 37   | 影子数据件（reset/dispose）                   | 胶水   |
| display/ShadowSprite.as | 346  | Bitmap 影子绘制与隔离（isolate/keepOnlyPath） | 值得拆 |
小结：`ShadowSprite.as` 值得拆（主项目无 `display` 包，无同位冲突），`ShadowData.as` 是它的数据件。
#### factory（1 类）
| 路径                      | 行数 | 一句话职责                                    | 评级 |
| ------------------------- | ---- | --------------------------------------------- | ---- |
| factory/GameRunFactory.as | 87   | 关卡对象工厂（把 mosou 与 JSON 地图接进构建） | 胶水 |
小结：`GameRunFactory.as` 是适配层，只服务 3.7 的 mosou + JSON 地图组合，单独搬无收益。

### 4.2 别覆盖清单：主项目独有的 39 个
这 39 个在 3.7 里**同路径不存在**；「覆盖」指有人拿 3.7 的同名类（不同包）或自制替代件放到该路径。
| 路径                                  | 行数 | 干什么                                                              | 被替代后会坏什么                                                                                    |
| ------------------------------------- | ---- | ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Debugger.as                           | 1189 | 分级日志（log/logFold/warn）+ 文件日志 + 可拖拽面板 + TAG 过滤      | 全树 84 个文件引用 `Debugger`，覆盖即整库编译失败；`DIAG_HURT` 等开关消失会让受击期逐帧写盘失控 |
| ctrl/AssetLoader.as                   | 291  | 外置优先解析（绝对路径→外置→APK 回退）+ `EXT-RESOLVE` 日志          | 外置链路整条断；3.7 的同名类 `mob/AssetLoader.as` 没有 `ANEFileReader` 外置分支                                      |
| ctrl/game_ctrls/GameCameraCtrler.as   | 302  | 镜头门面（setCamera/setFocusX/setAutoZoom 纯转发）                  | `GameState.cameraCtrler` 的类型来源，也是 `FighterCameraCtrler` 的父类                              |
| ctrl/game_ctrls/TagModeCtrler.as      | 550  | 换人模式：`requestSwitch()`/`trySwitch()`/共享池/HUD 刷新           | 模式 16/17 的唯一入口，`GameCtrl`、`GameState`、`FighterMcCtrler` 三处调用                          |
| fighter/ctrler/FighterCameraCtrler.as | 104  | 继承 `GameCameraCtrler`，给人物包用的镜头 API                       | 外置人物包调镜头会编译失败                                                                          |
| mob/ScreenRotater.as                  | 85   | 屏幕方向切换（isSupported/init/setOrientation/accUpdate）           | 横竖屏与加速度计适配失效                                                                            |
| mob/data/HostVO.as                    | 73   | 房间广播 VO（toJson/readJson/toByteArray）                          | LAN 房间发现与加入的数据契约                                                                        |
| mob/events/LanEvent.as                | 16   | 联机事件常量                                                        | 联机 UI 与 ctrl 的事件契约                                                                          |
| mob/sockets/PacketBuffer.as           | 63   | 粘包/拆包缓冲（push/getPackets）                                    | 联机数据流解析                                                                                      |
| mob/sockets/PacketUtils.as            | 48   | 包头与压缩（compress/uncompress）                                   | 同上                                                                                                |
| mob/sockets/SocketClient.as           | 145  | TCP 客户端（connect/send/sendJSON）                                 | 联机客户端整条                                                                                      |
| mob/sockets/SocketServer.as           | 231  | TCP 服务端（bind/sendAll/getClientByIP）                            | 联机房主整条                                                                                        |
| mob/sockets/events/SocketEvent.as     | 51   | 套接字事件 + `getDataObject()`                                      | 同上                                                                                                |
| mob/sockets/udp/UdpDataType.as        | 18   | UDP 数据类型常量                                                    | 局域网房间发现                                                                                      |
| mob/sockets/udp/UDPDataVO.as          | 49   | UDP 载荷 VO                                                         | 同上                                                                                                |
| mob/sockets/udp/UDPSocket.as          | 55   | UDP 监听/广播（sendBroadcast）                                      | 房间发现                                                                                            |
| mob/utils/AdManager.as                | 142  | 主项目广告入口（showInterAd/showOpenAd/showVideoAd）                | 所有广告调用点；与 3.7 `mob/ads/AdManager.as` 同名不同包                                            |
| mob/utils/ANEFileReader.as            | 466  | 外置根目录/读写/列目录 + `EXTERNAL_ENABLED` 与 `ANE_ENABLED` 双开关 | 外置子系统总开关；误覆盖会静默废掉整条链路（历史事故）                                              |
| mob/utils/JsonUtils.as                | 43   | `isJsonString()`/`str2json()`                                       | 配置解析兜底                                                                                        |
| mob/utils/LanSyncType.as              | 20   | 联机同步类型常量                                                    | 帧同步契约                                                                                          |
| mob/utils/LANUtils.as                 | 45   | 时间与参数格式化                                                    | 联机日志与校验                                                                                      |
| mob/utils/LockFrameLogic.as           | 83   | 锁帧门面（initServer/initClient/render）                            | 联机帧推进                                                                                          |
| mob/utils/MsgType.as                  | 34   | 消息类型常量                                                        | 联机消息路由                                                                                        |
| mob/utils/SelectFighterDataType.as    | 24   | 选人同步数据类型                                                    | 联机选人                                                                                            |
| mob/utils/SocketMsgFactory.as         | 87   | 各类联机消息构造（createJoinMsg 等）                                | 握手/加入/开局                                                                                      |
| mob/views/AdPauseView.as              | 26   | 广告返回后的暂停遮罩                                                | 广告链路返回态                                                                                      |
| state/GameCameraFocusWatch.as         | 299  | 必杀特写镜头的撤销看门狗（readLabel/isBishaLabel）                  | 演出结束镜头不回收；与 `GameCamera` 的 `FOCUS_OWNER_*` 配对                                         |
| state/RuleState.as                    | 192  | 规则设置页（`rule_ui` + `getRuleMenu()`）                           | 主菜单 RULE CFG 入口（`MainGame` 调用）；3.7 无对应物                                               |
| ui/ControlSetUI.as                    | 104  | 控制设置子页（`keyset_mc` + `SetBtnGroup.initControlSet()`）        | 手机端按键设置入口（`SettingState` 调用）                                                           |
| ui/fight/FightScoreUI.as              | 28   | 战斗分数（`MCNumber`）                                              | `FightUI` 的分数位                                                                                  |
| utils/AssetBatchLoader.as             | 195  | 并发加载调度器（load/pump，N 路）                                   | 批量加载路径（8 个文件引用）                                                                        |
| utils/BlendModeCompat.as              | 68   | GPU 不支持的混合模式映射白名单                                      | `lighten`/`hardlight`/`darken` 在 GPU 下静默失效的兜底                                              |
| views/filter/BitmapDataPool.as        | 183  | BitmapData 分档复用池                                               | 滤镜代理每帧 new/dispose 的性能灾难回归                                                             |
| views/filter/FilterNodeProxy.as       | 1310 | 单节点滤镜位图代理（兄弟 Bitmap + 变换拷贝）                        | GPU 模式下所有 Glow/Blur 消失或残留                                                                 |
| views/filter/FilterPad.as             | 117  | 滤镜外扩量估算（of/sumOf）                                          | 代理位图裁边/啃边                                                                                   |
| views/filter/FilterProxyManager.as    | 1250 | 代理注册/预算/两段式驱动/自愈                                       | 与 `GameState`、`GameCtrl`、`GameInterfaceManager` 三处接线，覆盖即整体失效                         |
| views/filter/FilterSignature.as       | 541  | 滤镜签名哈希（决定要不要重烘）                                      | 每帧重烘，或该烘不烘                                                                                |
| kyo/stage/effect/ZoomEffect.as        | 63   | 舞台缩放淡入淡出（`IStageFadEffect`）                               | 舞台切换效果；3.7 的 kyo 无此类（反向缺口）                                                         |
| kyo/utils/setFrameOut.as              | 34   | 包级函数：延迟 N 帧回调                                             | 3.7 的 kyo 无此函数（反向缺口）                                                                     |
### 4.3 同名陷阱（同路径、同文件名，实现已是两个东西）
判定口径：行数差 ≥ 40 且差异集中在「谁新增了什么能力」；同名同接口仍能编译，最容易被误当等价物。
| 路径                                | 行数 主/3.7 | 差异实质                                                                                                                                           | 覆盖后果                                                      |
| ----------------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| state/GameCamera.as                 | 413 / 807   | 主项目把相机拆成 4 件（`GameCamera` + `GameCameraCtrler` + `FighterCameraCtrler` + `GameCameraFocusWatch`），3.7 单类内建 `FighterScaleModel` 缩放 | 直接覆盖**编译失败**：`data/FighterScaleModel` 在主项目不存在 |
| ctrl/game_ctrls/GameCtrl.as         | 1154 / 2393 | 3.7 内建 `_mosouCtrl`，主项目内建 `_tagCtrl`                                                                                                       | 覆盖会引入 13 个不存在的依赖                                  |
| ui/SetBtnGroup.as                   | 1021 / 207  | 主项目多 `enableScrollDrag()`/`applyScrollY()`/`dragScrollEnabled`                                                                                 | 手机端设置列表滚不到 APPLY（唯一保存入口）                    |
| ui/select/SelectFighterItem.as      | 552 / 162   | 主项目 override `addEventListener` 与 `removeEventListener`，判据是 `_listeners`；3.7 只 override add                                              | 回退到 `ui.hasEventListener` → 外部回调被吞 + 监听泄漏        |
| fighter/ctrler/ai/FighterAILogic.as | 1178 / 802  | 主项目加 `_crazy*` 六字段与 `isCrazy` 分支                                                                                                         | CRAZY 档整体退回 HELL                                         |
| GameConfig.as                       | 354 / 171   | 主项目多 `GPU_FILTER_PROXY`、`FILTER_EFFECT_ENABLED`、`FPROXY_*`（3.7 版 grep 无这些字段）                                                         | `FilterProxyManager` 的读点全失，滤镜代理静默关闭             |
| ui/fight/FightUI.as                 | 615 / 1117  | 同名同接口：两边都 `implements IGameUI`、`initlize(GameRunFighterGroup, GameRunFighterGroup)`                                                      | 能编译，但 HUD 接线与视觉全错                                 |
| mob/GameInterfaceManager.as         | 824 / 499   | 主项目多 `FilterProxyManager.applyQualityPreset()`/`setEnabled()` 与设置页路由                                                                     | 画质档与滤镜开关失效                                          |
| data/GameData.as                    | 190 / 382   | 3.7 版含 mosou/任务数据装载，主项目版含 `EXTERNAL_ENABLED` 门控                                                                                    | 外置配置合并丢失                                              |
## 5. 陷阱与反编译噪音
**反编译噪音（会把结论带偏的假象）**
- 局部变量一律 `param1`/`_loc1_`，方法名与字段名保留 ⇒ 按字段名 grep 可靠，按变量名 grep 必空。
- 有人工后处理痕迹：`kyo/utils/setFrameOut.as` 里出现 `_mc ||= new Sprite();`（逻辑或赋值），不是原始反编译产物风格；不能假定全树同一手感。
- `00-README.md` 称「缺 `net.play5d.kyo.*` 约 30 个类 ⇒ 3.7 不可编译」，与本册实测不一致：3.7 树未解析的 `net.play5d.*` import 为 **0**，`kyo` 28 个还多于主项目 24 个。真正缺口在外部库（M6）。
**踩坑点**
- 三对同名不同包：`AssetLoader`（主 `ctrl/` vs 3.7 `mob/`）、`AdManager`（主 `mob/utils/` vs 3.7 `mob/ads/`）、`Debugger`（主根包 vs 3.7 `debug/`）——IDE 自动 import 会挑错，挑错后不报错只静默失效。
- `MemoryCleaner` 有两份：3.7 `ctrl/MemoryCleaner.as`（清引擎侧）与 `kyo/utils/MemoryCleaner.as`（清 fighter/GC），职责不同，不能互替。
- 「只搬 227 个独有类」搬不动：5 个共享文件是挂载点（M2），而那些文件正带着主项目的 TAG/滤镜/联机改动。
- `utils/GameSafeKeeper.as` 内有硬编码 `KEY`/`IV` 常量（字段名可 grep 到）⇒ 移植时不要照抄，也不要抄进文档或提交。
## 6. 移植可行性
| 组件                                                                                                   | 能搬/要改/搬不了 | 原因与改动点                                                                                                                                                                               |
| ------------------------------------------------------------------------------------------------------ | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| JSON 地图全链（`map/` 5 类）                                                                           | 能搬             | 5 类互相闭合（`JsonMapLoader`→`JsonLayerRenderer`→`MapLayer`，`JsonMapMain` 继承共享的 `MapMain`）；主项目 `map/` 只有 `MapMain.as` 与 `FloorVO.as`，需在 `GameLoader`/`EffectCtrl` 加分支 |
| 影子三件套（`ShadowCtrl` + `ShadowSprite` + `ShadowData`）                                             | 能搬             | 3 类闭合；主项目无 `display/` 包，无同位冲突；`SpiritAura` 依赖 `ShadowSprite` 的静态常量 `SPRITE_NAME`/`FALLBACK_KEEP_COUNT`                                                                                                   |
| 自绘特效件（`FlameFx`/`InkFx`/`KoBgFx`/`LowHpFx`/`GlitchPulse`/`FightRaster`/`BwBackdrop`/`CodeDraw`） | 能搬             | 0 个 3.7 独有依赖，纯 `Graphics`/`BitmapData` 逻辑；与主项目 `views/effects` 不冲突                                                                                                        |
| 自动更新（`GithubUpdater`/`UpdateManager`/`UpdateCtrl`/`UpdateURL`）                                   | 要改             | 0 依赖可编译；但 `UpdateURL` 的混淆表与文件布局是 3.7 自己的，须换成主项目发布源                                                                                                           |
| 自绘控件三件套（`OptKit`/`OptList`/`OptRow`）+ `GamePadSetUI`                                          | 要改             | 与 `SetBtnGroup`/`SettingState` 同位，只能替换不能并存；`GamePadSetUI` 依赖前三个                                                                                                          |
| 角色缩放（`FighterScaleModel`）                                                                        | 要改             | 与 3.7 的 `GameCamera` 单类耦合；主项目相机是 `GameCameraCtrler` 门面，需改绑定入口                                                                                                        |
| 战斗 HUD（`SpiritBar`/`SpiritDrive`/`MiniHpBar`/`AssistStrip`/`FightNotice`）                          | 搬不了           | 与 `FightUI`/`QiBar`/`FighterHpBar` 平行，两套 HUD 不能共存；`SpiritDrive.tagSwitch()` 还撞 TAG                                                                                            |
| 整屏类（`LoadingScreenUI`/`VersusLoadingUI`/`TitleScreenUI`/`VictoryUI`/选人屏/大地图 8 类）           | 搬不了           | 与 `LoadingState`/`MenuState`/`WinnerState`/`SelectFighterStage` 同位，替换成本高于收益                                                                                                    |
| 无双（mosou）全链 60 余类                                                                               | 搬不了           | 13 个依赖的 `MosouCtrl` 只是入口；还要改 `GameCtrl`/`GameUI`/`MainGame`/`GameRunFactory` 并自造存档格式                                                                                    |
| TAG cut-in（`TagCutIn`/`TagFX`/`TagBgFx`/`TagActionCtrl`）                                             | 搬不了           | 主项目 `TagModeCtrler` 的方法表里没有任何 cut-in 接入点                                                                                                                                    |
| 广告（`mob/ads` 12 类）                                                                                | 搬不了           | `com.game.ttads.TTAdManager` 两棵树都没有 `.as`，只能来自外部 SWC/ANE                                                                                                                    |
| 加密（`GameEncriptUtils`）                                                                             | 搬不了           | `com.adobe.crypto` 与 `com.hurlant` 只有 3.7 树有                                                                                                                                          |
| LAN（`net/` 5 类）                                                                                     | 搬不了           | 3.7 是骨架（M5）；主项目有 `mob/sockets` 8 类 + `mob/views/lan` 4 类 + `mob/ctrls` 8 个联机控制器                                                                                                      |
### 6.2 建议深拆顺序
1. **JSON 地图**（03 册）：5 类闭合、主项目零同位冲突，收益最直接。
2. **相机与缩放**（02 册）：先读 `data/FighterScaleModel.as`，再决定要不要动 `GameCamera`。
3. **自绘 UI 基元**（04 册）：`CodeDraw` → `OptKit` → `OptRow`/`OptList`，再谈替换设置页。
4. **手柄改键**（05 册）：`GamePadSetUI` 必须与 `OptKit`/`OptList`/`OptRow` 成组搬。
5. **自动更新**（06 册）：0 依赖，改 `UpdateURL` 与发布源即可，与引擎耦合最浅。
### 6.3 明确不建议碰
- 无双（mosou）全链 60 余类：要改 4 个共享文件 + 自造存档，等于开第二条产品线。
- 3.7 的战斗 HUD、载入/VS 屏、选人屏、大地图：主项目都有同位且更贴现有美术的实现。
- §4.2 的 39 个不是「不建议」，是**禁止覆盖**。
## 7. 未实测清单
以下每一条都**没有**跑过，不能当已知事实继续推演：
- [ ] 3.7 参考树能否整体编译（本册只做了 import 静态可解析性检查）。验证手段：本地 FDT/FlashDevelop 工程补 `com.game.ttads` 或排除 `mob/ads` 后编译。
- [ ] 227 个独有类的**运行行为**一律未跑（结论全部来自静态代码与方法名）。验证手段：构建可运行 SWF 后逐场景录屏对照。
- [ ] 20 张 `stage.json` 的字段契约是否被 `JsonMapLoader.load()` 全覆盖。验证手段：逐一解析并比对 `JsonLayerRenderer` 读取的键。
- [ ] `ShadowSprite.isolate()`/`keepOnlyPath()` 在真机 GPU 模式的单帧耗时。验证手段：真机 FPS 采样 + `getTimer()` 打点。
- [ ] `FighterIdleLoader` 的 SWF 逐出策略在手机内存水位下的表现。验证手段：反复进出选人 100 次，记录内存曲线。
- [ ] `GameSafeKeeper` 的加密算法与存档格式是否与主项目存档兼容。验证手段：用 3.7 生成存档再让主项目读。
- [ ] 75 个同名差异文件里哪些是「功能增量」哪些是「整体重构」（本册只按行数差筛选）。验证手段：逐文件 `git diff --no-index` 后归类。
- [ ] 39 个主项目独有类被覆盖后的具体报错形态。验证手段：临时分支做一次覆盖编译，不在主工作区做。