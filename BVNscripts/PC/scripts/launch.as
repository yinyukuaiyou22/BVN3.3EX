package
{
   import flash.desktop.NativeApplication;
   import flash.display.DisplayObject;
   import flash.display.NativeWindow;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.InvokeEvent;
   import flash.events.KeyboardEvent;
   import flash.system.Capabilities;
   import flash.system.IME;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.utils.GameLoger;
   import net.play5d.game.bvn.win.GameInterfaceManager;
   import net.play5d.game.bvn.win.utils.Loger;
   import net.play5d.game.bvn.win.utils.MenuUtils;
   import net.play5d.game.bvn.win.utils.MultiLangUtils;
   import net.play5d.game.bvn.win.utils.UIAssetUtils;
   import net.play5d.game.bvn.win.utils.UpdateUtils;
   import net.play5d.game.bvn.win.views.Watermark;
   import net.play5d.patchouli.utils.ClassUtil;
   
   public class launch extends Sprite
   {
      
      (function():void
      {
         var MODE_DEBUG:Boolean = (function():Boolean
         {
            return false;
         })();
         var MODE_RELEASE:Boolean = (function():Boolean
         {
            return true;
         })();
         if(MODE_DEBUG == MODE_RELEASE)
         {
            throw new Error("只能是 DEBUG 模式或者 RELEASE 模式！请检查编译参数！");
         }
         GetGameClass("");
      })();
      
      private var _mainGame:MainGame;
      
      private var _isDeactivated:Boolean = false;
      
      public function launch()
      {
         super();
         if(stage)
         {
            initialize();
         }
         else
         {
            addEventListener("addedToStage",initialize);
         }
      }
      
      private static function initFailHandler(param1:String) : void
      {
         GameLoger.log("初始化失败！" + param1);
      }
      
      private function initialize(param1:Event = null) : void
      {
         removeEventListener("addedToStage",initialize);
         relocationWindow();
         if(Capabilities.hasIME && IME.isSupported && IME.enabled)
         {
            try
            {
               if(IME.conversionMode != "ALPHANUMERIC_HALF")
               {
                  IME.conversionMode = "ALPHANUMERIC_HALF";
               }
            }
            catch(e:Error)
            {
            }
            IME.enabled = false;
         }
         NativeApplication.nativeApplication.addEventListener("invoke",onInvoke);
      }
      
      private function relocationWindow() : void
      {
         var _loc1_:NativeWindow = stage.nativeWindow;
         var _loc5_:Number = Capabilities.screenResolutionX;
         var _loc4_:Number = Capabilities.screenResolutionY;
         var _loc2_:Number = Number(_loc1_.width);
         var _loc3_:Number = Number(_loc1_.height);
         _loc1_.x = (_loc5_ - _loc2_) * 0.5;
         _loc1_.y = (_loc4_ - _loc3_) * 0.5;
      }
      
      private function next() : void
      {
         var nextBuild:* = function():void
         {
            switch(step)
            {
               case 0:
                  step = 1;
                  UpdateUtils.I.initialize(nextBuild);
                  break;
               case 1:
                  step = 2;
                  stage.nativeWindow.title = GetLangText("system.game_title");
                  stage.nativeWindow.title += " - " + UpdateUtils.I.version;
                  MenuUtils.I.initialize(stage);
                  GameLoger.setLoger(new Loger());
                  GameLoger.log("初始化中。。。");
                  GameInterface.instance = new GameInterfaceManager();
                  GameUI.BITMAP_UI = true;
                  GameData.releaseSaveData(true);
                  buildGame();
                  Debugger.initDebug(stage,$this);
            }
         };
         var step:int = 0;
         var $this:Sprite = this;
         MultiLangUtils.I.initialize(nextBuild);
      }
      
      private function onInvoke(param1:InvokeEvent) : void
      {
         NativeApplication.nativeApplication.removeEventListener("invoke",onInvoke);
         var _loc2_:Array = param1.arguments;
         if(_loc2_.length > 0 && _loc2_.indexOf("no_quick") != -1)
         {
            GameConfig.IS_QUICK_LOAD = false;
         }
         next();
      }
      
      private function buildGame() : void
      {
         GameLoger.log("正在构建游戏。。。");
         _mainGame = new MainGame();
         _mainGame.initialize(this,stage,initBackHandler,initFailHandler);
         stage.addEventListener("keyDown",keyDownHandler);
         stage.addEventListener("deactivate",activeHandler);
         stage.addEventListener("activate",activeHandler);
      }
      
      private function initBackHandler() : void
      {
         var _loc1_:Watermark = null;
         var _loc2_:String = null;
         GameLoger.log("初始化完成！");
         UIAssetUtils.I.initalize(stage,_mainGame.goLogo);
         if(MainGame.I.VERSION.indexOf("概念") != -1)
         {
            _loc1_ = new Watermark();
            stage.addChild(_loc1_);
            _loc2_ = "你的下一句话是————我是黑客，我发现了水印的代码！于是我是时候该将其去掉了！";
         }
      }
      
      private function keyDownHandler(param1:KeyboardEvent) : void
      {
         var e:KeyboardEvent = param1;
         switch(e.keyCode)
         {
            case 27:
               e.preventDefault();
               break;
            case 112:
               (function():void
               {
                  var _loc1_:FighterMain = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter as FighterMain;
                  var _loc2_:FighterMain = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter as FighterMain;
                  if(_loc1_ == null || _loc2_ == null || GameMode.currentMode != 40)
                  {
                     return;
                  }
                  GameConfig.IS_SINGLE_STEP = !GameConfig.IS_SINGLE_STEP;
               })();
               break;
            case 113:
               (function():void
               {
                  if(GameConfig.IS_SINGLE_STEP)
                  {
                     GameRender.render();
                  }
               })();
               break;
            case 114:
               (function():void
               {
                  var _loc1_:DisplayObject = ClassUtil.continuousAccess(GameCtrl.I,["gameState","gameUI","getUIDisplay()"]) as DisplayObject;
                  if(_loc1_ == null)
                  {
                     return;
                  }
                  _loc1_.visible = !_loc1_.visible;
               })();
               break;
            case 115:
               (function():void
               {
               })();
               break;
            case 122:
               if(stage.displayState == "normal")
               {
                  stage.displayState = "fullScreenInteractive";
               }
               else
               {
                  stage.displayState = "normal";
               }
               break;
            case 18:
               MenuUtils.I.showMenu();
         }
      }
      
      private function activeHandler(param1:Event) : void
      {
         MenuUtils.I.hiddenMenu();
         if(param1.type == "deactivate" && !_isDeactivated)
         {
            _isDeactivated = true;
            SoundCtrl.I.setSoundVolumn(0);
            SoundCtrl.I.setBgmVolumn(0);
         }
         else if(param1.type == "activate" && _isDeactivated)
         {
            _isDeactivated = false;
            SoundCtrl.I.setSoundVolumn(GameData.I.config.soundVolume);
            SoundCtrl.I.setBgmVolumn(GameData.I.config.bgmVolume);
         }
         GameConfig.IS_WIN_ACTIVATE = !_isDeactivated;
      }
      
      private function onWindowClosing(param1:Event) : void
      {
         if(GameData.I.record.uploadRecord(1,true))
         {
            param1.preventDefault();
            stage.nativeWindow.removeEventListener("closing",onWindowClosing);
            GameUI.alert("UPLOADING","<仅测试版>\n对局数据自动上传中，上传完成后会自动关闭游戏。");
         }
      }
   }
}

