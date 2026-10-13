# BVN 项目开发手册

## 目标与边界

本项目是 ActionScript 3 / AIR 游戏。可编译源码基准为 `BVNscripts/scripts/`；参考目录只用于阅读比对，不作为提交源。生成的 APK、SWF、ANE、测试资源和 `.backup/` 保留本地，APK 仅作为 GitHub Release 附件。

所有回答和提交说明使用中文。修改前先在 `.backup/` 建立带时间戳副本；不删除用户文件；每次源码修改后运行 `./build.bat`。

## 关键源码

| 模块 | 文件 |
|---|---|
| 资源统一加载 | `BVNscripts/scripts/net/play5d/game/bvn/ctrl/AssetLoader.as`、`AssetManager.as` |
| 外部扫描与配置合并 | `BVNscripts/scripts/net/play5d/game/bvn/ctrl/GameLoader.as`、`data/GameData.as` |
| Android 文件封装 | `BVNscripts/scripts/net/play5d/game/bvn/mob/utils/ANEFileReader.as` |
| ANE Java/AS3 | `extensions/BVNFileReader/` |
| Android 打包 | `tools/Test/application.xml`、`tools/script/debug_mob.bat` |
| 迁移设计与用户资料 | `doc/external-fighter-37/` |

## 文档地图（AI 检索入口）

**全部文档已收拢到 `doc/`；根目录只保留 `CLAUDE.md` / `AGENTS.md` / `README.md` 三个入口。**
**详细索引（含每个文件用途 + 「按主题快速定位」表）见 [`doc/README.md`](doc/README.md) —— 找文档先读它。**

```text
doc/
├── README.md                  ← 文档总索引（先读）
├── AI-SYSTEM-DOC.md           PC 分支 AI 系统说明〔历史文档，基准路径已失效〕
├── architecture.md            工程结构 / 模块清单 / 路径依赖图
├── ane-dev-guide.md           ANE 开发指南
├── runtime-pitfalls.md        运行时踩坑速查〔改移动端前必读〕
├── _api_doc.txt               类与方法签名速查 dump
├── 38-rule-stage/             3.8 独立规则设置界面（rule-stage.md 详解 / plan.md 移植计划）
├── ane/                       ANE 专题（proposal / high-level / detailed / tasks）
├── crazy-ai/crazy-ai.md       手机端主项目 CRAZY 难度移植记录〔重点〕
├── external-fighter-37/       外置人物迁移（设计 + tasks + template-package）
├── jingji/                    竞技项（设计 + tasks t1…t7）
├── kai-chang/                 开场（proposal + tasks）
├── adr/                       架构决策记录（原 docs/adr 并入）
├── plans/                     实施计划
└── archive/                   归档：过时 / 重复 / 第三方 / 日志（archive/logs/ 为构建日志）
```

不在 `doc/` 下但常用的文档：

| 路径 | 用途 |
|---|---|
| `BVNscripts/scripts/REGRESSION_TEST_MATRIX_BATCH6.5.md` | 选人人物子框回归矩阵（改 `SelectFighterItem` / `SelectFighterStage` / `SelectStageConfigVO` / `MenuBtn` 须同步刷行号） |
| `BVNscripts/3.8竞技参考/竞技改代码/CLAUDE.md` | 3.8 竞技版参考代码索引（只读参考） |
| `tools/Test/_report/` | 真机诊断报告（如 ANE 诊断报告） |
| `tools/skills-1.2.3/` | 第三方技能包（非本项目文档，原样留存） |

**文档维护约定**：新文档一律进 `doc/`（**不要再建顶层 `docs/`**）；新增或移动后同步更新 `doc/README.md` 与上表；过期但仍有参考价值的文档移入 `doc/archive/` 而不是删除；构建日志（`build_output.txt`、`mob_*.log`）属临时产物，留档时放 `doc/archive/logs/`。

## 参考工程索引与专题文档

