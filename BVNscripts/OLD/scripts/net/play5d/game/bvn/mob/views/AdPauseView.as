package net.play5d.game.bvn.mob.views
{
   import flash.display.Bitmap;
   import flash.display.Sprite;
   
   public class AdPauseView extends Sprite
   {
      
      private var _closeBtn:Class = contbtn_png$de43e5cf9e4a68d517f58b1a9e2b580f403349984;
      
      public function AdPauseView()
      {
         super();
         this.graphics.beginFill(0,0.5);
         this.graphics.drawRect(0,0,launch.FULL_SCREEN_SIZE.x,launch.FULL_SCREEN_SIZE.y);
         this.graphics.endFill();
         var _loc1_:Bitmap = new _closeBtn();
         _loc1_.scaleX = launch.FULL_SCREEN_SIZE.x / 800;
         _loc1_.scaleY = _loc1_.scaleX;
         _loc1_.x = (launch.FULL_SCREEN_SIZE.x - _loc1_.width) / 2;
         _loc1_.y = (launch.FULL_SCREEN_SIZE.y - _loc1_.height) / 2;
         this.addChild(_loc1_);
      }
   }
}

