package net.play5d.game.bvn.views.filter
{
   import flash.filters.BevelFilter;
   import flash.filters.BitmapFilter;
   import flash.filters.BlurFilter;
   import flash.filters.ColorMatrixFilter;
   import flash.filters.ConvolutionFilter;
   import flash.filters.DisplacementMapFilter;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.filters.GradientBevelFilter;
   import flash.filters.GradientGlowFilter;

   /**
    * 滤镜外扩量计算。
    *
    * 实测（真机 AIR 51，见 tools/Test/_report/2026-10-23_GPU滤镜探针结论.md）：
    * GlowFilter(blur 24, quality 1, strength 2) 的实际可见外扩只有 10~15px，
    * 远小于常见的 "1.5 × blur" 估算；而且四边不对称（右/下比左/上厚约 5px）。
    * 所以这里按 0.8 × blur + 6 的保守值取对称 pad，宁可多几像素也不啃边。
    */
   public class FilterPad
   {
      /** 未知/无法估算的滤镜类型给的保守值 */
      public static const UNKNOWN:int = 12;

      public static function of(param1:BitmapFilter, param2:int = 3) : int
      {
         if(param1 == null)
         {
            return 0;
         }
         var q:int = param2 < 1 ? 1 : (param2 > 3 ? 3 : param2);
         var k:Number = 0.6 + 0.2 * q;
         if(param1 is BlurFilter)
         {
            var bf:BlurFilter = param1 as BlurFilter;
            return Math.ceil(Math.max(bf.blurX,bf.blurY) * k) + 6;
         }
         if(param1 is GlowFilter)
         {
            var gf:GlowFilter = param1 as GlowFilter;
            return Math.ceil(Math.max(gf.blurX,gf.blurY) * k) + 6;
         }
         if(param1 is DropShadowFilter)
         {
            var ds:DropShadowFilter = param1 as DropShadowFilter;
            return Math.ceil(Math.max(ds.blurX,ds.blurY) * k + Math.abs(ds.distance)) + 6;
         }
         if(param1 is BevelFilter)
         {
            var bv:BevelFilter = param1 as BevelFilter;
            return Math.ceil(Math.max(bv.blurX,bv.blurY) * k + Math.abs(bv.distance)) + 6;
         }
         if(param1 is GradientGlowFilter)
         {
            var gg:GradientGlowFilter = param1 as GradientGlowFilter;
            return Math.ceil(Math.max(gg.blurX,gg.blurY) * k + Math.abs(gg.distance)) + 6;
         }
         if(param1 is GradientBevelFilter)
         {
            var gb:GradientBevelFilter = param1 as GradientBevelFilter;
            return Math.ceil(Math.max(gb.blurX,gb.blurY) * k + Math.abs(gb.distance)) + 6;
         }
         if(param1 is ColorMatrixFilter)
         {
            return 0;
         }
         if(param1 is ConvolutionFilter)
         {
            var cf:ConvolutionFilter = param1 as ConvolutionFilter;
            return Math.ceil((cf.matrixX - 1) * 0.5 + (cf.matrixY - 1) * 0.5) + 2;
         }
         if(param1 is DisplacementMapFilter)
         {
            var dm:DisplacementMapFilter = param1 as DisplacementMapFilter;
            return Math.ceil(Math.max(Math.abs(dm.scaleX),Math.abs(dm.scaleY))) + 2;
         }
         return UNKNOWN;
      }

      /** 多滤镜串联的外扩量是**求和**（每级各吃自己的外扩），不是取最大。 */
      public static function sumOf(param1:Array, param2:int = 3, param3:int = 64) : int
      {
         if(param1 == null || param1.length == 0)
         {
            return 0;
         }
         var total:int = 0;
         var i:int = 0;
         while(i < param1.length)
         {
            total += of(param1[i] as BitmapFilter,param2);
            i++;
         }
         if(total > param3)
         {
            total = param3;
         }
         return total;
      }
   }
}
