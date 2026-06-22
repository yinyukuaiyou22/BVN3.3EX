package net.play5d.game.bvn.interfaces
{
   public class GameInterface
   {
      
      public static var instance:IGameInterface;
      
      public function GameInterface()
      {
         super();
      }
      
      public static function getDefaultMenu() : Array
      {
         return [{
            "txt":"TEAM PLAY",
            "cn":"小队模式",
            "children":[{
               "txt":"TEAM ACRADE",
               "cn":"闯关模式"
            },{
               "txt":"TEAM VS PEOPLE",
               "cn":"2P对战"
            },{
               "txt":"TEAM VS CPU",
               "cn":"对战电脑"
            },{
               "txt":"TEAM DUO",
               "cn":"2v2对战"
            },{
               "txt":"TEAM DUO WATCH",
               "cn":"2v2观战"
            }]
         },{
            "txt":"SINGLE PLAY",
            "cn":"单人模式",
            "children":[{
               "txt":"SINGLE ACRADE",
               "cn":"闯关模式"
            },{
               "txt":"SINGLE VS PEOPLE",
               "cn":"2P对战"
            },{
               "txt":"SINGLE VS CPU",
               "cn":"对战电脑"
            },{
               "txt":"SINGLE VS DUO",
               "cn":"1v2对战"
            },{
               "txt":"SINGLE VS DUO WATCH",
               "cn":"1v2观战"
            }]
         },{
            "txt":"OPTION",
            "cn":"游戏设置"
         },{
            "txt":"TRAINING",
            "cn":"练习模式"
         },{
            "txt":"CREDITS",
            "cn":"制作组"
         },{
            "txt":"MORE GAMES",
            "cn":"更多游戏"
         }];
      }
   }
}

