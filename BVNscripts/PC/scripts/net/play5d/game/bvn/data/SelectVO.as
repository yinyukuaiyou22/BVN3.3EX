package net.play5d.game.bvn.data
{
   public class SelectVO
   {
      
      public var fighter1:String;
      
      public var fighter2:String;
      
      public var fighter3:String;
      
      public var fuzhu:String;
      
      public function SelectVO()
      {
         super();
      }
      
      public function getSelectFighters() : Array
      {
         var _loc1_:Array = [];
         if(fighter1 != null)
         {
            _loc1_.push(fighter1);
         }
         if(fighter2 != null)
         {
            _loc1_.push(fighter2);
         }
         if(fighter3 != null)
         {
            _loc1_.push(fighter3);
         }
         return _loc1_;
      }
      
      public function isSelected(param1:String) : Boolean
      {
         var _loc2_:Array = getSelectFighters();
         return _loc2_.indexOf(param1) != -1;
      }
      
      public function toString() : String
      {
         return "SelectVO{fighter1=" + fighter1 + ",fighter2=" + fighter2 + ",fighter3=" + fighter3 + ",fuzhu=" + fuzhu + "}";
      }
   }
}

