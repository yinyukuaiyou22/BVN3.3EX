# 3.7 自绘 UI 体系：代码绘制的界面层

一句话——3.7 界面不靠元件，靠代码现画；可复用的是四个套件而非 152 个类。
源码基准——BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/ui（152 个 .as）与 state（16 个场景类），只读参考，本轮未改动。
对照基准——BVNscripts/scripts/net/play5d/game/bvn/ui（38 个 .as，3.3 主项目，SWF 元件 + AS 链接形态）。

引用约定：路径相对 BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/ 书写，统一为 路径:类.方法()。行号不写死，确需定位写「参考 :N」并注明是反编译参考行号。本篇所有类名、方法名、字段名均来自实读代码；行为结论由代码推出，推不出的进第 7 节。

## 1. 一句话结论

3.7 的 ui 包用 152 个类把全部页面、HUD、弹窗外壳、过场重画了一遍，件件不依赖 SWF 元件库的**元件类型**，只依赖**按名取件**这一个窄口子（7 个文件、9 处 ResUtils.I.createDisplayObject）；真正可复用的不是这 152 个类，而是四个横切套件——FightTheme（镜像坐标）、SelectStyle/MosouStyle/OptKit（绘制与文字）、HDText/VectorText（两种文字栅格化）、GameInputer 的三档边沿判定——加上一条铁律：**所有动效期间必须把 GameInputer.enabled 置 false**。

三件必须先纠正的事实：

1. 「0 个 import net.play5d.game.bvn._assets」是真的，但 3.3 主项目同样是 0 个——这条判据区分不了两套 UI。两边的按钮外壳都来自 ResUtils.I.createDisplayObject(ResUtils.I.common_ui, "mc_wzbtn")。
2. 3.7 仍然把 11 个 SWF 编进二进制（_assets/22_bigmap_swf...swf 到 _assets/31_setting_swf...swf，见 ResUtils.as 的 common_ui/fight/select/setting/title/mosou/bigMap/dialog 等字段），再由 ResUtils 用 Loader.loadBytes 拆开按名取件。所谓「不依赖 SWF」准确表述是：**不依赖 SWF 的 AS 链接类型，仍依赖 SWF 里的少量面板外壳**。
3. 战斗 HUD 与无双 HUD 是唯一受统一接口约束的两块（IGameUI），其余 150 个类没有任何共同基类——152 个类里 76 个连 extends 都没有。

## 2. 领域术语

| 术语 | 本册含义 | 代码对应物 |
|---|---|---|
| 自绘 | 用 Graphics 在运行时描边填色、用 BitmapData 逐像素出图，不摆美术元件 | Graphics 的 beginFill/lineStyle/lineTo/drawXxx；new BitmapData(...) |
| 元件 | Flash 库里拖出来的 MovieClip，带帧和实例名 | ui/MenuBtn.as 的 ui 字段（类型 mc_wzbtn） |
| 按名取件 | 从已加载 SWF 里按字符串取子元件，编译期不检查 | `utils/ResUtils.as:ResUtils.createDisplayObject(Class, String)` |
| 页面 | 一整屏界面，实现 Istage 的 state，或自成体系的 Sprite | state/MenuState.as、ui/select/MapSelectUI.as |
| 层 | 页内为分离 z 序而建的 Sprite 容器 | TitleScreenUI 的 _content/_menuLayer/_flash；MenuBtnGroup 的 _bgLayer/_artLayer/_fxLayer/_entryLayer/_topContentLayer |
| 基元 | 一个可点、可选中、可自绘的最小控件 | ui/MenuBtnGroup.as 内的 MainMenuEntry；ui/SkewBtn.as；ui/SetBtn.as |
| 套件 | 一束 static 常量 + static 绘制函数的集合，充当主题与画具 | ui/fight/FightTheme.as、ui/select/SelectStyle.as、ui/mosou/MosouStyle.as、ui/OptKit.as、ui/SetUIKit.as、ui/loading/LoadingTheme.as |
| 单位 u | 以 800×600 为基准的整体缩放因子 | MosouStyle.unit()＝min(W/800, H/600)；MosouBanner 的 _u |
| 镜像坐标 | 左方坐标写一遍，右方按 VW − x − w 反算 | FightTheme.mx(side, x)、FightTheme.mrect(side, x, w) |
| 索引光标 | 选中态是数组下标，不是屏幕坐标指针 | MenuBtnGroup 的 _mainIdx/_childIdx；OptList 的 _index |
| 帧任务 | 注册到全局 ENTER_FRAME 注册表的函数 | ctrl/GameRender.as:GameRender.add(func, group, priority, interval) |
| 设计分辨率 | 组件内部假设的画布尺寸，与 GAME_SIZE 常不一致 | FightUI 的 1066×600；FightTheme.VH＝720；LoadingTheme 的 800×600 |
| 闸门 | 动效/弹窗期间屏蔽输入的开关 | GameInputer.enabled；MenuBtnGroup.enabled；GameUI.showingDialog() |

## 3. 结构与数据流

### 3.1 分层盘点（按包）

实测计数（递归统计 ui/ 下 .as）：

| 包 | 类数 | 职责 | 代表类 |
|---|---|---|---|
| ui（根） | 33 | 页面外壳、主菜单、选项页、暂停、转场、共用工具与画具 | MenuBtnGroup、SkewBtn、OptionsScreen、OptList、OptKit、SetUIKit、PauseMenuUI、TitleScreenUI、VictoryUI、MoveListSp、GameUI、UIUtils |
| ui/fight | 34 | 战斗 HUD：血条、气条、连击、KO、公告、位置指示、屏幕特效 | FightUI、FightBar、QiBar、HitsUI、FightAnnounce、FightNotice、PlayerMarker、KoBgFx、SpiritDrive |
| ui/mosou | 21 | 无双模式 HUD：玩家面板、Boss 条、敌兵条、能量表、Wave、横幅 | MosouUI、MosouPlayerPanel、MosouBossBar、MosouEnemyBars、MosouBanner、MosouStyle |
| ui/mosou/enemy | 4 | 敌兵血条族（含跟随式） | EnemyHpUI、EnemyHpUIGroup、EnemyHpFollowUI、BossHpUI |
| ui/select | 21 | 选人/选图：格位、光标、序号、背景、风格常量、工厂 | SelectFighterItem、SelectCursor、MapSelectUI、MapCard、SelectStyle、HDText、SelectUIFactory |
| ui/loading | 18 | 过场：VS 演出、加载条、标题故障字、竖排跑马灯 | VersusLoadingUI、LoadingView、LoadingScreenUI、LoadingTheme、VerticalMarquee、RasterText |
| ui/bigmap | 8 | 大地图：屏幕、节点、云、领袖头像、斜切按钮 | WorldMapScreen、MapNodeView、WorldMapPointUI、BigmapAtmosphere、CloudView |
| ui/dialog | 8 | 弹窗：确认/告警、管理器、样式对话基类与视图 | BaseDialog、ConfrimUI、AlertUI、DialogManager、StyleDialogBase、StyleDialogView |
| ui/dialog/select | 4 | 弹窗内选人 | SelectFighterUI、SelectFighterList、DotsGroupUI、DotItemUI |
| ui/dialog/mosou_state | 1 | 无双状态大头像 | BigFaceUI |
| 合计 | 152 | — | — |

按「机制证据」再切一刀（grep 记号统计，152 个文件全量）：

| 记号 | 文件数 | 含义 |
|---|---|---|
| 有矢量绘制记号（beginFill/lineStyle/lineTo/drawXxx/:Graphics） | 78 | 共 1822 处记号，是自绘的主体 |
| new Bitmap | 24 | 位图显示对象 |
| new BitmapData | 26 | 离屏画布（含文字栅格化、噪声、快照） |
| TweenLite | 22 | 补间 |
| 按名取 SWF 元件（ResUtils/createDisplayObject 或 mc_ 类型） | 7 | 唯一的元件口子 |
| gotoAndStop/gotoAndPlay | 10 | 帧脚本（都在读外部 SWF 里的 MC） |
| GameRender.add | 8 | 注册全局帧任务 |
| Event.ENTER_FRAME | 33 | 自己挂帧事件 |
| scrollRect | 17 | 用矩形裁切当视口 |
| "touchBegin/Tap/Move/End" | 10 | 触摸分支 |
| 以上记号全无 | 43 | 纯容器/纯逻辑/纯常量类 |

### 3.2 一棵 UI 树怎么长出来

顶层（全局唯一，不在 ui 包）：

    MainGame.initlize(root, stage)
      └─ root.scrollRect = new Rectangle(0,0,GAME_SIZE.x,GAME_SIZE.y)   ← 800×600 硬裁
      └─ stageCtrl = new KyoStageCtrl(_rootSprite)
           └─ goStage(state):
                 curStage.destory()            ← 先卸旧
                 newStage(): state.build()
                             _mainStage.addChild(state.display)   ← 唯一挂载点
                             state.afterBuild()

于是「一个页面」= 一个 Istage 实现，页面自己不一定是容器：MenuState 是 Sprite 却从不 addChild(_ui)，它把 display 直接返回 TitleScreenUI；SelectFighterStage 反过来，自己 new 一个 _ui:Sprite 当内容根。两种写法在 16 个 state 里并存。

页面内部的层：

    MenuState.build()
      _ui = new TitleScreenUI(800, 600, TOUCH_MODE)
        └─ ctor: _content(Sprite) → buildBackground/buildArt/buildVignette/
                 buildShards/buildSlashes/buildLogo/buildPress/buildFooter/buildFade
                 _menuLayer(Sprite)  ← 留给外部塞菜单
                 _flash(Shape)
    MenuState.afterBuild()
      _ui.play(); 等 500ms → 挂 click/touchTap → GameRender.add(render) → GameInputer.focus()
    MenuState.showBtns() → buildMenu()
      _btnGroup = new MenuBtnGroup()
      _ui.menuLayer.addChild(_btnGroup)      ← 外部往页面的预留层里塞
      _btnGroup.build(); _btnGroup.fadIn(0.2, 0.04)

战斗页是另一条链（不进 KyoStageCtrl 的 layer 体系）：

    GameState.build()
      gameUI = new GameUI()
      gameUI.initFight(p1Group, p2Group)
        └─ new FightUI()   ← ui.scaleX = 800/1066, ui.scaleY = 600/600
      addChild(gameUI.getUIDisplay())

弹窗是第三条链，**绕开 state 树**：

    GameUI.confrim(...) → new ConfrimUI() → DialogManager.showDialog(ui, false)
      └─ MainGame.I.root.addChild(dialog.getDisplay())   ← 直接挂到裁剪根，z 序天然最高
      └─ addDialogBg(): 1×1 BitmapData 铺满做 0.7 遮罩

三条链的差别决定了改法：页面链改 state + ui 类；战斗链改 GameUI + IGameUI 实现；弹窗链只改 BaseDialog 子类。

### 3.3 数据从哪来、到哪去

    GameModel/MapModel/FighterVO  ──► UI 的 build() 读一次，存成 _maps/_cards/_rows
    GameCtrl.gameRunData ─────────► FightUI.render() 每帧读 currentFighter 的 hp/hpMax/actionState
    GameInterface.instance.getGameMenu() ─► MenuBtnGroup._btnConfig（按钮表的唯一来源）
    AssetManager.getMapPic(vo) ───► MapSelectUI._picCache（每图裁成卡片尺寸后缓存）
    SoundCtrl ────────────────────► 所有交互点的 sndSelect()/sndConfrim()
    GameEvent ────────────────────► "SCORE_UPDATE"/"UI_CONFRIM"/"UI_ALERT"/"SELECT_MAP"

驱动方式两套并存：8 个类用 GameRender.add 挂全局帧任务，33 个类自己 addEventListener(Event.ENTER_FRAME)；战斗 HUD 第三种，由 GameState 每帧调 gameUI.render()（state/GameState.as:GameState.render() 里 gameUI.render()）。

## 4. 关键机制逐条拆解

### 4.1 基类契约：三个真契约，一个假基类

结论：没有 UIBase/BaseView。152 个类的 extends 分布为 无 extends 76、Sprite 62、EventDispatcher 5、BaseDialog 3，Shape/Bitmap/MovieClip/BitmapText/BleachTransition/ConfrimUI 各 1。真契约只有三个，覆盖面都窄。

（1）Istage 页面契约（不在 ui 包）：net/play5d/kyo/stage/Istage.as:Istage，成员为 display/build/afterBuild/destory。它是唯一规定生命周期四拍的东西：build 建树、addChild 上舞台、afterBuild 做依赖舞台的事、destory 反序拆。state/MenuState.as 用满了：build 只 new 与设初值，afterBuild 才 addEventListener 与 GameRender.add(render)。

（2）IGameUI 战斗 HUD 契约：ui/IGameUI.as:IGameUI，成员 setVolume/destory/fadIn/fadOut/getUI/render/renderAnimate/showHits/hideHits/showStart/showEnd/clearStartAndEnd/pause/resume。实现者只有 ui/fight/FightUI.as:FightUI 与 ui/mosou/MosouUI.as:MosouUI。它的分工值得抄：render 每帧跑数值，renderAnimate 按 30fps 节流跑美术（ui/GameUI.as:GameUI.isRenderAnimate() 用 _renderAnimateGap=ceil(FPS_GAME/30)-1 跳帧），showStart/showEnd 收 Function 回调做时序。这是全套 UI 唯一为性能做过的接口级设计。

