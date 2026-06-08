package net.play5d.game.bvn.ui.fight
{
   import flash.display.DisplayObject;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameRunFighterGroup;
   
   public class FightFaceGroup
   {
      
      private var _ui:*;
      
      private var _face1:FightFaceUI;
      
      private var _face2:FightFaceUI;
      
      private var _face3:FightFaceUI;
      
      public function FightFaceGroup(param1:*)
      {
         super();
         this._ui = param1;
         this._ui.cacheAsBitmap = true;
         this._face1 = new FightFaceUI(this._ui.face);
         this._face2 = new FightFaceUI(this._ui.face2);
         this._face3 = new FightFaceUI(this._ui.face3);
      }
      
      public function get ui() : DisplayObject
      {
         return this._ui;
      }
      
      public function setFighter(param1:GameRunFighterGroup = null) : void
      {
         this._ui.cacheAsBitmap = false;
         if(Boolean(param1.currentFighter))
         {
            this._face1.setData(param1.currentFighter.data);
         }
         switch(param1.currentFighter)
         {
            case param1.fighter1:
               this._face2.setData(param1.fighter2 ? param1.fighter2.data : null);
               this._face3.setData(param1.fighter3 ? param1.fighter3.data : null);
               break;
            case param1.fighter2:
               this._face2.setData(param1.fighter3 ? param1.fighter3.data : null);
               this._face3.setData(null);
               break;
            case param1.fighter3:
               this._face2.setData(null);
               this._face3.setData(null);
         }
         this._ui.cacheAsBitmap = true;
      }
      
      public function setDirect(param1:int) : void
      {
         this._face1.setDirect(param1);
         this._face2.setDirect(param1);
         this._face3.setDirect(param1);
      }
   }
}

