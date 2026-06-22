package net.play5d.game.bvn.data
{
   public class GameMode
   {
      
      public static var currentMode:int;
      
      public static const TEAM_ACRADE:int = 10;
      
      public static const TEAM_VS_PEOPLE:int = 11;
      
      public static const TEAM_VS_CPU:int = 12;
      
      public static const TEAM_WATCH:int = 13;

      public static const TEAM_DUO:int = 14;

      public static const TEAM_DUO_WATCH:int = 15;

      public static const SINGLE_ACRADE:int = 20;

      public static const SINGLE_VS_PEOPLE:int = 21;

      public static const SINGLE_VS_CPU:int = 22;

      public static const SINGLE_WATCH:int = 23;

      public static const SINGLE_VS_DUO:int = 24;

      public static const SINGLE_VS_DUO_WATCH:int = 25;

      public static const SURVIVOR:int = 30;

      public static const TRAINING:int = 40;
      
      public function GameMode()
      {
         super();
      }
      
      public static function getTeams() : Array
      {
         return [{
            "id":1,
            "name":"P1"
         },{
            "id":2,
            "name":"P2"
         }];
      }
      
      public static function isTeamMode() : Boolean
      {
         return currentMode >= 10 && currentMode <= 15;
      }

      public static function isSingleMode() : Boolean
      {
         return currentMode >= 20 && currentMode <= 25;
      }

      public static function isDuoMode() : Boolean
      {
         return currentMode == TEAM_DUO || currentMode == TEAM_DUO_WATCH;
      }

      public static function is1v2Mode() : Boolean
      {
         return currentMode == SINGLE_VS_DUO || currentMode == SINGLE_VS_DUO_WATCH;
      }

      public static function getSelectCount(playerId:int = 0) : int
      {
         if (isDuoMode()) return 2;           // 2v2: 每队选 2 人
         if (isTeamMode()) return 3;          // 3v3: 每队选 3 人
         if (is1v2Mode()) {
            return playerId == 1 ? 1 : 2;     // 1v2: P1选1人 P2选2人
         }
         return 1;                            // 单人模式: 选 1 人
      }

      public static function isVsPeople() : Boolean
      {
         return currentMode == 11 || currentMode == 21;
      }

      public static function isVsCPU(param1:Boolean = true) : Boolean
      {
         return currentMode == 12 || currentMode == 22 || currentMode == 14 || currentMode == 24 || param1 && currentMode == 40 || isWatch(param1);
      }

      public static function isWatch(param1:Boolean = true) : Boolean
      {
         return currentMode == 13 || currentMode == 23 || currentMode == 15 || currentMode == 25 || param1 && currentMode == 40;
      }

      public static function isAcrade() : Boolean
      {
         return currentMode == 20 || currentMode == 10 || currentMode == 30;
      }
   }
}

