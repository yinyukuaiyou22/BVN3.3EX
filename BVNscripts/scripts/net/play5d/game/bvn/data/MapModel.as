package net.play5d.game.bvn.data
{
   public class MapModel
   {
      
      private static var _i:MapModel;
      
      private var _mapObj:Object;
      
      private var _mapArray:Array;
      
      public function MapModel()
      {
         super();
      }
      
      public static function get I() : MapModel
      {
         if(!_i)
         {
            _i = new MapModel();
         }
         return _i;
      }
      
      public function getMap(param1:String) : MapVO
      {
         return this._mapObj[param1];
      }
      
      public function getAllMaps() : Array
      {
         return this._mapArray;
      }
      
      public function initByXML(param1:XML) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:MapVO = null;
         this._mapObj = {};
         this._mapArray = [];
         for each(_loc3_ in param1.map)
         {
            _loc2_ = new MapVO();
            _loc2_.initByXML(_loc3_);
            this._mapObj[_loc2_.id] = _loc2_;
            this._mapArray.push(_loc2_);
         }
      }
   }
}

