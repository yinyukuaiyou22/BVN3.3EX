package com.bvn.filereader
{
   import flash.external.ExtensionContext;
   import flash.utils.ByteArray;

   public class BVNFileReaderLib
   {
      private static var _ctx:ExtensionContext;

      private static function get ctx() : ExtensionContext
      {
         if(!_ctx)
         {
            try
            {
               _ctx = ExtensionContext.createExtensionContext("com.bvn.filereader", "");
            }
            catch(e:Error)
            {
               _ctx = null;
            }
         }
         return _ctx;
      }

      public static function get isSupported() : Boolean
      {
         return ctx != null;
      }

      public function readBytes(path:String) : ByteArray
      {
         if(ctx != null) return ctx.call("readBytes", path) as ByteArray;
         return null;
      }

      public function listDir(path:String) : Array
      {
         if(ctx != null) return ctx.call("listDir", path) as Array;
         return null;
      }

      public function exists(path:String) : Boolean
      {
         if(ctx != null) return ctx.call("exists", path) as Boolean;
         return false;
      }
   }
}
