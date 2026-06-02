package net.play5d.game.bvn.win.views.lan
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.win.ctrls.LANServerCtrl;
   import net.play5d.game.bvn.win.data.HostVO;
   import net.play5d.game.bvn.win.data.LanGameModel;
   import net.play5d.kyo.stage.Istage;
   import net.play5d.kyo.utils.KyoBtnUtils;
   
   public class LANHostCreateDialog implements Istage
   {
      
      private var _ui:MovieClip;
      
      public var onCreate:Function;
      
      public var onClose:Function;
      
      public function LANHostCreateDialog()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function close() : void
      {
         if(onClose != null)
         {
            onClose();
         }
         MainGame.stageCtrl.removeLayer(this);
      }
      
      public function build() : void
      {
         _ui = AssetManager.I.createObject("build_win_mc","subswfs/win_ui.swf") as MovieClip;
         _ui.check_pass.addEventListener("change",checkHandler);
         KyoBtnUtils.initBtn(_ui.btn_ok,btnHandler);
         KyoBtnUtils.initBtn(_ui.btn_close,close);
         _ui.txt_pass.visible = false;
         _ui.comb_mode.addItem({
            "label":"TEAM VS - 小队模式",
            "data":1
         });
      }
      
      private function btnHandler() : void
      {
         SoundCtrl.I.sndConfrim();
         var _loc1_:String = _ui.txt_hostname.text;
         var _loc3_:String = "";
         var _loc4_:int = int(_ui.comb_mode.selectedItem.data);
         if(_loc1_ == "")
         {
            GameUI.alert(GetLangText("game_ui.alert.input_host_name.title"),GetLangText("game_ui.alert.input_host_name.message"));
            return;
         }
         if(_ui.check_pass.selected)
         {
            _loc3_ = _ui.txt_pass.text;
         }
         var _loc2_:HostVO = new HostVO();
         _loc2_.name = _loc1_;
         _loc2_.gameMode = _loc4_;
         _loc2_.password = _loc3_;
         _loc2_.ownerName = LanGameModel.I.playerName;
         _loc2_.tcpPort = 17511;
         _loc2_.udpPort = 17477;
         LANServerCtrl.I.startServer(_loc2_);
         if(onCreate != null)
         {
            onCreate();
         }
         close();
      }
      
      private function checkHandler(param1:Event) : void
      {
         _ui.txt_pass.visible = _ui.check_pass.selected;
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         _ui.btn_ok.removeEventListener("click",btnHandler);
         _ui.check_pass.removeEventListener("change",checkHandler);
         KyoBtnUtils.disposeBtn(_ui.btn_ok);
         KyoBtnUtils.disposeBtn(_ui.btn_close);
      }
   }
}

