package net.play5d.game.bvn.fighter.ctrler
{
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.*;
   
   public class FighterKeyCtrl implements IFighterActionCtrl
   {
      
      public var inputType:String;
      
      public var classicMode:Boolean = false;
      
      private var _justDown:int = 0;
      
      public function FighterKeyCtrl()
      {
         super();
      }
      
      public function initlize() : void
      {
         if(!this.classicMode)
         {
            this._justDown = 2;
            GameInputer.listenKeys(this.inputType,["attack","jump","dash","skill","superSkill"],2);
         }
         else
         {
            this._justDown = 0;
         }
      }
      
      public function render() : void
      {
      }
      
      public function renderAnimate() : void
      {
      }
      
      public function destory() : void
      {
         if(!this.classicMode)
         {
            GameInputer.unListenKeys(this.inputType,2);
         }
      }
      
      public function enabled() : Boolean
      {
         return GameCtrl.I.actionEnable;
      }
      
      public function moveLEFT() : Boolean
      {
         return Boolean(GameInputer.left(this.inputType,0)) && !GameInputer.right(this.inputType,0);
      }
      
      public function moveRIGHT() : Boolean
      {
         return Boolean(GameInputer.right(this.inputType,0)) && !GameInputer.left(this.inputType,0);
      }
      
      public function defense() : Boolean
      {
         return GameInputer.down(this.inputType,0);
      }
      
      public function attack() : Boolean
      {
         return Boolean(GameInputer.attack(this.inputType,this._justDown)) && !(Boolean(GameInputer.up(this.inputType,0)) || Boolean(GameInputer.down(this.inputType,0)) || Boolean(GameInputer.jump(this.inputType,0)));
      }
      
      public function jump() : Boolean
      {
         return Boolean(GameInputer.jump(this.inputType,this._justDown)) && !GameInputer.attack(this.inputType,0);
      }
      
      public function jumpQuick() : Boolean
      {
         if(this.classicMode)
         {
            return false;
         }
         return Boolean(GameInputer.jump(this.inputType,this._justDown)) && !GameInputer.attack(this.inputType,0);
      }
      
      public function jumpDown() : Boolean
      {
         return Boolean(GameInputer.down(this.inputType,0)) && Boolean(GameInputer.jump(this.inputType,this._justDown));
      }
      
      public function dash() : Boolean
      {
         return Boolean(GameInputer.dash(this.inputType,this._justDown)) && !GameInputer.down(this.inputType,0);
      }
      
      public function dashJump() : Boolean
      {
         return GameInputer.dash(this.inputType,this._justDown);
      }
      
      public function skill1() : Boolean
      {
         return Boolean(GameInputer.down(this.inputType,0)) && Boolean(GameInputer.attack(this.inputType,this._justDown));
      }
      
      public function skill2() : Boolean
      {
         return Boolean(GameInputer.up(this.inputType,0)) && Boolean(GameInputer.attack(this.inputType,this._justDown));
      }
      
      public function zhao1() : Boolean
      {
         return Boolean(GameInputer.skill(this.inputType,this._justDown)) && !GameInputer.up(this.inputType,0) && !GameInputer.down(this.inputType,0);
      }
      
      public function zhao2() : Boolean
      {
         return Boolean(GameInputer.down(this.inputType,0)) && Boolean(GameInputer.skill(this.inputType,this._justDown));
      }
      
      public function zhao3() : Boolean
      {
         return Boolean(GameInputer.up(this.inputType,0)) && Boolean(GameInputer.skill(this.inputType,this._justDown));
      }
      
      public function catch1() : Boolean
      {
         return Boolean(GameInputer.attack(this.inputType,2)) && (Boolean(GameInputer.left(this.inputType,0)) || Boolean(GameInputer.right(this.inputType,0)));
      }
      
      public function catch2() : Boolean
      {
         return Boolean(GameInputer.skill(this.inputType,2)) && (Boolean(GameInputer.left(this.inputType,0)) || Boolean(GameInputer.right(this.inputType,0)));
      }
      
      public function bisha() : Boolean
      {
         return Boolean(GameInputer.superSkill(this.inputType,this._justDown)) && !(Boolean(GameInputer.up(this.inputType,0)) || Boolean(GameInputer.down(this.inputType,0)));
      }
      
      public function bishaUP() : Boolean
      {
         return Boolean(GameInputer.superSkill(this.inputType,this._justDown)) && Boolean(GameInputer.up(this.inputType,0));
      }
      
      public function bishaSUPER() : Boolean
      {
         return Boolean(GameInputer.superSkill(this.inputType,this._justDown)) && Boolean(GameInputer.down(this.inputType,0));
      }
      
      public function assist() : Boolean
      {
         return GameInputer.special(this.inputType,0);
      }
      
      public function specailSkill() : Boolean
      {
         return GameInputer.special(this.inputType,0);
      }
      
      public function attackAIR() : Boolean
      {
         return GameInputer.attack(this.inputType,this._justDown);
      }
      
      public function skillAIR() : Boolean
      {
         return GameInputer.skill(this.inputType,this._justDown);
      }
      
      public function bishaAIR() : Boolean
      {
         return GameInputer.superSkill(this.inputType,this._justDown);
      }
      
      public function waiKai() : Boolean
      {
         return Boolean(GameInputer.wankai(this.inputType,0)) && !(Boolean(GameInputer.up(this.inputType,0)) || Boolean(GameInputer.down(this.inputType,0)));
      }
      
      public function waiKaiW() : Boolean
      {
         return Boolean(GameInputer.up(this.inputType,0)) && Boolean(GameInputer.wankai(this.inputType,0));
      }
      
      public function waiKaiS() : Boolean
      {
         return Boolean(GameInputer.down(this.inputType,0)) && Boolean(GameInputer.wankai(this.inputType,0));
      }
      
      public function ghostStep() : Boolean
      {
         return Boolean(GameInputer.dash(this.inputType,this._justDown)) && Boolean(GameInputer.down(this.inputType,0));
      }
      
      public function ghostJump() : Boolean
      {
         return Boolean(GameInputer.dash(this.inputType,this._justDown)) && Boolean(GameInputer.up(this.inputType,0));
      }
      
      public function ghostJumpDown() : Boolean
      {
         return Boolean(GameInputer.dash(this.inputType,this._justDown)) && Boolean(GameInputer.down(this.inputType,0));
      }
   }
}

