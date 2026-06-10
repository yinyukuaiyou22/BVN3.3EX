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
      public static var ANE_ENABLED:Boolean = true;

      public function ANEFileReader()
      {
         super();
         try
         {
            if(ANE_ENABLED) { _ctx = ExtensionContext.createExtensionContext("com.bvn.filereader", "");
            _hasANE = (_ctx != null); } else { _ctx = null; _hasANE = false; }
            Debugger.log(TAG, "ANE init:", _hasANE ? "OK" : "FAILED (ctx=null)");
         }
         catch(e:Error)
         {
            _ctx = null;
            _hasANE = false;
            Debugger.log(TAG, "ANE init ERROR:", e.message);
         }
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

      /** External resource base path. On Android: /storage/emulated/0/BVN/assets/ */
      public static var EXTERNAL_BASE:String = "/storage/emulated/0/BVN/assets/";

      /** Map assets/ relative path to external base dir */
      public static function resolveExternalPath(assetPath:String) : String
      {
         return EXTERNAL_BASE + assetPath;
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
