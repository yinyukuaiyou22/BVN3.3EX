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

      public function createDirectory(path:String) : Boolean
      {
         if(ctx != null) return ctx.call("createDirectory", path) as Boolean;
         return false;
      }

      public function writeBytes(path:String, data:ByteArray, append:Boolean=false) : Boolean
      {
         if(ctx != null) return ctx.call("writeBytes", path, data, append) as Boolean;
         return false;
      }

      public function deleteFile(path:String) : Boolean
      {
         if(ctx != null) return ctx.call("deleteFile", path) as Boolean;
         return false;
      }

      public function getFileState(path:String) : Object
      {
         if(ctx != null) return ctx.call("getFileState", path);
         return null;
      }

      public function getExternalFilesDir(subPath:String="") : String
      {
         if(ctx != null) return ctx.call("getExternalFilesDir", subPath) as String;
         return null;
      }
   }
}
