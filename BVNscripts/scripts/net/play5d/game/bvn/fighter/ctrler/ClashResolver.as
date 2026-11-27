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
    * 鎷兼嫑瑁佸喅鍣紙2026-11-27锛屾柟妗堣 doc/clash/plan.md锛夈€?    *
    * 鍙鏁板€笺€佷笉纰版樉绀哄璞°€佷笉鏀圭姸鎬侊細杈撳叆涓や晶鍛戒腑 VO 涓庣簿鐏碉紝杈撳嚭銆孉 璧?/ B 璧?/ 鍚屾椂 / 涓嶇畻鎷兼嫑銆嶃€?    * 浼樺厛绾ф槸鍥涚骇瀛楀吀搴忥細閲嶅嚮 > 鍑诲€?> 闈㈤暱 > 鍚庡嚭锛涘叏骞虫墠鍒ゅ悓鏃讹紙鍙屾柟寮瑰紑锛夈€?    *
    * 涓轰粈涔堜笉鍦?beHit 閲屽垽锛氬厛搴旂敤鐨勪竴鏂瑰凡缁忔妸瀵规墜鎵撹繘鍙楀嚮骞剁疆 isAllowBeHit=false锛?    * 浜嬪悗鎷垮埌鐨勭姸鎬佸凡琚薄鏌撱€傚敮涓€姝ｇ‘鐨勭獥鍙ｆ槸 checkHit 閲屻€屼袱鍚戦兘绠楀畬銆佸皻鏈簲鐢ㄣ€嶄箣闂淬€?    */
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
       * 瑁佸喅鍏ュ彛銆俻aram5 / param6 鍒嗗埆鏄?A 鎵?B銆丅 鎵?A 鐨勪氦闆嗙煩褰€?       * 杩斿洖 null = 涓嶇畻鎷兼嫑锛堝紑鍏冲叧銆佹湁涓€鏂逛笉鍚堟牸銆乷wner 瑙ｆ瀽涓嶅嚭瑙掕壊锛夈€?       */
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
            return this.make(_loc9_ > _loc10_ ? ClashVerdictVO.WIN_A : ClashVerdictVO.WIN_B,"閲嶅嚮",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
         }
         var _loc11_:int = param1.hurtType == 1 ? 1 : 0;
         var _loc12_:int = param3.hurtType == 1 ? 1 : 0;
         if(_loc11_ != _loc12_)
         {
            return this.make(_loc11_ > _loc12_ ? ClashVerdictVO.WIN_A : ClashVerdictVO.WIN_B,"鍑诲€?,param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
         }
         var _loc13_:Number = this.reach(param1,_loc7_);
         var _loc14_:Number = this.reach(param3,_loc8_);
         if(Math.abs(_loc13_ - _loc14_) > GameConfig.CLASH_REACH_EPS)
         {
            return this.make(_loc13_ > _loc14_ ? ClashVerdictVO.WIN_A : ClashVerdictVO.WIN_B,"闈㈤暱",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
         }
         var _loc15_:Number = _loc7_.getActionStartFrame() - this.sideLag(_loc7_);
         var _loc16_:Number = _loc8_.getActionStartFrame() - this.sideLag(_loc8_);
         var _loc17_:int = this.simWindowFrames();
         if(Math.abs(_loc15_ - _loc16_) > _loc17_)
         {
            return this.make(_loc15_ > _loc16_ ? ClashVerdictVO.WIN_A : ClashVerdictVO.WIN_B,"鍚庡嚭",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
         }
         return this.make(ClashVerdictVO.TIE,"鍚屾椂",param1,param2,param3,param4,_loc7_,_loc8_,param5,param6);
      }

      /** 鍙銆岃鑹叉湰浜虹殑杩戣韩鍒ゅ畾銆嶄笌鏀诲嚮浣撳弬涓庯紱蹇呮潃/鎶撳彇/瀛愬脊/杈呭姪涓€寰嬩笉绠楁嫾鎷涖€?*/
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

      /** 闈㈤暱锛氬懡涓灛闂存敾鍑荤洅鍦ㄦ湞鍚戜笂鐨勫娌垮埌瑙掕壊鏍圭殑妯悜璺濈銆傞敋鐐瑰繀椤绘槸瑙掕壊鏍癸紝涓嶆槸鏀诲嚮浣撱€?*/
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

      /** 鍚屾椂绐楀彛鎸夋绉掓姌绠楋細60fps鈮? 甯с€?0fps=0 甯э紙浣庣敾璐ㄤ笌 LAN 閮戒細鍘嬪埌 30fps锛夈€?*/
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
