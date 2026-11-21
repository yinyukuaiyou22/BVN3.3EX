# 版本号与发行署名（唯一事实源）

> 目的：把「改版本号要改哪几处」「对外署谁的名、指向哪个站」集中到一张表，下次不必全仓 grep。
> 建立：2026-11-21（配合 V2.0.5 测试版角标改动）。改这里的字符串前先读本页。

## 1. 版本号：只手改一个常量，其余自动跟随

| 位置 | 现在写成 | 说明 |
|---|---|---|
| `MainGame.VERSION` | `V2.0.5` | **唯一需要手改的常量** |
| `MenuState._versionTxt` | `MainGame.VERSION + " 测试版"` | 主菜单右下角角标；中文由系统字体渲染 |
| `Debugger` 性能面板 | `"VER: " + MainGame.VERSION` | 真机日志 / 性能面板里的版本行 |
| `launch.as` 的 `URL.MARK` | `bvn_mobV2.0.5` | `URL.markURL()` 会把它拼成 `?bvn_mobV2.0.5` 追进所有外链；保持纯 ASCII，不要放中文 |
| `tools/Test/application.xml` 的 `versionNumber` | `2.0.5` | APK 版本；`versionCode` = 各段 ×10^6 / 10^3（2.0.5 → 2000005） |

`Debugger.BUILD_TAG` 不在此列：`build.bat` 每次编译都会用正则把日期时间强制回写成 `BVN-3.3EX-batch6.14-<yyyy-MM-dd-HHmm>`，手改无效。

## 2. 制作组页（CREDITS）署名与链接

页面文本 = `CreditsState.getCreditsText()`（署名段）+ `GameInterfaceManager.getCreadits()`（追加的链接段）。

| 行 | 文本 | 链接 |
|---|---|---|
| 1 | 原作者：剑jian | 无 |
| 2 | 游戏官网 : 1212321.com | `https://1212321.com/` |
| 3 | 面板BUG反馈 : 改版作者 | `https://space.bilibili.com/485366223` |
| 4 | 反馈邮箱 : yinyu7798@foxmail.com | `mailto:` |
| 5 | 此改版代码仓库 : github.com/yinyukuaiyou22/BVN3.3EX | 同左 |
| 6 | 本版本完全免费，付费获取请举报并申请退款；更新见 7723 游戏盒或作者 B 站私信 | 无 |

- 2026-11-21 起人员名单（设计/美术/研发/特效、人物制作、辅助人物制作、图片资源整理、测试及策划、特殊贡献）**整块删除**，按用户要求只保留原作者署名。
- 英文分支（`GameInterfaceManager.ENGLISH_VERSION`）在 `getCreadits()` 里另有一份硬编码，域名与链接文字要同步（链接文字用 `Mod author`）；只改中文分支会留旧站。
- 官网链接文字写 `1212321.com`，协议用 `https`。实测该域名 http/https 都回 403（拒绝脚本 UA，服务可达），无法核对页面内容，所以只承诺协议与可达性。

## 3. 改完的验收顺序

1. `./build.bat` 零错误（必需，仓库规则）；
2. 进主菜单看右下角角标是否 `V2.0.5 测试版`；
3. 进 `CREDITS` 看 6 行与 3 个可点链接（官网 / 改版作者 / 仓库）；
4. 拿真机日志确认 `VER: V2.0.5`（Debugger 走 `MainGame.VERSION`，与角标同源）。
