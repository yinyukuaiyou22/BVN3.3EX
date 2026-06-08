package net.play5d.game.bvn.ui
{
   import flash.text.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.bitmap.*;
   
   public class SetBtnDialog
   {
      
      public var ui:*;
      
      public var isShow:Boolean = true;
      
      private var _pushTxt:BitmapFontText;
      
      private var _keyNameTxt:BitmapFontText;
      
      private var _cntxt:TextField;
      
      public function SetBtnDialog()
      {
         super();
         this.ui = ResUtils.I.createDisplayObject(ResUtils.I.setting,"key_set_dialog_mc");
         this.ui.visible = false;
         this._pushTxt = new BitmapFontText(AssetManager.I.getFont("font1"));
         this._keyNameTxt = new BitmapFontText(AssetManager.I.getFont("font1"));
         this._pushTxt.y = this._keyNameTxt.y = -30;
         this._pushTxt.text = "PUSH A KEY FOR";
         this._pushTxt.x = -this._pushTxt.width / 2;
         this.ui.ct_msg.addChild(this._pushTxt);
         this.ui.ct_keyname.addChild(this._keyNameTxt);
         this._cntxt = this.ui.txt;
         this._cntxt.defaultTextFormat = new TextFormat("楷体",20);
      }
      
      public function show(param1:String, param2:String) : void
      {
         this.ui.visible = true;
         this._keyNameTxt.text = param1;
         this._keyNameTxt.x = -this._keyNameTxt.width / 2;
         this._cntxt.text = "请按下一个键设置【" + param2 + "】";
         this.isShow = true;
      }
      
      public function hide() : void
      {
         this.ui.visible = false;
         this.isShow = false;
      }
   }
}

