package net.play5d.game.bvn.fighter.ctrler
{
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.ctrler.ai.*;
   import net.play5d.game.bvn.interfaces.*;
   
   public class FighterAICtrl implements IFighterActionCtrl
   {
      
      public var AILevel:int;
      
      public var fighter:FighterMain;
      
      private var _target:IGameSprite;
      
      private var _ai_update_gap:int;
      
      private var _ai_update_frame:int;
      
      private var _AIlogic:FighterAILogic;
      
      public function FighterAICtrl()
      {
         super();
      }
      
      public function initlize() : void
      {
         this._AIlogic = new FighterAILogic(this.AILevel,this.fighter);
      }
      
      public function destory() : void
      {
         this.fighter = null;
         this._target = null;
         if(Boolean(this._AIlogic))
         {
            this._AIlogic.destory();
            this._AIlogic = null;
         }
      }
      
      public function enabled() : Boolean
      {
         return GameCtrl.I.actionEnable;
      }
      
      public function render() : void
      {
      }
      
      public function renderAnimate() : void
      {
         this._AIlogic.render();
      }
      
      public function moveLEFT() : Boolean
      {
         return this._AIlogic.moveLeft;
      }
      
      public function moveRIGHT() : Boolean
      {
         return this._AIlogic.moveRight;
      }
      
      public function defense() : Boolean
      {
         return this._AIlogic.defense;
      }
      
      public function attack() : Boolean
      {
         return this._AIlogic.attack;
      }
      
      public function jump() : Boolean
      {
         return this._AIlogic.jump;
      }
      
      public function jumpQuick() : Boolean
      {
         return false;
      }
      
      public function jumpDown() : Boolean
      {
         return this._AIlogic.jumpDown;
      }
      
      public function dash() : Boolean
      {
         return this._AIlogic.dash;
      }
      
      public function dashJump() : Boolean
      {
         return this._AIlogic.downJump;
      }
      
      public function skill1() : Boolean
      {
         return this._AIlogic.skill1;
      }
      
      public function skill2() : Boolean
      {
         return this._AIlogic.skill2;
      }
      
      public function zhao1() : Boolean
      {
         return this._AIlogic.zhao1;
      }
      
      public function zhao2() : Boolean
      {
         return this._AIlogic.zhao2;
      }
      
      public function zhao3() : Boolean
      {
         return this._AIlogic.zhao3;
      }
      
      public function catch1() : Boolean
      {
         return this._AIlogic.catch1;
      }
      
      public function catch2() : Boolean
      {
         return this._AIlogic.catch2;
      }
      
      public function bisha() : Boolean
      {
         return this._AIlogic.bisha;
      }
      
      public function bishaUP() : Boolean
      {
         return this._AIlogic.bishaUP;
      }
      
      public function bishaSUPER() : Boolean
      {
         return this._AIlogic.bishaSUPER;
      }
      
      public function assist() : Boolean
      {
         return this._AIlogic.assist;
      }
      
      public function specailSkill() : Boolean
      {
         return this._AIlogic.specialSkill;
      }
      
      public function attackAIR() : Boolean
      {
         return this._AIlogic.attackAIR;
      }
      
      public function skillAIR() : Boolean
      {
         return this._AIlogic.skillAIR;
      }
      
      public function bishaAIR() : Boolean
      {
         return this._AIlogic.bishaAIR;
      }
      
      public function waiKai() : Boolean
      {
         return false;
      }
      
      public function waiKaiW() : Boolean
      {
         return false;
      }
      
      public function waiKaiS() : Boolean
      {
         return false;
      }
      
      public function ghostStep() : Boolean
      {
         return this._AIlogic.ghostStep;
      }
      
      public function ghostJump() : Boolean
      {
         return this._AIlogic.ghostJump;
      }
      
      public function ghostJumpDown() : Boolean
      {
         return this._AIlogic.ghostJumpDowm;
      }
   }
}

