package net.play5d.game.bvn.ctrl.game_ctrls
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.ui.*;
   
   public class GameEndCtrl
   {
      
      private var _winner:FighterMain;
      
      private var _loser:FighterMain;
      
      private var _step:int;
      
      private var _isRender:Boolean;
      
      private var _holdFrame:int;
      
      private var _drawGame:Boolean;
      
      public function GameEndCtrl()
      {
         super();
      }
      
      public function initlize(param1:FighterMain, param2:FighterMain) : void
      {
         GameCtrl.I.gameRunData.setAllowLoseHP(false);
         this._winner = param1;
         this._loser = param2;
         this._step = 0;
         this._isRender = true;
      }
      
      public function drawGame() : void
      {
         GameCtrl.I.gameRunData.setAllowLoseHP(false);
         this._drawGame = true;
         this._step = 0;
         this._isRender = true;
      }
      
      public function destory() : void
      {
         this._winner = null;
         this._loser = null;
      }
      
      public function render() : Boolean
      {
         if(!this._isRender)
         {
            return false;
         }
         if(this._holdFrame-- > 0)
         {
            return false;
         }
         if(this._drawGame)
         {
            return this.renderDrawGame();
         }
         return this.renderEND();
      }
      
      private function renderDrawGame() : Boolean
      {
         switch(this._step)
         {
            case 0:
               GameUI.I.getUI().showEnd(function():void
               {
                  _holdFrame = 0;
               },{"drawGame":true});
               this._step = 1;
               this._holdFrame = 10 * GameConfig.FPS_GAME;
               break;
            case 1:
               this._isRender = false;
               GameUI.I.getUI().clearStartAndEnd();
               return true;
         }
         return false;
      }
      
      private function renderEND() : Boolean
      {
         var rundata:GameRunDataVO = null;
         var winner:FighterMain = null;
         var timeRate:Number = NaN;
         var addHPMax:int = 0;
         var addHP:int = 0;
         switch(this._step)
         {
            case 0:
               GameUI.I.getUI().showEnd(function():void
               {
                  _holdFrame = 0;
               },{
                  "winner":this._winner,
                  "loser":this._loser
               });
               this._step = 1;
               this._holdFrame = 10 * GameConfig.FPS_GAME;
               break;
            case 1:
               if(!FighterActionState.isAllowWinState(this._winner.actionState))
               {
                  return false;
               }
               this._winner.win();
               this._holdFrame = 3 * GameConfig.FPS_GAME;
               this._step = 2;
               rundata = GameCtrl.I.gameRunData;
               winner = rundata.lastWinner;
               if(Boolean(GameMode.isTeamMode()) || GameMode.currentMode == 30)
               {
                  timeRate = rundata.gameTime == -1 ? 1 : rundata.gameTime / rundata.gameTimeMax;
                  addHPMax = winner.hpMax * 0.2;
                  addHP = addHPMax * timeRate;
                  if(addHP < winner.hpMax * 0.05)
                  {
                     addHP = winner.hpMax * 0.05;
                  }
                  winner.hp += addHP;
               }
               rundata.lastWinnerHp = winner.hp;
               break;
            case 2:
               this._step = 22;
               this._winner = null;
               this._loser = null;
               StateCtrl.I.transIn(function():void
               {
                  _step = 3;
               },false);
               break;
            case 3:
               this._isRender = false;
               GameUI.I.getUI().clearStartAndEnd();
               GameUI.I.getUI().fadOut(false);
               return true;
         }
         return false;
      }
      
      public function skip() : void
      {
         if(this._step == 2)
         {
            this._holdFrame = 0;
         }
      }
   }
}

