package net.play5d.game.bvn.fighter.vos
{
   import net.play5d.kyo.utils.KyoUtils;
   
   public class FlyParams
   {
      
      public var lrSpd:Number = 0;
      
      public var upSpd:Number = 0;
      
      public var downSpd:Number = 0;
      
      public var holdFrame:int = 0;
      
      public var endAction:String = null;
      
      public function FlyParams(param1:Object)
      {
         super();
         if(param1)
         {
            KyoUtils.setValueByObject(this,param1);
         }
      }
   }
}

