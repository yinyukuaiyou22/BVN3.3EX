package nagisa.debug
{
   public class OutputMessage
   {
      
      public function OutputMessage()
      {
         super();
      }
      
      public static function TRACE(param1:String, param2:String, param3:String, ... rest) : void
      {
         var _loc5_:String = param1 + "." + param2 + " " + param3 + " :: ";
         rest.unshift(_loc5_);
         trace.call(null,rest);
      }
      
      public static function ERROR(param1:String, param2:String, param3:String, param4:Error = null, param5:Boolean = false) : void
      {
         param4 ||= new Error();
         var _loc6_:String = param1 + "." + param2 + " " + param4.name + " :: " + param3;
         trace(_loc6_,"\n Error Message : [ " + param4.message + " ] \n");
         if(param5)
         {
            throw param4 || new Error();
         }
      }
      
      public static function WARNING(param1:String, param2:String, param3:String) : void
      {
         var _loc4_:String = param1 + "." + param2 + "  WARNING" + " :: " + param3;
         trace(_loc4_,"\n");
      }
   }
}

