package net.play5d.game.bvn.mob.views
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   
   public class GameSideBg extends Bitmap
   {
      
      private var _sideBg:Class = §side_bg_png$96075bbda94b02fc3b1c390a5423deca-1383785024§;
      
      private var _sideShadow:Class = side_shadow_png$b8cfb6f15ca6c929fe5608e764526bc1272628395;
      
      public function GameSideBg(param1:Point, param2:Rectangle)
      {
         super(null,"auto",false);
         update(param1,param2);
      }
      
      public function update(param1:Point, param2:Rectangle) : void
      {
         if(this.bitmapData)
         {
            this.bitmapData.dispose();
            this.bitmapData = null;
         }
         param1.x <<= 0;
         param1.y <<= 0;
         param2.x <<= 0;
         param2.y <<= 0;
         param2.width <<= 0;
         param2.height <<= 0;
         var _loc11_:BitmapData = new BitmapData(param1.x,param1.y,false,0);
         var _loc5_:Bitmap = new _sideBg();
         _loc5_.height = param1.y;
         _loc5_.scaleX = _loc5_.scaleY;
         var _loc10_:Matrix = new Matrix();
         _loc10_.scale(_loc5_.scaleX,_loc5_.scaleY);
         _loc11_.draw(_loc5_,_loc10_,null,null,new Rectangle(0,0,param2.x,param1.y));
         var _loc4_:Matrix = _loc10_.clone();
         var _loc8_:Number = _loc5_.width - (param1.x - param2.right);
         _loc4_.translate(param2.right - _loc8_ << 0,0);
         var _loc3_:Rectangle = new Rectangle(param2.right,0,param1.x,param1.y);
         _loc11_.draw(_loc5_,_loc4_,null,null,_loc3_);
         var _loc7_:Bitmap = new _sideShadow();
         _loc7_.height = param1.y;
         _loc7_.scaleX = _loc7_.scaleY;
         var _loc9_:Matrix = new Matrix();
         _loc9_.scale(_loc7_.scaleX,_loc7_.scaleY);
         _loc9_.translate(param2.x - _loc7_.width + 1 << 0,0);
         _loc11_.draw(_loc7_,_loc9_,null);
         var _loc6_:Matrix = new Matrix();
         _loc6_.scale(-_loc7_.scaleX,_loc7_.scaleY);
         _loc6_.translate(param2.right + _loc7_.width << 0,0);
         _loc11_.draw(_loc7_,_loc6_,null);
         this.bitmapData = _loc11_;
         _loc5_.bitmapData.dispose();
         _loc7_.bitmapData.dispose();
      }
      
      public function destory() : void
      {
         try
         {
            this.parent.removeChild(this);
         }
         catch(e:Error)
         {
            trace(e);
         }
         if(this.bitmapData)
         {
            this.bitmapData.dispose();
            this.bitmapData = null;
         }
      }
   }
}

