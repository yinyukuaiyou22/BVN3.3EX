package net.play5d.kyo.display.bitmap
{
   import flash.display.BitmapData;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   
   public class BitmapFont
   {
      
      public var charGap:Number = 0;
      
      public var spaceGap:Number = 0;
      
      public var offsetX:Number = 0;
      
      public var offsetY:Number = 0;
      
      private var _source:BitmapData;
      
      private var _fontCache:Object;
      
      private var _charWidth:int;
      
      private var _charHeight:int;
      
      private var _yOffsetMin:int = 999;
      
      public function BitmapFont(param1:XML, param2:BitmapData)
      {
         var _loc3_:InsCharVO = null;
         _fontCache = {};
         super();
         _source = param2;
         _charWidth = param1.info.@size;
         for each(var _loc4_ in param1.chars.char)
         {
            _loc3_ = new InsCharVO(_loc4_);
            if(_charHeight < _loc3_.height)
            {
               _charHeight = _loc3_.height;
            }
            if(_yOffsetMin > _loc3_.yoffset)
            {
               _yOffsetMin = _loc3_.yoffset;
            }
            _fontCache[_loc3_.id] = _loc3_;
         }
      }
      
      public function translate(param1:String) : BitmapData
      {
         var _loc9_:int = 0;
         var _loc8_:InsCharVO = null;
         var _loc7_:int = 0;
         var _loc4_:Rectangle = null;
         var _loc6_:Point = null;
         var _loc5_:Number = 0;
         var _loc2_:Array = [];
         _loc9_ = 0;
         while(_loc9_ < param1.length)
         {
            _loc7_ = param1.charCodeAt(_loc9_);
            if(_loc7_ == 32 && spaceGap)
            {
               _loc5_ += spaceGap;
            }
            else
            {
               _loc8_ = getChar(_loc7_);
               if(!_loc8_)
               {
                  if(_loc7_ == 32)
                  {
                     _loc5_ += _charWidth + charGap;
                  }
               }
               else
               {
                  _loc8_.x = _loc5_;
                  _loc5_ += _loc8_.width + charGap;
                  _loc2_.push(_loc8_);
               }
            }
            _loc9_++;
         }
         if(charGap < 0)
         {
            _loc5_ -= charGap;
         }
         var _loc3_:BitmapData = new BitmapData(_loc5_,_charHeight,true,0);
         _loc9_ = 0;
         while(_loc9_ < _loc2_.length)
         {
            _loc8_ = _loc2_[_loc9_];
            _loc4_ = new Rectangle(_loc8_.sx,_loc8_.sy,_loc8_.width,_loc8_.height);
            _loc6_ = new Point(_loc8_.x + offsetX,_loc8_.y + (_loc8_.yoffset - _yOffsetMin) + offsetY);
            _loc3_.copyPixels(_source,_loc4_,_loc6_,null,null,true);
            _loc9_++;
         }
         return _loc3_;
      }
      
      private function getChar(param1:int) : InsCharVO
      {
         var _loc2_:InsCharVO = _fontCache[param1];
         if(_loc2_)
         {
            return _loc2_.clone();
         }
         return null;
      }
   }
}

class InsCharVO
{
   
   public var x:Number = 0;
   
   public var y:Number = 0;
   
   public var id:String;
   
   public var sx:int;
   
   public var sy:int;
   
   public var width:int;
   
   public var height:int;
   
   public var xoffset:int;
   
   public var yoffset:int;
   
   public var xadvance:int;
   
   private var _xml:XML;
   
   public function InsCharVO(param1:XML = null)
   {
      super();
      _xml = param1;
      if(param1)
      {
         id = param1.@id;
         sx = param1.@x;
         sy = param1.@y;
         width = param1.@width;
         height = param1.@height;
         xoffset = param1.@xoffset;
         yoffset = param1.@yoffset;
         xadvance = param1.@xadvance;
      }
   }
   
   public function clone() : InsCharVO
   {
      return new InsCharVO(_xml);
   }
}
