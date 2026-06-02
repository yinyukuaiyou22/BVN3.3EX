package net.play5d.game.bvn.data
{
   import flash.utils.Dictionary;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterMain;
   
   public class GameRunFighterGroup
   {
      
      public var fighter1:FighterVO;
      
      public var fighter2:FighterVO;
      
      public var fighter3:FighterVO;
      
      public var assister:FighterVO;
      
      private var _currentFighter:FighterMain;
      
      public var currentFighterVO:FighterVO;
      
      public var currentAssister:Assister;
      
      private var _fighterMap:Dictionary;
      
      public var limitLevel:int;
      
      public function GameRunFighterGroup()
      {
         super();
      }
      
      public function destory() : void
      {
         fighter1 = null;
         fighter2 = null;
         fighter3 = null;
         assister = null;
         if(currentFighter != null)
         {
            currentFighter.destory(true);
            currentFighter = null;
            currentFighterVO = null;
         }
         if(currentAssister != null)
         {
            currentAssister.destory(true);
            currentAssister = null;
         }
      }
      
      public function get currentFighter() : FighterMain
      {
         return _currentFighter;
      }
      
      public function set currentFighter(param1:FighterMain) : void
      {
         _currentFighter = param1;
         if(_currentFighter != null && _currentFighter.data != null)
         {
            currentFighterVO = _currentFighter.data;
         }
      }
      
      public function getFighters(param1:Boolean = false) : Vector.<FighterVO>
      {
         var _loc3_:Vector.<FighterVO> = new Vector.<FighterVO>();
         var _loc2_:FighterVO = currentFighter ? currentFighter.data : null;
         if(param1)
         {
            if(fighter1 != _loc2_)
            {
               _loc3_.push(fighter1);
            }
            if(fighter2 != _loc2_)
            {
               _loc3_.push(fighter2);
            }
            if(fighter3 != _loc2_)
            {
               _loc3_.push(fighter3);
            }
         }
         else
         {
            _loc3_.push(fighter1);
            _loc3_.push(fighter2);
            _loc3_.push(fighter3);
         }
         return _loc3_;
      }
      
      public function getAliveFighters() : Vector.<FighterMain>
      {
         var _loc3_:Vector.<FighterMain> = new Vector.<FighterMain>();
         var _loc2_:FighterMain = getFighter(fighter1);
         var _loc4_:FighterMain = getFighter(fighter2);
         var _loc1_:FighterMain = getFighter(fighter3);
         if(_loc2_ && _loc2_.isAlive)
         {
            _loc3_.push(_loc2_);
         }
         if(_loc4_ && _loc4_.isAlive)
         {
            _loc3_.push(_loc4_);
         }
         if(_loc1_ && _loc1_.isAlive)
         {
            _loc3_.push(_loc1_);
         }
         return _loc3_;
      }
      
      public function getNextAliveFighter() : FighterMain
      {
         if(!currentFighter)
         {
            return null;
         }
         var _loc2_:Vector.<FighterMain> = getAliveFighters();
         if(_loc2_.length < 1)
         {
            return null;
         }
         var _loc1_:int = _loc2_.indexOf(currentFighter);
         if(_loc1_ == _loc2_.length - 1)
         {
            return _loc2_[0];
         }
         return _loc2_[_loc1_ + 1];
      }
      
      public function getNextFighter(param1:Boolean = false) : FighterVO
      {
         if(!currentFighter)
         {
            return null;
         }
         switch(currentFighter.data)
         {
            case fighter1:
               return fighter2;
            case fighter2:
               return fighter3;
            case fighter3:
               return param1 ? fighter1 : null;
            default:
               return null;
         }
      }
      
      public function putFighter(param1:FighterMain) : void
      {
         if(!_fighterMap)
         {
            _fighterMap = new Dictionary();
         }
         _fighterMap[param1.data] = param1;
      }
      
      public function getFighter(param1:FighterVO) : FighterMain
      {
         if(!_fighterMap)
         {
            return null;
         }
         return _fighterMap[param1];
      }
      
      public function getHoldFighters() : Vector.<FighterMain>
      {
         if(!currentFighter)
         {
            return null;
         }
         var _loc2_:Vector.<FighterMain> = getAliveFighters();
         var _loc1_:int = _loc2_.indexOf(currentFighter);
         if(_loc1_ != -1)
         {
            _loc2_.splice(_loc1_,1);
         }
         return _loc2_;
      }
   }
}

