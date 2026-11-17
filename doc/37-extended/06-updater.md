# 3.7 扩展版自动更新（GithubUpdater / UpdateManager）

一句话：3.7 的自动更新是「GitHub Release API 查版本 → 下整包 SWF 到 Local Store → 下次启动用 loadBytes 顶替自己」的补丁壳，不换 APK。
源码基准：`BVNscripts/3.7扩展版参考/scripts/`（AS3 反编译产物，只读，不入提交）。
对照基准：`BVNscripts/scripts/` 主项目 3.3（现场只读比对，未改动任何文件）。

> **引用约定**：`路径:类.方法()`。不带前缀的路径相对 `BVNscripts/3.7扩展版参考/scripts/net/play5d/game/bvn/`；
> 文档类 `launchWUFAN` 不在 `bvn/` 下，一律写全 `scripts/launchWUFAN.as`；
> 「主项目」开头表示 `BVNscripts/scripts/` 侧，其后路径相对 `net/play5d/game/bvn/`。
> 行号一律不写死（反编译重编会漂）；确需定位写「参考 :N」并标参考。

---

## 1. 一句话结论

**更新源**：GitHub REST `releases/latest` + `releases/download/<tag>/<asset>` 两条公开地址，无鉴权、无请求头、无 HTTP 状态码分支、无重试、无退避。`UpdateURL.as` 不是更新源——它是一段 XOR 混淆的字符串，解出来指向一个 YouTube 频道页。

**版本比较**不是语义化版本，是「把 tag 里所有数字字符抽出来拼成一个整数」（`GithubUpdater.digitsToInt()`），本地侧用整型常量 `launchWUFAN.VERSION_CODE = 104`。所以远端 tag 必须编码成「拼起来后大于 104 的数字」，`V3.7` 这种 tag 解出 37，被判为旧版本。

**检查流程**没有状态机：单次请求 + 5 秒定时器，成功/失败/超时三条路都汇到 `GithubUpdater.finishCheck()` 各调一次回调；任何失败都 `proceed()` 放行（fail-open），用户只看到一行 `trace`。

**下载**是 `URLStream` + `FileStream` 手动分块搬运，落到 `File.applicationStorageDirectory/update/launchWUFAN.swf.tmp`；**没有断点续传**（起手先 `deleteFile()`，任何错误也删）；停摆判据是 `getTimer() - _dlLastProgress > 20000`，5 秒一轮轮询；恢复手段只有「整体重下」。

**下载完不替换自身**：`installDownloaded()` 做的是 `moveTo(...,true)` 覆盖 + 写一个 `.ver` 版本戳文件，然后提示「游戏将关闭」，`NativeApplication.nativeApplication.exit()`。重开时由文档类 `launchWUFAN.checkAndLoadExternal()` 发现补丁，`UpdateManager.loadFile()` 全量读进内存再 `Loader.loadBytes()`，`addChild(loader)` 让补丁 SWF 作为子显示对象接管整个应用。APK 本身一个字节都没动。

**UI 只有两处**：一个 `GameUI.alert` 单按钮对话框，一个手工 `Sprite` 全屏黑底 + `TextField` 进度层。进度回调接到 `UpdateCtrl.onDlProgress()`，250 毫秒节流。

**完整性校验只有三道弱门**：API 元数据 `size` 在 (0, 314572800] 内、下载字节数严格等于 `size`、文件头三字节 ∈ {`FWS`,`CWS`,`ZWS`}。无哈希、无签名、无证书绑定；下完的 SWF 用 `allowCodeImport = true` 以本应用权限执行代码。

**主项目没有同类能力**：`BVNscripts/scripts/` 全树 0 处 `GithubUpdater` / `UpdateCtrl` / `UpdateManager` / `UpdateURL`，只有 `主项目 MainGame.UPDATE_INFO`（声明+读取，无写入点）与 `主项目 MenuState` 的首启弹窗（永远进不去）。

**结论**：这套东西搬进主项目只值得搬「检查 + 提示 + 跳转下载页」，不值得搬「自替换」——不是因为跑不起来（主项目已经在用 `loadBytes + allowCodeImport` 加载外置人物 SWF），而是因为它把版本号分成了两条互不相干的线，代码里存在的「版本戳锁死」把这条线锁死在半路。

---

## 2. 领域术语

| 术语 | 本册含义 | 代码对应物 |
|---|---|---|
| 补丁壳（patch shell） | 用一个从网络下发的整包 SWF 顶替当前运行的 SWF，APK 不变 | `scripts/launchWUFAN.as:launchWUFAN.checkAndLoadExternal()` + `utils/UpdateManager.as:UpdateManager.startLoader()` |
| 引导器（bootloader） | 文档类自身兼作引导：先找补丁，找不到再跑内置流程 | `scripts/launchWUFAN.as:launchWUFAN`（`isLoadedByHost()` 是它判断「我自己是不是补丁」的开关） |
| 宿主判定 | 若本 SWF 是被别的 Loader 装载的，就跳过补丁查找，防无限套娃 | `scripts/launchWUFAN.as:launchWUFAN.isLoadedByHost()` |
| `VERSION_CODE` | 本地构建号，整型，比较的唯一本地依据 | `scripts/launchWUFAN.as:launchWUFAN.VERSION_CODE = 104` |
| release tag | GitHub Release 的 `tag_name`，远端版本载体 | `utils/GithubUpdater.as:GithubUpdater.onCheckComplete()` 里的 `data.tag_name` |
| 数字化 tag | 把 tag 内所有数字字符拼成一个整数 | `utils/GithubUpdater.as:GithubUpdater.digitsToInt()` |
| 检查窗口 `_checkLocal` | 一次检查的比较基线 = max(传入版本, 已装补丁版本) | `utils/GithubUpdater.as:GithubUpdater._checkLocal` |
| 版本戳 `.ver` | 与补丁 SWF 同目录、同名加 `.ver` 后缀的小文本文件，内容是一个十进制整数 | `utils/GithubUpdater.as:GithubUpdater.installDownloaded()` 写入；`installedVersion()` / `readVersionHint()` 读取 |
| 已装补丁版本 | 从 `.ver` 读出的整数；swf 与 ver 缺一即为 0 | `utils/GithubUpdater.as:GithubUpdater.installedVersion()` |
| 停摆看门狗 | 20 秒无新字节即判连接断，5 秒轮询一次 | `utils/GithubUpdater.as:GithubUpdater.onStallCheck()` + `STALL_TIMEOUT_MS` |
| 隔离域装载 | 补丁用独立 `ApplicationDomain` 加载，类静态与宿主互不共享 | `utils/UpdateManager.as:UpdateManager.startLoader()` 的 `_isolated` 分支 |
| 补丁目录（新） | 应用私有存储 `update/`，无需任何权限 | `utils/GithubUpdater.as:GithubUpdater.updateDir()` |
| 补丁目录（旧） | `/storage/emulated/0/assets/update`，需要存储权限 | `scripts/launchWUFAN.as:launchWUFAN.PATCH_DIR` |
| fail-open | 检查/下载失败一律放行进入游戏，不阻塞启动 | `mob/ctrls/UpdateCtrl.as:UpdateCtrl.proceed()` |
| 第二条通道 | 远程配置文件里带 `VS` 段，解析成 `VersionInfoVO`，但无人消费 | `mob/ctrls/GamePolyCtrl.as:GamePolyCtrl.parseConfig()` |
| 桩类 | 命名像更新、实际只是跳外链的类 | `utils/UpdateURL.as:UpdateURL.getURL()` → `mob/views/ViewManager.as:ViewManager.checkUpdate()` |

---

## 3. 结构与数据流

### 3.1 七个类的职责

| 类 | 所在路径 | 职责 | 是否持有网络/文件状态 |
|---|---|---|---|
| `GithubUpdater` | `utils/GithubUpdater.as` | 全部网络与落盘：查版本、下文件、写 `.ver`。全静态，构造即 `throw new Error("Static Class")` | 是（17 个静态字段，见 §3.6） |
| `UpdateManager` | `utils/UpdateManager.as` | 把磁盘上的 SWF 读进内存并 `loadBytes`，产出 `Loader`；顺带兜 `UncaughtErrorEvent` | 是（`_stream`/`_bytes`/`_loader`） |
| `UpdateCtrl` | `mob/ctrls/UpdateCtrl.as` | 唯一 UI 层：对话框 + 全屏进度层 + 退出应用 | 是（`_overlay`/`_label`/`_info`） |
| `launchWUFAN` | `scripts/launchWUFAN.as` | 文档类兼引导器：宿主判定、补丁查找、版本门、装载、再启动游戏 | 是（`_patchLoader`，只写不读） |
| `VersionInfoVO` | `mob/data/VersionInfoVO.as` | 纯数据：`version` / `url` / `info` / `forceUpdate` / `enabled` | 否 |
| `GamePolyCtrl` | `mob/ctrls/GamePolyCtrl.as` | 远程配置拉取 + MD5 签名校验 + 本地缓存 `bvnpoly.conf`，内含 `VS` 段 | 是（`_versionInfo`、`_adConfList`） |
| `UpdateURL` | `utils/UpdateURL.as` | XOR 解码一段 hex，返回一个外链字符串 | 否 |

### 3.2 两个入口，两条完全不同的链

| 入口 | 何时 | 干什么 | 与更新的关系 |
|---|---|---|---|
| 启动期装载 | 每次启动，`launchWUFAN.initlize()` → `checkAndLoadExternal()` | 找本地补丁 → 装载 → 接管 | 消费上一次下载的结果 |
| 局内检查 | 游戏装配完成，`launchWUFAN.initBackHandler()` → `UpdateCtrl.I.update(...)` | 查远端版本 → 提示 → 下载 | 产生下一次启动要用的补丁 |

`initBackHandler()` 是 `RootSprite.I.buildGame(initBackHandler, initFailHandler)` 成功的回调，也即「资源装配完成、即将 `goLogo()`」这一刻。参考里它的最后两行是 `UpdateCtrl.I.update(updateBack, updateBack)` 与 `updateBack()`→`RootSprite.I.getMainGame().goLogo()`，顺序上检查先于进 Logo —— 对话框压在 Logo 之前弹出。

### 3.3 检查 → 下载 → 落盘 → 装载（文字箭头图）

