package nagisa.data
{
   import flash.display.BitmapData;
   
   public class DrawMovieClipCacheVO
   {
      
      public var scriptCache:Object;
      
      public var bitmapDataCache:Vector.<BitmapDataCacheVO>;
      
      public var frameLabelCache:Object;
      
      public function DrawMovieClipCacheVO()
      {
         super();
      }
      
      public function get bitmapDatas() : Vector.<BitmapData>
      {
         if(!bitmapDataCache || !bitmapDataCache.length)
         {
            return null;
         }
         var _loc1_:Vector.<BitmapData> = new Vector.<BitmapData>();
         for each(var _loc2_ in bitmapDataCache)
         {
            _loc1_.push(_loc2_.bitmapData);
         }
         return _loc1_;
      }
      
      public function destory() : void
      {
         scriptCache = null;
         bitmapDataCache = null;
         frameLabelCache = null;
      }
      
      public function clone() : DrawMovieClipCacheVO
      {
         var _loc1_:DrawMovieClipCacheVO = new DrawMovieClipCacheVO();
         _loc1_.bitmapDataCache = bitmapDataCache;
         _loc1_.frameLabelCache = frameLabelCache;
         _loc1_.scriptCache = scriptCache;
         return _loc1_;
      }
   }
}

