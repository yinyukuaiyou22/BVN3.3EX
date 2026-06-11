# Detailed Design — ANE 原生文件读取子系统

## 文件结构

```
extensions/BVNFileReader/
├── Android/
│   ├── lib/FlashRuntimeExtensions.jar          # AIR 51 FRE 编译依赖
│   └── src/com/bvn/filereader/
│       ├── BVNFileReaderExtension.java          # FREExtension 入口
│       └── BVNFileReaderExtensionContext.java   # 3 个 FREFunctions (内联类)
├── as3/com/bvn/filereader/
│   └── BVNFileReaderLib.as                     # AS3 ANE 库（SWC 源）
├── extension.xml                                # ANE 平台声明
├── build_ane.bat                                # 五步构建流水线
├── build/                                       # 构建中间产物（gitignore）
│   ├── java/   → .class files
│   ├── Android-ARM64/ → BVNFileReader.jar + library.swf
│   └── swc/    → BVNFileReader.swc
└── BVNFileReader.ane                            # 最终产出（复制到 tools/Test/）

BVNscripts/scripts/net/play5d/game/bvn/
├── mob/utils/
│   └── ANEFileReader.as                         # 应用层封装（单例 + 降级）
├── ctrl/
│   └── GameLoader.as                            # 外部扫描/配置合并（5 个公开方法）
└── data/
    └── GameData.as                              # 启动时触发扫描 (line 62, 88)

tools/Test/
├── application.xml                              # <extensionID> 声明 (line 38)
└── BVNFileReader.ane                            # 构建产物副本
```

## 模块职责

### 1. Java Native Layer

**BVNFileReaderExtension.java**
- 实现 `FREExtension` 接口
- `createContext()` → 创建 `BVNFileReaderExtensionContext`
- 无状态：`initialize()` / `dispose()` 为空

**BVNFileReaderExtensionContext.java**
- 实现 `FREContext` 接口
- `getFunctions()` → 注册 3 个 FREFunction 到 HashMap
- 三个内联类：
  - `ReadBytesFunction` — `FREObject.call()` 接收 path:String，返回 FREByteArray
  - `ListDirFunction` — `FREObject.call()` 接收 path:String，返回 FREArray
  - `ExistsFunction` — `FREObject.call()` 接收 path:String，返回 FREBoolean

**ReadBytesFunction 算法**：
```
1. args[0].getAsString() → path
2. new File(path) → 检查 exists() && isFile()
3. new FileInputStream(file)
4. FREByteArray.newByteArray() → acquire() → getBytes() → ByteBuffer
5. 循环 read(tmp[8192]) → buf.put(tmp, 0, n)
6. fis.close() → ba.release() → return ba
```

**ListDirFunction 算法**：
```
1. args[0].getAsString() → path
2. new File(path) → 检查 exists() && isDirectory()
3. dir.list() → String[]
4. FREArray.newArray(files.length)
5. 循环 arr.setObjectAt(i, FREObject.newObject(files[i]))
6. return arr
```

**ExistsFunction 算法**：
```
1. args[0].getAsString() → path
2. new File(path).exists() → boolean
3. return FREObject.newObject(boolean)
```

### 2. ANE Library Layer (AS3 → SWC)

**BVNFileReaderLib.as**
- `_ctx:ExtensionContext` — 懒加载创建 `ExtensionContext.createExtensionContext("com.bvn.filereader", "")`
- `isSupported:Boolean` — getter，检查 `ctx != null`
- `readBytes(path):ByteArray` — `ctx.call("readBytes", path)` 返回 ByteArray
- `listDir(path):Array` — `ctx.call("listDir", path)` 返回 Array
- `exists(path):Boolean` — `ctx.call("exists", path)` 返回 Boolean
- 所有方法在 `ctx == null` 时返回 safe default（null/null/false）

### 3. ANE Wrapper Layer (应用层封装)

**ANEFileReader.as**
- 单例 `ANEFileReader.I`
- `ANE_ENABLED:Boolean = true` — 全局开关（public static）
- `_hasANE:Boolean` — 实例级 ANE 可用状态
- `_ctx:ExtensionContext` — ANE 上下文
- `EXTERNAL_BASE:String` — 外部资源根路径（public static）
- `resolveExternalPath(assetPath):String` — 拼接完整路径
- `hasExternalAsset(assetPath):Boolean` — 检查外部资源是否存在
- 三个核心方法：
  - `readBytes(path):ByteArray` — ANE 优先，失败降级到 `readBytesFallback()`
  - `listDir(path):Array` — ANE 优先，失败降级到 `listDirFallback()`
  - `exists(path):Boolean` — ANE 优先，失败降级到 `existsFallback()`