```text
[launchWUFAN.initBackHandler()]
        │  UpdateCtrl.I.update(updateBack, updateBack)
        ▼
UpdateCtrl.update()  ── 记 _proceed、_handled=false ──▶ GithubUpdater.check(VERSION_CODE, ...)
                                                            │
                          GET api.github.com/repos/{OWNER}/{REPO}/releases/latest
                          useCache=false · 无请求头 · 无 token · 5s 超时
                                                            ▼
                        onCheckComplete / onCheckIOError / onCheckTimeout
                                                            │
                                        finishCheck(info | errMsg)  ← 唯一收口，各调一次
                                                            ▼
UpdateCtrl.onCheckResult(info)                       UpdateCtrl.onCheckError(msg)
        │ info == null → proceed()                            │ trace + proceed()
        ▼                                                     ▼
 GameUI.alert("Update Tersedia", …) ── OK ──▶ startDownload()          （fail-open 进游戏）
                                                   │
                                                   ▼
                        GithubUpdater.download(info, ...)  → update/launchWUFAN.swf.tmp
                                                   │
                    ProgressEvent → drainDownload() → FileStream.writeBytes()
                                                   ▼
                   Event.COMPLETE → 尺寸相等？→ 魔数 FWS/CWS/ZWS？→ installDownloaded()
                                                   │            moveTo(swf,true) + 写 .ver
                                                   ▼
                        UpdateCtrl.onDlDone() → alert("Update Berhasil") → exitGame()
                                                   │
                                        NativeApplication.nativeApplication.exit()
                                                   ▼
                                          （用户手动重开应用）
                                                   │
        ┌──────────────────────────────────────────┘
        ▼
launchWUFAN.checkAndLoadExternal()
        │ isLoadedByHost()? → 是：直接 startGame()
        │ 找 Local Store/update/launchWUFAN.swf（缺→建 /storage/emulated/0/assets/update 再找）
        │ readVersionHint() 读 .ver：hint>0 且 hint<VERSION_CODE → 跳过补丁
        ▼
UpdateManager.loadFile(patchFile, true, onPatchLoaded, onPatchFailed, sendLog)
        │ _bytes.length = file.size  ← 整文件预分配
        │ openAsync(READ) → PROGRESS 分块 readBytes
        ▼
   startLoader()：new ApplicationDomain() · LoaderContext.allowCodeImport=true · loadBytes
        │
        ▼
onPatchLoaded() → getDefinition("launchWUFAN") → 取补丁 VERSION_CODE
        │ extVersion >= VERSION_CODE → addChild(loader)  ← 补丁接管整个应用
        │ 否则 unloadAndStop() + collectGarbage() + startGame()
        ▼
补丁自己作为文档类：showStartPic → RootSprite.STAGE=stage → initSDK → initGame →
initGameConfig（两条明文 http 配置）→ buildGame → initBackHandler → 再次 UpdateCtrl.I.update()
```

### 3.4 版本号在这个系统里出现四种形态

| 形态 | 出处 | 类型/取值 | 谁读它 |
|---|---|---|---|
| `launchWUFAN.VERSION_CODE` | `scripts/launchWUFAN.as` | `int`，`= 104` | `UpdateCtrl.update()` 传参、`checkAndLoadExternal()` 的过期判据、`onPatchLoaded()` 的接管线 |
| release `tag_name` | GitHub API 响应 | `String`，如 `v1.0.5` | `GithubUpdater.onCheckComplete()` → `digitsToInt()` |
| `info.version` | `check()` 组装 | `int`（数字化后的 tag） | `installDownloaded()` 写进 `.ver` |
| `MainGame.VERSION` / `VERSION_LABEL` / `VERSION_DATE` | `MainGame.as` | `V3.7` / `V3.7` / `2021.10.14` | **零引用**（全树仅声明处各一行，见 §5 T12） |

四种形态里只有前三种参与更新判断，且互相换算关系是单向的：`tag → digitsToInt → version → .ver → installedVersion`。`MainGame.VERSION*` 三个常量与更新链路没有任何连接；版本号显示走的是另一条硬编码字符串（`MenuState.build()` 里的 `_ui.setVersion("V3.7")`），而那条字符串在 `TitleScreenUI.setVersion()` 里被丢弃（§5 T12）。

### 3.5 落盘布局

| 路径 | 谁写 | 谁读 | 内容 |
|---|---|---|---|
| `File.applicationStorageDirectory/update/` | `GithubUpdater.updateDir()` 建目录 | 同 | 补丁目录（应用私有，无需权限） |
| `…/update/launchWUFAN.swf.tmp` | `download()` 打开写入 | `endDownload()` 删、`installDownloaded()` 移动 | 下载中间态 |
| `…/update/launchWUFAN.swf` | `installDownloaded()` 的 `moveTo(tmp, true)` | `launchWUFAN.checkAndLoadExternal()`、`installedVersion()` | 补丁本体 |
| `…/update/launchWUFAN.swf.ver` | `installDownloaded()` 用 `writeUTFBytes(String(version))` | `installedVersion()`、`readVersionHint()` | 十进制整数文本，≤32 字节 |
| `/storage/emulated/0/assets/update/launchWUFAN.swf`（+`.ver`） | 不是代码写的（人工投放） | `checkAndLoadExternal()` 的第二候选 | 手工补丁，需存储权限 |
| `File.applicationStorageDirectory/bvnpoly.conf` | `GamePolyCtrl.saveLocalConfig()` | `readLocalConfig()` | 远程配置原文（`payload|md5`） |
| `…/Android/data/com.jarworld.bleach.bvi/files/<swf>` 等 10 条 | 不是代码写的 | `UpdateManager.findUpdateFile()` | 兼容旧人工投放路径 |

### 3.6 `GithubUpdater` 的 17 个静态字段

全静态类，一次只会有一轮检查与一轮下载，字段就是它的全部状态。理解「谁写、何时清」比读方法体更快。

| 字段 | 类型 | 谁写 | 何时清 / 复位 |
|---|---|---|---|
| `_checkLoader` | `URLLoader` | `check()` | `abortCheck()` 里摘监听、`close()`、置 `null` |
| `_checkTimer` | `uint` | `check()` 的 `setTimeout` 返回值 | `abortCheck()` 里 `clearTimeout` |
| `_checkLocal` | `int` | `check()` 算出的比较基线 | 不复位，下次 `check()` 覆写 |
| `_checkResult` | `Function` | `check()` | `abortCheck()` / `finishCheck()` 取走快照后置 `null` |
| `_checkError` | `Function` | `check()` | 同上 |
| `_dlStream` | `URLStream` | `download()` | `endDownload()` 摘四个监听、`close()`、置 `null` |
| `_dlFile` | `FileStream` | `download()` | `onDlComplete()` 或 `endDownload()` 里 `close()` + 置 `null` |
| `_dlTmp` | `File` | `download()` | `endDownload()` 置 `null`（错误时先 `deleteFile()`） |
| `_dlChunk` | `ByteArray` | `download()` | `endDownload()` 里 `clear()` + 置 `null` |
| `_dlInfo` | `Object` | `download()` | `endDownload()` 置 `null` |
| `_dlStallTimer` | `uint` | `download()` 与 `onStallCheck()` 自续 | `endDownload()` 里 `clearTimeout` |
| `_dlOnProgress` / `_dlOnDone` / `_dlOnError` | `Function` ×3 | `download()` | `endDownload()` 置 `null` |
| `_dlBusy` | `Boolean` | `download()` 置 true | `endDownload()` 置 false（重入分支不置，见 §4.4 步骤 7） |
| `_dlWritten` | `Number` | `download()` 置 0、`drainDownload()` 累加 | 下次 `download()` 归零 |
| `_dlLastProgress` | `int` | `download()` 与 `drainDownload()` | 不复位 |

### 3.7 参数与定时器总表

| 参数/数值 | 值 | 出处 | 作用 | 谁取消/复位 |
|---|---|---|---|---|
| `CHECK_TIMEOUT_MS` | 5000 | `GithubUpdater` 常量 | 检查总超时 | `abortCheck()` |
| `STALL_TIMEOUT_MS` | 20000 | `GithubUpdater` 常量 | 停摆判据（距上一字节的间隔） | 一次性判断，不取消 |
| 看门狗轮询间隔 | 5000（字面量，两处） | `download()` 与 `onStallCheck()` | 每隔 5 秒看一次 | `endDownload()` |
| 进度 UI 节流 | 250（字面量） | `UpdateCtrl.onDlProgress()` | 250 毫秒内不重排文本 | 时间戳比较，无定时器 |
| `MAX_SIZE_BYTES` | 314572800（300 MiB） | `GithubUpdater` 常量 | 元数据尺寸上限 | — |
| `.ver` 尺寸窗口 | `0 < size <= 32` | `installedVersion()` / `readVersionHint()` | 防误读二进制文件 | 越界即返回 0 |
| `isSafeTag()` 长度窗口 | 1~40 | `GithubUpdater` | 防 URL 注入 | — |
| 进度遮罩 | 黑底 `alpha 0.88`、字号 28、左右各 40 | `UpdateCtrl.showOverlay()` | 全屏覆盖 | `hideOverlay()` |

**这两处定时器都不归 `TimerOutUtils.pauseAllTimer()` 管**（它是另一套 `flash.utils.Timer` 封装，见 §5 T15）；只有 `UpdateCtrl` 的 250 毫秒节流是纯时间戳比较、不依赖任何定时器。切后台时这两个 `flash.utils.setTimeout` 的行为需要真机确认（§7 U14）。

---

## 4. 关键机制逐条拆解

### 4.1 更新源：两条 GitHub 公开地址，没有任何鉴权与状态码处理

**结论**：检查走 `https://api.github.com/repos/{OWNER}/{REPO}/releases/latest`，下载走 `https://github.com/{OWNER}/{REPO}/releases/download/{tag}/{ASSET_NAME}`；常量 `OWNER = "RizkyRaya"`、`REPO = "Shonen-Clash"`、`ASSET_NAME = "launchWUFAN.swf"`。两个请求都只设了 `useCache = false`，没有 `Accept`、没有 `User-Agent`、没有 `Authorization`。

**代码引用**：`utils/GithubUpdater.as:GithubUpdater.check()`（拼 API 地址 + `new URLLoader()` + 三个监听）、`utils/GithubUpdater.as:GithubUpdater.download()`（拼下载地址）、`utils/GithubUpdater.as:GithubUpdater.OWNER` / `.REPO` / `.ASSET_NAME`。

**为什么这么做**：公开仓库的 Release 是唯一「作者能发版、玩家能直接下」的通道，不需要自建后端；`useCache=false` 是为了绕开平台 HTTP 缓存拿到最新 `tag_name`（AIR 的 `URLRequest.useCache` 默认会命中本地缓存，导致发版后仍读到旧 JSON）。

**没有的东西（同样重要）**：监听器只有 `Event.COMPLETE` / `IOErrorEvent.IO_ERROR` / `SecurityErrorEvent.SECURITY_ERROR`（检查段）与 `ProgressEvent.PROGRESS` / `Event.COMPLETE` / `IO_ERROR` / `SECURITY_ERROR`（下载段）——**没有 `HTTPStatusEvent`**，所以 403（限流）、404（tag 不存在）、5xx 全部落进同一个 `onCheckIOError` 分支，文案是 `Tidak bisa menghubungi GitHub (offline / rate limit).`。匿名额度也好、按 IP 的额度也好，代码里没有任何计数、`Retry-After` 解析或退避；`_checkTimer` 用完即弃，再次 `check()` 会从零开始。

