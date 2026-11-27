package net.play5d.game.bvn.fighter.models
{
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.IGameSprite;

   /**
    * 鎷兼嫑瑁佸喅缁撴灉锛?026-11-27锛夈€傜函鏁版嵁锛氬彧甯﹀垽瀹氱粨璁轰笌鐢ㄤ簬鏃ュ織/鐗规晥鐨勬暟鍊煎揩鐓э紝
    * 涓嶆寔鏈夐€昏緫锛屼篃涓嶆敼浠讳綍鐘舵€?鈥斺€?搴旂敤鐢?GameMainLogicCtrler.applyClash 璐熻矗銆?    */
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

      /** 鏃ュ織蹇収锛氶潰闀夸笌鎶樼畻鍚庣殑璧锋墜甯э紙鍚瘡渚у亸绉伙級 */
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
