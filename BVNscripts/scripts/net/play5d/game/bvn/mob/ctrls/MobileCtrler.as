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
      
      /** 2026-10-21：本次「切后台暂停」是否由我们触发 —— 回前台只撤销自己造成的那次暂停 */
      private var _pausedByDeactive:Boolean = false;
      
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
         var _wasPaused:Boolean = GameCtrl.I.isPauseGame();
         GameCtrl.I.pause(true);
         this._pausedByDeactive = !_wasPaused && GameCtrl.I.isPauseGame();
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
         // 2026-10-21：撤销 pause() 造成的暂停。
         // 原先这里只调 System.resume()，不调 GameCtrl.resume(true) —— 玩家必须自己点屏幕上的
         // 「继续」才能回到战斗；而加载阶段 getUI() 还是 null，暂停对话框根本没建出来，
         // 于是回前台后 _isPauseGame 永远为 true、画面永久黑屏。
         if(this._pausedByDeactive)
         {
            this._pausedByDeactive = false;
            if(GameCtrl.I.isPauseGame())
            {
               GameCtrl.I.resume(true);
            }
         }
      }
   }
}

