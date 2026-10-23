package net.play5d.game.bvn.views.filter
{
   import flash.display.BitmapData;

   /**
    * BitmapData 复用池。
    *
    * 分档理由：动画帧之间 getBounds 抖动 ±1~2px 极常见，精确匹配会导致每帧
    * new/dispose（真机上就是灾难）。按 32px 分档后同一节点能稳定命中同一个桶。
    * 拿到的图可能比请求的大，调用方必须按实际 bitmapData.rect 清理。
    */
   public class BitmapDataPool
   {
      private var _free:Object = {};
      private var _live:Vector.<BitmapData> = new Vector.<BitmapData>();
      private var _maxLive:int;
      private var _bucket:int;
      private var _bytes:int = 0;

      public function BitmapDataPool(param1:int = 24, param2:int = 32)
      {
         super();
         this._maxLive = param1 < 4 ? 4 : param1;
         this._bucket = param2 < 8 ? 8 : param2;
      }

      public function acquire(param1:int, param2:int) : BitmapData
      {
         var w:int = this.roundUp(param1);
         var h:int = this.roundUp(param2);
         var key:String = w + "x" + h;
         var list:Vector.<BitmapData> = this._free[key] as Vector.<BitmapData>;
         if(list && list.length > 0)
         {
            return list.pop();
         }
         var bd:BitmapData = new BitmapData(w,h,true,0);
         this._live.push(bd);
         this._bytes += w * h * 4;
         return bd;
      }

      public function release(param1:BitmapData) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(this._live.indexOf(param1) < 0)
         {
            return;
         }
         var key:String = param1.width + "x" + param1.height;
         var list:Vector.<BitmapData> = this._free[key] as Vector.<BitmapData>;
         if(list == null)
         {
            list = new Vector.<BitmapData>();
            this._free[key] = list;
         }
         if(list.length >= 2)
         {
            this.kill(param1);
            return;
         }
         if(list.indexOf(param1) < 0)
         {
            list.push(param1);
         }
      }

      public function trim() : void
      {
         var key:String = null;
         var list:Vector.<BitmapData> = null;
         var i:int = 0;
         for(key in this._free)
         {
            list = this._free[key] as Vector.<BitmapData>;
            while(list.length > 1)
            {
               this.kill(list.pop());
            }
         }
         if(this._live.length > this._maxLive)
         {
            var drop:int = this._live.length - this._maxLive;
            i = 0;
            while(i < drop)
            {
               var bd:BitmapData = this._live[0];
               this._live.shift();
               if(this._unfree(bd))
               {
                  this.kill(bd);
                  i++;
               }
               else
               {
                  this._live.push(bd);
                  break;
               }
            }
         }
      }

      public function dispose() : void
      {
         var i:int = 0;
         while(i < this._live.length)
         {
            var bd:BitmapData = this._live[i];
            try
            {
               if(bd)
               {
                  bd.dispose();
               }
            }
            catch(e:Error)
            {
            }
            i++;
         }
         this._live.length = 0;
         this._free = {};
         this._bytes = 0;
      }

      public function get liveCount() : int
      {
         return this._live.length;
      }

      public function get totalBytes() : Number
      {
         return this._bytes;
      }

      private function roundUp(param1:int) : int
      {
         var v:int = param1 < 1 ? 1 : param1;
         return int(Math.ceil(v / this._bucket)) * this._bucket;
      }

      private function _unfree(param1:BitmapData) : Boolean
      {
         var key:String = null;
         var list:Vector.<BitmapData> = null;
         for(key in this._free)
         {
            list = this._free[key] as Vector.<BitmapData>;
            var idx:int = list.indexOf(param1);
            if(idx >= 0)
            {
               list.splice(idx,1);
               return true;
            }
         }
         return false;
      }

      private function kill(param1:BitmapData) : void
      {
         if(param1 == null)
         {
            return;
         }
         var idx:int = this._live.indexOf(param1);
         if(idx >= 0)
         {
            this._live.splice(idx,1);
            this._bytes -= param1.width * param1.height * 4;
         }
         try
         {
            param1.dispose();
         }
         catch(e2:Error)
         {
         }
      }
   }
}
