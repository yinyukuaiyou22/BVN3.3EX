package net.play5d.game.bvn.win.utils
{
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.utils.URL;
   import net.play5d.kyo.loader.KyoURLoader;
   
   public class UpdateUtils
   {
      
      private static var _instance:UpdateUtils;
      
      public var version:String = null;
      
      public var date:String = null;
      
      private var _cloudConfig:String = null;
      
      public function UpdateUtils()
      {
         super();
      }
      
      public static function get I() : UpdateUtils
      {
         if(_instance == null)
         {
            _instance = new UpdateUtils();
         }
         return _instance;
      }
      
      public function initialize(param1:Function = null) : void
      {
         var back:Function = param1;
         KyoURLoader.load("version.json",function(param1:*):void
         {
            var _loc2_:Object = JSON.parse(String(param1));
            if(_loc2_.version)
            {
               version = _loc2_.version;
            }
            if(_loc2_.date)
            {
               date = _loc2_.date;
            }
            if(_loc2_.cloud_config)
            {
               _cloudConfig = _loc2_.cloud_config;
            }
            if(back != null)
            {
               back();
            }
         });
      }
      
      public function updateVersionText() : void
      {
         MainGame.I.VERSION = "V " + version + " " + MainGame.I.VERSION;
         MainGame.I.VERSION_DATE = date;
      }
      
      public function checkUpdate(param1:Boolean = false) : void
      {
         var silent:Boolean = param1;
         KyoURLoader.load(_cloudConfig,function(param1:*):void
         {
            var notice:Object;
            var newVersion:String;
            var newDate:String;
            var downloadLink:String;
            var message:String;
            var data:* = param1;
            var newVersionObj:Object = JSON.parse(String(data));
            if(newVersionObj == null)
            {
               return;
            }
            notice = newVersionObj.notice;
            if(GameData.I.config.latestNoticeID != notice.id)
            {
               GameUI.alert("NOTICE  " + notice.id,notice[MultiLangUtils.I.lang],function():void
               {
                  checkUpdate(silent);
               });
               GameData.I.config.latestNoticeID = notice.id;
               GameData.I.saveData();
               return;
            }
            newVersion = newVersionObj.version;
            if(newVersion == version)
            {
               if(!silent)
               {
                  GameUI.confrim(GetLangText("game_ui.confrim.update_congratulation.title"),GetLangText("game_ui.confrim.update_congratulation.message"));
               }
               return;
            }
            newDate = newVersionObj.date;
            downloadLink = newVersionObj.download_link;
            message = GetLangText("game_ui.confrim.update.message_items.tips_1") + "\n" + GetLangText("game_ui.confrim.update.message_items.tips_2") + newVersion + GetLangText("game_ui.confrim.update.message_items.tips_3") + GetLangText("game_ui.confrim.update.message_items.tips_4") + newDate + "\n\n" + GetLangText("game_ui.confrim.update.message_items.tips_5");
            GameUI.confrim(GetLangText("game_ui.confrim.update.title"),message,function():void
            {
               URL.go(downloadLink,false);
            });
         },function():void
         {
            if(!silent)
            {
               GameUI.confrim(GetLangText("game_ui.confrim.update_error.title"),GetLangText("game_ui.confrim.update_error.message"));
            }
         });
      }
   }
}

