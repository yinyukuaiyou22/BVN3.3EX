# BVN（死神vs火影）V3.3 — 银鱼改

> 5dplay 原作 | AS3 反编译修复 | Android APK 打包 | ANE 扩展支持

## 快速开始（开发者）

### 环境要求

| 工具 | 位置 | 用途 |
|------|------|------|
| Flex SDK 4.16.1 (AIR 51) | `flex4.16.1-air51.0.1.1/` | mxmlc 编译 SWF |
| AIR SDK 51.3.2 | `AIRSDK/AIRSDK_51.3.2/` | ADT 打包 APK / adl 调试 |
| JDK 21 | `C:\Program Files\Java\jdk-21.0.11\` | mxmlc / ADT 运行时 |
| JDK 8 | `D:\JDK8\` | ANE Java 编译（d8 兼容） |
| Android SDK | `D:\Android\SDK\` | ADT `-platformsdk` |
| ADB | `tools\platform-tools\adb.exe` | 设备调试 |

### 一键命令

```bash
# PC 编译
.\build.bat

# PC 调试（ADL 启动）
.\tools\script\debug.bat

# 手机打包 + 安装 + 日志（全程自动）
.\tools\script\debug_mob.bat

# ANE 重建（Java 源码修改后）
.\extensions\BVNFileReader\build_ane.bat
```

### 外部资源

手机文件管理器在 `/storage/emulated/0/` 下创建 `BVN/assets/`，放入：

```
/storage/emulated/0/BVN/assets/
├── fighter/    ← 角色 SWF
├── map/        ← 地图 SWF
├── face/       ← 头像 PNG
├── bgm/        ← 背景音乐
└── config/     ← 额外 XML 配置（追加合并）
```

启动游戏即可自动加载。内置优先，外部追加在后。

### 项目结构

```
BVNY/
├── BVNscripts/scripts/    ← AS3 源码
├── tools/Test/            ← 编译产物 + 运行时资源
├── tools/script/          ← 调试/打包脚本
├── extensions/BVNFileReader/ ← ANE 扩展（Java + AS3）
├── flex4.16.1-air51.0.1.1/  ← Flex SDK
├── AIRSDK/AIRSDK_51.3.2/    ← AIR SDK
├── build.bat              ← 编译
├── CLAUDE.md              ← 项目完整文档（AI + 人类）
└── AGENTS.md              ← AI 行为准则
```

## AI Agent 开发指引

### 模型策略

- 简单任务 → `deepseek-v4-flash`（搜索、单文件修改）
- 复杂任务 → `deepseek-v4-pro`（多文件、架构、Bug）
- 路由工具：`python tools/route_model.py "<任务描述>" --json`

### 关键规则

1. 所有回答中文，禁止整段英文
2. 修改后必须 `.\build.bat` 编译验证
3. 涉及 ≥4 文件时联动排查 + 更新文档
4. 不要动 `_assets/` 中的二进制文件、`mx/core/` 框架桩

### ANE 开发速查

```
ANE 启用三开关（需同步开启）:
  application.xml:     取消注释 <extensions>
  ANEFileReader.as:    ANE_ENABLED = true
  debug_mob.bat:       ADT 命令含 -extdir "." + -platformsdk

ANE 重建:
  1. D:\JDK8\ 编译 Java → JAR
  2. compc (Flex SDK) 编译 AS3 → SWC
  3. adt (AIR SDK) 打包 → .ane → 复制到 tools/Test/

关键修复点:
  - 平台名: Android-ARM64（armv8 架构）
  - Java: JDK 8（class v52，d8 兼容）
  - airglobal.swc: 用 AIR 51 SDK 的
  - extension.xml: namespace 32.0
```

## 版本信息

| 项目 | 内容 |
|------|------|
| 游戏版本 | V3.3（2019.3.32） |
| 引擎 | Adobe Flash / AIR 51.3.2 |
| 编译器 | Flex 4.16.1 mxmlc |
| 目标平台 | Android armv8 (64位) |
| ANE | com.bvn.filereader（文件读取） |
| 许可 | GPL-3.0 |
