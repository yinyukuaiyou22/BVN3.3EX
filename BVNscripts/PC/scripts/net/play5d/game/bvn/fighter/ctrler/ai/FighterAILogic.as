package net.play5d.game.bvn.fighter.ctrler.ai
{
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.Bullet;
   import net.play5d.game.bvn.fighter.FighterActionState;
   import net.play5d.game.bvn.fighter.FighterAttacker;
   import net.play5d.game.bvn.fighter.FighterComicType;
   import net.play5d.game.bvn.fighter.FighterMC;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class FighterAILogic extends FighterAILogicBase
   {
      
      public var moveLeft:Boolean;
      
      public var moveRight:Boolean;
      
      public var jump:Boolean;
      
      public var jumpDown:Boolean;
      
      public var dash:Boolean;
      
      public var downJump:Boolean;
      
      public var defense:Boolean;
      
      private const _moveKeep:Number = 40;
      
      private const _catchMoveKeep:Number = 15;
      
      private var _hurtDownMoveType:int = 0;
      
      private var _moveSetDirect:int = 0;
      
      private const _dashKeep:Number = 250;
      
      private const _dashInKeep:Number = 125;
      
      private const _jumpKeep:Number = 300;
      
      private const _jumpDownKeep:Number = 50;
      
      private var _justStandUp:Boolean = false;
      
      public var attack:Boolean;
      
      public var attackAIR:Boolean;
      
      public var skillAIR:Boolean;
      
      public var bishaAIR:Boolean;
      
      public var skill1:Boolean;
      
      public var skill2:Boolean;
      
      public var zhao1:Boolean;
      
      public var zhao2:Boolean;
      
      public var zhao3:Boolean;
      
      public var catch1:Boolean;
      
      public var catch2:Boolean;
      
      public var bisha:Boolean;
      
      public var bishaUP:Boolean;
      
      public var bishaSUPER:Boolean;
      
      public var assist:Boolean;
      
      public var specialSkill:Boolean;
      
      public var holdAttack:Boolean;
      
      public var holdSkill:Boolean;
      
      public var holdBisha:Boolean;
      
      public var ghostStep:Boolean;
      
      public var ghostJump:Boolean;
      
      public var ghostJumpDowm:Boolean;
      
      private var _moveFrame:int;
      
      private var _defenseFrame:int;
      
      private var _hasSetColor:Boolean = false;
      
      private var _isNeedBishaAction:Object = {
         "bisha":true,
         "bishaUP":true,
         "bishaSUPER":true,
         "bishaAIR":true
      };
      
      private var _isFirstAssister:Boolean = true;
      
      public function FighterAILogic(param1:int, param2:FighterMain)
      {
         super(param1,param2);
      }
      
      override public function render() : void
      {
         var _loc1_:Function = null;
         super.render();
         if(_fighter == null || _target == null)
         {
            return;
         }
         try
         {
            updateHurtAI();
            updateGhostStep();
            _loc1_ = AImain.afterRender as Function;
            if(_loc1_ != null)
            {
               _loc1_();
            }
         }
         catch(err:Error)
         {
            Debugger.errorMsg("FightAILogic.render :: Render error.");
            if(err.getStackTrace() != null)
            {
               Debugger.log(err.getStackTrace());
            }
            else
            {
               Debugger.log(err.toString());
            }
         }
      }
      
      override protected function updateActionAI() : void
      {
         if(_fighter != null && _target != null && _targetFighter != null)
         {
            updateAImain();
            updateDashAI();
            updateAttackAI();
            updateSkill();
            updateBisha();
            updateCatch();
            updateAssist();
            updateMoveAI();
            updateJumpAI();
            updateJumpDownAI();
            updateDefenseAI();
            updateSpecialSkill();
         }
      }
      
      private function updateAImain() : void
      {
         var _loc4_:Function = null;
         if(AImain == null)
         {
            return;
         }
         if(GameData.I.config.AI_level < 6)
         {
            return;
         }
         var _loc2_:Boolean = Boolean(AImain.inited);
         var _loc1_:Function = AImain.init as Function;
         if(_loc1_ != null && !_loc2_)
         {
            _loc1_(setAIAction,addContOrder,getAIByFighterState);
            _loc4_ = AImain.setBishaAction;
            if(_loc4_ != null)
            {
               _loc4_(_isNeedBishaAction);
            }
         }
         var _loc3_:Function = AImain.preRender as Function;
         if(_loc3_ != null)
         {
            _loc3_();
         }
      }
      
      private function setAIAction(param1:String, param2:Boolean = true) : void
      {
         try
         {
            this[param1] = param2;
         }
         catch(e:Error)
         {
         }
      }
      
      private function updateAImainAction(param1:String) : Boolean
      {
         if(AImain == null)
         {
            return false;
         }
         var _loc3_:Function = AImain.updateActionAI;
         if(_loc3_ == null)
         {
            return false;
         }
         return Boolean(_loc3_(param1));
      }
      
      private function updateHurtAI() : void
      {
         if(updateAImainAction("hurt"))
         {
            return;
         }
         downJump = false;
         if(_fighter.energy <= 60 || _fighter.energyOverLoad)
         {
            return;
         }
         var _loc1_:Object = {};
         _loc1_["defult"] = [0,0,0.2,1,3,5];
         _loc1_[11] = [0,0,0,0,0,0];
         _loc1_[12] = [0,0,0,0,0,0];
         _loc1_[13] = [0,0,0,0,0,0];
         setAIByMain(_loc1_,"downJump");
         downJump = getAIByFighterState(_loc1_);
      }
      
      private function updateMoveAI() : void
      {
         var _loc4_:Boolean = false;
         var _loc6_:Object = null;
         var _loc3_:Number = NaN;
         var _loc5_:Boolean = false;
         var _loc1_:Boolean = false;
         if(updateAImainAction("move"))
         {
            return;
         }
         moveLeft = false;
         moveRight = false;
         var _loc2_:Point = getTargetDistance(_target);
         if(FighterActionState.isHurtFlying(_targetFighter.actionState))
         {
            if(!_hurtDownMoveType)
            {
               if(_loc2_.x > 125)
               {
                  _hurtDownMoveType = Math.random() < 0.7 ? 2 : 1;
               }
               else
               {
                  _hurtDownMoveType = Math.random() < 0.45 ? 2 : 1;
               }
            }
         }
         else
         {
            _hurtDownMoveType = 0;
         }
         var _loc7_:Boolean = _fighter.actionState == 20;
         if(_loc7_)
         {
            _loc4_ = getAIResult(1,2,4,5,6,8);
            if(_loc4_)
            {
               if(_fighter.x > _target.x + 20)
               {
                  moveLeft = true;
               }
               if(_fighter.x < _target.x - 20)
               {
                  moveRight = true;
               }
            }
            return;
         }
         var _loc8_:Boolean = false;
         if(_moveFrame < GameConfig.FPS_GAME)
         {
            _moveFrame = _moveFrame + 1;
            _loc8_ = true;
         }
         else
         {
            _loc6_ = {};
            _loc6_.defult = [3,5,7,8,9,10];
            _loc6_[10] = [2,3,4,5,6,8];
            _loc6_[11] = [2,4,3,2,1,0];
            _loc6_[12] = [2,1,0,0,0,0];
            _loc6_[13] = [2,1,0,0,0,0];
            setAIByMain(_loc6_,"move");
            _loc8_ = getAIByFighterState(_loc6_);
            if(_loc8_)
            {
               _moveFrame = 0;
            }
         }
         if(_loc8_)
         {
            if(_hurtDownMoveType == 1)
            {
               if(_target.direct > 0 ? _fighter.x > _target.x - 5 : _fighter.x > _target.x + 20)
               {
                  moveLeft = true;
               }
               else if(_target.direct > 0 ? _fighter.x < _target.x - 20 : _fighter.x < _target.x + 5)
               {
                  moveRight = true;
               }
            }
            else if(_hurtDownMoveType == 2)
            {
               _loc3_ = _fighter.x > _target.x ? _target.x + 125 : _target.x - 125;
               if(_fighter.x > 40 + _loc3_)
               {
                  moveLeft = true;
               }
               else if(_fighter.x < -40 + _loc3_)
               {
                  moveRight = true;
               }
            }
            else
            {
               _loc5_ = (catch1 || catch2) && _loc2_.y < 2;
               _loc3_ = _loc5_ ? 15 : 40;
               if(_fighter.x > _target.x + _loc3_)
               {
                  moveLeft = true;
               }
               else if(_fighter.x < _target.x - _loc3_)
               {
                  moveRight = true;
               }
            }
         }
         if(!moveLeft && !moveRight)
         {
            _moveFrame = GameConfig.FPS_GAME;
         }
         if(_targetFighter && (_targetFighter.isSteelBody && _targetFighter.isSuperSteelBody && !_fighter.isSteelBody))
         {
            _loc1_ = moveLeft;
            moveLeft = moveRight;
            moveRight = _loc1_;
         }
         else if(_fighter.isInAir && _fighterAction.airHitTimes < 1)
         {
            _loc1_ = moveLeft;
            moveLeft = moveRight;
            moveRight = _loc1_;
         }
      }
      
      private function updateJumpAI() : void
      {
         if(updateAImainAction("jump"))
         {
            return;
         }
         if(!_fighterAction.jump)
         {
            jump = false;
            return;
         }
         var _loc1_:Object = {};
         if(_isConting)
         {
            _loc1_["defult"] = [1,2,3,2,1,0];
            _loc1_[21] = [0,1,2,3,3,4];
         }
         else if(targetInRange("tkanmian") && (_targetFighter && _targetFighter.isAllowBeHit && !_targetFighter.isSteelBody && _targetFighter.actionState != 16) && !(_targetFighter.hurtHit && _targetFighter.hurtHit.id.indexOf("sh") != -1))
         {
            _loc1_["defult"] = [0.1,0.5,1,3,1.9,1.3];
         }
         else if(targetInRange("tzmian") && (_targetFighter && _targetFighter.isAllowBeHit && !_targetFighter.isSteelBody && _targetFighter.actionState != 16) && !(_targetFighter.hurtHit && _targetFighter.hurtHit.id.indexOf("sh") != -1))
         {
            _loc1_["defult"] = [0.1,0.5,1,3,1.5,1];
         }
         else if(_fighter.y > _target.y + 300 || _fighter.y > _target.y + 50 && _targetFighter.isInAir == false)
         {
            _loc1_["defult"] = [2,3,4,5,6,6];
            _loc1_[12] = _loc1_[13] = [2,1,0,0,0,0];
         }
         else
         {
            _loc1_["defult"] = [0.01,0,0,0,0,0];
            _loc1_[12] = _loc1_[13] = [0.02,0,0,0,0,0];
         }
         setAIByMain(_loc1_,"jump");
         jump = getAIByFighterState(_loc1_);
         if(_isConting && jump)
         {
            if(_loc1_["order"])
            {
               addContOrder("jump",110 + _loc1_["order"]);
            }
            else
            {
               addContOrder("jump",110);
            }
         }
      }
      
      private function updateJumpDownAI() : void
      {
         if(updateAImainAction("jumpDown"))
         {
            return;
         }
         var _loc1_:Object = {};
         if(_fighter.y < _target.y - 50)
         {
            _loc1_["defult"] = [2,3,4,5,6,6];
            _loc1_[12] = _loc1_[13] = [2,1,0,0,0,0];
         }
         else
         {
            _loc1_["defult"] = [0.01,0,0,0,0,0];
            _loc1_[12] = _loc1_[13] = [0.02,0,0,0,0,0];
         }
         setAIByMain(_loc1_,"jumpDown");
         jumpDown = getAIByFighterState(_loc1_);
      }
      
      private function updateDashAI() : void
      {
         var _loc5_:* = 0;
         if(updateAImainAction("dash"))
         {
            return;
         }
         var _loc6_:Object = {};
         var _loc1_:Number = getTargetDistance(_target).x;
         var _loc3_:Number = _target.x > _fighter.x ? 1 : -1;
         var _loc4_:Boolean = false;
         if(_targetFighter && (_targetFighter.actionState == 22 || _targetFighter.actionState == 23 || _targetFighter.actionState == 24))
         {
            dash = false;
            return;
         }
         if(!_fighterAction.dash && _fighter.actionState != 23)
         {
            dash = false;
            return;
         }
         var _loc2_:Boolean = false;
         if(_fighter.actionState == 23 || _justStandUp)
         {
            _loc2_ = true;
            _justStandUp = _fighter.actionState == 23;
            if(_loc1_ <= 60)
            {
               _loc6_["defult"] = [2,3,4,5,6,9];
            }
            else if(_loc1_ <= 180)
            {
               _loc6_["defult"] = [1,2,3,4,4,4];
            }
            else
            {
               _loc6_["defult"] = [1,2,3,2,1,0.5];
            }
            _loc6_[21] = _loc6_[22] = _loc6_[23] = _loc6_[24] = [0,0,0.1,0.5,0,0];
         }
         else if(_fighter.actionState >= 10 && _fighter.actionState <= 13)
         {
            _loc6_["defult"] = [0,0,0.2,0.5,2,8];
            _loc6_[21] = [0,0,0.1,0.5,0,0];
            _loc4_ = true;
         }
         else if(_fighter.energy < 60)
         {
            if(_loc1_ > 250 && _fighter.direct == _loc3_)
            {
               _loc6_["defult"] = [0,0,0.1,0.5,0,0];
               _loc6_[10] = _loc6_[11] = [0,0.05,0.3,1,1.7,2.5];
               _loc6_[12] = _loc6_[13] = [0,0,0,0,0,0];
            }
            else if(_loc1_ < 125 && _fighter.energy > 20 && !_fighter.energyOverLoad && getTargetDistance(_target).y <= 75)
            {
               _loc6_["defult"] = [0,0,0.05,1,1,1];
               _loc6_[10] = [0.5,1,1.5,2.5,3,4.5];
               _loc6_[11] = [0.5,1,1.5,2.5,3,4.5];
               _loc6_[12] = _loc6_[13] = [0.5,1,1.5,2.5,3,4.5];
               _loc6_[15] = [0,0,0.1,0.5,0,0];
               _loc6_[21] = [0,0,0.1,0,0,0];
               _loc4_ = true;
            }
            else
            {
               _loc6_["defult"] = [0,0,0.05,0,0,0];
               _loc6_[10] = _loc6_[11] = _loc6_[12] = _loc6_[13] = [0,0,0,0,0,0];
            }
         }
         else if(_loc1_ > 250 && _fighter.direct == _loc3_)
         {
            _loc6_["defult"] = [0.5,1,1.5,2.5,4,5.5];
            _loc6_[10] = [0,0,0.1,3,2,1];
            _loc6_[11] = [0,0,0.05,1,1.5,2];
            _loc6_[12] = _loc6_[13] = [0,0,0,0,0,0];
            _loc6_[15] = [0,0,0.1,0.5,0.05,0.05];
            _loc6_[21] = [0,0,0.1,0,0,0];
         }
         else if(_loc1_ < 125 && getTargetDistance(_target).y <= 75)
         {
            _loc6_["defult"] = [0,0,0.05,1,1.5,2.5];
            _loc6_[10] = [0.5,1,1.5,2.5,5,8];
            _loc6_[11] = [0.5,1,1.5,2.5,5,8];
            _loc6_[12] = _loc6_[13] = [0.5,1,1.5,2.5,6,9];
            _loc6_[15] = [0,0,0.1,0.5,0,0];
            _loc6_[21] = [0,0,0.1,0,0,0];
            _loc4_ = true;
         }
         else
         {
            _loc6_["defult"] = [0,0,0.05,0.1,0,0];
            _loc6_[10] = _loc6_[11] = _loc6_[12] = _loc6_[13] = [0,0,0,0,0,0];
         }
         setAIByMain(_loc6_,"dash");
         dash = getAIByFighterState(_loc6_);
         if(_loc4_)
         {
            _loc5_ = _loc2_ ? 400 : 114;
            if(_loc6_["order"])
            {
               addContOrder("dash",_loc5_ + _loc6_["order"]);
            }
            else
            {
               addContOrder("dash",_loc5_);
            }
         }
      }
      
      private function updateDefenseAI() : void
      {
         var _loc2_:Object = null;
         var _loc4_:* = undefined;
         if(updateAImainAction("defense"))
         {
            return;
         }
         var _loc6_:Object = null;
         var _loc3_:* = null;
         var _loc8_:Point = null;
         var _loc1_:Array = _targetFighter.getCurrentHits();
         if(_fighter.energy <= 20 || _fighter.isSteelBody || _fighter.hpRate > 0.5 && (!_loc1_ || _loc1_ && _loc1_.length == 0))
         {
            defense = false;
            return;
         }
         if(defense)
         {
            _loc6_ = {};
            _loc6_["defult"] = [10,10,10,10,10,10];
            _loc6_[40] = [5,4,4,3,2,1];
            _loc6_[0] = [2,1,1,0,0,0];
            _loc6_[14] = [9,6,2,1,0.5,0];
            _loc6_[15] = [2,1,1,0,0,0];
            _loc6_[21] = [0,0,0,0,0,0];
            _loc6_[22] = [0,0,0,0,0,0];
            _loc6_[23] = [0,0,0,0,0,0];
            setAIByMain(_loc6_,"defensing");
            defense = getAIByFighterState(_loc6_);
            if(defense)
            {
               doInDefense(_loc6_,119);
               return;
            }
         }
         var _loc5_:Point = getTargetDistance(_target);
         _loc2_ = {};
         _loc2_["defult"] = [0,0,0,0,0,0];
         if(_fighter.qi <= 10)
         {
            _loc2_[10] = _loc2_[11] = [1,2,3,2,1,0.5];
            _loc2_[12] = _loc2_[13] = [2,3,3.5,4,5,6.5];
         }
         else
         {
            if(_loc5_.x < 100 && _loc5_.y < 100)
            {
               _loc2_[10] = [0.5,1,3,5,7,9];
            }
            else
            {
               _loc2_[10] = [0.5,1,3,2,1,0];
            }
            _loc2_[11] = [1,2.5,4,6,8,9.5];
            _loc2_[12] = _loc2_[13] = [2,4,6,8,10,10];
         }
         setAIByMain(_loc2_,"defense");
         defense = getAIByFighterState(_loc2_);
         if(defense)
         {
            doInDefense(_loc2_,120);
            return;
         }
         var _loc7_:Vector.<IGameSprite> = _fighter.getTargets();
         for each(_loc4_ in _loc7_)
         {
            if(_loc4_ != _target)
            {
               if(_loc4_ is Bullet && (_loc4_ as Bullet).isAttacking)
               {
                  _loc8_ = getTargetDistance(_loc4_);
                  if(_loc8_.x < 125 && _loc8_.y < 125)
                  {
                     defense = getAIResult(2,4,5,7,9,10);
                  }
                  else
                  {
                     defense = getAIResult(2,4,2,1,0.5,0.2);
                  }
                  if(defense)
                  {
                     doInDefense(_loc2_,115);
                     return;
                  }
               }
               if(_loc4_ is FighterAttacker && (_loc4_ as FighterAttacker).isAttacking)
               {
                  _loc8_ = getTargetDistance(_loc4_);
                  if(_loc8_.x < 125 && _loc8_.y < 125)
                  {
                     defense = getAIResult(2,4,5,7,9,10);
                  }
                  else
                  {
                     defense = getAIResult(2,4,2,1,0.5,0.2);
                  }
                  if(defense)
                  {
                     doInDefense(_loc2_,120);
                     return;
                  }
               }
               if(_loc4_ is Assister && (_loc4_ as Assister).isAttacking)
               {
                  _loc8_ = getTargetDistance(_loc4_);
                  if(_loc8_.x < 125 && _loc8_.y < 125)
                  {
                     defense = getAIResult(2,4,5,7,9,10);
                  }
                  else
                  {
                     defense = getAIResult(2,4,2,1,0.5,0.2);
                  }
                  if(defense)
                  {
                     doInDefense(_loc2_,120);
                     return;
                  }
               }
            }
         }
      }
      
      private function doInDefense(param1:Object = null, param2:int = 115) : void
      {
         if(param1 && param1["order"])
         {
            addContOrder("defense",param2 + param1["order"]);
         }
         else
         {
            addContOrder("defense",param2);
         }
         if(_target.x < _fighter.x)
         {
            moveLeft = true;
            moveRight = false;
         }
         else
         {
            moveLeft = false;
            moveRight = true;
         }
      }
      
      private function updateAttackAI() : void
      {
         var _loc1_:Boolean = updateAImainAction("attack");
         if(_loc1_)
         {
            return;
         }
         var _loc4_:String = null;
         attack = false;
         attackAIR = false;
         if(!_fighterAction.attack && !_fighterAction.attackAIR)
         {
            return;
         }
         if(!targetCanBeHit())
         {
            return;
         }
         var _loc2_:Object = {};
         _loc2_.defult = _isConting ? [1,2,3,6,9,10] : [0.5,1,4,6,8,10];
         _loc2_[20] = _isConting ? [1,2,3,6,9,9] : [0.5,1,3,2,2,1];
         _loc2_[16] = [0.5,1,1,0.5,0,0];
         if(_fighter.actionState == 20)
         {
            _loc2_[10] = _loc2_[11] = _loc2_[12] = _loc2_[13] = [0.5,1,1,0,0,0];
         }
         else
         {
            _loc2_[10] = [0.5,1,1,0,3,10];
            _loc2_[11] = [0,0,0,0,3,10];
            _loc2_[12] = _loc2_[13] = [0,0,0.1,0,0,0];
         }
         if(_targetFighter && _targetFighter.hurtHit && _targetFighter.hurtHit.id && _targetFighter.hurtHit.id.indexOf("sh") != -1 && (_target.x - _fighter.x) * _fighter.direct <= 0)
         {
            _loc2_[21] = [1,0.5,0.2,0,0,0];
         }
         else
         {
            _loc2_[21] = [10,10,10,10,10,10];
         }
         if(_fighterAction.attack)
         {
            setAIByMain(_loc2_,"attack");
         }
         if(_fighterAction.attackAIR)
         {
            setAIByMain(_loc2_,"attackAIR");
         }
         var _loc3_:Boolean = getAIByFighterState(_loc2_);
         if(!_loc3_)
         {
            return;
         }
         var _loc5_:int = 100;
         if(_isConting)
         {
            attack = true;
            attackAIR = true;
            _loc4_ = _fighter.getCtrler().getMcCtrl().getCurAction();
            if(_loc4_ == "砍1")
            {
               _loc5_ = 200;
            }
            else if(!!_targetFighter && _targetFighter.actionState == 21)
            {
               _loc5_ = 117;
            }
            else
            {
               attack = targetInRange("kanmian");
               attackAIR = targetInRange("tkanmian");
               _loc5_ = 300;
            }
         }
         else
         {
            attack = targetInRange("kanmian");
            attackAIR = targetInRange("tkanmian");
            _loc5_ = 116;
         }
         if(_loc2_["order"])
         {
            _loc5_ += _loc2_["order"];
         }
         if(attack && _fighterAction.attack)
         {
            addContOrder("attack",_loc5_);
         }
         if(attackAIR && _fighterAction.attackAIR)
         {
            addContOrder("attackAIR",_loc5_);
         }
      }
      
      private function updateSkill() : void
      {
         skill1 = _fighterAction.skill1 && getSkillAI("skill1","kj1","kj1mian",10);
         skill2 = _fighterAction.skill2 && getSkillAI("skill2","kj2","kj2mian",10);
         zhao1 = _fighterAction.zhao1 && getSkillAI("zhao1","zh1","zh1mian",10);
         zhao2 = _fighterAction.zhao2 && getSkillAI("zhao2","zh2","zh2mian",10);
         zhao3 = _fighterAction.zhao3 && getSkillAI("zhao3","zh3","zh3mian",10);
         skillAIR = _fighterAction.skillAIR && getSkillAI("skillAIR","tz","tzmian",10);
      }
      
      private function getSkillAI(param1:String, param2:String, param3:String, param4:int) : Boolean
      {
         if(updateAImainAction(param1))
         {
            return this[param1];
         }
         var _loc6_:Object = {};
         if(isBreakAct(param2))
         {
            _loc6_.defult = _isConting ? [0.1,0.2,0.5,3,6,10] : [0,0.2,0.5,2,1,0.5];
            _loc6_[20] = _isConting ? [0,0.2,0.7,5,7,9] : [0.1,0.2,0.5,1,2,2];
            _loc6_[21] = _isConting ? [0.5,1,3,5,8,10] : [0,0.2,0.5,2,1,0.5];
         }
         else
         {
            _loc6_.defult = _isConting ? [0,0,0.1,1,5,10] : [0.1,0.5,1,3,1.5,1];
            _loc6_[20] = [0,0,1,1,0,0.5];
            _loc6_[21] = _isConting ? [1,2,3,5,7,10] : [0.1,0.5,1,3,1.5,1];
         }
         _loc6_[16] = [0.5,1,0.5,0,0,0];
         if(_fighter.actionState == 20)
         {
            _loc6_[10] = _loc6_[11] = _loc6_[12] = _loc6_[13] = [0.5,1,1,0,0,0];
         }
         else
         {
            _loc6_[10] = [0,0,0,1,1,2];
            _loc6_[11] = _loc6_[12] = _loc6_[13] = [0,0,0,0,0.5,0.25];
         }
         if(_targetFighter && _targetFighter.hurtHit && _targetFighter.hurtHit.id && _targetFighter.hurtHit.id.indexOf("sh") != -1)
         {
            _loc6_[21] = [1,0.5,0.2,0,0,0];
         }
         setAIByMain(_loc6_,param1);
         var _loc5_:Boolean = getAIByFighterState(_loc6_) && targetInRange(param3) && targetCanBeHit();
         if(_loc5_)
         {
            if(_isConting || _targetFighter.actionState == 21)
            {
               if(_loc6_["order"])
               {
                  param4 += _loc6_["order"];
               }
               addContOrder(param1,param4 + 100);
            }
         }
         return _loc5_;
      }
      
      public function updateBisha() : void
      {
         bisha = bishaUP = bishaSUPER = bishaAIR = false;
         if(_targetFighter == null)
         {
            return;
         }
         var _loc1_:Number = _targetFighter.hp <= 300 ? 100 : 200;
         bisha = getBishaAI("bisha","bs","bsmian",_loc1_,115) && (_isNeedBishaAction["bisha"] ? _fighterAction.bisha : true);
         bishaUP = getBishaAI("bishaUP","sbs","sbsmian",_loc1_,115) && (_isNeedBishaAction["bishaUP"] ? _fighterAction.bishaUP : true);
         bishaSUPER = getBishaAI("bishaSUPER","cbs","cbsmian",300,100) && (_isNeedBishaAction["bishaSUPER"] ? _fighterAction.bishaSUPER : true);
         bishaAIR = getBishaAI("bishaAIR","kbs","kbsmian",_loc1_,115) && (_isNeedBishaAction["bishaAIR"] ? _fighterAction.bishaAIR : true);
      }
      
      private function getBishaAI(param1:String, param2:String, param3:String, param4:int, param5:int) : Boolean
      {
         if(updateAImainAction(param1))
         {
            return this[param1];
         }
         var _loc7_:Object = {};
         var _loc6_:Boolean = false;
         if(_fighter.qi >= param4)
         {
            if(param4 > 200 && _targetFighter.hp > 500)
            {
               _loc7_.defult = [0.05,0.02,0.01,0,0,0];
               _loc7_[20] = [0.1,0.2,0,0,0,0];
               _loc7_[21] = [0.1,0.2,0,0,0,0];
            }
            else if(isBreakAct(param2))
            {
               _loc7_.defult = _isConting ? [0,0,0.3,2,5,10] : [0.1,0.2,0.5,2,2,2];
               _loc7_[20] = _isConting ? [0,0,0.5,3,7,9] : [0.1,0.2,1,6,8,10];
               _loc7_[21] = [0.2,0.5,1,3,5,8];
            }
            else
            {
               _loc7_.defult = _isConting ? [0,0,0.5,4,8,10] : [0.2,0.5,1,2,2,0];
               _loc7_[21] = [0.2,0.5,1,3,5,6];
               _loc7_[14] = [0.2,0.5,1,3,4,4];
               _loc7_[20] = _isConting ? [0.2,0.5,1,3,2,1] : [0.2,0.5,1,2,1,0];
            }
            _loc7_[15] = [0.2,0.5,0,0,0,0];
            _loc7_[16] = [0.2,0.5,0,0,0,0];
            _loc7_[10] = _loc7_[11] = [0,0.2,0.5,2,1,0.66];
            _loc7_[12] = _loc7_[13] = [0,0.1,0.3,1,2,5];
            _loc7_[0] = [0,0,0.1,0,0.01,0.02];
            if(_targetFighter && _targetFighter.hurtHit && _targetFighter.hurtHit.id && _targetFighter.hurtHit.id.indexOf("sh") != -1)
            {
               _loc7_[21] = [1,0.5,0.2,0,0,0];
            }
            setAIByMain(_loc7_,param1);
            _loc6_ = getAIByFighterState(_loc7_) && targetInRange(param3) && targetCanBeHit();
            if(_loc6_ && _targetFighter)
            {
               if(_targetFighter.actionState == 21)
               {
                  _loc6_ = _targetFighter.qi < 100 || _targetFighter.energy < 30 && _targetFighter.energyOverLoad == true || _targetFighter.hurtBreakHit() || _targetFighter.currentHurtDamage() > 210;
               }
               else
               {
                  _loc6_ = (_targetFighter.energy < 20 && _targetFighter.energyOverLoad == true || (_targetFighter.actionState == 12 || _targetFighter.actionState == 13) && _targetFighter.isAllowBeHit) && !_targetFighter.isSuperSteelBody;
               }
            }
         }
         if(_loc6_)
         {
            if(_isConting || _targetFighter && _targetFighter.actionState == 21)
            {
               if(_loc7_["order"])
               {
                  param5 += _loc7_["order"];
               }
               addContOrder(param1,param5);
            }
         }
         return _loc6_;
      }
      
      private function updateCatch() : void
      {
         if(updateAImainAction("catch"))
         {
            return;
         }
         if(_target == null || _targetFighter == null)
         {
            return;
         }
         catch1 = false;
         catch2 = false;
         if(FighterActionState.isHurting(_targetFighter.actionState) || _targetFighter.isSuperSteelBody || !_targetFighter.isAllowBeHit)
         {
            return;
         }
         var _loc2_:Object = {};
         var _loc3_:Object = {};
         var _loc1_:Point = getTargetDistance(_target);
         if(_loc1_.x < 50)
         {
            if(_justStandUp)
            {
               _loc2_.defult = [0,0.5,1,1,0.5,0.1];
               _loc2_[20] = [1,2,3,4,3,2];
               _loc2_[40] = [1,2,3,4,3,2];
               _loc3_.defult = [0,0.5,1,1,1.5,2];
               _loc3_[20] = [1,2,4,5,7,10];
               _loc3_[40] = [1,2,4,5,7,10];
            }
            else
            {
               _loc2_.defult = [0,0.5,1,3,1.5,0.5];
               _loc2_[20] = [1,2,3,2,1,0.5];
               _loc2_[40] = [1,2,3,2,1,0.5];
               _loc3_.defult = [0,0.5,1,3,5,8];
               _loc3_[20] = [1,2,4,5,7,10];
               _loc3_[40] = [1,2,4,5,7,10];
            }
         }
         else
         {
            _loc2_.defult = [0,0.5,1,0,0,0];
            _loc2_[20] = [1,2,3,4,3,2];
            _loc3_.defult = [0,0.5,1,0,0,0];
            _loc3_[20] = [1,2,3,4,3,2];
         }
         _loc2_[16] = [0.2,0.1,0,0,0,0];
         _loc2_[21] = [0.2,0.1,0,0,0,0];
         _loc3_[16] = [0.2,0.1,0,0,0,0];
         _loc3_[21] = [0.2,0.1,0,0,0,0];
         setAIByMain(_loc3_,"catch1");
         setAIByMain(_loc2_,"catch2");
         catch1 = targetCanBeHit() && getAIByFighterState(_loc3_);
         catch2 = !catch1 && targetCanBeHit() && getAIByFighterState(_loc2_);
      }
      
      private function updateSpecialSkill() : void
      {
         var _loc3_:Point = null;
         if(updateAImainAction("specialSkill"))
         {
            return;
         }
         specialSkill = false;
         if(_fighter.qi < 100)
         {
            return;
         }
         if(_fighter.actionState != 21)
         {
            return;
         }
         if(_target == null || _targetFighter == null)
         {
            return;
         }
         if(!FighterActionState.isAttacking(_targetFighter.actionState))
         {
            return;
         }
         var _loc1_:Array = _targetFighter.getCurrentHits();
         if(_loc1_ == null || _loc1_.length == 0)
         {
            return;
         }
         if(FighterComicType.isBleach(_fighter.data.comicType))
         {
            _loc3_ = getTargetDistance(_target);
            if(_loc3_.x > 80 || _loc3_.y > 80)
            {
               return;
            }
         }
         if(_targetFighter.actionState == 16)
         {
            return;
         }
         var _loc2_:Object = {};
         _loc2_.defult = [0.5,2,4,7,9,9.5];
         _loc2_[11] = [0.5,1.5,4,6,8,9];
         _loc2_[12] = [0.5,3,6,8,9.25,9.75];
         _loc2_[13] = [0.5,3,6,8,9.25,9.75];
         setAIByMain(_loc2_,"specialSkill");
         specialSkill = getAIByFighterState(_loc2_);
      }
      
      private function updateAssist() : void
      {
         var _loc2_:FighterMC = null;
         var _loc4_:Rectangle = null;
         if(updateAImainAction("assist"))
         {
            return;
         }
         assist = false;
         if(!_isFirstAssister)
         {
            _loc2_ = _fighter.getMC();
            _loc4_ = _loc2_.getHitRange("assistmian");
            if(_loc4_ != null && !_loc4_.isEmpty())
            {
               if(!targetInRange("assistmian"))
               {
                  return;
               }
            }
         }
         if(_fighter.actionState != 0 && _fighter.actionState != 20)
         {
            return;
         }
         if(FighterActionState.isHurtFlying(_targetFighter.actionState))
         {
            return;
         }
         if((_target.x - _fighter.x) * _fighter.direct <= 0)
         {
            return;
         }
         var _loc3_:Object = {};
         var _loc1_:Number = getTargetDistance(_target).x;
         if(_loc1_ <= 250)
         {
            _loc3_.defult = [0,0.5,1,1.5,2,2.5];
            _loc3_[20] = [0,0.5,1,1.75,2.5,3.5];
            _loc3_[21] = [0,0,0,0,0,0];
            _loc3_[22] = [0,0,0,0,0,0];
            _loc3_[23] = [0,0,0,0,0,0];
            _loc3_[24] = [0,0,0,0,0,0];
         }
         else
         {
            _loc3_.defult = [0,0.02,0.05,0.1,0.1,0.1];
         }
         setAIByMain(_loc3_,"assist");
         assist = getAIByFighterState(_loc3_);
         if(_isFirstAssister && assist)
         {
            _isFirstAssister = false;
         }
      }
      
      private function updateGhostStep() : void
      {
         var _loc1_:String = null;
         var _loc5_:Boolean = false;
         if(updateAImainAction("ghostStep"))
         {
            return;
         }
         var _loc4_:Object = null;
         var _loc2_:* = null;
         var _loc6_:Point = getTargetDistance(_target);
         ghostStep = ghostJump = ghostJumpDowm = false;
         var _loc3_:Object = {};
         if(_fighter.qi < 60)
         {
            return;
         }
         if(!_fighter.getCtrler() || !_fighter.getCtrler().getMcCtrl())
         {
            return;
         }
         if(_fighter.isSteelBody || !_fighter.isAllowBeHit || !_fighter.getBodyArea())
         {
            return;
         }
         _loc4_ = {};
         _loc3_[21] = _loc3_[22] = _loc3_[23] = _loc3_[24] = _loc3_[30] = [0,0,0,0,0,0];
         _loc4_[21] = _loc4_[22] = _loc4_[23] = _loc4_[24] = _loc4_[30] = [0,0,0,0,0,0];
         if((_isConting || _fighter.actionState == 40) && _loc6_.x < 100 && _loc6_.x > -100 && _loc6_.y < 100 && _loc6_.y > -100 && _fighter.isAllowBeHit == true)
         {
            _loc1_ = _fighter.getCtrler().getMcCtrl().getCurAction();
            _loc5_ = _attackAction[_loc1_] && !targetInRange(_attackAction[_loc1_]);
            if(_loc5_)
            {
               _loc3_.defult = [0,0,0,0.1,0.1,0.5];
               _loc4_.defult = [0,0,0,0.1,0.1,0.1];
               if(_fighter.actionState == 40)
               {
                  _loc3_[0] = [0,0,0.1,0.3,0.75,1.5];
                  _loc3_[10] = _loc3_[11] = _loc3_[12] = _loc3_[13] = [0,0,0.1,0.3,0.75,2];
                  _loc4_[10] = _loc4_[11] = _loc4_[12] = _loc4_[13] = [0,0,0.1,0.06,0.03,0.1];
               }
               else
               {
                  _loc3_[10] = _loc3_[11] = _loc3_[12] = _loc3_[13] = [0,0,0.1,0.2,0.5,1.5];
                  _loc4_[10] = _loc4_[11] = _loc4_[12] = _loc4_[13] = [0,0,0.1,0.06,0.03,0.1];
               }
               setAIByMain(_loc3_,"ghostStep");
               setAIByMain(_loc4_,"ghostJump");
               ghostStep = getAIByFighterState(_loc3_);
               ghostJump = !ghostStep && getAIByFighterState(_loc4_);
            }
         }
      }
   }
}

