# BVN ANE 开发指南

> 基于实战经验总结，涵盖从零搭建到调试的完整流程。

---

## 一、ANE 是什么

ANE（Adobe Native Extension）是 AIR 调用移动设备原生功能的桥梁。AS3 无法直接操作文件系统、硬件、传感器等——ANE 用 Java（Android）实现这些功能，通过 FRE（Flash Runtime Extension）API 暴露给 AS3。

```
AS3 (ANEFileReader.as)
  → ExtensionContext.call("functionName", args)
    → Java FREFunction.call(ctx, args)
      → java.io.File / android.* API
```

## 二、ANE 项目结构

```
extensions/YourANE/
├── extension.xml                    # ANE 描述符
├── build_ane.bat                    # 构建脚本
├── Android/
│   ├── lib/FlashRuntimeExtensions.jar  # FRE API（AIR SDK 提供）
│   └── src/com/example/
│       ├── YourExtension.java       # FREExtension 入口
│       └── YourExtensionContext.java # FREContext + FREFunction 实现
├── as3/com/example/
│   └── YourLib.as                  # AS3 SWC 类库
└── build/                           # 临时构建产物（gitignore）
```

## 三、extension.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<extension xmlns="http://ns.adobe.com/air/extension/32.0">
    <id>com.example.YourExt</id>          <!-- 唯一标识 -->
    <versionNumber>1.0</versionNumber>
    <platforms>
        <platform name="Android-ARM64">    <!-- ARM 64位 -->
            <applicationDeployment>
                <nativeLibrary>YourExt.jar</nativeLibrary>
                <initializer>com.example.YourExtension</initializer>
            </applicationDeployment>
        </platform>
    </platforms>
</extension>
```

- `<id>` 必须与 AS3 中 `ExtensionContext.createExtensionContext("com.example.YourExt", "")` 第一个参数一致
- 平台名：`Android-ARM64`（64位）、`Android-ARM`（32位）
- namespace `32.0` 适用于 AIR 32+

## 四、Java 层（原生实现）

### 4.1 FREExtension 入口

```java
package com.example;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

public class YourExtension implements FREExtension {
    public void initialize() {}

    public FREContext createContext(String extId) {
        return new YourExtensionContext();  // 每个 AS3 ExtensionContext 创建一个实例
    }

    public void dispose() {}
}
```

### 4.2 FREFunction 实现

```java
public class YourExtensionContext extends FREContext {
    @Override
    public Map<String, FREFunction> getFunctions() {
        Map<String, FREFunction> map = new HashMap<>();
        map.put("doSomething", new DoSomethingFunction());
        return map;
    }

    @Override
    public void dispose() {}

