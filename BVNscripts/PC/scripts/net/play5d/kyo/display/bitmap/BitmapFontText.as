package net.play5d.kyo.display.bitmap
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.geom.ColorTransform;
   import flash.geom.Rectangle;
   
   public class BitmapFontText extends Bitmap
   {
      
      private var _font:BitmapFont;
      
      private var _text:String;
      
      private var _orgBitmapData:BitmapData;
      
      public function BitmapFontText(param1:BitmapFont)
      {
         super(null,"auto",true);
         _font = param1;
      }
      
      public function get text() : String
      {
         return _text;
      }
      
      public function set text(param1:String) : void
      {
         _text = param1;
         bitmapData = _font.translate(param1);
         smoothing = true;
         width = bitmapData.width;
      }
      
      public function colorTransform(param1:ColorTransform) : void
      {
         if(param1 == null)
         {
            if(_orgBitmapData)
            {
               bitmapData.dispose();
               bitmapData = _orgBitmapData.clone();
            }
            return;
         }
         if(!_orgBitmapData)
         {
            _orgBitmapData = bitmapData.clone();
         }
         bitmapData.colorTransform(new Rectangle(0,0,bitmapData.width,bitmapData.height),param1);
      }
      
      public function dispose() : void
      {
         if(_orgBitmapData)
         {
            _orgBitmapData.dispose();
            _orgBitmapData = null;
         }
         bitmapData.dispose();
      }
   }
}

