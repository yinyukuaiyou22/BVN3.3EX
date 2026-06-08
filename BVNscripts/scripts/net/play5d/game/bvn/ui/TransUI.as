package net.play5d.game.bvn.ui
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.utils.*;
   
   public class TransUI
   {
      
      public var ui:*;
      
      private var _renderAnimateGap:int = 0;
      
      private var _renderAnimateFrame:int = 0;
      
      private var _fadInBack:Function;
      
      private var _fadOutBack:Function;
      
      private var _rendering:Boolean = true;
      
      public function TransUI()
      {
         super();
         this.ui = ResUtils.I.createDisplayObject(ResUtils.I.common_ui,"trans_mc");
      }
      
      public function destory() : void
      {
         GameRender.remove(this.render);
      }
      
      private function startRender() : void
      {
         this._renderAnimateGap = Math.ceil(MainGame.I.getFPS() / 30) - 1;
         this._renderAnimateFrame = 0;
         this._rendering = true;
         GameRender.add(this.render);
      }
      
      private function stopRender() : void
      {
         this._rendering = false;
         GameRender.remove(this.render);
      }
      
      private function render() : void
      {
         if(!this._rendering)
         {
            return;
         }
         if(this._renderAnimateGap > 0)
         {
            if(this._renderAnimateFrame++ >= this._renderAnimateGap)
            {
               this._renderAnimateFrame = 0;
               this.renderAnimate();
            }
         }
         else
         {
            this.renderAnimate();
         }
      }
      
      private function renderAnimate() : void
      {
         if(this.ui.currentFrameLabel == "stop")
         {
            if(this._fadInBack != null)
            {
               this._fadInBack();
               this._fadInBack = null;
               return;
            }
            if(this._fadOutBack != null)
            {
               this._fadOutBack();
               this._fadOutBack = null;
               return;
            }
            this.stopRender();
            return;
         }
         this.ui.nextFrame();
      }
      
      public function fadIn(param1:Function = null) : void
      {
         this._fadOutBack = null;
         this._fadInBack = param1;
         this.ui.gotoAndStop("fadin");
         this.startRender();
      }
      
      public function fadOut(param1:Function = null) : void
      {
         this._fadInBack = null;
         this._fadOutBack = param1;
         this.ui.gotoAndStop("fadout");
         this.startRender();
      }
   }
}

