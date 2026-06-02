package net.play5d.game.bvn.data.mosou
{
   import net.play5d.game.bvn.ctrl.AssetManager;
   
   public class MosouModel
   {
      
      private static var _i:MosouModel;
      
      private var _mapObj:Object = {};
      
      public var currentArea:MosouWorldMapAreaVO;
      
      public var currentMission:MosouMissionVO;
      
      public function MosouModel()
      {
         super();
      }
      
      public static function get I() : MosouModel
      {
         if(!_i)
         {
            _i = new MosouModel();
         }
         return _i;
      }
      
      public function getAllMap() : Object
      {
         return _mapObj;
      }
      
      public function getMap(param1:String) : MosouWorldMapVO
      {
         return _mapObj[param1];
      }
      
      public function getMapArea(param1:String, param2:String) : MosouWorldMapAreaVO
      {
         var _loc3_:MosouWorldMapVO = _mapObj[param1];
         if(!_loc3_)
         {
            return null;
         }
         return _loc3_.getArea(param2);
      }
      
      public function loadMapData(param1:Function, param2:Function) : void
      {
         var back:Function = param1;
         var fail:Function = param2;
         var mapId:String = "map1";
         var url:String = "config/mosou/" + mapId + "/" + mapId + ".json";
         AssetManager.I.loadJSON(url,function(param1:Object):void
         {
            var _loc2_:MosouWorldMapVO = new MosouWorldMapVO();
            _loc2_.id = param1.id;
            _loc2_.name = param1.name;
            _loc2_.initWay(param1.way);
            _mapObj[_loc2_.id] = _loc2_;
            loadAreas(_loc2_,param1.parts,back,fail);
         },fail);
      }
      
      private function loadAreas(param1:MosouWorldMapVO, param2:Array, param3:Function, param4:Function) : void
      {
         var map:MosouWorldMapVO = param1;
         var parts:Array = param2;
         var back:Function = param3;
         var fail:Function = param4;
         var loadNext:* = function(param1:Object = null):void
         {
            var _loc4_:MosouWorldMapAreaVO = null;
            if(!param1)
            {
               fail != null && fail();
               return;
            }
            if(param1 && param1.id)
            {
               _loc4_ = map.getArea(param1.id);
               if(_loc4_)
               {
                  initMapArea(_loc4_,param1);
               }
            }
            if(mapIds.length < 1)
            {
               back != null && back();
               return;
            }
            var _loc2_:String = mapIds.shift();
            var _loc3_:String = "config/mosou/" + map.id + "/" + _loc2_ + ".json";
            AssetManager.I.loadJSON(_loc3_,loadNext,fail);
         };
         var mapIds:Array = parts.concat();
         loadNext({"remark":"first time!"});
      }
      
      private function initMapArea(param1:MosouWorldMapAreaVO, param2:Object) : void
      {
         var _loc4_:int = 0;
         var _loc5_:MosouMissionVO = null;
         param1.id = param2.id;
         param1.name = param2.name;
         param1.missions = new Vector.<MosouMissionVO>();
         var _loc3_:Array = param2.missions;
         _loc4_ = 0;
         while(_loc4_ < _loc3_.length)
         {
            _loc5_ = new MosouMissionVO();
            _loc5_.initByJsonObject(_loc3_[_loc4_]);
            param1.missions.push(_loc5_);
            _loc4_++;
         }
      }
   }
}

