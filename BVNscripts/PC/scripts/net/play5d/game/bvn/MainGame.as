package net.play5d.game.bvn
{
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.EffectModel;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.stage.CongratulateStage;
   import net.play5d.game.bvn.stage.GameLoadingStage;
   import net.play5d.game.bvn.stage.GameOverStage;
   import net.play5d.game.bvn.stage.GameStage;
   import net.play5d.game.bvn.stage.HowToPlayStage;
   import net.play5d.game.bvn.stage.LoadingMosouStage;
   import net.play5d.game.bvn.stage.LoadingStage;
   import net.play5d.game.bvn.stage.LogoStage;
   import net.play5d.game.bvn.stage.MenuStage;
   import net.play5d.game.bvn.stage.RuleStage;
   import net.play5d.game.bvn.stage.SelectFighterStage;
   import net.play5d.game.bvn.stage.SettingStage;
   import net.play5d.game.bvn.stage.StaffStage;
   import net.play5d.game.bvn.stage.WinnerStage;
   import net.play5d.game.bvn.stage.WorldMapStage;
   import net.play5d.game.bvn.utils.GameLoger;
   import net.play5d.game.bvn.utils.ResUtils;
   import net.play5d.game.bvn.utils.TouchUtils;
   import net.play5d.kyo.stage.KyoStageCtrl;
   import net.play5d.kyo.utils.KyoTimeout;
   
   public class MainGame
   {
      
      public static var UPDATE_INFO:String;
      
      public static var stageCtrl:KyoStageCtrl;
      
      public static var I:MainGame;
      
      public var VERSION:String;
      
      public var VERSION_DATE:String = "1970.01.01";
      
      private var _rootSprite:Sprite;
      
      private var _stage:Stage;
      
      private var _fps:int = 60;
      
      private var _quality:String = null;
      
      public function MainGame()
      {
         super();
         VERSION = GetLangText("stage_menu.version_release");
         I = this;
      }
      
      private static function resetDefault() : void
      {
         GameCtrl.I.autoEndRoundAble = true;
         GameCtrl.I.autoStartAble = true;
         SelectFighterStage.AUTO_FINISH = true;
         LoadingStage.AUTO_START_GAME = true;
      }
      
      public function get root() : Sprite
      {
         return _rootSprite;
      }
      
      public function get stage() : Stage
      {
         return _stage;
      }
      
      public function initialize(param1:Sprite, param2:Stage, param3:Function = null, param4:Function = null) : void
      {
         var root:Sprite = param1;
         var stage:Stage = param2;
         var initBack:Function = param3;
         var initFail:Function = param4;
         var resInitBack:* = function():void
         {
            AssetManager.I.init(initNext);
         };
         var initNext:* = function():void
         {
            GameLoger.log("游戏资源初始化成功！");
            _rootSprite = root;
            _stage = stage;
            GameLoger.log("正在初始化游戏渲染器。。。");
            GameRender.initlize(stage);
            GameLoger.log("正在初始化游戏输入控制器。。。");
            GameInputer.initlize(_stage);
            GameLoger.log("正在初始化平面卷轴系统。。。");
            root.scrollRect = new Rectangle(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
            GameLoger.log("正在初始化 stageCtrl 控制器。。。");
            stageCtrl = new KyoStageCtrl(_rootSprite);
            GameLoger.log("正在初始化游戏加载场景。。。");
            var _loc1_:GameLoadingStage = new GameLoadingStage();
            stageCtrl.goStage(_loc1_);
            _loc1_.loadGame(loadGameBack,initFail);
         };
         var loadGameBack:* = function():void
         {
            GameLoger.log("正在初始化游戏数据！");
            GameData.I.initData();
            GameLoger.log("正在初始化游戏配置");
            GameData.I.config.applyConfig();
            GameLoger.log("正在初始化游戏控制器配置。。。");
            GameInputer.updateConfig();
            EffectModel.I.initlize();
            GameEvent.dispatchEvent("LOAD_GAME_COMPLETE");
            if(initBack != null)
            {
               initBack();
            }
         };
         ResUtils.I.initalize(resInitBack,initFail);
         KyoTimeout.init(root);
         if(GameConfig.TOUCH_MODE)
         {
            TouchUtils.I.init(stage);
         }
      }
      
      public function getFPS() : int
      {
         return _fps;
      }
      
      public function setFPS(param1:int) : void
      {
         _fps = param1;
         _stage.frameRate = int(GameConfig.IS_LOW_QUALITY ? 30 : param1);
      }
      
      public function setQuality(param1:String) : void
      {
         if(_quality == param1)
         {
            return;
         }
         _quality = param1;
         _stage.quality = param1;
      }
      
      public function goLogo() : void
      {
         stageCtrl.goStage(new LogoStage());
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",LogoStage);
      }
      
      public function goMenu() : void
      {
         resetDefault();
         stageCtrl.goStage(new MenuStage());
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",MenuStage);
      }
      
      public function goHowToPlay() : void
      {
         stageCtrl.goStage(new HowToPlayStage());
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",HowToPlayStage);
      }
      
      public function goSelect() : void
      {
         stageCtrl.goStage(new SelectFighterStage(),true);
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",SelectFighterStage);
      }
      
      public function loadGame() : void
      {
         if(GameMode.currentMode == 100)
         {
            stageCtrl.goStage(new LoadingMosouStage(),true);
            GameEvent.dispatchEvent("ENTER_STAGE",LoadingMosouStage);
         }
         else
         {
            stageCtrl.goStage(new LoadingStage(),true);
            GameEvent.dispatchEvent("ENTER_STAGE",LoadingStage);
         }
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
      }
      
      public function goGame() : void
      {
         var _loc1_:GameStage = new GameStage();
         stageCtrl.goStage(_loc1_);
         GameCtrl.I.startGame();
         setFPS(GameConfig.FPS_GAME);
         setQuality(GameConfig.QUALITY_GAME);
         GameEvent.dispatchEvent("ENTER_STAGE",GameStage);
      }
      
      public function goMosouGame() : void
      {
         var _loc1_:GameStage = new GameStage();
         stageCtrl.goStage(_loc1_);
         GameCtrl.I.startMosouGame();
         setFPS(GameConfig.FPS_GAME);
         setQuality(GameConfig.QUALITY_GAME);
         GameEvent.dispatchEvent("ENTER_STAGE",GameStage);
      }
      
      public function goOption() : void
      {
         stageCtrl.goStage(new SettingStage());
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",SettingStage);
      }
      
      public function goRule() : void
      {
         stageCtrl.goStage(new RuleStage());
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",RuleStage);
      }
      
      public function goContinue() : void
      {
         var _loc1_:GameOverStage = new GameOverStage();
         _loc1_.showContinue();
         stageCtrl.goStage(_loc1_);
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",GameOverStage);
      }
      
      public function goGameOver() : void
      {
         var _loc1_:GameOverStage = new GameOverStage();
         _loc1_.showGameOver();
         stageCtrl.goStage(_loc1_);
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",GameOverStage);
      }
      
      public function goWinner() : void
      {
         var _loc1_:WinnerStage = new WinnerStage();
         stageCtrl.goStage(_loc1_);
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",WinnerStage);
      }
      
      public function goStaff() : void
      {
         stageCtrl.goStage(new StaffStage());
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",StaffStage);
      }
      
      public function goCongratulations() : void
      {
         stageCtrl.goStage(new CongratulateStage());
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
      }
      
      public function goWorldMap() : void
      {
         stageCtrl.goStage(new WorldMapStage());
         setFPS(30);
         setQuality(GameConfig.QUALITY_UI);
         GameEvent.dispatchEvent("ENTER_STAGE",WorldMapStage);
      }
   }
}

