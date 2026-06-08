package net.play5d.game.bvn.fighter.ctrler
{
   import flash.display.*;
   import flash.filters.*;
   import flash.geom.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   
   public class FighterEffectCtrl
   {
      
      private var _target:BaseGameSprite;
      
      private var _targetDisplay:DisplayObject;
      
      private var _inGhostStep:Boolean;
      
      private var _faceObj:Object = {};
      
      private var _isShakeIng:Boolean;
      
      private var _isShadowIng:Boolean;
      
      private var _isGlowIng:Boolean;
      
      public function FighterEffectCtrl(param1:BaseGameSprite)
      {
         super();
         this._target = param1;
         this._targetDisplay = param1.getDisplay();
      }
      
      public function destory() : void
      {
         this._target = null;
         this._targetDisplay = null;
         this._faceObj = null;
      }
      
      public function setBishaFace(param1:String, param2:Class) : void
      {
         this._faceObj[param1] = param2;
      }
      
      private function getFace(param1:String) : DisplayObject
      {
         if(!param1)
         {
            return null;
         }
         var _loc2_:Class = this._faceObj[param1];
         if(!_loc2_)
         {
            Debugger.errorMsg("未定义必杀特写:" + param1);
            return null;
         }
         var _loc3_:BitmapData = new _loc2_();
         var _loc4_:Bitmap = new Bitmap(_loc3_);
         _loc4_.smoothing = true;
         return _loc4_;
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
         this._isShakeIng = true;
         EffectCtrl.I.startShake(param1,param2);
      }
      
      public function endShake() : void
      {
         if(this._isShakeIng)
         {
            EffectCtrl.I.endShake();
            this._isShakeIng = false;
         }
      }
      
      public function shadow(param1:int = 0, param2:int = 0, param3:int = 0) : void
      {
         this._isShadowIng = true;
         EffectCtrl.I.startShadow(this._targetDisplay,param1,param2,param3);
      }
      
      public function endShadow() : void
      {
         if(this._isShadowIng)
         {
            EffectCtrl.I.endShadow(this._targetDisplay);
         }
      }
      
      public function dash() : void
      {
         if(this._target.isInAir)
         {
            EffectCtrl.I.doEffectById("dash_air",this._target.x,this._target.y,this._target.direct);
         }
         else
         {
            EffectCtrl.I.doEffectById("dash",this._target.x,this._target.y,this._target.direct);
         }
      }
      
      public function bisha(param1:Boolean = false, param2:String = null) : void
      {
         var _loc3_:DisplayObject = this.getFace(param2);
         EffectCtrl.I.bisha(this._target,param1,_loc3_);
      }
      
      public function endBisha() : void
      {
         EffectCtrl.I.endBisha(this._target);
      }
      
      public function startWanKai(param1:String = null) : void
      {
         var _loc2_:DisplayObject = param1 ? this.getFace(param1) : null;
         EffectCtrl.I.wanKai(this._target as FighterMain,_loc2_);
      }
      
      public function endWanKai() : void
      {
         if((this._target as FighterMain).actionState == 50)
         {
            EffectCtrl.I.endWanKai(this._target as FighterMain);
         }
      }
      
      public function walk() : void
      {
         if(this._inGhostStep)
         {
            EffectCtrl.I.doEffectById("ghost_step",this._target.x,this._target.y,this._target.direct);
         }
         else
         {
            SoundCtrl.I.playAssetSoundRandom("step1","step2","step3");
         }
      }
      
      public function jump() : void
      {
         EffectCtrl.I.jumpEffect(this._targetDisplay.x,this._targetDisplay.y);
      }
      
      public function jumpAir() : void
      {
         EffectCtrl.I.jumpAirEffect(this._targetDisplay.x,this._targetDisplay.y);
      }
      
      public function touchFloor() : void
      {
         EffectCtrl.I.touchFloorEffect(this._targetDisplay.x,this._targetDisplay.y);
      }
      
      public function hitFloor(param1:int) : void
      {
         EffectCtrl.I.hitFloorEffect(param1,this._targetDisplay.x,this._targetDisplay.y);
      }
      
      public function slowDown(param1:Number) : void
      {
         EffectCtrl.I.slowDown(1.5,param1 * 1000);
      }
      
      public function energyExplode() : void
      {
         EffectCtrl.I.energyExplode(this._target);
      }
      
      public function replaceSkill() : void
      {
         EffectCtrl.I.replaceSkill(this._target);
      }
      
      public function ghostStep() : void
      {
         this._inGhostStep = true;
         this.shadow(0,0,255);
         EffectCtrl.I.ghostStep(this._target);
      }
      
      public function endGhostStep() : void
      {
         this._inGhostStep = false;
         this.endShadow();
         EffectCtrl.I.endGhostStep(this._target);
      }
      
      public function startGlow(param1:uint = 16777215) : void
      {
         this._isGlowIng = true;
         var _loc2_:Point = new Point(20,20);
         var _loc3_:Number = 2;
         var _loc4_:GlowFilter = new GlowFilter(param1,1,_loc2_.x,_loc2_.y,_loc3_,1,false,true);
         EffectCtrl.I.startFilter(this._target,_loc4_,_loc2_);
      }
      
      public function endGlow() : void
      {
         if(this._isGlowIng)
         {
            EffectCtrl.I.endFilter(this._target);
         }
         this._isGlowIng = false;
      }
   }
}

