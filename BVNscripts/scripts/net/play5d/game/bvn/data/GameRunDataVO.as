package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.map.MapMain;
   
   public class GameRunDataVO
   {
      
      public const p1FighterGroup:GameRunFighterGroup = new GameRunFighterGroup();
      
      public const p2FighterGroup:GameRunFighterGroup = new GameRunFighterGroup();
      
      public var map:MapMain;
      
      public var p1Wins:int = 0;
      
      public var p2Wins:int = 0;
      
      public var lastWinnerTeam:TeamVO;
      
      public var continueLoser:FighterMain;
      
      public var lastWinner:FighterMain;
      
      public var lastWinnerHp:int = 1000;
      
      public var lastLoserData:FighterVO;
      
      public var lastLoserQi:int = 0;
      
      public var round:int = 1;
      
      public var gameTime:int;
      
      public var gameTimeMax:int;
      
      public var isTimerOver:Boolean;
      
      public var isDrawGame:Boolean;
      
      public function GameRunDataVO()
      {
         super();
      }
      
      public function getWins(f:FighterMain) : int
      {
         switch(f.team.id - 1)
         {
            case 0:
               return this.p1Wins;
            case 1:
               return this.p2Wins;
            default:
               return 0;
         }
      }
      
      public function reset() : void
      {
         this.p1Wins = 0;
         this.p2Wins = 0;
         this.round = 1;
         this.lastWinnerTeam = null;
         this.lastWinner = null;
         this.lastLoserData = null;
         this.lastLoserQi = 0;
         this.isTimerOver = false;
         this.isDrawGame = false;
         this.lastWinnerHp = GameData.I.config.fighterHP;
         this.gameTimeMax = GameData.I.config.fightTime;
         this.gameTime = this.gameTimeMax;
         this.continueLoser = null;
      }
      
      public function clear() : void
      {
         this.map = null;
         this.lastWinnerTeam = null;
         this.lastWinner = null;
         this.lastLoserData = null;
         this.continueLoser = null;
      }
      
      public function nextRound() : void
      {
         ++this.round;
         this.gameTime = this.gameTimeMax;
         this.isTimerOver = false;
      }
      
      public function setAllowLoseHP(v:Boolean) : void
      {
         if(Boolean(this.p1FighterGroup))
         {
            this.p1FighterGroup.currentFighter.isAllowLoseHP = v;
         }
         if(Boolean(this.p2FighterGroup))
         {
            this.p2FighterGroup.currentFighter.isAllowLoseHP = v;
         }
      }
   }
}

