# 运行时踩坑速查（手机端 / 触控 / 选人 / 输入 / 受击 / 加载）

> 本文件是 `AGENTS.md` 里「静默失败陷阱」表的**展开版**：常驻层只留判据，这里给完整机理与可抄的代码。
> **进入条件**：改移动端 UI、触控、选人界面、手柄/输入、Debugger 面板、打 APK、**改 `fighter/` 受击/灵爆、排查开局黑屏或「创建游戏失败」**时读；其它时候不必读。
> 汇总自原 `AGENTS.md` §245–735（2026-10-11 重组）+ 回补自 `CLAUDE.md.rewrite.2026-09-09-142021`（2026-10-11 二次修订）+ 2026-10-21 补入受击/灵爆/加载三条卡死。
> 已删除过期 Termux 路径、已过时包名、逐批次备份台账；**保留内容均经 2026-10-11 实测核对**（详见 §8「核实记录」）。

## 0. 这份文件的读法

按「症状」定位。多数坑的共同点是**不报错、不打日志**，只能靠预先知道：

| 症状关键词 | 跳到 |
|---|---|
| 界面能画出来但点不动 / 点格子无反应 | §3.1 |
| 设置界面滚不到 APPLY，存不了也退不出 | §3.2 |
| 图片换了但显示的还是旧图 | §2.1 |
| 按钮点一下之后消失 | §2.2 |
| Debugger 面板重复出现 / 折叠按钮失灵 | §2.4 |
| 手柄控制了对手 / 键位全错位 | §4 |
| 选人界面卡顿、日志每帧刷屏 | §3.1 连带修复 |
| 子框长按没反应 | §5.2 |
| 真机看不到任何游戏日志 | §2.3 |
| 打包/脚本闪退、一闪而过 | §1.8 |
| 编译零错误但运行时 `#1006` / `#1065` | §1B |
| 打包报中文路径错误 / APK 该打哪些资源 | §1.5 |
| 日志路径拼不对（包名三段辨析） | §1.6 |
| 受击中按 SPECIAL 后永久僵直 + 永久金身 | §7.1 |
| 某角色一选就崩 / 开局 `#1009 at cameraResume` | §7.2 |
| `创建游戏失败` 每帧刷屏 / 开局黑屏 / 切后台回来黑屏 | §7.3 |

---

## 1. 编译与打包

### 1.1 PC 编译必带参数

产物不产出或 `-strict` 报错时，核对这两条：

| 参数 | 必要性 | 缺失后果 |
|---|:---:|---|
| `-strict=false` | **必须** | 预存反编译类型不匹配（ScreenRotater、GameInputer、JsonUtils、ANEFileReader 等）阻止 SWF 产出；mxmlc 仍返回 exitCode=0 但无产物 |
| `-external-library-path+=.../airglobal.swc` | **必须** | ANEFileReader、FileUtils 等 AIR 库类报 `Type was not found` |

完整命令：

```bash
java -jar flex4.16.1-air51.0.1.1/lib/mxmlc.jar \
  +flexlib=flex4.16.1-air51.0.1.1/frameworks \
  -debug=true -swf-version=37 -strict=false \
  -source-path+=BVNscripts/scripts \
  -library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/core.swc \
  -external-library-path+=flex4.16.1-air51.0.1.1/frameworks/libs/air/airglobal.swc \
  -output=tools/Test/launch.swf -- BVNscripts/scripts/launch.as
```

> 常规入口是根目录 `./build.bat`（会自动注入 BUILD_TAG，编译约 70s）。上面的手搓命令只在调试 bespoke 场景用。

### 1.2 编译前资源一致性

`EmbeddedAssets.as` 的 `[Embed]` 引用的文件若不存在，编译必失败。`_assets/` 下曾有同名 `.png` / `.jpg` 不一致的情况：缺文件时**用 `cp` 补同名文件，不要改 `EmbeddedAssets.as` 源码**。

### 1.3 新手引入符号时的编译陷阱

`-strict=false` 会**静默放过**缺失的 import，编译过但运行时炸（典型是 `SelectFighterItem` 用 `GameConfig` 忘了 import → `#1065`）。
**跨包引入新符号时，先核对 import，别指望编译器。**

### 1.4 构建工具链路径（2026-10-11 实测）

