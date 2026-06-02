package net.play5d.game.bvn.debug
{
   import com.oaxoa.components.FrameRater;
   import flash.display.DisplayObject;
   import flash.display.NativeWindow;
   import flash.display.Sprite;
   import flash.display.Stage;
   import kglad.Stats;
   
   public class Debugger
   {
      
      public static var onErrorMsgCall:Function;
      
      public static const DRAW_AREA:Boolean = false;
      
      public static const SAFE_MODE:Boolean = false;
      
      public static const DEBUG_ENABLED:Boolean = false;
      
      public static const HIDE_MAP:Boolean = false;
      
      public static const HIDE_HITEFFECT:Boolean = false;
      
      private static var _stage:Stage;
      
      private static var _main:Sprite;
      
      private static var _stats:Stats;
      
      private static var _fr:FrameRater;
      
      private static var _window:NativeWindow;
      
      public function Debugger()
      {
         super();
      }
      
      public static function log(... rest) : void
      {
         trace.call(null,rest);
      }
      
      public static function errorMsg(param1:String) : void
      {
      }
      
      public static function initDebug(param1:Stage, param2:Sprite) : void
      {
         _stage = param1;
         _main = param2;
         showFPS();
      }
      
      public static function addChild(param1:DisplayObject) : void
      {
         _stage.addChild(param1);
      }
      
      public static function removeChild(param1:DisplayObject) : void
      {
         try
         {
            _stage.removeChild(param1);
         }
         catch(e:Error)
         {
         }
      }
      
      public static function showFPS() : void
      {
         _fr = new FrameRater(16777215,true);
         addChild(_fr);
      }
      
      public static function setFPSVisible(param1:Boolean) : void
      {
         _fr.visible = param1;
      }
   }
}

