package nagisa.util
{
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import nagisa.debug.OutputMessage;
   
   public class NagisaUtil
   {
      
      public function NagisaUtil()
      {
         super();
      }
      
      public static function destory(param1:*, param2:Boolean = true) : void
      {
         if(!("destory" in param1))
         {
            return;
         }
         try
         {
            switch(param1.destory.length)
            {
               case 0:
                  param1.destory();
                  break;
               case 1:
                  param1.destory(param2);
            }
         }
         catch(e:Error)
         {
            OutputMessage.ERROR("NagisaUtil","destory","",e);
         }
      }
      
      public static function url_getSuffix(param1:String) : String
      {
         var _loc2_:int = 0;
         if(!param1)
         {
            return null;
         }
         _loc2_ = param1.lastIndexOf(".");
         if(_loc2_ == -1)
         {
            return "";
         }
         return param1.substr(_loc2_,param1.length - _loc2_);
      }
      
      public static function url_setSuffx(param1:String, param2:String) : String
      {
         var _loc3_:int = 0;
         if(!param1)
         {
            return null;
         }
         _loc3_ = param1.lastIndexOf(".");
         if(_loc3_ == -1)
         {
            return param1 + "." + param2;
         }
         return url_getFolder(param1) + url_getName(param1) + "." + param2;
      }
      
      public static function url_getFolder(param1:String) : String
      {
         var _loc2_:int = 0;
         if(!param1)
         {
            return null;
         }
         _loc2_ = param1.lastIndexOf("/");
         if(_loc2_ == -1)
         {
            return "";
         }
         return param1.substr(0,_loc2_ + 1);
      }
      
      public static function url_getName(param1:String) : String
      {
         if(!param1)
         {
            return null;
         }
         var _loc2_:String = url_getFolder(param1);
         var _loc3_:String = url_getSuffix(param1);
         return param1.substr(_loc2_.length,param1.length - _loc2_.length - _loc3_.length);
      }
      
      public static function url_getPath(param1:String, param2:String, param3:String = null) : String
      {
         param1 = param1 ? param1 + "/" : "";
         param2 ||= "";
         param3 = param3 ? "." + param3 : "";
         return param1 + param2 + param3;
      }
      
      public static function string_remove(param1:String, param2:String) : String
      {
         var _loc3_:int = -1;
         if(!param1 || !param2)
         {
            return param1;
         }
         _loc3_ = param1.indexOf(param2);
         if(_loc3_ == -1)
         {
            return param1;
         }
         return param1.substring(0,_loc3_) + param1.substring(_loc3_ + param2.length);
      }
      
      public static function rect_zoom(param1:Rectangle, param2:Number = 1, param3:Number = 1, param4:Point = null) : Rectangle
      {
         if(!param1 || param1.isEmpty())
         {
            return null;
         }
         var _loc5_:Rectangle = param1.clone();
         var _loc7_:int = MathUtil.sgn(param2);
         var _loc6_:int = MathUtil.sgn(param3);
         if(!_loc7_)
         {
            _loc5_.width = 0;
         }
         else
         {
            if(_loc7_ == -1)
            {
               _loc5_.x = -param1.right;
            }
            _loc5_.x *= param2 * _loc7_;
            _loc5_.width *= param2 * _loc7_;
         }
         if(!_loc6_)
         {
            _loc5_.height = 0;
         }
         else
         {
            if(_loc6_ == -1)
            {
               _loc5_.y = -param1.bottom;
            }
            _loc5_.y *= param3 * _loc6_;
            _loc5_.height *= param3 * _loc6_;
         }
         if(param4)
         {
            _loc5_.x -= param4.x * param2;
            _loc5_.y -= param4.y * param3;
         }
         return _loc5_;
      }
      
      public static function rect_identity(param1:Rectangle, param2:Boolean = false) : Rectangle
      {
         var _loc3_:Rectangle = param2 ? param1 : param1.clone();
         var _loc4_:Number = 0;
         if(_loc3_.width < 0)
         {
            _loc3_.x = _loc3_.right;
            _loc3_.width *= -1;
         }
         if(_loc3_.height < 0)
         {
            _loc3_.y = _loc3_.bottom;
            _loc3_.height *= -1;
         }
         return _loc3_;
      }
      
      public static function rect_createByPoint(param1:Point, param2:Number, param3:Number, param4:Number, param5:Number) : Rectangle
      {
         return new Rectangle(param2 + param1.x,param4 + param1.y,param3 - param2,param5 - param4);
      }
      
      public static function rect_compare(param1:Rectangle, param2:Rectangle) : int
      {
         if(param1.x == param2.x && param1.y == param2.y && param1.width == param2.width && param1.height == param2.height)
         {
            return 0;
         }
         return MathUtil.sgn(param1.width * param1.height - param2.width * param2.height);
      }
      
      public static function rect_getCenter(param1:Rectangle) : Point
      {
         return param1 ? new Point(param1.x + param1.width / 2,param1.y + param1.height / 2) : null;
      }
      
      public static function controls_getIndexFromDataProvider(param1:Object, param2:String, param3:Object) : int
      {
         var _loc5_:int = 0;
         var _loc4_:Object = null;
         var _loc6_:Object = param1["dataProvider"];
         _loc5_ = 0;
         while(_loc5_ < _loc6_.length)
         {
            _loc4_ = _loc6_.getItemAt(_loc5_);
            if(_loc4_[param2] == param3)
            {
               return _loc5_;
            }
            _loc5_++;
         }
         return -1;
      }
      
      public static function controls_setControlDataProvider(param1:Object, param2:Object, param3:Function, param4:Function, param5:Boolean = true) : void
      {
         var _loc8_:String = null;
         var _loc6_:Array = null;
         var _loc7_:Object = param1["dataProvider"] = ObjectUtil.shallowClone(param1["dataProvider"]);
         for(_loc8_ in param2)
         {
            _loc7_.addItem({
               "label":param3(_loc8_,param2[_loc8_],param2),
               "data":param4(_loc8_,param2[_loc8_],param2)
            });
         }
         if(param5)
         {
            _loc6_ = _loc7_.toArray();
            _loc6_.sortOn("label");
            param1["dataProvider"] = _loc7_ = ObjectUtil.shallowClone(param1["dataProvider"]);
            while(_loc6_.length)
            {
               _loc7_.addItem(_loc6_.shift());
            }
         }
      }
      
      public static function function_apply(param1:Function, param2:Object, ... rest) : *
      {
         return function_apply2(param1,param2,rest);
      }
      
      public static function function_apply2(param1:Function, param2:Object, param3:Array) : *
      {
         if(!param3.length)
         {
            param1();
            return 0;
         }
         return param1.apply(param2,param3.slice(0,param1.length));
      }
      
      public static function sound_getTotalFrame(param1:Number, param2:int) : int
      {
         return Math.ceil(param1 / 1000 * param2);
      }
      
      public static function sound_getTime(param1:int, param2:int) : Number
      {
         return param1 / param2 * 1000;
      }
      
      public static function nagisa_setAnimateFPS(param1:int, param2:int) : int
      {
         return Math.ceil(param2 / param1) - 1;
      }
      
      public static function data_saveObject(param1:Object, param2:String, param3:String = null) : void
      {
         var _loc4_:String = JSON.stringify(param1);
         param3 ? FileUtil.writeFile(param3 + "/" + param2,param1) : FileUtil.writeAppFloderFile(param2,_loc4_);
      }
      
      public static function data_readObject(param1:String, param2:String = null) : Object
      {
         param2 = param2 ? param2 + "/" + param1 : FileUtil.getAppFloderFileUrl("bvnsave.sav");
         var _loc3_:String = FileUtil.readTextFile(param2);
         if(_loc3_ == null)
         {
            return null;
         }
         return JSON.parse(_loc3_);
      }
   }
}

