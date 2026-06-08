package net.play5d.game.bvn.ui.fight
{
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.kyo.utils.*;
   
   public class QiBar
   {
      
      private var _ui:*;
      
      private var _fighter:FighterMain;
      
      private var _bar:InsBar;
      
      private var _fzBar:InsFzBar;
      
      private var _fzReadyMc:MovieClip;
      
      private var _qiRate:Number = 0;
      
      private var _fzRate:Number = 0;
      
      private var _orgPose:Point;
      
      private var _tweenSpd:Number = 0.5;
      
      private var _moveFin:Boolean = true;
      
      private var _moveType:int = 0;
      
      private var _isFadIn:Boolean;
      
      private var _isRenderAnimate:Boolean;
      
      private var _faceBp:Bitmap;
      
      public function QiBar(param1:*)
      {
         super();
         this._ui = param1;
         this._bar = new InsBar(this._ui.barmc);
         this._fzBar = new InsFzBar(this._ui.fzqibar);
         this._fzReadyMc = this._ui.readymc;
         this._orgPose = new Point(this._ui.x,this._ui.y);
         this._ui.addEventListener("complete",this.uiPlayComplete);
         if(GameUI.BITMAP_UI)
         {
            this._ui.gotoAndStop("fadin_fin");
            this._ui.visible = false;
         }
      }
      
      public function destory() : void
      {
         if(Boolean(this._ui))
         {
            this._ui.removeEventListener("complete",this.uiPlayComplete);
            this._ui.gotoAndStop("destory");
            this._ui = null;
         }
         if(Boolean(this._faceBp))
         {
            this._faceBp.bitmapData.dispose();
            this._faceBp = null;
         }
         this._fighter = null;
      }
      
      private function uiPlayComplete(param1:Event) : void
      {
         if(this._isFadIn)
         {
            this._ui.visible = true;
            this.setCacheBitmap(true);
         }
         else
         {
            this._ui.visible = false;
         }
      }
      
      public function setFighter(param1:FighterMain, param2:Assister = null) : void
      {
         var _loc3_:DisplayObject = null;
         this._fighter = param1;
         if(Boolean(param2) && Boolean(param2.data))
         {
            _loc3_ = AssetManager.I.getFighterFace(param2.data);
            if(Boolean(_loc3_))
            {
               this._ui.facemc.ct.addChild(_loc3_);
            }
         }
         if(GameUI.BITMAP_UI)
         {
            this._faceBp = KyoUtils.drawDisplay(this._ui.facemc);
            this._ui.addChild(this._faceBp);
            this._faceBp.x = this._ui.facemc.x;
            this._faceBp.y = this._ui.facemc.y;
            try
            {
               this._ui.removeChild(this._ui.facemc);
            }
            catch(e:Error)
            {
            }
            this._ui.addChild(this._ui.readymc);
         }
      }
      
      private function setCacheBitmap(param1:Boolean) : void
      {
         if(GameUI.BITMAP_UI)
         {
            return;
         }
         this._ui.facemc.cacheAsBitmap = param1;
      }
      
      public function setDirect(param1:int) : void
      {
         this._bar.setDirect(param1);
         this._fzReadyMc.mc.scaleX = param1 > 0 ? 1 : -1;
      }
      
      public function render() : void
      {
         this._qiRate = this._fighter.qi / 100;
         if(this._qiRate > 3)
         {
            this._qiRate = 3;
         }
         var _loc1_:Number = Number(this._bar.getProcess());
         var _loc2_:Number = this._qiRate - _loc1_;
         if(Math.abs(_loc2_) < 0.01)
         {
            this._bar.setProcess(this._qiRate);
         }
         else
         {
            this._bar.setProcess(_loc1_ + _loc2_ * 0.4);
         }
         this._fzBar.setProcess(this._fighter.fzqi / 100);
         var _loc3_:* = this._fzBar.getProcess() >= 1;
         if(this._fzReadyMc.visible != _loc3_)
         {
            this._fzReadyMc.visible = _loc3_;
            if(Boolean(_loc3_))
            {
               this._fzReadyMc.mc.play();
            }
            else
            {
               this._fzReadyMc.mc.gotoAndStop(1);
            }
         }
      }
      
      public function renderAnimate() : void
      {
         if(!this._isRenderAnimate)
         {
            return;
         }
         var _loc1_:String = this._ui.currentFrameLabel;
         if(_loc1_ == "fadin_fin" || _loc1_ == "fadout_fin")
         {
            this._isRenderAnimate = false;
            return;
         }
         this._ui.nextFrame();
      }
      
      public function fadIn(param1:Boolean = true) : void
      {
         if(this._isFadIn)
         {
            return;
         }
         this._isFadIn = true;
         this._ui.visible = true;
         if(GameUI.BITMAP_UI)
         {
            return;
         }
         if(param1)
         {
            this.setCacheBitmap(false);
            this._ui.gotoAndStop("fadin");
            this._isRenderAnimate = true;
         }
         else
         {
            this._ui.gotoAndStop("fadin_fin");
            this.setCacheBitmap(true);
         }
      }
      
      public function fadOut(param1:Boolean = true) : void
      {
         if(!this._isFadIn)
         {
            return;
         }
         this._isFadIn = false;
         if(GameUI.BITMAP_UI)
         {
            this._ui.visible = false;
            return;
         }
         if(param1)
         {
            this._ui.gotoAndStop("fadout");
            this._isRenderAnimate = true;
            this.setCacheBitmap(false);
         }
         else
         {
            this._ui.visible = false;
         }
      }
      
      public function moveTo(param1:Number, param2:Number, param3:Number) : void
      {
         if(this._moveType == 1)
         {
            if(this._moveFin)
            {
               return;
            }
         }
         else
         {
            this._moveType = 1;
            this._moveFin = false;
         }
         this.moving(param1,param2,param3);
      }
      
      public function moveResume() : void
      {
         if(this._moveType == 0)
         {
            if(this._moveFin)
            {
               return;
            }
         }
         else
         {
            this._moveType = 0;
            this._moveFin = false;
         }
         this.moving(this._orgPose.x,this._orgPose.y,1);
      }
      
      private function moving(param1:Number, param2:Number, param3:Number) : void
      {
         if(Math.abs(param1 - this._ui.x) < 2 && Math.abs(param2 - this._ui.y) < 2 && Math.abs(param3 - this._ui.scaleX) < 0.2)
         {
            this._ui.x = param1;
            this._ui.y = param2;
            this._ui.scaleX = this._ui.scaleY = param3;
            this._moveFin = true;
         }
         this._ui.x += (param1 - this._ui.x) * this._tweenSpd;
         this._ui.y += (param2 - this._ui.y) * this._tweenSpd;
         this._ui.scaleX += (param3 - this._ui.scaleX) * this._tweenSpd;
         this._ui.scaleY = this._ui.scaleX;
      }
      
      public function setPosAndScale(param1:Number, param2:Number, param3:Number) : void
      {
         this._ui.x = param1;
         this._ui.y = param2;
         this._ui.scaleX = param3;
         this._ui.scaleY = param3;
      }
   }
}

