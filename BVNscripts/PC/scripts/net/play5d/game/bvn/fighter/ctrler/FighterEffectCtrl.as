package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.filters.GlowFilter;
   import flash.geom.Point;
   import nagisa.data.DrawMovieClipCacheVO;
   import nagisa.filters.Melt;
   import nagisa.util.DisplayUtil;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.win.input.JoyRumble;
   
   public class FighterEffectCtrl
   {
      
      private var _target:BaseGameSprite;
      
      private var _targetDisplay:DisplayObject;
      
      private var _inGhostStep:Boolean;
      
      private var _faceObj:Object = {};
      
      private var _isShakeIng:Boolean;
      
      private var _isShadowIng:Boolean;
      
      private var _isGlowIng:Boolean;
      
      private var _melts:Object = {};
      
      public function FighterEffectCtrl(param1:BaseGameSprite)
      {
         super();
         _target = param1;
         _targetDisplay = param1.getDisplay();
      }
      
      public function destory() : void
      {
         _target = null;
         _targetDisplay = null;
         _faceObj = null;
      }
      
      public function defineMelt(param1:MovieClip, param2:String, param3:Object = null) : void
      {
         var _loc4_:DrawMovieClipCacheVO = DisplayUtil.drawMovieClip(param1);
         _melts[param2] = _loc4_;
      }
      
      public function addMelt(param1:String, param2:Object = null) : Melt
      {
         var _loc3_:DrawMovieClipCacheVO = _melts[param1];
         if(!_loc3_)
         {
            return null;
         }
         var _loc4_:Melt = EffectCtrl.I.getMeltCtrl().addMelt(param1,_loc3_,param2);
         _loc4_.x = _target.x;
         _loc4_.y = _target.y;
         return _loc4_;
      }
      
      public function setBishaFace(param1:String, param2:Class) : void
      {
         _faceObj[param1] = param2;
      }
      
      private function getFace(param1:String) : DisplayObject
      {
         if(!param1)
         {
            return null;
         }
         var _loc3_:Class = _faceObj[param1];
         if(_loc3_ == null)
         {
            Debugger.errorMsg("未定义必杀特写:" + param1);
            return null;
         }
         var _loc4_:BitmapData = new _loc3_();
         var _loc2_:Bitmap = new Bitmap(_loc4_);
         _loc2_.smoothing = true;
         return _loc2_;
      }
      
      public function doEffectById(param1:String, param2:Boolean = true) : void
      {
         EffectCtrl.I.doEffectById(param1,_target.x,_target.y,_target.direct,null,param2);
      }
      
      public function shine(param1:uint = 16777215) : void
      {
         var _loc2_:Number = param1 == 16777215 ? 0.3 : 0.2;
         EffectCtrl.I.shine(param1,_loc2_);
      }
      
      public function shake(param1:Number = 0, param2:Number = 3, param3:Number = 0) : void
      {
         var _loc4_:Number = Math.max(param1,param2);
         EffectCtrl.I.shake(0,_loc4_ * 2,param3 * 1000);
      }
      
      public function startShake(param1:Number = 0, param2:Number = 3) : void
      {
         _isShakeIng = true;
         EffectCtrl.I.startShake(param1,param2);
      }
      
      public function endShake() : void
      {
         if(_isShakeIng)
         {
            EffectCtrl.I.endShake();
            _isShakeIng = false;
         }
      }
      
      public function shadow(param1:int = 0, param2:int = 0, param3:int = 0, param4:Object = null) : void
      {
         _isShadowIng = true;
         EffectCtrl.I.startShadow(_targetDisplay,param1,param2,param3,param4);
      }
      
      public function endShadow() : void
      {
         if(_isShadowIng)
         {
            EffectCtrl.I.endShadow(_targetDisplay);
         }
      }
      
      public function dash(param1:Boolean = true) : void
      {
         if(_target.isInAir)
         {
            doEffectById("dash_air",param1);
         }
         else
         {
            doEffectById("dash",param1);
         }
         JoyRumble.I.addRumble(_target.team.id,6553,6553,100,2);
      }
      
      public function bisha(param1:Boolean = false, param2:String = null) : void
      {
         var _loc3_:DisplayObject = getFace(param2);
         EffectCtrl.I.bisha(_target,param1,_loc3_);
         EffectCtrl.I.startRenderBlackBack();
      }
      
      public function endBisha() : void
      {
         EffectCtrl.I.endBisha(_target);
      }
      
      public function startWanKai(param1:String = null) : void
      {
         var _loc2_:DisplayObject = param1 ? getFace(param1) : null;
         EffectCtrl.I.wanKai(_target as FighterMain,_loc2_);
      }
      
      public function endWanKai() : void
      {
         if((_target as FighterMain).actionState == 50)
         {
            EffectCtrl.I.endWanKai(_target as FighterMain);
         }
      }
      
      public function walk() : void
      {
         if(_inGhostStep)
         {
            doEffectById("ghost_step");
         }
         else
         {
            SoundCtrl.I.playAssetSoundRandom("step1","step2","step3");
         }
      }
      
      public function jump() : void
      {
         EffectCtrl.I.jumpEffect(_targetDisplay.x,_targetDisplay.y);
         JoyRumble.I.addRumble(_target.team.id,6553,6553,100,2);
      }
      
      public function jumpAir() : void
      {
         EffectCtrl.I.jumpAirEffect(_targetDisplay.x,_targetDisplay.y);
         JoyRumble.I.addRumble(_target.team.id,6553,6553,100,2);
      }
      
      public function touchFloor() : void
      {
         EffectCtrl.I.touchFloorEffect(_targetDisplay.x,_targetDisplay.y);
         JoyRumble.I.addRumble(_target.team.id,6553,6553,100,2);
      }
      
      public function hitFloor(param1:int, param2:Number = 0) : void
      {
         if(_target is FighterMain && (_target as FighterMain).mosouEnemyData && !(_target as FighterMain).mosouEnemyData.isBoss)
         {
            if(param2 > 1)
            {
               param2 = 1;
            }
         }
         if(param2 > 0)
         {
            shake(0,param2);
         }
         EffectCtrl.I.hitFloorEffect(param1,_targetDisplay.x,_targetDisplay.y);
         if(param1 == 1)
         {
            JoyRumble.I.addRumble(_target.team.id,6553,6553,100,2);
         }
         if(param1 == 2)
         {
            JoyRumble.I.addRumble(_target.team.id,13107,13107,100,2);
         }
      }
      
      public function slowDown(param1:Number) : void
      {
         EffectCtrl.I.slowDown(2,param1 * 1000);
      }
      
      public function energyExplode() : void
      {
         EffectCtrl.I.energyExplode(_target);
      }
      
      public function replaceSkill() : void
      {
         EffectCtrl.I.replaceSkill(_target);
      }
      
      public function ghostStep() : void
      {
         _inGhostStep = true;
         shadow(0,0,255);
         EffectCtrl.I.ghostStep(_target);
      }
      
      public function endGhostStep() : void
      {
         _inGhostStep = false;
         endShadow();
         EffectCtrl.I.endGhostStep(_target);
      }
      
      public function startGlow(param1:uint = 16777215) : void
      {
         _isGlowIng = true;
         var _loc3_:Point = new Point(20,20);
         var _loc2_:GlowFilter = new GlowFilter(param1,1,_loc3_.x,_loc3_.y,2,1,false,true);
         EffectCtrl.I.startFilter(_target,_loc2_,_loc3_);
      }
      
      public function endGlow() : void
      {
         if(_isGlowIng)
         {
            EffectCtrl.I.endFilter(_target);
         }
         _isGlowIng = false;
      }
      
      public function playImpactEffect(param1:Object = null) : void
      {
         try
         {
            if(!EffectCtrl.I)
            {
               Trace("EffectCtrl.I 未初始化，跳过黑白闪特效");
               return;
            }
            EffectCtrl.I.createImpactEffect(param1);
         }
         catch(e:Error)
         {
            Trace("播放黑白闪特效失败：",e.message);
         }
      }
      
      public function stopImpactEffect() : void
      {
         try
         {
            if(EffectCtrl.I)
            {
               EffectCtrl.I.clearImpactEffects();
            }
         }
         catch(e:Error)
         {
            Trace("停止黑白闪特效失败：",e.message);
         }
      }
      
      public function clean() : void
      {
         endGhostStep();
         endGlow();
         endShadow();
      }
   }
}

