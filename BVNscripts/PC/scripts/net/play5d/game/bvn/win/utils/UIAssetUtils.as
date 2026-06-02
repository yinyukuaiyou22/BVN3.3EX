package net.play5d.game.bvn.win.utils
{
   import flash.display.Stage;
   
   public class UIAssetUtils
   {
      
      private static var _i:UIAssetUtils;
      
      private var _stage:Stage;
      
      private var _initBack:Function;
      
      private var _inited:Boolean;
      
      private var _initing:Boolean;
      
      public function UIAssetUtils()
      {
         super();
      }
      
      public static function get I() : UIAssetUtils
      {
         if(!_i)
         {
            _i = new UIAssetUtils();
         }
         return _i;
      }
      
      public function initalize(param1:Stage, param2:Function = null) : void
      {
         if(_initing)
         {
            throw new Error("正在初始化过程中，不能再次初始化！");
         }
         if(_inited)
         {
            if(param2 != null)
            {
               param2();
            }
            return;
         }
         _stage = param1;
         _inited = true;
         _initing = true;
         _initBack = param2;
         MenuUtils.I.initPluginMenu();
         MenuUtils.I.initAIMenu();
         finish();
      }
      
      private function finish() : void
      {
         _initing = false;
         if(_initBack != null)
         {
            _initBack();
            _initBack = null;
         }
      }
   }
}

