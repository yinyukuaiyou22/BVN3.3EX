# Android 外置 ANE 资源使用说明

本说明适用于当前 Android 主线（包名 `air.com.bvn.yy798`）。程序启动时先读取 APK 内置 `assets/`；对于 `assets/...` 相对 URL，会优先检查外置目录，外置文件不存在时自动回退 APK。外置文件存在但损坏时不会静默替换，以便从日志定位问题。

## 外置目录

```text
/storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets/
  config/   fighter/   face/   bgm/   map/   sounds/
```

使用 ADB 推送模板包（设备已连接且允许调试）：

```text
adb shell mkdir -p /storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets
adb push template-package/. /storage/emulated/0/Android/data/air.com.bvn.yy798/BVN/assets/
```

文件管理器无法访问 `Android/data` 时，请使用 ADB 或具备作用域存储权限的文件管理器。不要把文件放到 `/data/user/0/...`，该目录是应用私有日志目录，不是用户资源入口。

## 必备文件关系

- `config/fighter.xml`：人物 ID、名称、SWF、头像、BGM 元数据。
- `config/assist.xml`：辅助角色定义。
- `config/map.xml`：地图 SWF、预览图和 BGM。
- `config/select.xml`：选人界面索引；人物必须在 `char_list` 中出现才可见，辅助必须在 `assist_list` 中出现。
- `config/preload.xml`：预加载 BGM/音效清单，可按需补充。

每个 `id` 必须唯一。`file/@url`、`face/@url`、`img/@url`、`bgm/@url` 推荐写成 `assets/...`，并确保对应文件实际存在。SWF 可使用旧式根 MovieClip；新式人物包可提供 `main_mc`。

## 日志检查

```text
adb logcat -v threadtime | findstr /i "BVNFileReader ANEFileReader GameLoader EXT-RESOLVE EXT-READ FATAL"
```

应用文件日志位于：

```text
/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log
```

重点确认 `SelectedUI setFighter id=...`、`EXT-RESOLVE ... external` 和 `readBytes...`。出现 `apk-fallback` 表示外置文件未找到，属于预期回退行为。

