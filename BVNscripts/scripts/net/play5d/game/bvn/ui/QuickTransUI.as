package net.play5d.game.bvn.ui
{
   import com.greensock.*;
   import flash.display.Sprite;
   import net.play5d.game.bvn.*;
   import net.play5d.kyo.display.shapes.*;
   
   public class QuickTransUI extends Sprite
   {
      
      private var _up:Box;
      
      private var _down:Box;
      
      private var _center:Number = 0;
      
      public function QuickTransUI()
      {
         super();
         this._center = GameConfig.GAME_SIZE.y / 2;
         this._up = new Box(GameConfig.GAME_SIZE.x,this._center);
         this._down = new Box(GameConfig.GAME_SIZE.x,this._center);
         addChild(this._up);
         addChild(this._down);
      }
      
      public function fadInAndOut(param1:Function = null) : void
      {
         var back:Function = null;
         back = param1;
         this.fadIn(function():void
         {
            fadOut(back);
         });
      }
      
      public function fadIn(param1:Function = null) : void
      {
         this._up.y = -this._center;
         this._down.y = GameConfig.GAME_SIZE.y;
         TweenLite.to(this._up,0.1,{"y":0});
         TweenLite.to(this._down,0.1,{
            "y":this._center,
            "onComplete":param1
         });
      }
      
      public function fadOut(param1:Function = null) : void
      {
         TweenLite.to(this._up,0.1,{"y":-this._center});
         TweenLite.to(this._down,0.1,{
            "y":GameConfig.GAME_SIZE.y,
            "onComplete":param1
         });
      }
   }
}

