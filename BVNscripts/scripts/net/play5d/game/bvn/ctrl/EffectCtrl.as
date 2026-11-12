package net.play5d.game.bvn.ctrl
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.filters.BitmapFilter;
   import flash.geom.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.fighter.vos.FighterBuffVO;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.state.GameState;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.game.bvn.views.effects.*;
   
   public class EffectCtrl
   {
      
      private static var _i:EffectCtrl;
      
      public static var EFFECT_SMOOTHING:Boolean = true;
      
      public static var SHADOW_ENABLED:Boolean = true;
      
      public static var SHAKE_ENABLED:Boolean = true;
      
      public var shineMaxCount:int = 3;
      
      private var _gameStage:GameState;
      
      private var _effectLayer:Sprite;
      
      private var _manager:EffectManager;
      
      public var freezeEnabled:Boolean = true;
      
      private var _freezeFrame:int = 0;
      
      private var _effects:Vector.<EffectView>;
      
      private var _justRenderAnimateTargets:Vector.<BaseGameSprite>;
      
      private var _justRenderTargets:Vector.<BaseGameSprite>;
      
      private var _shineEffects:Vector.<ShineEffectView>;
      
      private var _shadowEffects:Dictionary;
      
      private var _filterEffects:Vector.<BitmapFilterView> = new Vector.<BitmapFilterView>();
      
      private var _blackBack:BlackBackView;
      
      /**
       * 命中聚焦的目标（3.9 官方 EffectCtrl._hitFocusTarget）。
       * 非空说明镜头正锁在这个目标身上，时停结束时要把镜头收回来。
       */
      private var _hitFocusTarget:IGameSprite;
      
      private var _shakeHoldX:int = 0;
      
      private var _shakeHoldY:int = 0;
      
      private var _shakePowX:int = 0;
      
      private var _shakePowY:int = 0;
      
      private var _shakeXDirect:int = 1;
      
      private var _shakeYDirect:int = 1;
      
      private var _shakeFrameX:int = 0;
      
      private var _shakeFrameY:int = 0;
      
      private var _shakeLoseX:int = 0;
      
      private var _shakeLoseY:int = 0;
      
      private var _renderAnimateGap:int = 0;
      
      private var _renderAnimateFrame:int = 0;
      
      private var _renderAnimate:Boolean = true;
      
      private var _slowDownFrame:int;
      
      private var _replaceSkillFrame:int;
      
      private var _replaceSkillFrameHold:int;
      
      private var _replaceSkillPos:Point;
      
      private var _explodeSkillFrame:int;
      
      private var _explodeEffectPos:Point;
      
      private var _onFreezeOver:Vector.<Function> = null;
      
      public function EffectCtrl()
      {
         super();
      }
      
      public static function get I() : EffectCtrl
      {
         if(!_i)
         {
            _i = new EffectCtrl();
         }
         return _i;
      }
      
      public function destory() : void
      {
         if(Boolean(this._manager))
         {
            this._manager.destory();
            this._manager = null;
         }
         if(Boolean(this._blackBack))
         {
            this._blackBack.destory();
            this._blackBack = null;
         }
         this._effects = null;
         this._justRenderAnimateTargets = null;
         this._justRenderTargets = null;
         this._shineEffects = null;
         this._shadowEffects = null;
         this._gameStage = null;
         this._effectLayer = null;
      }

        /**
         * 局内重开专用：单帧清空所有活动特效与临时表现状态，不销毁管理器本身。
         * 移植自3.7重开流程，按3.3 EffectCtrl 结构实现。
         */
        public function clearAll() : void
        {
           var _loc1_:int = 0;
           var _loc2_:EffectView = null;
           var _loc3_:ShineEffectView = null;
           var _loc4_:ShadowEffectView = null;

           if(Boolean(this._effects))
           {
              while(this._effects.length > 0)
              {
                 _loc2_ = this._effects.pop();
                 if(Boolean(_loc2_))
                 {
                    try
                    {
                       _loc2_.destory();
                    }
                    catch(e:Error)
                    {
                    }
                 }
              }
           }
           if(Boolean(this._shineEffects))
           {
              while(this._shineEffects.length > 0)
              {
                 _loc3_ = this._shineEffects.pop();
                 if(Boolean(_loc3_))
                 {
                    try
                    {
                       _loc3_.destory();
                    }
                    catch(e:Error)
                    {
                    }
                 }
              }
           }
           if(Boolean(this._shadowEffects))
           {
              for each(_loc4_ in this._shadowEffects)
              {
                 try
                 {
                    _loc4_.destory();
                 }
                 catch(e:Error)
                 {
                 }
              }
              this._shadowEffects = new Dictionary();
           }
           if(Boolean(this._filterEffects))
           {
              // 2026-10-25：原来只 `length = 0`，把唯一的引用丢掉就算完。
              // clearDynamicSprites() 先跑时确实已经把视图销毁了，但只要是别的路径调进来
              // （或顺序变了），这些 Bitmap 就会既不在列表里、又还挂在 _playerLayer 上 ——
              // 之后 endFilter 再也找不到它 = 永久残像。这里必须真的回收。
              while(this._filterEffects.length > 0)
              {
                 var _loc5_:BitmapFilterView = this._filterEffects.pop();
                 if(!Boolean(_loc5_))
                 {
                    continue;
                 }
                 try
                 {
                    GameCtrl.I.removeGameSprite(_loc5_,true);
                 }
                 catch(fe:Error)
                 {
                 }
                 try
                 {
                    if(!_loc5_.isDestoryed())
                    {
                       _loc5_.destory(true);
                    }
                 }
                 catch(fe2:Error)
                 {
                 }
              }
           }
           if(Boolean(this._justRenderAnimateTargets))
           {
              this._justRenderAnimateTargets.length = 0;
           }
           if(Boolean(this._justRenderTargets))
           {
              this._justRenderTargets.length = 0;
           }
           if(Boolean(this._blackBack))
           {
              try
              {
                 if(Boolean(this._blackBack.parent))
                 {
                    this._blackBack.parent.removeChild(this._blackBack);
                 }
              }
              catch(e:Error)
              {
              }
              this._blackBack.destory();
              this._blackBack = new BlackBackView();
           }
           // 2026-10-23：局内重开时命中聚焦的镜头也要一起收掉，否则镜头停在被击者身上
           this._hitFocusTarget = null;
           this._freezeFrame = 0;
           this._onFreezeOver = null;
           this._slowDownFrame = 0;
           this._replaceSkillFrame = 0;
           this._replaceSkillFrameHold = 0;
           this._explodeSkillFrame = 0;
           this.freezeEnabled = true;
           if(Boolean(this._gameStage))
           {
              this.endShake();
           }
           this.slowDownResume();
        }
      
      public function initlize(param1:GameState, param2:Sprite) : void
      {
         this._manager = new EffectManager();
         this._gameStage = param1;
         this._effectLayer = param2;
         this._effects = new Vector.<EffectView>();
         this._justRenderAnimateTargets = new Vector.<BaseGameSprite>();
         this._justRenderTargets = new Vector.<BaseGameSprite>();
         this._shineEffects = new Vector.<ShineEffectView>();
         this._shadowEffects = new Dictionary();
         this._blackBack = new BlackBackView();
         this._renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / 30) - 1;
         // 镜头看门狗要判断「必杀黑幕是否还在」，但 state 层不能反向依赖 ctrl 层，
         // 所以由这里把探针注册进 GameState（GameState.probeBlackBack 负责兜异常）。
         param1.bishaBlackProbe = this.isBlackBackShowing;
      }
      
      /**
       * 必杀黑幕是否仍在显示列表里。GameCameraFocusWatch 用它判定「演出已结束」。
       * 注意：bisha()/wanKai() 是先 addChildAt 再聚焦，所以聚焦那一刻这里一定返回 true。
       */
      public function isBlackBackShowing() : Boolean
      {
         return Boolean(this._blackBack) && Boolean(this._blackBack.parent);
      }
      
      public function render() : void
      {
         var _loc2_:* = undefined;
         var _loc1_:int = 0;
         if(this.freezeEnabled)
         {
            this.renderFreeze();
         }
         this.renderSlowDown();
         this.renderShine();
         // 钢身/金身辉光的兜底清扫：endGlow 漏调一次就是一尊永久残像，
         // 只能每帧按「角色还要不要发光」这个唯一真相来自愈。
         this.sweepFilterViews();
         _loc1_ = 0;
         while(_loc1_ < this._effects.length)
         {
            this._effects[_loc1_].render();
            _loc1_++;
         }
         if(this.isRenderAnimate())
         {
            this.renderAnimate();
         }
         if(this._replaceSkillFrameHold > 0)
         {
            this.renderReplaceSkill();
         }
         if(this._explodeSkillFrame > 0)
         {
            this.renderEnergyExplode();
         }
         if(this._justRenderTargets.length > 0)
         {
            for each(_loc2_ in this._justRenderTargets)
            {
               _loc2_.render();
               GameLogic.fixGameSpritePosition(_loc2_);
            }
         }
      }
      
      private function renderShine() : void
      {
         var _loc1_:ShineEffectView = null;
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < this._shineEffects.length)
         {
            _loc1_ = this._shineEffects[_loc2_];
            _loc1_.render();
            _loc2_++;
         }
      }
      
      private function renderAnimate() : void
      {
         var _loc1_:* = null;
         var _loc2_:EffectView = null;
         var _loc3_:* = null;
         var _loc4_:* = null;
         var _loc5_:* = null;
         var _loc6_:int = 0;
         _loc6_ = 0;
         while(_loc6_ < this._effects.length)
         {
            _loc2_ = this._effects[_loc6_];
            _loc2_.renderAnimate();
            _loc6_++;
         }
         for each(_loc3_ in this._shadowEffects)
         {
            _loc3_.render();
         }
         if(this._justRenderAnimateTargets.length > 0)
         {
            for each(_loc5_ in this._justRenderAnimateTargets)
            {
               _loc5_.renderAnimate();
            }
         }
         if(Boolean(this._blackBack))
         {
            this._blackBack.renderAnimate();
         }
         this.renderShakeX();
         this.renderShakeY();
      }
      
      private function isRenderAnimate() : Boolean
      {
         if(this._renderAnimateGap > 0)
         {
            if(this._renderAnimateFrame++ >= this._renderAnimateGap)
            {
               this._renderAnimateFrame = 0;
               return true;
            }
            return false;
         }
         return true;
      }
      
      private function renderFreeze() : void
      {
         var _loc1_:int = 0;
         if(this._freezeFrame > 0)
         {
            --this._freezeFrame;
            if(this._freezeFrame <= 0)
            {
               if(Boolean(this._onFreezeOver))
               {
                  while(_loc1_ < this._onFreezeOver.length)
                  {
                     this._onFreezeOver[_loc1_]();
                     _loc1_++;
                  }
                  this._onFreezeOver = null;
               }
               // 2026-10-23：命中聚焦的镜头在这时收回（3.9 官方 EffectCtrl.renderFreeze 同一处）。
               if(Boolean(this._hitFocusTarget))
               {
                  this._hitFocusTarget = null;
                  if(Boolean(GameCtrl.I.gameState))
                  {
                     GameCtrl.I.gameState.cameraResume();
                  }
               }
               GameCtrl.I.resume();
            }
         }
      }
      
      private function renderShakeX() : void
      {
         var _loc1_:Number = this._shakeHoldX + this._shakePowX;
         if(_loc1_ > 0)
         {
            this._gameStage.x = _loc1_ * this._shakeXDirect;
            if(this._shakePowX > 0 && this._shakeFrameX % 2 == 0)
            {
               this._shakePowX -= this._shakeLoseX;
               if(this._shakePowX < this._shakeLoseX)
               {
                  this._shakePowX = 0;
                  this._gameStage.x = 0;
                  this._shakeFrameX = 0;
                  this._shakeLoseX = 0;
                  return;
               }
            }
            ++this._shakeFrameX;
            this._shakeXDirect *= -1;
         }
      }
      
      private function renderShakeY() : void
      {
         var _loc1_:Number = this._shakeHoldY + this._shakePowY;
         if(_loc1_ > 0)
         {
            this._gameStage.y = _loc1_ * this._shakeYDirect;
            if(this._shakePowY > 0 && this._shakeFrameY % 2 == 0)
            {
               this._shakePowY -= this._shakeLoseY;
               if(this._shakePowY < this._shakeLoseY)
               {
                  this._shakePowY = 0;
                  this._gameStage.y = 0;
                  this._shakeFrameY = 0;
                  this._shakeLoseY = 0;
                  return;
               }
            }
            this._shakeYDirect *= -1;
            ++this._shakeFrameY;
         }
      }
      
      public function doHitEffect(param1:HitVO, param2:Rectangle, param3:IGameSprite = null) : void
      {
         var _loc4_:EffectVO = this._manager.getEffectVOByHitVO(param1);
         if(!_loc4_)
         {
            return;
         }
         var _loc5_:Number = param2.x + param2.width / 2;
         var _loc6_:Number = param2.y + param2.height / 2;
         var _loc7_:int = 1;
          if(Boolean(_loc4_.followDirect) && Boolean(param1.owner) && param1.owner is IGameSprite)
         {
             _loc7_ = int((param1.owner as IGameSprite).direct);
          }
         // 2026-10-23：命中聚焦（3.9 官方 EffectCtrl.doHitEffect 的 focusTarget 分支）。
         // 角色包在 defineAction 里写 focusTarget:true 时，镜头拉到被击者身上；
         // 该次时停结束时由 renderFreeze() 收回（cameraResume）。
         if(param1.focusTarget)
         {
            this._hitFocusTarget = param3;
            if(Boolean(param3) && Boolean(GameCtrl.I.gameState))
            {
               GameCtrl.I.gameState.cameraFocusOne(param3.getDisplay());
            }
         }
         else if(Boolean(this._hitFocusTarget) && this._hitFocusTarget == param3)
         {
            this._hitFocusTarget = null;
         }
         this.doEffectVO(_loc4_,_loc5_,_loc6_,_loc7_,param3);
       }
      
      public function doDefenseEffect(param1:HitVO, param2:Rectangle, param3:int, param4:IGameSprite = null) : void
      {
         var _loc5_:int = param1.hitType;
         switch(param3)
         {
            case 0:
               break;
            case 1:
               if(_loc5_ == 1)
               {
                  _loc5_ = 2;
               }
               if(_loc5_ == 6)
               {
                  _loc5_ = 3;
               }
         }
         var _loc6_:EffectVO = EffectModel.I.getDefenseEffect(_loc5_);
         if(!_loc6_)
         {
            return;
         }
         var _loc7_:Number = param2.x + param2.width / 2;
         var _loc8_:Number = param2.y + param2.height / 2;
         if(Boolean(_loc6_.shake))
         {
            if(_loc6_.shake.pow != undefined && _loc6_.shake.pow != 0)
            {
               _loc6_.shake.x = 0;
               _loc6_.shake.y = _loc6_.shake.pow;
            }
         }
         var _loc9_:int = 1;
         if(Boolean(_loc6_.followDirect) && Boolean(param1.owner) && param1.owner is IGameSprite)
         {
            _loc9_ = int((param1.owner as IGameSprite).direct);
         }
         this.doEffectVO(_loc6_,_loc7_,_loc8_,_loc9_,param4);
      }
      
      public function doSteelHitEffect(param1:HitVO, param2:Rectangle, param3:IGameSprite) : void
      {
         var _loc4_:EffectVO = null;
         switch(param1.hitType)
         {
            case 0:
               return;
            case 1:
            case 6:
               _loc4_ = EffectModel.I.getEffect("steel_hit_kan");
               break;
            case 2:
            case 3:
               _loc4_ = EffectModel.I.getEffect("steel_hit_qdj");
               break;
            default:
               _loc4_ = EffectModel.I.getEffect("steel_hit_mfdj");
         }
         if(!_loc4_)
         {
            return;
         }
         var _loc5_:Number = param2.x + param2.width / 2;
         var _loc6_:Number = param2.y + param2.height / 2;
         var _loc7_:int = 1;
          if(Boolean(_loc4_.followDirect) && Boolean(param1.owner) && param1.owner is IGameSprite)
          {
             _loc7_ = int((param1.owner as IGameSprite).direct);
          }
          // 2026-09-09 竞技规则移植：刚身停顿关闭时，钢体命中特效不冻结、不闪光
          if(!GameData.I.config.isSteelBodyFreeze)
          {
             _loc4_ = _loc4_.clone();
             _loc4_.freeze = 0;
             _loc4_.shine = {};
          }
         this.doEffectVO(_loc4_,_loc5_,_loc6_,_loc7_,param3);
       }
      
      public function doEffectById(param1:String, param2:Number, param3:Number, param4:int = 1, param5:IGameSprite = null) : void
      {
         var _loc6_:EffectVO = EffectModel.I.getEffect(param1);
         if(Boolean(_loc6_))
         {
            this.doEffectVO(_loc6_,param2,param3,param4,param5);
         }
      }
      
      public function assisterEffect(param1:Assister) : void
      {
         var _loc2_:* = param1.data.comicType == 1;
         if(Boolean(_loc2_))
         {
            this.doEffectById("fz_naruto",param1.x,param1.y);
         }
         else
         {
            this.doEffectById("fz_bleach",param1.x,param1.y);
         }
      }
      
      public function doEffectVO(param1:EffectVO, param2:Number, param3:Number, param4:int = 1, param5:IGameSprite = null) : void
      {
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:* = 0;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc12_:int = 0;
         var _loc13_:EffectView = this.addEffect(param1,param2,param3,param4);
         if(Boolean(_loc13_))
         {
            this._effectLayer.addChild(_loc13_.display);
         }
         if(param1.freeze > 0)
         {
            this.freeze(param1.freeze);
         }
         if(Boolean(param1.shake))
         {
            _loc6_ = Number(param1.shake.time != undefined ? param1.shake.time : 0);
            _loc7_ = Number(param1.shake.x != undefined ? param1.shake.x : 0);
            _loc8_ = Number(param1.shake.y != undefined ? param1.shake.y : 0);
            this.shake(_loc7_,_loc8_,_loc6_);
         }
         if(Boolean(param1.shine))
         {
            _loc9_ = uint(param1.shine.color != undefined ? param1.shine.color : 16777215);
            _loc10_ = Number(param1.shine.alpha != undefined ? param1.shine.alpha : 0.2);
            this.shine(_loc9_,_loc10_);
         }
         if(Boolean(param1.slowDown))
         {
            _loc11_ = Number(param1.slowDown.rate != undefined ? param1.slowDown.rate : 1.5);
            _loc12_ = int(param1.slowDown.time != undefined ? param1.slowDown.time : 1000);
            this.slowDown(_loc11_,_loc12_);
         }
         if(Boolean(param5))
         {
            _loc13_.setTarget(param5);
         }
         if(Boolean(param1.specialEffectId) && Boolean(param5) && param5 is FighterMain)
         {
            this.doSpecialEffect(param1.specialEffectId,param5 as FighterMain);
         }
      }
      
      public function doSpecialEffect(param1:String, param2:FighterMain) : void
      {
         var _loc3_:EffectVO = EffectModel.I.getEffect(param1);
         var _loc4_:SpecialEffectView = this.addEffect(_loc3_,param2.x,param2.y,param2.direct) as SpecialEffectView;
         if(Boolean(_loc4_))
         {
            _loc4_.setTarget(param2);
            this._effectLayer.addChild(_loc4_.display);
         }
      }
      
      public function doBuffEffect(param1:String, param2:FighterMain, param3:FighterBuffVO) : void
      {
         var _loc4_:EffectVO = EffectModel.I.getEffect(param1);
         var _loc5_:BuffEffectView = this.addEffect(_loc4_,param2.x,param2.y,param2.direct) as BuffEffectView;
         if(Boolean(_loc5_))
         {
            _loc5_.setTarget(param2);
            _loc5_.setBuff(param3);
            this._effectLayer.addChild(_loc5_.display);
         }
      }
      
      private function addEffect(param1:EffectVO, param2:Number, param3:Number, param4:int = 1) : EffectView
      {
         var _loc5_:EffectView = this._manager.getEffectView(param1);
         if(!_loc5_)
         {
            return null;
         }
         _loc5_.start(param2,param3,param4);
         _loc5_.addRemoveBack(this.removeEffect);
         this._effects.push(_loc5_);
         return _loc5_;
      }
      
      private function removeEffect(param1:EffectView) : void
      {
         var _loc2_:int = int(this._effects.indexOf(param1));
         if(_loc2_ != -1)
         {
            this._effects.splice(_loc2_,1);
         }
      }
      
      public function freeze(param1:int) : void
      {
         if(!this.freezeEnabled)
         {
            return;
         }
         if(param1 < 1)
         {
            return;
         }
         var _loc2_:int = param1 / 1000 * GameConfig.FPS_GAME;
         if(_loc2_ < 1)
         {
            return;
         }
         this._freezeFrame = _loc2_;
         GameCtrl.I.pause();
      }
      
      private function justRender(param1:BaseGameSprite) : void
      {
         if(this._justRenderTargets.indexOf(param1) == -1)
         {
            this._justRenderTargets.push(param1);
         }
      }
      
      private function justRenderAnimate(param1:BaseGameSprite) : void
      {
         if(this._justRenderAnimateTargets.indexOf(param1) == -1)
         {
            this._justRenderAnimateTargets.push(param1);
         }
      }
      
      private function cancelJustRender(param1:BaseGameSprite) : Boolean
      {
         var _loc2_:int = int(this._justRenderTargets.indexOf(param1));
         if(_loc2_ == -1)
         {
            // 2026-10-21：没登记过就说明该角色本来就不在瞬步/必杀里。
            // 原实现会返回「列表已空 === true」，于是人物包里漏出来的帧脚本一调
            // endBisha()/endGhostStep() 就会被当成合法收尾，去 resume 全局暂停、fadOut 黑幕。
            return false;
         }
         this._justRenderTargets.splice(_loc2_,1);
         return this._justRenderTargets.length < 1;
      }
      
      private function cancelJustRenderAnimate(param1:BaseGameSprite) : Boolean
      {
         var _loc2_:int = int(this._justRenderAnimateTargets.indexOf(param1));
         if(_loc2_ == -1)
         {
            // 2026-10-21：同上。本次卡死的直接原因就是这条误判：
            // 人物包在人物_1 的 frame1 里无条件调 effect_ctrler.endBisha()，
            // 开局 addFighter -> initMc -> idle() -> gotoAndStop 触发该帧脚本，
            // endBisha 误判为「合法收尾」-> GameState.cameraResume()，而此刻镜头还没建
            // （initCamera 在 buildGame 后面的 initFight 里）-> #1009 -> 整个 buildGame 中断。
            return false;
         }
         this._justRenderAnimateTargets.splice(_loc2_,1);
         return this._justRenderAnimateTargets.length < 1;
      }
      
      public function shine(param1:uint = 16777215, param2:Number = 0.2) : void
      {
         if(GameConfig.FPS_SHINE_EFFECT == 0)
         {
            return;
         }
         if(this._shineEffects.length > this.shineMaxCount)
         {
            this._shineEffects[0].removeSelf();
         }
         var _loc3_:ShineEffectView = this._manager.getShine();
         _loc3_.init(param1,param2);
         _loc3_.onRemove = this.removeShine;
         this._shineEffects.push(_loc3_);
         this._gameStage.addChild(_loc3_);
      }
      
      private function removeShine(param1:ShineEffectView) : void
      {
         var _loc2_:int = int(this._shineEffects.indexOf(param1));
         if(_loc2_ != -1)
         {
            this._shineEffects.splice(_loc2_,1);
         }
      }
      
      public function startShake(param1:Number, param2:Number) : void
      {
         this._shakeHoldX = param1;
         this._shakeHoldY = param2;
      }
      
      public function endShake() : void
      {
         this._shakeHoldX = 0;
         this._shakeHoldY = 0;
         this._gameStage.x = 0;
         this._gameStage.y = 0;
      }
      
      public function shake(param1:Number = 0, param2:Number = 3, param3:int = 500) : void
      {
         if(!SHAKE_ENABLED)
         {
            return;
         }
         if(Boolean(isNaN(param1)) || Boolean(isNaN(param2)))
         {
            return;
         }
         if(param1 != 0)
         {
            if(this._shakePowX == 0)
            {
               this._shakeXDirect = param1 > 0 ? 1 : -1;
               this._shakePowX = Math.abs(param1);
            }
            else
            {
               this._shakePowX += Math.abs(param1) / 2;
            }
         }
         if(param2 != 0)
         {
            if(this._shakePowY == 0)
            {
               this._shakeYDirect = param2 > 0 ? 1 : -1;
               this._shakePowY = Math.abs(param2);
            }
            else
            {
               this._shakePowY += Math.abs(param2) / 2;
            }
         }
         if(param3 <= 0)
         {
            param3 = 500;
         }
         this._shakeLoseX = Math.ceil(this._shakePowX / (param3 / 1000 * 30));
         this._shakeLoseY = Math.ceil(this._shakePowY / (param3 / 1000 * 30));
         if(this._shakeLoseX < 1)
         {
            this._shakeLoseX = 1;
         }
         if(this._shakeLoseY < 1)
         {
            this._shakeLoseY = 1;
         }
      }
      
      public function startShadow(param1:DisplayObject, param2:int = 0, param3:int = 0, param4:int = 0) : void
      {
         if(!SHADOW_ENABLED)
         {
            return;
         }
         var _loc5_:ShadowEffectView = this._shadowEffects[param1];
         if(Boolean(_loc5_))
         {
            _loc5_.r = param2;
            _loc5_.g = param3;
            _loc5_.b = param4;
            _loc5_.stopShadow = false;
            return;
         }
         _loc5_ = new ShadowEffectView(param1,param2,param3,param4);
         _loc5_.onRemove = this.removeShadow;
         _loc5_.container = this._effectLayer;
         this._shadowEffects[param1] = _loc5_;
      }
      
      public function endShadow(param1:DisplayObject) : void
      {
         if(!SHADOW_ENABLED)
         {
            return;
         }
         if(!this._shadowEffects)
         {
            return;
         }
         var _loc2_:ShadowEffectView = this._shadowEffects[param1];
         if(Boolean(_loc2_))
         {
            _loc2_.stopShadow = true;
         }
      }
      
      private function removeShadow(param1:ShadowEffectView) : void
      {
         if(!this._shadowEffects)
         {
            return;
         }
         delete this._shadowEffects[param1.target];
      }
      
      public function bisha(param1:BaseGameSprite, param2:Boolean = false, param3:DisplayObject = null) : void
      {
         this.justRenderAnimate(param1);
         GameCtrl.I.pause();
         GameCtrl.I.setRenderHit(false);
         this._gameStage.addChildAt(this._blackBack,0);
         this._blackBack.fadIn();
         if(Boolean(param3) && param1 is FighterMain)
         {
            this.showFace(param1 as FighterMain,param3);
         }
         if(param2)
         {
            GameCtrl.I.gameState.cameraFocusBisha(param1.getDisplay());
            this.doEffectById("bisha_super",param1.x,param1.y - 50);
         }
         else
         {
            this.doEffectById("bisha",param1.x,param1.y - 50);
         }
         this._gameStage.getMap().setVisible(false);
         this._gameStage.setVisibleByClass(BitmapFilterView,false);
      }
      
      public function endBisha(param1:BaseGameSprite) : void
      {
         var _loc2_:Boolean = this.cancelJustRenderAnimate(param1);
         // 2026-10-23：「endBisha = 取消镜头」是角色包的通用约定，必须无条件执行。
         // 原来把 cameraResume 挂在 cancelJustRenderAnimate()==true 里，而那个判据在
         // 第二次调用时必然 false —— 人物包（赛马娘 东海帝王）先 endBisha 再自己
         // camera.focus() 摆特写、靠下一次 endBisha 收尾，那一次就被整段跳过，
         // 镜头永远停在特写目标上。
         if(Boolean(GameCtrl.I.gameState))
         {
            GameCtrl.I.gameState.cameraResumeByEffect();
         }
         if(_loc2_)
         {
            // 先恢复命中判定：这一行一旦被跳过就是「全场打不动」（看起来像永久金身），
            // 不能因为后面镜头/黑幕任一步抛异常而丢失。
            GameCtrl.I.setRenderHit(true);
            GameCtrl.I.resume();
            this._blackBack.fadOut();
            this._gameStage.getMap().setVisible(true);
            this._gameStage.setVisibleByClass(BitmapFilterView,true);
         }
      }
      
      private function showFace(param1:FighterMain, param2:DisplayObject) : void
      {
         var _loc3_:DisplayObject = null;
         var _loc4_:int = 1;
         var _loc5_:IGameSprite = param1.getCurrentTarget();
         if(Boolean(_loc5_))
         {
            _loc3_ = _loc5_.getDisplay();
            if(Boolean(_loc3_))
            {
               _loc4_ = param1.getDisplay().x > _loc3_.x ? 2 : 1;
            }
         }
         this._blackBack.showBishaFace(_loc4_,param2);
      }
      
      public function wanKai(param1:FighterMain, param2:DisplayObject = null) : void
      {
         this.justRenderAnimate(param1);
         GameCtrl.I.pause();
         GameCtrl.I.setRenderHit(false);
         this._gameStage.addChildAt(this._blackBack,0);
         this._blackBack.fadIn();
         if(Boolean(param2))
         {
            this.showFace(param1,param2);
         }
         GameCtrl.I.gameState.cameraFocusBisha(param1.getDisplay());
         this.doEffectById("bisha_super",param1.x,param1.y - 50);
         this._gameStage.getMap().setVisible(false);
         this._gameStage.setVisibleByClass(BitmapFilterView,false);
      }
      
      public function endWanKai(param1:FighterMain) : void
      {
         var _loc2_:Boolean = this.cancelJustRenderAnimate(param1);
         // 同 endBisha：「endWanKai = 取消镜头」，无条件恢复
         if(Boolean(GameCtrl.I.gameState))
         {
            GameCtrl.I.gameState.cameraResumeByEffect();
         }
         if(_loc2_)
         {
            // 同 endBisha：命中判定必须在任何可能抛异常的操作之前恢复
            GameCtrl.I.setRenderHit(true);
            GameCtrl.I.resume();
            this._blackBack.fadOut();
            this._gameStage.getMap().setVisible(true);
         }
      }
      
      public function jumpEffect(param1:Number, param2:Number) : void
      {
         this.doEffectById("jump",param1,param2);
      }
      
      public function jumpAirEffect(param1:Number, param2:Number) : void
      {
         this.doEffectById("jump_air",param1,param2);
      }
      
      public function touchFloorEffect(param1:Number, param2:Number) : void
      {
         this.doEffectById("touch_floor",param1,param2);
      }
      
      public function hitFloorEffect(param1:int, param2:Number, param3:Number) : void
      {
         switch(param1)
         {
            case 0:
               this.doEffectById("hit_floor",param2,param3);
               break;
            case 1:
               this.doEffectById("hit_floor_low",param2,param3);
               break;
            case 2:
               this.doEffectById("hit_floor_heavy",param2,param3);
               this.doEffectById("hit_floor_yan",param2,param3);
         }
      }
      
      public function slowDown(param1:Number, param2:int = 1000) : void
      {
         GameCtrl.I.slow(param1);
         this._renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / (30 / param1)) - 1;
         if(param2 == 0)
         {
            this._slowDownFrame = 0;
         }
         else
         {
            this._slowDownFrame = param2 / 1000 * GameConfig.FPS_GAME;
         }
      }
      
      private function renderSlowDown() : void
      {
         if(this._slowDownFrame > 0)
         {
            --this._slowDownFrame;
            if(this._slowDownFrame <= 0)
            {
               this.slowDownResume();
            }
         }
      }
      
      public function slowDownResume() : void
      {
         GameCtrl.I.slowResume();
         this._renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / 30) - 1;
         this._slowDownFrame = 0;
      }
      
      public function BGEffect(param1:String, param2:Number = -1) : void
      {
         var effect:EffectView = null;
         var id:String = param1;
         var hold:Number = param2;
         var data:EffectVO = EffectModel.I.getEffect(id);
         if(!data)
         {
            return;
         }
         effect = this.addEffect(data,0,0,1);
         if(hold != -1)
         {
            effect.holdFrame = hold * 30;
         }
         if(Boolean(effect))
         {
            effect.addRemoveBack(function():void
            {
               _gameStage.getMap().setVisible(true);
            });
            this._gameStage.getMap().setVisible(false);
            this._gameStage.addChildAt(effect.display,0);
         }
      }
      
      public function setOnFreezeOver(param1:Function) : void
      {
         if(!this._onFreezeOver)
         {
            this._onFreezeOver = new Vector.<Function>();
         }
         this._onFreezeOver.push(param1);
      }
      
      public function replaceSkill(param1:BaseGameSprite) : void
      {
         GameCtrl.I.pause();
         this._gameStage.addChildAt(this._blackBack,0);
         this._gameStage.getMap().setVisible(false);
         this.doEffectById("replaceSp",param1.x,param1.y);
         this._replaceSkillPos = new Point(param1.x,param1.y);
         this._replaceSkillFrame = 0;
         this._replaceSkillFrameHold = GameConfig.FPS_GAME;
      }
      
      private function endReplaceSkill() : void
      {
         GameCtrl.I.resume();
         this._blackBack.fadOut();
         this._gameStage.getMap().setVisible(true);
         this._replaceSkillFrameHold = 0;
      }
      
      private function renderReplaceSkill() : void
      {
         ++this._replaceSkillFrame;
         if(this._replaceSkillFrame == 1)
         {
            this.doEffectById("replaceSp2",this._replaceSkillPos.x,this._replaceSkillPos.y);
         }
         if(this._replaceSkillFrame > this._replaceSkillFrameHold)
         {
            this.endReplaceSkill();
         }
      }
      
      public function energyExplode(param1:BaseGameSprite) : void
      {
         GameCtrl.I.pause();
         this._gameStage.addChildAt(this._blackBack,0);
         this._gameStage.getMap().setVisible(false);
         this.doEffectById("explodeSp",param1.x,param1.y);
         this._explodeEffectPos = new Point(param1.x,param1.y);
         this._explodeSkillFrame = 0.7 * GameConfig.FPS_GAME;
      }
      
      private function endEnergyExplode() : void
      {
         this.doEffectById("explodeSp2",this._explodeEffectPos.x,this._explodeEffectPos.y);
         GameCtrl.I.resume();
         this._blackBack.fadOut();
         this._gameStage.getMap().setVisible(true);
         this._explodeSkillFrame = 0;
      }
      
      private function renderEnergyExplode() : void
      {
         --this._explodeSkillFrame;
         if(this._explodeSkillFrame <= 0)
         {
            this.endEnergyExplode();
         }
      }
      
      public function ghostStep(param1:BaseGameSprite) : void
      {
         this.justRender(param1);
         this.justRenderAnimate(param1);
         GameCtrl.I.pause();
         this._gameStage.addChildAt(this._blackBack,0);
         this._blackBack.fadIn();
         this._gameStage.getMap().setVisible(false);
         SoundCtrl.I.playSwcSound(snd_ghost_jump);
      }
      
      public function endGhostStep(param1:BaseGameSprite) : void
      {
         var _loc2_:Boolean = Boolean(this.cancelJustRender(param1));
         var _loc3_:Boolean = Boolean(this.cancelJustRenderAnimate(param1));
         if(_loc2_ && _loc3_)
         {
            GameCtrl.I.resume();
            this._blackBack.fadOut();
            this._gameStage.getMap().setVisible(true);
         }
      }
      
      public function startFilter(param1:BaseGameSprite, param2:BitmapFilter, param3:Point = null) : void
      {
         if(!GameConfig.FILTER_EFFECT_ENABLED)
         {
            // 手机端关掉「滤镜效果（实验功能）」：不新建轮廓视图；
            // 若切换开关前已有该目标的视图，顺带回收，避免留下定格发光残像。
            this.endFilter(param1);
            return;
         }
         var _loc5_:* = undefined;
         var _loc4_:* = null;
         for each(_loc5_ in this._filterEffects)
         {
            if(_loc5_.target == param1)
            {
               _loc4_ = _loc5_;
               break;
            }
         }
         if(!_loc4_)
         {
            _loc4_ = new BitmapFilterView(param1,param2,param3);
            GameCtrl.I.addGameSprite(0,_loc4_,0);
            this._filterEffects.push(_loc4_);
         }
         else
         {
            _loc4_.update(param2,param3);
         }
      }
      
      public function endFilter(param1:BaseGameSprite) : void
      {
         var _loc2_:int = 0;
         var _loc3_:BitmapFilterView = null;
         _loc2_ = 0;
         while(_loc2_ < this._filterEffects.length)
         {
            _loc3_ = this._filterEffects[_loc2_];
            if(_loc3_.target == param1)
            {
               GameCtrl.I.removeGameSprite(_loc3_,true);
               this._filterEffects.splice(_loc2_,1);
               break;
            }
            _loc2_++;
         }
      }

      /**
       * 钢身/金身辉光的兜底清扫（2026-10-25）。
       *
       * `BitmapFilterView` 是独立 game sprite（`_playerLayer` 上的 Bitmap），只靠
       * `endGlow()` → `endFilter()` 这一条路回收。只要有一条路径漏掉它 ——
       * 帧窗口被别处提前打断、换人/KO 先摘渲染列表、`_isGlowIng` 与实际状态不同步、
       * 重开后 `_filterEffects` 被清空而视图还挂在场上的旧包里 —— 这个 Bitmap 就会
       * 永远留在舞台上；而且它自己按帧号缓存，连像素都不再更新，表现就是一尊
       * **定格的发光残像**（"刚身被打之后光晕留着不走"）。
       *
       * 这里把「该不该发光」的最终解释权交回角色本人，每帧只做两条 O(n) 判据：
       *   1. 目标已销毁 / 视图已离开舞台 → 立刻回收；
       *   2. 目标是 FighterMain，而 isSteelBody / isSuperSteelBody 都为 false → 立刻回收。
       * `startFilter()` 目前只有 `startGlow()` 一个调用方（钢身/金身），所以 2 不会误伤。
       */
      private function sweepFilterViews() : void
      {
         if(this._filterEffects == null || this._filterEffects.length == 0)
         {
            return;
         }
         var i:int = this._filterEffects.length - 1;
         while(i >= 0)
         {
            var v:BitmapFilterView = this._filterEffects[i];
            i--;
            if(v == null)
            {
               continue;
            }
            var dead:Boolean = !GameConfig.FILTER_EFFECT_ENABLED;
            var tgt:BaseGameSprite = v.target;
            var disp:DisplayObject = null;
            try
            {
               disp = v.getDisplay();
            }
            catch(de:Error)
            {
               disp = null;
            }
            if(v.isDestoryed() || disp == null || disp.parent == null)
            {
               dead = true;
            }
            else if(tgt == null || tgt.isDestoryed())
            {
               dead = true;
            }
            else if(tgt is FighterMain && !(tgt as FighterMain).isSteelBody
                    && !(tgt as FighterMain).isSuperSteelBody)
            {
               dead = true;
            }
            if(!dead)
            {
               continue;
            }
            var idx:int = this._filterEffects.indexOf(v);
            if(idx >= 0)
            {
               this._filterEffects.splice(idx,1);
            }
            try
            {
               GameCtrl.I.removeGameSprite(v,true);
            }
            catch(e:Error)
            {
            }
            // removeGameSprite 在「视图不在 _gameSprites 里」时会早退，显示对象自己得再摘一次
            try
            {
               if(disp != null && disp.parent != null)
               {
                  disp.parent.removeChild(disp);
               }
            }
            catch(re:Error)
            {
            }
            try
            {
               if(!v.isDestoryed())
               {
                  v.destory(true);
               }
            }
            catch(ve:Error)
            {
            }
         }
      }

      /**
       * 查询某个显示对象当前是否被 BitmapFilterView（钢身/金身/自定义辉光）占用。
       *
       * 2026-10-23 新增，纯只读，不改 _filterEffects 的任何状态。
       * 用途：GPU 滤镜位图代理层必须给这条链路让位 —— BitmapFilterView 烘的是
       * FighterMain.getDisplay()，如果代理层把同一个节点 alpha 置 0，辉光会烘出空白。
       */
      public function isFilterTarget(param1:DisplayObject) : Boolean
      {
         if(param1 == null || this._filterEffects == null)
         {
            return false;
         }
         var i:int = 0;
         var n:int = this._filterEffects.length;
         while(i < n)
         {
            var v:BitmapFilterView = this._filterEffects[i];
            if(v != null && v.target != null && v.target.getDisplay() == param1)
            {
               return true;
            }
            i++;
         }
         return false;
      }
   }
}
