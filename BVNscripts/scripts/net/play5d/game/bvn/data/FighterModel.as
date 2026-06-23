package net.play5d.game.bvn.data
{
   public class FighterModel
   {
      
      private static var _i:FighterModel;
      
      private var _fighterObj:Object;
      
      public function FighterModel()
      {
         super();
      }
      
      public static function get I() : FighterModel
      {
         if(!_i)
         {
            _i = new FighterModel();
         }
         return _i;
      }
      
      public function getAllFighters() : Object
      {
         return this._fighterObj;
      }
      
      public function getFighters(param1:int = -1, param2:Function = null) : Vector.<FighterVO>
      {
         var _loc4_:* = undefined;
         var _loc3_:Vector.<FighterVO> = new Vector.<FighterVO>();
         for each(_loc4_ in this._fighterObj)
         {
            if(param2 == null || Boolean(param2(_loc4_)))
            {
               if(param1 == -1 || _loc4_.comicType == param1)
               {
                  _loc3_.push(_loc4_);
               }
            }
         }
         return _loc3_;
      }
      
      public function getFighter(param1:String, param2:Boolean = false) : FighterVO
      {
         return this._fighterObj[param1];
      }
      
      public function initByXML(param1:XML) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:FighterVO = null;
         this._fighterObj = {};
         for each(_loc3_ in param1.fighter)
         {
            _loc2_ = new FighterVO();
            _loc2_.initByXML(_loc3_);
            this._fighterObj[_loc2_.id] = _loc2_;
         }
      }

      /** Ensure backing store is initialized (safe to call before any operations) */
      public function ensureInit() : void
      {
         if(!this._fighterObj) { this._fighterObj = {}; }
      }

      /** Merge/update fighters from external XML (overwrites entries previously registered by SWF scan) */
      public function mergeByXML(param1:XML) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:FighterVO = null;
         if(!this._fighterObj)
         {
            this._fighterObj = {};
         }
         for each(_loc3_ in param1.fighter)
         {
            _loc2_ = new FighterVO();
            _loc2_.initByXML(_loc3_);
            this._fighterObj[_loc2_.id] = _loc2_;
         }
      }
   }
}

