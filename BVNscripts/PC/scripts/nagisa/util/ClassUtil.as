package nagisa.util
{
   import flash.utils.getQualifiedClassName;
   
   public class ClassUtil
   {
      
      public static const VALUE_TYPE:Array = [Boolean,int,uint,Number,String,XML];
      
      public function ClassUtil()
      {
         super();
      }
      
      public static function getRegisterClassName(param1:*) : String
      {
         return getQualifiedClassName(param1) + "_NagisaRegister";
      }
      
      public static function getTargetClass(param1:*) : Class
      {
         return param1.constructor as Class;
      }
      
      public static function abstructClass(param1:*, param2:Class) : void
      {
         if(getTargetClass(param1) == param2)
         {
            throw new Error("The Class " + param2 + " is abstructClass,can not be instance!");
         }
      }
      
      public static function getInstance(param1:*) : *
      {
         if(param1 is Class)
         {
            return new param1();
         }
         return param1;
      }
      
      public static function checkTargetType(param1:Object, ... rest) : int
      {
         if(!param1)
         {
            return -1;
         }
         if(!rest || !rest.length)
         {
            return -1;
         }
         for each(var _loc3_ in rest)
         {
            if(param1 is _loc3_ || param1 === _loc3_)
            {
               return rest.indexOf(_loc3_);
            }
         }
         return -1;
      }
      
      public static function checkTargetTypeNoSuper(param1:Object, ... rest) : int
      {
         if(!param1)
         {
            return -1;
         }
         if(!rest || !rest.length)
         {
            return -1;
         }
         var _loc3_:Class = getTargetClass(param1);
         for each(var _loc4_ in rest)
         {
            if(_loc3_ === _loc4_)
            {
               return rest.indexOf(_loc4_);
            }
         }
         return -1;
      }
      
      public static function isValueType(param1:Object) : Boolean
      {
         var _loc2_:Class = getTargetClass(param1);
         return VALUE_TYPE.indexOf(_loc2_) != -1;
      }
   }
}

