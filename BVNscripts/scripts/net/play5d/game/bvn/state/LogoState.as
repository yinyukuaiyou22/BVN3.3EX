package net.play5d.game.bvn.state
{
   import flash.display.DisplayObject;
   import flash.events.Event;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   
   public class LogoState implements Istage
   {
      
      private var _ui:*;
      
      public function LogoState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.common_ui,"logo_movie");
         this._ui.addEventListener("complete",this.playComplete);
         this._ui.gotoAndPlay(2);
      }
      
      private function playComplete(param1:Event) : void
      {
         this._ui.removeEventListener("complete",this.playComplete);
         MainGame.I.goMenu();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         this._ui.removeEventListener("complete",this.playComplete);
      }
   }
}

