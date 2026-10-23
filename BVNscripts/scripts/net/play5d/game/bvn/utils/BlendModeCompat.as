package net.play5d.game.bvn.utils
{
   import flash.display.BlendMode;
   import net.play5d.game.bvn.Debugger;

   /**
    * GPU 渲染模式下的混合模式白名单。
    *
    * Adobe《移动设备 GPU 呈现》明确：GPU 模式**不支持** layer / alpha / erase /
    * overlay / hardlight / lighten / darken。工程现状有三处踩在这些值上，且在真机上
    * 完全静默失效（不是变暗，是压根不生效）：
    *   - EffectModel.as:52   hit_floor_yan 用 lighten
    *   - EffectModel.as:186  一处用 hardlight
    *   - ShineEffectView.as  暗色闪光用 darken
    *
    * 这里只做「赋值处映射」，不改 EffectModel 的数据 —— 将来若切回 cpu 渲染，
    * 数据层仍是原始语义，映射恒等。
    */
   public class BlendModeCompat
   {
      private static var _warned:Object = {};

      public static function map(param1:String) : String
      {
         if(param1 == null || param1 == "" || param1 == BlendMode.NORMAL)
         {
            return BlendMode.NORMAL;
         }
         if(param1 == BlendMode.ADD || param1 == BlendMode.MULTIPLY
            || param1 == BlendMode.SCREEN || param1 == BlendMode.SUBTRACT
            || param1 == BlendMode.INVERT || param1 == BlendMode.DIFFERENCE)
         {
            return param1;
         }
         if(param1 == BlendMode.LIGHTEN || param1 == BlendMode.HARDLIGHT
            || param1 == BlendMode.OVERLAY)
         {
            warnOnce(param1,BlendMode.ADD);
            return BlendMode.ADD;
         }
         if(param1 == BlendMode.DARKEN)
         {
            warnOnce(param1,BlendMode.MULTIPLY);
            return BlendMode.MULTIPLY;
         }
         warnOnce(param1,BlendMode.NORMAL);
         return BlendMode.NORMAL;
      }

      public static function isGpuSafe(param1:String) : Boolean
      {
         return param1 == null || param1 == "" || param1 == BlendMode.NORMAL
            || param1 == BlendMode.ADD || param1 == BlendMode.MULTIPLY
            || param1 == BlendMode.SCREEN || param1 == BlendMode.SUBTRACT
            || param1 == BlendMode.INVERT || param1 == BlendMode.DIFFERENCE;
      }

      private static function warnOnce(param1:String, param2:String) : void
      {
         if(_warned[param1])
         {
            return;
         }
         _warned[param1] = true;
         Debugger.warn("[BLEND] GPU 不支持 blendMode=" + param1 + "，已映射为 " + param2);
      }
   }
}
