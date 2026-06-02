package net.play5d.game.bvn.mob.ctrls
{
   import flash.system.System;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.mob.utils.AdManager;
   import net.play5d.game.bvn.mob.utils.UMengAneManager;
   import net.play5d.game.bvn.mob.views.AdPauseView;
   
   public class MobileCtrler
   {
      
      private static var _i:MobileCtrler;
      
      private var _adPauseView:AdPauseView;
      
      public var isAdPause:Boolean;
      
      public function MobileCtrler()
      {
         super();
      }
      
      public static function get I() : MobileCtrler
      {
         if(!_i)
         {
            _i = new MobileCtrler();
         }
         return _i;
      }
      
      public function adPause() : void
      {
         if(isAdPause)
         {
            return;
         }
         trace("adPause");
         isAdPause = true;
         if(!_adPauseView)
         {
            _adPauseView = new AdPauseView();
         }
         launch.STAGE.addChild(_adPauseView);
         GameCtrl.I.pause(true);
         SoundCtrl.I.pauseBGM();
      }
      
      public function adResume() : void
      {
         if(!isAdPause)
         {
            return;
         }
         isAdPause = false;
         trace("adResume");
         if(_adPauseView)
         {
            try
            {
               launch.STAGE.removeChild(_adPauseView);
            }
            catch(e:Error)
            {
            }
         }
         SoundCtrl.I.resumeBGM();
         GameCtrl.I.resume(true);
      }
      
      public function pause() : void
      {
         trace("pause process");
         System.pause();
         GameCtrl.I.pause(true);
         SoundCtrl.I.pauseBGM();
         UMengAneManager.I.onDeactive();
         AdManager.I.onPause();
      }
      
      public function resume() : void
      {
         trace("resume process");
         System.resume();
         UMengAneManager.I.onActive();
         AdManager.I.onResume();
         if(!isAdPause)
         {
            SoundCtrl.I.resumeBGM();
         }
      }
   }
}

