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
         if(Boolean(this.fighter1))
         {
            _loc1_.push(this.fighter1);
         }
         if(Boolean(this.fighter2))
         {
            _loc1_.push(this.fighter2);
         }
         if(Boolean(this.fighter3))
         {
            _loc1_.push(this.fighter3);
         }
         return _loc1_;
      }
      
      public function isSelected(param1:String) : Boolean
      {
         return this.fighter1 == param1 || this.fighter2 == param1 || this.fighter3 == param1;
      }
      
      public function toString() : String
      {
         return JSON.stringify({"select":{
            "fighter1":this.fighter1,
            "fighter2":this.fighter2,
            "fighter3":this.fighter3,
            "fuzhu":this.fuzhu
         }});
      }
   }
}

