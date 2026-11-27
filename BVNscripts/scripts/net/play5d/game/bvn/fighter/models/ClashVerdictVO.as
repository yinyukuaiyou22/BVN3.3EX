package net.play5d.game.bvn.fighter.models
{
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.IGameSprite;

   /**
    * 拼招裁决结果（2026-11-27）。纯数据：只带判定结论与用于日志/特效的数值快照，
    * 不持有逻辑，也不改任何状态 —— 应用由 GameMainLogicCtrler.applyClash 负责。
    */
   public class ClashVerdictVO
   {
      public static const WIN_A:int = 1;
      public static const WIN_B:int = -1;
      public static const TIE:int = 0;

      public var type:int;
      public var reason:String = "";

      public var fighterA:FighterMain;
      public var fighterB:FighterMain;
      public var hitA:HitVO;
      public var hitB:HitVO;
      public var rectAtoB:Rectangle;
      public var rectBtoA:Rectangle;

      public var winner:FighterMain;
      public var loser:FighterMain;
      public var winnerHitVO:HitVO;
      public var loserHitVO:HitVO;
      public var rect:Rectangle;

      /** 日志快照：面长与折算后的起手帧（含每侧偏移） */
      public var reachA:Number = 0;
      public var reachB:Number = 0;
      public var startA:Number = 0;
      public var startB:Number = 0;

      public function ClashVerdictVO(param1:int = 0)
      {
         super();
         this.type = param1;
      }
   }
}
