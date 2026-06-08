package net.play5d.game.bvn.mob.sockets
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.net.*;
   import flash.utils.*;
   import net.play5d.game.bvn.mob.sockets.events.*;
   
   public class SocketClient extends EventDispatcher
   {
      
      private var _clientSocket:Socket;
      
      public var isConnected:Boolean;
      
      private var _packetBuffer:PacketBuffer;
      
      public function SocketClient()
      {
         super();
         this._clientSocket = new Socket();
         this._clientSocket.objectEncoding = 3;
         this._clientSocket.addEventListener("connect",this.onConnect);
         this._clientSocket.addEventListener("close",this.onClose);
         this._clientSocket.addEventListener("ioError",this.onError);
         this._clientSocket.addEventListener("socketData",this.onSocketData);
         this._packetBuffer = new PacketBuffer();
      }
      
      public function getSocketServer() : String
      {
         return this._clientSocket.remoteAddress + ":" + this._clientSocket.remotePort;
      }
      
      public function connect(param1:String, param2:int) : void
      {
         this.log("开始连接服务器 :: " + param1 + ":" + param2);
         this._clientSocket.connect(param1,param2);
      }
      
      public function close() : void
      {
         this.log("关闭链接");
         try
         {
            this._clientSocket.close();
         }
         catch(e:Error)
         {
            trace(e);
         }
      }
      
      private function onConnect(param1:Event) : void
      {
         this.log("成功连接服务器!");
         this.log("Connection from " + this._clientSocket.remoteAddress + ":" + this._clientSocket.remotePort);
         this.isConnected = true;
         dispatchEvent(new SocketEvent("SocketEvent_CLIENT_CONNECT"));
      }
      
      private function onClose(param1:Event) : void
      {
         this.log("服务器断开!");
         this.isConnected = false;
         dispatchEvent(new SocketEvent("SocketEvent_CLOSE"));
      }
      
      private function onSocketData(param1:ProgressEvent) : void
      {
         var _loc5_:* = undefined;
         var _loc2_:SocketEvent = null;
         var _loc3_:ByteArray = new ByteArray();
         this._clientSocket.readBytes(_loc3_,0,this._clientSocket.bytesAvailable);
         PacketUtils.uncompress(_loc3_);
         this._packetBuffer.push(_loc3_);
         var _loc4_:Array = this._packetBuffer.getPackets();
         for each(_loc5_ in _loc4_)
         {
            _loc2_ = new SocketEvent("SocketEvent_RECEIVE_DATA");
            _loc2_.data = _loc5_;
            dispatchEvent(_loc2_);
            this.log("Received from Server ::" + _loc5_);
         }
      }
      
      public function send(param1:Object) : void
      {
         var _loc2_:ByteArray = null;
         try
         {
            if(this._clientSocket != null && Boolean(this._clientSocket.connected))
            {
               if(param1 is ByteArray)
               {
                  _loc2_ = PacketUtils.addByteArrayHead(param1 as ByteArray);
               }
               else
               {
                  _loc2_ = PacketUtils.createByteArrayWithHead(param1);
               }
               if(!_loc2_)
               {
                  return;
               }
               PacketUtils.compress(_loc2_);
               this._clientSocket.writeBytes(_loc2_,0,_loc2_.bytesAvailable);
               this._clientSocket.flush();
               this.log("Sent message (" + param1 + " | length:" + _loc2_.length + ") to " + this._clientSocket.remoteAddress + ":" + this._clientSocket.remotePort);
            }
            else
            {
               this.log("No socket connection.");
            }
         }
         catch(error:Error)
         {
            log(error.message);
         }
      }
      
      public function sendJSON(param1:Object) : void
      {
         var _loc2_:String = JSON.stringify(param1);
         this.send(_loc2_);
      }
      
      private function onError(param1:IOErrorEvent) : void
      {
         this.log(param1.toString());
         this.isConnected = false;
         var _loc2_:SocketEvent = new SocketEvent("SocketEvent_ERROR");
         _loc2_.error = param1.toString();
         dispatchEvent(_loc2_);
      }
      
      private function log(param1:String) : void
      {
      }
   }
}

