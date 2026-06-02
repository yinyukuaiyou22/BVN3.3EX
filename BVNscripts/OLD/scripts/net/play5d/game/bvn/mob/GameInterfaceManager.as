package net.play5d.game.bvn.mob
{
   import flash.desktop.NativeApplication;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.filesystem.File;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import net.play5d.game.bvn.Debugger;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.ConfigVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.MessionModel;
   import net.play5d.game.bvn.input.IGameInput;
   import net.play5d.game.bvn.interfaces.IExtendConfig;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   import net.play5d.game.bvn.interfaces.IGameInterface;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.mob.ctrls.LANClientCtrl;
   import net.play5d.game.bvn.mob.ctrls.LANServerCtrl;
   import net.play5d.game.bvn.mob.data.ExtendConfig;
   import net.play5d.game.bvn.mob.data.ScreenPadConfigVO;
   import net.play5d.game.bvn.mob.input.InputManager;
   import net.play5d.game.bvn.mob.screenpad.ScreenPadManager;
   import net.play5d.game.bvn.mob.utils.AdManager;
   import net.play5d.game.bvn.mob.utils.FileUtils;
   import net.play5d.game.bvn.mob.views.ViewManager;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.utils.URL;
   
   public class GameInterfaceManager implements IGameInterface
   {
      
      public static var ENGLISH_VERSION:Boolean = false;
      
      private static var _extendsConfig:ExtendConfig = new ExtendConfig();
      
      public function GameInterfaceManager()
      {
         super();
      }
      
      public static function get config() : ExtendConfig
      {
         return _extendsConfig;
      }
      
      public function initTitleUI(param1:DisplayObject) : void
      {
      }
      
      public function moreGames() : void
      {
         AdManager.I.showVideoAd();
      }
      
      public function submitScore(param1:int) : void
      {
      }
      
      public function showRank() : void
      {
      }
      
      public function saveGame(param1:Object) : void
      {
         var _loc2_:String = JSON.stringify(param1);
         var _loc3_:File = File.applicationStorageDirectory.resolvePath("bvnsave.sav");
         FileUtils.writeFile(_loc3_.nativePath,_loc2_);
         Debugger.log("saveData",_loc2_);
      }
      
      public function loadGame() : Object
      {
         var _loc2_:File = File.applicationStorageDirectory.resolvePath("bvnsave.sav");
         var _loc1_:String = FileUtils.readTextFile(_loc2_.nativePath);
         if(!_loc1_)
         {
            return null;
         }
         return JSON.parse(_loc1_);
      }
      
      public function getFighterCtrl(param1:int) : IFighterActionCtrl
      {
         return null;
      }
      
      public function getGameMenu() : Array
      {
         return [{
            "txt":"ARCADE",
            "cn":"闯关",
            "children":[{
               "txt":"Single Arcade",
               "cn":"单人闯关",
               "func":function():void
               {
                  GameMode.currentMode = 20;
                  MessionModel.I.reset();
                  MainGame.I.goSelect();
               }
            },{
               "txt":"Team Arcade",
               "cn":"小队闯关",
               "func":function():void
               {
                  GameMode.currentMode = 10;
                  MessionModel.I.reset();
                  MainGame.I.goSelect();
               }
            }]
         },{
            "txt":"VS CPU",
            "cn":"对战人机",
            "children":[{
               "txt":"SINGLE MODE",
               "cn":"单人模式",
               "func":function():void
               {
                  GameMode.currentMode = 22;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"Team Mode",
               "cn":"小队模式"
            }]
         },{
            "txt":"2P VS",
            "cn":"玩家对战",
            "children":[{
               "txt":"SINGLE VS",
               "cn":"单人对战",
               "func":function():void
               {
                  GameMode.currentMode = 21;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"TEAM VS",
               "cn":"小队对战",
               "func":function():void
               {
                  GameMode.currentMode = 11;
                  MainGame.I.goSelect();
               }
            }]
         },{
            "txt":"WATCHMODE",
            "cn":"观战模式",
            "children":[{
               "txt":"SINGLE WATCH",
               "cn":"单人观战",
               "func":function():void
               {
                  GameMode.currentMode = 23;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"Team Watch",
               "cn":"小队观战",
               "func":function():void
               {
                  GameMode.currentMode = 13;
                  MainGame.I.goSelect();
               }
            }]
         },{
            "txt":"OPTION",
            "cn":"设置"
         },{
            "txt":"TRAINING",
            "cn":"练习"
         },{
            "txt":"EXIT GAME",
            "cn":"退出",
            "func":function():void
            {
               GameUI.confrim("EXIT GAME","是否退出?",NativeApplication.nativeApplication.exit);
            }
         }];
      }
      
      public function getSettingMenu() : Array
      {
         return [{
            "txt":"Joystick Setting",
            "cn":"设置按钮",
            "select":ViewManager.I.setScreenBtns
         },{
            "txt":"Keyboard Input",
            "cn":"键盘输入",
            "options":[{
               "label":"ON",
               "cn":"开启",
               "value":true
            },{
               "label":"OFF",
               "cn":"关闭",
               "value":false
            }],
            "optoinKey":"ENABLE_KEYBOARD"
         },{
            "txt":"How To Play",
            "cn":"如何操作",
            "select":MainGame.I.goHowToPlay
         },{
            "txt":"AI Level",
            "cn":"难度",
            "options":[{
               "label":"VERY EASY",
               "cn":"非常简单",
               "value":1
            },{
               "label":"EASY",
               "cn":"简单",
               "value":2
            },{
               "label":"NORMAL",
               "cn":"正常",
               "value":3
            },{
               "label":"HARD",
               "cn":"困难",
               "value":4
            },{
               "label":"VERY HARD",
               "cn":"非常困难",
               "value":5
            },{
               "label":"HELL",
               "cn":"地狱",
               "value":6
            },{
               "label":"CRAZY",
               "cn":"疯狂",
               "value":7
            }],
            "optoinKey":"AI_level"
         },{
            "txt":"Life Point",
            "cn":"血量",
            "options":[{
               "label":"50%",
               "cn":"50%",
               "value":0.5
            },{
               "label":"100%",
               "cn":"100%",
               "value":1
            },{
               "label":"200%",
               "cn":"200%",
               "value":2
            },{
               "label":"300%",
               "cn":"300%",
               "value":3
            },{
               "label":"500%",
               "cn":"500%",
               "value":5
            },{
               "label":"600%",
               "cn":"600%",
               "value":6
            },{
               "label":"700%",
               "cn":"700%",
               "value":7
            },{
               "label":"1000%",
               "cn":"1000%",
               "value":10
            },{
               "label":"2000%",
               "cn":"2000%",
               "value":20
            },{},{
               "label":"9999%",
               "cn":"9999%",
               "value":99
            }],
            "optoinKey":"fighterHP"
         },{
            "txt":"Time Set",
            "cn":"时间",
            "options":[{
               "label":"30s",
               "cn":"30d",
               "value":30
            },{
               "label":"60s",
               "cn":"60d",
               "value":60
            },{
               "label":"90s",
               "cn":"90d",
               "value":90
            },{
               "label":"120s",
               "cn":"120d",
               "value":120
            },{
               "label":"∞",
               "cn":"Infinity",
               "value":-1
            }],
            "optoinKey":"fightTime"
         },{
            "txt":"Sound Set",
            "cn":"声音",
            "options":[{
               "label":"0%",
               "cn":"0%",
               "value":0
            },{
               "label":"10%",
               "cn":"10%",
               "value":0.1
            },{
               "label":"30%",
               "cn":"30%",
               "value":0.3
            },{
               "label":"50%",
               "cn":"50%",
               "value":0.5
            },{
               "label":"70%",
               "cn":"70%",
               "value":0.7
            },{
               "label":"100%",
               "cn":"100%",
               "value":1
            }],
            "optoinKey":"soundVolume"
         },{
            "txt":"BGM Set",
            "cn":"背景音乐",
            "options":[{
               "label":"0%",
               "cn":"0%",
               "value":0
            },{
               "label":"10%",
               "cn":"10%",
               "value":0.1
            },{
               "label":"30%",
               "cn":"30%",
               "value":0.3
            },{
               "label":"50%",
               "cn":"50%",
               "value":0.5
            },{
               "label":"70%",
               "cn":"70%",
               "value":0.7
            },{
               "label":"100%",
               "cn":"100%",
               "value":1
            }],
            "optoinKey":"bgmVolume"
         },{
            "txt":"Screen Mode",
            "cn":"屏幕模式",
            "options":[{
               "label":"Fill",
               "cn":"填充",
               "value":0
            },{
               "label":"Center",
               "cn":"中心",
               "value":1
            }],
            "optoinKey":"screenMode"
         },{
            "txt":"GAME FPS",
            "cn":"游戏帧率",
            "options":[{
               "label":"30",
               "cn":"30帧",
               "value":"low"
            },{
               "label":"60",
               "cn":"60帧",
               "value":""
            },{
               "label":"90",
               "cn":"90帧",
               "value":"high"
            },{
               "label":"120",
               "cn":"120帧",
               "value":"best"
            }],
            "optoinKey":"quality"
         },{
            "txt":"Infinite Energy",
            "cn":"无限气",
            "options":[{
               "label":"OFF",
               "cn":"关",
               "value":false
            },{
               "label":"ON",
               "cn":"开",
               "value":true
            }],
            "optoinKey":"INFINITE_ENERGY"
         }];
      }
      
      public function getGameInput(param1:String) : Vector.<IGameInput>
      {
         var _loc2_:Vector.<IGameInput> = new Vector.<IGameInput>();
         switch(param1)
         {
            case "MENU":
               _loc2_.push(InputManager.I.key_menu);
               _loc2_.push(InputManager.I.screen_menu);
               _loc2_.push(InputManager.I.joy_menu);
               break;
            case "P1":
               _loc2_.push(InputManager.I.key_p1);
               _loc2_.push(InputManager.I.screen_p1);
               _loc2_.push(InputManager.I.joy_p1);
               _loc2_.push(InputManager.I.socket_input_p1);
               break;
            case "P2":
               _loc2_.push(InputManager.I.key_p2);
               _loc2_.push(InputManager.I.socket_input_p2);
               break;
            default:
               return null;
         }
         return _loc2_;
      }
      
      public function getConfigExtend() : IExtendConfig
      {
         return _extendsConfig;
      }
      
      public function afterBuildGame() : void
      {
         var _loc1_:MapMain = GameCtrl.I.gameState.getMap();
         if(_loc1_.mapLayer)
         {
            _loc1_.mapLayer.cacheAsBitmapMatrix = new Matrix();
         }
         if(_loc1_.frontLayer)
         {
            _loc1_.frontLayer.cacheAsBitmapMatrix = new Matrix();
         }
         if(_loc1_.frontFixLayer)
         {
            _loc1_.frontFixLayer.cacheAsBitmapMatrix = new Matrix();
         }
         if(_loc1_.bgLayer)
         {
            _loc1_.bgLayer.cacheAsBitmap = true;
         }
      }
      
      public function updateInputConfig() : Boolean
      {
         var keyEnabled:Boolean = _extendsConfig.ENABLE_KEYBOARD;
         InputManager.I.key_menu.enabled = keyEnabled;
         InputManager.I.key_p1.enabled = keyEnabled;
         InputManager.I.key_p2.enabled = keyEnabled;
         InputManager.I.key_menu.setConfig(GameData.I.config.key_menu);
         InputManager.I.key_p1.setConfig(GameData.I.config.key_p1);
         InputManager.I.key_p2.setConfig(GameData.I.config.key_p2);
         if(LANServerCtrl.I.active || LANClientCtrl.I.active)
         {
            InputManager.I.key_menu.enabled = false;
            InputManager.I.key_p1.enabled = false;
            InputManager.I.key_p2.enabled = false;
            InputManager.I.screen_menu.enabled = false;
            InputManager.I.screen_p1.enabled = false;
            InputManager.I.joy_menu.enabled = false;
            InputManager.I.joy_p1.enabled = false;
            InputManager.I.socket_input_p1.enabled = true;
            InputManager.I.socket_input_p2.enabled = true;
            if(LANServerCtrl.I.active)
            {
               InputManager.I.socket_input_p1.setInputers([InputManager.I.screen_p1,InputManager.I.joy_p1]);
            }
            if(LANClientCtrl.I.active)
            {
               InputManager.I.socket_input_p2.setInputers([InputManager.I.screen_p1,InputManager.I.joy_p1]);
            }
            return true;
         }
         InputManager.I.joy_menu.setConfig(_extendsConfig.joyMenuConfig);
         InputManager.I.joy_p1.setConfig(_extendsConfig.joy1Config);
         InputManager.I.socket_input_p1.enabled = false;
         InputManager.I.socket_input_p2.enabled = false;
         InputManager.I.joy_menu.enabled = true;
         InputManager.I.joy_p1.enabled = true;
         return true;
      }
      
      public function applyConfig(param1:ConfigVO) : void
      {
         Debugger.log("=== [DEBUG] applyConfig called ===");
         switch(param1.quality)
         {
            case "best":
               GameConfig.setGameFps(120);
               GameConfig.FPS_SHINE_EFFECT = 15;
               EffectCtrl.EFFECT_SMOOTHING = true;
               EffectCtrl.SHADOW_ENABLED = true;
               EffectCtrl.SHAKE_ENABLED = true;
               break;
            case "high":
               GameConfig.setGameFps(90);
               GameConfig.FPS_SHINE_EFFECT = 15;
               EffectCtrl.EFFECT_SMOOTHING = true;
               EffectCtrl.SHADOW_ENABLED = true;
               EffectCtrl.SHAKE_ENABLED = true;
               break;
            case "medium":
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 10;
               EffectCtrl.EFFECT_SMOOTHING = true;
               EffectCtrl.SHADOW_ENABLED = true;
               EffectCtrl.SHAKE_ENABLED = true;
               break;
            case "low":
               GameConfig.setGameFps(30);
               GameConfig.FPS_SHINE_EFFECT = 0;
               EffectCtrl.EFFECT_SMOOTHING = false;
               EffectCtrl.SHADOW_ENABLED = false;
               EffectCtrl.SHAKE_ENABLED = false;
         }
         Debugger.log("[DEBUG] param1.INFINITE_ENERGY = " + param1.INFINITE_ENERGY);
         Debugger.log("[DEBUG] param1.hasOwnProperty(\'INFINITE_ENERGY\') = " + param1.hasOwnProperty("INFINITE_ENERGY"));
         if(param1.hasOwnProperty("INFINITE_ENERGY"))
         {
            _extendsConfig.INFINITE_ENERGY = param1.INFINITE_ENERGY;
            GameConfig.INFINITE_ENERGY = param1.INFINITE_ENERGY;
            GameData.I.config.INFINITE_ENERGY = param1.INFINITE_ENERGY;
            Debugger.log("[DEBUG] Set _extendsConfig.INFINITE_ENERGY = " + _extendsConfig.INFINITE_ENERGY);
            Debugger.log("[DEBUG] Set GameConfig.INFINITE_ENERGY = " + GameConfig.INFINITE_ENERGY);
         }
         else
         {
            _extendsConfig.INFINITE_ENERGY = false;
            GameConfig.INFINITE_ENERGY = false;
            GameData.I.config.INFINITE_ENERGY = false;
            Debugger.log("[DEBUG] INFINITE_ENERGY property missing, set both to false");
         }
         Debugger.log("[DEBUG] After assignment: _extendsConfig.INFINITE_ENERGY = " + _extendsConfig.INFINITE_ENERGY);
         Debugger.log("[DEBUG] After assignment: GameConfig.INFINITE_ENERGY = " + GameConfig.INFINITE_ENERGY);
         var screenPadConfig:ScreenPadConfigVO = _extendsConfig.screenPadConfig;
         if(!screenPadConfig)
         {
            screenPadConfig = ScreenPadManager.I.getConfig() as ScreenPadConfigVO;
            if(!screenPadConfig)
            {
               screenPadConfig = new ScreenPadConfigVO();
            }
            _extendsConfig.screenPadConfig = screenPadConfig;
         }
         if(_extendsConfig.INFINITE_ENERGY)
         {
            screenPadConfig.superSkillAutoHide = false;
            Debugger.log("[DEBUG] INFINITE_ENERGY is ON, set superSkillAutoHide = false (button always visible)");
         }
         else
         {
            screenPadConfig.superSkillAutoHide = true;
            Debugger.log("[DEBUG] INFINITE_ENERGY is OFF, set superSkillAutoHide = true (auto hide)");
         }
         ScreenPadManager.reBuild();
         launch.I.updateSize();
         updateInputConfig();
         Debugger.log("=== [DEBUG] applyConfig finished ===\n");
      }
      
      public function getCreadits(param1:String) : Sprite
      {
         var _loc2_:Sprite = new Sprite();
         param1 += "游戏官网 : <a href=\"" + URL.markURL("http://www.5dplay.net/") + "\" target=\"_blank\">www.5dplay.net</a>" + "<br/>";
         param1 += "游戏论坛 : <a href=\"" + URL.markURL("http://bbs.5dplay.net/") + "\" target=\"_blank\">bbs.5dplay.net</a>" + "<br/>";
         var _loc4_:TextField = new TextField();
         var _loc3_:TextFormat = new TextFormat();
         _loc3_.font = "微软雅黑";
         _loc3_.size = 20;
         _loc3_.color = 16776960;
         _loc3_.leading = 15;
         _loc4_.defaultTextFormat = _loc3_;
         _loc4_.multiline = true;
         if(ENGLISH_VERSION)
         {
            _loc4_.htmlText = "website : <a href=\"" + URL.markURL("http://www.5dplay.net/") + "\" target=\"_blank\">www.5dplay.net</a>" + "<br/>" + "bbs : <a href=\"" + URL.markURL("http://bbs.5dplay.net/") + "\" target=\"_blank\">bbs.5dplay.net</a>" + "<br/>";
         }
         else
         {
            _loc4_.htmlText = param1;
         }
         _loc4_.autoSize = "left";
         _loc4_.x = 50;
         _loc4_.y = 30;
         _loc2_.addChild(_loc4_);
         return _loc2_;
      }
   }
}

