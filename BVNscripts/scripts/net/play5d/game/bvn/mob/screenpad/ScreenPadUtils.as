package net.play5d.game.bvn.mob.screenpad
{
   import flash.display.Bitmap;
   import flash.geom.*;
   import flash.system.*;
   import net.play5d.game.bvn.mob.*;
   
   public class ScreenPadUtils
   {
      
      public static var scale:Number = 1;
      
      public function ScreenPadUtils()
      {
         super();
      }
      
      public static function getArrow(param1:Class) : ScreenPadArrow
      {
         var _loc2_:ScreenPadArrow = new ScreenPadArrow();
         var _loc3_:Bitmap = new param1();
         _loc3_.scaleX = _loc3_.scaleY = scale;
         _loc2_.display = _loc3_;
         _loc2_.display.alpha = GameInterfaceManager.config.screenPadConfig.joyAlpha;
         _loc2_.init();
         return _loc2_;
      }
      
      public static function getButton(param1:Class, param2:Point = null) : ScreenPadBtn
      {
         var _loc3_:ScreenPadBtn = new ScreenPadBtn();
         var _loc4_:Bitmap = new param1();
         _loc4_.scaleX = _loc4_.scaleY = scale;
         _loc3_.display = _loc4_;
         _loc3_.display.alpha = GameInterfaceManager.config.screenPadConfig.joyAlpha;
         _loc3_.init(param2);
         return _loc3_;
      }
      
      public static function getPointByCM(param1:Number = 0, param2:Number = 0) : Point
      {
         var _loc3_:Number = Number(Capabilities.screenDPI);
         var _loc4_:Point = new Point();
         _loc4_.x = param1 * _loc3_ / 2.54;
         _loc4_.y = param2 * _loc3_ / 2.54;
         return _loc4_;
      }
      
      public static function cm2pixel(param1:Number) : Number
      {
         var _loc2_:Number = Number(Capabilities.screenDPI);
         return param1 * _loc2_ / 2.54;
      }
   }
}

