package net.play5d.game.bvn.ui
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import net.play5d.game.bvn.data.FighterVO;
   
   public class WinUI
   {
      
      private var _ui:*;
      
      private var _team:int;
      
      public function WinUI(param1:*, param2:int)
      {
         super();
         this._ui = param1;
         this._team = param2;
      }
      
      public function get ui() : DisplayObject
      {
         return this._ui;
      }
      
      public function show(param1:FighterVO, param2:int) : void
      {
         var _loc3_:MovieClip = null;
         if(!param1)
         {
            return;
         }
         switch(param2 - 1)
         {
            case 0:
               _loc3_ = this._team == 1 ? this._ui.w1 : this._ui.w2;
               break;
            case 1:
               _loc3_ = this._team == 1 ? this._ui.w2 : this._ui.w1;
         }
         if(!_loc3_)
         {
            return;
         }
         switch(param1.comicType)
         {
            case 0:
               _loc3_.gotoAndPlay("in_bleach");
               break;
            case 1:
               _loc3_.gotoAndPlay("in_naruto");
         }
      }
   }
}

