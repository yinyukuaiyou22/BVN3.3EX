package net.play5d.game.bvn.views.effects
{
   import flash.display.*;
   import flash.filters.BitmapFilter;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.kyo.utils.*;
   
   public class BitmapFilterView implements IGameSprite
   {
      
      private var _bitmap:Bitmap;
      
      public var target:BaseGameSprite;
      
      private var _filter:BitmapFilter;
      
      private var _filterOffset:Point;
      
      private var _isDestoryed:Boolean;
      
      private var _bitmapFrame:int;
      
      private var _targetDisplay:DisplayObject;
      
      private var _targetBounds:Rectangle;
      
      private var _targetFighter:FighterMain;
      
      public function BitmapFilterView(param1:BaseGameSprite, param2:BitmapFilter, param3:Point = null)
      {
         super();
         this._bitmap = new Bitmap(null,"auto",false);
         this.target = param1;
         if(param1 is FighterMain)
         {
            this._targetFighter = param1 as FighterMain;
         }
         this._targetDisplay = param1.getDisplay();
         this._filter = param2;
         this._filterOffset = param3;
      }
      
      public function setVolume(param1:Number) : void
      {
      }
      
      public function update(param1:BitmapFilter, param2:Point = null) : void
      {
         this._filter = param1;
         this._filterOffset = param2;
      }
      
      public function renderAnimate() : void
      {
      }
      
      public function render() : void
      {
         if(!this.target || !this._targetDisplay)
         {
            return;
         }
         if(this._isDestoryed)
         {
            return;
         }
         this.renderBitmapData();
         this._bitmap.scaleX = this._targetDisplay.scaleX;
         this._bitmap.scaleY = this._targetDisplay.scaleY;
         if(this.target.direct > 0)
         {
            this._bitmap.x = this._targetDisplay.x - this._filterOffset.x + this._targetBounds.x;
         }
         else
         {
            this._bitmap.x = this._targetDisplay.x + this._filterOffset.x - this._targetBounds.x;
         }
         this._bitmap.y = this._targetDisplay.y - this._filterOffset.y + this._targetBounds.y;
      }
      
      private function renderBitmapData() : void
      {
         var _loc1_:int = 0;
         if(Boolean(this._targetFighter))
         {
            _loc1_ = int(this._targetFighter.getMC().getCurrentFrameCount());
            if(_loc1_ == this._bitmapFrame)
            {
               return;
            }
            this._bitmapFrame = _loc1_;
         }
         if(Boolean(this._bitmap.bitmapData))
         {
            this._bitmap.bitmapData.dispose();
            this._bitmap.bitmapData = null;
         }
         this._bitmap.bitmapData = KyoUtils.drawBitmapFilter(this._targetDisplay,this._filter,true,this._filterOffset);
         this._targetBounds = this._targetDisplay.getBounds(this._targetDisplay);
      }
      
      public function isDestoryed() : Boolean
      {
         return this._isDestoryed;
      }
      
      public function getDisplay() : DisplayObject
      {
         return this._bitmap;
      }
      
      public function get direct() : int
      {
         return this.target.direct;
      }
      
      public function set direct(param1:int) : void
      {
      }
      
      public function get x() : Number
      {
         return this._bitmap.x;
      }
      
      public function set x(param1:Number) : void
      {
         this._bitmap.x = param1;
      }
      
      public function get y() : Number
      {
         return this._bitmap.y;
      }
      
      public function set y(param1:Number) : void
      {
         this._bitmap.y = param1;
      }
      
      public function get team() : TeamVO
      {
         return null;
      }
      
      public function set team(param1:TeamVO) : void
      {
      }
      
      public function hit(param1:HitVO, param2:IGameSprite) : void
      {
      }
      
      public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
      }
      
      public function getArea() : Rectangle
      {
         return null;
      }
      
      public function getBodyArea() : Rectangle
      {
         return null;
      }
      
      public function getCurrentHits() : Array
      {
         return null;
      }
      
      public function allowCrossMapXY() : Boolean
      {
         return true;
      }
      
      public function allowCrossMapBottom() : Boolean
      {
         return true;
      }
      
      public function getIsTouchSide() : Boolean
      {
         return false;
      }
      
      public function setIsTouchSide(param1:Boolean) : void
      {
      }
      
      public function setSpeedRate(param1:Number) : void
      {
      }
      
      public function destory(param1:Boolean = true) : void
      {
         if(param1)
         {
            if(Boolean(this._bitmap.bitmapData))
            {
               this._bitmap.bitmapData.dispose();
               this._bitmap.bitmapData = null;
            }
            this._isDestoryed = true;
            this.target = null;
            this._filter = null;
            this._filterOffset = null;
            this._targetFighter = null;
            this._targetBounds = null;
            this._targetDisplay = null;
         }
      }
   }
}

