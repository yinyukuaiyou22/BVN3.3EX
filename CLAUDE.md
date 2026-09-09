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

## 外部资源契约

Android 包名是 `air.com.bvn.yy798`，外置根目录是 `/storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets/`。目录约定为 `config/`、`fighter/`、`face/`、`map/`、`bgm/`、`sounds/`。

`fighter.xml` 定义人物；`assist.xml` 定义辅助；`map.xml` 定义地图和地图 BGM；`select.xml` 决定人物/辅助是否在选人界面出现；`preload.xml` 定义预加载资源。

`AssetLoader` 的解析顺序固定为：绝对路径直读；`assets/...` 相对 URL 规范化后先查外置目录；不存在时加载 APK 内置 URL。日志使用 `EXT-RESOLVE` 标记命中来源。外部人物必须同时拥有 XML `<fighter id>`、可读取的 SWF 和 `select.xml/char_list` 中同名 `<item>`；缺少 SWF 时不进入可选列表。

主项目流程是：APK 配置初始化模型，`GameLoader` 扫描外部 SWF 建立占位 VO，再合并外部 XML 覆盖元数据，最后在选人界面构建前完成 `select.xml`。内置人物 ID 冲突保持内置优先。

## ANE 构建与三开关

真实 ANE 运行需要三处一致：`ANEFileReader.as` 的 `ANE_ENABLED`、`tools/Test/application.xml` 的 `com.bvn.filereader` 扩展、`debug_mob.bat` 的 `-extdir` 和 `BVNFileReader.ane`。

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

`SelectedUI setFighter id=...` 表示角色已进入选人列表；`EXT-RESOLVE ... external` 表示外置命中；`apk-fallback` 表示回退 APK；`ANE init ERROR` 表示扩展初始化失败，应继续检查 AIR 降级读取结果。

## 代码审查与提交

提交前只选择用户明确纳入的文件，并运行 `git diff --check`、`git diff --stat --cached`。扫描密码、令牌、私钥、本机路径、设备标识和临时日志。文档中的 Android 公共路径可以保留，真实设备序列号和签名凭据必须移除。

正常代码只从 `BVNscripts/scripts/` 选择性提交；本轮文档只提交 `README.md`、`CLAUDE.md`。参考代码、`tools/Test/`、模板 ZIP 和 APK不进入源码提交；APK 和模板 ZIP 在 GitHub Release 中作为附件上传。

## 交付验收

- `./build.bat` 通过并生成 SWF；
- ANE 构建和 APK 打包成功；
- 真机日志确认外部人物 ID、SWF 命中和 APK 回退；
- Release 附件是本轮新 APK 和带用户说明的模板 ZIP；
- Git diff 不包含参考源码、测试二进制、凭据或设备隐私。
