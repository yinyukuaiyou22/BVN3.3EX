package net.play5d.game.bvn
{
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.*;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.state.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   
   public class MainGame
   {
      
      public static var UPDATE_INFO:String;
      
      public static var stageCtrl:KyoStageCtrl;
      
      public static var I:MainGame;
      
      public static const VERSION:String = "V3.3";
      
      public static const VERSION_DATE:String = "2019.3.32";
      
      private var _rootSprite:Sprite;
      
      private var _stage:Stage;
      
      private var _fps:Number = 60;
      
      public function MainGame()
      {
         super();
         I = this;
      }
      
      public function get root() : Sprite
      {
         return this._rootSprite;
      }
      
      public function get stage() : Stage
      {
         return this._stage;
      }
      
      public function initlize(param1:Sprite, param2:Stage, param3:Function = null, param4:Function = null) : void
      {
         var root:Sprite = null;
         var stage:Stage = null;
         var initBack:Function = null;
         var initFail:Function = null;
         var loadGameBack:* = undefined;
         root = param1;
         stage = param2;
         initBack = param3;
         initFail = param4;
         var resInitBack:* = function():void
         {
            GameLoger.log("res init ok");
            _rootSprite = root;
            _stage = stage;
            // 先设置初始帧率，避免stage.frameRate未初始化
            _fps = 30;
            _stage.frameRate = 30;
            GameLoger.log("init game render");
            GameRender.initlize(stage);
            GameLoger.log("init game inputer");
            GameInputer.initlize(_stage);
            GameLoger.log("init game data");
            GameData.I.loadData();
            GameLoger.log("init config");
            GameData.I.config.applyConfig();
            GameLoger.log("init inputer config");
            GameInputer.updateConfig();
            GameLoger.log("init scroll");
            root.scrollRect = new Rectangle(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
            GameLoger.log("init stagectrl");
            stageCtrl = new KyoStageCtrl(_rootSprite);
            GameLoger.log("init loading");
            var _loc1_:GameLoadingState = new GameLoadingState();
            stageCtrl.goStage(_loc1_);
            _loc1_.loadGame(loadGameBack,initFail);
         };
         loadGameBack = function():void
         {
            EffectModel.I.initlize();
            if(initBack != null)
            {
               initBack();
            }
         };
         ResUtils.I.initalize(resInitBack,initFail);
      }
      
      private function resetDefault() : void
      {
         GameCtrl.I.autoEndRoundAble = true;
         GameCtrl.I.autoStartAble = true;
         SelectFighterStage.AUTO_FINISH = true;
         LoadingState.AUTO_START_GAME = true;
      }
      
      public function getFPS() : Number
      {
         return this._fps;
      }
      
      public function setFPS(param1:Number) : void
      {
         this._fps = param1;
         this._stage.frameRate = param1;
      }
      
      public function goLogo() : void
      {
         stageCtrl.goStage(new LogoState());
         this.setFPS(30);
      }
      
      public function goMenu() : void
      {
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["go_menu_stage"])));
         this.resetDefault();
         stageCtrl.goStage(new MenuState());
         this.setFPS(30);
      }
      
      public function goHowToPlay() : void
      {
         stageCtrl.goStage(new HowToPlayState());
         this.setFPS(30);
      }
      
      public function goSelect() : void
      {
         stageCtrl.goStage(new SelectFighterStage());
         this.setFPS(30);
      }
      
      public function loadGame() : void
      {
         var _loc1_:LoadingState = new LoadingState();
         stageCtrl.goStage(_loc1_,true);
         this.setFPS(30);
      }
      
      public function goGame() : void
      {
         var _loc1_:GameState = new GameState();
         stageCtrl.goStage(_loc1_);
         GameCtrl.I.startGame();
         this.setFPS(GameConfig.FPS_GAME);
      }
      
      public function goOption() : void
      {
         stageCtrl.goStage(new SettingState());
         this.setFPS(30);
      }
      
      public function goContinue() : void
      {
         var _loc1_:GameOverState = new GameOverState();
         _loc1_.showContinue();
         stageCtrl.goStage(_loc1_);
         this.setFPS(30);
      }
      
      public function goGameOver() : void
      {
         var _loc1_:GameOverState = new GameOverState();
         _loc1_.showGameOver();
         stageCtrl.goStage(_loc1_);
         this.setFPS(30);
      }
      
      public function goWinner() : void
      {
         var _loc1_:WinnerState = new WinnerState();
         stageCtrl.goStage(_loc1_);
         this.setFPS(30);
      }
      
      public function goCredits() : void
      {
         stageCtrl.goStage(new CreditsState());
         this.setFPS(30);
      }
      
      public function moreGames() : void
      {
         GameInterface.instance.moreGames();
      }
      
      public function goCongratulations() : void
      {
         stageCtrl.goStage(new CongratulateState());
         this.setFPS(30);
      }
      
      public function submitScore() : void
      {
         GameInterface.instance.submitScore(GameData.I.score);
      }
      
      public function showRank() : void
      {
         GameInterface.instance.showRank();
      }
   }
}