（3）BaseDialog 模板方法基类：ui/dialog/BaseDialog.as:BaseDialog。final 包办 init（找实例名为 back 的 SimpleButton 并绑 closeSelf）/show/close/closeSelf/destory/hide/hiding/resume，子类只填 protected 钩子 onShow/onHide/onResume/onClose/onDestory；另有 width/height/offsetX/offsetY/_dialogUI 字段约定。子类 ConfrimUI、MosouSelectDialog、MosouStateDialog，孙类 AlertUI。契约靠实例名口口相传，无类型保证。

（4）GameUI 不是基类而是单例门面：ui/GameUI.as:GameUI 持 _ui:IGameUI，对外 initFight/initMission/render/fadIn/fadOut/destory，并提供静态 confrim/alert/showingDialog/showingConfrim/showingAlert。它是「一个 slot 装一个 HUD」的策略容器，判据写的是 if(_ui is FightUI == false) 就 destory 重建。

（5）惯例契约（无编译期强制，152 类基本都守）：构造即建树（MapSelectUI.ctor 直接调 build()）；出口要么 getUI()/getDisplay() 要么自身是 Sprite；拆法统一为 destory() 摘监听、killTweensOf、摘 parent、置 null；闸是 enabled:Boolean；拼写统一把 destroy 写成 destory（IGameUI 与 Istage 也如此），只有 TitleScreenUI/MenuBtn 用 dispose、OptKit 用 disposeField；初始化统一写作 initlize（FightUI/MosouUI/GameUI 三处同错）。

为什么：3.7 是逐屏手写而非搭框架，要的是每屏动效可以完全不同，代价是没有横向约束。移植时若照抄 152 个类而不先立这三个契约，会把 152 种写法一起搬进来。

### 4.2 装配、z 序与缩放

结论：z 序只由 addChild 顺序决定，无 z 管理器；缩放分三层（root、state 根、组件自身）靠约定叠乘。

（1）z 序靠顺序，且有硬编码下标：

    TitleScreenUI：_content、_menuLayer、_flash 依次 addChild，_flash 最后加所以永远盖在菜单上
    MenuBtnGroup：_bgLayer、_particleLayer、_artLayer、_fxLayer、_slashLayer、_slashMask、
                  _entryLayer、_topContentLayer、_strip、四个 wipe；且 _topContentLayer.mask=_slashMask
    FightUI：_bounds、_lowFx.view、_hud、_noticeHost、_spiritHost、_legacy，
             再 ui.setChildIndex(_spiritHost, ui.getChildIndex(_hud)) 把 spirit 插回 hud 原位
    SelectFighterStage：_ui.addChildAt(_p1Slt.group,1) 与 (_p2Slt.group,1) 两次插同一下标

最后一条最脆：两次 addChildAt(...,1) 把第二个插到第一个前面，1P/2P 叠放次序反转；没有常量也没有注释，多加一个 addChild 就盖住光标。

（2）缩放三层：

    第 1 层 mob/RootSprite.as:RootSprite.updateGameSize()：按 screenMode 求 sx/sy
      （NATIVE 取 min、FILL 取 max、16:9 等先算 target box 再除、默认拉伸），
      _gameSprite 居中偏移并设 scale，写回 GameConfig.GAME_SCALE（TouchUtils 反用它换坐标），
      偏移大于 0.5 时补 GameSideBg 黑边
    第 2 层 kyo/stage/KyoStageCtrl.as:KyoStageCtrl.addLayer()：用 _mainStage.scaleX 反算居中
    第 3 层 组件自缩放：FightUI 把 ui.scale 设成 800/1066 与 600/600，再令
      _hud.scaleX = FightTheme.S / ui.scaleX，先把父层缩放除掉再按设计单位铺

所以没有自适应布局，800x600 之外的适配全被第 1 层拉伸与第 3 层换算吸收；所有 UI 必须按 800x600 写死。

（3）AdaptiveEngine 是效果闸，不是 UI 闸：ctrl/AdaptiveEngine.as 用 60 帧滑窗测帧时，level 分 NORMAL/LIGHT/MEDIUM/HEAVY（滞后阈值 54/58/46/52/38/44），spawnLimit 35/20/10/4，effectScale 1/0.9/0.8/0.6。canSpawnEffect()/notifySpawn() 由 EffectCtrl 使用；shouldRenderOptionalEffect() 与 effectScale 全项目零调用点。「3.7 的 UI 有自适应降级」不成立。

### 4.3 布局：五套坐标系，零个布局引擎

结论：scale9Grid 出现 0 次，无锚点、无百分比约束、无布局器。五套并行约定，同一屏混两套的情况在 4.3 表里可见（如 OptionsScreen 同时用 A 与 E）。

| 套系 | 定位方式 | 代码对应物 | 使用者 |
|---|---|---|---|
| A 固定 800x600 加比例系数 | 一律 W 乘 k、H 乘 k 后取整 | MapSelectUI：_cardW=round(W*0.08)、_cardH=round(H*0.3)、_step=round(W*0.094) | MapSelectUI、SelectCursor、SelectBackdrop、OptionsScreen、TitleScreenUI |
| B 镜像坐标 | 左方写一遍，右方按 VW-x-w 反算 | FightTheme.setup 得 S=min(gameH/720, gameW/1000)、VW=gameW/S；FightTheme.mx/mrect | fight 全包（QiBar、MiniHpBar、FightNotice、FightAnnounce） |
| C 单位 u | 全部尺寸乘 u | MosouStyle.unit()=min(viewW/800, viewH/600)；MosouBanner 的 _u | mosou 全包 |
| D 自报宽度倒算右锚 | 子件暴露 totalWidth，父件用 W-pad-totalWidth | MosouUI 的 _info.x=_w-12*_u-_info.totalWidth | MosouUI、MosouBossBar、MosouEnemyBars、MosouInfoStrip |
| E 舞台居中 | (stageWidth-display.width*scaleX)/2 | KyoStageCtrl.addLayer() 的 isNaN(x) 分支 | 只 LANGameState 一处，且传 (30,100) 不走居中 |

以 MapSelectUI 为例（问 4 的答案）：build() 里 _cardW=round(W*0.08)=64、_cardH=round(H*0.3)=180、_step=round(W*0.094)=75、cardTop=H*0.575=345、cy=round(cardTop+_cardH/2)=435；条数 count=min(n, MAX_VISIBLE=9)，偶数则减一以保证有正中一张；第 i 张卡 x=round(W/2+(i-half)*_step)，half=count>>1；中心那张用 _row.setChildIndex(_cards[half], _row.numChildren-1) 抬到最上；箭头在 0.045W 与 0.955W；标题条 tagW=round(W*0.27)、tagH=round(H*0.043)、tagY=round(H*0.505)；名条 nameSize=round(H*0.034)、nameBoxW=round(W*0.6)，基线走 SelectStyle.textY(H*0.912, nameSize)。

滚动不重排只平移：showMap(index) 算 d=index-_curId 做环形归正（d>n/2 则 d-=n），夹到正负 3，_slide=d*_step，_row.x=_slide，再挂 ENTER_FRAME(onSlide)；onSlide 每帧 _slide*=0.7，绝对值小于 0.5 时归零并摘监听。

节点命中：addMouseEvents(prev,next,confirm) 由外部注入三个回调（控制反转），内部把 _arrowL/_arrowR 与每张 _cards[i] 塞进 _targets，统一挂 touchTap 或 mouseOver+mouseOut+click，doAction 里靠 e.currentTarget 与 _targets 成员比较分派；卡片的命中区就是自身显示边界，斜切外形外的透明角也算命中。

为什么：9 张牌只算一次坐标、之后只动 _row.x，省掉每帧 9 次重排；代价是滑动期间「逻辑槽位」与「屏幕位置」不同步，靠人眼容差过去。结论（问 4）：写死比例加常量，改分辨率必须改公式，改不了配置。

### 4.4 皮肤、配色与字体：六套并行套件，没有主题对象

结论：颜色与线宽是套件里的 static const（个别可变 static），没有 Theme 对象也没有切换机制；六套彼此不知道对方存在，且重复实现同一批工具函数。

| 套件 | 常量 | 工具函数 | 备注 |
|---|---|---|---|
| ui/fight/FightTheme.as | VH=720、VW、S、INK/WHITE/PINK/PINK_LOW/CREAM/CRIMSON/TRACK/RED/DEEP_RED/ORANGE/HOT/GOLD/GRAY | setup、mx、mrect、path、fillPoly、slab、fillSlab、gradSlab、clamp、lerp、easeOut/easeIn/easeBack、mix、fighterName | 唯一带镜像与平行四边形 slab 的套件 |
| ui/select/SelectStyle.as | COLOR_ACCENT=15921906、COLOR_P1/P2/PANEL/CROSS/CIRCLE/MORE | sideColor、isLight、onColor、displayName、makeText、textY、slantPath、slantSlice、cloneFace、fitCover、verticalName | 唯一带斜切与竖排文字位图的套件 |
| ui/mosou/MosouStyle.as | INK/ORANGE/ORANGE_HOT/PAPER/PAPER_SHADE/RED/GREY/STEEL | viewW、viewH、unit、para、fillPara、fillBand、inner、clamp01、sanitize、time、textW、drawText、drawTextOutlined | 唯一用 VectorText 画字的套件 |
| ui/OptKit.as | ACCENT/WHITE/DIM/GREY/INK/PANEL/TEAL | heavyFont/bodyFont、makeField、makeAlignedField、fitAligned、resizeField、setText、placeField、centerY、fitField、disposeField、lerpColor、clamp、easeOut、easeQuad、makeSlash、hash、makeBadge、makeArrowBadge、drawWord、makeVerticalTitle、verticalTitleWidth、makeArt、makePadButton | 设置页画具，含画手柄的 makePadButton |
| ui/SetUIKit.as | PANEL/GREY/WHITE/INK、ACCENT(getter) | heavyFont/bodyFont、makeField、resizeField、placeField、fitField、disposeField、lerpColor、easeQuad、clamp01、makePadButton | 与 OptKit 高度重复，PANEL 与 WHITE 值相同，INK 一个 462868 一个 657931 |
| ui/loading/LoadingTheme.as | W=800、H=600、MARGIN=36、BLACK/WHITE/RED/DARK_RED/GREY、SLASH_ANGLE=-32 度、SLASH_COS/SIN、GAME_TITLE、TEXT_SCALE | findFont、headFont/bodyFont/cjkFont、hasCjk、clamp01、easeOutCubic、easeOutExpo | 唯一有 findFont 与 hasCjk（探测字体表） |

第七套是散装：ui/MenuBtnGroup.as 自己一组 static——COLOR_MAIN（可变，每帧被 animate() 写成当前项的 COLORS 值）、CONTRAST_COLOR（由亮度反算）、FONT="Impact"、FAUX_BOLD、COLORS/DESCRIPTIONS/ARTWORKS 三张表，以及 20 余个动效参数（ART_ANIM_FRAMES=15、ART_SHAKE=12、STRIKE_INTERVAL=4000、STRIKE_FIRST=1500、STRIKE_TIME=460、STRIKE_SPARKS=36 等）。

线宽与圆角：线宽几乎都是比例式（Math.max(8,_H*0.022)、Math.max(14,_H*0.035)、Math.max(2,th*0.17)）；圆角只出现在 3 个文件 7 处（GamePadArt 10、MoveListSp s*0.4、OptKit h*0.28 与 size*0.22）；其余外形一律斜切平行四边形（SelectStyle.slantPath、MosouStyle.para、FightTheme.slab），这是整套 UI 的视觉母题。

字体三条路线并存：其一直接用 TextField（UIUtils.formatText 统一走 TextFormat，DEFAULT_FONT="黑体"，LOCK_FONT 可强制覆盖，formatTextFunction 是全局钩子）；其二 ui/select/HDText.as 把字号乘 QUALITY(=3) 画进 BitmapData 再缩到 1/3（超采样抗锯齿，浅色字自动加 GlowFilter 描边）；其三 video/VectorText.as 手写笔画字体，DATA 表覆盖 A-Z、0-9 与 20 个符号，GLYPH_H=6，每字形形如 "4|0,6 0,2 1,0 3,0 4,2 4,6;0,3 4,3"（宽|折线，分号分段）。

第三条是自绘最硬的证据，也是最大风险：VectorText 与 MosouStyle.sanitize() 的 ALLOWED 白名单只含 A-Z、0-9 与 空格 > < - / . : ! % + ? # =，白名单外字符直接丢弃（走 !gl 分支只推进 cx 不画笔画），MosouBanner 的中文标题会整段消失且不报错。

### 4.5 输入：三档边沿，两条事件轨，索引光标

结论：菜单是纯索引导航，没有自由光标；触摸与鼠标两条轨靠时间戳互斥；按键查询走同一个静态门面，有三档语义。

