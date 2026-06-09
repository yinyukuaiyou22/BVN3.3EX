package net.play5d.game.bvn.mob.views
{
   import flash.display.*;
   import flash.geom.*;
import net.play5d.game.bvn.Debugger;
   
   public class GameSideBg extends Bitmap
   {
      
      private var _sideBg:Class = EmbeddedAssets.side_bg_png;
      
      private var _sideShadow:Class = EmbeddedAssets.side_shadow_png;
      
      public function GameSideBg(param1:Point, param2:Rectangle)
      {
         super(null,"auto",false);
         this.update(param1,param2);
      }
      
      public function update(param1:Point, param2:Rectangle) : void
      {
         if(Boolean(this.bitmapData))
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
         var _loc3_:BitmapData = new BitmapData(param1.x,param1.y,false,0);
         var _loc4_:Bitmap = new this._sideBg();
         _loc4_.height = param1.y;
         _loc4_.scaleX = _loc4_.scaleY;
         var _loc5_:Matrix = new Matrix();
         _loc5_.scale(_loc4_.scaleX,_loc4_.scaleY);
         _loc3_.draw(_loc4_,_loc5_,null,null,new Rectangle(0,0,param2.x,param1.y));
         var _loc6_:Matrix = _loc5_.clone();
         var _loc7_:Number = _loc4_.width - (param1.x - param2.right);
         _loc6_.translate(param2.right - _loc7_ << 0,0);
         var _loc8_:Rectangle = new Rectangle(param2.right,0,param1.x,param1.y);
         _loc3_.draw(_loc4_,_loc6_,null,null,_loc8_);
         var _loc9_:Bitmap = new this._sideShadow();
         _loc9_.height = param1.y;
         _loc9_.scaleX = _loc9_.scaleY;
         var _loc10_:Matrix = new Matrix();
         _loc10_.scale(_loc9_.scaleX,_loc9_.scaleY);
         _loc10_.translate(param2.x - _loc9_.width + 1 << 0,0);
         _loc3_.draw(_loc9_,_loc10_,null);
         var _loc11_:Matrix = new Matrix();
         _loc11_.scale(-_loc9_.scaleX,_loc9_.scaleY);
         _loc11_.translate(param2.right + _loc9_.width << 0,0);
         _loc3_.draw(_loc9_,_loc11_,null);
         this.bitmapData = _loc3_;
         _loc4_.bitmapData.dispose();
         _loc9_.bitmapData.dispose();
      }
      
      public function destory() : void
      {
         try
         {
            this.parent.removeChild(this);
         }
         catch(e:Error)
         {
            Debugger.log(e);
         }
         if(Boolean(this.bitmapData))
         {
            this.bitmapData.dispose();
            this.bitmapData = null;
         }
      }
   }
}

