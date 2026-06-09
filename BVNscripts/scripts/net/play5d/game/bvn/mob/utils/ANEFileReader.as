package net.play5d.game.bvn.mob.utils
{
   import flash.external.ExtensionContext;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.ByteArray;

   public class ANEFileReader
   {
      private static var _i:ANEFileReader;
      private var _ctx:ExtensionContext;
      private var _hasANE:Boolean;

      private static const TAG:String = "[ANEFileReader]";

      public function ANEFileReader()
      {
         super();
         try
         {
            _ctx = ExtensionContext.createExtensionContext("com.bvn.filereader", "");
            _hasANE = (_ctx != null);
            trace(TAG, "ANE init:", _hasANE ? "OK" : "FAILED (ctx=null)");
         }
         catch(e:Error)
         {
            _ctx = null;
            _hasANE = false;
            trace(TAG, "ANE init ERROR:", e.message);
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

      /** Read file bytes from absolute path */
      public function readBytes(path:String) : ByteArray
      {
         trace(TAG, "readBytes:", path, "hasANE=" + _hasANE);
         if(_hasANE)
         {
            var result:ByteArray = _ctx.call("readBytes", path) as ByteArray;
            trace(TAG, "readBytes result:", result ? result.length + " bytes" : "null");
            return result;
         }
         trace(TAG, "readBytes fallback (AIR File API)");
         return readBytesFallback(path);
      }

      /** List filenames in directory */
      public function listDir(path:String) : Array
      {
         trace(TAG, "listDir:", path, "hasANE=" + _hasANE);
         if(_hasANE)
         {
            var arr:Array = _ctx.call("listDir", path) as Array;
            trace(TAG, "listDir result:", arr ? arr.length + " files" : "null");
            return arr;
         }
         trace(TAG, "listDir fallback (AIR File API)");
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
         trace(TAG, "exists:", path, "=" + result);
         return result;
      }

      // ---- Fallback via AIR File API (sandbox-limited) ----

      private function readBytesFallback(path:String) : ByteArray
      {
         var f:File = new File(path);
         if(!f.exists)
         {
            trace(TAG, "readBytesFallback: file not found:", path);
            return null;
         }
         var fs:FileStream = new FileStream();
         var ba:ByteArray = new ByteArray();
         try
         {
            fs.open(f, FileMode.READ);
            fs.readBytes(ba, 0, fs.bytesAvailable);
            fs.close();
            trace(TAG, "readBytesFallback OK:", ba.length, "bytes");
         }
         catch(e:Error)
         {
            trace(TAG, "readBytesFallback ERROR:", e.message);
            return null;
         }
         return ba;
      }

      private function listDirFallback(path:String) : Array
      {
         var f:File = new File(path);
         if(!f.exists || !f.isDirectory)
         {
            trace(TAG, "listDirFallback: not found or not dir:", path);
            return [];
         }
         var list:Array = f.getDirectoryListing();
         var result:Array = [];
         for each(var item:File in list)
         {
            result.push(item.name);
         }
         trace(TAG, "listDirFallback OK:", result.length, "files");
         return result;
      }

      private function existsFallback(path:String) : Boolean
      {
         var f:File = new File(path);
         return f.exists;
      }
   }
}
