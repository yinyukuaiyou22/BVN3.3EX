package net.play5d.game.bvn.utils
{
   import flash.display.*;
   import net.play5d.game.bvn.ctrl.*;
   
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
         var _loc2_:BitmapData = this._cacheObj[param1];
         if(_loc2_ == null)
         {
            return null;
         }
         return new Bitmap(_loc2_);
      }
      
      public function loadQueue(param1:Array, param2:Function, param3:Function = null) : void
      {
         this._successBack = param2;
         this._processBack = param3;
         this._urls = param1.concat();
         this._queueLength = param1.length;
         this.loadNext();
      }
      
      private function load(param1:String, param2:Function = null, param3:Function = null) : void
      {
         var url:String = null;
         var back:Function = null;
         url = param1;
         back = param2;
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
            trace("BitmapAssetLoader.loadFail ::",url);
            if(back != null)
            {
               back();
            }
         };
         AssetManager.I.loadBitmap(url,loadCom,loadFail,process);
      }
      
      private function cacheBitmap(param1:String, param2:DisplayObject) : void
      {
         var _loc4_:BitmapData = null;
         var _loc3_:Bitmap = param2 as Bitmap;
         if(!_loc3_)
         {
            trace("BitmapAssetLoader.cacheBitmap Error");
            return;
         }
         if(Boolean(_loc3_))
         {
            try
            {
               _loc4_ = _loc3_.bitmapData;
            }
            catch(e:Error)
            {
               trace("BitmapAssetLoader.cacheBitmap::",e);
            }
         }
         if(Boolean(_loc4_))
         {
            this._cacheObj[param1] = _loc4_;
         }
         AssetManager.I.disposeAsset(param1);
      }
      
      private function loadNext() : void
      {
         var url:String = null;
         var loadProcess:* = function(param1:Number):void
         {
            var _loc2_:Number = NaN;
            var _loc3_:Number = NaN;
            if(_processBack != null)
            {
               _loc2_ = _queueLength - _urls.length - 1 + param1;
               _loc3_ = _loc2_ / _queueLength;
               _processBack(_loc3_);
            }
         };
         if(this._urls.length < 1)
         {
            if(this._successBack != null)
            {
               this._successBack();
               this._successBack = null;
            }
            return;
         }
         url = this._urls.shift();
         this.load(url,this.loadNext,loadProcess);
      }
   }
}

