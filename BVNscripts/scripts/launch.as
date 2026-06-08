package
{
   import flash.display.*;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.geom.*;
   import flash.system.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.mob.*;
   import net.play5d.game.bvn.mob.ctrls.*;
   import net.play5d.game.bvn.mob.screenpad.*;
   import net.play5d.game.bvn.mob.utils.*;
   import net.play5d.game.bvn.mob.views.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.ui.fight.*;
   import net.play5d.game.bvn.utils.*;
   
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
         addEventListener("addedToStage",this.initlize);
      }
      
      private static function isMobile() : Boolean
      {
         var version:String = Capabilities.version;
         return version.indexOf("AND") !== -1 || version.indexOf("IOS") !== -1;
      }
      
      private function initlize(param1:Event = null) : void
      {
         removeEventListener("addedToStage",this.initlize);
         stage.align = "TL";
         stage.scaleMode = "noScale";
         this.updateFullScreenSize();
         this._startBitmap = new this.startupBitmap();
         if(Boolean(DEBUG_PANEL_ENABLED) && !isMobile())
         {
            this._startBitmap.width = FULL_SCREEN_SIZE.x;
            this._startBitmap.height = FULL_SCREEN_SIZE.y;
         }
         else
         {
            this._startBitmap.width = FULL_SCREEN_SIZE.x;
            this._startBitmap.height = FULL_SCREEN_SIZE.y;
            this._startBitmap.rotation = 90;
            this._startBitmap.x = FULL_SCREEN_SIZE.y;
         }
         addChild(this._startBitmap);
         STAGE = stage;
         this.initGame();
      }
      
      private function initGame() : void
      {
         ScreenRotater.I.init(stage);
         stage.addEventListener("deactivate",this.activeHandler);
         stage.addEventListener("activate",this.activeHandler);
         stage.addEventListener("resize",this.updateFullScreenSize);
         if(Boolean(this._startBitmap))
         {
            try
            {
               removeChild(this._startBitmap);
            }
            catch(e:Error)
            {
            }
            this._startBitmap.bitmapData.dispose();
            this._startBitmap = null;
         }
         stage.addEventListener("keyDown",this.keyHandler);
         GameInterface.instance = new GameInterfaceManager();
         GameData.I.config.AI_level = 1;
         GameData.I.config.quality = "medium";
         GameData.I.config.keyInputMode = 1;
         GameConfig.SHOW_HOW_TO_PLAY = false;
         UIUtils.LOCK_FONT = "Droid Sans Fallback";
         URL.MARK = "bvn_mobV3.3";
         ScreenPadManager.initlize(stage);
         UIAssetUtil.I.initalize(this.buildGame);
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
         this._gameSprite = new Sprite();
         addChild(this._gameSprite);
         this._mainGame = new MainGame();
         this._mainGame.initlize(this._gameSprite,stage,this.initBackHandler,this.initFailHandler);
      }
      
      private function updateFullScreenSize(param1:Event = null) : void
      {
         if(Boolean(DEBUG_PANEL_ENABLED) && !isMobile())
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
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:Point = null;
         var _loc4_:Rectangle = null;
         if(!this._gameSprite)
         {
            return;
         }
         this.updateFullScreenSize();
         switch(GameInterfaceManager.config.screenMode)
         {
            case 0:
               this._gameSprite.scaleX = FULL_SCREEN_SIZE.x / GameConfig.GAME_SIZE.x;
               this._gameSprite.scaleY = FULL_SCREEN_SIZE.y / GameConfig.GAME_SIZE.y;
               this._gameSprite.x = this._gameSprite.y = 0;
               if(Boolean(this._gameSideBg))
               {
                  this._gameSideBg.destory();
                  this._gameSideBg = null;
               }
               break;
            case 1:
               _loc1_ = FULL_SCREEN_SIZE.x / GameConfig.GAME_SIZE.x;
               _loc2_ = FULL_SCREEN_SIZE.y / GameConfig.GAME_SIZE.y;
               if(_loc1_ < _loc2_)
               {
                  this._gameSprite.scaleX = this._gameSprite.scaleY = _loc1_;
                  this._gameSprite.y = (FULL_SCREEN_SIZE.y - GameConfig.GAME_SIZE.y * _loc1_) / 2;
               }
               else
               {
                  this._gameSprite.scaleX = this._gameSprite.scaleY = _loc2_;
                  this._gameSprite.x = (FULL_SCREEN_SIZE.x - GameConfig.GAME_SIZE.x * _loc2_) / 2;
               }
               _loc3_ = FULL_SCREEN_SIZE;
               _loc4_ = new Rectangle(this._gameSprite.x,this._gameSprite.y,GameConfig.GAME_SIZE.x * this._gameSprite.scaleX,GameConfig.GAME_SIZE.y * this._gameSprite.scaleY);
               Debugger.log("resize",_loc3_,_loc4_);
               if(!this._gameSideBg)
               {
                  this._gameSideBg = new GameSideBg(_loc3_,_loc4_);
                  addChildAt(this._gameSideBg,0);
               }
               else
               {
                  this._gameSideBg.update(_loc3_,_loc4_);
               }
         }
      }
      
      public function addChildToGameSprite(param1:DisplayObject) : void
      {
         this._gameSprite && this._gameSprite.addChild(param1);
      }
      
      private function initBackHandler() : void
      {
         ScreenPadManager.listen();
         FightUI.QI_BAR_MODE = 1;
         if(DEBUG_PANEL_ENABLED)
         {
            Debugger.initDebug(stage);
         }
         this._mainGame.goLogo();
      }
      
      private function initFailHandler(param1:String) : void
      {
      }
   }
}

