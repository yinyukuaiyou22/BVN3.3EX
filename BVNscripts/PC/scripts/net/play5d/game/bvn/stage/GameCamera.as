package net.play5d.game.bvn.stage
{
   import flash.display.DisplayObject;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   
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
         _stage = param1;
         _rect = new Rectangle(0,0,param2.x,param2.y);
         _noTweenRect = new Rectangle(0,0,param2.x,param2.y);
         _screenSize = new Point(param2.x,param2.y);
         if(param4)
         {
            _fbR = new Rectangle();
         }
         this.stageSize = param3;
         if(!this.stageSize)
         {
            setStageSizeFromDisplay(_stage);
         }
         setStageBounds();
      }
      
      public function getScreenRect(param1:Boolean = false) : Rectangle
      {
         return param1 ? _rect : _noTweenRect;
      }
      
      public function updateNow() : void
      {
         var _loc1_:Number = tweenSpd;
         tweenSpd = 0;
         render();
         tweenSpd = _loc1_;
      }
      
      public function setStageBounds(param1:Rectangle = null) : void
      {
         if(!param1)
         {
            _stageBounds = _stage.getBounds(_stage);
         }
         else
         {
            _stageBounds = param1;
         }
         setZoom(_zoom);
      }
      
      public function setStageSizeFromDisplay(param1:DisplayObject) : void
      {
         stageSize = new Point(param1.width / param1.scaleX + _stageBounds.x,param1.height / param1.scaleY + _stageBounds.y);
      }
      
      public function getZoom(param1:Boolean = false) : Number
      {
         return param1 ? _stageScale : _zoom;
      }
      
      public function setZoom(param1:Number) : void
      {
         _zoom = param1;
         _noTweenRect.width = _screenSize.x / _zoom;
         _noTweenRect.height = _screenSize.y / _zoom;
         _foffsetX = _screenSize.x * 0.5 / _zoom;
         _foffsetY = _screenSize.y * 0.5 / _zoom;
         if(_fbR)
         {
            _fbR.x = _stageBounds.x * _zoom;
            _fbR.y = _stageBounds.y * _zoom;
            _fbR.width = _stageBounds.width - _screenSize.x / _zoom;
            _fbR.height = _stageBounds.height - _screenSize.y / _zoom;
         }
      }
      
      public function focus(param1:Array, param2:Boolean = false) : void
      {
         var _loc3_:int = 0;
         _focus = param1;
         _point = _focus.length > 1 ? new Point() : null;
         if(param2)
         {
            _loc3_ = tweenSpd;
            tweenSpd = 0;
            render();
            tweenSpd = _loc3_;
         }
      }
      
      public function move(param1:Number, param2:Number) : void
      {
         _focus = null;
         _point = new Point(param1,param2);
      }
      
      public function moveCenter() : void
      {
         _focus = null;
         _point = new Point(stageSize.x * 0.5,stageSize.y * 0.5);
      }
      
      public function render() : void
      {
         if(!_focus && !_point)
         {
            return;
         }
         if(_focus.length > 1)
         {
            renderTwo(_focus[0],_focus[_focus.length - 1]);
         }
         if(focusX)
         {
            renderX();
         }
         if(focusY)
         {
            renderY();
         }
         if(_stageScale != _zoom)
         {
            renderZoom();
         }
         applySet();
      }
      
      private function applySet() : void
      {
         _stage.scrollRect = _rect;
         _stage.scaleX = _stage.scaleY = _stageScale;
      }
      
      private function renderTwo(param1:DisplayObject, param2:DisplayObject) : void
      {
         var _loc8_:DisplayObject = null;
         var _loc3_:DisplayObject = null;
         var _loc10_:DisplayObject = null;
         var _loc11_:DisplayObject = null;
         var _loc6_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc5_:* = 0;
         var _loc4_:* = 0;
         if(focusX)
         {
            if(param1.x < param2.x)
            {
               _loc3_ = param1;
               _loc8_ = param2;
            }
            else
            {
               _loc3_ = param2;
               _loc8_ = param1;
            }
            _loc5_ = _loc8_.x - _loc3_.x;
            _point.x = _loc3_.x + _loc5_ * 0.5;
         }
         if(focusY)
         {
            if(param1.y < param2.y)
            {
               _loc11_ = param1;
               _loc10_ = param2;
            }
            else
            {
               _loc11_ = param2;
               _loc10_ = param1;
            }
            _loc4_ = _loc10_.y - _loc11_.y;
            _point.y = _loc11_.y + _loc4_ * 0.5;
         }
         if(autoZoom)
         {
            _loc6_ = _zoom;
            _loc9_ = _zoom;
            if(focusX)
            {
               _loc6_ = _screenSize.x / _loc5_ * 0.8;
            }
            if(focusY)
            {
               _loc9_ = _screenSize.y / _loc4_ * 0.8;
            }
            _loc7_ = Math.min(_loc6_,_loc9_);
            renderAutoZoom(_loc7_);
         }
      }
      
      private function renderAutoZoom(param1:Number) : void
      {
         if(param1 < autoZoomMin)
         {
            param1 = autoZoomMin;
         }
         if(param1 > autoZoomMax)
         {
            param1 = autoZoomMax;
         }
         setZoom(param1);
      }
      
      private function renderX() : void
      {
         var _loc1_:Number = NaN;
         _loc1_ = Number(_point ? _point.x : _focus[0].x);
         _loc1_ -= _foffsetX + offsetX;
         setX(_loc1_);
      }
      
      private function renderY() : void
      {
         var _loc1_:Number = NaN;
         _loc1_ = Number(_point ? _point.y : _focus[0].y);
         _loc1_ -= _foffsetY + offsetY;
         setY(_loc1_);
      }
      
      public function setX(param1:Number) : void
      {
         if(_fbR)
         {
            if(param1 < _fbR.x)
            {
               param1 = _fbR.x;
            }
            if(param1 > _fbR.width)
            {
               param1 = _fbR.width;
            }
         }
         _noTweenRect.x = param1;
         if(tweenSpd > 1)
         {
            _rect.x += (param1 - _rect.x) / tweenSpd;
         }
         else
         {
            _rect.x = param1;
         }
      }
      
      public function setY(param1:Number) : void
      {
         if(_fbR)
         {
            if(param1 < _fbR.y)
            {
               param1 = _fbR.y;
            }
            if(param1 > _fbR.height)
            {
               param1 = _fbR.height;
            }
         }
         _noTweenRect.y = param1;
         if(tweenSpd > 1)
         {
            _rect.y += (param1 - _rect.y) / tweenSpd;
         }
         else
         {
            _rect.y = param1;
         }
      }
      
      private function renderZoom() : void
      {
         if(_zoom <= 0)
         {
            throw new Error("zoom 不能 <= 0 !");
         }
         if(tweenSpd > 1)
         {
            _stageScale += (_zoom - _stageScale) / tweenSpd;
         }
         else
         {
            _stageScale = _zoom;
         }
         _rect.width = _screenSize.x / _stageScale + 1 >> 0;
         _rect.height = _screenSize.y / _stageScale + 1 >> 0;
      }
   }
}

