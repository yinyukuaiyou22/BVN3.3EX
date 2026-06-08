package net.play5d.game.bvn.ui.fight
{
   import flash.geom.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.*;
   
   public class HitsUI
   {
      
      private var _mc:*;
      
      private var _txtmc:MCNumber;
      
      private var _isShow:Boolean;
      
      private var _orgPos:Point;
      
      public function HitsUI(param1:*)
      {
         super();
         this._mc = param1;
         var _loc2_:Class = ResUtils.I.getItemClass(ResUtils.I.fight,"hits_num_mc");
         this._txtmc = new MCNumber(_loc2_,0,1,35);
         this._orgPos = new Point(param1.x,param1.y);
         this._mc.ct.addChild(this._txtmc);
      }
      
      public function destory() : void
      {
         if(Boolean(this._txtmc))
         {
            try
            {
               this._mc.ct.removeChild(this._txtmc);
            }
            catch(e:Error)
            {
            }
            this._txtmc = null;
         }
         if(Boolean(this._mc))
         {
            this._mc = null;
         }
         this._orgPos = null;
      }
      
      public function show(param1:int) : void
      {
         this._txtmc.number = param1;
         var _loc2_:Number = -this._txtmc.width + 45;
         this._txtmc.x = _loc2_;
         if(this._mc.name == "hits1")
         {
            this._mc.x = this._orgPos.x - _loc2_;
         }
         if(this._isShow)
         {
            this._mc.gotoAndPlay("update");
            return;
         }
         this._isShow = true;
         this._mc.gotoAndPlay("fadin");
      }
      
      public function hide() : void
      {
         if(!this._isShow)
         {
            return;
         }
         this._isShow = false;
         this._mc.gotoAndPlay("fadout");
      }
   }
}

