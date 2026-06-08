package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.models.*;
   import net.play5d.game.bvn.interfaces.*;
   
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
         if(Boolean(this._effectCtrl))
         {
            this._effectCtrl.destory();
            this._effectCtrl = null;
         }
         if(Boolean(this._fighterMcCtrl))
         {
            this._fighterMcCtrl.destory();
            this._fighterMcCtrl = null;
         }
         if(Boolean(this._voiceCtrl))
         {
            this._voiceCtrl.destory();
            this._voiceCtrl = null;
         }
         if(Boolean(this._rectCache))
         {
            this._rectCache = null;
         }
         if(Boolean(this.hitModel))
         {
            this.hitModel.destory();
            this.hitModel = null;
         }
         this._fighter = null;
      }
      
      public function getEffectCtrl() : FighterEffectCtrl
      {
         return this._effectCtrl;
      }
      
      public function getVoiceCtrl() : FighterVoiceCtrler
      {
         return this._voiceCtrl;
      }
      
      public function get hp() : Number
      {
         return this._fighter.hp;
      }
      
      public function set hp(param1:Number) : void
      {
         this._fighter.hp = this._fighter.hpMax = this._fighter.customHpMax = param1;
      }
      
      public function get energy() : Number
      {
         return this._fighter.energyMax;
      }
      
      public function set energy(param1:Number) : void
      {
         this._fighter.energy = this._fighter.energyMax = param1;
      }
      
      public function get speed() : Number
      {
         return this._fighter.speed;
      }
      
      public function set speed(param1:Number) : void
      {
         this._fighter.speed = param1;
      }
      
      public function get jumpPower() : Number
      {
         return this._fighter.jumpPower;
      }
      
      public function set jumpPower(param1:Number) : void
      {
         this._fighter.jumpPower = param1;
      }
      
      public function get heavy() : Number
      {
         return this._fighter.heavy;
      }
      
      public function set heavy(param1:Number) : void
      {
         this._fighter.heavy = param1;
      }
      
      public function get defenseType() : int
      {
         return this._fighter.defenseType;
      }
      
      public function set defenseType(param1:int) : void
      {
         this._fighter.defenseType = param1;
      }
      
      public function addHp(param1:Number) : void
      {
         this._fighter.addHp(param1);
      }
      
      public function addHpPercent(param1:Number) : void
      {
         this._fighter.addHp(this._fighter.hpMax * param1);
      }
      
      public function loseHp(param1:Number) : void
      {
         this._fighter.loseHp(param1);
      }
      
      public function loseHpPercent(param1:Number) : void
      {
         this._fighter.loseHp(param1 * this._fighter.hpMax);
      }
      
      public function get self() : DisplayObject
      {
         return this._fighter.getDisplay();
      }
      
      public function get target() : DisplayObject
      {
         var _loc1_:IGameSprite = this._fighter.getCurrentTarget();
         if(!_loc1_)
         {
            return null;
         }
         return _loc1_.getDisplay();
      }
      
      public function getTargetSP() : IGameSprite
      {
         var _loc1_:IGameSprite = this._fighter.getCurrentTarget();
         if(!_loc1_)
         {
            return null;
         }
         return _loc1_;
      }
      
      public function getTargetState() : int
      {
         var _loc1_:FighterMain = this._fighter.getCurrentTarget() as FighterMain;
         if(!_loc1_)
         {
            return 0;
         }
         return _loc1_.actionState;
      }
      
      public function setTargetVelocity(param1:Number, param2:Number) : void
      {
         var _loc3_:IGameSprite = this._fighter.getCurrentTarget();
         if(Boolean(_loc3_) && _loc3_ is BaseGameSprite)
         {
            (_loc3_ as BaseGameSprite).setVelocity(param1,param2);
         }
      }
      
      public function setTargetDamping(param1:Number, param2:Number) : void
      {
         var _loc3_:IGameSprite = this._fighter.getCurrentTarget();
         if(Boolean(_loc3_) && _loc3_ is BaseGameSprite)
         {
            (_loc3_ as BaseGameSprite).setDamping(param1,param2);
         }
      }
      
      public function targetInRange(param1:Array = null, param2:Array = null) : Boolean
      {
         var _loc3_:Number = NaN;
         var _loc4_:DisplayObject = this.target;
         if(!this.target)
         {
            return false;
         }
         var _loc5_:DisplayObject = this.self;
         if(this._fighter.direct > 0)
         {
            _loc3_ = _loc4_.x - _loc5_.x;
         }
         else
         {
            _loc3_ = _loc5_.x - _loc4_.x;
         }
         var _loc6_:Number = _loc4_.y - _loc5_.y;
         var _loc7_:Boolean = true;
         var _loc8_:Boolean = true;
         if(Boolean(param1))
         {
            _loc7_ = _loc3_ >= param1[0] && _loc3_ <= param1[1];
         }
         if(Boolean(param2))
         {
            _loc8_ = _loc6_ >= param2[0] && _loc6_ <= param2[1];
         }
         return _loc7_ && _loc8_;
      }
      
      public function justHit(param1:String, param2:Boolean = false) : Boolean
      {
         var _loc3_:HitVO = null;
         var _loc4_:HitVO = null;
         var _loc5_:IGameSprite = this._fighter.getCurrentTarget();
         if(Boolean(_loc5_) && _loc5_ is FighterMain)
         {
            _loc3_ = (_loc5_ as FighterMain).hurtHit;
            if(Boolean(_loc3_))
            {
               return _loc3_.id == param1;
            }
            if(param2)
            {
               _loc4_ = (_loc5_ as FighterMain).defenseHit;
               if(Boolean(_loc4_))
               {
                  return _loc4_.id == param1;
               }
            }
         }
         return false;
      }
      
      public function getMcCtrl() : FighterMcCtrler
      {
         return this._fighterMcCtrl;
      }
      
      public function initFighter(param1:FighterMain) : void
      {
         this._fighter = param1;
         this.hitModel = new FighterHitModel(this._fighter);
         this._voiceCtrl = new FighterVoiceCtrler();
         if(Boolean(param1.mc.setEffectCtrler))
         {
            this._effectCtrl = new FighterEffectCtrl(param1);
            param1.mc.setEffectCtrler(this._effectCtrl);
            if(Boolean(param1.mc.setFighterMcCtrler))
            {
               this._fighterMcCtrl = new FighterMcCtrler(param1);
               this._fighterMcCtrl.effectCtrler = this._effectCtrl;
               param1.mc.setFighterMcCtrler(this._fighterMcCtrl);
               return;
            }
            throw new Error("初始化效果接口失败，SWF未定义setFighterMcCtrler()");
         }
         throw new Error("初始化效果接口失败，SWF未定义setEffectCtrler()");
      }
      
      public function renderAnimate() : void
      {
         if(Boolean(this._fighterMcCtrl))
         {
            this._fighterMcCtrl.renderAnimate();
         }
      }
      
      public function render() : void
      {
         if(Boolean(this._fighterMcCtrl))
         {
            this._fighterMcCtrl.render();
         }
      }
      
      public function setActionCtrl(param1:IFighterActionCtrl) : void
      {
         if(Boolean(this._fighterMcCtrl))
         {
            this._fighterMcCtrl.setActionCtrler(param1);
         }
         else
         {
            trace("设置ctrler失败！");
         }
      }
      
      public function defineAction(param1:String, param2:Object) : void
      {
         this.hitModel.addHitVO(param1,param2);
      }
      
      public function defineBishaFace(param1:String, param2:Class) : void
      {
         this._effectCtrl.setBishaFace(param1,param2);
      }
      
      public function defineHurtSound(... rest) : void
      {
         this._voiceCtrl.setVoice(0,rest);
      }
      
      public function defineHurtFlySound(... rest) : void
      {
         this._voiceCtrl.setVoice(1,rest);
      }
      
      public function defineDieSound(... rest) : void
      {
         this._voiceCtrl.setVoice(2,rest);
      }
      
      public function initMc(param1:MovieClip) : void
      {
         var _loc2_:FighterMC = null;
         if(Boolean(param1))
         {
            _loc2_ = new FighterMC();
            _loc2_.initlize(param1,this._fighter,this._fighterMcCtrl);
            if(this._doingWankai)
            {
               this._fighter.actionState = 50;
               _loc2_.goFrame("开场");
               this._doingWankai = false;
            }
            else
            {
               this._fighterMcCtrl.idle();
            }
            return;
         }
         throw new Error("FighterCtrler.initMc Error :: mc is null!");
      }
      
      public function getCurrentHits() : Array
      {
         var _loc1_:Array;
         var _loc5_:Array = null;
         var _loc8_:int = 0;
         var _loc7_:Object = null;
         var _loc6_:HitVO = null;
         var _loc4_:* = null;
         var _loc2_:Rectangle = null;
         var _loc3_:String = null;
         try
         {
            _loc5_ = this._fighter.getMC().getCurrentHitArea();
         }
         catch(e:Error)
         {
            trace("FighterCtrler.getCurrentHits::",e);
         }
         if(!_loc5_ || _loc5_.length < 1)
         {
            return null;
         }
         _loc1_ = [];
         while(_loc8_ < _loc5_.length)
         {
            _loc7_ = _loc5_[_loc8_];
            _loc3_ = _loc7_.name;
            _loc6_ = _loc7_.hitVO;
            if(Boolean(_loc6_))
            {
               _loc2_ = _loc7_.area;
               _loc6_.currentArea = this.getCurrentRect(_loc2_,"hit" + _loc8_);
               _loc1_.push(_loc6_);
            }
            _loc8_++;
         }
         return _loc1_;
      }
      
      public function getBodyArea() : Rectangle
      {
         var _loc1_:Rectangle = null;
         try
         {
            _loc1_ = this._fighter.getMC().getCurrentBodyArea();
         }
         catch(e:Error)
         {
            trace("FighterCtrler.getBodyArea::",e);
         }
         if(_loc1_ == null)
         {
            return null;
         }
         return this.getCurrentRect(_loc1_,"body");
      }
      
      public function getHitCheckRect(param1:String) : Rectangle
      {
         var _loc2_:Rectangle = this._fighter.getMC().getCheckHitRect(param1);
         if(_loc2_ == null)
         {
            return null;
         }
         return this.getCurrentRect(_loc2_,"hit_check");
      }
      
      public function getCurrentRect(param1:Rectangle, param2:String = null) : Rectangle
      {
         var _loc3_:Rectangle = null;
         if(param2 == null)
         {
            _loc3_ = new Rectangle();
         }
         else if(Boolean(this._rectCache[param2]))
         {
            _loc3_ = this._rectCache[param2];
         }
         else
         {
            _loc3_ = new Rectangle();
            this._rectCache[param2] = _loc3_;
         }
         _loc3_.x = param1.x * this._fighter.direct + this._fighter.x;
         if(this._fighter.direct < 0)
         {
            _loc3_.x -= param1.width;
         }
         _loc3_.y = param1.y + this._fighter.y;
         _loc3_.width = param1.width;
         _loc3_.height = param1.height;
         return _loc3_;
      }
      
      public function doWanKai(param1:int = 0) : void
      {
         this._doingWankai = true;
         if(param1 == 0)
         {
            this._fighter.mc.nextFrame();
         }
         else
         {
            this._fighter.mc.gotoAndStop(param1);
         }
      }
      
      public function setDirectToTarget() : void
      {
         var _loc1_:IGameSprite = this._fighter.getCurrentTarget();
         if(!_loc1_)
         {
            return;
         }
         this._fighter.direct = this._fighter.x < _loc1_.x ? 1 : -1;
      }
      
      public function moveOnce(param1:Number = 0, param2:Number = 0) : void
      {
         this._fighter.x += param1 * this._fighter.direct;
         this._fighter.y += param2;
      }
      
      public function moveToTarget(param1:Object = null, param2:Object = null, param3:Boolean = true) : void
      {
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:IGameSprite = this._fighter.getCurrentTarget();
         if(!_loc6_)
         {
            return;
         }
         if(param1 != null)
         {
            _loc4_ = Number(param1);
            _loc5_ = _loc6_.x + _loc4_ * this._fighter.direct;
            if(_loc4_ > 0)
            {
               try
               {
                  if(_loc6_.x < _loc4_)
                  {
                     _loc5_ = _loc6_.x + _loc4_;
                  }
                  else if(_loc6_.x > GameCtrl.I.gameState.getMap().right - _loc4_)
                  {
                     _loc5_ = _loc6_.x - _loc4_;
                  }
               }
               catch(e:Error)
               {
               }
            }
            this._fighter.x = _loc5_;
         }
         if(param2 != null)
         {
            this._fighter.y = _loc6_.y + Number(param2);
         }
         if(param3)
         {
            this._fighter.direct = this._fighter.x < _loc6_.x ? 1 : -1;
         }
      }
      
      public function setCross(param1:Boolean) : void
      {
         this._fighter.isCross = param1;
      }
      
      public function getHitRange(param1:String) : Rectangle
      {
         var _loc2_:Rectangle = this._fighter.getMC().getHitRange(param1);
         if(_loc2_ == null)
         {
            return null;
         }
         return this.getCurrentRect(_loc2_,"hitRange_" + param1);
      }
   }
}

