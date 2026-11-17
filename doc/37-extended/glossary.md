# 术语表（3.7 扩展版参考）

> 收录判据：**在 3.7 里这个词有特定含义，或与主项目容易混淆**。通用 AS3 词汇不收录。
> 每个词给出「本套文档的用法 → 代码对应物 → 去哪本册看细节」。

---

## A. 跨册通用

| 术语 | 含义 | 代码对应物 | 出自 |
|---|---|---|---|
| 三分支 | 主项目 `scripts/`、3.7 参考、3.9 官方重构版，是同一游戏的不同分支，不是三个项目 | — | 00 |
| 参考树 / 参考目录 | `BVNscripts/3.7扩展版参考/`，整目录被 gitignore，只读 | — | 00 |
| 闭合岛 | 3.7 独有的 227 个类：对 `net.play5d.*` 未解析 import 为 0，主项目也无任何引用 | 全树比对 | 01 |
| 挂载点 | 让「闭合岛」接进引擎的共享文件，共 5 处：`GameCtrl→MosouCtrl`、`GameUI→MosouUI`、`GameLoader`/`EffectCtrl→JsonMapMain`、`MainGame→WorldMapState` | 见 01 §2 | 01 |
| 别覆盖清单 | 主项目独有的 39 个类。拿 3.7 同名文件覆盖会毁掉 TAG 换人 / GPU 滤镜代理 / ANE / LAN / Debugger | 见 01 §4.2 | 01 |
| 同名陷阱 | 两树路径相同但实现差异大的文件（如 `state/GameCamera.as` 807 行 ↔ 413 行） | 见 01 §4.3 | 01 |
| 评级三档 | 值得拆 / 胶水 / 别碰 —— 01 册对 227 个独有类的人工评级 | 66 / 70 / 91 | 01 |
| `destory` | **故意保留的错拼**，不是笔误。改名会断掉全树调用链 | `GameCtrl.destory()` 等 | 00 |
| 无双 / mosou | 3.7 独有的清版玩法。3.7/主项目拼 `Mosou`，3.9 官方改成 `Musou` —— 搜代码时两种都要试 | `ui/mosou/**`、`MosouCtrl` | 01 |

---

## B. 相机（02 册）

| 术语 | 含义 | 代码对应物 |
|---|---|---|
| 相机 | 不是 `Camera` 对象，而是每帧把焦点包围盒算成容器 `scrollRect` + `scale` 的几何计算器 | `state/GameCamera.as` |
| 宿主 / stage | 被相机改写的那个容器，**不是** Flash 的 `Stage` | `GameState._gameLayer` |
| 视口矩形 | 相机此刻看到的世界矩形，等于 `scrollRect` | `_rect` / `_noTweenRect` / `_displayRect` |
| `_zoom` vs `_stageScale` | 目标缩放 vs 当帧真正写上去的缩放（带缓动） | `getZoom()` / `getZoom(true)` |
| 留白 | 焦点允许贴边的比例，防止角色被切边；主项目用写死的 `*0.8` 近似 | `keepFocusInFrame()`、`framePaddingX/Headroom/Footroom` |
| `_fbR` | 「边界矩形」，但字段名与用途不符（其 `width/height` 被当成最大 x/y 用） | `GameCamera._fbR` |
| trauma | 震屏剂量 0~1，线性衰减，振幅取平方 | `_trauma`、`trauma` |
| punchZoom | 打击冲击缩放，弹簧系统叠在 `_stageScale` 上 | `_punchZoomOffset/Vel` |
| 电影锁 | 一次性锁住「单人自动缩放 + 留白钳制 + 缩放减速」三处行为 | `_cinematicLock`、`isCinematic` |
| owner / 发起方 | 谁摆的镜头：引擎、必杀、人物包自己。**主项目独有概念** | `FOCUS_OWNER_ENGINE/BISHA` |
| 门面 | 只做空判 + 转发的语义化包装，不含策略 | `ctrl/game_ctrls/GameCameraCtrler.as` |
| 看门狗 | 每帧判断「必杀特写该收回了吗」，收回即回调。**主项目独有** | `state/GameCameraFocusWatch.as` |

---

## C. 特殊格式地图（03 册）

| 术语 | 含义 | 代码对应物 |
|---|---|---|
| JSON 关卡 / stage.json | 每个地图目录一份的关卡描述，由 MUGEN stage `.def` 转换而来 | `assets/assets/maps/<名>/stage.json` |
| audit.txt | 转换器的自检报告：BG 层数比对、帧特性统计、`NOT SUPPORTED` 清单、运行时报文 | 同目录 |
| `layers` | 顶层唯一硬必填键；其余 11 个键里 `format`/`info` 无人读 | `JsonMapMain` |
| 层类型 | 只有 `parallax` 会改变绘制分支，`anim` 与 `normal` 走同一路径 | `JsonLayerRenderer.draw()` |
| `layerno` | MUGEN 的前后景标记（0 背景 / 1 前景） | 78 层 `layerno==1` |
| `deltaX/deltaY` | MUGEN 视差系数 | 见 03 §4.7 的 `zsx` 算式 |
| `tileX/tileY` | 平铺开关；视差层另由 `repeatX = tileX!=0 \|\| xshear!=0` 判定 | `drawTiled` / `drawParallax` |
| `trans as` | MUGEN 的加算合成写法（`AS<alpha><dest>`） | `JsonStageFx.applyTrans()` |
| addalpha | `AS` 且目标 alpha < 250 的组合；3.7 用「NORMAL + 提亮 + cover」近似 | `JsonStageFx.a256/isAdditiveAS` |
| `interpolate blend` | 插值混合，全树仅 4 处使用 | `JsonStageFx` |
| v2.5 runtime patch | 地图渲染器的两代行为差异：旧版把 addalpha 画成黑纱、把未平铺视差层重复铺满整屏 | `JsonStageFx` / `JsonLayerRenderer` |
| 时间 0 帧 | MUGEN 会用「停留 0 帧」表达瞬切，转换器直接跳过；这是已知视觉差异来源 | audit.txt |

