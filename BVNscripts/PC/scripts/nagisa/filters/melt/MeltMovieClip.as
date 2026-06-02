package nagisa.filters.melt
{
   import flash.display.BitmapData;
   import nagisa.data.BitmapDataCacheVO;
   import nagisa.debug.OutputMessage;
   import nagisa.display.ctrler.NMovieClipCtrler;
   import nagisa.util.ClassUtil;
   
   public class MeltMovieClip extends NMovieClipCtrler
   {
      
      private var _caches:Vector.<BitmapDataCacheVO>;
      
      public function MeltMovieClip()
      {
         super();
      }
      
      public function get curCache() : BitmapDataCacheVO
      {
         return _caches[_currentFrame - 1];
      }
      
      public function get bitmapData() : BitmapData
      {
         if(!curCache)
         {
            return null;
         }
         return curCache.bitmapData;
      }
      
      public function get offsetX() : Number
      {
         if(!curCache)
         {
            return 0;
         }
         return curCache.offsetX;
      }
      
      public function get offsetY() : Number
      {
         if(!curCache)
         {
            return 0;
         }
         return curCache.offsetY;
      }
      
      override public function initialize(param1:* = null, param2:Object = null, param3:int = 0) : void
      {
         if(ClassUtil.checkTargetType(param1,Vector.<BitmapDataCacheVO>) == -1)
         {
            OutputMessage.ERROR("MeltMovieClip","initialize","无法读取传入的数据！",null,true);
         }
         super.initialize(param1,param2,param3);
         _caches = param1;
      }
      
      public function start() : void
      {
         _goFrame(1,true);
      }
   }
}