**`UpdateURL.as` 不是更新源**：`utils/UpdateURL.as:UpdateURL.getURL()` 把常量 `DATA`（40 字节 hex）按 `xorDecode(DATA, getKey())` 解码，密钥是 `String.fromCharCode(78,101,120,86)`（即 `NexV`）。逐字节 XOR 的结果是 31 字符的 `https://www.youtube.com/@ReNexV`，一个频道页。它唯一的消费点是 `mob/views/ViewManager.as:ViewManager.checkUpdate()`（`URL.go(UpdateURL.getURL(), false)`），而 `checkUpdate` 又被 `mob/GameInterfaceManager.as:GameInterfaceManager.getSettingMenu()` 注册成设置菜单里的 `Check Update` 项。也就是说：**设置里的「检查更新」打开的是浏览器，不是更新器**。这层 XOR 只是把作者外链藏起来，不构成任何安全机制（密钥就写在同一文件里）。

### 4.2 版本比较：数字拼接，不是语义化版本

**结论**：`digitsToInt(tag)` 遍历 tag 的每个字符，只保留 `0-9`，拼成字符串后截到 9 位再 `int()`；空串返回 0（`int("")` 在 AS3 里就是 0）。比较是单条 `remote > _checkLocal`。

**代码引用**：`utils/GithubUpdater.as:GithubUpdater.digitsToInt()`、`utils/GithubUpdater.as:GithubUpdater.isSafeTag()`、`utils/GithubUpdater.as:GithubUpdater.check()` 的 `_checkLocal = Math.max(localVersion, installedVersion())`、`utils/GithubUpdater.as:GithubUpdater.onCheckComplete()` 的 `if(remote > _checkLocal)`。

**前缀 `v` 的处理**：没有专门处理——因为非数字一律被丢弃，`v1.0.5`、`1.0.5`、`release-1.0.5` 得到同一个 105。同理 `.` 与 `-` 也被丢弃，于是：

| tag | `digitsToInt` 结果 | 与基线 104 比较 | 备注 |
|---|---|---|---|
| `v1.0.4` | 104 | 不更新 | 与构建号同值 |
| `v1.0.5` | 105 | 更新 | 作者实际采用的编码 |
| `v3.7` | 37 | 不更新 | 版本字面量当 tag 用会失效 |
| `v1.10.0` | 1100 | 更新 | 但见下一行 |
| `v2.0.0` | 200 | 更新 | 200 < 1100 → 大版本被判为更旧 |
| `release` | 0 | 不更新 | 无数字即 0 |

**为什么这么做**：作者需要一个「单调整数」来当构建号，而 GitHub tag 是自由字符串；抽数字是成本最低的映射。**代价**是它只在「每段都一位数」时保序：`v1.10.0`（1100）会永远压过 `v2.0.0`（200），一旦某段进位到两位数，版本序就与人类语义相反。

**`VERSION_LABEL` 与 tag 无关系**：`MainGame.VERSION_LABEL = "V3.7"` 全树零引用（`MainGame.as` 里仅声明），tag 由 Release 决定，比较用 `VERSION_CODE`。三者没有任何换算代码。

**`isSafeTag()` 是 URL 净化**：长度 1~40，字符集限定 `[0-9A-Za-z._-]`。因为 tag 会被拼进下载 URL 的路径段，这道门挡的是 `/`、`?`、`#`、`%` 与空格的注入。下载前还会再校验一次（`download()` 里的 `!isSafeTag(String(info.tag))`），所以手工构造 `info` 也绕不过。

### 4.3 检查的状态机：三条失败路径，一个收口，零重试

**结论**：`check()` 是「一次性」的，不存在重试或轮询；四类结果（成功 / IO 或安全错误 / 5 秒超时 / 同步异常）都调 `finishCheck()`，而 `finishCheck()` 先 `abortCheck()` 再回调，保证回调恰好一次。

**代码引用**：`utils/GithubUpdater.as:GithubUpdater.check()`、`.onCheckComplete()`、`.onCheckIOError()`、`.onCheckTimeout()`、`.finishCheck()`、`.abortCheck()`。

| 触发 | 处理函数 | 传给回调的 error 文案（原文即印尼语） |
|---|---|---|
| `load()` 同步抛错 | `check()` 内 `catch` → `finishCheck(null, …)` | `Gagal memulai pengecekan: + err.message` |
| `Event.COMPLETE` 且 `tag_name` 为空 | `onCheckComplete()` | `Respon GitHub tidak berisi rilis.` |
| tag 非法 | `onCheckComplete()` | `Tag rilis tidak valid.` |
| 有新版本但 assets 里没有 `launchWUFAN.swf` | `onCheckComplete()` | `Rilis <tag> tidak memiliki file launchWUFAN.swf.` |
| `asset.size` ≤0 或 >300MiB | `onCheckComplete()` | `Ukuran file rilis tidak wajar.` |
| `JSON.parse` 抛错 | `onCheckComplete()` 的 `catch` | `Respon GitHub tidak valid: + err.message` |
| `IO_ERROR` / `SECURITY_ERROR` | `onCheckIOError()` | `Tidak bisa menghubungi GitHub (offline / rate limit).` |
| 5 秒到 | `onCheckTimeout()` | `Pengecekan update timeout.` |
| 无更新（`remote <= _checkLocal`） | `finishCheck(null, null)` | 无 error → 回调 `info = null` |

**为什么这么做**：启动路径不能因为网络卡住而挂起——`CHECK_TIMEOUT_MS = 5000` 把最坏等待锁在 5 秒，`finishCheck()` 的「先 abort 再回调」则保证即使回调里再次发起 `check()`，旧请求也已经拆干净（`abortCheck()` 会 `clearTimeout` + 摘监听 + `close()` + 置空 `_checkLoader` 与两个回调）。

**超时之后晚到的数据进不来**：`abortCheck()` 摘掉了 `Event.COMPLETE` 监听并 `close()` 了 loader，所以 5 秒后到达的响应没有接收者。

**失败一律放行**：`UpdateCtrl.onCheckError(msg)` 只 `trace("[UpdateCtrl] " + msg)` 然后 `proceed()`；`onCheckResult(null)`（无更新）也走 `proceed()`。`proceed()` 用 `_handled` 布尔做幂等，然后调 `_proceed` 并把 `_proceed` 置 null。玩家侧看不到任何失败提示。

### 4.4 一次完整下载的时序（第 N 步 / 谁调用谁 / 失败会怎样）

这是本册的主干。前提：`update()` 已被 `initBackHandler()` 调用，`check()` 返回了非空 `info`（`{version, tag, name, notes, size}`）。

| # | 调用方 → 被调方 | 干了什么 | 失败会怎样 |
|---|---|---|---|
| 1 | `launchWUFAN.initBackHandler()` → `UpdateCtrl.update(updateBack, updateBack)` | 记 `_proceed = param2`（非空时优先）、`_handled = false` | 无（同步） |
| 2 | `UpdateCtrl.update()` → `GithubUpdater.check(launchWUFAN.VERSION_CODE, …)` | 进入检查链（见 4.3） | 见 4.3 表；全部 fail-open |
| 3 | `GithubUpdater.onCheckComplete()` → `UpdateCtrl.onCheckResult(info)` | 组装文案 `Versi baru tersedia: <name> (<MB> MB)`，`notes` 非空时追加 `shorten(notes,300)`，末尾 `Tekan OK untuk mengunduh.` | `shorten()` 只截断不改写；`notes` 为空则少一段 |
| 4 | `onCheckResult()` → `showAlert("Update Tersedia", msg, startDownload, proceed)` | 尝试 `GameUI.alert(title,msg,onOk)`；`catch` 时调 `onShowFail`（= `proceed`） | 对话框建不出来 → 直接进游戏，下载不会发生 |
| 5 | 玩家点 OK → `AlertUI.chooseHandler("OK")` → `yesBack` → `GameUI.closeBack` → `close()` | `close()` 就是 `startDownload` | 玩家不点（或系统杀进程）→ 无下载，`_proceed` 仍挂着 |
| 6 | `startDownload()` → `showOverlay("Menghubungkan ke GitHub...")` | 建全屏黑底（`beginFill(0,0.88)`）+ 居中 `TextField`（`_sans`/28/白/粗/居中/`multiline`/`wordWrap`），`RootSprite.STAGE.addChild(_overlay)` | `RootSprite.STAGE == null` 时 `showOverlay` 静默返回，下载照跑但无进度层 |
| 7 | `startDownload()` → `GithubUpdater.download(_info, onDlProgress, onDlDone, onDlError)` | 先查 `_dlBusy`（重入直接 `onError("Download masih berjalan.")`），置 `_dlBusy = true`、`_dlWritten = 0` | 重入被拒，回调立刻收到 error，`endDownload` 未走（`_dlBusy` 保持原值，属于他人会话） |
| 8 | `download()` 内部 | 校验 `info != null` 且 `isSafeTag(info.tag)`；`updateDir()` 不存在则 `createDirectory()`；指向 `update/launchWUFAN.swf.tmp`，**已存在则先 `deleteFile()`**；`_dlFile.open(tmp, WRITE)`；`_dlChunk = new ByteArray()`；`_dlLastProgress = getTimer()` | 任一步抛错 → `catch` → `endDownload("Gagal memulai download: " + err.message)` → 删 tmp（若已建） |
| 9 | `download()` → `_dlStream.load(req)` | `URLRequest("https://github.com/{OWNER}/{REPO}/releases/download/{tag}/{ASSET_NAME}")`，`useCache=false` | 同步抛错同上；异步失败走步骤 13 的错误分支 |
| 10 | `download()` → `setTimeout(onStallCheck, 5000)` | 挂看门狗 | — |
| 11 | `URLStream` 派 `ProgressEvent.PROGRESS` → `onDlProgress()` → `drainDownload()` | `n = _dlStream.bytesAvailable`；`readBytes(_dlChunk,0,n)` → `_dlFile.writeBytes(_dlChunk,0,n)` → `_dlWritten += n` → **刷新 `_dlLastProgress = getTimer()`** → `_dlWritten > info.size` 则抛错 | 写盘抛错 → `endDownload("Gagal menulis file: " + err.message)`；超长发的是同一条文案（见 §5 T10） |
| 12 | `onDlProgress()` → `_dlOnProgress(_dlWritten, Number(_dlInfo.size))` → `UpdateCtrl.onDlProgress()` | 250 毫秒节流；`pct = int(loaded*100/total)`；`setOverlayText("Mengunduh " + name + "\n" + MB + " / " + MB + " (" + pct + "%)")` | `total <= 0` 时 `pct = 0`，文案仍更新 |
| 13 | 看门狗 `onStallCheck()`（每 5 秒自续） | `if(getTimer() - _dlLastProgress > 20000)` → `endDownload("Koneksi terputus (tidak ada data masuk).")`；否则再挂 5 秒 | 只判「无新字节」，不判「速率过低」；一趟长下载里只要有字节进来就永不判停 |
| 14 | `Event.COMPLETE` → `onDlComplete()` | `drainDownload()` 最后一次抽干 → `_dlFile.close()` → **`_dlWritten != info.size` 即报错** → `looksLikeSwf(_dlTmp)` 三字节魔数 → `installDownloaded()` | 尺寸不符文案 `Ukuran file tidak cocok (X dari Y bytes).`；魔数不符 `File yang diunduh bukan SWF yang valid.`；两条都走 `endDownload(err)` → **删 tmp** |
| 15 | `installDownloaded()` | `_dlTmp.moveTo(dir/launchWUFAN.swf, true)`（覆盖）→ 新建 `FileStream` 写 `launchWUFAN.swf.ver`（`writeUTFBytes(String(_dlInfo.version))`）→ `close()` | 移动或写入抛错 → `onDlComplete` 的 `catch` → `endDownload("Gagal memasang update: " + ex.message)`；此时 `.swf` 已被换掉而 `.ver` 还是旧值 |
| 16 | `endDownload(null)` | 清 `_dlStallTimer`、摘四个监听、`close()` stream、`close()` file、因 `error == null` **不删 tmp**（已移走）、`_dlChunk.clear()`、把 6 个字段置空、`_dlBusy = false` → 回调 `done()` | — |
| 17 | `UpdateCtrl.onDlDone()` | `hideOverlay()` → `showAlert("Update Berhasil", "Patch " + name + " sudah terpasang.\n\nGame akan ditutup. Buka kembali untuk menerapkan patch.", exitGame, exitGame)` | 对话框建不出来 → `exitGame()` 照样执行 |
| 18 | `exitGame()` | `NativeApplication.nativeApplication.exit()` | 无返回值、无重启；见 4.7 |

