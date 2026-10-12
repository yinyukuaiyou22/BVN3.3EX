package net.play5d.game.bvn.utils
{
   import flash.display.*;
   import net.play5d.game.bvn.ctrl.*;
import net.play5d.game.bvn.Debugger;
   
   public class BitmapAssetLoader
   {
      
      /** AS3 批量加载并发度：头像/地图缩略图数量多（约 250 张）但单张很小，6 路并发 */
      private static const BITMAP_BATCH_CONCURRENCY:int = 6;
      
      private var _cacheObj:Object = {};
      
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
         var urls:Array = param1.concat();
         var back:Function = param2;
         var process:Function = param3;
         if(urls.length < 1)
         {
            if(back != null) back();
            return;
         }
         // AS3 批量加载：头像/地图图一次按并发度挂起多路，替代原先的逐个 loadNext 串行链
         var batch:AssetBatchLoader = new AssetBatchLoader();
         batch.load(urls,function(url:String, onDone:Function, onFail:Function, onProgress:Function):void
         {
            load(url,function():void { onDone(); },onProgress);
         },function():void
         {
            if(back != null) back();
         },process,BITMAP_BATCH_CONCURRENCY);
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
            Debugger.log("BitmapAssetLoader.loadFail ::",url);
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
            Debugger.log("BitmapAssetLoader.cacheBitmap Error");
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
               Debugger.log("BitmapAssetLoader.cacheBitmap::",e);
            }
         }
         if(Boolean(_loc4_))
         {
            this._cacheObj[param1] = _loc4_;
         }
         AssetManager.I.disposeAsset(param1);
      }

   }
}

