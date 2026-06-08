package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.*;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.events.*;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class FighterAttackerCtrler
   {
      
      public var effect:FighterEffectCtrl;
      
      public var ownerMc:FighterMcCtrler;
      
      private var _attacker:FighterAttacker;
      
      private var _touchFloor:Boolean;
      
      private var _touchFloorFrame:String;
      
      private var hitTargetAction:String;
      
      private var hitTargetChecker:String;
      
      public function FighterAttackerCtrler(param1:FighterAttacker)
      {
         super();
         this._attacker = param1;
      }
      
      public function get owner_mc_ctrler() : FighterMcCtrler
      {
         var _loc1_:FighterMain = this._attacker.getOwner() as FighterMain;
         if(Boolean(_loc1_))
         {
            return _loc1_.getCtrler().getMcCtrl();
         }
         return null;
      }
      
      public function get owner_fighter_ctrler() : FighterCtrler
      {
         var _loc1_:FighterMain = this._attacker.getOwner() as FighterMain;
         if(Boolean(_loc1_))
         {
            return _loc1_.getCtrler();
         }
         return null;
      }
      
      public function destory() : void
      {
         this._attacker = null;
         this.effect = null;
         this.ownerMc = null;
      }
      
      public function endAct() : void
      {
         this._attacker.isAttacking = false;
      }
      
      public function render() : void
      {
         this.renderCheckTargetHit();
         if(this._attacker.isInAir)
         {
            this._touchFloor = false;
            return;
         }
         if(!this._touchFloor)
         {
            this._touchFloor = true;
            if(Boolean(this._touchFloorFrame))
            {
               this._attacker.gotoAndPlay(this._touchFloorFrame);
               this._touchFloorFrame = null;
            }
         }
      }
      
      private function renderCheckTargetHit() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Rectangle = null;
         if(!this.hitTargetChecker)
         {
            return;
         }
         var _loc3_:Rectangle = this._attacker.getHitCheckRect(this.hitTargetChecker);
         if(!_loc3_)
         {
            return;
         }
         var _loc4_:Vector.<IGameSprite> = this._attacker.getTargets();
         if(!_loc4_)
         {
            return;
         }
         while(_loc1_ < _loc4_.length)
         {
            _loc2_ = _loc4_[_loc1_].getBodyArea();
            if(Boolean(_loc2_) && _loc3_.intersects(_loc2_))
            {
               this.gotoAndPlay(this.hitTargetAction);
            }
            _loc1_++;
         }
      }
      
      public function stopFollowTarget() : void
      {
         this._attacker.stopFollowTarget();
      }
      
      public function moveToTarget(param1:Number = NaN, param2:Number = NaN) : void
      {
         this._attacker.moveToTarget(param1,param2);
      }
      
      public function move(param1:Number = 0, param2:Number = 0) : void
      {
         this._attacker.setVelocity(param1 * this._attacker.direct,param2);
      }
      
      public function damping(param1:Number = 0, param2:Number = 0) : void
      {
         this._attacker.setDamping(param1,param2);
      }
      
      public function stop() : void
      {
         this._attacker.stop();
      }
      
      public function gotoAndPlay(param1:String) : void
      {
         this._attacker.gotoAndPlay(param1);
      }
      
      public function gotoAndStop(param1:String) : void
      {
         this._attacker.gotoAndStop(param1);
      }
      
      public function setTouchFloor(param1:String) : void
      {
         this._touchFloorFrame = param1;
      }
      
      public function justHit(param1:String) : Boolean
      {
         var _loc2_:IGameSprite = this._attacker.getOwner();
         if(_loc2_ is FighterMain)
         {
            return (this._attacker.getOwner() as FighterMain).getCtrler().justHit(param1);
         }
         if(_loc2_ is Assister)
         {
            return (this._attacker.getOwner() as Assister).getCtrler().justHit(param1);
         }
         return false;
      }
      
      public function setHitTarget(param1:String, param2:String) : void
      {
         this.hitTargetAction = param2;
         this.hitTargetChecker = param1;
      }
      
      public function setCrossMap(param1:Boolean) : void
      {
         this._attacker.isAllowCrossX = this._attacker.isAllowCrossBottom = param1;
      }
      
      public function removeSelf() : void
      {
         this._attacker.removeSelf();
      }
      
      public function fire(param1:String, param2:Object = null) : void
      {
         var mc:MovieClip = null;
         var hv:HitVO = null;
         var mcName:String = null;
         var params:Object = null;
         mcName = param1;
         params = param2;
         if(!this.owner_fighter_ctrler || !this.owner_fighter_ctrler.hitModel)
         {
            trace("hitModel error!");
            return;
         }
         mc = this._attacker.mc.getChildByName(mcName) as MovieClip;
         if(Boolean(mc))
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            hv = this.owner_fighter_ctrler.hitModel.getHitVOByDisplayName(mcName);
            if(!hv)
            {
               trace("hitVO error!");
               return;
            }
            hv = hv.clone();
            hv.owner = this._attacker;
            params.hitVO = hv;
            FighterEventDispatcher.dispatchEvent(this._attacker,"FIRE_BULLET",params);
         }
         else
         {
            this._attacker.setAnimateFrameOut(function():void
            {
               fire(mcName,params);
            },1);
         }
      }
   }
}

