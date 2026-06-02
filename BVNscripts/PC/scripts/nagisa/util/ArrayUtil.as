package nagisa.util
{
   public class ArrayUtil
   {
      
      public function ArrayUtil()
      {
         super();
      }
      
      public static function equal(param1:Object, param2:Object) : Boolean
      {
         if(param1 == param2)
         {
            return true;
         }
         if(param1.length != param2.length)
         {
            return false;
         }
         return contain(param1,param2);
      }
      
      public static function contain(param1:Object, param2:Object) : Boolean
      {
         if(ClassUtil.checkTargetType(param1,Array,Vector.<*>) == -1 || ClassUtil.checkTargetType(param2,Array,Vector.<*>) == -1)
         {
            throw new TypeError("Static ArrayUtil.contain Error::param is not Vector or Array!");
         }
         for each(var _loc3_ in param2)
         {
            if(param1.indexOf(_loc3_) == -1)
            {
               return false;
            }
         }
         return true;
      }
      
      public static function getRandomInArray(param1:Object, param2:Boolean = false) : *
      {
         if(param1 == null || param1.length < 1)
         {
            return null;
         }
         var _loc3_:int = Math.round(Math.random() * (param1.length - 1));
         var _loc4_:* = param1[_loc3_];
         if(param2)
         {
            param1.splice(_loc3_,1);
         }
         return _loc4_;
      }
      
      public static function getInArray(param1:Number, param2:Number, param3:Number) : Number
      {
         if(param1 < param2)
         {
            param1 = param2;
         }
         if(param1 > param3)
         {
            param1 = param3;
         }
         return param1;
      }
      
      public static function isOutOfRange(param1:Number, param2:Number, param3:Number) : int
      {
         if(param1 < param2)
         {
            return -1;
         }
         if(param1 > param3)
         {
            return 1;
         }
         return 0;
      }
      
      public static function clone(param1:*) : *
      {
         var _loc3_:int = 0;
         if(!param1 || !param1.length)
         {
            return null;
         }
         var _loc4_:Class = ClassUtil.getTargetClass(param1);
         var _loc2_:Class = new _loc4_();
         _loc3_ = 0;
         while(_loc3_ < param1.length)
         {
            _loc2_[_loc3_] = param1[_loc3_];
            _loc3_++;
         }
         return _loc2_;
      }
      
      public static function addItem(param1:*, param2:Object) : Boolean
      {
         var _loc3_:int = int(param1.indexOf(param2));
         if(_loc3_ != -1)
         {
            return false;
         }
         param1[param1.length] = param2;
         return true;
      }
      
      public static function getItemBy(param1:*, param2:String, param3:Object, param4:Boolean = false) : *
      {
         for each(var _loc5_ in param1)
         {
            if(param4)
            {
               if(_loc5_[param2]() == param3)
               {
                  return _loc5_;
               }
            }
            else if(_loc5_[param2] == param3)
            {
               return _loc5_;
            }
         }
         return null;
      }
      
      public static function getItemsBy(param1:*, param2:String, param3:Object, param4:Boolean = false) : Vector.<*>
      {
         var _loc5_:* = undefined;
         for each(var _loc6_ in param1)
         {
            if(param4)
            {
               if(_loc6_[param2]() == param3)
               {
                  if(!_loc5_)
                  {
                     _loc5_ = new Vector.<*>();
                  }
                  _loc5_[_loc5_.length] = _loc6_;
               }
            }
            else if(_loc6_[param2] == param3)
            {
               if(!_loc5_)
               {
                  _loc5_ = new Vector.<*>();
               }
               _loc5_[_loc5_.length] = _loc6_;
            }
         }
         return _loc5_;
      }
      
      public static function removeItemBy(param1:*, param2:String, param3:Object, param4:Boolean = true, param5:Boolean = true) : Boolean
      {
         var _loc6_:Object = null;
         var _loc7_:int = 0;
         while(_loc7_ < param1.length)
         {
            _loc6_ = param1[_loc7_];
            if(_loc6_[param2] == param3)
            {
               param1.splice(_loc7_,1);
               if(param4)
               {
                  ObjectUtil.destoryObject(_loc6_,param5);
               }
               return true;
            }
         }
         return false;
      }
      
      public static function removeItem(param1:*, param2:Object = null, param3:Boolean = true, param4:Boolean = true) : Boolean
      {
         if(!param2)
         {
            while(param1.length)
            {
               param2 = param1[param1.length - 1];
               if(!param2)
               {
                  param1.splice(param1.length - 1,1);
               }
               else
               {
                  if(param3)
                  {
                     ObjectUtil.destoryObject(param2,param4);
                  }
                  removeItem(param1,param2);
               }
            }
            return true;
         }
         var _loc5_:int = int(param1.indexOf(param2));
         if(_loc5_ == -1)
         {
            return false;
         }
         param1.splice(_loc5_,1);
         if(param3)
         {
            ObjectUtil.destoryObject(param2,param4);
         }
         return true;
      }
   }
}