---

## D. 自绘 UI（04 册）

| 术语 | 含义 | 代码对应物 |
|---|---|---|
| 自绘 | 运行时用 Graphics 描边填色、用 BitmapData 出图，**不摆美术元件** | 152 个 `ui/` 类全部符合 |
| 元件 | Flash 库里拖出来的 MovieClip，带帧和实例名（主项目的常态） | `ui/MenuBtn.as` 的 `ui` 字段 |
| 按名取件 | 从已加载 SWF 里按字符串取子元件，编译期不检查 | `utils/ResUtils.as:ResUtils.createDisplayObject(Class, String)` |
| 页面 | 一整屏界面：实现 `Istage` 的 state，或自成体系的 Sprite | `state/MenuState.as`、`ui/select/MapSelectUI.as` |
| 层 | 页内为分离 z 序而建的 Sprite 容器 | `MenuBtnGroup._bgLayer/_artLayer/...` |
| 基元 | 一个可点、可选中、可自绘的最小控件 | `ui/MenuBtnGroup.as` 内的 `MainMenuEntry` |
| 套件 | 一束 static 常量 + static 绘制函数，充当主题与画具 | `ui/fight/FightTheme.as`、`ui/mosou/MosouStyle.as` |
| 单位 u | 以 800×600 为基准的整体缩放因子 | `MosouStyle.unit()` |
| 镜像坐标 | 左方坐标写一遍，右方按 `VW - x - w` 反算 | `FightTheme.mx()/mrect()` |

---

## E. 输入与局内重开（05 册）

| 术语 | 含义 | 代码对应物 |
|---|---|---|
| `IGameInput` | 输入实现契约；接口层**不表达「抬起」**，边沿三态靠第三参 | `input/IGameInput.as` |
| 通道 | 三条输入通道 `MENU / P1 / P2`，每条里放 `Vector.<IGameInput>`，列表顺序即优先级 | `input/GameInputer.as` |
| 死树 | 写了但零引用的整棵代码（`GameInputRouter` + `GameInputFocus`），别当成「第二条切换路径」 | `mob/input/GameInputRouter.as` |
| 改键 UI | 17 行映射表 + 临时副本 + Apply 才写回的录制界面 | `mob/views/GamePadSetUI.as` |
| `QUICK_RESTART` | 只活一次调用的静态开关，让新建的 `LoadingState` 跳过片头 | `state/LoadingState.as` |
| 局内重开（3.7 义） | **销毁整局重建**：`LoadingState.restartBattle()` → 重新加载 → `doStartGame` | `state/LoadingState.as` |
| 局内重开（主项目义） | **原地逐项复位**：`GameCtrl.restartBattle()` + `isResetting` 闸门 | 主项目 `ctrl/game_ctrls/GameCtrl.as` |
| 续关 | 街机败北后的 YES/NO，YES 扣 10000 分再回选人；与「局内重开」**不是一回事** | `state/GameOverState.as:showContinue()` |

### E.1 四个「Continue」不是一个东西

| 名字 | 是什么 | 位置 |
|---|---|---|
| `ContinueBtn` | 回合结束后屏幕上那个「继续」按钮 | `ui/ContinueBtn.as` |
| `GameOverState.showContinue()` | 街机模式败北续关（扣分） | `state/GameOverState.as` |
| `VersusLoadingUI.showContinue()` | 加载完「按任意键继续」 | `ui/loading/VersusLoadingUI.as` |
| 局内重开 | 把当前这局重置到开局可操作状态（**本册专题**） | 3.7 见上；主项目 `GameCtrl.restartBattle()` |

---

## F. 自动更新（06 册）

| 术语 | 含义 | 代码对应物 |
|---|---|---|
| 更新检查 | 启动后向 GitHub 询问是否有新版本 | `utils/GithubUpdater.as` |
| 分块下载 | `URLStream` 边下边写 `FileStream`，带停摆超时重试 | `_dlStallTimer` / `_dlTmp` |
| 版本三元组 | `VERSION` / `VERSION_LABEL` / `VERSION_DATE` | `MainGame.as` |

---

## G. 本套文档**不**覆盖的词

下面这些词属于「3.7 与主项目共有」的框架层，读 3.7 没有增量价值，请回主项目文档：

| 词 | 去哪 |
|---|---|
| 判定面 / `atm` 前缀 / hitbox | [`doc/runtime-pitfalls.md`](../runtime-pitfalls.md)、[`doc/_api_doc.txt`](../_api_doc.txt) |
| 受击僵直 / 灵爆 / 替身术 | [`doc/runtime-pitfalls.md`](../runtime-pitfalls.md) §7 |
| AI 难度 / CRAZY | [`doc/crazy-ai/crazy-ai.md`](../crazy-ai/crazy-ai.md) |
| TAG 换人 | [`doc/tag-mode/`](../tag-mode/) |
| GPU 滤镜代理 | [`doc/gpu-filter-proxy.md`](../gpu-filter-proxy.md) |

---

_建立于 2026-11-17。新增术语请补进对应组，并标出出自哪本册。_
