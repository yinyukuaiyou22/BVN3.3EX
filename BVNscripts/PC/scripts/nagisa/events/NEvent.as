package nagisa.events
{
   import flash.events.Event;
   
   public class NEvent extends Event
   {
      
      public static const RENDER:String = "render";
      
      public static const RENDER_ANIMATE:String = "renderAnimate";
      
      public static const DESTORY:String = "destory";
      
      public static const DISPOSE:String = "dispose";
      
      public var params:Object;
      
      public function NEvent(param1:String, param2:Object = null, param3:Boolean = false, param4:Boolean = false)
      {
         this.params = param2;
         super(param1,param3,param4);
      }
   }
}

