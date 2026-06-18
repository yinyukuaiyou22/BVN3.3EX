# BVN 死神vs火影 V3.3 — 银鱼改

> 5dplay 原作 | 支持外部资源扩展 | Android ARM64

---

## 📱 安装

### 方式一：直接安装 APK

1. 下载 `bvn.apk`
2. 传输到手机，点击安装
3. 允许"安装未知来源应用"

### 方式二：ADB 安装（开发者）

```bash
adb install bvn.apk
```

安装后桌面出现「死神vs火影银鱼改」图标，点击启动即可。

---

## 🗂️ 添加外部资源（自定义角色/地图）

游戏支持从手机存储加载外部资源，无需修改 APK。

### 第一步：创建资源目录

在手机存储中创建以下目录结构（路径**区分大小写**）：

```
内部存储/
└── Android/
    └── data/
        └── air.com.bvn.yinyu/
            └── files/
                └── BVN/
                    └── assets/
                        ├── config/     ← 配置文件
                        ├── fighter/    ← 角色文件 (.swf)
                        ├── map/        ← 地图文件 (.swf)
                        ├── face/       ← 头像图片 (.png/.jpg)
                        └── bgm/        ← 背景音乐 (.mp3)
```

### 第二步：放入文件

#### 放角色

把角色 `.swf` 文件放入 `fighter/` 目录。例如：

```
fighter/
├── ichigo.swf        ← 黑崎一护
├── naruto.swf        ← 漩涡鸣人
└── custom_xxx.swf    ← 自定义角色
```

#### 放头像

头像文件放入 `face/` 目录。游戏会从 `config/fighter.xml` 中读取每个角色对应的头像文件名，所以文件名可以是任意的。

```
face/
├── ichigo.png        ← 一护小头像
├── ichigo_b.png      ← 一护大头像（选人界面）
├── ichigo_m.png      ← 一护血条头像
└── ichigo_w.png      ← 一护胜利头像
```

#### 放配置

在 `config/` 下放 `fighter.xml` 来**定义**外部角色。这是最关键的一步——没有它，角色 SWF 虽然能被扫描到，但没有头像、名字、BGM 等信息。

`config/fighter.xml` 示例：

```xml
<config>
  <fighter id="ichigo" name="黑崎一护" comic_type="0">
    <file url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/fighter/ichigo.swf"
          startFrame="1"/>
    <face url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/face/ichigo.png"
          big_url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/face/ichigo_b.png"
          bar_url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/face/ichigo_m.png"
          win_url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/face/ichigo_w.png"/>
    <contact>
      <friend></friend>
      <enemy></enemy>
    </contact>
    <says>
      <say_item>月牙天冲！</say_item>
    </says>
    <bgm url="" rate="0"/>
  </fighter>
</config>
```

> **提示**：其他配置文件同理——`assist.xml`（辅助角色）、`map.xml`（地图）、`mission.xml`（闯关模式）、`select.xml`（选人界面布局）。这些文件**追加合并**到内置配置之后，ID 冲突时内置配置优先。

### 第三步：启动游戏

放好文件后启动游戏，外部资源会自动加载。

---

## 🛠️ 用 MT 管理器操作文件

如果你不想手动创建目录，可以使用 **MT 管理器** 进行可视化操作：

1. 下载安装 [MT 管理器](https://mt2.cn/download/)
2. 打开 MT 管理器 → 侧拉栏 → 右上角「添加本地存储」
3. 在列表中找到「死神vs火影银鱼改」→ 点击「选择」
4. 返回后看到新加的本地存储 → 点击进入
5. 进入 `android_data` → `files` → `BVN` → `assets`
6. 在这里可以直接新建目录、粘贴文件

> **注意**：游戏运行时才能浏览此目录。如果目录为空，先启动一次游戏让应用自动创建。

---

## 🖥️ 开发者：打包构建

### 环境要求

| 工具 | 用途 |
|------|------|
| Flex SDK 4.16.1 (AIR 51) | 编译 ActionScript → SWF |
| AIR SDK 51.3.2 | 打包 APK / 调试 |
| JDK 8 | ANE Java 编译 |
| Android SDK (platform-33) | ADT platform SDK |

### 构建命令

```bash
# 编译 SWF
.\build.bat

# 编译 + 打包 APK + 安装 + logcat
.\tools\script\debug_mob.bat

# 重建 ANE 扩展
.\extensions\BVNFileReader\build_ane.bat
```

> 完整开发文档见 [CLAUDE.md](CLAUDE.md) 和 [AGENTS.md](AGENTS.md)。

---

## 📂 项目结构

```
BVNY/
├── BVNscripts/scripts/          ← AS3 游戏源码
├── extensions/BVNFileReader/    ← ANE 原生扩展 (Java + AS3)
├── tools/
│   ├── Test/                    ← 编译产物 + 运行时资源 + 配置文件
│   ├── script/                  ← 构建/调试脚本
│   └── platform-tools/          ← ADB 工具
├── reference/                   ← 参考代码（只读）
├── doc/                         ← 架构与规划文档
├── build.bat                    ← 编译入口
├── CLAUDE.md                    ← 开发者完整手册
└── AGENTS.md                    ← AI 助手工作流规则
```

---

## ❓ 常见问题

**Q: 放好文件后游戏里看不到新角色？**
A: 检查三点：
1. `fighter/` 目录下有 `.swf` 文件
2. `config/` 下有对应的 `fighter.xml`（定义角色属性、头像路径）
3. 角色 ID 不能与内置角色重复（内置优先）

**Q: 头像不显示？**
A: `config/fighter.xml` 中 `face` 的四个 `url` 属性必须写**完整绝对路径**（如示例中的 `/storage/emulated/0/...`）。

**Q: 游戏启动后黑屏/闪退？**
A: 检查 `config/fighter.xml` 是否有 XML 语法错误（缺少闭合标签、特殊字符未转义等）。

**Q: MT 管理器看不到应用目录？**
A: 确保游戏正在运行（切换到游戏后再切回 MT 管理器），或者调用游戏内的"注册文件提供器"功能（如果可用）。

---

## 📋 版本

| 项目 | 内容 |
|------|------|
| 游戏版本 | V3.3（2019.3.32） |
| 原作 | 5dplay |
| 修改 | 银鱼改 |
| 引擎 | Adobe AIR 51.3.2 |
| 目标 | Android ARM64 (64位) |
| 许可 | GPL-3.0 |
