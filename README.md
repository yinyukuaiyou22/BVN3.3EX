# BVN 死神 vs 火影 V3.3EX

ActionScript 3 / AIR 项目，支持 PC 编译、Android APK 打包、ANE 外部资源读取和选人界面扩展。Android 真机已验证 `ExternalSample` 能在选人界面出现并从外置目录读取 SWF；外置文件不存在时回退到 APK 内置资源。

## Release 与本轮新增

本轮新增的是一套“外置资源优先、APK 内置资源回退”的兼容层，以及 Android 真机可用的配置合并流程。Release 应同时提供新 APK 和模板包；源码提交只包含文档与 `BVNscripts/scripts/` 下的正常源码。

新增行为：

- 启动时先扫描外置 `fighter/`、`assist/`、`map/` 和 `config/`，再进入选人界面；
- `fighter.xml` 提供人物元数据，`select.xml` 的 `char_list/item/@fighterID` 决定是否显示在选人界面；
- 外置 SWF、头像、BGM 等文件优先读取；同一路径找不到时自动读取 APK 内置 `assets/`；
- 支持 `assets/...`、不带 `assets/` 的相对路径和绝对路径；
- ANE 可用时通过 ANE 读取，ANE 初始化失败时降级到 AIR 文件 API，游戏仍可启动；
- 内置人物与外置人物 ID 冲突时维持内置优先。

Release 附件：`bvn.apk`（本轮重新打包的 APK）和 `external-fighter-template-package.zip`（包含人物、辅助、地图、BGM、配置模板及用户说明）。

## Android 外置资源

Android 包名为 `air.com.bvn.yy798`。外置根目录：

```text
/storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets/
├── config/    fighter.xml、assist.xml、select.xml、map.xml、mission.xml、preload.xml
├── fighter/   人物和辅助 SWF
├── face/      人物和辅助头像
├── map/       地图 SWF 和预览图
├── bgm/       BGM
└── sounds/    音效
```

解析规则：绝对路径直读；`assets/...` 先查外置目录；外置文件不存在时回退 APK。人物必须同时出现在 `fighter.xml` 和 `select.xml/char_list`，并且 SWF、头像 URL 对应文件存在。辅助和地图分别使用 `assist.xml`/`assist_list`、`map.xml`。

### 用户必须手动完成的操作

1. 安装 Release APK，并首次启动一次，让应用创建目录。
2. 将模板 ZIP 解压到电脑；模板中的 `config/` 是整体配置目录，至少要完整保留 `fighter.xml`、`select.xml`，不要只复制其中一页或单个 XML 节点。
3. 把自己的二进制资源放入与 APK 相同的相对目录：人物 SWF 放 `fighter/`，人物头像放 `face/`，辅助放 `assist/`，地图放 `map/`，音乐放 `bgm/`。
4. 在 `config/fighter.xml` 增加 `<fighter id="...">`，让 `file/@url` 指向对应 SWF，并填写头像 URL；然后在 `config/select.xml` 的 `char_list` 中增加同一 ID 的 `<item fighterID="..." .../>`。只改 `fighter.xml` 而不改 `select.xml`，角色会被读取但不会出现在选人界面。
5. 使用 `assets/...` 或不带 `assets/` 的相对 URL 时，路径必须相对于上述 `assets/` 根目录；绝对路径仅用于调试，不适合随模板分发。
6. 将外置 `assets/` 目录复制到 Android 外置根目录。Android 11+ 文件管理器可能无法直接写入该目录，应使用电脑 `adb`、系统授权文件管理器或 Shizuku。
7. 完全退出并重新启动游戏，使配置和选人列表重新构建；若仍不可见，先检查 ID 拼写、SWF 文件名、头像 URL 和日志。

```bash
adb install -r bvn.apk
adb shell mkdir -p /storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets
adb push template-package/. /storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets/
```

模板包里的示例 XML 只提供结构和路径示例，不包含可运行的人物 SWF 或真实图片；发布自己的模板时必须替换为实际文件，并保持 XML 中的 ID、文件名和 `select.xml` 索引一致。

完整说明见 [`doc/external-fighter-37/external-ane-user-guide.md`](doc/external-fighter-37/external-ane-user-guide.md)，模板见 [`doc/external-fighter-37/template-package/`](doc/external-fighter-37/template-package/)。

## 构建

源码基准目录是 `BVNscripts/scripts/`。常用命令：

```text
./build.bat
extensions/BVNFileReader/build_ane.bat
tools/script/debug_mob.bat
```

打包前设置签名密码环境变量，密码不写入文档或脚本：

```powershell
$env:BVN_KEYSTORE_PASS = "<本机证书密码>"
tools/script/debug_mob.bat
```

ANE 三开关必须一致：`ANEFileReader.as` 的 `ANE_ENABLED`、`application.xml` 的 `com.bvn.filereader`、`debug_mob.bat` 的 `-extdir` 和 `BVNFileReader.ane`。ANE 不可用时保持 AIR 文件 API 降级。

## 日志

```text
/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log
```

```bash
adb exec-out run-as air.com.bvn.yy798 cat "/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log"
adb logcat -v threadtime | findstr /i "AdobeAIR BVNFileReader ANEFileReader GameLoader EXT-RESOLVE EXT-READ FATAL"
```

`SelectedUI setFighter id=...` 表示角色进入选人列表；`EXT-RESOLVE ... external` 表示外置命中；`apk-fallback` 表示回退 APK。

## 提交边界

默认不提交 `tools/Test/` 生成物、`assets/`、`*.swf`、`*.apk`、`*.ane`、`.backup/`、`.agents/` 和 `.codex/`。APK 和模板包只作为 GitHub Release 附件发布。`BVNscripts/scripts/` 是可编译源码基准，修改源码后运行 `./build.bat`。

## 许可

项目代码、原始游戏资源、第三方库和用户导入资源分别遵守各自许可；发布自定义资源前请确认拥有授权。
