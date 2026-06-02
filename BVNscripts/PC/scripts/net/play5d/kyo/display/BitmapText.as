package net.play5d.kyo.display
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.filters.BitmapFilter;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;
   
   public class BitmapText extends Bitmap
   {
      
      public var autoUpdate:Boolean;
      
      protected var _tf:TextField;
      
      private var _format:TextFormat = new TextFormat();
      
      private var _filers:Array;
      
      private var _width:Number = 0;
      
      private var _height:Number = 0;
      
      public function BitmapText(param1:Boolean = true, param2:uint = 0, param3:Array = null)
      {
         super();
         this.autoUpdate = param1;
         this.smoothing = true;
         _filers = param3;
         _tf = new TextField();
         this.color = param2;
      }
      
      public function multiLine(param1:Boolean) : void
      {
         _tf.multiline = param1;
         _tf.wordWrap = true;
      }
      
      override public function set width(param1:Number) : void
      {
         _width = param1;
         _tf.width = param1;
      }
      
      override public function set height(param1:Number) : void
      {
         _height = param1;
         _tf.height = param1;
      }
      
      public function get textfield() : TextField
      {
         return _tf;
      }
      
      public function get font() : String
      {
         return _format.font;
      }
      
      public function set font(param1:String) : void
      {
         _format.font = param1;
         if(autoUpdate)
         {
            update();
         }
      }
      
      public function get fontSize() : Object
      {
         return _format.size;
      }
      
      public function set fontSize(param1:Object) : void
      {
         _format.size = param1;
         if(autoUpdate)
         {
            update();
         }
      }
      
      public function get color() : uint
      {
         return _format.color as uint;
      }
      
      public function set color(param1:uint) : void
      {
         _format.color = param1;
         if(autoUpdate)
         {
            update();
         }
      }
      
      public function get align() : String
      {
         return _format.align;
      }
      
      public function set align(param1:String) : void
      {
         _format.align = param1;
      }
      
      public function get text() : String
      {
         return _tf.text;
      }
      
      public function set text(param1:String) : void
      {
         _tf.text = param1;
         if(autoUpdate)
         {
            update();
         }
      }
      
      public function setTextFormat(param1:TextFormat, param2:int = -1, param3:int = -1) : void
      {
         _tf.setTextFormat(param1,param2,param3);
         if(autoUpdate)
         {
            update();
         }
      }
      
      public function get defaultTextFormat() : TextFormat
      {
         return _format;
      }
      
      public function set defaultTextFormat(param1:TextFormat) : void
      {
         _format = param1;
         if(autoUpdate)
         {
            update();
         }
      }
      
      public function getTextWidth() : Number
      {
         return _tf.textWidth;
      }
      
      public function get textWidth() : Number
      {
         return _tf.width;
      }
      
      public function set textWidth(param1:Number) : void
      {
         _tf.width = param1;
      }
      
      public function get textHeight() : Number
      {
         return _tf.height;
      }
      
      public function set textHeight(param1:Number) : void
      {
         _tf.height = param1;
      }
      
      public function set leading(param1:Number) : void
      {
         _format.leading = param1;
      }
      
      public function set letterSpacing(param1:Number) : void
      {
         _format.letterSpacing = param1;
      }
      
      public function update() : void
      {
         if(!_tf)
         {
            return;
         }
         if(!_tf.text)
         {
            return;
         }
         var _loc2_:int = int(int(_format.size) > 0 ? int(_format.size) : 12);
         _tf.setTextFormat(_format);
         _tf.width = _width != 0 ? _width : _tf.textWidth + _loc2_;
         _tf.height = _height != 0 ? _height : _tf.textHeight + _loc2_;
         var _loc1_:BitmapData = new BitmapData(_tf.width,_tf.height,true,0);
         _loc1_.draw(_tf);
         if(_filers)
         {
            for each(var _loc3_ in _filers)
            {
               _loc1_.applyFilter(_loc1_,new Rectangle(0,0,_loc1_.width,_loc1_.height),new Point(),_loc3_);
            }
         }
         if(bitmapData)
         {
            bitmapData.dispose();
         }
         bitmapData = _loc1_;
      }
      
      public function destory() : void
      {
         try
         {
            parent.removeChild(this);
         }
         catch(e:Error)
         {
         }
         if(bitmapData)
         {
            bitmapData.dispose();
         }
         _tf = null;
      }
   }
}

