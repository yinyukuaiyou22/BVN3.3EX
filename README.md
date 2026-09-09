# BVN 死神 vs 火影 V3.3EX

ActionScript 3 / AIR 项目，支持 PC 编译、Android APK 打包、ANE 外部资源读取和选人界面扩展。Android 真机已验证 `ExternalSample` 能在选人界面出现并从外置目录读取 SWF；外置文件不存在时回退到 APK 内置资源。

## Release

GitHub Release 提供本轮新打包的 Android APK 和包含用户说明的自定义外置资源模板包 ZIP。源码提交只包含源码和文档，不把生成的 SWF、ANE 和大型资源混入源码。

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

```bash
adb install -r bvn.apk
adb shell mkdir -p /storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets
adb push template-package/. /storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets/
```

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
