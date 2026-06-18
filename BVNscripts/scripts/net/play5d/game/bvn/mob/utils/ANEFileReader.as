package net.play5d.game.bvn.mob.utils
{
   import flash.external.ExtensionContext;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.Debugger;

   public class ANEFileReader
   {
      private static var _i:ANEFileReader;
      private var _ctx:ExtensionContext;
      private var _hasANE:Boolean;

      private static const TAG:String = "[ANEFileReader]";

      /** Set to false when ANE (.ane file) is bundled in APK. Requires:
       *   1. application.xml: uncomment <extensions><extensionID>com.bvn.filereader</extensionID></extensions>
       *   2. debug_mob.bat: ensure BVNFileReader.ane is in tools/Test/ before packaging
       *   When ANE is not bundled, AIR File API fallback handles all file operations. */
      public static var ANE_ENABLED:Boolean = false;

      public function ANEFileReader()
      {
         super();
         try
         {
            if(ANE_ENABLED) { _ctx = ExtensionContext.createExtensionContext("com.bvn.filereader", "");
            _hasANE = (_ctx != null); } else { _ctx = null; _hasANE = false; }
            Debugger.log(TAG, "ANE init:", _hasANE ? "OK" : "FAILED (ctx=null)");
            // Dynamic EXTERNAL_BASE — get Android path via ANE, fall back to hardcoded
            if(_hasANE)
            {
               tryInitExternalBase();
            }
         }
         catch(e:Error)
         {
            _ctx = null;
            _hasANE = false;
            Debugger.log(TAG, "ANE init ERROR:", e.message);
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

      /** External resource base path — app-private external storage on Android.
       *  Path: /storage/emulated/0/Android/data/air.com.bvn.yinyu/BVN/assets/
       *  Users can push custom content via:
       *    adb push <local_dir>/ /storage/emulated/0/Android/data/air.com.bvn.yinyu/BVN/assets/
       *  Subdirs: fighter/ map/ face/ bgm/ config/  (auto-created on first launch) */
      public static var EXTERNAL_BASE:String = "/storage/emulated/0/Android/data/air.com.bvn.yinyu/BVN/assets/";

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
         return EXTERNAL_BASE + assetPath;
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
            result = _ctx.call("exists", path) as Boolean;
         }
         else
         {
            result = existsFallback(path);
         }
         Debugger.log(TAG, "exists:", path, "=" + result);
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
