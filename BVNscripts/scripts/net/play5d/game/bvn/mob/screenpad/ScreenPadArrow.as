package net.play5d.game.bvn.mob.screenpad
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.events.TimerEvent;
   import flash.geom.*;
   import flash.utils.*;
   
   public class ScreenPadArrow extends ScreenPadBtnBase
   {
      
      private var _keyUP:String;
      
      private var _keyDOWN:String;
      
      private var _keyLEFT:String;
      
      private var _keyRIGHT:String;
      
      private var _downV:String;
      
      private var _downH:String;
      
      private var _lightH:Bitmap;
      
      private var _lightV:Bitmap;
      
      private var _center:Rectangle;
      
      private var _upBitmap:BitmapData;
      
      private var _startTouchPoint:Point;
      
      private var _touchMoving:Boolean;
      
      private var _resetPoint:Point;
      
      private var _resetTimer:Timer;
      
      public function ScreenPadArrow()
      {
         super();
      }
      
      override public function initArea() : void
      {
         super.initArea();
         this._center = new Rectangle(_orgBounds.x + _orgBounds.width * 0.3,_orgBounds.y + _orgBounds.height * 0.3,_orgBounds.x + _orgBounds.width * 0.7,_orgBounds.y + _orgBounds.height * 0.7);
         this._resetPoint = new Point(_orgBounds.x,_orgBounds.y);
         this._lightH = new ScreenPadAsset.light();
         this._lightV = new ScreenPadAsset.light();
         this._lightH.scaleX = this._lightH.scaleY = _orgScale;
         this._lightV.scaleX = this._lightV.scaleY = _orgScale;
         this._lightH.alpha = display.alpha;
         this._lightV.alpha = display.alpha;
         this._lightH.visible = false;
         this._lightV.visible = false;
         if(moveAble)
         {
            this._resetTimer = new Timer(1000,1);
            this._resetTimer.addEventListener("timerComplete",this.resetTimeHandler);
         }
      }
      
      private function resetTimeHandler(param1:TimerEvent) : void
      {
         display.x = this._resetPoint.x;
         display.y = this._resetPoint.y;
         this.updateBounds();
      }
      
      override public function updateBounds() : void
      {
         super.updateBounds();
         this._center.x = _orgBounds.x + _orgBounds.width * 0.4;
         this._center.y = _orgBounds.y + _orgBounds.height * 0.3;
         this._center.width = _orgBounds.x + _orgBounds.width * 0.6;
         this._center.height = _orgBounds.y + _orgBounds.height * 0.7;
      }
      
      override public function onAdd() : void
      {
         super.onAdd();
         display.parent.addChild(this._lightH);
         display.parent.addChild(this._lightV);
      }
      
      override public function onRemove() : void
      {
         super.onRemove();
         try
         {
            this._lightH.parent.removeChild(this._lightH);
            this._lightV.parent.removeChild(this._lightV);
         }
         catch(e:Error)
         {
         }
         if(Boolean(this._resetTimer))
         {
            this._resetTimer.stop();
         }
      }
      
      public function setKeyIds(param1:String, param2:String, param3:String, param4:String) : void
      {
         this._keyUP = param1;
         this._keyDOWN = param2;
         this._keyLEFT = param3;
         this._keyRIGHT = param4;
      }
      
      override protected function onTouchDown(param1:Number, param2:Number) : void
      {
         if(param2 < this._center.y)
         {
            this._downV = this._keyUP;
         }
         if(param2 > this._center.height)
         {
            this._downV = this._keyDOWN;
         }
         if(param1 < this._center.x)
         {
            this._downH = this._keyLEFT;
         }
         if(param1 > this._center.width)
         {
            this._downH = this._keyRIGHT;
         }
         this.updateKeyId();
      }
      
      override protected function onTouchUp() : void
      {
         super.touchUP();
         this._downV = null;
         this._downH = null;
         this.updateKeyId();
      }
      
      private function updateKeyId() : void
      {
         if(!this._downV && !this._downH)
         {
            keyId = null;
         }
         keyId = [this._downV,this._downH];
      }
      
      public function getAllKeyIds() : Array
      {
         return [this._keyUP,this._keyDOWN,this._keyLEFT,this._keyRIGHT];
      }
      
      public function clearKey() : void
      {
         this._downV = null;
         this._downH = null;
         this._lightH.visible = false;
         this._lightV.visible = false;
      }
      
      public function getNotDownKeyIds() : Array
      {
         var _loc1_:Array = [this._keyUP,this._keyDOWN,this._keyLEFT,this._keyRIGHT];
         var _loc2_:int = _loc1_.indexOf(this._downV);
         if(_loc2_ != -1)
         {
            _loc1_.splice(_loc2_,1);
         }
         var _loc3_:int = _loc1_.indexOf(this._downH);
         if(_loc3_ != -1)
         {
            _loc1_.splice(_loc3_,1);
         }
         return _loc1_;
      }
      
      override protected function downState() : void
      {
         if(this._downH == this._keyLEFT)
         {
            this._lightH.visible = true;
            this._lightH.x = _orgBounds.x - this._lightH.width / 2;
            this._lightH.y = _orgBounds.y - this._lightH.height / 2 + _orgBounds.width / 2;
         }
         if(this._downH == this._keyRIGHT)
         {
            this._lightH.visible = true;
            this._lightH.x = _orgBounds.x - this._lightH.width / 2 + _orgBounds.width;
            this._lightH.y = _orgBounds.y - this._lightH.height / 2 + _orgBounds.width / 2;
         }
         if(this._downV == this._keyUP)
         {
            this._lightV.visible = true;
            this._lightV.x = _orgBounds.x - this._lightV.width / 2 + _orgBounds.width / 2;
            this._lightV.y = _orgBounds.y - this._lightV.height / 2;
         }
         if(this._downV == this._keyDOWN)
         {
            this._lightV.visible = true;
            this._lightV.x = _orgBounds.x - this._lightV.width / 2 + _orgBounds.width / 2;
            this._lightV.y = _orgBounds.y - this._lightV.height / 2 + _orgBounds.height;
         }
         if(Boolean(this._resetTimer))
         {
            this._resetTimer.stop();
         }
      }
      
      override protected function onTouchMove(param1:Number, param2:Number) : void
      {
         if(!_isDown)
         {
            return;
         }
         this._downV = null;
         this._downH = null;
         if(param2 < this._center.y)
         {
            this._downV = this._keyUP;
         }
         if(param2 > this._center.height)
         {
            this._downV = this._keyDOWN;
         }
         if(param1 < this._center.x)
         {
            this._downH = this._keyLEFT;
         }
         if(param1 > this._center.width)
         {
            this._downH = this._keyRIGHT;
         }
         this.updateKeyId();
         if(moveAble)
         {
            this.updateMovePosition(param1,param2);
         }
      }
      
      private function updateMovePosition(param1:Number, param2:Number) : void
      {
         var _loc3_:Boolean = false;
         if(!this._touchMoving)
         {
            if(!this._startTouchPoint)
            {
               this._startTouchPoint = new Point(param1,param2);
            }
            if(Math.abs(param1 - this._startTouchPoint.x) + Math.abs(param2 - this._startTouchPoint.y) > ScreenPadUtils.cm2pixel(0.3))
            {
               this._touchMoving = true;
            }
            return;
         }
         var _loc4_:Number = _orgBounds.x + _orgBounds.width;
         var _loc5_:Number = _orgBounds.y + _orgBounds.height;
         if(param1 > _loc4_)
         {
            _loc3_ = true;
            display.x = param1 - display.width;
         }
         if(param1 < _orgBounds.x)
         {
            _loc3_ = true;
            display.x = param1;
         }
         if(param2 > _loc5_)
         {
            _loc3_ = true;
            display.y = param2 - display.height;
         }
         if(param2 < _orgBounds.y)
         {
            _loc3_ = true;
            display.y = param2;
         }
         if(_loc3_)
         {
            this.updateBounds();
         }
      }
      
      override protected function moveState() : void
      {
         if(!_isDown)
         {
            return;
         }
         this._lightH.visible = false;
         this._lightV.visible = false;
         this.downState();
      }
      
      override protected function upState() : void
      {
         super.upState();
         this._lightH.visible = false;
         this._lightV.visible = false;
         this._startTouchPoint = null;
         this._touchMoving = false;
         if(Boolean(this._resetTimer))
         {
            this._resetTimer.reset();
            this._resetTimer.start();
         }
      }
   }
}

