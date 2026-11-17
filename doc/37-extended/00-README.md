# BVN 3.7 扩展版参考 — 拆解文档集

> 本目录是「3.7 扩展版参考源码」的**拆解与移植参考**，不是 3.7 的项目说明，也不是主项目的开发手册。
> 主项目事实见 [`CLAUDE.md`](../../CLAUDE.md)；文档总索引见 [`doc/README.md`](../README.md)。

---

## 0. 目标 / 约束 / 冲突后的优先级

**目标**：回答三个问题——① 3.7 里有什么是主项目没有的；② 那些东西是怎么实现的（讲到 `类.方法()` 一级）；③ 要搬的话代价是什么、会不会碰坏主项目已有能力。

**约束**：

| # | 约束 | 理由 |
|---|---|---|
| 1 | 源码基准只读：`BVNscripts/3.7扩展版参考/` 整目录已被 `.gitignore` 忽略，不改、不提交 | 380.8MB 参考资产（2024 张 png / 27 个 mp3 / 20 张地图），是本地参考代码 |
| 2 | 所有类名、方法名、字段名必须能在源码里 grep 到 | 反编译代码容易被「想当然」写错 |
| 3 | 行号一律不写死，只写 `路径:类.方法()` | 反编译重编后行号必漂，写死等于制造过期引用 |
| 4 | 推不出的行为进各册「未实测清单」，正文不许出现软断言 | 文档一旦把猜测当事实，后面所有决策都会歪 |

**冲突后的优先级**：`用户当前指令` > `本目录各册的实测结论` > `旧稿（已删除，见 §6）` > `其它二手描述`。
如果某条结论与主项目 `CLAUDE.md` 冲突，以**能跑起来的代码**为准，并回头修正文档。

---

## 1. 事实基线

| 项 | 值 | 取证方式 |
|---|---|---|
| 版本标识 | `V3.7` / `2021.10.14` | `MainGame.as:46`、`MainGame.as:50` |
| 代码规模 | 整目录 **570 个 `.as`**，其中业务代码 `scripts/net/play5d/` 下 **442 个** | 文件计数 |
| 主项目规模 | `BVNscripts/scripts/net/play5d/` 下 **254 个 `.as`** | 文件计数 |
| 代码性质 | AS3 **反编译产物 + 人工后处理**（局部变量名被重命名，方法与字段原名保留） | 抽样阅读 + 旧稿声明 |
| 资源 | 20 张 JSON 地图（每张一个 `stage.json` + 一份 `audit.txt`）、embed 包装类 60 余个、config 9 个 xml | 目录清点 |
| 可编译性 | **未验证编译**（无 fla / 入口工程）。静态全树解析 570 个 `.as`：`net.play5d.*` 仅 **13 处 import 未解析**，全部集中在 4 个 LAN 文件；`kyo` 包 28 个类（反而多于主项目 24 个）。真正的缺口在外部库：`com.game.ttads.TTAdManager` 两棵树都没有、`com.adobe.crypto` / `com.hurlant` 只有本树有 | 全树 import 解析 + 目录比对 |

### 1.1 路径变迁（读旧资料前必看）

早先的资料（含已删除的 `PROJECT_DOC.md`）称源码在 `3.7扩展版参考/Shonen-Clash-main/`、规模 308 个 `.as`。
**现状是源码平铺在 `3.7扩展版参考/scripts/`，442 个业务类 + 570 个总计**。凡按 `Shonen-Clash-main/` 去找文件的旧描述，一律作废。

---

## 2. 与主项目的关系

两边是**同一个游戏的不同分支**，差异是双向的：

| 方向 | 数量 | 含义 |
|---|---|---|
| 3.7 独有 | **227 个类**（ui 116 / mob 32 / data 21 / utils 14 / ctrl 13 / net 5 / map 5 / video 4 / fighter 4 / 其它 8） | 潜在可移植能力 |
| 主项目独有 | **39 个类** | **别覆盖清单**：TAG 换人、GPU 滤镜代理 6 个、ANE 封装、LAN socket 全家、`RuleState`、`Debugger` 等 |

