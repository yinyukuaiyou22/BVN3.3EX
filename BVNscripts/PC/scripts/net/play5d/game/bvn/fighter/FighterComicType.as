package net.play5d.game.bvn.fighter
{
   public class FighterComicType
   {
      
      public static const UNKNOWN:int = -1;
      
      public static const BLEACH:int = 0;
      
      public static const NARUTO:int = 1;
      
      public static const KENSHIN:int = 2;
      
      public static const FAIRY_TAIL:int = 3;
      
      public static const ONE_PIECE:int = 4;
      
      private static const _bvnComicType:Array = [0,1,2];
      
      private static const _fvoComicType:Array = [3,4];
      
      public function FighterComicType()
      {
         super();
      }
      
      public static function isBleach(param1:int) : Boolean
      {
         return param1 == 0;
      }
      
      public static function isNaruto(param1:int) : Boolean
      {
         return param1 == 1;
      }
      
      public static function isKenshin(param1:int) : Boolean
      {
         return param1 == 2;
      }
      
      public static function isFairyTail(param1:int) : Boolean
      {
         return param1 == 3;
      }
      
      public static function isOnePiece(param1:int) : Boolean
      {
         return param1 == 4;
      }
      
      public static function isBVN(param1:int) : Boolean
      {
         return _bvnComicType.indexOf(param1) != -1;
      }
      
      public static function isFVO(param1:int) : Boolean
      {
         return _fvoComicType.indexOf(param1) != -1;
      }
   }
}