（1）门面与三档：input/GameInputer.as:GameInputer 的 _inputMap:Dictionary 以 "MENU"/"P1"/"P2" 映射到 Vector.<IGameInput>；initInput() 优先 GameInterface.instance.getGameInput(...)，回退 new GameKeyInput() 与 new GameJoystickInput(1|2)；call(param1,param2,...rest) 遍历该组、以 param2 作为方法名字符串取值并 apply 调用（duck typing）；enabled:static 是 call 的第一道判断。三档由 isDown 的第三参决定：0 是按住的电平，1 是边沿（isJustDown 用 _justDownKeys 记账），2 是边沿加重复延迟（isJustDownDelay 首次为真后写 _justDownDelayKeys=0.1*FPS 帧，期间恒真）。菜单用第 1 档：MenuBtnGroup.render() 里 up/down/select 都是 ("MENU",1)，back(1)；所以长按不连滚，这与 moveSel 带音效加整屏重绘相配。

（2）两条事件轨：TOUCH_MODE 为真挂 touchBegin/touchTap，为假挂 mouseOver/mouseDown/mouseUp/mouseOut/click。互斥判据在 MenuBtnGroup 内嵌 MainMenuEntry 的三处鼠标回调：if(getTimer()-_lastTouch < 600) return;（_lastTouch 由 onTouchBegin/onTouchTap 写）。MapSelectUI 不混挂两轨所以没有这条判据。600ms 互斥是逐类复制的，无统一封装。

（3）三种交互语义（ui/MenuBtnGroup.as:MenuBtnGroup.activateHandler()）：onHover(this) 在悬停或触摸按下时触发（onTouchBegin 里也调 onHover）；onActivate(this,isTouch,wasSel) 在抬起或 tap 时触发，其中 isTouch 且 wasSel 为假则直接 return（触摸首点只选中不激活）；e.children 存在则 toggleChildren(e) 展开二级列不执行；否则 choose(e) 走 14 帧确认动画（_confirmFrame>=14）后执行 func。这条「首点选中、再点确认」与主项目选人格子语义一致（见 CLAUDE.md 触控章节），是 3.3 到 3.7 一脉相承的准则。

（4）光标是索引不是指针：MenuBtnGroup 用 _mainIdx/_childIdx 加 moveSel(dir) 的 (_mainIdx+dir+n)%n 环绕，syncSelected() 批量刷 selected；OptList 用 _index 加 ( _index+dir+len)%len，滚动由 _index*pitch 反算；只有 SelectCursor 有屏幕坐标——moveTo(px,py) 带 0.09s 补间，位移大于 1px 时先 spawnGhost(旧位置) 留残影再 snap()，由 state/SelectFighterStage.as 调 _p1Slt.moveTo(param1.ui.x, param1.ui.y)。所以问 6 的答案是没有手柄自由光标：移动的是选中下标，画面位移是选中态迁移加补间跟随格子，移动端因此不需要指针碰撞。

（5）长按与拖拽：ui 包内没有长按实现（无长按计时器一类的代码）；拖拽只在 state/SelectFighterStage.as 的 _ui.stage 上挂 MOUSE_MOVE/MOUSE_UP 做人物预览；滚轮在 ui/OptList.as（TOUCH_MODE 为假时挂 stage 的 MOUSE_WHEEL），onWheel 里 select(_index+(e.delta>0?-1:1))——滚轮也是导航下标，不是自由滚动。

### 4.6 生命周期与内存：三种拆法，零对象池

结论：拆卸按类手写，三种命名并存；ui 包没有任何对象池，临时可视件按需 new、靠 Tween 完成回调移除。

（1）三种拆法：destory() 是主流（IGameUI 与 Istage 也这么定义）；dispose() 见 ui/TitleScreenUI.as:TitleScreenUI.dispose()、ui/MenuBtn.as:MenuBtn.dispose()、MapCard.dispose()；clear() 见 MosouBanner.clear()/clearChildren() 与 FightUI.clearStartAndEnd()。同类里也不一致：MapCard 用 dispose，HDText 用 destory。

（2）MenuBtnGroup.destory() 是完整样本，四步齐全：先 GameRender.remove(render)（防止拆到一半又跑一帧），再 endStrike() 复位动效状态机（隐藏 strike 层、还原 scaleY、重置 _strikeNext），再遍历 _mains 调每个 entry.destory()（先子后父）并 _mains.length=0，最后置空 _openParent/_confirmEntry/_confirmFunc。

（3）监听清理的正确样本是 MapSelectUI.destory()：removeEventListener 摘 onSlide 与 onAmbient 两个 ENTER_FRAME、摘 ADDED_TO_STAGE 与 REMOVED_FROM_STAGE、killTweensOf(_anim) 与 (_nudge)、遍历 _targets 逐个摘四类监听、_targets=[]、遍历 _cards 调 dispose()、摘 parent、三个 HDText 置 null。注意先 remove 再清数组，顺序不能反。ADDED_TO_STAGE/REMOVED_FROM_STAGE 的用法值得抄：页内动画绑舞台进出而不是绑页面生命周期，页面在内存里也不空转。

（4）BitmapData 记账只有 TitleScreenUI 做成规模：ui/TitleScreenUI.as:TitleScreenUI.makeText() 每造一张就 _bitmaps.push(bd)，dispose() 里 while(numChildren>0) removeChildAt(0) 后逐张 BitmapData(_bitmaps[i]).dispose()。HDText 走单条路线：set text 时先 dispose 旧图再新建（render() 首两行），destory() 再 dispose 一次。

（5）零池化加硬上限：MenuBtnGroup.updateParticles() 仅 _particles.length<150 时 spawn（每帧最多加 3，寿命按 decay 递减，越界或 life<=0 就 removeChild 加 splice）；spawnSparks() 固定 STRIKE_SPARKS=36 个；MapSelectUI.burst() 是 10 个 spark 加 1 个 ring，用 TweenLite.delayedCall(0.42, dropFx, [fx]) 统一摘；MapCard._runner 每帧 graphics.clear() 后重画 7 段线、不再 new。全项目对象池只在效果与阴影系统（ctrl/EffectManager.as 的 EffectPool 与 MAX_POOL_PER_EFFECT=64、ctrl/PoolMaintenance.as 的 MIN_POOL=8、ctrl/ShadowCtrl.as、views/filter/BitmapFilterView.as 的 _bmdPool=30、ShadowEffectView）。UI 层不池化是明确取舍：UI 件生命周期是屏级，池化收益低于状态污染风险。

（6）两套帧驱动并存：GameRender.add 的 8 个类是 MenuBtnGroup、MoveListSp、OptionsScreen、OptList、PauseMenuUI、StyleDialogBase、StyleDialogView、SelectIndexUIGroup；另有 33 个类自挂 Event.ENTER_FRAME（MapSelectUI 的 onAmbient/onSlide、MapCard.onFrame、SelectCursor.onPulse、SelectIndexArrow、SetBackdrop、SetBtn 等）。结果是一个页面同时挂着 3 到 5 个 ENTER_FRAME 加 1 个 GameRender 任务，无统一调度，也无降频入口（GameRender 的 interval 参数在 ui 包里 8 处全用默认 1）。

### 4.7 案例一：ui/MenuBtnGroup.as —— 最纯的代码 UI 基元

规模与定位：参考 :2446 行，是 ui 包最大的单文件；grep 到 80 处绘图记号（beginFill/lineStyle/lineTo/drawXxx/:Graphics），单文件最多；同时用 TweenLite 与 GameRender，且不取任何 SWF 元件、不留任何帧脚本。就「纯代码 UI」这一点说，它是整套体系里最干净的样本。

层级（ctor 只记画布再建层，10 个 Sprite 加 6 个特效 Shape）：

    Sprite：_bgLayer、_particleLayer、_slashLayer、_slashMask、_artLayer、_fxLayer、
            _entryLayer、_topContentLayer（内含 _topArtLayer 与 _topTextLayer）、_strip
    Shape： _bgSolid、_slash1/_slash2、_slashMask1/_slashMask2、_colLine、
            _wipeNewN/_wipeOldN/_wipeNewT/_wipeOldT、_cutFx、_flashFx
    数据：  _mains:Vector.<MainMenuEntry>、_openParent、_mainIdx、_childIdx、_artCache
    静态：  COLOR_MAIN（可变）、CONTRAST_COLOR、FONT、FAUX_BOLD、COLORS、DESCRIPTIONS、
            ARTWORKS、ART_SILHOUETTE、BG_COLOR、ART_* 与 STRIKE_* 二十余个动效参数、
            FEEDBACK_FX、HAPTIC

build() 的十步（这是全套 UI 最完整的一份初始化清单）：

    1) 复位 scaleX/scaleY=1、x/y=0
    2) initWipeGeometry()：由 (0.95W,-1.01H) 求单位法向 _nx/_ny，算擦除边界 _wipeMin/_wipeMax、
       切向 _tMin/_tMax、锚点 _pivX=0.7W 与 _pivY=0.5H
    3) setArtwork() 注册 8 张主菜单插图（ArtArcade/ArtBattle/ArtMultiplayer/ArtMosou/ArtOption/
       ArtTraining/ArtEndless/ArtWatchmode，均为 _assets 里 Embed 的 PNG 类）
    4) _btnConfig = GameInterface.instance.getGameMenu()，空则 getDefaultMenu()，并滤掉
       label 为 "ENDLESS MODE" 的项
    5) new 全部层与四张 wipe Shape，new _cutFx/_flashFx（后者直接画 -20..W+40 白矩形、alpha=0）
    6) buildStrike()：createGradientBox 加 beginGradientFill 做 OVERLAY 与 ADD 两层扫描光束，
       再叠 glow/core/echo 三条矩形，全部 mouseEnabled=false 且预置 visible=false
    7) _topContentLayer.mask = _slashMask（斜条裁菜单文字），随后 addChild 十连把层组进舞台
    8) buildBackground()：铺 -W..2W 乘 -H..2H 实底，保证任何偏移都不露底
    9) buildSlashes()：两条 makeSlash 七边形长条，rotation 用 atan2 对齐
   10) buildEntries() 与 buildStrip()，然后 syncSelected()、updateDesc()、animate()、
       _strikeNext=getTimer()+STRIKE_FIRST、_built=true、GameRender.add(render)

排版公式（它所谓的「布局」只有这几行）：

    x0 = round(W*0.05)                      y0 = H*0.075
    row = min(H*0.088, (H*0.86-y0)/max(1,_btnConfig.length))   挤不下就压行距
    fsize = round(H*0.074 * row/(H*0.088))                     字号跟着行距等比缩
    w = round(W*0.3)
    第 i 项：baseX=x0、baseY=y0+i*row、introDelay=4+i*3          入场逐项延迟 3 帧
    子项：fsize=round(H*0.048)、row=H*0.07、列 x=round(W*0.05+W*0.3+30)，
          列首 y 夹在 H*0.06..H*0.84，并画 3px 竖线 _colLine.lineStyle(3,COLOR_MAIN,0.95)

内嵌基元 MainMenuEntry（同文件 package 块之后的文件级私有类，非 public）：

    构成：hit（alpha=0 的 w+8 乘 rowH 命中矩形）、_marker（5 点三角）、
          _sweep（斜切渐变扫条，createGradientBox 三档 alpha）、_tf（TextField）、
          _fx（特效层）、_topContainer/_tfTop（反色字，同坐标同缩放，描边色 CONTRAST_COLOR）
    交互：buttonMode=true、mouseChildren=false；挂 mouseOver/mouseDown/mouseUp/mouseOut/click
          与 touchBegin/touchEnd/touchTap；回调字段 onHover/onActivate 由父类注入
    反馈：pressed() 记 localX/localY 后 ripple()（上限 9 个子件）；
          onSelectedFx() 用 TweenLite 弹 _pop（0.3s Back.easeOut）加 _marker.scaleY 0.1 到 1
          加 runSweep(0.3)；playConfirmFx() 用 _pop=1.6 起跳加双环加 10 道放射短线

render(intro,shift,offset) 由父类每帧调：

    x = baseX + p*shift - (1-intro)*offset        p 是选中插值，选中项向右让 shift 像素
    y = baseY - (sc-1)*rowH/2                     缩放中心补偿，围绕行中心放大
    sc = 1 + 0.07*_pop.v - 0.05*_press.v
    alpha = intro*dim；文字色用 ColorTransform 三个 offset 从白过渡到 COLOR_MAIN
    _topContainer 同步 x/y/scale/alpha，visible = parent!=null 且 alpha>0.01
    marqueeStep() 走 SkewBtn.marquee(_tf,_mqStart) 做跑马灯，再令 _tfTop.scrollH=_tf.scrollH

动效三段（都与 _artT 或 _frame 绑定）：

    擦除过渡 startArtTransition()：旧图挂 _wipeOldN、新图挂 _wipeNewN，
      drawWipe(m,edge,keepFar) 按法向画多边形把画面劈成两半
    图像步进 stepArt()：_artT<1 时按 easeSnap 推进，每 2 帧抖一次（_shX/_shY 与 inv 平方
      成正比乘 ART_SHAKE）；新图 punch=1+ART_PUNCH*inv*inv 并沿法向骑入 130px 再反向推 70px，
      旧图反向退出；drawCut(edge,inv) 画 1 粗 1 细两条加 10 道 hash() 定值毛刺；
      _flashFx.alpha = ART_FLASH*inv*inv
    定时打击 stepStrike()：_strikeNext 到点且 canStrike()（_built 加无 _confirmEntry 加
      _artCur 非空 加 _artT>=1 加非 _wipeActive）才起手；按 _pivX/_pivY 在法向上的投影
      反算命中比例 _strikeHitP；命中时 spawnSparks() 造 36 个 ADD 亮点，并把 _slash1/_slash2
      的 scaleY 拉到 1+1.6*pk*pk 做刀光撑开

