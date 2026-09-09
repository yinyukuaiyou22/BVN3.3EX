package net.play5d.game.bvn.ctrl
{
   import flash.display.*;
   import flash.events.*;
   import flash.media.Sound;
   import flash.net.*;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.Debugger;
   import net.play5d.game.bvn.interfaces.IAssetLoader;
   import net.play5d.game.bvn.mob.utils.ANEFileReader;
   import net.play5d.kyo.loader.KyoURLoader;

   public class AssetLoader implements IAssetLoader
   {
      public function AssetLoader() { super(); }

      public function loadXML(url:String, back:Function, fail:Function = null) : void
      {
         var path:String = findExternalPath(url);
         if(path)
         {
            var bytes:ByteArray = ANEFileReader.I.readBytes(path);
            if(bytes && bytes.length > 0)
            {
               bytes.position = 0;
               try { Debugger.log("[EXT-READ] XML hit:", url, path, bytes.length); back(new XML(bytes.readUTFBytes(bytes.length))); return; }
               catch(e:Error) { Debugger.log("AssetLoader external XML parse failed:", url, e.message); }
            }
         }
         KyoURLoader.load(url,function(text:String):void { if(back != null) back(new XML(text)); },fail);
      }

      public function loadSwf(url:String, back:Function, fail:Function = null, process:Function = null) : void
      {
         loadDisplay(url,back,fail,process,true);
      }

      public function loadBitmap(url:String, back:Function, fail:Function = null, process:Function = null) : void
      {
         loadDisplay(url,function(loader:Loader):void { if(back != null) back(loader.content); },fail,process,false);
      }

      private function loadDisplay(url:String, back:Function, fail:Function, process:Function, allowCode:Boolean) : void
      {
         var path:String = findExternalPath(url);
         if(path)
         {
            var bytes:ByteArray = ANEFileReader.I.readBytes(path);
            if(bytes && bytes.length > 0)
            {
               bytes.position = 0;
               var externalLoader:Loader = new Loader();
               attachLoader(externalLoader,back,fail,process);
               try
               {
                  var context:LoaderContext = new LoaderContext(false);
                  if(allowCode && "allowCodeImport" in context) context["allowCodeImport"] = true;
                  if(allowCode && "allowLoadBytesCodeExecution" in context) context["allowLoadBytesCodeExecution"] = true;
                  externalLoader.loadBytes(bytes,context);
                  return;
               }
               catch(e:Error) { Debugger.log("AssetLoader external display load failed:", url, e.message); }
            }
         }
         var loader:Loader = new Loader();
         attachLoader(loader,back,fail,process);
         loader.load(new URLRequest(url));
      }

      private function attachLoader(loader:Loader, back:Function, fail:Function, process:Function) : void
      {
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void { if(back != null) back(loader); });
         loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void { if(fail != null) fail(); });
         loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,function(e:ProgressEvent):void { if(process != null && e.bytesTotal > 0) process(e.bytesLoaded / e.bytesTotal); });
      }

      public function loadSound(url:String, back:Function, fail:Function = null, process:Function = null) : void
      {
         var path:String = findExternalPath(url);
         if(path)
         {
            var bytes:ByteArray = ANEFileReader.I.readBytes(path);
            if(bytes && bytes.length > 0)
            {
               bytes.position = 0;
               var externalSound:Sound = new Sound();
               externalSound.addEventListener(Event.COMPLETE,function(e:Event):void { if(back != null) back(externalSound); });
               externalSound.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void { if(fail != null) fail(); });
               try { externalSound.loadCompressedDataFromByteArray(bytes,bytes.length); return; }
               catch(e:Error) { Debugger.log("AssetLoader external sound load failed:", url, e.message); }
            }
         }
         var sound:Sound = new Sound(new URLRequest(url));
         sound.addEventListener(Event.COMPLETE,function(e:Event):void { if(back != null) back(sound); });
         sound.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void { if(fail != null) fail(); });
         sound.addEventListener(ProgressEvent.PROGRESS,function(e:ProgressEvent):void { if(process != null && e.bytesTotal > 0) process(e.bytesLoaded / e.bytesTotal); });
      }

      public function dispose(url:String) : void { }
      public function needPreLoad() : Boolean { return false; }
      public function loadPreLoad(back:Function, process:Function = null, fail:Function = null) : void { }

      private function findExternalPath(url:String) : String
      {
         if(!ANEFileReader.ANE_ENABLED || !url || url.indexOf("://") >= 0) return null;
         var clean:String = url.replace(/\\/g,"/");
         if(clean.charAt(0) == "/") return ANEFileReader.I.exists(clean) ? clean : null;
         if(clean.indexOf("assets/") == 0) clean = clean.substr(7);
         var path:String = ANEFileReader.resolveExternalPath(clean);
         return ANEFileReader.I.exists(path) ? path : null;
      }
   }
}
