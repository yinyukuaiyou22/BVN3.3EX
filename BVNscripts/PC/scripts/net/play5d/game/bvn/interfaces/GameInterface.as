package net.play5d.game.bvn.interfaces
{
   import flash.utils.ByteArray;
   
   public class GameInterface
   {
      
      public static var instance:IGameInterface;
      
      public function GameInterface()
      {
         super();
      }
      
      public static function getDefaultMenu() : Array
      {
         return null;
      }
      
      public static function checkFile(param1:String, param2:ByteArray) : Boolean
      {
         if(instance)
         {
            return instance.checkFile(param1,param2);
         }
         return true;
      }
      
      public static function addMoney(param1:Function) : void
      {
         var back:Function = param1;
         var addMoneyBack:* = function(param1:*):void
         {
            var _loc2_:int = param1;
            if(_loc2_ < 1)
            {
               return;
            }
            if(_loc2_ > 5000)
            {
               return;
            }
            back(_loc2_);
         };
         if(instance)
         {
            instance.addMosouMoney(addMoneyBack);
            return;
         }
         addMoneyBack(100 + Math.random() * 500);
      }
   }
}