**失败重试**：没有。第 8 步的 `deleteFile()` 与第 16 步的「错误即删」共同保证任何一次失败后 `.tmp` 不残留，所以下一次下载必然从 0 字节开始。**唯一不删的路径是进程被杀**（`endDownload` 没跑），下次 `download()` 第 8 步照样先删。

**断点续传**：代码里不存在。`URLRequest` 没有设置任何请求头（无 `Range`），`URLStream` 也没有定位能力，落盘指针由 `FileStream` 的 `WRITE` 模式固定在文件头。

### 4.5 落盘与版本戳：先写 `.ver`，后验补丁

**结论**：`installDownloaded()` 的顺序是「先 `moveTo` 覆盖 swf，再写 `.ver`」，而 `.ver` 里写的是**远端 tag 数字化后的值**，不是补丁 SWF 内部的 `VERSION_CODE`。这两件事在正常发版时相等，在异常发版时不等——这正是 §5 T3 的锁死来源。

**代码引用**：`utils/GithubUpdater.as:GithubUpdater.installDownloaded()`；读取端两处：`utils/GithubUpdater.as:GithubUpdater.installedVersion()`（要求 `update/launchWUFAN.swf` 与 `update/launchWUFAN.swf.ver` **同时**存在，且 `0 < ver.size <= 32`）、`scripts/launchWUFAN.as:launchWUFAN.readVersionHint()`（从补丁文件所在目录取 `launchWUFAN.swf.ver`，同样的 `0 < size <= 32` 门）。

**为什么这么做**：`.ver` 是「已装补丁版本」的旁证文件。它让两件事可行：① 检查时用 `Math.max(传入版本, 已装补丁版本)` 作基线，避免重复下载同一个 release；② 启动时若补丁比当前构建旧（`hint > 0 && hint < VERSION_CODE`）就跳过，防止降级。

**为什么这是个坑**：补丁是否真的能用，要到下一次启动 `onPatchLoaded()` 里比 `extVersion >= VERSION_CODE` 才知道；而 `.ver` 在下载完成那一刻就已经写死了。判断依据（tag 数字化）与校验依据（SWF 内常量）是两套数，代码里没有任何一致性检查。

### 4.6 下次启动的装载链：一个类干两件事

**结论**：`launchWUFAN` 既是文档类又是引导器。它先判断「我是不是被别人装载的」，不是才去找补丁；找到且版本门通过就用 `UpdateManager.loadFile(..., isolatedDomain = true, ...)` 全量读进内存，在**独立 `ApplicationDomain`** 里 `loadBytes`，`extVersion >= VERSION_CODE` 时 `addChild(loader)` 让补丁接管；否则丢弃补丁并跑内置流程。

**代码引用**：`scripts/launchWUFAN.as:launchWUFAN.isLoadedByHost()`、`.checkAndLoadExternal()`、`.readVersionHint()`、`.onPatchLoaded()`、`.onPatchFailed()`；`utils/UpdateManager.as:UpdateManager.loadFile()`、`.startLoader()`、`.onLoaderComplete()`、`.fail()`、`.drainStream()`、`.onUncaughtError()`。

**为什么这么做**：

1. **防递归**：补丁 SWF 里编的也是 `launchWUFAN` 这个文档类，它跑起来后同样会执行 `checkAndLoadExternal()`。`isLoadedByHost()` 看 `loaderInfo.loader != null` —— 被装载的实例直接 `startGame()`，链条到此为止，否则每次启动会再套一层补丁。
2. **隔离域**：`_isolated = true` 时 `new ApplicationDomain()`（而非以 `ApplicationDomain.currentDomain` 为父域）。这样补丁里的 `launchWUFAN`、`MainGame`、`RootSprite` 等类与引导器各自一份静态字段。`onPatchLoaded()` 从 `loader.contentLoaderInfo.applicationDomain.getDefinition("launchWUFAN")` 取 `VERSION_CODE`，取到的正是补丁自己那份；若共用当前域，同名类会直接命中引导器的类，这个版本判断就失去意义。
3. **代执行**：`LoaderContext(false, domain)` 之后显式 `context.allowCodeImport = true`，并对老属性名 `allowLoadBytesCodeExecution` 再做一次存在性判断 —— 这是 AIR 特有开关，没有它 `loadBytes` 里的代码不会执行。这段写法与主项目 `AssetLoader` / `ResUtils` / `UIAssetUtil` 里的用法同构。
4. **兜异常**：`_loader.uncaughtErrorEvents` 挂 `onUncaughtError`，`preventDefault()` 后计数；只在 `≤5` 次或每 500 次时记 `lastUncaughtError` 并 `trace`。补丁里的未捕获异常不会击穿引导器。

**装载期的失败面**：

| 失败点 | 处理 | 后果 |
|---|---|---|
| 补丁文件不存在 / `size <= 0` | 两个候选都试完 → `patchFile = null` → `startGame()` | 跑内置流程 |
| `patchDir.createDirectory()` 抛错（旧目录） | `catch` → `sendLog("DIR PERMISSION ERROR: …")` → `patchFile = null` | 跑内置流程 |
| `.ver` 显示更旧 | `sendLog("Patch usang …")` → `startGame()` | 跑内置流程，**补丁文件仍留在盘上** |
| `file.size <= 0` | `UpdateManager.fail("Error: file update kosong (0 Bytes).")` | 回调 `onPatchFailed` → `startGame()` |
| 读取后 `_readPos == 0` | `fail("… pastikan Izin Storage sudah diaktifkan …")` | 同上（文案提示存储权限） |
| `loadBytes` 抛错 / IO / 安全错误 | `fail("Crash saat eksekusi SWF: …")` / `fail("Gagal eksekusi SWF: …")` | 同上 |
| 补丁 `VERSION_CODE` 更低或取不到 | `loader.unloadAndStop()` + `UpdateManager.collectGarbage()` + `startGame()` | 同上，**补丁文件同样留在盘上** |

**内存代价**：`loadFile()` 一开始就 `_bytes.length = total`，把整包 SWF 的尺寸一次性分配，然后按 `ProgressEvent.PROGRESS` 逐块 `readBytes` 填进去。`MAX_SIZE_BYTES = 314572800`（300 MiB），所以上限场景下这一次分配就是 300 MiB。

### 4.7 下载完成之后：提示 + 退出，没有自重启

**结论**：装完之后应用只会 `NativeApplication.nativeApplication.exit()`，没有任何重启或拉起自身的代码。补丁生效依赖「用户重新点开图标」。

**代码引用**：`mob/ctrls/UpdateCtrl.as:UpdateCtrl.onDlDone()`（文案里明写 `Game akan ditutup. Buka kembali untuk menerapkan patch.`）、`.exitGame()`。

**全树的 `NativeApplication` 用法只有四处**（可用来证明「没有自重启」）：
`scripts/launchWUFAN.as` 的 `systemIdleMode = KEEP_AWAKE` / `= NORMAL` / `= KEEP_AWAKE`、`nativeApplication.exit()`（`initFailHandler`）；
`mob/ctrls/UpdateCtrl.as` 的 `nativeApplication.exit()`。

**没有的**：没有 `NativeApplication.nativeApplication.startup()`、没有二次 `launch`、没有 `flash.desktop.NativeProcess`、没有 ANE 调用。AIR 层面也没有「重启自己」的 API，代码里也没试图绕。

### 4.8 进度与 UI：一个对话框 + 一层手绘遮罩

**结论**：进度回调的接线是 `GithubUpdater.download(..., onProgress = UpdateCtrl.onDlProgress, ...)`，`GithubUpdater` 在每次 `ProgressEvent.PROGRESS` 抽干数据后回调 `_dlOnProgress(_dlWritten, Number(_dlInfo.size))`；`UpdateCtrl` 侧 250 毫秒节流一次，写进一个手工创建的 `TextField`。

**代码引用**：`mob/ctrls/UpdateCtrl.as:UpdateCtrl.onDlProgress()`、`.showOverlay()`、`.setOverlayText()`、`.hideOverlay()`、`.showAlert()`、`.shorten()`。

**为什么这么做**：

1. **不在游戏 UI 体系里**：遮罩直接 `RootSprite.STAGE.addChild(_overlay)`（加在 `Stage` 上，不是 `RootSprite.I.addChild`，也不是 `GameUI` 的对话框层），所以在任何场景之上、且不随场景销毁。下载期跨场景也不需要重建。
2. **250 毫秒节流**：`if(now - _lastUi < 250) return;` —— 每次 `ProgressEvent` 都重排文本在安卓低端机上会拖帧。
3. **百分比按元数据算**：`total` 取自 `info.size`（API 里的 asset 尺寸），不是 `ProgressEvent.bytesTotal`。两者不一致时进度条与最终校验会同时暴露（步骤 14 的尺寸比对用的也是 `info.size`）。

**对话框的两个硬约束**（都来自 `GameUI.alert` / `AlertUI` / `StyleDialogView`）：

