package net.play5d.game.bvn.ctrl.game_ctrls
{
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.GameLoader;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.ctrl.mosou_ctrls.MosouCtrl;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.GameRunDataVO;
   import net.play5d.game.bvn.data.GameRunFighterGroup;
   import net.play5d.game.bvn.data.MessionModel;
   import net.play5d.game.bvn.data.TeamMap;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.factory.GameRunFactory;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterAttacker;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.ctrler.FighterAICtrl;
   import net.play5d.game.bvn.fighter.ctrler.FighterKeyCtrl;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.stage.GameStage;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.utils.KeyBoarder;
   import net.play5d.game.bvn.views.effects.BitmapFilterView;
   import net.play5d.game.bvn.win.input.JoyRumble;
   
   public class GameCtrl
   {
      
      private static var _i:GameCtrl;
      
      public var gameState:GameStage;
      
      public const gameRunData:GameRunDataVO = new GameRunDataVO();
      
      private var _actionEnable:Boolean = false;
      
      public var autoStartAble:Boolean = true;
      
      public var autoEndRoundAble:Boolean = true;
      
      private var _teamMap:TeamMap = new TeamMap();
      
      private var _startCtrl:GameStartCtrl;
      
      private var _fighterEventCtrl:FighterEventCtrl;
      
      private var _trainingCtrl:TrainingCtrler;
      
      private var _mainLogicCtrl:GameMainLogicCtrler;
      
      private var _endCtrl:GameEndCtrl;
      
      private var _mosouCtrl:MosouCtrl;
      
      private var _isRenderGame:Boolean = true;
      
      private var _isPauseGame:Boolean;
      
      private var _isGamePause:Boolean;
      
      private var _gameRunning:Boolean;
      
      private var _renderTimeFrame:int;
      
      private var _renderAnimateGap:int = 0;
      
      private var _renderAnimateFrame:int = 0;
      
      public var fightFinished:Boolean;
      
      private var _gameStartAndPause:Boolean;
      
      private var _isCountdown:Boolean;
      
      public var slowRate:Number = 0;
      
      private var _isDestoryed:Boolean;
      
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
      
      public static function onFighterDie(param1:FighterMain) : void
      {
         var _loc2_:FighterMain = null;
         var _loc4_:TeamVO = GameCtrl.I.getEnemyTeam(param1);
         if(_loc4_)
         {
            for each(var _loc3_ in _loc4_.children)
            {
               if(_loc3_ is FighterMain)
               {
                  _loc2_ = _loc3_ as FighterMain;
                  break;
               }
            }
         }
         GameCtrl.I.gameEnd(_loc2_,param1);
      }
      
      public function set actionEnable(param1:Boolean) : void
      {
         if(_actionEnable != param1)
         {
            gameRunData.setAllowLoseHP(param1);
         }
         _actionEnable = param1;
      }
      
      public function get actionEnable() : Boolean
      {
         return _actionEnable;
      }
      
      public function getAttacker(param1:String, param2:int) : FighterAttacker
      {
         if(_mosouCtrl)
         {
            return _mosouCtrl.getFighterEventCtrl().getAttacker(param1,param2);
         }
         return _fighterEventCtrl.getAttacker(param1,param2);
      }
      
      public function getAssister(param1:int) : Assister
      {
         if(_mosouCtrl != null)
         {
            return null;
         }
         return FighterEventCtrl.getAssister(param1);
      }
      
      public function setRenderHit(param1:Boolean) : void
      {
         if(_mainLogicCtrl)
         {
            _mainLogicCtrl.renderHit = param1;
         }
      }
      
      public function getMosouCtrl() : MosouCtrl
      {
         return _mosouCtrl;
      }
      
      public function getTeamMap() : TeamMap
      {
         return _teamMap;
      }
      
      public function getFighterByData(param1:FighterVO) : FighterMain
      {
         return this.gameState.getFighterByData(param1);
      }
      
      public function initlize(param1:GameStage) : void
      {
         _isDestoryed = false;
         this.gameState = param1;
         _isPauseGame = false;
         _isRenderGame = true;
         _gameRunning = true;
         _gameStartAndPause = false;
         _isCountdown = false;
         if(!_mosouCtrl)
         {
            _fighterEventCtrl = new FighterEventCtrl();
            _fighterEventCtrl.initialize();
         }
         _renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / 30) - 1;
         KeyBoarder.focus();
      }
      
      private function renderPause() : void
      {
         if(_startCtrl || _endCtrl)
         {
            if(GameInputer.back(1) || GameInputer.attack("P1",1) || GameInputer.attack("P2",1))
            {
               if(_startCtrl)
               {
                  _startCtrl.skip();
               }
               if(_endCtrl)
               {
                  _endCtrl.skip();
               }
            }
            return;
         }
         if(GameInputer.back(1))
         {
            if(GameUI.showingConfrim())
            {
               GameUI.cancelConfrim();
               return;
            }
            if(GameUI.showingAlert())
            {
               GameUI.closeAlert();
               return;
            }
            if(_isPauseGame)
            {
               resume(true);
            }
            else
            {
               pause(true);
            }
         }
      }
      
      public function destory() : void
      {
         if(_isDestoryed)
         {
            return;
         }
         _isDestoryed = true;
         GameRender.remove(render);
         GameLogic.clear();
         GameInputer.clearInput();
         if(_fighterEventCtrl)
         {
            _fighterEventCtrl.destory();
            _fighterEventCtrl = null;
         }
         if(_mainLogicCtrl)
         {
            _mainLogicCtrl.destory();
            _mainLogicCtrl = null;
         }
         if(_trainingCtrl)
         {
            _trainingCtrl.destory();
            _trainingCtrl = null;
         }
         if(_startCtrl)
         {
            _startCtrl.destory();
            _startCtrl = null;
         }
         if(_endCtrl)
         {
            _endCtrl.destory();
            _endCtrl = null;
         }
         if(gameState)
         {
            gameState = null;
         }
         if(_mosouCtrl)
         {
            _mosouCtrl.destory();
            _mosouCtrl = null;
         }
         gameRunData.p1FighterGroup.destory();
         gameRunData.p2FighterGroup.destory();
         gameRunData.clear();
         GameLoader.dispose();
         _gameRunning = false;
         GameConfig.IS_SINGLE_STEP = false;
      }
      
      public function getEnemyTeam(param1:IGameSprite) : TeamVO
      {
         if(param1.team)
         {
            switch(param1.team.id - 1)
            {
               case 0:
                  return _teamMap.getTeam(2);
               case 1:
                  return _teamMap.getTeam(1);
            }
         }
         return null;
      }
      
      public function addGameSprite(param1:int, param2:IGameSprite, param3:int = -1) : void
      {
         if(param3 != -1)
         {
            gameState.addGameSpriteAt(param2,param3);
         }
         else
         {
            gameState.addGameSprite(param2);
         }
         var _loc4_:TeamVO = _teamMap.getTeam(param1);
         if(_loc4_)
         {
            param2.team = _loc4_;
            _loc4_.addChild(param2);
            if(param2 is FighterMain)
            {
               (param2 as FighterMain).targetTeams = _teamMap.getOtherTeams(param1);
            }
         }
         else if(!(param2 is BitmapFilterView))
         {
            Debugger.log("GameCtrl.addGameSprite :: team is null!");
         }
      }
      
      public function removeGameSprite(param1:IGameSprite, param2:Boolean = false) : void
      {
         gameState.removeGameSprite(param1);
         var _loc3_:TeamVO = param1.team;
         if(_loc3_)
         {
            _loc3_.removeChild(param1);
         }
         param1.destory(param2);
      }
      
      public function startGame() : void
      {
         if(!autoStartAble)
         {
            return;
         }
         fightFinished = false;
         doStartGame();
      }
      
      public function startMosouGame() : void
      {
         if(!autoStartAble)
         {
            return;
         }
         fightFinished = false;
         _isPauseGame = false;
         GameInputer.enabled = true;
         initTeam();
         _mosouCtrl.buildGame();
         GameRender.add(render);
      }
      
      public function doStartGame() : void
      {
         _isPauseGame = false;
         GameInputer.enabled = true;
         gameRunData.reset();
         initTeam();
         buildGame();
         GameEvent.dispatchEvent("GAME_START");
         GameRender.add(render);
      }
      
      private function buildGame() : void
      {
         var _loc1_:Array = null;
         var _loc3_:* = undefined;
         var _loc5_:* = undefined;
         var _loc4_:FighterMain = null;
         if(!GameMode.isMusouMode())
         {
            if(!GameMode.isTeamMode())
            {
               gameRunData.p1FighterGroup.currentFighter = GameRunFactory.createFighterByData(gameRunData.p1FighterGroup.fighter1,"1");
               gameRunData.p2FighterGroup.currentFighter = GameRunFactory.createFighterByData(gameRunData.p2FighterGroup.fighter1,"2");
            }
            else
            {
               gameRunData.p1FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p1FighterGroup.fighter1,"1"));
               if(gameRunData.p1FighterGroup.fighter2)
               {
                  gameRunData.p1FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p1FighterGroup.fighter2,"1"));
               }
               if(gameRunData.p1FighterGroup.fighter3)
               {
                  gameRunData.p1FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p1FighterGroup.fighter3,"1"));
               }
               gameRunData.p1FighterGroup.currentFighter = gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter1);
               gameRunData.p2FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p2FighterGroup.fighter1,"2"));
               if(gameRunData.p2FighterGroup.fighter2)
               {
                  gameRunData.p2FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p2FighterGroup.fighter2,"2"));
               }
               if(gameRunData.p2FighterGroup.fighter3)
               {
                  gameRunData.p2FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p2FighterGroup.fighter3,"2"));
               }
               gameRunData.p2FighterGroup.currentFighter = gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter1);
            }
            gameRunData.p1FighterGroup.currentAssister = GameRunFactory.createAssisterByData(gameRunData.p1FighterGroup.assister,"1",gameRunData.p1FighterGroup.currentFighter);
            gameRunData.p2FighterGroup.currentAssister = GameRunFactory.createAssisterByData(gameRunData.p2FighterGroup.assister,"2",gameRunData.p2FighterGroup.currentFighter);
         }
         else
         {
            gameRunData.p1FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p1FighterGroup.fighter1,"1"));
            gameRunData.p1FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p1FighterGroup.fighter2,"1"));
            gameRunData.p1FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p1FighterGroup.fighter3,"1"));
            gameRunData.p1FighterGroup.currentFighter = gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter1);
            gameRunData.p2FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p2FighterGroup.fighter1,"2"));
            gameRunData.p2FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p2FighterGroup.fighter2,"2"));
            gameRunData.p2FighterGroup.putFighter(GameRunFactory.createFighterByData(gameRunData.p2FighterGroup.fighter3,"2"));
            gameRunData.p2FighterGroup.currentFighter = gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter1);
         }
         var _loc6_:FighterMain = gameRunData.p1FighterGroup.currentFighter;
         var _loc2_:FighterMain = gameRunData.p2FighterGroup.currentFighter;
         switch(GameMode.currentMode)
         {
            case 40:
               _trainingCtrl = new TrainingCtrler();
               _trainingCtrl.initlize([_loc6_,_loc2_]);
               gameRunData.gameTimeMax = -1;
               break;
            case 104:
               _loc1_ = [];
               _loc3_ = gameRunData.p1FighterGroup.getAliveFighters();
               _loc5_ = gameRunData.p2FighterGroup.getAliveFighters();
               _loc4_ = null;
               for each(_loc4_ in _loc3_)
               {
                  _loc1_.push(_loc4_);
               }
               for each(_loc4_ in _loc5_)
               {
                  _loc1_.push(_loc4_);
               }
               _trainingCtrl = new TrainingCtrler();
               _trainingCtrl.initlize(_loc1_);
               gameRunData.gameTimeMax = -1;
         }
         var _loc7_:MapMain = GameRunFactory.createMapByData(gameRunData.map);
         if(!_loc6_ || !_loc2_ || !_loc7_)
         {
            throw new Error("创建游戏失败");
         }
         addFighter(_loc6_,1);
         addFighter(_loc2_,2);
         _loc7_.initlize();
         gameState.initFight(gameRunData.p1FighterGroup,gameRunData.p2FighterGroup,_loc7_);
         GameLogic.initGameLogic(_loc7_,gameState.camera);
         initMainLogic();
         if(!GameMode.isTraining() || GameMode.isTraining() && TrainingCtrler.SAY_INTRO)
         {
            initStart();
            _startCtrl.start1v1(_loc6_,_loc2_);
         }
         else
         {
            actionEnable = true;
            GameUI.I.fadIn();
            SoundCtrl.I.smartPlayGameBGM("map");
         }
         GameInterface.instance.afterBuildGame();
      }
      
      public function addFighter(param1:FighterMain, param2:int, param3:Boolean = true) : void
      {
         var _loc4_:IFighterActionCtrl = null;
         if(!param1)
         {
            return;
         }
         switch(param2 - 1)
         {
            case 0:
               if(GameMode.isWatch())
               {
                  _loc4_ = new FighterAICtrl();
                  (_loc4_ as FighterAICtrl).AILevel = GameData.I.config.AI_level;
                  (_loc4_ as FighterAICtrl).fighter = param1;
                  break;
               }
               _loc4_ = new FighterKeyCtrl();
               (_loc4_ as FighterKeyCtrl).inputType = "P1";
               (_loc4_ as FighterKeyCtrl).classicMode = GameData.I.config.keyInputMode == 1;
               break;
            case 1:
               if(GameMode.isWatch() || GameMode.isVsCPU(false) || GameMode.isAcrade())
               {
                  _loc4_ = new FighterAICtrl();
                  (_loc4_ as FighterAICtrl).AILevel = GameData.I.config.AI_level;
                  (_loc4_ as FighterAICtrl).fighter = param1;
                  break;
               }
               _loc4_ = new FighterKeyCtrl();
               (_loc4_ as FighterKeyCtrl).inputType = "P2";
               (_loc4_ as FighterKeyCtrl).classicMode = GameData.I.config.keyInputMode == 1;
         }
         addGameSprite(param2,param1);
         param1.initlize(param3);
         param1.setActionCtrl(_loc4_);
         FighterEventDispatcher.dispatchEvent(param1,"BIRTH");
      }
      
      public function removeFighter(param1:FighterMain, param2:Boolean = false) : void
      {
         if(!param1)
         {
            return;
         }
         removeGameSprite(param1,param2);
      }
      
      public function startNextRound() : void
      {
         doBuildNextRound(GameMode.isTeamMode());
      }
      
      private function buildNextRound(param1:Boolean) : void
      {
         doBuildNextRound(param1);
      }
      
      private function doBuildNextRound(param1:Boolean) : void
      {
         var _loc3_:Assister = null;
         var _loc4_:Assister = null;
         var _loc2_:int = 0;
         gameState.resetFight(gameRunData.p1FighterGroup,gameRunData.p2FighterGroup);
         _startCtrl = new GameStartCtrl(gameState);
         if(param1)
         {
            _loc3_ = gameRunData.p1FighterGroup.currentAssister;
            _loc4_ = gameRunData.p2FighterGroup.currentAssister;
            _loc3_.setOwner(gameRunData.p1FighterGroup.currentFighter);
            _loc4_.setOwner(gameRunData.p2FighterGroup.currentFighter);
            if(gameRunData.lastWinner)
            {
               gameRunData.lastWinner.hp = gameRunData.lastWinnerHp;
            }
            _loc2_ = -1;
            if(gameRunData.lastWinnerTeam)
            {
               _loc2_ = gameRunData.lastWinnerTeam.id == 1 ? 2 : 1;
            }
            _startCtrl.start1v1(gameRunData.p1FighterGroup.currentFighter,gameRunData.p2FighterGroup.currentFighter,_loc2_);
         }
         else
         {
            _startCtrl.startNextRound();
         }
         gameRunData.isDrawGame = false;
         GameEvent.dispatchEvent("ROUND_START");
      }
      
      public function fightFinish() : void
      {
         fightFinished = true;
         addRecord();
         if(GameMode.isAcrade())
         {
            if(gameRunData.lastWinnerTeam.id == 1)
            {
               if(MessionModel.I.missionAllComplete())
               {
                  MainGame.I.goCongratulations();
               }
               else
               {
                  GameData.I.winnerId = gameRunData.p1FighterGroup.currentFighter.data.id;
                  MainGame.I.goWinner();
               }
            }
            else
            {
               gameRunData.continueLoser = gameRunData.p1FighterGroup.currentFighter;
               MainGame.I.goContinue();
            }
         }
         if(GameMode.isVsCPU() || GameMode.isVsPeople())
         {
            GameEvent.dispatchEvent("GAME_END");
            MainGame.I.goSelect();
         }
      }
      
      private function addRecord() : void
      {
         if(MainGame.I.VERSION.indexOf(GetLangText("stage_menu.version_debug_suffix")) != -1)
         {
            return;
         }
         if(MainGame.I.VERSION.indexOf("概念") != -1)
         {
            return;
         }
         if(!GameMode.isVsPeople())
         {
            return;
         }
         if(!GameData.I.config.isSportsEnabled(true))
         {
            return;
         }
         if(gameRunData.p1FighterGroup.currentFighter.data.nameCn == null)
         {
            return;
         }
         if(GameMode.isSingleMode())
         {
            if(gameRunData.p1FighterGroup.currentFighter.data.level != gameRunData.p2FighterGroup.currentFighter.data.level)
            {
               return;
            }
            if(gameRunData.p1FighterGroup.currentFighter.data.isGodLevel)
            {
               return;
            }
            if(gameRunData.p2FighterGroup.currentFighter.data.isGodLevel)
            {
               return;
            }
            if(gameRunData.p1FighterGroup.currentAssister.data.isGodLevel)
            {
               return;
            }
            if(gameRunData.p2FighterGroup.currentAssister.data.isGodLevel)
            {
               return;
            }
            GameData.I.record.addRecord(0,{
               "P1":{
                  "fighter":{
                     "name":gameRunData.p1FighterGroup.currentFighter.data.nameCn,
                     "level":gameRunData.p1FighterGroup.currentFighter.data.level,
                     "count":gameRunData.p1FighterGroup.currentFighter.recordCount,
                     "win_count":gameRunData.p1FighterGroup.currentFighter.recordWinCount,
                     "damage":gameRunData.p1FighterGroup.currentFighter.recordDamage
                  },
                  "assist":gameRunData.p1FighterGroup.currentAssister.data.nameCn
               },
               "P2":{
                  "fighter":{
                     "name":gameRunData.p2FighterGroup.currentFighter.data.nameCn,
                     "level":gameRunData.p2FighterGroup.currentFighter.data.level,
                     "count":gameRunData.p2FighterGroup.currentFighter.recordCount,
                     "win_count":gameRunData.p2FighterGroup.currentFighter.recordWinCount,
                     "damage":gameRunData.p2FighterGroup.currentFighter.recordDamage
                  },
                  "assist":gameRunData.p2FighterGroup.currentAssister.data.nameCn
               },
               "winner":gameRunData.lastWinnerTeam.name
            });
         }
         if(GameMode.isTeamMode())
         {
            if(!(gameRunData.p1FighterGroup.fighter1.level == gameRunData.p1FighterGroup.fighter2.level && gameRunData.p1FighterGroup.fighter2.level == gameRunData.p1FighterGroup.fighter3.level && gameRunData.p1FighterGroup.fighter3.level == gameRunData.p2FighterGroup.fighter1.level && gameRunData.p2FighterGroup.fighter1.level == gameRunData.p2FighterGroup.fighter2.level && gameRunData.p2FighterGroup.fighter2.level == gameRunData.p2FighterGroup.fighter3.level))
            {
               return;
            }
            if(gameRunData.p1FighterGroup.fighter1.isGodLevel)
            {
               return;
            }
            if(gameRunData.p1FighterGroup.fighter2.isGodLevel)
            {
               return;
            }
            if(gameRunData.p1FighterGroup.fighter3.isGodLevel)
            {
               return;
            }
            if(gameRunData.p2FighterGroup.fighter1.isGodLevel)
            {
               return;
            }
            if(gameRunData.p2FighterGroup.fighter2.isGodLevel)
            {
               return;
            }
            if(gameRunData.p2FighterGroup.fighter3.isGodLevel)
            {
               return;
            }
            if(gameRunData.p1FighterGroup.currentAssister.data.isGodLevel)
            {
               return;
            }
            if(gameRunData.p2FighterGroup.currentAssister.data.isGodLevel)
            {
               return;
            }
            GameData.I.record.addRecord(1,{
               "P1":{
                  "fighter":{
                     "fighter1":{
                        "name":gameRunData.p1FighterGroup.fighter1.nameCn,
                        "level":gameRunData.p1FighterGroup.fighter1.level,
                        "count":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter1).recordCount,
                        "win_count":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter1).recordWinCount,
                        "damage":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter1).recordDamage
                     },
                     "fighter2":{
                        "name":gameRunData.p1FighterGroup.fighter2.nameCn,
                        "level":gameRunData.p1FighterGroup.fighter2.level,
                        "count":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter2).recordCount,
                        "win_count":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter2).recordWinCount,
                        "damage":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter2).recordDamage
                     },
                     "fighter3":{
                        "name":gameRunData.p1FighterGroup.fighter3.nameCn,
                        "level":gameRunData.p1FighterGroup.fighter3.level,
                        "count":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter3).recordCount,
                        "win_count":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter3).recordWinCount,
                        "damage":gameRunData.p1FighterGroup.getFighter(gameRunData.p1FighterGroup.fighter3).recordDamage
                     }
                  },
                  "assist":gameRunData.p1FighterGroup.currentAssister.data.nameCn
               },
               "P2":{
                  "fighter":{
                     "fighter1":{
                        "name":gameRunData.p2FighterGroup.fighter1.nameCn,
                        "level":gameRunData.p2FighterGroup.fighter1.level,
                        "count":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter1).recordCount,
                        "win_count":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter1).recordWinCount,
                        "damage":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter1).recordDamage
                     },
                     "fighter2":{
                        "name":gameRunData.p2FighterGroup.fighter2.nameCn,
                        "level":gameRunData.p2FighterGroup.fighter2.level,
                        "count":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter2).recordCount,
                        "win_count":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter2).recordWinCount,
                        "damage":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter2).recordDamage
                     },
                     "fighter3":{
                        "name":gameRunData.p2FighterGroup.fighter3.nameCn,
                        "level":gameRunData.p2FighterGroup.fighter3.level,
                        "count":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter3).recordCount,
                        "win_count":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter3).recordWinCount,
                        "damage":gameRunData.p2FighterGroup.getFighter(gameRunData.p2FighterGroup.fighter3).recordDamage
                     }
                  },
                  "assist":gameRunData.p2FighterGroup.currentAssister.data.nameCn
               },
               "winner":gameRunData.lastWinnerTeam.name
            });
         }
      }
      
      public function initStart() : GameStartCtrl
      {
         _startCtrl = new GameStartCtrl(GameCtrl.I.gameState);
         actionEnable = false;
         return _startCtrl;
      }
      
      public function initMainLogic() : void
      {
         _mainLogicCtrl = new GameMainLogicCtrler();
         _mainLogicCtrl.initlize(gameState,_teamMap);
      }
      
      private function initTeam() : void
      {
         _teamMap.clear();
         var _loc2_:Array = GameMode.getTeams();
         for each(var _loc1_ in _loc2_)
         {
            _teamMap.add(new TeamVO(_loc1_.id,_loc1_.name));
         }
      }
      
      public function get isGamePause() : Boolean
      {
         return _isGamePause;
      }
      
      public function pause(param1:Boolean = false) : void
      {
         if(!_gameRunning)
         {
            return;
         }
         if(!param1)
         {
            _isGamePause = true;
            setRenderHit(false);
            return;
         }
         if(param1 && !_isPauseGame)
         {
            if(_startCtrl || _endCtrl || _mosouCtrl && _mosouCtrl.getGameFinished())
            {
               _gameStartAndPause = true;
               return;
            }
            GameEvent.dispatchEvent("PAUSE_GAME");
            _isPauseGame = true;
            GameUI.I.getUI().pause();
         }
         _isRenderGame = false;
      }
      
      public function resume(param1:Boolean = false) : void
      {
         if(!_gameRunning)
         {
            return;
         }
         _gameStartAndPause = false;
         if(!param1)
         {
            _isGamePause = false;
            setRenderHit(true);
            return;
         }
         if(param1 && _isPauseGame)
         {
            if(GameUI.I.getUI().resume())
            {
               GameEvent.dispatchEvent("RESUME_GAME");
               _isPauseGame = false;
            }
         }
         KeyBoarder.focus();
         _isRenderGame = true;
         if(!GameMode.isTraining() && !GameMode.isMusouMode())
         {
            doCountdown();
         }
      }
      
      private function doCountdown() : void
      {
         _isCountdown = true;
         actionEnable = false;
         pause();
         setRenderHit(false);
         GameUI.I.getUI().showCountdown(function():void
         {
            _isCountdown = false;
            actionEnable = true;
            resume();
            setRenderHit(true);
         });
      }
      
      public function gameEnd(param1:FighterMain, param2:FighterMain) : void
      {
         if(!autoEndRoundAble)
         {
            return;
         }
         if(_endCtrl)
         {
            return;
         }
         doGameEnd(param1,param2);
      }
      
      public function doGameEnd(param1:FighterMain, param2:FighterMain) : void
      {
         gameRunData.lastWinnerTeam = param1.team;
         gameRunData.lastWinner = param1;
         gameRunData.lastLoser = param2;
         gameRunData.lastLoserData = param2.data;
         gameRunData.lastLoserQi = param2.qi;
         param1.recordCount++;
         param2.recordCount++;
         param1.recordWinCount++;
         switch(param1.team.id - 1)
         {
            case 0:
               gameRunData.p1Wins++;
               if(param2.hp <= 0 && GameMode.isAcrade())
               {
                  GameLogic.addScoreByKO();
               }
               break;
            case 1:
               gameRunData.p2Wins++;
         }
         _endCtrl = new GameEndCtrl();
         _endCtrl.initlize(param1,param2);
         actionEnable = false;
         param1.isAllowBeHit = false;
         GameEvent.dispatchEvent("ROUND_END");
      }
      
      private function render() : void
      {
         if(_isDestoryed)
         {
            return;
         }
         var _loc1_:Boolean = false;
         var _loc2_:Boolean = false;
         renderPause();
         if(_isPauseGame)
         {
            return;
         }
         EffectCtrl.I.render();
         JoyRumble.I.doRumble();
         gameState.render();
         if(!_isRenderGame)
         {
            return;
         }
         if(_isGamePause)
         {
            return;
         }
         checkRenderAnimate();
         if(_mainLogicCtrl)
         {
            _mainLogicCtrl.render();
         }
         if(_startCtrl)
         {
            actionEnable = false;
            _loc1_ = _startCtrl.render();
            if(_loc1_)
            {
               _startCtrl.destory();
               _startCtrl = null;
               actionEnable = true;
               if(_gameStartAndPause)
               {
                  pause(true);
                  _gameStartAndPause = false;
               }
            }
         }
         if(_endCtrl)
         {
            _loc2_ = _endCtrl.render();
            if(_loc2_)
            {
               _endCtrl.destory();
               _endCtrl = null;
               runNext();
            }
         }
         if(_trainingCtrl)
         {
            _trainingCtrl.render();
         }
         if(_mosouCtrl)
         {
            _mosouCtrl.render();
         }
         if(_isCountdown)
         {
            actionEnable = false;
            pause();
            setRenderHit(false);
         }
      }
      
      private function checkRenderAnimate() : void
      {
         if(_renderAnimateGap > 0)
         {
            if(_renderAnimateFrame++ >= _renderAnimateGap)
            {
               _renderAnimateFrame = 0;
               renderAnimate();
            }
         }
         else
         {
            renderAnimate();
         }
      }
      
      private function renderAnimate() : void
      {
         if(_isDestoryed)
         {
            return;
         }
         if(_mainLogicCtrl)
         {
            _mainLogicCtrl.renderAnimate();
         }
         if(_mosouCtrl)
         {
            _mosouCtrl.renderAnimate();
         }
         if(actionEnable && !_startCtrl && !_endCtrl && !_mosouCtrl)
         {
            renderGameTime();
         }
      }
      
      private function renderGameTime() : void
      {
         if(gameRunData.gameTimeMax != -1)
         {
            if(++_renderTimeFrame > 30)
            {
               _renderTimeFrame = 0;
               gameRunData.gameTime--;
               if(gameRunData.gameTime <= 0)
               {
                  fightTimeover();
               }
            }
         }
      }
      
      private function fightTimeover() : void
      {
         actionEnable = false;
         var _loc2_:FighterMain = gameRunData.p1FighterGroup.currentFighter;
         var _loc1_:FighterMain = gameRunData.p2FighterGroup.currentFighter;
         gameRunData.isTimerOver = true;
         if(_loc2_.hp == _loc1_.hp)
         {
            drawGame();
            return;
         }
         if(_loc2_.hp > _loc1_.hp)
         {
            gameEnd(_loc2_,_loc1_);
         }
         else
         {
            gameEnd(_loc1_,_loc2_);
         }
      }
      
      public function drawGame() : void
      {
         if(_endCtrl)
         {
            return;
         }
         gameRunData.lastWinnerTeam = null;
         gameRunData.lastWinner = null;
         gameRunData.lastLoser = null;
         gameRunData.isDrawGame = true;
         _endCtrl = new GameEndCtrl();
         _endCtrl.drawGame();
         actionEnable = false;
         GameEvent.dispatchEvent("ROUND_END");
      }
      
      private function runNext() : void
      {
         gameRunData.nextRound();
         if(GameMode.isTeamMode())
         {
            if(startNextTeamFight())
            {
               buildNextRound(true);
               gameRunData.lastWinner = null;
               gameRunData.lastLoser = null;
               return;
            }
         }
         if(GameMode.isSingleMode() || GameMode.isMusouMode())
         {
            if(gameRunData.p1Wins < 2 && gameRunData.p2Wins < 2)
            {
               buildNextRound(false);
               gameRunData.lastWinner = null;
               gameRunData.lastLoser = null;
               return;
            }
         }
         fightFinish();
      }
      
      private function startNextTeamFight() : Boolean
      {
         var _loc2_:FighterVO = null;
         var _loc1_:FighterVO = null;
         if(gameRunData.isDrawGame)
         {
            _loc2_ = gameRunData.p1FighterGroup.getNextFighter();
            _loc1_ = gameRunData.p2FighterGroup.getNextFighter();
            if(!_loc2_ && !_loc1_)
            {
               return true;
            }
            if(_loc2_ && !_loc1_)
            {
               gameRunData.lastWinnerTeam = gameRunData.p1FighterGroup.currentFighter.team;
               return false;
            }
            if(!_loc2_ && _loc1_)
            {
               gameRunData.lastWinnerTeam = gameRunData.p2FighterGroup.currentFighter.team;
               return false;
            }
            nextFighter(gameRunData.p1FighterGroup);
            nextFighter(gameRunData.p2FighterGroup);
            return true;
         }
         switch(gameRunData.lastWinnerTeam.id - 1)
         {
            case 0:
               return nextFighter(gameRunData.p2FighterGroup);
            case 1:
               return nextFighter(gameRunData.p1FighterGroup);
            default:
               gameRunData.lastWinnerTeam = null;
               return true;
         }
      }
      
      private function nextFighter(param1:GameRunFighterGroup) : Boolean
      {
         if(!param1)
         {
            return false;
         }
         var _loc4_:TeamVO = param1.currentFighter.team;
         var _loc3_:FighterVO = param1.getNextFighter();
         if(!_loc3_)
         {
            return false;
         }
         var _loc2_:FighterMain = param1.getNextAliveFighter();
         if(!_loc2_)
         {
            return false;
         }
         if(gameRunData.lastLoserData)
         {
            if(gameRunData.lastLoserData.comicType == _loc2_.data.comicType)
            {
               _loc2_.qi = gameRunData.lastLoserQi + 100;
            }
            if(_loc2_.qi > _loc2_.qiMax)
            {
               _loc2_.qi = _loc2_.qiMax;
            }
            param1.currentFighter.doInheritFunc(_loc2_);
         }
         removeFighter(param1.currentFighter,true);
         param1.currentFighter = _loc2_;
         addFighter(param1.currentFighter,_loc4_.id);
         return true;
      }
      
      public function slow(param1:Number) : void
      {
         slowRate = param1;
         var _loc2_:Number = 30 / param1;
         setAnimateFPS(_loc2_);
         _mainLogicCtrl.setSpeedPlus(GameConfig.SPEED_PLUS_DEFAULT / param1);
         gameState.camera.tweenSpd = 2.5 * param1;
      }
      
      public function slowResume() : void
      {
         slowRate = 0;
         setAnimateFPS(30);
         _mainLogicCtrl.setSpeedPlus(GameConfig.SPEED_PLUS_DEFAULT);
         gameState.camera.tweenSpd = 2.5;
      }
      
      private function setAnimateFPS(param1:Number) : void
      {
         _renderAnimateGap = Math.ceil(GameConfig.FPS_GAME / param1) - 1;
         _renderAnimateFrame = 0;
      }
      
      public function initMosouGame() : void
      {
         _mosouCtrl = new MosouCtrl();
         _mosouCtrl.initalize();
      }
   }
}

