# 高层设计：外部人物兼容层

## 架构

```text
assets/... 请求
      ↓
ExternalAssetResolver
  ├─ ANE EXTERNAL_BASE/<normalized>
  ├─ 可选兼容公共目录
  └─ APK applicationDirectory/assets/...
      ↓
AssetLoader / AssetManager
      ↓
GameLoader 与头像、BGM 消费方
```

## 核心决策

1. 绝对路径直通；相对路径先规范化为 `assets/...`。
2. Android 外部路径由 `ANEFileReader.resolveExternalPath()`、`exists()`、`readBytes()` 提供，禁止在 UI 或 `GameLoader` 重复拼路径。
3. 外部 SWF 扫描只创建最小可加载 VO；外部 XML 负责正式元数据并覆盖占位值。
4. 内置 ID 默认优先；同 ID 外部文件只记录跳过日志。是否允许显式覆盖另立决策。
5. 外部扫描/合并失败仅降级到内置资源，不阻断启动。

## 数据流与时序

`GameData.loadConfig()` 先完成内置配置，再排队外部扫描和 XML 合并。实现阶段必须确认选人 UI 在合并完成前不会冻结；若会，则增加完成事件或列表重建，而不是依赖固定延迟。

## 风险

作用域存储权限、ANE 三开关不一致、路径格式混杂、外部 XML 与 SWF 不匹配、缓存复用旧 Loader、外部头像加载器未接入解析层，是主要风险。所有风险须通过日志和真机用例覆盖。
