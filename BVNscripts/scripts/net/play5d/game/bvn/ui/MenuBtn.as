package net.play5d.game.bvn.ui
{
   import com.greensock.*;
   import com.greensock.easing.*;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.*;
   import net.play5d.kyo.display.bitmap.*;
   
   public class MenuBtn extends EventDispatcher
   {
      
      public var ui:*;
      
      public var cn:String;
      
      public var label:String;
      
      public var func:Function;
      
      public var height:Number = 75;
      
      public var index:int;
      
      public var children:Array;
      
      private var _bitmapText:BitmapFontText;
      
      private var _cnTxt:BitmapText;
      
      private var _listeners:Object = {};
      
      private var _isOpen:Boolean;
      
      public function MenuBtn(param1:String, param2:String = "", param3:Function = null)
      {
         super();
         this.cn = param2;
         this.label = param1;
         this.func = param3;
         this.ui = ResUtils.I.createDisplayObject(ResUtils.I.common_ui,"mc_wzbtn");
         this.ui.buttonMode = true;
         this.ui.mouseChildren = false;
         this._bitmapText = new BitmapFontText(AssetManager.I.getFont("font1"));
         this._bitmapText.text = param1;
         this._bitmapText.x = -this._bitmapText.width / 2;
         this.ui.addChild(this._bitmapText);
         this.ui.bg.mouseChildren = this.ui.bg.mouseEnabled = false;
         this.ui.bg.visible = false;
         if(GameUI.SHOW_CN_TEXT)
         {
            this._cnTxt = new BitmapText();
            UIUtils.formatText(this._cnTxt.textfield,{
               "font":"黑体",
               "size":18
            });
            this._cnTxt.text = param2;
            this._cnTxt.x = 10;
            this._cnTxt.y = 45;
            this.ui.bg.addChild(this._cnTxt);
         }
      }
      
      override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(Boolean(this.ui.hasEventListener(param1)))
         {
            return;
         }
         this.ui.addEventListener(param1,this.selfHandler,param3,param4,param5);
         this._listeners[param1] = param2;
      }
      
      public function removeAllEventListener() : void
      {
         var _loc1_:* = undefined;
         for(_loc1_ in this._listeners)
         {
            this.ui.removeEventListener(_loc1_,this._listeners[_loc1_]);
         }
         this._listeners = {};
      }
      
      private function selfHandler(param1:Event) : void
      {
         this._listeners[param1.type](param1.type,this);
      }
      
      public function isHover() : Boolean
      {
         return this.ui.bg.visible;
      }
      
      public function hover() : void
      {
         if(this._isOpen)
         {
            return;
         }
         if(Boolean(this.ui.bg.visible))
         {
            return;
         }
         this.ui.bg.visible = true;
         var _loc1_:Number = Number(this.ui.bg.scaleX);
         this.ui.bg.scaleX = 0.01;
         TweenLite.to(this.ui.bg,0.2,{"scaleX":_loc1_});
         SoundCtrl.I.sndSelect();
      }
      
      public function normal() : void
      {
         if(this._isOpen)
         {
            return;
         }
         this.ui.bg.visible = false;
      }
      
      public function select(param1:Function = null) : void
      {
         this.ui.alpha = -1;
         TweenLite.to(this.ui,1,{
            "alpha":1,
            "ease":Elastic.easeOut,
            "onComplete":param1
         });
         SoundCtrl.I.sndConfrim();
      }
      
      public function openChild() : void
      {
         if(this._isOpen)
         {
            return;
         }
         this._isOpen = true;
         this.ui.bg.gotoAndStop(2);
         var _loc1_:ColorTransform = new ColorTransform();
         _loc1_.redOffset = 50;
         _loc1_.greenOffset = -30;
         _loc1_.blueOffset = -30;
         this._bitmapText.colorTransform(_loc1_);
      }
      
      public function closeChild() : void
      {
         if(!this._isOpen)
         {
            return;
         }
         this._isOpen = false;
         this.ui.bg.gotoAndStop(1);
         this._bitmapText.colorTransform(null);
      }
      
      public function dispose() : void
      {
         var _loc1_:* = undefined;
         if(Boolean(this._bitmapText))
         {
            this._bitmapText.dispose();
            this._bitmapText = null;
         }
         this.removeAllEventListener();
         if(Boolean(this.children))
         {
            for each(_loc1_ in this.children)
            {
               _loc1_.dispose();
            }
            this.children = null;
         }
         if(Boolean(this._cnTxt))
         {
            this._cnTxt.destory();
            this._cnTxt = null;
         }
      }
      
      public function childMode() : void
      {
         var _loc1_:ColorTransform = new ColorTransform();
         _loc1_.redOffset = 50;
         _loc1_.greenOffset = -30;
         _loc1_.blueOffset = -30;
         this._bitmapText.colorTransform(_loc1_);
         this._bitmapText.scaleX = this._bitmapText.scaleY = 0.75;
         this._bitmapText.x = -this._bitmapText.width / 2;
         this.ui.bg.scaleY = 0.75;
         this.ui.bg.scaleX = 0.9;
         this.ui.bg.gotoAndStop(2);
         this.height = 55;
      }
   }
}

