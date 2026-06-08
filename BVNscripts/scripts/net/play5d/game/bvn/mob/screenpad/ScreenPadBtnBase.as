package net.play5d.game.bvn.mob.screenpad
{
   import flash.display.Bitmap;
   import flash.geom.*;
   
   public class ScreenPadBtnBase
   {
      
      public var moveAble:Boolean = false;
      
      public var display:Bitmap;
      
      public var touchPos:Point = new Point();
      
      public var keyId:Object;
      
      public var areaAdd:Number = 0;
      
      protected var _orgScale:Number = 1;
      
      protected var _orgBounds:Rectangle;
      
      protected var _area:Rectangle;
      
      protected var _isDown:Boolean;
      
      protected var _visible:Boolean = true;
      
      public function ScreenPadBtnBase()
      {
         super();
      }
      
      public function init(param1:Point = null) : void
      {
         if(Boolean(param1))
         {
            this.display.width = param1.x;
            this.display.height = param1.y;
         }
         this._orgScale = this.display.scaleX;
      }
      
      public function setScale(param1:Number) : void
      {
         this._orgScale = param1;
         this.display.scaleX = this.display.scaleY = param1;
      }
      
      public function isDown() : Boolean
      {
         return this._isDown;
      }
      
      public function setVisible(param1:Boolean) : void
      {
         this._visible = param1;
         if(Boolean(this.display))
         {
            this.display.visible = param1;
         }
      }
      
      public function onAdd() : void
      {
      }
      
      public function onRemove() : void
      {
      }
      
      public function initArea() : void
      {
         this._orgBounds = new Rectangle();
         this._orgBounds.x = this.display.x;
         this._orgBounds.y = this.display.y;
         this._orgBounds.width = this.display.width;
         this._orgBounds.height = this.display.height;
         this._area = this._orgBounds.clone();
         if(this.areaAdd != 0)
         {
            this._area.x -= this.areaAdd;
            this._area.y -= this.areaAdd;
            this._area.width += this.areaAdd * 2;
            this._area.height += this.areaAdd * 2;
         }
      }
      
      public function updateBounds() : void
      {
         this._orgBounds.x = this.display.x;
         this._orgBounds.y = this.display.y;
         this._orgBounds.width = this.display.width;
         this._orgBounds.height = this.display.height;
      }
      
      public function checkArea(param1:Number, param2:Number) : Boolean
      {
         if(!this._visible)
         {
            return false;
         }
         return this._area.contains(param1,param2);
      }
      
      final public function touchDown(param1:Number, param2:Number) : void
      {
         if(this._isDown)
         {
            return;
         }
         this._isDown = true;
         this.onTouchDown(param1,param2);
         this.downState();
      }
      
      final public function touchMove(param1:Number, param2:Number) : void
      {
         this.onTouchMove(param1,param2);
         this.moveState();
      }
      
      final public function touchUP() : void
      {
         if(!this._isDown)
         {
            return;
         }
         this._isDown = false;
         this.onTouchUp();
         this.upState();
      }
      
      public function setPosData(param1:Object) : void
      {
         if(Boolean(this.display))
         {
            this.display.x = param1.x;
            this.display.y = param1.y;
            this.display.scaleX = this.display.scaleY = param1.scale;
         }
      }
      
      public function getPosData() : Object
      {
         return {
            "x":this.display.x,
            "y":this.display.y,
            "scale":this.display.scaleX
         };
      }
      
      protected function onTouchDown(param1:Number, param2:Number) : void
      {
      }
      
      protected function onTouchUp() : void
      {
      }
      
      protected function downState() : void
      {
      }
      
      protected function upState() : void
      {
         this.display.scaleX = this.display.scaleY = this._orgScale;
         this.display.x = this._orgBounds.x;
         this.display.y = this._orgBounds.y;
      }
      
      protected function onTouchMove(param1:Number, param2:Number) : void
      {
      }
      
      protected function moveState() : void
      {
      }
   }
}

