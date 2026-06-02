package net.play5d.game.bvn.data
{
   public class GameMode
   {
      
      public static const TEAM_ACRADE:int = 10;
      
      public static const TEAM_VS_PEOPLE:int = 11;
      
      public static const TEAM_VS_CPU:int = 12;
      
      public static const TEAM_WATCH:int = 13;
      
      public static const SINGLE_ACRADE:int = 20;
      
      public static const SINGLE_VS_PEOPLE:int = 21;
      
      public static const SINGLE_VS_CPU:int = 22;
      
      public static const SINGLE_WATCH:int = 23;
      
      public static const SURVIVOR:int = 30;
      
      public static const TRAINING:int = 40;
      
      public static const MUSOU_ACRADE:int = 100;
      
      public static const MUSOU_VS_PEOPLE:int = 101;
      
      public static const MUSOU_VS_CPU:int = 102;
      
      public static const MUSOU_WATCH:int = 103;
      
      public static const MUSOU_TRAINING:int = 104;
      
      public static var currentMode:int;
      
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
         return currentMode == 10 || currentMode == 12 || currentMode == 11 || currentMode == 100 || currentMode == 13;
      }
      
      public static function isSingleMode() : Boolean
      {
         return currentMode == 20 || currentMode == 22 || currentMode == 21 || currentMode == 23;
      }
      
      public static function isMusouMode() : Boolean
      {
         return currentMode == 100 || currentMode == 101 || currentMode == 102 || currentMode == 103 || currentMode == 104;
      }
      
      public static function isVsPeople() : Boolean
      {
         return currentMode == 11 || currentMode == 21 || currentMode == 101;
      }
      
      public static function isVsCPU(param1:Boolean = true) : Boolean
      {
         return currentMode == 12 || currentMode == 22 || currentMode == 102 || param1 && isTraining() || isWatch();
      }
      
      public static function isWatch() : Boolean
      {
         return currentMode == 13 || currentMode == 23 || currentMode == 103;
      }
      
      public static function isAcrade() : Boolean
      {
         return currentMode == 20 || currentMode == 10 || currentMode == 30;
      }
      
      public static function isTraining() : Boolean
      {
         return currentMode == 40 || currentMode == 104;
      }
   }
}

