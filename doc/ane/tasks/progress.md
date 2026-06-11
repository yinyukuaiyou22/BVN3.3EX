# Progress — ANE 原生文件读取子系统

## 当前状态

**阶段**：基本功能已实现，存在 1 个已知阻塞 bug（`tryLoadExternalXML` 作用域），待修复后进入稳定验证。

**最后更新**：2026-06-11（修复 T17/T18/T21，基于 plan hidden-inventing-otter）

## 任务

### 已完成 ✅

- [x] **T1: ANE Java 层实现** — BVNFileReaderExtension + ExtensionContext + 3 FREFunctions
- [x] **T2: ANE AS3 库** — BVNFileReaderLib.as (SWC 源)
- [x] **T3: ANE 封装层** — ANEFileReader.as 单例 + ANE_ENABLED 开关 + File API 降级
- [x] **T4: 外部角色扫描** — scanExternalFighters / scanExternalMaps
- [x] **T5: 外部配置 XML 合并** — loadExternalConfigs / tryLoadExternalXML (有 bug)
- [x] **T6: 异步非阻塞扫描** — setTimeout 2s + 3s 延迟
- [x] **T7: 外部目录自动创建** — ensureExternalDirs
- [x] **T8: 绝对路径角色加载** — loadFighterFromPath (ByteArray → Loader → FighterMain)
- [x] **T9: ANE 构建流水线** — build_ane.bat (Java→JAR→SWC→ANE→Copy)
- [x] **T10: 应用配置** — application.xml extensionID 取消注释
- [x] **T11: APK 瘦身与 ANE 协调** — fighter/map/face/bgm 打包时空目录 + 恢复
- [x] **T12: 调试日志全链路** — Debugger.log + trace 覆盖所有关键节点
- [x] **T13: ANE 路径迁移** — 改为应用私有目录 `Android/data/air.com.bvn.yinyu/files/`
- [x] **T14: PC 编译通过** — build.bat 输出 4.29MB SWF
- [x] **T15: AIR 51 + Android-ARM64 适配** — extension.xml + build_ane.bat 平台修正
- [x] **T16: JDK 8 编译强制** — build_ane.bat 锁定 D:\JDK8

### 待完成 🔲

- [x] **T17: 🔴 修复 `tryLoadExternalXML` 作用域 bug** — 添加 basePath 参数 + 更新 4 调用点
- [x] **T18: 外部角色缺少头像属性** — 修正 FighterModel/AssisterModel/MapModel 的 mergeByXML 去掉 skip-duplicate 守卫，外部 fighter.xml 可覆盖 SWF 扫描的占位条目（注：运行时 face 加载链路需后续 ANE 适配）
- [x] **T21: 外部资源引导工具** — ANEFileReader.as 注释添加 adb push 命令示例 + EXTERNAL_BASE 路径说明
- [ ] **T19: ANE 开关一致性自检** — 启动时校验 ANE_ENABLED + application.xml + hasANE 三方一致
- [ ] **T20: 手机端真机集成测试** — debug_mob.bat 打包安装 + 外部资源放置 + logcat 验证
- [ ] **T21: 外部资源引导工具** — ~~PC 端脚本将资源推送到应用私有目录（`adb push`）~~ 已通过 ANEFileReader 注释 + 日志输出完成基础引导
- [ ] **T22: 用户文档** — 如何添加外部角色/地图/配置的说明
- [ ] **T23: 合并后 UI 刷新** — 确认外部配置合并后选人列表是否需要重新渲染

## 已运行命令

```bash
# PC 编译
./build.bat                          # ✅ Exit: 0, SWF: 4.29MB

# ANE 构建
extensions/BVNFileReader/build_ane.bat  # ✅ 五步全部通过

# 手机调试
tools/script/debug_mob.bat           # 需真机验证
```

## 决策记录

| 日期 | 决策 | 原因 |
|------|------|------|
| 2026-06 | 外部路径改为应用私有目录 | Android 10+ 分区存储要求（`42f2ffb`） |
| 2026-06 | 外部扫描改为异步 setTimeout | 防止启动 ANR（`90a4842`） |
| 2026-06 | build_ane.bat 锁定 JDK 8 | class v52 兼容 build-tools d8（`eb08c73`） |
| 2026-05 | ANE 平台 fixed to Android-ARM64 | 仅支持 armv8（`4df4807`） |
| 2026-05 | 放弃 AIR 33.1，回到 AIR 51 | ANE 不兼容旧版 AIR（`d228fd8`） |

## 阻塞项

| 阻塞 | 影响任务 | 说明 |
|------|----------|------|
| （无） | — | 之前阻塞 bug 已全部修复 |

## 下一步

1. **短期**：真机集成测试（T20） + ANE 开关自检（T19）
2. **中期**：外部角色 face 加载链路 ANE 适配（T18 后续） + 用户文档（T22）
3. **长期**：合并后 UI 刷新验证（T23）
