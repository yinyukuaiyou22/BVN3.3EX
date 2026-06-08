package net.play5d.game.bvn.mob.views
{
   import com.greensock.*;
   import flash.display.*;
   import flash.events.TouchEvent;
   import flash.geom.*;
   import flash.utils.*;
   import net.play5d.game.bvn.mob.screenpad.ScreenPadBtnBase;
   import net.play5d.game.bvn.mob.utils.*;
   
   public class CustomSetBtnItemUI
   {
      
      private var _ui:Sprite;
      
      private var _target:ScreenPadBtnBase;
      
      private var _btns:Array;
      
      private var _btnPos:Dictionary = new Dictionary();
      
      private var _scale:Number = 1;
      
      public function CustomSetBtnItemUI(param1:Number)
      {
         super();
         this._ui = UIAssetUtil.I.createDisplayObject("item_set_btns_mc");
         this._ui.scaleX = this._ui.scaleY = param1;
         this._ui.visible = false;
         this.initBtns("zoomin2","zoomout2");
      }
      
      public function getUI() : Sprite
      {
         return this._ui;
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
            _loc3_.y += 5;
            _loc3_.alpha = 0.5;
            TweenLite.to(_loc3_,0.2,{
               "alpha":1,
               "y":_loc2_
            });
         }
         switch(_loc3_.name)
         {
            case "zoomin2":
               this.zoomBtn(0.1);
               break;
            case "zoomout2":
               this.zoomBtn(-0.1);
         }
      }
      
      private function zoomBtn(param1:Number) : void
      {
         if(!this._target)
         {
            return;
         }
         var _loc2_:Number = Number(this._target.display.scaleX);
         _loc2_ += param1;
         this._target.display.scaleX = this._target.display.scaleY = _loc2_;
      }
      
      public function show(param1:ScreenPadBtnBase) : void
      {
         this._target = param1;
         this._ui.visible = true;
         this._ui.x = this._target.display.x + this._target.display.width - this._ui.width;
         this._ui.y = this._target.display.y;
      }
      
      public function hide() : void
      {
         this._target = null;
         this._ui.visible = false;
      }
   }
}

