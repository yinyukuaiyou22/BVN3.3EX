package net.play5d.game.bvn.mob.sockets.events
{
   import flash.events.Event;
   import flash.net.Socket;
   import flash.utils.ByteArray;
import net.play5d.game.bvn.Debugger;
   
   public class SocketEvent extends Event
   {
      
      public static const CLIENT_CONNECT:String = "SocketEvent_CLIENT_CONNECT";
      
      public static const CLIENT_DIS_CONNECT:String = "SocketEvent_CLIENT_DIS_CONNECT";
      
      public static const RECEIVE_DATA:String = "SocketEvent_RECEIVE_DATA";
      
      public static const CLOSE:String = "SocketEvent_CLOSE";
      
      public static const ERROR:String = "SocketEvent_ERROR";
      
      public var clientSocket:Socket;
      
      public var data:ByteArray;
      
      public var error:String;
      
      private var _quickGetData:Object;
      
      public function SocketEvent(param1:String, param2:Boolean = false, param3:Boolean = false)
      {
         super(param1,param2,param3);
      }
      
      public function getDataObject() : Object
      {
         var _loc1_:Object;
         this.data.position = 0;
         _loc1_ = null;
         try
         {
            _loc1_ = this.data.readObject();
         }
         catch(e:Error)
         {
            Debugger.log("SocketEvent.getDataObject :: ",e);
         }
         return _loc1_;
      }
   }
}