- `GameUI.alert(param1, param2, param3)` 的三个形参分别是 `enMsg` / `cnMsg` / `close`，`UpdateCtrl` 只传了第一个，第二个传 `null`。`StyleDialogView.setMsg(en, cn)` 的实现是 `_msg.text = en ? en.toUpperCase() : ""`，`_sub.text = cn ? cn : ""` —— **正文会被强制大写**，印尼语文案会以全大写显示，副行永远空。
- `AlertUI.build()` 调 `_view.setButtons([{"label":"OK","text":"OK"}], 0)`，只有一个按钮，不存在取消/关闭按钮。`UpdateCtrl.showAlert()` 里那段 `dlg.hasOwnProperty("cancelBtn")` / `("closeBtn")` 的隐藏逻辑没有执行机会（§5 T6）。

**失败提示文案在哪**：全部硬编码在 `GithubUpdater`（网络/校验类）、`UpdateCtrl`（流程类）与 `UpdateManager`（装载类）里，印尼语；逐条清单见 §4.12。没有任何 i18n 表或语言分支（`GameUI.SHOW_CN_TEXT` 不参与）。

### 4.9 安全与完整性：三道弱门，执行权全给

**结论**：没有哈希、没有签名、没有证书绑定，靠「元数据尺寸 + 字节数相等 + SWF 魔数」三道弱门；通过后以 `allowCodeImport = true` 执行。

**代码引用**：`utils/GithubUpdater.as:GithubUpdater.onCheckComplete()`（`size <= 0 || size > MAX_SIZE_BYTES`）、`.drainDownload()`（`_dlWritten > info.size` 抛错）、`.onDlComplete()`（`_dlWritten != info.size` 报错）、`.looksLikeSwf()`（`readUTFBytes(3)` 判 `FWS`/`CWS`/`ZWS`）、`utils/UpdateManager.as:UpdateManager.startLoader()`（`allowCodeImport = true`）。

| 检查项 | 强度 | 挡得住什么 | 挡不住什么 |
|---|---|---|---|
| API 元数据 `size ∈ (0, 300MiB]` | 极弱 | 空文件、超大文件被当补丁 | 被篡改的同尺寸文件 |
| 下载字节数 `== size` | 弱 | 截断（丢包、连接提前结束） | 同样长度的替换 |
| 三字节魔数 | 极弱 | HTML 错误页、CDN 5xx 页面伪装成下载 | 任意合法 SWF |
| `extVersion >= VERSION_CODE`（装载期） | 中 | 旧补丁回滚 | 自报高版本号的任意 SWF |
| `isSafeTag()` | 中（针对注入） | tag 里的路径穿越、查询串注入 | — |
| 传输层 | 依赖 HTTPS | 明文链路窃听/替换 | 拿到 GitHub 账号后直接换 Release 附件 |

**没有的**：全文没有 `MD5`、`SHA`、`digest`、`signature` 字样（`GamePolyCtrl` 用 MD5 校验的是配置文本，不是补丁 SWF，见 4.10）；没有证书 pinning 代码（`URLRequest` 只有 `useCache` 一个属性被设置）。

**最薄的一处是旧补丁目录**：`checkAndLoadExternal()` 的第二候选 `/storage/emulated/0/assets/update/launchWUFAN.swf` 是「谁能写这个目录谁就能让应用执行任意代码」的路径——判据只有 `.ver`，而 `.ver` **缺失时 `hint = 0`，`if(hint > 0 && hint < VERSION_CODE)` 整条不成立，版本门直接跳过**，最后只剩补丁 SWF 自带的 `VERSION_CODE` 自证（写入者当然会填高）。新目录（`applicationStorageDirectory/update`）在应用私有空间，第三方写不进去；旧目录在共享存储上，靠系统权限挡。

### 4.10 第二条通道：`GamePolyCtrl` 的远程配置（写了没接）

**结论**：另有一条「拉远程配置 → MD5 校验 → JSON 解析 → 填 `VersionInfoVO`」的通道，字段含 `forceUpdate` / `enabled` / `url`，具备做强制更新的全部数据，但 `getVersion()` **零调用点**。

**代码引用**：`mob/ctrls/GamePolyCtrl.as:GamePolyCtrl.loadConfig()`、`.parseConfig()`、`.saveLocalConfig()`、`.readLocalConfig()`、`.getVersion()`；`mob/data/VersionInfoVO.as:VersionInfoVO`；调用入口 `scripts/launchWUFAN.as:launchWUFAN.initGameConfig()`。

**机制**：

1. `initGameConfig()` 传入两个明文 http 地址（`http://1212321.cn-sh2.ufileos.com/upload/BVN_WF.ini`、`http://1212321.com/file/get/BVN_WF.ini`），`loadConfig()` 依次尝试，每个地址都追加 `?rand=<0..9999>` 破缓存。
2. 响应必须是 `payload|signature` 两段（`split("|")`，长度不为 2 即失败）。签名判据是 `MD5.hash("$%_ST_%$" + payload + "$%_ED_%$") == signature`。
3. 通过后 `JSON.parse(payload)`，`VS` 段映射到 `VersionInfoVO`：`V→version`、`U→url`、`I→info`、`F→forceUpdate`、`E→enabled`；`AD` 段映射成 `Vector.<AdConfVO>`。
4. 成功即 `saveLocalConfig()` 落 `bvnpoly.conf`；全部地址失败则 `readLocalConfig()` 读缓存再解析一次。

**为什么它是死路**：`getAdConf()` 有调用点（`mob/ads/AdManager.as` 的 `_adCtrler.updatePolity(GamePolyCtrl.I.getAdConf())`），`getVersion()` 没有。所以 `VersionInfoVO` 的五个字段被解析、被存进静态字段、被 `getVersion()` 暴露，然后没有任何读者。`forceUpdate` 是纯死字段。这条通道与 `GithubUpdater` 之间也没有任何连接代码（两者互不 import）。

### 4.11 未接线 / 死分支清单（写了但没接上的部分）

| 位置 | 现象 | 证据 |
|---|---|---|
| `utils/UpdateManager.as:UpdateManager.loadUpdate()` | 公共 API，全树零调用点；`launchWUFAN` 走的是 `loadFile()` | 全树搜 `loadUpdate` 只有声明处一行 |
| `scripts/launchWUFAN.as:launchWUFAN._patchLoader` | 只在 `onPatchLoaded()` 里被赋值，从未被读取（`addChild(loader)` 用的是形参） | 字段声明 + 一处赋值 |
| `scripts/launchWUFAN.as:launchWUFAN.setupDebugger()` / `_debugLog` | 建了一个绿色 `TextField`，从未 `addChild`；`startGame()` 里只有 `if(_debugLog && contains(_debugLog)) removeChild(...)`，永远为假 | 全树搜 `_debugLog` 只有声明、构造、`contains` 三处 |
| `mob/ctrls/UpdateCtrl.as:UpdateCtrl.showAlert()` 的 `dlg` 分支 | `dlg = GameUI.alert(...)`，而 `GameUI.alert` 声明为 `:void`，`dlg` 恒为 `null`，`cancelBtn` / `closeBtn` 隐藏逻辑永不执行 | `ui/GameUI.as:GameUI.alert()` 返回类型 `void` |
| `mob/ctrls/GamePolyCtrl.as:GamePolyCtrl.getVersion()` | 返回 `VersionInfoVO`，零调用点 | 全树搜 `getVersion()` 只有声明 |
| `mob/views/ViewManager.as:ViewManager.checkUpdate()` | 名字是「检查更新」，实现是 `URL.go(UpdateURL.getURL(), false)`，打开浏览器 | 该方法体与 `UpdateURL.getURL()` 的解码结果 |
| `MainGame.UPDATE_INFO` | `public static var`，只有读者（`state/MenuState.as` 的 `versionClickHandler`），无写入点 | 全树搜 `UPDATE_INFO` 三处：声明 + `if` + `alert` 参数 |
| `MainGame.VERSION_LABEL` / `VERSION_DATE` | 两个 `const`，零引用 | 全树各只有声明一行 |
| `ui/TitleScreenUI.as:TitleScreenUI.setVersion()` | 形参 `str` 完全没被使用，函数体只清空 `_versionBtn` 的子对象 | 方法体只有 `while(_versionBtn.numChildren > 0) removeChildAt(0)` |

### 4.12 全部文案清单（按出处，逐条对得上）

**`GithubUpdater` 侧 17 条**（网络与落盘）：

| # | 出处 | 触发条件 | 原文 |
|---|---|---|---|
| 1 | `check()` catch | `_checkLoader.load()` 同步抛错 | `Gagal memulai pengecekan: + err.message` |
| 2 | `onCheckComplete()` | `JSON` 里没有 `tag_name` | `Respon GitHub tidak berisi rilis.` |
| 3 | `onCheckComplete()` | `isSafeTag(tag)` 为假 | `Tag rilis tidak valid.` |
| 4 | `onCheckComplete()` | assets 里找不到同名资产 | `Rilis <tag> tidak memiliki file launchWUFAN.swf.` |
| 5 | `onCheckComplete()` | `size <= 0` 或 `> MAX_SIZE_BYTES` | `Ukuran file rilis tidak wajar.` |
| 6 | `onCheckComplete()` catch | `JSON.parse` 抛错 | `Respon GitHub tidak valid: + err.message` |
| 7 | `onCheckIOError()` | `IO_ERROR` / `SECURITY_ERROR` | `Tidak bisa menghubungi GitHub (offline / rate limit).` |
| 8 | `onCheckTimeout()` | 5 秒到 | `Pengecekan update timeout.` |
| 9 | `download()` | `_dlBusy` 为真 | `Download masih berjalan.` |
| 10 | `download()` | `info` 空或 tag 非法 | `Info rilis tidak valid.` |
| 11 | `download()` catch | 建目录、删 tmp、开流等抛错 | `Gagal memulai download: + err.message` |
| 12 | `onDlProgress()` catch | `drainDownload()` 抛错（写盘失败或数据超长） | `Gagal menulis file: + err.message` |
| 13 | `onDlComplete()` | `_dlWritten != info.size` | `Ukuran file tidak cocok (X dari Y bytes).` |
| 14 | `onDlComplete()` | 三字节魔数不是 SWF | `File yang diunduh bukan SWF yang valid.` |
| 15 | `onDlComplete()` catch | `moveTo` 或写 `.ver` 抛错 | `Gagal memasang update: + ex.message` |
| 16 | `onDlIOError()` | 下载期 IO / 安全错误 | `Download gagal: + e.text` |
| 17 | `onStallCheck()` | 20 秒无新字节 | `Koneksi terputus (tidak ada data masuk).` |

**`UpdateCtrl` 侧（标题 3 条 + 正文 5 条）**：

