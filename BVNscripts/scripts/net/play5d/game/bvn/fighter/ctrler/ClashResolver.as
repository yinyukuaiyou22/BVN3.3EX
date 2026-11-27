package net.play5d.game.bvn.fighter.ctrler
{
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.HitType;
   import net.play5d.game.bvn.fighter.FighterActionState;
   import net.play5d.game.bvn.fighter.FighterAttacker;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.models.ClashVerdictVO;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.IGameSprite;

   /**
    * 拼招裁决器（2026-11-27，方案见 doc/clash/plan.md）。
    *
    * 只读数值、不碰显示对象、不改状态：输入两侧命中 VO 与精灵，输出「A 赢 / B 赢 / 同时 / 不算拼招」。
    * 优先级是四级字典序：重击 > 击倒 > 面长 > 后出；全平才判同时（双方弹开）。
    *
    * 为什么不在 beHit 里判：先应用的一方已经把对手打进受击并置 isAllowBeHit=false，
    * 事后拿到的状态已被污染。唯一正确的窗口是 checkHit 里「两向都算完、尚未应用」之间。
    */
   public class ClashResolver
   {
      private static var _i:ClashResolver;

      public static function get I() : ClashResolver
      {
         if(!_i)
         {
            _i = new ClashResolver();
         }
         return _i;
      }

      public function ClashResolver()
      {
         super();
      }

      public function isEnabled() : Boolean
      {
         return GameData.I.config != null && GameData.I.config.clashEnabled;
      }

      /**
       * 裁决入口。param5 / param6 分别是 A 打 B、B 打 A 的交集矩形。
       * 返回 null = 不算拼招（开关关、有一方不合格、owner 解析不出角色）。
       */
      public function judge(param1:HitVO, param2:IGameSprite, param3:HitVO, param4:IGameSprite, param5:Rectangle, param6:Rectangle) : ClashVerdictVO
      {
         if(!this.isEnabled())
         {
            return null;
         }
         var _loc7_:FighterMain = this.resolveFighter(param2);
         var _loc8_:FighterMain = this.resolveFighter(param4);
         if(_loc7_ == null || _loc8_ == null || _loc7_ == _loc8_)
         {
            return null;
         }
         if(!this.eligible(param1,_loc7_) || !this.eligible(param3,_loc8_))
         {
            return null;
         }
         var _loc9_:int = HitType.isHeavy(param1.hitType) ? 1 : 0;
         var _loc10_:int = HitType.isHeavy(param3.hitType) ? 1 : 0;
         if(_loc9_ != _loc10_)
         {
            return this.make(_loc9_ > _loc10_ ? ClashVerdictVO.WIN_A : ClashVerdictVO.WIN_B,"重击",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
         }
         var _loc11_:int = param1.hurtType == 1 ? 1 : 0;
         var _loc12_:int = param3.hurtType == 1 ? 1 : 0;
         if(_loc11_ != _loc12_)
         {
            return this.make(_loc11_ > _loc12_ ? ClashVerdictVO.WIN_A : ClashVerdictVO.WIN_B,"击倒",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
         }
         var _loc13_:Number = this.reach(param1,_loc7_);
         var _loc14_:Number = this.reach(param3,_loc8_);
         if(Math.abs(_loc13_ - _loc14_) > GameConfig.CLASH_REACH_EPS)
         {
            return this.make(_loc13_ > _loc14_ ? ClashVerdictVO.WIN_A : ClashVerdictVO.WIN_B,"面长",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
         }
         var _loc15_:Number = _loc7_.getActionStartFrame() - this.sideLag(_loc7_);
         var _loc16_:Number = _loc8_.getActionStartFrame() - this.sideLag(_loc8_);
         var _loc17_:int = this.simWindowFrames();
         if(Math.abs(_loc15_ - _loc16_) > _loc17_)
         {
            return this.make(_loc15_ > _loc16_ ? ClashVerdictVO.WIN_A : ClashVerdictVO.WIN_B,"后出",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
         }
         return this.make(ClashVerdictVO.TIE,"同时",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
      }

      /** 只让「角色本人的近身判定」与攻击体参与；必杀/抓取/子弹/辅助一律不算拼招。 */
      private function eligible(param1:HitVO, param2:FighterMain) : Boolean
      {
         if(param1 == null || param2 == null)
         {
            return false;
         }
         if(param1.isBisha() || param1.isCatch() || param1.hitType == HitType.CATCH)
         {
            return false;
         }
         var _loc3_:int = param2.actionState;
         return _loc3_ == FighterActionState.ATTACK_ING || _loc3_ == FighterActionState.SKILL_ING;
      }

      private function resolveFighter(param1:IGameSprite) : FighterMain
      {
         if(param1 is FighterMain)
         {
            return param1 as FighterMain;
         }
         if(param1 is FighterAttacker)
         {
            return (param1 as FighterAttacker).getOwner() as FighterMain;
         }
         return null;
      }

      /** 面长：命中瞬间攻击盒在朝向上的外沿到角色根的横向距离。锚点必须是角色根，不是攻击体。 */
      private function reach(param1:HitVO, param2:FighterMain) : Number
      {
         var _loc3_:Rectangle = param1.currentArea;
         if(_loc3_ == null || param2 == null)
         {
            return 0;
         }
         var _loc4_:Number = param2.direct > 0 ? _loc3_.x + _loc3_.width - param2.x : param2.x - _loc3_.x;
         return _loc4_ < 0 ? 0 : _loc4_;
      }

      private function sideLag(param1:FighterMain) : Number
      {
         var _loc2_:int = param1.team != null ? param1.team.id : 0;
         var _loc3_:Array = GameConfig.CLASH_SIDE_LAG;
         if(_loc3_ != null && _loc2_ >= 0 && _loc2_ < _loc3_.length && _loc3_[_loc2_] != null)
         {
            return Number(_loc3_[_loc2_]);
         }
         return 0;
      }

      /** 同时窗口按毫秒折算：60fps≈1 帧、30fps=0 帧（低画质与 LAN 都会压到 30fps）。 */
      private function simWindowFrames() : int
      {
         var _loc1_:Number = GameConfig.FPS_GAME;
         if(_loc1_ <= 0)
         {
            _loc1_ = 60;
         }
         var _loc2_:int = Math.floor(GameConfig.CLASH_SIM_WINDOW_MS / (1000 / _loc1_));
         return _loc2_ < 0 ? 0 : _loc2_;
      }

      private function make(param1:int, param2:String, param3:HitVO, param4:IGameSprite, param5:HitVO, param6:IGameSprite, param7:FighterMain, param8:FighterMain, param9:Rectangle, param10:Rectangle) : ClashVerdictVO
      {
         var _loc11_:ClashVerdictVO = new ClashVerdictVO(param1);
         _loc11_.reason = param2;
         _loc11_.hitA = param3;
         _loc11_.hitB = param5;
         _loc11_.fighterA = param7;
         _loc11_.fighterB = param8;
         _loc11_.rectAtoB = param9;
         _loc11_.rectBtoA = param10;
         _loc11_.reachA = this.reach(param3,param7);
         _loc11_.reachB = this.reach(param5,param8);
         _loc11_.startA = param7.getActionStartFrame() - this.sideLag(param7);
         _loc11_.startB = param8.getActionStartFrame() - this.sideLag(param8);
         if(param1 == ClashVerdictVO.WIN_A)
         {
            _loc11_.winner = param7;
            _loc11_.loser = param8;
            _loc11_.winnerHitVO = param3;
            _loc11_.loserHitVO = param5;
            _loc11_.rect = param9;
         }
         else if(param1 == ClashVerdictVO.WIN_B)
         {
            _loc11_.winner = param8;
            _loc11_.loser = param7;
            _loc11_.winnerHitVO = param5;
            _loc11_.loserHitVO = param3;
            _loc11_.rect = param10;
         }
         return _loc11_;
      }
   }
}
