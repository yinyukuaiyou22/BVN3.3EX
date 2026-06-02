package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.HitType;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.Bullet;
   import net.play5d.game.bvn.fighter.FighterAction;
   import net.play5d.game.bvn.fighter.FighterActionState;
   import net.play5d.game.bvn.fighter.FighterAttacker;
   import net.play5d.game.bvn.fighter.FighterComicType;
   import net.play5d.game.bvn.fighter.FighterMC;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.events.FighterEvent;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.fighter.vos.FlyParams;
   import net.play5d.game.bvn.fighter.vos.MoveTargetParamVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.kyo.utils.KyoUtils;
   
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
      
      private var _hurtHoldFrameMax:int = 0;
      
      private var _defenseHoldFrame:int = 0;
      
      private var _steelHoldFrame:int = 0;
      
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
      
      private var _justJumpDown:Boolean;
      
      private var _actionLogic:FighterActionLogic;
      
      public var beHitActions:Object = null;
      
      private var _hasBadAction:Boolean = false;
      
      private var _lastHurtActionTimes:uint = 0;
      
      private var _longGhostStepState:uint = 0;
      
      public var doActionTimes:uint = 1;
      
      private var _flyParam:FlyParams;
      
      private var _tempIsAirAction:Boolean = false;
      
      private var _hurtDownQuickUp:Boolean = true;
      
      private var _isCheckTargetIsAllowBeHit:Boolean;
      
      private var _isResponseTargetGameSprite:Boolean;
      
      private var _isMovingTarget:Boolean = false;
      
      private var touchFrameCount:int;
      
      public function FighterMcCtrler(param1:FighterMain)
      {
         super();
         _fighter = param1;
         _actionLogic = new FighterActionLogic(param1);
      }
      
      public function destory() : void
      {
         if(_actionCtrler)
         {
            _actionCtrler.destory();
            _actionCtrler = null;
         }
         if(_mc)
         {
            _mc.destory();
            _mc = null;
         }
         _fighter = null;
         _action = null;
         _moveTargetParam = null;
         effectCtrler = null;
      }
      
      public function getAction() : FighterAction
      {
         return _action;
      }
      
      public function getFighterMc() : FighterMC
      {
         return _mc;
      }
      
      public function getCurAction() : String
      {
         if(_doingAirAction != null)
         {
            return _doingAirAction;
         }
         return _doingAction;
      }
      
      public function getHurtHoldFrame() : int
      {
         return _hurtHoldFrame;
      }
      
      public function getHurtHoldFrameMax() : int
      {
         return _hurtHoldFrameMax;
      }
      
      public function getActionCtrler() : IFighterActionCtrl
      {
         return _actionCtrler;
      }
      
      public function setActionCtrler(param1:IFighterActionCtrl) : void
      {
         _actionCtrler = param1;
      }
      
      public function setNewActionLogic(param1:FighterMain) : void
      {
         _fighter = param1;
         _actionLogic = new FighterActionLogic(param1);
      }
      
      public function setMc(param1:FighterMC) : void
      {
         _mc = param1;
         idle();
      }
      
      public function initMc(param1:MovieClip) : FighterMC
      {
         if(_mc != null)
         {
            KyoUtils.setMcVolume(_mc.mc,GameData.I.config.soundVolume);
         }
         _mc = new FighterMC();
         _mc.initlize(param1,_fighter,this);
         idle();
         return _mc;
      }
      
      public function setSteelBody(param1:Boolean, param2:Boolean = false) : void
      {
         _fighter.isSteelBody = param1;
         _fighter.isSuperSteelBody = param1 && param2;
         if(param1)
         {
            effectCtrler.startGlow(param2 ? 16776960 : 16777215);
         }
         else
         {
            effectCtrler.endGlow();
         }
      }
      
      public function addQi(param1:Number) : void
      {
         _fighter.addQi(param1);
      }
      
      public function idle(param1:String = "站立") : void
      {
         var _loc2_:Boolean = false;
         if(!_fighter.isAlive)
         {
            return;
         }
         if(FighterActionState.isHurting(_fighter.actionState))
         {
            _justHurtResume = true;
         }
         _mc.stopHurtFly();
         endAct();
         if(_doingAirAction)
         {
            _tempIsAirAction = true;
         }
         _doingAction = null;
         _doingAirAction = null;
         setSteelBody(false);
         _justDefenseFrame = 0.1 * GameConfig.FPS_GAME;
         effectCtrler.endShadow();
         effectCtrler.endShake();
         _action.clear();
         _fighter.actionState = 0;
         _fighter.isAllowBeHit = !_justHurtResume;
         _beHitGap > 0 && (_fighter.isAllowBeHit = false);
         _fighter.isApplyG = true;
         _fighter.isAllowCrossFloor = false;
         _fighter.isCross = false;
         _fighter.clearHurtHits();
         _fighter.clearBeHurtHits();
         _fighter.getDisplay().visible = true;
         _isDefense = false;
         _autoDirectFrame = 0;
         if(!_isTouchFloor)
         {
            fall();
         }
         else
         {
            _loc2_ = true;
            _fighter.setVelocity(0,0);
            if(param1 == "站立")
            {
               _loc2_ = false;
               _action.jumpTimes = _fighter.jumpTimes;
               _action.airHitTimes = _fighter.airHitTimes;
               setAllAct();
            }
            _mc.goFrame(param1,_loc2_);
         }
         _justJumpDown = false;
         _tempIsAirAction = false;
         _hurtDownQuickUp = true;
         hurtActionClear();
         limitClear();
         FighterEventDispatcher.dispatchEvent(_fighter,"IDLE");
      }
      
      public function loop(param1:String) : void
      {
         _mc.goFrame(param1);
      }
      
      public function stop() : void
      {
         _mc.stopRenderMainAnimate();
      }
      
      public function dash(param1:Number = 3) : void
      {
         _action.isDashing = true;
         var _loc2_:Number = (_fighter.speed + _fighter.speedAdd) * param1;
         _fighter.setVelocity(_loc2_ * _fighter.direct,0);
         _fighter.setDamping(0,0);
         _fighter.isCross = true;
         _fighter.isAllowBeHit = false;
      }
      
      public function dashStop(param1:Number = 0.5) : void
      {
         var _loc2_:Number = _fighter.getVecX();
         if(FighterComicType.isFVO(_fighter.data.comicType) && _fighter.isInAir)
         {
            param1 *= 0.4;
         }
         var _loc3_:Number = Math.abs(_loc2_) * param1;
         _fighter.setDamping(_loc3_);
         _fighter.isAllowBeHit = true;
         _action.clearAction();
         _action.isDashing = false;
         _fighter.isCross = false;
      }
      
      public function setAllAct() : void
      {
         setMove();
         setDefense();
         setJump();
         setJumpDown();
         setDash();
         setAttack();
         setSkill1();
         setSkill2();
         setZhao1();
         setZhao2();
         setZhao3();
         setCatch1();
         setCatch2();
         setBisha();
         setBishaUP();
         setBishaSUPER();
         setWankai();
      }
      
      public function setAirAllAct() : void
      {
         setDash();
         setAttackAIR();
         setSkillAIR();
         setBishaAIR();
         setAirMove(true);
      }
      
      public function setAirMove(param1:Boolean) : void
      {
         _action.airMove = param1;
      }
      
      public function setMove() : void
      {
         setMoveLeft();
         setMoveRight();
      }
      
      public function setMoveLeft() : void
      {
         _action.moveLeft = "走";
      }
      
      public function setMoveRight() : void
      {
         _action.moveRight = "走";
      }
      
      public function setDefense() : void
      {
         _action.defense = "防御";
      }
      
      public function setJump(param1:String = "跳") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.jump = param1;
      }
      
      public function setJumpQuick(param1:String = "跳") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.jumpQuick = param1;
      }
      
      public function setJumpDown(param1:String = "落") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.jumpDown = param1;
      }
      
      public function setDash(param1:String = "瞬步") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.dash = param1;
      }
      
      public function setAttack(param1:String = "砍1") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.attack = param1;
      }
      
      public function setSkill1(param1:String = "砍技1") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.skill1 = param1;
      }
      
      public function setSkill2(param1:String = "砍技2") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.skill2 = param1;
      }
      
      public function setZhao1(param1:String = "招1") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.zhao1 = param1;
      }
      
      public function setZhao2(param1:String = "招2") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.zhao2 = param1;
      }
      
      public function setZhao3(param1:String = "招3") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.zhao3 = param1;
      }
      
      public function setCatch1(param1:String = "摔1") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.catch1 = param1;
      }
      
      public function setCatch2(param1:String = "摔2") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.catch2 = param1;
      }
      
      public function setSpecialSkill(param1:String = null) : void
      {
         if(_action.specialAssistAction == null)
         {
            return;
         }
         _action.specialSkill = _action.specialAssistAction;
         if(param1 != null)
         {
            if(!_mc.checkFrame(param1))
            {
               return;
            }
            _action.specialSkill = param1;
         }
      }
      
      public function setBisha(param1:String = "必杀", param2:int = 100) : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.bisha = param1;
         if(param2 != 100)
         {
            _action.bishaQi = param2;
         }
      }
      
      public function setBishaUP(param1:String = "上必杀", param2:int = 100) : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.bishaUP = param1;
         if(param2 != 100)
         {
            _action.bishaUPQi = param2;
         }
      }
      
      public function setBishaSUPER(param1:String = "超必杀", param2:int = 300) : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.bishaSUPER = param1;
         if(param2 != 300)
         {
            _action.bishaSUPERQi = param2;
         }
      }
      
      public function setAttackAIR(param1:String = "跳砍") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.attackAIR = param1;
      }
      
      public function setSkillAIR(param1:String = "跳招") : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.skillAIR = param1;
      }
      
      public function setBishaAIR(param1:String = "空中必杀", param2:int = 100) : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.bishaAIR = param1;
         if(param2 != 100)
         {
            _action.bishaAIRQi = param2;
         }
      }
      
      public function setTouchFloor(param1:String = "落地", param2:Boolean = true) : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.touchFloor = param1;
         _action.touchFloorBreakAct = param2;
      }
      
      public function setWankai() : void
      {
         if(_mc.checkFrame("万解"))
         {
            _action.waiKai = "万解";
         }
         if(_mc.checkFrame("万解W"))
         {
            _action.waiKaiW = "万解W";
         }
         if(_mc.checkFrame("万解S"))
         {
            _action.waiKaiS = "万解S";
         }
      }
      
      public function setHitTarget(param1:String, param2:String, param3:Boolean = true, param4:Boolean = false) : void
      {
         _action.hitTargetChecker = param1;
         _action.hitTarget = param2;
         _isCheckTargetIsAllowBeHit = param3;
         _isResponseTargetGameSprite = param4;
      }
      
      public function setHurtAction(param1:String) : void
      {
         _action.hurtAction = param1;
         _fighter.actionState = 16;
      }
      
      public function setTouchSide(param1:String) : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         _action.touchSide = param1;
      }
      
      public function move(param1:Number = 0, param2:Number = 0) : void
      {
         if(param1 == 0 && param2 == 0)
         {
            stopMove();
            return;
         }
         if(param1 != 0)
         {
            _action.airMove = false;
         }
         param1 *= _fighter.direct;
         _fighter.setVelocity(param1,param2);
      }
      
      public function movePercent(param1:Number = 0, param2:Number = 0) : void
      {
         move((_fighter.speed + _fighter.speedAdd) * param1,(_fighter.speed + _fighter.speedAdd) * param2);
      }
      
      public function stopMove() : void
      {
         _fighter.setVelocity(0,0);
      }
      
      public function damping(param1:Number = 0, param2:Number = 0) : void
      {
         _fighter.setDamping(param1,param2);
      }
      
      public function dampingPercent(param1:Number = 0, param2:Number = 0) : void
      {
         _fighter.setDamping((_fighter.speed + _fighter.speedAdd) * param1,(_fighter.speed + _fighter.speedAdd) * param2);
      }
      
      public function endAct() : void
      {
         _action.clearAction();
         _fighter.actionState = 40;
         _moveTargetParam = null;
         setSteelBody(false);
      }
      
      public function fire(param1:String, param2:Object = null) : void
      {
         var mcName:String = param1;
         var params:Object = param2;
         var mc:MovieClip = _mc.getChildByName(mcName) as MovieClip;
         if(mc)
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            params.hitVO = _fighter.getCtrler().hitModel.getHitVOByDisplayName(mcName);
            FighterEventDispatcher.dispatchEvent(_fighter,"FIRE_BULLET",params);
         }
         else
         {
            _fighter.setAnimateFrameOut(function():void
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
         var mc:MovieClip = _mc.getChildByName(mcName) as MovieClip;
         if(mc)
         {
            if(!params)
            {
               params = {};
            }
            params.mc = mc;
            params.hitVO = _fighter.getCtrler().hitModel.getHitVOByDisplayName(mcName);
            FighterEventDispatcher.dispatchEvent(_fighter,"ADD_ATTACKER",params);
         }
         else if(!again)
         {
            _fighter.setAnimateFrameOut(function():void
            {
               addAttacker(mcName,params,true);
            },1);
         }
      }
      
      public function isApplyG(param1:Boolean) : void
      {
         _fighter.isApplyG = param1;
      }
      
      public function isAllowCrossFloor(param1:Boolean) : void
      {
         _fighter.isAllowCrossFloor = param1;
      }
      
      public function setFly(param1:Boolean, param2:Object = null) : void
      {
         _action.isFlying = param1;
         _fighter.isApplyG = false;
         if(param1)
         {
            if(param2 && param2.hold)
            {
               param2.holdFrame = param2.hold * GameConfig.FPS_GAME;
            }
            _flyParam = new FlyParams(param2);
            if(_flyParam.lrSpd <= 0)
            {
               _flyParam.lrSpd = _fighter.speed;
            }
            if(_flyParam.upSpd <= 0)
            {
               _flyParam.upSpd = _fighter.speed;
            }
            if(_flyParam.downSpd <= 0)
            {
               _flyParam.downSpd = _fighter.speed;
            }
            if(_flyParam.holdFrame <= 0)
            {
               _flyParam.holdFrame = 5 * GameConfig.FPS_GAME;
            }
         }
      }
      
      public function gotoAndPlay(param1:String) : void
      {
         _mc.goFrame(param1,true);
      }
      
      public function gotoAndStop(param1:String) : void
      {
         _mc.goFrame(param1,false);
      }
      
      public function hurtFly(param1:Number, param2:Number) : void
      {
         _mc.playHurtFly(param1 * _fighter.direct,param2,false);
         _action.isHurtFlying = true;
         _fighter.actionState = 22;
         _hurtDownQuickUp = false;
         _hurtDownFrame = 0;
         _isFalling = false;
      }
      
      public function moveMC(param1:DisplayObject, param2:Object = null, param3:Object = null) : void
      {
         var _loc4_:IGameSprite = _fighter.getCurrentTarget();
         if(param2)
         {
            if(param2 is Number)
            {
               param1.x = _fighter.x + param2;
            }
            else if(param2.target != undefined && _loc4_)
            {
               param1.x = _loc4_.x - _fighter.x;
               if(isNaN(Number(param2.target)))
               {
                  param1.x += Number(param2.target);
               }
            }
         }
         if(param3)
         {
            if(param3 is Number)
            {
               param1.y = _fighter.y + param3;
            }
            else if(param3.target != undefined && _loc4_)
            {
               param1.y = _loc4_.y - _fighter.y + Number(param3);
               if(isNaN(Number(param3.target)))
               {
                  param1.y += Number(param3.target);
               }
            }
         }
      }
      
      public function justHitToPlay(param1:String, param2:String, param3:Boolean = false, param4:Boolean = false) : void
      {
         if(_fighter.getCtrler().justHit(param1,param4))
         {
            _mc.goFrame(param2);
         }
         else if(param3)
         {
            idle();
         }
      }
      
      public function getAttacker(param1:String) : FighterAttackerCtrler
      {
         var _loc2_:FighterAttacker = GameCtrl.I.getAttacker(param1,_fighter.team.id);
         if(_loc2_)
         {
            return _loc2_.getCtrler();
         }
         return null;
      }
      
      public function getAssister() : AssisiterCtrler
      {
         var _loc1_:Assister = GameCtrl.I.getAssister(_fighter.team.id);
         if(_loc1_ != null)
         {
            return _loc1_.getCtrler();
         }
         return null;
      }
      
      public function getAssisterGlobal() : Assister
      {
         var _loc1_:GameRunDataVO = GameCtrl.I.gameRunData;
         if(_fighter.team.name == "P1")
         {
            return _loc1_.p1FighterGroup.currentAssister;
         }
         if(_fighter.team.name == "P2")
         {
            return _loc1_.p2FighterGroup.currentAssister;
         }
         return null;
      }
      
      public function setSpecialAssist(param1:Object = null) : Boolean
      {
         if(param1 == null)
         {
            return false;
         }
         var _loc6_:String = param1.id != undefined ? param1.id : null;
         var _loc3_:Function = param1.back != undefined ? param1.back : null;
         var _loc7_:Boolean = Boolean(param1.enabled != undefined ? param1.enabled : false);
         var _loc2_:Boolean = Boolean(param1.useFzqi != undefined ? param1.useFzqi : true);
         var _loc4_:* = param1.action != undefined ? param1.action : null;
         var _loc5_:Assister = getAssisterGlobal() as Assister;
         if(_loc5_ == null)
         {
            return false;
         }
         if(_loc6_ != null && _loc6_ != _loc5_.data.id)
         {
            return false;
         }
         if(_loc3_ != null && !_loc3_())
         {
            _loc5_.getCtrler().enabled = true;
            _loc5_.getCtrler().useFzqi = true;
            getAction().specialAssistAction = null;
            return false;
         }
         _loc5_.getCtrler().enabled = _loc7_;
         _loc5_.getCtrler().useFzqi = _loc2_;
         getAction().specialAssistAction = _loc4_;
         return true;
      }
      
      public function setSpecialHurtBreak(param1:Object = null) : Boolean
      {
         if(param1 == null)
         {
            return false;
         }
         getAction().specialHurtBreak = param1;
         return true;
      }
      
      public function moveTarget(param1:Object = null) : void
      {
         if(param1 == null && _moveTargetParam != null)
         {
            _moveTargetParam.clear();
            _moveTargetParam = null;
            return;
         }
         _moveTargetParam = new MoveTargetParamVO(param1);
         _moveTargetParam.setTarget(_fighter.getCurrentTarget());
      }
      
      public function unHoldAttack(param1:String = null) : void
      {
         if(param1 == null)
         {
            _action.unHolding = null;
            _action.unHoldingChecker = null;
            return;
         }
         _action.unHolding = param1;
         _action.unHoldingChecker = _actionCtrler.holdAttack;
      }
      
      public function unHoldSkill(param1:String = null) : void
      {
         if(param1 == null)
         {
            _action.unHolding = null;
            _action.unHoldingChecker = null;
            return;
         }
         _action.unHolding = param1;
         _action.unHoldingChecker = _actionCtrler.holdSkill;
      }
      
      public function unHoldBisha(param1:String = null) : void
      {
         if(param1 == null)
         {
            _action.unHolding = null;
            _action.unHoldingChecker = null;
            return;
         }
         _action.unHolding = param1;
         _action.unHoldingChecker = _actionCtrler.holdBisha;
      }
      
      public function render() : void
      {
         if(_ghostStepIng)
         {
            return;
         }
         if(_justDefenseFrame > 0)
         {
            _justDefenseFrame = _justDefenseFrame - 1;
         }
         if(_moveTargetParam != null)
         {
            renderMoveTarget();
         }
         if(_actionCtrler)
         {
            _actionCtrler.render();
         }
         if(_action.isJumping)
         {
            renderJump();
         }
         if(_action.isHurtFlying)
         {
            renderHurtFlying();
            return;
         }
         if(_action.isHurting)
         {
            renderHurt();
            return;
         }
         if(_action.isDefenseHiting)
         {
            renderDefense(false,true);
            return;
         }
         if(_action.hitTarget)
         {
            renderCheckTargetHit();
         }
         if(_action.unHolding)
         {
            renderUnHolding();
         }
         if(renderWanKaiCtrl())
         {
            return;
         }
         if(_fighter && _fighter.isInAir || _doingAirAction && !_action.touchFloorBreakAct)
         {
            renderAirAction();
         }
         else
         {
            renderFloorAction();
         }
      }
      
      private function renderHurtFlying() : void
      {
         if(!_fighter.isInAir)
         {
            _isTouchFloor = true;
         }
         if(!_fighter.isAlive)
         {
            return;
         }
         if(_fighter.actionState == 24)
         {
            _hurtDownFrame = 1;
         }
         if(_hurtDownFrame > 0)
         {
            if(!_actionLogic || !_actionLogic.enabled())
            {
               return;
            }
            if(++_hurtDownFrame < 20)
            {
               if(_actionLogic.hurtFlyResume())
               {
                  doHurtDownJump();
                  _hurtDownFrame = 0;
               }
            }
         }
      }
      
      private function renderSpecial() : void
      {
         var _loc1_:Assister = null;
         if(_actionLogic.assist())
         {
            if(_action.specialSkill != null)
            {
               _loc1_ = getAssisterGlobal() as Assister;
               if(_loc1_ == null)
               {
                  return;
               }
               if(_loc1_.getCtrler().useFzqi)
               {
                  if(_fighter.fzqi < 100)
                  {
                     return;
                  }
                  _fighter.fzqi = 0;
               }
               doActionFlexible(_action.specialSkill);
               return;
            }
            FighterEventDispatcher.dispatchEvent(_fighter,"DO_SPECIAL");
         }
      }
      
      private function renderFloorAction() : void
      {
         if(!_fighter.isAlive)
         {
            return;
         }
         if(!_isTouchFloor)
         {
            if(_fighter.actionState == 0)
            {
               _isTouchFloor = true;
               _isFalling = false;
               idle();
            }
            else
            {
               touchFloor();
            }
         }
         else if(_action.touchFloor != null && _action.touchFloor != "落地")
         {
            touchFloor();
         }
         touchSide();
         if(_actionLogic == null || !_actionLogic.enabled())
         {
            if(_mc.currentFrameName == "走" || _mc.currentFrameName == "防御")
            {
               idle();
            }
            return;
         }
         renderSpecial();
         var _loc1_:Boolean = false;
         if(_actionLogic.moveLEFT() && _fighter.direct > 0)
         {
            doMove(_action.moveLeft,-1);
            _loc1_ = true;
         }
         if(_actionLogic.moveRIGHT() && _fighter.direct < 0)
         {
            doMove(_action.moveRight,1);
            _loc1_ = true;
         }
         if(_loc1_)
         {
            if(_action.isMoving)
            {
               renderMoving();
            }
            if(_actionLogic.jumpDown())
            {
               doJumpDown(_action.jumpDown);
            }
            if(_actionLogic.defense() && !_actionLogic.jump())
            {
               doDefense();
            }
            if(_actionLogic.dash() && !_actionLogic.jump())
            {
               doDash(_action.dash);
            }
            if(_action.isDefensing)
            {
               renderDefense();
            }
            if(_actionLogic.ghostStep())
            {
               doGhostStep();
            }
            if(_actionLogic.ghostJump())
            {
               doGhostJump();
            }
            return;
         }
         if(_actionLogic.jumpDown())
         {
            doJumpDown(_action.jumpDown);
         }
         if(_actionLogic.jump())
         {
            doJump(_action.jump);
         }
         if(_actionLogic.catch1())
         {
            doCatch(_action.catch1);
         }
         if(_actionLogic.catch2())
         {
            doCatch(_action.catch2);
         }
         if(_actionLogic.bishaSUPER())
         {
            doBisha(_action.bishaSUPER,_action.bishaSUPERQi,true);
         }
         if(_actionLogic.bishaUP())
         {
            doBisha(_action.bishaUP,_action.bishaUPQi);
         }
         if(_actionLogic.bisha())
         {
            doBisha(_action.bisha,_action.bishaQi);
         }
         if(_actionLogic.skill2())
         {
            doSkill(_action.skill2);
         }
         if(_actionLogic.skill1())
         {
            doSkill(_action.skill1);
         }
         if(_actionLogic.zhao3())
         {
            doSkill(_action.zhao3);
         }
         if(_actionLogic.zhao2())
         {
            doSkill(_action.zhao2);
         }
         if(_actionLogic.attack())
         {
            doAttack(_action.attack);
         }
         if(_actionLogic.zhao1())
         {
            doSkill(_action.zhao1);
         }
         if(_actionLogic.defense())
         {
            doDefense();
         }
         if(_actionLogic.dash())
         {
            doDash(_action.dash);
         }
         if(_actionLogic.moveLEFT())
         {
            doMove(_action.moveLeft,-1);
         }
         if(_actionLogic.moveRIGHT())
         {
            doMove(_action.moveRight,1);
         }
         if(_action.isMoving)
         {
            renderMoving();
         }
         if(_action.isDefensing)
         {
            renderDefense();
         }
         if(_actionLogic.ghostStep())
         {
            doGhostStep();
         }
         if(_actionLogic.ghostJump())
         {
            doGhostJump();
         }
         if(FighterActionState.isAttacking(_fighter.actionState))
         {
            if(_actionLogic.attackAIR())
            {
               doAirAttack(_action.attackAIR);
            }
            if(_actionLogic.skillAIR())
            {
               doAirSkill(_action.skillAIR);
            }
            if(_actionLogic.bishaAIR())
            {
               doAirBisha(_action.bishaAIR,_action.bishaAIRQi);
            }
         }
      }
      
      private function renderWanKaiCtrl() : Boolean
      {
         if(!_actionLogic || !_actionLogic.enabled())
         {
            return false;
         }
         if(_actionLogic.waiKai())
         {
            return checkDoWankai(_action.waiKai,"万解");
         }
         if(_actionLogic.waiKaiW())
         {
            return checkDoWankai(_action.waiKaiW,"万解W");
         }
         if(_actionLogic.waiKaiS())
         {
            return checkDoWankai(_action.waiKaiS,"万解S");
         }
         return false;
      }
      
      private function checkDoWankai(param1:String, param2:String) : Boolean
      {
         if(param1)
         {
            doWaiKaiAction(param1);
            return true;
         }
         if(_mc.currentFrameName == "防御")
         {
            doWaiKaiAction(param2);
            return true;
         }
         if(_doingAction == "砍1")
         {
            if(_doActionFrame < 2)
            {
               doWaiKaiAction(param2);
               return true;
            }
         }
         return false;
      }
      
      public function renderAnimate() : void
      {
         if(_justHurtResume)
         {
            _fighter.isAllowBeHit = true;
            _justHurtResume = false;
         }
         renderBeHitGap();
         if(_mc)
         {
            _mc.renderAnimate();
         }
         if(_actionCtrler)
         {
            _actionCtrler.renderAnimate();
         }
         if(_ghostStepIng)
         {
            renderGhostStep();
            return;
         }
         if(_action)
         {
            _action.renderAnimate();
            if(_action.isHurting)
            {
               renderHurtAnimate();
            }
            if(_action.isDefenseHiting)
            {
               renderDefensHiting();
            }
            if(_action.isSteelHiting)
            {
               renderSteelHiting();
            }
            if(_action.isJumping)
            {
               renderJumpAnimate();
            }
            if(_doingAction)
            {
               _doActionFrame = _doActionFrame + 1;
            }
            if(_action.isDefensing)
            {
               renderDefenseAnimate();
            }
         }
         if(GameData.I.config.isAutoDirect)
         {
            if(_mc && _mc.currentFrameName == "站立")
            {
               if(++_autoDirectFrame > 5)
               {
                  _fighter.getCtrler().setDirectToTarget();
                  _autoDirectFrame = 0;
               }
            }
         }
      }
      
      private function renderAirAction() : void
      {
         if(!_fighter.isAlive)
         {
            return;
         }
         if(!_action.isJumping)
         {
            fall();
         }
         _isTouchFloor = false;
         if(_actionLogic == null || !_actionLogic.enabled())
         {
            return;
         }
         if(_actionLogic.jump())
         {
            doAirJump(_action.jump);
         }
         if(_actionLogic.jumpQuick())
         {
            doAirJump(_action.jumpQuick);
         }
         if(_actionLogic.attackAIR())
         {
            doAirAttack(_action.attackAIR);
         }
         if(_actionLogic.skillAIR())
         {
            doAirSkill(_action.skillAIR);
         }
         if(_actionLogic.bishaAIR())
         {
            doAirBisha(_action.bishaAIR,_action.bishaAIRQi);
         }
         if(FighterActionState.isAttacking(_fighter.actionState))
         {
            if(_actionLogic.bishaSUPER())
            {
               doBisha(_action.bishaSUPER,_action.bishaSUPERQi,true);
            }
            if(_actionLogic.bishaUP())
            {
               doBisha(_action.bishaUP,_action.bishaUPQi);
            }
            if(_actionLogic.bisha())
            {
               doBisha(_action.bisha,_action.bishaQi);
            }
            if(_actionLogic.skill2())
            {
               doSkill(_action.skill2);
            }
            if(_actionLogic.skill1())
            {
               doSkill(_action.skill1);
            }
            if(_actionLogic.zhao3())
            {
               doSkill(_action.zhao3);
            }
            if(_actionLogic.zhao2())
            {
               doSkill(_action.zhao2);
            }
            if(_actionLogic.attack())
            {
               doAttack(_action.attack);
            }
            if(_actionLogic.zhao1())
            {
               doSkill(_action.zhao1);
            }
         }
         if(_actionLogic.dash())
         {
            doDashAir(_action.dash);
         }
         if(_action.isFlying)
         {
            doFly();
         }
         else if(_actionLogic.airMove())
         {
            doAirMove();
         }
         if(_actionLogic.ghostJump())
         {
            doGhostJump();
         }
         if(_actionLogic.ghostJumpDown())
         {
            doGhostJumpDown();
         }
      }
      
      private function renderMoveTarget() : void
      {
         var _loc3_:DisplayObject = null;
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc4_:IGameSprite = _moveTargetParam.target;
         if(_loc4_ == null)
         {
            return;
         }
         if(_moveTargetParam.followMcName)
         {
            _loc3_ = _mc.getChildByName(_moveTargetParam.followMcName);
            if(_loc3_ == null)
            {
               if(_isMovingTarget)
               {
                  _moveTargetParam.clear();
               }
               _isMovingTarget = false;
               return;
            }
            _isMovingTarget = true;
            _loc1_ = _fighter.x + _loc3_.x * _fighter.direct;
            _loc2_ = _fighter.y + _loc3_.y;
         }
         else
         {
            if(!isNaN(_moveTargetParam.x))
            {
               _loc1_ = _moveTargetParam.x;
            }
            if(!isNaN(_moveTargetParam.y))
            {
               _loc2_ = _moveTargetParam.y;
            }
         }
         if(_moveTargetParam.speed)
         {
            if(_moveTargetParam.speed.x > 0 && !isNaN(_loc1_))
            {
               if(_loc4_.x > _loc1_ + _moveTargetParam.speed.x)
               {
                  _loc4_.x -= _moveTargetParam.speed.x;
               }
               if(_loc4_.x < _loc1_ - _moveTargetParam.speed.x)
               {
                  _loc4_.x += _moveTargetParam.speed.x;
               }
               if(_loc4_.y > _loc2_ + _moveTargetParam.speed.y)
               {
                  if(_loc4_ is BaseGameSprite)
                  {
                     (_loc4_ as BaseGameSprite).setVecY(-_moveTargetParam.speed.y);
                     (_loc4_ as BaseGameSprite).setDampingY(1);
                  }
                  else
                  {
                     _loc4_.y -= _moveTargetParam.speed.y;
                  }
               }
               if(_loc4_.y < _loc2_ - _moveTargetParam.speed.y)
               {
                  if(_loc4_ is BaseGameSprite)
                  {
                     (_loc4_ as BaseGameSprite).setVecY(_moveTargetParam.speed.y);
                     (_loc4_ as BaseGameSprite).setDampingY(1);
                  }
                  else
                  {
                     _loc4_.y += _moveTargetParam.speed.y;
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
         if(_isFalling && _fighter.actionState != 50)
         {
            if(_fighter.isInAir)
            {
               _mc.goFrame("落",false);
               _fighter.actionState = 14;
               return;
            }
            return;
         }
         if(_doingAction)
         {
            return;
         }
         _action.clearState();
         _action.clearAction();
         if(_fighter.replaceSkillFrame == 0)
         {
            setAirAllAct();
            setJump();
         }
         _isFalling = true;
         _doingAirAction = null;
         _isTouchFloor = false;
         _isDefense = false;
         _fighter.setVecX(0);
         setTouchFloor("落地",true);
         if(_fighter.actionState != 0 || _fighter.isInAir || _tempIsAirAction)
         {
            _mc.goFrame("落",false);
            _fighter.actionState = 14;
         }
         else
         {
            idle();
         }
      }
      
      public function touchFloor() : void
      {
         if(!_fighter.isAlive)
         {
            return;
         }
         var _loc1_:String = _action.touchFloor;
         if(_isFalling)
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
            "call":setAttack,
            "delay":1
         } : null;
         doAction(_loc1_,false,_loc2_);
         GameLogic.fixGameSpritePosition(_fighter);
         effectCtrler.touchFloor();
         _action.airHitTimes = _fighter.airHitTimes;
         _action.jumpTimes = _fighter.jumpTimes;
         _isTouchFloor = true;
         _isFalling = false;
         _flyParam = null;
         _justJumpDown = false;
      }
      
      private function touchFrameCheck() : void
      {
         if(_mc.currentFrameName != "落地")
         {
            _fighter.removeRenderFunc(touchFrameCheck);
            touchFrameCount = 0;
            return;
         }
         if(touchFrameCount < _mc.getCurrentFrameCount())
         {
            touchFrameCount = _mc.getCurrentFrameCount();
         }
      }
      
      public function touchSide() : void
      {
         if(!_fighter.isAlive)
         {
            return;
         }
         if(_action.touchSide == null)
         {
            return;
         }
         if(_mc.checkFrame(_action.touchSide) && _fighter.getIsTouchSide())
         {
            doAction(_action.touchSide);
            _action.touchSide = null;
         }
      }
      
      private function doAction(param1:String, param2:Boolean = false, param3:Object = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         effectCtrler.endShadow();
         effectCtrler.endShake();
         _fighter.setVelocity(0,0);
         _action.isMoving = false;
         _action.isDefensing = false;
         _action.isDashing = false;
         _doingAction = param1;
         _doingAirAction = param2 ? param1 : null;
         _action.clearAction();
         _isFalling = false;
         _isDefense = false;
         _fighter.isAllowBeHit = true;
         _fighter.isCross = false;
         _fighter.isApplyG = true;
         _fighter.isAllowCrossFloor = false;
         _doActionFrame = 0;
         doActionTimes = doActionTimes + 1;
         _mc.goFrame(param1,true,0,param3);
         _fighter.dispatchEvent(new FighterEvent("DO_ACTION"));
      }
      
      public function doActionFlexible(param1:*, param2:int = -1) : void
      {
         if(param1 != null)
         {
            if(param2 != -1)
            {
               _fighter.actionState = param2;
            }
            if(param1 is String)
            {
               _action.clear();
               doAction(param1);
            }
            if(param1 is Function)
            {
               param1();
            }
         }
      }
      
      private function setMoveAction() : void
      {
         _action.clearAction();
         _action.isMoving = true;
         setMove();
         setAttack();
         setZhao1();
         setZhao3();
         setSkill2();
         setJump();
         setJumpDown();
         setDash();
         setBisha();
         setBishaUP();
         setDefense();
         setCatch1();
         setCatch2();
      }
      
      private function renderMoving() : void
      {
         if(_actionCtrler.moveLEFT())
         {
            _fighter.direct = -1;
            move(_fighter.speed + _fighter.speedAdd);
         }
         else if(_actionCtrler.moveRIGHT())
         {
            _fighter.direct = 1;
            move(_fighter.speed + _fighter.speedAdd);
         }
         else
         {
            idle();
         }
      }
      
      private function doMove(param1:String, param2:int = 1) : void
      {
         if(_action.isMoving)
         {
            return;
         }
         _mc.goFrame(param1,true);
         _fighter.actionState = 0;
         setMoveAction();
      }
      
      private function doAirMove() : void
      {
         if(_actionCtrler.moveLEFT())
         {
            _fighter.move(-(_fighter.speed + _fighter.speedAdd));
         }
         if(_actionCtrler.moveRIGHT())
         {
            _fighter.move(_fighter.speed + _fighter.speedAdd);
         }
      }
      
      private function doFly() : void
      {
         if(!_flyParam)
         {
            return;
         }
         if(--_flyParam.holdFrame <= 0)
         {
            if(_flyParam.endAction)
            {
               gotoAndPlay(_flyParam.endAction);
            }
            else
            {
               idle();
            }
            _action.isFlying = false;
            _flyParam = null;
            return;
         }
         var _loc1_:Number = 0;
         var _loc2_:Number = 0;
         if(_actionCtrler.moveLEFT())
         {
            _loc1_ = -_flyParam.lrSpd;
         }
         if(_actionCtrler.moveRIGHT())
         {
            _loc1_ = _flyParam.lrSpd;
         }
         if(_actionCtrler.moveUP())
         {
            _loc2_ = -_flyParam.upSpd;
         }
         if(_actionCtrler.moveDOWN())
         {
            _loc2_ = _flyParam.downSpd;
         }
         _fighter.move(_loc1_,_loc2_);
      }
      
      private function renderDefense(param1:Boolean = true, param2:Boolean = false) : void
      {
         if(_actionCtrler.moveLEFT())
         {
            if(_fighter.direct != -1)
            {
               _fighter.direct = -1;
               setDefenseAction(param1,param2);
            }
         }
         if(_actionCtrler.moveRIGHT())
         {
            if(_fighter.direct != 1)
            {
               _fighter.direct = 1;
               setDefenseAction(param1,param2);
            }
         }
      }
      
      private function renderDefenseAnimate() : void
      {
         if(_action.isDefenseHiting)
         {
            return;
         }
         if(_defenseFrameDelay-- > 0)
         {
            return;
         }
         if(_actionCtrler.enabled() && _actionCtrler.defense())
         {
            if(!_isDefense)
            {
               _isDefense = true;
            }
         }
         else
         {
            if(_defenseFrameDelay > -5)
            {
               return;
            }
            _action.isDefensing = false;
            _isDefense = false;
            _mc.goFrame("防御恢复",false,0,{
               "call":idle,
               "delay":1
            });
         }
      }
      
      private function setDefenseAction(param1:Boolean = true, param2:Boolean = false) : void
      {
         if(param1)
         {
            _action.clearAction();
            _action.clearState();
            _action.isDefensing = true;
            setSkill1();
            setZhao2();
            setBishaSUPER();
            setJumpDown();
         }
         if(param2)
         {
            _isDefense = true;
         }
         else
         {
            _isDefense = _justDefenseFrame > 0;
         }
         _defenseFrameDelay = 1;
         _mc.goFrame("防御",true,3);
         FighterEventDispatcher.dispatchEvent(_fighter,"DEFENSE");
      }
      
      private function doDefense() : void
      {
         if(_action.isDefensing)
         {
            return;
         }
         _fighter.actionState = 20;
         dampingPercent(1,1);
         setDefenseAction();
      }
      
      private function doDash(param1:String) : void
      {
         if(!_fighter.hasEnergy(20,true))
         {
            return;
         }
         _fighter.useEnergy(20);
         if(_actionCtrler.moveLEFT())
         {
            _fighter.direct = -1;
         }
         if(_actionCtrler.moveRIGHT())
         {
            _fighter.direct = 1;
         }
         doAction(param1);
         _fighter.actionState = 15;
         _fighter.isAllowBeHit = false;
         isApplyG(false);
         isAllowCrossFloor(false);
      }
      
      private function doDashAir(param1:String) : void
      {
         if(_action.jumpTimes < 1 && !_justJumpDown)
         {
            return;
         }
         if(!_fighter.hasEnergy(30,true))
         {
            return;
         }
         _justJumpDown = false;
         _fighter.useEnergy(30);
         doAction(param1);
         _fighter.actionState = 15;
         _fighter.isAllowBeHit = false;
         isApplyG(false);
         isAllowCrossFloor(false);
         _action.jumpTimes = 0;
      }
      
      private function doJump(param1:String) : void
      {
         if(_action.jumpTimes <= 0)
         {
            return;
         }
         _action.clearAction();
         _action.clearState();
         _doingAction = null;
         _doingAirAction = null;
         _mc.goFrame("起跳",false);
         _jumpDelayFrame = 2;
         _action.isJumping = true;
         _fighter.actionState = 14;
      }
      
      private function doJumpDown(param1:String) : void
      {
         if(_fighter.isTouchBottom)
         {
            return;
         }
         _action.clear();
         _action.jumpTimes = 0;
         _fighter.setVecY(12);
         _fighter.setDamping(0,1);
         _fighter.y += 12;
         _isDefense = false;
         _justJumpDown = true;
         _mc.goFrame(param1,false);
         setTouchFloor();
      }
      
      private function doAirJump(param1:String) : void
      {
         if(_action.jumpTimes <= 0)
         {
            return;
         }
         _action.clearAction();
         _action.clearState();
         _doingAction = null;
         _doingAirAction = null;
         _jumpDelayFrame = 1;
         _action.isJumping = true;
         _fighter.actionState = 14;
      }
      
      public function renderJumpAnimate() : void
      {
         if(_doingAction)
         {
            return;
         }
         if(_jumpDelayFrame > 0)
         {
            _jumpDelayFrame = _jumpDelayFrame - 1;
            if(_jumpDelayFrame == 0)
            {
               _isFalling = false;
               _action.jumpTimes--;
               _mc.goFrame("跳",false);
               _fighter.jump();
               if(_fighter.isInAir)
               {
                  effectCtrler.jumpAir();
               }
               else
               {
                  effectCtrler.jump();
               }
            }
            return;
         }
         if(_mc.getCurrentFrameCount() == 2)
         {
            setJumpQuick();
         }
         var _loc1_:Number = _fighter.getVecY();
         if(_mc.currentFrameName == "跳中")
         {
            if(_mc.getCurrentFrameCount() >= 4)
            {
               setJump();
            }
         }
         else if(_loc1_ > -_fighter.jumpPower * 0.35)
         {
            _mc.goFrame("跳中",false);
         }
         if(_loc1_ >= 0)
         {
            _action.isJumping = false;
            _isFalling = true;
         }
      }
      
      public function renderJump() : void
      {
         if(_doingAction)
         {
            return;
         }
         if(_mc.currentFrameName == "跳" && _fighter.isInAir && _fighter.y < GameCtrl.I.gameState.getMap().playerBottom - 12)
         {
            setAirAllAct();
         }
      }
      
      private function doAttack(param1:String) : void
      {
         doAction(param1);
         _fighter.actionState = 10;
      }
      
      private function doSkill(param1:String) : void
      {
         doAction(param1);
         _fighter.actionState = 11;
      }
      
      private function doCatch(param1:String) : void
      {
         if(!allowCatch())
         {
            return;
         }
         doAction(param1);
         _fighter.actionState = 11;
      }
      
      private function doBisha(param1:String, param2:int, param3:Boolean = false) : void
      {
         if(!_fighter.useQi(param2))
         {
            return;
         }
         _fighter.actionState = param3 ? 13 : 12;
         doAction(param1);
      }
      
      private function doWaiKaiAction(param1:String) : void
      {
         if(!_mc.checkFrame(param1))
         {
            return;
         }
         if(!_fighter.useQi(300))
         {
            return;
         }
         _fighter.actionState = 50;
         doAction(param1);
         _fighter.isAllowBeHit = false;
      }
      
      private function doAirAttack(param1:String) : void
      {
         if(_doingAction == null && _action.airHitTimes <= 0)
         {
            return;
         }
         _fighter.addDamping(0,3);
         _action.airHitTimes--;
         _action.jumpTimes = 0;
         doAction(param1,true);
         _fighter.actionState = 10;
      }
      
      private function doAirSkill(param1:String) : void
      {
         var _loc2_:String = null;
         if(_doingAction == null && _action.airHitTimes <= 0)
         {
            return;
         }
         if(_action.isJumping)
         {
            _loc2_ = null;
            if(_actionCtrler.zhao3())
            {
               _loc2_ = "跳招-上";
            }
            if(_actionCtrler.zhao2())
            {
               _loc2_ = "跳招-下";
            }
            if(_loc2_ && _mc.checkFrame(_loc2_))
            {
               param1 = _loc2_;
            }
         }
         _action.airHitTimes = 0;
         _action.jumpTimes = 0;
         doAction(param1,true);
         _fighter.actionState = 11;
      }
      
      private function doAirBisha(param1:String, param2:int) : void
      {
         if(_doingAction == null && _action.airHitTimes <= 0)
         {
            return;
         }
         if(!_fighter.useQi(param2))
         {
            return;
         }
         _fighter.actionState = 12;
         _action.airHitTimes = 0;
         doAction(param1,true);
      }
      
      public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
         var _loc3_:BaseGameSprite = null;
         var _loc6_:Number = NaN;
         var _loc4_:Boolean = false;
         var _loc7_:int = 0;
         var _loc5_:Number = NaN;
         if(_action.hurtAction != null)
         {
            doAction(_action.hurtAction);
            return;
         }
         if(param1.onHit != null)
         {
            param1.onHit(_fighter);
         }
         if(_fighter.getIsTouchSide())
         {
            if(param1.owner && param1.owner is BaseGameSprite)
            {
               _loc3_ = param1.owner as BaseGameSprite;
               if(Math.abs(_fighter.x - param1.owner.x) < 100)
               {
                  _loc6_ = 0.3;
                  _loc4_ = _fighter.x < _loc3_.x;
                  _loc7_ = _loc4_ ? 1 : -1;
                  if(_loc4_ && _loc3_.direct == 1 || !_loc4_ && _loc3_.direct == -1)
                  {
                     _loc7_ = 0;
                  }
                  _loc5_ = param1.hitx * _loc7_ * 1.4;
                  if(_loc5_ > 20)
                  {
                     _loc5_ = 20;
                  }
                  if(_loc5_ < -20)
                  {
                     _loc5_ = -20;
                  }
                  _loc3_.setVec2(_loc5_,0,_loc6_,0);
               }
            }
         }
         if(_isDefense)
         {
            if(param1.isBreakDef && param1.hitType == 11)
            {
               doHurt(param1,param2);
               return;
            }
            if(param1.checkDirect && param1.owner)
            {
               if(checkDefDirect(param1.owner))
               {
                  if(_fighter.isSteelBody && _fighter.isAlive)
                  {
                     doSteelHurt(param1,param2);
                  }
                  else
                  {
                     doHurt(param1,param2);
                  }
                  return;
               }
            }
            doDefenseHit(param1,param2);
         }
         else if(_fighter.isSteelBody && _fighter.isAlive)
         {
            doSteelHurt(param1,param2);
         }
         else
         {
            doHurt(param1,param2);
         }
      }
      
      private function checkDefDirect(param1:IGameSprite) : Boolean
      {
         if(!_fighter.allowDefDirect)
         {
            return false;
         }
         if(param1 is Bullet)
         {
            if(_fighter.direct < 0 && (param1 as Bullet).speed.x < 0)
            {
               return true;
            }
            if(_fighter.direct > 0 && (param1 as Bullet).speed.x > 0)
            {
               return true;
            }
            return false;
         }
         if(_fighter.x < param1.x - 5)
         {
            return _fighter.direct < 0 && param1.direct < 0;
         }
         if(_fighter.x > param1.x + 5)
         {
            return _fighter.direct > 0 && param1.direct > 0;
         }
         return false;
      }
      
      private function doSteelHurt(param1:HitVO, param2:Rectangle) : void
      {
         var _loc3_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         if(!_fighter.isSuperSteelBody && (_fighter.energyOverLoad || param1.isBisha() || _fighter.allowSteelCatch && param1.isCatch()))
         {
            doHurt(param1,param2);
            return;
         }
         _fighter.hurtHit = param1;
         if(_fighter.isSuperSteelBody)
         {
            _fighter.loseHp(param1.getDamage() * 0.3);
         }
         else
         {
            _fighter.loseHp(param1.getDamage() * 0.65);
         }
         _action.isSteelHiting = true;
         if(param1.hurtType == 0)
         {
            _beHitGap = 4;
            _steelHoldFrame = Math.round(param1.hurtTime / 1000 * 30 / 3);
            if(_steelHoldFrame < 6)
            {
               _steelHoldFrame = 6;
            }
            if(_steelHoldFrame > 12)
            {
               _steelHoldFrame = 12;
            }
         }
         else
         {
            _beHitGap = 10;
            _steelHoldFrame = 12;
         }
         if(_fighter.isAlive && GameLogic.checkFighterDie(_fighter))
         {
            FighterEventDispatcher.dispatchEvent(_fighter,"DIE");
            _fighter.isAlive = false;
            doHurt(param1,param2);
            return;
         }
         if(_fighter.isSuperSteelBody)
         {
            _fighter.useEnergy(param1.getDamage() * 0.2);
         }
         else if(param1.isBreakDef)
         {
            _fighter.useEnergy(param1.getDamage());
         }
         else
         {
            _fighter.useEnergy(param1.getDamage() * 0.4);
         }
         _fighter.isAllowBeHit = false;
         if(!_fighter.isSuperSteelBody)
         {
            _loc3_ = param1.hitx;
            _loc6_ = param1.hity;
            if(param1.owner)
            {
               _loc3_ *= param1.owner.direct;
            }
            _loc4_ = _loc3_;
            _loc5_ = _loc6_;
            if(param1.isBreakDef)
            {
               _loc4_ *= 2;
               _loc5_ *= 2;
            }
            _fighter.setVec2(_loc4_,_loc5_,Math.abs(_loc3_ * 0.1),Math.abs(_loc6_ * 0.1));
         }
         if(param1 && param2)
         {
            EffectCtrl.I.doSteelHitEffect(param1,param2,_fighter);
         }
      }
      
      private function doHurt(param1:HitVO, param2:Rectangle) : void
      {
         var _loc3_:Number = NaN;
         _hasBadAction = hurtActionCheck(param1);
         if(param1 && param2)
         {
            EffectCtrl.I.doHitEffect(param1,param2,_fighter);
         }
         _fighter.hurtHit = param1;
         if(!_hasBadAction)
         {
            _loc3_ = _fighter.loseHp(param1.getDamage());
            param1.lastDamage = _loc3_;
         }
         _fighter.isAllowBeHit = false;
         _beHitGap = 4;
         if(_fighter.isAlive && GameLogic.checkFighterDie(_fighter))
         {
            _fighter.isAlive = false;
            FighterEventDispatcher.dispatchEvent(_fighter,"DIE");
         }
         if(!_fighter.isAlive || !param1.isWeakHit())
         {
            doHurtAnimate(param1,param2);
         }
      }
      
      private function doHurtAnimate(param1:HitVO, param2:Rectangle) : void
      {
         effectCtrler.endShadow();
         effectCtrler.endShake();
         _fighter.isCross = false;
         _fighter.isApplyG = true;
         _fighter.isAllowCrossFloor = false;
         _isDefense = false;
         var _loc3_:Number = param1.hitx;
         var _loc4_:Number = param1.hity;
         if(_fighter.mosouEnemyData && !_fighter.mosouEnemyData.isBoss)
         {
            if(!_fighter.isAlive)
            {
               if(_loc4_ > 0)
               {
                  _loc4_ += Math.random() * 3;
               }
               else
               {
                  _loc4_ -= 3 + Math.random() * 3;
               }
               _loc3_ += 2 + Math.random() * 3;
            }
         }
         if(param1.owner)
         {
            _loc3_ *= param1.owner.direct;
         }
         if(_fighter.isInAir)
         {
            if(_loc4_ <= 0)
            {
               _loc4_ -= 3;
            }
         }
         else if(_loc4_ < 0)
         {
            _loc4_ -= 6;
            _isTouchFloor = false;
         }
         _action.clearState();
         _doingAirAction = null;
         _doingAction = null;
         setSteelBody(false);
         if(param1.hurtType == 0 && !_hasBadAction)
         {
            _action.isHurting = true;
            _hurtHoldFrame = Math.round(param1.hurtTime / 1000 * 30) + GameConfig.HURT_FRAME_OFFSET;
            if(_hurtHoldFrame < 4)
            {
               _hurtHoldFrame = 4;
            }
            if(GameData.I.config.isComboBurden)
            {
               var _temp_9:* = §§findproperty(_hurtHoldFrame);
               _hurtHoldFrame += param1.isWeakHit() ? 4 : 2;
            }
            _hurtHoldFrameMax = _hurtHoldFrame;
            if(param1.hitType == 11)
            {
               _mc.goFrame("被打",false);
            }
            else
            {
               _mc.goFrame("被打",true,7);
            }
            _fighter.actionState = 21;
            _fighter.setVelocity(_loc3_,_loc4_);
            _fighter.setDamping(0.1,0.5);
            if(_fighter.isAlive && HitType.isHeavy(param1.hitType))
            {
               _fighter.getCtrler().getVoiceCtrl().playVoice(0,0.5);
            }
         }
         if(param1.hurtType == 1 || _hasBadAction)
         {
            _action.isHurtFlying = true;
            _fighter.actionState = 22;
            if(_hasBadAction)
            {
               _hurtDownQuickUp = false;
            }
            _hurtDownFrame = 0;
            if(_hasBadAction)
            {
               _mc.playHurtFly(_loc3_,_loc4_ > 0 ? 0 : _loc4_,false);
            }
            else
            {
               _mc.playHurtFly(_loc3_,_loc4_);
            }
            if(_fighter.isAlive)
            {
               _fighter.getCtrler().getVoiceCtrl().playVoice(1,1);
            }
            else
            {
               _fighter.getCtrler().getVoiceCtrl().playVoice(2,1);
            }
            hurtActionClear();
         }
         _isFalling = false;
         FighterEventDispatcher.dispatchEvent(_fighter,"HURT");
      }
      
      private function hurtActionCheck(param1:HitVO) : Boolean
      {
         var _loc2_:Object = null;
         var _loc3_:IGameSprite = param1.owner;
         if(_loc3_ == null)
         {
            return false;
         }
         if(beHitActions == null)
         {
            beHitActions = {};
         }
         if(_loc3_ is FighterMain || _loc3_ is Bullet || _loc3_ is FighterAttacker)
         {
            if(_loc3_ is Bullet && (_loc3_ as Bullet).owner is Assister || _loc3_ is FighterAttacker && (_loc3_ as FighterAttacker).getOwner() is Assister)
            {
               return false;
            }
            _loc2_ = null;
            if(_loc3_ is FighterMain)
            {
               _loc2_ = (_loc3_ as FighterMain).getDoingAction();
            }
            else if(_loc3_ is Bullet)
            {
               _loc2_ = (_loc3_ as Bullet).getDoingAction();
            }
            else if(_loc3_ is FighterAttacker)
            {
               _loc2_ = (_loc3_ as FighterAttacker).getDoingAction();
            }
            if(_loc2_ == null || _loc2_.action == null)
            {
               return false;
            }
            if(hurtActionRepeatCheck(_loc2_))
            {
               return true;
            }
            _lastHurtActionTimes = _loc2_.times;
            if(_longGhostStepState == 2)
            {
               return true;
            }
         }
         else if(_loc3_ is Assister)
         {
         }
         return false;
      }
      
      private function hurtActionRepeatCheck(param1:Object) : Boolean
      {
         if(!GameData.I.config.isInfiniteAttack)
         {
            return false;
         }
         if(!beHitActions[param1.action])
         {
            beHitActions[param1.action] = param1.times;
            return false;
         }
         if(beHitActions[param1.action] != param1.times)
         {
            return true;
         }
         return false;
      }
      
      public function hurtActionClear() : void
      {
         _hasBadAction = false;
         beHitActions = null;
         _lastHurtActionTimes = 0;
         _longGhostStepState = 0;
      }
      
      private function limitClear() : void
      {
         var _loc1_:FighterMain = _fighter.getCurrentTarget() as FighterMain;
         if(_loc1_)
         {
            _loc1_.limitLevel = 0;
         }
      }
      
      private function renderHurt() : void
      {
         if(!_fighter.isAlive)
         {
            return;
         }
         renderHurtBreak();
         renderBreakCatch();
      }
      
      private function renderHurtBreak() : void
      {
         if(!GameData.I.config.isSpecialSkill)
         {
            return;
         }
         if(!_actionCtrler.specailSkill())
         {
            return;
         }
         if(!_fighter.hasEnergy(50))
         {
            return;
         }
         if(_fighter.qi < 100)
         {
            return;
         }
         if(_fighter.getLastHurtHitVO().isBreakDef || _fighter.hurtBreakDefHit() || _fighter.getLastHurtHitVO().isBisha() || _fighter.hurtCatchHit() || _fighter.currentHurtDamage() > 210)
         {
            return;
         }
         _fighter.useQi(100);
         var _loc1_:Object = _action.specialHurtBreak;
         if(_loc1_ != null)
         {
            _fighter.clearHurtHits();
            _fighter.clearBeHurtHits();
            hurtActionClear();
            doActionFlexible(_loc1_);
         }
         else
         {
            switch(_fighter.data.comicType)
            {
               case 0:
                  _fighter.energyExplode();
                  break;
               case 1:
                  _fighter.replaceSkill();
                  break;
               default:
                  _fighter.energyExplode();
            }
         }
         if(_actionCtrler is FighterKeyCtrl)
         {
            (_actionCtrler as FighterKeyCtrl).justSpecialFrame = 8;
         }
         FighterEventDispatcher.dispatchEvent(_fighter,"HURT_RESUME");
      }
      
      private function renderBreakCatch() : void
      {
         var _loc1_:HitVO = _fighter.getLastHurtHitVO();
         if(_loc1_ == null)
         {
            return;
         }
         if(!_loc1_.isCatch())
         {
            return;
         }
         if(_loc1_.id.indexOf("sh") == -1)
         {
            return;
         }
         var _loc4_:FighterMain = _fighter.getCurrentTarget() as FighterMain;
         if(_loc4_.team.name != "P1")
         {
            return;
         }
         if(_loc1_.hurtTime != 500)
         {
         }
         var _loc5_:int = _loc4_.getCtrler().getMcCtrl().getFighterMc().getCurrentFrameCount() + 1;
         var _loc2_:Boolean = _loc1_.id.indexOf("sh1") != -1 && _loc5_ < 5;
         var _loc3_:Boolean = _loc1_.id.indexOf("sh2") != -1 && _loc5_ < 4;
         if(_loc2_ || _loc3_)
         {
         }
      }
      
      private function renderHurtAnimate() : void
      {
         var _loc1_:Point = _fighter.getVec2();
         var _loc2_:FighterVoiceCtrler = _fighter.getCtrler().getVoiceCtrl();
         if(_hurtHoldFrame > 0)
         {
            _hurtHoldFrame = _hurtHoldFrame - 1;
         }
         else if(!_fighter.isAlive)
         {
            _action.clearState();
            if(_fighter.isInAir)
            {
               hurtFly(_loc1_.x,_loc1_.y);
            }
            else
            {
               _mc.playHurtDown();
            }
            _loc2_.playVoice(2,1);
         }
         else
         {
            if(GameData.I.config.isStandardLimit && !GameMode.isTraining())
            {
               _fighter.isApplyG = true;
               _fighter.clearBeHurtHits();
               _action.clear();
               hurtActionClear();
               if(_fighter.isInAir)
               {
                  hurtFly(_fighter.getVecX() * _fighter.direct,_fighter.getVecY());
               }
               else
               {
                  _fighter.setVelocity(_fighter.getVecX() * _fighter.direct,_fighter.getVecY());
                  _mc.playHurtDown(false);
                  _action.isHurtFlying = true;
                  _fighter.actionState = 23;
                  _hurtDownQuickUp = false;
                  _hurtDownFrame = 0;
               }
               _loc2_.playVoice(1,1);
               return;
            }
            hurtResume();
         }
      }
      
      private function hurtResume() : void
      {
         if(!_fighter.isInAir && !_isTouchFloor)
         {
            _isTouchFloor = true;
         }
         idle();
         FighterEventDispatcher.dispatchEvent(_fighter,"HURT_RESUME");
      }
      
      private function renderBeHitGap() : void
      {
         if(_beHitGap > 0)
         {
            if(--_beHitGap <= 0)
            {
               if(_fighter.actionState == 15)
               {
                  return;
               }
               _fighter.isAllowBeHit = true;
            }
         }
      }
      
      private function doDefenseHit(param1:HitVO, param2:Rectangle) : void
      {
         var _loc3_:int = 0;
         if(param1.isBreakDef)
         {
            _loc3_ = 90;
         }
         else
         {
            _loc3_ = param1.getDamage() * 0.2;
            if(_loc3_ > 50)
            {
               _loc3_ = 50;
            }
         }
         if(!_fighter.hasEnergy(_loc3_,false))
         {
            if(_fighter.isSteelBody && _fighter.isAlive)
            {
               doSteelHurt(param1,param2);
            }
            else
            {
               _fighter.useEnergy(_loc3_);
               doBreakDefense(param1,param2);
            }
            return;
         }
         _fighter.defenseHit = param1;
         _fighter.loseHp(param1.getDamage() * 0.05);
         _fighter.isAllowBeHit = false;
         _beHitGap = 4;
         if(_fighter.isAlive && GameLogic.checkFighterDie(_fighter))
         {
            FighterEventDispatcher.dispatchEvent(_fighter,"DIE");
            _fighter.isAlive = false;
            doHurt(param1,param2);
            return;
         }
         var _loc4_:Number = param1.hitx;
         if(param1.hitxDef != 0)
         {
            _loc4_ = param1.hitxDef;
         }
         if(param1.owner)
         {
            _loc4_ *= param1.owner.direct;
         }
         _action.isDefenseHiting = true;
         if(param1.hurtType == 0)
         {
            _defenseHoldFrame = Math.round(param1.hurtTime / 1000 * 30 / 3);
            if(_defenseHoldFrame < 6)
            {
               _defenseHoldFrame = 6;
            }
            if(_defenseHoldFrame > 12)
            {
               _defenseHoldFrame = 12;
            }
         }
         else
         {
            _beHitGap = 8;
            _defenseHoldFrame = 12;
         }
         _fighter.useEnergy(_loc3_);
         _fighter.setVelocity(_loc4_,0);
         _fighter.setDamping(1,0);
         if(param1 && param2)
         {
            EffectCtrl.I.doDefenseEffect(param1,param2,_fighter.defenseType);
         }
      }
      
      private function doBreakDefense(param1:HitVO, param2:Rectangle) : void
      {
         var _loc6_:* = undefined;
         var _loc4_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc5_:HitVO = param1.clone();
         _loc5_.id = "breakdef";
         _loc5_.hurtTime = 1400;
         _fighter.defenseHit = _loc5_;
         _fighter.hurtHit = _loc5_;
         var _loc3_:Number = _fighter.loseHp(_loc5_.getDamage() * 0.1);
         _loc5_.lastDamage = _loc3_;
         _fighter.isAllowBeHit = false;
         if(_loc5_.hurtType == 0)
         {
            _beHitGap = 4;
         }
         if(_loc5_.hurtType == 1)
         {
            _beHitGap = 10;
         }
         _fighter.energyOverLoad = false;
         _isDefense = false;
         _loc6_ = _loc5_.hitx;
         if(_loc6_ < 5)
         {
            _loc6_ = 5;
         }
         if(_loc6_ > 10)
         {
            _loc6_ = 10;
         }
         if(_loc5_.owner)
         {
            _loc6_ *= _loc5_.owner.direct;
         }
         _action.clearState();
         _action.isHurting = true;
         _hurtHoldFrame = Math.round(_loc5_.hurtTime * 0.03);
         _hurtHoldFrameMax = _hurtHoldFrame;
         _mc.goFrame("被打",true,7);
         _fighter.actionState = 21;
         _fighter.setVelocity(_loc6_);
         _fighter.setDamping(0.1);
         if(_loc5_ && param2)
         {
            _loc4_ = param2.x + param2.width * 0.5;
            _loc7_ = param2.y + param2.height * 0.5;
            EffectCtrl.I.doDefenseEffect(_loc5_,param2,_fighter.defenseType);
            EffectCtrl.I.doEffectById("break_def",_loc4_,_loc7_,_fighter.direct);
         }
      }
      
      private function renderDefensHiting() : void
      {
         if(_defenseHoldFrame > 0)
         {
            _defenseHoldFrame = _defenseHoldFrame - 1;
         }
         else
         {
            if(_fighter.getVecX() == 0)
            {
               _action.isDefenseHiting = false;
            }
            _fighter.defenseHit = null;
         }
      }
      
      private function renderSteelHiting() : void
      {
         if(_steelHoldFrame > 0)
         {
            _steelHoldFrame = _steelHoldFrame - 1;
         }
         else
         {
            _action.isSteelHiting = false;
            _fighter.hurtHit = null;
         }
      }
      
      private function renderCheckTargetHit() : void
      {
         var _loc1_:Boolean = false;
         var _loc2_:Boolean = false;
         var _loc5_:Rectangle = null;
         var _loc4_:Boolean = false;
         if(_action.hitTargetChecker == null)
         {
            return;
         }
         var _loc3_:Rectangle = _fighter.getCtrler().getHitCheckRect(_action.hitTargetChecker);
         var _loc6_:Vector.<IGameSprite> = _fighter.getTargets();
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
                        doAction(_action.hitTarget);
                     }
                  }
                  else if(_loc4_)
                  {
                     doAction(_action.hitTarget);
                  }
               }
               else if(_loc4_)
               {
                  doAction(_action.hitTarget);
               }
            }
            else if(_loc1_)
            {
               if(_isCheckTargetIsAllowBeHit)
               {
                  if(_loc2_ && _loc4_)
                  {
                     doAction(_action.hitTarget);
                  }
               }
               else if(_loc4_)
               {
                  doAction(_action.hitTarget);
               }
            }
         }
      }
      
      private function renderUnHolding() : void
      {
         if(_action.unHolding && _action.unHoldingChecker && !_action.unHoldingChecker())
         {
            doAction(_action.unHolding);
         }
      }
      
      private function allowCatch() : Boolean
      {
         var _loc6_:IGameSprite = _fighter.getCurrentTarget();
         if(_loc6_ == null)
         {
            return false;
         }
         if(!(_loc6_ is FighterMain))
         {
            return false;
         }
         var _loc1_:FighterMain = _loc6_ as FighterMain;
         if(_loc1_.actionState == 21)
         {
            return false;
         }
         var _loc5_:Rectangle = _loc1_.getBodyArea();
         var _loc4_:Rectangle = _fighter.getBodyArea();
         if(_loc5_ == null || _loc4_ == null)
         {
            return false;
         }
         var _loc3_:Number = NaN;
         var _loc2_:Number = Math.abs(_fighter.y - _loc1_.y);
         if(_loc4_.x < _loc5_.x)
         {
            if(_fighter.direct < 0)
            {
               return false;
            }
            _loc3_ = _loc5_.x - (_loc4_.x + _loc4_.width);
         }
         else
         {
            if(_fighter.direct > 0)
            {
               return false;
            }
            _loc3_ = _loc4_.x - (_loc5_.x + _loc5_.width);
         }
         return _loc3_ < 2 && _loc2_ < 1;
      }
      
      private function doHurtDownJump() : void
      {
         if(_doingAction == "起身")
         {
            return;
         }
         if(_fighter.currentHurtDamage() > 240)
         {
            return;
         }
         if(!_fighter.hasEnergy(30))
         {
            return;
         }
         if(!_hurtDownQuickUp)
         {
            return;
         }
         _mc.stopHurtFly();
         _fighter.useEnergy(30);
         var _loc1_:Number = _fighter.getVecX();
         doAction("起身");
         _fighter.isAllowBeHit = false;
         _fighter.setVelocity(_loc1_);
         _fighter.setDamping(_loc1_ * 0.1);
         FighterEventDispatcher.dispatchEvent(_fighter,"HURT_RESUME");
      }
      
      public function sayIntro() : void
      {
         _fighter.actionState = 60;
         _mc.goFrame("开场");
      }
      
      public function doWin() : void
      {
         _fighter.actionState = 61;
         _mc.goFrame("胜利");
      }
      
      public function doLose() : void
      {
         _fighter.actionState = 62;
         _mc.goFrame("失败");
      }
      
      private function doGhostStep() : void
      {
         if(startGhostStep())
         {
            move(8,0);
            _fighter.setVec2(0,0,0,0);
            _mc.goFrame("走",true);
            _ghostType = 0;
         }
      }
      
      private function doGhostJump() : void
      {
         if(startGhostStep())
         {
            move(0,-12);
            damping(0,0.1);
            _fighter.setVec2(0,0,0,0);
            _mc.goFrame("跳",false);
            _action.jumpTimes--;
            _ghostType = 1;
         }
      }
      
      private function doGhostJumpDown() : void
      {
         if(startGhostStep())
         {
            move(0,15);
            _fighter.setVec2(0,0,0,0);
            _mc.goFrame("落",false);
            _ghostType = 2;
         }
      }
      
      private function startGhostStep() : Boolean
      {
         if(!GameData.I.config.isGhostStep)
         {
            return false;
         }
         if(_fighter.explodeSkillFrame > 0)
         {
            return false;
         }
         if(_fighter.qi < 60)
         {
            return false;
         }
         if(!_fighter.hasEnergy(80,true))
         {
            return false;
         }
         var _loc1_:FighterMain = _fighter.getCurrentTarget() as FighterMain;
         if(_ghostStepIng || _loc1_.getCtrler().getMcCtrl().isGhostSteping())
         {
            return false;
         }
         _fighter.useQi(60);
         _fighter.useEnergy(80);
         _fighter.getCtrler().setDirectToTarget();
         if(_fighter.x - GameCtrl.I.gameState.getMap().left <= 15)
         {
            _fighter.direct = 1;
         }
         if(GameCtrl.I.gameState.getMap().right - _fighter.x <= 15)
         {
            _fighter.direct = -1;
         }
         _ghostStepIng = true;
         _ghostStepFrame = 12;
         _justHurtResume = false;
         _fighter.isAllowBeHit = false;
         _fighter.isCross = true;
         effectCtrler.ghostStep();
         if(_loc1_.actionState == 21)
         {
            _fighter.limitLevel++;
         }
         return true;
      }
      
      private function renderGhostStep() : void
      {
         var _loc1_:Number = NaN;
         if(_ghostStepFrame-- <= 0)
         {
            if(_ghostType == 1)
            {
               _loc1_ = _fighter.getVecY();
               _action.isJumping = false;
               endGhostStep();
               _fighter.setVelocity(0,_loc1_);
               _fighter.setDamping(0,-_loc1_ * 0.1);
               setAirMove(true);
               return;
            }
            endGhostStep();
         }
         if(_ghostType == 2)
         {
            if(GameLogic.isTouchBottomFloor(_fighter))
            {
               stopMove();
               touchFloor();
               idle();
            }
         }
      }
      
      private function endGhostStep() : void
      {
         _ghostStepIng = false;
         effectCtrler.endGhostStep();
         if(_ghostType == 0)
         {
            _fighter.getCtrler().setDirectToTarget();
            if(_fighter.x - GameCtrl.I.gameState.getMap().left <= 10)
            {
               _fighter.direct = 1;
            }
         }
         _isFalling = false;
         _fighter.setInAir(GameLogic.isInAir(_fighter));
         idle();
         var _loc1_:FighterMain = _fighter.getCurrentTarget() as FighterMain;
         if(_loc1_ != null)
         {
            _loc1_.targetDoGhostStep();
         }
      }
      
      public function targetDoGhostStep() : void
      {
         if(_action.isDefenseHiting)
         {
            _fighter.isAllowBeHit = false;
            _beHitGap = 4;
            _fighter.setVecX(0);
            _defenseHoldFrame = 0;
            _action.isDefenseHiting = false;
            setDash();
         }
      }
      
      public function isGhostSteping() : Boolean
      {
         return _ghostStepIng;
      }
   }
}