| 内容 | 文档 |
|---|---|
| 3.8 竞技版参考代码索引（AI 进入该目录会自动加载） | `BVNscripts/3.8竞技参考/竞技改代码/CLAUDE.md`（只读参考，不改造） |
| 3.8「独立规则设置界面」实现详解 + 3.3↔3.8 规则项对照 + 移植要点 | `doc/38-rule-stage/rule-stage.md` |
| PC版工程新增独立规则页的实现计划（含改动清单与坑） | `doc/38-rule-stage/plan.md` |
| **手机端主项目** CRAZY（疯狂）人机难度**移植记录**（源：3.7 扩展版参考工程 Shonen-Clash-main 的最难档）：档位机制、逐项移植对照、调参坑、回滚 | `doc/crazy-ai/crazy-ai.md` |
| PC 分支全量 AI 系统说明（**基准路径 `BVNscripts/PC/` 已不存在，属历史文档**；读结论前先核对路径） | `doc/AI-SYSTEM-DOC.md` |

规则页相关约定：竞技规则项走 `ConfigVO` 字段 + `optoinKey` 字符串绑定（注意是错拼）；UI 复用设置界面框架，新元件 AS 链接 `rule_ui`（在 setting.fla 内），角色实例名 `yuna`；改过 UI SWF 后必须重跑 build（编译期内嵌）。

AI 难度相关约定：`AI_level` 共 7 档（1 VERY EASY … 6 HELL、7 CRAZY），主项目 `FighterAILogicBase.getAIResult()` 新增的第 7 个参数 `param7` 是 CRAZY 专属列，**概率表不补第 7 列即回落 HELL**，所以等级 1~6 不受影响；`updateContOrder()` 用 `sortOn("order", 2 | 0x10)`（`2`=DESCENDING、`0x10`=NUMERIC）⇒ **order 越大优先级越高**，调优先级别写反；改 AI 后必须跑 `./build.bat`。详见 `doc/crazy-ai/crazy-ai.md`。

随机纽带连招约定（2026-10-13 新增）：HELL/CRAZY 下 `FighterAILogic.updateLinkAI()` 在**非出招态**（`NORNAL`/`JUMP_ING`）从可用纽带里随机挑一个非基础动作执行，order 取 999 压过同帧其它候选，概率门 HELL 6/10、CRAZY 10/10；**只能做在非出招态**，因为 `doAction()` 每次起手都 `clearAction()` 清空全部纽带；判定面来自角色 MC 的 `AImain`，**AImain 缺失时必须走距离回退**（`FighterMC.initHitRange()` 会因缺 AImain 抛错）。详见 `doc/crazy-ai/crazy-ai.md` §10 与 `doc/decisions-ai-link-chain.md`。

## 外部资源契约

Android 包名是 `air.com.bvn.yy798`，外置根目录是 `/storage/emulated/0/Android/media/air.com.bvn.yy798/BVN/assets/`。目录约定为 `config/`、`fighter/`、`face/`、`map/`、`bgm/`、`sounds/`。

> **为什么是 `Android/media` 而不是 `Android/data`**（2026-10-09 真机实测，Android 13 / vivo V2073A）：
> `Android/data/<pkg>/` 只能由 Android 框架通过 `getExternalFilesDir()` 创建，应用用原始路径 `mkdir` 必失败（`Error #3001`）；
> `Android/media/<pkg>/` 则可被应用**零权限自行创建并写入**。首启由 `GameLoader.ensureExternalDirs()` 自动建 `fighter/map/face/bgm/config` 五个子目录。
> 中文文件名不要直接 `adb push`（会截断，如 `七夜.swf`→`七夜.`）；正确做法是 `tar` 打包后 push 再 `tar xf` 解包。

`fighter.xml` 定义人物；`assist.xml` 定义辅助；`map.xml` 定义地图和地图 BGM；`select.xml` 决定人物/辅助是否在选人界面出现；`preload.xml` 定义预加载资源。