> ⚠️ 移植时最容易出事的不是「3.7 缺什么」，而是**拿 3.7 的文件去覆盖主项目同名文件**。
> 逐类清单见 [`01-diff-inventory.md`](01-diff-inventory.md) §4.2「别覆盖清单」、§4.3「同名陷阱」。
>
> 另一个反直觉结论：**227 个独有类是「闭合岛，但不是孤岛」**——它们对 `net.play5d.*` 的未解析 import 为 0，主项目也没有任何引用，但 3.7 用 5 个共享文件把新子系统挂进引擎：
> `GameCtrl→MosouCtrl`、`GameUI→MosouUI`、`GameLoader`/`EffectCtrl→JsonMapMain`、`MainGame→WorldMapState`。
> 所以「只把 227 个类拷过去」搬不动，必须连这 5 个挂载点一起改。

---

## 3. 五册导航

| 册 | 回答什么问题 | 关键类 |
|---|---|---|
| [`01-diff-inventory.md`](01-diff-inventory.md) | 到底差哪些类？哪些值得拆、哪些是胶水、哪些别碰 | 227 + 39 全量清单 |
| [`02-camera.md`](02-camera.md) | 相机怎么跟随/缩放/钳制/震屏；3.7 单类 vs 主项目三件套 | `state/GameCamera.as` |
| [`03-json-map.md`](03-json-map.md) | 特殊格式地图：MUGEN stage 怎么变成 `stage.json`、渲染器怎么画 | `map/JsonMapLoader`、`JsonLayerRenderer`、`JsonStageFx` |
| [`04-selfdrawn-ui.md`](04-selfdrawn-ui.md) | 代码自绘 UI 的分层与契约：**145/152 纯自绘**，另 7 个类按名取 SWF 子元件 | `ui/MenuBtnGroup`、`MapSelectUI`、`FightUI`、`utils/ResUtils` |
| [`05-gamepad-continue.md`](05-gamepad-continue.md) | 手柄四实现路由 + 改键 UI + 局内重开的重置链 | `input/GameInputer`、`mob/input/JoySticker`、`GamePadSetUI` |
| [`06-updater.md`](06-updater.md) | 自动更新：查版本、下载、替换、失败重试 | `utils/GithubUpdater`、`UpdateManager`、`mob/ctrls/UpdateCtrl` |
| [`glossary.md`](glossary.md) | 本套文档的黑话对照表 | — |

---

## 4. 怎么用

**人读**：每册第 1 节是「一句话结论」，第 2 节是术语，读完这两节就能判断这事要不要关心；
关心了再进第 4 节看机制，最后看第 6 节「移植可行性」决定做不做。

**AI 读 / 检索**：

- 按类名检索：`grep -r "JsonLayerRenderer" doc/37-extended/`，每册引用格式统一为 `相对路径:类.方法()`；
- 要改主项目之前，先读 `01-diff-inventory.md` 第 3 节，确认目标文件不在「别覆盖清单」里；
- 各册第 7 节「未实测清单」里的条目**不可当作已知事实**继续推演。

**引用路径的基准**：除特别说明，路径均相对 `BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/`。

---

## 5. 不在本套文档里

下面这些已有专门文档，本套不重复：

| 主题 | 去哪 |
|---|---|
| 主项目架构、ANE 现状、构建方式 | [`CLAUDE.md`](../../CLAUDE.md) |
| 触控/设置界面/受击状态机等踩坑 | [`doc/runtime-pitfalls.md`](../runtime-pitfalls.md) |
| CRAZY 难度移植（源同为本参考工程） | [`doc/crazy-ai/crazy-ai.md`](../crazy-ai/crazy-ai.md) |
| 3.8 独立规则页 | [`doc/38-rule-stage/`](../38-rule-stage/) |
| 全量文档索引 | [`doc/README.md`](../README.md) |

打斗判定、战斗数值、LAN 联机、事件系统这些**框架层**内容不在本套五册里：
它们属于「3.7 与主项目共有」的部分，主项目自己的实现才是基准，读 3.7 的没有增量价值。

---

## 6. 维护约定

- 本目录取代了两份旧稿（`PROJECT_DOC.md` 109KB、`3.7扩展-局内重开与手柄适配实现参考.md` 52KB）。
  旧稿内容已被 01~06 册吸收并**逐条回代码复核**，故不再保留；删除前已存 `.backup/`。
- 新增结论只改对应册，不新开文件；册的顺序即推荐阅读顺序。
- 若 3.7 参考目录被替换成新快照，先重跑 `01-diff-inventory.md` 的比对方法，再逐册核对 §3 的类清单。
- 改动本目录后同步登记 [`doc/README.md`](../README.md)。

---

_建立于 2026-11-17。基线 commit `540f7dd`，快照 tag `snapshot/pre-37ext-docs-20261117`。_
