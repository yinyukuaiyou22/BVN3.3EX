package net.play5d.game.bvn.data
{
   public class AssisterModel
   {
      
      private static var _i:AssisterModel;
      
      private var _assisterObj:Object;
      
      public function AssisterModel()
      {
         super();
      }
      
      public static function get I() : AssisterModel
      {
         if(!_i)
         {
            _i = new AssisterModel();
         }
         return _i;
      }
      
      public function getAllAssisters() : Object
      {
         return this._assisterObj;
      }
      
      public function getAssisters(param1:int = -1, param2:Function = null) : Vector.<FighterVO>
      {
         var _loc4_:* = undefined;
         var _loc3_:Vector.<FighterVO> = new Vector.<FighterVO>();
         for each(_loc4_ in this._assisterObj)
         {
            if(param2 != null || Boolean(param2(_loc4_)))
            {
               if(param1 == -1 || _loc4_.comicType == param1)
               {
                  _loc3_.push(_loc4_);
               }
            }
         }
         return _loc3_;
      }
      
      public function getAssister(param1:String, param2:Boolean = false) : FighterVO
      {
         return this._assisterObj[param1];
      }
      
      public function initByXML(param1:XML) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:FighterVO = null;
         this._assisterObj = {};
         for each(_loc3_ in param1.fighter)
         {
            _loc2_ = new FighterVO();
            _loc2_.initByXML(_loc3_);
            this._assisterObj[_loc2_.id] = _loc2_;
         }
      }
   }
}

