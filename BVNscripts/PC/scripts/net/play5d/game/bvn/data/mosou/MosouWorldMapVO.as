package net.play5d.game.bvn.data.mosou
{
   public class MosouWorldMapVO
   {
      
      public var id:String;
      
      public var name:String;
      
      public var areas:Vector.<MosouWorldMapAreaVO>;
      
      private var _areaMap:Object;
      
      public function MosouWorldMapVO()
      {
         super();
      }
      
      public function initWay(param1:Array) : void
      {
         var _loc5_:* = null;
         var _loc4_:* = null;
         var _loc2_:int = 0;
         areas = new Vector.<MosouWorldMapAreaVO>();
         _areaMap = {};
         _loc2_ = 0;
         while(_loc2_ < param1.length)
         {
            _loc5_ = param1[_loc2_];
            _loc4_ = new MosouWorldMapAreaVO();
            _loc4_.id = _loc5_.P;
            areas.push(_loc4_);
            _areaMap[_loc4_.id] = _loc4_;
            _loc2_++;
         }
         _loc2_ = 0;
         while(_loc2_ < param1.length)
         {
            _loc5_ = param1[_loc2_];
            _loc4_ = _areaMap[_loc5_.P];
            if(!(!_loc4_ || !_loc5_.N))
            {
               _loc4_.preOpens = new Vector.<MosouWorldMapAreaVO>();
               if(_loc5_.N is Array)
               {
                  for each(var _loc3_ in _loc5_.N)
                  {
                     if(_areaMap[_loc3_])
                     {
                        _loc4_.preOpens.push(_areaMap[_loc3_]);
                     }
                  }
               }
               else if(_areaMap[_loc5_.N])
               {
                  _loc4_.preOpens.push(_areaMap[_loc5_.N]);
               }
            }
            _loc2_++;
         }
      }
      
      public function getArea(param1:String) : MosouWorldMapAreaVO
      {
         return _areaMap[param1];
      }
   }
}