- 三个降级方法：
  - `readBytesFallback(path)` — `flash.filesystem.File` + `FileStream`
  - `listDirFallback(path)` — `File.getDirectoryListing()`
  - `existsFallback(path)` — `File.exists`
- 构造函数：try-catch 创建 ExtensionContext，失败时 `_hasANE = false`

**初始化逻辑**：
```
constructor():
  if(ANE_ENABLED) {
    try { _ctx = ExtensionContext.createExtensionContext("com.bvn.filereader", "")
          _hasANE = (_ctx != null) }
    catch(e:Error) { _ctx = null; _hasANE = false }
  }
  Debugger.log ANE init 状态
```

### 4. GameLoader — 外部资源扫描

**公开方法**：

| 方法 | 功能 | 调用时机 |
|------|------|----------|
| `scanExternalAssets()` | 统一入口：创建目录 + 扫描角色 + 扫描地图 | GameData 启动时（setTimeout 2s） |
| `loadExternalConfigs()` | 加载外部配置 XML（fighter/assist/map/mission） | GameData 加载完内置配置后（setTimeout 3s） |
| `loadFighterFromPath(path, back, fail)` | 从绝对路径加载角色 SWF → FighterMain | 外部角色按需加载 |
| `scanExternalFighters()` | 扫描 `fighter/` 目录 SWF，注册为 FighterVO | scanExternalAssets 内部调用 |
| `scanExternalMaps()` | 扫描 `map/` 目录 SWF，注册为 MapVO | scanExternalAssets 内部调用 |
| `ensureExternalDirs()` | 创建 fighter/map/face/bgm/config 目录 | scanExternalAssets 内部调用 |

**外部角色注册算法** (`scanExternalFighters`):
```
1. basePath = EXTERNAL_BASE + "fighter/"
2. if !exists(basePath): return
3. files = listDir(basePath)
4. for each fileName in files:
     if !fileName.endsWith(".swf"): continue
     fighterId = fileName.replace(".swf", "")
     if FighterModel.I.getFighter(fighterId): continue  // 内置优先
     vo = new FighterVO()
     vo.id = fighterId; vo.name = fighterId; vo.fileUrl = basePath + fileName
     vo.comicType = 0; vo.startFrame = 1
     vo.faceUrl = ""; vo.faceBigUrl = ""; vo.faceBarUrl = ""; vo.faceWinUrl = ""
     vo.contactFriends = []; vo.contactEnemys = []; vo.says = []
     vo.bgm = ""; vo.bgmRate = 0
     FighterModel.I.getAllFighters()[fighterId] = vo
```

**外部配置合并算法** (`_loadExternalConfigsImpl`):
```
1. basePath = EXTERNAL_BASE + "config/"
2. if !exists(basePath): return
3. tryLoadExternalXML("fighter.xml", xml → FighterModel.I.mergeByXML(xml))
4. tryLoadExternalXML("assist.xml",  xml → AssisterModel.I.mergeByXML(xml))
5. tryLoadExternalXML("map.xml",     xml → MapModel.I.mergeByXML(xml))
6. tryLoadExternalXML("mission.xml", xml → MessionModel.I.mergeByXML(xml))
```

**⚠️ BUG — `tryLoadExternalXML` 作用域问题**：
```as3
// _loadExternalConfigsImpl 中定义:
var basePath:String = ANEFileReader.resolveExternalPath("config") + "/";

// 然后调用:
tryLoadExternalXML("fighter.xml", ...);

// tryLoadExternalXML 是独立的 private static 方法:
private static function tryLoadExternalXML(fileName:String, back:Function):void {
    var fullPath:String = basePath + fileName;  // ❌ basePath 不在作用域内!
```

**修复方案**：将 `basePath` 作为参数传入 `tryLoadExternalXML`，或将其提升为静态成员变量。

### 5. GameData 启动集成

**loadConfig 流程中的 ANE 调用点**：
```
loadConfig(back, fail):
  loadXML("assets/config/fighter.xml",
    onFighterLoaded: FighterModel.initByXML()
      → GameLoader.scanExternalAssets()  // [调用点1] line 62
    onAssistLoaded: AssisterModel.initByXML()
    onSelectLoaded: config.select_config.setByXML()
    onMapLoaded: MapModel.initByXML()
    onMissionLoaded: MessionModel.initByXML()
      → GameLoader.loadExternalConfigs()  // [调用点2] line 88
      → back()
  )
```

### 6. application.xml 配置

```xml
<extensions>
    <extensionID>com.bvn.filereader</extensionID>
</extensions>
```

**注意**：该行取消注释后 ANE 才能被 AIR 运行时加载。如果被注释，ExtensionContext 创建失败 → 自动降级。

## 公共接口和数据契约

### ANEFileReader 公共 API

