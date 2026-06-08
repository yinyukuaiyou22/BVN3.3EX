package net.play5d.game.bvn.state
{
   import flash.display.DisplayObject;
   import flash.geom.*;
   
   public class GameCamera
   {
      
      public var tweenSpd:int;
      
      public var stageSize:Point;
      
      public var focusX:Boolean = true;
      
      public var focusY:Boolean;
      
      public var offsetX:Number = 0;
      
      public var offsetY:Number = 0;
      
      public var autoZoom:Boolean = false;
      
      public var autoZoomMin:Number = 1;
      
      public var autoZoomMax:Number = 3;
      
      private var _zoom:Number = 1;
      
      private var _noTweenRect:Rectangle;
      
      private var _stage:DisplayObject;
      
      private var _stageBounds:Rectangle;
      
      private var _rect:Rectangle;
      
      private var _focus:Array;
      
      private var _point:Point;
      
      private var _stageScale:Number = 1;
      
      private var _fbR:Rectangle;
      
      private var _foffsetX:Number = 0;
      
      private var _foffsetY:Number = 0;
      
      private var _screenSize:Point;
      
      public function GameCamera(param1:DisplayObject, param2:Point, param3:Point = null, param4:Boolean = false)
      {
         super();
         this._stage = param1;
         this._rect = new Rectangle(0,0,param2.x,param2.y);
         this._noTweenRect = new Rectangle(0,0,param2.x,param2.y);
         this._screenSize = new Point(param2.x,param2.y);
         if(param4)
         {
            this._fbR = new Rectangle();
         }
         this.stageSize = param3;
         if(!this.stageSize)
         {
            this.setStageSizeFromDisplay(this._stage);
         }
         this.setStageBounds();
      }
      
      public function getScreenRect(param1:Boolean = false) : Rectangle
      {
         return param1 ? this._rect : this._noTweenRect;
      }
      
      public function updateNow() : void
      {
         var _loc1_:Number = this.tweenSpd;
         this.tweenSpd = 0;
         this.render();
         this.tweenSpd = _loc1_;
      }
      
      public function setStageBounds(param1:Rectangle = null) : void
      {
         if(!param1)
         {
            this._stageBounds = this._stage.getBounds(this._stage);
         }
         else
         {
            this._stageBounds = param1;
         }
         this.setZoom(this._zoom);
      }
      
      public function setStageSizeFromDisplay(param1:DisplayObject) : void
      {
         this.stageSize = new Point(param1.width / param1.scaleX + this._stageBounds.x,param1.height / param1.scaleY + this._stageBounds.y);
      }
      
      public function getZoom(param1:Boolean = false) : Number
      {
         return param1 ? Number(this._stageScale) : Number(this._zoom);
      }
      
      public function setZoom(param1:Number) : void
      {
         this._zoom = param1;
         this._noTweenRect.width = this._screenSize.x / this._zoom;
         this._noTweenRect.height = this._screenSize.y / this._zoom;
         this._foffsetX = this._screenSize.x / 2 / this._zoom;
         this._foffsetY = this._screenSize.y / 2 / this._zoom;
         if(Boolean(this._fbR))
         {
            this._fbR.x = this._stageBounds.x * this._zoom;
            this._fbR.y = this._stageBounds.y * this._zoom;
            this._fbR.width = this._stageBounds.width - this._screenSize.x / this._zoom;
            this._fbR.height = this._stageBounds.height - this._screenSize.y / this._zoom;
         }
      }
      
      public function focus(param1:Array, param2:Boolean = false) : void
      {
         var _loc3_:int = 0;
         this._focus = param1;
         this._point = this._focus.length > 1 ? new Point() : null;
         if(param2)
         {
            _loc3_ = this.tweenSpd;
            this.tweenSpd = 0;
            this.render();
            this.tweenSpd = _loc3_;
         }
      }
      
      public function move(param1:Number, param2:Number) : void
      {
         this._focus = null;
         this._point = new Point(param1,param2);
      }
      
      public function moveCenter() : void
      {
         this._focus = null;
         this._point = new Point(this.stageSize.x / 2,this.stageSize.y / 2);
      }
      
      public function render() : void
      {
         if(!this._focus && !this._point)
         {
            return;
         }
         if(this._focus.length > 1)
         {
            this.renderTwo(this._focus[0],this._focus[this._focus.length - 1]);
         }
         if(this.focusX)
         {
            this.renderX();
         }
         if(this.focusY)
         {
            this.renderY();
         }
         if(this._stageScale != this._zoom)
         {
            this.renderZoom();
         }
         this.applySet();
      }
      
      private function applySet() : void
      {
         this._stage.scrollRect = this._rect;
         this._stage.scaleX = this._stage.scaleY = this._stageScale;
      }
      
      private function renderTwo(param1:DisplayObject, param2:DisplayObject) : void
      {
         var _loc3_:* = null;
         var _loc4_:* = null;
         var _loc5_:* = null;
         var _loc6_:* = null;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = 0;
         var _loc11_:Number = 0;
         if(this.focusX)
         {
            if(param1.x < param2.x)
            {
               _loc4_ = param1;
               _loc3_ = param2;
            }
            else
            {
               _loc4_ = param2;
               _loc3_ = param1;
            }
            _loc10_ = _loc3_.x - _loc4_.x;
            this._point.x = _loc4_.x + _loc10_ / 2;
         }
         if(this.focusY)
         {
            if(param1.y < param2.y)
            {
               _loc6_ = param1;
               _loc5_ = param2;
            }
            else
            {
               _loc6_ = param2;
               _loc5_ = param1;
            }
            _loc11_ = _loc5_.y - _loc6_.y;
            this._point.y = _loc6_.y + _loc11_ / 2;
         }
         if(this.autoZoom)
         {
            _loc7_ = Number(this._zoom);
            _loc8_ = Number(this._zoom);
            if(this.focusX)
            {
               _loc7_ = this._screenSize.x / _loc10_ * 0.8;
            }
            if(this.focusY)
            {
               _loc8_ = this._screenSize.y / _loc11_ * 0.8;
            }
            _loc9_ = Math.min(_loc7_,_loc8_);
            this.renderAutoZoom(_loc9_);
         }
      }
      
      private function renderAutoZoom(param1:Number) : void
      {
         if(param1 < this.autoZoomMin)
         {
            param1 = this.autoZoomMin;
         }
         if(param1 > this.autoZoomMax)
         {
            param1 = this.autoZoomMax;
         }
         this.setZoom(param1);
      }
      
      private function renderX() : void
      {
         var _loc1_:Number = NaN;
         _loc1_ = Number(this._point ? this._point.x : this._focus[0].x);
         _loc1_ -= this._foffsetX + this.offsetX;
         this.setX(_loc1_);
      }
      
      private function renderY() : void
      {
         var _loc1_:Number = NaN;
         _loc1_ = Number(this._point ? this._point.y : this._focus[0].y);
         _loc1_ -= this._foffsetY + this.offsetY;
         this.setY(_loc1_);
      }
      
      public function setX(param1:Number) : void
      {
         if(Boolean(this._fbR))
         {
            if(param1 < this._fbR.x)
            {
               param1 = Number(this._fbR.x);
            }
            if(param1 > this._fbR.width)
            {
               param1 = Number(this._fbR.width);
            }
         }
         this._noTweenRect.x = param1;
         if(this.tweenSpd > 1)
         {
            this._rect.x += (param1 - this._rect.x) / this.tweenSpd;
         }
         else
         {
            this._rect.x = param1;
         }
      }
      
      public function setY(param1:Number) : void
      {
         if(Boolean(this._fbR))
         {
            if(param1 < this._fbR.y)
            {
               param1 = Number(this._fbR.y);
            }
            if(param1 > this._fbR.height)
            {
               param1 = Number(this._fbR.height);
            }
         }
         this._noTweenRect.y = param1;
         if(this.tweenSpd > 1)
         {
            this._rect.y += (param1 - this._rect.y) / this.tweenSpd;
         }
         else
         {
            this._rect.y = param1;
         }
      }
      
      private function renderZoom() : void
      {
         if(this._zoom <= 0)
         {
            throw new Error("zoom 不能 <= 0 !");
         }
         if(this.tweenSpd > 1)
         {
            this._stageScale += (this._zoom - this._stageScale) / this.tweenSpd;
         }
         else
         {
            this._stageScale = this._zoom;
         }
         this._rect.width = this._screenSize.x / this._stageScale + 1 >> 0;
         this._rect.height = this._screenSize.y / this._stageScale + 1 >> 0;
      }
   }
}

