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

      public function ANEFileReader()
      {
         super();
         try
         {
            _ctx = ExtensionContext.createExtensionContext("com.bvn.filereader", "");
            _hasANE = (_ctx != null);
         }
         catch(e:Error)
         {
            _ctx = null;
            _hasANE = false;
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
         if(_hasANE)
         {
            return _ctx.call("readBytes", path) as ByteArray;
         }
         return readBytesFallback(path);
      }

      /** List filenames in directory */
      public function listDir(path:String) : Array
      {
         if(_hasANE)
         {
            return _ctx.call("listDir", path) as Array;
         }
         return listDirFallback(path);
      }

      /** Check if path exists */
      public function exists(path:String) : Boolean
      {
         if(_hasANE)
         {
            return _ctx.call("exists", path);
         }
         return existsFallback(path);
      }

      // ---- Fallback via AIR File API (sandbox-limited) ----

      private function readBytesFallback(path:String) : ByteArray
      {
         var f:File = new File(path);
         if(!f.exists) return null;
         var fs:FileStream = new FileStream();
         var ba:ByteArray = new ByteArray();
         try
         {
            fs.open(f, FileMode.READ);
            fs.readBytes(ba, 0, fs.bytesAvailable);
            fs.close();
         }
         catch(e:Error)
         {
            return null;
         }
         return ba;
      }

      private function listDirFallback(path:String) : Array
      {
         var f:File = new File(path);
         if(!f.exists || !f.isDirectory) return [];
         var list:Array = f.getDirectoryListing();
         var result:Array = [];
         for each(var item:File in list)
         {
            result.push(item.name);
         }
         return result;
      }

      private function existsFallback(path:String) : Boolean
      {
         var f:File = new File(path);
         return f.exists;
      }
   }
}
