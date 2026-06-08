package net.play5d.game.bvn.ctrl.game_ctrls
{
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.TeamMap;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.state.GameState;
   
   public class GameMainLogicCtrler
   {
      
      public var renderHit:Boolean = true;
      
      private var _gameState:GameState;
      
      private var _leftSide:Number = 0;
      
      private var _rightSide:Number = 0;
      
      private var _teamMap:TeamMap;
      
      private var _renderAnimate:Boolean;
      
      public function GameMainLogicCtrler()
      {
         super();
      }
      
      public function initlize(param1:GameState, param2:TeamMap, param3:MapMain) : void
      {
         this._gameState = param1;
         this._teamMap = param2;
         this._leftSide = param3.left + 10;
         this._rightSide = param3.right - 10;
      }
      
      public function setSpeedPlus(param1:Number) : void
      {
         var _loc2_:TeamVO = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:IGameSprite = null;
         var _loc6_:int = 0;
         GameConfig.SPEED_PLUS = param1;
         var _loc7_:int = int(this._teamMap.teams.length);
         _loc3_ = 0;
         while(_loc3_ < _loc7_)
         {
            _loc2_ = this._teamMap.teams[_loc3_];
            _loc4_ = int(_loc2_.children.length);
            _loc6_ = 0;
            while(_loc6_ < _loc4_)
            {
               _loc5_ = _loc2_.children[_loc6_];
               if(Boolean(_loc5_) && !_loc5_.isDestoryed())
               {
                  _loc5_.setSpeedRate(param1);
               }
               _loc6_++;
            }
            _loc3_++;
         }
      }
      
      public function destory() : void
      {
      }
      
      public function render() : void
      {
         this.renderMainLogic();
      }
      
      private function renderMainLogic() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:IGameSprite = null;
         var _loc6_:IGameSprite = null;
         var _loc7_:TeamVO = null;
         var _loc8_:TeamVO = null;
         var _loc9_:* = undefined;
         var _loc10_:* = undefined;
         var _loc11_:int = 0;
         var _loc12_:Vector.<TeamVO> = this._teamMap.teams;
         var _loc13_:int = int(_loc12_.length);
         var _loc14_:Vector.<IGameSprite> = this._gameState.getGameSprites();
         _loc4_ = 0;
         while(_loc4_ < _loc14_.length)
         {
            this.renderGameSprite(_loc14_[_loc4_]);
            _loc4_++;
         }
         _loc4_ = 0;
         while(_loc4_ < _loc13_)
         {
            _loc8_ = _loc12_[_loc4_];
            _loc10_ = _loc8_.children;
            _loc1_ = 0;
            while(_loc1_ < _loc10_.length)
            {
               _loc6_ = _loc10_[_loc1_];
               if(!(_loc6_ == null || _loc6_.isDestoryed()))
               {
                  _loc2_ = _loc4_ + 1;
                  while(_loc2_ < _loc13_)
                  {
                     _loc7_ = _loc12_[_loc2_];
                     _loc9_ = _loc7_.children;
                     _loc11_ = int(_loc9_.length);
                     _loc3_ = 0;
                     while(_loc3_ < _loc11_)
                     {
                        _loc5_ = _loc9_[_loc3_];
                        if(!(_loc5_ == null || _loc5_.isDestoryed()))
                        {
                           this.checkBodyHit(_loc6_,_loc5_);
                           if(this._renderAnimate)
                           {
                              this.checkHit(_loc6_,_loc5_);
                           }
                        }
                        _loc3_++;
                     }
                     _loc2_++;
                  }
               }
               _loc1_++;
            }
            _loc4_++;
         }
         this._renderAnimate = false;
      }
      
      public function renderAnimate() : void
      {
         this._renderAnimate = true;
      }
      
      private function checkBodyHit(param1:IGameSprite, param2:IGameSprite) : void
      {
         var ba:BaseGameSprite = null;
         var bb:BaseGameSprite = null;
         var bodyA:Rectangle = null;
         var bodyB:Rectangle = null;
         var bodyHit:Rectangle = null;
         var vecA:Number = NaN;
         var vecB:Number = NaN;
         var overVec:Object = null;
         var vo:Object = null;
         var vo2:Object = null;
         var A:IGameSprite = null;
         var B:IGameSprite = null;
         A = param1;
         B = param2;
         var getVec:* = function(param1:Number):Object
         {
            var _loc2_:Number = bb.heavy / ba.heavy * 0.5;
            if(_loc2_ > 0.9)
            {
               _loc2_ = 0.9;
            }
            if(_loc2_ < 0.1)
            {
               _loc2_ = 0.1;
            }
            var _loc3_:* = param1 * _loc2_;
            var _loc4_:* = param1 * (1 - _loc2_);
            if(A.getIsTouchSide() && B.getIsTouchSide())
            {
               _loc3_ = param1;
               _loc4_ = param1;
            }
            else if(A.getIsTouchSide())
            {
               _loc3_ = 0;
               _loc4_ = param1;
            }
            else if(B.getIsTouchSide())
            {
               _loc4_ = 0;
               _loc3_ = param1;
            }
            return {
               "A":_loc3_,
               "B":_loc4_
            };
         };
         if(!this.renderHit)
         {
            return;
         }
         if(A is BaseGameSprite == false)
         {
            return;
         }
         if(B is BaseGameSprite == false)
         {
            return;
         }
         ba = A as BaseGameSprite;
         bb = B as BaseGameSprite;
         if(ba.isCross || bb.isCross)
         {
            return;
         }
         bodyA = A.getBodyArea();
         bodyB = B.getBodyArea();
         if(bodyA == null)
         {
            return;
         }
         if(bodyB == null)
         {
            return;
         }
         bodyHit = bodyA.intersection(bodyB);
         if(!bodyHit || bodyHit.isEmpty())
         {
            return;
         }
         vecA = ba.getVecX();
         vecB = bb.getVecX();
         if(ba.x < bb.x)
         {
            if(vecA < 0 && vecA < vecB || vecB > 0 && vecB > vecA)
            {
               return;
            }
            if(bodyHit.width > 2)
            {
               if(!overVec)
               {
                  overVec = getVec(5 * GameConfig.SPEED_PLUS);
               }
               ba.move(-overVec.A);
               bb.move(overVec.B);
            }
         }
         else
         {
            if(vecA > 0 && vecA > vecB || vecB < 0 && vecB < vecA)
            {
               return;
            }
            if(bodyHit.width > 2)
            {
               if(!overVec)
               {
                  overVec = getVec(5 * GameConfig.SPEED_PLUS);
               }
               ba.move(overVec.A);
               bb.move(-overVec.B);
            }
         }
         if(vecA != 0)
         {
            vo = getVec(vecA);
            bb.move(vo.B);
            ba.move(-vo.A);
         }
         if(vecB != 0)
         {
            vo2 = getVec(vecB);
            ba.move(vo2.A);
            bb.move(-vo2.B);
         }
      }
      
      private function renderGameSprite(param1:IGameSprite) : void
      {
         var _loc3_:BaseGameSprite = null;
         var _loc2_:Boolean = false;
         try
         {
            GameLogic.fixGameSpritePosition(param1);
            if(param1 is BaseGameSprite)
            {
               _loc3_ = param1 as BaseGameSprite;
               _loc2_ = Boolean(GameLogic.isInAir(_loc3_));
               if(_loc2_)
               {
                  _loc3_.applayG(12);
               }
               _loc3_.setInAir(_loc2_);
            }
            param1.render();
            if(Boolean(this._renderAnimate) && !param1.isDestoryed())
            {
               param1.renderAnimate();
            }
         }
         catch(e:Error)
         {
            Debugger.log("GameMainLogicCtrler.renderGameSprite",e);
         }
      }
      
      private function checkHit(param1:IGameSprite, param2:IGameSprite) : void
      {
         var _loc3_:Rectangle = null;
         var _loc4_:Rectangle = null;
         if(!this.renderHit)
         {
            return;
         }
         var _loc5_:Array = param1.getCurrentHits();
         var _loc6_:Array = param2.getCurrentHits();
         if(param1 is BaseGameSprite && !(param1 as BaseGameSprite).isAllowBeHit)
         {
            _loc3_ = null;
         }
         else
         {
            _loc3_ = param1.getBodyArea();
         }
         if(param2 is BaseGameSprite && !(param2 as BaseGameSprite).isAllowBeHit)
         {
            _loc4_ = null;
         }
         else
         {
            _loc4_ = param2.getBodyArea();
         }
         var _loc7_:Object = this.getHitObj(_loc5_,_loc4_);
         var _loc8_:Object = this.getHitObj(_loc6_,_loc3_);
         if(Boolean(_loc7_))
         {
            param2.beHit(_loc7_.hitVO,_loc7_.hitRect);
            param1.hit(_loc7_.hitVO,param2);
         }
         if(Boolean(_loc8_))
         {
            param1.beHit(_loc8_.hitVO,_loc8_.hitRect);
            param2.hit(_loc8_.hitVO,param1);
         }
      }
      
      private function getHitObj(param1:Array, param2:Rectangle) : Object
      {
         var _loc3_:int = 0;
         var _loc4_:Rectangle = null;
         var _loc5_:HitVO = null;
         var _loc6_:Rectangle = null;
         if(!param2)
         {
            return null;
         }
         if(!param1 || param1.length < 1)
         {
            return null;
         }
         var _loc7_:int = int(param1.length);
         _loc3_ = 0;
         while(_loc3_ < _loc7_)
         {
            _loc5_ = param1[_loc3_];
            if(_loc5_ != null)
            {
               _loc6_ = _loc5_.currentArea;
               if(_loc6_ != null)
               {
                  _loc4_ = _loc6_.intersection(param2);
                  if(Boolean(_loc4_) && _loc4_.isEmpty() == false)
                  {
                     return {
                        "hitVO":_loc5_,
                        "hitRect":_loc4_
                     };
                  }
               }
            }
            _loc3_++;
         }
         return null;
      }
      
      public function renderPause() : void
      {
      }
   }
}

