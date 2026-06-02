package nagisa.interfaces
{
   public interface INEventDispatcher
   {
      
      function listen(param1:String, param2:Function) : void;
      
      function unlisten(param1:String, param2:Function) : void;
      
      function removeAllListener(param1:String = null) : void;
      
      function hasListener(param1:String, param2:Function = null) : Boolean;
      
      function dispatch(param1:*, param2:Object = null) : Boolean;
   }
}

