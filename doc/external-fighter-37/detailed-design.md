# 详细设计与接口契约

## 路径契约

输入支持：`assets/fighter/a.swf`、`fighter/a.swf`、绝对路径。规范化后相对资源统一以 `assets/` 开头；外部命中返回绝对路径，未命中返回 APK URL。解析结果应携带 `source=external|builtin` 供日志使用。

## 加载器契约

`loadXML`、`loadSwf/loadSWF`、`loadBitmap`、`loadSound` 均调用同一解析器；失败回调保持现有签名。缓存键使用规范化 URL，避免外部与内置同一资源产生两份缓存。

## 人物契约

目录：`fighter/<id>.swf`、`face/*`、`bgm/*`、`config/fighter.xml`。扫描得到的 VO 至少包含 `id`、默认 `name`、`fileUrl`、`startFrame=1`；XML 合并填充 `faceUrl/faceBigUrl/faceBarUrl/faceWinUrl/bgm/bgmRate/contact/says` 等字段。SWF 加载优先 `main_mc`，失败回退根 MovieClip。

## 错误处理

目录不存在返回空列表；XML 解析错误记录文件名并跳过；SWF/头像/BGM 失败调用原有失败回调；任何外部错误不得清空已初始化的内置 Model。日志至少包含原始 URL、规范化 URL、来源、人物 ID 和异常原因。

## 实施顺序

先实现解析器并接入四类加载，再调整人物注册/合并时序，最后处理 UI 刷新与 Android 打包。每步均需独立编译和 diff 审查。
