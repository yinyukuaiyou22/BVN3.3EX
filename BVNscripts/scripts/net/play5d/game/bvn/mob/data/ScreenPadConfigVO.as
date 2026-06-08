package net.play5d.game.bvn.mob.data
{
   public class ScreenPadConfigVO
   {
      
      public var joyMode:int = 1;
      
      public var joyAlpha:Number = 0.7;
      
      public var joySet:Object;
      
      public var wankaiAutoHide:Boolean = true;
      
      public var specialAutoHide:Boolean = true;
      
      public var superSkillAutoHide:Boolean = true;
      
      public function ScreenPadConfigVO()
      {
         super();
      }
      
      public function applyInfiniteEnergy(infiniteOn:Boolean) : void
      {
         if(infiniteOn)
         {
            this.superSkillAutoHide = false;
         }
      }
      
      public function toObj() : Object
      {
         return {
            "joyMode":this.joyMode,
            "joyAlpha":this.joyAlpha,
            "joySet":this.joySet,
            "wankaiAutoHide":this.wankaiAutoHide,
            "specialAutoHide":this.specialAutoHide,
            "superSkillAutoHide":this.superSkillAutoHide
         };
      }
      
      public function readObj(param1:Object) : void
      {
         if(!param1)
         {
            return;
         }
         if(param1.joyMode != undefined)
         {
            this.joyMode = param1.joyMode;
         }
         if(param1.joyAlpha != undefined)
         {
            this.joyAlpha = param1.joyAlpha;
         }
         if(param1.joySet != undefined)
         {
            this.joySet = param1.joySet;
         }
         if(param1.wankaiAutoHide != undefined)
         {
            this.wankaiAutoHide = param1.wankaiAutoHide;
         }
         if(param1.specialAutoHide != undefined)
         {
            this.specialAutoHide = param1.specialAutoHide;
         }
         if(param1.superSkillAutoHide != undefined)
         {
            this.superSkillAutoHide = param1.superSkillAutoHide;
         }
      }
      
      public function setValueByKey(param1:String, param2:Object) : void
      {
         if(this.hasOwnProperty(param1))
         {
            this[param1] = param2;
         }
      }
   }
}

