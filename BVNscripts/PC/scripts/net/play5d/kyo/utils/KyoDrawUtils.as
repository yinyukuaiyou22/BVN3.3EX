package net.play5d.kyo.utils
{
   import flash.display.BitmapData;
   import flash.display.Graphics;
   import flash.display.Shape;
   
   public class KyoDrawUtils
   {
      
      private static var _drawShape:Shape;
      
      public function KyoDrawUtils()
      {
         super();
      }
      
      public static function drawRing(param1:Number, param2:Number, param3:int, param4:Object = 16776960, param5:Number = 1) : BitmapData
      {
         var _loc6_:BitmapData = new BitmapData(param2 * 2,param2 * 2,true,0);
         if(!_drawShape)
         {
            _drawShape = new Shape();
         }
         drawSector(_drawShape.graphics,param2,param2,param2,param3,-90,param4,param5);
         _loc6_.draw(_drawShape);
         _drawShape.graphics.clear();
         _drawShape.graphics.beginFill(16711680,1);
         _drawShape.graphics.drawCircle(param2,param2,param2 - param1);
         _drawShape.graphics.endFill();
         _loc6_.draw(_drawShape,null,null,"erase");
         _drawShape.graphics.clear();
         return _loc6_;
      }
      
      public static function drawSector(param1:Graphics, param2:Number = 200, param3:Number = 200, param4:Number = 100, param5:Number = 60, param6:Number = 0, param7:Object = 16777215, param8:Number = 1) : void
      {
         var _loc18_:Array = null;
         var _loc10_:int = 0;
         var _loc9_:int = 0;
         var _loc14_:Number = NaN;
         var _loc17_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc15_:Number = NaN;
         var _loc16_:Number = NaN;
         param1.clear();
         if(param7 is Array)
         {
            _loc18_ = [];
            while(_loc10_ < param7.length)
            {
               _loc18_.push(param8);
               _loc10_++;
            }
            param1.beginGradientFill("linear",param7 as Array,_loc18_,[128,255]);
         }
         else
         {
            param1.beginFill(param7 as uint,param8);
         }
         param5 = Math.abs(param5) > 360 ? 360 : param5;
         var _loc12_:int = Math.ceil(Math.abs(param5) / 45);
         var _loc11_:Number = param5 / _loc12_;
         _loc11_ = _loc11_ * 3.141592653589793 / 180;
         param6 = param6 * 3.141592653589793 / 180;
         param1.moveTo(param2 + param4 * Math.cos(param6),param3 + param4 * Math.sin(param6));
         _loc9_ = 1;
         while(_loc9_ <= _loc12_)
         {
            param6 += _loc11_;
            _loc16_ = param6 - _loc11_ / 2;
            _loc14_ = param2 + param4 / Math.cos(_loc11_ / 2) * Math.cos(_loc16_);
            _loc17_ = param3 + param4 / Math.cos(_loc11_ / 2) * Math.sin(_loc16_);
            _loc13_ = param2 + param4 * Math.cos(param6);
            _loc15_ = param3 + param4 * Math.sin(param6);
            param1.curveTo(_loc14_,_loc17_,_loc13_,_loc15_);
            _loc9_++;
         }
         if(param5 != 360)
         {
            param1.lineTo(param2,param3);
         }
         param1.endFill();
      }
   }
}

