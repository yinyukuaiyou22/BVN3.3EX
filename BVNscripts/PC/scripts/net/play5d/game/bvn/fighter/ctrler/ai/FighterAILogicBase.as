package net.play5d.game.bvn.fighter.ctrler.ai
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.fighter.FighterAction;
   import net.play5d.game.bvn.fighter.FighterActionState;
   import net.play5d.game.bvn.fighter.FighterMC;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class FighterAILogicBase
   {
      
      protected var AILevel:int;
      
      private var _AImain:MovieClip;
      
      protected var _fighter:FighterMain;
      
      protected var _fighterAction:FighterAction;
      
      protected var _target:IGameSprite;
      
      protected var _targetFighter:FighterMain;
      
      protected var _isConting:Boolean;
      
      private var _breakActCache:Object = {};
      
      private var _hitDownActCache:Object = {};
      
      private var _contOrder:Array = [];
      
      protected var _attackAction:Object = {
         "招1":"zh1mian",
         "砍1":"kanmian",
         "招2":"zh2mian",
         "招3":"zh3mian",
         "砍技1":"kj1mian",
         "砍技2":"kj2mian",
         "跳砍":"tzmian",
         "跳招":"tkanmian"
      };
      
      public function FighterAILogicBase(param1:int, param2:FighterMain)
      {
         super();
         this.AILevel = param1;
         _fighter = param2;
      }
      
      protected static function mergeRateObject(param1:Object, param2:Object) : void
      {
         var _loc3_:int = 0;
         var _loc5_:int = 0;
         for(var _loc4_ in param2)
         {
            if(param1[_loc4_] == undefined)
            {
               param1[_loc4_] = param2[_loc4_];
            }
            else
            {
               _loc3_ = int(param2[_loc4_].length);
               _loc5_ = 0;
               while(_loc5_ < _loc3_)
               {
                  if(param1[_loc4_][_loc5_] < param2[_loc4_][_loc5_])
                  {
                     param1[_loc4_][_loc5_] = param2[_loc4_][_loc5_];
                  }
                  _loc5_++;
               }
            }
         }
      }
      
      public function destory() : void
      {
         _fighter = null;
         _fighterAction = null;
         _target = null;
         _targetFighter = null;
         _breakActCache = null;
         _hitDownActCache = null;
         _AImain = null;
         _attackAction = null;
      }
      
      protected function addContOrder(param1:String, param2:int) : void
      {
         var _loc3_:int = _contOrder.indexOf(param1);
         if(_loc3_ != -1)
         {
            _contOrder[_loc3_].order = param2;
         }
         else
         {
            _contOrder.push({
               "id":param1,
               "order":param2 + int(Math.random() * 10)
            });
         }
      }
      
      protected function updateConting() : void
      {
         _isConting = FighterActionState.isAttacking(_fighter.actionState);
      }
      
      public function render() : void
      {
         _target = _fighter.getCurrentTarget();
         if(_fighter == null || _target == null)
         {
            return;
         }
         _targetFighter = _target as FighterMain;
         updateConting();
         if(_fighterAction == null)
         {
            _fighterAction = _fighter.getCtrler().getMcCtrl().getAction();
         }
         updateActionAI();
         updateContOrder();
      }
      
      private function updateContOrder() : void
      {
         var _loc1_:int = 0;
         var _loc2_:String = null;
         if(_contOrder.length < 1)
         {
            return;
         }
         _contOrder.sortOn("order",2 | 0x10);
         _loc1_ = 1;
         while(_loc1_ < _contOrder.length)
         {
            _loc2_ = _contOrder[_loc1_].id;
            this[_loc2_] = false;
            _loc1_++;
         }
         _contOrder = [];
      }
      
      protected function updateActionAI() : void
      {
      }
      
      protected function getAIByFighterState(param1:Object) : Boolean
      {
         var _loc4_:Array = param1.defult;
         var _loc3_:int = int(_targetFighter != null ? _targetFighter.actionState : -1);
         var _loc2_:Array = param1 != null && param1[_loc3_] ? param1[_loc3_] : _loc4_;
         if(_loc2_ == null)
         {
            return false;
         }
         return getAIResult(_loc2_[0],_loc2_[1],_loc2_[2],_loc2_[3],_loc2_[4],_loc2_[5]);
      }
      
      protected function getAIResult(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number) : Boolean
      {
         var _loc7_:Number = Math.random() * 10;
         switch(AILevel)
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
      
      protected function getTargetDistance(param1:IGameSprite) : Point
      {
         if(param1 == null)
         {
            return null;
         }
         var _loc2_:Number = Math.abs(param1.x - _fighter.x);
         var _loc3_:Number = Math.abs(param1.y - _fighter.y);
         return new Point(_loc2_,_loc3_);
      }
      
      final public function targetInDistance(param1:IGameSprite, param2:Number, param3:Number) : Boolean
      {
         var _loc4_:Point = getTargetDistance(param1);
         return _loc4_.x <= param2 && _loc4_.y <= param3;
      }
      
      final public function targetInRange(param1:String) : Boolean
      {
         var _loc2_:Rectangle = _target.getBodyArea();
         if(_loc2_ == null)
         {
            return false;
         }
         var _loc4_:Rectangle = _fighter.getHitRange(param1);
         if(!_loc4_)
         {
            return false;
         }
         var _loc3_:Rectangle = _loc2_.intersection(_loc4_);
         return !_loc3_.isEmpty();
      }
      
      protected function get AImain() : MovieClip
      {
         var _loc1_:FighterMC = null;
         if(_AImain == null)
         {
            _loc1_ = _fighter.getMC();
            if(_loc1_ == null)
            {
               return null;
            }
            _AImain = _loc1_.getChildByName("AImain") as MovieClip;
         }
         return _AImain;
      }
      
      protected function setAIByMain(param1:Object, param2:String) : void
      {
         var _loc4_:Function = AImain.getActionAI as Function;
         if(AImain == null || _loc4_ == null)
         {
            return;
         }
         var _loc3_:Object = _loc4_(param2);
         if(_loc3_ != null)
         {
            for(var _loc5_ in _loc3_)
            {
               param1[_loc5_] = _loc3_[_loc5_];
            }
         }
      }
      
      protected function isBreakAct(param1:String) : Boolean
      {
         if(_breakActCache[param1] != undefined)
         {
            return _breakActCache[param1];
         }
         var _loc2_:Vector.<HitVO> = _fighter.getCtrler().hitModel.getHitVOLike(param1);
         for each(var _loc3_ in _loc2_)
         {
            if(_loc3_.isBreakDef)
            {
               _breakActCache[param1] = true;
               return true;
            }
         }
         _breakActCache[param1] = false;
         return false;
      }
      
      protected function isHitDownAct(param1:String) : Boolean
      {
         if(_hitDownActCache[param1] != undefined)
         {
            return _hitDownActCache[param1];
         }
         var _loc2_:Vector.<HitVO> = _fighter.getCtrler().hitModel.getHitVOLike(param1);
         for each(var _loc3_ in _loc2_)
         {
            if(_loc3_.hurtType == 1)
            {
               _breakActCache[param1] = true;
               return true;
            }
         }
         _breakActCache[param1] = false;
         return false;
      }
      
      protected function targetCanBeHit() : Boolean
      {
         if(_target == null)
         {
            return false;
         }
         if(_targetFighter != null)
         {
            return _targetFighter.actionState == 21 || _targetFighter.isAllowBeHit;
         }
         return _target.getBodyArea() != null;
      }
   }
}

