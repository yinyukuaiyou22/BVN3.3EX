# 竞技规则移植 高层设计

## 数据流

```
OPTION 设置菜单 JSON (mob/GameInterfaceManager.getSettingMenu)
        │ SettingState.onOptionChange → ConfigVO.setValueByKey
        ▼
ConfigVO 6 新字段（类声明默认值 = fork 原值）
        │ toSaveObj / readSaveObj（KyoUtils.setValueByObject 对老存档自动按默认补齐）
        ▼
运行时消费点（进入对局时读取 GameData.I.config.*）
  ├─ FighterMain.qi 初值          ← initialQi
  ├─ EffectCtrl.doSteelHitEffect  ← isSteelBodyFreeze
  ├─ FighterMcCtrler.doWaiKaiAction ← allowWankai
  ├─ FighterMcCtrler.doHurt / hurtActionCheck ← isAllowRepeatAttack
  ├─ GameState.initCamera          ← cameraMaxSize（autoZoomMin）
  └─ FighterKeyCtrl.assist / specailSkill ← isChangeSpecialKey
```

## 模块边界

- 配置层：`data/ConfigVO.as` 只管字段/默认/存档，不感知 UI 与玩法。
- 接口层：`mob/GameInterfaceManager.as` 只提供菜单 JSON；选择与保存走既有 `SettingState/SetBtnGroup` 链路，无需新增事件。
- 玩法层：6 个消费点各自独立、互不依赖，均只读 `GameData.I.config`，无共享可变状态。
- 菜单结构：`getGameMenu()` 重组是纯 JSON 数据变更，`MenuBtnGroup`/`GameMode` 常量不动；子项保留 func 闭包保证点击逻辑不变。

## 设计决策

| 决策 | 选择 | 理由 |
|---|---|---|
| 防重复连依赖链路 | 连带移植 `getDoingAction`（FighterMain/Bullet/FighterAttacker）| fork 的重复判定读取攻击方当前动作+次数；主项目无此基础设施，缺失则判定不可用 |
| 老存档兼容 | 靠字段默认值 + `KyoUtils.setValueByObject` 只覆盖已有键 | 无需迁移代码，最小侵入 |
| 菜单重组 | 保留 func 子项 + 中文 cn | 避免依赖 MenuBtnGroup 的 label switch，降低回归风险 |
| 灵替按键 | 完全按 fork 的 assist/specailSkill 分支 | 与 fork 手感一致（默认 true）|

## 风险

- 防重复连改动位于受伤判定热路径，可能影响对战手感/连段；以 fork doHurt 为准逐行对齐，尽量不改主项目既有安全网（_hurtStuckFrame 等）逻辑。
- FighterMain/Bullet/FighterAttacker 新增方法需保证对象生命周期（destory 清引用）。
- isChangeSpecialKey 默认 true 后「灵压爆发/受击破防」触发方式变化（需要方向组合），文档记录，不改默认。

## 备选方案（未采用）

- 只加菜单不加行为：无法满足「设置真实生效」。
- 引入 win 包整体替换 mob：破坏移动端输入/触屏链路，风险过大。
