package net.play5d.game.bvn.ctrl
{
   import flash.display.*;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.media.*;
   import flash.net.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.kyo.loader.*;
   
   public class AssetLoader implements IAssetLoader
   {
      
      public function AssetLoader()
      {
         super();
      }
      
      public function loadXML(param1:String, param2:Function, param3:Function = null) : void
      {
         var back:Function = null;
         var url:String = param1;
         back = param2;
         var fail:Function = param3;
         KyoURLoader.load(url,function(param1:String):void
         {
            if(back != null)
            {
               back(new XML(param1));
            }
         },fail);
      }
      
      public function loadSwf(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         var back:Function = null;
         var fail:Function = null;
         var process:Function = null;
         var loadComplete:* = undefined;
         var loadError:* = undefined;
         var loadProcess:* = undefined;
         var loader:Loader = null;
         var url:String = param1;
         back = param2;
         fail = param3;
         process = param4;
         loadComplete = function(param1:Event):void
         {
            loader.contentLoaderInfo.removeEventListener("complete",loadComplete);
            loader.contentLoaderInfo.removeEventListener("ioError",loadError);
            loader.contentLoaderInfo.removeEventListener("progress",loadProcess);
            if(back != null)
            {
               back(loader);
            }
         };
         loadError = function(param1:Event):void
         {
            loader.contentLoaderInfo.removeEventListener("complete",loadComplete);
            loader.contentLoaderInfo.removeEventListener("ioError",loadError);
            loader.contentLoaderInfo.removeEventListener("progress",loadProcess);
            if(fail != null)
            {
               fail();
            }
         };
         loadProcess = function(param1:ProgressEvent):void
         {
            if(process != null)
            {
               process(param1.bytesLoaded / param1.bytesTotal);
            }
         };
         loader = new Loader();
         loader.contentLoaderInfo.addEventListener("complete",loadComplete);
         loader.contentLoaderInfo.addEventListener("ioError",loadError);
         loader.contentLoaderInfo.addEventListener("progress",loadProcess);
         loader.load(new URLRequest(url));
      }
      
      public function loadBitmap(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         var back:Function = null;
         var fail:Function = null;
         var process:Function = null;
         var loadComplete:* = undefined;
         var loadError:* = undefined;
         var loadProcess:* = undefined;
         var loader:Loader = null;
         var url:String = param1;
         back = param2;
         fail = param3;
         process = param4;
         loadComplete = function(param1:Event):void
         {
            loader.contentLoaderInfo.removeEventListener("complete",loadComplete);
            loader.contentLoaderInfo.removeEventListener("ioError",loadError);
            loader.contentLoaderInfo.removeEventListener("progress",loadProcess);
            if(back != null)
            {
               back(loader.content);
            }
         };
         loadError = function(param1:Event):void
         {
            loader.contentLoaderInfo.removeEventListener("complete",loadComplete);
            loader.contentLoaderInfo.removeEventListener("ioError",loadError);
            loader.contentLoaderInfo.removeEventListener("progress",loadProcess);
            if(fail != null)
            {
               fail();
            }
         };
         loadProcess = function(param1:ProgressEvent):void
         {
            if(process != null)
            {
               process(param1.bytesLoaded / param1.bytesTotal);
            }
         };
         loader = new Loader();
         loader.contentLoaderInfo.addEventListener("complete",loadComplete);
         loader.contentLoaderInfo.addEventListener("ioError",loadError);
         loader.contentLoaderInfo.addEventListener("progress",loadProcess);
         loader.load(new URLRequest(url));
      }
      
      public function loadSound(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         var back:Function = null;
         var fail:Function = null;
         var process:Function = null;
         var loadCom:* = undefined;
         var loadErr:* = undefined;
         var loadProcess:* = undefined;
         var sound:Sound = null;
         var url:String = param1;
         back = param2;
         fail = param3;
         process = param4;
         loadCom = function(param1:Event):void
         {
            sound.removeEventListener("complete",loadCom);
            sound.removeEventListener("ioError",loadErr);
            sound.removeEventListener("progress",loadProcess);
            if(back != null)
            {
               back(sound);
            }
         };
         loadErr = function(param1:IOErrorEvent):void
         {
            sound.removeEventListener("complete",loadCom);
            sound.removeEventListener("ioError",loadErr);
            sound.removeEventListener("progress",loadProcess);
            if(fail != null)
            {
               fail();
            }
         };
         loadProcess = function(param1:ProgressEvent):void
         {
            if(process != null)
            {
               process(param1.bytesLoaded / param1.bytesTotal);
            }
         };
         sound = new Sound(new URLRequest(url));
         sound.addEventListener("complete",loadCom);
         sound.addEventListener("ioError",loadErr);
         sound.addEventListener("progress",loadProcess);
      }
      
      public function dispose(param1:String) : void
      {
      }
      
      public function needPreLoad() : Boolean
      {
         return false;
      }
      
      public function loadPreLoad(param1:Function, param2:Function = null, param3:Function = null) : void
      {
      }
   }
}