| 位置 | 原文 |
|---|---|
| `onCheckResult()` 标题 | `Update Tersedia` |
| `onCheckResult()` 正文 | `Versi baru tersedia: <name> (<MB> MB)` + 空行 + `shorten(notes,300)` + 空行 + `Tekan OK untuk mengunduh.` |
| `startDownload()` | `Menghubungkan ke GitHub...` |
| `onDlProgress()` | `Mengunduh <name>` + 换行 + `<loaded> / <total> MB (<pct>%)` |
| `onDlDone()` 标题/正文 | `Update Berhasil` / `Patch <name> sudah terpasang.` + 空行 + `Game akan ditutup. Buka kembali untuk menerapkan patch.` |
| `onDlError()` 标题/正文 | `Update Gagal` / `<msg>` + 空行 + `Game dilanjutkan tanpa update.` |

**`UpdateManager` 侧 9 条独立文案（11 个调用点：「另一轮装载在跑」与「Gagal membaca file」各出现两次）**：

| # | 出处 | 原文 |
|---|---|---|
| 1 | `loadUpdate()` / `loadFile()` | `Proses load update lain masih berjalan.` |
| 2 | `loadUpdate()` | `File update '<name>' tidak ditemukan.` + 两条候选路径说明（其中一条写死 `com.jarworld.bleach.bvi`） |
| 3 | `loadFile()` | `Error: file update kosong (0 Bytes).` |
| 4 | `loadFile()` catch | `Gagal Buka Stream: + err.message` |
| 5 | `onStreamProgress()` / `onStreamComplete()` catch | `Gagal membaca file: + err.message` |
| 6 | `onStreamComplete()` | `Error: Pembacaan file menghasilkan 0 Bytes.` + 「若放在 Android/data 之外，请在设置里打开存储权限」 |
| 7 | `onStreamError()` | `Error Stream File: + e.text` |
| 8 | `startLoader()` catch | `Crash saat eksekusi SWF: + err.message` |
| 9 | `onLoaderError()` | `Gagal eksekusi SWF: + errText` |

**装载期的 4 条进度日志**（走 `logTo(_onLog, …)`，在 `launchWUFAN` 里就是 `sendLog`→`trace`，屏幕上看不到）：

```text
1. Memeriksa & memindai penyimpanan eksternal HP...
2. Ukuran file: <x.xx> MB | RAM: <x.x> MB. Membaca file...
3. Pembacaan file berhasil (<x.xx> MB). Memuat SWF...
4. SWF Eksternal Berhasil Dimuat! RAM: <x.x> MB
```

这四条日志带 1~4 编号，说明作者按「扫描 → 读盘 → 装载」三段设计，但 `launchWUFAN.setupDebugger()` 建的调试文本框从未上屏（§4.11），所以这四行只存在于 `trace` 通道。

---

## 5. 陷阱与反编译噪音

> 本节每条都给出「现象 / 证据 / 后果」。凡涉及运行时行为而代码无法穷尽的，统一移到 §7，不在正文里下结论。

**T1 `digitsToInt` 不是语义化版本比较。**
证据：`utils/GithubUpdater.as:GithubUpdater.digitsToInt()` 只保留数字字符；`v1.10.0→1100`、`v2.0.0→200`。
后果：只要某一段进位到两位数，大版本号反过来被判为「更旧」，永远发不出去。

**T2 tag 编号与 `VERSION_CODE` 是两套互不相干的数。**
证据：`check()` 传的是 `launchWUFAN.VERSION_CODE = 104`；远端用 `digitsToInt(tag)`。`V3.7` 解出 37。
后果：若把工程的字面版本号（`V3.7`）直接当 release tag 用，检查恒返回「无更新」。作者实际采用 `v1.0.5` 这类编码，与 UI 上显示的 `V3.7` 无映射关系。

**T3 版本戳先写后验 → 补丁永远装不上且永远不再更新。**
证据：`installDownloaded()` 在 `moveTo` 之后立刻把**远端 tag 数字化值**写进 `.ver`；补丁真正可用与否要等下次启动 `onPatchLoaded()` 比 `extVersion >= VERSION_CODE`；而 `installedVersion()` 只读 `.ver`，`check()` 用 `Math.max(localVersion, installedVersion())` 作基线。
推演：release tag 数字化 = 200、补丁 SWF 内 `VERSION_CODE` = 100、当前基座 104 → 下载装好（`.ver=200`）→ 下次启动 `hint=200 ≥ 104` 不跳过 → 装载后 `extVersion(100) < 104` → 丢弃补丁跑内置 → `.ver` 仍是 200 → 再检查：`_checkLocal = max(104, 200) = 200`，远端 200 不大于 200 → **不再提示更新**。整条链进入终态，代码里没有任何清理 `.ver` 的地方。

**T4 `.tmp` 的生命周期在「进程被杀」这条路上没有兜底。**
证据：`download()` 起手 `if(_dlTmp.exists) _dlTmp.deleteFile();`；`endDownload()` 在 `error != null` 时删；成功路径靠 `moveTo` 移走。
后果：被杀留下的半个 `.tmp` 会在下次下载第 8 步被删，不造成污染；但**旧补丁目录里人工投放的补丁没有任何清理机制**——版本门判旧（`hint < VERSION_CODE`）只是 `startGame()`，文件留在盘上，每次启动都要重新读一次 `.ver`。

**T5 失败即放行，玩家侧静默。**
证据：`onCheckError()` 只 `trace`，`onDlError()` 弹 `Update Gagal` 后 `proceed`，`onCheckResult(null)` 直接 `proceed`。
后果：限流、离线、GitHub 改结构导致的解析失败，全部表现为「这次启动没有更新提示」，没有任何可诊断输出：这三条失败路径只调 `trace`，不写文件、不上报；参考工程的 `debug/Debugger.as` 整份文件没有 `FileStream`，没有文件日志实现。

**T6 `GameUI.alert` 返回 `void`，`dlg` 恒为 `null`。**
证据：`ui/GameUI.as:GameUI.alert()` 签名 `:void`；`UpdateCtrl.showAlert()` 里 `dlg = GameUI.alert(...)`。
性质：反编译产物里「把 void 调用赋给变量」这种形状有两种来源——原码残留（早期 `alert` 有返回值）或反编译噪音；**以这份树无法判定是哪一种**。能确认的是：那段隐藏取消/关闭按钮的代码在本树上不可达，而 `AlertUI.build()` 本来就只建一个 OK 按钮。

**T7 对话框正文会被强制大写。**
证据：`ui/dialog/StyleDialogView.as:StyleDialogView.setMsg()` 的 `_msg.text = en ? en.toUpperCase() : ""`；`UpdateCtrl` 把所有文案放在 `enMsg` 位。
后果：印尼语文案全大写显示；`cnMsg` 传 `null` → 副行恒空。

**T8 进度遮罩是全屏黑底且没有事件处理。**
证据：`showOverlay()` 里 `beginFill(0,0.88)` + `drawRect(0,0,w,h)` 铺满 `stageWidth × stageHeight`，直接 `RootSprite.STAGE.addChild`；`_overlay` 是普通 `Sprite`（`mouseEnabled` 未改）。
后果：按 Flash 命中测试语义，带绘制区域且在最上层、且无监听者的对象会成为命中目标，其下方的游戏 UI 在遮罩期间收不到 `click` / `touchTap`；这条是语义推论，真机复核见 §7 U8。

**T9 进度百分比与落盘字节不是一回事。**
证据：`_dlOnProgress(_dlWritten, Number(_dlInfo.size))`；`_dlFile` 中途从不 `flush()`/`close()`。
后果：进度条涨到 100% 时数据仍在 `FileStream` 缓冲里；此时强杀进程，磁盘上的文件长度小于显示值（下次会被删，不造成错误安装）。

**T10 超长数据的错误文案指错了方向。**
证据：`drainDownload()` 在 `_dlWritten > Number(_dlInfo.size)` 时 `throw new Error("Data melebihi ukuran rilis.")`；该异常被 `onDlProgress()` 的 `catch` 统一包成 `Gagal menulis file: + err.message`。
后果：日志里出现「写文件失败」，实际是「服务端给了比元数据更大的文件」。

**T11 `UpdateManager` 整包预分配。**
证据：`loadFile()` 里 `_bytes = new ByteArray(); _bytes.length = total;`。
后果：装载 300 MiB 上限的补丁时先要 300 MiB 连续内存；`loadFile()` 里只有 `total <= 0` 与读取后 `_readPos == 0` 两道校验，没有对 `MAX_SIZE_BYTES` 的二次把关（下载段的 300 MiB 门在 `onCheckComplete`，手工投放的补丁不过那道门）。

**T12 版本号根本不显示，且三个常量各写一遍。**
证据：`state/MenuState.as:MenuState.build()` 调 `_ui.setVersion("V3.7")`（硬编码字面量，不是 `MainGame.VERSION_LABEL`）；`ui/TitleScreenUI.as:TitleScreenUI.setVersion(str)` 的函数体只做 `while(_versionBtn.numChildren > 0) _versionBtn.removeChildAt(0)`，**完全没有使用 `str`**；`_versionBtn` 在构造处是 `new Sprite()`、`alpha = 0`、无子对象、无 `graphics` 绘制（参考 :605-608）。
后果：标题界面的版本号是空白；`MainGame.VERSION` / `VERSION_LABEL` / `VERSION_DATE` 三个常量零引用，改它们不影响任何显示。

**T13 `versionButton` 不可命中。**
证据：同上，`_versionBtn` 无子对象、无绘制；`MenuState.afterBuild()` 把 `versionClickHandler` 挂在 `_ui.versionButton` 上。
后果：按 Flash 命中测试语义，空 `Sprite` 无命中区域 → `click` 不触发 → `versionClickHandler`（`MainGame.UPDATE_INFO` 的唯一读者）不可达。与 T6 同属「UI 链路在反编译树里断掉」，真机复核见 §7 U9。

**T14 `ViewManager.checkUpdate()` 与 `UpdateURL` 都是命名陷阱。**
证据：方法体只有 `URL.go(UpdateURL.getURL(), false)`；`UpdateURL.getURL()` 解出 `https://www.youtube.com/@ReNexV`；该方法被 `getSettingMenu()` 注册成 `Check Update`（`desc` 是 `Open the update page.`）。
后果：玩家点「检查更新」→ 跳浏览器 → 频道页。真正的更新器只在启动时自动跑一次，没有任何手动触发入口。

**T15 两套定时器互不相干。**
证据：`GithubUpdater` 用的是 `flash.utils.setTimeout` / `clearTimeout`（文件头 `import flash.utils.setTimeout`）；`mob/utils/TimerOutUtils.as:TimerOutUtils` 是另一套（内部 `InsTimer` 包 `flash.utils.Timer` + 静态表 `_timers`），`pauseAllTimer()` / `resumeAllTimer()` 只遍历自己那张表。`scripts/launchWUFAN.as:launchWUFAN.activeHandler()` 在 `deactivate` 时调的是 `TimerOutUtils.pauseAllTimer()`。
后果：切后台并不会通过这套机制暂停检查超时与停摆看门狗。