    private class DoSomethingFunction implements FREFunction {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args) {
            try {
                String param = args[0].getAsString();           // 读 AS3 参数
                // ... 原生逻辑 ...
                return FREObject.newObject("result");            // 返回值给 AS3
            } catch(Exception e) {
                e.printStackTrace();
                return null;
            }
        }
    }
}
```

### 4.3 FREFunction 数据转换

| AS3 类型 | Java 读取 | Java 返回 |
|----------|-----------|-----------|
| `String` | `args[0].getAsString()` | `FREObject.newObject("str")` |
| `Boolean` | `args[0].getAsBool()` | `FREObject.newObject(true)` |
| `int` | `args[0].getAsInt()` | `FREObject.newObject(42)` |
| `ByteArray` | `FREByteArray` + `acquire()` + `getBytes()` | `FREByteArray` + `release()` |
| `Array` | 遍历 `FREArray` | `FREArray.newArray(n)` + `setObjectAt()` |

### 4.4 ANE → AS3 通信（事件）

```java
// Java 侧发事件
ctx.dispatchStatusEventAsync("EVENT_CODE", "level_info");
```

```as3
// AS3 侧监听
_ctx.addEventListener(StatusEvent.STATUS, function(e:StatusEvent):void {
    trace(e.code, e.level);  // "EVENT_CODE", "level_info"
});
```

### 4.5 ANE ↔ AS3 共享数据

```java
// Java 侧读写
FREObject shared = ctx.getActionScriptData();  // 从 AS3 读
ctx.setActionScriptData(FREObject.newObject("data"));  // 写回 AS3
```

```as3
// AS3 侧
_ctx.actionScriptData = "hello";  // 写入
var val:Object = _ctx.actionScriptData;  // 读取
```

## 五、AS3 SWC 层

```as3
package com.example {
    import flash.external.ExtensionContext;

    public class YourLib {
        private var _ctx:ExtensionContext;  // 成员变量（官方推荐）

        public function YourLib() {
            try {
                _ctx = ExtensionContext.createExtensionContext("com.example.YourExt", "");
            } catch(e:Error) {
                _ctx = null;
            }
        }

        public function doSomething(param:String) : String {
            if(_ctx) return _ctx.call("doSomething", param) as String;
            return null;
        }
    }
}
```

> **为什么用成员变量而非静态变量**：静态 `ExtensionContext` 创建过早，可能 app 还没初始化完毕就尝试连接原生层，导致看不到效果。成员变量按需创建，更可靠。

## 六、构建 ANE

### build_ane.bat 五步流程

```
[1/5] javac → .class          # JDK 8 编译 Java
[2/5] jar → .jar              # 打包 JAR
[3/5] compc → .swc            # Flex SDK 编译 AS3 SWC
       unzip .swc → library.swf  # 提取 SWF
