# 进度

- [x] 完成 3.7 与主项目源码勘察
- [x] 明确排除 `launchWUFAN.swf` 热更新及 Continue/Gamepad
- [x] 形成兼容层高层设计
- [x] 形成详细接口、错误和测试契约
- [x] 拆分资源解析、人物注册、附属资源、Android 验证任务
- [x] 实现统一资源解析层（`AssetLoader`：XML/SWF/Bitmap/Sound 外部优先，APK 回退）
- [x] 接入 ANE 打包链（`application.xml` 扩展 + `debug_mob.bat -extdir`）
- [x] 完成 PC 编译、ANE 构建、APK 打包和真机安装
- [x] 推送示例 `ExternalSample.swf` 与外部 `fighter.xml` 到设备目录
- [x] 修正资源根目录：ANE 返回应用外部目录父级，实际为 `.../air.com.bvn.yy798/BVN/assets/`，不是 `.../files/BVN/assets/`
- [x] 示例补齐完整 `config`（fighter/assist/select/map/mission/preload），并在 `select.xml` 增加 `ExternalSample` 索引
- [x] 示例 `fighter.xml` 使用主项目完整人物配置并追加外部人物，补充 face URL
- [x] 实施资源解析增强：规范化相对路径/查询串、记录外部命中与 APK 回退、修正 yy798 回退根目录
- [x] PC 编译验证：`./build.bat`（Exit 0，launch.swf 生成）
- [x] ANE 重建验证：`extensions/BVNFileReader/build_ane.bat`（JAR/SWC/ANE 成功）
- [x] Android APK 打包验证：`tools/script/debug_mob.bat`（ADT 打包成功）
- [ ] 在真机选人界面确认外部人物可见并进入战斗（阻塞：本次执行未检测到连接设备）
- [ ] 读取真机 `bvn_debug.log` 确认 ANE 初始化和外部命中日志

## 已运行检查

- `rg` 定位 3.7 `launchWUFAN.as`、`mob/AssetLoader.as`、`ctrl/GameLoader.as` 与主项目对应实现。
- 对照 `doc/ane/`、`CLAUDE.md`、`AGENTS.md` 的现有 ANE 约束。

## 阻塞项

- 需要在实现阶段确认真实设备的作用域存储访问和选人 UI 刷新行为。
- 当前设备安装/启动已完成，但自动脚本未提供可见的应用日志；需在设备上进入选人界面后再抓取文件日志确认最终业务链路。
- 2026-09-09：本轮 APK 已成功打包，但 `debug_mob.bat` 报告 `No device connection detected`，未执行安装、启动和日志采集。
