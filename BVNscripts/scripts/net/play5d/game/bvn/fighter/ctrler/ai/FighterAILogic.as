package net.play5d.game.bvn.fighter.ctrler.ai
{
   import flash.geom.Point;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.fighter.*;
   
   public class FighterAILogic extends FighterAILogicBase
   {
      
      public var moveLeft:Boolean;
      
      public var moveRight:Boolean;
      
      public var jump:Boolean;
      
      public var jumpDown:Boolean;
      
      public var dash:Boolean;
      
      public var downJump:Boolean;
      
      public var defense:Boolean;
      
      private var _moveKeep:Number = 40;
      
      private var _catchMoveKeep:Number = 15;
      
      private var _dashKeep:Number = 250;
      
      private var _dashInKeep:Number = 75;
      
      private var _jumpKeep:Number = 300;
      
      private var _jumpDownKeep:Number = 50;
      
      /**
       * ===== CRAZY（AI 等级 ≥7）专属难度参数 =====
       *
       * 取值基准：BVN 3.7 扩展版参考工程 Shonen-Clash-main 的最难档
       * （其设置菜单最高只到 HELL，即 getAIResult 的第 6 档 param6）。
       *
       * 取值规则：逐项取"主项目 HELL"与"参考工程 HELL"中更激进的一侧，使"疯狂"严格强于
       * "地狱"。因此下面各项有的是从主项目的保守值放宽到参考值（如 _crazyBishaQi 200→100、
       * _crazyJumpKeep 300→50、_crazyDefenseReact 125→200），有的是刻意高于参考值
       * （如 _crazyBishaSuperOrder 取 210 而非参考的 200，以同时盖过本工程普通必杀的 115）。
       * 不含"逐项一律高于参考"的含义。
       *
       * 注意：等级 1~6（含 HELL）不读取这些字段；概率表没补第 7 列时 CRAZY 也回落
       * 到 HELL 的取值（见 FighterAILogicBase.getAIResult）。所以 HELL 及以下行为不变。
       */
      private var _crazyDashKeep:Number = 200;
      
      private var _crazyDashEnergy:Number = 40;
      
      private var _crazyJumpKeep:Number = 50;
      
      private var _crazyBishaQi:int = 100;
      
      private var _crazyBishaSuperOrder:int = 210;
      
      private var _crazyDefenseReact:Number = 200;
      
      private var _crazyDefenseFarRate:Number = 1;
      
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
      
      public var ghostStep:Boolean;
      
      public var ghostJump:Boolean;
      
      public var ghostJumpDowm:Boolean;
      
      private var _attackAction:Object = {
         "招1":"zh1mian",
         "砍1":"kanmian",
         "招2":"zh2mian",
         "招3":"zh3mian",
         "砍技1":"kj1mian",
         "砍技2":"kj2mian",
         "跳砍":"tzmian",
         "跳招":"tkanmian"
      };
      
      private var _moveFrame:int;
      
      private var _defenseFrame:int;
      
      private var _hasSetColor:Boolean = false;
      
      public function FighterAILogic(param1:int, param2:*)
      {
         super(param1,param2);
      }
      
      override public function render() : void
      {
         super.render();
         if(!_fighter || !_target)
         {
            return;
         }
         this.updateHurtAI();
         this.updateGhostStep();
         if(Boolean(AImain.afterRender))
         {
            AImain.afterRender();
         }
      }
      
      override protected function updateActionAI() : void
      {
         if(!_fighter || !_target)
         {
            return;
         }
         this.updateAImain();
         this.updateDashAI();
         this.updateAttackAI();
         this.updateSkill();
         this.updateBisha();
         this.updateCache();
         this.updateAssist();
         this.updateMoveAI();
         this.updateJumpAI();
         this.updateJumpDownAI();
         this.updateDefenseAI();
         this.updateSpecialSkill();
      }
      
      private function updateAImain() : void
      {
         if(!AImain)
         {
            return;
         }
         if(Boolean(AImain.init) && !AImain.inited)
         {
            AImain.init(this.setAIAction,addContOrder,getAIByFighterState);
         }
         if(Boolean(AImain.preRender))
         {
            AImain.preRender();
         }
      }
      
      private function setAIAction(param1:String, param2:Boolean = true) : void
      {
         this[param1] = param2;
      }
      
      private function updateAImainAction(param1:String) : Boolean
      {
         if(!AImain || !AImain.updateActionAI)
         {
            return false;
         }
         return AImain.updateActionAI(param1);
      }
      
      private function updateHurtAI() : void
      {
         if(this.updateAImainAction("hurt"))
         {
            return;
         }
         this.downJump = false;
         if(_fighter.energy <= 60 || Boolean(_fighter.energyOverLoad))
         {
            return;
         }
         var _loc1_:Object = {};
         _loc1_["defult"] = [0,0,0.2,1,3,5];
         _loc1_[11] = [0,0,0,0,0,0];
         _loc1_[12] = _loc1_[13] = [0,0,0,0,0,0];
         setAIByMain(_loc1_,"downJump");
         this.downJump = getAIByFighterState(_loc1_);
      }
      
      private function updateMoveAI() : void
      {
         var tMove:Boolean = false;
         if(this.updateAImainAction("move"))
         {
            return;
         }
         var _loc2_:Boolean = false;
         var _loc3_:Boolean = false;
         var _loc4_:* = null;
         var _loc5_:Boolean = false;
         var _loc6_:* = NaN;
         this.moveLeft = false;
         this.moveRight = false;
         if(Boolean(_targetFighter) && (_targetFighter.actionState == 22 || _targetFighter.actionState == 23 || _targetFighter.actionState == 24))
         {
            return;
         }
         var _loc7_:* = _fighter.actionState == 20;
         if(Boolean(_loc7_))
         {
            _loc2_ = getAIResult(1,2,4,5,6,8);
            if(_loc2_)
            {
               if(_fighter.x > _target.x + 20)
               {
                  this.moveLeft = true;
               }
               if(_fighter.x < _target.x - 20)
               {
                  this.moveRight = true;
               }
            }
            return;
         }
         if(this._moveFrame < GameConfig.FPS_GAME)
         {
            ++this._moveFrame;
            _loc3_ = true;
         }
         else
         {
            _loc4_ = {};
            _loc4_["defult"] = [3,5,7,8,9,10];
            _loc4_[10] = [2,4,5,3,1,9];
            _loc4_[11] = [2,4,3,2,0,9];
            _loc4_[12] = _loc4_[13] = [2,1,0,0,0,9];
            setAIByMain(_loc4_,"move");
            _loc3_ = getAIByFighterState(_loc4_);
            if(_loc3_)
            {
               this._moveFrame = 0;
            }
         }
         if(_loc3_)
         {
            _loc5_ = (this.catch1 || this.catch2) && Math.abs(_fighter.y - _target.y) < 2;
            _loc6_ = _loc5_ ? this._catchMoveKeep : Number(this._moveKeep);
            if(_fighter.x > _target.x + _loc6_)
            {
               this.moveLeft = true;
            }
            if(_fighter.x < _target.x - _loc6_)
            {
               this.moveRight = true;
            }
         }
         if(!this.moveLeft && !this.moveRight)
         {
            this._moveFrame = GameConfig.FPS_GAME;
         }
         if(Boolean(_targetFighter) && Boolean(_targetFighter.isSteelBody))
         {
            tMove = this.moveLeft;
            this.moveLeft = this.moveRight;
            this.moveRight = tMove;
         }
      }
      
      private function updateJumpAI() : void
      {
         if(this.updateAImainAction("jump"))
         {
            return;
         }
         var _loc1_:Object = {};
         // CRAZY 档把"起跳追击"的落差门槛从 300 降到参考工程 HELL 的 50。
         // 判据是 `_fighter.y > _target.y + jumpKeep`，Flash 里 y 向下为正，
         // 即"自己在目标下方且落差够大"时起跳追上去。主项目 300 在原版关卡尺寸下
         // 几乎不可能满足，对空中的上方目标等于不起跳。
         var jumpKeep:Number = this.isCrazy ? this._crazyJumpKeep : Number(this._jumpKeep);
         if(_isConting)
         {
            _loc1_["defult"] = [1,2,3,2,1,0];
            _loc1_[21] = [0,1,2,3,3,4];
         }
         else if(_fighter.y > _target.y + jumpKeep || _fighter.y > _target.y + this._jumpDownKeep && _target.isInAir == false)
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
         this.jump = getAIByFighterState(_loc1_);
         if(_isConting && this.jump)
         {
            if(Boolean(_loc1_["order"]))
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
         if(this.updateAImainAction("jumpDown"))
         {
            return;
         }
         var _loc1_:Object = {};
         if(_fighter.y < _target.y - this._jumpDownKeep)
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
         this.jumpDown = getAIByFighterState(_loc1_);
      }
      
      private function updateDashAI() : void
      {
         if(this.updateAImainAction("dash"))
         {
            return;
         }
         var _loc1_:Object = {};
         var _loc2_:Number = getTargetDistance(_target).x;
         var _loc3_:Number = _target.x > _fighter.x ? 1 : -1;
         var _loc4_:Boolean = false;
         // CRAZY 档取参考工程 HELL 的冲刺门槛：远距离冲刺触发距离 250→200、
         // 允许走"气够"冲刺分支的 energy（防御 / 受身槽，见 FighterMain.useEnergy）
         // 下限 60→40（参考工程也是 40）。energy 低于该值时进保守分支、远距冲刺概率为 0。
         // 刻意只在这里取局部值，不动 _dashKeep 字段本身 —— updateAssist() 也在读它。
         var dashKeep:Number = this.isCrazy ? this._crazyDashKeep : Number(this._dashKeep);
         var dashEnergy:Number = this.isCrazy ? this._crazyDashEnergy : 60;
         if(Boolean(_targetFighter) && (_targetFighter.actionState == 22 || _targetFighter.actionState == 23 || _targetFighter.actionState == 24))
         {
            this.dash = false;
            return;
         }
         if(!_fighterAction.dash)
         {
            this.dash = false;
            return;
         }
         if(_fighter.actionState >= 10 && _fighter.actionState <= 13)
         {
            _loc1_["defult"] = [0,0,0.2,0.5,2,8];
            _loc1_[21] = [0,0,0.1,0.5,0,0];
            _loc4_ = true;
         }
         else if(_fighter.energy < dashEnergy)
         {
            if(_loc2_ > dashKeep && _fighter.direct == _loc3_)
            {
               _loc1_["defult"] = [0,0,0.1,0.5,0,0];
               _loc1_[10] = _loc1_[11] = [0,0.05,0.3,1,1.7,2.5];
               _loc1_[12] = _loc1_[13] = [0,0,0,0,0,0];
            }
            else if(_loc2_ < this._dashInKeep && _fighter.energy > 20 && !_fighter.energyOverLoad && getTargetDistance(_target).y <= 75)
            {
               _loc1_["defult"] = [0,0,0.05,1,1.5,2.5];
               _loc1_[10] = [0.5,1,1.5,2.5,3,4.5];
               _loc1_[11] = [0.5,1,1.5,2.5,3,4.5];
               _loc1_[12] = _loc1_[13] = [0.5,1,1.5,2.5,3,4.5];
               _loc1_[21] = [0,0,0.1,0,0,0];
               _loc4_ = true;
            }
            else
            {
               _loc1_["defult"] = [0,0,0.05,0,0,0];
               _loc1_[10] = _loc1_[11] = _loc1_[12] = _loc1_[13] = [0,0,0,0,0,0];
            }
         }
         else if(_loc2_ > dashKeep && _fighter.direct == _loc3_)
         {
            // 第 7 列 = CRAZY：远距离面向目标时冲刺概率 5.5 → 9（参考工程 HELL 取值）
            _loc1_["defult"] = [0.5,1,1.5,2.5,4,5.5,9];
            _loc1_[10] = [0,0,0.1,3,2,1];
            _loc1_[11] = [0,0,0.05,1,1.5,2];
            _loc1_[12] = _loc1_[13] = [0,0,0,0,0,0];
            _loc1_[21] = [0,0,0.1,0,0,0];
         }
         else if(_loc2_ < this._dashInKeep && getTargetDistance(_target).y <= 75)
         {
            _loc1_["defult"] = [0,0,0.05,1,1.5,2.5];
            _loc1_[10] = [0.5,1,1.5,2.5,4,5.5];
            _loc1_[11] = [0.5,1,1.5,2.5,4,5.5];
            _loc1_[12] = _loc1_[13] = [0.5,1,1.5,2.5,4,5.5];
            _loc1_[21] = [0,0,0.1,0,0,0];
            _loc4_ = true;
         }
         else
         {
            _loc1_["defult"] = [0,0,0.05,0.1,0,0];
            _loc1_[10] = _loc1_[11] = _loc1_[12] = _loc1_[13] = [0,0,0,0,0,0];
         }
         setAIByMain(_loc1_,"dash");
         this.dash = getAIByFighterState(_loc1_);
         if(_loc4_)
         {
            if(Boolean(_loc1_["order"]))
            {
               addContOrder("dash",114 + _loc1_["order"]);
            }
            else
            {
               addContOrder("dash",114);
            }
         }
      }
      
      private function updateDefenseAI() : void
      {
         var _loc1_:Object = null;
         var _loc2_:* = undefined;
         if(this.updateAImainAction("defense"))
         {
            return;
         }
         var _loc3_:* = null;
         var _loc4_:* = null;
         var _loc5_:* = null;
         // CRAZY 档对"子弹 / 攻击体 / 助战"的防御反应距离 125 → 200（参考工程 HELL 用 200，
         // 且对攻击体与助战不做距离判定）。这里保留距离分层，但远距概率 0.2 → 1。
         // farRate 作为 getAIResult 的第 7 个实参传入（第 6 位保留 HELL 的 0.2 字面量），
         // 不依赖 param7=NaN 的回落通道 —— 否则将来一旦有人动那条回落规则，
         // CRAZY 的远距防御率会静默退回 0.2 且没有任何提示。
         // 注意：上面 energy<=20 / 钢身 直接不防御的判定是有意保留的正确逻辑
         // （energy 是防御 / 受身槽，见 FighterMain.useEnergy 与 energyOverLoad，
         // 槽空再防会直接破防），参考工程没有这个保护，属于更差而非更难，故不照搬。
         var reactDist:Number = this.isCrazy ? this._crazyDefenseReact : 125;
         var farRate:Number = this.isCrazy ? this._crazyDefenseFarRate : 0.2;
         if(_fighter.energy <= 20 || _fighter.isSteelBody == true)
         {
            this.defense = false;
            return;
         }
         if(this.defense)
         {
            _loc3_ = {};
            _loc3_["defult"] = [10,10,10,10,10,10];
            _loc3_[40] = [5,4,4,3,2,1];
            _loc3_[0] = [2,1,1,0,0,0];
            _loc3_[21] = [0,0,0,0,0,0];
            _loc3_[22] = [0,0,0,0,0,0];
            _loc3_[23] = [0,0,0,0,0,0];
            setAIByMain(_loc3_,"defensing");
            this.defense = getAIByFighterState(_loc3_);
            if(this.defense)
            {
               this.doInDefense(_loc3_,119);
               return;
            }
         }
         var _loc6_:Point = getTargetDistance(_target);
         _loc1_ = {};
         _loc1_["defult"] = [0,0,0,0,0,0];
         if(_fighter.qi <= 10)
         {
            _loc1_[10] = _loc1_[11] = [1,2,3,2,1,0.5];
            _loc1_[12] = _loc1_[13] = [2,3,3.5,4,5,6.5];
         }
         else
         {
            if(_loc6_.x < 100 && _loc6_.y < 100)
            {
               _loc1_[10] = [0.5,1,3,5,7,9];
            }
            else
            {
               _loc1_[10] = [0.5,1,3,2,1,0];
            }
            _loc1_[11] = [1,2.5,4,6,8,9.5];
            _loc1_[12] = _loc1_[13] = [2,4,6,8,10,10];
         }
         setAIByMain(_loc1_,"defense");
         this.defense = getAIByFighterState(_loc1_);
         if(this.defense)
         {
            this.doInDefense(_loc1_,120);
            return;
         }
         var _loc7_:Vector.<*> = _fighter.getTargets();
         for each(_loc2_ in _loc7_)
         {
            if(_loc2_ != _target)
            {
               if(_loc2_ is Bullet && Boolean((_loc2_ as Bullet).isAttacking()))
               {
                  _loc5_ = getTargetDistance(_loc2_);
                  if(_loc5_.x < reactDist && _loc5_.y < reactDist)
                  {
                     this.defense = getAIResult(2,4,5,7,9,10);
                  }
                  else
                  {
                     this.defense = getAIResult(2,4,2,1,0.5,0.2,farRate);
                  }
                  if(this.defense)
                  {
                     this.doInDefense(_loc1_,115);
                     return;
                  }
               }
               if(_loc2_ is FighterAttacker && Boolean((_loc2_ as FighterAttacker).isAttacking))
               {
                  _loc5_ = getTargetDistance(_loc2_);
                  if(_loc5_.x < reactDist && _loc5_.y < reactDist)
                  {
                     this.defense = getAIResult(2,4,5,7,9,10);
                  }
                  else
                  {
                     this.defense = getAIResult(2,4,2,1,0.5,0.2,farRate);
                  }
                  if(this.defense)
                  {
                     this.doInDefense(_loc1_,120);
                     return;
                  }
               }
               if(_loc2_ is Assister && Boolean((_loc2_ as Assister).isAttacking))
               {
                  _loc5_ = getTargetDistance(_loc2_);
                  if(_loc5_.x < reactDist && _loc5_.y < reactDist)
                  {
                     this.defense = getAIResult(2,4,5,7,9,10);
                  }
                  else
                  {
                     this.defense = getAIResult(2,4,2,1,0.5,0.2,farRate);
                  }
                  if(this.defense)
                  {
                     this.doInDefense(_loc1_,120);
                     return;
                  }
               }
            }
         }
      }
      
      private function doInDefense(param1:Object = null, param2:int = 115) : void
      {
         if(Boolean(param1) && Boolean(param1["order"]))
         {
            addContOrder("defense",param2 + param1["order"]);
         }
         else
         {
            addContOrder("defense",param2);
         }
         if(_target.x < _fighter.x)
         {
            this.moveLeft = true;
            this.moveRight = false;
         }
         else
         {
            this.moveLeft = false;
            this.moveRight = true;
         }
      }
      
      private function updateAttackAI() : void
      {
         var _loc7_:Boolean = Boolean(this.updateAImainAction("attack"));
         if(_loc7_)
         {
            return;
         }
         var _loc2_:* = null;
         this.attack = false;
         this.attackAIR = false;
         if(!_fighterAction.attack && !_fighterAction.attackAIR)
         {
            return;
         }
         // CRAZY 档补上参考工程 HELL 的命中守卫：目标处于无敌 / 不可命中帧时不出手，
         // 把出招机会留给真正能打中的时机（主项目原先没有这个判断，会对着无敌帧空挥）。
         // 用 canHitTarget() 而不是 targetCanBeHit()：后者在目标退化为 Bullet 时
         // 会因缺少 FighterMain 类型转换而恒为 false，详见 FighterAILogicBase.canHitTarget()。
         if(this.isCrazy && !canHitTarget())
         {
            return;
         }
         var _loc3_:Object = {};
         _loc3_.defult = _isConting ? [1,2,3,6,9,10] : [0.5,1,4,6,8,10];
         _loc3_[20] = _isConting ? [1,2,3,6,9,9] : [0.5,1,3,2,2,1];
         _loc3_[16] = [0.5,1,1,0.5,0,0];
         _loc3_[10] = [0.5,1,1,0,3,10];
         _loc3_[11] = [0,0,0,0,3,10];
         _loc3_[12] = _loc3_[13] = [0,0,0.1,0,0,0];
         _loc3_[21] = [10,10,10,10,10,10];
         if(Boolean(_fighterAction.attack))
         {
            setAIByMain(_loc3_,"attack");
         }
         if(Boolean(_fighterAction.attackAIR))
         {
            setAIByMain(_loc3_,"attackAIR");
         }
         var _loc4_:Boolean = getAIByFighterState(_loc3_);
         if(!_loc4_)
         {
            return;
         }
         var _loc5_:int = 100;
         if(_isConting)
         {
            this.attack = true;
            this.attackAIR = true;
            _loc2_ = _fighter.getCtrler().getMcCtrl().getCurAction();
            if(_loc2_ == "砍1")
            {
               _loc5_ = 200;
            }
            else if(!!_targetFighter && _targetFighter.actionState == 21)
            {
               _loc5_ = 114;
            }
            else
            {
               this.attack = targetInRange("kanmian");
               this.attackAIR = targetInRange("tkanmian");
               _loc5_ = 300;
            }
         }
         else
         {
            this.attack = targetInRange("kanmian");
            this.attackAIR = targetInRange("tkanmian");
            _loc5_ = 116;
         }
         if(Boolean(_loc3_["order"]))
         {
            _loc5_ += _loc3_["order"];
         }
         if(this.attack && Boolean(_fighterAction.attack))
         {
            addContOrder("attack",_loc5_);
         }
         if(this.attackAIR && Boolean(_fighterAction.attackAIR))
         {
            addContOrder("attackAIR",_loc5_);
         }
      }
      
      private function updateSkill() : void
      {
         this.skill1 = Boolean(_fighterAction.skill1) && Boolean(this.getSkillAI("skill1","kj1","kj1mian",10));
         this.skill2 = Boolean(_fighterAction.skill2) && Boolean(this.getSkillAI("skill2","kj2","kj2mian",10));
         this.zhao1 = Boolean(_fighterAction.zhao1) && Boolean(this.getSkillAI("zhao1","zh1","zh1mian",10));
         this.zhao2 = Boolean(_fighterAction.zhao2) && Boolean(this.getSkillAI("zhao2","zh2","zh2mian",10));
         this.zhao3 = Boolean(_fighterAction.zhao3) && Boolean(this.getSkillAI("zhao3","zh3","zh3mian",10));
         this.skillAIR = Boolean(_fighterAction.skillAIR) && Boolean(this.getSkillAI("skillAIR","tz","tzmian",10));
      }
      
      private function getSkillAI(param1:String, param2:String, param3:String, param4:int) : Boolean
      {
         if(this.updateAImainAction(param1))
         {
            return this[param1];
         }
         // CRAZY 档补上参考工程 HELL 的命中守卫（同上，用修正版 canHitTarget()）。
         if(this.isCrazy && !canHitTarget())
         {
            return false;
         }
         var _loc5_:Object = {};
         var _loc6_:Boolean = false;
         if(isBreakAct(param2))
         {
            _loc5_.defult = _isConting ? [0.1,0.2,0.5,3,6,10] : [0,0.2,0.5,2,1,0.5];
            _loc5_[20] = _isConting ? [0,0.2,0.7,5,7,9] : [0.1,0.2,0.5,1,2,2];
         }
         else
         {
            _loc5_.defult = _isConting ? [0,0,0.1,1,5,10] : [0.1,0.5,1,3,1.5,1];
            _loc5_[20] = [0,0,1,1,0,0.5];
         }
         _loc5_[16] = [0.5,1,0.5,0,0,0];
         _loc5_[10] = [0,0,0,1,1,2];
         _loc5_[11] = _loc5_[12] = _loc5_[13] = [0,0,0,0,0.5,1];
         setAIByMain(_loc5_,param1);
         _loc6_ = getAIByFighterState(_loc5_) && targetInRange(param3);
         if(_loc6_)
         {
            if(_isConting || !!_targetFighter && _targetFighter.actionState == 21)
            {
               if(Boolean(_loc5_["order"]))
               {
                  param4 += _loc5_["order"];
               }
               // CRAZY 档引入参考工程 HELL 的"击倒技"区分：isHitDownAct 为真（hurtType==1，
               // 会把对手击倒、直接断掉连招）的技能只拿低优先级 param4，普通技能拿 param4+100。
               // 注意 _contOrder 用 sortOn("order", 2 | 0x10)：2 = DESCENDING、0x10 = NUMERIC，
               // 即 order 越大越优先、只有该帧 order 最大的那个动作能留下 —— 所以这里是
               // 让击倒技给同帧的普通技能让路，而不是给它加优先级（方向别写反）。
               addContOrder(param1,param4 + (this.isCrazy && isHitDownAct(param2) ? 0 : 100));
            }
         }
         return _loc6_;
      }
      
      public function updateBisha() : void
      {
         // CRAZY 档必杀气量门槛 200 → 100：参考工程最难档（HELL）就是 100，
         // 主项目要攒到 200 才肯放必杀，实战里几乎攒不满；超必杀仍需 300，不动。
         var bishaQi:int = this.isCrazy ? this._crazyBishaQi : 200;
         // CRAZY 档把超必杀的 cont 优先级 100 → 210。
         // 参考工程的最难档里 bishaSUPER = 200、bishaAIR = 210；这里取 210 是为了同时高于
         // 本工程的普通必杀 115，_contOrder 用 sortOn("order", 2 | 0x10)（降序 + 数值），
         // order 越大越优先。原值 100 低于普通必杀的 115，同帧两招同时掷中时超必杀必被顶掉。
         var superOrder:int = this.isCrazy ? this._crazyBishaSuperOrder : 100;
         this.bisha = Boolean(_fighterAction.bisha) && Boolean(this.getBishaAI("bisha","bs","bsmian",bishaQi,115));
         this.bishaUP = Boolean(_fighterAction.bishaUP) && Boolean(this.getBishaAI("bishaUP","sbs","sbsmian",bishaQi,115));
         this.bishaSUPER = Boolean(_fighterAction.bishaSUPER) && Boolean(this.getBishaAI("bishaSUPER","cbs","cbsmian",300,superOrder));
         this.bishaAIR = Boolean(_fighterAction.bishaAIR) && Boolean(this.getBishaAI("bishaAIR","kbs","kbsmian",bishaQi,115));
      }
      
      private function getBishaAI(param1:String, param2:String, param3:String, param4:int, param5:int) : Boolean
      {
         if(this.updateAImainAction(param1))
         {
            return this[param1];
         }
         // CRAZY 档补上参考工程 HELL 的命中守卫（同上，用修正版 canHitTarget()）。
         // 必杀要花 100~300 气，是最不能空挥的一招，所以这个守卫对必杀尤其重要。
         if(this.isCrazy && !canHitTarget())
         {
            return false;
         }
         var _loc6_:Object = {};
         var _loc7_:Boolean = false;
         if(_fighter.qi >= param4)
         {
            if(isBreakAct(param2))
            {
               _loc6_.defult = _isConting ? [0,0,0.3,2,5,10] : [0.1,0.2,0.5,2,2,2];
               _loc6_[20] = _isConting ? [0,0,0.5,3,7,9] : [0.1,0.2,1,6,8,10];
               _loc6_[21] = [0.2,0.5,1,3,5,8];
            }
            else
            {
               _loc6_.defult = _isConting ? [0,0,0.5,4,8,10] : [0.2,0.5,1,2,2,0];
               _loc6_[21] = [0.2,0.5,1,3,5,6];
               _loc6_[14] = [0.2,0.5,1,3,4,4];
               _loc6_[20] = _isConting ? [0.2,0.5,1,3,2,1] : [0.2,0.5,1,2,1,0];
            }
            _loc6_[16] = [0.2,0.5,0,0,0,0];
            _loc6_[10] = [0,0.2,0.5,2,1,1];
            _loc6_[11] = _loc6_[12] = _loc6_[13] = [0,0,0.1,0,0,0];
            _loc6_[0] = [0,0,0.1,0,0.01,0.02];
            setAIByMain(_loc6_,param1);
            _loc7_ = getAIByFighterState(_loc6_) && targetInRange(param3);
            // CRAZY 档不套"终结过滤"：主项目这段判定要求（目标气<100 / 防御槽<30 且已破防 /
            // 可破防 / 本次受击累计伤害>210）之一成立才肯放必杀，实战里几乎不成立，
            // 等于把必杀整条链路锁死。参考工程最难档没有这层过滤 —— 命中框已经压在
            // 目标身上（上面的 targetInRange 已过）就直接出手。
            if(!this.isCrazy && _loc7_ && Boolean(_targetFighter))
            {
               if(_targetFighter.actionState == 21)
               {
                  _loc7_ = _targetFighter.qi < 100 || _targetFighter.energy < 30 && _targetFighter.energyOverLoad == true || Boolean(_targetFighter.hurtBreakHit()) || _targetFighter.currentHurtDamage() > 210;
               }
               else
               {
                  _loc7_ = _targetFighter.energy < 20 && _targetFighter.energyOverLoad == true && !_targetFighter.isSuperSteelBody;
               }
            }
         }
         if(_loc7_)
         {
            if(_isConting || !!_targetFighter && _targetFighter.actionState == 21)
            {
               if(Boolean(_loc6_["order"]))
               {
                  param5 += _loc6_["order"];
               }
               addContOrder(param1,param5);
            }
         }
         return _loc7_;
      }
      
      private function updateCache() : void
      {
         if(this.updateAImainAction("catch"))
         {
            return;
         }
         this.catch1 = false;
         this.catch2 = false;
         var _loc1_:Object = {};
         var _loc2_:Object = {};
         if(Boolean(_targetFighter) && (_targetFighter.actionState == 21 || _targetFighter.actionState == 22 || _targetFighter.actionState == 23))
         {
            return;
         }
         var _loc3_:Point = getTargetDistance(_target);
         if(_loc3_.x < 50)
         {
            _loc1_.defult = [0,0.5,1,3,1.5,0.5];
            _loc1_[20] = _loc1_[40] = [1,2,3,4,3,2];
            _loc2_.defult = [0,0.5,1,3,5,8];
            _loc2_[20] = _loc1_[40] = [1,2,4,5,7,10];
         }
         else
         {
            _loc1_.defult = [0,0.5,1,0,0,0];
            _loc1_[20] = [1,2,3,4,3,2];
            _loc2_.defult = [0,0.5,1,0,0,0];
            _loc2_[20] = [1,2,3,4,3,2];
         }
         _loc1_[16] = [0.2,0.1,0,0,0,0];
         _loc1_[21] = [0.2,0.1,0,0,0,0];
         _loc2_[16] = [0.2,0.1,0,0,0,0];
         _loc2_[21] = [0.2,0.1,0,0,0,0];
         setAIByMain(_loc2_,"catch1");
         setAIByMain(_loc1_,"catch2");
         this.catch1 = getAIByFighterState(_loc2_) && targetCanBeHit();
         this.catch2 = getAIByFighterState(_loc1_) && targetCanBeHit();
      }
      
      private function updateSpecialSkill() : void
      {
         if(this.updateAImainAction("specialSkill"))
         {
            return;
         }
         var _loc1_:* = null;
         this.specialSkill = false;
         if(_fighter.actionState == 21 && (!_targetFighter || _targetFighter.actionState < 21 || _targetFighter.actionState > 30))
         {
            _loc1_ = {};
            _loc1_.defult = [0.5,2,4,7,9,9.5];
            _loc1_[11] = [0.5,1.5,4,6,8,9];
            _loc1_[12] = _loc1_[13] = [0.5,3,6,8,9.25,9.75];
            setAIByMain(_loc1_,"specialSkill");
            this.specialSkill = getAIByFighterState(_loc1_);
         }
      }
      
      private function updateAssist() : void
      {
         if(this.updateAImainAction("assist"))
         {
            return;
         }
         var _loc1_:Object = {};
         var _loc2_:Number = getTargetDistance(_target).x;
         this.assist = false;
         if(_fighter.actionState != 0)
         {
            return;
         }
         if(Boolean(_targetFighter) && (_targetFighter.actionState == 22 || _targetFighter.actionState == 23 || _targetFighter.actionState == 24))
         {
            return;
         }
         if(_loc2_ <= this._dashKeep)
         {
            _loc1_.defult = [0,0.5,1,1.5,2,2.5];
            _loc1_[20] = [0,0.5,1,1.75,2.5,3.5];
            _loc1_[21] = _loc1_[22] = _loc1_[23] = _loc1_[24] = [0,0,0,0,0,0];
         }
         else
         {
            _loc1_.defult = [0,0.02,0.05,0.1,0.3,0.5];
         }
         setAIByMain(_loc1_,"assist");
         this.assist = getAIByFighterState(_loc1_);
      }
      
      private function updateGhostStep() : void
      {
         var isnInRange:Boolean = false;
         var i:String = null;
         if(this.updateAImainAction("ghostStep"))
         {
            return;
         }
         var _loc3_:* = null;
         var _loc4_:* = null;
         var _loc5_:Point = getTargetDistance(_target);
         this.ghostStep = this.ghostJump = this.ghostJumpDowm = false;
         var _loc6_:Object = {};
         if(_fighter.qi < 60)
         {
            return;
         }
         if(!_fighter.getCtrler() || !_fighter.getCtrler().getMcCtrl())
         {
            return;
         }
         _loc3_ = {};
         _loc6_[21] = _loc6_[22] = _loc6_[23] = _loc6_[24] = _loc6_[30] = [0,0,0,0,0,0];
         _loc3_[21] = _loc3_[22] = _loc3_[23] = _loc3_[24] = _loc3_[30] = [0,0,0,0,0,0];
         if((_isConting || _fighter.actionState == 40) && _loc5_.x < 100 && _loc5_.x > -100 && _loc5_.y < 100 && _loc5_.y > -100 && (_target.x - _fighter.x) * _target.direct <= 0 && _fighter.isAllowBeHit == true)
         {
            isnInRange = false;
            for(i in this._attackAction)
            {
               if(_fighter.getCtrler().getMcCtrl().getCurAction() == i)
               {
                  if(!targetInRange(this._attackAction[i]))
                  {
                     isnInRange = true;
                  }
                  break;
               }
            }
            if(isnInRange)
            {
               _loc6_.defult = [0,0,0,0.1,0.1,0.1];
               _loc3_.defult = [0,0,0,0.1,0.1,0.01];
               if(_fighter.actionState == 40)
               {
                  _loc6_[10] = _loc6_[11] = _loc6_[12] = _loc6_[13] = [0,0,0.1,0.3,0.7,1.25];
                  _loc3_[10] = _loc3_[11] = _loc3_[12] = _loc3_[13] = [0,0,0.1,0.06,0.03,0.01];
               }
               else
               {
                  _loc6_[10] = _loc6_[11] = _loc6_[12] = _loc6_[13] = [0,0,0.1,0.2,0.5,1];
                  _loc3_[10] = _loc3_[11] = _loc3_[12] = _loc3_[13] = [0,0,0.1,0.06,0.03,0.01];
               }
               setAIByMain(_loc6_,"ghostStep");
               setAIByMain(_loc3_,"ghostJump");
               this.ghostStep = getAIByFighterState(_loc6_);
               this.ghostJump = getAIByFighterState(_loc3_) && !this.ghostStep;
               // 修死代码：ghostJumpDowm 在 updateGhostStep 里只有开头那句 = false，
               // 全方法没有任何赋值点，FighterAICtrl.ghostJumpDown() 因此恒为 false。
               // 3.7 参考工程与 3.9 官方版同样存在该缺陷（那边写作
               // _target.y - _fighter.y < 80 && _target.y - _fighter.y > 100，数学上不可能成立）。
               // 这里按"残影步三个变体各管一个方向"的原始意图补判据：目标明显在下方时
               // 改走残影步下跳（doGhostJumpDown 是 move(0,15)，即向下；上跳变体是 move(0,-12)）。
               //
               // 必须带上 isInAir：FighterMcCtrler 在 :724 按 isInAir / _doingAirAction
               // 分派到 renderFloorAction(:777) 或 renderAirAction(:989)，而
               // ghostJumpDown 只在 renderAirAction 的 :1071 被消费，地面路径
               // (:870/:874) 只消费 ghostStep / ghostJump。
               // 若在地面也把 ghostJump 清掉换成 ghostJumpDowm，只会白丢一次残影步上跳。
               // 仅在 CRAZY 档生效，HELL 及以下行为保持不变。
               //
               // 量级提示：本判据复用的是 ghostJump 同一掷骰（_loc3_ 表的 CRAZY 列没补，
               // 回落 param6 = 0.01，约 1%/帧），所以它是个低频修正，别当成明显提升。
               if(this.isCrazy && this.ghostJump && Boolean(_fighter.isInAir) && _fighter.y < _target.y - this._jumpDownKeep)
               {
                  this.ghostJumpDowm = true;
                  this.ghostJump = false;
               }
            }
         }
      }
   }
}

