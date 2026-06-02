package net.play5d.game.bvn.utils
{
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.GameConfig;
   
   public class PayUtils
   {
      
      private static var _orgRect:Rectangle;
      
      public function PayUtils()
      {
         super();
      }
      
      public static function getPaySp(param1:Bitmap) : Sprite
      {
         var _loc2_:Sprite = new Sprite();
         _loc2_.buttonMode = true;
         _loc2_.addChild(param1);
         _loc2_.addEventListener("mouseUp",payMouseHandler,false,0,true);
         return _loc2_;
      }
      
      private static function payMouseHandler(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         param1.stopPropagation();
         var _loc4_:Sprite = param1.currentTarget as Sprite;
         if(_loc4_ == null)
         {
            return;
         }
         var _loc3_:DisplayObject = _loc4_.getChildAt(0);
         var _loc2_:Graphics = _loc4_.graphics;
         if(_orgRect != null && _loc4_.width != _orgRect.width)
         {
            _loc2_.clear();
            if(_loc3_ != null)
            {
               _loc3_.scaleX = _loc3_.scaleY = 1;
               _loc3_.x = 0;
               _loc3_.y = 0;
            }
            _loc4_.x = _orgRect.x;
            _loc4_.y = _orgRect.y;
            _loc4_.width = _orgRect.width;
            _loc4_.height = _orgRect.height;
            _orgRect = null;
            return;
         }
         _orgRect = new Rectangle(_loc4_.x,_loc4_.y,_loc4_.width,_loc4_.height);
         _loc2_.beginFill(0,0.7);
         _loc2_.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y + 20);
         _loc2_.endFill();
         _loc4_.parent.addChild(_loc4_);
         _loc4_.x = 0;
         _loc4_.y = 0;
         _loc4_.width = GameConfig.GAME_SIZE.x;
         _loc4_.height = GameConfig.GAME_SIZE.y;
         if(_loc3_ != null)
         {
            _loc3_.scaleX = _loc3_.scaleY = 0.8;
            _loc3_.x = (GameConfig.GAME_SIZE.x - _loc3_.width) * 0.5;
            _loc3_.y = (GameConfig.GAME_SIZE.y - _loc3_.height) * 0.5;
         }
      }
   }
}

