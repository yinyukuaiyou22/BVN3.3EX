package net.play5d.game.bvn.ui
{
   import fl.motion.ColorMatrix;
   import flash.display.Sprite;
   import flash.filters.ColorMatrixFilter;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.kyo.display.bitmap.BitmapFontText;
   import net.play5d.kyo.input.KyoKeyCode;
   
   public class KeyMapping
   {
      
      public var name:String;
      
      public var mc:Sprite;
      
      public var keyId:String;
      
      public var cn:String;
      
      private var _keyTxt:BitmapFontText;
      
      public function KeyMapping(param1:Sprite, param2:String, param3:String, param4:String)
      {
         super();
         this.mc = param1;
         this.keyId = param2;
         this.name = param3;
         this.cn = param4;
         _keyTxt = new BitmapFontText(AssetManager.I.getFont("font1"));
         var _loc5_:ColorMatrix = new ColorMatrix();
         _loc5_.SetBrightnessMatrix(-100);
         _loc5_.SetSaturationMatrix(0);
         _keyTxt.filters = [new ColorMatrixFilter(_loc5_.GetFlatArray())];
         param1.addChild(_keyTxt);
      }
      
      public function setKey(param1:int, param2:String = null) : void
      {
         if(!param2)
         {
            param2 = KyoKeyCode.code2name(param1);
         }
         _keyTxt.text = param2.toUpperCase();
         var _loc3_:int = 0;
         var _loc4_:* = 1;
         var _loc5_:int = 0;
         if(keyId == "up" || keyId == "down" || keyId == "left" || keyId == "right")
         {
            _loc4_ = 0.8;
            _loc3_ = 40;
            _loc5_ = 5;
         }
         else
         {
            _loc3_ = 60;
         }
         if(_keyTxt.width > _loc3_)
         {
            _keyTxt.width = _loc3_;
            _keyTxt.scaleY = _keyTxt.scaleX;
         }
         else
         {
            _keyTxt.scaleX = _keyTxt.scaleY = _loc4_;
         }
         _keyTxt.x = -_keyTxt.width * 0.5;
         _keyTxt.y = -_keyTxt.height * 0.5 + _loc5_;
      }
   }
}

