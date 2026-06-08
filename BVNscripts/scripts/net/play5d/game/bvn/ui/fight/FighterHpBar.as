package net.play5d.game.bvn.ui.fight
{
   import flash.display.DisplayObject;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   
   public class FighterHpBar
   {
      
      private var _ui:*;
      
      private var _bar:DisplayObject;
      
      private var _redbar:DisplayObject;
      
      private var _fighter:FighterMain;
      
      private var _hprate:Number = 1;
      
      private var _redBarMoving:Boolean;
      
      private var _redBarMoveDelay:int;
      
      private var _justHurtFly:Boolean;
      
      public function FighterHpBar(param1:*)
      {
         super();
         this._ui = param1;
         this._bar = this._ui.bar;
         this._redbar = this._ui.redbar;
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
      }
      
      public function render() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:Number = this._fighter.hp / this._fighter.hpMax;
         if(Boolean(this._redBarMoving) && _loc3_ != this._hprate)
         {
            this._redbar.scaleX = this._hprate;
            this._redBarMoving = false;
         }
         this._hprate = _loc3_;
         var _loc4_:Number = this._hprate - this._bar.scaleX;
         var _loc5_:Number = _loc4_ < 0 ? 0.4 : 0.04;
         if(Math.abs(_loc4_) < 0.01)
         {
            this._bar.scaleX = this._hprate;
         }
         else
         {
            this._bar.scaleX += _loc4_ * _loc5_;
         }
         switch(this._fighter.actionState - 21)
         {
            case 0:
               this._redBarMoveDelay = 100;
               break;
            case 1:
            case 2:
               if(this._redBarMoveDelay > 0)
               {
                  if(!this._justHurtFly)
                  {
                     this._redBarMoveDelay = 1.5 * GameConfig.FPS_GAME;
                     this._justHurtFly = true;
                  }
                  else if(this._redBarMoveDelay > 0)
                  {
                     --this._redBarMoveDelay;
                  }
               }
               break;
            default:
               this._redBarMoveDelay = 0;
               this._justHurtFly = false;
         }
         if(this._redBarMoveDelay <= 0)
         {
            _loc1_ = this._hprate - this._redbar.scaleX;
            _loc2_ = _loc1_ < 0 ? 0.1 : 0.02;
            if(Math.abs(_loc1_) < 0.01)
            {
               this._redbar.scaleX = this._hprate;
               this._redBarMoving = false;
            }
            else
            {
               this._redbar.scaleX += _loc1_ * _loc2_;
               this._redBarMoving = true;
            }
         }
      }
   }
}

