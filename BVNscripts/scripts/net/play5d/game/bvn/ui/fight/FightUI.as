package net.play5d.game.bvn.ui.fight
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.media.SoundTransform;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   
   public class FightUI implements IGameUI
   {
      
      public static var QI_BAR_MODE:int;
      
      public var ui:*;
      
      private var _fightbar:FightBar;
      
      private var _qibar1:QiBar;
      
      private var _qibar2:QiBar;
      
      private var _hits1:HitsUI;
      
      private var _hits2:HitsUI;
      
      private var _endParam:Object;
      
      private var _renderEnd:Boolean;
      
      private var _playOver:Boolean;
      
      private var _showWinnerDelay:int;
      
      private var _drawGame:Boolean;
      
      private var _isSlowDown:Boolean;
      
      private var _pauseDialog:PauseDialog;
      
      private var _flyTimer:Number = 0;
      
      private var _p1PosUI:*;
      
      private var _p2PosUI:*;
      
      public function FightUI()
      {
         super();
         this.ui = ResUtils.I.createDisplayObject(ResUtils.I.fight,"ui_fight");
         this._fightbar = new FightBar(this.ui.hpbarmc);
         this._qibar1 = new QiBar(this.ui.fzqi1);
         this._qibar2 = new QiBar(this.ui.fzqi2);
         this._hits1 = new HitsUI(this.ui.hits1);
         this._hits2 = new HitsUI(this.ui.hits2);
         this._qibar2.setDirect(-1);
         this._p1PosUI = ResUtils.I.createDisplayObject(ResUtils.I.fight,"player_pos_p1");
         this._p2PosUI = ResUtils.I.createDisplayObject(ResUtils.I.fight,"player_pos_p2");
         this._p1PosUI.visible = false;
         this._p2PosUI.visible = false;
         this.ui.addChild(this._p1PosUI);
         this.ui.addChild(this._p2PosUI);
         if(GameMode.isAcrade())
         {
            trace("fightUI.initlize");
            this._fightbar.initScore();
            GameEvent.addEventListener("SCORE_UPDATE",this.updateScore);
         }
      }
      
      public function initlize(param1:GameRunFighterGroup, param2:GameRunFighterGroup) : void
      {
         this._fightbar.setFighter(param1,param2);
         this._qibar1.setFighter(param1.currentFighter,param1.fuzhu);
         this._qibar2.setFighter(param2.currentFighter,param2.fuzhu);
         this.updateScore(null);
      }
      
      public function setVolume(param1:Number) : void
      {
         var _loc2_:SoundTransform = this.ui.soundTransform;
         _loc2_.volume = param1;
         this.ui.soundTransform = _loc2_;
      }
      
      public function showWins(param1:FighterMain, param2:int) : void
      {
         this._fightbar.showWin(param1,param2);
      }
      
      private function updateScore(param1:GameEvent) : void
      {
         this._fightbar.setScore(GameData.I.score);
      }
      
      public function destory() : void
      {
         GameEvent.removeEventListener("SCORE_UPDATE",this.updateScore);
         if(Boolean(this._pauseDialog))
         {
            this._pauseDialog.destory();
            this._pauseDialog = null;
         }
         if(Boolean(this._fightbar))
         {
            this._fightbar.destory();
            this._fightbar = null;
         }
         if(Boolean(this._qibar1))
         {
            this._qibar1.destory();
            this._qibar1 = null;
         }
         if(Boolean(this._qibar2))
         {
            this._qibar2.destory();
            this._qibar2 = null;
         }
         if(Boolean(this._hits1))
         {
            this._hits1.destory();
            this._hits1 = null;
         }
         if(Boolean(this._hits2))
         {
            this._hits2.destory();
            this._hits2 = null;
         }
         if(Boolean(this.ui))
         {
            try
            {
               this.ui.removeChildren();
               this.ui.stopAllMovieClips();
            }
            catch(e:Error)
            {
               trace(e);
            }
            this.ui = null;
         }
      }
      
      public function getUI() : DisplayObject
      {
         return this.ui;
      }
      
      public function render() : void
      {
         this._fightbar.render();
         this._qibar1.render();
         this._qibar2.render();
         var _loc1_:Number = Number(GameCtrl.I.gameState.camera.getZoom());
         this.renderPlayerPosUI(_loc1_);
         if(this._renderEnd)
         {
            this.renderEnd();
         }
      }
      
      private function renderQibarPos(param1:Number) : void
      {
         if(QI_BAR_MODE != 0)
         {
            return;
         }
         if(param1 < 1.5)
         {
            this._qibar1.moveTo(120,60,0.8);
            this._qibar2.moveTo(675,60,0.8);
         }
         else
         {
            this._qibar1.moveResume();
            this._qibar2.moveResume();
         }
      }
      
      public function renderAnimate() : void
      {
         this._fightbar.renderAnimate();
         this._qibar1.renderAnimate();
         this._qibar2.renderAnimate();
         this.renderStartAndKO();
      }
      
      private function renderStartAndKO() : void
      {
         var _loc1_:MovieClip = this.ui.startKOmc;
         if(!_loc1_)
         {
            return;
         }
         var _loc2_:String = _loc1_.currentFrameLabel;
         if(Boolean(_loc2_))
         {
            if(_loc2_ == "stop")
            {
               return;
            }
            if(_loc2_.indexOf("go:") != -1)
            {
               _loc1_.gotoAndStop(_loc2_.split("go:")[1]);
               return;
            }
         }
         _loc1_.nextFrame();
      }
      
      public function fadIn(param1:Boolean = true) : void
      {
         this._fightbar.fadIn(param1);
         if(QI_BAR_MODE == 1)
         {
            this._qibar1.fadIn(false);
            this._qibar2.fadIn(false);
            this._qibar1.setPosAndScale(120,60,0.8);
            this._qibar2.setPosAndScale(675,60,0.8);
         }
         else
         {
            this._qibar1.fadIn(param1);
            this._qibar2.fadIn(param1);
         }
      }
      
      public function fadOut(param1:Boolean = true) : void
      {
         this._fightbar.fadOut(param1);
         this._qibar1.fadOut(param1);
         this._qibar2.fadOut(param1);
      }
      
      public function showHits(param1:int, param2:int) : void
      {
         var _loc3_:HitsUI = param2 == 1 ? this._hits1 : this._hits2;
         _loc3_.show(param1);
      }
      
      public function hideHits(param1:int) : void
      {
         var _loc2_:HitsUI = param1 == 1 ? this._hits1 : this._hits2;
         _loc2_.hide();
      }
      
      public function showStart(param1:Function = null, param2:Object = null) : void
      {
         var round:int = 0;
         var finishBack:Function = null;
         var onFight:* = undefined;
         var startComplete:* = undefined;
         finishBack = param1;
         var params:Object = param2;
         onFight = function(param1:Event):void
         {
            ui.startKOmc.removeEventListener("fight",onFight);
         };
         startComplete = function(param1:Event):void
         {
            ui.startKOmc.removeEventListener("complete",startComplete);
            if(finishBack != null)
            {
               finishBack();
            }
         };
         this.fadIn();
         round = int(GameCtrl.I.gameRunData.round);
         this.ui.startKOmc.y = -50;
         this.ui.startKOmc.$round = round;
         this.ui.startKOmc.gotoAndStop(round < 5 ? "start" : "start_final");
         this.ui.startKOmc.addEventListener("fight",onFight);
         if(finishBack != null)
         {
            this.ui.startKOmc.addEventListener("complete",startComplete);
         }
      }
      
      public function showEnd(param1:Function = null, param2:Object = null) : void
      {
         var _loc3_:FighterMain = null;
         this._endParam = param2;
         if(!this._endParam)
         {
            this._endParam = {};
         }
         this._endParam.finishBack = param1;
         this._drawGame = param2 ? Boolean(param2.drawGame) : false;
         this._renderEnd = true;
         this._playOver = false;
         if(GameCtrl.I.gameRunData.isTimerOver)
         {
            this.playTimeOver();
         }
         else
         {
            _loc3_ = param2 ? param2.loser : null;
            this.playKO(_loc3_);
         }
      }
      
      private function playKO(param1:FighterMain = null) : void
      {
         var bsKO:Boolean = false;
         var p1:FighterMain = null;
         var p2:FighterMain = null;
         var loser:FighterMain = param1;
         var playKO2:* = function():void
         {
            ui.startKOmc.y = 0;
            ui.startKOmc.gotoAndStop("ko");
            ui.startKOmc.addEventListener("complete",koBack);
            SoundCtrl.I.playSwcSound(bsKO ? snd_ko_bs : snd_ko);
            _qibar1.fadOut();
            _qibar2.fadOut();
         };
         this._showWinnerDelay = 0;
         EffectCtrl.I.freezeEnabled = false;
         this._isSlowDown = false;
         if(Boolean(loser))
         {
            EffectCtrl.I.doEffectById("hit_end",loser.x,loser.y);
            EffectCtrl.I.shine(16777215,0.5);
            GameCtrl.I.gameState.cameraFocusOne(loser.getDisplay());
         }
         GameCtrl.I.pause();
         bsKO = false;
         p1 = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
         p2 = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter;
         if(Boolean(p1) && Boolean(p2))
         {
            if(p1.actionState == 12 || p1.actionState == 13 || p2.actionState == 12 || p2.actionState == 13)
            {
               bsKO = true;
               EffectCtrl.I.BGEffect("kobg",2);
            }
         }
         EffectCtrl.I.shake(5,0,1.5);
         SoundCtrl.I.playSwcSound(snd_over_hit);
         setTimeout(playKO2,500);
      }
      
      private function koBack(param1:Event) : void
      {
         EffectCtrl.I.freezeEnabled = true;
         this.ui.startKOmc.removeEventListener("complete",this.koBack);
         this._playOver = true;
         GameCtrl.I.resume();
         EffectCtrl.I.freezeEnabled = true;
      }
      
      private function playTimeOver() : void
      {
         this.ui.startKOmc.y = 0;
         this.ui.startKOmc.gotoAndStop("timeover");
         this.ui.startKOmc.addEventListener("complete",this.timeoverBack);
         this._qibar1.fadOut();
         this._qibar2.fadOut();
      }
      
      private function timeoverBack(param1:Event) : void
      {
         EffectCtrl.I.freezeEnabled = true;
         this.ui.startKOmc.removeEventListener("complete",this.timeoverBack);
         if(this._drawGame)
         {
            this.playDrawGame();
            this._showWinnerDelay = 0;
         }
         else
         {
            this._playOver = true;
            this._showWinnerDelay = 1 * GameConfig.FPS_GAME;
         }
      }
      
      private function playDrawGame() : void
      {
         this.ui.startKOmc.gotoAndStop("drawgame");
         this.ui.startKOmc.addEventListener("complete",this.drawGameBack);
      }
      
      private function drawGameBack(param1:Event) : void
      {
         this.ui.startKOmc.removeEventListener("complete",this.drawGameBack);
         if(this._endParam.finishBack != null)
         {
            this._endParam.finishBack();
         }
      }
      
      private function renderEnd() : void
      {
         var _loc1_:FighterMain = null;
         if(!this._playOver)
         {
            return;
         }
         if(!this._endParam)
         {
            return;
         }
         if(this._showWinnerDelay > 0)
         {
            --this._showWinnerDelay;
            if(this._showWinnerDelay <= 0)
            {
               _loc1_ = this._endParam.winner;
               if(Boolean(_loc1_))
               {
                  GameCtrl.I.gameState.cameraFocusOne(_loc1_.getDisplay());
                  this.showWinner(_loc1_);
                  if(GameMode.isSingleMode())
                  {
                     this.showWins(_loc1_,GameCtrl.I.gameRunData.getWins(_loc1_));
                  }
                  if(Boolean(this._endParam))
                  {
                     this._endParam.finishBack();
                  }
               }
               this._renderEnd = false;
               this._endParam = null;
            }
            return;
         }
         var _loc2_:FighterMain = this._endParam.loser;
         if(Boolean(_loc2_))
         {
            if(_loc2_.actionState == 22)
            {
               if(!this._isSlowDown)
               {
                  this._isSlowDown = true;
                  EffectCtrl.I.slowDown(2,0);
                  this._flyTimer = getTimer();
               }
            }
            if(_loc2_.actionState == 30)
            {
               if(this._isSlowDown)
               {
                  if(getTimer() - this._flyTimer < 2000)
                  {
                     this._showWinnerDelay = 2 * GameConfig.FPS_GAME;
                  }
                  else
                  {
                     this._showWinnerDelay = 1 * GameConfig.FPS_GAME;
                  }
                  EffectCtrl.I.slowDownResume();
               }
               else
               {
                  this._showWinnerDelay = 2 * GameConfig.FPS_GAME;
                  EffectCtrl.I.slowDownResume();
               }
            }
         }
      }
      
      public function clearStartAndEnd() : void
      {
         this.ui.startKOmc.gotoAndStop(1);
      }
      
      public function pause() : void
      {
         if(!this._pauseDialog)
         {
            this._pauseDialog = new PauseDialog();
            this.ui.addChild(this._pauseDialog);
         }
         this._pauseDialog.show();
      }
      
      public function resume() : void
      {
         if(!this._pauseDialog)
         {
            return;
         }
         this._pauseDialog.hide();
      }
      
      private function showWinner(param1:FighterMain, param2:Function = null) : void
      {
         var teamid:int = 0;
         var back:Function = null;
         var winnerBack:* = undefined;
         var winner:FighterMain = param1;
         back = param2;
         winnerBack = function(param1:Event):void
         {
            ui.startKOmc.removeEventListener("complete",winnerBack);
            if(back != null)
            {
               back();
            }
         };
         this.ui.startKOmc.y = 30;
         teamid = int(Boolean(winner) && Boolean(winner.team) ? winner.team.id : 1);
         switch(teamid - 1)
         {
            case 0:
               this.ui.startKOmc.$winnerX = 30;
               break;
            case 1:
               this.ui.startKOmc.$winnerX = 546;
         }
         this.ui.startKOmc.$perfect = winner.hp >= winner.hpMax;
         this.ui.startKOmc.gotoAndStop("winner");
         if(back != null)
         {
            this.ui.startKOmc.addEventListener("complete",winnerBack);
         }
      }
      
      private function renderPlayerPosUI(param1:Number) : void
      {
         var _loc2_:Point = null;
         if(param1 > 1.8)
         {
            this._p1PosUI.visible = this._p2PosUI.visible = false;
            return;
         }
         var _loc3_:FighterMain = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
         var _loc4_:FighterMain = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter;
         if(Boolean(_loc3_))
         {
            _loc2_ = this.getPlayerPos(_loc3_);
            this._p1PosUI.x = _loc2_.x;
            this._p1PosUI.y = _loc2_.y;
            this._p1PosUI.visible = true;
         }
         if(Boolean(_loc4_))
         {
            _loc2_ = this.getPlayerPos(_loc4_);
            this._p2PosUI.x = _loc2_.x;
            this._p2PosUI.y = _loc2_.y;
            this._p2PosUI.visible = true;
         }
      }
      
      private function getPlayerPos(param1:IGameSprite) : Point
      {
         var _loc2_:Point = GameCtrl.I.gameState.getGameSpriteGlobalPosition(param1,0,-50);
         if(_loc2_.x < 20)
         {
            _loc2_.x = 20;
         }
         if(_loc2_.x > GameConfig.GAME_SIZE.x - 20)
         {
            _loc2_.x = GameConfig.GAME_SIZE.x - 20;
         }
         if(_loc2_.y < 60)
         {
            _loc2_.y = 60;
         }
         if(_loc2_.y > GameConfig.GAME_SIZE.y - 5)
         {
            _loc2_.x = GameConfig.GAME_SIZE.x - 5;
         }
         return _loc2_;
      }
   }
}

