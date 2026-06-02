package net.play5d.kyo.display
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   
   public class MCNumber extends Sprite
   {
      
      public var mcWidth:Number = -1;
      
      public var startFrame:int;
      
      protected var _mc:Class;
      
      protected var _mcs:Array = [];
      
      protected var _number:uint;
      
      protected var _bits:uint;
      
      public function MCNumber(param1:Class, param2:uint, param3:int = 1, param4:Number = -1, param5:uint = 0)
      {
         super();
         _mc = param1;
         _bits = param5;
         this.startFrame = param3;
         this.mcWidth = param4;
         this.number = param2;
      }
      
      public function get number() : uint
      {
         return _number;
      }
      
      public function set number(param1:uint) : void
      {
         var _loc5_:int = 0;
         var _loc4_:String = null;
         var _loc6_:DisplayObject = null;
         _number = param1;
         for each(var _loc7_ in _mcs)
         {
            removeChild(_loc7_);
         }
         _mcs = [];
         var _loc3_:String = param1.toString();
         while(_loc3_.length < _bits)
         {
            _loc3_ = "0" + _loc3_;
         }
         var _loc2_:Number = 0;
         while(_loc5_ < _loc3_.length)
         {
            _loc4_ = _loc3_.charAt(_loc5_);
            _loc6_ = createNum(int(_loc4_));
            _loc6_.x = _loc2_;
            _loc2_ += mcWidth == -1 ? _loc6_.width : mcWidth;
            _loc5_++;
         }
      }
      
      protected function createNum(param1:int) : DisplayObject
      {
         var _loc2_:MovieClip = new _mc();
         _loc2_.gotoAndStop(startFrame + param1);
         addChild(_loc2_);
         _mcs.push(_loc2_);
         return _loc2_;
      }
   }
}

