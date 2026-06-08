package net.play5d.game.bvn.data
{
   import flash.display.*;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.kyo.utils.*;
   
   public class EffectVO
   {
      
      public var className:String;
      
      public var shine:Object;
      
      public var shake:Object;
      
      public var freeze:int;
      
      public var sound:String;
      
      public var randRotate:Boolean;
      
      public var followDirect:Boolean;
      
      public var slowDown:Object;
      
      public var blendMode:String = "normal";
      
      public var bitmapDataCache:Vector.<BitmapDataCacheVO>;
      
      public var frameLabelCache:Object;
      
      public var specialEffectId:String;
      
      public var targetColorOffset:Array;
      
      public var isSpecial:Boolean = false;
      
      public var isBuff:Boolean = false;
      
      public var isSteelHit:Boolean = false;
      
      public function EffectVO(param1:String, param2:Object = null)
      {
         super();
         this.className = param1;
         if(Boolean(param2))
         {
            KyoUtils.setValueByObject(this,param2);
         }
      }
      
      public function clone() : EffectVO
      {
         var _loc2_:Object = KyoUtils.itemToObject(this);
         delete _loc2_["className"];
         return new EffectVO(this.className,_loc2_);
      }
      
      public function cacheBitmapData() : void
      {
         var _loc1_:Rectangle = null;
         var _loc2_:BitmapDataCacheVO = null;
         var _loc3_:String = null;
         var _loc4_:BitmapData = null;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         this.bitmapDataCache = new Vector.<BitmapDataCacheVO>();
         this.frameLabelCache = {};
         var _loc7_:MovieClip = AssetManager.I.getEffect(this.className);
         _loc7_.gotoAndStop(1);
         while(_loc7_.currentFrame < _loc7_.totalFrames)
         {
            _loc3_ = _loc7_.currentFrameLabel;
            if(Boolean(_loc3_))
            {
               this.frameLabelCache[_loc7_.currentFrame] = _loc3_;
            }
            if(_loc7_.width < 1 || _loc7_.height < 1)
            {
               this.bitmapDataCache.push(null);
               _loc7_.nextFrame();
            }
            else
            {
               _loc4_ = new BitmapData(_loc7_.width,_loc7_.height,true,0);
               _loc1_ = _loc7_.getBounds(_loc7_);
               _loc4_.draw(_loc7_,new Matrix(1,0,0,1,-_loc1_.x,-_loc1_.y));
               _loc5_ = _loc1_.x;
               _loc6_ = _loc1_.y;
               if(Boolean(_loc2_ && _loc2_.offsetX == _loc5_) && Boolean(_loc2_.offsetY == _loc6_) && _loc2_.bitmapData.compare(_loc4_) == 0)
               {
                  this.bitmapDataCache.push(_loc2_);
                  _loc7_.nextFrame();
               }
               else
               {
                  _loc2_ = new BitmapDataCacheVO();
                  _loc2_.bitmapData = _loc4_;
                  _loc2_.offsetX = _loc5_;
                  _loc2_.offsetY = _loc6_;
                  this.bitmapDataCache.push(_loc2_);
                  _loc7_.nextFrame();
               }
            }
         }
         _loc7_ = null;
         _loc1_ = null;
         _loc2_ = null;
      }
   }
}

