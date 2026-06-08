package net.play5d.game.bvn.ctrl
{
   import flash.display.Sprite;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ui.*;
   
   public class StateCtrl
   {
      
      private static var _i:StateCtrl;
      
      public var transEnabled:Boolean = true;
      
      private var _transUI:TransUI;
      
      private var _quickTransUI:QuickTransUI;
      
      private var _transContainer:Sprite;
      
      public function StateCtrl()
      {
         super();
         this._transContainer = MainGame.I.root;
      }
      
      public static function get I() : StateCtrl
      {
         if(!_i)
         {
            _i = new StateCtrl();
         }
         return _i;
      }
      
      private function addTransUI() : void
      {
         if(!this._transUI)
         {
            this._transUI = new TransUI();
         }
         this._transContainer.addChild(this._transUI.ui);
      }
      
      private function removeTrainsUI() : void
      {
         try
         {
            this._transContainer.removeChild(this._transUI.ui);
         }
         catch(e:Error)
         {
         }
      }
      
      public function transIn(param1:Function = null, param2:Boolean = false) : void
      {
         var back:Function = null;
         back = param1;
         var removeAfterComplete:Boolean = param2;
         var removeSelf:* = function():void
         {
            if(back != null)
            {
               back();
            }
            removeTrainsUI();
         };
         if(!this.transEnabled)
         {
            if(back != null)
            {
               back();
            }
            return;
         }
         this.addTransUI();
         if(removeAfterComplete)
         {
            this._transUI.fadIn(removeSelf);
         }
         else
         {
            this._transUI.fadIn(back);
         }
      }
      
      public function transOut(param1:Function = null, param2:Boolean = true) : void
      {
         var back:Function = null;
         back = param1;
         var removeAfterComplete:Boolean = param2;
         var removeSelf:* = function():void
         {
            if(back != null)
            {
               back();
            }
            removeTrainsUI();
         };
         if(!this.transEnabled)
         {
            if(back != null)
            {
               back();
            }
            return;
         }
         this.addTransUI();
         if(removeAfterComplete)
         {
            this._transUI.fadOut(removeSelf);
         }
         else
         {
            this._transUI.fadOut(back);
         }
      }
      
      public function quickTrans(param1:Function = null) : void
      {
         var back:Function = null;
         back = param1;
         var transCom:* = function():void
         {
            try
            {
               _transContainer.removeChild(_quickTransUI);
            }
            catch(e:Error)
            {
            }
            if(back != null)
            {
               back();
            }
         };
         if(!this._quickTransUI)
         {
            this._quickTransUI = new QuickTransUI();
         }
         this._transContainer.addChild(this._quickTransUI);
         this._quickTransUI.fadInAndOut(transCom);
      }
      
      public function clearTrans() : void
      {
         this.removeTrainsUI();
      }
   }
}

