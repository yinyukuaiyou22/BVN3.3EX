package net.play5d.game.bvn.ui
{
   import com.greensock.TweenLite;
   import com.greensock.easing.Elastic;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.geom.ColorTransform;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.kyo.display.BitmapText;
   import net.play5d.kyo.display.bitmap.BitmapFontText;
   
   public class MenuBtn extends EventDispatcher
   {
      
      public var ui:MovieClip;
      
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
         this.label = param1;
         this.cn = param2;
         this.func = param3;
         ui = AssetManager.I.createObject("mc_wzbtn","subswfs/common_ui.swf") as MovieClip;
         ui.buttonMode = true;
         ui.mouseChildren = false;
         _bitmapText = new BitmapFontText(AssetManager.I.getFont("font1"));
         _bitmapText.text = param1;
         _bitmapText.x = -_bitmapText.width * 0.5;
         ui.addChild(_bitmapText);
         ui.bg.mouseEnabled = false;
         ui.bg.mouseChildren = false;
         ui.bg.visible = false;
         if(GameUI.SHOW_CN_TEXT)
         {
            _cnTxt = new BitmapText();
            UIUtils.formatText(_cnTxt.textfield,{
               "font":"Microsoft YaHei",
               "size":16,
               "bold":true
            });
            _cnTxt.text = param2;
            _cnTxt.x = -_cnTxt.width * 0.5;
            _cnTxt.y = 45;
            ui.bg.addChild(_cnTxt);
         }
      }
      
      override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(ui.hasEventListener(param1))
         {
            return;
         }
         ui.addEventListener(param1,selfHandler,param3,param4,param5);
         _listeners[param1] = param2;
      }
      
      public function removeAllEventListener() : void
      {
         for(var _loc1_ in _listeners)
         {
            ui.removeEventListener(_loc1_,_listeners[_loc1_]);
         }
         _listeners = {};
      }
      
      private function selfHandler(param1:Event) : void
      {
         _listeners[param1.type](param1.type,this);
      }
      
      public function isHover() : Boolean
      {
         return ui.bg.visible;
      }
      
      public function hover() : void
      {
         if(_isOpen)
         {
            return;
         }
         if(ui.bg.visible)
         {
            return;
         }
         ui.bg.visible = true;
         var _loc1_:Number = 1;
         ui.bg.scaleX = 0.01;
         TweenLite.to(ui.bg,0.25,{"scaleX":_loc1_});
         SoundCtrl.I.sndSelect();
      }
      
      public function normal() : void
      {
         if(_isOpen)
         {
            return;
         }
         ui.bg.visible = false;
      }
      
      public function select(param1:Function = null) : void
      {
         ui.alpha = -1;
         TweenLite.to(ui,1,{
            "alpha":1,
            "ease":Elastic.easeOut,
            "onComplete":param1
         });
         SoundCtrl.I.sndConfrim();
      }
      
      public function openChild() : void
      {
         if(_isOpen)
         {
            return;
         }
         _isOpen = true;
         ui.bg.gotoAndStop(2);
         var _loc1_:ColorTransform = new ColorTransform();
         _loc1_.redOffset = 50;
         _loc1_.greenOffset = -30;
         _loc1_.blueOffset = -30;
         _bitmapText.colorTransform(_loc1_);
      }
      
      public function closeChild() : void
      {
         if(!_isOpen)
         {
            return;
         }
         _isOpen = false;
         ui.bg.gotoAndStop(1);
         _bitmapText.colorTransform(null);
      }
      
      public function dispose() : void
      {
         if(_bitmapText)
         {
            _bitmapText.dispose();
            _bitmapText = null;
         }
         removeAllEventListener();
         if(children)
         {
            for each(var _loc1_ in children)
            {
               _loc1_.dispose();
            }
            children = null;
         }
         if(_cnTxt)
         {
            _cnTxt.destory();
            _cnTxt = null;
         }
      }
      
      public function childMode() : void
      {
         var _loc1_:ColorTransform = new ColorTransform();
         _loc1_.redOffset = 50;
         _loc1_.greenOffset = -30;
         _loc1_.blueOffset = -30;
         _bitmapText.colorTransform(_loc1_);
         _bitmapText.scaleY = 0.75;
         _bitmapText.scaleX = 0.75;
         _bitmapText.x = -_bitmapText.width * 0.5;
         ui.bg.scaleY = 0.75;
         ui.bg.scaleX = 0.9;
         ui.bg.gotoAndStop(2);
         height = 55;
         _cnTxt.y -= 1;
         _cnTxt.scaleX = 0.9;
         _cnTxt.scaleY = 1.05;
         _cnTxt.text = cn;
      }
   }
}

