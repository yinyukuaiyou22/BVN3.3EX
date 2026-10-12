package net.play5d.game.bvn.ctrl
{
   import flash.display.*;
   import flash.events.*;
   import flash.media.Sound;
   import flash.net.*;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
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
            ANEFileReader.I.readBytesAsync(path,function(bytes:ByteArray):void
            {
               if(bytes && bytes.length > 0)
               {
                  bytes.position = 0;
                  try
                  {
                     Debugger.log("[EXT-READ] XML hit:", url, path, bytes.length);
                     if(back != null) back(new XML(bytes.readUTFBytes(bytes.length)));
                     return;
                  }
                  catch(e:Error)
                  {
                     Debugger.log("AssetLoader external XML parse failed:", url, e.message);
                  }
               }
               loadInternalXML(url,back,fail);
            },function():void
            {
               loadInternalXML(url,back,fail);
            });
            return;
         }
         loadInternalXML(url,back,fail);
      }

      /** 内置（APK）XML 加载：URLLoader 流水线；外置读取失败时回退到这里 */
      private function loadInternalXML(url:String, back:Function, fail:Function) : void
      {
         KyoURLoader.load(url,function(text:String):void
         {
            if(back != null) back(new XML(text));
         },fail);
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
            ANEFileReader.I.readBytesAsync(path,function(bytes:ByteArray):void
            {
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
                  catch(e:Error)
                  {
                     Debugger.log("AssetLoader external display load failed:", url, e.message);
                  }
               }
               loadInternalDisplay(url,back,fail,process);
            },function():void
            {
               loadInternalDisplay(url,back,fail,process);
            });
            return;
         }
         loadInternalDisplay(url,back,fail,process);
      }

      /** 内置（APK）显示对象加载：URLRequest 流水线；外置读取失败时回退到这里 */
      private function loadInternalDisplay(url:String, back:Function, fail:Function, process:Function) : void
      {
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
            ANEFileReader.I.readBytesAsync(path,function(bytes:ByteArray):void
            {
               if(bytes && bytes.length > 0)
               {
                  bytes.position = 0;
                  var externalSound:Sound = new Sound();
                  var notified:Boolean = false;
                  // loadCompressedDataFromByteArray 之后 Sound 已可用，COMPLETE 不一定派发；
                  // 用 once 守护保证 back 恰好回调一次（批量并发计数依赖这一点）。
                  var notify:Function = function() : void
                  {
                     if(notified) return;
                     notified = true;
                     if(back != null) back(externalSound);
                  };
                  externalSound.addEventListener(Event.COMPLETE,function(e:Event):void { notify(); });
                  externalSound.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void { if(fail != null) fail(); });
                  try
                  {
                     externalSound.loadCompressedDataFromByteArray(bytes,bytes.length);
                  }
                  catch(e:Error)
                  {
                     Debugger.log("AssetLoader external sound load failed:", url, e.message);
                     loadInternalSound(url,back,fail,process);
                     return;
                  }
                  notify();
                  return;
               }
               loadInternalSound(url,back,fail,process);
            },function():void
            {
               loadInternalSound(url,back,fail,process);
            });
            return;
         }
         loadInternalSound(url,back,fail,process);
      }

      /** 内置（APK）声音加载：URLLoader 取字节 + loadCompressedDataFromByteArray。
       *  原 `new Sound(new URLRequest(url))` 流式构造在 Android 上会间歇性抛 Error #1069，
       *  或「既不 COMPLETE 也不 IO_ERROR」永久不结算 —— LoadingState.onLoadItemsDone 会等
       *  BGM 完成才进场景（地图/角色都带 bgm 时必现卡加载界面）。改走字节加载，与外置路径
       *  同一条已实测可用的通道，并加看门狗兜底，保证 back/fail 必回调一次。 */
      private function loadInternalSound(url:String, back:Function, fail:Function, process:Function) : void
      {
         var settled:Boolean = false;
         var watchdog:Timer = new Timer(10000,1);
         var finish:Function = function(sound:Sound) : void
         {
            if(settled) return;
            settled = true;
            if(watchdog != null) { try { watchdog.stop(); } catch(e:Error) { } watchdog = null; }
            if(back != null) back(sound);
         };
         var failed:Function = function() : void
         {
            Debugger.log("[AssetLoader] failed() url=" + url + " failNull=" + (fail == null) + " settled=" + settled);
            if(settled) return;
            settled = true;
            if(watchdog != null) { try { watchdog.stop(); } catch(e:Error) { } watchdog = null; }
            if(fail != null) fail();
         };
         watchdog.addEventListener(TimerEvent.TIMER,function(e:TimerEvent):void { Debugger.log("AssetLoader internal sound TIMEOUT:", url); failed(); });
         var ul:URLLoader = new URLLoader();
         ul.dataFormat = URLLoaderDataFormat.BINARY;
         ul.addEventListener(Event.COMPLETE,function(e:Event):void
         {
            var rawData:ByteArray = ul.data as ByteArray;
            Debugger.log("[AssetLoader] internal sound COMPLETE:", url, "dataNull=" + (rawData == null), "bytes=" + (rawData != null ? rawData.length : -1));
            var s:Sound = new Sound();
            try
            {
               s.loadCompressedDataFromByteArray(ul.data,ul.data.length);
            }
            catch(err:Error)
            {
               Debugger.log("AssetLoader internal sound DECODE FAIL:", url, err);
               failed();
               return;
            }
            // 批次6.16：finish() 会调用 back() 回调（SoundCtrl.loadFightBGM 的 onDone）。
            // 回调里的异常过去会被上面 catch 误报为 "decode failed"；且 finish 已把 settled
            // 置 true，导致 failed() 静默 return、batch 永不结算 → 卡加载。拆分后单独 try，
            // 能区分"真解码失败"与"回调失败"。
            try
            {
               finish(s);
            }
            catch(cbErr:Error)
            {
               Debugger.log("AssetLoader internal sound CALLBACK FAIL:", url, "settled=" + settled, cbErr);
               failed();
            }
         });
         ul.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void { failed(); });
         ul.addEventListener(ProgressEvent.PROGRESS,function(e:ProgressEvent):void
         {
            if(process != null && e.bytesTotal > 0) process(e.bytesLoaded / e.bytesTotal);
         });
         try
         {
            watchdog.start();
            ul.load(new URLRequest(url));
         }
         catch(e:Error)
         {
            Debugger.log("AssetLoader internal sound load failed:", url, e.message);
            failed();
         }
      }

      public function dispose(url:String) : void { }
      public function needPreLoad() : Boolean { return false; }
      public function loadPreLoad(back:Function, process:Function = null, fail:Function = null) : void { }

      /** 启动关键路径资源白名单：永远从 APK 内嵌读取，不查外置。
       *  原因 A（阻塞主线程）：外置读取走 ANEFileReader.readBytes 的同步 FileStream，
       *  启动阶段读 5MB 的 effect.swf / 字体位图会阻塞主线程（满量外置资源下实测启动阻塞数分钟）。
       *  原因 B（异步通道可能不结算，2026-10-11 新增）：外置读取的另一条路径
       *  ANEFileReader.readBytesAsync 依赖 FileStream.openAsync 的 COMPLETE/IO_ERROR/CLOSE，
       *  实测存在「三者都不派发」的情况 → back/fail 都不回调 → AssetBatchLoader 并发计数
       *  永不归零 → 启动永久卡在加载界面。以下资源 APK 内已有，走内置即同时避开 A 与 B。
       *  详见验收报告 §八。 */
      private static const EMBEDDED_ONLY_EXACT:Array = ["effect.swf","config/preload.xml"];

      /** true = 该（已去掉 assets/ 前缀的）资源路径只允许内嵌 */
      private static function isEmbeddedOnlyPath(clean:String) : Boolean
      {
         if(EMBEDDED_ONLY_EXACT.indexOf(clean) >= 0)
         {
            return true;
         }
         // 字体目录整体内嵌：font1.xml / font1.png（以及 font1.xml 里 page 引用的位图）
         if(clean.indexOf("font/") == 0)
         {
            return true;
         }
         // 2026-10-11：音效目录整体内嵌。sounds/ 已打进 APK（见 debug_mob.bat 打包白名单），
         // 外置那份只是冗余副本；但 AssetLoader 是「外置优先」，冗余副本会盖住内置版本，
         // 把启动预载的 3 个 step 音效推到上面原因 B 那条可能不结算的异步通道上。
         // 内置读取最快、且不依赖外置目录是否存在。
         return clean.indexOf("sounds/") == 0;
      }

      private function findExternalPath(url:String) : String
      {
         if(!ANEFileReader.EXTERNAL_ENABLED || !url || url.indexOf("://") >= 0) return null;
         var clean:String = url.replace(/\\/g,"/");
         var queryIndex:int = clean.indexOf("?");
         if(queryIndex >= 0) clean = clean.substr(0,queryIndex);
         if(clean.charAt(0) == "/") return ANEFileReader.I.exists(clean) ? clean : null;
         if(clean.indexOf("assets/") == 0) clean = clean.substr(7);
         // 启动关键路径资源固定走 APK 内嵌（见 isEmbeddedOnlyPath 注释）
         if(isEmbeddedOnlyPath(clean))
         {
            Debugger.logFold("EXT-RESOLVE.embedded", url);
            return null;
         }
         var path:String = ANEFileReader.resolveExternalPath(clean);
         var hit:Boolean = ANEFileReader.I.exists(path);
         // 每个资源都要解析一次，正常路径改为折叠计数（命中/回退分别计数，flushFold 时各出一行）
         Debugger.logFold(hit ? "EXT-RESOLVE.external" : "EXT-RESOLVE.apk-fallback", url);
         return hit ? path : null;
      }
   }
}
