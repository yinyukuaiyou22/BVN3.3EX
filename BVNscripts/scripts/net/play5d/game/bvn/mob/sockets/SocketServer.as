package net.play5d.game.bvn.mob.sockets
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.ProgressEvent;
   import flash.events.ServerSocketConnectEvent;
   import flash.net.*;
   import flash.utils.*;
   import net.play5d.game.bvn.mob.sockets.events.*;
   
   public class SocketServer extends EventDispatcher
   {
      
      private static var _i:SocketServer;
      
      public var connected:Boolean;
      
      private var _serverSocket:ServerSocket;
      
      private var _clients:Vector.<Socket>;
      
      private var _packetBuffer:PacketBuffer;
      
      public function SocketServer()
      {
         super();
      }
      
      public static function get I() : SocketServer
      {
         if(!_i)
         {
            _i = new SocketServer();
         }
         return _i;
      }
      
      public function get port() : int
      {
         return this._serverSocket.localPort;
      }
      
      public function bind(param1:int) : void
      {
         this.close();
         this._serverSocket = new ServerSocket();
         this._serverSocket.addEventListener("connect",this.onClientConnect);
         this._serverSocket.addEventListener("close",this.onClose);
         this._clients = new Vector.<Socket>();
         this._packetBuffer = new PacketBuffer();
         try
         {
            this._serverSocket.bind(param1);
            this._serverSocket.listen();
            this.log("SERVER SOCKET正在监听端口:" + this._serverSocket.localPort);
         }
         catch(e:Error)
         {
            log("监听失败，请尝试另一个端口");
         }
         this.connected = this._serverSocket.bound;
      }
      
      public function get clients() : Vector.<Socket>
      {
         return this._clients;
      }
      
      public function close() : void
      {
         var _loc1_:* = undefined;
         if(Boolean(this._clients))
         {
            for each(_loc1_ in this._clients)
            {
               if(Boolean(_loc1_.connected))
               {
                  _loc1_.close();
               }
            }
            this._clients = null;
         }
         if(Boolean(this._serverSocket))
         {
            this._serverSocket.close();
            this._serverSocket = null;
         }
         this.connected = false;
      }
      
      public function getClientByIP(param1:String) : Socket
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in this._clients)
         {
            if(_loc2_.remoteAddress == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      private function onClientConnect(param1:ServerSocketConnectEvent) : void
      {
         var _loc2_:Socket = param1.socket;
         _loc2_.addEventListener("socketData",this.onClientSocketData);
         this._clients.push(_loc2_);
         _loc2_.addEventListener("close",this.onCloseClient);
         this.log("Connection from " + _loc2_.localAddress + ":" + _loc2_.localPort);
         this.connected = true;
         var _loc3_:SocketEvent = new SocketEvent("SocketEvent_CLIENT_CONNECT");
         _loc3_.clientSocket = _loc2_;
         dispatchEvent(_loc3_);
      }
      
      private function onClose(param1:Event) : void
      {
         this._serverSocket.removeEventListener("connect",this.onClientConnect);
         this._serverSocket.removeEventListener("close",this.onClose);
         dispatchEvent(new SocketEvent("SocketEvent_CLOSE"));
         this.connected = false;
         this.log("Connection Closed ");
      }
      
      private function onCloseClient(param1:Event) : void
      {
         var _loc2_:int = 0;
         var _loc3_:Socket = null;
         var _loc4_:SocketEvent = null;
         var _loc5_:Socket = param1.target as Socket;
         _loc2_ = 0;
         while(_loc2_ < this._clients.length)
         {
            _loc3_ = this._clients[_loc2_];
            if(_loc3_.remoteAddress == _loc5_.remoteAddress && _loc3_.remotePort == _loc5_.remotePort)
            {
               this._clients.splice(_loc2_,1);
               this.log(param1.target.remoteAddress + ":" + param1.target.remotePort + "断开");
               _loc4_ = new SocketEvent("SocketEvent_CLIENT_DIS_CONNECT");
               _loc4_.clientSocket = _loc3_;
               dispatchEvent(_loc4_);
            }
            _loc2_++;
         }
      }
      
      private function onClientSocketData(param1:ProgressEvent) : void
      {
         var _loc6_:* = undefined;
         var _loc2_:SocketEvent = null;
         var _loc3_:ByteArray = new ByteArray();
         var _loc4_:Socket = param1.currentTarget as Socket;
         _loc4_.readBytes(_loc3_,0,_loc4_.bytesAvailable);
         PacketUtils.uncompress(_loc3_);
         this._packetBuffer.push(_loc3_);
         var _loc5_:Array = this._packetBuffer.getPackets();
         for each(_loc6_ in _loc5_)
         {
            _loc2_ = new SocketEvent("SocketEvent_RECEIVE_DATA");
            _loc2_.data = _loc6_;
            _loc2_.clientSocket = _loc4_;
            dispatchEvent(_loc2_);
            this.log("Received from Client" + _loc4_.remoteAddress + ":" + _loc4_.remotePort + "-- " + _loc6_);
         }
      }
      
      public function sendAll(param1:Object) : void
      {
         var _loc3_:int = 0;
         var _loc2_:Socket = null;
         try
         {
            if(this._clients.length == 0)
            {
               this.log("没有连接");
               return;
            }
            _loc3_ = 0;
            while(_loc3_ < this._clients.length)
            {
               _loc2_ = this._clients[_loc3_] as Socket;
               this.send(_loc2_,param1);
               _loc3_++;
            }
         }
         catch(error:Error)
         {
            log(error.message);
         }
      }
      
      public function send(param1:Socket, param2:Object) : void
      {
         var _loc3_:ByteArray = null;
         if(param1 == null)
         {
            return;
         }
         if(param2 is ByteArray)
         {
            _loc3_ = PacketUtils.addByteArrayHead(param2 as ByteArray);
         }
         else
         {
            _loc3_ = PacketUtils.createByteArrayWithHead(param2);
         }
         PacketUtils.compress(_loc3_);
         param1.objectEncoding = 3;
         param1.writeBytes(_loc3_,0,_loc3_.bytesAvailable);
         param1.flush();
      }
      
      public function sendJson(param1:*, param2:Object) : void
      {
         var _loc3_:String = JSON.stringify(param2);
         this.send(param1,_loc3_);
      }
      
      public function sendByIP(param1:String, param2:ByteArray) : void
      {
         var _loc3_:Socket = this.getClientByIP(param1);
         this.send(_loc3_,param2);
      }
      
      public function log(param1:String) : void
      {
      }
   }
}

