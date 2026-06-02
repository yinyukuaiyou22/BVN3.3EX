package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   import net.play5d.game.bvn.fighter.models.FighterHitModel;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.fighter.vos.MoveTargetParamVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class AssisiterCtrler
   {
      
      public var hitModel:FighterHitModel;
      
      private var _effectCtrl:FighterEffectCtrl;
      
      private var _assister:Assister;
      
      private var _touchFloor:Boolean;
      
      private var _touchFloorFrame:String;
      
      private var _hitTargetChecker:String;
      
      private var _hitTargetAction:String;
      
      private var _isCheckTargetIsAllowBeHit:Boolean;
      
      private var _isResponseTargetGameSprite:Boolean;
      
      private var _hitOwnerChecker:String;
      
      private var _touchSideAction:String;
      
      private var _moveTargetParam:MoveTargetParamVO;
      
      private var _isMovingTarget:Boolean = false;
      
      public function AssisiterCtrler()
      {
         super();
      }
      
      public function get effect() : FighterEffectCtrl
      {
         return _effectCtrl;
      }
      
      public function destory() : void
      {
         if(_effectCtrl)
         {
            _effectCtrl.destory();
            _effectCtrl = null;
         }
         if(hitModel)
         {
            hitModel.destory();
            hitModel = null;
         }
         _moveTargetParam = null;
         _assister = null;
      }
      
      public function getTarget() : IGameSprite
      {
         var _loc1_:FighterMain = _assister.getOwner() as FighterMain;
         if(_loc1_ != null)
         {
            return _loc1_.getCurrentTarget();
         }
         return null;
      }
      
      public function getOwner() : IGameSprite
      {
         if(_assister == null)
         {
            return null;
         }
         return _assister.getOwner();
      }
      
      public function getSelf() : Assister
      {
         return _assister;
      }
      
      public function setDirectReverse() : void
      {
         _assister.direct *= -1;
      }
      
      public function setApplyG(param1:Boolean) : void
      {
         _assister.isApplyG = param1;
      }
      
      public function setAllowCrossFloor(param1:Boolean) : void
      {
         _assister.isAllowCrossFloor = param1;
      }
      
      public function get targetChecker() : String
      {
         return _hitTargetChecker;
      }
      
      public function get ownerChecker() : String
      {
         return _hitOwnerChecker;
      }
      
      public function finish(param1:Boolean = true) : void
      {
         if(param1)
         {
            EffectCtrl.I.assisterEffect(_assister);
         }
         removeSelf();
         _assister.gotoAndStop(1);
      }
      
      public function defineAction(param1:String, param2:Object) : void
      {
         hitModel.addHitVO(param1,param2);
      }
      
      public function get owner_mc_ctrler() : FighterMcCtrler
      {
         var _loc1_:FighterMain = _assister.getOwner() as FighterMain;
         if(_loc1_)
         {
            return _loc1_.getCtrler().getMcCtrl();
         }
         return null;
      }
      
      public function get owner_fighter_ctrler() : FighterCtrler
      {
         var _loc1_:FighterMain = _assister.getOwner() as FighterMain;
         if(_loc1_)
         {
            return _loc1_.getCtrler();
         }
         return null;
      }
      
      public function initAssister(param1:Assister) : void
      {
         hitModel = new FighterHitModel(param1);
         _assister = param1;
         _effectCtrl = new FighterEffectCtrl(param1);
      }
      
      public function endAct() : void
      {
         _moveTargetParam = null;
         _assister.isAttacking = false;
      }
      
      public function render() : void
      {
         renderCheckTargetHit();
         renderTouchSide();
         if(_moveTargetParam != null)
         {
            renderMoveTarget();
         }
         if(_assister.isInAir)
         {
            _touchFloor = false;
            return;
         }
         if(!_touchFloor)
         {
            _touchFloor = true;
         }
         if(_touchFloorFrame)
         {
            stopMove();
            gotoAndPlay(_touchFloorFrame);
            _touchFloorFrame = null;
         }
      }
      
      private function renderMoveTarget() : void
      {
         var _loc1_:MovieClip = null;
         var _loc4_:DisplayObject = null;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc5_:IGameSprite = _moveTargetParam.target;
         if(_loc5_ == null)
         {
            return;
         }
         if(_moveTargetParam.followMcName)
         {
            _loc1_ = _assister.mc;
            _loc4_ = _loc1_.getChildByName(_moveTargetParam.followMcName);
            if(_loc4_ == null)
            {
               if(_isMovingTarget)
               {
                  _moveTargetParam.clear();
               }
               _isMovingTarget = false;
               return;
            }
            _isMovingTarget = true;
            _loc2_ = _assister.x + _loc4_.x * _assister.direct;
            _loc3_ = _assister.y + _loc4_.y;
         }
         else
         {
            if(!isNaN(_moveTargetParam.x))
            {
               _loc2_ = _moveTargetParam.x;
            }
            if(!isNaN(_moveTargetParam.y))
            {
               _loc3_ = _moveTargetParam.y;
            }
         }
         if(_moveTargetParam.speed)
         {
            if(_moveTargetParam.speed.x > 0 && !isNaN(_loc2_))
            {
               if(_loc5_.x > _loc2_ + _moveTargetParam.speed.x)
               {
                  _loc5_.x -= _moveTargetParam.speed.x;
               }
               if(_loc5_.x < _loc2_ - _moveTargetParam.speed.x)
               {
                  _loc5_.x += _moveTargetParam.speed.x;
               }
               if(_loc5_.y > _loc3_ + _moveTargetParam.speed.y)
               {
                  if(_loc5_ is BaseGameSprite)
                  {
                     (_loc5_ as BaseGameSprite).setVecY(-_moveTargetParam.speed.y);
                     (_loc5_ as BaseGameSprite).setDampingY(1);
                  }
                  else
                  {
                     _loc5_.y -= _moveTargetParam.speed.y;
                  }
               }
               if(_loc5_.y < _loc3_ - _moveTargetParam.speed.y)
               {
                  if(_loc5_ is BaseGameSprite)
                  {
                     (_loc5_ as BaseGameSprite).setVecY(_moveTargetParam.speed.y);
                     (_loc5_ as BaseGameSprite).setDampingY(1);
                  }
                  else
                  {
                     _loc5_.y += _moveTargetParam.speed.y;
                  }
               }
            }
         }
         else
         {
            if(!isNaN(_loc2_))
            {
               _loc5_.x = _loc2_;
            }
            if(!isNaN(_loc3_))
            {
               _loc5_.y = _loc3_;
            }
         }
      }
      
      public function moveToTarget(param1:Object = null, param2:Object = null, param3:Boolean = true) : void
      {
         var _loc4_:FighterMain = _assister.getOwner() as FighterMain;
         if(!_loc4_)
         {
            return;
         }
         var _loc5_:IGameSprite = _loc4_.getCurrentTarget();
         if(!_loc5_)
         {
            return;
         }
         if(param1 != null)
         {
            _assister.x = _loc5_.x + Number(param1) * _assister.direct;
         }
         if(param2 != null)
         {
            _assister.y = _loc5_.y + Number(param2);
         }
         if(param3)
         {
            _assister.direct = _assister.x < _loc5_.x ? 1 : -1;
         }
      }
      
      public function setDirectToTarget() : void
      {
         var _loc1_:IGameSprite = getTarget();
         if(!_loc1_)
         {
            return;
         }
         _assister.direct = _assister.x < _loc1_.x ? 1 : -1;
      }
      
      public function move(param1:Number = 0, param2:Number = 0) : void
      {
         _assister.setVelocity(param1 * _assister.direct,param2);
      }
      
      public function stopMove() : void
      {
         _assister.setVelocity(0,0);
      }
      
      public function damping(param1:Number = 0, param2:Number = 0) : void
      {
         _assister.setDamping(param1,param2);
      }
      
      public function stop() : void
      {
         _assister.stop();
      }
      
      public function gotoAndPlay(param1:String) : void
      {
         _assister.gotoAndPlay(param1);
      }
      
      public function gotoAndStop(param1:String) : void
      {
         _assister.gotoAndStop(param1);
      }
      
      public function setTouchFloor(param1:String) : void
      {
         _touchFloorFrame = param1;
      }
      
      public function setTouchSide(param1:String) : void
      {
         _touchSideAction = param1;
      }
      
      public function justHit(param1:String, param2:String = null, param3:Boolean = false) : Boolean
      {
         if(isJustHit(param1,param3))
         {
            if(param2 != null)
            {
               gotoAndPlay(param2);
            }
            return true;
         }
         return false;
      }
      
      private function isJustHit(param1:String, param2:Boolean = false) : Boolean
      {
         var _loc3_:HitVO = null;
         var _loc6_:HitVO = null;
         var _loc4_:FighterMain = _assister.getOwner() as FighterMain;
         var _loc5_:IGameSprite = _loc4_.getCurrentTarget();
         if(_loc5_ && _loc5_ is FighterMain)
         {
            _loc6_ = (_loc5_ as FighterMain).hurtHit;
            if(_loc6_)
            {
               return _loc6_.id == param1;
            }
            if(param2)
            {
               _loc3_ = (_loc5_ as FighterMain).defenseHit;
               if(_loc3_)
               {
                  return _loc3_.id == param1;
               }
            }
         }
         return false;
      }
      
      public function setHitTarget(param1:String, param2:String, param3:Boolean = true, param4:Boolean = true) : void
      {
         _hitTargetChecker = param1;
         _hitTargetAction = param2;
         _isCheckTargetIsAllowBeHit = param3;
         _isResponseTargetGameSprite = param4;
      }
      
      public function removeSelf() : void
      {
         _touchSideAction = null;
         _moveTargetParam = null;
         _assister.isAttacking = false;
         stopMove();
         _assister.removeSelf();
      }
      
      public function fire(param1:String, param2:Object = null) : void
      {
         var mcName:String = param1;
         var params:Object = param2;
         var mc:MovieClip = _assister.mc.getChildByName(mcName) as MovieClip;
         if(mc)
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            params.hitVO = hitModel.getHitVO(mcName);
            FighterEventDispatcher.dispatchEvent(_assister,"FIRE_BULLET",params);
         }
         else
         {
            _assister.setAnimateFrameOut(function():void
            {
               fire(mcName,params);
            },1);
         }
      }
      
      public function addAttacker(param1:String, param2:Object = null, param3:Boolean = false) : void
      {
         var mcName:String = param1;
         var params:Object = param2;
         var again:Boolean = param3;
         var mc:MovieClip = _assister.mc.getChildByName(mcName) as MovieClip;
         if(mc)
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            params.hitVO = hitModel.getHitVOByDisplayName(mcName);
            FighterEventDispatcher.dispatchEvent(_assister,"ADD_ATTACKER",params);
         }
         else if(!again)
         {
            _assister.setAnimateFrameOut(function():void
            {
               addAttacker(mcName,params,true);
            },1);
         }
      }
      
      public function checkHitOwner(param1:String) : Boolean
      {
         _hitOwnerChecker = param1;
         var _loc3_:Rectangle = _assister.getHitCheckRect(param1);
         if(!_loc3_)
         {
            return false;
         }
         var _loc2_:Rectangle = _assister.getOwner().getBodyArea();
         if(!_loc2_)
         {
            return false;
         }
         return _loc3_.intersects(_loc2_);
      }
      
      private function renderTouchSide() : void
      {
         if(_touchSideAction == null)
         {
            return;
         }
         if(_assister.getIsTouchSide())
         {
            _assister.gotoAndPlay(_touchSideAction);
            _touchSideAction = null;
         }
      }
      
      private function renderCheckTargetHit() : void
      {
         var _loc1_:Boolean = false;
         var _loc2_:Boolean = false;
         var _loc5_:Rectangle = null;
         var _loc4_:Boolean = false;
         if(_hitTargetChecker == null)
         {
            return;
         }
         var _loc3_:Rectangle = _assister.getHitCheckRect(_hitTargetChecker);
         var _loc6_:Vector.<IGameSprite> = _assister.getTargets();
         if(_loc3_ == null || _loc6_ == null)
         {
            return;
         }
         for each(var _loc7_ in _loc6_)
         {
            _loc1_ = _loc7_ is FighterMain;
            _loc2_ = _loc1_ && ((_loc7_ as FighterMain).isAllowBeHit || (_loc7_ as FighterMain).hurtHit || (_loc7_ as FighterMain).defenseHit);
            _loc5_ = _loc7_.getBodyArea();
            _loc4_ = _loc5_ != null && _loc3_.intersects(_loc5_);
            if(_isResponseTargetGameSprite)
            {
               if(_isCheckTargetIsAllowBeHit)
               {
                  if(_loc1_)
                  {
                     if(_loc2_ && _loc4_)
                     {
                        gotoAndPlay(_hitTargetAction);
                     }
                  }
                  else if(_loc4_)
                  {
                     gotoAndPlay(_hitTargetAction);
                  }
               }
               else if(_loc4_)
               {
                  gotoAndPlay(_hitTargetAction);
               }
            }
            else if(_loc1_)
            {
               if(_isCheckTargetIsAllowBeHit)
               {
                  if(_loc2_ && _loc4_)
                  {
                     gotoAndPlay(_hitTargetAction);
                  }
               }
               else if(_loc4_)
               {
                  gotoAndPlay(_hitTargetAction);
               }
            }
         }
      }
      
      public function targetInRange(param1:Array = null, param2:Array = null) : Boolean
      {
         var _loc8_:DisplayObject = getTarget().getDisplay();
         var _loc4_:DisplayObject = getSelf().getDisplay();
         if(_loc8_ == null)
         {
            return false;
         }
         var _loc3_:Number = getSelf().direct > 0 ? _loc8_.x - _loc4_.x : _loc4_.x - _loc8_.x;
         var _loc7_:Number = _loc8_.y - _loc4_.y;
         var _loc6_:Boolean = true;
         var _loc5_:Boolean = true;
         if(param1)
         {
            _loc6_ = _loc3_ >= param1[0] && _loc3_ <= param1[1];
         }
         if(param2)
         {
            _loc5_ = _loc7_ >= param2[0] && _loc7_ <= param2[1];
         }
         return _loc6_ && _loc5_;
      }
      
      public function moveTarget(param1:Object = null, param2:IGameSprite = null) : void
      {
         if(param1 == null && _moveTargetParam)
         {
            _moveTargetParam.clear();
            _moveTargetParam = null;
            return;
         }
         if(param2 == null)
         {
            param2 = getTarget();
         }
         _moveTargetParam = new MoveTargetParamVO(param1);
         _moveTargetParam.setTarget(param2);
      }
      
      public function addRenderFunc(param1:Function = null, param2:Object = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         _assister.addRenderFunc(param1,param2);
      }
      
      public function removeRenderFunc(param1:Function = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         _assister.removeRenderFunc(param1);
      }
      
      public function get enabled() : Boolean
      {
         return _assister.enable;
      }
      
      public function set enabled(param1:Boolean) : void
      {
         _assister.enable = param1;
      }
      
      public function get useFzqi() : Boolean
      {
         return _assister.useFzqi;
      }
      
      public function set useFzqi(param1:Boolean) : void
      {
         _assister.useFzqi = param1;
      }
   }
}

