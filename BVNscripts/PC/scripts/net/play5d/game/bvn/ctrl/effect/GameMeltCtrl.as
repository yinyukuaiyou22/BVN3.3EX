package net.play5d.game.bvn.ctrl.effect
{
   import flash.geom.Point;
   import nagisa.filters.FilterManager;
   import nagisa.filters.ctrlers.MeltCtrler;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.stage.GameStage;
   
   public class GameMeltCtrl extends MeltCtrler
   {
      
      public function GameMeltCtrl()
      {
         super();
      }
      
      override public function initialize(param1:FilterManager, param2:Function = null) : void
      {
         var _loc3_:GameStage = GameCtrl.I.gameState;
         super.initialize(_loc3_.filterManager,_transformPosition);
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         super.destory(param1);
      }
      
      private function _transformPosition(param1:Number, param2:Number) : Point
      {
         return GameCtrl.I.gameState.toLocalPosition(null,new Point(param1,param2));
      }
   }
}

