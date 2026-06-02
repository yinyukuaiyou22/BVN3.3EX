package net.play5d.game.bvn.stage
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.kyo.stage.Istage;
   
   public class LogoStage implements Istage
   {
      
      private var _ui:MovieClip;
      
      public function LogoStage()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function build() : void
      {
         _ui = AssetManager.I.createObject("logo_movie","subswfs/common_ui.swf") as MovieClip;
         _ui.addEventListener("complete",playComplete);
         _ui.gotoAndPlay(2);
      }
      
      private function playComplete(param1:Event) : void
      {
         _ui.removeEventListener("complete",playComplete);
         MainGame.I.goMenu();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         _ui.removeEventListener("complete",playComplete);
      }
   }
}

