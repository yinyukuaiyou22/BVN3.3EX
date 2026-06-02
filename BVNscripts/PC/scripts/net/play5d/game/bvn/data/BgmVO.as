package net.play5d.game.bvn.data
{
   public class BgmVO
   {
      
      public var id:String;
      
      public var rate:Number;
      
      public var url:String;
      
      private var _cloneKey:Array = ["id","rate","url"];
      
      public function BgmVO()
      {
         super();
      }
      
      public function toString() : String
      {
         return "BgmVO{id=" + id + ",rate=" + String(rate) + ",url=" + url + "}";
      }
      
      public function clone() : BgmVO
      {
         var _loc1_:BgmVO = new BgmVO();
         for each(var _loc2_ in _cloneKey)
         {
            _loc1_[_loc2_] = this[_loc2_];
         }
         return _loc1_;
      }
   }
}

