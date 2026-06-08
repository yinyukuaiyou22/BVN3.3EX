package net.play5d.game.bvn.ui
{
   import fl.motion.*;
   import flash.display.Sprite;
   import flash.filters.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.kyo.display.bitmap.*;
   import net.play5d.kyo.input.*;
   
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
         this._keyTxt = new BitmapFontText(AssetManager.I.getFont("font1"));
         var _loc5_:ColorMatrix = new ColorMatrix();
         _loc5_.SetBrightnessMatrix(-100);
         _loc5_.SetSaturationMatrix(0);
         this._keyTxt.filters = [new ColorMatrixFilter(_loc5_.GetFlatArray())];
         param1.addChild(this._keyTxt);
      }
      
      public function setKey(param1:int, param2:String = null) : void
      {
         if(!param2)
         {
            param2 = KyoKeyCode.code2name(param1);
         }
         this._keyTxt.text = param2.toUpperCase();
         var _loc3_:Number = 0;
         var _loc4_:Number = 1;
         var _loc5_:Number = 0;
         if(this.keyId == "up" || this.keyId == "down" || this.keyId == "left" || this.keyId == "right")
         {
            _loc4_ = 0.8;
            _loc3_ = 40;
            _loc5_ = 5;
         }
         else
         {
            _loc3_ = 60;
         }
         if(this._keyTxt.width > _loc3_)
         {
            this._keyTxt.width = _loc3_;
            this._keyTxt.scaleY = this._keyTxt.scaleX;
         }
         else
         {
            this._keyTxt.scaleX = this._keyTxt.scaleY = _loc4_;
         }
         this._keyTxt.x = -this._keyTxt.width / 2;
         this._keyTxt.y = -this._keyTxt.height / 2 + _loc5_;
      }
   }
}

