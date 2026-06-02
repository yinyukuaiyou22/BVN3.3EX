package net.play5d.game.bvn.views.effects
{
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.geom.ColorTransform;
   import flash.geom.Rectangle;
   import net.play5d.kyo.utils.KyoUtils;
   
   public class ShadowEffectView
   {
      
      public var target:DisplayObject;
      
      public var r:int = 0;
      
      public var g:int = 0;
      
      public var b:int = 0;
      
      public var container:Sprite;
      
      private var _bps:Vector.<Bitmap> = new Vector.<Bitmap>();
      
      private var _alphaLose:Number = 0.1;
      
      private var _alphaStart:Number = 0.8;
      
      private var _addBpGap:int = 1;
      
      private var _addBpFrame:int = 0;
      
      private var _addBpOnce:Boolean;
      
      public var stopShadow:Boolean;
      
      public var onRemove:Function;
      
      public function ShadowEffectView(param1:DisplayObject, param2:int = 0, param3:int = 0, param4:int = 0, param5:Object = null)
      {
         super();
         this.target = param1;
         this.r = param2;
         this.g = param3;
         this.b = param4;
         _addBpFrame = 0;
         setAddonParam(param5);
      }
      
      public function destory() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Bitmap = null;
         target = null;
         while(_loc1_ < _bps.length)
         {
            _loc2_ = _bps[_loc1_];
            _loc2_.bitmapData.dispose();
            try
            {
               container.removeChild(_loc2_);
            }
            catch(error:Error)
            {
            }
            _loc1_++;
         }
         _bps = null;
      }
      
      public function setAddonParam(param1:Object = null) : void
      {
         if(param1 == null)
         {
            _addBpGap = 1;
            _addBpOnce = false;
            return;
         }
         if(param1.gap)
         {
            _addBpGap = param1.gap;
         }
         if(param1.addOnce)
         {
            _addBpOnce = param1.addOnce;
         }
      }
      
      public function render() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Bitmap = null;
         if(stopShadow)
         {
            if(_bps.length <= 0)
            {
               removeSelf();
            }
         }
         else if(_addBpFrame++ > _addBpGap)
         {
            addShadowBp();
            _addBpFrame = 0;
            if(_addBpOnce)
            {
               stopShadow = true;
            }
         }
         while(_loc1_ < _bps.length)
         {
            _loc2_ = _bps[_loc1_];
            _loc2_.alpha -= _alphaLose;
            if(_loc2_.alpha <= 0)
            {
               removeBitmap(_loc2_);
            }
            _loc1_++;
         }
      }
      
      private function addShadowBp() : void
      {
         var _loc3_:ColorTransform = null;
         if(r != 0 || g != 0 || b != 0)
         {
            _loc3_ = new ColorTransform();
            _loc3_.redOffset = r;
            _loc3_.greenOffset = g;
            _loc3_.blueOffset = b;
         }
         var _loc1_:Rectangle = target.getBounds(target);
         var _loc2_:Bitmap = KyoUtils.drawDisplay(target,true,true,0,_loc3_);
         if(_loc2_ == null)
         {
            return;
         }
         _loc2_.alpha = _alphaStart;
         _loc2_.x = target.x + _loc1_.x * target.scaleX;
         _loc2_.y = target.y + _loc1_.y;
         _loc2_.scaleX = target.scaleX;
         _loc2_.scaleY = target.scaleY;
         container.addChildAt(_loc2_,0);
         _bps.push(_loc2_);
      }
      
      private function removeBitmap(param1:Bitmap) : void
      {
         var _loc2_:int = _bps.indexOf(param1);
         if(_loc2_ != -1)
         {
            _bps.splice(_loc2_,1);
         }
         try
         {
            container.removeChild(param1);
         }
         catch(e:Error)
         {
         }
         param1.bitmapData.dispose();
      }
      
      private function removeSelf() : void
      {
         if(onRemove != null)
         {
            onRemove(this);
         }
      }
   }
}

