package net.play5d.game.bvn.fighter.ctrler
{
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.GameData;
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
            // 2026-08-15 修复：不再注册 listenKeys —— renderListenKeys 每帧预查询会抢占 isJustDown 边沿，
            // 导致本类的 justDown=2 查询（attack/jump/dash/skill/superSkill）永远拿不到"刚按下"边沿，按钮全部无效。
            // 边沿检测完全由本类的实时查询驱动（isJustDownDelay 的 listened 参数未使用，监听机制无实际功能）。
            // GameInputer.listenKeys(this.inputType,["attack","jump","dash","skill","superSkill"],2);
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
         // listenKeys 已停用（见 initlize），unListenKeys 同步停用
         // if(!this.classicMode)
         // {
         //    GameInputer.unListenKeys(this.inputType,2);
         // }
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
         // 2026-09-09 竞技规则移植：isChangeSpecialKey=true 时灵替 = special 且不按上
         if(!GameData.I.config.isChangeSpecialKey)
         {
            return GameInputer.special(this.inputType,0);
         }
         return Boolean(GameInputer.special(this.inputType,0)) && !Boolean(GameInputer.up(this.inputType,0));
      }
      
      public function specailSkill() : Boolean
      {
         // 2026-09-09 竞技规则移植：isChangeSpecialKey=true 时灵技 = special + 上/下
         if(!GameData.I.config.isChangeSpecialKey)
         {
            return GameInputer.special(this.inputType,0);
         }
         return Boolean(GameInputer.special(this.inputType,0)) && (Boolean(GameInputer.up(this.inputType,0)) || Boolean(GameInputer.down(this.inputType,0)));
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
