package net.play5d.game.bvn.data
{
   import net.play5d.kyo.utils.*;
   
   public class KeyConfigVO
   {
      
      public var id:int;
      
      public var up:uint;
      
      public var down:uint;
      
      public var left:uint;
      
      public var right:uint;
      
      public var attack:uint;
      
      public var jump:uint;
      
      public var dash:uint;
      
      public var skill:uint;
      
      public var superKill:uint;
      
      public var beckons:uint;
      
      public var selects:Array;
      
      public function KeyConfigVO(param1:int)
      {
         super();
         this.id = param1;
      }
      
      public function setKeys(param1:uint, param2:uint, param3:uint, param4:uint, param5:uint, param6:uint, param7:uint, param8:uint, param9:uint, param10:uint) : void
      {
         this.up = param1;
         this.down = param2;
         this.left = param3;
         this.right = param4;
         this.attack = param5;
         this.jump = param6;
         this.dash = param7;
         this.skill = param8;
         this.dash = param7;
         this.superKill = param9;
         this.beckons = param10;
         if(!this.selects)
         {
            this.selects = [param5];
         }
      }
      
      public function toSaveObj() : Object
      {
         var _loc1_:Object = KyoUtils.itemToObject(this);
         delete _loc1_["id"];
         return _loc1_;
      }
      
      public function readSaveObj(param1:Object) : void
      {
         KyoUtils.setValueByObject(this,param1);
      }
      
      public function clone() : KeyConfigVO
      {
         var _loc1_:Object = this.toSaveObj();
         var _loc2_:KeyConfigVO = new KeyConfigVO(this.id);
         _loc2_.readSaveObj(_loc1_);
         return _loc2_;
      }
   }
}

