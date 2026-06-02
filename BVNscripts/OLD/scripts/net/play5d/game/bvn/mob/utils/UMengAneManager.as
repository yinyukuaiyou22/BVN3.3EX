package net.play5d.game.bvn.mob.utils
{
   public class UMengAneManager
   {
      
      private static var _i:UMengAneManager;
      
      public function UMengAneManager()
      {
         super();
      }
      
      public static function get I() : UMengAneManager
      {
         if(!_i)
         {
            _i = new UMengAneManager();
         }
         return _i;
      }
      
      public function initlize() : void
      {
      }
      
      public function onDeactive() : void
      {
      }
      
      public function onActive() : void
      {
      }
   }
}

