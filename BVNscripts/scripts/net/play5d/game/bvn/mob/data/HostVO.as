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

      /** 拼招开关（2026-11-27）：由房主下发，保证两端同值；旧端缺该字节时按默认 true。 */
      public var clashEnabled:Boolean = true;
      
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
            "gameTime":this.gameTime,
            "clashEnabled":this.clashEnabled
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
         if(_loc2_.clashEnabled != null)
         {
            this.clashEnabled = _loc2_.clashEnabled == true;
         }
      }
      
      public function toByteArray() : ByteArray
      {
         var _loc1_:ByteArray = new ByteArray();
         _loc1_.writeByte(this.gameMode);
         _loc1_.writeByte(this.gameTime);
         _loc1_.writeByte(this.hp);
         _loc1_.writeByte(this.clashEnabled ? 1 : 0);
         return _loc1_;
      }
      
      public function readByteArray(param1:ByteArray) : void
      {
         this.gameMode = param1.readByte();
         this.gameTime = param1.readByte();
         this.hp = param1.readByte();
         // 旧客户端只发 3 字节：缺字节时保持默认 true，不读越界。
         if(param1.bytesAvailable > 0)
         {
            this.clashEnabled = param1.readByte() != 0;
         }
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

