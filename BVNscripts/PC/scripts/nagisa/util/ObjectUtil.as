package nagisa.util
{
   import flash.net.getClassByAlias;
   import flash.net.registerClassAlias;
   import flash.utils.ByteArray;
   import flash.utils.describeType;
   import flash.utils.getQualifiedClassName;
   import nagisa.debug.OutputMessage;
   
   public class ObjectUtil
   {
      
      public function ObjectUtil()
      {
         super();
      }
      
      public static function getObjValue(param1:Object, param2:String, param3:*) : *
      {
         if(!param1)
         {
            return param3;
         }
         if(!param2 || !(param2 in param1))
         {
            return param3;
         }
         if(param1[param2] === undefined)
         {
            return param3;
         }
         return param1[param2];
      }
      
      public static function getTargetProperties(param1:Object) : Vector.<String>
      {
         var _loc3_:* = null;
         var _loc4_:String = null;
         var _loc5_:* = undefined;
         var _loc2_:XML = describeType(param1);
         for each(_loc3_ in _loc2_..accessor)
         {
            _loc4_ = _loc3_.@name;
            _loc5_.push(_loc4_);
         }
         return _loc5_;
      }
      
      public static function checkTargetProperties(param1:*, ... rest) : Boolean
      {
         if(!rest || !rest.length)
         {
            return true;
         }
         for each(var _loc3_ in rest)
         {
            if(!(_loc3_ in param1))
            {
               return false;
            }
         }
         return true;
      }
      
      public static function setValueByObject(param1:*, param2:Object) : void
      {
         var _loc4_:String = null;
         var _loc3_:* = null;
         if(!param2)
         {
            return;
         }
         for(_loc4_ in param2)
         {
            if(_loc4_ in param1)
            {
               param1[_loc4_] = param2[_loc4_];
            }
         }
      }
      
      public static function itemToObject(param1:*) : Object
      {
         return null;
      }
      
      public static function shallowClone(param1:Object) : *
      {
         var _loc2_:* = null;
         var _loc3_:Class = ClassUtil.getTargetClass(param1);
         return new _loc3_();
      }
      
      public static function deepClone(param1:Object) : Object
      {
         var _loc2_:Class = null;
         var _loc3_:ByteArray = null;
         var _loc5_:Class = Object(param1).constructor as Class;
         var _loc4_:String = getQualifiedClassName(param1);
         try
         {
            _loc2_ = getClassByAlias(_loc4_);
         }
         catch(err:Error)
         {
         }
         if(!_loc2_)
         {
            registerClassAlias(_loc4_,_loc5_);
         }
         else
         {
            if(_loc2_ == _loc5_)
            {
               _loc3_ = new ByteArray();
               _loc3_.writeObject(param1);
               _loc3_.position = 0;
               return _loc3_.readObject();
            }
            registerClassAlias(_loc4_ + "" + _loc4_,_loc5_);
         }
         return null;
      }
      
      public static function destoryObject(param1:Object, param2:Boolean = true, param3:Boolean = false, param4:Array = null) : void
      {
         var _loc5_:* = undefined;
         if(param3)
         {
            for(var _loc6_ in param1)
            {
               _loc5_ = param1[_loc6_];
               if(!ClassUtil.isValueType(_loc5_))
               {
                  if(!(param4 && param4.indexOf(_loc6_) != -1))
                  {
                     param1[_loc6_] = null;
                  }
               }
            }
         }
         if(!("destory" in param1))
         {
            return;
         }
         if(param1.destory.length < 1)
         {
            param1.destory();
            return;
         }
         param1.destory(param2);
      }
      
      public static function setTargetInterface(param1:*, param2:String, param3:Object, param4:Boolean = false) : Boolean
      {
         if(!param1)
         {
            return false;
         }
         if(!(param2 in param1))
         {
            return false;
         }
         param1[param2](param3);
         if(param4)
         {
            if(!("initialize" in param1))
            {
               return true;
            }
            try
            {
               param1.initialize();
            }
            catch(e:Error)
            {
               OutputMessage.ERROR("ObjectUtil","setTargetInterface","target.initialize",e,true);
            }
         }
         return true;
      }
   }
}