| 工具 | 路径 | 用途 |
|---|---|---|
| Flex + AIR SDK | 仓库内 `AIRSDK\flex4.16.1-air51.0.1.1\` | mxmlc 编译 + ADT 打包 + fdb 调试（合并包） |
| JDK 8 | `D:\JDK8\` | ANE Java 编译（**必须 JDK 8**，兼容 build-tools d8） |
| Android SDK | `D:\Android\SDK\` | ADT `-platformsdk`（platform-33 + build-tools 33.0.2） |
| JAVA_HOME | JDK 17 | mxmlc 运行时 |
| adb | `tools\platform-tools\adb.exe` | 真机调试（也可放 PATH） |
| 签名证书 | `AIRSDK\flex4.16.1-air51.0.1.1\bin\mycert.p12` | APK 签名 |

> 三者分工易混：**编译**用 JDK 17，**ANE 的 Java 层**必须用 JDK 8，**d8 打包**只认 JDK 8 产出的 class。

调试脚本（`tools/script/`）：

| 脚本 | 作用 |
|---|---|
| `debug.bat` | 编译 + adl 启动（启动时询问 SWF 路径，回车用默认） |
| `debug_mob.bat` | 编译 → ADT 打包 → ADB 安装 → `adb logcat` 实时日志 |
| `fdbg.bat` | 通用 fdb 连接 SWF 断点调试（支持命令行参数指定 SWF） |
| `add_asset.py` | 自动添加角色/辅助/地图（向导/快速/批量模式） |

另注：`tools/script/lang/` 有多代码页包装脚本（437/932/936/949），用于解决系统编码兼容。

### 1.5 APK 打包白名单（运行时资源结构）

APK **默认包的 assets 下只有** `config/` 的 7 个 XML + `effect.swf` + `movelist.jpg` + `sounds/` + `font/`；**没有** `fighter/`、`map/`、`face/`、`bgm/` —— 这四类全部从外部存储读（见 `CLAUDE.md`「外部资源契约」）。所以「缩 APK 体积」在角色/地图上无可缩，只有内部 config 与实际内嵌资源可动。

`tools/script/debug_mob.bat` 提供两种包型：

| 模式 | 产物 | 打包内容 | 设备外置目录 |
|---|---|---|---|
| `min`（默认） | `bvn_min.apk` | `tools/Test/min_assets/assets/**`：2 角色 / 2 辅助 / 2 地图 / 12 BGM + 7 个最小 config（**全 ASCII 文件名**） | 打包后把 `assets` 改名为 `assets_full` |
| `full` | `bvn.apk` | `assets/` 下的 `effect.swf`、`movelist.jpg`、`sounds`、`font`、以及 `config/` 的 7 个 XML | 不动 |

两个硬约束（都是 2026-10-11 实测踩出来的）：

1. **`assets/config/` 必须逐文件列举，不能整目录打包。** 该目录下有 `backup/trash_unused/`（1388 个文件、其中 540 个含中文名），整目录打包会让 ADT 以
   `Asset file or directory name contains invalid characters` 退出（exit 12）。同理，**任何非 ASCII 文件名都进不了 APK**。
2. **只能有一个 `-C`。** AIR 的 `-C <dir> file...` 每出现一次就重置一次基准目录，写成
   `-C . a\b.xml -C . c.xml` 时第二个会被解析成相对 `.` 的 `c.xml`，报 `no such file` 后打印 usage 并以 exit 2 结束。
   正确写法是单个 `-C <dir>` 后面跟**全部**文件/目录参数。
3. **生成/改写的 config XML 必须与对应原文件同格式，禁止自行添加 `<?xml ...?>` 声明或 `<!-- ... -->` 注释。**
   原文件里有的才保留、没有的一律不加：`map.xml`/`fighter.xml`/`assist.xml` 是**裸根元素**（`<map_config>`/`<fighter_config>` 直接开头），
   `select.xml`/`salect.xml` 是 `<!-- ... -->` 注释开头，`mission.xml` 是 `<?xml ...?>` 声明开头。
   最小包的 7 个 config 由 `tools/Test/build_min_assets.py` 生成，**一律裸根元素开头**（不加声明、不加 `GENERATED` 注释）。
   ⚠️ 曾经踩过：生成器给 `map.xml` 多加 `<?xml version="1.0" encoding="utf-8"?>` + `<!-- GENERATED ... -->` 两行，
   与裸根元素的 `map.xml` 格式不一致。**以后改 `build_min_assets.py` 或手写最小 config 时，绝不添加这些多余行。**

```bat
:: full 模式的等价手搓命令（min 模式把 -C . 换成 -C min_assets，参数换成 assets\ 下的最小集）
cd tools\Test
adt -package -target apk-captive-runtime -arch armv8 ^
  -storetype pkcs12 -keystore "%FLEX_HOME%\bin\mycert.p12" -storepass <密码> ^
  bvn.apk application.xml -platformsdk "D:/Android/SDK" launch.swf ^
  -C . assets\effect.swf assets\movelist.jpg assets\sounds assets\font ^
  assets\config\preload.xml assets\config\fighter.xml assets\config\assist.xml ^
  assets\config\select.xml assets\config\salect.xml assets\config\map.xml assets\config\mission.xml
```

> **APK 输出文件名必须用纯英文**（如 `bvn.apk`）。ADT 不认非 ASCII 路径，中文名会报 `no such file`。日常走 `tools/script/debug_mob.bat` 即可，上面的手搓命令用于调试白名单本身。

### 1.5.1 最小可玩测试包（`min` 模式）为什么必须动内置 config

结论：**只清外置目录没用，只改 APK 白名单也没用**，必须替换 APK 内置 config + 临时摘掉外置目录。三条依据：

1. `GameData.applyConfigXMLs()`（`GameData.as:84-142`）用 **APK 内置** `fighter.xml`/`select.xml` 初始化模型。内置 `fighter.xml` 有 659 个角色、`select.xml` 606 条目、`map.xml` 146 张图 —— 这些数字才是选人列表长度的来源。
2. `GameLoader.appendMissingExternalFightersToSelect()`（`GameLoader.as:411-435`）会把 `FighterModel` 里**所有不在选人列表中的角色追加回去**。所以即使外置 `select.xml` 只写 2 个角色，内置的 659 个也会被逐个补进列表。
3. `GameLoader.loadExternalConfigsNow()` / `scanExternalMaps()`（`GameLoader.as:375-408`、`230-268`）在外置目录存在时会再合并一次配置、并把外置 `map/` 平铺扫描注册进模型。

因此 `min` 模式做两件事：用 `tools/Test/min_assets`（由 `tools/Test/build_min_assets.py` 从完整 config **抽取**节点生成，含逐段 ASCII 校验）替换内置 config 与资源；再把设备上的 `assets` 改名为 `assets_full`，让外置扫描与合并全部落空。

- 切换/恢复**只做 rename，绝不删除用户文件**；恢复时若 `assets` 下仍有文件，会改名为 `assets.app_generated` 并输出路径，而不是删掉。
- 恢复命令：`tools\script\debug_mob.bat restore`。
- 改最小集：编辑 `tools/Test/build_min_assets.py` 顶部的 `FIGHTERS` / `ASSISTS` / `MAPS` 列表后重跑该脚本。

### 1.6 三个标识符不要混用

本项目有三个不同的 ID，历史上长期混为一谈：

| 标识符 | 值 | 出处 |
|---|---|---|
| **Android 包名** | `air.com.bvn.yy798` | `adb shell run-as` / `pm install` / APK 路径 |
| **AIR applicationID** | `com.bvn.yy798` | `tools/Test/application.xml` 的 `<id>` |
| **AIR 私有目录内 ID** | `com.bvn.yy798` | `/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/` |

> ⚠️ 旧文档曾写 applicationID 是 `com.bvn33.y36`，**已过时**（2026-10-11 实测 `<id>com.bvn.yy798</id>`）。私有目录里的子目录名以 AIR 运行时实际写入的为准，改错就找不到日志。

### 1.7 签名凭据

`debug_mob.bat` 的签名密码是**可选覆盖 + 内置默认**：环境变量 `BVN_KEYSTORE_PASS` 只要存在就优先生效，不存在时回落到脚本内置的默认值，因此双击即可一键打包，不需要预置任何环境变量。

```powershell
# 用非默认密码时：
$env:BVN_KEYSTORE_PASS = "<本机证书密码>"
tools/script/debug_mob.bat
```

> 密码明文只存在于 `tools/script/debug_mob.bat` 一处；**文档、README、其他脚本里不要再抄一遍**（`doc/architecture.md`、`doc/ane/proposal.md`、`tools/script/pack_termux.sh` 仍有历史遗留的明文副本，属待清理项）。提交前按 `CLAUDE.md`「代码审查与提交」扫描凭据。

### 1.8 bat 脚本故障排查（打包闪退必看）

`.bat` 双击闪退或报错即关闭时，按此顺序排查：

| 优先级 | 排查项 | 症状 | 修复 |
|:---:|---|---|---|
| 1 | `exit /b` | cmd 窗口一闪而过 | 改 `goto :EOF`，末尾加 `pause` |
| 2 | 调用子 `.bat` 缺 `call` | 子 bat 退出连带终止主脚本 | `call xxx.bat` 而非直接写 `xxx.bat` |
| 3 | `()` 块内 `)` 未转义 | `-- was unexpected at this time.` | 块内文字 `)` 用 `^)` 转义，或改用 `REM` |
| 4 | `-C "path\"` 末尾反斜杠 | `No such directory` | 去掉末尾 `\`（`\"` 被解析成转义引号） |
| 5 | `::` 注释含中文/特殊字符 | `'xxx' 不是内部或外部命令` | 改用 `REM` |
| 6 | 内联 PowerShell 含 `^` 续行 | `-- was unexpected` | 独立 `.ps1` 文件，别内联 |
| 7 | `enabledelayedexpansion` 下用 `%VAR%` | ANE 未被传入 → `implementation not found` | 运行时变量改用 `!VAR!` |
| 8 | APK 文件名含中文 | `no such file ...死神vs火影.apk` | 纯英文名 |
| 9 | **`.bat` 是 LF 行尾** | 脚本乱跳：该进的分支不进、变量全空、`'adb' is not recognized`、`Script finished` 打印两次 | 存成 **CRLF**（见下） |
| 10 | **`call` 子程序里 `goto END`** | 错误没被拦下，脚本"跳过检查"继续往下跑，甚至带着未赋值变量执行 | 子程序改 `exit /b <code>`，由**调用处**判断后再 `goto END` |

**第 9 条（LF 行尾）实机表现**：`.bat` 用 LF-only 保存时，cmd 的标签与块解析会错乱 —— `goto` 可能跳到错误的行、`for`/`if` 块半途断裂、变量像是没被赋值。因为窗口里错误信息互相矛盾，很容易误判成"权限问题"或"adb 没装"。已实测：同一个文件只把行尾从 LF 改成 CRLF，行为立刻恢复正常。
**探针脚本常常不复现**：没有标签、没有多行块的短 `.bat` 即使 LF 也能跑，别用它证明"不是行尾问题"。
检查与修复：

```powershell
$b=[IO.File]::ReadAllBytes('tools\script\debug_mob.bat'); $lf=0;$crlf=0
for($i=0;$i -lt $b.Length;$i++){ if($b[$i] -eq 10){ if($i -gt 0 -and $b[$i-1] -eq 13){$crlf++} else {$lf++} } }
"CRLF=$crlf bare-LF=$lf"   # bare-LF 必须为 0
```

> ⚠️ 用脚本/工具生成或改写 `.bat` 时最容易踩这条：多数编辑器与 `write` 类工具默认写 LF。改完务必复核一次行尾。

**第 10 条（`goto END` 在 `call` 里）**：`:END` 末尾是 `goto :EOF`，而 `goto :EOF` 在**子程序上下文里只结束该子程序**，控制权会回到 `call` 的下一行继续执行。所以 `:EXIST` / `:CHK_CMD` 这类子程序里的 `goto END` 并不能终止脚本，只是白打印一遍收尾横幅。本项目的 `debug_mob.bat` 已按此改为子程序 `exit /b 1` + 调用处统一 `goto END`。

**强制模板**（所有项目 `.bat` 遵守）：

```bat
@echo off
setlocal
...脚本主体...

:: 所有错误出口统一用 goto END
if errorlevel 1 goto END

:END
echo.
echo =============================================
echo   Script finished. Press any key to exit.
echo =============================================
pause
goto :EOF
```

**禁止**：`exit /b`（双击即关窗）、`pause >nul`（看不到提示）、直接调用子 bat 不加 `call`、`::` 注释写在 `()` 块内、内联 PowerShell 含 `)`/`$`/`^`。
**例外**：`build.bat` 是被调用的叶子脚本，不加 `pause`。

调试技巧：绕过 bat 直接命令行跑 `adt -package ...` 看原始错误；查隐藏字符用 `python3 -c "print(open('x.bat','rb').read().hex())"`；回到干净版用 `git checkout HEAD -- 文件`。

---

## 1B. 编译器的两个"静默放过"（最高代价陷阱）

`-strict=false` 让 mxmlc 放过两类错误，**编译零错误、运行时才炸**，且AS3 报错会连带整个表达式不求值：

### 1B.1 不存在的**方法调用**被放过 → `#1006`

真实事故：批次 6.10 在 `SelectFighterStage.build()` 写了 `GameMode.getCurMode()`，而该方法**整个项目根本不存在**（2026-10-11 实测 `GameMode` 只有 `getTeams()` / `isTeamMode()` / `isSingleMode()` / `isDuoMode()` / `is1v2Mode()` / `getSelectCount()` / `isVsPeople()` / `isVsCPU()` / `isWatch()` / `isAcrade()`）。

后果是连锁的：

> AS3 调用未定义方法 → `TypeError #1006` → **整个 `Debugger.log(...)` 表达式在求值前就抛错** → 这一行日志根本没写出去，且 `build()` 从此处中断。

表现为「选人界面黑屏 + **入口日志缺失**」，极难反推。定位是靠三重交叉验证（值得抄的方法论）：
① 用 zlib 解压 SWF，确认 4 处 `build() enter` 确实编译进去了；② 比对 APK 内 SWF 与本地 SWF 的 md5 一致（排除"打错包"）；③ 发现运行时入口日志不存在 → 反推是表达式求值阶段就抛错。

**教训：调用跨类静态方法前先 grep 确认方法存在。** `-strict=false` 不会告诉你。

### 1B.2 缺失的 import 被放过 → `#1065`

跨包引入新符号忘了 import，编译过、运行时炸。

**两者共通的自救法则：新增跨类/跨包引用时，先 grep 确认符号存在 + 手工核对 import，别指望编译器。**

---

## 2. GPU 渲染与显示行为

### 2.1 Bitmap 换图不刷新（GPU 纹理缓存）

AIR Android 用 GPU 渲染，**直接替换 `bitmapData` 不保证刷新纹理缓存**：

```actionscript
// 错：看起来正确，但显示仍是旧图
display.bitmapData = new BitmapData(...);
display.width = w; display.height = h;
```

```actionscript
// 对：创建全新 Bitmap 对象替换整个 display
var newBmp:Bitmap = new NewAssetClass();
newBmp.scaleX = ScreenPadUtils.scale;
newBmp.scaleY = ScreenPadUtils.scale;
newBmp.alpha = display.alpha;
newBmp.x = display.x;
newBmp.y = display.y;
container.display = newBmp;          // 替换整个对象
```

> 案例：`ScreenPadGame._switchPlayer()` 的 P1/P2 切换按钮（`ScreenPadBtn.display` 是 `Bitmap`）必须走整对象替换。资源：`ScreenPadAsset.p1`（`EmbeddedAssets.p1_png`，1067B）、`.p2`（2552B）。

### 2.2 Sprite 尺寸清零（`graphics.clear()` 之后）

`graphics.clear()` 后 `width`/`height` 变 **0**，重绘时若依赖这两个动态属性就会画出 0×0 空矩形——**按钮"消失"**：

```actionscript
btn.graphics.clear();
btn.graphics.drawRect(0, 0, btn.width, btn.height);   // 错：画 0×0
```

```actionscript
// 对：用静态常量存尺寸
private static var _closeBtnSize:int = 0;   // initDebug 中初始化为 int(14 * _scale)
btn.graphics.clear();
btn.graphics.beginFill(color);
btn.graphics.drawRect(0, 0, _closeBtnSize, _closeBtnSize);
btn.graphics.endFill();
```

> 案例：Debugger 面板的绿/红折叠方块。展开=绿 `0x00AA00`，收起=红 `0xCC0000`。

### 2.3 文件日志（看不到日志时先读这条）

移动端 AIR trace 默认**不进 logcat**（需 fdb 连接）。项目已内置文件日志：`launch.as` **无条件**调用 `Debugger.initFileLog(stage)`（不依赖面板开关），`Debugger.log()` 每 5 帧刷盘。

```
/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log
```

```bash
adb exec-out run-as air.com.bvn.yy798 cat "/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log"
adb logcat -v threadtime | findstr /i "AdobeAIR BVNFileReader ANEFileReader GameLoader EXT-RESOLVE EXT-READ FATAL"
```

> 路径是 `/data/user/0/<包名>/<applicationID>/Local Store/`，applicationID 取 `application.xml` 的 `<id>`，不是纯包名目录。

日志前缀含义（输入类问题排查靠它）：

| 前缀 | 含义 |
|---|---|
| `JOY_IN: DOWN/UP device=... control=N value=...` | 手柄 control 边沿（设备侧实际输入，`JoySticker.pollInputLog()` 每帧轮询） |
| `INPUT: P1.attack = true` | GameInputer 查询到的按下边沿（**哪个通道收到输入**） |
| `JOY:P1 up dev=xxx [1:AXIS=0.5]` | `GameJoystickInput._joyLog()` 实时扫描（**设备切换感知**） |
| `JOY:P1 EDGE DOWN/UP key=attack dev=xxx ctrl=15,` | 组合键边沿；`key=any` 表示任意键边沿 |
| `JOY_ROUTE: singlePad joy_p1=true joy_p2=false` | 手柄路由状态（`refreshJoystickRouting()`） |
| `refreshMultiPadCache: devices=N multiPad=true` | 双手柄检测（选人时执行一次） |
| `goJoyStickSet: enter player=2 deviceId=yyy` | 进入改键页（P1/P2 分流） |
| `connected / button:N:ID` | 设备连接 + control 布局（**换手柄时先核对它**） |
| `initFileLog: <路径>` | 日志文件路径确认（首行） |

### 2.4 Debugger 面板（移动端）

| 问题 | 根因 | 处理 |
|---|---|---|
| 面板重复创建 | `launch.as` 两处调用 `initDebug()` | `_inited` 静态守卫，开头 return |
| 折叠后无法展开 | 绿方块仅 `int(14*_scale)` px，只响应 `MouseEvent.CLICK` | 正常——触控也触发 CLICK；确认按钮重绘正确即可 |
| 按钮点击后消失 | `clear()` 后尺寸归零（§2.2） | 用 `_closeBtnSize` 常量重绘 |
| PERF toggle 无重绘 | `_togglePerfBody` 缺重绘逻辑 | 展开绿、收起红 |

**交互原则**：只用原始绿方块触发折叠/展开，**不要在标题栏整条加监听**（与按钮监听冲突，也不符原设计）。

开启：`launch.as` 里 `DEBUG_PANEL_ENABLED:Boolean = true`，或游戏内按 `P→L→A→Y`。

---

## 3. 触控与 UI（静默失败重灾区）

### 3.1 包装类监听判据：界面能显示但点不动

`SelectFighterItem` / `MenuBtn` 是包装类，重写 `addEventListener` 把外部回调转挂到 `ui` 上。**原判据用了底层显示对象**：

```actionscript
if(this.ui.hasEventListener(param1)) { return; }    // 有病
```

`SelectFighterItem` 构造器里为做长按**直挂**了 `touchBegin/touchMove/touchEnd/touchTap` 到 `ui`。于是 `SelectFighterStage.addFighterItem` 里那句 `addEventListener("touchTap", selectFighterTouchHandler)`（角色格**唯一**的触摸入口）被判为"已注册"而静默 `return` —— 单击毫无反应，**不报错不打日志**。

- **修复**：判据改用本类登记表 `this._listeners[param1] == null`（selfHandler 每类型只挂一次；外部回调每次覆盖记录）
- **连带必须做**：补 `removeEventListener` 重写。挂在 `ui` 上的是 `selfHandler` 而非外部回调，缺这个重写 → `removeEventListener` 落在 `EventDispatcher` 自身成为空操作 → `_refreshFace` 的 `ENTER_FRAME` 永不注销，**face 就绪后仍每帧清空 `ui.ct` 并重加 face、每帧写日志**（选人界面卡顿 + 日志刷屏的真正根因）；`removeAllEventListener()` 同样空转
- **通用教训**：包装类"是否已注册"的判据**必须以自己的登记表为准**，绝不能用底层显示对象的 `hasEventListener` —— 任何第三方/帧脚本直挂的同类监听都会污染它

> ⚠️ 纠正一处过时说法：早期曾认为"不要走 override 路径"。真正的坑是 override 里的 `hasEventListener` 判据会吞回调；6.15 修好多监听/注销语义后，两条路径都可用。

### 3.2 SetBtnGroup 滚不到 APPLY（存不了 = 退不出）

滚动由 `_arrowIndex` 驱动（`moveScroll()` 把 `_scrollRect.y` 补间到 `-_arrowIndex * (step - gap)`）。**公式本身是对的**（`scrollRect.y` 增大 = 显示更靠下的内容）。问题是手机端 `_arrowIndex` **没法动**：

1. 设置界面不属于 `GameState`/`SelectFighterStage` → `ScreenPadManager` 走 `menuMode()` → **不显示虚拟方向键**
2. `_arrowIndex` 只由 `render()` 里的 `GameInputer.up/down`（键盘/手柄）驱动
3. 触摸唯一入口是 `touchHandler`（点一行 → 箭头移到那一行），而 **`scrollRect` 同时裁剪渲染与命中测试**，视口外的行根本点不到
4. 移动端 `getSettingMenu()` 有 16 行，加 `SetBtnGroup` 追加的 APPLY ≈ 16~17 行；行高 `y = startY + 70*i`，视口 600 → APPLY 落在 `y≈1080~1150`

APPLY 是 `SettingState` 里**唯一**的 `saveData` + `applyConfig` + `goMenu` 动作，`SettingState` 自身没有返回按钮，列表也没有 `BACK` 行 ⇒ **"存不了"和"退不出"是同一个原因**。

**修复**：`SetBtnGroup.enableScrollDrag()` — 铺一张与视口等大的透明热区（`beginFill(0,0)`，alpha=0 的填充照样参与命中测试），挂 `touchBegin/Move/End` 直接改 `_scrollRect.y`（clamp 到 `[0, 内容底部-视口高]`），另加 `mouseWheel`。拖动阈值 `DRAG_THRESHOLD=12`（本地像素；stage 差值需除以 `scaleY`——**本类在 TOUCH_MODE 下 `scale=1.1`**），越阈值置 `_dragMoved`，`touchHandler` 据此屏蔽"拖完误触发点击"。

方向用自然滚动：`applyScrollY(_dragStartScrollY - dy)`（手指下拉 → 显示更靠上的内容）。`scrollRect.y` 符号极易搞反，改动前先对照 `moveScroll` 的已验证方向。

**两个量纲陷阱**（真机二次反馈才踩到）：

- 可滚动上界必须用**有效视口高度**，不能用 `_scrollRect.height`：`_scrollRect` 是**本地**尺寸，而 `scale=1.1` 下本地 600 渲染后是 660 游戏单位，超出部分被屏幕裁掉 → 真正可见的只有 `GameConfig.GAME_SIZE.y / scaleY ≈ 545` 本地单位。按 600 算会让末尾 APPLY **恰好**卡在屏幕外。见 `getEffectiveViewportHeight()`（`min(_scrollRect.height, GAME_SIZE.y / scaleY)`），并留 `BOTTOM_MARGIN=12` 呼吸间距
- `launch.FULL_SCREEN_SIZE` 是**设备像素**不是游戏单位（`stage.fullScreenWidth/Height`），只参与 `_gameSprite` 的像素级缩放。任何本地单位混算都别用它——第一次修这个 bug 就误用了它，`min(600, 1080/1.1)=600` 让修复变成空操作

`enableScrollDrag` 是 **opt-in**，只由 `SettingState.build()` 调用。`SetScreenBtnView` 也复用 `SetBtnGroup`，**不要**在 `initScroll` 里无条件开启。

**未做**「常驻 APPLY 底栏」：视口已占满 600px（且 `scale=1.1`），钉底栏必须缩视口，缩了会让 `moveScroll` 的 `step=(endY-startY)/N` 失配 → 箭头移到 APPLY 时反而滚出更矮的窗口，把**现在正常工作的**键盘自动滚动搞坏。

### 3.3 选人界面交互语义

- 格子点击：**首次点击 = 预览，再点同一格 = 确认**
- 长按展开子框 **只对配了 `plugins=` 的角色生效**（52 个角色里仅 `灵梦,妹红`、`早苗,妹红` 两个）。其余角色长按是**设计的静默 `return`**，不要当 bug——**测长按必须用这两个角色**
- 诊断标记 `[DIAG6.15]`（`touchBegin hit id=` / `touchTap hit id=` / `Stage.touchTap →` / `longPress fired id= plugins=`）与 `[SCROLLDIAG] btns= rectH= scaleY= gameH= effViewH= lastRowY= maxY=`：`AGENTS.md` 链路确认后应删除并重新编译。滚动几何校验应满足 `lastRowY + 44 <= maxY + effViewH`；`effViewH=600` 说明有效视口又算错了

---

## 4. 手柄与输入

### 4.1 单手柄模型（2026-08-15 重构）

手机端只连一个手柄（Xbox 布局），输入**固定走 "P1" 通道**（`joy_p1` 恒启用、`joy_p2` 恒禁用）。控制哪个角色由 `GameCtrl.switchControlPlayer()` 依 **joyTarget** 决定（交换 `FighterKeyCtrl.inputType` 实现）。

- `refreshJoystickRouting()`：观战 → 双禁用；其余（vs CPU/闯关/对战）→ `joy_p1.enabled=true`、`joy_p2.enabled=false`
- `switchControlPlayer(controlP1)`：`joyTarget=0` 跟随切换（用 `controlP1`）；`=1` 固定 P1；`=2` 固定 P2
- vs CPU/闯关：P2 是 AI，`_switchPlayer` 直接 return，手柄自然只控 P1

调用链：`ScreenPadGame._switchPlayer()` → `GameCtrl.switchControlPlayer()` → `GameInterfaceManager.refreshJoystickRouting()`
joyTarget 入口：`SetBtnGroup.as`（设置菜单「手柄控制权」，`optoinKey=joyTarget`）

> 历史 bug：旧版按 controllingP1 切换 joy_p1/joy_p2 启用，与交换 inputType 的模型冲突 → 切换后手柄控制对面角色。统一为单手柄模型后消除。

### 4.2 Xbox Wireless Controller 键位映射（24 control）

```
control 0/1   = D-pad HAT 轴（AXIS_16 上下 / AXIS_15 左右）
control 8/9   = 左摇杆（AXIS_1=Y 正1=下拉 / AXIS_0=X）
control 13=A  14=B  15=X  16=Y
control 17=LB 18=RB 19=LS 21=Start 22=Select
control 10/11/12 = D-pad 按钮（BUTTON_19/21/22，缺 down）
```

| 配置项 | control | 物理键 | 配置项 | control | 物理键 |
|---|---|---|---|---|---|
| up2 | (8,-0.5) | 左摇杆上 | attack | (15,1) | X |
| down2 | (8,0.5) | 左摇杆下（正1=下拉） | jump | (13,1) | A |
| left2 | (9,-0.5) | 左摇杆左 | dash | (14,1) | B |
| right2 | (9,0.5) | 左摇杆右 | skill | (16,1) | Y |
| up | (0,-0.5) | D-pad 上（HAT） | superSkill | (18,1) | RB |
| down | (0,0.5) | D-pad 下（HAT） | special | (17,1) | LB |
| left | (1,-0.5) | D-pad 左（HAT） | waikai | (19,1) | LS 按下 |
| right | (1,0.5) | D-pad 右（HAT） | back | (21,1) | Start（暂停） |
| | | | select | (22,1) | Select（确认） |

> **历史坑**：旧默认映射（left2/right2=0/1、back=8 等）基于另一设备，与 Xbox 完全错位——back=8 实为左摇杆 Y 轴，**下拉左摇杆触发暂停**，按钮全无效。**换手柄设备时务必先看 `connected/button:N:ID` 日志核对 control 布局再改映射。**

### 4.3 多手柄（批次 4/5，2026-08）

原始 `joy_p1`/`joy_p2` 共享 `joy1Config`，P2 改键覆盖 P1、设备号重连失效。重构为「单手柄模型 + P2 独立 `joy2Config` + 双手柄时 P2 独立改键 UI」：

| 文件 | 职责 |
|---|---|
| `ViewManager.as` | `goP1JoyStickSet()`/`goP2JoyStickSet()` → `goJoyStickSet(playerNum, joyConfigVO)`；`isMultiplePads()`/`refreshMultiPadCache()`/`_multiPadCache` |
| `GameInterfaceManager.as` | `getSettingMenu()` 加 P2 条件入口（`isMultiplePads() ? {...} : null`）；`updateInputConfig` 绑定 `joy_p2.setConfig(joy2Config)` |
| `SelectFighterStage.as` | `build()` 末尾调 `ViewManager.I.refreshMultiPadCache()`（选人时检测一次） |
| `ExtendConfig.as` | `joy2Config` 字段 + `toSaveObj/readSaveObj/setDefaultDevice(joy2Config,1)` 独立存档 |
| `GameJoystickInput.as` | `_prevKeys` 设备级隔离、`_joyLog` 设备感知、`anyKey` 接 `_checkEdge` |

维护规范：

1. **P2 APPLY 不调 `updateJoyConfig`**：只 `readObj` 直存，与 P1 解耦。改 P2 存档逻辑时勿让 P2 覆盖 P1 设备号
2. **双手柄检测只在选人时做一次**，不订阅设备热插拔事件 → 游戏中途热插拔**不支持**（当前唯一留白，将来要在 `refreshMultiPadCache` 加事件订阅）
3. **单手柄时 P2 入口完全隐藏**（不灰显）：`isMultiplePads() ? {...} : null` 三元，`null` 元素被渲染层过滤
4. **保留历史拼写错误**：`getAllDeivces`、`wankai/waikai`——不要"修正"，与反编译代码风格一致
5. 改键 UI 已参数化：`JoyStickSetUI.setConfig(playerNum, configVO)`、`IInnerSetUI` 接口——新增入口复用此模式，勿重复实现
6. **编译产物 SWF 字节数变化应控制在 ±1KB 内**；变化过大要检查是否误嵌入资源（见 `EmbeddedAssets.as`）
7. 手柄日志统一带 `P{n}` 前缀（`JOY:P1`/`JOY:P2`）+ `dev=` 设备号

---

## 5. 选人界面人物子框（plugin sub-frame，方案 B，批次 6.8）

### 5.1 数据契约

**仅 fighter.xml 通道**（`select.xml` `<plugin>` 子节点通道保留但未启用）：

```xml
<fighter id="溯源拉赫莱蒂" plugins="灵梦,xxx" ...>   <!-- 逗号分隔 plugin 角色 id -->
```

链路：`FighterVO.initByXML` 解析 `@plugins` → `FighterVO.pluginIDs` → `SelectFighterStage.buildList` 构建子框（8 方位 `gridOffset`）。

当前主源码 = **方案 B（badge + TweenLite 动画）**，参考实现在 `BVNscripts/人物子框3.3/`（基于旧基线，**不可整体覆盖**，只能选择性移植）。方案 A（showPluginSub 静态小方块）**已移除**——批次 6.12 回退时 Stage 触发逻辑已丢失，6.8 一并从 `SelectFighterItem` 清除。

交互：右键 / 手柄 special（LB）展开（`doShow`）；**触屏长按 1.3s**（`LONG_PRESS_MS=1300`）；展开时方向键走 `movePluginSelect`（8 方位 + 主角色间导航）；hover/select 组外或选中时收起（`closePlugins`）。

### 5.2 维护要点

1. badge 角标（`updateBadge`）与 face 占位 TextField（`_refreshFace`）分属 `ui` 顶层与 `ui.ct` 子容器，无冲突
2. plugin 子角色 `_itemObj` 键 = `x,y.N` 后缀（避免与主网格 `x,y` 冲突）；`addFighterItem` 判空防御已就位（plugin id 无效 → null 跳过）
3. 子框坐标复用分页 `_loc5_/_loc6_`（含 `pageIdx*PAGE_HEIGHT`），子框 ui 挂在 `_ui.bg` 容器内 → 翻页兼容
4. `clear()`/`destory()` 已做 `closePlugins()` + 引用置空 + `TweenLite.killTweensOf(_badge)` 防泄漏
5. **不要**把参考版 `SelecterItemUI.as` 合入——它带 `KyoVoiceSounder` 语音调用，主源码无此类
6. 触屏长按监听走 `ui` 原生路径（`ui.addEventListener("touchBegin"...`）；`onLongPress` 回调由 Stage 在 `addFighterItem` 注入；长按后松手由 `touchTapGuardHandler` 用 `_longPressed` 标志 + `stopImmediatePropagation()` 屏蔽误触。**配合 §3.1 的判据修复使用**
7. **render 分页吸附段必须跳过子框展开状态**（`p1/p2FocusedOnPlugin` + `isBelongToPluginGroup` 守卫）——否则 hover 子框被每帧吸附弹回主体，键盘 `moveSlt` 查不到子框
8. **`SelectFighterStage.SELECT_STATE` 必须恒为 0**：`select.swf` 帧脚本每帧消费它，赋非 0 会让 `clear()` 无守卫地每帧 `removeChild(up/down)` → 第二次起 `#2025` 刷屏（批次 6.11 修复：不再赋值，辅助界面翻页由主程序 render 分页段支持）。
   **一般教训：主程序静态变量会被 select.swf 帧脚本每帧消费，赋非 0 值前必须确认帧脚本怎么读它。**

---

## 6. ANE

**不要在本文件找 ANE 结论** —— 现状见 `CLAUDE.md`「ANE 现状：已按设计停用（勿再重复攻克 #2113）」，历史设计见 `doc/ane/`，构建见 `doc/ane-dev-guide.md`。

唯一重复一句（因为踩过的代价最大）：`ANEFileReader.EXTERNAL_ENABLED`（默认 `true`）是**外置资源子系统**总开关，`ANE_ENABLED`（默认 `false`）才是是否创建原生扩展上下文。**把 `ANE_ENABLED` 当外置资源总开关关掉，会静默废掉整条外置资源链路。**

相关文件（改之前先看 `CLAUDE.md` 结论）：

```
BVNscripts/scripts/net/play5d/game/bvn/mob/utils/ANEFileReader.as   # 封装层（最常改）
BVNscripts/scripts/net/play5d/game/bvn/ctrl/GameLoader.as           # 外部扫描（经常改）
BVNscripts/scripts/net/play5d/game/bvn/data/GameData.as             # 启动集成
extensions/BVNFileReader/Android/src/com/bvn/filereader/            # Java 层
extensions/BVNFileReader/as3/com/bvn/filereader/BVNFileReaderLib.as # AS3 库
extensions/BVNFileReader/extension.xml                              # ANE 描述
extensions/BVNFileReader/build_ane.bat                              # 构建脚本
tools/Test/application.xml                                          # 应用配置
tools/script/debug_mob.bat                                          # 打包脚本
```

新增 FREFunction 时四处同步：Java `BVNFileReaderExtensionContext.getFunctions()` 注册 → AS3 库 `BVNFileReaderLib.as` → 封装层 `ANEFileReader.as`（含降级方法）→ 文档 `doc/ane/detailed-design.md` API 列表。

> **改 Java → 重走完整链**：`build_ane.bat`（Java→JAR→SWC→ANE）→ `debug_mob.bat`（打包→安装→验证）。
> **改 AS3 封装层 → 至少真机验证一次**：PC 端无 ANE 运行时，永远走降级，验不出问题。

---

## 7. 受击 / 灵爆 / 开局加载：三条"看起来都是卡死"的坑（2026-10-21）

三条都在真机上出现过，现象都像"卡死"，根因完全不同。**红线清单见 `CLAUDE.md`「受击 / 灵爆状态机」，本节给机理、判据与验收。**

| 编号 | 现象 | 根因落点 |
|---|---|---|
| §7.1 | 受击中按 SPECIAL（灵爆）后**永久僵直 + 永久金身**，对手还能动，点暂停继续也救不回 | `render()` 抛异常 → 同帧 `renderAnimate()` 被跳过 → 三个计时器停摆；安全网又被同一计时器门控（自锁） |
| §7.2 | 某角色**一选就崩 / 开局黑屏**（`#1009 at GameState/cameraResume`） | 人物包 `人物_1/frame1` 无条件调 `endBisha()`；`cancelJustRender*` 把"从没登记过"误判成合法收尾 |
| §7.3 | `创建游戏失败` 每帧刷屏 + 黑屏；切后台回来永久黑屏 | `TransUI` 转场回调"先调后清"；`GameUI.getUI()` 为 null 时 `pause(true)` 半途崩 |

### 7.1 灵爆后永久金身 + 永久僵直

**机理（一条链，三个受害者）**：

```
render() 抛异常（最可能：renderHurtBreak 解引用空 _actionCtrler）
  └─ GameMainLogicCtrler.renderGameSprite 把 render() 与 renderAnimate() 放在同一个 try
       → 本帧 renderAnimate() 整块跳过
          ├─ FighterMcCtrler.renderHurtAnimate  _hurtHoldFrame--     ← 停 → 永久受击
          ├─ FighterMain.renderAnimate          --_explodeSteelFrame  ← 停 → 永久金身
          └─ FighterMain.renderAnimate          --_explodeHitFrame    ← 停 → 到不了 idle()
```

**自锁点**：`renderHurt()` 的两道安全网原先都以 `_fighter.explodeSteelFrame <= 0` 门控，而
`_explodeSteelFrame` 的唯一递减点就是被跳过的那条 `renderAnimate()` —— **计数器一停，保护它的安全网同时失效**，
这就是上一轮（`ca46d10` 加了两道网）没修好的原因。

**现场判定三问**（比读代码快）：

| 问 | 观察 | 结论 |
|---|---|---|
| 卡死时全场定格还是单角色？ | 单角色（对手能动） | 排除全局 `_isRenderGame`，锁定单角色 render 链路 |
| 暂停→继续能救吗？ | 不能 | `resume(true)` 只重置 `_isRenderGame`，不碰该角色的计数器 |
| 哪一侧？ | 死神侧（灵爆，黄色辉光） | 走 `energyExplode()`；火影侧走 `replaceSkill()`（替身术，黑幕） |

**为什么「火/冰/雷重击」几乎必现**（放大因素，不是根因）：

| 因素 | 证据 | 作用 |
|---|---|---|
| 7/8/9 是唯一 `freeze:400` 的 hitType（轻击只有 50） | `data/EffectModel.as:156-197` | 每次命中多 400ms 全局 `GameCtrl.pause()`，与灵爆 0.7s 窗口大面积交叠 |
| 7/8/9 唯一带 `specialEffectId`，会改写受害者 `ColorTransform` | `EffectModel.as:307-324`、`views/effects/SpecialEffectView.as:57-66` | 只在 `actionState ∈ {0,23,24}` 才 `resumeColor()`；卡在 21/22 就**永久染色**（火=发黑），叠加辉光就是"变金身" |
| 受击期每帧 4 条同步写盘日志 | `Debugger.log` 每次 `writeUTFBytes + flush`（`Debugger.as:245-251`） | 手机上直接吃帧时间，放大所有暂停窗口的错位概率 ← **"真机尤其明显"的直接原因** |

**修法要点**：拆两个独立 try；控制器动画链再包一层 try；安全网门控 `explodeSteelFrame` → **`explodeHitFrame`**；
`== 8` 改幂等 `<= 8 && !_explodeIdled`；`_explodeSteelWatchdog` 150 帧强解金身；`idle()` 重置 `_hurtHoldFrame`；
`renderHurtBreak`/`renderHurtFlying` 判空；`FighterMC.renderHurtFly` 起身后加 12 帧引擎兜底
（`_action.isHurtFlying` 全工程只有 `clearState()` 能清，不能只靠角色 SWF 的 `parent.$mc_ctrler.idle()`）。

**日志判据**：正常一次灵爆必有 `【僵直归零】→【僵直恢复】`；出现 `【钢体看门狗】` 说明还有别的链在漏；
`RENDER_ERR[render]` / `RENDER_ERR[renderAnimate]` / `FIGHTER_ANIM_ERR` 都会带角色 id + 堆栈。
逐帧细节把 `Debugger.DIAG_HURT` 改 `true` 重编（默认 false，同步 flush 很贵）。

### 7.2 开局 `#1009 at GameState/cameraResume`（人物包脏帧脚本）

```
人物_1/frame1 → FighterEffectCtrl.endBisha() → EffectCtrl.endBisha()
              → GameCtrl.I.gameState.cameraResume()   ← this.camera 还是 null
```

`camera` 在 `initFight → initCamera` 才创建，而角色在更早的 `buildGame` 的 `addFighter` 里就初始化了。
根因是 `EffectCtrl.cancelJustRender(Animate)` 的误判：

```as
// 旧实现：indexOf == -1 也返回 length < 1
if(_loc2_ != -1) this._justRenderAnimateTargets.splice(_loc2_,1);
return this._justRenderAnimateTargets.length < 1;   // 从没登记过 → 也返回 true
```

于是人物包里漏出来的 `endBisha()` 被当成"合法收尾"。**对局中**同样会误触发：`GameCtrl.resume()` +
`setRenderHit(true)` + `_blackBack.fadOut()` + 地图设可见 —— 随时强行打断别人的灵爆/替身术/瞬步黑幕。

**修法**：`cancelJustRender*` 未登记 `return false`（根因，3 个调用点全走这里）；
`endBisha`/`endWanKai` 把 `setRenderHit(true)` **提到最前**（漏这行＝全场打不动，看起来完全是"永久金身"）；
`cameraResume`/`cameraFocusOne` 判空 `camera`。

**人物包侧**：删掉 `人物_1` 第 1 帧的 `parent.$effect_ctrler.endBisha()`。引擎现在能兜住，但脏帧脚本还会在别处惹事。

### 7.3 `创建游戏失败` 刷屏 + 黑屏

**三段因果**：

1. `buildGame()` 的 null 保护触发（`p1/p2.currentFighter` 或 `map` 为 null）→ 原实现 `throw`。
2. `throw` 穿过 `startGame → goGame` 落进 `TransUI.renderAnimate` 的 `_fadOutBack`。原实现**先调回调、后置 null**
   → 回调抛异常后 `_fadOutBack` 永久保留 → **每帧重试一次** → 黑屏 + 同一个错误刷屏。
3. `buildGame` 中断 ⇒ `initFight` 从未执行 ⇒ `GameUI.getUI()` 为 null ⇒ 切后台
   `MobileCtrler.pause → GameCtrl.pause(true) → getUI().pause()` **#1009**（`_isPauseGame` 已置 true、
   对话框没建出来）⇒ 回前台无人 `resume(true)` ⇒ **永久黑屏，只能杀进程**。

**修法**：`TransUI` 回调**先摘再调**（黑屏+刷屏根因）；`pause/resume` 判空 `getUI()`；
`MobileCtrler` 加 `_pausedByDeactive`，回前台只撤销自己造成的那次暂停；
`buildGame(): void → Boolean`，null 保护改点名日志 + `return false`，`doStartGame` 失败则回菜单。

**定位**：下一次失败只看这一行 ——
`[GameCtrl] buildGame ABORT — p1.currentFighter=? p2.currentFighter=? map=?`。
`p1=null` ⇒ `getP1Order()[0]` 为空（问题在选人/加载，与角色状态机无关）；`map=null` ⇒ 地图项没加载完。

### 7.4 验收断言

| 场景 | 通过标准 |
|---|---|
| 受击中按 SPECIAL ×20（死神侧 + 火/冰/雷 对手） | 每次金身 ≤ 2s 结束，**不出现** `【钢体看门狗】` |
| 同上，看日志 | 每次灵爆必现 `【僵直归零】→【僵直恢复】` |
| KO 前 2 秒内灵爆 ×5 | 换人/结算后无黄色辉光残像 |
| 对局中切后台再回前台 ×10 | 自动回到战斗（不再需要点「继续」）；无 `#1009 at GameCtrl/pause` |
| 选人进局失败 | 回菜单 + 一行 `[GameCtrl] buildGame ABORT — ...`，**不再**黑屏刷屏 |

---

## 8. 核实记录（2026-10-11 修订时逐项实测）

本文件的内容不靠"文档说"，靠当时核过。下表记录本次修订时的核对结果，供下次维护时判断哪些可能已漂移。

| 项目 | 声称值 | 实测结果 | 状态 |
|---|---|---|---|
| JDK 8 路径 | `D:\JDK8\` | 存在（含 bin/jre/lib） | ✅ 有效 |
| Android SDK 路径 | `D:\Android\SDK\` | 存在（含 build-tools/platforms/platform-tools） | ✅ 有效 |
| adb | `tools\platform-tools\adb.exe` | 存在 | ✅ 有效 |
| 签名证书 | `AIRSDK\...\bin\mycert.p12` | 存在 | ✅ 有效 |
| `application.xml` 的 `<id>` | 旧文档写 `com.bvn33.y36` | 实测 `com.bvn.yy798` | ⚠️ **旧说法已过时** |
| ANE `<extensions>` | 旧 AGENTS.md 说"取消注释可启用" | 实测仍被注释（有 `-->`），路线已停用 | ⚠️ 勿据此重启 |
| APK 白名单 | 只打包 effect/swf/sounds/font/config | assets 实际 8 个子目录，其余走外置 | ✅ 有效 |
| `GameMode.getCurMode()` | 批次 6.10 曾调用 | **整个项目不存在**，实测只有 `getTeams()` 等 10 个方法 | ❌ **不存在**（§1B.1 事故源头） |
| `GameMode` 可用方法 | — | `getTeams` / `isTeamMode` / `isSingleMode` / `isDuoMode` / `is1v2Mode` / `getSelectCount` / `isVsPeople` / `isVsCPU` / `isWatch` / `isAcrade` | ✅ 实测清单 |
| Termux 路径 `~/BVN3.3EX-master/` | 旧 AGENTS.md §345 | 已过期，不再使用 | 🗑️ 已删 |

> **维护约定**：下次修订本文件时，重跑上表中标 ✅ 的项目。路径类信息最容易漂移，`from memory` 不可信。
