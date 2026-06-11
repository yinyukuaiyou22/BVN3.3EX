# Proposal — ANE 原生文件读取子系统

## 目标 (Goal)

为 BVN Android 版提供突破 AIR 沙箱限制的原生文件读取能力，实现：
- 从应用私有目录（`app-storage://`）读取外部角色/地图/头像/BGM 资源
- 运行时动态扫描并注册外部资源（追加到 APK 内置资源后）
- 外部配置 XML 合并（fighter/assist/map/mission）
- ANE 不可用时自动降级为 AIR `flash.filesystem.File` API

## 非目标 (Non-Goals)

- 不实现文件写入（当前仅需只读）
- 不支持 iOS 平台（仅 Android-ARM64）
- 不替换 APK 内置资源，仅追加
- 不实现网络文件读取

## 用户与运行时上下文

- **用户场景**：玩家将新角色 `.swf` 放入手机存储的 `BVN/assets/fighter/` 目录后，游戏启动时自动加载
- **运行时环境**：Android 10+ / AIR 51.0 / armv8
- **包名**：`air.com.bvn.yinyu`
- **外部存储路径**：`/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/`

## 功能需求

| ID | 需求 | 状态 |
|----|------|------|
| F1 | ANE 原生读取任意绝对路径文件字节 (`readBytes`) | ✅ 已实现 |
| F2 | ANE 原生列出目录文件 (`listDir`) | ✅ 已实现 |
| F3 | ANE 原生检查路径是否存在 (`exists`) | ✅ 已实现 |
| F4 | ANE 不可用时 AIR File API 降级 | ✅ 已实现 |
| F5 | 扫描外部 `fighter/` 目录注册角色 | ✅ 已实现 |
| F6 | 扫描外部 `map/` 目录注册地图 | ✅ 已实现 |
| F7 | 外部配置 XML 合并（fighter/assist/map/mission） | ✅ 已实现 |
| F8 | 异步非阻塞扫描（setTimeout 防 ANR） | ✅ 已实现 |
| F9 | 自动创建外部目录结构 | ✅ 已实现 |
| F10 | 从绝对路径加载角色 SWF（`loadFighterFromPath`） | ✅ 已实现 |
| F11 | 调试日志覆盖全链路（`Debugger.log` + `trace`） | ✅ 已实现 |
| F12 | ANE 构建自动化（`build_ane.bat` 五步流水线） | ✅ 已实现 |

## 输入与输出

| 方向 | 描述 |
|------|------|
| **输入** | 手机存储中 `BVN/assets/{fighter,map,face,bgm,config}/` 下的资源文件 |
| **输出** | ByteArray（角色/地图 SWF）、Array（目录列表）、Boolean（存在检查）、合并后的 XML 数据模型 |

## 依赖与约束

| 依赖 | 说明 |
|------|------|
| AIR SDK 51.3.2 | ADT 打包 / adl 启动 / fdb 调试 |
| JDK 8 | ANE Java 编译（class v52 兼容 build-tools d8） |
| Android SDK platform-33 | ADT `-platformsdk` |
| FlashRuntimeExtensions.jar | ANE Java 编译依赖（`extensions/BVNFileReader/Android/lib/`） |
| Flex SDK 4.16.1 | compc.jar 编译 SWC |
| 签名证书 | `AIRSDK5/AIRSDK_51.3.2/bin/mycert.p12`（密码 yinyu7798） |

| 约束 | 说明 |
|------|------|
| 仅 Android-ARM64 | extension.xml 仅声明 `Android-ARM64` 平台 |
| 必须三开关 | ANE 启用需 `ANE_ENABLED=true` + `application.xml` extensionID + ADT `-extdir "."` |
| APK 瘦身冲突 | 打包时 fighter/map/face/bgm 被临时移走（空目录打包），ANE 外部路径在应用私有目录 |

## 成功标准

1. 手机启动游戏后，外部 `fighter/` 目录中的 SWF 角色自动出现在选人列表
2. 外部 `config/fighter.xml` 中定义的角色合并到内置角色后
3. ANE 未安装时不崩溃，自动降级为 AIR File API
4. 构建 `build_ane.bat` 一键完成 Java→JAR→SWC→ANE→复制全流程
5. `debug_mob.bat` 一键打包安装并输出 logcat 日志

## 验收检查

- [ ] PC 编译零错误（`./build.bat`）
- [ ] ANE 构建成功（`build_ane.bat`）
- [ ] 手机端外部角色扫描成功（logcat 可见 `[GameLoader] Registered external fighter`）
- [ ] ANE 降级测试：`ANE_ENABLED=false` 时使用 File API 不崩溃
- [ ] 外部 config XML 合并测试：新角色出现在选人列表末尾

## 假设

- 用户的 Android 设备运行 Android 10+（应用私有目录可访问）
- 外部 SWF 文件结构与内置角色 SWF 兼容（含正确的 MovieClip 帧标签）
- 外部 XML 格式与 `tools/Test/assets/config/*.xml` 一致

## 待决问题

1. **`tryLoadExternalXML` 作用域 bug**：`GameLoader.as:335` 中 `basePath` 变量在 `_loadExternalConfigsImpl` 方法内定义，`tryLoadExternalXML` 作为独立方法无法访问该局部变量——运行时必然报错。需确认是否已在未提交修改中修复。
2. **应用私有目录可访问性**：`EXTERNAL_BASE` 指向 `Android/data/` 应用专属目录，用户无法通过文件管理器直接放置资源。是否需要提供引导工具或改用公共目录？
3. **外部资源 ID 冲突**：当前内置优先（重复 ID 跳过外部），但未向用户提示被跳过的资源。
4. **ANE 三开关状态不一致风险**：`ANE_ENABLED` 在代码中设为 `true`，但如果 `application.xml` 中 ANE 被注释或 `debug_mob.bat` 未传 `-extdir`，ANE 将静默失败（降级到 File API）。
