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

## 🎮 新增游戏模式：2v2 和 1v2（白板方案）

> 通过魔改现有小队模式（3v3）实现。以下列出所有需要增加/修改的文件、方法名和具体改动点。

### 模式定义

| 模式 | 常量名 | 值 | 说明 |
|------|--------|----|------|
| 小队 2v2 | `TEAM_2V2` | 14 | 每队选 2 人，按小队规则对战 |
| 小队 1v2 | `TEAM_1V2` | 15 | P1 选 1 人，P2 选 2 人（不对称） |

### 菜单显示

```
TEAM PLAY
  ├── TEAM ACRADE (3v3)  ← 原有
  ├── TEAM VS CPU  (3v3)  ← 原有
  ├── TEAM 2V2 VS CPU      ← 新增
  └── TEAM 1V2 VS CPU      ← 新增
```

---

### 需要修改的文件清单

#### 1. `data/GameMode.as` — 模式常量 + 检测方法

| 方法/字段 | 改动 |
|-----------|------|
| `TEAM_2V2:int = 14` | **新增**常量 |
| `TEAM_1V2:int = 15` | **新增**常量 |
| `isTeamMode()` | 改为 `return currentMode >= 10 && currentMode <= 15` |
| `is2v2Mode()` | **新增**：`return currentMode == 14` |
| `is1v2Mode()` | **新增**：`return currentMode == 15` |
| `getSelectCount()` | **新增**：根据模式返回选人数（3/2/1） |

#### 2. `interfaces/GameInterface.as` — 默认菜单配置

| 方法/字段 | 改动 |
|-----------|------|
| `getDefaultMenu()` | TEAM PLAY 的 children 追加 `TEAM 2V2 VS CPU` 和 `TEAM 1V2 VS CPU` |

#### 3. `mob/GameInterfaceManager.as` — 移动端菜单

| 方法/字段 | 改动 |
|-----------|------|
| `getGameMenu()` | TEAM MODE children 追加两个新模式按钮，`func` 内联设置 `currentMode = 14/15` |

#### 4. `ui/MenuBtnGroup.as` — 菜单按钮回调

| 方法/字段 | 改动 |
|-----------|------|
| `getFucByLabel()` | 新增两个 case：`"TEAM 2V2 VS CPU"` 设 `currentMode = 14`、`"TEAM 1V2 VS CPU"` 设 `currentMode = 15` |

#### 5. `state/SelectFighterStage.as` — 选人逻辑

| 方法/字段 | 改动 |
|-----------|------|
| `initSelecterP1()` | `selectTimesCount` 改为调用 `GameMode.getSelectCount()` 而非硬编码 `isTeamMode() ? 3 : 1` |
| `initSelecterP2()` | 同上 |
| `nextStep()` | 新模式（14/15）的对战流程同 TEAM_VS_CPU（step1→step2→step3→...） |
| `initFighter()` | `p2Select` 创建条件追加新模式判断 |

#### 6. `ctrl/game_ctrls/GameCtrl.as` — 对战逻辑

| 方法/字段 | 改动 |
|-----------|------|
| `addFighter()` | P2 控制逻辑：新模式同 VS_CPU（P2 用 AI） |
| `startNextTeamFight()` | 换人逻辑复用现有 `isTeamMode()`（新模式已纳入） |
| `runNext()` | 复用 `isTeamMode()` 分支，不需额外改动 |

#### 7. `data/GameRunFighterGroup.as` — 队伍数据结构

| 方法/字段 | 改动 |
|-----------|------|
| `getNextFighter()` | 2v2 模式：fighter2 后返回 null（只有 2 人）；现有 3v3 不变 |
| `getFighterCount()` | **新增**：返回当前队伍实际 fighter 数 |

#### 8. `state/LoadingState.as` — 加载与分配

| 方法/字段 | 改动 |
|-----------|------|
| `gotoGame()` | 2v2 模式只加载 fighter1/fighter2，fighter3 设为 null |

#### 9. `ui/select/SelectIndexUI.as` — 出场顺序选择

| 方法/字段 | 改动 |
|-----------|------|
| `initSelect()` | `currentMode - 10` switch 追加 case 4(14)、case 5(15) |

#### 10. `ctrl/game_ctrls/GameEndCtrl.as` — 回合结束

| 方法/字段 | 改动 |
|-----------|------|
| `renderEND()` | HP 恢复逻辑：`isTeamMode()` 已覆盖新模式，不需改动 |

---

### 核心改动逻辑：`getSelectCount()`

```as
// GameMode.as 新增
public static function getSelectCount() : int {
    switch(currentMode) {
        case TEAM_1V2: return 1;   // P1 选 1 人
        case TEAM_2V2: return 2;   // 每队选 2 人
        default:
            return isTeamMode() ? 3 : 1;
    }
}
```

1v2 模式需要区分 P1/P2 的选人数：P1 选 1 人，P2 选 2 人。可通过在 `SelectVO` 或调用处传入 `playerType` 参数实现。

### 不需要修改的文件

- `GameStartCtrl.as` — 开场动画逻辑不依赖模式
- `FighterMain.as` / `FighterMcCtrler.as` — 角色行为不依赖模式
- `GameMainLogicCtrler.as` — 物理/碰撞不依赖模式
- `GameState.as` / `GameCamera.as` — 渲染不依赖模式
- `MessionModel.as` — 闯关模式暂不需要 2v2/1v2 关卡

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
