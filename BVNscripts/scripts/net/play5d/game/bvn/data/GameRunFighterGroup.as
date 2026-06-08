package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterMain;
   
   public class GameRunFighterGroup
   {
      
      public var fighter1:FighterMain;
      
      public var fighter2:FighterMain;
      
      public var fighter3:FighterMain;
      
      public var fuzhu:Assister;
      
      public var currentFighter:FighterMain;
      
      public function GameRunFighterGroup()
      {
         super();
      }
      
      public function getFighterDatas() : Vector.<FighterVO>
      {
         var vec:Vector.<FighterVO> = new Vector.<FighterVO>();
         this.fighter1 && vec.push(this.fighter1.data);
         this.fighter2 && vec.push(this.fighter2.data);
         this.fighter3 && vec.push(this.fighter3.data);
         return vec;
      }
      
      public function getNextFighter() : FighterMain
      {
         switch(this.currentFighter)
         {
            case this.fighter1:
               return this.fighter2;
            case this.fighter2:
               return this.fighter3;
            default:
               return null;
         }
      }
      
      public function destoryFighters(expect:FighterMain) : void
      {
         if(Boolean(this.fighter1) && this.fighter1 != expect)
         {
            this.disposeFighter(this.fighter1);
         }
         if(Boolean(this.fighter2) && this.fighter2 != expect)
         {
            this.disposeFighter(this.fighter2);
         }
         if(Boolean(this.fighter3) && this.fighter3 != expect)
         {
            this.disposeFighter(this.fighter3);
         }
         this.disposeFuzhu();
      }
      
      public function removeCurrentFighter() : void
      {
         this.disposeFighter(this.currentFighter);
      }
      
      private function disposeFighter(f:FighterMain) : void
      {
         if(f == null)
         {
            return;
         }
         if(f == this.currentFighter)
         {
            this.currentFighter = null;
         }
         f.destory(true);
         switch(f)
         {
            case this.fighter1:
               this.fighter1 = null;
               return;
            case this.fighter2:
               this.fighter2 = null;
               break;
            case this.fighter3:
               this.fighter3 = null;
         }
      }
      
      private function disposeFuzhu() : void
      {
         if(this.fuzhu != null)
         {
            this.fuzhu.destory(true);
            this.fuzhu = null;
         }
      }
   }
}

