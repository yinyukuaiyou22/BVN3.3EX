package net.play5d.game.bvn.mob.data
{
   import flash.utils.ByteArray;
   
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
            "ownerName":ownerName,
            "gameMode":gameMode,
            "hp":hp,
            "gameTime":gameTime
         };
         return JSON.stringify(_loc2_);
      }
      
      public function readJson(param1:String) : void
      {
         var _loc2_:Object = JSON.parse(param1);
         ownerName = _loc2_.ownerName;
         gameMode = _loc2_.gameMode;
         hp = _loc2_.hp;
         gameTime = _loc2_.gameTime;
      }
      
      public function toByteArray() : ByteArray
      {
         var _loc1_:ByteArray = new ByteArray();
         _loc1_.writeByte(gameMode);
         _loc1_.writeByte(gameTime);
         _loc1_.writeByte(hp);
         return _loc1_;
      }
      
      public function readByteArray(param1:ByteArray) : void
      {
         gameMode = param1.readByte();
         gameTime = param1.readByte();
         hp = param1.readByte();
      }
      
      public function getGameModeStr() : String
      {
         switch(gameMode - 1)
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

