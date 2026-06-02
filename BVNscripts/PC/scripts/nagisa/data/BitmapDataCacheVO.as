package nagisa.data
{
   import flash.display.BitmapData;
   import flash.geom.Point;
   
   public class BitmapDataCacheVO
   {
      
      public var bitmapData:BitmapData;
      
      public var offsetX:Number = 0;
      
      public var offsetY:Number = 0;
      
      public var quality:Number = 1;
      
      public function BitmapDataCacheVO()
      {
         super();
      }
      
      public static function isEqual(param1:BitmapDataCacheVO, param2:BitmapDataCacheVO, param3:Boolean = true) : Boolean
      {
         if(!param1 && !param2)
         {
            return true;
         }
         if(param1 && !param2 || !param1 && param2)
         {
            return false;
         }
         if(!param1.bitmapData && !param2.bitmapData)
         {
            return true;
         }
         if(param1.bitmapData && !param2.bitmapData || !param1.bitmapData && param2.bitmapData)
         {
            return false;
         }
         if(param3)
         {
            if(param1.offsetX != param2.offsetX)
            {
               return false;
            }
            if(param1.offsetY != param2.offsetY)
            {
               return false;
            }
         }
         return param1.bitmapData.compare(param2.bitmapData) == 0;
      }
      
      public function get offset() : Point
      {
         return new Point(offsetX,offsetY);
      }
      
      public function clone() : BitmapDataCacheVO
      {
         var _loc1_:BitmapDataCacheVO = new BitmapDataCacheVO();
         _loc1_.bitmapData = bitmapData;
         _loc1_.offsetX = offsetX;
         _loc1_.offsetY = offsetY;
         return _loc1_;
      }
   }
}