输入闸门三层，缺一漏点：

    if(!_built) return;                     未建完
    if(!enabled) return;                    外部闸（MenuState 在 fadIn 后 400ms 才置 true）
    if(GameUI.showingDialog()) return;      弹窗挂在 root 上不在本树，必须显式问
    确认动画期间 _confirmEntry 非空则直接 return（连 animate() 都跳过，见 render() 分支顺序）

内存与拆解：destory() 见 4.6。每帧 animate() 里 new 两个 ColorTransform（slCT/invCT）与一个
pureCT，是它唯一的每帧分配；_artCache 按 artKey 缓存 normal/top 两份实例且不 dispose
（贴图来自 Embed 类，随类常驻）。

移植判断：能整块搬。对外只依赖 GameInterface.getGameMenu() 的按钮表（txt/func/children/art
字段）、GameMode.currentMode 常量、SoundCtrl 三个音效方法、HAPTIC 钩子。必须重写
getFucByLabel()：它用英文字符串 label 做 switch 分派业务（"TEAM MODE" 对应
GameMode.currentMode=10 等），label 一改文字功能就断。

### 4.8 案例二：ui/select/MapSelectUI.as —— 选关轮播，滚动与节点命中

规模：参考 :1011 行（主类 759 行加同文件内嵌 252 行的 MapCard），43 处绘图记号，TweenLite 加两个 ENTER_FRAME（环境动画 onAmbient、滑动 onSlide），scrollRect 只用于图片裁切。

主类骨架：

    static：MAX_VISIBLE=9、SHOW_BACKDROP=true、COLOR_MAIN=SelectStyle.COLOR_ACCENT、
            CONFIRM_TIME=0.28
    public：enabled（初值 false）、inputType
    数据：  _maps、_curId、_picCache、_cards:Vector.<MapCard>、_targets、_slots
    几何：  _cardW/_cardH/_step/_slide
    件：    _bg(Shape)、_row(Sprite)、_title/_counter/_nameTxt(HDText)、_nameLine、
            _arrowL/_arrowR、_innerL/_innerR、_nudge{l,r}、_anim{v}
    回调：  _prevListener/_nextListener/_confrimListener（外部注入）

ctor 直接 build()，并在 ctor 里挂 ADDED_TO_STAGE 与 REMOVED_FROM_STAGE —— 进场才动、退场就停（见 4.6 第 3 点）。

build() 的分工（背景一次画完永不变）：

    _bg：SHOW_BACKDROP 时从 H*0.49 到 H 铺 [328965,328965] 线性渐变（alpha 0..0.75 到 70 处），
        再描 1px 导轨线（alpha 0.15）加中央 3px 斜切小标记（SelectStyle.slantPath）
    buildTag(tx,ty,tw,th)：斜切标签底板 = 1px 白描边 加 0.72 黑填充 加 左侧 COLOR_ACCENT 斜条
    标题条：tagW=round(W*0.27)、tagH=round(H*0.043)、tagY=round(H*0.505)，水平居中
    计数条：cW=round(W*0.13)，右缘对齐到 round(W*0.94)
    _row：每张卡以 W/2 为中心对称摆，中心那张 setChildIndex 到末位（抬到最上）
    箭头：createArrow(dir,W,H) 造双 V 形（两个相隔 13px 的折线组），GlowFilter 发光，
          alpha 0.85，x 为 0.045W 与 0.955W，内层 x 由 applyArrows(sway) 给
    名条：nameBoxW=round(W*0.6) 居中；_nameLine 是 120x3 斜切小条，
          y=round(H*0.912+nameSize*0.62) 对齐文字基线

几何常量：_cardW=round(W*0.08)=64、_cardH=round(H*0.3)=180、_step=round(W*0.094)=75、cardTop=H*0.575=345、cy=round(cardTop+_cardH/2)=435；条数 count=min(n,MAX_VISIBLE) 且偶数则减一，保证有正中一张；第 i 张 x=round(W/2+(i-half)*_step)、half=count>>1。

layout() 只重建「下标到卡片」的映射，不动任何 x/y：

    half = _slots>>1
    逐槽：off=s-half；idx=wrap(_curId+off,n)（wrap 做 ((i%n)+n)%n）；
          card.index=idx；card.setPic(getPic(vo))；card.setState(off==0, abs(off))
    计数条：pad2(_curId+1) 加 " / " 加 pad2(n)
    名条变化时 playNameFx()：距上次小于 120ms 直接落位（防连按叠动画），否则
      _nameTxt.x 从 _nameX+24 补间到 _nameX、alpha 0 到 1（0.22s），
      _nameLine.scaleX 0.15 到 1（0.3s Back）

滑动是整行平移，不重排：

    showMap(index)：d=index-_curId，环形归正（d>n/2 则 d-=n；d<-n/2 则 d+=n），
      夹到正负 3；_slide=d*_step；_row.x=_slide；addEventListener(ENTER_FRAME, onSlide)
    onSlide()：_slide*=0.7；abs(_slide)<0.5 则归零并摘监听；_row.x=_slide
    所以跨 3 张以上是「瞬移到夹取后的位置再回弹」，视觉上是一次快速滑入

图片管线（唯一用 scrollRect 的地方）：

    getPic(vo)：先查 _picCache[vo.id]；未命中则 AssetManager.I.getMapPic(vo)，
      新建 holder:Sprite 包一层，按 max(_cardW/b.width,_cardH/b.height) 做 cover 缩放，
      居中补偏移（-b.x*sc 与 -b.y*sc），holder.scrollRect=new Rectangle(0,0,_cardW,_cardH) 硬裁，
      holder.mouseChildren=false，入缓存
    同一张图在 9 个槽位轮转只裁一次，此后是同一 DisplayObject 被 setPic 搬来搬去

节点命中：

    addMouseEvents(p1,p2,p3)：存三个回调；_targets=[_arrowL,_arrowR] 加所有 _cards[i]；
      buttonMode=true；TOUCH_MODE 挂 touchTap，否则挂 mouseOver 加 mouseOut 加 click
    doAction(t)：t 是 _arrowL 则 prev；是 _arrowR 则 next；是 MapCard 时若 card.index==_curId
      走确认回调，否则 showMap(card.index) 并播 sndSelect
    语义：点别的卡为选中、点当前卡为确认，没有二次确认弹窗（MapCard.playConfirm 只是视觉）
    命中区就是自身显示边界（无自定义 hitTest），斜切外形外的透明角也算命中

MapCard（同文件 package 后的文件级私有类，extends Sprite）：

    构成：bg（1052688 实底斜切）、_picBox 加 _picMask（斜切遮罩）、_shade（未选中压暗）、
          _halo（7px 描边呼吸）、_frame（选中 3px、未选中 1.5px 加 GlowFilter）、
          _runner（沿周长跑光）、_flash（确认闪白）
    setState(selected,dist)：0.18s Back 把 scale 补到 1.1 或 1.0；
      _shade.alpha 到 selected 为 0，否则 min(0.6, 0.22+dist*0.07)（越远越暗）；
      _frame 重画描边并换 filters；_halo 与 _runner.visible 跟随 selected；
      只有选中才挂 ENTER_FRAME(onFrame)，取消即摘
    onFrame：_halo.alpha=0.55+sin(_t*0.2)*0.45；SelectFx.ENABLED 为真时才用
      buildPerimeter() 的周长与 pointAt(d) 画 runner（head=_t*_perim/70，拖尾占周长 20%，
      分 7 段递增 alpha）
    playConfirm：_flash 从 0.9 到 0（0.28s），自身 1.2（0.12s）再回 1.1（0.14s）
    dispose：摘 ENTER_FRAME 加 killTweensOf(this/_shade/_flash)

为什么这么做：9 张卡若每帧重裁，BitmapData.draw 的代价在手机上直接掉帧；scrollRect 让 GPU 裁、_picCache 让裁只发生一次，是这套 UI 最实用的性能约定。副作用是 holder 被多卡共享时 parent 反复换，setPic 对「pic 与 _pic 相同且 parent 已是 _picBox」短路正是为此。

移植判断：搬得动，但要替三个数据源（MapModel.I.getAllMaps() 的 MapVO 需要 id 与 name、AssetManager.I.getMapPic(vo)、GameData.I.selectMap 赋值），另需 KyoRandom.getRandomInArray 处理 id 为 random 的随机图。

### 4.9 案例三：ui/fight/FightUI.as —— 战斗 HUD，与主项目正面冲突的那块

规模：参考 :1117 行，自身仅 4 处绘图记号（画图的是 9 个子件），实现 IGameUI，是状态机最复杂的一个。

结构与双重缩放：

    ui.scaleX = GameConfig.GAME_SIZE.x / 1066      （800/1066 = 0.7505）
    ui.scaleY = GameConfig.GAME_SIZE.y / 600       （600/600 = 1）
    _hud.scaleX = FightTheme.S / ui.scaleX          先把父层缩放除掉
    _hud.scaleY = FightTheme.S / ui.scaleY
    _noticeHost.scaleX = _hud.scaleX；_spiritHost.scaleX = _hud.scaleX
    _bounds = 1066x600 透明矩形（撑开 ui 的尺寸与 hitArea）
    ui.setChildIndex(_spiritHost, ui.getChildIndex(_hud))   把 spirit 插回 hud 原位

装配（ctor 完成全部，共 6 个直属子层）：

    ui 含 _bounds、_lowFx.view、_hud、_noticeHost、_spiritHost、_legacy
    _hud 含 _fightbar.ui、_qibar1.ui、_qibar2.ui、_hits1.ui、_hits2.ui、
          _p1PosUI、_p2PosUI、_announce
    子件类型：FightBar、QiBar、HitsUI、PlayerMarker、FightAnnounce、FightNotice、
             SpiritDrive（宿主 _spiritHost）、LowHpFx、PauseDialog

render() 的五件事（由 state/GameState.as 每帧调）：

    tickCinema()                                  影视化自动隐藏 HUD
    _fightbar.render()/_qibar1.render()/_qibar2.render()   数值层
    _hits1.update()/_hits2.update()               连击层
    renderPlayerPosUI(camera.getZoom())           屏幕外角色位置箭头
    checkLowHpBGM()/checkRestoreUI()/checkBloodFilter()    音频与滤镜联动

tickCinema()：

    want = EffectCtrl.I["hideFightUI"]==true      字符串索引加 try/catch 兜底
    _cineIgnore、_playOver、_renderEnd 为真时不隐藏
    want 且未隐藏 则 _cineHidden=true、记 _cineStart、fadOut(true)
    已隐藏且（不再 want 或超 9000ms）则 _cineHidden=false、fadIn(true)
    每帧把 _hud.alpha 与 _lowFx.view.alpha 按 dt/200 推向 0 或 1（dt 夹在 16..100）

checkBloodFilter()：

    判据 p1.hpMax>0 且 p1.hp>0 且 p1.hp/p1.hpMax<=0.3
    力度 lowPow=0.2+0.8*clamp((0.3-hpRate)/0.3)
    动作 _lowFx.update(lowPow,dt)；_lowFx.beat 为真时 _fightbar.hpBeat(lowPow) 抖血条；
        _targetMasterVolume=0.2，FightSfx.setMasterVolume 按 0.05 系数逼近

checkLowHpBGM()：

    actionState==13 记为必杀（_p1SuperTimer 累加且要求 <=30 帧）
    actionState==50 记为卍解（isP1Wankai）
    触发：必杀且对手 hpRate<=0.3，或卍解；每方只触发一次（_p1BgmTriggered）
    换人检测：_p1FighterCache 变则重置全部标志并 SoundCtrl.I.playStartGameBGM()

时序编排 showStart：

    先按 GameCtrl.I.gameRunData 重新 initlize（血条重新绑人）
    清 _playOver/_renderEnd；ui.visible=true 与 alpha=1；fadIn(true)
    挂 _announce 的 "fight"（一次性，收到即摘）与可选 "complete"
    最后 _announce.playStart(round)

时序编排 showEnd 与 playKO：

    showEnd 写 _endParam=params 与 finishBack、_drawGame=params.drawGame；
      isTimerOver 则 playTimeOver() 否则 playKO(params.loser)
    playKO 依次：SpiritDrive.stopAll()、所有条 fadOut、隐藏连击与位置箭头、
      EffectCtrl.I.freezeEnabled=false、doEffectById("hit_end",loser.x,loser.y)、
      shine(16777215,0.85)、cameraFocusOne、相机 setZoom(1.8)（走 hasOwnProperty 动态探测，
      失败静默）、BGEffect("kobg", KO_PAUSE_MS/1000)、bgBlurEnabled=false、shake(12,12,1.5)、
      GameCtrl.I.pause()、IMPACT_FRAME 为真时给整个游戏加黑白 ColorMatrixFilter
    setTimeout(KO_PAUSE_MS=2500ms) 后：摘滤镜、resume()、bgBlur(4,0,20000)、
      slowDownRamp(4,0.5,2.5)、playKO2()（播 KO 演出与 snd_ko 或 snd_ko_bs）

