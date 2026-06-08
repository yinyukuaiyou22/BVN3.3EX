package net.play5d.game.bvn.ctrl.game_ctrls
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.state.GameState;
   
   public class GameStartCtrl
   {
      
      private var _state:GameState;
      
      private var _p1:FighterMain;
      
      private var _p2:FighterMain;
      
      private var _isStart1v1:Boolean;
      
      private var _isStartNextRound:Boolean;
      
      private var _step:int;
      
      private var _holdFrame:int;
      
      private var _uiPlaying:Boolean;
      
      private var _introTeamId:int = -1;
      
      public function GameStartCtrl(param1:GameState)
      {
         super();
         this._state = param1;
      }
      
      public function destory() : void
      {
         this._p1 = null;
         this._p2 = null;
         this._state = null;
      }
      
      public function render() : Boolean
      {
         if(this._isStart1v1)
         {
            return this.renderStart1v1();
         }
         if(this._isStartNextRound)
         {
            return this.renderNextRound();
         }
         return false;
      }
      
      public function start1v1(param1:FighterMain, param2:FighterMain, param3:int = -1) : void
      {
         this._p1 = param1;
         this._p2 = param2;
         this._isStart1v1 = true;
         this._introTeamId = param3;
         switch(param3 - 1)
         {
            case 0:
               SoundCtrl.I.playFightBGM(param1.data.id);
               break;
            case 1:
               SoundCtrl.I.playFightBGM(param2.data.id);
               break;
            default:
               SoundCtrl.I.playFightBGM(param2.data.id);
         }
         this.preRenderStart();
      }
      
      private function preRenderStart() : void
      {
         var initStep:int = 0;
         this._step = -1;
         initStep = 0;
         switch(this._introTeamId - -1)
         {
            case 0:
               initStep = 0;
               break;
            case 2:
               this._state.cameraFocusOne(this._p1.getDisplay());
               initStep = 1;
               break;
            case 3:
               this._state.cameraFocusOne(this._p2.getDisplay());
               initStep = 2;
         }
         this._state.camera.updateNow();
         StateCtrl.I.transOut(function():void
         {
            _step = initStep;
         },true);
      }
      
      private function renderStart1v1() : Boolean
      {
         if(this._uiPlaying)
         {
            return false;
         }
         if(this._p1.actionState == 60 || this._p2.actionState == 60)
         {
            return false;
         }
         if(this._holdFrame-- > 0)
         {
            return false;
         }
         switch(this._step)
         {
            case 0:
               if(this._introTeamId == -1 || this._introTeamId == 1)
               {
                  this._state.cameraFocusOne(this._p1.getDisplay());
                  this._holdFrame = 0.5 * GameConfig.FPS_GAME;
                  this._step = 1;
               }
               else
               {
                  this._step = 2;
               }
               break;
            case 1:
               this._p1.sayIntro();
               this._holdFrame = 0.3 * GameConfig.FPS_GAME;
               this._step = 2;
               break;
            case 2:
               if(this._introTeamId == -1 || this._introTeamId == 2)
               {
                  this._state.cameraFocusOne(this._p2.getDisplay());
                  this._holdFrame = 0.5 * GameConfig.FPS_GAME;
                  this._step = 3;
               }
               else
               {
                  this._step = 4;
               }
               break;
            case 3:
               this._p2.sayIntro();
               this._holdFrame = 0.3 * GameConfig.FPS_GAME;
               this._step = 4;
               break;
            case 4:
               this._state.cameraResume();
               this._holdFrame = 0.1 * GameConfig.FPS_GAME;
               this._step = 5;
               break;
            case 5:
               this._uiPlaying = true;
               this._state.gameUI.getUI().showStart(function():void
               {
                  _uiPlaying = false;
               });
               this._step = 6;
               break;
            case 6:
               this._p1 = null;
               this._p2 = null;
               return true;
         }
         return false;
      }
      
      public function startNextRound() : void
      {
         this._isStartNextRound = true;
         this._uiPlaying = true;
         StateCtrl.I.transOut(null,true);
         this._state.gameUI.getUI().showStart(function():void
         {
            _uiPlaying = false;
         });
      }
      
      public function skip() : void
      {
         if(this._isStart1v1)
         {
            if(this._step < 5)
            {
               StateCtrl.I.quickTrans();
               this._state.cameraResume();
               this._uiPlaying = false;
               this._step = 6;
               this._state.gameUI.getUI().fadIn(true);
               this._p1.idle();
               this._p2.idle();
               this._holdFrame = 0.5 * GameConfig.FPS_GAME;
            }
         }
         if(!this._isStartNextRound)
         {
         }
      }
      
      private function renderNextRound() : Boolean
      {
         return this._uiPlaying == false;
      }
   }
}