`AssetLoader` 的解析顺序固定为：绝对路径直读；`assets/...` 相对 URL 规范化后先查外置目录；不存在时加载 APK 内置 URL。日志使用 `EXT-RESOLVE` 标记命中来源。外部人物必须同时拥有 XML `<fighter id>`、可读取的 SWF 和 `select.xml/char_list` 中同名 `<item>`；缺少 SWF 时不进入可选列表。

主项目流程是：APK 配置初始化模型，`GameLoader` 扫描外部 SWF 建立占位 VO，再合并外部 XML 覆盖元数据，最后在选人界面构建前完成 `select.xml`。内置人物 ID 冲突保持内置优先。

## ANE 现状：已按设计停用（勿再重复攻克 #2113）

**结论（2026-10-09）**：`com.bvn.filereader` 在本工具链上**无法加载**——`ExtensionContext.createExtensionContext()` 恒抛
`Error #2113: Provided parameter LoaderContext.SecurityDomain is from a disallowed domain.`，失败点在 AIR 运行时的
`flash.external::ExtensionContext$/_createExtensionContext()`，**早于任何 Java 代码**（logcat 有 `initialize() called`，从无 `createContext() called`）。

已逐项实测排除的 8 类变量（真机探针见 `tools/Test/ane_probe/`，报告见 `tools/Test/_report/2026-10-09_ANE-诊断报告.md`）：
ANE 自身实现 / 命名空间 26.0·32.0 / SWF 版本 37·43 / `supportedProfiles` / Adobe 原版 AIR 33.1.1 / **第三方 ANEToolkit 对照组** / 去掉 `android:debuggable` / **`application/51.0` 现代 Gradle 打包路径**。
第三方 ANE 与 Adobe 自家 SDK 同样失败 ⇒ **不是本项目代码问题，是 AIR 运行时缺陷**（上游 `freshplanet/ANE-Alert#12`、`ANE-DatePicker#6` 同栈且无解）。

**因此两个开关职责已拆分，不要混用**：
- `ANEFileReader.EXTERNAL_ENABLED`（默认 `true`）= 外置资源子系统总开关，被 `AssetLoader.findExternalPath()` 与 `GameData.loadConfig()` 读取；
- `ANEFileReader.ANE_ENABLED`（默认 `false`）= 是否尝试创建原生扩展上下文。

⚠️ 把 `ANE_ENABLED` 当总开关关掉会静默废掉整个外置资源链路（曾经踩过）。`application.xml` 的 `<extensions>` 已注释。
真要重启 ANE 路线，必须先找到能加载扩展的工具链（例如 `-target apk`/共享运行时），并在真机上验到 `createContext() called` 再改开关。

（以下三段命令仍是常规构建/打包链路；ANE 相关命令保留以备将来工具链可用时复用）

```text
./build.bat
extensions/BVNFileReader/build_ane.bat
tools/script/debug_mob.bat
```

签名密码只能从环境变量读取，不得写入文档或脚本：

```powershell
$env:BVN_KEYSTORE_PASS = "<本机证书密码>"
tools/script/debug_mob.bat
```

密码、私钥、设备序列号、用户目录和临时日志不得提交。Android APK 白名单不包含 `assets/swf` UI 目录；不要把生成的 APK、SWF、ANE 或测试二进制加入源码提交。

## 真机日志

文件日志位于 `/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log`。

```bash
adb exec-out run-as air.com.bvn.yy798 cat "/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log"
adb logcat -v threadtime | findstr /i "AdobeAIR BVNFileReader ANEFileReader GameLoader EXT-RESOLVE EXT-READ FATAL"
```

