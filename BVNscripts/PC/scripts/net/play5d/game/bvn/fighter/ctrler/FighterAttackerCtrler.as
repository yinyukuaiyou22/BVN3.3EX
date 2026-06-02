package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.MovieClip;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterAttacker;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class FighterAttackerCtrler
   {
      
      public var effect:FighterEffectCtrl;
      
      public var ownerMc:FighterMcCtrler;
      
      private var _attacker:FighterAttacker;
      
      private var _touchFloor:Boolean;
      
      private var _touchFloorFrame:String;
      
      private var _hitTargetChecker:String;
      
      private var _hitTargetAction:String;
      
      private var _isCheckTargetIsAllowBeHit:Boolean;
      
      private var _isResponseTargetGameSprite:Boolean;
      
      private var _hitOwnerChecker:String;
      
      private var _touchSideAction:String;
      
      public function FighterAttackerCtrler(param1:FighterAttacker, param2:IGameSprite)
      {
         super();
         _attacker = param1;
         _attacker.setOwner(param2);
      }
      
      public function get owner_mc_ctrler() : FighterMcCtrler
      {
         var _loc1_:FighterMain = _attacker.getOwner() as FighterMain;
         if(_loc1_ != null)
         {
            return _loc1_.getCtrler().getMcCtrl();
         }
         return null;
      }
      
      public function get owner_fighter_ctrler() : FighterCtrler
      {
         var _loc1_:FighterMain = _attacker.getOwner() as FighterMain;
         if(_loc1_ != null)
         {
            return _loc1_.getCtrler();
         }
         return null;
      }
      
      public function getOwner() : IGameSprite
      {
         var _loc1_:IGameSprite = _attacker.getOwner();
         if(_loc1_ != null)
         {
            return _loc1_;
         }
         return null;
      }
      
      public function getOwnerFighter() : IGameSprite
      {
         var _loc1_:IGameSprite = getOwner();
         if(_loc1_ is Assister)
         {
            _loc1_ = (_loc1_ as Assister).getOwner();
         }
         if(_loc1_ != null)
         {
            return _loc1_;
         }
         return null;
      }
      
      public function getTargetFighter() : IGameSprite
      {
         var _loc2_:FighterCtrler = null;
         var _loc1_:IGameSprite = getOwner();
         var _loc3_:IGameSprite = null;
         if(_loc1_ is FighterMain)
         {
            _loc2_ = this.owner_fighter_ctrler;
            _loc3_ = _loc2_.getTargetSP();
         }
         else if(_loc1_ is Assister)
         {
            _loc3_ = (_loc1_ as Assister).getCurrentTarget();
         }
         if(_loc3_ != null)
         {
            return _loc3_;
         }
         return null;
      }
      
      public function getSelf() : FighterAttacker
      {
         return _attacker;
      }
      
      public function setDirectReverse() : void
      {
         _attacker.direct *= -1;
      }
      
      public function setApplyG(param1:Boolean) : void
      {
         _attacker.isApplyG = param1;
      }
      
      public function setAllowCrossFloor(param1:Boolean) : void
      {
         _attacker.isAllowCrossFloor = param1;
      }
      
      public function get targetChecker() : String
      {
         return _hitTargetChecker;
      }
      
      public function get ownerChecker() : String
      {
         return _hitOwnerChecker;
      }
      
      public function destory() : void
      {
         _attacker = null;
         effect = null;
         ownerMc = null;
      }
      
      public function endAct() : void
      {
         _attacker.isAttacking = false;
      }
      
      public function render() : void
      {
         renderCheckTargetHit();
         renderTouchSide();
         if(_attacker.isInAir)
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
      
      private function renderTouchSide() : void
      {
         if(_touchSideAction == null)
         {
            return;
         }
         if(_attacker.getIsTouchSide())
         {
            _attacker.gotoAndPlay(_touchSideAction);
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
         var _loc3_:Rectangle = _attacker.getHitCheckRect(_hitTargetChecker);
         var _loc6_:Vector.<IGameSprite> = _attacker.getTargets();
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
      
      public function stopFollowTarget() : void
      {
         _attacker.stopFollowTarget();
      }
      
      public function moveToTarget(param1:Number = NaN, param2:Number = NaN) : void
      {
         _attacker.moveToTarget(param1,param2);
      }
      
      public function move(param1:Number = 0, param2:Number = 0) : void
      {
         _attacker.setVelocity(param1 * _attacker.direct,param2);
      }
      
      public function stopMove() : void
      {
         _attacker.setVelocity(0,0);
      }
      
      public function damping(param1:Number = 0, param2:Number = 0) : void
      {
         _attacker.setDamping(param1,param2);
      }
      
      public function stop() : void
      {
         _attacker.stop();
      }
      
      public function gotoAndPlay(param1:String) : void
      {
         _attacker.gotoAndPlay(param1);
      }
      
      public function gotoAndStop(param1:String) : void
      {
         _attacker.gotoAndStop(param1);
      }
      
      public function setTouchFloor(param1:String) : void
      {
         _touchFloorFrame = param1;
      }
      
      public function setTouchSide(param1:String) : void
      {
         _touchSideAction = param1;
      }
      
      public function justHit(param1:String) : Boolean
      {
         var _loc2_:IGameSprite = _attacker.getOwner();
         if(_loc2_ is FighterMain)
         {
            return (_attacker.getOwner() as FighterMain).getCtrler().justHit(param1);
         }
         if(_loc2_ is Assister)
         {
            return (_attacker.getOwner() as Assister).getCtrler().justHit(param1);
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
      
      public function setCrossMap(param1:Boolean) : void
      {
         _attacker.isAllowCrossX = _attacker.isAllowCrossBottom = param1;
      }
      
      public function setCrossFloor(param1:Boolean) : void
      {
         _attacker.isAllowCrossFloor = param1;
      }
      
      public function removeSelf() : void
      {
         _touchSideAction = null;
         _attacker.removeSelf();
      }
      
      public function fire(param1:String, param2:Object = null) : void
      {
         var mc:MovieClip;
         var hv:HitVO;
         var mcName:String = param1;
         var params:Object = param2;
         if(!owner_fighter_ctrler || !owner_fighter_ctrler.hitModel)
         {
            return;
         }
         mc = _attacker.mc.getChildByName(mcName) as MovieClip;
         if(mc)
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            hv = owner_fighter_ctrler.hitModel.getHitVOByDisplayName(mcName);
            if(!hv)
            {
               return;
            }
            hv = hv.clone();
            hv.owner = _attacker;
            params.hitVO = hv;
            FighterEventDispatcher.dispatchEvent(_attacker,"FIRE_BULLET",params);
         }
         else
         {
            _attacker.setAnimateFrameOut(function():void
            {
               fire(mcName,params);
            },1);
         }
      }
      
      public function addRenderFunc(param1:Function = null, param2:Object = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         _attacker.addRenderFunc(param1,param2);
      }
      
      public function removeRenderFunc(param1:Function = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         _attacker.removeRenderFunc(param1);
      }
   }
}