renderEnd()：用 _showWinnerDelay 计帧（0.5/1/2 乘 GameConfig.FPS_GAME）延迟出胜利者；
dynamicCamera 为真走 EffectCtrl.I.playCinematicOutro(winner)，否则 cameraFocusOne。

pause 与 resume 的语义不对称：

    pause()：置 _isPaused、SpiritDrive.userPaused；_pauseDialog 为空时 new PauseDialog()，
      用 graphics.beginFill(0,0.6) 画 1066x600 黑罩，_legacy.addChild，再 show()
    resume()：清两标志；_pauseDialog 为空返回 true，否则 return _pauseDialog.hide()
    即返回值表示「暂停框是否已关闭」，供外层判断能否继续

与 3.3 的正面冲突：3.3 的 ui/fight/FightUI.as 只有 610 行，血条/气条/连击全部来自 fight_swf 元件，按 AS 链接类型取实例名；3.7 的同名类 9 个子件全是自绘 Sprite。两者没有共同中间表示，只能整块替换、不能逐个对齐；单独搬 FightUI 会得到空壳，因为它引用的 _fightbar.ui 与 _qibar1.ui 都是自绘子件暴露的出口。

移植判断：能搬但成本最高。需要 GameCtrl.I.gameRunData（p1FighterGroup/p2FighterGroup/currentFighter/isTimerOver/getWins）、GameState.camera（getZoom/cameraFocusOne/setZoom）、EffectCtrl（freezeEnabled/shine/BGEffect/bgBlur/slowDownRamp/playCinematicOutro/cancelBgBlur/hideFightUI）、SoundCtrl（playStartGameBGM/checkFighterHpBGM/playSwcSound）、FightSfx（warm/resetMixer/setMasterVolume/masterVolume）五套替身；EffectCtrl 与 GameCtrl 都是全局单例且方法名靠字符串动态访问，替身必须同名。

### 4.10 案例四：ui/mosou/MosouBanner.as —— 无双横幅

规模与形态：参考 :446 行，11 处绘图记号加 1 处 scrollRect，无 SWF、无 TweenLite（自己算插值）、不注册帧任务（由外部 tick 驱动）。整体是「按 kind 配置 + 一次性 build + 纯函数 renderAt(t)」。

ctor(w,h)：

    _u = min(w/800, h/600)                 整体缩放单位
    _cy = h*0.4                            横幅中线
    mouseEnabled=false、mouseChildren=false
    scrollRect = new Rectangle(0,0,w,h)    自身即视口
    visible = false
    _ct = new Sprite()                     内容容器，抖动只动它，不动自身

play(kind,finish,sub) 的配置表：

    clearChildren() 后复位 _t/_done/_hold/_slam/_warn/_shake/_flashStart/_dimMax/_dur
    默认：MISSION START 配 DEFEAT ALL ENEMIES 配 ORANGE、_dimMax=0.35、_dur=2.4
    BOSS_IN：WARNING 配 BOSS APPROACHING、INK 带配 ORANGE、_dimMax=0.5、_dur=2.8、_warn=true
    BOSS_KO：K.O.、_dimMax=0.3、_dur=2.6、_slam/_shake/_flashStart 全真
    WIN：MISSION COMPLETE、_dimMax=0.4、_dur=2.6、_hold=true
    LOSE：MISSION FAILED 配 TRY AGAIN、INK/RED、_dimMax=0.55、_hold=true
    sub 参数非空则覆盖副标；随后 build(...)、_playing=true、visible=true、renderAt(0)

tick(dtMs)：dt 夹到 0..50；_t+=dt/1000；renderAt(min(_t,_dur))；_t>=_dur 且未 _done 时收尾——_done=true、_playing=false、取走 _finish 置空、_hold 为假则 visible=false、最后调 finish。

build() 的几何（全部是 _u 的倍数，13 个局部常量一次算完）：

    bandH=(_slam?96:104)*u、slant=bandH*0.38、shapeW=W*1.15
    stripeH=5*u、stripeS=slant*stripeH/bandH
    hz=14*u（警示条高）、hzP=28*u（周期）
    th=bandH*(_slam?1.3:0.5)、tw=MosouStyle.textW(title,th,0.9)
    sh=24*u（副标条高）、sth=13*u（副标字高）

build() 的件：

    _dim：(-20u,-20u) 铺到 W+40u 乘 h+40u 的 INK 实底，alpha 从 0 起
    _paper（非 warn）：SlashFx.torn(W*1.3, bandH+30u, paperCol, 31, 3u)，rotation=-2
    _band：SlashFx.slash(shapeW,bandH,slant,bandCol)；warn 时上下各加一条 hazard 斜纹
      （INK 底加橙色斜纹，周期 hzP），否则顶底各叠一条 5u 装饰条
      （botCol = bandCol==INK ? accentCol : INK）
    _titleHolder：tw 超 W*0.86 则按比例缩 th 再重量；thick=max(2,th*0.17)；
      双遍 MosouStyle.drawText，先 (3u,3u) 用 shadowCol 再 (0,0) 用 titleCol；
      定位在 (_bandW/2, bandH*0.46 或 0.5)
    _titleMask（非 slam）：(tw+24u) 乘 bandH*2 的矩形，scaleX 从 0.001 起，titleG.mask 指它
    _sub：fillPara 画 INK 底条加左侧 7u 橙竖条再 drawText(subText,20u,...)；
      _subX=W-_subW-56u，初始 x=W+20u
    _flash：全屏白，alpha=0

renderAt(t) 的六个通道（全由 SlashFx 的 prog/outCubic/inOutCubic 组合）：

    出场 o = _hold 取 0，否则 inOutCubic(prog(t,_dur-0.5,_dur))
    入位 inB = outCubic(prog(t,0,0.4))；settle=(W-_bandW)/2；start=W+10u
      _band.x = start+(settle-start)*inB；o>0 时改为 settle+(-_bandW-settle)*o
    撕纸 pin = outCubic(prog(t,0.08,0.6))：_paper.x = -W*0.7+W*1.2*pin+W*1.3*o
    dim：_dim.alpha = _dimMax*prog(t,0,0.3)*(1-o)
    slam：k=prog(t,0.05,0.3)、sc=1+2.2*(1-outCubic(k))，并按 prog(t,0.05,0.12) 淡入
    非 slam：_titleMask.scaleX=max(0.001,outCubic(prog(t,0.25,0.8)))；warn 且在
      0.9..(_dur-0.6) 内 _titleHolder.alpha 做 0.5+0.5*abs(sin((t-0.9)*PI*3)) 闪烁
    副标：_sub.x = _subX+(W+20u-_subX)*(1-outCubic(prog(t,0.55,0.95)))，出场再按 o 推出去
    警示纹：off = t*90*u%(hzP)；_hazTop.x=-off；_hazBot.x=-hzP+off
    闪白：_flash.alpha = _flashStart ? 1-prog(t,0,0.35) : 0
    抖动：_shake 且 t 在 0.25..0.9 时 _ct.x/_ct.y = (random-0.5)*16*u*sk

要点：整段动画是 t 的纯函数，可任意 seek（tick 传什么 t 就画什么状态）。这与 MenuBtnGroup 的累积式状态机（_artT/_frame 递增）是两种范式：前者可回放可暂停，后者只能顺序播。

移植判断：能整块搬，是四件里最干净的，只依赖 MosouStyle（常量与 drawText）、SlashFx（slash/torn/prog/outCubic/inOutCubic）、VectorText。代价是文案只认 ASCII（见 4.4），且宿主必须像 MosouUI 那样每帧调 tick(dtMs)，它不自驱动。

### 4.11 自绘三件套与它们的代价

（1）Graphics 描边填色：78 个文件、1822 处记号。典型形态是 Shape.graphics.beginFill(color,a) 配 moveTo/lineTo 一圈 endFill，lineStyle(w,color,alpha,pixelHinting) 高频出现在 MapNodeView（60 处）、MoveListSp（81 处）、VictoryUI（122 处）、MenuBtnGroup（80 处）、LoadingScreenUI（75 处）。代价是每次 clear 加重画都要重新提交绘制指令，静态图形无妨，逐帧重画的（MapCard._runner、SelectCursor.drawRunner、MenuBtnGroup 的 wipe）在低端机上是纯 CPU 开销。

（2）BitmapData 离屏：26 个文件、57 处构造，用途四类——文字栅格化（HDText、TitleScreenUI.makeText、SelectStyle.verticalName、LoadingView）、噪声与纹理（TitleScreenUI.buildClouds 的 noise/cloud、VersusLoadingUI 的 _grainBmd、VerticalMarquee 的 _tile）、快照与转场（BleachTransition 的 src/out、FightRaster）、遮罩底色（DialogManager 的 1x1 透明位图）。代价是每张都要 dispose，做记账的只有 TitleScreenUI（_bitmaps）与 HDText（set text 时先 dispose）。

（3）Bitmap 显示：24 个文件，共同手法是 new Bitmap(bmd,"auto",true) 第三参 smoothing=true；SelectStyle.cloneFace 对 Bitmap 做「同 bitmapData 再包一个 Bitmap」的浅克隆，SelectStyle.fitCover 再补一次 bmp.smoothing=true。

（4）三种字体方案的代价：TextField 直用清晰度随设备缩放、内存极低、原生支持中文但不支持独立字重控制；HDText 超采样清晰度高、每字符串一张位图、支持中文、不支持换字重；VectorText 与分辨率无关、零位图、不支持中文、笔画粗细可调但字形固定。选择判据写在代码里：需中英混排的走 TextField/HDText，只有大写英文与数字的（无双横幅、菜单标题）走 VectorText，因为字形表只覆盖 46 个字符。

## 5. 陷阱与反编译噪音

以下每条都是实读代码得出的确定事实，不是猜测。分两类：A 类是代码本身的坑（照抄会踩），B 类是反编译造成的假象（照着改会改错）。

### A 类：代码本身的坑

A1. GameUI.fadOut() 调的是 fadIn()。

    源码：ui/GameUI.as:GameUI.fadOut()
      public function fadOut() : void { if(_ui) { _ui.fadIn(); } }
    对比同类 fadIn()：if(_ui) { _loc1_ = GameData.I.config.soundVolume; _ui.fadIn(); _ui.setVolume(_loc1_); }
    ⇒ fadOut 既不淡出、也不设音量，是复制粘贴留下的死路径。谁调 GameUI.fadOut() 都不会有淡出效果。

A2. GameUI.initMission() 的 as MosouUI 强转只在 _ui 为 null 时成立。

    源码：ui/GameUI.as:GameUI.initMission()
      if(_ui) { if(_ui is FightUI == false) { _ui.destory(); _ui = new FightUI(); ... } }
      else    { _ui = new MosouUI(); ... }
      (_ui as MosouUI).initlize(param1);
    MosouUI 只 implements IGameUI，不 extends FightUI（ui/mosou/MosouUI.as:public class MosouUI implements IGameUI）。
    因此：_ui 为 null 时进 else 建 MosouUI，转型成立；
          _ui 已是 FightUI 时，if 块内因为 is FightUI 为真而跳过重建，随后 as MosouUI 得 null；
          _ui 已是 MosouUI 时，if 块内 is FightUI 为假，于是 destory 掉 MosouUI 换成 FightUI，随后仍得 null。
    ⇒ 第二次进入无双关卡必然空引用。这条同时暴露了 initFight 那个判据的语义错位：
      「不是 FightUI 才重建」与「要 MosouUI」是两个互不相容的条件。

A3. GameUI.BITMAP_UI 是死开关。

    源码：ui/GameUI.as:GameUI 里 public static var BITMAP_UI:Boolean = true;
    全项目检索 BITMAP_UI，只有这一处声明，0 处读取。
    ⇒ 想靠它切换「位图 UI / 元件 UI」不会生效。

A4. MenuBtn 的监听判据用了 ui.hasEventListener，且没有对称的 removeEventListener。

    源码：ui/MenuBtn.as:MenuBtn.addEventListener()
      if(ui.hasEventListener(param1)) { return; }
      ui.addEventListener(param1, selfHandler, param3, param4, param5);
      _listeners[param1] = param2;
    源码：ui/MenuBtn.as:MenuBtn.removeAllEventListener()
      for(var _loc1_:String in _listeners) { ui.removeEventListener(_loc1_, _listeners[_loc1_]); }
    两个问题：
      1) 判据看的是 ui 上有没有同类监听。任何直挂 ui 的监听（例如触屏长按用的
         touchBegin/touchTap）都会让它误判为已注册而静默 return，吞掉外部回调。
      2) 真正挂在 ui 上的是 selfHandler，而 _listeners 里存的是外部回调 param2。
         removeAllEventListener 拿 param2 去 removeEventListener，删的是一个从未挂上的函数，
         selfHandler 永远留在 ui 上。
    这是主项目已经修过、3.7 还没修的老问题：BVNscripts/scripts 下同名类
    （ui/MenuBtn.as:MenuBtn.addEventListener()/removeEventListener()）已经把判据改成
    _listeners[param1] == null、补了对称的 removeEventListener，并对 ui 为 null 加了守卫。
    ⇒ 移植这一块必须用 3.3 的写法，不能抄 3.7。

