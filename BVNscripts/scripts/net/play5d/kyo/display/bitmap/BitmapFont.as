package net.play5d.kyo.display.bitmap
{
   import flash.display.*;
   import flash.geom.*;
   
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
         var _loc3_:XML = null;
         var _loc4_:InsCharVO = null;
         this._fontCache = {};
         super();
         this._source = param2;
         this._charWidth = param1.info.@size;
         for each(_loc3_ in param1.chars.char)
         {
            _loc4_ = new InsCharVO(_loc3_);
            if(this._charHeight < _loc4_.height)
            {
               this._charHeight = _loc4_.height;
            }
            if(this._yOffsetMin > _loc4_.yoffset)
            {
               this._yOffsetMin = _loc4_.yoffset;
            }
            this._fontCache[_loc4_.id] = _loc4_;
         }
      }
      
      public function translate(param1:String) : BitmapData
      {
         var _loc2_:int = 0;
         var _loc3_:InsCharVO = null;
         var _loc4_:int = 0;
         var _loc5_:Rectangle = null;
         var _loc6_:Point = null;
         var _loc7_:Number = 0;
         var _loc8_:Array = [];
         _loc2_ = 0;
         while(_loc2_ < param1.length)
         {
            _loc4_ = int(param1.charCodeAt(_loc2_));
            if(_loc4_ == 32 && Boolean(this.spaceGap))
            {
               _loc7_ += this.spaceGap;
            }
            else
            {
               _loc3_ = this.getChar(_loc4_);
               if(!_loc3_)
               {
                  if(_loc4_ == 32)
                  {
                     _loc7_ += this._charWidth + this.charGap;
                  }
               }
               else
               {
                  _loc3_.x = _loc7_;
                  _loc7_ += _loc3_.width + this.charGap;
                  _loc8_.push(_loc3_);
               }
            }
            _loc2_++;
         }
         if(this.charGap < 0)
         {
            _loc7_ -= this.charGap;
         }
         var _loc9_:BitmapData = new BitmapData(_loc7_,this._charHeight,true,0);
         _loc2_ = 0;
         while(_loc2_ < _loc8_.length)
         {
            _loc3_ = _loc8_[_loc2_];
            _loc5_ = new Rectangle(_loc3_.sx,_loc3_.sy,_loc3_.width,_loc3_.height);
            _loc6_ = new Point(_loc3_.x + this.offsetX,_loc3_.y + (_loc3_.yoffset - this._yOffsetMin) + this.offsetY);
            _loc9_.copyPixels(this._source,_loc5_,_loc6_,null,null,true);
            _loc2_++;
         }
         return _loc9_;
      }
      
      private function getChar(param1:int) : InsCharVO
      {
         var _loc2_:InsCharVO = this._fontCache[param1];
         if(Boolean(_loc2_))
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
      this._xml = param1;
      if(Boolean(param1))
      {
         this.id = param1.@id;
         this.sx = param1.@x;
         this.sy = param1.@y;
         this.width = param1.@width;
         this.height = param1.@height;
         this.xoffset = param1.@xoffset;
         this.yoffset = param1.@yoffset;
         this.xadvance = param1.@xadvance;
      }
   }
   
   public function clone() : InsCharVO
   {
      return new InsCharVO(this._xml);
   }
}
