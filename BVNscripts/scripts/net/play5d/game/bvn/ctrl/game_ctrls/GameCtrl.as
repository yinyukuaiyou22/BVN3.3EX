package net.play5d.game.bvn.ctrl.game_ctrls
{
   import flash.events.*;
   import flash.geom.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.ctrler.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.state.GameState;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
import net.play5d.game.bvn.Debugger;
   
   public class GameCtrl
   {
      
      private static var _i:GameCtrl;
      
      public var gameState:GameState;
      
      public const gameRunData:GameRunDataVO = new GameRunDataVO();
      
      public var actionEnable:Boolean = false;
      
      public var autoStartAble:Boolean = true;
      
      public var autoEndRoundAble:Boolean = true;
      
      private var _teamMap:TeamMap = new TeamMap();
      
      private var _startCtrl:GameStartCtrl;
      
      private var _fighterEventCtrl:FighterEventCtrl;
      
      private var _trainingCtrl:TrainingCtrler;
      
      private var _mainLogicCtrl:GameMainLogicCtrler;
      
      private var _endCtrl:GameEndCtrl;
      
      private var _isRenderGame:Boolean = true;
      
      private var _isPauseGame:Boolean;
      
      private var _gameRunning:Boolean;
      
      private var _renderTimeFrame:int;
      
      private var _renderAnimateGap:int = 0;
      
      private var _renderAnimateFrame:int = 0;
      
      public var fightFinished:Boolean;
      
      private var _gameStartAndPause:Boolean;
      
      public function GameCtrl()
      {
         super();
      }
      
      public static function get I() : GameCtrl
      {
         if(!_i)
         {
            _i = new GameCtrl();
         }
         return _i;
      }
      
      public function getAttacker(param1:String, param2:int) : FighterAttacker
      {
         return this._fighterEventCtrl.getAttacker(param1,param2);
      }
      
      public function setRenderHit(param1:Boolean) : void
      {
         if(Boolean(this._mainLogicCtrl))
         {
            this._mainLogicCtrl.renderHit = param1;
         }
      }
      
      public function initlize(param1:GameState) : void
      {
         this.gameState = param1;
         this._isPauseGame = false;
         this._isRenderGame = true;
         this._gameRunning = true;
         this._gameStartAndPause = false;
         this._fighterEventCtrl = new FighterEventCtrl();
         this._fighterEventCtrl.initlize();
         this._renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / 30) - 1;
         KeyBoarder.focus();
      }
      
      private function renderPause() : void
      {
         if(Boolean(this._startCtrl) || Boolean(this._endCtrl))
         {
            if(Boolean(GameInputer.back(1)) || Boolean(GameInputer.select("MENU",1)))
            {
               if(Boolean(this._startCtrl))
               {
                  this._startCtrl.skip();
               }
               if(Boolean(this._endCtrl))
               {
                  this._endCtrl.skip();
               }
            }
            return;
         }
         if(GameInputer.back(1))
         {
            if(this._isPauseGame)
            {
               this.resume(true);
            }
            else
            {
               this.pause(true);
            }
         }
      }
      
      public function destory() : void
      {
         GameRender.remove(this.render);
         GameLogic.clear();
         GameInputer.clearInput();
         if(Boolean(this._fighterEventCtrl))
         {
            this._fighterEventCtrl.destory();
            this._fighterEventCtrl = null;
         }
         if(Boolean(this._mainLogicCtrl))
         {
            this._mainLogicCtrl.destory();
            this._mainLogicCtrl = null;
         }
         if(Boolean(this._trainingCtrl))
         {
            this._trainingCtrl.destory();
            this._trainingCtrl = null;
         }
         if(Boolean(this._startCtrl))
         {
            this._startCtrl.destory();
            this._startCtrl = null;
         }
         if(Boolean(this._endCtrl))
         {
            this._endCtrl.destory();
            this._endCtrl = null;
         }
         if(Boolean(this.gameState))
         {
            this.gameState = null;
         }
         this.gameRunData.p1FighterGroup.destoryFighters(this.gameRunData.continueLoser);
         this.gameRunData.p2FighterGroup.destoryFighters(null);
         if(this.gameRunData.continueLoser == null)
         {
            this.gameRunData.clear();
            GameLoader.dispose();
         }
         this._gameRunning = false;
      }
      
      public function getEnemyTeam(param1:IGameSprite) : TeamVO
      {
         if(Boolean(param1.team))
         {
            switch(int(param1.team.id) - 1)
            {
               case 0:
                  return this._teamMap.getTeam(2);
               case 1:
                  return this._teamMap.getTeam(1);
            }
         }
         return null;
      }
      
      public function addGameSprite(param1:int, param2:IGameSprite, param3:int = -1) : void
      {
         var _loc4_:TeamVO = null;
         if(param3 != -1)
         {
            this.gameState.addGameSpriteAt(param2,param3);
         }
         else
         {
            this.gameState.addGameSprite(param2);
         }
         _loc4_ = this._teamMap.getTeam(param1);
         if(Boolean(_loc4_))
         {
            param2.team = _loc4_;
            _loc4_.addChild(param2);
            if(param2 is FighterMain)
            {
               (param2 as FighterMain).targetTeams = this._teamMap.getOtherTeams(param1);
            }
         }
         else
         {
            Debugger.log("GameCtrl.addGameSprite :: team is null!");
         }
      }
      
      public function removeGameSprite(param1:IGameSprite, param2:Boolean = false) : void
      {
         this.gameState.removeGameSprite(param1);
         var _loc3_:TeamVO = param1.team;
         if(Boolean(_loc3_))
         {
            _loc3_.removeChild(param1);
         }
         param1.destory(param2);
      }
      
      public function startGame() : void
      {
         if(!this.autoStartAble)
         {
            return;
         }
         this.fightFinished = false;
         this.doStartGame();
      }
      
      public function doStartGame() : void
      {
         this._isPauseGame = false;
         GameInputer.enabled = true;
         this.gameRunData.reset();
         this.initTeam();
         this.buildGame();
         GameEvent.dispatchEvent("GAME_START");
         GameRender.add(this.render);
      }
      
      private function buildGame() : void
      {
         var _loc1_:* = null;
         var _loc2_:FighterMain = this.gameRunData.p1FighterGroup.currentFighter;
         var _loc3_:FighterMain = this.gameRunData.p2FighterGroup.currentFighter;
         if(GameMode.currentMode == 40)
         {
            this._trainingCtrl = new TrainingCtrler();
            this._trainingCtrl.initlize([_loc2_,_loc3_]);
            this.gameRunData.gameTimeMax = -1;
         }
         var _loc4_:MapMain = this.gameRunData.map;
         if(!_loc2_ || !_loc3_ || !_loc4_)
         {
            throw new Error("创建游戏失败");
         }
         if(_loc2_.data.id == _loc3_.data.id)
         {
            _loc1_ = new ColorTransform();
            _loc1_.greenOffset = -85;
            _loc3_.colorTransform = _loc1_;
         }
         else
         {
            _loc3_.colorTransform = null;
         }
         this.addFighter(_loc2_,1);
         this.addFighter(_loc3_,2);
         // 2v2/1v2：额外 fighter 同时上场（最小原型）
         if (GameMode.isDuoMode()) {
            var _p1f2:FighterMain = this.gameRunData.p1FighterGroup.fighter2;
            var _p2f2:FighterMain = this.gameRunData.p2FighterGroup.fighter2;
            if (_p1f2) { this.addFighter(_p1f2, 1); _p1f2.x += 30; }
            if (_p2f2) { this.addFighter(_p2f2, 2); _p2f2.x -= 30; }
         } else if (GameMode.is1v2Mode()) {
            var _p2f2_1v2:FighterMain = this.gameRunData.p2FighterGroup.fighter2;
            if (_p2f2_1v2) { this.addFighter(_p2f2_1v2, 2); _p2f2_1v2.x -= 30; }
         }
         _loc4_.initlize();
         this.gameState.initFight(this.gameRunData.p1FighterGroup,this.gameRunData.p2FighterGroup,_loc4_);
         GameLogic.initGameLogic(_loc4_,this.gameState.camera);
         this._mainLogicCtrl = new GameMainLogicCtrler();
         this._mainLogicCtrl.initlize(this.gameState,this._teamMap,_loc4_);
         if(GameMode.currentMode == 40 && !TrainingCtrler.SAY_INTRO)
         {
            // 训练模式跳过开场动画，直接开打
            this.actionEnable = true;
            GameUI.I.fadIn();
            SoundCtrl.I.playFightBGM("map");
         }
         else
         {
            // 正常模式 / 训练中手动开启开场 → 播放开场动画
            this._startCtrl = new GameStartCtrl(this.gameState);
            this.actionEnable = false;
            this._startCtrl.start1v1(_loc2_,_loc3_);
         }
         GameInterface.instance.afterBuildGame();
      }
      
      private function addFighter(param1:FighterMain, param2:int) : void
      {
         var _loc3_:* = null;
         if(!param1)
         {
            return;
         }
         switch(int(param2) - 1)
         {
            case 0:
               if(GameMode.isWatch(false))
               {
                  _loc3_ = new FighterAICtrl();
                  (_loc3_ as FighterAICtrl).AILevel = MessionModel.I.AI_LEVEL;
                  (_loc3_ as FighterAICtrl).fighter = param1;
                  break;
               }
               _loc3_ = new FighterKeyCtrl();
               (_loc3_ as FighterKeyCtrl).inputType = "P1";
               (_loc3_ as FighterKeyCtrl).classicMode = GameData.I.config.keyInputMode == 1;
               break;
            case 1:
               if(Boolean(GameMode.isVsCPU(false)) || Boolean(GameMode.isWatch(false)) || Boolean(GameMode.isAcrade()))
               {
                  _loc3_ = new FighterAICtrl();
                  (_loc3_ as FighterAICtrl).AILevel = MessionModel.I.AI_LEVEL;
                  (_loc3_ as FighterAICtrl).fighter = param1;
                  break;
               }
               _loc3_ = new FighterKeyCtrl();
               (_loc3_ as FighterKeyCtrl).inputType = "P2";
               (_loc3_ as FighterKeyCtrl).classicMode = GameData.I.config.keyInputMode == 1;
         }
         param1.initlize();
         if(param1.initFailed)
         {
            Debugger.log("[GameCtrl] addFighter FAILED — 此角色不可用: " + param1.data.id);
            GameUI.confrim("此角色暂时不可用","该角色文件不完整，请选择其他角色。",MainGame.I.goMenu);
            return;
         }
         param1.setActionCtrl(_loc3_);
         this.addGameSprite(param2,param1);
      }
      
      private function removeFighter(param1:FighterMain) : void
      {
         if(!param1)
         {
            return;
         }
         this.removeGameSprite(param1);
      }
      
      public function startNextRound() : void
      {
         this.doBuildNextRound(GameMode.isTeamMode());
      }
      
      private function buildNextRound(param1:Boolean) : void
      {
         this.doBuildNextRound(param1);
      }
      
      private function doBuildNextRound(param1:Boolean) : void
      {
         // 训练模式跳过所有跨轮开场
         if(GameMode.currentMode == 40 && !TrainingCtrler.SAY_INTRO)
         {
            this.actionEnable = true;
            return;
         }
         var _loc2_:* = 0;
         this.gameState.resetFight(this.gameRunData.p1FighterGroup,this.gameRunData.p2FighterGroup);
         this._startCtrl = new GameStartCtrl(this.gameState);
         if(param1)
         {
            if(Boolean(this.gameRunData.lastWinner))
            {
               this.gameRunData.lastWinner.hp = this.gameRunData.lastWinnerHp;
            }
            _loc2_ = -1;
            if(Boolean(this.gameRunData.lastWinnerTeam))
            {
               _loc2_ = this.gameRunData.lastWinnerTeam.id == 1 ? 2 : 1;
            }
            this._startCtrl.start1v1(this.gameRunData.p1FighterGroup.currentFighter,this.gameRunData.p2FighterGroup.currentFighter,_loc2_);
         }
         else
         {
            this._startCtrl.startNextRound();
         }
         this.gameRunData.isDrawGame = false;
         GameEvent.dispatchEvent("ROUND_START");
      }
      
      public function fightFinish() : void
      {
         this.fightFinished = true;
         if(GameMode.isAcrade())
         {
            if(this.gameRunData.lastWinnerTeam.id == 1)
            {
               if(MessionModel.I.missionAllComplete())
               {
                  Debugger.log("通关！");
                  MainGame.I.goCongratulations();
               }
               else
               {
                  Debugger.log("下一关");
                  GameData.I.winnerId = this.gameRunData.p1FighterGroup.currentFighter.data.id;
                  MainGame.I.goWinner();
               }
            }
            else
            {
               Debugger.log("跳转是否继续");
               this.gameRunData.continueLoser = this.gameRunData.p1FighterGroup.currentFighter;
               MainGame.I.goContinue();
            }
         }
         if(Boolean(GameMode.isVsCPU()) || Boolean(GameMode.isVsPeople()))
         {
            Debugger.log("返回选人");
            GameEvent.dispatchEvent("GAME_END");
            MainGame.I.goSelect();
         }
      }
      
      private function initTeam() : void
      {
         var _loc1_:* = undefined;
         this._teamMap.clear();
         var _loc2_:Array = GameMode.getTeams();
         for each(_loc1_ in _loc2_)
         {
            this._teamMap.add(new TeamVO(_loc1_.id,_loc1_.name));
         }
      }
      
      public function pause(param1:Boolean = false) : void
      {
         if(!this._gameRunning)
         {
            return;
         }
         if(param1 && !this._isPauseGame)
         {
            if(Boolean(this._startCtrl) || Boolean(this._endCtrl))
            {
               this._gameStartAndPause = true;
               return;
            }
            GameEvent.dispatchEvent("PAUSE_GAME");
            this._isPauseGame = true;
            GameUI.I.getUI().pause();
            MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["game_pause"])));
         }
         this._isRenderGame = false;
      }
      
      public function resume(param1:Boolean = false) : void
      {
         if(!this._gameRunning)
         {
            return;
         }
         this._gameStartAndPause = false;
         if(param1 && Boolean(this._isPauseGame))
         {
            GameEvent.dispatchEvent("RESUME_GAME");
            this._isPauseGame = false;
            GameUI.I.getUI().resume();
            MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["game_resume"])));
         }
         KeyBoarder.focus();
         this._isRenderGame = true;
      }
      
      public function gameEnd(param1:FighterMain, param2:FighterMain) : void
      {
         if(!this.autoEndRoundAble)
         {
            return;
         }
         if(Boolean(this._endCtrl))
         {
            return;
         }
         this.doGameEnd(param1,param2);
      }
      
      public function doGameEnd(param1:FighterMain, param2:FighterMain) : void
      {
         this.gameRunData.lastWinnerTeam = param1.team;
         this.gameRunData.lastWinner = param1;
         this.gameRunData.lastLoserData = param2.data;
         this.gameRunData.lastLoserQi = param2.qi;
         switch(int(param1.team.id) - 1)
         {
            case 0:
               ++this.gameRunData.p1Wins;
               if(param2.hp <= 0 && Boolean(GameMode.isAcrade()))
               {
                  GameLogic.addScoreByKO();
               }
               break;
            case 1:
               ++this.gameRunData.p2Wins;
         }
         this._endCtrl = new GameEndCtrl();
         this._endCtrl.initlize(param1,param2);
         this.actionEnable = false;
         GameEvent.dispatchEvent("ROUND_END");
      }
      
      private function render() : void
      {
         var _loc1_:Boolean = false;
         var _loc2_:Boolean = false;
         this.renderPause();
         if(this._isPauseGame)
         {
            return;
         }
         EffectCtrl.I.render();
         this.gameState.render();
         if(!this._isRenderGame)
         {
            return;
         }
         this.checkRenderAnimate();
         if(Boolean(this._mainLogicCtrl))
         {
            this._mainLogicCtrl.render();
         }
         if(Boolean(this._startCtrl))
         {
            this.actionEnable = false;
            _loc1_ = Boolean(this._startCtrl.render());
            if(_loc1_)
            {
               this._startCtrl.destory();
               this._startCtrl = null;
               this.actionEnable = true;
               this.gameRunData.setAllowLoseHP(true);
               if(this._gameStartAndPause)
               {
                  this.pause(true);
                  this._gameStartAndPause = false;
               }
            }
         }
         if(Boolean(this._endCtrl))
         {
            _loc2_ = Boolean(this._endCtrl.render());
            if(_loc2_)
            {
               this._endCtrl.destory();
               this._endCtrl = null;
               this.runNext();
            }
         }
         if(Boolean(this._trainingCtrl))
         {
            this._trainingCtrl.render();
         }
      }
      
      private function checkRenderAnimate() : void
      {
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
         if(Boolean(this._mainLogicCtrl))
         {
            this._mainLogicCtrl.renderAnimate();
         }
         if(this.actionEnable && !this._startCtrl && !this._endCtrl)
         {
            this.renderGameTime();
         }
      }
      
      private function renderGameTime() : void
      {
         if(this.gameRunData.gameTimeMax != -1)
         {
            if(++this._renderTimeFrame > 30)
            {
               this._renderTimeFrame = 0;
               --this.gameRunData.gameTime;
               if(this.gameRunData.gameTime <= 0)
               {
                  this.timeover();
               }
            }
         }
      }
      
      private function timeover() : void
      {
         Debugger.log("time over!!!");
         this.actionEnable = false;
         var _loc1_:FighterMain = this.gameRunData.p1FighterGroup.currentFighter;
         var _loc2_:FighterMain = this.gameRunData.p2FighterGroup.currentFighter;
         this.gameRunData.isTimerOver = true;
         if(_loc1_.hp == _loc2_.hp)
         {
            this.drawGame();
            return;
         }
         if(_loc1_.hp > _loc2_.hp)
         {
            this.gameEnd(_loc1_,_loc2_);
         }
         else
         {
            this.gameEnd(_loc2_,_loc1_);
         }
      }
      
      public function drawGame() : void
      {
         if(Boolean(this._endCtrl))
         {
            return;
         }
         this.gameRunData.lastWinnerTeam = null;
         this.gameRunData.lastWinner = null;
         this.gameRunData.isDrawGame = true;
         this._endCtrl = new GameEndCtrl();
         this._endCtrl.drawGame();
         this.actionEnable = false;
      }
      
      private function runNext() : void
      {
         Debugger.log("GameMode.currentMode",GameMode.currentMode);
         this.gameRunData.nextRound();
         if(GameMode.isTeamMode())
         {
            if(this.startNextTeamFight())
            {
               this.buildNextRound(true);
               this.gameRunData.lastWinner = null;
               return;
            }
         }
         if(GameMode.isSingleMode())
         {
            if(this.gameRunData.p1Wins < 2 && this.gameRunData.p2Wins < 2)
            {
               this.buildNextRound(false);
               this.gameRunData.lastWinner = null;
               return;
            }
         }
         this.fightFinish();
      }
      
      private function startNextTeamFight() : Boolean
      {
         var _loc1_:* = null;
         var _loc2_:* = null;
         if(this.gameRunData.isDrawGame)
         {
            _loc1_ = this.gameRunData.p1FighterGroup.getNextFighter();
            _loc2_ = this.gameRunData.p2FighterGroup.getNextFighter();
            if(!_loc1_ && !_loc2_)
            {
               return true;
            }
            if(Boolean(_loc1_) && !_loc2_)
            {
               this.gameRunData.lastWinnerTeam = this.gameRunData.p1FighterGroup.currentFighter.team;
               return false;
            }
            if(!_loc1_ && Boolean(_loc2_))
            {
               this.gameRunData.lastWinnerTeam = this.gameRunData.p2FighterGroup.currentFighter.team;
               return false;
            }
            this.nextFighter(this.gameRunData.p1FighterGroup);
            this.nextFighter(this.gameRunData.p2FighterGroup);
            return true;
         }
         switch(int(this.gameRunData.lastWinnerTeam.id) - 1)
         {
            case 0:
               return this.nextFighter(this.gameRunData.p2FighterGroup);
            case 1:
               return this.nextFighter(this.gameRunData.p1FighterGroup);
            default:
               this.gameRunData.lastWinnerTeam = null;
               return true;
         }
      }
      
      private function nextFighter(param1:GameRunFighterGroup) : Boolean
      {
         if(!param1)
         {
            return false;
         }
         var _loc2_:TeamVO = param1.currentFighter.team;
         var _loc3_:FighterMain = param1.getNextFighter();
         if(!_loc3_)
         {
            return false;
         }
         if(Boolean(this.gameRunData.lastLoserData))
         {
            if(this.gameRunData.lastLoserData.comicType == _loc3_.data.comicType)
            {
               _loc3_.qi = this.gameRunData.lastLoserQi + 100;
               if(_loc3_.qi > 300)
               {
                  _loc3_.qi = 300;
               }
            }
         }
         this.removeFighter(param1.currentFighter);
         param1.removeCurrentFighter();
         param1.currentFighter = _loc3_;
         this.addFighter(param1.currentFighter,_loc2_.id);
         return true;
      }
      
      public function slow(param1:Number) : void
      {
         var _loc2_:Number = 30 / param1;
         this.setAnimateFPS(_loc2_);
         this._mainLogicCtrl.setSpeedPlus(GameConfig.SPEED_PLUS_DEFAULT / param1);
         this.gameState.camera.tweenSpd = 2.5 * param1;
      }
      
      public function slowResume() : void
      {
         this.setAnimateFPS(30);
         this._mainLogicCtrl.setSpeedPlus(GameConfig.SPEED_PLUS_DEFAULT);
         this.gameState.camera.tweenSpd = 2.5;
      }
      
      public function setFighterActionCtrl(param1:FighterMain, param2:int, param3:Boolean = false) : void
      {
         var _loc4_:* = null;
         if(!param1)
         {
            return;
         }
         if(param3 || Boolean(GameMode.isWatch()) || param2 == 2 && (Boolean(GameMode.isVsCPU(false)) || Boolean(GameMode.isAcrade())))
         {
            _loc4_ = new FighterAICtrl();
            (_loc4_ as FighterAICtrl).AILevel = MessionModel.I.AI_LEVEL;
            (_loc4_ as FighterAICtrl).fighter = param1;
         }
         else
         {
            _loc4_ = new FighterKeyCtrl();
            (_loc4_ as FighterKeyCtrl).inputType = param2 == 1 ? "P1" : "P2";
            (_loc4_ as FighterKeyCtrl).classicMode = GameData.I.config.keyInputMode == 1;
         }
         param1.setActionCtrl(_loc4_);
      }
      
      public function toggleFighterAI(param1:FighterMain, param2:int, param3:Boolean) : void
      {
         var _loc4_:* = null;
         if(!param1)
         {
            return;
         }
         if(param3)
         {
            _loc4_ = new FighterAICtrl();
            (_loc4_ as FighterAICtrl).AILevel = MessionModel.I.AI_LEVEL;
            (_loc4_ as FighterAICtrl).fighter = param1;
         }
         else
         {
            _loc4_ = new FighterKeyCtrl();
            (_loc4_ as FighterKeyCtrl).inputType = param2 == 1 ? "P1" : "P2";
            (_loc4_ as FighterKeyCtrl).classicMode = GameData.I.config.keyInputMode == 1;
         }
         param1.setActionCtrl(_loc4_);
      }
      
      private function setAnimateFPS(param1:Number) : void
      {
         this._renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / param1) - 1;
         this._renderAnimateFrame = 0;
      }
   }
}

