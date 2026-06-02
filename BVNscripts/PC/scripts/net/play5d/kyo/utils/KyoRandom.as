package net.play5d.kyo.utils
{
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.MapVO;
   
   public class KyoRandom
   {
      
      public function KyoRandom()
      {
         super();
      }
      
      public static function getRandomInArray(param1:Object, param2:Boolean = false) : *
      {
         var _loc4_:int = 0;
         var _loc3_:* = undefined;
         while(_loc3_ == null)
         {
            if(param1 == null || param1.length < 1)
            {
               return null;
            }
            _loc4_ = Math.random() * param1.length << 0;
            _loc3_ = param1[_loc4_];
            if(param2)
            {
               param1.splice(_loc4_,1);
            }
            if(_loc3_ is MapVO && GameData.I.config.isStandardLimit && _loc3_.inRandom == "0")
            {
               _loc3_ = null;
            }
         }
         return _loc3_;
      }
      
      public static function getRandomSomeInArray(param1:Array, param2:int, param3:Boolean = false) : Array
      {
         var _loc7_:int = 0;
         var _loc6_:int = 0;
         var _loc8_:* = undefined;
         var _loc4_:Array = param1.concat();
         var _loc5_:Array = [];
         while(_loc7_ < param2)
         {
            _loc6_ = Math.random() * _loc4_.length << 0;
            _loc8_ = _loc4_[_loc6_];
            _loc5_.push(_loc8_);
            if(!param3)
            {
               _loc4_.splice(_loc6_,1);
            }
            _loc7_++;
         }
         return _loc5_;
      }
      
      public static function getRandomOne(... rest) : *
      {
         return getRandomInArray(rest);
      }
      
      public static function between(param1:Number, param2:Number) : Number
      {
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         if(param1 < param2)
         {
            _loc4_ = param1;
            _loc5_ = param2;
         }
         else
         {
            _loc4_ = param2;
            _loc5_ = param1;
         }
         var _loc3_:Number = _loc4_ + Math.random() * (_loc5_ - _loc4_);
         if(_loc3_ < _loc4_)
         {
            _loc3_ = _loc4_;
         }
         if(_loc3_ > _loc5_)
         {
            _loc3_ = _loc5_;
         }
         return _loc3_;
      }
      
      public static function getRandomByRate(param1:Array, param2:String) : *
      {
         var _loc6_:int = 0;
         var _loc7_:Number = NaN;
         var _loc4_:Number = 0;
         param1.sortOn(param2,16);
         _loc6_ = 0;
         while(_loc6_ < param1.length)
         {
            _loc4_ += Number(param1[_loc6_][param2]);
            _loc6_++;
         }
         var _loc3_:Number = Math.random() * _loc4_;
         if(_loc3_ > _loc4_ - 1)
         {
            _loc3_ = _loc4_ - 1;
         }
         var _loc5_:Number = 0;
         _loc6_ = 0;
         while(_loc6_ < param1.length)
         {
            _loc7_ = _loc5_ + Number(param1[_loc6_][param2]);
            if(_loc3_ >= _loc5_ && _loc3_ < _loc7_)
            {
               return param1[_loc6_];
            }
            _loc5_ = _loc7_;
            _loc6_++;
         }
         throw Error("无法按机率选择，请检查数据");
      }
      
      public static function getRandomByRateLite(param1:Array, param2:String, param3:Number = 1) : *
      {
         var _loc7_:int = 0;
         var _loc8_:* = undefined;
         var _loc9_:Number = NaN;
         param1.sortOn(param2,16);
         var _loc5_:Number = Math.random() * param3;
         var _loc6_:Number = 0;
         var _loc4_:Array = [];
         _loc7_ = 0;
         while(_loc7_ < param1.length)
         {
            _loc8_ = param1[_loc7_];
            _loc9_ = Number(_loc8_[param2]);
            if(_loc6_ == 0)
            {
               if(_loc5_ <= _loc9_)
               {
                  _loc6_ = _loc9_;
                  _loc4_.push(_loc8_);
               }
            }
            else if(_loc9_ == _loc6_)
            {
               _loc4_.push(_loc8_);
            }
            _loc7_++;
         }
         return getRandomInArray(_loc4_);
      }
      
      public static function getRandomInts(param1:int, param2:int) : Array
      {
         var _loc4_:int = 0;
         var _loc3_:Array = [];
         _loc4_ = param1;
         while(_loc4_ < param2)
         {
            _loc3_.push(_loc4_);
            _loc4_++;
         }
         arraySortRandom(_loc3_);
         return _loc3_;
      }
      
      public static function arraySortRandom(param1:Array) : void
      {
         var array:Array = param1;
         var taxis:* = function(param1:*, param2:*):int
         {
            var _loc3_:Number = Math.random();
            if(_loc3_ < 0.5)
            {
               return -1;
            }
            return 1;
         };
         array.sort(taxis);
      }
      
      public static function getRandomColor(param1:uint = 0, param2:uint = 16777215) : uint
      {
         return param1 + (param2 - param1) * Math.random();
      }
   }
}

