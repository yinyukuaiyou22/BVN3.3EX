package net.play5d.kyo.loader
{
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.net.URLVariables;
   import flash.utils.ByteArray;
   
   public class KyoURLoader
   {
      
      public static var showDebug:Boolean = true;
      
      public static var errorStr:String;
      
      public static const TYPE_UNICODE:String = "Unicode";
      
      public static const TYPE_UNICODE_BIG_ENDIAN:String = "Unicode big endian";
      
      public static const TYPE_UTF8:String = "UTF-8";
      
      public static const TYPE_ANSI:String = "ANSI";
      
      public function KyoURLoader()
      {
         super();
      }
      
      public static function load(param1:String, param2:Function, param3:Function = null, param4:Object = null) : void
      {
         var i:String;
         var url:String = param1;
         var back:Function = param2;
         var failBack:Function = param3;
         var param:Object = param4;
         var onComplete:* = function(param1:Event):void
         {
            if(back != null)
            {
               back(loader.data);
            }
            loader = null;
         };
         var onError:* = function(param1:IOErrorEvent):void
         {
            errorStr = param1.toString();
            if(failBack != null)
            {
               failBack();
            }
            loader = null;
            if(showDebug)
            {
               trace(param1);
            }
         };
         var onError2:* = function(param1:SecurityErrorEvent):void
         {
            errorStr = param1.toString();
            if(failBack != null)
            {
               failBack();
            }
            loader = null;
         };
         errorStr = null;
         var loader:URLLoader = new URLLoader();
         if(param)
         {
            for(i in param)
            {
               loader[i] = param[i];
            }
         }
         loader.addEventListener("complete",onComplete);
         loader.addEventListener("ioError",onError);
         loader.addEventListener("securityError",onError2);
         loader.load(new URLRequest(url));
      }
      
      public static function post(param1:String, param2:Object, param3:Function = null, param4:Function = null) : void
      {
         var uq:URLRequest;
         var uv:URLVariables;
         var i:String;
         var url:String = param1;
         var data:Object = param2;
         var back:Function = param3;
         var failBack:Function = param4;
         var onComplete:* = function(param1:Event):void
         {
            if(back != null)
            {
               back(loader.data);
            }
            loader = null;
         };
         var onError:* = function(param1:IOErrorEvent):void
         {
            if(failBack != null)
            {
               failBack();
            }
            loader = null;
            if(showDebug)
            {
               trace(param1);
            }
         };
         var loader:URLLoader = new URLLoader();
         loader.addEventListener("complete",onComplete);
         loader.addEventListener("ioError",onError);
         uq = new URLRequest(url);
         uq.method = "POST";
         if(data is URLVariables)
         {
            uq.data = data;
         }
         else
         {
            uv = new URLVariables();
            for(i in data)
            {
               uv[i] = data[i];
            }
            uq.data = uv;
         }
         loader.load(uq);
      }
      
      public static function getFileType(param1:ByteArray) : String
      {
         var _loc2_:int = int(param1.readUnsignedByte());
         var _loc3_:int = int(param1.readUnsignedByte());
         param1.position = 0;
         if(_loc2_ == 255 && _loc3_ == 254)
         {
            return "Unicode";
         }
         if(_loc2_ == 254 && _loc3_ == 255)
         {
            return "Unicode big endian";
         }
         if(_loc2_ == 239 && _loc3_ == 187)
         {
            return "UTF-8";
         }
         return "ANSI";
      }
   }
}

