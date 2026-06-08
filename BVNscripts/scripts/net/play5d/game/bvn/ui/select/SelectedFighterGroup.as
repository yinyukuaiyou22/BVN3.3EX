package net.play5d.game.bvn.ui.select
{
   import com.greensock.*;
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
         this._uiClass = param1;
      }
      
      public function destory() : void
      {
         if(Boolean(this._curUI))
         {
            this._curUI.destory();
            this._curUI = null;
         }
      }
      
      public function addFighter(param1:FighterVO) : void
      {
         var _loc2_:SelectedFighterUI = null;
         var _loc3_:int = 0;
         var _loc4_:Number = 20 - (this._uis.length - 1) * 3;
         var _loc5_:Number = this._uis.length * -20;
         var _loc6_:Number = 0.7 - (this._uis.length - 1) * 0.3;
         var _loc7_:Number = 0.85 - (this._uis.length - 1) * 0.15;
         while(_loc3_ < this._uis.length)
         {
            _loc2_ = this._uis[_loc3_];
            TweenLite.to(_loc2_.ui,0.1,{
               "y":_loc5_,
               "alpha":_loc6_,
               "scaleX":_loc7_,
               "scaleY":_loc7_
            });
            _loc5_ += _loc4_;
            _loc6_ += 0.3;
            _loc7_ += 0.15;
            _loc3_++;
         }
         _loc2_ = new SelectedFighterUI(new this._uiClass());
         if(Boolean(param1))
         {
            _loc2_.setFighter(param1);
         }
         _loc2_.ui.y = 50;
         TweenLite.to(_loc2_.ui,0.1,{
            "y":0,
            "delay":0.05
         });
         addChild(_loc2_.ui);
         this._uis.push(_loc2_);
         if(Boolean(this._curUI))
         {
            this._curUI.destory();
            this._curUI = null;
         }
         this._curUI = _loc2_;
      }
      
      public function updateFighter(param1:FighterVO) : void
      {
         this._curUI.setFighter(param1);
      }
   }
}

