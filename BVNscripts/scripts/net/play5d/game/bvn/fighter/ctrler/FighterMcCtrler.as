package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.*;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.events.*;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.fighter.vos.*;
   import net.play5d.game.bvn.interfaces.*;
   
   public class FighterMcCtrler
   {
      
      public var effectCtrler:FighterEffectCtrl;
      
      private var _actionCtrler:IFighterActionCtrl;
      
      private var _mc:FighterMC;
      
      private var _fighter:FighterMain;
      
      private var _action:FighterAction = new FighterAction();
      
      private var _doingAction:String;
      
      private var _doingAirAction:String;
      
      private var _isFalling:Boolean;
      
      private var _jumpDelayFrame:int = 0;
      
      private var _hurtHoldFrame:int = 0;
      
      private var _defenseHoldFrame:int = 0;
      
      private var _beHitGap:int;
      
      private var _doActionFrame:int;
      
      private var _isTouchFloor:Boolean = true;
      
      private var _isDefense:Boolean;
      
      private var _defenseFrameDelay:int = 0;
      
      private var _moveTargetParam:MoveTargetParamVO;
      
      private var _hurtDownFrame:int;
      
      private var _ghostStepIng:Boolean;
      
      private var _ghostStepFrame:int;
      
      private var _autoDirectFrame:int;
      
      private var _justDefenseFrame:int;
      
      private var _ghostType:int = 0;
      
      private var _justHurtResume:Boolean;
      
      public function FighterMcCtrler(param1:FighterMain)
      {
         super();
         this._fighter = param1;
      }
      
      public function destory() : void
      {
         if(Boolean(this._actionCtrler))
         {
            this._actionCtrler.destory();
            this._actionCtrler = null;
         }
         if(Boolean(this._mc))
         {
            this._mc.destory();
            this._mc = null;
         }
         this._fighter = null;
         this._action = null;
         this._moveTargetParam = null;
         this.effectCtrler = null;
      }
      
      public function getAction() : FighterAction
      {
         return this._action;
      }
      
      public function getFighterMc() : FighterMC
      {
         return this._mc;
      }
      
      public function getCurAction() : String
      {
         if(this._doingAirAction != null)
         {
            return this._doingAirAction;
         }
         return this._doingAction;
      }
      
      public function setActionCtrler(param1:IFighterActionCtrl) : void
      {
         this._actionCtrler = param1;
      }
      
      public function setMc(param1:FighterMC) : void
      {
         this._mc = param1;
         this.idle();
      }
      
      public function setSteelBody(param1:Boolean, param2:Boolean = false) : void
      {
         this._fighter.isSteelBody = param1;
         this._fighter.isSuperSteelBody = param1 && param2;
         if(param1)
         {
            this.effectCtrler.startGlow(param2 ? 16776960 : 16777215);
         }
         else
         {
            this.effectCtrler.endGlow();
         }
      }
      
      public function addQi(param1:Number) : void
      {
         this._fighter.addQi(param1);
      }
      
      public function idle(param1:String = "站立") : void
      {
         var _loc2_:Boolean = false;
         if(FighterActionState.isHurting(this._fighter.actionState))
         {
            this._justHurtResume = true;
         }
         this.endAct();
         this._doingAction = null;
         this._doingAirAction = null;
         this.setSteelBody(false);
         this._justDefenseFrame = 0.1 * GameConfig.FPS_GAME;
         this.effectCtrler.endShadow();
         this.effectCtrler.endShake();
         this._action.clearAction();
         this._action.clearState();
         this._fighter.actionState = 0;
         this._fighter.isAllowBeHit = !this._justHurtResume;
         this._fighter.isApplyG = true;
         this._fighter.isCross = false;
         this._fighter.hurtHit = null;
         this._fighter.defenseHit = null;
         this._fighter.clearHurtHits();
         this._fighter.getDisplay().visible = true;
         this._isDefense = false;
         this._autoDirectFrame = 0;
         if(!this._isTouchFloor)
         {
            this.fall();
         }
         else
         {
            _loc2_ = true;
            this._fighter.setVelocity(0,0);
            if(param1 == "站立")
            {
               _loc2_ = false;
               this._action.jumpTimes = this._fighter.jumpTimes;
               this._action.airHitTimes = this._fighter.airHitTimes;
               this.setAllAct();
            }
            this._mc.goFrame(param1,_loc2_);
         }
      }
      
      public function loop(param1:String) : void
      {
         this._mc.goFrame(param1);
      }
      
      public function stop() : void
      {
         this._mc.stopRenderMainAnimate();
      }
      
      public function dash(param1:Number = 3) : void
      {
         this._action.isDashing = true;
         this._fighter.setVelocity(this._fighter.speed * param1 * this._fighter.direct,0);
         this._fighter.setDamping(0,0);
         this._fighter.isCross = true;
         this._fighter.isAllowBeHit = false;
      }
      
      public function dashStop(param1:Number = 0.5) : void
      {
         var _loc2_:Number = Number(this._fighter.getVecX());
         var _loc3_:Number = Math.abs(_loc2_) * param1;
         this._fighter.setDamping(_loc3_);
         this._fighter.isAllowBeHit = true;
         this._fighter.actionState = 0;
         this._action.clearAction();
         this._action.isDashing = false;
         this._fighter.isCross = false;
      }
      
      public function setAllAct() : void
      {
         this.setMove();
         this.setDefense();
         this.setJump();
         this.setJumpDown();
         this.setDash();
         this.setAttack();
         this.setSkill1();
         this.setSkill2();
         this.setZhao1();
         this.setZhao2();
         this.setZhao3();
         this.setCatch1();
         this.setCatch2();
         this.setBisha();
         this.setBishaUP();
         this.setBishaSUPER();
         this.setWankai();
      }
      
      public function setAirAllAct() : void
      {
         this.setDash();
         this.setAttackAIR();
         this.setSkillAIR();
         this.setBishaAIR();
         this.setAirMove(true);
      }
      
      public function setAirMove(param1:Boolean) : void
      {
         this._action.airMove = param1;
      }
      
      public function setMove() : void
      {
         this.setMoveLeft();
         this.setMoveRight();
      }
      
      public function setMoveLeft() : void
      {
         this._action.moveLeft = "走";
      }
      
      public function setMoveRight() : void
      {
         this._action.moveRight = "走";
      }
      
      public function setDefense() : void
      {
         this._action.defense = "防御";
      }
      
      public function setJump(param1:String = "跳") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.jump = param1;
      }
      
      public function setJumpQuick(param1:String = "跳") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.jumpQuick = param1;
      }
      
      public function setJumpDown(param1:String = "落") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.jumpDown = param1;
      }
      
      public function setDash(param1:String = "瞬步") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.dash = param1;
      }
      
      public function setAttack(param1:String = "砍1") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.attack = param1;
      }
      
      public function setSkill1(param1:String = "砍技1") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.skill1 = param1;
      }
      
      public function setSkill2(param1:String = "砍技2") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.skill2 = param1;
      }
      
      public function setZhao1(param1:String = "招1") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.zhao1 = param1;
      }
      
      public function setZhao2(param1:String = "招2") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.zhao2 = param1;
      }
      
      public function setZhao3(param1:String = "招3") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.zhao3 = param1;
      }
      
      public function setCatch1(param1:String = "摔1") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.catch1 = param1;
      }
      
      public function setCatch2(param1:String = "摔2") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.catch2 = param1;
      }
      
      public function setBisha(param1:String = "必杀", param2:int = 100) : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.bisha = param1;
         this._action.bishaQi = GameConfig.INFINITE_ENERGY ? 0 : param2;
      }
      
      public function setBishaUP(param1:String = "上必杀", param2:int = 100) : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.bishaUP = param1;
         this._action.bishaUPQi = GameConfig.INFINITE_ENERGY ? 0 : param2;
      }
      
      public function setBishaSUPER(param1:String = "超必杀", param2:int = 300) : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.bishaSUPER = param1;
         this._action.bishaSUPERQi = GameConfig.INFINITE_ENERGY ? 0 : param2;
      }
      
      public function setAttackAIR(param1:String = "跳砍") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.attackAIR = param1;
      }
      
      public function setSkillAIR(param1:String = "跳招") : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.skillAIR = param1;
      }
      
      public function setBishaAIR(param1:String = "空中必杀", param2:int = 100) : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.bishaAIR = param1;
         this._action.bishaAIRQi = GameConfig.INFINITE_ENERGY ? 0 : param2;
      }
      
      public function setTouchFloor(param1:String = "落地", param2:Boolean = true) : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         this._action.touchFloor = param1;
         this._action.touchFloorBreakAct = param2;
      }
      
      public function setWankai() : void
      {
         if(this._mc.checkFrame("万解"))
         {
            this._action.waiKai = "万解";
         }
         if(this._mc.checkFrame("万解W"))
         {
            this._action.waiKaiW = "万解W";
         }
         if(this._mc.checkFrame("万解S"))
         {
            this._action.waiKaiS = "万解S";
         }
      }
      
      public function setHitTarget(param1:String, param2:String) : void
      {
         this._action.hitTarget = param2;
         this._action.hitTargetChecker = param1;
      }
      
      public function setHurtAction(param1:String) : void
      {
         this._action.hurtAction = param1;
         this._fighter.actionState = 16;
      }
      
      public function move(param1:Number = 0, param2:Number = 0) : void
      {
         if(param1 == 0 && param2 == 0)
         {
            this.stopMove();
            return;
         }
         if(Boolean(this._fighter.isInAir) && param1 != 0)
         {
            this._action.airMove = false;
         }
         param1 *= this._fighter.direct;
         this._fighter.setVelocity(param1,param2);
      }
      
      public function movePercent(param1:Number = 0, param2:Number = 0) : void
      {
         this.move(this._fighter.speed * param1,this._fighter.speed * param2);
      }
      
      public function stopMove() : void
      {
         this._fighter.setVelocity(0,0);
      }
      
      public function damping(param1:Number = 0, param2:Number = 0) : void
      {
         this._fighter.setDamping(param1,param2);
      }
      
      public function dampingPercent(param1:Number = 0, param2:Number = 0) : void
      {
         this._fighter.setDamping(this._fighter.speed * param1,this._fighter.speed * param2);
      }
      
      public function endAct() : void
      {
         this._action.clearAction();
         this._fighter.actionState = 40;
         this._moveTargetParam = null;
         this.setSteelBody(false);
      }
      
      public function fire(param1:String, param2:Object = null) : void
      {
         var mcName:String = null;
         var params:Object = null;
         mcName = param1;
         params = param2;
         var mc:MovieClip = this._mc.getChildByName(mcName) as MovieClip;
         if(Boolean(mc))
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            params.hitVO = this._fighter.getCtrler().hitModel.getHitVOByDisplayName(mcName);
            FighterEventDispatcher.dispatchEvent(this._fighter,"FIRE_BULLET",params);
         }
         else
         {
            this._fighter.setAnimateFrameOut(function():void
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
         var mc:MovieClip = this._mc.getChildByName(mcName) as MovieClip;
         if(Boolean(mc))
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            params.hitVO = this._fighter.getCtrler().hitModel.getHitVOByDisplayName(mcName);
            FighterEventDispatcher.dispatchEvent(this._fighter,"ADD_ATTACKER",params);
         }
         else
         {
            this._fighter.setAnimateFrameOut(function():void
            {
               addAttacker(mcName,params);
            },1);
         }
      }
      
      public function isApplyG(param1:Boolean) : void
      {
         this._fighter.isApplyG = param1;
      }
      
      public function gotoAndPlay(param1:String) : void
      {
         this._mc.goFrame(param1,true);
      }
      
      public function gotoAndStop(param1:String) : void
      {
         this._mc.goFrame(param1,false);
      }
      
      public function hurtFly(param1:Number, param2:Number) : void
      {
         this._mc.playHurtFly(param1 * this._fighter.direct,param2,false);
         this._action.isHurtFlying = true;
         this._fighter.actionState = 22;
         this._hurtDownFrame = 0;
         this._isFalling = false;
      }
      
      public function moveMC(param1:DisplayObject, param2:Object = null, param3:Object = null) : void
      {
         var _loc4_:IGameSprite = this._fighter.getCurrentTarget();
         if(Boolean(param2))
         {
            if(param2 is Number)
            {
               param1.x = this._fighter.x + param2;
            }
            else if(param2.target != undefined && Boolean(_loc4_))
            {
               param1.x = _loc4_.x - this._fighter.x;
               if(isNaN(Number(param2.target)))
               {
                  param1.x += Number(param2.target);
               }
            }
         }
         if(Boolean(param3))
         {
            if(param3 is Number)
            {
               param1.y = this._fighter.y + param3;
            }
            else if(param3.target != undefined && Boolean(_loc4_))
            {
               param1.y = _loc4_.y - this._fighter.y + Number(param3);
               if(isNaN(Number(param3.target)))
               {
                  param1.y += Number(param3.target);
               }
            }
         }
      }
      
      public function justHitToPlay(param1:String, param2:String, param3:Boolean = false, param4:Boolean = false) : void
      {
         if(this._fighter.getCtrler().justHit(param1,param4))
         {
            this._mc.goFrame(param2);
         }
         else if(param3)
         {
            this.idle();
         }
      }
      
      public function getAttacker(param1:String) : FighterAttackerCtrler
      {
         var _loc2_:FighterAttacker = GameCtrl.I.getAttacker(param1,this._fighter.team.id);
         if(Boolean(_loc2_))
         {
            return _loc2_.getCtrler();
         }
         return null;
      }
      
      public function moveTarget(param1:Object = null) : void
      {
         if(!param1)
         {
            this._moveTargetParam.clear();
            this._moveTargetParam = null;
            return;
         }
         this._moveTargetParam = new MoveTargetParamVO(param1);
         this._moveTargetParam.setTarget(this._fighter.getCurrentTarget());
      }
      
      public function render() : void
      {
         if(this._ghostStepIng)
         {
            return;
         }
         if(this._justDefenseFrame > 0)
         {
            --this._justDefenseFrame;
         }
         this._action.render();
         if(Boolean(this._moveTargetParam))
         {
            this.renderMoveTarget();
         }
         if(Boolean(this._actionCtrler))
         {
            this._actionCtrler.render();
         }
         if(this._action.isHurtFlying)
         {
            this.renderHurtFlying();
            return;
         }
         if(this._action.isHurting)
         {
            this.renderHurt();
            return;
         }
         if(this._action.isDefenseHiting)
         {
            this.renderDefense(false,true);
            return;
         }
         if(Boolean(this._action.hitTarget))
         {
            this.renderCheckTargetHit();
         }
         if(this.renderWanKaiCtrl())
         {
            return;
         }
         if(Boolean(this._fighter) && Boolean(this._fighter.isInAir) || Boolean(this._doingAirAction) && Boolean(!this._action.touchFloorBreakAct))
         {
            this.renderAirAction();
         }
         else
         {
            this.renderFloorAction();
         }
      }
      
      private function renderHurtFlying() : void
      {
         if(!this._fighter.isInAir)
         {
            this._isTouchFloor = true;
         }
         if(!this._fighter.isAlive)
         {
            return;
         }
         if(this._fighter.actionState == 24)
         {
            this._hurtDownFrame = 1;
         }
         if(this._hurtDownFrame > 0)
         {
            if(++this._hurtDownFrame < 20)
            {
               if(this._actionCtrler.dashJump())
               {
                  this.doHurtDownJump();
                  this._hurtDownFrame = 0;
               }
            }
         }
      }
      
      private function renderAssist() : void
      {
         if(this._fighter.actionState != 0 && this._fighter.actionState != 20)
         {
            return;
         }
         if(this._actionCtrler.assist())
         {
            if(this._fighter.fzqi >= 100)
            {
               this._fighter.fzqi = 0;
               FighterEventDispatcher.dispatchEvent(this._fighter,"ADD_ASSISTER");
            }
         }
      }
      
      private function renderFloorAction() : void
      {
         if(!this._isTouchFloor)
         {
            this.touchFloor();
         }
         if(this._actionCtrler == null || !this._actionCtrler.enabled())
         {
            if(this._mc.currentFrameName == "走" || this._mc.currentFrameName == "防御")
            {
               this.idle();
            }
            return;
         }
         this.renderAssist();
         if(Boolean(this._action.catch1) && Boolean(this._actionCtrler.catch1()))
         {
            this.doCatch(this._action.catch1);
         }
         if(Boolean(this._action.catch2) && Boolean(this._actionCtrler.catch2()))
         {
            this.doCatch(this._action.catch2);
         }
         if(Boolean(this._action.bishaSUPER) && Boolean(this._actionCtrler.bishaSUPER()))
         {
            this.doBisha(this._action.bishaSUPER,this._action.bishaSUPERQi,true);
         }
         if(Boolean(this._action.bishaUP) && Boolean(this._actionCtrler.bishaUP()))
         {
            this.doBisha(this._action.bishaUP,this._action.bishaUPQi);
         }
         if(Boolean(this._action.bisha) && Boolean(this._actionCtrler.bisha()))
         {
            this.doBisha(this._action.bisha,this._action.bishaQi);
         }
         if(Boolean(this._action.skill2) && Boolean(this._actionCtrler.skill2()))
         {
            this.doSkill(this._action.skill2);
         }
         if(Boolean(this._action.skill1) && Boolean(this._actionCtrler.skill1()))
         {
            this.doSkill(this._action.skill1);
         }
         if(Boolean(this._action.zhao3) && Boolean(this._actionCtrler.zhao3()))
         {
            this.doSkill(this._action.zhao3);
         }
         if(Boolean(this._action.zhao2) && Boolean(this._actionCtrler.zhao2()))
         {
            this.doSkill(this._action.zhao2);
         }
         if(Boolean(this._action.attack) && Boolean(this._actionCtrler.attack()))
         {
            this.doAttack(this._action.attack);
         }
         if(Boolean(this._action.zhao1) && Boolean(this._actionCtrler.zhao1()))
         {
            this.doSkill(this._action.zhao1);
         }
         if(Boolean(this._action.defense) && Boolean(this._actionCtrler.defense()))
         {
            this.doDefense();
         }
         if(Boolean(this._action.dash) && Boolean(this._actionCtrler.dash()))
         {
            this.doDash(this._action.dash);
         }
         if(Boolean(this._action.moveLeft) && Boolean(this._actionCtrler.moveLEFT()))
         {
            this.doMove(this._action.moveLeft,-1);
         }
         if(Boolean(this._action.moveRight) && Boolean(this._actionCtrler.moveRIGHT()))
         {
            this.doMove(this._action.moveRight,1);
         }
         if(Boolean(this._action.jump) && Boolean(this._actionCtrler.jump()))
         {
            this.doJump(this._action.jump);
         }
         if(Boolean(this._action.jumpDown) && Boolean(this._actionCtrler.jumpDown()))
         {
            this.doJumpDown(this._action.jumpDown);
         }
         if(this._action.isMoving)
         {
            this.renderMoving();
         }
         if(this._action.isDefensing)
         {
            this.renderDefense();
         }
         if(FighterActionState.allowGhostStep(this._fighter.actionState))
         {
            if(this._actionCtrler.ghostStep())
            {
               this.doGhostStep();
            }
            if(this._actionCtrler.ghostJump())
            {
               this.doGhostJump();
            }
         }
         if(FighterActionState.isAttacking(this._fighter.actionState))
         {
            if(Boolean(this._action.attackAIR) && Boolean(this._actionCtrler.attackAIR()))
            {
               this.doAirAttack(this._action.attackAIR);
            }
            if(Boolean(this._action.skillAIR) && Boolean(this._actionCtrler.skillAIR()))
            {
               this.doAirSkill(this._action.skillAIR);
            }
            if(Boolean(this._action.bishaAIR) && Boolean(this._actionCtrler.bishaAIR()))
            {
               this.doAirBisha(this._action.bishaAIR,this._action.bishaAIRQi);
            }
         }
      }
      
      private function renderWanKaiCtrl() : Boolean
      {
         if(!this._actionCtrler || !this._actionCtrler.enabled())
         {
            return false;
         }
         if(this._actionCtrler.waiKai())
         {
            return this.checkDoWankai(this._action.waiKai,"万解");
         }
         if(this._actionCtrler.waiKaiW())
         {
            return this.checkDoWankai(this._action.waiKaiW,"万解W");
         }
         if(this._actionCtrler.waiKaiS())
         {
            return this.checkDoWankai(this._action.waiKaiS,"万解S");
         }
         return false;
      }
      
      private function checkDoWankai(param1:String, param2:String) : Boolean
      {
         if(Boolean(param1))
         {
            this.doWaiKaiAction(param1);
            return true;
         }
         if(this._doingAction == "砍1")
         {
            if(this._doActionFrame < 2)
            {
               this.doWaiKaiAction(param2);
               return true;
            }
         }
         return false;
      }
      
      public function renderAnimate() : void
      {
         if(this._justHurtResume)
         {
            this._fighter.isAllowBeHit = true;
            this._justHurtResume = false;
         }
         this.renderBeHitGap();
         if(Boolean(this._mc))
         {
            this._mc.renderAnimate();
         }
         if(Boolean(this._actionCtrler))
         {
            this._actionCtrler.renderAnimate();
         }
         if(this._ghostStepIng)
         {
            this.renderGhostStep();
            return;
         }
         if(Boolean(this._action))
         {
            if(this._action.isHurting)
            {
               this.renderHurtAnimate();
            }
            if(this._action.isDefenseHiting)
            {
               this.renderDefensHiting();
            }
            if(this._action.isJumping)
            {
               this.renderJumpAnimate();
            }
            if(Boolean(this._doingAction))
            {
               ++this._doActionFrame;
            }
            if(this._action.isDefensing)
            {
               this.renderDefenseAnimate();
            }
         }
         if(Boolean(this._mc) && this._mc.currentFrameName == "站立")
         {
            if(++this._autoDirectFrame > 5)
            {
               this._fighter.getCtrler().setDirectToTarget();
               this._autoDirectFrame = 0;
            }
         }
      }
      
      private function renderAirAction() : void
      {
         if(!this._action.isJumping)
         {
            this.fall();
         }
         this._isTouchFloor = false;
         if(this._actionCtrler == null || !this._actionCtrler.enabled())
         {
            return;
         }
         if(Boolean(this._action.attackAIR) && Boolean(this._actionCtrler.attackAIR()))
         {
            this.doAirAttack(this._action.attackAIR);
         }
         if(Boolean(this._action.skillAIR) && Boolean(this._actionCtrler.skillAIR()))
         {
            this.doAirSkill(this._action.skillAIR);
         }
         if(Boolean(this._action.bishaAIR) && Boolean(this._actionCtrler.bishaAIR()))
         {
            this.doAirBisha(this._action.bishaAIR,this._action.bishaAIRQi);
         }
         if(Boolean(this._action.jump) && Boolean(this._actionCtrler.jump()))
         {
            this.doAirJump(this._action.jump);
         }
         if(Boolean(this._action.jumpQuick) && Boolean(this._actionCtrler.jumpQuick()))
         {
            this.doAirJump(this._action.jumpQuick);
         }
         if(FighterActionState.isAttacking(this._fighter.actionState))
         {
            if(Boolean(this._action.bishaSUPER) && Boolean(this._actionCtrler.bishaSUPER()))
            {
               this.doBisha(this._action.bishaSUPER,this._action.bishaSUPERQi,true);
            }
            if(Boolean(this._action.bishaUP) && Boolean(this._actionCtrler.bishaUP()))
            {
               this.doBisha(this._action.bishaUP,this._action.bishaUPQi);
            }
            if(Boolean(this._action.bisha) && Boolean(this._actionCtrler.bisha()))
            {
               this.doBisha(this._action.bisha,this._action.bishaQi);
            }
            if(Boolean(this._action.skill2) && Boolean(this._actionCtrler.skill2()))
            {
               this.doSkill(this._action.skill2);
            }
            if(Boolean(this._action.skill1) && Boolean(this._actionCtrler.skill1()))
            {
               this.doSkill(this._action.skill1);
            }
            if(Boolean(this._action.zhao3) && Boolean(this._actionCtrler.zhao3()))
            {
               this.doSkill(this._action.zhao3);
            }
            if(Boolean(this._action.zhao2) && Boolean(this._actionCtrler.zhao2()))
            {
               this.doSkill(this._action.zhao2);
            }
            if(Boolean(this._action.attack) && Boolean(this._actionCtrler.attack()))
            {
               this.doAttack(this._action.attack);
            }
            if(Boolean(this._action.zhao1) && Boolean(this._actionCtrler.zhao1()))
            {
               this.doSkill(this._action.zhao1);
            }
         }
         if(Boolean(this._action.dash) && Boolean(this._actionCtrler.dash()))
         {
            this.doDashAir(this._action.dash);
         }
         if(this._action.airMove)
         {
            this.doAirMove();
         }
         if(this._actionCtrler.ghostJump())
         {
            this.doGhostJump();
         }
         if(this._actionCtrler.ghostJumpDown())
         {
            this.doGhostJumpDown();
         }
      }
      
      private function renderMoveTarget() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:DisplayObject = null;
         var _loc4_:IGameSprite = this._moveTargetParam.target;
         if(!_loc4_)
         {
            return;
         }
         if(Boolean(this._moveTargetParam.followMcName))
         {
            _loc3_ = this._mc.getChildByName(this._moveTargetParam.followMcName);
            if(!_loc3_)
            {
               return;
            }
            _loc1_ = this._fighter.x + _loc3_.x * this._fighter.direct;
            _loc2_ = this._fighter.y + _loc3_.y;
         }
         else
         {
            if(!isNaN(this._moveTargetParam.x))
            {
               _loc1_ = Number(this._moveTargetParam.x);
            }
            if(!isNaN(this._moveTargetParam.y))
            {
               _loc2_ = Number(this._moveTargetParam.y);
            }
         }
         if(Boolean(this._moveTargetParam.speed))
         {
            if(this._moveTargetParam.speed.x > 0 && !isNaN(_loc1_))
            {
               if(_loc4_.x > _loc1_ + this._moveTargetParam.speed.x)
               {
                  _loc4_.x -= this._moveTargetParam.speed.x;
               }
               if(_loc4_.x < _loc1_ - this._moveTargetParam.speed.x)
               {
                  _loc4_.x += this._moveTargetParam.speed.x;
               }
               if(_loc4_.y > _loc2_ + this._moveTargetParam.speed.y)
               {
                  if(_loc4_ is BaseGameSprite)
                  {
                     (_loc4_ as BaseGameSprite).setVecY(-this._moveTargetParam.speed.y);
                     (_loc4_ as BaseGameSprite).setDampingY(1);
                  }
                  else
                  {
                     _loc4_.y -= this._moveTargetParam.speed.y;
                  }
               }
               if(_loc4_.y < _loc2_ - this._moveTargetParam.speed.y)
               {
                  if(_loc4_ is BaseGameSprite)
                  {
                     (_loc4_ as BaseGameSprite).setVecY(this._moveTargetParam.speed.y);
                     (_loc4_ as BaseGameSprite).setDampingY(1);
                  }
                  else
                  {
                     _loc4_.y += this._moveTargetParam.speed.y;
                  }
               }
            }
         }
         else
         {
            if(!isNaN(_loc1_))
            {
               _loc4_.x = _loc1_;
            }
            if(!isNaN(_loc2_))
            {
               _loc4_.y = _loc2_;
            }
         }
      }
      
      private function fall() : void
      {
         if(this._isFalling)
         {
            return;
         }
         if(Boolean(this._doingAction))
         {
            return;
         }
         this._action.clearState();
         this._action.clearAction();
         this.setAirAllAct();
         this.setJump();
         this._isFalling = true;
         this._doingAirAction = null;
         this._isTouchFloor = false;
         this._isDefense = false;
         this._fighter.setVecX(0);
         this.setTouchFloor("落地",true);
         this._mc.goFrame("落",false);
      }
      
      public function touchFloor() : void
      {
         if(!this._fighter.isAlive)
         {
            return;
         }
         var _loc1_:String = this._action.touchFloor;
         if(this._isFalling)
         {
            if(!_loc1_)
            {
               _loc1_ = "落地";
            }
         }
         if(_loc1_ == null)
         {
            return;
         }
         var _loc2_:Object = _loc1_ == "落地" ? {
            "call":this.setAttack,
            "delay":1
         } : null;
         this.doAction(_loc1_,false,_loc2_);
         this.effectCtrler.touchFloor();
         this._action.airHitTimes = this._fighter.airHitTimes;
         this._action.jumpTimes = this._fighter.jumpTimes;
         this._isTouchFloor = true;
         this._isFalling = false;
      }
      
      private function doAction(param1:String, param2:Boolean = false, param3:Object = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         this.effectCtrler.endShadow();
         this.effectCtrler.endShake();
         this._fighter.setVelocity(0,0);
         this._action.isMoving = false;
         this._action.isDefensing = false;
         this._action.isDashing = false;
         this._doingAction = param1;
         this._doingAirAction = param2 ? param1 : null;
         this._action.clearAction();
         this._isFalling = false;
         this._isDefense = false;
         this._fighter.isAllowBeHit = true;
         this._fighter.isCross = false;
         this._fighter.isApplyG = true;
         this._doActionFrame = 0;
         this._mc.goFrame(param1,true,0,param3);
         this._fighter.dispatchEvent(new FighterEvent("DO_ACTION"));
      }
      
      private function setMoveAction() : void
      {
         this._action.clearAction();
         this._action.isMoving = true;
         this.setMove();
         this.setAttack();
         this.setZhao1();
         this.setZhao3();
         this.setSkill2();
         this.setJump();
         this.setDash();
         this.setBisha();
         this.setBishaUP();
         this.setDefense();
         this.setCatch1();
         this.setCatch2();
      }
      
      private function renderMoving() : void
      {
         if(this._actionCtrler.moveLEFT())
         {
            this._fighter.direct = -1;
            this.move(this._fighter.speed);
         }
         else if(this._actionCtrler.moveRIGHT())
         {
            this._fighter.direct = 1;
            this.move(this._fighter.speed);
         }
         else
         {
            this.idle();
         }
      }
      
      private function doMove(param1:String, param2:int = 1) : void
      {
         if(this._action.isMoving)
         {
            return;
         }
         this._mc.goFrame(param1,true);
         this._fighter.actionState = 0;
         this.setMoveAction();
      }
      
      private function doAirMove() : void
      {
         if(this._actionCtrler.moveLEFT())
         {
            this._fighter.move(-this._fighter.speed);
         }
         if(this._actionCtrler.moveRIGHT())
         {
            this._fighter.move(this._fighter.speed);
         }
      }
      
      private function renderDefense(param1:Boolean = true, param2:Boolean = false) : void
      {
         if(this._actionCtrler.moveLEFT())
         {
            if(this._fighter.direct != -1)
            {
               this._fighter.direct = -1;
               this.setDefenseAction(param1,param2);
            }
         }
         if(this._actionCtrler.moveRIGHT())
         {
            if(this._fighter.direct != 1)
            {
               this._fighter.direct = 1;
               this.setDefenseAction(param1,param2);
            }
         }
      }
      
      private function renderDefenseAnimate() : void
      {
         if(this._action.isDefenseHiting)
         {
            return;
         }
         if(this._defenseFrameDelay-- > 0)
         {
            return;
         }
         if(Boolean(this._actionCtrler.enabled()) && Boolean(this._actionCtrler.defense()))
         {
            if(!this._isDefense)
            {
               this._isDefense = true;
            }
         }
         else
         {
            if(this._defenseFrameDelay > -5)
            {
               return;
            }
            this._action.isDefensing = false;
            this._mc.goFrame("防御恢复",false,0,{
               "call":this.idle,
               "delay":1
            });
         }
      }
      
      private function setDefenseAction(param1:Boolean = true, param2:Boolean = false) : void
      {
         if(param1)
         {
            this._action.clearAction();
            this._action.clearState();
            this._action.isDefensing = true;
            this.setSkill1();
            this.setZhao2();
            this.setBishaSUPER();
            this.setJumpDown();
         }
         if(param2)
         {
            this._isDefense = true;
         }
         else
         {
            this._isDefense = this._justDefenseFrame > 0 ? true : false;
         }
         this._defenseFrameDelay = 1;
         this._mc.goFrame("防御",true,3);
      }
      
      private function doDefense() : void
      {
         if(this._action.isDefensing)
         {
            return;
         }
         this._fighter.actionState = 20;
         this.dampingPercent(1,1);
         this.setDefenseAction();
      }
      
      private function doDash(param1:String) : void
      {
         if(!this._fighter.hasEnergy(20,true))
         {
            return;
         }
         this._fighter.useEnergy(20);
         if(this._actionCtrler.moveLEFT())
         {
            this._fighter.direct = -1;
         }
         if(this._actionCtrler.moveRIGHT())
         {
            this._fighter.direct = 1;
         }
         this.doAction(param1);
         this._fighter.actionState = 15;
         this._fighter.isAllowBeHit = false;
         this.isApplyG(false);
      }
      
      private function doDashAir(param1:String) : void
      {
         if(this._action.jumpTimes < 1)
         {
            return;
         }
         if(!this._fighter.hasEnergy(30,true))
         {
            return;
         }
         this._fighter.useEnergy(30);
         this.doAction(param1);
         this._fighter.actionState = 15;
         this._fighter.isAllowBeHit = false;
         this.isApplyG(false);
         this._action.jumpTimes = 0;
      }
      
      private function doJump(param1:String) : void
      {
         if(this._action.jumpTimes <= 0)
         {
            return;
         }
         this._action.clearAction();
         this._action.clearState();
         this._doingAction = null;
         this._doingAirAction = null;
         this._mc.goFrame("起跳",false);
         this._jumpDelayFrame = 2;
         this._action.isJumping = true;
         this._fighter.actionState = 14;
      }
      
      private function doJumpDown(param1:String) : void
      {
         if(this._fighter.isTouchBottom)
         {
            return;
         }
         this._action.clear();
         this._action.jumpTimes = 0;
         this._fighter.setVecY(5);
         this._fighter.setDamping(0,1);
         this._fighter.y += 1;
         this._isDefense = false;
         this._mc.goFrame(param1,false);
         this.setTouchFloor();
      }
      
      private function doAirJump(param1:String) : void
      {
         if(this._action.jumpTimes <= 0)
         {
            return;
         }
         this._action.clearAction();
         this._action.clearState();
         this._doingAction = null;
         this._doingAirAction = null;
         this._jumpDelayFrame = 1;
         this._action.isJumping = true;
         this._fighter.actionState = 14;
      }
      
      public function renderJumpAnimate() : void
      {
         if(Boolean(this._doingAction))
         {
            return;
         }
         if(this._jumpDelayFrame > 0)
         {
            --this._jumpDelayFrame;
            if(this._jumpDelayFrame == 0)
            {
               this._isFalling = false;
               --this._action.jumpTimes;
               this._mc.goFrame("跳",false);
               this._fighter.jump();
               this.setAirAllAct();
               if(this._fighter.isInAir)
               {
                  this.effectCtrler.jumpAir();
               }
               else
               {
                  this.effectCtrler.jump();
               }
            }
            return;
         }
         if(this._mc.getCurrentFrameCount() == 2)
         {
            this.setJumpQuick();
         }
         var _loc1_:Number = Number(this._fighter.getVecY());
         if(this._mc.currentFrameName != "跳中" && _loc1_ > -this._fighter.jumpPower * 0.35)
         {
            this._mc.goFrame("跳中",false);
            this._fighter.setAnimateFrameOut(this.setJump,5);
         }
         if(_loc1_ >= 0)
         {
            this._action.isJumping = false;
            this._isFalling = true;
         }
      }
      
      private function doAttack(param1:String) : void
      {
         this.doAction(param1);
         this._fighter.actionState = 10;
      }
      
      private function doSkill(param1:String) : void
      {
         this.doAction(param1);
         this._fighter.actionState = 11;
      }
      
      private function doCatch(param1:String) : void
      {
         if(!this.allowCatch())
         {
            return;
         }
         this.doAction(param1);
         this._fighter.actionState = 11;
      }
      
      private function doBisha(param1:String, param2:int, param3:Boolean = false) : void
      {
         if(GameConfig.INFINITE_ENERGY)
         {
            param2 = 0;
         }
         if(!this._fighter.useQi(param2))
         {
            return;
         }
         this._fighter.actionState = param3 ? 13 : 12;
         this.doAction(param1);
      }
      
      private function doWaiKaiAction(param1:String) : void
      {
         if(!this._mc.checkFrame(param1))
         {
            return;
         }
         if(!GameConfig.INFINITE_ENERGY)
         {
         }
         if(!this._fighter.useQi(300))
         {
            return;
         }
         this._fighter.actionState = 50;
         this.doAction(param1);
         this._fighter.isAllowBeHit = false;
      }
      
      private function doAirAttack(param1:String) : void
      {
         if(this._doingAction == null && this._action.airHitTimes <= 0)
         {
            return;
         }
         this._fighter.addDamping(0,3);
         --this._action.airHitTimes;
         this._action.jumpTimes = 0;
         this.doAction(param1,true);
         this._fighter.actionState = 10;
      }
      
      private function doAirSkill(param1:String) : void
      {
         if(this._doingAction == null && this._action.airHitTimes <= 0)
         {
            return;
         }
         this._action.airHitTimes = 0;
         this._action.jumpTimes = 0;
         this.doAction(param1,true);
         this._fighter.actionState = 11;
      }
      
      private function doAirBisha(param1:String, param2:int) : void
      {
         if(this._doingAction == null && this._action.airHitTimes <= 0)
         {
            return;
         }
         if(!this._fighter.useQi(param2))
         {
            return;
         }
         this._fighter.actionState = 12;
         this._action.airHitTimes = 0;
         this.doAction(param1,true);
      }
      
      public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
         var _loc3_:BaseGameSprite = null;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         if(Boolean(this._action.hurtAction))
         {
            this.doAction(this._action.hurtAction);
            return;
         }
         if(this._fighter.getIsTouchSide())
         {
            if(Boolean(param1.owner) && param1.owner is BaseGameSprite)
            {
               _loc3_ = param1.owner as BaseGameSprite;
               if(Math.abs(this._fighter.x - param1.owner.x) < 100)
               {
                  _loc4_ = 0.3;
                  _loc5_ = -param1.hitx * _loc3_.direct * 1.4;
                  if(_loc5_ > 20)
                  {
                     _loc5_ = 20;
                  }
                  if(_loc5_ < -20)
                  {
                     _loc5_ = -20;
                  }
                  _loc3_.setVec2(_loc5_,0,_loc4_,0);
               }
            }
         }
         if(this._isDefense)
         {
            if(param1.isBreakDef && param1.hitType == 11)
            {
               this.doHurt(param1,param2);
               return;
            }
            if(param1.checkDirect && Boolean(param1.owner))
            {
               if(this.checkDefDirect(param1.owner))
               {
                  this.doHurt(param1,param2);
                  return;
               }
            }
            this.doDefenseHit(param1,param2);
         }
         else if(Boolean(this._fighter.isSteelBody) && Boolean(this._fighter.isAlive))
         {
            this.doSteelHurt(param1,param2);
         }
         else
         {
            this.doHurt(param1,param2);
         }
      }
      
      private function checkDefDirect(param1:IGameSprite) : Boolean
      {
         var _loc2_:int = 5;
         if(this._fighter.x < param1.x - _loc2_)
         {
            return this._fighter.direct < 0 && param1.direct < 0;
         }
         if(this._fighter.x > param1.x + _loc2_)
         {
            return this._fighter.direct > 0 && param1.direct > 0;
         }
         return false;
      }
      
      private function doSteelHurt(param1:HitVO, param2:Rectangle) : void
      {
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:* = NaN;
         var _loc6_:* = NaN;
         if(!this._fighter.isSuperSteelBody && (Boolean(this._fighter.energyOverLoad) || param1.isBisha() || param1.isCatch()))
         {
            this.doHurt(param1,param2);
            return;
         }
         this._fighter.hurtHit = param1;
         if(this._fighter.isSuperSteelBody)
         {
            this._fighter.loseHp(param1.getDamage() * 0.3);
         }
         else
         {
            this._fighter.loseHp(param1.getDamage() * 0.65);
         }
         if(Boolean(this._fighter.isAlive) && Boolean(GameLogic.checkFighterDie(this._fighter)))
         {
            FighterEventDispatcher.dispatchEvent(this._fighter,"DIE");
            this._fighter.isAlive = false;
            this.doHurt(param1,param2);
            return;
         }
         if(param1.hurtType == 1)
         {
            this._beHitGap = 10;
         }
         else
         {
            this._beHitGap = 4;
         }
         if(this._fighter.isSuperSteelBody)
         {
            this._fighter.useEnergy(param1.getDamage() * 0.2);
         }
         else if(param1.isBreakDef)
         {
            this._fighter.useEnergy(param1.getDamage());
         }
         else
         {
            this._fighter.useEnergy(param1.getDamage() * 0.4);
         }
         this._fighter.isAllowBeHit = false;
         if(!this._fighter.isSuperSteelBody)
         {
            _loc3_ = param1.hitx;
            _loc4_ = param1.hity;
            if(Boolean(param1.owner))
            {
               _loc3_ *= param1.owner.direct;
            }
            _loc5_ = _loc3_;
            _loc6_ = _loc4_;
            if(param1.isBreakDef)
            {
               _loc5_ *= 2;
               _loc6_ *= 2;
            }
            this._fighter.setVec2(_loc5_,_loc6_,Math.abs(_loc3_ * 0.1),Math.abs(_loc4_ * 0.1));
         }
         if(Boolean(param1) && Boolean(param2))
         {
            EffectCtrl.I.doSteelHitEffect(param1,param2,this._fighter);
         }
      }
      
      private function doHurt(param1:HitVO, param2:Rectangle) : void
      {
         this.effectCtrler.endShadow();
         this.effectCtrler.endShake();
         this._fighter.hurtHit = param1;
         this._fighter.loseHp(param1.getDamage());
         if(Boolean(this._fighter.isAlive) && Boolean(GameLogic.checkFighterDie(this._fighter)))
         {
            FighterEventDispatcher.dispatchEvent(this._fighter,"DIE");
            this._fighter.isAlive = false;
         }
         this._beHitGap = 4;
         this._fighter.isAllowBeHit = false;
         this._fighter.isApplyG = true;
         this._isDefense = false;
         var _loc3_:Number = param1.hitx;
         var _loc4_:Number = param1.hity;
         if(Boolean(param1.owner))
         {
            _loc3_ *= param1.owner.direct;
         }
         if(this._fighter.isInAir)
         {
            if(_loc4_ <= 0)
            {
               _loc4_ -= 3;
            }
         }
         else if(_loc4_ < 0)
         {
            _loc4_ -= 6;
            this._isTouchFloor = false;
         }
         this._action.clearState();
         this._doingAirAction = null;
         this._doingAction = null;
         this.setSteelBody(false);
         if(param1.hurtType == 0)
         {
            this._action.isHurting = true;
            this._hurtHoldFrame = Math.round(param1.hurtTime / 1000 * 30) + GameConfig.HURT_FRAME_OFFSET;
            if(this._hurtHoldFrame < 4)
            {
               this._hurtHoldFrame = 4;
            }
            if(param1.hitType == 11)
            {
               this._mc.goFrame("被打",false);
            }
            else
            {
               this._mc.goFrame("被打",true,7);
            }
            this._fighter.actionState = 21;
            this._fighter.setVelocity(_loc3_,_loc4_);
            this._fighter.setDamping(0.1,0.5);
            if(Boolean(this._fighter.isAlive) && Boolean(HitType.isHeavy(param1.hitType)))
            {
               this._fighter.getCtrler().getVoiceCtrl().playVoice(0,0.5);
            }
         }
         if(param1.hurtType == 1)
         {
            this._action.isHurtFlying = true;
            this._fighter.actionState = 22;
            this._hurtDownFrame = 0;
            this._mc.playHurtFly(_loc3_,_loc4_);
            if(this._fighter.isAlive)
            {
               this._fighter.getCtrler().getVoiceCtrl().playVoice(1,1);
            }
            else
            {
               this._fighter.getCtrler().getVoiceCtrl().playVoice(2,1);
            }
         }
         if(Boolean(param1) && Boolean(param2))
         {
            EffectCtrl.I.doHitEffect(param1,param2,this._fighter);
         }
         this._isFalling = false;
      }
      
      private function renderHurt() : void
      {
         if(!this._fighter.isAlive)
         {
            return;
         }
         this.renderHurtBreak();
      }
      
      private function renderHurtBreak() : void
      {
         if(!this._actionCtrler.specailSkill())
         {
            return;
         }
         if(!this._fighter.hasEnergy(50))
         {
            return;
         }
         if(this._fighter.qi < 100)
         {
            return;
         }
         var _loc1_:Boolean = Boolean(this._fighter.getLastHurtHitVO().isBisha());
         if(_loc1_)
         {
            return;
         }
         var _loc2_:Boolean = Boolean(this._fighter.hurtBreakHit());
         if(_loc2_)
         {
            return;
         }
         var _loc3_:int = int(this._fighter.currentHurtDamage());
         if(_loc3_ > 210)
         {
            return;
         }
         this._fighter.useQi(100);
         this._fighter.useEnergy(100);
         if(this._fighter.data.comicType == 1)
         {
            this._fighter.replaceSkill();
         }
         else
         {
            this._fighter.energyExplode();
         }
         FighterEventDispatcher.dispatchEvent(this._fighter,"HURT_RESUME");
      }
      
      private function renderHurtAnimate() : void
      {
         var _loc1_:Point = null;
         if(this._hurtHoldFrame-- <= 0)
         {
            if(!this._fighter.isAlive)
            {
               this._action.clearState();
               if(this._fighter.isInAir)
               {
                  _loc1_ = this._fighter.getVec2();
                  this.hurtFly(_loc1_.x,_loc1_.y);
               }
               else
               {
                  this._mc.playHurtDown();
               }
               this._fighter.getCtrler().getVoiceCtrl().playVoice(2,1);
            }
            else
            {
               this.hurtResume();
            }
         }
      }
      
      private function hurtResume() : void
      {
         if(!this._fighter.isInAir && !this._isTouchFloor)
         {
            this._isTouchFloor = true;
         }
         this.idle();
         FighterEventDispatcher.dispatchEvent(this._fighter,"HURT_RESUME");
      }
      
      private function renderBeHitGap() : void
      {
         if(this._beHitGap > 0)
         {
            if(--this._beHitGap <= 0)
            {
               this._fighter.isAllowBeHit = true;
            }
         }
      }
      
      private function doDefenseHit(param1:HitVO, param2:Rectangle) : void
      {
         this._fighter.loseHp(param1.getDamage() * 0.05);
         if(Boolean(this._fighter.isAlive) && Boolean(GameLogic.checkFighterDie(this._fighter)))
         {
            FighterEventDispatcher.dispatchEvent(this._fighter,"DIE");
            this._fighter.isAlive = false;
            this.doHurt(param1,param2);
            return;
         }
         this._fighter.defenseHit = param1;
         var _loc3_:int = 0;
         if(param1.isBreakDef)
         {
            _loc3_ = 90;
         }
         else
         {
            _loc3_ = param1.getDamage() / 5;
            if(_loc3_ > 50)
            {
               _loc3_ = 50;
            }
         }
         if(!this._fighter.hasEnergy(_loc3_,false))
         {
            this._fighter.useEnergy(_loc3_);
            this.doBreakDefense(param1,param2);
            return;
         }
         this._fighter.useEnergy(_loc3_);
         this._beHitGap = 4;
         this._fighter.isAllowBeHit = false;
         var _loc4_:Number = param1.hitx;
         if(Boolean(param1.owner))
         {
            _loc4_ *= param1.owner.direct;
         }
         this._action.isDefenseHiting = true;
         if(param1.hurtType == 0)
         {
            this._defenseHoldFrame = param1.hurtTime / 1000 * GameConfig.FPS_GAME / 5;
            if(this._defenseHoldFrame < 5)
            {
               this._defenseHoldFrame = 5;
            }
            if(this._defenseHoldFrame > 10)
            {
               this._defenseHoldFrame = 10;
            }
         }
         else
         {
            this._defenseHoldFrame = 10;
            this._beHitGap = 8;
         }
         this._fighter.setVelocity(_loc4_,0);
         this._fighter.setDamping(1,0);
         if(Boolean(param1) && Boolean(param2))
         {
            EffectCtrl.I.doDefenseEffect(param1,param2,this._fighter.defenseType);
         }
      }
      
      private function doBreakDefense(param1:HitVO, param2:Rectangle) : void
      {
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         this._fighter.loseHp(param1.getDamage() / 10);
         if(param1.hurtType == 0)
         {
            this._beHitGap = 4;
         }
         if(param1.hurtType == 1)
         {
            this._beHitGap = 10;
         }
         this._fighter.isAllowBeHit = false;
         this._fighter.energyOverLoad = false;
         this._isDefense = false;
         var _loc5_:Number = param1.hitx;
         if(_loc5_ < 5)
         {
            _loc5_ = 5;
         }
         if(_loc5_ > 10)
         {
            _loc5_ = 10;
         }
         if(Boolean(param1.owner))
         {
            _loc5_ *= param1.owner.direct;
         }
         this._action.clearState();
         this._action.isHurting = true;
         this._hurtHoldFrame = 42;
         this._mc.goFrame("被打",true,7);
         this._fighter.actionState = 21;
         this._fighter.setVelocity(_loc5_);
         this._fighter.setDamping(0.1);
         if(Boolean(param1) && Boolean(param2))
         {
            _loc3_ = param2.x + param2.width / 2;
            _loc4_ = param2.y + param2.height / 2;
            EffectCtrl.I.doDefenseEffect(param1,param2,this._fighter.defenseType);
            EffectCtrl.I.doEffectById("break_def",_loc3_,_loc4_,this._fighter.direct);
         }
      }
      
      private function renderDefensHiting() : void
      {
         if(this._defenseHoldFrame > 0)
         {
            --this._defenseHoldFrame;
         }
         else if(this._fighter.getVecX() == 0)
         {
            this._action.isDefenseHiting = false;
         }
      }
      
      private function renderCheckTargetHit() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Rectangle = null;
         var _loc3_:String = this._action.hitTargetChecker;
         if(!_loc3_)
         {
            return;
         }
         var _loc4_:Rectangle = this._fighter.getCtrler().getHitCheckRect(_loc3_);
         if(!_loc4_)
         {
            return;
         }
         var _loc5_:Vector.<IGameSprite> = this._fighter.getTargets();
         if(!_loc5_)
         {
            return;
         }
         while(_loc1_ < _loc5_.length)
         {
            if(_loc5_[_loc1_] is FighterMain)
            {
               _loc2_ = _loc5_[_loc1_].getBodyArea();
               if(Boolean(_loc2_) && _loc4_.intersects(_loc2_))
               {
                  this.doAction(this._action.hitTarget);
               }
            }
            _loc1_++;
         }
      }
      
      private function allowCatch() : Boolean
      {
         var _loc1_:Number = NaN;
         var _loc2_:IGameSprite = this._fighter.getCurrentTarget();
         if(!_loc2_)
         {
            return false;
         }
         if(_loc2_ is FighterMain)
         {
            if((_loc2_ as FighterMain).actionState == 21)
            {
               return false;
            }
         }
         var _loc3_:Rectangle = _loc2_.getBodyArea();
         var _loc4_:Rectangle = this._fighter.getBodyArea();
         if(!_loc3_ || !_loc4_)
         {
            return false;
         }
         var _loc5_:Number = Math.abs(this._fighter.y - _loc2_.y);
         if(_loc4_.x < _loc3_.x)
         {
            if(this._fighter.direct < 0)
            {
               return false;
            }
            _loc1_ = _loc3_.x - (_loc4_.x + _loc4_.width);
         }
         else
         {
            if(this._fighter.direct > 0)
            {
               return false;
            }
            _loc1_ = _loc4_.x - (_loc3_.x + _loc3_.width);
         }
         return _loc1_ < 2 && _loc5_ < 1;
      }
      
      private function doHurtDownJump() : void
      {
         if(this._doingAction == "起身")
         {
            return;
         }
         if(this._fighter.currentHurtDamage() > 240)
         {
            return;
         }
         if(!this._fighter.hasEnergy(30))
         {
            return;
         }
         this._mc.stopHurtFly();
         this._fighter.useEnergy(30);
         var _loc1_:Number = Number(this._fighter.getVecX());
         this.doAction("起身");
         this._fighter.isAllowBeHit = false;
         this._fighter.setVelocity(_loc1_);
         this._fighter.setDamping(_loc1_ * 0.1);
         FighterEventDispatcher.dispatchEvent(this._fighter,"HURT_RESUME");
      }
      
      public function sayIntro() : void
      {
         if(this._mc.checkFrame("开场"))
         {
            this._fighter.actionState = 60;
            this._mc.goFrame("开场");
         }
         else
         {
            this.idle();
         }
      }
      
      public function doWin() : void
      {
         if(this._mc.checkFrame("胜利"))
         {
            this._fighter.actionState = 61;
            this._mc.goFrame("胜利");
         }
         else
         {
            this.idle();
         }
      }
      
      public function doLose() : void
      {
         if(this._mc.checkFrame("失败"))
         {
            this._fighter.actionState = 62;
            this._mc.goFrame("失败");
         }
         else
         {
            this.idle();
         }
      }
      
      private function doGhostStep() : void
      {
         if(this.startGhostStep())
         {
            this.move(8,0);
            this._mc.goFrame("走",true);
            this._ghostType = 0;
         }
      }
      
      private function doGhostJump() : void
      {
         if(this.startGhostStep())
         {
            this.move(0,-12);
            this.damping(0,0.1);
            this._mc.goFrame("跳",false);
            --this._action.jumpTimes;
            this._ghostType = 1;
         }
      }
      
      private function doGhostJumpDown() : void
      {
         if(this.startGhostStep())
         {
            this.move(0,15);
            this._mc.goFrame("落",false);
            this._ghostType = 2;
         }
      }
      
      private function startGhostStep() : Boolean
      {
         if(this._fighter.qi < 60)
         {
            return false;
         }
         if(!this._fighter.hasEnergy(80,true))
         {
            return false;
         }
         this._fighter.useQi(60);
         this._fighter.useEnergy(80);
         this._fighter.getCtrler().setDirectToTarget();
         this._ghostStepIng = true;
         this._ghostStepFrame = 30 * 0.4;
         this._fighter.isAllowBeHit = false;
         this._fighter.isCross = true;
         this.effectCtrler.ghostStep();
         return true;
      }
      
      private function renderGhostStep() : void
      {
         var _loc1_:Number = NaN;
         if(this._ghostStepFrame-- <= 0)
         {
            if(this._ghostType == 1)
            {
               _loc1_ = Number(this._fighter.getVecY());
               this._action.isJumping = false;
               this.endGhostStep();
               this._fighter.setVelocity(0,_loc1_);
               this._fighter.setDamping(0,-_loc1_ / 10);
               this.setAirMove(true);
               return;
            }
            this.endGhostStep();
         }
         if(this._ghostType == 2)
         {
            if(GameLogic.isTouchBottomFloor(this._fighter))
            {
               this.endGhostStep();
            }
         }
      }
      
      private function endGhostStep() : void
      {
         this._ghostStepIng = false;
         this.effectCtrler.endGhostStep();
         this._fighter.getCtrler().setDirectToTarget();
         this.idle();
      }
   }
}

