package net.play5d.game.bvn.views.filter
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.filters.BevelFilter;
   import flash.filters.BitmapFilter;
   import flash.filters.BlurFilter;
   import flash.filters.ColorMatrixFilter;
   import flash.filters.DisplacementMapFilter;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.filters.GradientBevelFilter;
   import flash.filters.GradientGlowFilter;
   import flash.utils.getQualifiedClassName;

   /**
    * 滤镜签名与动画帧号。
    *
    * 签名唯一的用途是「判断 filters 数组变没变」——因为 AS3 没有属性监听，
    * 只能轮询后比对。用 uint 哈希而不是 Object/Array 快照，避免每帧分配。
    *
    * 注意：烘焙本身不依赖签名（draw() 自己会算滤镜），签名只决定要不要重烘。
    */
   public class FilterSignature
   {
      private static const BASIS:uint = 2166136261;
      private static const ALT:uint = 2654435769;

      public static function compute(param1:Array) : uint
      {
         return hash(param1,BASIS);
      }

      public static function computeAlt(param1:Array) : uint
      {
         return hash(param1,ALT);
      }

      private static function hash(param1:Array, param2:uint) : uint
      {
         if(param1 == null || param1.length == 0)
         {
            return 0;
         }
         var h:uint = param2 ^ uint(param1.length * 2654435761);
         var i:int = 0;
         var n:int = param1.length;
         while(i < n)
         {
            var f:BitmapFilter = param1[i] as BitmapFilter;
            if(f == null)
            {
               h = mixU(h,0xFFFF);
            }
            else if(f is GlowFilter)
            {
               var gf:GlowFilter = f as GlowFilter;
               h = mixU(h,0x01);
               h = mixU(h,gf.color);
               h = mixN(h,gf.alpha);
               h = mixN(h,gf.blurX);
               h = mixN(h,gf.blurY);
               h = mixN(h,gf.strength);
               h = mixN(h,gf.quality);
               h = mixU(h,(gf.inner ? 1 : 0) | (gf.knockout ? 2 : 0));
            }
            else if(f is BlurFilter)
            {
               var bf:BlurFilter = f as BlurFilter;
               h = mixU(h,0x02);
               h = mixN(h,bf.blurX);
               h = mixN(h,bf.blurY);
               h = mixN(h,bf.quality);
            }
            else if(f is ColorMatrixFilter)
            {
               var cm:ColorMatrixFilter = f as ColorMatrixFilter;
               h = mixU(h,0x03);
               var j:int = 0;
               var m:Array = cm.matrix;
               while(j < 20)
               {
                  h = mixN(h,m[j]);
                  j++;
               }
            }
            else if(f is DropShadowFilter)
            {
               var ds:DropShadowFilter = f as DropShadowFilter;
               h = mixU(h,0x04);
               h = mixU(h,ds.color);
               h = mixN(h,ds.alpha);
               h = mixN(h,ds.blurX);
               h = mixN(h,ds.blurY);
               h = mixN(h,ds.distance);
               h = mixN(h,ds.angle);
               h = mixN(h,ds.strength);
               h = mixN(h,ds.quality);
               h = mixU(h,(ds.inner ? 1 : 0) | (ds.knockout ? 2 : 0) | (ds.hideObject ? 4 : 0));
            }
            else if(f is BevelFilter)
            {
               var bv:BevelFilter = f as BevelFilter;
               h = mixU(h,0x05);
               h = mixU(h,bv.highlightColor);
               h = mixU(h,bv.shadowColor);
               h = mixN(h,bv.angle);
               h = mixN(h,bv.distance);
               h = mixN(h,bv.blurX);
               h = mixN(h,bv.blurY);
               h = mixN(h,bv.strength);
               h = mixN(h,bv.quality);
               h = mixU(h,(bv.knockout ? 1 : 0) | (bv.type == "inner" ? 2 : (bv.type == "full" ? 6 : 4)));
            }
            else if(f is GradientGlowFilter)
            {
               var gg:GradientGlowFilter = f as GradientGlowFilter;
               h = mixU(h,0x06);
               h = mixN(h,gg.blurX);
               h = mixN(h,gg.blurY);
               h = mixN(h,gg.distance);
               h = mixN(h,gg.angle);
               h = mixN(h,gg.strength);
               h = mixN(h,gg.quality);
               h = mixU(h,(gg.knockout ? 1 : 0) | (gg.type == "inner" ? 2 : (gg.type == "full" ? 6 : 4)));
               h = mixArr(h,gg.colors);
               h = mixArr(h,gg.alphas);
               h = mixArr(h,gg.ratios);
            }
            else if(f is GradientBevelFilter)
            {
               var gb:GradientBevelFilter = f as GradientBevelFilter;
               h = mixU(h,0x07);
               h = mixN(h,gb.blurX);
               h = mixN(h,gb.blurY);
               h = mixN(h,gb.distance);
               h = mixN(h,gb.angle);
               h = mixN(h,gb.strength);
               h = mixN(h,gb.quality);
               h = mixU(h,(gb.knockout ? 1 : 0) | (gb.type == "inner" ? 2 : (gb.type == "full" ? 6 : 4)));
               h = mixArr(h,gb.colors);
               h = mixArr(h,gb.alphas);
               h = mixArr(h,gb.ratios);
            }
            else if(f is DisplacementMapFilter)
            {
               var dm:DisplacementMapFilter = f as DisplacementMapFilter;
               h = mixU(h,0x08);
               h = mixU(h,dm.componentX | (dm.componentY << 4) | (dm.mode == "wrap" ? 64 : (dm.mode == "clamp" ? 128 : 0)));
               h = mixN(h,dm.scaleX);
               h = mixN(h,dm.scaleY);
               h = mixN(h,dm.alpha);
               h = mixU(h,dm.color);
               if(dm.mapBitmap)
               {
                  h = mixU(h,dm.mapBitmap.width * 65536 + dm.mapBitmap.height);
               }
            }
            else
            {
               h = mixS(h,getQualifiedClassName(f));
            }
            i++;
         }
         return h;
      }

      /**
       * 动画帧号：自身是 MovieClip 用 currentFrame；否则取最近 MC 祖先，
       * 再把前两个 MC 子节点的帧号混进来（纯 Sprite 节点的内容通常由子 MC 驱动）。
       */
      public static function frameKey(param1:DisplayObject) : int
      {
         if(param1 == null)
         {
            return 0;
         }
         var mc:MovieClip = param1 as MovieClip;
         if(mc)
         {
            return mc.currentFrame;
         }
         var p:DisplayObject = param1.parent;
         var up:int = 0;
         while(p && !(p is MovieClip) && up < 6)
         {
            p = p.parent;
            up++;
         }
         var k:int = p ? (p as MovieClip).currentFrame : 0;
         var c:DisplayObjectContainer = param1 as DisplayObjectContainer;
         if(c)
         {
            var added:int = 0;
            var i:int = 0;
            var n:int = c.numChildren;
            while(i < n && added < 2)
            {
               var ch:DisplayObject = c.getChildAt(i);
               var cm2:MovieClip = ch as MovieClip;
               if(cm2)
               {
                  k = k * 31 + cm2.currentFrame;
                  added++;
               }
               i++;
            }
         }
         return k;
      }

      /**
       * 把 filters 数组压成一行可读摘要，只用于诊断日志（低频，不进热路径）。
       * 例：ColorMatrixFilter[0.33,0.33,0.33,0,0,...]
       */
      public static function describe(param1:Array) : String
      {
         if(param1 == null || param1.length == 0)
         {
            return "none";
         }
         var out:String = "";
         var i:int = 0;
         while(i < param1.length)
         {
            var f:BitmapFilter = param1[i] as BitmapFilter;
            if(f == null)
            {
               out += (out ? " | " : "") + "null";
            }
            else if(f is ColorMatrixFilter)
            {
               var m:Array = (f as ColorMatrixFilter).matrix;
               var j:int = 0;
               var s:String = "";
               while(j < m.length && j < 8)
               {
                  s += (j ? "," : "") + Number(m[j]).toFixed(3);
                  j++;
               }
               out += (out ? " | " : "") + "ColorMatrix[" + s + "...]";
            }
            else if(f is GlowFilter)
            {
               var g:GlowFilter = f as GlowFilter;
               out += (out ? " | " : "") + "Glow[0x" + g.color.toString(16)
                  + " a=" + g.alpha + " b=" + g.blurX + "/" + g.blurY
                  + " s=" + g.strength + " q=" + g.quality
                  + " in=" + g.inner + " ko=" + g.knockout + "]";
            }
            else if(f is BlurFilter)
            {
               var b:BlurFilter = f as BlurFilter;
               out += (out ? " | " : "") + "Blur[" + b.blurX + "/" + b.blurY
                  + " q=" + b.quality + "]";
            }
            else if(f is DropShadowFilter)
            {
               var d:DropShadowFilter = f as DropShadowFilter;
               out += (out ? " | " : "") + "DropShadow[0x" + d.color.toString(16)
                  + " a=" + d.alpha + " b=" + d.blurX + " dist=" + d.distance
                  + " hide=" + d.hideObject + " q=" + d.quality + "]";
            }
            else
            {
               out += (out ? " | " : "") + getQualifiedClassName(f).split("::").pop();
            }
            i++;
         }
         return out;
      }

      private static function mixU(param1:uint, param2:uint) : uint
      {
         var h:uint = param1;
         h = (h ^ (param2 & 0xFF)) * 16777619;
         h = (h ^ ((param2 >>> 8) & 0xFF)) * 16777619;
         h = (h ^ ((param2 >>> 16) & 0xFF)) * 16777619;
         h = (h ^ ((param2 >>> 24) & 0xFF)) * 16777619;
         return h;
      }

      private static function mixN(param1:uint, param2:Number) : uint
      {
         var v:int = int(Math.round(param2 * 1000));
         return mixU(param1,uint(v));
      }

      private static function mixS(param1:uint, param2:String) : uint
      {
         if(param2 == null)
         {
            return mixU(param1,0);
         }
         var h:uint = param1;
         var i:int = 0;
         var n:int = param2.length;
         if(n > 64)
         {
            n = 64;
         }
         while(i < n)
         {
            h = (h ^ param2.charCodeAt(i)) * 16777619;
            i++;
         }
         return h;
      }

      private static function mixArr(param1:uint, param2:Array) : uint
      {
         if(param2 == null)
         {
            return mixU(param1,0);
         }
         var h:uint = mixU(param1,uint(param2.length));
         var i:int = 0;
         var n:int = param2.length > 16 ? 16 : param2.length;
         while(i < n)
         {
            h = mixN(h,Number(param2[i]));
            i++;
         }
         return h;
      }
   }
}
