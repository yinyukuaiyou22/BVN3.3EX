package net.play5d.game.bvn.ui
{
   import flash.display.Sprite;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.ctrler.FighterAICtrl;
   import net.play5d.game.bvn.fighter.ctrler.FighterKeyCtrl;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   import net.play5d.kyo.utils.KyoUtils;
   
   public class PauseDialog extends Sprite
   {
      
      private var _bg:Sprite;
      
      private var _btnGroup:SetBtnGroup;
      
      private var _moveList:MoveListSp;
      
      private var _btnData:Array = null;
      
      private var _bIsOpenAI:Boolean = false;
      
      public function PauseDialog()
      {
         super();
         _bg = new Sprite();
         _bg.graphics.beginFill(0,0.5);
         _bg.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         _bg.graphics.endFill();
         addChild(_bg);
         updateBtnData();
      }
      
      private function updateBtnData() : void
      {
         if(_btnGroup != null)
         {
            removeChild(_btnGroup);
            _btnGroup.destory();
            _btnGroup = null;
         }
         _btnGroup = new SetBtnGroup();
         var _loc1_:Object = {
            "label":(_bIsOpenAI ? GetLangText("game_ui.btn_data.pause_dialog.training_ai_off.label") : GetLangText("game_ui.btn_data.pause_dialog.training_ai_on.label")),
            "cn":(_bIsOpenAI ? GetLangText("game_ui.btn_data.pause_dialog.training_ai_off.txt") : GetLangText("game_ui.btn_data.pause_dialog.training_ai_on.txt"))
         };
         _btnData = [{
            "label":GetLangText("game_ui.btn_data.pause_dialog.back_title.label"),
            "cn":GetLangText("game_ui.btn_data.pause_dialog.back_title.txt")
         },{
            "label":GetLangText("game_ui.btn_data.pause_dialog.move_list.label"),
            "cn":GetLangText("game_ui.btn_data.pause_dialog.move_list.txt")
         },{
            "label":GetLangText("game_ui.btn_data.pause_dialog.back_select.label"),
            "cn":GetLangText("game_ui.btn_data.pause_dialog.back_select.txt")
         },{
            "label":GetLangText("game_ui.btn_data.pause_dialog.continue.label"),
            "cn":GetLangText("game_ui.btn_data.pause_dialog.continue.txt")
         }];
         if(GameMode.currentMode == 40)
         {
            KyoUtils.array_pushAt(_btnData,_loc1_,3);
         }
         _btnGroup.setBtnData(_btnData,_btnData.length - 1);
         _btnGroup.addEventListener("SELECT",btnGroupSelectHandler);
         addChild(_btnGroup);
      }
      
      public function destory() : void
      {
         if(_btnGroup)
         {
            _btnGroup.removeEventListener("SELECT",btnGroupSelectHandler);
            _btnGroup.destory();
            _btnGroup = null;
         }
         if(_moveList)
         {
            _moveList.destory();
            _moveList = null;
         }
      }
      
      public function isShowing() : Boolean
      {
         return visible;
      }
      
      public function show() : void
      {
         updateBtnData();
         this.visible = true;
         _btnGroup.keyEnable = true;
         _btnGroup.setArrowIndex(_btnData.length - 1);
      }
      
      public function hide() : Boolean
      {
         if(_moveList && _moveList.isShowing())
         {
            hideMoveList();
            return false;
         }
         this.visible = false;
         _btnGroup.keyEnable = false;
         return true;
      }
      
      private function btnGroupSelectHandler(param1:SetBtnEvent) : void
      {
         var e:SetBtnEvent = param1;
         if(GameUI.showingDialog())
         {
            return;
         }
         switch(e.selectedLabel)
         {
            case GetLangText("game_ui.btn_data.pause_dialog.back_title.label"):
               _btnGroup.keyEnable = false;
               GameUI.confrim(GetLangText("game_ui.confrim.back_title.title"),GetLangText("game_ui.confrim.back_title.message"),function():void
               {
                  MainGame.I.goMenu();
               },function():void
               {
                  _btnGroup.keyEnable = true;
               });
               break;
            case GetLangText("game_ui.btn_data.pause_dialog.move_list.label"):
               showMoveList();
               GameEvent.dispatchEvent("PAUSE_GAME_MENU","movelist");
               break;
            case GetLangText("game_ui.btn_data.pause_dialog.back_select.label"):
               GameEvent.dispatchEvent("GAME_END");
               MainGame.I.goSelect();
               break;
            case GetLangText("game_ui.btn_data.pause_dialog.training_ai_on.label"):
            case GetLangText("game_ui.btn_data.pause_dialog.training_ai_off.label"):
               (function():void
               {
                  var _loc2_:FighterMain = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter as FighterMain;
                  if(_loc2_ == null)
                  {
                     return;
                  }
                  var _loc1_:IFighterActionCtrl = _loc2_.getActionCtrl();
                  if(_loc1_ == null)
                  {
                     return;
                  }
                  var _loc3_:IFighterActionCtrl = null;
                  if(_bIsOpenAI)
                  {
                     _loc3_ = new FighterKeyCtrl();
                     (_loc3_ as FighterKeyCtrl).inputType = "P2";
                     (_loc3_ as FighterKeyCtrl).classicMode = GameData.I.config.keyInputMode == 1;
                  }
                  else
                  {
                     _loc3_ = new FighterAICtrl();
                     (_loc3_ as FighterAICtrl).AILevel = GameData.I.config.AI_level;
                     (_loc3_ as FighterAICtrl).fighter = _loc2_;
                  }
                  _bIsOpenAI = !_bIsOpenAI;
                  _loc2_.setActionCtrl(_loc3_);
                  _loc2_.getCtrler().getMcCtrl().setNewActionLogic(_loc2_);
               })();
            case GetLangText("game_ui.btn_data.pause_dialog.continue.label"):
               GameCtrl.I.resume(true);
         }
      }
      
      private function showMoveList() : void
      {
         if(!_moveList)
         {
            _moveList = new MoveListSp();
            _moveList.onBackSelect = hideMoveList;
            addChild(_moveList);
         }
         _btnGroup.keyEnable = false;
         _moveList.show();
      }
      
      private function hideMoveList() : void
      {
         _moveList.hide();
         _btnGroup.keyEnable = true;
         GameEvent.dispatchEvent("PAUSE_GAME_MENU","movelist-back");
      }
   }
}