**T16 `_handled` 防的是回调重入，不是重复检查。**
证据：`UpdateCtrl.update()` 每次都把 `_handled = false` 并重新 `check()`；`check()` 起手 `abortCheck()`。
后果：重复调 `update()` 会中断上一轮检查（上一轮的回调永远不来），`_proceed` 被覆写。当前只有一个调用点，所以是潜在问题而非现症。

**T17 反编译噪音的辨认方法（本树通用）。**
本树是反编译产物：局部变量名一律 `param1` / `_loc1_`，`parseConfig()` 里出现 `var _loc14_:Boolean = false;` 只为在 `catch` 后 `return _loc14_`（未初始化路径读局部变量），`GamePolyCtrl` 的 `loadNext` 闭包被拆成 `*` 类型。这类形状**不要当成 bug 修**；判据是「能否从对外行为上证明」——能证明的写正文，不能证明的进 §7。

**T18 `installedVersion()` 要求 swf 与 ver 同时存在，删一个就把基线打回 0。**
证据：`installedVersion()` 里 `if(!swf.exists || !f.exists || f.size <= 0 || f.size > 32) return 0;`。
后果：只删 `.swf`（或只删 `.ver`）不会让系统「忘掉已装补丁」，而是让基线掉回「传入版本」——若传入版本低于远端，同一个 release 会被重复下载、重复覆盖。

**T19 检查与下载共用一个全静态类，没有并发保护。**
证据：`check()` 起手 `abortCheck()` 后立刻覆写 `_checkResult` / `_checkError` / `_checkLocal`；`download()` 用 `_dlBusy` 挡重入，而 `check()` 没有对应的 busy 标记。
后果：两处同时调 `check()` 时，先发起那一轮的回调永远不来（监听已被摘掉），它的 `proceed` 也不执行。当前 `UpdateCtrl.update()` 是唯一调用点且 `initBackHandler()` 只跑一次，所以是潜在问题。

**T20 装载两步不是事务：swf 换掉了、ver 没写成。**
证据：`installDownloaded()` 先 `moveTo`、后写 `.ver`；`onDlComplete()` 只把异常包成 `Gagal memasang update`，不回滚。
后果：`.ver` 停在旧值时 `installedVersion()` 返回旧值，同一 release 会再次下载；启动侧 `readVersionHint()` 还会拿旧 hint 去比 `VERSION_CODE`，把刚装上的新补丁判成「补丁过期」而跳过（T4 的另一面）。

**T21 更新对话框是启动闸门，玩家不点就进不了游戏。**
证据：`launchWUFAN.updateBack()` 是启动期**唯一**调用 `RootSprite.I.getMainGame().goLogo()` 的地方（另两处在 `state/GameOverState.as` 与 `state/CongratulateState.as`，属于局内回 Logo）；`updateBack` 作为 `UpdateCtrl.update(updateBack, updateBack)` 的两个参数传入，只在 `proceed()` 时执行；`AlertUI.build()` 只建一个 OK 按钮，而 `showAlert()` 里试图隐藏 `cancelBtn`/`closeBtn` 的分支不可达（§4.11）。
后果：检查到「有更新」而玩家一直不点 OK，应用停在启动图，游戏主体不启动。更新是硬要求时这是特性，只做提示时这就是缺陷——移植必须把提示改成非阻塞（§6.2 步骤 3、§6.3 第 4 项）。

**T22 「检查」这一个动作有三个不同实现，互相不认识。**
证据：① `GithubUpdater.check()`（真检查，启动时自动跑一次）；② `ViewManager.checkUpdate()`（跳浏览器，设置菜单里的 `Check Update`）；③ `GamePolyCtrl.getVersion()`（远程配置 `VS` 段，零调用点）。
后果：排查「为什么没有更新提示」时三处都要看，而其中两处与更新无关。

---

## 6. 移植可行性

### 6.1 逐组件判定

| 组件 | 判定 | 原因与改动点 |
|---|---|---|
| `GithubUpdater.check()` 检查段（`onCheckComplete` / `finishCheck` / `abortCheck` / `isSafeTag`） | **能搬（小改）** | 纯 AIR 网络 + 字符串处理，无 ANE、无平台 API。改 3 个常量（`OWNER` / `REPO` / `ASSET_NAME` → 改为主项目 Release 的资产名）；把 `launchWUFAN.VERSION_CODE` 换成主项目自己的构建号（主项目当前**没有**这个常量，要先加） |
| `digitsToInt()` 版本比较 | **要改** | 见 T1/T2。改成分段数值比较（按 `.` 拆，逐段比），并引入一个显式构建号；否则 `v1.10.0` 会压住 `v2.0.0` |
| `download()` + `drainDownload()` + `onDlComplete()` + `looksLikeSwf()` | **能搬（按交付物改末段）** | 分块搬运与停摆看门狗与平台无关。`looksLikeSwf` 只对「交付物是 SWF」成立；若主项目改发 zip（人物包/资源包），末段校验要换成 zip 头并按条目解析 |
| `installDownloaded()` 的 `.ver` 戳 | **要改** | 见 T3：必须先验后用（装载成功后再写 `.ver`），或把 `.ver` 换成「补丁 SWF 内 `VERSION_CODE` 读回值」。原样搬会带着锁死陷阱进主项目 |
| `UpdateManager`（`loadFile` / `startLoader` / `fail` / `onUncaughtError`） | **能搬（内存策略要改）** | 主项目已在用同一套原语：`主项目 ctrl/AssetLoader.as:AssetLoader.loadDisplay()`（`LoaderContext(false)` + `allowCodeImport` + `loadBytes`）、`主项目 utils/ResUtils.as`、`主项目 mob/utils/UIAssetUtil.as`（`ApplicationDomain.currentDomain` + `allowCodeImport = true` + `loadBytes`）。改动点：`_bytes.length = total` 的整包预分配（T11）在手机上要加尺寸上限或改流式 |
| `launchWUFAN` 的引导器结构（`isLoadedByHost` + 版本门 + `addChild(loader)`） | **要改（风险最高）** | 主项目文档类是 `主项目 launch.as:launch`，它同时承担全部启动装配（`ScreenRotater.I.init` / `Debugger.initFileLog` / 缩放 `updateSize` / `UIAssetUtil.I.initalize` / `ScreenPadManager.initlize`）。塞进补丁分支等于把「启动路径」整体纳入回归面，而 `launch.as` 所在的树当前有 66 个未提交改动 |
| `UpdateCtrl` 的 UI（`showAlert` / `showOverlay`） | **能搬但建议重写** | 文案硬编码印尼语且会被 `toUpperCase()`（T7）；`dlg` 分支不可达（T6）；进度层是裸 `Sprite` + `TextField`，与主项目 UI 风格不统一。主项目已有 `主项目 ui/GameUI.as:GameUI.alert()` 可复用；另注意它是**启动闸门**（T21），搬之前先决定「提示是否阻塞」 |
| `GamePolyCtrl` 的签名配置通道 | **要改** | 依赖 `com.adobe.crypto.MD5`，**主项目全树没有 MD5 实现**（搜 `MD5` 零命中）。要用就得把 as3crypto 的 `MD5` 一起搬，或换成主项目能算的校验方式。另：`getVersion()` 零调用点（§4.11），搬过来先要决定谁来读 `VersionInfoVO` |
| `VersionInfoVO` | **能搬** | 纯 VO，5 个公开字段，无依赖 |
| `ChangelogPopup` | **能搬（需补依赖）** | 依赖 `ui/OptKit.as`（3.7 独有的绘制工具类，**主项目没有**）与 `TweenLite`（主项目有，`主项目 com/greensock/`）。搬它等于搬 `OptKit`。另：它的内容是硬编码的 `PATCH 1.0.3 UPDATE` 七行文本（`GameInterfaceManager.getGameMenu()` 里写死（`OTHER` → `CHANGELOG` 项）），与 Release notes 无连接 |
| `UpdateURL` | **不要搬** | 桩类，解出来是外链（T14） |
| Android 侧「替换已安装 APK」 | **搬不了** | 代码里没有任何地方触碰 `File.applicationDirectory`（参考全树只有两处**读**：`mob/utils/FileUtils.as` 与 `mob/AssetLoader.as`，无一处写），装完只 `exit()` 不自重启（4.7）。APK 的更新通道只能是人工安装/应用商店 |

### 6.2 结论：搬「检查 + 提示」，不搬「自替换」

**值不值**：检查与提示这一段值得，自替换这一整段不值得。

**四条理由（都能落到代码上）**：

1. **自替换的真正代价在引导器，不在下载器。** `launchWUFAN` 把「文档类」与「引导器」压在同一个类里，靠 `isLoadedByHost()` 区分身份；主项目的 `launch.as` 已经是 313 行的启动装配器（屏幕旋转、文件日志、缩放、UI 资源、虚拟摇杆全在里面）。要让主项目具备同样的能力，等于重写启动路径——收益是「不用重装 APK」，成本是把整条启动链纳入回归面。而这条链是**最不该动**的那条：它一坏，玩家看到的是黑屏而不是一个功能缺失。
2. **跑得起来这件事已经被主项目自己证明了。** 主项目的 `AssetLoader.loadDisplay()` 从 `Android/media/.../BVN/assets/` 读外置人物 SWF，`ANEFileReader.readBytesAsync` 拿到 `ByteArray` 后同样用 `LoaderContext` + `allowCodeImport` + `loadBytes` 执行代码。也就是说「AIR 在 Android 上执行外部 SWF 代码」在主项目是**现役能力**，不是待验证假设；所以「能不能」不构成搬的理由，「该不该」才是。
3. **两条版本线会分裂。** 主项目的发布物是 APK（GitHub Release 附件），补丁壳走 SWF。一旦补丁先跑起来，`VERSION_CODE`（补丁里的）与 APK 内的构建号就各说各话，而 `.ver` 锁死（T3）正是这种分裂的产物。要么统一到「APK 是唯一版本载体」，要么接受两套号并写死映射——两条都比「只提示」贵。
4. **ANE 不是障碍。** 整条链只 import `flash.events` / `flash.filesystem` / `flash.net` / `flash.utils` / `flash.system` / `flash.display`，没有一行依赖原生扩展。所以「主项目 ANE 已停用」这件事对本专题**不构成限制**（背景见 `CLAUDE.md` 的 ANE 现状一节，此处不展开）。

**只搬「检查 + 提示」的最小改动面**：

