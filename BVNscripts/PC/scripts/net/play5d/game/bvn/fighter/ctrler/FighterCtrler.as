package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.fighter.FighterMC;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.models.FighterHitModel;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.patchouli.utils.ClassUtil;
   
   public class FighterCtrler
   {
      
      public var hitModel:FighterHitModel;
      
      private var _effectCtrl:FighterEffectCtrl;
      
      private var _fighterMcCtrl:FighterMcCtrler;
      
      private var _voiceCtrl:FighterVoiceCtrler;
      
      private var _fighter:FighterMain;
      
      private var _rectCache:Object = {};
      
      private var _doingWankai:Boolean;
      
      public function FighterCtrler()
      {
         super();
      }
      
      public function destory() : void
      {
         if(_effectCtrl)
         {
            _effectCtrl.destory();
            _effectCtrl = null;
         }
         if(_fighterMcCtrl)
         {
            _fighterMcCtrl.destory();
            _fighterMcCtrl = null;
         }
         if(_voiceCtrl)
         {
            _voiceCtrl.destory();
            _voiceCtrl = null;
         }
         if(_rectCache)
         {
            _rectCache = null;
         }
         if(hitModel)
         {
            hitModel.destory();
            hitModel = null;
         }
         _fighter = null;
      }
      
      public function getEffectCtrl() : FighterEffectCtrl
      {
         return _effectCtrl;
      }
      
      public function getVoiceCtrl() : FighterVoiceCtrler
      {
         return _voiceCtrl;
      }
      
      public function get hp() : Number
      {
         return _fighter.hp;
      }
      
      public function set hp(param1:Number) : void
      {
         _fighter.hp = _fighter.hpMax = _fighter.customHpMax = param1;
      }
      
      public function get energy() : Number
      {
         return _fighter.energyMax;
      }
      
      public function set energy(param1:Number) : void
      {
         _fighter.energy = _fighter.energyMax = param1;
      }
      
      public function get speed() : Number
      {
         return _fighter.speed;
      }
      
      public function set speed(param1:Number) : void
      {
         _fighter.speed = param1;
      }
      
      public function get speedAdd() : Number
      {
         return _fighter.speedAdd;
      }
      
      public function set speedAdd(param1:Number) : void
      {
         _fighter.speedAdd = param1;
      }
      
      public function get jumpPower() : Number
      {
         return _fighter.jumpPower;
      }
      
      public function set jumpPower(param1:Number) : void
      {
         _fighter.jumpPower = param1;
      }
      
      public function get heavy() : Number
      {
         return _fighter.heavy;
      }
      
      public function set heavy(param1:Number) : void
      {
         _fighter.heavy = param1;
      }
      
      public function get defenseType() : int
      {
         return _fighter.defenseType;
      }
      
      public function set defenseType(param1:int) : void
      {
         _fighter.defenseType = param1;
      }
      
      public function addHp(param1:Number) : void
      {
         _fighter.addHp(param1);
      }
      
      public function addHpPercent(param1:Number) : void
      {
         _fighter.addHp(_fighter.hpMax * param1);
      }
      
      public function addHpLosePercent(param1:Number) : void
      {
         var _loc2_:Number = _fighter.hpMax - _fighter.hp;
         _fighter.addHp(_loc2_ * param1);
      }
      
      public function loseHp(param1:Number) : void
      {
         _fighter.loseHp(param1);
      }
      
      public function loseHpPercent(param1:Number) : void
      {
         _fighter.loseHp(param1 * _fighter.hpMax);
      }
      
      public function loseHpLosePercent(param1:Number) : void
      {
         var _loc2_:Number = _fighter.hpMax - _fighter.hp;
         _fighter.loseHp(_loc2_ * param1);
      }
      
      public function addEnergy(param1:Number) : void
      {
         _fighter.addEnergy(param1);
      }
      
      public function getEnergy() : Number
      {
         return _fighter.energy;
      }
      
      public function getEnergyOverload() : Boolean
      {
         return _fighter.energyOverLoad;
      }
      
      public function loseEnergy(param1:Number) : void
      {
         _fighter.useEnergy(param1);
      }
      
      public function loseQi(param1:Number) : void
      {
         _fighter.useQi(param1);
      }
      
      public function get self() : DisplayObject
      {
         return _fighter.getDisplay();
      }
      
      public function get target() : DisplayObject
      {
         var _loc1_:IGameSprite = _fighter.getCurrentTarget();
         if(!_loc1_)
         {
            return null;
         }
         return _loc1_.getDisplay();
      }
      
      public function getTargetSP() : IGameSprite
      {
         var _loc1_:IGameSprite = _fighter.getCurrentTarget();
         if(!_loc1_)
         {
            return null;
         }
         return _loc1_;
      }
      
      public function getTargetState() : int
      {
         var _loc1_:FighterMain = _fighter.getCurrentTarget() as FighterMain;
         if(_loc1_ == null)
         {
            return 0;
         }
         return _loc1_.actionState;
      }
      
      public function setTargetVelocity(param1:Number, param2:Number) : void
      {
         var _loc3_:IGameSprite = _fighter.getCurrentTarget();
         if(_loc3_ && _loc3_ is BaseGameSprite)
         {
            (_loc3_ as BaseGameSprite).setVelocity(param1,param2);
         }
      }
      
      public function setTargetDamping(param1:Number, param2:Number) : void
      {
         var _loc3_:IGameSprite = _fighter.getCurrentTarget();
         if(_loc3_ && _loc3_ is BaseGameSprite)
         {
            (_loc3_ as BaseGameSprite).setDamping(param1,param2);
         }
      }
      
      public function targetInRange(param1:Array = null, param2:Array = null) : Boolean
      {
         if(target == null)
         {
            return false;
         }
         var _loc3_:Number = _fighter.direct > 0 ? target.x - self.x : self.x - target.x;
         var _loc6_:Number = target.y - self.y;
         var _loc5_:Boolean = true;
         var _loc4_:Boolean = true;
         if(param1)
         {
            _loc5_ = _loc3_ >= param1[0] && _loc3_ <= param1[1];
         }
         if(param2)
         {
            _loc4_ = _loc6_ >= param2[0] && _loc6_ <= param2[1];
         }
         return _loc5_ && _loc4_;
      }
      
      public function justHit(param1:String, param2:Boolean = false) : Boolean
      {
         var _loc3_:HitVO = null;
         var _loc5_:HitVO = null;
         var _loc4_:IGameSprite = _fighter.getCurrentTarget();
         if(_loc4_ && _loc4_ is FighterMain)
         {
            _loc5_ = (_loc4_ as FighterMain).hurtHit;
            if(_loc5_)
            {
               return _loc5_.id == param1;
            }
            if(param2)
            {
               _loc3_ = (_loc4_ as FighterMain).defenseHit;
               if(_loc3_)
               {
                  return _loc3_.id == param1;
               }
            }
         }
         return false;
      }
      
      public function getMcCtrl() : FighterMcCtrler
      {
         return _fighterMcCtrl;
      }
      
      public function initFighter(param1:FighterMain) : void
      {
         var _loc2_:Object = null;
         _fighter = param1;
         hitModel = new FighterHitModel(_fighter);
         _voiceCtrl = new FighterVoiceCtrler();
         _effectCtrl = new FighterEffectCtrl(param1);
         _fighterMcCtrl = new FighterMcCtrler(param1);
         _fighterMcCtrl.effectCtrler = _effectCtrl;
         var _loc3_:MovieClip = param1.mc as MovieClip;
         if(_loc3_.initFighter)
         {
            try
            {
               _loc2_ = {
                  "fighter_ctrler":this,
                  "mc_ctrler":_fighterMcCtrl,
                  "effect_ctrler":_effectCtrl
               };
               _loc3_.initFighter(_loc2_);
            }
            catch(e:Error)
            {
            }
         }
         else
         {
            if(!_loc3_.setFighterCtrler)
            {
               throw new Error("初始化失败，SWF未定义setFighterCtrler()");
            }
            _loc3_.setFighterCtrler(this);
            if(!_loc3_.setEffectCtrler)
            {
               throw new Error("初始化效果接口失败，SWF未定义setEffectCtrler()");
            }
            _loc3_.setEffectCtrler(_effectCtrl);
            if(!_loc3_.setFighterMcCtrler)
            {
               throw new Error("初始化效果接口失败，SWF未定义setFighterMcCtrler()");
            }
            _loc3_.setFighterMcCtrler(_fighterMcCtrl);
         }
      }
      
      public function renderAnimate() : void
      {
         if(_fighterMcCtrl)
         {
            _fighterMcCtrl.renderAnimate();
         }
      }
      
      public function render() : void
      {
         if(_fighterMcCtrl)
         {
            _fighterMcCtrl.render();
         }
      }
      
      public function setActionCtrl(param1:IFighterActionCtrl) : void
      {
         if(_fighterMcCtrl)
         {
            _fighterMcCtrl.setActionCtrler(param1);
         }
      }
      
      public function defineAction(param1:String, param2:Object) : void
      {
         hitModel.addHitVO(param1,param2);
      }
      
      public function defineBishaFace(param1:String, param2:Class) : void
      {
         _effectCtrl.setBishaFace(param1,param2);
      }
      
      public function defineHurtSound(... rest) : void
      {
         _voiceCtrl.setVoice(0,rest);
      }
      
      public function defineHurtFlySound(... rest) : void
      {
         _voiceCtrl.setVoice(1,rest);
      }
      
      public function defineDieSound(... rest) : void
      {
         _voiceCtrl.setVoice(2,rest);
      }
      
      public function initMc(param1:MovieClip) : void
      {
         if(param1 == null)
         {
            throw new Error("FighterCtrler.initMc Error :: mc is null!");
         }
         var _loc2_:FighterMC = _fighterMcCtrl.initMc(param1);
         if(_doingWankai)
         {
            _fighter.actionState = 50;
            _loc2_.goFrame("开场");
            _doingWankai = false;
         }
         else
         {
            _fighterMcCtrl.idle();
         }
         _fighter.onMcInited();
      }
      
      public function getCurrentHits() : Array
      {
         var _loc6_:Array = null;
         var _loc5_:int = 0;
         var _loc8_:Object = null;
         var _loc7_:String = null;
         var _loc4_:HitVO = null;
         var _loc2_:Rectangle = null;
         try
         {
            _loc6_ = _fighter.getMC().getCurrentHitArea();
         }
         catch(e:Error)
         {
         }
         if(!_loc6_ || _loc6_.length < 1)
         {
            return null;
         }
         var _loc1_:Array = [];
         var _loc3_:int = int(_loc6_.length);
         _loc5_ = 0;
         while(_loc5_ < _loc3_)
         {
            _loc8_ = _loc6_[_loc5_];
            _loc7_ = _loc8_.name;
            _loc4_ = (_loc8_.hitVO as HitVO).clone();
            if(_loc4_)
            {
               _loc2_ = _loc8_.area;
               _loc4_.currentArea = getCurrentRect(_loc2_,"hit" + _loc5_);
               _loc1_.push(_loc4_);
            }
            _loc5_++;
         }
         return _loc1_;
      }
      
      public function getBodyArea() : Rectangle
      {
         var _loc1_:FighterMC = null;
         var _loc2_:Rectangle = null;
         try
         {
            _loc1_ = _fighter.getMC();
            _loc2_ = _loc1_.getCurrentBodyArea();
         }
         catch(e:Error)
         {
         }
         if(_loc2_ == null)
         {
            return null;
         }
         return getCurrentRect(_loc2_,"body");
      }
      
      public function getHitCheckRect(param1:String) : Rectangle
      {
         var _loc2_:Rectangle = _fighter.getMC().getCheckHitRect(param1);
         if(_loc2_ == null)
         {
            return null;
         }
         return getCurrentRect(_loc2_,"hit_check");
      }
      
      public function getCurrentRect(param1:Rectangle, param2:String = null) : Rectangle
      {
         var _loc3_:* = null;
         if(param2 == null)
         {
            _loc3_ = new Rectangle();
         }
         else if(_rectCache[param2])
         {
            _loc3_ = _rectCache[param2];
         }
         else
         {
            _loc3_ = new Rectangle();
            _rectCache[param2] = _loc3_;
         }
         _loc3_.x = param1.x * _fighter.direct + _fighter.x;
         if(_fighter.direct < 0)
         {
            _loc3_.x -= param1.width;
         }
         _loc3_.y = param1.y + _fighter.y;
         _loc3_.width = param1.width;
         _loc3_.height = param1.height;
         return _loc3_;
      }
      
      public function doWanKai(param1:int = 0) : void
      {
         _doingWankai = true;
         ClassUtil.removeAllEventListener(_fighter.getMC().mc);
         if(param1 == 0)
         {
            _fighter.mc.nextFrame();
         }
         else
         {
            _fighter.mc.gotoAndStop(param1);
         }
      }
      
      public function setDirectToTarget() : void
      {
         var _loc1_:IGameSprite = _fighter.getCurrentTarget();
         if(_loc1_ == null)
         {
            return;
         }
         _fighter.direct = _fighter.x < _loc1_.x ? 1 : -1;
      }
      
      public function moveOnce(param1:Number = 0, param2:Number = 0) : void
      {
         _fighter.x += param1 * _fighter.direct;
         _fighter.y += param2;
      }
      
      public function moveToTarget(param1:Object = null, param2:Object = null, param3:Boolean = true) : void
      {
         var _loc4_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc5_:IGameSprite = _fighter.getCurrentTarget();
         if(!_loc5_)
         {
            return;
         }
         if(param1 != null)
         {
            _loc4_ = Number(param1);
            _loc6_ = _loc5_.x + _loc4_ * _fighter.direct;
            if(_loc4_ > 0)
            {
               try
               {
                  if(_loc5_.x < _loc4_)
                  {
                     _loc6_ = _loc5_.x + _loc4_;
                  }
                  else if(_loc5_.x > GameCtrl.I.gameState.getMap().right - _loc4_)
                  {
                     _loc6_ = _loc5_.x - _loc4_;
                  }
               }
               catch(e:Error)
               {
               }
            }
            _fighter.x = _loc6_;
         }
         if(param2 != null)
         {
            _fighter.y = _loc5_.y + Number(param2);
         }
         if(param3)
         {
            _fighter.direct = _fighter.x < _loc5_.x ? 1 : -1;
         }
      }
      
      public function setCross(param1:Boolean) : void
      {
         _fighter.isCross = param1;
      }
      
      public function getHitRange(param1:String) : Rectangle
      {
         var _loc2_:Rectangle = _fighter.getMC().getHitRange(param1);
         if(_loc2_ == null)
         {
            return null;
         }
         return getCurrentRect(_loc2_,"hitRange_" + param1);
      }
      
      public function getSelf() : FighterMain
      {
         return _fighter;
      }
      
      public function setDirectReverse() : void
      {
         _fighter.direct *= -1;
      }
      
      public function addRenderFunc(param1:Function = null, param2:Object = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         _fighter.addRenderFunc(param1,param2);
      }
      
      public function removeRenderFunc(param1:Function = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         _fighter.removeRenderFunc(param1);
      }
      
      public function inheritRenderFunc(param1:Function = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         _fighter.inheritRenderFunc(param1);
      }
   }
}

