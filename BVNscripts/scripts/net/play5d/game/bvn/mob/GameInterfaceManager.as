package net.play5d.game.bvn.mob
{
   import flash.desktop.*;
   import flash.display.*;
   import flash.filesystem.*;
   import flash.geom.*;
   import flash.text.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.mob.ctrls.*;
   import net.play5d.game.bvn.mob.data.*;
   import net.play5d.game.bvn.mob.input.*;
   import net.play5d.game.bvn.mob.screenpad.*;
   import net.play5d.game.bvn.mob.utils.*;
   import net.play5d.game.bvn.mob.views.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   
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
         var _loc1_:File = File.applicationStorageDirectory.resolvePath("bvnsave.sav");
         var _loc2_:String = FileUtils.readTextFile(_loc1_.nativePath);
         if(!_loc2_)
         {
            return null;
         }
         return JSON.parse(_loc2_);
      }
      
      public function getFighterCtrl(param1:int) : IFighterActionCtrl
      {
         return null;
      }
      
      public function getGameMenu() : Array
      {
         return [{
            "txt":"TEAM PLAY",
            "cn":"小队模式",
            "children":[{
               "txt":"TEAM ACRADE",
               "cn":"闯关",
               "func":function():void
               {
                  GameMode.currentMode = 10;
                  MessionModel.I.reset();
                  MainGame.I.goSelect();
               }
            },{
               "txt":"TEAM VS PEOPLE",
               "cn":"小队对战",
               "func":function():void
               {
                  GameMode.currentMode = 11;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"TEAM VS CPU",
               "cn":"VS人机",
               "func":function():void
               {
                  GameMode.currentMode = 12;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"TEAM WATCH",
               "cn":"观战小队",
               "func":function():void
               {
                  GameMode.currentMode = 13;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"TEAM DUO",
               "cn":"2v2",
               "func":function():void
               {
                  GameMode.currentMode = 14;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"TEAM DUO WATCH",
               "cn":"观战(2v2)",
               "func":function():void
               {
                  GameMode.currentMode = 15;
                  MainGame.I.goSelect();
               }
            }]
         },{
            "txt":"SINGLE PLAY",
            "cn":"单人模式",
            "children":[{
               "txt":"SINGLE ACRADE",
               "cn":"闯关",
               "func":function():void
               {
                  GameMode.currentMode = 20;
                  MessionModel.I.reset();
                  MainGame.I.goSelect();
               }
            },{
               "txt":"SINGLE VS PEOPLE",
               "cn":"单人对战",
               "func":function():void
               {
                  GameMode.currentMode = 21;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"SINGLE VS CPU",
               "cn":"VS人机",
               "func":function():void
               {
                  GameMode.currentMode = 22;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"SINGLE WATCH",
               "cn":"观战单人",
               "func":function():void
               {
                  GameMode.currentMode = 23;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"1 VS 2",
               "cn":"1v2",
               "func":function():void
               {
                  GameMode.currentMode = 24;
                  MainGame.I.goSelect();
               }
            },{
               "txt":"1VS2 WATCH",
               "cn":"观战(1v2)",
               "func":function():void
               {
                  GameMode.currentMode = 25;
                  MainGame.I.goSelect();
               }
            }]
         },{
            "txt":"OPTION",
            "cn":"设置",
            "children":[{
               "txt":"GAME CFG",
               "cn":"常规设置"
            },{
               "txt":"RULE CFG",
               "cn":"规则设置"
            }]
         },{
            "txt":"TRAINING",
            "cn":"练习"
         },{
            "txt":"CREDITS",
            "cn":"制作组",
            "func":function():void
            {
               MainGame.I.goCredits();
            }
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
            // 注意：这里不能再挂 "select": ViewManager.I.goP1JoyStickSet。
            // SetBtn.onSelect 会先调 select() 再派发 SELECT，SettingState.onBtnSelect 的
            // case "Joystick Setting" 又会开 ControlSetUI —— 同一次选择会连开两个子页
            // （JoyStickSetUI 被随后的 goInnerSetPage → destoryInnerSetUI 立刻销毁）。
            // 控制设置页（ControlSetUI）承载「Screen Button / Keyboard Input」，必须保留。
            "txt":"Joystick Setting",
            "cn":"控制设置"
         },(ViewManager.I.isMultiplePads() ? {
            "txt":"P2 Joystick Setting",
            "cn":"玩家2 手柄设置",
            "select": ViewManager.I.goP2JoyStickSet
         } : null),{
            "txt":"AI Level",
            "cn":"AI等级",
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
            "txt":"GRAPHICS QUALITY",
            "cn":"游戏画质",
            "options":[{
               "label":"30",
               "cn":"30帧",
               "value":"low"
            },{
               "label":"60",
               "cn":"60帧",
               "value":"medium"
            },{
               "label":"60M",
               "cn":"60中",
               "value":"high"
            },{
               "label":"60H",
               "cn":"60高",
               "value":"best"
            }],
            "optoinKey":"quality"
         }];
      }
      
      /**
       * 规则设置界面（RULE CFG）的选项数据：竞技规则项不再混在常规设置里。
       * 第 1 项无 options，是「一键切换竞技/娱乐规则」开关，由 RuleState 按 selectedLabel 处理。
       */
      public function getRuleMenu() : Array
      {
         return [{
            "txt":"RULE SWITCH",
            "cn":"一键切换竞技/娱乐规则"
         },{
            "txt":"STEEL FREEZE",
            "cn":"刚身停顿",
            "options":[{
               "label":"TRUE",
               "cn":"是",
               "value":true
            },{
               "label":"FALSE",
               "cn":"否",
               "value":false
            }],
            "optoinKey":"isSteelBodyFreeze"
         },{
            "txt":"INITIAL QI",
            "cn":"初始气量",
            "options":[{
               "label":"0",
               "cn":"0",
               "value":0
            },{
               "label":"100",
               "cn":"100",
               "value":100
            },{
               "label":"200",
               "cn":"200",
               "value":200
            },{
               "label":"300",
               "cn":"300",
               "value":300
            }],
            "optoinKey":"initialQi"
         },{
            // 由常规设置页迁入（原 getSettingMenu 末项）。
            // 注意：它不参与「一键切换竞技/娱乐」（ConfigVO.switchAllRuleConfig 不含此键）。
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
         },{
            "txt":"ALLOW WANKAI",
            "cn":"允许变身",
            "options":[{
               "label":"FALSE",
               "cn":"否",
               "value":false
            },{
               "label":"TRUE",
               "cn":"是",
               "value":true
            }],
            "optoinKey":"allowWankai"
         },{
            "txt":"ALLOW REATTACK",
            "cn":"允许重复连",
            "options":[{
               "label":"FALSE",
               "cn":"不允许",
               "value":false
            },{
               "label":"TRUE",
               "cn":"允许",
               "value":true
            }],
            "optoinKey":"isAllowRepeatAttack"
         },{
            "txt":"CHANGE SPECIAL KEY",
            "cn":"修改灵替按键",
            "options":[{
               "label":"OFF",
               "cn":"关闭",
               "value":false
            },{
               "label":"ON",
               "cn":"开启",
               "value":true
            }],
            "optoinKey":"isChangeSpecialKey"
         },{
            "txt":"CAMERA MAX SIZE",
            "cn":"镜头最大大小",
            "options":[{
               "label":"50%",
               "cn":"50%",
               "value":0.5
            },{
               "label":"60%",
               "cn":"60%",
               "value":0.6
            },{
               "label":"70%",
               "cn":"70%",
               "value":0.7
            },{
               "label":"80%",
               "cn":"80%",
               "value":0.8
            },{
               "label":"90%",
               "cn":"90%",
               "value":0.9
            },{
               "label":"100%",
               "cn":"100%",
               "value":1
            }],
            "optoinKey":"cameraMaxSize"
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
               _loc2_.push(InputManager.I.joy_p2);
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
         if(Boolean(_loc1_.mapLayer))
         {
            _loc1_.mapLayer.cacheAsBitmapMatrix = new Matrix();
         }
         if(Boolean(_loc1_.frontLayer))
         {
            _loc1_.frontLayer.cacheAsBitmapMatrix = new Matrix();
         }
         if(Boolean(_loc1_.frontFixLayer))
         {
            _loc1_.frontFixLayer.cacheAsBitmapMatrix = new Matrix();
         }
         if(Boolean(_loc1_.bgLayer))
         {
            _loc1_.bgLayer.cacheAsBitmap = true;
         }
      }
      
      public function updateInputConfig() : Boolean
      {
         // 键盘输入由 ExtendConfig.ENABLE_KEYBOARD 控制（默认 true），用户可在设置菜单「Keyboard Input」关闭；
         // 开启后键盘通道生效（注意：手柄 D-pad/按钮的 KeyboardEvent 会进入键盘通道，属预期行为）
         var keyEnabled:Boolean = Boolean(_extendsConfig.ENABLE_KEYBOARD);
         InputManager.I.key_menu.enabled = keyEnabled;
         InputManager.I.key_p1.enabled = keyEnabled;
         InputManager.I.key_p2.enabled = keyEnabled;
         InputManager.I.key_menu.setConfig(GameData.I.config.key_menu);
         InputManager.I.key_p1.setConfig(GameData.I.config.key_p1);
         InputManager.I.key_p2.setConfig(GameData.I.config.key_p2);
         if(Boolean(LANServerCtrl.I.active) || Boolean(LANClientCtrl.I.active))
         {
            InputManager.I.key_menu.enabled = false;
            InputManager.I.key_p1.enabled = false;
            InputManager.I.key_p2.enabled = false;
            InputManager.I.screen_menu.enabled = false;
            InputManager.I.screen_p1.enabled = false;
            InputManager.I.joy_menu.enabled = false;
            InputManager.I.joy_p1.enabled = false;
            InputManager.I.joy_p2.enabled = false;
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
         // 刷新设备分配（设备连接可能晚于读档，确保 deviceId 已绑定当前手柄）
         _extendsConfig.updateJoyConfig();
         InputManager.I.joy_menu.setConfig(_extendsConfig.joyMenuConfig);
         InputManager.I.joy_p1.setConfig(_extendsConfig.joy1Config);
         // 2026-08-26 批次 2：P2 改用独立配置（与 P1 解耦，避免 P2 改键被 P1 覆盖、P2 设备号重连后失效）
         InputManager.I.joy_p2.setConfig(_extendsConfig.joy2Config);
         InputManager.I.socket_input_p1.enabled = false;
         InputManager.I.socket_input_p2.enabled = false;
         InputManager.I.joy_menu.enabled = true;
         refreshJoystickRouting();
         return true;
      }

      /** 手柄路由：单手柄模型（手机端只连一个手柄，Xbox 布局）。
      手柄输入固定走"P1"通道（joy_p1），控制哪个角色由 GameCtrl.switchControlPlayer/joyTarget 决定。
      观战→双禁用；其余（vs CPU/闯关/对战）→ 仅 joy_p1 启用（vs CPU 时 switchControlPlayer 不参与，手柄自然只控制 P1）。
      2026-08-26 批次 3 收尾：决策确认"单手柄永远禁 joy_p2"，本函数只动 enabled 字段，不动 deviceId。
      joy2Config 设备号由 ExtendConfig.updateJoyConfig 独立管理（批次 2 P2 独立配置存档），与本路由函数解耦。 */
      public function refreshJoystickRouting() : void
      {
         var isWatchMode:Boolean = GameMode.isWatch(false);
         if(isWatchMode)
         {
            InputManager.I.joy_p1.enabled = false;
            InputManager.I.joy_p2.enabled = false;
             Debugger.logFold("JOY_ROUTE.singlePadWatch", "joy_p1=" + InputManager.I.joy_p1.enabled + " joy_p2=" + InputManager.I.joy_p2.enabled);
            return;
         }
         InputManager.I.joy_p1.enabled = true;
         InputManager.I.joy_p2.enabled = false;
         Debugger.logFold("JOY_ROUTE.singlePadAllModes", "joy_p1=" + InputManager.I.joy_p1.enabled + " joy_p2=" + InputManager.I.joy_p2.enabled);
      }

      public function applyConfig(param1:ConfigVO) : void
      {
         Debugger.logFold("applyConfig");
         switch(param1.quality)
         {
            case "best":
               GameConfig.setGameFps(90);
               GameConfig.FPS_SHINE_EFFECT = 15;
               EffectCtrl.EFFECT_SMOOTHING = true;
               EffectCtrl.SHADOW_ENABLED = true;
               EffectCtrl.SHAKE_ENABLED = true;
               break;
            case "high":
               GameConfig.setGameFps(60);
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
         if(param1.hasOwnProperty("INFINITE_ENERGY"))
         {
            _extendsConfig.INFINITE_ENERGY = param1.INFINITE_ENERGY;
            GameConfig.INFINITE_ENERGY = param1.INFINITE_ENERGY;
            GameData.I.config.INFINITE_ENERGY = param1.INFINITE_ENERGY;
         }
         else
         {
            _extendsConfig.INFINITE_ENERGY = false;
            GameConfig.INFINITE_ENERGY = false;
            GameData.I.config.INFINITE_ENERGY = false;
         }
         // 原来这里有 8 行 [DEBUG] 逐字段打印（每次 applyConfig 刷一屏），折叠成一行
         Debugger.logFold("INFINITE_ENERGY", GameConfig.INFINITE_ENERGY ? "ON" : "OFF");
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
            Debugger.logFold("INFINITE_ENERGY.superSkillAutoHide", "OFF(常显)");
         }
         else
         {
            screenPadConfig.superSkillAutoHide = true;
            Debugger.logFold("INFINITE_ENERGY.superSkillAutoHide", "ON(自动隐藏)");
         }
         ScreenPadManager.reBuild();
         launch.I.updateSize();
         this.updateInputConfig();

      }
      
      public function getCreadits(param1:String) : Sprite
      {
         var _loc2_:Sprite = new Sprite();
         param1 += "游戏官网 : <a href=\"" + URL.markURL("http://www.5dplay.net/") + "\" target=\"_blank\">www.5dplay.net</a>" + "<br/>";
         param1 += "面板BUG反馈 : <a href=\"" + URL.markURL("https://space.bilibili.com/485366223") + "\" target=\"_blank\"><font color=\"#4488ff\"><u>作者主页</u></font></a><br/>";
         param1 += "反馈邮箱 : <a href=\"mailto:yinyu7798@foxmail.com\"><font color=\"#4488ff\"><u>yinyu7798@foxmail.com</u></font></a><br/>";
         var _loc3_:TextField = new TextField();
         var _loc4_:TextFormat = new TextFormat();
         _loc4_.font = "微软雅黑";
         _loc4_.size = 20;
         _loc4_.color = 0xCCCCCC;
         _loc4_.leading = 15;
         _loc3_.defaultTextFormat = _loc4_;
         _loc3_.multiline = true;
         if(ENGLISH_VERSION)
         {
            _loc3_.htmlText = "website : <a href=\"" + URL.markURL("http://www.5dplay.net/") + "\" target=\"_blank\"><font color=\"#4488ff\"><u>www.5dplay.net</u></font></a><br/>" + "BUG Report : <a href=\"" + URL.markURL("https://space.bilibili.com/485366223") + "\" target=\"_blank\"><font color=\"#4488ff\"><u>BiliBili Space</u></font></a><br/>" + "E-mail : <a href=\"mailto:yinyu7798@foxmail.com\"><font color=\"#4488ff\"><u>yinyu7798@foxmail.com</u></font></a><br/>";
         }
         else
         {
            _loc3_.htmlText = param1;
         }
         _loc3_.autoSize = "left";
         _loc3_.x = 50;
         _loc3_.y = 30;
         _loc2_.addChild(_loc3_);
         return _loc2_;
      }
   }
}
