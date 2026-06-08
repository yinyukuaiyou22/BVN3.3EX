package net.play5d.game.bvn.views.effects
{
   import flash.display.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   
   public class ShineEffectView extends Bitmap
   {
      
      public var onRemove:Function;
      
      public var isActive:Boolean = true;
      
      private var _loseAlpha:Number = 1;
      
      private var _alpha:int;
      
      private var _renderGap:int = 0;
      
      private var _renderFrame:int;
      
      private var _isDestoryed:Boolean;
      
      private var _startTimer:int;
      
      private var _frameTime:int;
      
      private const _skipFrameRate:Number = 1.2;
      
      public function ShineEffectView()
      {
         super(null,"never",false);
      }
      
      public function destory() : void
      {
         this._isDestoryed = true;
         if(this.isActive)
         {
            this.removeSelf();
         }
      }
      
      public function init(param1:uint = 16777215, param2:Number = 0.2) : void
      {
         if(Boolean(this.bitmapData))
         {
            this.bitmapData.dispose();
            this.bitmapData = null;
         }
         this.bitmapData = new BitmapData(GameConfig.GAME_SIZE.x / 10,GameConfig.GAME_SIZE.y / 10,false,param1);
         this.width = GameConfig.GAME_SIZE.x;
         this.height = GameConfig.GAME_SIZE.y;
         this.isActive = true;
         var _loc3_:Number = 8388607;
         if(param1 > _loc3_)
         {
            this.blendMode = "add";
         }
         else
         {
            this.blendMode = "darken";
            param2 *= 0.8;
         }
         this.alpha = param2;
         this._alpha = param2 * 100;
         this._renderFrame = 0;
         this._renderGap = Math.ceil(GameConfig.FPS_GAME / GameConfig.FPS_SHINE_EFFECT) - 1;
         this._startTimer = 0;
         this._loseAlpha = this._renderGap + 1;
         this._frameTime = 1000 / GameConfig.FPS_SHINE_EFFECT;
      }
      
      public function render() : void
      {
         if(this._isDestoryed)
         {
            return;
         }
         if(this._renderGap > 0)
         {
            ++this._renderFrame;
            if(this._renderFrame % this._renderGap != 0)
            {
               return;
            }
         }
         this.skipFrame();
         this._alpha -= this._loseAlpha;
         if(this._alpha <= 5)
         {
            this.removeSelf();
         }
         else
         {
            this.alpha = this._alpha * 0.01;
         }
      }
      
      private function skipFrame() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Number = NaN;
         var _loc3_:int = 0;
         if(this._startTimer != 0)
         {
            _loc1_ = getTimer() - this._startTimer;
            _loc2_ = _loc1_ / this._frameTime;
            if(_loc2_ > 1.2)
            {
               _loc3_ = Math.ceil(this._loseAlpha * _loc2_);
               if(this._loseAlpha < _loc3_)
               {
                  this._loseAlpha = _loc3_;
               }
            }
         }
         this._startTimer = getTimer();
      }
      
      public function removeSelf() : void
      {
         this.isActive = false;
         if(Boolean(bitmapData))
         {
            bitmapData.dispose();
            bitmapData = null;
         }
         if(Boolean(this.parent))
         {
            try
            {
               this.parent.removeChild(this);
            }
            catch(e:Error)
            {
            }
         }
         if(this.onRemove != null)
         {
            this.onRemove(this);
         }
      }
   }
}

