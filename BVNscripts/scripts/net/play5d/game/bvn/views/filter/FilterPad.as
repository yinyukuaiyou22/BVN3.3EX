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
    * 滤镜外扩量计算（单位：**逻辑像素**；烘焙时再乘倍率换算成位图像素）。
    *
    * 实测（真机 AIR 51，见 tools/Test/_report/2026-10-23_GPU滤镜探针结论.md）：
    * GlowFilter(blur 24, quality 1, strength 2) 的实际可见外扩只有 10~15px，
    * 远小于常见的 "1.5 × blur" 估算；而且四边不对称（右/下比左/上厚约 5px）。
    * 所以 k = 0.6 + 0.2×quality（默认 qCap=2 → 1.0×blur），再 +6 的保守余量；
    * 宁可多几像素也不啃边。多出来的透明边只是位图变大，不影响观感。
    */
   public class FilterPad
   {
      /** 未知/无法估算的滤镜类型给的保守值 */
      public static const UNKNOWN:int = 12;

      /**
       * @param param2 qCap（估算用的 quality 上限）
       * @param param3 glowQ  烘焙时**实际**会用的 quality 上限（0 = 与 param2 相同）。
       *        开了 FPROXY_GLOW_QUALITY_MAX 后 draw 用的是更低 quality，外扩更小，
       *        这里必须跟着降，否则白留一大圈透明边（实测那边占 61% 像素）。
       */
      public static function of(param1:BitmapFilter, param2:int = 3, param3:int = 0) : int
      {
         if(param1 == null)
         {
            return 0;
         }
         var q:int = param2 < 1 ? 1 : (param2 > 3 ? 3 : param2);
         if(param3 > 0 && param3 < q)
         {
            q = param3;
         }
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

      /** 多滤镜串联的外扩量是**求和**（每级各吃自己的外扩），不是取最大。
       *  param3 与 GameConfig.FPROXY_MAX_PAD 保持一致；调用点显式传值，这里只是兜底。
       *  param4 = 烘焙时实际用的 Glow/Blur quality（0 = 与 qCap 相同），透传给 of()。 */
      public static function sumOf(param1:Array, param2:int = 3, param3:int = 96,
                                   param4:int = 0) : int
      {
         if(param1 == null || param1.length == 0)
         {
            return 0;
         }
         var total:int = 0;
         var i:int = 0;
         while(i < param1.length)
         {
            total += of(param1[i] as BitmapFilter,param2,param4);
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
