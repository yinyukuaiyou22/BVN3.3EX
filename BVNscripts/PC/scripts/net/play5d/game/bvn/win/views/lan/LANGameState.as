package net.play5d.game.bvn.win.views.lan
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.ui.SetBtnGroup;
   import net.play5d.kyo.stage.Istage;
   
   public class LANGameState implements Istage
   {
      
      private var _ui:Sprite;
      
      private var _btnGroup:SetBtnGroup;
      
      private var _hostList:HostListDialog;
      
      public function LANGameState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function build() : void
      {
         _ui = AssetManager.I.createObject("spr_lan","subswfs/win_ui.swf") as MovieClip;
         _btnGroup = new SetBtnGroup();
         _btnGroup.setBtnData([{
            "label":GetLangText("game_ui.btn_data.lan_game.join_game.label"),
            "cn":GetLangText("game_ui.btn_data.lan_game.join_game.txt")
         },{
            "label":GetLangText("game_ui.btn_data.lan_game.build_game.label"),
            "cn":GetLangText("game_ui.btn_data.lan_game.build_game.txt")
         },{
            "label":GetLangText("game_ui.btn_data.lan_game.profile.label"),
            "cn":GetLangText("game_ui.btn_data.lan_game.profile.txt")
         },{
            "label":GetLangText("game_ui.btn_data.lan_game.exit.label"),
            "cn":GetLangText("game_ui.btn_data.lan_game.exit.txt")
         }]);
         _btnGroup.addEventListener("SELECT",btnHandler);
         _ui.addChild(_btnGroup);
         SoundCtrl.I.BGM(AssetManager.I.getSound("continue"));
      }
      
      public function showHostList() : void
      {
         _btnGroup.keyEnable = false;
         _hostList = new HostListDialog();
         _hostList.onClose = onDialogClose;
         MainGame.stageCtrl.addLayer(_hostList,10,10);
      }
      
      private function btnHandler(param1:SetBtnEvent) : void
      {
         var _loc3_:LANHostCreateDialog = null;
         var _loc2_:ProfileDialog = null;
         switch(param1.selectedLabel)
         {
            case GetLangText("game_ui.btn_data.lan_game.join_game.label"):
               showHostList();
               break;
            case GetLangText("game_ui.btn_data.lan_game.build_game.label"):
               _btnGroup.keyEnable = false;
               _loc3_ = new LANHostCreateDialog();
               _loc3_.onCreate = onCreateHost;
               _loc3_.onClose = onDialogClose;
               MainGame.stageCtrl.addLayer(_loc3_,0,0);
               break;
            case GetLangText("game_ui.btn_data.lan_game.profile.label"):
               _btnGroup.keyEnable = false;
               _loc2_ = new ProfileDialog();
               _loc2_.onClose = onDialogClose;
               MainGame.stageCtrl.addLayer(_loc2_,0,0);
               break;
            case GetLangText("game_ui.btn_data.lan_game.exit.label"):
               MainGame.I.goMenu();
         }
      }
      
      private function onDialogClose() : void
      {
         if(_btnGroup)
         {
            _btnGroup.keyEnable = true;
         }
      }
      
      private function onCreateHost() : void
      {
         var _loc1_:LANRoomState = new LANRoomState();
         MainGame.stageCtrl.goStage(_loc1_);
         _loc1_.hostMode();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         if(_btnGroup)
         {
            _btnGroup.destory();
            _btnGroup = null;
         }
      }
   }
}

