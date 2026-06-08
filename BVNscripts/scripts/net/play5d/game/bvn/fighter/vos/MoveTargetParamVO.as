package net.play5d.game.bvn.fighter.vos
{
   import flash.geom.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.interfaces.*;
   
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
         if(!param1)
         {
            return;
         }
         this.x = param1.x != undefined ? Number(param1.x) : 0;
         this.y = param1.y != undefined ? Number(param1.y) : 0;
         this.followMcName = param1.followmc != undefined ? param1.followmc : null;
         if(Boolean(param1.speed))
         {
            this.speed = new Point();
            if(param1.speed is Number)
            {
               this.speed.x = this.speed.y = param1.speed * GameConfig.SPEED_PLUS;
            }
            else
            {
               this.speed.x = param1.speed.x != undefined ? param1.speed.x * GameConfig.SPEED_PLUS : 0;
               this.speed.y = param1.speed.y != undefined ? param1.speed.y * GameConfig.SPEED_PLUS : 0;
            }
         }
      }
      
      public function setTarget(param1:IGameSprite) : void
      {
         this.target = param1;
         if(this.target is BaseGameSprite)
         {
            (this.target as BaseGameSprite).setVelocity(0,0);
         }
      }
      
      public function clear() : void
      {
         if(Boolean(this.target))
         {
            if(this.target is BaseGameSprite)
            {
               (this.target as BaseGameSprite).isApplyG = true;
            }
         }
      }
   }
}

