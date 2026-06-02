package net.play5d.game.bvn.ctrl.game_ctrls
{
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.ctrl.StateCtrl;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.stage.GameStage;
   import net.play5d.game.bvn.ui.GameUI;
   
   public class GameStartCtrl
   {
      
      private var _state:GameStage;
      
      private var _p1:FighterMain;
      
      private var _p2:FighterMain;
      
      private var _isStart1v1:Boolean;
      
      private var _isStartNextRound:Boolean;
      
      private var _isStartMosou:Boolean;
      
      private var _step:int;
      
      private var _holdFrame:int;
      
      private var _uiPlaying:Boolean;
      
      private var _introTeamId:int = -1;
      
      private var _mousouFinish:Boolean = false;
      
      public function GameStartCtrl(param1:GameStage)
      {
         super();
         _state = param1;
      }
      
      public function destory() : void
      {
         _p1 = null;
         _p2 = null;
         _state = null;
      }
      
      public function render() : Boolean
      {
         if(_isStart1v1)
         {
            return renderStart1v1();
         }
         if(_isStartNextRound)
         {
            return renderNextRound();
         }
         if(_isStartMosou)
         {
            return renderStartMosou();
         }
         return false;
      }
      
      private function renderStartMosou() : Boolean
      {
         return _mousouFinish;
      }
      
      public function start1v1(param1:FighterMain, param2:FighterMain, param3:int = -1) : void
      {
         _p1 = param1;
         _p2 = param2;
         _isStart1v1 = true;
         _introTeamId = param3;
         switch(param3 - 1)
         {
            case 0:
               SoundCtrl.I.smartPlayGameBGM(param1.data.id);
               break;
            case 1:
               SoundCtrl.I.smartPlayGameBGM(param2.data.id);
               break;
            default:
               SoundCtrl.I.smartPlayGameBGM(Math.random() > 0.5 ? param1.data.id : param2.data.id);
         }
         preRenderStart();
      }
      
      public function startMosou() : void
      {
         _isStartMosou = true;
         _mousouFinish = false;
         GameUI.I.getUI().showStart(function():void
         {
            _mousouFinish = true;
         });
      }
      
      private function preRenderStart() : void
      {
         _step = -1;
         var initStep:int = 0;
         switch(_introTeamId - -1)
         {
            case 0:
               initStep = 0;
               break;
            case 2:
               _state.cameraFocusOne(_p1.getDisplay());
               initStep = 0;
               break;
            case 3:
               _state.cameraFocusOne(_p2.getDisplay());
               initStep = 0;
         }
         _state.camera.updateNow();
         StateCtrl.I.transOut(function():void
         {
            _step = initStep;
            if(GameData.I.config.isSkipStart)
            {
               _step = 5;
            }
         },true);
      }
      
      private function renderStart1v1() : Boolean
      {
         var p2Prior:Boolean;
         var equalPrior:Boolean;
         var onlyOnce:Boolean;
         var p1Prior:Boolean;
         if(_uiPlaying)
         {
            return false;
         }
         if(_p1.actionState == 60 || _p2.actionState == 60)
         {
            return false;
         }
         if(_holdFrame-- > 0)
         {
            return false;
         }
         p1Prior = false;
         p2Prior = false;
         equalPrior = false;
         onlyOnce = false;
         if(_introTeamId == -1)
         {
            if(_p1.introPrior && !_p2.introPrior)
            {
               p1Prior = true;
            }
            if(!_p1.introPrior && _p2.introPrior)
            {
               p2Prior = true;
            }
            if(_p1.introPrior && _p2.introPrior)
            {
               equalPrior = true;
               onlyOnce = true;
            }
            if(!_p1.introPrior && !_p2.introPrior)
            {
               p1Prior = true;
            }
         }
         if(_introTeamId == 1)
         {
            p1Prior = true;
            onlyOnce = true;
         }
         if(_introTeamId == 2)
         {
            p2Prior = true;
            onlyOnce = true;
         }
         switch(_step)
         {
            case 0:
               if(equalPrior)
               {
                  _holdFrame = 0.5 * GameConfig.FPS_GAME;
                  _step = 1;
                  break;
               }
               if(p1Prior)
               {
                  _state.cameraFocusOne(_p1.getDisplay());
                  _holdFrame = 0.5 * GameConfig.FPS_GAME;
                  _step = 1;
                  break;
               }
               if(p2Prior)
               {
                  _state.cameraFocusOne(_p2.getDisplay());
                  _holdFrame = 0.5 * GameConfig.FPS_GAME;
                  _step = 1;
                  break;
               }
               _step = 2;
               break;
            case 1:
               if(equalPrior)
               {
                  _p1.sayIntro();
                  _p2.sayIntro();
               }
               if(p1Prior)
               {
                  _p1.sayIntro();
               }
               if(p2Prior)
               {
                  _p2.sayIntro();
               }
               _holdFrame = 0.3 * GameConfig.FPS_GAME;
               _step = 2;
               break;
            case 2:
               if(onlyOnce)
               {
                  _step = 4;
                  break;
               }
               if(p1Prior)
               {
                  _state.cameraFocusOne(_p2.getDisplay());
                  _holdFrame = 0.5 * GameConfig.FPS_GAME;
                  _step = 3;
                  break;
               }
               if(p2Prior)
               {
                  _state.cameraFocusOne(_p1.getDisplay());
                  _holdFrame = 0.5 * GameConfig.FPS_GAME;
                  _step = 3;
                  break;
               }
               _step = 4;
               break;
            case 3:
               if(p1Prior)
               {
                  _p2.sayIntro();
               }
               if(p2Prior)
               {
                  _p1.sayIntro();
               }
               _holdFrame = 0.3 * GameConfig.FPS_GAME;
               _step = 4;
               break;
            case 4:
               _state.cameraResume();
               _holdFrame = 0.1 * GameConfig.FPS_GAME;
               _step = 5;
               break;
            case 5:
               _state.cameraResume();
               _p1.idle();
               _p2.idle();
               _uiPlaying = true;
               _state.gameUI.getUI().showStart(function():void
               {
                  _uiPlaying = false;
               });
               _step = 6;
               break;
            case 6:
               _p1 = null;
               _p2 = null;
               return true;
         }
         return false;
      }
      
      public function startNextRound() : void
      {
         _isStartNextRound = true;
         _uiPlaying = true;
         StateCtrl.I.transOut(null,true);
         _state.gameUI.getUI().showStart(function():void
         {
            _uiPlaying = false;
         });
      }
      
      public function skip() : void
      {
         if(GameData.I.config.isSkipStart)
         {
            return;
         }
         if(_isStart1v1)
         {
            if(_step >= 0 && _step < 5)
            {
               _p1.idle();
               _p2.idle();
               _step = 5;
               _holdFrame = 0;
            }
         }
         if(_isStartNextRound)
         {
         }
      }
      
      private function renderNextRound() : Boolean
      {
         return _uiPlaying == false;
      }
   }
}