| 步骤 | 改哪里 | 具体动作 |
|---|---|---|
| 1 | 新建一个静态类（建议 `utils/VersionCheck.as`） | 搬 `check()` / `onCheckComplete()` / `finishCheck()` / `abortCheck()` / `isSafeTag()`，换成主项目仓库地址；比较算法改成分段数值比较；加 HTTP 状态码分支（`HTTPStatusEvent`）与一次重试 |
| 2 | `主项目 launch.as:launch.initBackHandler()` | 在 `this._mainGame.goLogo()` 之前发起检查（与参考的 `UpdateCtrl.I.update(...)` 同位），但**不要把 `goLogo()` 挂到检查回调上**（否则就是 T21 的闸门） |
| 3 | 提示 | 复用 `主项目 ui/GameUI.as:GameUI.alert()`，正文给「新版本 + 下载页 URL」，按钮只留 OK；下载交给系统浏览器（`主项目 net/play5d/kyo/utils/WebUtils.as:WebUtils.getURL()` 已有 `navigateToURL`）。提示与进 Logo 解耦：先 `goLogo()`，检查结果回来再弹 |
| 4 | 版本号 | 新增 `VERSION_CODE`（整型）作为唯一比较依据，并把 `主项目 MenuState` 里硬编码的 `V2.0.4` 换成常量（顺带修掉主项目同款 T12） |
| 5 | 不做 | 不写 `.ver`、不 `loadBytes`、不 `exit()`、不碰 `applicationStorageDirectory/update` |

**如果坚持要「落盘但不自替换」**（例如用来下发人物包/资源包）：可以搬 `download()` 全套 + `drainDownload()` 的尺寸校验 + `onStallCheck()` 的 20 秒判停，但交付物换成数据包、末段校验换成对应格式头，并且**不要**沿用 `launchWUFAN.swf` / `.ver` 这两个命名，避免与参考工程的人工补丁目录混淆。

### 6.3 若只搬「检查 + 提示」：落地后的自验清单

| # | 验什么 | 判据 |
|---|---|---|
| 1 | 常量替换干净 | 全树搜不到 `RizkyRaya` / `Shonen-Clash` / `launchWUFAN.swf` 三个旧值 |
| 2 | 版本比较保序 | 用 `v1.0.5` / `v1.10.0` / `v2.0.0` 三组 tag 验证「大版本不被小版本压住」，与 §5 T1 的表对照 |
| 3 | 超时可控 | 断网启动，确认最坏等待不超过设定值，且游戏照常进 Logo |
| 4 | 不阻塞启动 | 有更新时先 `goLogo()` 再弹提示，确认玩家不点 OK 也能进菜单（对照 §5 T21） |
| 5 | 失败留痕 | 断网/限流场景能在真机日志里看到一条可检索记录（用 `主项目 Debugger.log`，不是 `trace`，对照 §5 T5） |
| 6 | 文案可读 | 对话框正文不被 `toUpperCase()` 破坏（对照 §5 T7）；若复用 `GameUI.alert`，正文只放短句、详情进第二参 |
| 7 | 手动入口存在 | 设置菜单里那一项要真的触发检查（对照 §5 T14/T22），而不是开浏览器 |
| 8 | 版本号一致 | 界面显示的版本号与 `VERSION_CODE` 同源（对照 §5 T12，主项目当前硬编码 `V2.0.4`） |
| 9 | 零写入 | 确认没有对 `applicationStorageDirectory/update`、没有对 `.ver` 的写操作（不引入 §5 T3/T20 的失败面） |

---

## 7. 未实测清单

以下每一条都是「代码里读不到结论、必须动手才能确认」的项。集中列在这里，正文不出现软断言。

| # | 待验项 | 需要什么手段才能验 |
|---|---|---|
| U1 | GitHub `releases/latest` 的匿名限流在真实设备上的触发频率与表现形式（403 落到 `IOErrorEvent` 还是 `HTTPStatusEvent`） | 真机 + Charles/mitmproxy 抓包；或人为打满额度后启动应用，看 `trace` 是否出现 `Tidak bisa menghubungi GitHub` |
| U2 | `URLStream` 在服务端不返回 `Content-Length` 时是否派发 `ProgressEvent.PROGRESS`（若只派 `COMPLETE`，则 `_dlLastProgress` 不刷新，20 秒看门狗会误杀） | 起一个不设 `Content-Length` 的本地 HTTP 服务，把 `ASSET_NAME` 指向它，观察是否触发 `Koneksi terputus` |
| U3 | `releases/download/<tag>/<asset>` 的 302 跳转在 AIR `URLStream` 上是否自动跟随、跳转后实收字节与 `asset.size` 是否一致 | 抓包看是否出现两次请求；或用一个已知大小不符的 Release 复现 `Ukuran file tidak cocok` |
| U4 | `allowCodeImport = true` 的 `loadBytes` 在 Android 上能否执行来自 `applicationStorageDirectory` 的 SWF（主项目只证明了 `Android/media` 外置目录这一条路） | 真机：往 `…/Local Store/update/` 放一个改过 UI 文案的 `launchWUFAN.swf`，看补丁是否接管 |
| U5 | 隔离域装载后，补丁内的 `RootSprite` / `MainGame` 静态字段是否真的与引导器互不可见（两套单例） | 在补丁与引导器各打一条带域标识的日志，比对是否出现两份 |
| U6 | 补丁运行期崩溃时引导器的表现（`onUncaughtError` 只计数不恢复，崩溃后应用是否直接死） | 故意在补丁里 `throw`，观察进程是否退出 |
| U7 | `GameUI.alert()` 在补丁接管后的可用性（对话框层挂在哪个 `Stage` 上、与补丁自己的 UI 是否叠加） | 真机复现「有更新」状态，看对话框是否正常显示与响应 |
| U8 | 进度遮罩期间底层 UI 是否确实收不到点击（`_overlay` 无监听者但 `mouseEnabled` 默认） | 真机：下载中点击 Logo/菜单区域，看是否穿透 |
| U9 | `TitleScreenUI._versionBtn` 空 `Sprite` 是否真的无法命中（T13 的运行时确认） | 真机点标题界面右下角，看 `versionClickHandler` 是否触发（配合临时日志） |
| U10 | `/storage/emulated/0/assets/update/` 在目标 Android 版本上能否 `createDirectory()`（Android 10+ 分区存储） | 真机：删掉该目录后启动，看日志是否出现 `DIR PERMISSION ERROR`；再核对 APK 的 `targetSdkVersion` 与存储权限声明 |
| U11 | `File.documentsDirectory.requestPermission()` 在目标机型上的弹出时机与拒绝后的行为（`initlize()` 只调一次，未处理拒绝） | 真机首次启动，拒绝授权后重进，看补丁目录是否仍不可用、是否有二次请求 |
| U12 | 参考工程 APK 的 `application.xml` / AndroidManifest 权限集合（参考树只有 `scripts/`，没有描述文件） | 需要参考工程的打包配置，或对成品 APK 做 `aapt dump permissions` |
| U13 | 完整补丁装载的内存峰值（`_bytes.length = total` + `loadBytes` 的副本）在 2GB/3GB 机型上是否 OOM | 真机 + `adb shell dumpsys meminfo`，用一个接近真实体积的补丁 SWF |
| U14 | `flash.utils.setTimeout` 在切后台（`deactivate` 且系统冻结 SWF）时的行为——`_checkTimer` 与 `_dlStallTimer` 是否继续走时（T15 只证到「不归 `TimerOutUtils` 管」，没证到系统冻结下的表现） | 真机：检查/下载途中按 Home 停留 60 秒再回来，看是否立刻报超时或断流 |
| U15 | 下载中按 Home / 锁屏后 `URLStream` 是继续收字节还是断流（决定 20 秒看门狗的误判率） | 真机 + 抓包，比对后台期间字节是否增长、恢复后是否弹 `Koneksi terputus` |
| U16 | 「版本戳锁死」全链（T3）在真机上是否如推演般发生 | 造一个 tag 数字化值 200、内部 `VERSION_CODE` 100 的补丁放进 Release，走完整下载 → 重启 → 再检查，观察是否永久不再提示 |
| U17 | 「更新对话框是启动闸门」（T21）的实际观感：玩家不点 OK 时应用是否停在启动图且无其他入口 | 真机：造出「有更新」状态，点开应用后不操作 60 秒，看是否进入 Logo |
| U18 | 参考工程实际发版时 tag 与 `VERSION_CODE` 的对应约定（代码里只有 `v1.0.5` 这一处痕迹来自文案之外，远端历史在代码里读不到） | 拉该仓库的历史 Release 列表（`api.github.com/repos/RizkyRaya/Shonen-Clash/releases`），比对每版 `tag_name` 数字化值与该版 SWF 的 `VERSION_CODE` 是否同步递增 |

---

## 附：九个必答问题的一句话答复

| 问题 | 答复 |
|---|---|
| 1 更新源形式 / 鉴权 / 限流处理 | GitHub REST `releases/latest` + `releases/download/<tag>/<asset>`；无鉴权、无请求头、无状态码分支；限流只在失败文案里提了一句，无任何处理。`UpdateURL.as` 不是更新源（XOR 解出一个 YouTube 频道页，被设置菜单的 `Check Update` 拿去开浏览器） |
| 2 版本比较算法 / `VERSION_LABEL` 与 tag | 数字拼接整数比较（`digitsToInt`），非语义化；`VERSION_LABEL` 零引用，与 tag 无换算；`v` 前缀因「非数字丢弃」而无影响 |
| 3 检查状态机 / 定时器 / 重试 | 单次请求 + `CHECK_TIMEOUT_MS = 5000`，`_checkTimer` 一次性；`_checkLocal = max(传入, 已装补丁)`；九类结果汇到 `finishCheck()`；零重试、零退避 |
| 4 下载流程 / 临时文件 / 续传 / 停摆 | `URLStream` + `FileStream` 分块；tmp 在 `applicationStorageDirectory/update/launchWUFAN.swf.tmp`；无续传（起手删、错即删、无 `Range`）；停摆判据 `getTimer() - _dlLastProgress > 20000`，5 秒轮询；恢复 = 整体重下 |
| 5 装完怎么用 / 移动端可行性 | 不替换自身：`moveTo` 覆盖 + 写 `.ver` + 提示 + `exit()`；下次启动 `loadBytes` 补丁接管。代码里没有 APK 自更新的任何尝试 |
| 6 进度与 UI / 失败文案 | `_dlOnProgress` → `UpdateCtrl.onDlProgress()`（250ms 节流）→ 全屏黑底 `Sprite` + `TextField`；文案清单见 §4.12（`GithubUpdater` 17 条 / `UpdateManager` 9 条 / `UpdateCtrl` 标题 3 条 + 正文 5 条），全部硬编码印尼语 |
| 7 安全与完整性 | 无哈希、无签名；三道弱门（元数据尺寸范围 / 字节数相等 / 三字节魔数）+ 装载期 `extVersion >= VERSION_CODE`；下完即 `allowCodeImport` 执行 |
| 8 与主项目的关系 | 主项目零更新能力（0 处相关类）；`MainGame.UPDATE_INFO` 无写入点、`MenuState` 首启弹窗不可达；`VERSION` / `VERSION_LABEL` / `VERSION_DATE` 零引用，界面版本号另写死一份 |
| 9 平台差异 | 只写应用私有目录（无需权限）；旧补丁目录在共享存储、需权限且失败即降级；全树无 `applicationDirectory` 写入；整条链不依赖 ANE。manifest 权限集合与分区存储实测见 §7 U10 / U12 |
