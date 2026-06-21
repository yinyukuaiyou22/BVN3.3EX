package net.play5d.game.bvn.fighter
{
   import flash.display.MovieClip;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.fighter.ctrler.*;
   import net.play5d.game.bvn.fighter.models.*;
   import net.play5d.game.bvn.interfaces.*;
   
   public class FighterMain extends BaseGameSprite
   {
      
      public var qi:Number = 0;
      
      public const qiMax:Number = 300;
      
      public var energy:Number = 100;
      
      public var energyMax:Number = 100;
      
      public var energyOverLoad:Boolean = false;
      
      public var customHpMax:int = 0;
      
      public var fzqi:Number = 100;
      
      public const fzqiMax:Number = 100;
      
      public var speed:Number = 6;
      
      public var jumpPower:Number = 15;
      
      public var isSteelBody:Boolean = false;
      
      public var isSuperSteelBody:Boolean = false;
      
      public var data:FighterVO;

      public var initFailed:Boolean = false;
      
      public var airHitTimes:int = 1;
      
      public var jumpTimes:int = 2;
      
      public var actionState:int = 0;
      
      public var defenseType:int = 0;
      
      public var lastHitVO:HitVO;
      
      private var _buffCtrler:FighterBuffCtrler;
      
      private var _currentHurts:Vector.<HitVO>;
      
      public var hurtHit:HitVO;
      
      public var defenseHit:HitVO;
      
      public var targetTeams:Vector.<TeamVO>;
      
      private var _currentTarget:IGameSprite;
      
      private var _fighterCtrl:FighterCtrler;
      
      private var _energyAddGap:int;
      
      private var _explodeHitVO:HitVO;
      
      private var _explodeHitFrame:int;
      
      private var _explodeSteelFrame:int;
      
      private var _replaceSkillFrame:int;
      
      private var _speedBack:Number = 0;
      
      private var _colorTransform:ColorTransform;
      
      public function FighterMain(param1:MovieClip)
      {
         super(param1);
         _area = null;
      }
      
      public function get colorTransform() : ColorTransform
      {
         return this._colorTransform;
      }
      
      public function set colorTransform(param1:ColorTransform) : void
      {
         this._colorTransform = param1;
         _mainMc.transform.colorTransform = param1 ? param1 : new ColorTransform();
      }
      
      public function changeColor(param1:ColorTransform) : void
      {
         _mainMc.transform.colorTransform = param1;
      }
      
      public function resumeColor() : void
      {
         _mainMc.transform.colorTransform = this._colorTransform ? this._colorTransform : new ColorTransform();
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         if(!param1)
         {
            return;
         }
         if(Boolean(this._fighterCtrl))
         {
            this._fighterCtrl.destory();
            this._fighterCtrl = null;
         }
         if(Boolean(_mainMc))
         {
            _mainMc.filters = null;
            _mainMc.gotoAndStop(1);
         }
         if(Boolean(this._buffCtrler))
         {
            this._buffCtrler.destory();
            this._buffCtrler = null;
         }
         this.targetTeams = null;
         this._currentTarget = null;
         this._currentHurts = null;
         super.destory(param1);
      }
      
      override public function set attackRate(param1:Number) : void
      {
         super.attackRate = param1;
         if(Boolean(this._fighterCtrl) && Boolean(this._fighterCtrl.hitModel))
         {
            this._fighterCtrl.hitModel.setPowerRate(param1);
         }
      }
      
      public function currentHurtDamage() : int
      {
         var _loc1_:* = undefined;
         if(!this._currentHurts)
         {
            return 0;
         }
         var _loc2_:int = 0;
         for each(_loc1_ in this._currentHurts)
         {
            _loc2_ += _loc1_.getDamage();
         }
         return _loc2_;
      }
      
      public function getLastHurtHitVO() : HitVO
      {
         if(!this._currentHurts)
         {
            return null;
         }
         return this._currentHurts[this._currentHurts.length - 1];
      }
      
      public function hurtBreakHit() : Boolean
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in this._currentHurts)
         {
            if(Boolean(_loc1_.isBreakDef))
            {
               return true;
            }
         }
         return false;
      }
      
      public function clearHurtHits() : void
      {
         this._currentHurts = null;
      }
      
      public function getCtrler() : FighterCtrler
      {
         return this._fighterCtrl;
      }
      
      public function getBuffCtrl() : FighterBuffCtrler
      {
         return this._buffCtrler;
      }
      
      public function getCurrentTarget() : IGameSprite
      {
         var _loc1_:* = undefined;
         if(Boolean(this._currentTarget))
         {
            if(this._currentTarget is BaseGameSprite && Boolean((this._currentTarget as BaseGameSprite).isAlive))
            {
               return this._currentTarget;
            }
         }
         var _loc2_:Vector.<IGameSprite> = this.getTargets();
         var _loc3_:Array = [];
         if(Boolean(_loc2_) && _loc2_.length > 0)
         {
            for each(_loc1_ in _loc2_)
            {
               if(_loc1_.getBodyArea() == null)
               {
                  _loc3_.push({
                     "fighter":_loc1_,
                     "order":5
                  });
               }
               else if(_loc1_ is FighterMain && Boolean((_loc1_ as FighterMain).isAlive))
               {
                  _loc3_.push({
                     "fighter":_loc1_,
                     "order":0
                  });
               }
               else if(_loc1_ is BaseGameSprite && Boolean((_loc1_ as BaseGameSprite).isAlive))
               {
                  _loc3_.push({
                     "fighter":_loc1_,
                     "order":1
                  });
               }
               else
               {
                  _loc3_.push({
                     "fighter":_loc1_,
                     "order":2
                  });
               }
            }
            _loc3_.sortOn("order",16);
            this._currentTarget = _loc3_[0].fighter;
         }
         return this._currentTarget;
      }
      
      public function getTargets() : Vector.<IGameSprite>
      {
         var _loc1_:int = 0;
         if(!this.targetTeams || this.targetTeams.length < 1)
         {
            return null;
         }
         var _loc2_:Vector.<IGameSprite> = new Vector.<IGameSprite>();
         while(_loc1_ < this.targetTeams.length)
         {
            _loc2_ = _loc2_.concat(this.targetTeams[_loc1_].getAliveChildren());
            _loc1_++;
         }
         return _loc2_;
      }
      
      public function getMC() : FighterMC
      {
         if(!this._fighterCtrl)
         {
            return null;
         }
         if(!this._fighterCtrl.getMcCtrl())
         {
            return null;
         }
         return this._fighterCtrl.getMcCtrl().getFighterMc();
      }
      
      public function setActionCtrl(param1:IFighterActionCtrl) : void
      {
         if(Boolean(this._fighterCtrl))
         {
            this._fighterCtrl.setActionCtrl(param1);
            param1.initlize();
         }
      }
      
      public function initlize() : void
      {
         this._fighterCtrl = new FighterCtrler();
         if(Boolean(_mainMc.setFighterCtrler))
         {
            _mainMc.setFighterCtrler(this._fighterCtrl);
            this._fighterCtrl.initFighter(this);
            this._buffCtrler = new FighterBuffCtrler(this);
            _mainMc.gotoAndStop(this.data ? this.data.startFrame + 1 : 2);
            return;
         }
         this.initFailed = true;
         Debugger.log("[FighterMain] 此角色不可用 — SWF缺少setFighterCtrler: " + (this.data ? this.data.id : "unknown"));
      }
      
      override public function renderAnimate() : void
      {
         super.renderAnimate();
         if(_destoryed)
         {
            return;
         }
         this.renderEnergy();
         this.renderFzQi();
         if(Boolean(this._fighterCtrl))
         {
            this._fighterCtrl.renderAnimate();
         }
         if(this._explodeHitFrame > 0)
         {
            --this._explodeHitFrame;
            if(this._explodeHitFrame == 8)
            {
               this.idle();
               isAllowBeHit = false;
            }
            if(this._explodeHitFrame <= 0)
            {
               this._explodeHitVO = null;
               isAllowBeHit = true;
            }
         }
         if(this._explodeSteelFrame > 0)
         {
            --this._explodeSteelFrame;
            this._fighterCtrl.getMcCtrl().setSteelBody(true,true);
            if(this._explodeSteelFrame <= 0)
            {
               this._fighterCtrl.getMcCtrl().setSteelBody(false);
            }
         }
         if(this._replaceSkillFrame > 0)
         {
            --this._replaceSkillFrame;
            if(this._replaceSkillFrame <= 0)
            {
               isAllowBeHit = true;
            }
         }
      }
      
      override public function render() : void
      {
         super.render();
         if(_destoryed)
         {
            return;
         }
         if(Boolean(this._fighterCtrl))
         {
            this._fighterCtrl.render();
         }
         if(Boolean(this._buffCtrler))
         {
            this._buffCtrler.render();
         }
         if(hp < 0)
         {
            hp = 0;
         }
         if(hp > hpMax)
         {
            hp = hpMax;
         }
         if(this.qi < 0)
         {
            this.qi = 0;
         }
         if(this.qi > 300)
         {
            this.qi = 300;
         }
         if(this.fzqi < 0)
         {
            this.fzqi = 0;
         }
         if(this.fzqi > 100)
         {
            this.fzqi = 100;
         }
      }
      
      public function jump() : void
      {
         _g = 0;
         setVelocity(0,-this.jumpPower);
         setDamping(0,0.5);
      }
      
      override public function getCurrentHits() : Array
      {
         if(Boolean(this._explodeHitVO) && this._explodeHitFrame < 8)
         {
            return [this._explodeHitVO];
         }
         return this._fighterCtrl.getCurrentHits();
      }
      
      override public function getBodyArea() : Rectangle
      {
         if(!this._fighterCtrl)
         {
            return null;
         }
         return this._fighterCtrl.getBodyArea();
      }
      
      override public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         super.hit(param1,param2);
         this.lastHitVO = param1;
         var _loc3_:* = 0;
         if(param2 is FighterMain)
         {
            if(param1.isBisha())
            {
               _loc3_ = Number(param1.power * 0);
            }
            else
            {
               _loc3_ = Number(param1.power * 0.17);
            }
            if(_loc3_ > 15)
            {
               _loc3_ = 15;
            }
         }
         this.addQi(_loc3_);
         GameLogic.hitTarget(param1,this,param2);
      }
      
      override public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
         if(!isAllowBeHit)
         {
            return;
         }
         super.beHit(param1,param2);
         this._fighterCtrl.getMcCtrl().beHit(param1,param2);
         var _loc3_:* = Number(param1.power * 0.08);
         if(_loc3_ > 20)
         {
            _loc3_ = 20;
         }
         this.addQi(_loc3_);
         if(this.actionState == 21 || this.actionState == 22)
         {
            if(!this._currentHurts)
            {
               this._currentHurts = new Vector.<HitVO>();
            }
            this._currentHurts.push(param1);
         }
      }
      
      private function renderEnergy() : void
      {
         if(this._energyAddGap > 0)
         {
            --this._energyAddGap;
            return;
         }
         if(this.energy < this.energyMax)
         {
            if(this.energyOverLoad)
            {
               this.energy += 0.6;
               if(this.energy > 30)
               {
                  this.energyOverLoad = false;
               }
            }
            else if(this.actionState == 20)
            {
               this.energy += 0.8;
            }
            else if(FighterActionState.isAttacking(this.actionState))
            {
               this.energy += 1.1;
            }
            else
            {
               this.energy += 2;
            }
         }
      }
      
      private function renderFzQi() : void
      {
         if(this.fzqi < 100)
         {
            this.fzqi += 0.2;
         }
      }
      
      public function hasEnergy(param1:Number, param2:Boolean = false) : Boolean
      {
         if(this.energy >= param1)
         {
            return true;
         }
         if(param2)
         {
            if(!this.energyOverLoad)
            {
               return true;
            }
         }
         return false;
      }
      
      public function useEnergy(param1:Number) : void
      {
         this.energy -= param1;
         this._energyAddGap = 0.8 * 30;
         if(this.energy < 0)
         {
            this.energy = 0;
            this.energyOverLoad = true;
         }
      }
      
      public function useQi(param1:Number) : Boolean
      {
         if(this.qi < param1)
         {
            return false;
         }
         this.qi -= param1;
         return true;
      }
      
      public function addQi(param1:Number) : void
      {
         this.qi += param1;
         if(this.qi > 300)
         {
            this.qi = 300;
         }
      }
      
      public function sayIntro() : void
      {
         this._fighterCtrl.getMcCtrl().sayIntro();
      }
      
      public function win() : void
      {
         this._fighterCtrl.getMcCtrl().doWin();
      }
      
      public function idle() : void
      {
         this._fighterCtrl.getMcCtrl().idle();
      }
      
      public function lose() : void
      {
         this._fighterCtrl.getMcCtrl().doLose();
      }
      
      public function getHitRange(param1:String) : Rectangle
      {
         return this._fighterCtrl.getHitRange(param1);
      }
      
      public function energyExplode() : void
      {
         this._fighterCtrl.getEffectCtrl().energyExplode();
         this._fighterCtrl.getMcCtrl().setSteelBody(true,true);
         this._explodeHitVO = new HitVO();
         var _loc1_:Rectangle = new Rectangle(-100,-200,200,210);
         this._explodeHitVO.currentArea = this._fighterCtrl.getCurrentRect(_loc1_);
         this._explodeHitVO.power = 50;
         this._explodeHitVO.hitx = 15 * direct;
         this._explodeHitVO.hitType = 5;
         this._explodeHitVO.hurtType = 1;
         this._explodeHitFrame = 10;
         this._explodeSteelFrame = 60;
         isAllowBeHit = false;
      }
      
      public function replaceSkill() : void
      {
         this._fighterCtrl.getEffectCtrl().replaceSkill();
         move(250 * direct);
         this.idle();
         isAllowBeHit = false;
         super.render();
         this.renderAnimate();
         this._fighterCtrl.setDirectToTarget();
         this._replaceSkillFrame = 30;
      }
      
      override public function getArea() : Rectangle
      {
         if(!_area)
         {
            _area = this.getBodyArea();
         }
         return _area;
      }
      
      public function hasWankai() : Boolean
      {
         return this._fighterCtrl.getMcCtrl().getFighterMc().checkFrame("万解");
      }
      
      public function die() : void
      {
         hp = 0;
         isAlive = false;
         if(!FighterActionState.isHurting(this.actionState) && this.actionState != 30)
         {
            this._fighterCtrl.getMcCtrl().getFighterMc().playHurtDown();
         }
      }
      
      public function relive() : void
      {
         isAlive = true;
         this.idle();
      }
   }
}

