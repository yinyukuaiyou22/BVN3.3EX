package net.play5d.game.bvn.fighter.ctrler
{
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.AIModel;
   import net.play5d.game.bvn.data.AIVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.ctrler.ai.FighterAILogic;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   
   public class FighterAICtrl implements IFighterActionCtrl
   {
      
      public var AILevel:int;
      
      public var fighter:FighterMain;
      
      private var _ai_update_gap:int;
      
      private var _ai_update_frame:int;
      
      private var _AIlogic:*;
      
      public function FighterAICtrl()
      {
         super();
      }
      
      public function initlize() : void
      {
         var _loc2_:AIVO = AIModel.I.getAI(GameData.I.config.enableCurAI);
         if(_loc2_ == null || _loc2_.id == "default")
         {
            _AIlogic = new FighterAILogic(AILevel,fighter);
            return;
         }
         var _loc1_:Class = _loc2_.cls as Class;
         try
         {
            _AIlogic = new _loc1_(AILevel,fighter);
         }
         catch(e:Error)
         {
            throw new Error("FighterAICtrl.initlize::外置AI [" + _loc2_.id + "] 加载出错！");
         }
      }
      
      public function destory() : void
      {
         fighter = null;
         if(_AIlogic)
         {
            _AIlogic.destory();
            _AIlogic = null;
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
         _AIlogic.render();
      }
      
      public function moveLEFT() : Boolean
      {
         return _AIlogic.moveLeft;
      }
      
      public function moveRIGHT() : Boolean
      {
         return _AIlogic.moveRight;
      }
      
      public function moveUP() : Boolean
      {
         return _AIlogic.jump;
      }
      
      public function moveDOWN() : Boolean
      {
         return _AIlogic.jumpDown;
      }
      
      public function defense() : Boolean
      {
         return _AIlogic.defense;
      }
      
      public function attack() : Boolean
      {
         return _AIlogic.attack;
      }
      
      public function jump() : Boolean
      {
         return _AIlogic.jump;
      }
      
      public function jumpQuick() : Boolean
      {
         return false;
      }
      
      public function jumpDown() : Boolean
      {
         return _AIlogic.jumpDown;
      }
      
      public function dash() : Boolean
      {
         return _AIlogic.dash;
      }
      
      public function dashJump() : Boolean
      {
         return _AIlogic.downJump;
      }
      
      public function skill1() : Boolean
      {
         return _AIlogic.skill1;
      }
      
      public function skill2() : Boolean
      {
         return _AIlogic.skill2;
      }
      
      public function zhao1() : Boolean
      {
         return _AIlogic.zhao1;
      }
      
      public function zhao2() : Boolean
      {
         return _AIlogic.zhao2;
      }
      
      public function zhao3() : Boolean
      {
         return _AIlogic.zhao3;
      }
      
      public function catch1() : Boolean
      {
         return _AIlogic.catch1;
      }
      
      public function catch2() : Boolean
      {
         return _AIlogic.catch2;
      }
      
      public function bisha() : Boolean
      {
         return _AIlogic.bisha;
      }
      
      public function bishaUP() : Boolean
      {
         return _AIlogic.bishaUP;
      }
      
      public function bishaSUPER() : Boolean
      {
         return _AIlogic.bishaSUPER;
      }
      
      public function assist() : Boolean
      {
         return _AIlogic.assist;
      }
      
      public function specailSkill() : Boolean
      {
         return _AIlogic.specialSkill;
      }
      
      public function attackAIR() : Boolean
      {
         return _AIlogic.attackAIR;
      }
      
      public function skillAIR() : Boolean
      {
         return _AIlogic.skillAIR;
      }
      
      public function bishaAIR() : Boolean
      {
         return _AIlogic.bishaAIR;
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
      
      public function holdAttack() : Boolean
      {
         return _AIlogic.holdAttack;
      }
      
      public function holdSkill() : Boolean
      {
         return _AIlogic.holdSkill;
      }
      
      public function holdBisha() : Boolean
      {
         return _AIlogic.holdBisha;
      }
      
      public function ghostStep() : Boolean
      {
         return _AIlogic.ghostStep;
      }
      
      public function ghostJump() : Boolean
      {
         return _AIlogic.ghostJump;
      }
      
      public function ghostJumpDown() : Boolean
      {
         return _AIlogic.ghostJumpDowm;
      }
   }
}

