package nagisa.interfaces
{
   public class Instance implements IInstance
   {
      
      protected var _destoryed:Boolean = false;
      
      public function Instance()
      {
         super();
      }
      
      public function get isActive() : Boolean
      {
         return false;
      }
      
      public function isDestoryed() : Boolean
      {
         return _destoryed;
      }
      
      public function destory(param1:Boolean = true) : void
      {
         _destoryed = true;
      }
      
      public function render() : void
      {
      }
      
      public function renderAnimate() : void
      {
      }
   }
}

