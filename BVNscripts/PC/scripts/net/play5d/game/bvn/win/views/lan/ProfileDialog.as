package net.play5d.game.bvn.win.views.lan
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.win.data.LanGameModel;
   import net.play5d.kyo.stage.Istage;
   import net.play5d.kyo.utils.KyoBtnUtils;
   
   public class ProfileDialog implements Istage
   {
      
      private var _ui:MovieClip;
      
      public var onClose:Function;
      
      public function ProfileDialog()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function build() : void
      {
         _ui = AssetManager.I.createObject("profile_win_mc","subswfs/win_ui.swf") as MovieClip;
         KyoBtnUtils.initBtn(_ui.btn_ok,okHandler);
         KyoBtnUtils.initBtn(_ui.btn_close,close);
         _ui.txt.text = LanGameModel.I.playerName;
      }
      
      private function okHandler() : void
      {
         var _loc1_:String = _ui.txt.text;
         if(_loc1_ == "")
         {
            GameUI.alert(GetLangText("game_ui.alert.input_name.title"),GetLangText("game_ui.alert.input_name.message"));
            return;
         }
         LanGameModel.I.playerName = _loc1_;
         GameData.I.saveData();
         close();
      }
      
      public function close() : void
      {
         MainGame.stageCtrl.removeLayer(this);
         if(onClose != null)
         {
            onClose();
         }
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         KyoBtnUtils.disposeBtn(_ui.btn_ok);
         KyoBtnUtils.disposeBtn(_ui.btn_close);
      }
   }
}

