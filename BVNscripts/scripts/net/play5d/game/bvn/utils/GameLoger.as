package net.play5d.game.bvn.utils
{
   import net.play5d.game.bvn.interfaces.ILoger;
import net.play5d.game.bvn.Debugger;
   
   public class GameLoger
   {
      
      private static var _logger:ILoger;
      
      public function GameLoger()
      {
         super();
      }
      
      public static function setLoger(logger:ILoger) : void
      {
         _logger = logger;
      }
      
      public static function log(msg:String) : void
      {
         if(Boolean(_logger))
         {
            _logger.log(msg);
         }
         else
         {
            Debugger.log(msg);
         }
      }
   }
}

