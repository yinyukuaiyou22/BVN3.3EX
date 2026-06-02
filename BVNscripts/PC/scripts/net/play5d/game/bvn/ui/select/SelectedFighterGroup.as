package net.play5d.game.bvn.ui.select
{
   import com.greensock.TweenLite;
   import flash.display.Sprite;
   import net.play5d.game.bvn.data.FighterVO;
   
   public class SelectedFighterGroup extends Sprite
   {
      
      private var _uiClass:Class;
      
      private var _uis:Array = [];
      
      private var _curUI:SelectedFighterUI;
      
      public function SelectedFighterGroup(param1:Class)
      {
         super();
         _uiClass = param1;
      }
      
      public function destory() : void
      {
         if(_curUI)
         {
            _curUI.destory();
            _curUI = null;
         }
      }
      
      public function addFighter(param1:FighterVO) : void
      {
         var _loc5_:int = 0;
         var _loc4_:Number = 20 - (_uis.length - 1) * 3;
         var _loc6_:Number = _uis.length * -20;
         var _loc3_:Number = 0.7 - (_uis.length - 1) * 0.3;
         var _loc7_:Number = 0.85 - (_uis.length - 1) * 0.15;
         var _loc2_:SelectedFighterUI = null;
         _loc5_ = 0;
         while(_loc5_ < _uis.length)
         {
            _loc2_ = _uis[_loc5_];
            TweenLite.to(_loc2_.ui,0.1,{
               "y":_loc6_,
               "alpha":_loc3_,
               "scaleX":_loc7_,
               "scaleY":_loc7_
            });
            _loc6_ += _loc4_;
            _loc3_ += 0.3;
            _loc7_ += 0.15;
            _loc5_++;
         }
         _loc2_ = new SelectedFighterUI(new _uiClass());
         if(param1)
         {
            _loc2_.setFighter(param1);
         }
         _loc2_.ui.y = 50;
         TweenLite.to(_loc2_.ui,0.1,{
            "y":0,
            "delay":0.05
         });
         addChild(_loc2_.ui);
         _uis.push(_loc2_);
         if(_curUI)
         {
            _curUI.destory();
            _curUI = null;
         }
         _curUI = _loc2_;
      }
      
      public function updateFighter(param1:FighterVO) : void
      {
         _curUI.setFighter(param1);
      }
   }
}

