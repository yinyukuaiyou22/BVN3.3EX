package net.play5d.game.bvn.win.views
{
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.stage.SettingStage;
   import net.play5d.game.bvn.win.GameInterfaceManager;
   import net.play5d.game.bvn.win.input.JoyStickConfigVO;
   import net.play5d.kyo.stage.Istage;
   
   public class ViewManager
   {
      
      private static var _i:ViewManager;
      
      public function ViewManager()
      {
         super();
      }
      
      public static function get I() : ViewManager
      {
         if(!_i)
         {
            _i = new ViewManager();
         }
         return _i;
      }
      
      public function goP1JoyStickSet() : void
      {
         goJoyStickSet(1,GameInterfaceManager.config.joy1Config);
      }
      
      public function goP2JoyStickSet() : void
      {
         goJoyStickSet(2,GameInterfaceManager.config.joy2Config);
      }
      
      private function goJoyStickSet(param1:int, param2:JoyStickConfigVO) : void
      {
         var _loc3_:JoyStickSetUI = null;
         var _loc5_:Istage = MainGame.stageCtrl.currentStage;
         if(!_loc5_ is SettingStage)
         {
            return;
         }
         var _loc4_:SettingStage = _loc5_ as SettingStage;
         _loc3_ = new JoyStickSetUI();
         _loc3_.setConfig(param1,param2);
         _loc4_.goInnerSetPage(_loc3_);
      }
   }
}

