package net.play5d.game.bvn.win.sockets
{
   import flash.utils.ByteArray;
   
   public class PacketBuffer
   {
      
      private var buf:ByteArray = new ByteArray();
      
      public function PacketBuffer()
      {
         super();
      }
      
      public function push(param1:ByteArray) : void
      {
         if(buf == null)
         {
            buf = param1;
         }
         else
         {
            buf.position = buf.length;
            buf.writeBytes(param1);
         }
      }
      
      public function getPackets() : Array
      {
         var _loc4_:* = 0;
         var _loc2_:ByteArray = null;
         var _loc1_:ByteArray = null;
         var _loc3_:Array = [];
         buf.position = 0;
         while(buf.bytesAvailable >= 2)
         {
            _loc4_ = uint(buf.readShort());
            if(buf.bytesAvailable < _loc4_)
            {
               _loc2_ = new ByteArray();
               _loc2_.writeBytes(buf,0,buf.bytesAvailable);
               buf = _loc2_;
               return _loc3_;
            }
            _loc1_ = new ByteArray();
            buf.readBytes(_loc1_,0,_loc4_);
            _loc1_.position = 0;
            _loc3_.push(_loc1_);
         }
         if(buf.bytesAvailable <= 0)
         {
            buf = null;
         }
         return _loc3_;
      }
      
      public function clear() : void
      {
         buf = null;
      }
   }
}

