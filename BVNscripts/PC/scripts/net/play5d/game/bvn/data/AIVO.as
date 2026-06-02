package net.play5d.game.bvn.data
{
   public class AIVO
   {
      
      public var id:String;
      
      public var name:String;
      
      public var author:String;
      
      public var cls:Class;
      
      private var _cloneKey:Array = ["id","name","author","cls"];
      
      public function AIVO()
      {
         super();
      }
      
      public function toString() : String
      {
         return "AIVO{id=" + id + ",name=" + name + ",author=" + author + ",cls=" + String(cls) + "}";
      }
      
      public function clone() : AIVO
      {
         var _loc1_:AIVO = new AIVO();
         for each(var _loc2_ in _cloneKey)
         {
            _loc1_[_loc2_] = this[_loc2_];
         }
         return _loc1_;
      }
   }
}

