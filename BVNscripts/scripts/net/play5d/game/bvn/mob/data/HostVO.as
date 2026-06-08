package net.play5d.game.bvn.mob.data
{
   import flash.utils.*;
   
   public class HostVO
   {
      
      public var ip:String;
      
      public var ownerName:String;
      
      public var gameMode:int = 1;
      
      public var hp:int = 1;
      
      public var gameTime:int = 60;
      
      public function HostVO()
      {
         super();
      }
      
      public function toJson() : String
      {
         var _loc2_:Object = {
            "ownerName":this.ownerName,
            "gameMode":this.gameMode,
            "hp":this.hp,
            "gameTime":this.gameTime
         };
         return JSON.stringify(_loc2_);
      }
      
      public function readJson(param1:String) : void
      {
         var _loc2_:Object = JSON.parse(param1);
         this.ownerName = _loc2_.ownerName;
         this.gameMode = _loc2_.gameMode;
         this.hp = _loc2_.hp;
         this.gameTime = _loc2_.gameTime;
      }
      
      public function toByteArray() : ByteArray
      {
         var _loc1_:ByteArray = new ByteArray();
         _loc1_.writeByte(this.gameMode);
         _loc1_.writeByte(this.gameTime);
         _loc1_.writeByte(this.hp);
         return _loc1_;
      }
      
      public function readByteArray(param1:ByteArray) : void
      {
         this.gameMode = param1.readByte();
         this.gameTime = param1.readByte();
         this.hp = param1.readByte();
      }
      
      public function getGameModeStr() : String
      {
         switch(this.gameMode - 1)
         {
            case 0:
               return "TEAM VS - 小队对战";
            case 1:
               return "SINGLE VS - 单人对战";
            default:
               return null;
         }
      }
   }
}

