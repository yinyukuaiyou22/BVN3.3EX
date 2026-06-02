package net.play5d.kyo.stage.effect
{
   import com.greensock.TweenLite;
   import com.greensock.easing.Back;
   import flash.display.DisplayObject;
   import flash.geom.Point;
   import net.play5d.kyo.stage.Istage;
   
   public class ZoomEffect implements IStageFadEffect
   {
      
      private var _duration:Number;
      
      private var _back:Boolean;
      
      private var _fixPosition:Boolean;
      
      public function ZoomEffect(param1:Number = 0.3, param2:Boolean = true)
      {
         super();
         this._duration = param1;
         this._back = param2;
      }
      
      public function fadIn(param1:Istage, param2:Function = null) : void
      {
         var _loc3_:Number = 0.5;
         var _loc4_:Point = new Point();
         var _loc5_:DisplayObject = param1.display;
         _loc4_.x = _loc5_.x + _loc5_.width * _loc3_ / 2;
         _loc4_.y = _loc5_.y + _loc5_.height * _loc3_ / 2;
         var _loc6_:Object = {
            "scaleX":_loc3_,
            "scaleY":_loc3_,
            "x":_loc4_.x,
            "y":_loc4_.y,
            "onComplete":param2
         };
         if(this._back)
         {
            _loc6_["ease"] = Back.easeOut;
         }
         TweenLite.from(param1.display,this._duration,_loc6_);
      }
      
      public function fadOut(param1:Istage, param2:Function = null) : void
      {
         var _loc3_:Number = 0.1;
         var _loc4_:Point = new Point();
         var _loc5_:DisplayObject = param1.display;
         _loc4_.x = _loc5_.x + _loc5_.width / 2 - _loc5_.width * _loc3_;
         _loc4_.y = _loc5_.y + _loc5_.height / 2 - _loc5_.height * _loc3_;
         TweenLite.to(param1.display,this._duration,{
            "scaleX":_loc3_,
            "scaleY":_loc3_,
            "x":_loc4_.x,
            "y":_loc4_.y,
            "onComplete":param2
         });
      }
   }
}

