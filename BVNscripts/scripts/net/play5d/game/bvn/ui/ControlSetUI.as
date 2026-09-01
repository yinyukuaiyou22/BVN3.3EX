package net.play5d.game.bvn.ui
{
   import com.greensock.*;
   import flash.display.*;
   import flash.events.EventDispatcher;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.mob.views.ViewManager;
   import net.play5d.game.bvn.utils.*;

   public class ControlSetUI extends EventDispatcher implements IInnerSetUI
   {
      
      public var ui:*;
      
      private var _btnGroup:SetBtnGroup;
      
      public function ControlSetUI()
      {
         super();
         Debugger.log("[ControlSetUI]","create");
         this.ui = ResUtils.I.createDisplayObject(ResUtils.I.setting,"keyset_mc");
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.startY = 30;
         this._btnGroup.initControlSet();
         this._btnGroup.addEventListener("SELECT",this.onBtnSelect);
         this._btnGroup.addEventListener("OPTION_CHANGE",this.onOptionChange);
         this.ui.addChild(this._btnGroup);
      }
      
      public function destory() : void
      {
         Debugger.log("[ControlSetUI]","destory()");
         if(Boolean(this._btnGroup))
         {
            try
            {
               this.ui.removeChild(this._btnGroup);
            }
            catch(e:Error)
            {
            }
            this._btnGroup.removeEventListener("SELECT",this.onBtnSelect);
            this._btnGroup.removeEventListener("OPTION_CHANGE",this.onOptionChange);
            this._btnGroup.destory();
            this._btnGroup = null;
         }
      }
      
      public function getUI() : DisplayObject
      {
         return this.ui;
      }
      
      private function onBtnSelect(param1:SetBtnEvent) : void
      {
         Debugger.log("[ControlSetUI]","onBtnSelect label=",param1.selectedLabel);
         switch(param1.selectedLabel)
         {
            case "Screen Button":
               ViewManager.I.setScreenBtns();
               break;
            case "BACK":
               dispatchEvent(new SetBtnEvent("CANCEL_SET"));
         }
      }
      
      private function onOptionChange(param1:SetBtnEvent) : void
      {
         var _loc2_:ConfigVO = GameData.I.config;
         _loc2_.setValueByKey(param1.optionKey,param1.optionValue);
      }
      
      public function fadIn() : void
      {
         var duration:Number = 0.3;
         this.ui.y = GameConfig.GAME_SIZE.y;
         TweenLite.to(this.ui,duration,{
            "y":0,
            "onComplete":function():void
            {
               _btnGroup.keyEnable = true;
            }
         });
         this._btnGroup.setArrowIndex(0);
         this.ui.visible = true;
      }
      
      public function fadOut() : void
      {
         var duration:Number = 0.3;
         this._btnGroup.keyEnable = false;
         TweenLite.to(this.ui,duration,{
            "y":GameConfig.GAME_SIZE.y,
            "onComplete":function():void
            {
               ui.visible = false;
            }
         });
      }
   }
}
