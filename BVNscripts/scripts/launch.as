package
{
   import flash.display.*;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.geom.*;
   import flash.system.*;
   import flash.desktop.NativeApplication;
   import flash.desktop.SystemIdleMode;
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
   import net.play5d.kyo.stage.events.KyoStageEvent;
   
   public class launch extends Sprite
   {
      
      public static var STAGE:Stage;
      
      public static var I:launch;
      
      public static var FULL_SCREEN_SIZE:Point = new Point();
      
      private static const DEBUG_PANEL_ENABLED:Boolean = false;
      
      private var _mainGame:MainGame;
      
      private var _gameSprite:Sprite;
      
      /**
       * 直接挂在 _gameSprite 上、不在场景栈里的覆盖层（如 SetScreenBtnView）。
       * 它们不随场景切换销毁，若不登记清理就会在切场景后继续吃掉按键（表现为键盘失效、卡在某菜单）。
       */
      private var _gameSpriteOverlays:Vector.<DisplayObject> = new Vector.<DisplayObject>();
      
      private var _gameSideBg:GameSideBg;
      
      private var startupBitmap:Class = startup_png$5ab29dc3fdc04fbdd16afce6653b4bc0756872080;
      
      private var _startBitmap:Bitmap;
      
      public function launch()
      {
         super();
         trace("=== BVN TRACE-01 launch() ===");
         I = this;
         GameConfig.TOUCH_MODE = true;
         addEventListener("addedToStage",this.initlize);
      }
      
      private static function isMobile() : Boolean
      {
         var version:String = Capabilities.version;
         return version.indexOf("AND") !== -1 || version.indexOf("IOS") !== -1;
      }
      
      private function initlize(param1:Event = null) : void
      {
         trace("=== BVN TRACE-02 initlize(stage) ===");
         removeEventListener("addedToStage",this.initlize);
         STAGE = stage;
         // 文件日志：无条件开启（不依赖调试面板），写入应用私有目录 bvn_debug.log 供 root/adb 读取
         Debugger.initFileLog(stage);
         if(DEBUG_PANEL_ENABLED) { Debugger.initDebug(stage); }
         stage.align = "TL";
         stage.scaleMode = "noScale";
         this.updateFullScreenSize();
         if(isMobile())
         {
            stage.displayState = "fullScreenInteractive";
            NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
         }
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
            this._startBitmap.rotation = 0;
            this._startBitmap.x = FULL_SCREEN_SIZE.y;
         }
         addChild(this._startBitmap);
         STAGE = stage;
         this.initGame();
      }
      
      private function initGame() : void
      {
         trace("=== BVN TRACE-03 initGame() ===");
         ScreenRotater.I.init(stage);
         stage.addEventListener("deactivate",this.activeHandler);
         stage.addEventListener("activate",this.activeHandler);
         // resize: 调用 updateSize() 而非 updateFullScreenSize(), 让 _gameSprite 按 GameConfig.GAME_SIZE(800x600) 等比缩放 + GameSideBg 侧边栏填充
         stage.addEventListener("resize",this.updateSize);
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
            Debugger.flushLogFile();
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
         trace("=== BVN TRACE-04 buildGame() ===");
         this._gameSprite = new Sprite();
         addChild(this._gameSprite);
         this._mainGame = new MainGame();
         this._mainGame.initlize(this._gameSprite,stage,this.initBackHandler,this.initFailHandler);
         // buildGame 后立即缩放一次: PC 端启动时窗口是 800x600(未最大化), 必须主动触发等比缩放
         // 否则在用户进入『设置』面板之前, _gameSprite 一直保持 scaleX=1 原始大小
         this.updateSize();
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
      
      public function updateSize(param1:Event = null) : void
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
         if(Boolean(param1) && Boolean(this._gameSprite) && this._gameSpriteOverlays.indexOf(param1) == -1)
         {
            this._gameSpriteOverlays.push(param1);
         }
      }
      
      /**
       * 场景切换时清掉所有遗留的 _gameSprite 覆盖层。
       * SetScreenBtnView 走 closeSelf()，以注销它的 SetBtnGroup（输入仲裁栈 / GameRender 注册）；
       * 其余对象直接摘除。
       */
      public function clearGameSpriteOverlays() : void
      {
         var _loc1_:int = int(this._gameSpriteOverlays.length);
         if(_loc1_ > 0)
         {
            Debugger.log("[launch] clearGameSpriteOverlays n=",_loc1_);
         }
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_)
         {
            var _loc3_:DisplayObject = this._gameSpriteOverlays[_loc2_];
            try
            {
               if(_loc3_ is SetScreenBtnView)
               {
                  (_loc3_ as SetScreenBtnView).closeSelf();
               }
               else if(Boolean(_loc3_.parent))
               {
                  _loc3_.parent.removeChild(_loc3_);
               }
            }
            catch(e:Error)
            {
               Debugger.log("[launch] clearGameSpriteOverlays:",e);
            }
            _loc2_++;
         }
         this._gameSpriteOverlays.length = 0;
      }
      
      private function onStageChange(param1:KyoStageEvent) : void
      {
         this.clearGameSpriteOverlays();
         // 把本场景累积的折叠日志（资源探测/选中态/按键边沿…）汇总输出，每组一行
         Debugger.flushFold();
      }
      
      private function initBackHandler() : void
      {
         trace("=== BVN TRACE-05 initBackHandler(LOAD COMPLETE) ===");
         ScreenPadManager.listen();
         FightUI.QI_BAR_MODE = 1;
         // 覆盖层随场景切换清理：KyoStageCtrl.goStage 是唯一的场景切换必经点，会在新场景 build 后派发该事件
         MainGame.stageCtrl.addEventListener(KyoStageEvent.CHANGE_STATE,this.onStageChange);
         // 启动装载阶段（外部资源探测刷屏最密集）刚结束，先把折叠日志汇总输出一次
         Debugger.flushFold();
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

