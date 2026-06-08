package net.play5d.kyo.loader
{
   import flash.display.*;
   import flash.events.*;
   import flash.net.*;
   
   public class BitmapLoader
   {
      
      public var bitmap:Bitmap;
      
      public var url:String;
      
      public function BitmapLoader()
      {
         super();
      }
      
      public function load(param1:String, param2:Function = null, param3:Function = null) : void
      {
         var loader:Loader = null;
         var loadComplete:Function = null;
         var loadFail:Function = null;
         var back:Function = null;
         var fail:Function = null;
         loader = null;
         loadComplete = null;
         loadFail = null;
         var url:String = param1;
         back = param2;
         fail = param3;
         loadComplete = function(param1:Event):void
         {
            bitmap = loader.content as Bitmap;
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,loadComplete);
            loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,loadFail);
            loader.unload();
            loader = null;
            if(back != null)
            {
               back(bitmap);
            }
         };
         loadFail = function(param1:IOErrorEvent):void
         {
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,loadComplete);
            loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,loadFail);
            loader = null;
            if(fail != null)
            {
               fail();
            }
         };
         this.url = url;
         loader = new Loader();
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadComplete);
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,loadFail);
         loader.load(new URLRequest(url));
      }
   }
}

