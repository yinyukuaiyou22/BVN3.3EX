package
{
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.Capabilities;
   import net.play5d.game.bvn.Debugger;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.mob.GameInterfaceManager;
   import net.play5d.game.bvn.mob.ScreenRotater;
   import net.play5d.game.bvn.mob.ctrls.MobileCtrler;
   import net.play5d.game.bvn.mob.screenpad.ScreenPadManager;
   import net.play5d.game.bvn.mob.utils.UIAssetUtil;
   import net.play5d.game.bvn.mob.views.GameSideBg;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.ui.UIUtils;
   import net.play5d.game.bvn.ui.fight.FightUI;
   import net.play5d.game.bvn.utils.URL;
   
   public class launch extends Sprite
   {
      
      public static var STAGE:Stage;
      
      public static var I:launch;
      
      public static var FULL_SCREEN_SIZE:Point = new Point();
      
      private static const DEBUG_PANEL_ENABLED:Boolean = false;
      
      private var _mainGame:MainGame;
      
      private var _gameSprite:Sprite;
      
      private var _gameSideBg:GameSideBg;
      
      private var startupBitmap:Class = startup_png$5ab29dc3fdc04fbdd16afce6653b4bc0756872080;
      
      private var _startBitmap:Bitmap;
      
      public function launch()
      {
         super();
         I = this;
         GameConfig.TOUCH_MODE = false;
         addEventListener("addedToStage",initlize);
      }
      
      private static function isMobile() : Boolean
      {
         var version:String = Capabilities.version;
         return version.indexOf("AND") !== -1 || version.indexOf("IOS") !== -1;
      }
      
      private function initlize(param1:Event = null) : void
      {
         removeEventListener("addedToStage",initlize);
         stage.align = "TL";
         stage.scaleMode = "noScale";
         updateFullScreenSize();
         _startBitmap = new startupBitmap();
         if(DEBUG_PANEL_ENABLED && !isMobile())
         {
            _startBitmap.width = FULL_SCREEN_SIZE.x;
            _startBitmap.height = FULL_SCREEN_SIZE.y;
         }
         else
         {
            _startBitmap.width = FULL_SCREEN_SIZE.x;
            _startBitmap.height = FULL_SCREEN_SIZE.y;
            _startBitmap.rotation = 90;
            _startBitmap.x = FULL_SCREEN_SIZE.y;
         }
         addChild(_startBitmap);
         STAGE = stage;
         initGame();
      }
      
      private function initGame() : void
      {
         ScreenRotater.I.init(stage);
         stage.addEventListener("deactivate",activeHandler);
         stage.addEventListener("activate",activeHandler);
         stage.addEventListener("resize",updateFullScreenSize);
         if(_startBitmap)
         {
            try
            {
               removeChild(_startBitmap);
            }
            catch(e:Error)
            {
            }
            _startBitmap.bitmapData.dispose();
            _startBitmap = null;
         }
         stage.addEventListener("keyDown",keyHandler);
         GameInterface.instance = new GameInterfaceManager();
         GameData.I.config.AI_level = 1;
         GameData.I.config.quality = "medium";
         GameData.I.config.keyInputMode = 1;
         GameConfig.SHOW_HOW_TO_PLAY = false;
         UIUtils.LOCK_FONT = "Droid Sans Fallback";
         URL.MARK = "bvn_mobV3.3";
         ScreenPadManager.initlize(stage);
         UIAssetUtil.I.initalize(buildGame);
      }
      
      private function englishVersion() : void
      {
         GameUI.SHOW_CN_TEXT = false;
         GameInterfaceManager.ENGLISH_VERSION = true;
      }
      
      private function activeHandler(param1:Event) : void
      {
         if(param1.type == "deactivate")
         {
            MobileCtrler.I.pause();
         }
         else
         {
            MobileCtrler.I.resume();
         }
      }
      
      private function keyHandler(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == 16777238)
         {
            param1.preventDefault();
         }
      }
      
      private function buildGame() : void
      {
         _gameSprite = new Sprite();
         addChild(_gameSprite);
         _mainGame = new MainGame();
         _mainGame.initlize(_gameSprite,stage,initBackHandler,initFailHandler);
      }
      
      private function updateFullScreenSize(param1:Event = null) : void
      {
         if(DEBUG_PANEL_ENABLED && !isMobile())
         {
            FULL_SCREEN_SIZE.x = stage.fullScreenWidth;
            FULL_SCREEN_SIZE.y = stage.fullScreenHeight;
         }
         else if(stage.fullScreenWidth > stage.fullScreenHeight)
         {
            FULL_SCREEN_SIZE.x = stage.fullScreenWidth;
            FULL_SCREEN_SIZE.y = stage.fullScreenHeight;
         }
         else
         {
            FULL_SCREEN_SIZE.x = stage.fullScreenHeight;
            FULL_SCREEN_SIZE.y = stage.fullScreenWidth;
         }
      }
      
      public function updateSize() : void
      {
         var _loc4_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:Point = null;
         var _loc1_:Rectangle = null;
         if(!_gameSprite)
         {
            return;
         }
         updateFullScreenSize();
         switch(GameInterfaceManager.config.screenMode)
         {
            case 0:
               _gameSprite.scaleX = FULL_SCREEN_SIZE.x / GameConfig.GAME_SIZE.x;
               _gameSprite.scaleY = FULL_SCREEN_SIZE.y / GameConfig.GAME_SIZE.y;
               _gameSprite.x = _gameSprite.y = 0;
               if(_gameSideBg)
               {
                  _gameSideBg.destory();
                  _gameSideBg = null;
               }
               break;
            case 1:
               _loc4_ = FULL_SCREEN_SIZE.x / GameConfig.GAME_SIZE.x;
               _loc2_ = FULL_SCREEN_SIZE.y / GameConfig.GAME_SIZE.y;
               if(_loc4_ < _loc2_)
               {
                  _gameSprite.scaleX = _gameSprite.scaleY = _loc4_;
                  _gameSprite.y = (FULL_SCREEN_SIZE.y - GameConfig.GAME_SIZE.y * _loc4_) / 2;
               }
               else
               {
                  _gameSprite.scaleX = _gameSprite.scaleY = _loc2_;
                  _gameSprite.x = (FULL_SCREEN_SIZE.x - GameConfig.GAME_SIZE.x * _loc2_) / 2;
               }
               _loc3_ = FULL_SCREEN_SIZE;
               _loc1_ = new Rectangle(_gameSprite.x,_gameSprite.y,GameConfig.GAME_SIZE.x * _gameSprite.scaleX,GameConfig.GAME_SIZE.y * _gameSprite.scaleY);
               Debugger.log("resize",_loc3_,_loc1_);
               if(!_gameSideBg)
               {
                  _gameSideBg = new GameSideBg(_loc3_,_loc1_);
                  addChildAt(_gameSideBg,0);
               }
               else
               {
                  _gameSideBg.update(_loc3_,_loc1_);
               }
         }
      }
      
      public function addChildToGameSprite(param1:DisplayObject) : void
      {
         _gameSprite && _gameSprite.addChild(param1);
      }
      
      private function initBackHandler() : void
      {
         ScreenPadManager.listen();
         FightUI.QI_BAR_MODE = 1;
         if(DEBUG_PANEL_ENABLED)
         {
            Debugger.initDebug(stage);
         }
         _mainGame.goLogo();
      }
      
      private function initFailHandler(param1:String) : void
      {
      }
   }
}

