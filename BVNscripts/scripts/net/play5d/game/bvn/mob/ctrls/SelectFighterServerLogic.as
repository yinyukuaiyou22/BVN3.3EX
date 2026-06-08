package net.play5d.game.bvn.mob.ctrls
{
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.state.*;
   
   public class SelectFighterServerLogic
   {
      
      private var _timeout:int;
      
      public function SelectFighterServerLogic()
      {
         super();
      }
      
      public function init() : void
      {
         SelectFighterStage.AUTO_FINISH = false;
         LoadingState.AUTO_START_GAME = false;
         GameEvent.addEventListener("SELECT_FIGHTER_STEP",this.onSelectStep);
         GameEvent.addEventListener("SELECT_FIGHTER_FINISH",this.onSelectFinish);
         GameEvent.addEventListener("SELECT_FIGHTER_INDEX",this.onSelectFighterIndex);
      }
      
      public function dispose() : void
      {
         GameEvent.removeEventListener("SELECT_FIGHTER_STEP",this.onSelectStep);
         GameEvent.removeEventListener("SELECT_FIGHTER_FINISH",this.onSelectFinish);
         GameEvent.removeEventListener("SELECT_FIGHTER_INDEX",this.onSelectFighterIndex);
      }
      
      public function receiveSelect(param1:Object) : Boolean
      {
         var _loc5_:int = 0;
         var _loc2_:SelectFighterStage = null;
         var _loc3_:LoadingState = null;
         var _loc4_:Array = param1 as Array;
         if(!_loc4_ || _loc4_[0] != "SELECT")
         {
            return false;
         }
         switch((_loc5_ = int(param1[1])) - 1)
         {
            case 0:
               try
               {
                  _loc2_ = MainGame.stageCtrl.currentStage as SelectFighterStage;
                  _loc2_.setSelect(2,_loc4_[2]);
                  this.checkSelectFinish();
               }
               catch(e:Error)
               {
               }
               break;
            case 3:
               try
               {
                  _loc3_ = MainGame.stageCtrl.currentStage as LoadingState;
                  _loc3_.setOrder(2,param1[2]);
                  this.checkSelectIndexFinish();
               }
               catch(e:Error)
               {
               }
         }
         return true;
      }
      
      private function onSelectStep(param1:GameEvent) : void
      {
         var _loc2_:Array = ["SELECT",1,param1.param];
         LANServerCtrl.I.sendTCP(_loc2_);
         this.checkSelectFinish();
      }
      
      private function checkSelectFinish() : void
      {
         var stg:SelectFighterStage = null;
         stg = MainGame.stageCtrl.currentStage as SelectFighterStage;
         if(stg.p1SelectFinish && stg.p2SelectFinish)
         {
            clearTimeout(this._timeout);
            this._timeout = setTimeout(function():void
            {
               LANServerCtrl.I.sendTCP(["SELECT",2]);
               stg.nextStep();
            },1000);
         }
      }
      
      private function onSelectFinish(param1:GameEvent) : void
      {
         var _loc2_:Array = ["SELECT",3,GameData.I.p1Select.fighter1,GameData.I.p1Select.fighter2,GameData.I.p1Select.fighter3,GameData.I.p1Select.fuzhu,GameData.I.p2Select.fighter1,GameData.I.p2Select.fighter2,GameData.I.p2Select.fighter3,GameData.I.p2Select.fuzhu,GameData.I.selectMap];
         LANServerCtrl.I.sendTCP(_loc2_);
         var _loc3_:SelectFighterStage = MainGame.stageCtrl.currentStage as SelectFighterStage;
         _loc3_.goLoadGame();
      }
      
      private function onSelectFighterIndex(param1:GameEvent) : void
      {
         var _loc2_:Array = ["SELECT",4,param1.param];
         LANServerCtrl.I.sendTCP(_loc2_);
         this.checkSelectIndexFinish();
      }
      
      private function checkSelectIndexFinish() : void
      {
         var stg:LoadingState = null;
         try
         {
            stg = MainGame.stageCtrl.currentStage as LoadingState;
            if(stg.selectFinish())
            {
               setTimeout(function():void
               {
                  var _loc1_:Array = stg.getSort();
                  LANServerCtrl.I.sendTCP(["SELECT",5,_loc1_[0],_loc1_[1]]);
                  stg.gotoGame(_loc1_[0],_loc1_[1]);
               },1000);
            }
         }
         catch(e:Error)
         {
         }
      }
   }
}

