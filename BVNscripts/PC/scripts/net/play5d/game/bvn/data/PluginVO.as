package net.play5d.game.bvn.data
{
   public class PluginVO
   {
      
      public var id:String;
      
      public var name:String;
      
      public var author:String;
      
      public var isRunBack:Boolean;
      
      public var cls:Class;
      
      private var _cloneKey:Array = ["id","name","author","isRunBack","cls"];
      
      public function PluginVO()
      {
         super();
      }
      
      public function toString() : String
      {
         return "PluginVO{id=" + id + ",name=" + name + ",author=" + author + ",isRunBack=" + String(isRunBack) + ",cls=" + String(cls) + "}";
      }
      
      public function clone() : PluginVO
      {
         var _loc2_:PluginVO = new PluginVO();
         for each(var _loc1_ in _cloneKey)
         {
            _loc2_[_loc1_] = this[_loc1_];
         }
         return _loc2_;
      }
   }
}

