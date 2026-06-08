package net.play5d.game.bvn.mob.sockets.udp
{
   import flash.utils.*;
   
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
         if(this.dataType == 1)
         {
            (this._data as ByteArray).position = 0;
            return this._data as ByteArray;
         }
         return null;
      }
      
      public function getDataString() : String
      {
         return this.dataType == 2 ? this._data as String : null;
      }
      
      public function getDataObject() : Object
      {
         return this.dataType == 3 ? this._data : null;
      }
      
      public function setData(param1:Object) : void
      {
         this._data = param1;
      }
   }
}

