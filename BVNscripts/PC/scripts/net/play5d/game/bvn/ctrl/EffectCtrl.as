package net.play5d.game.bvn.ctrl
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.filters.BitmapFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.effect.GameMeltCtrl;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.EffectModel;
   import net.play5d.game.bvn.data.EffectVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.fighter.vos.FighterBuffVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.stage.GameStage;
   import net.play5d.game.bvn.utils.EffectManager;
   import net.play5d.game.bvn.views.effects.BitmapFilterView;
   import net.play5d.game.bvn.views.effects.BlackBackView;
   import net.play5d.game.bvn.views.effects.BuffEffectView;
   import net.play5d.game.bvn.views.effects.EffectView;
   import net.play5d.game.bvn.views.effects.ImpactEffectView;
   import net.play5d.game.bvn.views.effects.ShadowEffectView;
   import net.play5d.game.bvn.views.effects.ShineEffectView;
   import net.play5d.game.bvn.views.effects.SpecialEffectView;
   import net.play5d.game.bvn.win.input.JoyRumble;
   import net.play5d.kyo.utils.KyoUtils;
   import net.play5d.kyo.utils.UUID;
   
   public class EffectCtrl
   {
      
      public static var EFFECT_SMOOTHING:Boolean = true;
      
      public static var SHADOW_ENABLED:Boolean = true;
      
      public static var SHAKE_ENABLED:Boolean = true;
      
      public static var BG_BULR_ENABLED:Boolean = true;
      
      private static var _i:EffectCtrl;
      
      public var shineMaxCount:int = 3;
      
      private var _gameStage:GameStage;
      
      private var _effectLayer:Sprite;
      
      private var _manager:EffectManager;
      
      public var freezeEnabled:Boolean = true;
      
      public var bgBlurEnabled:Boolean = true;
      
      private const SHAKE_POW_MAX:int = 10;
      
      private var _freezeFrame:int = 0;
      
      private var _effects:Vector.<EffectView>;
      
      private var _justRenderAnimateTargets:Vector.<BaseGameSprite>;
      
      private var _justRenderTargets:Vector.<BaseGameSprite>;
      
      private var _shineEffects:Vector.<ShineEffectView>;
      
      private var _shadowEffects:Dictionary;
      
      private var _filterEffects:Vector.<BitmapFilterView> = new Vector.<BitmapFilterView>();
      
      private var _blackBack:BlackBackView;
      
      private var _impactEffects:Array;
      
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
      
      private var _blurFrame:int;
      
      private var _replaceSkillFrame:int;
      
      private var _replaceSkillFrameHold:int;
      
      private var _replaceSkillPos:Point;
      
      private var _explodeSkillFrame:int;
      
      private var _explodeEffectPos:Point;
      
      private var _onFreezeOver:Vector.<Function> = null;
      
      private var _hitFocusTarget:IGameSprite;
      
      private var _frameEffectCount:Dictionary = new Dictionary();
      
      private var _removeEnemieMap:Object = {};
      
      private var wayPoints:Array = [{
         "P":"p1",
         "N":null
      },{
         "P":"p2",
         "N":"p1"
      },{
         "P":"p2_1",
         "N":"p2"
      },{
         "P":"p2_2",
         "N":"p2"
      },{
         "P":"p3",
         "N":["p2_1","p2_2"]
      },{
         "P":"p3_1",
         "N":"p3"
      },{
         "P":"p3_1_1",
         "N":"p3_1"
      },{
         "P":"p3_1_2",
         "N":"p3_1_1"
      },{
         "P":"p3_2",
         "N":"p3"
      },{
         "P":"p3_2_4",
         "N":"p3_2"
      },{
         "P":"p3_2_3",
         "N":"p3_2_4"
      },{
         "P":"p3_2_1",
         "N":"p3_2"
      },{
         "P":"p3_2_2",
         "N":"p3_2_1"
      },{
         "P":"p3_2_5",
         "N":"p3_2_4"
      },{
         "P":"p3_2_6",
         "N":["p3_2_5","p3_2_4"]
      },{
         "P":"p4",
         "N":["p3_1_2","p3_2_5"]
      },{
         "P":"p5",
         "N":"p3_2_6"
      }];
      
      private var _renderBlackBack:Boolean = false;
      
      private var _isRenderBlackBack:Boolean = false;
      
      private var _meltCtrl:GameMeltCtrl;
      
      private var _isDestoryed:Boolean;
      
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
      
      public static function enemyBirthEffect(param1:FighterMain) : void
      {
         param1.getDisplay().alpha = 1;
         switch(param1.data.comicType)
         {
            case 0:
               EffectCtrl.I.doEffectById("fz_bleach",param1.x,param1.y,param1.direct,null,false);
               break;
            default:
               EffectCtrl.I.doEffectById("fz_naruto",param1.x,param1.y,param1.direct,null,false);
         }
      }
      
      public function getMeltCtrl() : GameMeltCtrl
      {
         return _meltCtrl;
      }
      
      public function destory() : void
      {
         if(_isDestoryed)
         {
            return;
         }
         _isDestoryed = true;
         endShake();
         GameCtrl.I.resume();
         _blackBack.fadOut();
         _gameStage.getMap().setVisible(true);
         _replaceSkillFrame = _explodeSkillFrame = 0;
         if(_manager)
         {
            _manager.destory();
            _manager = null;
         }
         if(_blackBack)
         {
            _blackBack.destory();
            _blackBack = null;
         }
         _effects = null;
         _justRenderAnimateTargets = null;
         _justRenderTargets = null;
         _shineEffects = null;
         _shadowEffects = null;
         _gameStage = null;
         _effectLayer = null;
         _meltCtrl.destory(true);
         _meltCtrl = null;
      }
      
      public function initlize(param1:GameStage, param2:Sprite) : void
      {
         _isDestoryed = false;
         _manager = new EffectManager();
         _gameStage = param1;
         _effectLayer = param2;
         _effects = new Vector.<EffectView>();
         _justRenderAnimateTargets = new Vector.<BaseGameSprite>();
         _justRenderTargets = new Vector.<BaseGameSprite>();
         _shineEffects = new Vector.<ShineEffectView>();
         _shadowEffects = new Dictionary();
         _blackBack = new BlackBackView();
         _renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / 30) - 1;
         _meltCtrl = new GameMeltCtrl();
         _meltCtrl.initialize(_gameStage.filterManager);
      }
      
      public function render() : void
      {
         if(_isDestoryed)
         {
            return;
         }
         if(freezeEnabled)
         {
            renderFreeze();
         }
         renderSlowDown();
         renderShine();
         if(_renderBlackBack)
         {
            renderBlackBack();
         }
         _frameEffectCount = new Dictionary();
         for each(var _loc1_ in _effects)
         {
            _loc1_.render();
         }
         if(isRenderAnimate())
         {
            renderAnimate();
         }
         if(_replaceSkillFrameHold > 0)
         {
            renderReplaceSkill();
         }
         if(_explodeSkillFrame > 0)
         {
            renderEnergyExplode();
         }
         if(_justRenderTargets != null)
         {
            for each(var _loc2_ in _justRenderTargets)
            {
               _loc2_.render();
               GameLogic.fixGameSpritePosition(_loc2_);
            }
         }
         _meltCtrl.render();
      }
      
      private function renderBlackBack() : void
      {
         var _loc4_:Number = NaN;
         _loc4_ = 0.03;
         var _loc8_:MapMain = _gameStage.getMap();
         var _loc6_:FighterMain = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
         var _loc3_:FighterMain = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter;
         if(_loc6_ == null || _loc3_ == null)
         {
            return;
         }
         var _loc5_:Boolean = _loc6_.actionState == 12 || _loc6_.actionState == 13;
         var _loc7_:Boolean = _loc3_.actionState == 12 || _loc3_.actionState == 13;
         var _loc1_:ColorTransform = _loc8_.getColorTransform();
         if(_loc5_ == _loc7_ && _loc5_ == false)
         {
            if(_loc1_.redMultiplier + 0.03 > 1)
            {
               _loc8_.resetColorTransform();
               _isRenderBlackBack = false;
               _renderBlackBack = false;
               return;
            }
            _loc1_.redMultiplier += 0.03;
            _loc1_.greenMultiplier = _loc1_.blueMultiplier = _loc1_.redMultiplier;
            _loc8_.setColorTransform(_loc1_);
            return;
         }
         if(_loc1_.redMultiplier == 0.6)
         {
            return;
         }
         var _loc2_:ColorTransform = new ColorTransform();
         _loc2_.redMultiplier = _loc2_.greenMultiplier = _loc2_.blueMultiplier = 0.6;
         _loc8_.setColorTransform(_loc2_);
      }
      
      public function startRenderBlackBack() : void
      {
         _renderBlackBack = true;
         _isRenderBlackBack = false;
      }
      
      private function renderShine() : void
      {
         if(_shineEffects == null || _shineEffects.length < 1)
         {
            return;
         }
         for each(var _loc1_ in _shineEffects)
         {
            _loc1_.render();
         }
      }
      
      private function renderAnimate() : void
      {
         if(_isDestoryed)
         {
            return;
         }
         for each(var _loc2_ in _effects)
         {
            _loc2_.renderAnimate();
         }
         for each(var _loc1_ in _shadowEffects)
         {
            _loc1_.render();
         }
         if(_justRenderAnimateTargets != null)
         {
            for each(var _loc3_ in _justRenderAnimateTargets)
            {
               _loc3_.renderAnimate();
            }
         }
         if(_blackBack)
         {
            _blackBack.renderAnimate();
         }
         renderShakeX();
         renderShakeY();
         renderRemoveEnemy();
         renderBgBlur();
         renderImpact();
         _meltCtrl.renderAnimate();
      }
      
      private function isRenderAnimate() : Boolean
      {
         if(_renderAnimateGap > 0)
         {
            if(_renderAnimateFrame++ >= _renderAnimateGap)
            {
               _renderAnimateFrame = 0;
               return true;
            }
            return false;
         }
         return true;
      }
      
      private function renderFreeze() : void
      {
         var _loc1_:int = 0;
         if(_freezeFrame > 0)
         {
            _freezeFrame = _freezeFrame - 1;
            if(_freezeFrame <= 0)
            {
               if(_onFreezeOver)
               {
                  while(_loc1_ < _onFreezeOver.length)
                  {
                     _onFreezeOver[_loc1_]();
                     _loc1_++;
                  }
                  _onFreezeOver = null;
               }
               if(_hitFocusTarget)
               {
                  _hitFocusTarget = null;
                  GameCtrl.I.gameState.cameraResume();
               }
               GameCtrl.I.resume();
            }
         }
      }
      
      private function renderShakeX() : void
      {
         var _loc1_:Number = _shakeHoldX + _shakePowX;
         if(_loc1_ > 0)
         {
            _gameStage.x = _loc1_ * _shakeXDirect;
            if(_shakePowX > 0 && _shakeFrameX % 2 == 0)
            {
               _shakePowX -= _shakeLoseX;
               if(_shakePowX < _shakeLoseX)
               {
                  _shakePowX = 0;
                  _gameStage.x = 0;
                  _shakeFrameX = 0;
                  _shakeLoseX = 0;
                  return;
               }
            }
            _shakeFrameX = _shakeFrameX + 1;
            _shakeXDirect *= -1;
         }
      }
      
      private function renderShakeY() : void
      {
         var _loc1_:Number = _shakeHoldY + _shakePowY;
         if(_loc1_ > 0)
         {
            _gameStage.y = _loc1_ * _shakeYDirect;
            if(_shakePowY > 0 && _shakeFrameY % 2 == 0)
            {
               _shakePowY -= _shakeLoseY;
               if(_shakePowY < _shakeLoseY)
               {
                  _shakePowY = 0;
                  _gameStage.y = 0;
                  _shakeFrameY = 0;
                  _shakeLoseY = 0;
                  return;
               }
            }
            _shakeYDirect *= -1;
            _shakeFrameY = _shakeFrameY + 1;
         }
      }
      
      public function doHitEffect(param1:HitVO, param2:Rectangle, param3:IGameSprite = null) : void
      {
         var _loc6_:EffectVO = _manager.getHitEffectVOByHitVO(param1,param3);
         if(_loc6_ == null)
         {
            return;
         }
         var _loc4_:Number = param2.x + param2.width / 2;
         var _loc5_:Number = param2.y + param2.height / 2;
         var _loc7_:int = 1;
         if(_loc6_.followDirect && param1.owner && param1.owner is IGameSprite)
         {
            _loc7_ = (param1.owner as IGameSprite).direct;
         }
         if(param1.slowDown > 0)
         {
            slowDown(2,param1.slowDown * 1000);
         }
         if(param1.holdTime > 0)
         {
            _loc6_ = _loc6_.clone();
            _loc6_.freeze = param1.holdTime;
         }
         if(param1.focusTarget)
         {
            _hitFocusTarget = param3;
            GameCtrl.I.gameState.cameraFocusOne(param3.getDisplay());
         }
         else if(_hitFocusTarget && _hitFocusTarget == param3)
         {
            _hitFocusTarget = null;
         }
         doEffectVO(_loc6_,_loc4_,_loc5_,_loc7_,param3);
      }
      
      public function doDefenseEffect(param1:HitVO, param2:Rectangle, param3:int, param4:IGameSprite = null) : void
      {
         var _loc7_:EffectVO = _manager.getDefenseEffectVOByHitVO(param1,param3,param4);
         if(_loc7_ == null)
         {
            return;
         }
         var _loc5_:Number = param2.x + param2.width / 2;
         var _loc6_:Number = param2.y + param2.height / 2;
         if(param1.holdTime > 0)
         {
            _loc7_ = _loc7_.clone();
            _loc7_.freeze = param1.holdTime;
         }
         if(_loc7_.shake)
         {
            if(_loc7_.shake.pow != undefined && _loc7_.shake.pow != 0)
            {
               _loc7_.shake.x = 0;
               _loc7_.shake.y = _loc7_.shake.pow;
            }
         }
         var _loc8_:int = 1;
         if(_loc7_.followDirect && param1.owner && param1.owner is IGameSprite)
         {
            _loc8_ = (param1.owner as IGameSprite).direct;
         }
         doEffectVO(_loc7_,_loc5_,_loc6_,_loc8_,param4);
      }
      
      public function doSteelHitEffect(param1:HitVO, param2:Rectangle, param3:IGameSprite) : void
      {
         var _loc6_:EffectVO = null;
         switch(param1.hitType)
         {
            case 0:
               return;
            case 1:
            case 6:
               _loc6_ = EffectModel.I.getEffect("steel_hit_kan");
               break;
            case 2:
            case 3:
               _loc6_ = EffectModel.I.getEffect("steel_hit_qdj");
               break;
            default:
               _loc6_ = EffectModel.I.getEffect("steel_hit_mfdj");
         }
         if(!_loc6_)
         {
            return;
         }
         var _loc4_:Number = param2.x + param2.width / 2;
         var _loc5_:Number = param2.y + param2.height / 2;
         var _loc7_:int = 1;
         if(_loc6_.followDirect && param1.owner && param1.owner is IGameSprite)
         {
            _loc7_ = (param1.owner as IGameSprite).direct;
         }
         if(!GameData.I.config.isSteelBodyFreeze)
         {
            _loc6_ = _loc6_.clone();
            _loc6_.freeze = 0;
            _loc6_.shine = {};
         }
         doEffectVO(_loc6_,_loc4_,_loc5_,_loc7_,param3);
      }
      
      public function doEffectById(param1:String, param2:Number, param3:Number, param4:int = 1, param5:IGameSprite = null, param6:Boolean = true) : void
      {
         var _loc7_:EffectVO = EffectModel.I.getEffect(param1);
         if(_loc7_ == null)
         {
            return;
         }
         doEffectVO(_loc7_,param2,param3,param4,param5,param6);
      }
      
      public function assisterEffect(param1:Assister) : void
      {
         switch(param1.data.comicType)
         {
            case 0:
               doEffectById("fz_bleach",param1.x,param1.y);
               break;
            default:
               doEffectById("fz_naruto",param1.x,param1.y);
         }
         JoyRumble.I.addRumble(param1.team.id,6553,6553,100,2);
      }
      
      public function doEffectVO(param1:EffectVO, param2:Number, param3:Number, param4:int = 1, param5:IGameSprite = null, param6:Boolean = true) : void
      {
         var _loc14_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc7_:* = 0;
         var _loc12_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc8_:int = 0;
         if(!_frameEffectCount[param1])
         {
            _frameEffectCount[param1] = 0;
         }
         if(++_frameEffectCount[param1] > 3)
         {
            return;
         }
         var _loc9_:EffectView = addEffect(param1,param2,param3,param4,param6);
         if(_loc9_)
         {
            _effectLayer.addChild(_loc9_.display);
         }
         if(param1.freeze > 0)
         {
            freeze(param1.freeze);
         }
         if(param1.shake)
         {
            _loc14_ = Number(param1.shake.time != undefined ? param1.shake.time : 0);
            _loc11_ = Number(param1.shake.x != undefined ? param1.shake.x : 0);
            _loc13_ = Number(param1.shake.y != undefined ? param1.shake.y : 0);
            shake(_loc11_,_loc13_,_loc14_);
         }
         if(param1.shine)
         {
            _loc7_ = uint(param1.shine.color != undefined ? param1.shine.color : 16777215);
            _loc12_ = Number(param1.shine.alpha != undefined ? param1.shine.alpha : 0.2);
            shine(_loc7_,_loc12_);
         }
         if(param1.slowDown)
         {
            _loc10_ = Number(param1.slowDown.rate != undefined ? param1.slowDown.rate : 1.5);
            _loc8_ = int(param1.slowDown.time != undefined ? param1.slowDown.time : 1000);
            slowDown(_loc10_,_loc8_);
         }
         if(param5)
         {
            _loc9_.setTarget(param5);
         }
         if(param1.specialEffectId && param5 && param5 is FighterMain)
         {
            doSpecialEffect(param1.specialEffectId,param5 as FighterMain);
         }
      }
      
      public function doSpecialEffect(param1:String, param2:FighterMain) : void
      {
         var _loc6_:int = 0;
         var _loc3_:SpecialEffectView = null;
         _loc6_ = 0;
         while(_loc6_ < _effects.length)
         {
            _loc3_ = _effects[_loc6_] as SpecialEffectView;
            if(_loc3_ != null)
            {
               if(_loc3_.getTarget() == param2)
               {
                  _loc3_.removeSelf();
               }
            }
            _loc6_++;
         }
         var _loc4_:EffectVO = EffectModel.I.getEffect(param1);
         var _loc5_:SpecialEffectView = addEffect(_loc4_,param2.x,param2.y,param2.direct) as SpecialEffectView;
         if(_loc5_ != null)
         {
            _loc5_.setTarget(param2);
            _effectLayer.addChild(_loc5_.display);
         }
      }
      
      public function doBuffEffect(param1:String, param2:FighterMain, param3:FighterBuffVO) : void
      {
         var _loc8_:int = 0;
         var _loc5_:BuffEffectView = null;
         var _loc6_:EffectVO = EffectModel.I.getEffect(param1);
         var _loc4_:EffectView = _manager.getEffectView(_loc6_);
         if(_loc4_ == null)
         {
            return;
         }
         _loc8_ = 0;
         while(_loc8_ < _effects.length)
         {
            _loc5_ = _effects[_loc8_] as BuffEffectView;
            if(_loc5_ != null)
            {
               if(_loc5_.data == _loc4_.data && _loc5_.getTarget() == param2)
               {
                  if(!_loc5_.getBuff().finished)
                  {
                     _loc5_.remove();
                     doBuffEffect(param1,param2,param3);
                     return;
                  }
               }
            }
            _loc8_++;
         }
         var _loc7_:BuffEffectView = addEffect(_loc6_,param2.x,param2.y,param2.direct) as BuffEffectView;
         if(_loc7_ != null)
         {
            _loc7_.setTarget(param2);
            _loc7_.setBuff(param3);
            _effectLayer.addChild(_loc7_.display);
         }
      }
      
      private function addEffect(param1:EffectVO, param2:Number, param3:Number, param4:int = 1, param5:Boolean = true) : EffectView
      {
         var _loc6_:EffectView = _manager.getEffectView(param1);
         if(_loc6_ == null)
         {
            return null;
         }
         _loc6_.start(param2,param3,param4,param5);
         _loc6_.addRemoveBack(removeEffect);
         _effects.push(_loc6_);
         return _loc6_;
      }
      
      private function removeEffect(param1:EffectView) : void
      {
         var _loc2_:int = _effects.indexOf(param1);
         if(_loc2_ != -1)
         {
            _effects.splice(_loc2_,1);
         }
      }
      
      public function freeze(param1:int) : void
      {
         if(!freezeEnabled)
         {
            return;
         }
         if(param1 < 1)
         {
            return;
         }
         var _loc2_:int = param1 * 0.001 * GameConfig.FPS_GAME;
         if(_loc2_ < 1)
         {
            return;
         }
         if(_freezeFrame > _loc2_)
         {
            return;
         }
         _freezeFrame = _loc2_;
         if(param1 > 300)
         {
            if(GameCtrl.I.slowRate > 0)
            {
               bgBlur(GameCtrl.I.slowRate * 4,0,500);
            }
         }
         GameCtrl.I.pause();
      }
      
      private function justRender(param1:BaseGameSprite) : void
      {
         if(_justRenderTargets.indexOf(param1) == -1)
         {
            _justRenderTargets.push(param1);
         }
      }
      
      private function justRenderAnimate(param1:BaseGameSprite) : void
      {
         if(_justRenderAnimateTargets.indexOf(param1) == -1)
         {
            _justRenderAnimateTargets.push(param1);
         }
      }
      
      private function cancelJustRender(param1:BaseGameSprite) : Boolean
      {
         var _loc2_:int = _justRenderTargets.indexOf(param1);
         if(_loc2_ != -1)
         {
            _justRenderTargets.splice(_loc2_,1);
         }
         return _justRenderTargets.length < 1;
      }
      
      private function cancelJustRenderAnimate(param1:BaseGameSprite) : Boolean
      {
         var _loc2_:int = _justRenderAnimateTargets.indexOf(param1);
         if(_loc2_ != -1)
         {
            _justRenderAnimateTargets.splice(_loc2_,1);
         }
         return _justRenderAnimateTargets.length < 1;
      }
      
      public function shine(param1:uint = 16777215, param2:Number = 0.2) : void
      {
         if(GameConfig.FPS_SHINE_EFFECT == 0)
         {
            return;
         }
         if(_shineEffects.length > shineMaxCount)
         {
            _shineEffects[0].removeSelf();
         }
         var _loc3_:ShineEffectView = _manager.getShine();
         _loc3_.init(param1,param2);
         _loc3_.onRemove = removeShine;
         _shineEffects.push(_loc3_);
         _gameStage.addChild(_loc3_);
      }
      
      private function removeShine(param1:ShineEffectView) : void
      {
         var _loc2_:int = _shineEffects.indexOf(param1);
         if(_loc2_ != -1)
         {
            _shineEffects.splice(_loc2_,1);
         }
      }
      
      public function startShake(param1:Number, param2:Number) : void
      {
         _shakeHoldX = param1;
         _shakeHoldY = param2;
         var _loc4_:Number = Math.max(Math.abs(param1),Math.abs(param2)) / 10;
         var _loc3_:uint = _loc4_ * 32767;
         JoyRumble.I.addRumble(-1,_loc3_,_loc3_,-1,0);
      }
      
      public function endShake() : void
      {
         _shakeHoldX = 0;
         _shakeHoldY = 0;
         _gameStage.x = 0;
         _gameStage.y = 0;
         JoyRumble.I.addRumble(-1,0,0,0,0);
      }
      
      public function shake(param1:Number = 0, param2:Number = 3, param3:int = 500) : void
      {
         if(!SHAKE_ENABLED)
         {
            return;
         }
         if(isNaN(param1) || isNaN(param2))
         {
            return;
         }
         if(Math.abs(_shakePowX) > Math.abs(param1) || Math.abs(_shakePowY) > Math.abs(param2))
         {
            return;
         }
         if(param1 != 0)
         {
            if(_shakePowX == 0)
            {
               _shakeXDirect = param1 > 0 ? 1 : -1;
               _shakePowX = Math.abs(param1);
            }
            else
            {
               _shakePowX += Math.abs(param1) * 0.5;
            }
            if(_shakePowX > 10)
            {
               _shakePowX = 10;
            }
         }
         if(param2 != 0)
         {
            if(_shakePowY == 0)
            {
               _shakeYDirect = param2 > 0 ? 1 : -1;
               _shakePowY = Math.abs(param2);
            }
            else
            {
               _shakePowY += Math.abs(param2) * 0.5;
            }
            if(_shakePowY > 10)
            {
               _shakePowY = 10;
            }
         }
         if(param3 <= 0)
         {
            param3 = 500;
         }
         _shakeLoseX = Math.ceil(_shakePowX / (param3 * 0.03));
         _shakeLoseY = Math.ceil(_shakePowY / (param3 * 0.03));
         if(_shakeLoseX < 1)
         {
            _shakeLoseX = 1;
         }
         if(_shakeLoseY < 1)
         {
            _shakeLoseY = 1;
         }
         var _loc5_:Number = Math.max(Math.abs(param1),Math.abs(param2)) / 10;
         var _loc4_:uint = _loc5_ * 65535;
         JoyRumble.I.addRumble(-1,_loc4_,_loc4_,param3,2);
      }
      
      public function startShadow(param1:DisplayObject, param2:int = 0, param3:int = 0, param4:int = 0, param5:Object = null) : void
      {
         if(!SHADOW_ENABLED)
         {
            return;
         }
         var _loc6_:ShadowEffectView = _shadowEffects[param1];
         if(_loc6_)
         {
            _loc6_.r = param2;
            _loc6_.g = param3;
            _loc6_.b = param4;
            _loc6_.stopShadow = false;
            _loc6_.setAddonParam(param5);
            return;
         }
         _loc6_ = new ShadowEffectView(param1,param2,param3,param4,param5);
         _loc6_.onRemove = removeShadow;
         _loc6_.container = _effectLayer;
         _shadowEffects[param1] = _loc6_;
      }
      
      public function endShadow(param1:DisplayObject) : void
      {
         if(!SHADOW_ENABLED)
         {
            return;
         }
         if(!_shadowEffects)
         {
            return;
         }
         var _loc2_:ShadowEffectView = _shadowEffects[param1];
         if(_loc2_)
         {
            _loc2_.stopShadow = true;
         }
      }
      
      private function removeShadow(param1:ShadowEffectView) : void
      {
         if(!_shadowEffects)
         {
            return;
         }
         delete _shadowEffects[param1.target];
      }
      
      public function bisha(param1:BaseGameSprite, param2:Boolean = false, param3:DisplayObject = null) : void
      {
         justRenderAnimate(param1);
         GameCtrl.I.pause();
         GameCtrl.I.setRenderHit(false);
         _gameStage.addChildAt(_blackBack,0);
         _blackBack.fadIn();
         if(param3 && (param1 is FighterMain || param1 is Assister))
         {
            showFace(param1,param3);
         }
         if(param2)
         {
            GameCtrl.I.gameState.cameraFocusOne(param1.getDisplay());
            doEffectById("bisha_super",param1.x,param1.y - 50);
         }
         else
         {
            doEffectById("bisha",param1.x,param1.y - 50);
         }
         JoyRumble.I.addRumble(param1.team.id,6553,6553,100,2);
         _gameStage.getMap().setVisible(false);
         _gameStage.setVisibleByClass(BitmapFilterView,false);
      }
      
      public function endBisha(param1:BaseGameSprite) : void
      {
         if(cancelJustRenderAnimate(param1))
         {
            GameCtrl.I.resume();
            GameCtrl.I.gameState.cameraResume();
            GameCtrl.I.setRenderHit(true);
            _blackBack.fadOut();
            _gameStage.getMap().setVisible(true);
            _gameStage.setVisibleByClass(BitmapFilterView,true);
         }
      }
      
      private function showFace(param1:BaseGameSprite, param2:DisplayObject) : void
      {
         var _loc5_:IGameSprite = null;
         var _loc3_:DisplayObject = null;
         var _loc4_:int = 1;
         if(param1 is FighterMain)
         {
            _loc5_ = (param1 as FighterMain).getCurrentTarget();
         }
         if(param1 is Assister)
         {
            _loc5_ = (param1 as Assister).getCurrentTarget();
         }
         if(_loc5_)
         {
            _loc3_ = _loc5_.getDisplay();
            if(_loc3_)
            {
               _loc4_ = param1.getDisplay().x > _loc3_.x ? 2 : 1;
            }
         }
         _blackBack.showBishaFace(_loc4_,param2);
      }
      
      public function wanKai(param1:FighterMain, param2:DisplayObject = null) : void
      {
         justRenderAnimate(param1);
         GameCtrl.I.pause();
         GameCtrl.I.setRenderHit(false);
         _gameStage.addChildAt(_blackBack,0);
         _blackBack.fadIn();
         if(param2)
         {
            showFace(param1,param2);
         }
         GameCtrl.I.gameState.cameraFocusOne(param1.getDisplay());
         doEffectById("bisha_super",param1.x,param1.y - 50);
         JoyRumble.I.addRumble(param1.team.id,6553,6553,100,2);
         _gameStage.getMap().setVisible(false);
         _gameStage.setVisibleByClass(BitmapFilterView,false);
      }
      
      public function endWanKai(param1:FighterMain) : void
      {
         if(cancelJustRenderAnimate(param1))
         {
            GameCtrl.I.resume();
            GameCtrl.I.gameState.cameraResume();
            _blackBack.fadOut();
            GameCtrl.I.setRenderHit(true);
            _gameStage.getMap().setVisible(true);
         }
      }
      
      public function jumpEffect(param1:Number, param2:Number) : void
      {
         doEffectById("jump",param1,param2);
      }
      
      public function jumpAirEffect(param1:Number, param2:Number) : void
      {
         doEffectById("jump_air",param1,param2);
      }
      
      public function touchFloorEffect(param1:Number, param2:Number) : void
      {
         doEffectById("touch_floor",param1,param2);
      }
      
      public function hitFloorEffect(param1:int, param2:Number, param3:Number) : void
      {
         switch(param1)
         {
            case 0:
               doEffectById("hit_floor",param2,param3);
               break;
            case 1:
               doEffectById("hit_floor_low",param2,param3);
               break;
            case 2:
               doEffectById("hit_floor_heavy",param2,param3);
               doEffectById("hit_floor_yan",param2,param3);
         }
      }
      
      public function slowDown(param1:Number, param2:int = 1000) : void
      {
         if(!GameData.I.config.isSlowDown)
         {
            _slowDownFrame = 0;
            return;
         }
         if(GameCtrl.I.slowRate > param1)
         {
            return;
         }
         GameCtrl.I.slow(param1);
         bgBlur(param1 * 2,0,250);
         _renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / (30 / param1)) - 1;
         if(param2 == 0)
         {
            _slowDownFrame = 0;
         }
         else
         {
            _slowDownFrame = param2 * 0.001 * GameConfig.FPS_GAME;
         }
      }
      
      public function bgBlur(param1:Number, param2:Number, param3:int = 1000) : void
      {
         if(!BG_BULR_ENABLED)
         {
            return;
         }
         if(!bgBlurEnabled)
         {
            return;
         }
         if(_gameStage.getMap().getSmoothing().x > param1 || _gameStage.getMap().getSmoothing().y > 0)
         {
            return;
         }
         _gameStage.getMap().setSmoothing(param1,param2);
         _blurFrame = param3 * 0.03;
      }
      
      public function cancelBgBlur() : void
      {
         _blurFrame = 0;
         _gameStage.getMap().setSmoothing(0,0);
      }
      
      private function renderBgBlur() : void
      {
         if(_blurFrame > 0)
         {
            if(--_blurFrame <= 0)
            {
               cancelBgBlur();
            }
         }
      }
      
      private function renderSlowDown() : void
      {
         if(_slowDownFrame > 0)
         {
            _slowDownFrame = _slowDownFrame - 1;
            if(_slowDownFrame <= 0)
            {
               slowDownResume();
            }
         }
      }
      
      public function slowDownResume() : void
      {
         GameCtrl.I.slowResume();
         _renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / 30) - 1;
         _slowDownFrame = 0;
      }
      
      public function BGEffect(param1:String, param2:Number = -1) : void
      {
         var effect:EffectView;
         var id:String = param1;
         var hold:Number = param2;
         var data:EffectVO = EffectModel.I.getEffect(id);
         if(!data)
         {
            return;
         }
         effect = addEffect(data,0,0,1);
         if(hold != -1)
         {
            effect.holdFrame = hold * 30;
         }
         if(effect)
         {
            effect.addRemoveBack(function():void
            {
               _gameStage.getMap().setVisible(true);
            });
            _gameStage.getMap().setVisible(false);
            _gameStage.addChildAt(effect.display,0);
         }
      }
      
      public function setOnFreezeOver(param1:Function) : void
      {
         if(!_onFreezeOver)
         {
            _onFreezeOver = new Vector.<Function>();
         }
         _onFreezeOver.push(param1);
      }
      
      public function replaceSkill(param1:BaseGameSprite) : void
      {
         GameCtrl.I.pause();
         _gameStage.addChildAt(_blackBack,0);
         _gameStage.getMap().setVisible(false);
         doEffectById("replaceSp",param1.x,param1.y);
         _replaceSkillPos = new Point(param1.x,param1.y);
         _replaceSkillFrame = 0;
         _replaceSkillFrameHold = GameConfig.FPS_GAME / 3;
      }
      
      private function endReplaceSkill() : void
      {
         GameCtrl.I.resume();
         _blackBack.fadOut();
         _gameStage.getMap().setVisible(true);
         _replaceSkillFrameHold = 0;
      }
      
      private function renderReplaceSkill() : void
      {
         _replaceSkillFrame = _replaceSkillFrame + 1;
         if(_replaceSkillFrame == 1)
         {
            doEffectById("replaceSp2",_replaceSkillPos.x,_replaceSkillPos.y);
         }
         if(_replaceSkillFrame > _replaceSkillFrameHold)
         {
            endReplaceSkill();
         }
      }
      
      public function energyExplode(param1:BaseGameSprite) : void
      {
         GameCtrl.I.pause();
         _gameStage.addChildAt(_blackBack,0);
         _gameStage.getMap().setVisible(false);
         doEffectById("explodeSp",param1.x,param1.y);
         _explodeEffectPos = new Point(param1.x,param1.y);
         _explodeSkillFrame = 0.7 * GameConfig.FPS_GAME;
         if(param1 is FighterMain)
         {
            (param1 as FighterMain).explodeSkillFrame = _explodeSkillFrame;
         }
      }
      
      private function endEnergyExplode() : void
      {
         doEffectById("explodeSp2",_explodeEffectPos.x,_explodeEffectPos.y);
         GameCtrl.I.resume();
         _blackBack.fadOut();
         _gameStage.getMap().setVisible(true);
         _explodeSkillFrame = 0;
      }
      
      private function renderEnergyExplode() : void
      {
         _explodeSkillFrame = _explodeSkillFrame - 1;
         if(_explodeSkillFrame <= 0)
         {
            endEnergyExplode();
         }
      }
      
      public function ghostStep(param1:BaseGameSprite) : void
      {
         justRender(param1);
         justRenderAnimate(param1);
         GameCtrl.I.pause();
         _gameStage.addChildAt(_blackBack,0);
         _blackBack.fadIn();
         _gameStage.getMap().setVisible(false);
         _gameStage.setVisibleByClass(BitmapFilterView,false);
         SoundCtrl.I.playAssetSound("ghost_jump");
         JoyRumble.I.addRumble(param1.team.id,6553,6553,100,2);
      }
      
      public function endGhostStep(param1:BaseGameSprite) : void
      {
         var _loc3_:Boolean = cancelJustRender(param1);
         var _loc2_:Boolean = cancelJustRenderAnimate(param1);
         if(_loc3_ && _loc2_)
         {
            GameCtrl.I.resume();
            _blackBack.fadOut();
            _gameStage.getMap().setVisible(true);
            _gameStage.setVisibleByClass(BitmapFilterView,true);
         }
      }
      
      public function startFilter(param1:BaseGameSprite, param2:BitmapFilter, param3:Point = null) : void
      {
         var _loc5_:BitmapFilterView = null;
         for each(var _loc4_ in _filterEffects)
         {
            if(_loc4_.target == param1)
            {
               _loc5_ = _loc4_;
               break;
            }
         }
         if(!_loc5_)
         {
            _loc5_ = new BitmapFilterView(param1,param2,param3);
            GameCtrl.I.addGameSprite(0,_loc5_,0);
            _filterEffects.push(_loc5_);
         }
         else
         {
            _loc5_.update(param2,param3);
         }
      }
      
      public function endFilter(param1:BaseGameSprite) : void
      {
         var _loc3_:int = 0;
         var _loc2_:BitmapFilterView = null;
         _loc3_ = 0;
         while(_loc3_ < _filterEffects.length)
         {
            _loc2_ = _filterEffects[_loc3_];
            if(_loc2_.target == param1)
            {
               GameCtrl.I.removeGameSprite(_loc2_,true);
               _filterEffects.splice(_loc3_,1);
               break;
            }
            _loc3_++;
         }
      }
      
      private function get impactEffects() : Array
      {
         if(!_impactEffects)
         {
            _impactEffects = [];
         }
         return _impactEffects;
      }
      
      public function createImpactEffect(param1:Object = null) : void
      {
         var _loc2_:ImpactEffectView = null;
         try
         {
            if(!GameCtrl.I || !GameCtrl.I.gameState)
            {
               Trace("GameCtrl.I.gameState 无效，跳过黑白闪特效");
               return;
            }
            _loc2_ = new ImpactEffectView();
            if(param1)
            {
               KyoUtils.setValueByObject(_loc2_,param1);
            }
            clearImpactEffects();
            try
            {
               _effectLayer.addChild(_loc2_);
               _loc2_.init();
            }
            catch(e:Error)
            {
               Trace("初始化黑白闪特效失败：",e.message);
               _loc2_.dispose();
               return;
            }
            impactEffects.push(_loc2_);
         }
         catch(e:Error)
         {
            Trace("创建黑白闪特效失败：",e.message);
         }
      }
      
      private function cleanInvalidImpactEffects() : void
      {
         var _loc2_:int = 0;
         var _loc1_:ImpactEffectView = null;
         if(impactEffects.length == 0)
         {
            return;
         }
         _loc2_ = impactEffects.length - 1;
         while(_loc2_ >= 0)
         {
            _loc1_ = impactEffects[_loc2_];
            if(!_loc1_ || _loc1_.isDispose)
            {
               impactEffects.splice(_loc2_,1);
            }
            _loc2_--;
         }
      }
      
      public function clearImpactEffects() : void
      {
         var _loc2_:int = 0;
         var _loc1_:ImpactEffectView = null;
         if(impactEffects.length == 0)
         {
            return;
         }
         _loc2_ = impactEffects.length - 1;
         while(_loc2_ >= 0)
         {
            _loc1_ = impactEffects[_loc2_];
            if(_loc1_)
            {
               _loc1_.dispose();
            }
            _loc2_--;
         }
         _impactEffects = [];
      }
      
      private function renderImpact() : void
      {
         var _loc3_:int = 0;
         var _loc1_:ImpactEffectView = null;
         var _loc2_:Boolean = false;
         if(impactEffects.length == 0)
         {
            return;
         }
         _loc3_ = impactEffects.length - 1;
         for(; _loc3_ >= 0; _loc3_--)
         {
            _loc1_ = impactEffects[_loc3_];
            if(!_loc1_ || _loc1_.isDispose)
            {
               impactEffects.splice(_loc3_,1);
            }
            else
            {
               try
               {
                  _loc2_ = _loc1_.renderImpact();
                  if(!_loc2_)
                  {
                     impactEffects.splice(_loc3_,1);
                  }
               }
               catch(e:Error)
               {
                  Trace("渲染黑白闪特效失败：",e.message);
                  _loc1_.dispose();
                  impactEffects.splice(_loc3_,1);
                  continue;
               }
            }
         }
      }
      
      private function renderRemoveEnemy() : void
      {
         var _loc3_:* = null;
         var _loc2_:* = null;
         var _loc4_:* = null;
         for(var _loc1_ in _removeEnemieMap)
         {
            _loc3_ = _removeEnemieMap[_loc1_];
            _loc2_ = _loc3_.fighter;
            _loc4_ = _loc3_.callback;
            if(!_loc2_)
            {
               delete _removeEnemieMap[_loc1_];
            }
            else if(_loc2_.getDisplay().alpha > 0)
            {
               _loc2_.getDisplay().alpha = _loc2_.getDisplay().alpha - 0.05;
            }
            else
            {
               if(_loc4_ != null)
               {
                  _loc4_();
               }
               _loc3_.fighter = null;
               _loc3_.callback = null;
               delete _removeEnemieMap[_loc1_];
            }
         }
      }
      
      public function removeEnemyEffect(param1:FighterMain, param2:Function = null) : void
      {
         _removeEnemieMap[UUID.create()] = {
            "fighter":param1,
            "callback":param2
         };
      }
   }
}

