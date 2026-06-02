package net.play5d.game.bvn.win
{
   import flash.desktop.NativeApplication;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TextEvent;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.ConfigVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.input.IGameInput;
   import net.play5d.game.bvn.interfaces.IExtendConfig;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   import net.play5d.game.bvn.interfaces.IGameInterface;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.utils.PayUtils;
   import net.play5d.game.bvn.utils.URL;
   import net.play5d.game.bvn.win.ctrls.LANClientCtrl;
   import net.play5d.game.bvn.win.ctrls.LANGameCtrl;
   import net.play5d.game.bvn.win.ctrls.LANServerCtrl;
   import net.play5d.game.bvn.win.data.ExtendConfig;
   import net.play5d.game.bvn.win.input.InputManager;
   import net.play5d.game.bvn.win.utils.FileUtils;
   import net.play5d.game.bvn.win.utils.MultiLangUtils;
   import net.play5d.game.bvn.win.utils.UpdateUtils;
   import net.play5d.game.bvn.win.views.ViewManager;
   
   public class GameInterfaceManager implements IGameInterface
   {
      
      private static var _extendsConfig:ExtendConfig = new ExtendConfig();
      
      public function GameInterfaceManager()
      {
         super();
      }
      
      public static function get config() : ExtendConfig
      {
         return _extendsConfig;
      }
      
      public static function getSaveFilePath() : String
      {
         return "bvnsave" + UpdateUtils.I.version + ".json";
      }
      
      public static function getRecordFilePath() : String
      {
         return "record.json";
      }
      
      public function initTitleUI(param1:DisplayObject) : void
      {
         if(!(param1 is MovieClip))
         {
            return;
         }
         var _loc3_:MovieClip = param1 as MovieClip;
         var _loc4_:Sprite = _loc3_.getChildByName("logo_mc") as Sprite;
         if(_loc4_ == null)
         {
            return;
         }
         var _loc5_:Sprite = _loc4_.getChildByName("bilibili") as Sprite;
         if(_loc5_ != null)
         {
            _loc5_.buttonMode = true;
            _loc5_.addEventListener("click",URL.bilibili,false,0,true);
         }
         var _loc2_:Sprite = _loc4_.getChildByName("logo_site") as Sprite;
         if(_loc2_ != null)
         {
            _loc2_.buttonMode = true;
            _loc2_.addEventListener("click",URL.website,false,0,true);
         }
      }
      
      public function moreGames() : void
      {
         URL.website();
      }
      
      public function submitScore(param1:int) : void
      {
      }
      
      public function showRank() : void
      {
      }
      
      public function saveGame(param1:Object) : void
      {
         var _loc2_:String = getSaveFilePath();
         FileUtils.writeAppStorageFloderFile(_loc2_,JSON.stringify(param1,null,"\t"));
      }
      
      public function loadGame() : Object
      {
         var _loc1_:String = FileUtils.getAppStorageFloderFileUrl(getSaveFilePath());
         var _loc2_:String = FileUtils.readTextFile(_loc1_);
         if(_loc2_ == null)
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
         var a:Array = [{
            "txt":"TEAM PLAY",
            "cn":GetLangText("stage_menu.menu_text.team_play.txt"),
            "children":[{
               "txt":"TEAM ARCADE",
               "cn":GetLangText("stage_menu.menu_text.team_play.child.team_arcade")
            },{
               "txt":"TEAM VS PEOPLE",
               "cn":GetLangText("stage_menu.menu_text.team_play.child.team_vs_people")
            },{
               "txt":"TEAM VS CPU",
               "cn":GetLangText("stage_menu.menu_text.team_play.child.team_vs_cpu")
            },{
               "txt":"TEAM WATCH",
               "cn":GetLangText("stage_menu.menu_text.team_play.child.team_watch")
            }]
         },{
            "txt":"SINGLE PLAY",
            "cn":GetLangText("stage_menu.menu_text.single_play.txt"),
            "children":[{
               "txt":"SINGLE ARCADE",
               "cn":GetLangText("stage_menu.menu_text.single_play.child.single_arcade")
            },{
               "txt":"SINGLE VS PEOPLE",
               "cn":GetLangText("stage_menu.menu_text.single_play.child.single_vs_people")
            },{
               "txt":"SINGLE VS CPU",
               "cn":GetLangText("stage_menu.menu_text.single_play.child.single_vs_cpu")
            },{
               "txt":"SINGLE WATCH",
               "cn":GetLangText("stage_menu.menu_text.single_play.child.single_watch")
            }]
         },{
            "txt":"MUSOU PLAY",
            "cn":GetLangText("stage_menu.menu_text.musou_play.txt"),
            "children":[{
               "txt":"MUSOU ARCADE",
               "cn":GetLangText("stage_menu.menu_text.musou_play.child.musou_arcade")
            },{
               "txt":"MUSOU VS PEOPLE",
               "cn":GetLangText("stage_menu.menu_text.musou_play.child.musou_vs_people")
            },{
               "txt":"MUSOU VS CPU",
               "cn":GetLangText("stage_menu.menu_text.musou_play.child.musou_vs_cpu")
            },{
               "txt":"MUSOU WATCH",
               "cn":GetLangText("stage_menu.menu_text.musou_play.child.musou_watch")
            },{
               "txt":"MUSOU TRAINING",
               "cn":GetLangText("stage_menu.menu_text.musou_play.child.musou_training")
            }]
         },{
            "txt":"TRAINING",
            "cn":GetLangText("stage_menu.menu_text.training.txt")
         },{
            "txt":"SETTINGS",
            "cn":GetLangText("stage_menu.menu_text.settings.txt"),
            "children":[{
               "txt":"GAME CFG",
               "cn":GetLangText("stage_menu.menu_text.settings.child.game")
            },{
               "txt":"RULE CFG",
               "cn":GetLangText("stage_menu.menu_text.settings.child.rule")
            }]
         },{
            "txt":"MISC",
            "cn":GetLangText("stage_menu.menu_text.misc.txt"),
            "children":[{
               "txt":"STAFF",
               "cn":GetLangText("stage_menu.menu_text.misc.child.staff")
            },{
               "txt":"ISSUES",
               "cn":GetLangText("stage_menu.menu_text.misc.child.issues")
            },{
               "txt":"UPDATE",
               "cn":GetLangText("stage_menu.menu_text.misc.child.update")
            },{
               "txt":"LAN PLAY",
               "cn":GetLangText("stage_menu.menu_text.misc.child.lan_play"),
               "func":function():void
               {
                  LANGameCtrl.I.goLANGameState();
               }
            }]
         },{
            "txt":"EXIT",
            "cn":GetLangText("stage_menu.menu_text.exit.txt"),
            "func":function():void
            {
               GameUI.confrim(GetLangText("game_ui.confrim.exit.title"),GetLangText("game_ui.confrim.exit.message"),NativeApplication.nativeApplication.exit);
            }
         }];
         return a;
      }
      
      public function getSettingMenu() : Array
      {
         var _loc1_:Array = [{
            "label":GetLangText("stage_settings.abled.enabled.label"),
            "cn":GetLangText("stage_settings.abled.enabled.txt"),
            "value":true
         },{
            "label":GetLangText("stage_settings.abled.disabled.label"),
            "cn":GetLangText("stage_settings.abled.disabled.txt"),
            "value":false
         }];
         return [{
            "txt":GetLangText("stage_settings.p1_key_set.label"),
            "cn":GetLangText("stage_settings.p1_key_set.txt")
         },{
            "txt":GetLangText("stage_settings.p2_key_set.label"),
            "cn":GetLangText("stage_settings.p2_key_set.txt")
         },{
            "txt":GetLangText("stage_settings.p1_joystick_set.label"),
            "cn":GetLangText("stage_settings.p1_joystick_set.txt"),
            "select":ViewManager.I.goP1JoyStickSet
         },{
            "txt":GetLangText("stage_settings.p2_joystick_set.label"),
            "cn":GetLangText("stage_settings.p2_joystick_set.txt"),
            "select":ViewManager.I.goP2JoyStickSet
         },{
            "txt":GetLangText("stage_settings.com_level.label"),
            "cn":GetLangText("stage_settings.com_level.txt"),
            "options":[{
               "label":GetLangText("stage_settings.com_level.child.very_easy.label"),
               "cn":GetLangText("stage_settings.com_level.child.very_easy.txt"),
               "value":1
            },{
               "label":GetLangText("stage_settings.com_level.child.easy.label"),
               "cn":GetLangText("stage_settings.com_level.child.easy.txt"),
               "value":2
            },{
               "label":GetLangText("stage_settings.com_level.child.normal.label"),
               "cn":GetLangText("stage_settings.com_level.child.normal.txt"),
               "value":3
            },{
               "label":GetLangText("stage_settings.com_level.child.hard.label"),
               "cn":GetLangText("stage_settings.com_level.child.hard.txt"),
               "value":4
            },{
               "label":GetLangText("stage_settings.com_level.child.very_hard.label"),
               "cn":GetLangText("stage_settings.com_level.child.very_hard.txt"),
               "value":5
            },{
               "label":GetLangText("stage_settings.com_level.child.hell.label"),
               "cn":GetLangText("stage_settings.com_level.child.hell.txt"),
               "value":6
            }],
            "optoinKey":"AI_level"
         },{
            "txt":GetLangText("stage_settings.operate_mode.label"),
            "cn":GetLangText("stage_settings.operate_mode.txt"),
            "options":[{
               "label":GetLangText("stage_settings.operate_mode.child.normal.label"),
               "cn":GetLangText("stage_settings.operate_mode.child.normal.txt"),
               "value":0
            },{
               "label":GetLangText("stage_settings.operate_mode.child.classic.label"),
               "cn":GetLangText("stage_settings.operate_mode.child.classic.txt"),
               "value":1
            }],
            "optoinKey":"keyInputMode"
         },{
            "txt":GetLangText("stage_settings.life.label"),
            "cn":GetLangText("stage_settings.life.txt"),
            "options":[{
               "label":GetLangText("stage_settings.life.child.p50.label"),
               "cn":GetLangText("stage_settings.life.child.p50.txt"),
               "value":0.5
            },{
               "label":GetLangText("stage_settings.life.child.p100.label"),
               "cn":GetLangText("stage_settings.life.child.p100.txt"),
               "value":1
            },{
               "label":GetLangText("stage_settings.life.child.p200.label"),
               "cn":GetLangText("stage_settings.life.child.p200.txt"),
               "value":2
            },{
               "label":GetLangText("stage_settings.life.child.p300.label"),
               "cn":GetLangText("stage_settings.life.child.p300.txt"),
               "value":3
            },{
               "label":GetLangText("stage_settings.life.child.p500.label"),
               "cn":GetLangText("stage_settings.life.child.p500.txt"),
               "value":5
            }],
            "optoinKey":"fighterHP"
         },{
            "txt":GetLangText("stage_settings.time.label"),
            "cn":GetLangText("stage_settings.time.txt"),
            "options":[{
               "label":GetLangText("stage_settings.time.child.s30.label"),
               "cn":GetLangText("stage_settings.time.child.s30.txt"),
               "value":30
            },{
               "label":GetLangText("stage_settings.time.child.s60.label"),
               "cn":GetLangText("stage_settings.time.child.s60.txt"),
               "value":60
            },{
               "label":GetLangText("stage_settings.time.child.s90.label"),
               "cn":GetLangText("stage_settings.time.child.s90.txt"),
               "value":90
            },{
               "label":GetLangText("stage_settings.time.child.s-1.label"),
               "cn":GetLangText("stage_settings.time.child.s-1.txt"),
               "value":-1
            }],
            "optoinKey":"fightTime"
         },{
            "txt":GetLangText("stage_settings.sound.label"),
            "cn":GetLangText("stage_settings.sound.txt"),
            "options":[{
               "label":GetLangText("stage_settings.sound.child.p0.label"),
               "cn":GetLangText("stage_settings.sound.child.p0.txt"),
               "value":0
            },{
               "label":GetLangText("stage_settings.sound.child.p10.label"),
               "cn":GetLangText("stage_settings.sound.child.p10.txt"),
               "value":0.1
            },{
               "label":GetLangText("stage_settings.sound.child.p30.label"),
               "cn":GetLangText("stage_settings.sound.child.p30.txt"),
               "value":0.3
            },{
               "label":GetLangText("stage_settings.sound.child.p50.label"),
               "cn":GetLangText("stage_settings.sound.child.p50.txt"),
               "value":0.5
            },{
               "label":GetLangText("stage_settings.sound.child.p70.label"),
               "cn":GetLangText("stage_settings.sound.child.p70.txt"),
               "value":0.7
            },{
               "label":GetLangText("stage_settings.sound.child.p100.label"),
               "cn":GetLangText("stage_settings.sound.child.p100.txt"),
               "value":1
            }],
            "optoinKey":"soundVolume"
         },{
            "txt":GetLangText("stage_settings.bgm.label"),
            "cn":GetLangText("stage_settings.bgm.txt"),
            "options":[{
               "label":GetLangText("stage_settings.bgm.child.p0.label"),
               "cn":GetLangText("stage_settings.bgm.child.p0.txt"),
               "value":0
            },{
               "label":GetLangText("stage_settings.bgm.child.p10.label"),
               "cn":GetLangText("stage_settings.bgm.child.p10.txt"),
               "value":0.1
            },{
               "label":GetLangText("stage_settings.bgm.child.p30.label"),
               "cn":GetLangText("stage_settings.bgm.child.p30.txt"),
               "value":0.3
            },{
               "label":GetLangText("stage_settings.bgm.child.p50.label"),
               "cn":GetLangText("stage_settings.bgm.child.p50.txt"),
               "value":0.5
            },{
               "label":GetLangText("stage_settings.bgm.child.p70.label"),
               "cn":GetLangText("stage_settings.bgm.child.p70.txt"),
               "value":0.7
            },{
               "label":GetLangText("stage_settings.bgm.child.p100.label"),
               "cn":GetLangText("stage_settings.bgm.child.p100.txt"),
               "value":1
            }],
            "optoinKey":"bgmVolume"
         },{
            "txt":GetLangText("stage_settings.quality.label"),
            "cn":GetLangText("stage_settings.quality.txt"),
            "options":[{
               "label":GetLangText("stage_settings.quality.child.low.label"),
               "cn":GetLangText("stage_settings.quality.child.low.txt"),
               "value":"low"
            },{
               "label":GetLangText("stage_settings.quality.child.medium.label"),
               "cn":GetLangText("stage_settings.quality.child.medium.txt"),
               "value":"medium"
            },{
               "label":GetLangText("stage_settings.quality.child.high.label"),
               "cn":GetLangText("stage_settings.quality.child.high.txt"),
               "value":"high"
            },{
               "label":GetLangText("stage_settings.quality.child.best.label"),
               "cn":GetLangText("stage_settings.quality.child.best.txt"),
               "value":"best"
            }],
            "optoinKey":"quality"
         },{
            "txt":GetLangText("stage_settings.joy_rumble.label"),
            "cn":GetLangText("stage_settings.joy_rumble.txt"),
            "options":_loc1_,
            "optoinKey":"joyRumble"
         },{
            "txt":GetLangText("stage_settings.display_mode.label"),
            "cn":GetLangText("stage_settings.display_mode.txt"),
            "options":[{
               "label":GetLangText("stage_settings.display_mode.child.full.label"),
               "cn":GetLangText("stage_settings.display_mode.child.full.txt"),
               "value":true
            },{
               "label":GetLangText("stage_settings.display_mode.child.win.label"),
               "cn":GetLangText("stage_settings.display_mode.child.win.txt"),
               "value":false
            }],
            "optoinKey":"isFullScreen"
         },{
            "txt":GetLangText("stage_settings.smooth_low_quality.label"),
            "cn":GetLangText("stage_settings.smooth_low_quality.txt"),
            "options":_loc1_,
            "optoinKey":"isSmoothLowQuality"
         },{
            "txt":GetLangText("stage_settings.music_type.label"),
            "cn":GetLangText("stage_settings.music_type.txt"),
            "options":[{
               "label":GetLangText("stage_settings.music_type.child.classical.label"),
               "cn":GetLangText("stage_settings.music_type.child.classical.txt"),
               "value":true
            },{
               "label":GetLangText("stage_settings.music_type.child.customized.label"),
               "cn":GetLangText("stage_settings.music_type.child.customized.txt"),
               "value":false
            }],
            "optoinKey":"isClassicalBgm"
         },{
            "txt":GetLangText("stage_settings.skip_start.label"),
            "cn":GetLangText("stage_settings.skip_start.txt"),
            "options":_loc1_,
            "optoinKey":"isSkipStart"
         },{
            "txt":GetLangText("stage_settings.steel_body_freeze.label"),
            "cn":GetLangText("stage_settings.steel_body_freeze.txt"),
            "options":_loc1_,
            "optoinKey":"isSteelBodyFreeze"
         },{
            "txt":GetLangText("stage_settings.slow_down_time.label"),
            "cn":GetLangText("stage_settings.slow_down_time.txt"),
            "options":_loc1_,
            "optoinKey":"isSlowDown"
         },{
            "txt":GetLangText("stage_settings.auto_match_random.label"),
            "cn":GetLangText("stage_settings.auto_match_random.txt"),
            "options":_loc1_,
            "optoinKey":"isAutoMathRandom"
         },{
            "txt":GetLangText("stage_settings.random_old_fighter.label"),
            "cn":GetLangText("stage_settings.random_old_fighter.txt"),
            "options":_loc1_,
            "optoinKey":"isRandomOldFighter"
         },{
            "txt":GetLangText("stage_settings.auto_show_more.label"),
            "cn":GetLangText("stage_settings.auto_show_more.txt"),
            "options":_loc1_,
            "optoinKey":"isAutoShowMore"
         },{
            "txt":GetLangText("stage_settings.show_fps.label"),
            "cn":GetLangText("stage_settings.show_fps.txt"),
            "options":_loc1_,
            "optoinKey":"isShowFPS"
         },{
            "txt":GetLangText("stage_settings.auto_update_check.label"),
            "cn":GetLangText("stage_settings.auto_update_check.txt"),
            "options":_loc1_,
            "optoinKey":"isAutoUpdateCheck"
         }];
      }
      
      public function getGameInput(param1:String) : Vector.<IGameInput>
      {
         var _loc2_:Vector.<IGameInput> = new Vector.<IGameInput>();
         switch(param1)
         {
            case "MENU":
               _loc2_.push(InputManager.I.key_menu);
               _loc2_.push(InputManager.I.joy_menu);
               break;
            case "P1":
               _loc2_.push(InputManager.I.key_p1);
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
         if(LANServerCtrl.I.active || LANClientCtrl.I.active)
         {
            InputManager.I.key_menu.enabled = false;
            InputManager.I.key_p1.enabled = false;
            InputManager.I.key_p2.enabled = false;
            InputManager.I.joy_menu.enabled = false;
            InputManager.I.joy_p1.enabled = false;
            InputManager.I.joy_p2.enabled = false;
            InputManager.I.socket_input_p1.enabled = true;
            InputManager.I.socket_input_p2.enabled = true;
            if(LANServerCtrl.I.active)
            {
               InputManager.I.socket_input_p1.setInputers([InputManager.I.key_p1,InputManager.I.joy_p1]);
            }
            if(LANClientCtrl.I.active)
            {
               InputManager.I.key_p2.setConfig(GameData.I.config.key_p1);
               InputManager.I.joy_p2.setConfig(_extendsConfig.joy1Config);
               InputManager.I.socket_input_p2.setInputers([InputManager.I.key_p2,InputManager.I.joy_p2]);
            }
            return true;
         }
         InputManager.I.key_menu.setConfig(GameData.I.config.key_menu);
         InputManager.I.key_p1.setConfig(GameData.I.config.key_p1);
         InputManager.I.key_p2.setConfig(GameData.I.config.key_p2);
         InputManager.I.joy_menu.setConfig(_extendsConfig.joyMenuConfig);
         InputManager.I.joy_p1.setConfig(_extendsConfig.joy1Config);
         InputManager.I.joy_p2.setConfig(_extendsConfig.joy2Config);
         InputManager.I.socket_input_p1.enabled = false;
         InputManager.I.socket_input_p2.enabled = false;
         return true;
      }
      
      public function applyConfig(param1:ConfigVO) : void
      {
         switch(param1.quality)
         {
            case "best":
               MainGame.I.stage.quality = "best";
               MainGame.I.setFPS(60);
               GameConfig.FPS_SHINE_EFFECT = 60;
               break;
            case "higher":
               MainGame.I.stage.quality = "high";
               MainGame.I.setFPS(60);
               GameConfig.FPS_SHINE_EFFECT = 30;
               break;
            case "high":
               MainGame.I.stage.quality = "high";
               MainGame.I.setFPS(60);
               GameConfig.FPS_SHINE_EFFECT = 30;
               break;
            case "medium":
               MainGame.I.stage.quality = "medium";
               MainGame.I.setFPS(45);
               GameConfig.FPS_SHINE_EFFECT = 15;
               break;
            case "low":
               MainGame.I.stage.quality = "low";
               MainGame.I.setFPS(30);
               GameConfig.FPS_SHINE_EFFECT = 15;
         }
         if(_extendsConfig.isFullScreen)
         {
            MainGame.I.stage.displayState = "fullScreenInteractive";
         }
         else
         {
            MainGame.I.stage.displayState = "normal";
         }
         Debugger.setFPSVisible(GameData.I.config.isShowFPS);
      }
      
      public function getCreadits(param1:String) : Sprite
      {
         var wechatBitmapData:BitmapData;
         var wechat:Sprite;
         var onMouseOver:*;
         var onMouseOut:*;
         var creditsInfo:String = param1;
         var sp:Sprite = new Sprite();
         creditsInfo += "<br/>官网：<a href=\"http://www.1212321.com/\" target=\"_blank\">www.1212321.com</a>    论坛：<a href=\"http://bbs.1212321.com/\" target=\"_blank\">bbs.1212321.com</a><br/>邮箱：5dplay@qun.mail.163.com （人才招募中）<br/>";
         var txt:TextField = new TextField();
         var tf:TextFormat = new TextFormat();
         tf.font = "Microsoft YaHei";
         tf.size = 17;
         tf.color = 16776960;
         tf.leading = 8;
         txt.defaultTextFormat = tf;
         txt.multiline = true;
         txt.htmlText = creditsInfo;
         txt.autoSize = "left";
         txt.x = 15;
         txt.y = 25;
         txt.addEventListener("link",function(param1:TextEvent):void
         {
            GameData.I.isOpenEgg = true;
            SoundCtrl.I.playAssetSound("ko");
         });
         sp.addChild(txt);
         if(MultiLangUtils.I.isChinese)
         {
            onMouseOver = function(param1:MouseEvent):void
            {
               var _loc2_:Sprite = param1.target as Sprite;
               _loc2_.alpha = 1;
            };
            onMouseOut = function(param1:MouseEvent):void
            {
               var _loc2_:Sprite = param1.target as Sprite;
               _loc2_.alpha = 0.2;
            };
            wechatBitmapData = AssetManager.I.createObject("wechat","subswfs/back.swf") as BitmapData;
            wechat = PayUtils.getPaySp(new Bitmap(wechatBitmapData));
            wechat.x = 615;
            wechat.y = 380;
            wechat.scaleX = wechat.scaleY = 0.5;
            wechat.alpha = 0.2;
            wechat.addEventListener("mouseOver",onMouseOver);
            wechat.addEventListener("mouseOut",onMouseOut);
            sp.addChild(wechat);
         }
         return sp;
      }
      
      public function checkFile(param1:String, param2:ByteArray) : Boolean
      {
         return true;
      }
      
      public function addMosouMoney(param1:Function) : void
      {
         param1(100 + Math.random() * 200);
      }
      
      public function saveRecord(param1:Object) : void
      {
         var _loc2_:String = getRecordFilePath();
         FileUtils.writeAppStorageFloderFile(_loc2_,JSON.stringify(param1,null,"\t"));
      }
      
      public function loadRecord() : Object
      {
         var _loc1_:String = FileUtils.getAppStorageFloderFileUrl(getRecordFilePath());
         var _loc2_:String = FileUtils.readTextFile(_loc1_);
         if(_loc2_ == null)
         {
            return null;
         }
         return JSON.parse(_loc2_);
      }
   }
}

