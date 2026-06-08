package net.play5d.game.bvn.state
{
   import com.greensock.*;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.IInnerSetUI;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   
   public class SettingState implements Istage
   {
      
      private var _ui:*;
      
      private var _btnGroup:SetBtnGroup;
      
      private var _innerSetUI:IInnerSetUI;
      
      private var _man:MovieClip;
      
      public function SettingState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.setting,ResUtils.SETTING);
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.startY = 30;
         this._btnGroup.endY = 550;
         this._btnGroup.gap = 70;
         this._btnGroup.initMainSet();
         this._btnGroup.initScroll(GameConfig.GAME_SIZE.x,600);
         this._btnGroup.addEventListener("SELECT",this.onBtnSelect);
         this._btnGroup.addEventListener("OPTION_CHANGE",this.onOptionChange);
         this._ui.addChild(this._btnGroup);
         this._man = this._ui.ichigo;
         SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
      }
      
      private function onOptionChange(param1:SetBtnEvent) : void
      {
         var _loc2_:ConfigVO = GameData.I.config;
         _loc2_.setValueByKey(param1.optionKey,param1.optionValue);
      }
      
      private function onBtnSelect(param1:SetBtnEvent) : void
      {
         switch(param1.selectedLabel)
         {
            case "P1 KEY SET":
               this.goKeyConfig(1,GameData.I.config.key_p1);
               break;
            case "P2 KEY SET":
               this.goKeyConfig(2,GameData.I.config.key_p2);
               break;
            case "APPLY":
               GameData.I.saveData();
               GameData.I.config.applyConfig();
               GameInputer.updateConfig();
               MainGame.I.goMenu();
         }
      }
      
      private function goKeyConfig(param1:int, param2:KeyConfigVO) : void
      {
         var _loc3_:SetCtrlBtnUI = new SetCtrlBtnUI();
         _loc3_.setKey(param2);
         this.goInnerSetPage(_loc3_);
      }
      
      public function goInnerSetPage(param1:IInnerSetUI) : void
      {
         var innerUI:IInnerSetUI = param1;
         var tweenComplete:* = function():void
         {
            _btnGroup.visible = false;
         };
         this.destoryInnerSetUI();
         this._innerSetUI = innerUI;
         innerUI.addEventListener("APPLY_SET",this.innerSetHandler);
         innerUI.addEventListener("CANCEL_SET",this.innerSetHandler);
         this._ui.addChild(innerUI.getUI());
         innerUI.fadIn();
         TweenLite.to(this._btnGroup,0.2,{
            "y":-GameConfig.GAME_SIZE.y,
            "onComplete":tweenComplete
         });
         this._btnGroup.keyEnable = false;
         this._man.gotoAndPlay("key_fadin");
      }
      
      private function destoryInnerSetUI() : void
      {
         if(Boolean(this._innerSetUI))
         {
            try
            {
               this._ui.removeChild(this._innerSetUI.getUI());
            }
            catch(e:Error)
            {
            }
            this._innerSetUI.removeEventListener("APPLY_SET",this.innerSetHandler);
            this._innerSetUI.removeEventListener("CANCEL_SET",this.innerSetHandler);
            this._innerSetUI.destory();
            this._innerSetUI = null;
         }
      }
      
      private function goMainSetting() : void
      {
         var tweenComplete:* = function():void
         {
            _btnGroup.keyEnable = true;
         };
         TweenLite.to(this._btnGroup,0.2,{
            "y":0,
            "onComplete":tweenComplete,
            "delay":0.1
         });
         this._btnGroup.visible = true;
         if(Boolean(this._innerSetUI))
         {
            this._innerSetUI.fadOut();
            this._innerSetUI.removeEventListener("APPLY_SET",this.innerSetHandler);
            this._innerSetUI.removeEventListener("CANCEL_SET",this.innerSetHandler);
         }
         this._man.gotoAndPlay("key_fadout");
      }
      
      private function innerSetHandler(param1:String) : void
      {
         this.goMainSetting();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         if(Boolean(this._btnGroup))
         {
            try
            {
               this._ui.removeChild(this._btnGroup);
            }
            catch(e:Error)
            {
            }
            this._btnGroup.removeEventListener("SELECT",this.onBtnSelect);
            this._btnGroup.removeEventListener("OPTION_CHANGE",this.onOptionChange);
            this._btnGroup.destory();
            this._btnGroup = null;
         }
         this.destoryInnerSetUI();
      }
   }
}

