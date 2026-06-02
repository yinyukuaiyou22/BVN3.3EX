package net.play5d.game.bvn.ctrl.game_ctrls
{
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.data.TeamMap;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.stage.GameStage;
   import net.play5d.game.bvn.views.effects.BitmapFilterView;
   
   public class GameMainLogicCtrler
   {
      
      public var renderHit:Boolean = true;
      
      private var _gameState:GameStage;
      
      private var _leftSide:Number = 0;
      
      private var _rightSide:Number = 0;
      
      private var _teamMap:TeamMap;
      
      private var _renderAnimate:Boolean;
      
      public function GameMainLogicCtrler()
      {
         super();
      }
      
      private static function getHitObj(param1:Array, param2:Rectangle) : Object
      {
         var _loc3_:Rectangle = null;
         var _loc5_:Rectangle = null;
         if(param2 == null)
         {
            return null;
         }
         if(param1 == null || param1.length < 1)
         {
            return null;
         }
         for each(var _loc4_ in param1)
         {
            if(_loc4_ != null)
            {
               _loc3_ = _loc4_.clone().currentArea;
               if(_loc3_ != null)
               {
                  if(_loc4_.isCatch())
                  {
                     _loc3_.width += 4;
                     _loc3_.x -= 2;
                  }
                  _loc5_ = _loc3_.intersection(param2);
                  if(!(_loc5_ == null || _loc5_.isEmpty()))
                  {
                     return {
                        "hitVO":_loc4_,
                        "hitRect":_loc5_
                     };
                  }
               }
            }
         }
         return null;
      }
      
      public function initlize(param1:GameStage, param2:TeamMap) : void
      {
         _gameState = param1;
         _teamMap = param2;
         var _loc3_:MapMain = param1.getMap();
         _leftSide = _loc3_.left + 10;
         _rightSide = _loc3_.right - 10;
      }
      
      public function setSpeedPlus(param1:Number) : void
      {
         GameConfig.SPEED_PLUS = param1;
         for each(var _loc2_ in _teamMap.teams)
         {
            for each(var _loc3_ in _loc2_.children)
            {
               if(_loc3_ != null && !_loc3_.isDestoryed())
               {
                  _loc3_.setSpeedRate(param1);
               }
            }
         }
      }
      
      public function destory() : void
      {
      }
      
      public function render() : void
      {
         renderMainLogic();
      }
      
      private function renderMainLogic() : void
      {
         var _loc10_:IGameSprite = null;
         var _loc7_:FighterMain = null;
         var _loc11_:IGameSprite = null;
         var _loc8_:int = 0;
         var _loc3_:Vector.<TeamVO> = _teamMap.teams;
         var _loc1_:Vector.<IGameSprite> = _gameState.getGameSprites();
         for each(_loc10_ in _loc1_)
         {
            if(_loc10_ is FighterMain)
            {
               _loc7_ = _loc10_ as FighterMain;
               _loc11_ = (_loc7_ as FighterMain).getCurrentTarget();
               if(_loc11_ && _loc11_ is FighterMain)
               {
                  _loc7_.targetX = (_loc11_ as FighterMain).x;
                  _loc7_.targetXMove = (_loc11_ as FighterMain).getVecX() + (_loc11_ as FighterMain).getVec2().x;
               }
               else
               {
                  _loc7_.targetX = NaN;
                  _loc7_.targetXMove = 0;
               }
            }
         }
         _loc8_ = 0;
         while(_loc8_ < _loc1_.length)
         {
            _loc10_ = _loc1_[_loc8_];
            renderGameSprite(_loc10_);
            if(_loc10_ == null || _loc10_.isDestoryed())
            {
               _loc8_--;
            }
            _loc8_++;
         }
         var _loc9_:TeamVO = _loc3_[0];
         var _loc5_:Vector.<IGameSprite> = _loc9_.children;
         var _loc6_:TeamVO = _loc3_[1];
         var _loc2_:Vector.<IGameSprite> = _loc6_.children;
         for each(_loc10_ in _loc5_)
         {
            if(!(_loc10_ == null || _loc10_.isDestoryed()))
            {
               for each(var _loc4_ in _loc2_)
               {
                  if(!(_loc4_ == null || _loc4_.isDestoryed()))
                  {
                     checkBodyHit(_loc10_,_loc4_);
                     if(_renderAnimate)
                     {
                        checkHit(_loc10_,_loc4_);
                     }
                  }
               }
            }
         }
         for each(_loc10_ in _loc1_)
         {
            if(_loc10_ is BitmapFilterView)
            {
               (_loc10_ as BitmapFilterView).render();
            }
         }
         _renderAnimate = false;
      }
      
      public function renderAnimate() : void
      {
         _renderAnimate = true;
      }
      
      private function checkBodyHit(param1:IGameSprite, param2:IGameSprite) : void
      {
         var ba:BaseGameSprite;
         var bb:BaseGameSprite;
         var bodyA:Rectangle;
         var bodyB:Rectangle;
         var bodyHit:Rectangle;
         var bodyRoom:Number;
         var vecA:Number;
         var vecB:Number;
         var mcCtrlA:*;
         var aFrontPushing:Boolean;
         var mcCtrlB:*;
         var bFrontPushing:Boolean;
         var overVec:Object;
         var vo:Object;
         var vo2:Object;
         var vo3:Object;
         var wallOffset:int;
         var posOffset:Number;
         var posCorrect:Number;
         var A:IGameSprite = param1;
         var B:IGameSprite = param2;
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
            var _loc4_:Number = param1 * _loc2_;
            var _loc3_:Number = param1 * (1 - _loc2_);
            if(A.getIsTouchSide() && B.getIsTouchSide())
            {
               _loc4_ = 0;
               _loc3_ = 0;
            }
            else if(A.getIsTouchSide())
            {
               _loc4_ = 0;
               _loc3_ = param1;
            }
            else if(B.getIsTouchSide())
            {
               _loc4_ = param1;
               _loc3_ = 0;
            }
            return {
               "A":_loc4_,
               "B":_loc3_
            };
         };
         if(!renderHit)
         {
            return;
         }
         if(!(A is BaseGameSprite) || !(B is BaseGameSprite))
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
         if(bodyA == null || bodyB == null)
         {
            return;
         }
         bodyHit = bodyA.intersection(bodyB);
         if(!bodyHit || bodyHit.isEmpty())
         {
            return;
         }
         if(ba.x < bb.x)
         {
            bodyRoom = bodyA.right - ba.x + (bb.x - bodyB.left);
         }
         else
         {
            bodyRoom = bodyB.right - bb.x + (ba.x - bodyA.left);
         }
         vecA = ba.getVecX();
         vecB = bb.getVecX();
         if(ba is FighterMain)
         {
            mcCtrlA = (ba as FighterMain).getCtrler().getMcCtrl();
            aFrontPushing = ba.direct * (bb.x - ba.x) > 0;
            if(aFrontPushing && ((ba as FighterMain).actionState == 14 || mcCtrlA.getAction().airMove))
            {
               if(mcCtrlA.getActionCtrler().moveLEFT())
               {
                  vecA += -((ba as FighterMain).speed + (ba as FighterMain).speedAdd);
               }
               if(mcCtrlA.getActionCtrler().moveRIGHT())
               {
                  vecA += (ba as FighterMain).speed + (ba as FighterMain).speedAdd;
               }
            }
         }
         if(bb is FighterMain)
         {
            mcCtrlB = (bb as FighterMain).getCtrler().getMcCtrl();
            bFrontPushing = bb.direct * (ba.x - bb.x) > 0;
            if(bFrontPushing && ((bb as FighterMain).actionState == 14 || mcCtrlB.getAction().airMove))
            {
               if(mcCtrlB.getActionCtrler().moveLEFT())
               {
                  vecB += -((bb as FighterMain).speed + (bb as FighterMain).speedAdd);
               }
               if(mcCtrlB.getActionCtrler().moveRIGHT())
               {
                  vecB += (bb as FighterMain).speed + (bb as FighterMain).speedAdd;
               }
            }
         }
         overVec = null;
         if(ba.x < bb.x)
         {
            if(vecA < 0 && vecA < vecB || vecB > 0 && vecB > vecA)
            {
               return;
            }
            if(bodyHit.width >= 4)
            {
               if(!overVec)
               {
                  overVec = getVec(4 * GameConfig.SPEED_PLUS);
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
            if(bodyHit.width >= 4)
            {
               if(!overVec)
               {
                  overVec = getVec(4 * GameConfig.SPEED_PLUS);
               }
               ba.move(overVec.A);
               bb.move(-overVec.B);
            }
         }
         if(vecA != 0)
         {
            vo = getVec(vecA);
            ba.move(-vo.A);
            bb.move(vo.B);
         }
         if(vecB != 0)
         {
            vo2 = getVec(vecB);
            ba.move(vo2.A);
            bb.move(-vo2.B);
         }
         wallOffset = 40;
         posOffset = 2;
         if(ba.x < this._leftSide + wallOffset || ba.x > this._rightSide - wallOffset || (bb.x < this._leftSide + wallOffset || bb.x > this._rightSide - wallOffset))
         {
            posOffset += -8;
         }
         posCorrect = Math.abs(bb.x - ba.x) - bodyRoom + posOffset;
         if(posCorrect <= 0)
         {
            ba.updatePosition();
            bb.updatePosition();
            return;
         }
         if(ba.x < bb.x)
         {
            vo3 = getVec(posCorrect);
            ba.move(vo3.A);
            bb.move(-vo3.B);
         }
         else
         {
            vo3 = getVec(posCorrect);
            ba.move(-vo3.A);
            bb.move(vo3.B);
         }
         ba.updatePosition();
         bb.updatePosition();
      }
      
      private function renderGameSprite(param1:IGameSprite) : void
      {
         var _loc3_:BaseGameSprite = null;
         var _loc2_:Boolean = false;
         try
         {
            if(param1 is BaseGameSprite)
            {
               _loc3_ = param1 as BaseGameSprite;
               _loc2_ = GameLogic.isInAir(_loc3_);
               if(_loc2_)
               {
                  _loc3_.applayG(12);
               }
               _loc3_.setInAir(_loc2_);
            }
            param1.render();
            GameLogic.fixGameSpritePositionX(param1);
            GameLogic.fixGameSpritePositionY(param1);
            if(_renderAnimate && !param1.isDestoryed())
            {
               param1.renderAnimate();
            }
         }
         catch(e:Error)
         {
         }
      }
      
      private function checkHit(param1:IGameSprite, param2:IGameSprite) : void
      {
         if(!renderHit)
         {
            return;
         }
         var _loc8_:Array = param1.getCurrentHits();
         var _loc7_:Array = param2.getCurrentHits();
         var _loc5_:Rectangle = param1 is BaseGameSprite && !(param1 as BaseGameSprite).isAllowBeHit ? null : param1.getBodyArea();
         var _loc6_:Rectangle = param2 is BaseGameSprite && !(param2 as BaseGameSprite).isAllowBeHit ? null : param2.getBodyArea();
         var _loc4_:Object = getHitObj(_loc8_,_loc6_);
         var _loc3_:Object = getHitObj(_loc7_,_loc5_);
         if(_loc4_ != null)
         {
            param2.beHit(_loc4_.hitVO,_loc4_.hitRect);
            param1.hit(_loc4_.hitVO,param2);
         }
         if(_loc3_ != null)
         {
            param1.beHit(_loc3_.hitVO,_loc3_.hitRect);
            param2.hit(_loc3_.hitVO,param1);
         }
      }
      
      public function renderPause() : void
      {
      }
   }
}