import flash.display.DisplayObject;
import flash.geom.*;

class InsBar
{
   
   private var _ui:*;
   
   private var _process:Number = 0;
   
   public function InsBar(param1:*)
   {
      super();
      this._ui = param1;
      this.setProcess(0);
   }
   
   public function get ui() : DisplayObject
   {
      return this._ui;
   }
   
   public function getProcess() : Number
   {
      return this._process;
   }
   
   public function setProcess(param1:Number) : void
   {
      this._process = param1;
      this._ui.bar.bar1.visible = param1 > 0;
      this._ui.bar.bar2.visible = param1 > 1;
      this._ui.bar.bar3.visible = param1 > 2;
      this._ui.bar.bar4.visible = param1 >= 3;
      if(param1 > 2)
      {
         this._ui.bar.bar1.scaleX = this._ui.bar.bar2.scaleX = 1;
         this._ui.bar.bar3.scaleX = param1 - 2;
      }
      else if(param1 > 1)
      {
         this._ui.bar.bar1.scaleX = 1;
         this._ui.bar.bar2.scaleX = param1 - 1;
      }
      else
      {
         this._ui.bar.bar1.scaleX = param1;
      }
      var _loc2_:int = int(param1) + 1;
      this._ui.txtmc.gotoAndStop(_loc2_);
   }
   
   public function setDirect(param1:int) : void
   {
      this._ui.txtmc.scaleX = param1 > 0 ? 1 : -1;
   }
}

class InsFzBar
{
   
   private var _ui:*;
   
   private var _process:Number = 0;
   
   private var _scroll:Rectangle;
   
   private var _height:Number;
   
   public function InsFzBar(param1:*)
   {
      super();
      this._ui = param1;
      var _loc2_:Rectangle = this._ui.barmc.getBounds(this._ui.barmc);
      this._scroll = new Rectangle(0,0,this._ui.barmc.width,this._ui.barmc.height);
      this._height = this._scroll.height;
      this._ui.barmc.scaleY = -1;
      this._ui.barmc.y = this._ui.barmc.height;
   }
   
   public function get ui() : DisplayObject
   {
      return this._ui;
   }
   
   public function getProcess() : Number
   {
      return this._process;
   }
   
   public function setProcess(param1:Number) : void
   {
      this._process = param1;
      this._scroll.height = param1 * this._height;
      this._ui.barmc.scrollRect = this._scroll;
   }
}
