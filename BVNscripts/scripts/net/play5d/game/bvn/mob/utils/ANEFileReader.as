package net.play5d.game.bvn.mob.utils
{
   import flash.events.*;
   import flash.external.ExtensionContext;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import net.play5d.game.bvn.Debugger;

   public class ANEFileReader
   {
      private static var _i:ANEFileReader;
      private var _ctx:ExtensionContext;
      private var _hasANE:Boolean;

      private static const TAG:String = "[ANEFileReader]";

      /** 外置异步读取看门狗超时（毫秒），见 readBytesAsync 内说明。
       *  取 8000ms：远大于正常读盘耗时（含 5MB 的 effect.swf），又远小于用户可感知的“卡死”。 */
      private static const READ_ASYNC_TIMEOUT_MS:int = 8000;

      /** Master switch for the WHOLE external-resource subsystem (scanning fighters/maps,
       *  merging external config XML, per-asset external override). Consumed by GameData and
       *  AssetLoader. It is deliberately separate from ANE_ENABLED: external resources work
       *  through the AIR File API alone, they do not need the native extension. */
      public static var EXTERNAL_ENABLED:Boolean = true;

      /** Attempt to create the native extension context — DISABLED by design (2026-10-09).
       *  com.bvn.filereader cannot be loaded on this toolchain (AIR 51 captive runtime):
       *  ExtensionContext.createExtensionContext() always throws Error #2113 in the
       *  runtime's LoaderContext.SecurityDomain check, BEFORE any Java code runs.
       *  Verified against 8 variable families incl. a third-party ANE control group and
       *  Adobe's own AIR 33.1.1 — see tools/Test/_report/2026-10-09_ANE-诊断报告.md.
       *  Only set to true if a future toolchain is proven to load the ANE. */
      public static var ANE_ENABLED:Boolean = false;

      public function ANEFileReader()
      {
         super();
         tryInitContext();
      }

      /** Attempt to create the extension context (only when ANE_ENABLED is true).
       *  Kept so a future, verified toolchain can simply flip the flag back. */
      private function tryInitContext() : void
      {
         if(!ANE_ENABLED)
         {
            _ctx = null;
            _hasANE = false;
            Debugger.log(TAG, "ANE disabled (by design) — AIR File API path active");
            return;
         }
         try
         {
            _ctx = ExtensionContext.createExtensionContext("com.bvn.filereader", null);
            _hasANE = (_ctx != null);
            Debugger.log(TAG, "ANE init:", _hasANE ? "OK" : "FAILED (ctx=null)");
            // Dynamic EXTERNAL_BASE — get the Android path via ANE, else keep hardcoded
            if(_hasANE)
            {
               tryInitExternalBase();
            }
         }
         catch(e:Error)
         {
            _ctx = null;
            _hasANE = false;
            Debugger.warn(TAG, "ANE init ERROR:", e.message);
         }
      }

      private function tryInitExternalBase() : void
      {
         try
         {
            var apiPath:String = _ctx.call("getExternalFilesDir", "") as String;
            if(apiPath && apiPath.length > 0)
            {
               // apiPath is like "/storage/.../files/", append BVN/assets/
               EXTERNAL_BASE = apiPath + "BVN/assets/";
               Debugger.log(TAG, "EXTERNAL_BASE from API:", EXTERNAL_BASE);
               return;
            }
         }
         catch(e:Error)
         {
            Debugger.log(TAG, "getExternalFilesDir failed, using hardcoded path");
         }
         // Keep hardcoded default (already set)
         Debugger.log(TAG, "EXTERNAL_BASE (hardcoded):", EXTERNAL_BASE);
      }

      public static function get I() : ANEFileReader
      {
         if(!_i)
         {
            _i = new ANEFileReader();
         }
         return _i;
      }

      public function get hasANE() : Boolean
      {
         return _hasANE;
      }

      /** External resource base path — app-writable external storage on Android 11+.
       *
       *  Why Android/media and NOT Android/data:
       *    - An app may not *create* Android/data/<pkg>/ with a raw path; the framework
       *      creates it only via getExternalFilesDir(), which needs native code (the ANE
       *      is unusable, see ANE_ENABLED). Measured: Error #3001.
       *    - Android/media/<pkg>/ can be created and written with NO permission.
       *  On-device probe (vivo V2073A / Android 13): create + write + read-back all OK.
       *  Users can push custom content via adb (tar, to avoid CJK filename truncation):
       *    adb push x.tar /sdcard/ && adb shell tar xf /sdcard/x.tar -C <this dir>
       *  Subdirs: fighter/ map/ face/ bgm/ config/  (auto-created on first launch) */
      public static var EXTERNAL_BASE:String = "/storage/emulated/0/Android/media/air.com.bvn.yy798/BVN/assets/";

      /** DocumentsProvider authority string. File managers (e.g. MT Manager) use this to browse app data.
       *  Call registerProvider() to wake the process before opening in a file manager. */
      public static const PROVIDER_AUTHORITY:String = "air.com.bvn.yinyu.BVNDataFilesProvider";

      /** Wake up the DocumentsProvider process so file managers can browse app-private data.
       *  Only works when ANE is active. Returns true on success, false on failure or ANE unavailable. */
      public function registerProvider() : Boolean
      {
         if(!_hasANE || !_ctx)
         {
            Debugger.log(TAG, "registerProvider: ANE not available, cannot wake provider");
            return false;
         }
         try
         {
            var result:Object = _ctx.call("registerProvider");
            Debugger.log(TAG, "registerProvider:", result ? "OK" : "FAILED");
            return result as Boolean;
         }
         catch(e:Error)
         {
            Debugger.log(TAG, "registerProvider ERROR:", e.message);
            return false;
         }
      }

      /** Map assets/ relative path to external base dir */
      public static function resolveExternalPath(assetPath:String) : String
      {
         var clean:String = assetPath ? assetPath.replace(/\\/g,"/") : "";
         while(clean.indexOf("../") == 0) clean = clean.substr(3);
         while(clean.indexOf("/") == 0) clean = clean.substr(1);
         return EXTERNAL_BASE + clean;
      }

      /** Create a directory (including parents) via ANE java.io.File.mkdirs().
       *  Bypasses AIR File API sandbox on Android 11+. */
      public function createDirectory(path:String) : Boolean
      {
         Debugger.log(TAG, "createDirectory:", path);
         if(_hasANE)
         {
            var result:Object = _ctx.call("createDirectory", path);
            return result as Boolean;
         }
         // Fallback: AIR File API
         try {
            var f:File = new File(path);
            if(f.exists) return true;
            f.createDirectory();
            return f.exists;
         } catch(e:Error) {
            return false;
         }
      }

      /** Write ByteArray data to a file via ANE. Creates parent dirs if needed.
       *  @param append  If true, append to existing file; otherwise overwrite. */
      public function writeBytes(path:String, data:ByteArray, append:Boolean=false) : Boolean
      {
         Debugger.log(TAG, "writeBytes:", path, data ? data.length + " bytes" : "null");
         if(_hasANE)
         {
            var result:Object = _ctx.call("writeBytes", path, data, append);
            return result as Boolean;
         }
         // Fallback: AIR File API
         try {
            var f:File = new File(path);
            var fs:FileStream = new FileStream();
            var mode:String = append ? FileMode.APPEND : FileMode.WRITE;
            fs.open(f, mode);
            fs.writeBytes(data, 0, data.length);
            fs.close();
            return true;
         } catch(e:Error) {
            Debugger.log(TAG, "writeBytes fallback ERROR:", e.message);
            return false;
         }
      }

      /** Delete a file via ANE. */
      public function deleteFile(path:String) : Boolean
      {
         Debugger.log(TAG, "deleteFile:", path);
         if(_hasANE)
         {
            var result:Object = _ctx.call("deleteFile", path);
            return result as Boolean;
         }
         try {
            var f:File = new File(path);
            if(f.exists) { f.deleteFile(); return true; }
            return false;
         } catch(e:Error) { return false; }
      }

      /** Get file state: {exists:Boolean, isDirectory:Boolean, isFile:Boolean}. */
      public function getFileState(path:String) : Object
      {
         if(_hasANE)
         {
            return _ctx.call("getFileState", path);
         }
         try {
            var f:File = new File(path);
            return {exists: f.exists, isDirectory: f.isDirectory, isFile: f.exists && !f.isDirectory};
         } catch(e:Error) { return null; }
      }

      /** Check if a file exists on external SD card */
      public static function hasExternalAsset(assetPath:String) : Boolean
      {
         return I.exists(resolveExternalPath(assetPath));
      }

      /** Read file bytes from absolute path */
      public function readBytes(path:String) : ByteArray
      {
         Debugger.log(TAG, "readBytes:", path, "hasANE=" + _hasANE);
         if(_hasANE)
         {
            var result:ByteArray = _ctx.call("readBytes", path) as ByteArray;
            Debugger.log(TAG, "readBytes result:", result ? result.length + " bytes" : "null");
            return result;
         }
         Debugger.log(TAG, "readBytes fallback (AIR File API)");
         return readBytesFallback(path);
      }

      /** 异步读取文件字节（AIR File API 的 FileStream.openAsync）。
       *
       *  批量并发加载依赖它：openAsync 把读盘交给运行时线程，主线程不再像同步 FileStream
       *  那样被整个文件的读取阻塞（满量外置资源时这是启动与进战斗卡顿的主因）。
       *  读取失败（文件不存在/不可读）时回调 fail()，由调用方回退内置 URL。
       *  @param path 绝对路径
       *  @param back 成功回调 back(bytes:ByteArray)
       *  @param fail 失败回调 fail() */
      public function readBytesAsync(path:String, back:Function, fail:Function = null) : void
      {
         if(_hasANE)
         {
            var aneBytes:ByteArray = null;
            try
            {
               aneBytes = _ctx.call("readBytes", path) as ByteArray;
            }
            catch(e:Error)
            {
               Debugger.log(TAG, "readBytesAsync ANE ERROR:", e.message);
            }
            if(aneBytes && aneBytes.length > 0)
            {
               if(back != null) back(aneBytes);
            }
            else if(fail != null)
            {
               fail();
            }
            return;
         }
         var f:File = new File(path);
         if(!f.exists || f.isDirectory)
         {
            if(fail != null) fail();
            return;
         }
         var fs:FileStream = new FileStream();
         var ba:ByteArray = new ByteArray();
         var finished:Boolean = false;
         var watchdog:Timer = null;
         var closeStream:Function = function() : void
         {
            if(watchdog != null)
            {
               try { watchdog.stop(); } catch(e:Error) {}
               watchdog = null;
            }
            try { fs.removeEventListener(Event.COMPLETE,onComplete); } catch(e:Error) {}
            try { fs.removeEventListener(IOErrorEvent.IO_ERROR,onError); } catch(e:Error) {}
            try { fs.removeEventListener(Event.CLOSE,onError); } catch(e:Error) {}
            try { fs.close(); } catch(e:Error) {}
         };
         var onComplete:Function = function(e:Event) : void
         {
            if(finished) return;
            finished = true;
            try
            {
               fs.readBytes(ba,0,fs.bytesAvailable);
            }
            catch(err:Error)
            {
               Debugger.log(TAG, "readBytesAsync read ERROR:", path, err.message);
            }
            closeStream();
            if(ba.length > 0)
            {
               Debugger.log(TAG, "readBytesAsync OK:", path, ba.length, "bytes");
               if(back != null) back(ba);
            }
            else if(fail != null)
            {
               fail();
            }
         };
         var onError:Function = function(e:Event) : void
         {
            if(finished) return;
            finished = true;
            closeStream();
            Debugger.log(TAG, "readBytesAsync ERROR:", path);
            if(fail != null) fail();
         };
         fs.addEventListener(Event.COMPLETE,onComplete);
         fs.addEventListener(IOErrorEvent.IO_ERROR,onError);
         fs.addEventListener(Event.CLOSE,onError);
         // ===== 2026-10-11 看门狗：保证 back / fail 二者必被调用一次 =====
         // 背景：真机上 openAsync 存在「既不派发 COMPLETE、也不派发 IO_ERROR / CLOSE」的情况
         // （实测：外置 bgm/ 或 sounds/ 存在时启动必现永久卡死，外置读取越多越容易命中）。
         // 一旦发生，本函数既不 back 也不 fail，而整条调用链都靠回调推进：
         //   AssetBatchLoader 的 _active 只在 onDone / onFail 中 settle → 永不归零
         //   → checkFinish() 永不成立 → loadBasic 某一步永不返回 → 永久卡在加载界面。
         // 这里给出兜底出口：超时即按失败处理，调用方的 fail() 会回退内置加载，
         // 于是「永不结算」在架构上不再可能发生。
         watchdog = new Timer(READ_ASYNC_TIMEOUT_MS,1);
         watchdog.addEventListener(TimerEvent.TIMER,function(e:TimerEvent) : void
         {
            if(finished) return;
            finished = true;
            Debugger.log(TAG, "readBytesAsync TIMEOUT, treat as fail:", path, "timeoutMs=", READ_ASYNC_TIMEOUT_MS);
            closeStream();
            if(fail != null) fail();
         });
         try
         {
            fs.openAsync(f,FileMode.READ);
            watchdog.start();
         }
         catch(e:Error)
         {
            finished = true;
            if(watchdog != null)
            {
               try { watchdog.stop(); } catch(e2:Error) {}
               watchdog = null;
            }
            Debugger.log(TAG, "readBytesAsync openAsync failed, fallback to sync:", path, e.message);
            var syncBytes:ByteArray = readBytesFallback(path);
            if(syncBytes && syncBytes.length > 0)
            {
               if(back != null) back(syncBytes);
            }
            else if(fail != null)
            {
               fail();
            }
         }
      }

      /** List filenames in directory */
      public function listDir(path:String) : Array
      {
         Debugger.log(TAG, "listDir:", path, "hasANE=" + _hasANE);
         if(_hasANE)
         {
            var arr:Array = _ctx.call("listDir", path) as Array;
            Debugger.log(TAG, "listDir result:", arr ? arr.length + " files" : "null");
            return arr;
         }
         Debugger.log(TAG, "listDir fallback (AIR File API)");
         return listDirFallback(path);
      }

      /** Check if path exists */
      public function exists(path:String) : Boolean
      {
         var result:Boolean;
         if(_hasANE)
         {
            try { result = _ctx.call("exists", path) as Boolean; }
            catch(e:Error) { Debugger.log(TAG, "exists ANE ERROR:", path, e.message); result = existsFallback(path); }
         }
         else
         {
            result = existsFallback(path);
         }
         // 每个资源都要探测一次，正常路径改为折叠计数（错误分支见上面的 catch，仍单条输出）
         Debugger.logFold("ANEFileReader.exists", path + "=" + result);
         return result;
      }

      // ---- Fallback via AIR File API (sandbox-limited) ----

      private function readBytesFallback(path:String) : ByteArray
      {
         var f:File = new File(path);
         if(!f.exists)
         {
            Debugger.log(TAG, "readBytesFallback: file not found:", path);
            return null;
         }
         var fs:FileStream = new FileStream();
         var ba:ByteArray = new ByteArray();
         try
         {
            fs.open(f, FileMode.READ);
            fs.readBytes(ba, 0, fs.bytesAvailable);
            fs.close();
            Debugger.log(TAG, "readBytesFallback OK:", ba.length, "bytes");
         }
         catch(e:Error)
         {
            Debugger.log(TAG, "readBytesFallback ERROR:", e.message);
            return null;
         }
         return ba;
      }

      private function listDirFallback(path:String) : Array
      {
         var f:File = new File(path);
         if(!f.exists || !f.isDirectory)
         {
            Debugger.log(TAG, "listDirFallback: not found or not dir:", path);
            return [];
         }
         var list:Array = f.getDirectoryListing();
         var result:Array = [];
         for each(var item:File in list)
         {
            result.push(item.name);
         }
         Debugger.log(TAG, "listDirFallback OK:", result.length, "files");
         return result;
      }

      private function existsFallback(path:String) : Boolean
      {
         var f:File = new File(path);
         return f.exists;
      }
   }
}
