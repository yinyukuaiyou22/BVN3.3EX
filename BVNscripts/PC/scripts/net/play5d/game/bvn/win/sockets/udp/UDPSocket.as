package net.play5d.game.bvn.win.sockets.udp
{
   import flash.events.DatagramSocketDataEvent;
   import flash.net.DatagramSocket;
   import flash.net.InterfaceAddress;
   import flash.net.NetworkInfo;
   import flash.net.NetworkInterface;
   import flash.utils.ByteArray;
   
   public class UDPSocket
   {
      
      private var _udpsocket:DatagramSocket;
      
      private var _dataBacks:Vector.<Function>;
      
      private var _onLineClients:Array;
      
      private var _broadCastAddress:String;
      
      public function UDPSocket()
      {
         super();
         _udpsocket = new DatagramSocket();
      }
      
      public function listen(param1:int) : void
      {
         _udpsocket.bind(param1);
         _udpsocket.receive();
      }
      
      public function unListen() : void
      {
         _udpsocket.close();
      }
      
      public function addDataHandler(param1:Function) : void
      {
         if(!_dataBacks)
         {
            _dataBacks = new Vector.<Function>();
         }
         if(_dataBacks.indexOf(param1) == -1)
         {
            _dataBacks.push(param1);
         }
         if(_udpsocket.hasEventListener("data"))
         {
            return;
         }
         _udpsocket.addEventListener("data",dataHandler);
      }
      
      public function removeDataHandler(param1:Function) : void
      {
         var _loc2_:int = _dataBacks.indexOf(param1);
         if(_loc2_ != -1)
         {
            _dataBacks.splice(_loc2_,1);
         }
      }
      
      private function dataHandler(param1:DatagramSocketDataEvent) : void
      {
         var _loc5_:UDPDataVO = null;
         var _loc2_:int = 0;
         var _loc3_:ByteArray = null;
         _loc5_ = new UDPDataVO();
         _loc5_.fromIP = param1.srcAddress;
         _loc5_.fromPort = param1.srcPort;
         var _loc6_:ByteArray;
         switch((_loc2_ = (_loc6_ = param1.data).readByte()) - 1)
         {
            case 0:
               _loc5_.dataType = 2;
               _loc5_.setData(_loc6_.readUTFBytes(_loc6_.bytesAvailable));
               break;
            case 1:
               _loc5_.dataType = 1;
               _loc3_ = new ByteArray();
               _loc3_.writeBytes(_loc6_,1,_loc6_.bytesAvailable);
               _loc3_.position = 0;
               _loc5_.setData(_loc3_);
               break;
            case 2:
               _loc5_.dataType = 3;
               _loc5_.setData(_loc6_.readObject());
         }
         for each(var _loc4_ in _dataBacks)
         {
            if(_loc4_ != null)
            {
               _loc4_(_loc5_);
            }
         }
      }
      
      public function send(param1:String, param2:int, param3:Object) : void
      {
         log("UDPCtrler.send",param1,param2,param3);
         var _loc4_:ByteArray = new ByteArray();
         if(param3 is String)
         {
            _loc4_.writeByte(1);
            _loc4_.writeUTFBytes(param3 as String);
         }
         else if(param3 is ByteArray)
         {
            _loc4_.writeByte(2);
            _loc4_.writeBytes(param3 as ByteArray,0,(param3 as ByteArray).bytesAvailable);
         }
         else
         {
            _loc4_.writeByte(3);
            _loc4_.writeObject(param3);
         }
         _udpsocket.send(_loc4_,0,0,param1,param2);
      }
      
      public function sendBroadcast(param1:int, param2:Object) : void
      {
         var _loc5_:* = undefined;
         if(!_broadCastAddress)
         {
            _loc5_ = NetworkInfo.networkInfo.findInterfaces();
            for each(var _loc3_ in _loc5_)
            {
               if(_loc3_.active)
               {
                  for each(var _loc4_ in _loc3_.addresses)
                  {
                     if(_loc4_.broadcast && _loc4_.broadcast != "")
                     {
                        _broadCastAddress = _loc4_.broadcast;
                     }
                  }
               }
            }
         }
         if(_broadCastAddress)
         {
            send(_broadCastAddress,param1,param2);
         }
      }
      
      private function log(... rest) : void
      {
      }
   }
}

