package net.play5d.game.bvn.mob.utils
{
   import flash.events.DataEvent;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
import net.play5d.game.bvn.Debugger;
   
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
         this._initSdkBack = param1;
         this._openCloseBack = param2;
         if(this._initSdkBack != null)
         {
            this._initSdkBack();
            this._initSdkBack = null;
         }
         if(this._openCloseBack != null)
         {
            this._showOpenAdTimer = setTimeout(this.openCloseBack,5000);
         }
      }
      
      public function cancelInitBack() : void
      {
         clearTimeout(this._showOpenAdTimer);
         this._initSdkBack = null;
         this._openCloseBack = null;
      }
      
      private function openCloseBack() : void
      {
         clearTimeout(this._showOpenAdTimer);
         if(this._openCloseBack != null)
         {
            this._openCloseBack();
            this._openCloseBack = null;
         }
      }
      
      public function onGameInited() : void
      {
         MainGame.I.stage.addEventListener("5d_message",this.messageHandler);
      }
      
      private function messageHandler(param1:DataEvent) : void
      {
         var cmd:String = null;
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
               if(++this._showMenuTimes > 2)
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
         Debugger.log("ad.resume");
      }
   }
}

