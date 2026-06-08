package net.play5d.game.bvn.ui.fight
{
   import flash.display.DisplayObject;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   
   public class FightFaceUI
   {
      
      private var _ui:*;
      
      public function FightFaceUI(param1:*)
      {
         super();
         this._ui = param1;
      }
      
      public function setData(param1:FighterVO) : void
      {
         if(!param1)
         {
            this._ui.visible = false;
            return;
         }
         this._ui.visible = true;
         var _loc2_:DisplayObject = AssetManager.I.getFighterFaceBar(param1);
         if(Boolean(_loc2_))
         {
            this._ui.ct.addChild(_loc2_);
         }
      }
      
      public function setDirect(param1:int) : void
      {
      }
   }
}