A5. GameRender 没有异常隔离，一个 UI 任务的异常会中断同帧后续全部任务。

    源码：ctrl/GameRender.as:GameRender.render(e)
      if(!isRender) return; if(_dirty) sortTasks();
      while(i < len) { task.counter++; if(counter>=interval){counter=0; task.func();} i++ }
    循环体没有 try/catch。8 个 UI 类把函数注册进来（见 4.6（6）），
    其中任何一个抛异常，本帧排在它后面的任务全部不执行。
    这与主项目在 GameMainLogicCtrler 里踩过的坑同型（见 CLAUDE.md 受击章节第 1 条：
    render 与 renderAnimate 必须两个独立 try），只是 3.7 这边没有做隔离。

A6. GameRender.add 以函数标识去重，传闭包会重复注册。

    源码：ctrl/GameRender.as:GameRender.add()
      while(i < _tasks.length) { if(_tasks[i].func == func) return; i++ }
    ⇒ 传 this.render（同一函数对象）安全；传 function():void{...} 每次都是新对象，
      重复 add 会挂多个，remove 一次只能摘一个。另外 remove(func, group) 的 group 参数
      在实现里完全没用到，摘除只按函数对象匹配。

A7. 魔法数与硬编码下标。

    ui/GameUI.as:GameUI() 里 SHOW_HP_TEXT = GameMode.currentMode == 40;   （40 = 无双模式）
    ui/fight/FightUI.as 里用 actionState == 12 / 13 / 50 / 22 / 30 判必杀、卍解、击飞、落地
    state/SelectFighterStage.as 里 _ui.addChildAt(_p1Slt.group, 1) 与 (_p2Slt.group, 1) 两次插同一下标
    ui/fight/FightUI.as 里 _pauseDialog 的遮罩写死 1066x600（与 ui 的设计分辨率绑死）
    ⇒ 这些数字没有任何枚举或常量收口，改模式编号或改设计分辨率时必须全局搜。

A8. MapSelectUI.addMouseEvents 没有幂等保护。

    源码：ui/select/MapSelectUI.as:MapSelectUI.addMouseEvents()
      每次调用都重新给 _arrowL/_arrowR/_cards 挂 touchTap/mouseOver/mouseOut/click，
      并重新 push 进 _targets（不清空旧数组）。
    ⇒ 同一次进场里调用两次，一次点击会触发两次 doAction（音效叠播、showMap 连跳）。

A9. VectorText 与 MosouStyle.sanitize 会吞掉白名单外的字符。

    源码：ui/mosou/MosouStyle.as:ALLOWED = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ><-/.:!%+?#="
    源码：ui/mosou/MosouStyle.as:drawText() 直接把 str 交给 VectorText.draw()，
          VectorText 的字形表 DATA 里没有的字符走到 !gl 分支，只推进 cx，不画任何笔画。
    ⇒ 中文、小写字母之外的拉丁字母、全角标点，全部消失（不是画成方框，是干脆没有）。
      做中文版时这是第一位的坑，且没有报错。

A10. MenuBtn.select() 把 alpha 设为负一。

    源码：ui/MenuBtn.as:MenuBtn.select()  ui.alpha = -1;
    Flash 的 alpha setter 会把值夹到 0..1，所以实际效果等价于 0（从全透明弹到 1）。
    写 -1 不是有效值，读代码时不要以为它在做「负向淡出」。

### B 类：反编译噪音

B1. 文件内私有类被挤到 package 块之后。

    ui/MenuBtnGroup.as 的 MainMenuEntry、ui/select/MapSelectUI.as 的 MapCard 都在
    package{...} 结束后以 file 级 class 声明出现，且不带 internal/public 修饰。
    这是反编译把「同包 internal 类」合并进主文件的结果。阅读时不要以为它们是嵌套类，
    它们无法访问主类的私有成员（只能通过传参拿）。

B2. 类型存在、源文件不存在。

    ui/MenuBtn.as 的 public var ui:mc_wzbtn;   —— mc_wzbtn 在 scripts 树里没有 .as
    ui/SetCtrlBtnUI.as 的 public var ui:keyset_mc; —— keyset_mc 同样没有
    它们是 SWF 库符号类（编译进 common_ui_swf / setting_swf 的 AS 链接类），
    反编译只导出了引用方。因此这两个类的字段类型在纯 AS 工程里无法通过编译，
    必须换成 * 或自定义接口。

B3. StyleDialogView extends MovieClip 是全包唯一一处。

    ui/dialog/StyleDialogView.as:public class StyleDialogView extends MovieClip
    其余 151 个类里最接近的是 BitmapText/Bitmap/Shape 各 1。
    ⇒ 它是元件类而不是自绘类，弹窗的视觉外壳仍来自 SWF；把「自绘」当全局结论会看错这一块。

B4. 十进制颜色常量。

    FightTheme.INK = 460044（0x07050C）、MenuBtnGroup.COLOR_MAIN = 16727306（0xFF3D8A）、
    SelectStyle.COLOR_ACCENT = 15921906（0xF2F2F2）、OptKit.PANEL = 328967（0x050507）
    反编译把十六进制面量统一写成十进制。比对配色时先换成十六进制再读，
    否则会误判「这些颜色毫无规律」。

B5. if(isNaN(x)) 分支来自默认参数的编译产物。

    kyo/stage/KyoStageCtrl.as:KyoStageCtrl.addLayer() 里
      if(isNaN(x)) layer.display.x = (sw-dw)/2; else layer.display.x = x;
    形参声明是 param2:Number = 0，正常调用永远不会是 NaN。
    这段是「调用方显式传 NaN 表示居中」的约定残留，读的时候不要当成默认居中逻辑
    （唯一调用点 LANGameState 传的是 30,100）。

B6. 参数名丢失、局部变量提前声明。ui/MenuBtnGroup.as:MainMenuEntry.render() 里 sc 与 pr 在函数顶部声明再赋值；ui/select/MapSelectUI.as:MapSelectUI.destory() 里 i 与 t 提到函数顶部、两个 while 复用同一个 i、t 只在一处用。这类提声明不影响行为，但会让变量生命周期看起来比实际长。

B7. 动态成员访问掩盖了原始接口。input/GameInputer.as:GameInputer.call() 用 _loc5_[_loc6_][param2] 取方法再 apply；ui/fight/FightUI.as:playKO() 用 hasOwnProperty("setZoom") 探测再相机调 setZoom；tickCinema() 用 EffectCtrl.I["hideFightUI"] 并外套 try/catch。原始写法究竟是接口调用还是直接属性访问，反编译树已无法区分；可确定的是反编译结果成了字符串索引，于是编译器不检查、改名不报错，try/catch 还会吞掉真异常。

B8. 拼写错误是原样保留的，不是反编译产物。destory（IGameUI/Istage/MenuBtnGroup/MapSelectUI）、initlize（FightUI/MosouUI/GameUI）、ConfrimUI 与 confrim 与 _confrimListener（confirm 之误）、MousouKOsUI（Mosou 之误）、GameMode.isAcrade()。反编译不改标识符，所以这些是原作者拼写，移植时要一并继承，否则调用点大面积对不上。

## 6. 移植可行性

### 6.1 与主项目 SWF + AS 链接形态的差异对照（问 9）

| 维度 | 3.3 主项目（BVNscripts/scripts） | 3.7 扩展版（本册基准） | 后果 |
|---|---|---|---|
| 元件来源 | 每个控件一个元件：MenuBtn.ui 由 ResUtils.I.createDisplayObject(ResUtils.I.common_ui,"mc_wzbtn") 取 | 152 个类里 7 个仍按名取件（MenuBtn/SetCtrlBtnUI/CloudView/MosouSelectDialog/MosouStateDialog/DotItemUI/SelectFighterUI），其余全自绘 | 3.7 的「自绘」是 145/152，不是 152/152 |
| 类型检查 | ui:* 无类型（3.3）或 ui:mc_wzbtn（3.7 的 MenuBtn，符号类无源） | 自绘件全是 Sprite 子类，编译期可检查 | 自绘件改名会立刻编译报错；元件件改名不报错，运行时才炸 |
| 布局负责人 | 元件作者（FLA 里摆）+ 少量代码补偿（3.3 MenuBtnGroup 有 MARGIN_LEFT/MARGIN_TOP/COL_GAP/ROW_GAP 常量并注释说明「原来 TOUCH_MODE 下整组乘 1.1 会溢出 600」） | 代码里算（W 乘 k、H 乘 k 或乘 u），元件只当容器 | 改版式：3.3 改 FLA，3.7 改公式 |
| 动效负责人 | 元件时间轴（gotoAndStop/gotoAndPlay 切帧：MenuBtn 的 ui.bg.gotoAndStop(1|2)、DotItemUI、CoinUI、MosouEnergyBar、MosouQiBar、WinUI 的 in_bleach/in_naruto） | 代码（TweenLite 22 个文件、手算插值如 MosouBanner、GameRender/ENTER_FRAME 逐帧 state） | 3.7 无帧脚本可调，动效全靠参数；可 seek 可暂停，但改曲线要改代码 |
| 命中测试 | 元件形状（实例名当按钮） | 自绘 Shape 的绘制外形（MainMenuEntry 里那块 alpha=0 的矩形充当命中区） | 自绘件必须自己造命中区；忘造就点不到（MapSelectUI 的卡是整块矩形，斜切透明角也可点） |
| 文字 | BitmapFontText + BitmapText + UIUtils.formatText（BitmapText 系） | 三路并存：TextField 直用、HDText 超采样位图、VectorText 笔画字 | 3.7 多了一条「零位图」路径，代价是只认 46 个字符 |
| 主题 | 分散在各元件的美术里 | 六套 static 套件 + MenuBtnGroup 的散装 static（见 4.4） | 3.7 能给整体换色（改套件常量 + COLORS 表），3.3 要重画元件 |
| 生命周期 | dispose/destory 混用，靠 CLAUDE.md 记录的判据修 | destory 为主，dispose 为辅，见 4.6 | 两边都必须逐个类核对，没有统一基类可依赖 |
| 改一处动几处 | 改文字或位置要开 FLA 重发布（build.bat 期内嵌） | 改一个常量即可重编 | 这是 3.7 形态的唯一硬优势 |
| 一次改动的风险 | 元件实例名被改 → 编译过、运行时 null | 公式改错 → 全屏错位但编译过 | 3.7 的错更「可见」，3.3 的错更「静默」 |

一句话：3.3 把复杂度放在美术管线（FLA + AS 链接），3.7 把它放在代码里（152 个手写类）。前者编译期安全、改动成本高；后者改动成本低、没有横向约束。

### 6.2 组件级判定：能搬 / 要改 / 搬不了（问 10 与问 6 的合并答案）

