package net.play5d.game.bvn.state
{
   import flash.display.*;
   import flash.events.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.bitmap.*;
   import net.play5d.kyo.stage.*;
   import net.play5d.kyo.utils.*;
   
   public class GameOverState implements Istage
   {
      
      private var _ui:*;
      
      private var _arrow:*;
      
      private var _arrowSelected:String;
      
      private var _keyInited:Boolean;
      
      private var _keyEnabled:Boolean = true;
      
      private var _char:FighterMain;
      
      private var _btns:Array = [];
      
      public function GameOverState()
      {
         super();
         StateCtrl.I.clearTrans();
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.gameover,ResUtils.GAME_OVER);
         this._ui.gotoAndStop(1);
      }
      
      public function showContinue() : void
      {
         this._ui.addEventListener("complete",this.showContinueComplete,false,0,true);
         this._ui.gotoAndPlay("continue");
         this.addChar();
         SoundCtrl.I.BGM(AssetManager.I.getSound("continue"));
      }
      
      private function showContinueComplete(param1:Event) : void
      {
         this._ui.removeEventListener("complete",this.showContinueComplete);
         this.initBtn("btn_yes");
         this.initBtn("btn_no");
         this.initArrow("btn_yes");
      }
      
      private function initBtn(param1:String) : void
      {
         var _loc2_:Sprite = this._ui.getChildByName(param1) as Sprite;
         if(!_loc2_)
         {
            return;
         }
         _loc2_.buttonMode = true;
         _loc2_.addEventListener("mouseOver",this.btnMouseHandler);
         _loc2_.addEventListener("click",this.btnMouseHandler);
         this._btns.push(_loc2_);
      }
      
      private function btnMouseHandler(param1:MouseEvent) : void
      {
         var _loc2_:DisplayObject = param1.currentTarget as DisplayObject;
         switch(param1.type)
         {
            case "mouseOver":
               this.setArrow(_loc2_.name);
               break;
            case "click":
               this._arrowSelected = _loc2_.name;
               this.selectHandler();
         }
      }
      
      private function render() : void
      {
         if(!this._keyEnabled)
         {
            return;
         }
         if(GameInputer.left("MENU",1))
         {
            this.setArrow("btn_yes");
         }
         if(GameInputer.right("MENU",1))
         {
            this.setArrow("btn_no");
         }
         if(GameInputer.select("MENU",1))
         {
            this.selectHandler();
         }
      }
      
      private function selectHandler() : void
      {
         switch(this._arrowSelected)
         {
            case "btn_yes":
               this.showContYes();
               break;
            case "btn_no":
               this.showContNo();
               break;
            case "btn_back":
               MainGame.I.goLogo();
         }
         SoundCtrl.I.sndConfrim();
      }
      
      private function initArrow(param1:String = null) : void
      {
         if(!this._arrow)
         {
            this._arrow = ResUtils.I.createDisplayObject(ResUtils.I.common_ui,"select_arrow_mc");
            this._ui.addChild(this._arrow);
         }
         if(Boolean(param1))
         {
            this.setArrow(param1);
         }
         GameRender.add(this.render);
         GameInputer.focus();
         this._keyEnabled = true;
      }
      
      private function removeArrow() : void
      {
         if(Boolean(this._arrow))
         {
            try
            {
               this._ui.removeChild(this._arrow);
            }
            catch(e:Error)
            {
            }
            this._arrow = null;
         }
         this._keyEnabled = false;
      }
      
      private function setArrow(param1:String) : void
      {
         this._arrowSelected = param1;
         var _loc2_:DisplayObject = this._ui.getChildByName(param1);
         if(Boolean(_loc2_))
         {
            this._arrow.x = _loc2_.x;
            this._arrow.y = _loc2_.y;
            SoundCtrl.I.sndSelect();
         }
      }
      
      private function addChar() : void
      {
         var _loc1_:FighterMain = null;
         var _loc2_:Sprite = this._ui.getChildByName("ct_char") as Sprite;
         if(Boolean(_loc2_))
         {
            try
            {
               _loc1_ = GameCtrl.I.gameRunData.continueLoser;
               if(Boolean(_loc1_))
               {
                  _loc1_.scale = 3;
                  _loc1_.x = 0;
                  _loc1_.y = 0;
                  _loc1_.setVelocity(0,0);
                  _loc1_.setVec2(0,0);
                  _loc1_.renderSelf();
                  _loc1_.lose();
                  _loc2_.addChild(_loc1_.mc);
                  this._char = _loc1_;
               }
            }
            catch(e:Error)
            {
               trace(e);
            }
         }
         else
         {
            setFrameOut(this.addChar,2,_loc2_);
         }
      }
      
      private function showContYes() : void
      {
         this._ui.addEventListener("complete",this.showContYesComplete,false,0,true);
         this._ui.gotoAndPlay("continue_yes");
         this._keyEnabled = false;
         if(Boolean(this._char))
         {
            this._char.idle();
         }
         this.removeArrow();
      }
      
      private function showContYesComplete(param1:Event) : void
      {
         this._ui.removeEventListener("complete",this.showContYesComplete);
         GameLogic.loseScoreByContinue();
         MainGame.I.goSelect();
      }
      
      private function showContNo() : void
      {
         this._ui.addEventListener("complete",this.showContNoComplete,false,0,true);
         this._ui.gotoAndPlay("continue_no");
         this.removeArrow();
      }
      
      private function showContNoComplete(param1:Event) : void
      {
         this._ui.removeEventListener("complete",this.showContNoComplete);
         this.showGameOver();
      }
      
      public function showGameOver() : void
      {
         this._ui.addEventListener("complete",this.gameOverComplete,false,0,true);
         this._ui.gotoAndPlay("gameover");
         SoundCtrl.I.playSwcSound(snd_gameover);
         SoundCtrl.I.BGM(null);
         this.addScore();
      }
      
      private function addScore() : void
      {
         var _loc1_:BitmapFontText = null;
         var _loc2_:Sprite = this._ui.getChildByName("ct_score") as Sprite;
         if(Boolean(_loc2_))
         {
            _loc1_ = new BitmapFontText(AssetManager.I.getFont("font1"));
            _loc1_.text = "SCORE " + GameData.I.score;
            _loc1_.x = -_loc1_.width / 2;
            _loc2_.addChild(_loc1_);
         }
         else
         {
            setFrameOut(this.addScore,1,_loc2_);
         }
      }
      
      private function gameOverComplete(param1:Event) : void
      {
         this._ui.removeEventListener("complete",this.gameOverComplete);
         GameEvent.dispatchEvent("GAME_OVER");
         this.initBtn("btn_back");
         this.initArrow("btn_back");
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
      }
      
      public function afterBuild() : void
      {
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["show_continue"])));
      }
      
      public function destory(param1:Function = null) : void
      {
         var _loc2_:* = undefined;
         GameRender.remove(this.render);
         if(Boolean(this._btns))
         {
            for each(_loc2_ in this._btns)
            {
               _loc2_.removeEventListener("mouseOver",this.btnMouseHandler);
               _loc2_.removeEventListener("click",this.btnMouseHandler);
            }
            this._btns = null;
         }
         if(Boolean(this._char))
         {
            try
            {
               this._char.mc.parent.removeChild(this._char.mc);
            }
            catch(e:Error)
            {
            }
            this._char = null;
         }
         GameCtrl.I.gameRunData.continueLoser = null;
         GameCtrl.I.destory();
      }
   }
}

