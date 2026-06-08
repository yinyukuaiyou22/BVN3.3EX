package net.play5d.game.bvn.mob.utils
{
   import flash.display.Stage;
   import flash.events.Event;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.mob.ctrls.*;
   
   public class LockFrameLogic
   {
      
      private static var _i:LockFrameLogic;
      
      private var _mode:int;
      
      private var _stage:Stage;
      
      private var _orgFps:int;
      
      private var _orgInputMode:int;
      
      public function LockFrameLogic()
      {
         super();
      }
      
      public static function get I() : LockFrameLogic
      {
         if(!_i)
         {
            _i = new LockFrameLogic();
         }
         return _i;
      }
      
      public function initServer() : void
      {
         this._mode = 1;
         this.init(MainGame.I.stage);
      }
      
      public function initClient() : void
      {
         this._mode = 2;
         this.init(MainGame.I.stage);
      }
      
      private function init(param1:Stage) : void
      {
         this._stage = param1;
         param1.addEventListener("enterFrame",this.render);
         this._orgFps = GameConfig.FPS_GAME;
         this._orgInputMode = GameData.I.config.keyInputMode;
         GameConfig.setGameFps(30);
         GameData.I.config.keyInputMode = 1;
      }
      
      public function dispose() : void
      {
         if(Boolean(this._stage))
         {
            this._stage.removeEventListener("enterFrame",this.render);
         }
         GameRender.isRender = true;
         GameConfig.setGameFps(this._orgFps);
         GameData.I.config.keyInputMode = this._orgInputMode;
      }
      
      private function render(param1:Event) : void
      {
         if(this._mode == 1)
         {
            GameRender.isRender = LANServerCtrl.I.renderGame();
         }
         if(this._mode == 2)
         {
            GameRender.isRender = LANClientCtrl.I.renderGame();
         }
      }
   }
}

