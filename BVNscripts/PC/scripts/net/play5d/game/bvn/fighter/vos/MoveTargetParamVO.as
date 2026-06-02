package net.play5d.game.bvn.fighter.vos
{
   import flash.geom.Point;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class MoveTargetParamVO
   {
      
      public var x:Number;
      
      public var y:Number;
      
      public var followMcName:String;
      
      public var target:IGameSprite;
      
      public var speed:Point;
      
      public function MoveTargetParamVO(param1:Object = null)
      {
         super();
         if(param1 == null)
         {
            return;
         }
         x = param1.x != undefined ? param1.x : 0;
         y = param1.y != undefined ? param1.y : 0;
         followMcName = param1.followmc != undefined ? param1.followmc : null;
         if(param1.speed)
         {
            speed = new Point();
            if(param1.speed is Number)
            {
               speed.x = speed.y = param1.speed * GameConfig.SPEED_PLUS;
            }
            else
            {
               speed.x = param1.speed.x != undefined ? param1.speed.x * GameConfig.SPEED_PLUS : 0;
               speed.y = param1.speed.y != undefined ? param1.speed.y * GameConfig.SPEED_PLUS : 0;
            }
         }
      }
      
      public function setTarget(param1:IGameSprite) : void
      {
         this.target = param1;
      }
      
      public function clear() : void
      {
         if(target)
         {
            if(target is BaseGameSprite)
            {
               if(speed && speed.y != 0)
               {
                  (target as BaseGameSprite).isApplyG = true;
                  if((target as BaseGameSprite).getVecY() <= 0)
                  {
                     (target as BaseGameSprite).setVecY(0);
                  }
               }
               target = null;
               speed = null;
            }
         }
      }
   }
}

