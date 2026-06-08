package net.play5d.game.bvn.views.effects
{
   import flash.display.*;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.BitmapDataCacheVO;
   import net.play5d.game.bvn.data.EffectVO;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.kyo.utils.*;
   
   public class EffectView
   {
      
      public var display:Bitmap;
      
      public var autoRemove:Boolean = true;
      
      public var loopPlay:Boolean = false;
      
      public var holdFrame:int = -1;
      
      public var isActive:Boolean = true;
      
      protected var _target:IGameSprite;
      
      private var _onRemoveFuncs:Array;
      
      private var _isDestoryed:Boolean;
      
      protected var _data:EffectVO;
      
      private var _bitmapDatas:Vector.<BitmapDataCacheVO>;
      
      private var _frameLabels:Object;
      
      private var _orgX:Number = 0;
      
      private var _orgY:Number = 0;
      
      private var _curFrame:int;
      
      private var _rotation:int;
      
      private var _direct:int;
      
      public function EffectView(param1:EffectVO)
      {
         super();
         this._data = param1;
         this.display = new Bitmap();
         this.display.blendMode = param1.blendMode;
         this.display.smoothing = EffectCtrl.EFFECT_SMOOTHING;
         this._bitmapDatas = param1.bitmapDataCache;
         this._frameLabels = param1.frameLabelCache;
      }
      
      public function setTarget(param1:IGameSprite) : void
      {
         this._target = param1;
      }
      
      public function setPos(param1:Number, param2:Number) : void
      {
         this._orgX = param1;
         this._orgY = param2;
      }
      
      public function start(param1:Number = 0, param2:Number = 0, param3:int = 1) : void
      {
         this._orgX = param1;
         this._orgY = param2;
         this._direct = this._rotation != 0 ? 1 : param3;
         this.display.scaleX = this._direct;
         this._curFrame = 0;
         if(this._data.randRotate)
         {
            this.randRotate();
         }
         if(Boolean(this._data.sound))
         {
            SoundCtrl.I.playEffectSound(this._data.sound);
         }
         this.renderDisplay();
         this.isActive = true;
      }
      
      public function destory() : void
      {
         this._isDestoryed = true;
         if(this.isActive)
         {
            this.removeSelf();
         }
         this.display = null;
      }
      
      public function gotoAndPlay(param1:Object) : void
      {
         var _loc2_:* = undefined;
         if(param1 is int)
         {
            this._curFrame = int(param1);
         }
         if(param1 is String)
         {
            for(_loc2_ in this._frameLabels)
            {
               if(this._frameLabels[_loc2_] == param1)
               {
                  this._curFrame = int(_loc2_);
               }
            }
         }
      }
      
      private function randRotate() : void
      {
         this._rotation = Math.random() * 360;
         this.display.rotation = this._rotation;
         this.display.scaleX = 1;
      }
      
      public function render() : void
      {
      }
      
      public function renderAnimate() : void
      {
         if(this._isDestoryed)
         {
            return;
         }
         var _loc1_:Boolean = false;
         if(this.loopPlay)
         {
            if(this._curFrame == this._bitmapDatas.length - 1)
            {
               this._curFrame = 0;
            }
         }
         else if(this.autoRemove)
         {
            if(this._curFrame == this._bitmapDatas.length - 1)
            {
               if(this.holdFrame == -1)
               {
                  this.removeSelf();
                  _loc1_ = true;
               }
               else
               {
                  this._curFrame = 0;
               }
            }
            if(this.holdFrame != -1)
            {
               if(this.holdFrame-- <= 0)
               {
                  this.removeSelf();
                  _loc1_ = true;
               }
            }
         }
         if(!_loc1_)
         {
            this.renderFrameLabel();
            this.renderDisplay();
            ++this._curFrame;
         }
      }
      
      private function renderDisplay() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Point = null;
         var _loc3_:BitmapDataCacheVO = this._bitmapDatas[this._curFrame];
         if(_loc3_ == null)
         {
            this.display.bitmapData = null;
         }
         else
         {
            this.display.bitmapData = _loc3_.bitmapData;
            if(this._rotation != 0)
            {
               _loc1_ = Number(KyoMath.asRadians(this._rotation));
               _loc2_ = KyoMath.getPointByRadians(new Point(_loc3_.offsetX,_loc3_.offsetY),_loc1_);
               this.display.x = this._orgX + _loc2_.x;
               this.display.y = this._orgY + _loc2_.y;
            }
            else
            {
               this.display.x = this._orgX + _loc3_.offsetX * this._direct;
               this.display.y = this._orgY + _loc3_.offsetY;
            }
         }
      }
      
      private function renderFrameLabel() : void
      {
         var _loc1_:String = this._frameLabels[this._curFrame];
         var _loc2_:* = _loc1_;
         if("loop" === _loc2_)
         {
            this.gotoAndPlay(1);
         }
      }
      
      public function remove() : void
      {
         this.removeSelf();
      }
      
      public function addRemoveBack(param1:Function) : void
      {
         if(!this._onRemoveFuncs)
         {
            this._onRemoveFuncs = [];
         }
         if(this._onRemoveFuncs.indexOf(param1) != -1)
         {
            return;
         }
         this._onRemoveFuncs.push(param1);
      }
      
      private function removeSelf() : void
      {
         var _loc1_:* = undefined;
         this.isActive = false;
         for each(_loc1_ in this._onRemoveFuncs)
         {
            _loc1_(this);
         }
         this._onRemoveFuncs = null;
         if(Boolean(this.display) && Boolean(this.display.parent))
         {
            this.display.parent.removeChild(this.display);
         }
      }
   }
}