```as3
// 全局开关
public static var ANE_ENABLED:Boolean = true;

// 外部路径
public static var EXTERNAL_BASE:String = "/storage/.../files/BVN/assets/";

// 路径拼接
public static function resolveExternalPath(assetPath:String):String;

// 检查外部资源
public static function hasExternalAsset(assetPath:String):Boolean;

// 文件操作（自动降级）
public function readBytes(path:String):ByteArray;
public function listDir(path:String):Array;
public function exists(path:String):Boolean;

// 状态查询
public function get hasANE():Boolean;
```

### GameLoader 公共 API（ANE 相关）

```as3
// 扫描所有外部资源（异步，setTimeout 2s）
public static function scanExternalAssets():void;

// 加载外部配置 XML（异步，setTimeout 3s）
public static function loadExternalConfigs():void;

// 从绝对路径加载角色
public static function loadFighterFromPath(path:String, back:Function, fail:Function = null):void;
```

## 错误处理

| 位置 | 错误 | 处理 |
|------|------|------|
| ANEFileReader 构造 | ExtensionContext 创建异常 | try-catch → `_hasANE = false` → 降级 |
| readBytes ANE 路径 | File 不存在或不是文件 | Java 返回 null → AS3 返回 null |
| readBytes Fallback | FileStream 打开失败 | try-catch → 返回 null |
| listDir ANE 路径 | 目录不存在或不是目录 | Java 返回 null → AS3 返回 `[]` |
| listDir Fallback | getDirectoryListing 失败 | 返回 `[]` |
| scanExternalFighters | basePath 不存在 | early return |
| scanExternalMaps | basePath 不存在 | early return |
| tryLoadExternalXML | XML 解析失败 | try-catch → Debugger.log |
| loadFighterFromPath | ByteArray 为 null | 调用 fail 回调 |
| scanExternalAssets | 任何异常 | try-catch → trace 输出 |

## 配置和环境假设

| 配置项 | 默认值 | 来源 |
|--------|--------|------|
| EXTERNAL_BASE | `Android/data/air.com.bvn.yinyu/files/BVN/assets/` | ANEFileReader.as |
| ANE_ENABLED | `true` | ANEFileReader.as |
| 扫描延迟 (assets) | `2000ms` | GameLoader.scanExternalAssets |
| 扫描延迟 (configs) | `3000ms` | GameLoader.loadExternalConfigs |
| ANE 平台 | `Android-ARM64` | extension.xml |
| ANE namespace | `http://ns.adobe.com/air/extension/32.0` | extension.xml |

## 测试计划

| 测试场景 | 前置条件 | 预期结果 | 验证方式 |
|----------|----------|----------|----------|
| ANE 正常模式 | ANE_ENABLED=true + ANE 已打包 | ExtensionContext 创建成功 | logcat: `[ANEFileReader] ANE init: OK` |
| ANE 降级模式 | ANE_ENABLED=false | 使用 File API 降级，不崩溃 | logcat: `readBytes fallback (AIR File API)` |
| 外部角色扫描 | 外部 fighter/ 有 `test.swf` | FighterVO 注册成功 | logcat: `Registered external fighter: test` |
| 内置优先 | 外部 fighter/ 有与内置同 ID 的 SWF | 外部跳过 | logcat: `External fighter skipped (already registered)` |
| 外部配置合并 | 外部 config/ 有 `fighter.xml` | 配置追加 | logcat: `External fighter.xml merged` |
| 空外部目录 | 外部目录不存在 | 静默跳过 | logcat: `External fighter path not found, skipping` |
| ANE 构建 | 运行 build_ane.bat | 五步全部通过 | 控制台输出 `[OK]` |

## 实现风险

| 风险 | 严重性 | 可能性 | 说明 |
|------|--------|--------|------|
| `tryLoadExternalXML` 作用域 bug | 🔴 高 | 确定 | `basePath` 不在作用域内，外部配置 XML 加载必定失败 |
| ANE 与 File API 行为不一致 | 🟡 中 | 低 | File.list() 和 getDirectoryListing() 返回格式可能不同 |
| 外部 SWF 结构不兼容 | 🟡 中 | 中 | 外部 SWF 缺少必需的 MovieClip 帧标签导致崩溃 |
| 启动延迟 | 🟢 低 | 中 | setTimeout 延迟可能不足以完成大目录扫描 |

## 待决问题

1. 🔴 **`tryLoadExternalXML` 作用域 bug** — 必须修复，见上文详细分析
2. 🟡 **应用私有目录用户可访问性** — 需确认是否需要提供辅助工具将文件复制到该目录
3. 🟡 **外部角色缺少 face/faceBig/faceBar/faceWin 属性** — 外部角色在选人界面无头像显示
4. 🔵 **合并后选人 UI 刷新** — 外部配置合并后选人列表是否需要重新渲染？
