package nagisa.interfaces
{
   public interface IInstance
   {
      
      function destory(param1:Boolean = true) : void;
      
      function isDestoryed() : Boolean;
      
      function render() : void;
      
      function renderAnimate() : void;
      
      function get isActive() : Boolean;
   }
}

