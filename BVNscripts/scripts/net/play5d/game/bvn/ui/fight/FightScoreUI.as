package net.play5d.game.bvn.ui.fight
{
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.*;
   
   public class FightScoreUI
   {
      
      private var _ui:*;
      
      private var _nummc:MCNumber;
      
      public function FightScoreUI(param1:*)
      {
         super();
         this._ui = param1;
         var _loc2_:Class = ResUtils.I.getItemClass(ResUtils.I.fight,"txtmc_score");
         this._nummc = new MCNumber(_loc2_,0,1,10,10);
         this._ui.ct.addChild(this._nummc);
      }
      
      public function setScore(param1:int) : void
      {
         this._nummc.number = param1;
      }
   }
}

