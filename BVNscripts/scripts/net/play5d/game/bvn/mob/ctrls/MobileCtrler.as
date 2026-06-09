package net.play5d.game.bvn.mob.ctrls
{
   import flash.system.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.mob.utils.*;
   import net.play5d.game.bvn.mob.views.*;
import net.play5d.game.bvn.Debugger;
   
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
         if(this.isAdPause)
         {
            return;
         }
         Debugger.log("adPause");
         this.isAdPause = true;
         if(!this._adPauseView)
         {
            this._adPauseView = new AdPauseView();
         }
         launch.STAGE.addChild(this._adPauseView);
         GameCtrl.I.pause(true);
         SoundCtrl.I.pauseBGM();
      }
      
      public function adResume() : void
      {
         if(!this.isAdPause)
         {
            return;
         }
         this.isAdPause = false;
         Debugger.log("adResume");
         if(Boolean(this._adPauseView))
         {
            try
            {
               launch.STAGE.removeChild(this._adPauseView);
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
         Debugger.log("pause process");
         System.pause();
         GameCtrl.I.pause(true);
         SoundCtrl.I.pauseBGM();
         UMengAneManager.I.onDeactive();
         AdManager.I.onPause();
      }
      
      public function resume() : void
      {
         Debugger.log("resume process");
         System.resume();
         UMengAneManager.I.onActive();
         AdManager.I.onResume();
         if(!this.isAdPause)
         {
            SoundCtrl.I.resumeBGM();
         }
      }
   }
}

