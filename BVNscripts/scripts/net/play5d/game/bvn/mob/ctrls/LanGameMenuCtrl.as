package net.play5d.game.bvn.mob.ctrls
{
   import flash.events.KeyboardEvent;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.mob.views.lan.*;
   import net.play5d.game.bvn.utils.*;
   
   public class LanGameMenuCtrl
   {
      
      private static var _i:LanGameMenuCtrl;
      
      private var _isKeyDown:Boolean;
      
      private var _exitDialog:LANExitDialog;
      
      public function LanGameMenuCtrl()
      {
         super();
      }
      
      public static function get I() : LanGameMenuCtrl
      {
         if(!_i)
         {
            _i = new LanGameMenuCtrl();
         }
         return _i;
      }
      
      public function init() : void
      {
         this._exitDialog = new LANExitDialog();
         this._exitDialog.hide();
         KeyBoarder.listen(this.keyHandler);
      }
      
      public function dispose() : void
      {
         if(Boolean(this._exitDialog))
         {
            try
            {
               MainGame.I.root.removeChild(this._exitDialog);
            }
            catch(e:Error)
            {
               trace(e);
            }
            this._exitDialog.destory();
            this._exitDialog = null;
         }
         KeyBoarder.unListen(this.keyHandler);
         this._isKeyDown = false;
      }
      
      private function keyHandler(param1:KeyboardEvent) : void
      {
         if(param1.type == "keyDown")
         {
            if(this._isKeyDown)
            {
               return;
            }
            if(!this._exitDialog)
            {
               return;
            }
            if(param1.keyCode == 27)
            {
               this._isKeyDown = true;
               if(this._exitDialog.isShowing())
               {
                  this._exitDialog.hide();
               }
               else
               {
                  MainGame.I.root.addChild(this._exitDialog);
                  this._exitDialog.show();
               }
            }
         }
         if(param1.type == "keyUp")
         {
            if(param1.keyCode == 27)
            {
               this._isKeyDown = false;
            }
         }
      }
   }
}