| 组件 | 判定 | 原因与改动点 |
|---|---|---|
| ui/MenuBtnGroup.as 加内嵌 MainMenuEntry | 能搬 | 只依赖 GameInterface.getGameMenu() 的按钮表、GameMode.currentMode 常量、SoundCtrl 三个方法、HAPTIC 钩子；必须重写 getFucByLabel()（它用英文 label 做业务 switch） |
| video/VectorText.as | 能搬（最佳单品） | 零外部依赖（只用 Graphics/CapsuleStyle/JointStyle/LineScaleMode/Shape），字形表自包含；只认 46 字符，中文场景不可用 |
| video/SlashFx.as | 能搬 | 纯几何工厂（slash/torn）加缓动（prog/outCubic/inOutCubic），MosouBanner 与 LoadingScreenUI 都在用 |
| ui/fight/FightTheme.as | 能搬 | 纯静态数学（setup/mx/mrect/slab/fillSlab/gradSlab/clamp/lerp/ease*/mix/fighterName） |
| ui/select/SelectStyle.as | 要改 | slantPath/slantSlice/fitCover/isLight/onColor/textY 可直接搬；makeText 返回 HDText、verticalName 返回 Bitmap、displayName 依赖 FighterVO，这三处要换类型 |
| ui/select/HDText.as | 要改 | 依赖 SelectStyle.isLight 与 SelectStyle.textY（等价于绑死 select 包），把这两处内联即可 |
| ui/mosou/MosouStyle.as 加 MosouBanner | 能搬 | 只需把 drawText 的 VectorText 依赖与 sanitize 白名单一起带过去；宿主必须每帧调 tick(dtMs) |
| ui/select/MapSelectUI.as 加内嵌 MapCard | 要改 | 换三个数据源：MapModel.I.getAllMaps()、AssetManager.I.getMapPic(vo)、GameData.I.selectMap；另需 KyoRandom.getRandomInArray |
| ui/OptKit.as、ui/OptList.as、ui/OptRow.as、ui/OptionsScreen.as | 要改 | OptKit 是纯画具可整搬；OptList/OptionsScreen 依赖 OptionsData、GameInterface 的配置读写与 onChange/onAction 回调协议，需要重接 |
| ui/select/SelectCursor.as | 要改 | 需要 SelectStyle.sideColor/onColor/makeText/textY 与 HDText；moveTo 的调用方要自己算格子坐标 |
| ui/select/SelectFighterItem.as、SelecterItemUI.as、SelectedFighterGroup.as、SelectFighterStage.as | 搬不了（整体） | 1838 行的 SelectFighterStage 与 GameData.p1Select/p2Select、GameMode 的四人/双人组队规则、FighterIdleLoader 的角色 SWF 预览深度耦合；单搬 UI 层拿不到可用选人流程 |
| ui/fight/FightUI.as 加 9 个 HUD 子件 | 要改（成本最高） | 需要 GameCtrl.gameRunData、GameState.camera、EffectCtrl、SoundCtrl、FightSfx 五套替身，且 EffectCtrl 的 hideFightUI 是字符串动态访问；子件必须整组搬，单独搬 FightUI 只得空壳 |
| ui/mosou/MosouUI.as 加 21 个 mosou 子件 | 要改 | 需要 MosouCtrl、MosouStyle、KyoTimeout；子件都接受 _u:Number 构造参数，接口比 fight 干净 |
| ui/dialog 全套（BaseDialog/ConfrimUI/AlertUI/DialogManager） | 要改 | BaseDialog 契约可整搬（模板方法清晰），但 ConfrimUI 的视图是 StyleDialogView extends MovieClip（SWF 符号类），必须替换成自绘视图 |
| ui/TitleScreenUI.as、ui/VictoryUI.as、loading 全套 | 要改 | 依赖 Font.enumerateFonts（pickFont）、AssetManager.getFont("font1")、LoadingTheme；VictoryUI 122 处绘图记号，搬的是画法不是文件 |
| ui/bigmap 全套（WorldMapScreen/MapNodeView/WorldMapPointUI） | 搬不了（整体） | 依赖 collectAreas() 的地图数据与 MOSOU 关卡进度模型；自绘部分（MapNodeView 60 处、WorldMapScreen 33 处）可摘用 |
| ctrl/AdaptiveEngine.as | 能搬但无收益 | 对 UI 无效（shouldRenderOptionalEffect/effectScale 零调用点），只对效果生成量有意义 |

### 6.3 主项目会「因为用惯 SWF 元件」而搬不动的五处

1. 战斗 HUD 的实例名契约。3.3 的 ui/fight/FightUI.as（610 行）通过 fight_swf 的元件实例名取血条与气条，元件内部结构（层级、遮罩、帧标签）就是数据契约。3.7 的同名类是 9 个自绘 Sprite，两者**没有共同的中间表示**，只能整块替换，不能逐个对齐。

2. 主菜单按钮的中心注册。3.3 的 ui/MenuBtnGroup.as 注释明确记录了「mc_wzbtn 是中心注册的美术：按钮放在 x=24 时，按钮中心在 24，左半截会跑到屏幕外」，因此 layoutColumns 必须按背景条左缘补偿。3.7 的 MainMenuEntry 是左上注册（hit 矩形从 -8 开始画）。换成自绘后这套补偿全部作废，但**只要还留一个元件按钮，就得同时维护两套注册原点**。

3. 设置列表的滚动语义相反。3.3 的 ui/SetBtnGroup.as 是「自由滚动 + 索引跟随」：_arrowIndex 变化时 moveScroll() 用 getScrollIntoViewY(_arrowIndex) 把 scrollRect.y 补间到目标，且新增了 enableScrollDrag()（touchBegin/touchMove/touchEnd + 滚轮）。3.7 的 ui/OptList.as 是「索引驱动」：滚动位置由 _index*pitch 反算（var top:Number = _index*_pitch），没有自由滚动量。两者的 scrollRect.y 语义、拖拽门闸（DRAG_THRESHOLD_CM、_suppressTapOnce）全都不一样，**不能只换类名**。

4. 选人格的包装类判据。3.3 的 ui/select/SelectFighterItem.as 与 ui/MenuBtn.as 已经按 CLAUDE.md 的要求改成 _listeners[type] == null 判据 + 对称 removeEventListener + ui 空值守卫；3.7 的 ui/MenuBtn.as（A4）与 ui/select/SelectFighterItem.as 仍是老写法。从 3.7 往回搬这块等于回退已修的 bug。

5. 设置页的按键重映射视图。3.3 的 ui/SetCtrlBtnUI.as（263 行）与 3.7 的同名类（446 行）都取 keyset_mc，而 IInnerSetUI 接口（net/play5d/game/bvn/interfaces/IInnerSetUI.as:IInnerSetUI extends IEventDispatcher）在两版里都要求 EventDispatcher 语义。这一块是「元件 + 接口 + 全局设置状态」三合一，自绘化收益最低、风险最高。

## 7. 未实测清单

以下每一条都无法只靠读代码定论，需要标注的手段才能验。本轮没有运行 3.7 工程（参考目录只读，且无对应可运行产物），所有条目均为未验状态。

- [ ] 1. 152 个类在 3.7 实际运行时的观感是否与代码推算一致（尤其 MenuBtnGroup 的斜条遮罩裁字、MapSelectUI 的中心卡抬层）。手段：用 launch.swf / 对应 SWF 产物在 PC 上跑起来，逐屏截图比对。
- [ ] 2. A2（GameUI.initMission 的 as MosouUI 空转型）在真实流程里是否可达。手段：进无双模式跑一局、退到菜单、再进一局，观察是否抛 #1009；或在该行加日志。若首局即崩，说明还有我没读到的调用顺序。
- [ ] 3. VectorText 在手机与 PC 上的字形清晰度与笔画重叠情况（粗体时 thick 可到 th*0.17，笔画间隙 0.2 单位）。手段：真机 1080p 截图。
- [ ] 4. HDText 的 QUALITY=3 在大量字符串时的 BitmapData 峰值内存。手段：运行时 System.totalMemory 采样，或 ADL profiler 抓 BitmapData 分配。
- [ ] 5. FightUI 的 1066x600 双缩放在 4:3 与 21:9 屏上的实际裁切范围（_bounds 与 _pauseDialog 的遮罩都写死 1066x600）。手段：把 RootSprite 的各 screenMode 逐个跑一遍截图。
- [ ] 6. A5（GameRender 无异常隔离）造成的实际影响面。手段：给某个已注册的 UI render 注入一次抛错，观察同帧后续任务与画面。
- [ ] 7. GameUI.fadOut() 的实际调用者与线上表现（A1）。手段：全局检索调用点后用运行期日志确认是否真有人调。
- [ ] 8. mc_wzbtn 与 keyset_mc 的真实舞台结构（子元件名、帧数、注册点）。手段：反编译 common_ui_swf / setting_swf 的字节流，或运行期递归打印实例树。
- [ ] 9. AdaptiveEngine 的 level 在真机上是否真的会降级，以及降级对 UI 帧率的间接影响。手段：真机长时间跑战斗，读 performanceScore/frameStability。
- [ ] 10. MapSelectUI 滑动期间（每次 showMap 后约 0.2s）的连续点击是否会落到相邻卡（A8 之外的时序问题）。手段：真机快速连点，或用自动化脚本按帧注入点击。
- [ ] 11. 3.7 的 OptionsScreen 在 16 行以上的列表下是否也存在「滚不到最后一项」的问题（3.3 的 SetBtnGroup 有这个已修问题，3.7 的 OptList 语义不同）。手段：真机触控在设置页把列表翻到底，确认 APPLY 可点。
- [ ] 12. 本参考树的脚本与 3.7 原始二进制的对应关系（是否有反编译丢失的类或方法）。手段：拿到原始 FLA/SWF 或官方源码比对；本轮只有反编译树，无法验证完整性。

## 附录 A：152 个类逐个登记

统计口径说明：BASE 列取自类声明行（extends 与 implements），(none) 表示该类没有显式继承（占 76 个）。EVIDENCE 列是该文件里出现过什么写法的记号统计，由正则计数得出，只表示字面出现过该类代码，不表示运行时行为；- 表示九类记号全无（纯容器、纯逻辑或纯常量类）。G 后的数字是绘图记号出现次数（beginFill/beginGradientFill/lineStyle/lineTo/drawRect/drawCircle/drawEllipse/drawRoundRect/:Graphics 合计），g 表示 1 到 2 次。其余记号：

    G / g 矢量绘制    Bm new Bitmap    Bd new BitmapData    Tw TweenLite
    Swf 按名取 SWF 元件    Fr gotoAndStop 或 gotoAndPlay    Gr GameRender.add
    Ef Event.ENTER_FRAME    Sc scrollRect    Tc 触摸事件字符串

