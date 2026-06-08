package net.play5d.game.bvn.ui
{
   import flash.display.DisplayObject;
   import flash.events.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.ui.dialog.*;
   import net.play5d.game.bvn.ui.fight.*;
   
   public class GameUI
   {
      
      public static var I:GameUI;
      
      private static var _confrimUI:ConfrimUI;
      
      private static var _alertUI:AlertUI;
      
      public static var BITMAP_UI:Boolean = true;
      
      public static var SHOW_CN_TEXT:Boolean = true;
      
      private var _ui:IGameUI;
      
      private var _renderAnimateGap:int;
      
      private var _renderAnimateFrame:int = 0;
      
      public function GameUI()
      {
         super();
         I = this;
         this._renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / 30) - 1;
      }
      
      public static function showingDialog() : Boolean
      {
         return _confrimUI != null || _alertUI != null;
      }
      
      public static function confrim(param1:String = null, param2:String = null, param3:Function = null, param4:Function = null) : void
      {
         var yes:Function = null;
         var no:Function = null;
         var enMsg:String = param1;
         var cnMsg:String = param2;
         yes = param3;
         no = param4;
         var yesClose:* = function():void
         {
            if(yes != null)
            {
               yes();
            }
            closeConfrim();
            MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["close_confrim",true])));
         };
         var noClose:* = function():void
         {
            if(no != null)
            {
               no();
            }
            closeConfrim();
            MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["close_confrim",false])));
         };
         closeConfrim();
         _confrimUI = new ConfrimUI();
         _confrimUI.setMsg(enMsg,cnMsg);
         _confrimUI.yesBack = yesClose;
         _confrimUI.noBack = noClose;
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["show_confrim"])));
         MainGame.I.root.addChild(_confrimUI);
      }
      
      public static function alert(param1:String = null, param2:String = null, param3:Function = null) : void
      {
         var close:Function = null;
         var enMsg:String = param1;
         var cnMsg:String = param2;
         close = param3;
         var closeBack:* = function():void
         {
            if(close != null)
            {
               close();
            }
            closeAlert();
            MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["close_alert"])));
         };
         closeAlert();
         _alertUI = new AlertUI();
         _alertUI.setMsg(enMsg,cnMsg);
         _alertUI.closeBack = closeBack;
         MainGame.I.root.addChild(_alertUI);
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["show_alert"])));
      }
      
      public static function closeAlert() : void
      {
         if(Boolean(_alertUI))
         {
            try
            {
               MainGame.I.root.removeChild(_alertUI);
            }
            catch(e:Error)
            {
            }
            _alertUI.destory();
            _alertUI = null;
         }
      }
      
      public static function closeConfrim() : void
      {
         if(Boolean(_confrimUI))
         {
            try
            {
               MainGame.I.root.removeChild(_confrimUI);
            }
            catch(e:Error)
            {
            }
            _confrimUI.destory();
            _confrimUI = null;
         }
      }
      
      public function getUI() : IGameUI
      {
         return this._ui;
      }
      
      public function getUIDisplay() : DisplayObject
      {
         return this._ui.getUI();
      }
      
      public function initFight(param1:GameRunFighterGroup, param2:GameRunFighterGroup) : void
      {
         var _loc3_:Number = Number(GameData.I.config.soundVolume);
         if(Boolean(this._ui))
         {
            if(this._ui is FightUI == false)
            {
               this._ui.destory();
               this._ui = new FightUI();
               this._ui.setVolume(_loc3_);
            }
         }
         else
         {
            this._ui = new FightUI();
            this._ui.setVolume(_loc3_);
         }
         (this._ui as FightUI).initlize(param1,param2);
      }
      
      public function render() : void
      {
         if(!this._ui)
         {
            return;
         }
         this._ui.render();
         if(this.isRenderAnimate())
         {
            this.renderAnimate();
         }
      }
      
      private function renderAnimate() : void
      {
         if(Boolean(this._ui))
         {
            this._ui.renderAnimate();
         }
      }
      
      private function isRenderAnimate() : Boolean
      {
         if(this._renderAnimateGap > 0)
         {
            if(this._renderAnimateFrame++ >= this._renderAnimateGap)
            {
               this._renderAnimateFrame = 0;
               return true;
            }
            return false;
         }
         return true;
      }
      
      public function fadIn() : void
      {
         var _loc1_:Number = NaN;
         if(Boolean(this._ui))
         {
            _loc1_ = Number(GameData.I.config.soundVolume);
            this._ui.fadIn();
            this._ui.setVolume(_loc1_);
         }
      }
      
      public function fadOut() : void
      {
         if(Boolean(this._ui))
         {
            this._ui.fadIn();
         }
      }
      
      public function destory() : void
      {
         if(Boolean(this._ui))
         {
            this._ui.destory();
         }
      }
   }
}

