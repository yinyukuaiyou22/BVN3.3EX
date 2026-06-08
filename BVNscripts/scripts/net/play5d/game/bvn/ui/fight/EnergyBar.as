package net.play5d.game.bvn.ui.fight
{
   import flash.display.DisplayObject;
   import net.play5d.game.bvn.fighter.FighterMain;
   
   public class EnergyBar
   {
      
      private var _ui:*;
      
      private var _fighter:FighterMain;
      
      private var _bar:InsBar;
      
      private var _txt:InsTxt;
      
      private var _renderFlash:Boolean;
      
      private var _renderFlashInt:int;
      
      public function EnergyBar(param1:*)
      {
         super();
         this._ui = param1;
         this._bar = new InsBar(this._ui.barmc.bar);
         this._txt = new InsTxt(this._ui.txtmc);
      }
      
      public function get ui() : DisplayObject
      {
         return this._ui;
      }
      
      public function destory() : void
      {
         this._fighter = null;
      }
      
      public function setFighter(param1:FighterMain) : void
      {
         this._fighter = param1;
         if(Boolean(param1.data))
         {
            this._txt.setType(param1.data.comicType);
         }
      }
      
      public function setDirect(param1:int) : void
      {
         this._txt.setDirect(param1);
      }
      
      public function render() : void
      {
         this._bar.rate = this._fighter.energy / this._fighter.energyMax;
         if(this._fighter.energyOverLoad)
         {
            this._bar.overLoad();
            this._txt.overLoad();
         }
         else if(this._bar.rate < 0.3)
         {
            this._bar.flash();
            this._txt.flash();
         }
         else
         {
            this._bar.normal();
            this._txt.normal();
         }
         this._bar.render();
         this._txt.render();
      }
   }
}

import flash.display.MovieClip;

class InsBar
{
   
   public var rate:Number = 1;
   
   private var _mc:MovieClip;
   
   private var _curRate:Number = 1;
   
   private var _isOverLoad:Boolean;
   
   private var _isFlash:Boolean;
   
   private var _renderFlashInt:int;
   
   private var _renderFlashFrame:int = 2;
   
   public function InsBar(param1:MovieClip)
   {
      super();
      this._mc = param1;
   }
   
   public function render() : void
   {
      var _loc1_:Number = this.rate - this._mc.scaleX;
      if(Math.abs(_loc1_) < 0.01)
      {
         this._mc.scaleX = this.rate;
      }
      else
      {
         this._mc.scaleX += _loc1_ * 0.4;
      }
      if(this._isFlash)
      {
         this.renderFlash();
      }
   }
   
   private function renderFlash() : void
   {
      if(++this._renderFlashInt > 2)
      {
         this._renderFlashInt = 0;
         this._mc.gotoAndStop(this._renderFlashFrame);
         this._renderFlashFrame = this._renderFlashFrame == 1 ? 2 : 1;
      }
   }
   
   public function normal() : void
   {
      if(!this._isOverLoad && !this._isFlash)
      {
         return;
      }
      this._isOverLoad = false;
      this._isFlash = false;
      this._mc.gotoAndStop(1);
   }
   
   public function flash() : void
   {
      if(this._isFlash)
      {
         return;
      }
      this._isFlash = true;
      this._renderFlashInt = 0;
      this._renderFlashFrame = 2;
   }
   
   public function overLoad() : void
   {
      if(this._isOverLoad)
      {
         return;
      }
      this._isOverLoad = true;
      this._isFlash = false;
      this._mc.gotoAndStop(2);
   }
}

class InsTxt
{
   
   private var _mc:MovieClip;
   
   private var _isOverLoad:Boolean;
   
   private var _isFlash:Boolean;
   
   private var _renderFlashInt:int;
   
   private var _renderFlashFrame:int;
   
   public function InsTxt(param1:MovieClip)
   {
      super();
      this._mc = param1;
   }
   
   public function setDirect(param1:int) : void
   {
      this._mc.scaleX = param1 > 0 ? 1 : -1;
   }
   
   public function setType(param1:int) : void
   {
      switch(param1)
      {
         case 0:
            this._mc.gotoAndStop(1);
            break;
         case 1:
            this._mc.gotoAndStop(2);
      }
   }
   
   public function render() : void
   {
      if(this._isFlash)
      {
         this.renderFlash();
      }
   }
   
   private function renderFlash() : void
   {
      if(!this._mc.mc)
      {
         return;
      }
      if(++this._renderFlashInt > 2)
      {
         this._renderFlashInt = 0;
         this._mc.mc.gotoAndStop(this._renderFlashFrame);
         this._renderFlashFrame = this._renderFlashFrame == 1 ? 2 : 1;
      }
   }
   
   public function normal() : void
   {
      if(!this._isOverLoad && !this._isFlash)
      {
         return;
      }
      this._isOverLoad = false;
      this._isFlash = false;
      if(Boolean(this._mc.mc))
      {
         this._mc.mc.gotoAndStop(1);
      }
   }
   
   public function flash() : void
   {
      if(this._isFlash)
      {
         return;
      }
      this._isFlash = true;
      this._renderFlashInt = 0;
      this._renderFlashFrame = 2;
   }
   
   public function overLoad() : void
   {
      if(this._isOverLoad)
      {
         return;
      }
      this._isOverLoad = true;
      this._isFlash = false;
      if(Boolean(this._mc.mc))
      {
         this._mc.mc.gotoAndStop(2);
      }
   }
}
