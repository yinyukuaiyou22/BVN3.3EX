package net.play5d.game.bvn.ctrl.game_ctrls
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   
   public class TrainingCtrler
   {
      
      public static var RECOVER_HP:Boolean = true;
      
      public static var RECOVER_QI:Boolean = true;
      
      public static var RECOVER_FZ_QI:Boolean = true;
      
      public static var SAY_INTRO:Boolean = false;
      
      private var _trainAddDelay:Object;
      
      private var _fighters:Array;
      
      public function TrainingCtrler()
      {
         super();
      }
      
      public function initlize(param1:Array) : void
      {
         var _loc2_:* = undefined;
         this._fighters = param1;
         for each(_loc2_ in this._fighters)
         {
            _loc2_.qi = 300;
         }
         this._trainAddDelay = {};
         StateCtrl.I.transOut(null,true);
      }
      
      public function destory() : void
      {
         this._fighters = null;
         this._trainAddDelay = null;
      }
      
      public function render() : void
      {
         var _loc4_:* = undefined;
         var _loc1_:String = null;
         var _loc2_:String = null;
         var _loc3_:String = null;
         for each(_loc4_ in this._fighters)
         {
            _loc1_ = _loc4_.id + "_hp";
            if(_loc4_.actionState == 21 || _loc4_.actionState == 22)
            {
               this._trainAddDelay[_loc1_] = 1 * GameConfig.FPS_GAME;
            }
            else if(this._trainAddDelay[_loc1_] != undefined && this._trainAddDelay[_loc1_] > 0)
            {
               --this._trainAddDelay[_loc1_];
               if(this._trainAddDelay[_loc1_] <= 0 && RECOVER_HP)
               {
                  _loc4_.hp = _loc4_.hpMax;
               }
            }
            else if(_loc4_.hp == _loc4_.hpMax)
            {
               this._trainAddDelay[_loc1_] = 0;
            }
            else
            {
               this._trainAddDelay[_loc1_] = 2 * GameConfig.FPS_GAME;
            }
            _loc2_ = _loc4_.id + "_qi";
            if(this._trainAddDelay[_loc2_] != undefined && this._trainAddDelay[_loc2_] > 0)
            {
               --this._trainAddDelay[_loc2_];
               if(this._trainAddDelay[_loc2_] <= 0 && RECOVER_QI)
               {
                  _loc4_.qi = 300;
               }
            }
            else if(_loc4_.qi == 300)
            {
               this._trainAddDelay[_loc2_] = 0;
            }
            else
            {
               this._trainAddDelay[_loc2_] = 2 * GameConfig.FPS_GAME;
            }
            _loc3_ = _loc4_.id + "fz";
            if(this._trainAddDelay[_loc3_] != undefined && this._trainAddDelay[_loc3_] > 0)
            {
               --this._trainAddDelay[_loc3_];
               if(this._trainAddDelay[_loc3_] <= 0 && RECOVER_FZ_QI)
               {
                  _loc4_.fzqi = 100;
               }
            }
            else if(_loc4_.fzqi == 100)
            {
               this._trainAddDelay[_loc3_] = 0;
            }
            else
            {
               this._trainAddDelay[_loc3_] = 2 * GameConfig.FPS_GAME;
            }
         }
      }
   }
}

