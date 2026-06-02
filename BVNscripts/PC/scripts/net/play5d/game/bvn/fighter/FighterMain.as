package net.play5d.game.bvn.fighter
{
   import flash.display.MovieClip;
   import flash.geom.ColorTransform;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.ctrl.mosou_ctrls.MosouLogic;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.data.mosou.MosouEnemyVO;
   import net.play5d.game.bvn.data.mosou.MosouFighterLogic;
   import net.play5d.game.bvn.data.mosou.player.MosouFighterVO;
   import net.play5d.game.bvn.fighter.ctrler.FighterAICtrl;
   import net.play5d.game.bvn.fighter.ctrler.FighterBuffCtrler;
   import net.play5d.game.bvn.fighter.ctrler.FighterCtrler;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class FighterMain extends BaseGameSprite
   {
      
      public var qi:Number = GameData.I.config.originalQi;
      
      public var qiMax:Number = 300;
      
      public var energy:Number = 100;
      
      public var energyMax:Number = 100;
      
      public var energyOverLoad:Boolean = false;
      
      public var tempPerEnergy:Number = 0;
      
      private var _energyAddGap:int;
      
      public var customHpMax:int = 0;
      
      private var _speed:Number = 6;
      
      public var speed:Number = 6;
      
      public var speedAdd:Number = 0;
      
      public var jumpPower:Number = 15;
      
      public var airHitTimes:int = 1;
      
      public var jumpTimes:int = 2;
      
      public var actionState:int = 0;
      
      public var defenseType:int = 0;
      
      public var isSteelBody:Boolean = false;
      
      public var isSuperSteelBody:Boolean = false;
      
      public var allowSteelCatch:Boolean = true;
      
      public var allowDefDirect:Boolean = true;
      
      public var allowAddQi:Boolean = true;
      
      public var fzqi:Number = GameData.I.config.originalAssist ? 100 : 0;
      
      public const fzqiMax:Number = 100;
      
      public var data:FighterVO;
      
      public var introSaid:Boolean = false;
      
      public var introPrior:Boolean = false;
      
      public var mosouPlayerData:MosouFighterVO;
      
      public var mosouEnemyData:MosouEnemyVO;
      
      public var mosouLogic:MosouFighterLogic;
      
      private var _mosouPlayerLogic:MosouFighterLogic;
      
      private var _currentHurts:Vector.<HitVO>;
      
      public var lastHitVO:HitVO;
      
      public var hurtHit:HitVO;
      
      public var defenseHit:HitVO;
      
      public var targetTeams:Vector.<TeamVO>;
      
      private var _currentTarget:IGameSprite;
      
      private var _buffCtrler:FighterBuffCtrler;
      
      private var _fighterCtrl:FighterCtrler;
      
      private var _explodeHitVO:HitVO;
      
      private var _explodeHitFrame:int;
      
      private var _explodeSteelFrame:int;
      
      public var explodeSkillFrame:int;
      
      private var _replaceSkillFrame:int;
      
      public var replaceSkillFrame:int;
      
      public var recordCount:int;
      
      public var recordWinCount:int;
      
      public var recordDamage:Number = 0;
      
      public var isRenderBeforeTarget:Boolean = false;
      
      public var isCheckedRender:Boolean = false;
      
      public var needStopEffects:Boolean = false;
      
      public var targetX:Number = NaN;
      
      public var targetXMove:Number = 0;
      
      public var ticksAtCorner:int = 0;
      
      public function FighterMain(param1:MovieClip)
      {
         super(param1);
         introSaid = false;
         _area = null;
         if(param1 == null)
         {
            throw new Error("人物创建失败, mainMc is null !");
         }
      }
      
      public function set limitLevel(param1:int) : void
      {
         if(!team)
         {
            return;
         }
         if(team.id == 1)
         {
            GameCtrl.I.gameRunData.p1FighterGroup.limitLevel = param1;
         }
         if(team.id == 2)
         {
            GameCtrl.I.gameRunData.p2FighterGroup.limitLevel = param1;
         }
      }
      
      public function get limitLevel() : int
      {
         if(team.id == 1)
         {
            return GameCtrl.I.gameRunData.p1FighterGroup.limitLevel;
         }
         if(team.id == 2)
         {
            return GameCtrl.I.gameRunData.p2FighterGroup.limitLevel;
         }
         return 0;
      }
      
      public function get isAICtrl() : Boolean
      {
         if(_fighterCtrl == null)
         {
            return false;
         }
         return _fighterCtrl.getMcCtrl().getActionCtrler() is FighterAICtrl;
      }
      
      public function changeColor(param1:ColorTransform) : void
      {
         _mainMc.transform.colorTransform = param1;
      }
      
      public function resumeColor() : void
      {
         _mainMc.transform.colorTransform = _colorTransform ?? new ColorTransform();
      }
      
      public function getMosouLogic() : MosouFighterLogic
      {
         return _mosouPlayerLogic;
      }
      
      override public function setActive(param1:Boolean) : void
      {
         super.setActive(param1);
         if(!param1 && _fighterCtrl && _fighterCtrl.getEffectCtrl())
         {
            _fighterCtrl.getEffectCtrl().clean();
         }
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         if(!param1)
         {
            return;
         }
         if(_fighterCtrl)
         {
            _fighterCtrl.destory();
            _fighterCtrl = null;
         }
         if(_mainMc)
         {
            _mainMc.filters = null;
            _mainMc.gotoAndStop(1);
         }
         if(_buffCtrler)
         {
            _buffCtrler.destory();
            _buffCtrler = null;
         }
         if(data)
         {
            data = null;
         }
         if(mosouEnemyData)
         {
            mosouEnemyData = null;
         }
         targetTeams = null;
         _currentTarget = null;
         _currentHurts = null;
         super.destory(param1);
      }
      
      override public function set attackRate(param1:Number) : void
      {
         super.attackRate = param1;
         if(_fighterCtrl && _fighterCtrl.hitModel)
         {
            _fighterCtrl.hitModel.setPowerRate(param1);
         }
      }
      
      public function currentHurtDamage() : int
      {
         if(!_currentHurts)
         {
            return 0;
         }
         var _loc1_:int = 0;
         for each(var _loc2_ in _currentHurts)
         {
            _loc1_ += _loc2_.lastDamage;
         }
         return _loc1_;
      }
      
      public function getLastHurtHitVO() : HitVO
      {
         if(!_currentHurts)
         {
            return null;
         }
         return _currentHurts[_currentHurts.length - 1];
      }
      
      public function hurtBreakHit() : Boolean
      {
         for each(var _loc1_ in _currentHurts)
         {
            if(_loc1_.isBreakDef)
            {
               return true;
            }
         }
         return false;
      }
      
      public function hurtBreakDefHit() : Boolean
      {
         for each(var _loc1_ in _currentHurts)
         {
            if(_loc1_.id == "breakdef")
            {
               return true;
            }
         }
         return false;
      }
      
      public function hurtCatchHit() : Boolean
      {
         for each(var _loc1_ in _currentHurts)
         {
            if(_loc1_.hitType == 11 && _loc1_.isBreakDef)
            {
               return true;
            }
         }
         return false;
      }
      
      public function hurtBishaHit() : Boolean
      {
         for each(var _loc1_ in _currentHurts)
         {
            if(_loc1_.isBisha())
            {
               return true;
            }
         }
         return false;
      }
      
      public function clearHurtHits() : void
      {
         _currentHurts = null;
      }
      
      public function clearBeHurtHits() : void
      {
         hurtHit = null;
         defenseHit = null;
      }
      
      public function getCtrler() : FighterCtrler
      {
         return _fighterCtrl;
      }
      
      public function getBuffCtrl() : FighterBuffCtrler
      {
         return _buffCtrler;
      }
      
      public function getCurrentTarget() : IGameSprite
      {
         var _loc4_:FighterMain = null;
         var _loc3_:MosouEnemyVO = null;
         if(!GameMode.isMusouMode())
         {
            if(team.id == 1)
            {
               return GameCtrl.I.gameRunData.p2FighterGroup.currentFighter;
            }
            if(team.id == 2)
            {
               return GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
            }
         }
         if(_currentTarget)
         {
            _loc4_ = _currentTarget as FighterMain;
            if(_loc4_ != null && _loc4_.isAlive && _loc4_.getActive())
            {
               return _currentTarget;
            }
         }
         var _loc1_:Vector.<IGameSprite> = getTargets();
         var _loc5_:Array = [];
         if(_loc1_ && _loc1_.length > 0)
         {
            for each(var _loc2_ in _loc1_)
            {
               if(_loc2_.getBodyArea() == null)
               {
                  _loc5_.push({
                     "fighter":_loc2_,
                     "order":5
                  });
               }
               else if(_loc2_ is FighterMain && (_loc2_ as FighterMain).isAlive && _loc2_.getActive())
               {
                  _loc3_ = (_loc2_ as FighterMain).mosouEnemyData;
                  if(_loc3_)
                  {
                     if(_loc3_.isBoss)
                     {
                        _loc5_.push({
                           "fighter":_loc2_,
                           "order":0
                        });
                     }
                     else
                     {
                        _loc5_.push({
                           "fighter":_loc2_,
                           "order":1
                        });
                     }
                  }
                  else
                  {
                     _loc5_.push({
                        "fighter":_loc2_,
                        "order":0
                     });
                  }
               }
               else if(_loc2_ is BaseGameSprite && (_loc2_ as BaseGameSprite).isAlive && _loc2_.getActive())
               {
                  _loc5_.push({
                     "fighter":_loc2_,
                     "order":10
                  });
               }
               else
               {
                  _loc5_.push({
                     "fighter":_loc2_,
                     "order":20
                  });
               }
            }
            _loc5_.sortOn("order",16);
            _currentTarget = _loc5_[0].fighter;
         }
         return _currentTarget;
      }
      
      public function getTargets() : Vector.<IGameSprite>
      {
         var _loc1_:int = 0;
         if(!targetTeams || targetTeams.length < 1)
         {
            return null;
         }
         var _loc2_:Vector.<IGameSprite> = new Vector.<IGameSprite>();
         while(_loc1_ < targetTeams.length)
         {
            _loc2_ = _loc2_.concat(targetTeams[_loc1_].getAliveChildren());
            _loc1_++;
         }
         return _loc2_;
      }
      
      public function getMC() : FighterMC
      {
         if(!_fighterCtrl)
         {
            return null;
         }
         if(!_fighterCtrl.getMcCtrl())
         {
            return null;
         }
         return _fighterCtrl.getMcCtrl().getFighterMc();
      }
      
      public function initMosouFighter(param1:MosouFighterVO) : void
      {
         mosouPlayerData = param1;
         _mosouPlayerLogic = new MosouFighterLogic(param1);
         updateProperties();
      }
      
      public function initMosouEnemy(param1:MosouEnemyVO) : void
      {
         mosouEnemyData = param1;
      }
      
      public function updateProperties() : void
      {
         if(!mosouPlayerData || !_mosouPlayerLogic)
         {
            return;
         }
         hp = hpMax = _mosouPlayerLogic.getHP();
         qiMax = _mosouPlayerLogic.getQI();
         energy = energyMax = _mosouPlayerLogic.getEnergy();
         qi = qiMax;
         if(_mosouPlayerLogic)
         {
            _mosouPlayerLogic.initFighterProps(this);
         }
      }
      
      public function setActionCtrl(param1:IFighterActionCtrl) : void
      {
         if(_fighterCtrl)
         {
            _fighterCtrl.setActionCtrl(param1);
            param1.initlize();
         }
      }
      
      public function getActionCtrl() : IFighterActionCtrl
      {
         return _fighterCtrl.getMcCtrl().getActionCtrler();
      }
      
      public function initlized() : Boolean
      {
         return _fighterCtrl != null;
      }
      
      public function initlize(param1:Boolean = true) : void
      {
         if(_fighterCtrl)
         {
            throw new Error("fighter 已完成化！");
         }
         _fighterCtrl = new FighterCtrler();
         _buffCtrler = new FighterBuffCtrler(this);
         _fighterCtrl.initFighter(this);
         try
         {
            if(param1)
            {
               GameLogic.clearHits(team.id);
            }
         }
         catch(e:*)
         {
         }
         _mainMc.gotoAndStop(data != null ? data.startFrame + 1 : 2);
      }
      
      public function onMcInited() : void
      {
         if(_mosouPlayerLogic != null)
         {
            _mosouPlayerLogic.initFighterProps(this);
         }
         if(mosouEnemyData != null)
         {
            MosouLogic.initEnemyProps(this);
         }
      }
      
      public function initAttackAddDmg(param1:int, param2:int = 0, param3:int = 0) : void
      {
         if(!_fighterCtrl || !_fighterCtrl.hitModel)
         {
            return;
         }
         var _loc4_:Object = _fighterCtrl.hitModel.getAll();
         for each(var _loc5_ in _loc4_)
         {
            if(_loc5_.isBisha())
            {
               _loc5_.powerAdd = param3;
            }
            else if(_loc5_.isSkill())
            {
               _loc5_.powerAdd = param2;
            }
            else
            {
               _loc5_.powerAdd = param1;
            }
         }
      }
      
      override public function renderAnimate() : void
      {
         var _loc1_:FighterMain = null;
         super.renderAnimate();
         if(_destoryed)
         {
            return;
         }
         if(!GameCtrl.I.isGamePause)
         {
            renderEnergy();
            renderFzQi();
         }
         if(_fighterCtrl)
         {
            _fighterCtrl.renderAnimate();
         }
         if(_explodeHitFrame > 0)
         {
            _explodeHitFrame = _explodeHitFrame - 1;
            if(_explodeHitFrame == 8)
            {
               idle();
               isAllowBeHit = false;
            }
            if(_explodeHitFrame <= 0)
            {
               _explodeHitVO = null;
               isAllowBeHit = true;
            }
         }
         if(_explodeSteelFrame > 0)
         {
            _explodeSteelFrame = _explodeSteelFrame - 1;
            _fighterCtrl.getMcCtrl().setSteelBody(true,true);
            if(_explodeSteelFrame <= 0)
            {
               _fighterCtrl.getMcCtrl().setSteelBody(false);
            }
         }
         if(_replaceSkillFrame > 0)
         {
            _replaceSkillFrame = _replaceSkillFrame - 1;
            if(_replaceSkillFrame > 2)
            {
               _mainMc.alpha = 0.5;
               isAllowBeHit = false;
               _fighterCtrl.getMcCtrl().getAction().clearAction();
               if(actionState == 0)
               {
                  _fighterCtrl.getMcCtrl().setMove();
               }
               _fighterCtrl.getMcCtrl().getAction().airMove = true;
            }
            else if(_replaceSkillFrame == 2)
            {
               if(actionState == 0)
               {
                  _fighterCtrl.getMcCtrl().setDash();
               }
            }
            else if(_replaceSkillFrame == 1)
            {
               _mainMc.alpha = 1;
               if(actionState == 0)
               {
                  isAllowBeHit = true;
                  _fighterCtrl.getMcCtrl().setDefense();
               }
            }
            else if(_replaceSkillFrame <= 0)
            {
               if(actionState == 0)
               {
                  _fighterCtrl.getMcCtrl().setAllAct();
               }
            }
         }
         replaceSkillFrame = _replaceSkillFrame;
         if(explodeSkillFrame > 0)
         {
            explodeSkillFrame = explodeSkillFrame - 1;
            _loc1_ = getCurrentTarget() as FighterMain;
            if(FighterActionState.isHurting(_loc1_.actionState))
            {
               explodeSkillFrame = 0;
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
         checkRenderToTarget();
         if(_fighterCtrl)
         {
            _fighterCtrl.render();
         }
         if(_buffCtrler)
         {
            _buffCtrler.render();
         }
         if(hp < 0)
         {
            hp = 0;
         }
         if(hp > hpMax)
         {
            hp = hpMax;
         }
         if(qi < 0)
         {
            qi = 0;
         }
         if(qi > qiMax)
         {
            qi = qiMax;
         }
         if(fzqi < 0)
         {
            fzqi = 0;
         }
         if(fzqi > 100)
         {
            fzqi = 100;
         }
         if(energy < 0)
         {
            energy = 0;
         }
         if(energy > energyMax)
         {
            energy = energyMax;
         }
         if(needStopEffects)
         {
            needStopEffects = false;
            stopEffects();
         }
         updatePosition();
      }
      
      private function checkRenderToTarget() : void
      {
         var _loc2_:IGameSprite = this.getCurrentTarget();
         if(_loc2_ == null || !(_loc2_ is FighterMain))
         {
            isCheckedRender = false;
            return;
         }
         var _loc1_:FighterMain = _loc2_ as FighterMain;
         if(isCheckedRender && _loc1_.isCheckedRender)
         {
            return;
         }
         isCheckedRender = true;
         _loc1_.isCheckedRender = true;
         isRenderBeforeTarget = true;
         _loc1_.isRenderBeforeTarget = false;
      }
      
      public function jump() : void
      {
         _g = 0;
         setVelocity(0,-jumpPower);
         setDamping(0,0.5);
      }
      
      override public function getCurrentHits() : Array
      {
         var _loc1_:Array = null;
         if(_explodeHitVO && _explodeHitFrame < 8)
         {
            if(_fighterCtrl.getCurrentHits())
            {
               _loc1_ = _fighterCtrl.getCurrentHits().concat();
               _loc1_.unshift(_explodeHitVO);
               return _loc1_;
            }
            return [_explodeHitVO];
         }
         return _fighterCtrl.getCurrentHits();
      }
      
      override public function getBodyArea() : Rectangle
      {
         if(!_fighterCtrl)
         {
            return null;
         }
         return _fighterCtrl.getBodyArea();
      }
      
      override public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         super.hit(param1,param2);
         lastHitVO = param1;
         var _loc3_:Number = 0;
         if(param2 is FighterMain && param2 == getCurrentTarget())
         {
            if(param1.isBisha())
            {
               _loc3_ = param1.power * 0;
            }
            else
            {
               _loc3_ = param1.power * 0.17;
            }
            if(_loc3_ > 15)
            {
               _loc3_ = 15;
            }
         }
         addQi(_loc3_);
         GameLogic.hitTarget(param1,this,param2);
      }
      
      override public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
         if(!isAllowBeHit)
         {
            return;
         }
         super.beHit(param1,param2);
         _fighterCtrl.getMcCtrl().beHit(param1,param2);
         var _loc3_:Number = param1.power * 0.08;
         if(_loc3_ > 20)
         {
            _loc3_ = 20;
         }
         addQi(_loc3_);
         if(actionState == 21 || actionState == 22)
         {
            _currentHurts = _currentHurts ?? new Vector.<HitVO>();
            if(hurtHit && hurtHit.id == "breakdef")
            {
               param1 = hurtHit;
            }
            _currentHurts.push(param1);
         }
      }
      
      override public function addHp(param1:Number) : void
      {
         super.addHp(param1);
      }
      
      override public function loseHp(param1:Number) : Number
      {
         var _loc3_:FighterMain = null;
         var _loc2_:Number = super.loseHp(param1);
         if(getCurrentTarget() && getCurrentTarget() is FighterMain)
         {
            _loc3_ = getCurrentTarget() as FighterMain;
            if(_loc3_ && _loc3_.isAlive)
            {
               _loc3_.recordDamage += _loc2_;
            }
         }
         return _loc2_;
      }
      
      private function renderEnergy() : void
      {
         if(_energyAddGap > 0)
         {
            _energyAddGap = _energyAddGap - 1;
            return;
         }
         if(energy < energyMax)
         {
            if(energyOverLoad)
            {
               addEnergyInRender(0.6);
               if(energy > 30)
               {
                  energyOverLoad = false;
               }
            }
            else if(actionState == 20)
            {
               addEnergyInRender(0.8);
            }
            else if(FighterActionState.isAttacking(actionState))
            {
               addEnergyInRender(1.1);
            }
            else if(actionState == 14)
            {
               addEnergyInRender(0);
            }
            else
            {
               addEnergyInRender(2);
            }
         }
         else
         {
            tempPerEnergy = 0;
         }
      }
      
      private function addEnergyInRender(param1:Number) : void
      {
         if(tempPerEnergy != 0)
         {
            energy += Math.min(tempPerEnergy,param1);
            return;
         }
         energy += param1;
         if(energy > energyMax)
         {
            energy = energyMax;
         }
      }
      
      private function renderFzQi() : void
      {
         if(fzqi < 100)
         {
            fzqi += 0.2;
         }
      }
      
      public function hasEnergy(param1:Number, param2:Boolean = false) : Boolean
      {
         if(energy >= param1)
         {
            return true;
         }
         if(param2)
         {
            if(!energyOverLoad)
            {
               return true;
            }
         }
         return false;
      }
      
      public function addEnergy(param1:Number) : void
      {
         energy += param1;
         if(energy > energyMax)
         {
            energy = energyMax;
         }
      }
      
      public function useEnergy(param1:Number) : void
      {
         energy -= param1;
         _energyAddGap = 24;
         if(energy < 0)
         {
            energy = 0;
            energyOverLoad = true;
         }
      }
      
      public function useQi(param1:Number) : Boolean
      {
         if(qi < param1)
         {
            return false;
         }
         qi -= param1;
         return true;
      }
      
      public function addQi(param1:Number) : void
      {
         if(GameData.I.config.isStandardLimit)
         {
            if(limitLevel > 0 && param1 > 0)
            {
               return;
            }
         }
         if(!allowAddQi && param1 > 0)
         {
            return;
         }
         qi += param1;
         if(qi > qiMax)
         {
            qi = qiMax;
         }
      }
      
      public function sayIntro() : void
      {
         introSaid = true;
         _fighterCtrl.getMcCtrl().sayIntro();
      }
      
      public function win() : void
      {
         _fighterCtrl.getMcCtrl().doWin();
      }
      
      public function idle() : void
      {
         _fighterCtrl.getMcCtrl().idle();
      }
      
      public function lose() : void
      {
         _fighterCtrl.getMcCtrl().doLose();
      }
      
      public function getHitRange(param1:String) : Rectangle
      {
         return _fighterCtrl.getHitRange(param1);
      }
      
      public function energyExplode() : void
      {
         useEnergy(100);
         _fighterCtrl.getEffectCtrl().energyExplode();
         _fighterCtrl.getMcCtrl().setSteelBody(true,true);
         _explodeHitVO = new HitVO();
         var _loc1_:Rectangle = new Rectangle(-100,-200,200,210);
         _explodeHitVO.currentArea = _fighterCtrl.getCurrentRect(_loc1_);
         _explodeHitVO.id = "reiatsu_bs";
         _explodeHitVO.power = 50;
         _explodeHitVO.hitx = 15 * direct;
         _explodeHitVO.hitType = 5;
         _explodeHitVO.hurtType = 1;
         _explodeHitFrame = 10;
         _explodeSteelFrame = 60;
         isAllowBeHit = false;
      }
      
      public function replaceSkill() : void
      {
         getCtrler().getMcCtrl().getAction().isHurting = false;
         _fighterCtrl.getEffectCtrl().replaceSkill();
         _fighterCtrl.moveToTarget(300,0);
         _fighterCtrl.getMcCtrl().stopMove();
         super.render();
         renderAnimate();
         _fighterCtrl.setDirectToTarget();
         energy = energyMax;
         energyOverLoad = false;
         _fighterCtrl.getMcCtrl().getAction().jumpTimes = 2;
         _fighterCtrl.getMcCtrl().getAction().airHitTimes = 1;
         _replaceSkillFrame = 10;
         replaceSkillFrame = _replaceSkillFrame;
         hp += hurtHit.lastDamage;
         idle();
         EffectCtrl.I.doEffectById("replaceSp2",this.x,this.y);
         _mainMc.alpha = 0.5;
         isAllowBeHit = false;
         _fighterCtrl.getMcCtrl().getAction().clearAction();
         if(actionState == 0)
         {
            _fighterCtrl.getMcCtrl().setMove();
         }
         _fighterCtrl.getMcCtrl().getAction().airMove = true;
      }
      
      override public function getArea() : Rectangle
      {
         if(!_area)
         {
            _area = getBodyArea();
         }
         return _area;
      }
      
      public function hasWankai() : Boolean
      {
         return _fighterCtrl.getMcCtrl().getFighterMc().checkFrame("万解");
      }
      
      public function die() : void
      {
         hp = 0;
         isAlive = false;
         if(!FighterActionState.isHurting(actionState) && actionState != 30)
         {
            _fighterCtrl.getMcCtrl().getFighterMc().playHurtDown();
         }
      }
      
      public function relive(param1:Boolean = false) : void
      {
         isAlive = true;
         if(param1)
         {
            hp = hpMax;
            qi = 0;
         }
         idle();
      }
      
      public function targetDoGhostStep() : void
      {
         _fighterCtrl.getMcCtrl().targetDoGhostStep();
      }
      
      public function getDoingAction() : Object
      {
         if(_fighterCtrl == null || _fighterCtrl.getMcCtrl() == null || getMC() == null || data == null)
         {
            return null;
         }
         return {
            "action":this.getMC().getCurrentLabel() + "\n" + mc.currentFrame.toString() + data.id,
            "times":this._fighterCtrl.getMcCtrl().doActionTimes
         };
      }
      
      public function isMosouEnemy() : Boolean
      {
         if(!mosouEnemyData)
         {
            return false;
         }
         return !mosouEnemyData.isBoss;
      }
      
      public function isMosouBoss() : Boolean
      {
         if(!mosouEnemyData)
         {
            return false;
         }
         return mosouEnemyData.isBoss;
      }
      
      public function stopEffects() : void
      {
         _fighterCtrl.getEffectCtrl().endShake();
         _fighterCtrl.getEffectCtrl().endShadow();
         _fighterCtrl.getEffectCtrl().endGlow();
         _explodeSteelFrame = 0;
         _explodeHitFrame = 0;
         _replaceSkillFrame = 0;
         resumeColor();
         _fighterCtrl.getMcCtrl().setSteelBody(false);
         _buffCtrler.speedDown(0,0);
         _buffCtrler.attackDown(0,0);
         _buffCtrler.defenseDown(0,0);
         _buffCtrler.render();
      }
   }
}

