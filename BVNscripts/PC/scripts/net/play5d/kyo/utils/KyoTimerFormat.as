package net.play5d.kyo.utils
{
   public class KyoTimerFormat
   {
      
      private static const EN_DAYS:Object = {
         0:"Sunday",
         1:"Monday",
         2:"Tuesdry",
         3:"Wednesday",
         4:"Thursday",
         5:"Friday",
         6:"Saturday"
      };
      
      private static const CN_DAYS:Object = {
         0:"星期天",
         1:"星期一",
         2:"星期二",
         3:"星期三",
         4:"星期四",
         5:"星期五",
         6:"星期六"
      };
      
      public function KyoTimerFormat()
      {
         super();
      }
      
      public static function isAM(param1:Date) : Boolean
      {
         return param1.hours < 12;
      }
      
      public static function getTime(param1:Date, param2:String = " : ", param3:Boolean = true, param4:Boolean = true) : String
      {
         var _loc7_:int = param1.hours;
         var _loc8_:String = formatNum(param1.minutes);
         var _loc6_:String = param3 ? param2 + formatNum(param1.seconds) : "";
         if(!param4 && _loc7_ > 12)
         {
            _loc7_ -= 12;
         }
         var _loc5_:String = formatNum(_loc7_);
         return _loc5_ + param2 + _loc8_ + _loc6_;
      }
      
      public static function getDate(param1:Date, param2:String = "/") : String
      {
         return param1.fullYear + param2 + formatNum(param1.month + 1) + param2 + formatNum(param1.date);
      }
      
      public static function getDateTime(param1:Date, param2:String = "/", param3:String = " : ", param4:Boolean = true, param5:Boolean = true) : String
      {
         return getDate(param1,param2) + " " + getTime(param1,param3,param4,param5);
      }
      
      public static function getDay(param1:Date, param2:int = 1) : String
      {
         var _loc3_:int = param1.day;
         switch(param2 - 1)
         {
            case 0:
               return EN_DAYS[_loc3_];
            case 1:
               return CN_DAYS[_loc3_];
            default:
               return _loc3_.toString();
         }
      }
      
      public static function secToTime(param1:int, param2:String = ":", param3:Boolean = true, param4:Boolean = true) : String
      {
         var _loc7_:int = param1 / 60 / 60;
         param1 -= _loc7_ * 60 * 60;
         var _loc9_:int = param1 / 60;
         param1 -= _loc9_ * 60;
         var _loc8_:String = "";
         if(param4)
         {
            _loc8_ = _loc7_ >= 10 ? _loc7_.toString() : "0" + _loc7_;
            _loc8_ = _loc8_ + param2;
         }
         var _loc6_:String = _loc9_ >= 10 ? _loc9_.toString() : "0" + _loc9_;
         var _loc5_:String = "";
         if(param3)
         {
            _loc5_ = param1 >= 10 ? param1.toString() : "0" + param1;
            _loc5_ = param2 + _loc5_;
         }
         return _loc8_ + _loc6_ + _loc5_;
      }
      
      public static function formatNum(param1:int) : String
      {
         return param1 >= 10 ? param1.toString() : "0" + param1;
      }
   }
}

