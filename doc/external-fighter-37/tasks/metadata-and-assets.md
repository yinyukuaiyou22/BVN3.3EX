# 任务：元数据与附属资源

- 目标：使头像和 BGM 采用与 SWF/XML 相同的外部优先规则。
- 输入：`FighterVO`、头像加载调用方、BGM 加载调用方、`fighter.xml`。
- 步骤：定义 URL 格式；验证四种头像字段和 `bgmRate`；补全缺省策略；检查外部 XML 覆盖占位字段。
- 检查：完整元数据、缺头像、缺 BGM、路径不存在、解析失败。
- 完成定义：选人头像、战斗人物和 BGM 均能正确回退。
- 依赖：asset-resolution、fighter-registration。
