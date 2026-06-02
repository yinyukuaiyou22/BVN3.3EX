package net.play5d.game.bvn.mob.sockets.udp
{
   import flash.utils.ByteArray;
   
   public class UDPDataVO
   {
      
      private var _data:Object;
      
      public var dataType:int;
      
      public var fromIP:String;
      
      public var fromPort:int;
      
      private var _jsonData:Object;
      
      public function UDPDataVO()
      {
         super();
      }
      
      public function getDataByteArray() : ByteArray
      {
         if(dataType == 1)
         {
            (_data as ByteArray).position = 0;
            return _data as ByteArray;
         }
         return null;
      }
      
      public function getDataString() : String
      {
         return dataType == 2 ? _data as String : null;
      }
      
      public function getDataObject() : Object
      {
         return dataType == 3 ? _data : null;
      }
      
      public function setData(param1:Object) : void
      {
         _data = param1;
      }
   }
}

