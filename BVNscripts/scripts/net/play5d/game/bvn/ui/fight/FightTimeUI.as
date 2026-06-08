package net.play5d.game.bvn.ui.fight
{
   import flash.display.DisplayObject;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.*;
   
   public class FightTimeUI
   {
      
      private var _ui:*;
      
      private var _numMc:MCNumber;
      
      private var _renderTime:Boolean;
      
      public function FightTimeUI(param1:*)
      {
         var _loc2_:Class = null;
         super();
         this._ui = param1;
         var _loc3_:int = int(GameCtrl.I.gameRunData.gameTimeMax);
         if(_loc3_ == -1)
         {
            this._renderTime = false;
            this._ui.wuxian.visible = true;
         }
         else
         {
            this._renderTime = true;
            _loc2_ = ResUtils.I.getItemClass(ResUtils.I.fight,"time_txtmc");
            this._numMc = new MCNumber(_loc2_,0,1,20,2);
            this._numMc.x = -22;
            this._numMc.y = -15;
            this._ui.addChild(this._numMc);
            this._ui.wuxian.visible = false;
            this._numMc.number = _loc3_;
         }
      }
      
      public function get timeUI() : DisplayObject
      {
         return this._numMc;
      }
      
      public function render() : void
      {
         if(!this._renderTime)
         {
            return;
         }
         var _loc1_:int = int(GameCtrl.I.gameRunData.gameTime);
         this._numMc.number = _loc1_;
      }
   }
}

