package net.play5d.game.bvn.mob.sockets
{
   import flash.utils.*;
   
   public class PacketBuffer
   {
      
      private var buf:ByteArray = new ByteArray();
      
      public function PacketBuffer()
      {
         super();
      }
      
      public function push(param1:ByteArray) : void
      {
         if(this.buf == null)
         {
            this.buf = param1;
         }
         else
         {
            this.buf.position = this.buf.length;
            this.buf.writeBytes(param1);
         }
      }
      
      public function getPackets() : Array
      {
         var _loc1_:* = 0;
         var _loc2_:ByteArray = null;
         var _loc3_:ByteArray = null;
         var _loc4_:Array = [];
         this.buf.position = 0;
         while(this.buf.bytesAvailable >= 2)
         {
            _loc1_ = uint(this.buf.readShort());
            if(this.buf.bytesAvailable < _loc1_)
            {
               _loc2_ = new ByteArray();
               _loc2_.writeBytes(this.buf,0,this.buf.bytesAvailable);
               this.buf = _loc2_;
               return _loc4_;
            }
            _loc3_ = new ByteArray();
            this.buf.readBytes(_loc3_,0,_loc1_);
            _loc3_.position = 0;
            _loc4_.push(_loc3_);
         }
         if(this.buf.bytesAvailable <= 0)
         {
            this.buf = null;
         }
         return _loc4_;
      }
      
      public function clear() : void
      {
         this.buf = null;
      }
   }
}

