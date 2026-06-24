# BVN 死神vs火影 V1.3 -- 银鱼

> 5dplay 原作 | 支持外部资源扩展 | Android ARM64

---

## 安装

### 方式一: 直接安装 APK

1. 下载 `bvn.apk`
2. 传输到手机, 点击安装
3. 允许"安装未知来源应用"

### 方式二: ADB 安装 (开发者)

```bash
adb install bvn.apk
```

安装后桌面出现「死神vs火影银鱼改」图标, 点击启动即可.

---

## 添加外部资源 (自定义角色/地图)

游戏支持从手机存储加载外部资源, 无需修改 APK.

### 第一步: 创建资源目录

在手机存储中创建以下目录结构 (路径区分大小写):

```
内部存储/
└── Android/
    └── data/
        └── air.com.bvn.yinyu/
            └── files/
                └── BVN/
                    └── assets/
                        ├── config/     <- 配置文件
                        ├── fighter/    <- 角色文件 (.swf)
                        ├── map/        <- 地图文件 (.swf)
                        ├── face/       <- 头像图片 (.png/.jpg)
                        └── bgm/        <- 背景音乐 (.mp3)
```

### 第二步: 放入文件

#### 放角色

把角色 `.swf` 文件放入 `fighter/` 目录。例如:

```
fighter/
├── ichigo.swf        <- 黑崎一护
├── naruto.swf        <- 漩涡鸣人
└── custom_xxx.swf    <- 自定义角色
```

#### 放头像

头像文件放入 `face/` 目录。

```
face/
├── ichigo.png        <- 一护小头像
├── ichigo_b.png      <- 一护大头像 (选人界面)
├── ichigo_m.png      <- 一护血条头像
└── ichigo_w.png      <- 一护胜利头像
```

#### 放配置

在 `config/` 下放 `fighter.xml` 来定义外部角色。

`config/fighter.xml` 示例:

```xml
<config>
  <fighter id="ichigo" name="黑崎一护" comic_type="0">
    <file url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/fighter/ichigo.swf"
          startFrame="1"/>
    <face url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/face/ichigo.png"
          big_url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/face/ichigo_b.png"
          bar_url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/face/ichigo_m.png"
          win_url="/storage/emulated/0/Android/data/air.com.bvn.yinyu/files/BVN/assets/face/ichigo_w.png"/>
  </fighter>
</config>
```

其他配置文件同理 -- `assist.xml` (辅助角色)、`map.xml` (地图)、`mission.xml` (闯关模式)、`select.xml` (选人界面布局)。这些文件追加合并到内置配置之后, ID 冲突时内置配置优先.

### 第三步: 启动游戏

放好文件后启动游戏, 外部资源会自动加载.

---

## 用 MT 管理器操作文件

1. 下载安装 [MT 管理器](https://mt2.cn/download/)
2. 打开 MT 管理器 -> 侧拉栏 -> 右上角「添加本地存储」
3. 在列表中找到「死神vs火影银鱼改」-> 点击「选择」
4. 返回后看到新加的本地存储 -> 点击进入
5. 进入 `android_data` -> `files` -> `BVN` -> `assets`
6. 在这里可以直接新建目录、粘贴文件

> 注意: 游戏运行时才能浏览此目录。如果目录为空, 先启动一次游戏让应用自动创建.

---

## 开发者: 打包构建

### 环境要求

| 工具                      | 用途                                                                |
| ------------------------- | ------------------------------------------------------------------- |
| Flex+AIR 合并 SDK         | 放到项目根 `AIRSDK/flex4.16.1-air51.0.1.1/`, 包含 mxmlc + ADT + fdb |
| JDK 17                    | mxmlc 编译器运行时                                                  |
| JDK 8                     | ANE Java 编译 (可选, ANE 当前已禁用)                                |
| Android SDK (platform-33) | ADT platform SDK                                                    |

> SDK 需要自行下载合并。将 Flex 4.16.1 与 AIR 51.0.1.1 合并后放到 `AIRSDK/flex4.16.1-air51.0.1.1/`。调试脚本会自动检测此路径。
> APK 签名证书需自行生成: `adt -certificate -cn <名称> 2048-RSA bin/mycert.p12 <密码>`，放到 `AIRSDK/flex4.16.1-air51.0.1.1/bin/mycert.p12`。

### 构建命令

```bash
# 编译 SWF
.\build.bat

# PC 调试 (启动时询问 SWF 路径, 回车使用默认)
.\tools\script\debug.bat

# 编译 + 打包 APK + 安装 + logcat
.\tools\script\debug_mob.bat

# 断点调试 SWF
.\tools\script\fdbg.bat [swf_file]

# 自动添加角色/辅助/地图工具
python tools\script\add_asset.py --mode wizard
python tools\script\add_asset.py --swf path\to\char.swf --name "角色名" --comic-type 0
```

### APK 打包

白名单打包, 仅以下内容进 APK:

- `assets/effect.swf` (特效)
- `assets/movelist.jpg` (出招表)
- `assets/swf/` (UI SWF)
- `assets/sounds/` (音效)
- `assets/font/` (字体)
- `assets/config/` (XML 配置)

fighter/map/face/bgm 从外部存储加载, 不打包进 APK.

> 完整开发文档见 [CLAUDE.md](CLAUDE.md) 和 [AGENTS.md](AGENTS.md).

---

## 项目结构

```
BVNY/
├── BVNscripts/scripts/          <- AS3 游戏源码
├── extensions/BVNFileReader/    <- ANE 原生扩展 (Java + AS3)
├── tools/
│   ├── Test/                    <- 编译产物 + 运行时资源 + 配置文件
│   ├── script/                  <- 构建/调试脚本
│   └── platform-tools/          <- ADB 工具
├── reference/                   <- 参考代码 (只读)
├── doc/                         <- 架构与规划文档
├── build.bat                    <- 编译入口
├── CLAUDE.md                    <- 开发者完整手册
├── AGENTS.md                    <- AI 助手工作流规则
└── README.md                    <- 用户文档 (本文件)
```

---

## 常见问题

**Q: 放好文件后游戏里看不到新角色?**
A: 检查三点:

1. `fighter/` 目录下有 `.swf` 文件
2. `config/` 下有对应的 `fighter.xml` (定义角色属性、头像路径)
3. 角色 ID 不能与内置角色重复 (内置优先)

**Q: 头像不显示?**
A: `config/fighter.xml` 中 `face` 的四个 `url` 属性必须写完整绝对路径。

**Q: 游戏启动后黑屏/闪退?**
A: 检查 `config/fighter.xml` 是否有 XML 语法错误。

**Q: MT 管理器看不到应用目录?**
A: 确保游戏正在运行 (切换到游戏后再切回 MT 管理器).

---

## 版本

| 项目     | 内容                                        |
| -------- | ------------------------------------------- |
| 游戏版本 | V1.3 (2026.6.24)                            |
| 原作     | 5dplay                                      |
| 修改     | 银鱼 (2v2/1v2 模式 + 翻页优化 + 训练无开场) |
| SDK      | Flex 4.16.1 + AIR 51.0.1.1 (合并包)         |
| 目标     | PC (adl) + Android ARM64                    |
| 许可     | GPL-3.0                                     |
