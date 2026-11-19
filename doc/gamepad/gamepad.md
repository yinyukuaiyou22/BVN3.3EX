# 手柄支持：现状、改键与测试台

建立日期 2026-11-19。本文对应两次提交 114e9fd（接线与配置）与 7adac30（入口与输入回滚修复）。

## 1 结论先行

P1 单手柄在 PC 上可用，设备层、动作层、存档全链路已实测通过。

默认键位表是按真实 Xbox 无线手柄标定的，换一台布局不同的设备（虚拟手柄、其他品牌、有线 Xbox 老型号）必须改键，否则按下去没有反应。这不是 bug，是控件索引随设备变。

P2 双打尚未放开：刷新路由时 joy_p2 恒为 false，两份配置与入口都在，但运行时零效果。

## 2 入口在哪

主路径：主菜单 OPTION → GAME CFG → 列表第一行「手柄设置」，点开就是改键页。

备用路径：同一页第二行「控制设置」→「手柄按键设置」，与主路径进的是同一页。

改键页内容依次是 USE JOY（绑定设备）、SET ALL（逐键录制）、SET DEFAULT（还原默认表）、APPLY、CANCEL。APPLY 只写进内存配置，真正落盘要回到设置列表再按 APPLY。

## 3 默认键位表与设备差异

JoyStickConfigVO 的默认值来自 2026-08-15 的真实 Xbox 无线手柄日志：

| 语义 | control 索引 | 说明 |
|---|---|---|
| jump | 13 | A |
| dash | 14 | B |
| attack | 15 | X |
| skill | 16 | Y |
| special | 17 | LB |
| superSkill | 18 | RB |
| waikai | 19 | LS |
| back | 21 | Start |
| select | 22 | Select |
| up / down | 0（-0.5 / +0.5） | 十字键竖直轴 |
| left / right | 1（-0.5 / +0.5） | 十字键水平轴 |
| up2 / down2 | 8（-0.5 / +0.5） | 左摇杆竖直 |
| left2 / right2 | 9（-0.5 / +0.5） | 左摇杆水平 |

同一台机器上，ViGEm 造的虚拟 Xbox 360 手柄枚举完全不同：轴占 0 到 3，A=4、B=5、X=6、Y=7、LB=8、RB=9、LT=10、RT=11、Back=12、Start=13、LS=14、RS=15、十字键=16 到 19。

实测结论：拿默认表去按虚拟手柄，几乎全错；把存档改成虚拟手柄的布局后，十字键上下、返回、确认全部对上。判据见第 6 节。

## 4 一条输入怎么走到动作

JoySticker 包 flash.ui.GameInput，负责设备增删与取值；GameJoystickInput 把取值翻译成 IGameInput 的 14 个动作；GameInputer 按 MENU / P1 / P2 三个通道按顺序问，命中即短路。

配置分三份存在 ExtendConfig：joyMenuConfig、joy1Config、joy2Config，随 bvnsave.sav 落盘。

updateJoyConfig 现在把 P1 的整张键位表拷进 joyMenuConfig（原来只拷 deviceId），原因是菜单通道走 joy_menu，只同步设备号会出现「战斗里改了键生效、菜单里仍按旧键」。

## 5 虚拟手柄测试台

测试脚本不入库。它们放在 tools\Test\gamepad_harness，该目录已被 .gitignore 的 tools/Test/* 覆盖。

组成：

ViGEmBus 驱动，本机已安装（服务 Nefarius Virtual Gamepad Emulation Bus 常驻）。

Nefarius.ViGEm.Client 1.21.256，来自 NuGet，netstandard2.0，PowerShell 7 直接 Add-Type 加载。

GamepadProbe.as 加 probe-app.xml，一个只做枚举与取值的 AIR 探针，编译后写 %USERPROFILE%\gamepad_probe.log，用来确认每个物理键落到哪个 control 索引。

feed.ps1 依次按完所有按键，seq.ps1 按指定序列按键，patch_save.ps1 把存档里的键位表改成虚拟手柄布局。

一条完整验证的步骤：

一，启动 adl 跑 application.xml，等二十秒左右到主菜单。

二，跑 seq.ps1 或 feed.ps1，虚拟手柄连上后游戏日志会打印连接与按键信息。

三，读 %APPDATA%\com.bvn.yy798\Local Store\bvn_debug.log，按第 6 节的判据比对。

注意：任何会改存档的测试之后都要核对键位表，脚本误触 SET DEFAULT 加 APPLY 会把表写回真实手柄默认值。

## 6 日志判据

连接与设备信息：JOY_IN: DOWN device=... control=N value=1。

动作层边沿：JOY:P0 EDGE DOWN key=up dev=... ctrl=16,0,。其中 P0 是菜单通道，P1 是玩家一。key 后面就是语义动作名，ctrl 后面是命中的 control 索引组合。

路由：JOY_ROUTE.singlePadAllModes last=joy_p1=true joy_p2=false。

逐帧取值：JOY_ISDOWN 行，pressed 时才会刷。

菜单态只轮询 up、down、select、back、anyKey，attack 与 jump 这类动作要进战斗态才会被问，因此验证攻击键要么进一局，要么临时把 up 改绑到该键间接验。

## 7 已经踩过的坑

菜单不跟改键：updateJoyConfig 只拷 deviceId。已修，改成整表拷贝。

返回键与确认键冲突：back() 原先写成 back 或 select，按确认键会同时触发返回。已修，back 只认 back 槽位。

子页退出后按键卡住：JoyStickSetUI 的 fadOut 只把页面滑到屏幕外，既不隐藏也不关收键闸，静态仲裁栈仍选中它。已修，退出时关闸并隐藏，SettingState 淡出后真正销毁子页。

回到主菜单输入全失效：MenuState.build 关掉总闸，恢复动作排在 afterBuild 的 gotoAndPlay 之后，前面一抛异常就永久关死且无日志。已修，先挂恢复定时器再做初始化。

没有手柄的平台点进改键页崩溃：getAllDeivces 返回 null 导致读 length 抛 1009。已修，返回空表占位。

## 8 待办

PC 双打：放开 joy_p2，做双设备分配与两人独立键位表，需要两台虚拟手柄验证。

手柄接管后自动隐藏虚拟摇杆：ScreenPadManager 目前没有显隐通道，要新写并理清与暂停、观战、换人按钮的互斥。

改键页 APPLY 立即落盘：现在必须回设置列表再按 APPLY，中途杀进程会丢改动。
