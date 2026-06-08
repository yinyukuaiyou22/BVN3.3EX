package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.*;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.events.*;
   import net.play5d.game.bvn.fighter.models.*;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class AssisiterCtrler
   {
      
      public var hitModel:FighterHitModel;
      
      private var _effectCtrl:FighterEffectCtrl;
      
      private var _assister:Assister;
      
      private var _touchFloor:Boolean;
      
      private var _touchFloorFrame:String;
      
      private var hitTargetAction:String;
      
      private var hitTargetChecker:String;
      
      public function AssisiterCtrler()
      {
         super();
      }
      
      public function get effect() : FighterEffectCtrl
      {
         return this._effectCtrl;
      }
      
      public function destory() : void
      {
         if(Boolean(this._effectCtrl))
         {
            this._effectCtrl.destory();
            this._effectCtrl = null;
         }
         if(Boolean(this.hitModel))
         {
            this.hitModel.destory();
            this.hitModel = null;
         }
         this._assister = null;
      }
      
      public function getTarget() : IGameSprite
      {
         var _loc1_:FighterMain = this._assister.getOwner() as FighterMain;
         if(Boolean(_loc1_))
         {
            return _loc1_.getCurrentTarget();
         }
         return null;
      }
      
      public function getOwner() : IGameSprite
      {
         return this._assister.getOwner();
      }
      
      public function getSelf() : Assister
      {
         return this._assister;
      }
      
      public function setApplyG(param1:Boolean) : void
      {
         this._assister.isApplyG = param1;
      }
      
      public function finish(param1:Boolean = true) : void
      {
         if(param1)
         {
            EffectCtrl.I.assisterEffect(this._assister);
         }
         this._assister.isAttacking = false;
         this.removeSelf();
         this._assister.gotoAndStop(1);
      }
      
      public function defineAction(param1:String, param2:Object) : void
      {
         this.hitModel.addHitVO(param1,param2);
      }
      
      public function get owner_mc_ctrler() : FighterMcCtrler
      {
         var _loc1_:FighterMain = this._assister.getOwner() as FighterMain;
         if(Boolean(_loc1_))
         {
            return _loc1_.getCtrler().getMcCtrl();
         }
         return null;
      }
      
      public function get owner_fighter_ctrler() : FighterCtrler
      {
         var _loc1_:FighterMain = this._assister.getOwner() as FighterMain;
         if(Boolean(_loc1_))
         {
            return _loc1_.getCtrler();
         }
         return null;
      }
      
      public function initAssister(param1:Assister) : void
      {
         this.hitModel = new FighterHitModel(param1);
         this._assister = param1;
         this._effectCtrl = new FighterEffectCtrl(param1);
      }
      
      public function endAct() : void
      {
         this._assister.isAttacking = false;
      }
      
      public function render() : void
      {
         this.renderCheckTargetHit();
         if(this._assister.isInAir)
         {
            this._touchFloor = false;
            return;
         }
         if(!this._touchFloor)
         {
            this._touchFloor = true;
            if(Boolean(this._touchFloorFrame))
            {
               this._assister.gotoAndPlay(this._touchFloorFrame);
               this._touchFloorFrame = null;
            }
         }
      }
      
      public function moveToTarget(param1:Object = null, param2:Object = null, param3:Boolean = true) : void
      {
         var _loc4_:FighterMain = this._assister.getOwner() as FighterMain;
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
            this._assister.x = _loc5_.x + Number(param1) * this._assister.direct;
         }
         if(param2 != null)
         {
            this._assister.y = _loc5_.y + Number(param2);
         }
         if(param3)
         {
            this._assister.direct = this._assister.x < _loc5_.x ? 1 : -1;
         }
      }
      
      public function setDirectToTarget() : void
      {
         var _loc1_:IGameSprite = this.getTarget();
         if(!_loc1_)
         {
            return;
         }
         this._assister.direct = this._assister.x < _loc1_.x ? 1 : -1;
      }
      
      public function move(param1:Number = 0, param2:Number = 0) : void
      {
         this._assister.setVelocity(param1 * this._assister.direct,param2);
      }
      
      public function damping(param1:Number = 0, param2:Number = 0) : void
      {
         this._assister.setDamping(param1,param2);
      }
      
      public function stop() : void
      {
         this._assister.stop();
      }
      
      public function gotoAndPlay(param1:String) : void
      {
         this._assister.gotoAndPlay(param1);
      }
      
      public function gotoAndStop(param1:String) : void
      {
         this._assister.gotoAndStop(param1);
      }
      
      public function setTouchFloor(param1:String) : void
      {
         this._touchFloorFrame = param1;
      }
      
      public function justHit(param1:String, param2:String = null, param3:Boolean = false) : Boolean
      {
         if(this.isJustHit(param1,param3))
         {
            if(param2 != null)
            {
               this.gotoAndPlay(param2);
            }
            return true;
         }
         return false;
      }
      
      private function isJustHit(param1:String, param2:Boolean = false) : Boolean
      {
         var _loc3_:HitVO = null;
         var _loc4_:HitVO = null;
         var _loc5_:FighterMain = this._assister.getOwner() as FighterMain;
         var _loc6_:IGameSprite = _loc5_.getCurrentTarget();
         if(Boolean(_loc6_) && _loc6_ is FighterMain)
         {
            _loc3_ = (_loc6_ as FighterMain).hurtHit;
            if(Boolean(_loc3_))
            {
               return _loc3_.id == param1;
            }
            if(param2)
            {
               _loc4_ = (_loc6_ as FighterMain).defenseHit;
               if(Boolean(_loc4_))
               {
                  return _loc4_.id == param1;
               }
            }
         }
         return false;
      }
      
      public function setHitTarget(param1:String, param2:String) : void
      {
         this.hitTargetAction = param2;
         this.hitTargetChecker = param1;
      }
      
      public function removeSelf() : void
      {
         this._assister.removeSelf();
      }
      
      public function fire(param1:String, param2:Object = null) : void
      {
         var mcName:String = null;
         var params:Object = null;
         mcName = param1;
         params = param2;
         var mc:MovieClip = this._assister.mc.getChildByName(mcName) as MovieClip;
         if(Boolean(mc))
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            params.hitVO = this.hitModel.getHitVO(mcName);
            FighterEventDispatcher.dispatchEvent(this._assister,"FIRE_BULLET",params);
         }
         else
         {
            this._assister.setAnimateFrameOut(function():void
            {
               fire(mcName,params);
            },1);
         }
      }
      
      public function addAttacker(param1:String, param2:Object = null) : void
      {
         var mcName:String = null;
         var params:Object = null;
         mcName = param1;
         params = param2;
         var mc:MovieClip = this._assister.mc.getChildByName(mcName) as MovieClip;
         if(Boolean(mc))
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            params.hitVO = this.hitModel.getHitVOByDisplayName(mcName);
            FighterEventDispatcher.dispatchEvent(this._assister,"ADD_ATTACKER",params);
         }
         else
         {
            this._assister.setAnimateFrameOut(function():void
            {
               addAttacker(mcName,params);
            },1);
         }
      }
      
      public function checkHitOwner(param1:String) : Boolean
      {
         var _loc2_:Rectangle = this._assister.getHitCheckRect(param1);
         if(!_loc2_)
         {
            return false;
         }
         var _loc3_:Rectangle = this._assister.getOwner().getArea();
         if(!_loc3_)
         {
            return false;
         }
         return _loc2_.intersects(_loc3_);
      }
      
      private function renderCheckTargetHit() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Rectangle = null;
         if(!this.hitTargetChecker)
         {
            return;
         }
         var _loc3_:Rectangle = this._assister.getHitCheckRect(this.hitTargetChecker);
         if(!_loc3_)
         {
            return;
         }
         var _loc4_:Vector.<IGameSprite> = this._assister.getTargets();
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
   }
}

