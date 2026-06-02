package net.play5d.game.bvn.mob.utils
{
   import flash.events.DataEvent;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import net.play5d.game.bvn.MainGame;
   
   public class AdManager
   {
      
      private static var _i:AdManager;
      
      private var _showAdTimes:int;
      
      private var _topAdShowing:Boolean;
      
      private const _showAdTimesTotal:int = 1;
      
      private var _showVideoAdTimes:int;
      
      private const _showVideoAdTimesTotal:int = 2;
      
      private var _initSdkBack:Function;
      
      private var _openCloseBack:Function;
      
      private var _showMenuTimes:int;
      
      private var _showOpenAdTimer:int;
      
      public function AdManager()
      {
         super();
      }
      
      public static function get I() : AdManager
      {
         if(!_i)
         {
            _i = new AdManager();
         }
         return _i;
      }
      
      public function initAD(param1:Function = null, param2:Function = null) : void
      {
         _initSdkBack = param1;
         _openCloseBack = param2;
         if(_initSdkBack != null)
         {
            _initSdkBack();
            _initSdkBack = null;
         }
         if(_openCloseBack != null)
         {
            _showOpenAdTimer = setTimeout(openCloseBack,5000);
         }
      }
      
      public function cancelInitBack() : void
      {
         clearTimeout(_showOpenAdTimer);
         _initSdkBack = null;
         _openCloseBack = null;
      }
      
      private function openCloseBack() : void
      {
         clearTimeout(_showOpenAdTimer);
         if(_openCloseBack != null)
         {
            _openCloseBack();
            _openCloseBack = null;
         }
      }
      
      public function onGameInited() : void
      {
         MainGame.I.stage.addEventListener("5d_message",messageHandler);
      }
      
      private function messageHandler(param1:DataEvent) : void
      {
         var cmd:String;
         var data:Array = null;
         try
         {
            data = JSON.parse(param1.data) as Array;
         }
         catch(e:Error)
         {
            return;
         }
         if(!data || data.length < 1)
         {
            return;
         }
         cmd = data[0];
         switch(cmd)
         {
            case "game_pause":
            case "winner_show":
            case "show_continue":
               break;
            case "go_menu_stage":
               if(++_showMenuTimes > 2)
               {
               }
         }
      }
      
      private function showSmartAd() : void
      {
      }
      
      public function showInterAdOrVideoAd() : void
      {
      }
      
      public function showInterAd() : void
      {
      }
      
      public function showVideoAd() : void
      {
      }
      
      public function showOpenAd() : void
      {
      }
      
      public function onPause() : void
      {
      }
      
      public function onResume() : void
      {
         trace("ad.resume");
      }
   }
}