[4/5] adt -package → .ane     # AIR SDK 打包 ANE
[5/5] copy → tools/Test/      # 复制到编译产物目录
```

### 关键构建参数

```bash
# Java 编译（JDK 8 + Android SDK android.jar）
javac -d build/java \
  -cp "FlashRuntimeExtensions.jar;android.jar" \
  -sourcepath "src" \
  src/com/example/*.java

# ADT 打包 ANE
adt -package -target ane output.ane extension.xml \
  -swc build/BVNFileReader.swc \
  -platform Android-ARM64 -C build/Android-ARM64 .
```

## 七、集成到 AIR 应用

### application.xml

```xml
<application xmlns="http://ns.adobe.com/air/application/32.0">
    <id>com.example.app</id>
    <extensions>
        <extensionID>com.example.YourExt</extensionID>
    </extensions>

    <!-- Android manifest 自定义项 -->
    <android>
        <manifestAdditions><![CDATA[
            <manifest>
                <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
            </manifest>
        ]]></manifestAdditions>
    </android>
</application>
```

### ADT 打包 APK

```bash
adt -package -target apk-captive-runtime \
  -arch armv8 \
  -storetype pkcs12 -keystore cert.p12 -storepass password \
  output.apk application.xml \
  -extdir "." \            # ANE 文件所在目录
  -platformsdk D:/Android/SDK \
  launch.swf -C . assets
```

## 八、调试

### PC 端限制

- PC 上运行 `ExtensionContext.createExtensionContext()` 会报错：*"Requested extension xxx is not supported for Windows-x86"*
- 这是**正常的**——ANE 是移动端原生代码，无法在 PC 模拟
- 必须打包 APK 安装到真机测试

### 调试方法

| 方法 | 说明 |
|------|------|
| **logcat** | `adb logcat -s AdobeAIR:I` 查看 trace 输出（部分设备屏蔽） |
| **Debug 面板** | BVN 内置，启动时初始化，屏幕上显示绿色日志 |
| **文件日志** | `File.applicationStorageDirectory` 写日志文件，`adb exec-out run-as` 拉取 |
| **`android.util.Log`** | Java 侧用 `Log.i("ANE", "msg")` 直接输出到 logcat，不受 Vivo 过滤 |

### 常见错误

| 错误 | 原因 | 解决 |
|------|------|------|
| `implementation not found` | ANE 未编入 APK | 检查 `-extdir "."` + ANE 文件在目录中 |
| `Extension context is not available` | `ANE_ENABLED=false` 或扩展 ID 不匹配 | 检查三开关 |
| `The import android cannot be resolved` (IDE) | IDE 缺少 android.jar | 配置 `.vscode/settings.json` 的 `java.project.referencedLibraries` |
| ANE 加载成功但调用返回 null | Java 层异常被 catch | 检查 logcat 中的 `printStackTrace` 输出 |

## 九、AIR 移动端存储路径

| AIR API | Android 实际路径 | 权限 |
|---------|-----------------|------|
| `File.applicationStorageDirectory` | `/data/data/<pkg>/<appID>/Local Store/` | 无需 |
| `File.documentsDirectory` | `/sdcard`（=`/storage/emulated/0/`） | `WRITE_EXTERNAL_STORAGE` |
| `File.desktopDirectory` | `/sdcard` 根 | `WRITE_EXTERNAL_STORAGE` |
| `File.applicationDirectory` | APK 内 assets（只读） | 无需 |
| `File.cacheDirectory` | `/data/data/<pkg>/<appID>/cache/` | 无需 |

> **Android 11+ 注意**：`WRITE_EXTERNAL_STORAGE` 在 scoped storage 下基本无效。写外部文件应改用 ANE 的 `java.io.File`（app 自有目录无需权限）或 SAF。

## 十、BVN 项目 ANE 速查

| 项目 | 值 |
|------|-----|
| 扩展 ID | `com.bvn.filereader` |
| 平台 | `Android-ARM64` |
| JDK | `D:\JDK8`（d8 兼容 class v52） |
| Android SDK | `D:\Android\SDK\platforms\android-33\android.jar` |
| 构建脚本 | `extensions\BVNFileReader\build_ane.bat` |
| APK 打包 | `tools\script\debug_mob.bat`（含 `-extdir "."`） |

### BVN ANE 完整函数列表

| FREFunction | 用途 | 参数 → 返回 |
|-------------|------|-------------|
| `readBytes` | 读文件 | `path:String` → `ByteArray` |
| `listDir` | 列目录 | `path:String` → `Array<String>` |
| `exists` | 检查存在 | `path:String` → `Boolean` |
| `createDirectory` | 创建目录 | `path:String` → `Boolean` |
| `registerProvider` | 激活 DocumentsProvider | 无 → `Boolean` |

### ANE 三开关

| # | 位置 | 设置 | 用途 |
|---|------|------|------|
| 1 | `ANEFileReader.as` | `ANE_ENABLED = true` | AS3 侧启用 |
| 2 | `application.xml` | `<extensionID>com.bvn.filereader</extensionID>` | AIR 声明 |
| 3 | `debug_mob.bat` | `-extdir "."` | ADT 打包 |

### 添加新 FREFunction 的步骤

1. 在 `BVNFileReaderExtensionContext.java` 中添加 `XXXFunction` 内部类
2. 在 `getFunctions()` 中注册 `functions.put("xxx", new XXXFunction())`
3. 在 `ANEFileReader.as` 中添加对应方法（含降级逻辑）
4. 在 `BVNFileReaderLib.as` 中添加声明（供 SWC 编译）
5. 运行 `build_ane.bat` 重建 ANE

---

## 参考资料

- [Adobe AIR Extensions API](http://help.adobe.com/zh_CN/air/extensions/index.html)
- [9ria ANE 教程 1](http://bbs.9ria.com/forum.php?mod=viewthread&tid=418251)
- [9ria ANE 教程 2](http://bbs.9ria.com/thread-156257-1-1.html)
- [MTDataFilesProvider](https://github.com/L-JINBIN/MTDataFilesProvider)
- 项目架构文档：[doc/architecture.md](architecture.md)
