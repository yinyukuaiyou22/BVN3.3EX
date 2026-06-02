package net.play5d.game.bvn.win.utils
{
   import flash.filesystem.File;
   import flash.filesystem.FileStream;
   import net.play5d.game.bvn.interfaces.ILoger;
   
   public class Loger implements ILoger
   {
      
      public static const ENABLED:Boolean = false;
      
      private static var _file:File;
      
      private static var _fileStream:FileStream;
      
      public function Loger()
      {
         super();
      }
      
      public function log(param1:String) : void
      {
      }
   }
}

