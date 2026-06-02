package net.play5d.game.bvn.win.utils
{
   import flash.filesystem.File;
   import flash.filesystem.FileStream;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.utils.GameLoger;
   
   public class FileUtils
   {
      
      public function FileUtils()
      {
         super();
      }
      
      public static function writeFile(param1:String, param2:*, param3:String = null) : void
      {
         var _loc4_:File = null;
         var _loc5_:FileStream = null;
         var _loc6_:ByteArray = null;
         if(!param3)
         {
            param3 = "write";
         }
         try
         {
            _loc4_ = new File(param1);
            _loc5_ = new FileStream();
            _loc5_.open(_loc4_,param3);
            if(param2 is String)
            {
               _loc5_.writeUTFBytes(param2);
            }
            if(param2 is ByteArray)
            {
               _loc6_ = param2 as ByteArray;
               _loc5_.writeBytes(_loc6_,0,_loc6_.bytesAvailable);
            }
            _loc5_.close();
         }
         catch(e:Error)
         {
            GameLoger.log("FileUtils.writeFile" + e);
         }
      }
      
      public static function writeAppFloderFile(param1:String, param2:*, param3:String = null) : void
      {
         var _loc4_:String = getAppFloderFileUrl(param1);
         writeFile(_loc4_,param2,param3);
      }
      
      public static function writeAppStorageFloderFile(param1:String, param2:*, param3:String = null) : void
      {
         var _loc4_:String = getAppStorageFloderFileUrl(param1);
         writeFile(_loc4_,param2,param3);
      }
      
      public static function getAppFloderFileUrl(param1:String) : String
      {
         var _loc3_:File = File.applicationDirectory;
         var _loc2_:String = _loc3_.nativePath;
         return _loc2_ + File.separator + param1;
      }
      
      public static function getAppStorageFloderFileUrl(param1:String) : String
      {
         var _loc3_:File = File.applicationStorageDirectory;
         var _loc2_:String = _loc3_.nativePath;
         return _loc2_ + File.separator + param1;
      }
      
      public static function createFloder(param1:String) : void
      {
         var _loc2_:* = null;
         try
         {
            _loc2_ = new File(param1);
            _loc2_.createDirectory();
         }
         catch(e:Error)
         {
            GameLoger.log("FileUtils.createFloder" + e);
         }
      }
      
      public static function readTextFile(param1:String) : String
      {
         var _loc2_:File = null;
         var _loc4_:FileStream = null;
         var _loc3_:String = null;
         try
         {
            _loc2_ = new File(param1);
            _loc4_ = new FileStream();
            _loc4_.open(_loc2_,"read");
            _loc3_ = _loc4_.readUTFBytes(_loc4_.bytesAvailable);
            _loc4_.close();
         }
         catch(e:Error)
         {
            GameLoger.log("FileUtils.readTextFile , " + e);
         }
         return _loc3_;
      }
      
      public static function del(param1:String) : void
      {
         var _loc2_:File = new File(param1);
         try
         {
            _loc2_.deleteFile();
         }
         catch(e:Error)
         {
            GameLoger.log("FileUtils.del" + e);
         }
      }
   }
}

