# BVN 死神vs火影 V3.3 — 银鱼改

> 基于 [5dplay](http://www.5dplay.net/) 原作的反编译修复与功能扩展版。
> PC + Android 双端 | 角色 / 地图 / 辅助可外置加载 | 2v2 / 1v2 / 观战等多模式

[![版本](https://img.shields.io/badge/version-V3.3-blue)](tools/Test/application.xml)
[![构建](https://img.shields.io/badge/build-BVN--3.3EX--batch6.14--2026--09--02--1219-green)](BVNscripts/scripts/net/play5d/game/bvn/Debugger.as)
[![SDK](https://img.shields.io/badge/SDK-Flex%204.16.1%20%2B%20AIR%2051.0.1.1-orange)](flex4.16.1-air51.0.1.1/)
[![平台](https://img.shields.io/badge/platform-PC%20%7C%20Android%20ARM64-lightgrey)](tools/Test/application.xml)
[![许可](https://img.shields.io/badge/license-GPL--3.0-red)](debug_mob.bat)

---

## 目录

- [玩家](#-玩家)
  - [安装 APK](#-安装-apk)
  - [加载外部资源](#-加载外部资源角色地图)
  - [多模式一览](#-多模式一览)
- [开发者](#-开发者)
  - [环境要求](#-环境要求)
  - [构建脚本](#-构建脚本)
  - [编译关键参数](#-编译关键参数)
  - [项目结构](#-项目结构)
- [变更记录](#-变更记录)
- [常见问题](#-常见问题)
- [许可](#-许可)

---

## 玩家

### 安装 APK

#### 方式一：直接安装

1. 下载 `bvn.apk`
2. 传输到手机，点击安装
3. 允许"安装未知来源应用"

#### 方式二：ADB 安装（开发者）

```bash
adb install bvn.apk
```

安装后桌面出现 **死神vs火影银鱼改** 图标，点击启动。

> **应用包名澄清**（无需关心）：AIR 私有目录 ID 为 `com.bvn.yy798`，Android 端包名为 `air.com.bvn.yy798`（因历史 applicationID 派生规则）。游戏运行时优先从 `/Android/data/<app 包名>/files/BVN/assets/` 读取外部资源，详情见下节。

### 加载外部资源（角色/地图）

游戏支持从手机存储加载外部资源，**无需修改 APK**。

游戏运行时，会按以下顺序在外部存储查找：

```
/Android/data/<包名>/files/BVN/assets/   ← 优先
└── config/    配置文件（追加合并到内置配置）
├── fighter/   角色 .swf
├── map/       地图 .swf
├── face/      头像 .png / .jpg
├── bgm/       背景音乐 .mp3
├── sounds/    音效
├── font/      字体
└── swf/       UI SWF
```

> 具体路径中的 `<包名>` 在不同安装版本下不同（由 AIR applicationID 决定），但 MT 管理器可一键定位，无需手动输入路径。

#### 操作流程（MT 管理器）

1. 安装 [MT 管理器](https://mt2.cn/download/)
2. 打开 MT → 侧拉栏 → 右上角"添加本地存储"
3. 找到"死神vs火影银鱼改" → 点击"选择"
4. 返回后进入新加的本地存储 → `android_data` → `files` → `BVN` → `assets`
5. 直接新建目录、粘贴文件

> 注意：游戏运行时才能浏览此目录。如果目录为空，先启动一次游戏让应用自动创建。

#### 资源清单

| 资源类型 | 目录 | 格式 | 命名要求 |
|---|---|---|---|
| 角色 | `fighter/` | `.swf` | 文件名任意（用 XML 关联 ID）|
| 地图 | `map/` | `.swf` | 同上 |
| 头像 | `face/` | `.png` `.jpg` | 命名见 XML 配置 |
| BGM | `bgm/` | `.mp3` | 命名见 XML 配置 |
| 辅助角色定义 | `config/assist.xml` | XML | 追加合并 |
| 角色定义 | `config/fighter.xml` | XML | **必需**，定义属性/头像路径 |
| 选人界面 | `config/select.xml` | XML | 追加合并 |
| 地图列表 | `config/map.xml` | XML | 追加合并 |
| 闯关关卡 | `config/mission.xml` | XML | 追加合并 |

#### 角色定义示例（`config/fighter.xml`）

```xml
<config>
  <fighter id="ichigo" name="黑崎一护" comic_type="0">
    <file url="/storage/emulated/0/Android/data/<包名>/files/BVN/assets/fighter/ichigo.swf"
          startFrame="1"/>
    <face url=".../face/ichigo.png"
          big_url=".../face/ichigo_b.png"
          bar_url=".../face/ichigo_m.png"
          win_url=".../face/ichigo_w.png"/>
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

> **冲突规则**：内置配置优先。如果新角色 ID 与内置角色重复，将忽略外部定义。

#### 自动添加工具

```bash
# 向导模式（交互）
python tools/script/add_asset.py --mode wizard

# 快速模式（直接添加一个角色）
python tools/script/add_asset.py --swf path/to/char.swf --name "角色名" --comic-type 0

# 批量模式
python tools/script/add_asset.py --mode batch
```

### 多模式一览

游戏模式在 `BVNscripts/scripts/net/play5d/game/bvn/data/GameMode.as` 定义。当前实现：

| 模式 | 常量 | 值 | 选人数 | 菜单入口 |
|---|---|---|---|---|
| 小队闯关 | `TEAM_ACRADE` | 10 | 3v3 | 小队模式 |
| 小队对战 | `TEAM_VS_PEOPLE` | 11 | 3v3 | 小队模式 |
| 小队 vs CPU | `TEAM_VS_CPU` | 12 | 3v3 | 小队模式 |
| 小队观战 | `TEAM_WATCH` | 13 | 3v3 | 小队模式 |
| **小队 2v2** | `TEAM_DUO` | 14 | 2v2 | 小队模式 |
| **小队 2v2 观战** | `TEAM_DUO_WATCH` | 15 | 2v2 | 小队模式 |
| 单人闯关 | `SINGLE_ACRADE` | 20 | 1v1 | 单人模式 |
| 单人 2P | `SINGLE_VS_PEOPLE` | 21 | 1v1 | 单人模式 |
| 单人 vs CPU | `SINGLE_VS_CPU` | 22 | 1v1 | 单人模式 |
| 单人观战 | `SINGLE_WATCH` | 23 | 1v1 | 单人模式 |
| **单人 1v2** | `SINGLE_VS_DUO` | 24 | 1v2 | 单人模式 |
| **单人 1v2 观战** | `SINGLE_VS_DUO_WATCH` | 25 | 1v2 | 单人模式 |
| 生存模式 | `SURVIVOR` | 30 | 1v1 | 其他 |
| 练习模式 | `TRAINING` | 40 | 1v1 | 主菜单 |

> **2v2 / 1v2 / 观战** 模式已在 [批次 6.x](BVNscripts/scripts/net/play5d/game/bvn/data/GameMode.as) 实现完毕，菜单可见即可用。详细实现在 [`data/GameMode.as`](BVNscripts/scripts/net/play5d/game/bvn/data/GameMode.as) 和 [`ui/MenuBtnGroup.as`](BVNscripts/scripts/net/play5d/game/bvn/ui/MenuBtnGroup.as)。

---

## 开发者

### 环境要求

| 工具 | 用途 | 备注 |
|---|---|---|
| **Flex + AIR 合并 SDK** | `flex4.16.1-air51.0.1.1/` 或 `AIRSDK/` | mxmlc 编译 + ADT 打包 + fdb 调试 |
| **JDK 17** | mxmlc 编译器运行时 | 必须 |
| **JDK 8**（可选）| ANE Java 编译 | ANE 当前已禁用，无需 |
| **Android SDK**（可选）| ADT `-platformsdk` | 仅打包 APK 时需要；phone-33 + build-tools 33.0.2 |
| **ADB**（可选）| 真机调试 | `tools/platform-tools/adb.exe` 或系统 PATH |

### 构建脚本

| 脚本 | 位置 | 用途 |
|---|---|---|
| `build.bat` | 项目根 | 编译 SWF → `tools/Test/launch.swf` |
| `tools/script/debug.bat` | `tools/script/` | 编译 + adl 启动（PC 调试器）|
| `tools/script/debug_mob.bat` | `tools/script/` | 编译 + ADT 打包 + ADB 安装 + logcat |
| `tools/script/fdbg.bat` | `tools/script/` | 通用 fdb 连接 SWF 断点调试 |
| `tools/script/pack_termux.sh` | `tools/script/` | Termux 内直接打包 APK（无需 PC）|
| `tools/script/add_asset.py` | `tools/script/` | 自动添加角色/辅助/地图到游戏 |

#### 快速开始

```bash
# PC 端：编译 + adl 启动
.\tools\script\debug.bat

# 移动端：编译 + 打包 + 安装 + 日志
.\tools\script\debug_mob.bat

# 仅编译 SWF
.\build.bat
```

### 编译关键参数

`build.bat` 自动注入构建时间戳到 `Debugger.as` 的 `BUILD_TAG`，然后调用：

```bash
java -jar flex4.16.1-air51.0.1.1/lib/mxmlc.jar \
  +flexlib=flex4.16.1-air51.0.1.1/frameworks \
  -debug=true \
  -swf-version=37 \
  -strict=false \
  -source-path+=BVNscripts/scripts \
  -library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/core.swc \
  -external-library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/air/airglobal.swc \
  -output=tools/Test/launch.swf \
  -- BVNscripts/scripts/launch.as
```

> **`-strict=false` 必须**：预存的反编译类型不匹配错误（`ScreenRotater`、`GameInputer`、`JsonUtils`、`ANEFileReader` 等）会阻止 SWF 产出。漏掉此参数时 mxmlc 仍返回 exitCode=0 但**无 SWF 生成**，极难排查。
>
> **`-external-library-path+=airglobal.swc` 必须**：提供 AIR 运行时类（ANEFileReader、FileUtils 等）。
>
> **`-swf-version=37`**：对应 AIR 51.0。

### 项目结构

```
BVNY/
├── BVNscripts/scripts/                # AS3 游戏源码（可编译）
│   ├── _assets/                       # 嵌入 PNG/MP3/SWF
│   ├── mx/                            # Flex 框架桩
│   ├── com/                           # 第三方库（TweenLite）
│   ├── fl/                            # Flash 运动辅助
│   ├── net/play5d/
│   │   ├── game/bvn/                  # === 主游戏代码 ===
│   │   │   ├── MainGame.as            # 游戏状态机
│   │   │   ├── GameConfig.as          # 常量（FPS/物理/气力等）
│   │   │   ├── ctrl/                  # 控制器层
│   │   │   ├── data/                  # 数据模型
│   │   │   ├── fighter/               # 角色系统
│   │   │   ├── state/                 # 游戏状态
│   │   │   ├── ui/                    # UI 组件
│   │   │   ├── mob/                   # 移动端支持
│   │   │   ├── utils/                 # 工具
│   │   │   └── views/                 # 视觉效果
│   │   └── kyo/                       # KYO 框架
│   └── launch.as                      # 入口
│
├── extensions/BVNFileReader/          # ANE 原生扩展（Java + AS3，已禁用）
├── tools/
│   ├── Test/                          # 编译产物 + 运行时资源
│   │   ├── launch.swf                 # 编译产出
│   │   ├── application.xml            # AIR 应用描述
│   │   └── assets/                    # 运行时加载
│   │       ├── config/                # 配置 XML
│   │       ├── fighter/ map/ face/    # 角色/地图/头像
│   │       ├── bgm/ sounds/ font/     # 音频/字体
│   │       └── swf/                   # UI SWF
│   ├── script/                        # 构建/调试脚本
│   └── platform-tools/                # ADB
├── reference/BVN3.9/                  # BVN 3.9 参考源码（只读）
├── doc/                               # 架构与规划文档
│   ├── architecture.md
│   ├── ane-dev-guide.md
│   └── AI-SYSTEM-DOC.md
├── flex4.16.1-air51.0.1.1/            # 合并 SDK
├── android-platform-33/               # Android SDK 平台库（被 ANE 依赖）
├── build.bat                          # 编译入口
├── CLAUDE.md                          # 开发者完整手册（必读）
├── AGENTS.md                          # AI 助手工作流规则
└── README.md                          # 本文件
```

### ANE（BVNFileReader）状态：**已禁用**

| 开关 | 状态 | 文件 |
|---|---|---|
| `application.xml` 取消 `<extensionID>` 注释 | (x) 已注释 | `tools/Test/application.xml` |
| `ANE_ENABLED = true` | (x) `false` | `BVNscripts/scripts/net/play5d/game/bvn/mob/utils/ANEFileReader.as` |
| `debug_mob.bat` 加 `-extdir "."` | (x) 已移除 | `tools/script/debug_mob.bat` |

**禁用原因**：统一从 APK 内置资源加载，简化部署、避免 ANE 兼容性问题。源码完整保留，未来重新启用只需打开以上三开关。详细迁移记录见 [`doc/ane-dev-guide.md`](doc/ane-dev-guide.md)。

---

## 变更记录

> 完整提交历史：[GitHub Commits](https://github.com/yinyukuaiyou22/BVN3.3EX/commits/master) · 当前本地领先 `origin/master` **13 个提交**。

### 重大重构（最近完成）

| 批次 | 内容 | 关键文件 |
|---|---|---|
| **批次 1-5**（2026-08） | **多手柄配置重构（单手柄模型）** | `GameJoystickInput.as`、`InputManager.as`、`ExtendConfig.as`、`GameInterfaceManager.as`、`ViewManager.as` |
| | • 手机端只连一个手柄，固定走 `joy_p1` 通道 | |
| | • `joy_p2` 恒禁用，由 `switchControlPlayer` 按 `joyTarget` 切换控制方 | |
| | • P2 独立配置 `joy2Config`，双手柄时支持 P2 独立改键 UI | |
| **批次 6.x**（2026-08~09）| **2v2 / 1v2 / 观战模式** | `GameMode.as`、`MenuBtnGroup.as`、`GameInterfaceManager.as`、`SelectFighterStage.as`、`GameCtrl.as` |
| | • 4 个观战模式常量（13/15/23/25）| |
| | • 4 个 2v2 / 1v2 常量（14/15/24/25）| |
| | • 选人 step 流程适配 | |
| **批次 6.5**（2026-09）| **选人分页布局 + 子框 plugin sub-frame** | `SelectFighterStage.as`、`SelectFighterItem.as` |
| **批次 6.14**（2026-09）| **BUILD_TAG 自动注入 + 文件日志** | `build.bat`、`Debugger.as`、`launch.as` |

### 当前活跃构建

```
BUILD_TAG = BVN-3.3EX-batch6.14-2026-09-02-1219
VERSION   = V3.3
VERSION_DATE = 2019.3.32
```

---

## 常见问题

**Q: 放好文件后游戏里看不到新角色？**
A: 检查三点：
1. `fighter/` 目录下有 `.swf` 文件
2. `config/` 下有对应的 `fighter.xml`（定义属性/头像）
3. 角色 ID 不与内置冲突（内置优先）

**Q: 头像不显示？**
A: `config/fighter.xml` 中 `face` 的四个 `url` 属性必须写**完整绝对路径**。

**Q: 游戏启动后黑屏/闪退？**
A: 检查 `config/*.xml` 是否有语法错误（缺少闭合标签、特殊字符未转义）。

**Q: MT 管理器看不到应用目录？**
A: 确保游戏正在运行，或调用游戏内的"注册文件提供器"功能。

**Q: 编译后没有 SWF 输出？**
A: 99% 是漏了 `-strict=false`。检查 `build.bat` 第 13 行附近。

**Q: 调试面板如何打开？**
A: 游戏中按 **`~`**（波浪键）调出调试面板（FPS / 内存 / 角色信息）。`Debugger.as` 中的 `DEBUG_PANEL_ENABLED` 控制开关。

**Q: 日志在哪？**
A: 文件日志：`/data/user/0/<包名>/<内部包名>/Local Store/bvn_debug.log`（每次会话自动追加）。手机端读取：
```bash
adb shell run-as <包名> cat '.../Local Store/bvn_debug.log'
```

---

## 完整文档

| 文档 | 内容 |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | 开发者完整手册（环境/构建/调试/项目结构/重构批次）|
| [`AGENTS.md`](AGENTS.md) | AI 助手工作流规则 + Vibe Coding 流程 |
| [`doc/architecture.md`](doc/architecture.md) | 架构总览 |
| [`doc/ane-dev-guide.md`](doc/ane-dev-guide.md) | ANE 重新启用指南（已禁用）|
| [`AI-SYSTEM-DOC.md`](AI-SYSTEM-DOC.md) | AI 系统文档（双层决策架构）|

---

## 许可

基于 [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html) 发布。
原作版权 © 5dplay。本修改版版权所有 © 2021-2026 YinYu。
