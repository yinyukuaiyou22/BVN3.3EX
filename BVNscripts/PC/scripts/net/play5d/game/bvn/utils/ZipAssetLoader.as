package net.play5d.game.bvn.utils
{
   import deng.fzip.FZip;
   import deng.fzip.FZipFile;
   import flash.display.Bitmap;
   import flash.display.Loader;
   import flash.display.LoaderInfo;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.media.Sound;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.interfaces.IAssetLoader;
   
   public class ZipAssetLoader implements IAssetLoader
   {
      
      private var _zipFile:FZip;
      
      private var _url:String;
      
      public function ZipAssetLoader(param1:String, param2:Function = null, param3:Function = null, param4:Function = null)
      {
         var zipPath:String = param1;
         var back:Function = param2;
         var fail:Function = param3;
         var process:Function = param4;
         var onProgress:* = function(param1:ProgressEvent):void
         {
            if(process != null)
            {
               process(param1.bytesLoaded / param1.bytesTotal);
            }
         };
         var onComplete:* = function(param1:Event):void
         {
            _zipFile.removeEventListener("complete",onComplete);
            if(back != null)
            {
               back();
            }
         };
         var onIOError:* = function(param1:IOErrorEvent):void
         {
            if(fail != null)
            {
               fail();
            }
         };
         super();
         _url = zipPath;
         _zipFile = new FZip();
         _zipFile.addEventListener("complete",onComplete);
         _zipFile.addEventListener("progress",onProgress);
         _zipFile.addEventListener("ioError",onIOError);
         _zipFile.load(new URLRequest(zipPath));
      }
      
      public static function loadGeneral(param1:String, param2:Array, param3:Function, param4:Function, param5:Function, param6:Function, param7:Number = 0, param8:Number = 1) : void
      {
         var path:String = param1;
         var loadArray:Array = param2;
         var next:Function = param3;
         var com:Function = param4;
         var back:Function = param5;
         var process:Function = param6;
         var startP:Number = param7;
         var scaleP:Number = param8;
         var loadNext:* = function():void
         {
            var loadCom:* = function(param1:*):void
            {
               loadedAmount = loadedAmount + 1;
               com(curUrl,param1);
               zip.dispose(curUrl);
               loadNext();
            };
            var loadFail:* = function():void
            {
               loadNext();
            };
            if(loads.length < 1)
            {
               zip.destory();
               zip = null;
               if(back != null)
               {
                  back();
               }
               return;
            }
            curUrl = loads.shift();
            next(zip,curUrl,loadCom,loadFail,loadProcess);
         };
         var fail:* = function():void
         {
         };
         var loadProcess:* = function(param1:Number):void
         {
            var _loc2_:Number = NaN;
            if(process != null)
            {
               _loc2_ = queueLength - loads.length - 1 + param1;
               process(startP + _loc2_ / queueLength * scaleP);
            }
         };
         var loadedAmount:int = 0;
         var curUrl:String = null;
         var loads:Array = loadArray.concat();
         var queueLength:int = int(loads.length);
         var zip:ZipAssetLoader = new ZipAssetLoader(path,loadNext,fail);
      }
      
      public function destory() : void
      {
         _zipFile.close();
         _zipFile = null;
      }
      
      public function loadXML(param1:String, param2:Function, param3:Function = null) : void
      {
         var _loc6_:String = null;
         var _loc4_:FZipFile = null;
         var _loc5_:ByteArray = null;
         try
         {
            _loc4_ = _zipFile.getFileByName(param1);
            _loc5_ = _loc4_.content;
            _loc5_.position = 0;
            _loc6_ = _loc5_.readUTFBytes(_loc5_.length);
         }
         catch(e:Error)
         {
            if(param3 != null)
            {
               param3();
            }
         }
         finally
         {
            if(_loc5_ != null)
            {
               _loc5_.clear();
            }
            _loc5_ = null;
            _loc4_ = null;
         }
         param2(new XML(_loc6_));
      }
      
      public function loadJSON(param1:String, param2:Function, param3:Function = null) : void
      {
      }
      
      public function loadSwf(param1:String, param2:Function, param3:Function = null, param4:Function = null, param5:ApplicationDomain = null) : void
      {
         var byteArray:ByteArray;
         var loader:Loader;
         var loaderInfo:LoaderInfo;
         var context:LoaderContext;
         var url:String = param1;
         var back:Function = param2;
         var fail:Function = param3;
         var process:Function = param4;
         var applicationDomain:ApplicationDomain = param5;
         var onComplete:* = function(param1:Event):void
         {
            if(loader != null)
            {
               back(loader);
               byteArray.clear();
               byteArray = null;
               file = null;
               loader = null;
               return;
            }
            fail();
         };
         var onIOError:* = function(param1:IOErrorEvent):void
         {
            fail();
         };
         var onProgress:* = function(param1:ProgressEvent):void
         {
            if(process != null)
            {
               process(param1.bytesLoaded / param1.bytesTotal);
            }
         };
         var file:FZipFile = _zipFile.getFileByName(url);
         if(file == null)
         {
            if(fail != null)
            {
               fail();
            }
            return;
         }
         byteArray = file.content;
         loader = new Loader();
         loaderInfo = loader.contentLoaderInfo;
         loaderInfo.addEventListener("complete",onComplete);
         loaderInfo.addEventListener("progress",onProgress);
         loaderInfo.addEventListener("ioError",onIOError);
         context = new LoaderContext();
         context.allowCodeImport = true;
         context.applicationDomain = applicationDomain;
         loader.loadBytes(byteArray,context);
      }
      
      public function loadSound(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         var _loc7_:Sound = null;
         var _loc5_:FZipFile = null;
         var _loc6_:ByteArray = null;
         try
         {
            _loc5_ = _zipFile.getFileByName(param1);
            _loc6_ = _loc5_.content;
            _loc7_ = new Sound();
            _loc7_.loadCompressedDataFromByteArray(_loc6_,_loc6_.bytesAvailable);
         }
         catch(e:Error)
         {
            if(param3 != null)
            {
               param3();
            }
         }
         finally
         {
            if(_loc6_ != null)
            {
               _loc6_.clear();
            }
            _loc6_ = null;
            _loc5_ = null;
         }
         if(param4 != null)
         {
            param4(1);
         }
         param2(_loc7_);
      }
      
      public function loadBitmap(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         var byteArray:ByteArray;
         var loader:Loader;
         var loaderInfo:LoaderInfo;
         var url:String = param1;
         var back:Function = param2;
         var fail:Function = param3;
         var process:Function = param4;
         var onComplete:* = function(param1:Event):void
         {
            var _loc2_:Bitmap = loader.content as Bitmap;
            if(_loc2_ != null)
            {
               back(_loc2_);
               byteArray.clear();
               byteArray = null;
               file = null;
               loader = null;
               return;
            }
            fail();
         };
         var onIOError:* = function(param1:IOErrorEvent):void
         {
            fail();
         };
         var onProgress:* = function(param1:ProgressEvent):void
         {
            if(process != null)
            {
               process(param1.bytesLoaded / param1.bytesTotal);
            }
         };
         var file:FZipFile = _zipFile.getFileByName(url);
         if(file == null)
         {
            if(fail != null)
            {
               fail();
            }
            return;
         }
         byteArray = file.content;
         loader = new Loader();
         loaderInfo = loader.contentLoaderInfo;
         loaderInfo.addEventListener("complete",onComplete);
         loaderInfo.addEventListener("progress",onProgress);
         loaderInfo.addEventListener("ioError",onIOError);
         loader.loadBytes(byteArray);
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

