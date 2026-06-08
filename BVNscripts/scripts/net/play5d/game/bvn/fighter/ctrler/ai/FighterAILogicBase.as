package net.play5d.game.bvn.fighter.ctrler.ai
{
   import flash.display.*;
   import flash.geom.*;
   
   public class FighterAILogicBase
   {
      
      protected var AILevel:int;
      
      protected var _fighter:*;
      
      protected var _fighterAction:*;
      
      protected var _target:*;
      
      protected var _targetFighter:*;
      
      protected var _isConting:Boolean;
      
      private var _breakActCache:Object = {};
      
      private var _hitDownActCache:Object = {};
      
      private var _contOrder:Array = [];
      
      private var _AImain:MovieClip = null;
      
      public function FighterAILogicBase(param1:int, param2:*)
      {
         super();
         this.AILevel = param1;
         this._fighter = param2;
      }
      
      public function destory() : void
      {
         this._fighter = null;
         this._fighterAction = null;
         this._target = null;
         this._targetFighter = null;
         this._breakActCache = null;
         this._hitDownActCache = null;
      }
      
      protected function addContOrder(param1:String, param2:int) : void
      {
         var _loc3_:int = int(this._contOrder.indexOf(param1));
         if(_loc3_ != -1)
         {
            this._contOrder[_loc3_].order = param2;
         }
         else
         {
            this._contOrder.push({
               "id":param1,
               "order":param2 + Math.floor(Math.random() * 10)
            });
         }
      }
      
      protected function updateConting() : void
      {
         this._isConting = this._fighter.actionState == 10 || this._fighter.actionState == 11 || this._fighter.actionState == 12 || this._fighter.actionState == 13;
      }
      
      public function render() : void
      {
         this._target = this._fighter.getCurrentTarget();
         this._targetFighter = this._target;
         this.updateConting();
         if(!this._fighterAction)
         {
            this._fighterAction = this._fighter.getCtrler().getMcCtrl().getAction();
         }
         this.updateActionAI();
         this.updateContOrder();
      }
      
      private function updateContOrder() : void
      {
         var _loc1_:int = 0;
         var _loc2_:* = null;
         if(this._contOrder.length < 1)
         {
            return;
         }
         this._contOrder.sortOn("order",2 | 0x10);
         _loc1_ = 1;
         while(_loc1_ < this._contOrder.length)
         {
            _loc2_ = this._contOrder[_loc1_].id;
            this[_loc2_] = false;
            _loc1_++;
         }
         this._contOrder = [];
      }
      
      protected function updateActionAI() : void
      {
      }
      
      protected function getAIByFighterState(param1:Object) : Boolean
      {
         var _loc2_:* = null;
         var _loc3_:Array = param1.defult;
         var _loc4_:int = int(this._targetFighter ? this._targetFighter.actionState : -1);
         _loc2_ = Boolean(param1) && Boolean(param1[_loc4_]) ? param1[_loc4_] : _loc3_;
         return this.getAIResult(_loc2_[0],_loc2_[1],_loc2_[2],_loc2_[3],_loc2_[4],_loc2_[5]);
      }
      
      protected function getAIResult(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number) : Boolean
      {
         var _loc7_:Number = Math.random() * 10;
         switch(int(this.AILevel))
         {
            case 0:
            case 1:
               return _loc7_ < param1;
            case 2:
               return _loc7_ < param2;
            case 3:
               return _loc7_ < param3;
            case 4:
               return _loc7_ < param4;
            case 5:
               return _loc7_ < param5;
            default:
               return _loc7_ < param6;
         }
      }
      
      protected function getTargetDistance(param1:*) : Point
      {
         var _loc2_:Number = Math.abs(param1.x - this._fighter.x);
         var _loc3_:Number = Math.abs(param1.y - this._fighter.y);
         return new Point(_loc2_,_loc3_);
      }
      
      protected function targetInDistance(param1:*, param2:Number, param3:Number) : Boolean
      {
         var _loc4_:Point = null;
         _loc4_ = this.getTargetDistance(param1);
         return _loc4_.x <= param2 && _loc4_.y <= param3;
      }
      
      protected function targetInRange(param1:String) : Boolean
      {
         var _loc2_:Rectangle = this._target.getBodyArea();
         if(!_loc2_)
         {
            return false;
         }
         var _loc3_:Rectangle = this._fighter.getHitRange(param1);
         if(!_loc3_)
         {
            return false;
         }
         return _loc2_.intersection(_loc3_).isEmpty() == false;
      }
      
      protected function get AImain() : MovieClip
      {
         if(Boolean(this._AImain))
         {
            return this._AImain;
         }
         var fighterMC:* = this._fighter.getMC();
         if(!fighterMC)
         {
            return null;
         }
         return this._AImain = fighterMC.getChildByName("AImain") as MovieClip;
      }
      
      protected function setAIByMain(param1:Object, param2:String) : void
      {
         var currentAI:Object = null;
         var i:Object = null;
         if(Boolean(this.AImain) && Boolean(this.AImain.getActionAI) && !!(currentAI = this.AImain.getActionAI(param2)))
         {
            for(i in currentAI)
            {
               param1[i] = currentAI[i];
            }
         }
      }
      
      protected function mergeRateObject(param1:Object, param2:Object) : void
      {
         var _loc3_:* = undefined;
         var _loc4_:int = 0;
         for(_loc3_ in param2)
         {
            if(param1[_loc3_] == undefined)
            {
               param1[_loc3_] = param2[_loc3_];
            }
            else
            {
               while(_loc4_ < param2[_loc3_].length)
               {
                  if(param1[_loc3_][_loc4_] < param2[_loc3_][_loc4_])
                  {
                     param1[_loc3_][_loc4_] = param2[_loc3_][_loc4_];
                  }
                  _loc4_++;
               }
            }
         }
      }
      
      protected function isBreakAct(param1:String) : Boolean
      {
         var _loc2_:* = undefined;
         if(this._breakActCache[param1] != undefined)
         {
            return this._breakActCache[param1];
         }
         var _loc3_:Vector.<*> = this._fighter.getCtrler().hitModel.getHitVOLike(param1);
         for each(_loc2_ in _loc3_)
         {
            if(Boolean(_loc2_.isBreakDef))
            {
               this._breakActCache[param1] = true;
               return true;
            }
         }
         this._breakActCache[param1] = false;
         return false;
      }
      
      protected function isHitDownAct(param1:String) : Boolean
      {
         var _loc2_:* = undefined;
         if(this._hitDownActCache[param1] != undefined)
         {
            return this._hitDownActCache[param1];
         }
         var _loc3_:Vector.<*> = this._fighter.getCtrler().hitModel.getHitVOLike(param1);
         for each(_loc2_ in _loc3_)
         {
            if(_loc2_.hurtType == 1)
            {
               this._breakActCache[param1] = true;
               return true;
            }
         }
         this._breakActCache[param1] = false;
         return false;
      }
      
      protected function targetCanBeHit() : Boolean
      {
         if(!this._target)
         {
            return false;
         }
         if(Boolean(this._targetFighter))
         {
            return this._targetFighter.isAllowBeHit;
         }
         return this._target.getBodyArea() != null;
      }
   }
}

