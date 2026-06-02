package nagisa.util
{
   import flash.geom.Point;
   import flash.geom.Rectangle;
   
   public class MathUtil
   {
      
      public static const radianToRotation:Number = 57.29577951308232;
      
      public function MathUtil()
      {
         super();
      }
      
      public static function getDistance(param1:Point, param2:Point = null) : Number
      {
         if(!param2)
         {
            param2 = new Point();
         }
         return Math.pow(Math.pow(param1.x - param2.x,2) + Math.pow(param1.x - param2.x,2),0.5);
      }
      
      public static function getDistanceXY(param1:Number, param2:Number) : Number
      {
         return Math.sqrt(param1 * param1 + param2 * param2);
      }
      
      public static function getRadianByPoint(param1:*, param2:*) : Number
      {
         return getRadianByXY(param2.x - param1.x,param2.y - param1.y);
      }
      
      public static function getRadianByXY(param1:Number, param2:Number) : Number
      {
         return Math.atan2(param2,param1);
      }
      
      public static function getRotationByXY(param1:Number, param2:Number) : Number
      {
         return asRotation(getRadianByXY(param1,param2));
      }
      
      public static function asRadian(param1:Number) : Number
      {
         return param1 / 57.29577951308232;
      }
      
      public static function asRotation(param1:Number) : Number
      {
         return param1 * 57.29577951308232;
      }
      
      public static function getRandomPointByRect(param1:Rectangle) : Point
      {
         return new Point(param1.x + param1.width * Math.random(),param1.y + param1.height * Math.random());
      }
      
      public static function getRandomPointByCircle(param1:Number, param2:Number, param3:Number) : Point
      {
         var _loc4_:Number = 6.28 * Math.random();
         param3 *= Math.random();
         return new Point(param1 + param3 * Math.cos(_loc4_),param2 + param3 * Math.sin(_loc4_));
      }
      
      public static function getRandomInRange(param1:Number) : Number
      {
         return param1 * Math.random() * (Math.random() > 0.5 ? 1 : -1);
      }
      
      public static function sgn(param1:Number) : int
      {
         if(!param1)
         {
            return 0;
         }
         return param1 > 0 ? 1 : -1;
      }
      
      public static function near(param1:Number, param2:Number, param3:Number) : Number
      {
         param3 = Math.abs(param3);
         var _loc4_:int = sgn(param1 - param2);
         if(!_loc4_ || Math.abs(param1 - param2) < param3)
         {
            return param1;
         }
         return param2 + param3 * _loc4_;
      }
      
      public static function away(param1:Number, param2:Number, param3:Number) : Number
      {
         param3 = Math.abs(param3);
         var _loc4_:int = sgn(param2 - param1);
         return param2 + param3 * _loc4_;
      }
      
      public static function quadrant(param1:Number, param2:Number, param3:Boolean = false) : int
      {
         if(param3)
         {
            if(param1 > 0 && param2 >= 0)
            {
               return 1;
            }
            if(param1 <= 0 && param2 > 0)
            {
               return 2;
            }
            if(param1 < 0 && param2 <= 0)
            {
               return 3;
            }
            if(param1 >= 0 && param2 < 0)
            {
               return 4;
            }
         }
         if(param1 > 0 && param2 > 0)
         {
            return 1;
         }
         if(param1 < 0 && param2 > 0)
         {
            return 2;
         }
         if(param1 < 0 && param2 < 0)
         {
            return 3;
         }
         if(param1 > 0 && param2 < 0)
         {
            return 4;
         }
         return 0;
      }
   }
}