`SelectedUI setFighter id=...` 表示角色已进入选人列表；`EXT-RESOLVE ... external` 表示外置命中；`apk-fallback` 表示回退 APK；
`[ANEFileReader] ANE disabled (by design)` 是**期望**输出（单条，无 `#2113`）；`[GameLoader] External dirs FAILED at: ...` 才表示外置目录建不出来，应先核对 `ANEFileReader.EXTERNAL_BASE` 是否落在 `Android/media/<pkg>/` 下。

## 触控事件与设置界面滚动

界面触摸有两条**不报错**的静默失败路径，改触控相关代码前必读（完整机理见 `doc/runtime-pitfalls.md` §3）：

1. **包装类的注册判据**。`SelectFighterItem` / `MenuBtn` 重写 `addEventListener`，把外部回调转挂到 `ui` 上。判据必须是本类登记表 `_listeners[type] == null`，**不能用 `ui.hasEventListener(type)`**：任何直挂在 `ui` 上的监听（例如触屏长按用的 `touchBegin/touchTap`）都会让它误判为"已注册"而静默 `return`，吞掉外部回调。同时必须提供对称的 `removeEventListener` 重写，否则挂在 `ui` 上的 `selfHandler` 无法注销，表现为每帧重复 `addChild` + 每帧写日志（选人界面卡顿与日志刷屏的根因）。

2. **`SetBtnGroup` 设置列表滚不到 APPLY**。滚动由 `_arrowIndex` 驱动（`moveScroll`），而手机端设置界面没有虚拟方向键（`ScreenPadManager` 对非 `GameState`/`SelectFighterStage` 走 `menuMode`），`_arrowIndex` 只能靠点击已可见的行移动；视口外的行又被 `scrollRect` 裁掉且不可命中 → 16~17 行的列表永远到不了末尾的 **APPLY**，而它是 `SettingState` 唯一的保存 + 退出入口。已加 `enableScrollDrag()`（触屏拖拽 + 滚轮）。`scrollRect.y` **增大 = 显示更靠下的内容**，改方向前先对照 `moveScroll` 的已验证符号。

   计算可滚动距离时注意两个量纲陷阱：`_scrollRect` 是**本地**尺寸，而 `SetBtnGroup` 在 `TOUCH_MODE` 下 `scale=1.1`，本地 600 渲染后是 660 游戏单位、超出部分被屏幕裁掉 → 有效视口必须按 `GameConfig.GAME_SIZE.y / scaleY ≈ 545` 算（按 600 算会让末尾 APPLY 卡在屏幕外）；`launch.FULL_SCREEN_SIZE` 是**设备像素**而非游戏单位，不要在本地单位混算里使用它。

长按展开人物子框**只对配了 `plugins=` 的角色生效**（当前 52 个角色里仅 `灵梦,妹红`、`早苗,妹红` 两个）；其余角色长按是设计的静默 `return`，不要当成 bug。

真机排查触控时可临时加 `[DIAG6.15]` 前缀日志（`touchBegin` / `touchTap` 落到 `ui`、Stage 侧回调是否触发），验证通过后删除并重编。选人界面格子的预期语义是：首次点击 = 预览，再点同一格 = 确认。

## 代码审查与提交

提交前只选择用户明确纳入的文件，并运行 `git diff --check`、`git diff --stat --cached`。扫描密码、令牌、私钥、本机路径、设备标识和临时日志。文档中的 Android 公共路径可以保留，真实设备序列号和签名凭据必须移除。

正常代码只从 `BVNscripts/scripts/` 选择性提交；本轮文档只提交 `README.md`、`CLAUDE.md`。参考代码、`tools/Test/`、模板 ZIP 和 APK不进入源码提交；APK 和模板 ZIP 在 GitHub Release 中作为附件上传。

## 交付验收

- `./build.bat` 通过并生成 SWF；
- ANE 构建和 APK 打包成功；
- 真机日志确认外部人物 ID、SWF 命中和 APK 回退；
- Release 附件是本轮新 APK 和带用户说明的模板 ZIP；
- Git diff 不包含参考源码、测试二进制、凭据或设备隐私。
