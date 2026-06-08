package net.play5d.game.bvn.mob.sockets.udp
{
   public class UDPSocket
   {
      
      public static const BUFFER_LENGTH:int = 50;
      
      public static const RECEIVE_TIME_OUT:int = 10;
      
      private var _dataBacks:Vector.<Function>;
      
      public function UDPSocket()
      {
         super();
      }
      
      public function listen(param1:int) : void
      {
      }
      
      public function unListen() : void
      {
      }
      
      public function addDataHandler(param1:Function) : void
      {
         if(!this._dataBacks)
         {
            this._dataBacks = new Vector.<Function>();
         }
         if(this._dataBacks.indexOf(param1) == -1)
         {
            this._dataBacks.push(param1);
         }
      }
      
      public function removeDataHandler(param1:Function) : void
      {
         var _loc2_:int = int(this._dataBacks.indexOf(param1));
         if(_loc2_ != -1)
         {
            this._dataBacks.splice(_loc2_,1);
         }
      }
      
      public function send(param1:String, param2:int, param3:Object) : void
      {
      }
      
      public function sendBroadcast(param1:int, param2:Object) : void
      {
      }
   }
}

