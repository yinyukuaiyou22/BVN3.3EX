# BVN Context

BVN（死神vs火影 V3.3 EX）格斗游戏的项目级领域术语表. 由 grill-with-docs 工作流的 domain-modeling 协议维护.

> **约定**: 术语在 grill session 推进时**逐条增加**, 用法见 [CONTEXT-FORMAT](https://github.com/mattpocock/skills/blob/main/skills/engineering/domain-modeling/CONTEXT-FORMAT.md). `CONTEXT.md` 只含术语定义, 不含实现细节或 spec 草稿.

## Language

**Fighter**:
一个完整的可操控角色实例（包含 MovieClip + 物理实体 + 输入/AI 控制器 + 状态机）.
_Avoid_: 角色、player、character

**FighterMcCtrler**:
Fighter 的核心状态机控制器（动作 / 受击 / 必杀 / 卍解 / 气力 / 僵直等状态转移）.
_Avoid_: 角色控制器、action controller

**FighterMain**:
Fighter 实体本身，继承 `BaseGameSprite`. 持有 _explodeHitFrame / _explodeSteelFrame 等灵压爆发窗口.
_Avoid_: 角色实体、sprite

**FighterMc**:
Fighter 的视觉 MovieClip 封装（不含逻辑）.
_Avoid_: 动画、MC、动画层

**doHurt**:
FighterMcCtrler 的入口方法，接收 HitVO 后切换到受击状态.
_Avoid_: 受击、被打、hit

**renderHurt**:
每帧递减僵直帧数；归零时调用 `hurtResume` 恢复.
_Avoid_: 僵直递减、hurt render

**_hurtHoldFrame**:
当前受击僵直剩余帧数. 初值由 `hurtTime / 1000 * 30 + HURT_FRAME_OFFSET` 算出（最小 4）.
_Avoid_: hold frame、僵直帧

**explodeHitFrame / explodeSteelFrame**:
FighterMain 的灵压爆发窗口（_explodeHitFrame>0 表示受击中，_explodeSteelFrame>0 表示钢体激活）.
_Avoid_: 灵压帧、钢体帧、spirit frame

**isAllowBeHit**:
角色当前是否可被命中（受 `setSteelBody` 控制 + 受击状态机影响）.
_Avoid_: 可被打、可被命中、can hit

**actionState**:
FighterMain 的当前动作状态常量（参见 CLAUDE.md 「动作状态常量」表，含 NORNAL/HURT_ING/HURT_FLYING 等）.
_Avoid_: state、状态

**AI_LEVEL**:
FighterAILogic 决策引擎的等级（0-6+），0=几乎不行动，6=激活角色 SWF 内嵌 AImain.
_Avoid_: AI 等级、难度

**debug.bat**:
PC 端编译 + adl 启动脚本（位于 `tools/script/`）.
_Avoid_: debug、调试脚本

**bvn_debug.log**:
移动端文件日志路径 (`/data/user/0/air.com.bvn.yy798/com.bvn.yy798/Local Store/bvn_debug.log`). 由 `Debugger.initFileLog` 启动.
_Avoid_: 日志、log

**isWatch**:
`GameMode.isWatch()` 判定当前模式是否是观战（13/15/23/25 + TRAINING 40）.
_Avoid_: 观战、watch mode

**switchControlPlayer**:
按 `joyTarget` (0=跟随/1=固定P1/2=固定P2) 决定 P1/P2 控制器 swap 的方法.
_Avoid_: 切换控制、control switch

## ADR 索引

参见 [ADR 索引](../adr/README.md)（2026-10-11 归档时路径由 `docs/adr/` 调整为 `doc/adr/`）。
