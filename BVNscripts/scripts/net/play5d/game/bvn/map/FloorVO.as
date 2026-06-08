package net.play5d.game.bvn.map
{
   public class FloorVO
   {
      
      public var y:Number = 0;
      
      public var xFrom:Number = 0;
      
      public var xTo:Number = 0;
      
      public function FloorVO()
      {
         super();
      }
      
      public function toString() : String
      {
         return "FloorVO::{xFrom:" + this.xFrom + ",xTo:" + this.xTo + ",y:" + this.y + "}";
      }
      
      public function hitTest(param1:Number, param2:Number, param3:Number) : Boolean
      {
         return param2 > this.y - param3 && param2 < this.y + param3 && param1 > this.xFrom && param1 < this.xTo;
      }
   }
}

