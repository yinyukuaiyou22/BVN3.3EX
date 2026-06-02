package net.play5d.game.bvn.mob.events
{
   import flash.events.Event;
   
   public class LanEvent extends Event
   {
      
      public static const CLIENT_JOIN_SUCCESS:String = "CLIENT_JOIN_SUCCESS";
      
      public function LanEvent(param1:String, param2:Boolean = false, param3:Boolean = false)
      {
         super(param1,param2,param3);
      }
   }
}

