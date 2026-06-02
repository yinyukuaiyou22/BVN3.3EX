package net.play5d.game.bvn.utils
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.AssetManager;
   
   public class BitmapAssetLoader
   {
      
      private var _queueLength:int;
      
      private var _urls:Array;
      
      private var _cacheObj:Object = {};
      
      private var _successBack:Function;
      
      private var _processBack:Function;
      
      public function BitmapAssetLoader()
      {
         super();
      }
      
      public function getBitmap(param1:*) : Bitmap
      {
         var _loc2_:BitmapData = _cacheObj[param1];
         if(_loc2_ == null)
         {
            return null;
         }
         return new Bitmap(_loc2_);
      }
      
      public function loadQueue(param1:Array, param2:Function, param3:Function = null) : void
      {
         _successBack = param2;
         _processBack = param3;
         _urls = param1.concat();
         _queueLength = param1.length;
         loadNext();
      }
      
      private function load(param1:String, param2:Function = null, param3:Function = null) : void
      {
         var url:String = param1;
         var back:Function = param2;
         var process:Function = param3;
         var loadCom:* = function(param1:DisplayObject):void
         {
            cacheBitmap(url,param1);
            if(back != null)
            {
               back();
            }
         };
         var loadFail:* = function():void
         {
            if(back != null)
            {
               back();
            }
         };
         AssetManager.I.loadBitmap(url,loadCom,loadFail,process);
      }
      
      private function loadByClass(param1:String, param2:Function = null, param3:Function = null) : void
      {
         var bmd:BitmapData;
         var bp:Bitmap;
         var urlParams:String = param1;
         var back:Function = param2;
         var process:Function = param3;
         var loadCom:* = function(param1:DisplayObject):void
         {
            cacheBitmap(url,param1);
            if(back != null)
            {
               back();
            }
         };
         var loadFail:* = function():void
         {
         };
         var array:Array = urlParams.split("|");
         var url:String = array[0];
         var clsName:String = array[1];
         try
         {
            bmd = AssetManager.I.createObject(clsName,"bitmap.swf") as BitmapData;
            bp = new Bitmap(bmd);
            if(process != null)
            {
               process(1);
            }
            if(loadCom != null)
            {
               loadCom(bp);
            }
         }
         catch(e:Error)
         {
            loadFail();
         }
      }
      
      private function cacheBitmap(param1:String, param2:DisplayObject) : void
      {
         var _loc3_:BitmapData = null;
         var _loc4_:Bitmap = param2 as Bitmap;
         if(_loc4_ == null)
         {
            return;
         }
         if(_loc4_)
         {
            try
            {
               _loc3_ = _loc4_.bitmapData;
            }
            catch(e:Error)
            {
            }
         }
         if(_loc3_)
         {
            _cacheObj[param1] = _loc3_;
         }
         AssetManager.I.disposeAsset(param1);
      }
      
      private function loadNext() : void
      {
         var url:String;
         var loadProcess:* = function(param1:Number):void
         {
            var _loc2_:int = 0;
            if(_processBack != null)
            {
               _loc2_ = _queueLength - _urls.length - 1 + param1;
               _processBack(_loc2_ / _queueLength);
            }
         };
         if(_urls.length < 1)
         {
            if(_successBack != null)
            {
               _successBack();
               _successBack = null;
            }
            return;
         }
         url = _urls.shift();
         if(GameConfig.IS_QUICK_LOAD && url.indexOf("|") != -1)
         {
            loadByClass(url,loadNext,loadProcess);
            return;
         }
         load(url,loadNext,loadProcess);
      }
   }
}

