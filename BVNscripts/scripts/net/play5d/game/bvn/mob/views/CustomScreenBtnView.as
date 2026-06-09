package net.play5d.game.bvn.mob.views
{
   import com.greensock.*;
   import flash.display.*;
   import flash.events.TouchEvent;
   import flash.geom.*;
   import flash.utils.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.mob.*;
   import net.play5d.game.bvn.mob.events.ScreenPadEvent;
   import net.play5d.game.bvn.mob.screenpad.*;
   import net.play5d.game.bvn.mob.utils.*;
import net.play5d.game.bvn.Debugger;
   
   public class CustomScreenBtnView
   {
      
      private var _ui:Sprite;
      
      private var _width:int;
      
      private var _height:int;
      
      private var _scale:Number = 1;
      
      private var _btns:Array;
      
      private var _btnPos:Dictionary = new Dictionary();
      
      private var _btnItemSetUI:CustomSetBtnItemUI;
      
      private var _screenPad:ScreenPadGame;
      
      private var _screenBtns:Vector.<ScreenPadBtnBase>;
      
      private var _moveStep:Point;
      
      public function CustomScreenBtnView()
      {
         super();
         this._ui = UIAssetUtil.I.createDisplayObject("screen_pad_set_ui_mc");
         this._ui.graphics.beginFill(0,0.8);
         this._ui.graphics.drawRect(0,0,launch.FULL_SCREEN_SIZE.x,launch.FULL_SCREEN_SIZE.y);
         this._ui.graphics.endFill();
         this._width = launch.FULL_SCREEN_SIZE.x;
         this._height = ScreenPadUtils.cm2pixel(0.8);
         this._scale = this._height / 55;
         this._btnItemSetUI = new CustomSetBtnItemUI(this._scale);
         this._ui.addChild(this._btnItemSetUI.getUI());
         this.initBtns("close","up","down","left","right","center","side","zoomin","zoomout","ok");
         this.initView();
         this.initPad();
      }
      
      public function getDisplay() : Sprite
      {
         return this._ui;
      }
      
      private function initView() : void
      {
         var _loc1_:DisplayObject = null;
         var _loc2_:int = 0;
         var _loc3_:DisplayObject = this._ui.getChildByName("btnbg");
         if(Boolean(_loc3_))
         {
            _loc3_.width = this._width;
            _loc3_.height = this._height;
         }
         var _loc4_:DisplayObject = this._ui.getChildByName("up");
         var _loc5_:int = _loc4_.width * 0.15;
         var _loc6_:Number = 0;
         _loc2_ = 0;
         while(_loc2_ < this._btns.length)
         {
            _loc1_ = this._btns[_loc2_];
            _loc1_.x = _loc6_;
            _loc6_ += _loc5_ + _loc1_.width;
            if(_loc2_ == 0 || _loc2_ == this._btns.length - 2)
            {
               _loc6_ += _loc5_;
            }
            _loc2_++;
         }
         var _loc7_:Number = _loc6_;
         var _loc8_:int = this._btns.length - 2;
         var _loc9_:Number = launch.FULL_SCREEN_SIZE.x;
         var _loc10_:Number = (_loc9_ - _loc7_) / 2;
         _loc2_ = 0;
         while(_loc2_ < this._btns.length)
         {
            _loc1_ = this._btns[_loc2_];
            _loc1_.x += _loc10_;
            _loc2_++;
         }
      }
      
      private function initBtns(... rest) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:DisplayObject = null;
         this._btns = [];
         for each(_loc3_ in rest)
         {
            _loc2_ = this._ui.getChildByName(_loc3_);
            if(Boolean(_loc2_))
            {
               this._btnPos[_loc2_] = new Point(_loc2_.x,_loc2_.y);
               this._btns.push(_loc2_);
               _loc2_.scaleX = _loc2_.scaleY = this._scale;
               _loc2_.addEventListener("touchTap",this.btnTouchHandler);
            }
         }
      }
      
      private function btnTouchHandler(param1:TouchEvent) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:DisplayObject = param1.currentTarget as DisplayObject;
         if(!_loc3_)
         {
            return;
         }
         var _loc4_:Point = this._btnPos[_loc3_];
         if(!_loc4_)
         {
            _loc3_.alpha = 0.5;
            TweenLite.to(_loc3_,0.2,{"alpha":1});
         }
         else
         {
            _loc2_ = _loc4_.y;
            _loc3_.y += 5 * this._scale;
            _loc3_.alpha = 0.5;
            TweenLite.to(_loc3_,0.2,{
               "alpha":1,
               "y":_loc2_
            });
         }
         switch(_loc3_.name)
         {
            case "close":
               this.removeSelf();
               break;
            case "up":
               this.moveAllBtns(0,-this._moveStep.x);
               break;
            case "down":
               this.moveAllBtns(0,this._moveStep.x);
               break;
            case "left":
               this.moveAllBtns(-this._moveStep.x,0);
               break;
            case "right":
               this.moveAllBtns(this._moveStep.x,0);
               break;
            case "center":
               this.moveLRBtns(this._moveStep.x);
               break;
            case "side":
               this.moveLRBtns(-this._moveStep.x);
               break;
            case "zoomin":
               this.zoomBtns(0.1);
               break;
            case "zoomout":
               this.zoomBtns(-0.1);
               break;
            case "ok":
               this.doOK();
         }
         if(_loc3_.name == "ok")
         {
            SoundCtrl.I.sndConfrim();
         }
         else
         {
            SoundCtrl.I.sndSelect();
         }
      }
      
      private function removeSelf() : void
      {
         var _loc1_:* = undefined;
         if(Boolean(this._screenPad))
         {
            this._screenPad.destory();
            this._screenPad = null;
         }
         if(Boolean(this._btns))
         {
            for each(_loc1_ in this._btns)
            {
               _loc1_.removeEventListener("touchTap",this.btnTouchHandler);
            }
            this._btns = null;
         }
         if(Boolean(this._ui))
         {
            try
            {
               this._ui.parent.removeChild(this._ui);
            }
            catch(e:Error)
            {
               Debugger.log(e);
            }
            this._ui = null;
         }
      }
      
      private function doOK() : void
      {
         GameInterfaceManager.config.screenPadConfig.joySet = this._screenPad.getBtnPosData();
         ScreenPadManager.reBuild();
         this.removeSelf();
      }
      
      private function initPad() : void
      {
         this._screenPad = new ScreenPadGame(launch.STAGE);
         this._screenPad.showEditMode();
         this._screenPad.addEventListener("ScreenPadEvent_CUSTOM_MOVING",this.screenPadCustomHandler);
         this._screenPad.addEventListener("ScreenPadEvent_CUSTOM_SELECT",this.screenPadCustomHandler);
         this._screenBtns = this._screenPad.getBtns();
         this._moveStep = new Point();
         this._moveStep.x = launch.FULL_SCREEN_SIZE.x * 0.01;
         this._moveStep.y = launch.FULL_SCREEN_SIZE.y * 0.01;
      }
      
      private function screenPadCustomHandler(param1:ScreenPadEvent) : void
      {
         switch(param1.type)
         {
            case "ScreenPadEvent_CUSTOM_MOVING":
               this._btnItemSetUI.show(param1.screenPadBtn);
               break;
            case "ScreenPadEvent_CUSTOM_SELECT":
               this._btnItemSetUI.show(param1.screenPadBtn);
         }
      }
      
      private function moveAllBtns(param1:Number = 0, param2:Number = 0) : void
      {
         var _loc3_:* = undefined;
         for each(_loc3_ in this._screenBtns)
         {
            _loc3_.display.x += param1;
            _loc3_.display.y += param2;
         }
      }
      
      private function moveLRBtns(param1:Number = 0) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:Number = launch.FULL_SCREEN_SIZE.x / 2;
         for each(_loc3_ in this._screenBtns)
         {
            if(_loc3_.display.x < _loc2_)
            {
               _loc3_.display.x += param1;
            }
            else
            {
               _loc3_.display.x -= param1;
            }
         }
      }
      
      private function zoomBtns(param1:Number) : void
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in this._screenBtns)
         {
            this.zoomBtn(_loc2_,param1);
         }
      }
      
      private function zoomBtn(param1:ScreenPadBtnBase, param2:Number) : void
      {
         if(!param1)
         {
            return;
         }
         var _loc3_:Number = param1.display.scaleX;
         _loc3_ += param2;
         param1.display.scaleX = param1.display.scaleY = _loc3_;
      }
   }
}

