# t3：简单行为（气/刚身/镜头/灵替键）

- 目标：initialQi、isSteelBodyFreeze、cameraMaxSize、isChangeSpecialKey 四行为生效。
- 文件：
  - `fighter/FighterMain.as`（qi 初值，1 处）
  - `ctrl/EffectCtrl.as`（doSteelHitEffect，1 处）
  - `state/GameState.as`（initCamera，1 处）
  - `fighter/ctrler/FighterKeyCtrl.as`（assist/specailSkill + import）
- 依赖：t1。
- 检查：每文件消费点 rg 存在；build.bat 零错误。