| CLASS | BASE | EVIDENCE | FILE |
|---|---|---|---|
| BigmapAtmosphere | Sprite | G22 | ui/bigmap/BigmapAtmosphere.as |
| BigmapClould | Sprite | - | ui/bigmap/BigmapClould.as |
| CloudView | (none) | Swf,Fr | ui/bigmap/CloudView.as |
| LeaderFace | (none) | G7,Bm,Bd | ui/bigmap/LeaderFace.as |
| MapNodeView | Sprite | G60 | ui/bigmap/MapNodeView.as |
| SlashButton | Sprite | G12 | ui/bigmap/SlashButton.as |
| WorldMapPointUI | EventDispatcher | Tw,Fr | ui/bigmap/WorldMapPointUI.as |
| WorldMapScreen | Sprite | G33,Ef,Sc | ui/bigmap/WorldMapScreen.as |
| BleachTransition | Sprite | G14,Bm,Bd,Ef | ui/BleachTransition.as |
| ChangelogPopup | (none) | G19,Tw | ui/ChangelogPopup.as |
| ContinueBtn | Sprite | - | ui/ContinueBtn.as |
| AlertUI | ConfrimUI | - | ui/dialog/AlertUI.as |
| BaseDialog | (none) | - | ui/dialog/BaseDialog.as |
| ConfrimUI | BaseDialog | - | ui/dialog/ConfrimUI.as |
| DialogManager | (none) | g1,Bd,Tw | ui/dialog/DialogManager.as |
| BigFaceUI | (none) | Tw | ui/dialog/mosou_state/BigFaceUI.as |
| MosouSelectDialog | BaseDialog | Swf | ui/dialog/MosouSelectDialog.as |
| MosouStateDialog | BaseDialog | Swf | ui/dialog/MosouStateDialog.as |
| DotItemUI | (none) | Swf,Fr | ui/dialog/select/DotItemUI.as |
| DotsGroupUI | Sprite | Tc | ui/dialog/select/DotsGroupUI.as |
| SelectFighterList | Sprite | g1,Bd,Tw,Sc | ui/dialog/select/SelectFighterList.as |
| SelectFighterUI | (none) | Swf,Fr | ui/dialog/select/SelectFighterUI.as |
| StyleDialogBase | Sprite | G27,Gr,Ef,Tc | ui/dialog/StyleDialogBase.as |
| StyleDialogView | MovieClip | G25,Gr,Ef | ui/dialog/StyleDialogView.as |
| AssistStrip | (none) | G15,Bd,Ef | ui/fight/AssistStrip.as |
| EnergyBar | (none) | g2 | ui/fight/EnergyBar.as |
| EnergyMiniBar | (none) | g2,Ef | ui/fight/EnergyMiniBar.as |
| FightAnnounce | Sprite | G29 | ui/fight/FightAnnounce.as |
| FightBar | (none) | - | ui/fight/FightBar.as |
| FighterHpBar | (none) | G3 | ui/fight/FighterHpBar.as |
| FightFaceGroup | (none) | G8 | ui/fight/FightFaceGroup.as |
| FightFaceUI | (none) | Bm,Sc | ui/fight/FightFaceUI.as |
| FightNotice | (none) | G26,Ef,Sc | ui/fight/FightNotice.as |
| FightQiBarMode | (none) | - | ui/fight/FightQiBarMode.as |
| FightRaster | (none) | Bm,Bd,Sc | ui/fight/FightRaster.as |
| FightSfx | (none) | - | ui/fight/FightSfx.as |
| FightSfxData | (none) | - | ui/fight/FightSfxData.as |
| FightText | Bitmap | Bd | ui/fight/FightText.as |
| FightTheme | (none) | G8 | ui/fight/FightTheme.as |
| FightTimeUI | (none) | G7 | ui/fight/FightTimeUI.as |
| FightUI |  / IGameUI | G4 | ui/fight/FightUI.as |
| FlameFx | (none) | G8,Bm,Bd | ui/fight/FlameFx.as |
| GlitchPulse | (none) | - | ui/fight/GlitchPulse.as |
| HitBgTrigger | (none) | - | ui/fight/HitBgTrigger.as |
| HitsUI | (none) | G9 | ui/fight/HitsUI.as |
| InkFx | (none) | G36,Bm,Bd | ui/fight/InkFx.as |
| KoBgFx | (none) | G14,Ef,Sc | ui/fight/KoBgFx.as |
| LowHpFx | (none) | G32,Bm,Bd | ui/fight/LowHpFx.as |
| MiniHpBar | (none) | G16 | ui/fight/MiniHpBar.as |
| PlayerMarker | Sprite | G9 | ui/fight/PlayerMarker.as |
| QiBar | (none) | G39,Ef | ui/fight/QiBar.as |
| SpiritAura | (none) | G3,Bm,Bd,Ef | ui/fight/SpiritAura.as |
| SpiritBar | (none) | G5,Ef | ui/fight/SpiritBar.as |
| SpiritBarFx | (none) | - | ui/fight/SpiritBarFx.as |
| SpiritBurst | (none) | G31,Ef | ui/fight/SpiritBurst.as |
| SpiritDrive | (none) | Ef | ui/fight/SpiritDrive.as |
| TagBgFx | (none) | G24,Bm,Bd,Ef,Sc | ui/fight/TagBgFx.as |
| VText | Shape | G5 | ui/fight/VText.as |
| GamePadArt | Sprite | G46 | ui/GamePadArt.as |
| GameUI | (none) | - | ui/GameUI.as |
| IGameUI | (none) | - | ui/IGameUI.as |
| KeyMapping | (none) | - | ui/KeyMapping.as |
| BladeBar | Sprite | G56 | ui/loading/BladeBar.as |
| BleachBackground | Sprite | G44 | ui/loading/BleachBackground.as |
| ConfirmInput | (none) | - | ui/loading/ConfirmInput.as |
| FighterBrief | (none) | - | ui/loading/FighterBrief.as |
| FighterCard | Sprite | G30 | ui/loading/FighterCard.as |
| GlitchTitle | Sprite | Bm | ui/loading/GlitchTitle.as |
| LoadingScreenUI | Sprite | G75,Ef,Tc | ui/loading/LoadingScreenUI.as |
| LoadingTheme | (none) | - | ui/loading/LoadingTheme.as |
| LoadingUIConfig | (none) | - | ui/loading/LoadingUIConfig.as |
| LoadingView | Sprite | G17,Bm,Bd,Ef,Sc | ui/loading/LoadingView.as |
| MissionBrief | (none) | - | ui/loading/MissionBrief.as |
| MissionCard | Sprite | G41 | ui/loading/MissionCard.as |
| RasterText | Sprite | Bm,Bd | ui/loading/RasterText.as |
| VersusArtSide | Sprite | G4,Bm,Bd,Sc | ui/loading/VersusArtSide.as |
| VersusFighter | (none) | - | ui/loading/VersusFighter.as |
| VersusLoadingUI | Sprite | G53,Bm,Bd,Ef,Sc | ui/loading/VersusLoadingUI.as |
| VersusText | (none) | Bm,Bd | ui/loading/VersusText.as |
| VerticalMarquee | Sprite | g2,Bd,Sc | ui/loading/VerticalMarquee.as |
| MenuBtn | EventDispatcher | Tw,Swf,Fr | ui/MenuBtn.as |
| MenuBtnGroup | Sprite | G80,Bm,Tw,Gr,Tc | ui/MenuBtnGroup.as |
| CoinUI | (none) | Fr | ui/mosou/CoinUI.as |
| BossHpUI | (none) | - | ui/mosou/enemy/BossHpUI.as |
| EnemyHpFollowUI | (none) | - | ui/mosou/enemy/EnemyHpFollowUI.as |
| EnemyHpUI | (none) | - | ui/mosou/enemy/EnemyHpUI.as |
| EnemyHpUIGroup | (none) | - | ui/mosou/enemy/EnemyHpUIGroup.as |
| LittleHpBar | (none) | - | ui/mosou/LittleHpBar.as |
| MosouBanner | Sprite | G11,Sc | ui/mosou/MosouBanner.as |
| MosouBossBar | Sprite | G4 | ui/mosou/MosouBossBar.as |
| MosouEnemyBars | Sprite | g1 | ui/mosou/MosouEnemyBars.as |
| MosouEnergyBar | (none) | Fr | ui/mosou/MosouEnergyBar.as |
| MosouEnergyMeter | Sprite | G4 | ui/mosou/MosouEnergyMeter.as |
| MosouFace | (none) | G7,Bm,Bd | ui/mosou/MosouFace.as |
| MosouFightBarUI | (none) | - | ui/mosou/MosouFightBarUI.as |
| MosouHitsCounter | Sprite | g1 | ui/mosou/MosouHitsCounter.as |
| MosouHpBar | (none) | - | ui/mosou/MosouHpBar.as |
| MosouHpMeter | Sprite | G8 | ui/mosou/MosouHpMeter.as |
| MosouInfoStrip | Sprite | G13 | ui/mosou/MosouInfoStrip.as |
| MosouPlayerPanel | Sprite | G4 | ui/mosou/MosouPlayerPanel.as |
| MosouQiBar | (none) | Fr | ui/mosou/MosouQiBar.as |
| MosouQiMeter | Sprite | G4 | ui/mosou/MosouQiMeter.as |
| MosouStyle | (none) | G15 | ui/mosou/MosouStyle.as |
| MosouTimeUI | (none) | - | ui/mosou/MosouTimeUI.as |
| MosouUI |  / IGameUI | - | ui/mosou/MosouUI.as |
| MosouWaveUI | (none) | Bm | ui/mosou/MosouWaveUI.as |
| MousouKOsUI | (none) | - | ui/mosou/MousouKOsUI.as |
| MosouPauseDialog | Sprite | - | ui/MosouPauseDialog.as |
| MoveListSp | Sprite | G81,Gr,Ef,Sc,Tc | ui/MoveListSp.as |
| OptionsData | (none) | - | ui/OptionsData.as |
| OptionsScreen | Sprite | G7,Gr,Ef | ui/OptionsScreen.as |
| OptKit | (none) | G56 | ui/OptKit.as |
| OptList | Sprite | Gr,Ef,Sc | ui/OptList.as |
| OptRow | Sprite | G17 | ui/OptRow.as |
| PauseDialog | Sprite | - | ui/PauseDialog.as |
| PauseMenuUI | Sprite | G29,Gr,Ef | ui/PauseMenuUI.as |
| QuickTransUI | BleachTransition | - | ui/QuickTransUI.as |
| FighterCardView | Sprite | G38,Tw,Ef | ui/select/FighterCardView.as |
| FighterIdleLoader | (none) | Fr,Ef | ui/select/FighterIdleLoader.as |
| FighterIdleView | Sprite | Bd,Tw,Ef | ui/select/FighterIdleView.as |
| FighterTile | Sprite | G19,Tw | ui/select/FighterTile.as |
| HDText | Sprite | Bm,Bd | ui/select/HDText.as |
| MapSelectUI | Sprite | G43,Tw,Ef,Sc,Tc | ui/select/MapSelectUI.as |
| SelectBackButton | Sprite | G33,Tw,Ef,Tc | ui/select/SelectBackButton.as |
| SelectBackdrop | Sprite | G70,Bm,Bd,Tw,Ef | ui/select/SelectBackdrop.as |
| SelectCursor | Sprite | G16,Tw,Ef | ui/select/SelectCursor.as |
| SelectedFighterGroup | Sprite | Tw | ui/select/SelectedFighterGroup.as |
| SelectedFighterUI | EventDispatcher | Tc | ui/select/SelectedFighterUI.as |
| SelecterItemUI | (none) | - | ui/select/SelecterItemUI.as |
| SelectFighterItem | EventDispatcher | Tw | ui/select/SelectFighterItem.as |
| SelectFx | (none) | - | ui/select/SelectFx.as |
| SelectIndexArrow | Sprite | G8,Ef | ui/select/SelectIndexArrow.as |
| SelectIndexUI | Sprite | - | ui/select/SelectIndexUI.as |
| SelectIndexUIGroup | Sprite | Tw,Gr,Tc | ui/select/SelectIndexUIGroup.as |
| SelectStyle | (none) | G14,Bm,Bd | ui/select/SelectStyle.as |
| SelectText | Sprite | Bm,Bd,Tw,Sc | ui/select/SelectText.as |
| SelectTransition | Sprite | G17,Tw | ui/select/SelectTransition.as |
| SelectUIFactory | (none) | - | ui/select/SelectUIFactory.as |
| SetBackdrop | Sprite | G41,Ef | ui/SetBackdrop.as |
| SetBtn | Sprite | G31,Ef | ui/SetBtn.as |
| SetBtnDialog | (none) | G13,Tw | ui/SetBtnDialog.as |
| SetBtnGroup | Sprite | - | ui/SetBtnGroup.as |
| SetBtnLine | Sprite | g2,Tw | ui/SetBtnLine.as |
| SetCtrlBtnUI | EventDispatcher / IInnerSetUI | Tw,Swf | ui/SetCtrlBtnUI.as |
| SetUIKit | (none) | G28 | ui/SetUIKit.as |
| SkewBtn | Sprite | G18,Tc | ui/SkewBtn.as |
| Text | BitmapText | - | ui/Text.as |
| TitleScreenUI | Sprite | G43,Bm,Bd,Ef,Sc | ui/TitleScreenUI.as |
| TransUI | (none) | - | ui/TransUI.as |
| UIUtils | (none) | - | ui/UIUtils.as |
| VictoryUI | Sprite | G122,Bm,Bd,Ef | ui/VictoryUI.as |
| WinUI | (none) | Fr | ui/WinUI.as |

## 附录 B：可复用契约清单（抄这些，不抄那 152 个类）

按「拿走即用」排序，每条给唯一代码锚点。这份清单是本册交付物本体，附录 A 只是索引。

1. 页面骨架四拍：build 建树、上舞台、afterBuild 再挂 stage 监听与帧任务、destory 反序拆。锚点 net/play5d/kyo/stage/Istage.as:Istage，样板 state/MenuState.as:MenuState.build()。
2. HUD 双帧率契约：render 管数值、renderAnimate 管美术、按 ceil(FPS_GAME/30) 跳帧。锚点 ui/IGameUI.as:IGameUI 与 ui/GameUI.as:GameUI.isRenderAnimate()。
3. 弹窗模板方法：final 包办显隐与销毁，子类只填钩子。锚点 ui/dialog/BaseDialog.as:BaseDialog；配套 ui/dialog/DialogManager.as:DialogManager.showDialog()（挂全局 root，天然最高层）。
4. 输入闸门三连：未建完、enabled 为假、GameUI.showingDialog() 为真，各 return 一次。锚点 ui/MenuBtnGroup.as:MenuBtnGroup.render() 的前三个 if。
5. 动效期间关输入：起手置 GameInputer.enabled=false，补间 onComplete 里置回 true。锚点 state/SelectFighterStage.as:SelectFighterStage.initMap()。
6. 索引光标三连：moveSel(dir) 用 (i+dir+n)%n 环绕、syncSelected() 批量刷选中态、updateDesc() 刷描述。锚点 ui/MenuBtnGroup.as:MenuBtnGroup.moveSel()。
7. 触摸首点只选中：isTouch 且 wasSel 为假则 return，把预览与确认分到两次点击。锚点 ui/MenuBtnGroup.as 内嵌 MainMenuEntry.tapped() 与会话层 activateHandler()。
8. 触摸与鼠标互斥：记 _lastTouch，三处鼠标回调先判 getTimer()-_lastTouch < 600。锚点 MainMenuEntry.onMouseOver()/onMouseDown()/onMouseClick()。
9. 动画绑舞台进出：ADDED_TO_STAGE 挂 ENTER_FRAME、REMOVED_FROM_STAGE 摘，页面在内存里也不空转。锚点 ui/select/MapSelectUI.as:MapSelectUI.onAdded()/onRemoved()。
10. BitmapData 记账：造即 push、拆时逐张 dispose、换文本先 dispose 旧图。锚点 ui/TitleScreenUI.as:TitleScreenUI.makeText()/dispose()，单体样板 ui/select/HDText.as:HDText.render()。
11. 贴图 cover 加 scrollRect 裁切加按 id 缓存：一次裁好，之后只搬 DisplayObject。锚点 ui/select/MapSelectUI.as:MapSelectUI.getPic()。
12. 主题收口：颜色与线宽进一套 static const（3.7 分了六套，移植时合成一套）。锚点 ui/fight/FightTheme.as:FightTheme；斜切几何复用 ui/select/SelectStyle.as:SelectStyle.slantPath()，多边形复用 ui/mosou/MosouStyle.as:MosouStyle.para()。
13. 可 seek 的动画：整段写成 t 的纯函数 renderAt(t)，宿主每帧 tick(dtMs) 并夹住 dt。锚点 ui/mosou/MosouBanner.as:MosouBanner.renderAt()/tick()。
14. 控制反转的命中装配：prev/next/confirm 由外部注入，控件只分派 currentTarget。锚点 ui/select/MapSelectUI.as:MapSelectUI.addMouseEvents()（注意 A8 不幂等，移植要加守卫）。
15. 超采样位图文字：字号乘 3 画进 BitmapData 再缩到 1/3，浅色字自动描边。锚点 ui/select/HDText.as:HDText.render()，竖排变体 ui/select/SelectStyle.as:SelectStyle.verticalName()。

不要抄的四处（原因见第 5 节）：ui/GameUI.as:GameUI.fadOut()、ui/GameUI.as:GameUI.initMission()、ui/MenuBtn.as:MenuBtn.addEventListener() 的判据与 removeAllEventListener、以及把 VectorText 用在含中文的文案上。
