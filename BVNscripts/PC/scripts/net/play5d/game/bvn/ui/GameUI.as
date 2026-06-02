package net.play5d.game.bvn.ui
{
   import flash.display.DisplayObject;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameRunFighterGroup;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.ui.dialog.AlertUI;
   import net.play5d.game.bvn.ui.dialog.BaseDialog;
   import net.play5d.game.bvn.ui.dialog.BranchUI;
   import net.play5d.game.bvn.ui.dialog.ConfrimUI;
   import net.play5d.game.bvn.ui.dialog.DialogManager;
   import net.play5d.game.bvn.ui.dialog.MosouAlertUI;
   import net.play5d.game.bvn.ui.dialog.MosouConfrimUI;
   import net.play5d.game.bvn.ui.fight.FightUI;
   import net.play5d.game.bvn.ui.mosou.MosouUI;
   
   public class GameUI
   {
      
      public static var I:GameUI;
      
      public static var BITMAP_UI:Boolean = true;
      
      public static var SHOW_CN_TEXT:Boolean = true;
      
      public static const SHOW_HP_TEXT:Boolean = true;
      
      private static var _confrimUI:BaseDialog;
      
      private static var _confrimUICls:Class;
      
      private static var _alertUI:BaseDialog;
      
      private static var _alertUICls:Class;
      
      private static var _branchUI:BranchUI;
      
      private static var _activeSetBtnGroup:SetBtnGroup;
      
      private var _ui:IGameUI;
      
      private var _renderAnimateGap:int;
      
      private var _renderAnimateFrame:int = 0;
      
      public function GameUI()
      {
         super();
         I = this;
         _renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / 30) - 1;
      }
      
      public static function showingDialog() : Boolean
      {
         return showingConfrim() || showingAlert() || showingBranch();
      }
      
      public static function showingConfrim() : Boolean
      {
         return _confrimUI != null;
      }
      
      public static function showingAlert() : Boolean
      {
         return _alertUI != null;
      }
      
      public static function showingBranch() : Boolean
      {
         return _branchUI != null;
      }
      
      public static function confrim(param1:String = null, param2:String = null, param3:Function = null, param4:Function = null, param5:Boolean = false) : void
      {
         var enMsg:String = param1;
         var cnMsg:String = param2;
         var yes:Function = param3;
         var no:Function = param4;
         var isMusou:Boolean = param5;
         var yesClose:* = function():void
         {
            if(yes != null)
            {
               yes();
            }
            if(_activeSetBtnGroup)
            {
               _activeSetBtnGroup.resumeRender();
            }
            closeConfrim();
         };
         var noClose:* = function():void
         {
            if(no != null)
            {
               no();
            }
            if(_activeSetBtnGroup)
            {
               _activeSetBtnGroup.resumeRender();
            }
            closeConfrim();
            GameEvent.dispatchEvent("UI_CONFRIM_CLOSE");
         };
         closeConfrim();
         _confrimUICls = isMusou ? MosouConfrimUI : ConfrimUI;
         _confrimUI = new _confrimUICls();
         _confrimUI.setMsg(enMsg,cnMsg);
         _confrimUI.yesBack = yesClose;
         _confrimUI.noBack = noClose;
         GameEvent.dispatchEvent("UI_CONFRIM");
         if(_activeSetBtnGroup)
         {
            _activeSetBtnGroup.pauseRender();
         }
         DialogManager.showDialog(_confrimUI,false);
      }
      
      public static function alert(param1:String = null, param2:String = null, param3:Function = null, param4:Boolean = false) : void
      {
         var enMsg:String = param1;
         var cnMsg:String = param2;
         var close:Function = param3;
         var isMusou:Boolean = param4;
         var closeBack:* = function():void
         {
            if(close != null)
            {
               close();
            }
            if(_activeSetBtnGroup)
            {
               _activeSetBtnGroup.resumeRender();
            }
            closeAlert();
            GameEvent.dispatchEvent("UI_ALERT_CLOSE");
         };
         closeAlert();
         _alertUICls = isMusou ? MosouAlertUI : AlertUI;
         _alertUI = new _alertUICls();
         _alertUI.setMsg(enMsg,cnMsg);
         _alertUI.yesBack = closeBack;
         GameEvent.dispatchEvent("UI_ALERT",{
            "enMsg":enMsg,
            "cnMsg":cnMsg
         });
         if(_activeSetBtnGroup)
         {
            _activeSetBtnGroup.pauseRender();
         }
         DialogManager.showDialog(_alertUI,false);
      }
      
      public static function branch(param1:String = null, param2:String = null, param3:Function = null, param4:Function = null, param5:int = 0) : void
      {
         var enMsg:String = param1;
         var cnMsg:String = param2;
         var branchFunc:Function = param3;
         var no:Function = param4;
         var branchNum:int = param5;
         var yesClose:* = function(param1:int):void
         {
            if(branchFunc != null)
            {
               branchFunc(param1);
            }
            closeBranch();
         };
         var noClose:* = function():void
         {
            if(no != null)
            {
               no();
            }
            closeBranch();
            GameEvent.dispatchEvent("UI_BRANCH_CLOSE");
         };
         closeConfrim();
         _branchUI = new BranchUI(branchNum);
         _branchUI.setMsg(enMsg,cnMsg);
         _branchUI.yesBack = yesClose;
         _branchUI.noBack = noClose;
         GameEvent.dispatchEvent("UI_BRANCH");
         DialogManager.showDialog(_branchUI,false);
      }
      
      public static function closeConfrim() : void
      {
         if(_confrimUI != null)
         {
            DialogManager.closeDialog(_confrimUI);
            _confrimUI = null;
         }
      }
      
      public static function closeAlert() : void
      {
         if(_alertUI)
         {
            DialogManager.closeDialog(_alertUI);
            _alertUI = null;
         }
      }
      
      public static function closeBranch() : void
      {
         if(_branchUI != null)
         {
            DialogManager.closeDialog(_branchUI);
            _branchUI = null;
         }
      }
      
      public static function cancelConfrim() : void
      {
         if(_confrimUI != null)
         {
            if((_confrimUI as _confrimUICls).noBack != null)
            {
               (_confrimUI as _confrimUICls).noBack();
            }
            else
            {
               closeConfrim();
            }
         }
      }
      
      public static function cancelBranch() : void
      {
         if(_branchUI != null)
         {
            if(_branchUI.noBack != null)
            {
               _branchUI.noBack();
            }
            else
            {
               closeBranch();
            }
         }
      }
      
      public static function registerSetBtnGroup(param1:SetBtnGroup) : void
      {
         _activeSetBtnGroup = param1;
      }
      
      public function getUI() : IGameUI
      {
         return _ui;
      }
      
      public function getUIDisplay() : DisplayObject
      {
         return _ui.getUI();
      }
      
      public function initFight(param1:GameRunFighterGroup, param2:GameRunFighterGroup) : void
      {
         var _loc3_:Number = !GameConfig.IS_WIN_ACTIVATE ? 0 : GameData.I.config.soundVolume;
         if(_ui)
         {
            if(_ui is FightUI == false)
            {
               _ui.destory();
               _ui = new FightUI();
               _ui.setVolume(_loc3_);
            }
         }
         else
         {
            _ui = new FightUI();
            _ui.setVolume(_loc3_);
         }
         (_ui as FightUI).initlize(param1,param2);
      }
      
      public function initMission(param1:GameRunFighterGroup) : void
      {
         var _loc2_:Number = !GameConfig.IS_WIN_ACTIVATE ? 0 : GameData.I.config.soundVolume;
         if(_ui)
         {
            if(_ui is FightUI == false)
            {
               _ui.destory();
               _ui = new FightUI();
               _ui.setVolume(_loc2_);
            }
         }
         else
         {
            _ui = new MosouUI();
            _ui.setVolume(_loc2_);
         }
         (_ui as MosouUI).initlize(param1);
      }
      
      public function render() : void
      {
         if(!_ui)
         {
            return;
         }
         var _loc1_:Number = !GameConfig.IS_WIN_ACTIVATE ? 0 : GameData.I.config.soundVolume;
         _ui.setVolume(_loc1_);
         _ui.render();
         if(isRenderAnimate())
         {
            renderAnimate();
         }
      }
      
      private function renderAnimate() : void
      {
         if(_ui)
         {
            _ui.renderAnimate();
         }
      }
      
      private function isRenderAnimate() : Boolean
      {
         if(_renderAnimateGap > 0)
         {
            if(_renderAnimateFrame++ >= _renderAnimateGap)
            {
               _renderAnimateFrame = 0;
               return true;
            }
            return false;
         }
         return true;
      }
      
      public function fadIn() : void
      {
         var _loc1_:Number = !GameConfig.IS_WIN_ACTIVATE ? 0 : GameData.I.config.soundVolume;
         if(_ui)
         {
            _ui.fadIn();
            _ui.setVolume(_loc1_);
         }
      }
      
      public function fadOut() : void
      {
         if(_ui)
         {
            _ui.fadIn();
         }
      }
      
      public function destory() : void
      {
         if(_confrimUICls != null)
         {
            _confrimUICls = null;
         }
         if(_ui)
         {
            _ui.destory();
         }
      }
   }
}

