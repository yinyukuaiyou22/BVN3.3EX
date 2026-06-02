package net.play5d.kyo.utils
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   
   public class KyoTimeout
   {
      
      public static var _root:DisplayObject;
      
      private static var _functions:Vector.<Object>;
      
      public function KyoTimeout()
      {
         super();
      }
      
      public static function init(param1:Sprite) : void
      {
         _root = param1;
         _functions = new Vector.<Object>();
      }
      
      public static function setFrameout(param1:Function, param2:int, ... rest) : void
      {
         _functions.push({
            "func":param1,
            "frame":param2,
            "param":rest
         });
         setLisnter();
      }
      
      public static function setTimeout(param1:Function, param2:int, ... rest) : void
      {
         var _loc5_:int = Math.ceil(param2 / 1000 * _root.stage.frameRate);
         var _loc4_:Array = [param1,_loc5_].concat(rest);
         setFrameout.apply(null,_loc4_);
      }
      
      private static function setLisnter() : void
      {
         _root.removeEventListener("enterFrame",onEnterframe);
         _root.addEventListener("enterFrame",onEnterframe);
      }
      
      private static function onEnterframe(param1:Event) : void
      {
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         var _loc2_:Function = null;
         var _loc3_:Array = null;
         var _loc6_:int = int(_functions.length);
         if(_loc6_ < 1)
         {
            _root.removeEventListener("enterFrame",onEnterframe);
            return;
         }
         _loc4_ = 0;
         while(_loc4_ < _loc6_)
         {
            _loc5_ = _functions[_loc4_];
            if(!_loc5_)
            {
               _functions.splice(_loc4_,1);
               _loc4_ = 0;
               _loc6_ = int(_functions.length);
            }
            else
            {
               _loc2_ = _loc5_.func;
               _loc3_ = _loc5_.param;
               if(_loc5_.frame-- <= 0)
               {
                  if(_loc3_ && _loc3_.length > 0)
                  {
                     _loc2_.apply(null,_loc3_);
                  }
                  else
                  {
                     _loc2_();
                  }
                  _functions[_loc4_] = null;
               }
            }
            _loc4_++;
         }
      }
   }
}

