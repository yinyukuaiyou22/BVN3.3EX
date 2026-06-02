package net.play5d.game.bvn.utils
{
   import net.play5d.game.bvn.interfaces.ILoger;
   
   public class GameLoger
   {
      
      private static var _logger:ILoger;
      
      public function GameLoger()
      {
         super();
      }
      
      public static function setLoger(param1:ILoger) : void
      {
         _logger = param1;
      }
      
      public static function log(param1:String) : void
      {
         if(_logger)
         {
            _logger.log(param1);
         }
      }
   }
}

