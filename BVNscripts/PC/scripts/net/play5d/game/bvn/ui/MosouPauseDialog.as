package net.play5d.game.bvn.ui
{
   import flash.display.Sprite;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.events.SetBtnEvent;
   
   public class MosouPauseDialog extends Sprite
   {
      
      private var _bg:Sprite;
      
      private var _btnGroup:SetBtnGroup;
      
      private var _moveList:MoveListSp;
      
      public function MosouPauseDialog()
      {
         super();
         _bg = new Sprite();
         _bg.graphics.beginFill(0,0.5);
         _bg.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         _bg.graphics.endFill();
         addChild(_bg);
         _btnGroup = new SetBtnGroup();
         _btnGroup.setBtnData([{
            "label":GetLangText("game_ui.btn_data.musou_pause.back_map.label"),
            "cn":GetLangText("game_ui.btn_data.musou_pause.back_map.txt")
         },{
            "label":GetLangText("game_ui.btn_data.musou_pause.move_list.label"),
            "cn":GetLangText("game_ui.btn_data.musou_pause.move_list.txt")
         },{
            "label":GetLangText("game_ui.btn_data.musou_pause.continue.label"),
            "cn":GetLangText("game_ui.btn_data.musou_pause.continue.txt")
         }],2);
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
         this.visible = true;
         _btnGroup.keyEnable = true;
         _btnGroup.setArrowIndex(2);
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
         GameUI.closeConfrim();
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
            case GetLangText("game_ui.btn_data.musou_pause.back_map.label"):
               _btnGroup.keyEnable = false;
               GameUI.confrim(GetLangText("game_ui.confrim.musou_back.title"),GetLangText("game_ui.confrim.musou_back.message"),function():void
               {
                  MainGame.I.goWorldMap();
                  GameEvent.dispatchEvent("MOSOU_BACK_MAP");
               },function():void
               {
                  _btnGroup.keyEnable = true;
               });
               break;
            case GetLangText("game_ui.btn_data.musou_pause.move_list.label"):
               showMoveList();
               GameEvent.dispatchEvent("PAUSE_GAME_MENU","movelist");
               break;
            case GetLangText("game_ui.btn_data.musou_pause.continue.label"):
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

