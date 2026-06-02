package nagisa.util
{
   import com.adobe.images.PNGEncoder;
   import flash.display.BitmapData;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.filesystem.File;
   import flash.filesystem.FileStream;
   import flash.utils.ByteArray;
   import nagisa.debug.OutputMessage;
   
   public class FileUtil
   {
      
      public static var defaultPath:String = null;
      
      public function FileUtil()
      {
         super();
      }
      
      public static function get defaultFolder() : String
      {
         if(!defaultPath)
         {
            return null;
         }
         return NagisaUtil.url_getFolder(defaultPath);
      }
      
      public static function get defaultName() : String
      {
         if(!defaultPath)
         {
            return null;
         }
         return NagisaUtil.url_getName(defaultPath);
      }
      
      public static function saveBitmapData(param1:*) : void
      {
         var _loc4_:* = undefined;
         if(!param1)
         {
            return;
         }
         var _loc2_:int = 0;
         var _loc3_:Vector.<ByteArray> = new Vector.<ByteArray>();
         switch(ClassUtil.checkTargetType(param1,BitmapData,Array,Vector.<*>) - -1)
         {
            case 0:
               return;
            case 1:
               _loc4_ = [param1];
               break;
            case 2:
            case 3:
               _loc4_ = param1;
               if(!_loc4_.length)
               {
                  return;
               }
         }
         while(_loc2_ < _loc4_.length)
         {
            _loc3_[_loc3_.length] = PNGEncoder.encode(_loc4_[_loc2_]);
            _loc2_++;
         }
         save(_loc3_,"png");
      }
      
      public static function save(param1:*, param2:String = null) : void
      {
         var file:File;
         var bytes:*;
         var saveComplete:Function;
         var byte:* = param1;
         var suffix:String = param2;
         if(!byte)
         {
            return;
         }
         file = new File(defaultPath);
         switch(ClassUtil.checkTargetType(byte,ByteArray,Array,Vector.<*>) - -1)
         {
            case 0:
               return;
            case 1:
               bytes = [byte];
               break;
            case 2:
            case 3:
               bytes = byte;
               if(!bytes.length)
               {
                  return;
               }
         }
         saveComplete = function(param1:Event):void
         {
            var _loc2_:ByteArray = null;
            var _loc4_:File = param1.target as File;
            var _loc3_:String = _loc4_.name;
            var _loc5_:int = 0;
            defaultPath = _loc4_.url;
            var _loc6_:FileStream = new FileStream();
            while(_loc5_ < bytes.length)
            {
               _loc2_ = bytes[_loc5_];
               if(_loc2_)
               {
                  file = new File(NagisaUtil.url_getPath(defaultFolder,_loc3_ + "_" + _loc5_,suffix));
                  _loc6_.open(file,"write");
                  _loc6_.writeBytes(_loc2_,0,_loc2_.length);
                  _loc6_.close();
                  _loc5_++;
               }
            }
         };
         file.addEventListener("select",saveComplete);
         file.browseForSave("Save Data");
      }
      
      public static function browse(param1:Function, ... rest) : void
      {
         var loadComplete:Function = param1;
         var fileFilters:Array = rest;
         var file:File = new File(defaultPath);
         var onLoadComplete:Function = function(param1:Event):void
         {
            var _loc2_:Loader = new Loader();
            defaultPath = file.url;
            _loc2_.loadBytes(file.data);
            _loc2_.contentLoaderInfo.addEventListener("complete",loadComplete);
         };
         file.addEventListener("select",_selectHandler);
         file.addEventListener("complete",onLoadComplete);
         file.browse(fileFilters);
      }
      
      private static function _selectHandler(param1:Event) : void
      {
         var _loc2_:File = param1.target as File;
         _loc2_.load();
      }
      
      public static function writeFile(param1:String, param2:*, param3:String = null) : void
      {
         var _loc4_:File = null;
         var _loc6_:FileStream = null;
         var _loc5_:ByteArray = null;
         if(!param3)
         {
            param3 = "write";
         }
         try
         {
            _loc4_ = new File(param1);
            _loc6_ = new FileStream();
            _loc6_.open(_loc4_,param3);
            if(param2 is String)
            {
               _loc6_.writeUTFBytes(param2);
            }
            if(param2 is ByteArray)
            {
               _loc5_ = param2 as ByteArray;
               _loc6_.writeBytes(_loc5_,0,_loc5_.bytesAvailable);
            }
            _loc6_.close();
         }
         catch(e:Error)
         {
            OutputMessage.ERROR("FileUtil","writeFile","",e);
         }
      }
      
      public static function writeAppFloderFile(param1:String, param2:*, param3:String = null) : void
      {
         var _loc4_:String = getAppFloderFileUrl(param1);
         writeFile(_loc4_,param2,param3);
      }
      
      public static function getAppFloderFileUrl(param1:String = null) : String
      {
         var _loc3_:File = File.applicationDirectory;
         var _loc2_:String = _loc3_.nativePath;
         if(!param1)
         {
            return _loc2_ + "/";
         }
         return _loc2_ + "/" + param1;
      }
      
      public static function createFloder(param1:String) : void
      {
         var _loc2_:File = null;
         try
         {
            _loc2_ = new File(param1);
            _loc2_.createDirectory();
         }
         catch(e:Error)
         {
            OutputMessage.ERROR("FileUtil","createFloder","",e);
         }
      }
      
      public static function readTextFile(param1:String) : String
      {
         var _loc3_:String = null;
         var _loc2_:File = null;
         var _loc4_:FileStream = null;
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
            OutputMessage.ERROR("FileUtil","readTextFile","",e);
         }
         return _loc3_;
      }
      
      public static function deleteFlie(param1:String) : void
      {
         var _loc2_:File = new File(param1);
         try
         {
            _loc2_.deleteFile();
         }
         catch(e:Error)
         {
            OutputMessage.ERROR("FileUtil","deleteFlie","",e);
         }
      }
   }
}

