package net.play5d.game.bvn.fighter
{
   import net.play5d.game.bvn.*;
   
   public class FighterAction
   {
      
      public var isMoving:Boolean;
      
      public var isJumping:Boolean;
      
      public var isDefensing:Boolean;
      
      public var isDashing:Boolean;
      
      public var isHurting:Boolean;
      
      public var isHurtFlying:Boolean;
      
      public var isDefenseHiting:Boolean;
      
      public var airMove:Boolean;
      
      public var touchFloor:String;
      
      public var touchFloorBreakAct:Boolean = false;
      
      public var hitTarget:String;
      
      public var hitTargetChecker:String;
      
      public var moveLeft:String;
      
      public var moveRight:String;
      
      public var defense:String;
      
      public var jump:String;
      
      public var jumpQuick:String;
      
      public var jumpDown:String;
      
      public var dash:String;
      
      public var attack:String;
      
      public var skill1:String;
      
      public var skill2:String;
      
      public var zhao1:String;
      
      public var zhao2:String;
      
      public var zhao3:String;
      
      public var catch1:String;
      
      public var catch2:String;
      
      public var bisha:String;
      
      public var bishaUP:String;
      
      public var bishaSUPER:String;
      
      public var hurtAction:String;
      
      public var waiKai:String;
      
      public var waiKaiW:String;
      
      public var waiKaiS:String;
      
      public var attackAIR:String;
      
      public var skillAIR:String;
      
      public var bishaAIR:String;
      
      public var airHitTimes:int;
      
      public var jumpTimes:int;
      
      public var bishaQi:int = 100;
      
      public var bishaUPQi:int = 100;
      
      public var bishaSUPERQi:int = 300;
      
      public var bishaAIRQi:int = 100;
      
      private var _cdObj:Object = {};
      
      public function FighterAction()
      {
         super();
      }
      
      public function clear() : void
      {
         this.clearState();
         this.clearAction();
      }
      
      public function clearState() : void
      {
         this.isMoving = false;
         this.isJumping = false;
         this.isDefensing = false;
         this.isDashing = false;
         this.isHurting = false;
         this.isHurtFlying = false;
         this.isDefenseHiting = false;
         this.touchFloorBreakAct = false;
      }
      
      public function clearAction() : void
      {
         this.hitTarget = null;
         this.hitTargetChecker = null;
         this.moveLeft = null;
         this.moveRight = null;
         this.defense = null;
         this.jump = null;
         this.jumpQuick = null;
         this.jumpDown = null;
         this.dash = null;
         this.attack = null;
         this.skill1 = null;
         this.skill2 = null;
         this.zhao1 = null;
         this.zhao2 = null;
         this.zhao3 = null;
         this.catch1 = null;
         this.catch2 = null;
         this.bisha = null;
         this.bishaUP = null;
         this.bishaSUPER = null;
         this.bishaQi = 100;
         this.bishaUPQi = 100;
         this.bishaAIRQi = 100;
         this.bishaSUPERQi = 300;
         this.hurtAction = null;
         this.waiKai = null;
         this.attackAIR = null;
         this.skillAIR = null;
         this.bishaAIR = null;
         this.touchFloor = null;
         this.airMove = false;
      }
      
      public function render() : void
      {
         var _loc2_:* = undefined;
         var infiniteOn:Boolean = Boolean(GameConfig.INFINITE_ENERGY);
         if(infiniteOn)
         {
            if(this.bishaQi != 100)
            {
               this.bishaQi = 100;
            }
            if(this.bishaUPQi != 100)
            {
               this.bishaUPQi = 100;
            }
            if(this.bishaSUPERQi != 300)
            {
               this.bishaSUPERQi = 300;
            }
            if(this.bishaAIRQi != 100)
            {
               this.bishaAIRQi = 100;
            }
         }
         for(_loc2_ in this._cdObj)
         {
            if(--this._cdObj[_loc2_] <= 0)
            {
               delete this._cdObj[_loc2_];
            }
         }
      }
      
      public function setCD(param1:String, param2:int) : void
      {
         this._cdObj[param1] = param2 / GameConfig.FPS_GAME;
         trace(this._cdObj[param1]);
      }
      
      public function CDOK(param1:String) : Boolean
      {
         return !this._cdObj[param1];
      }
   }
}

