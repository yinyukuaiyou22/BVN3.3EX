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
      
      // 批次6.15 修复：与 SelectFighterItem 同形缺陷——原判据 ui.hasEventListener(type) 会被
      // 任何"直挂在 ui 上"的同类监听误判为已注册而静默 return，吞掉外部回调。
      // 本类构造器当前未直挂 ui，属潜伏隐患，一并改为以 _listeners 登记表为判据。
      override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(this._listeners[param1] == null)
         {
            this.ui.addEventListener(param1,this.selfHandler,param3,param4,param5);
         }
         this._listeners[param1] = param2;
      }
      
      // 批次6.15 修复：补对称注销（挂在 ui 上的是 selfHandler，原实现删的是外部回调 → 空操作、清理失效）
      // 2026-10-10：加 ui 空值守卫，与 SelectFighterItem 同形防御 —— 对象销毁后 ui 可能已为 null，
      // 此时若仍有回调触发注销会抛 #1009 空对象引用。
      override public function removeEventListener(param1:String, param2:Function, param3:Boolean = false) : void
      {
         if(this._listeners[param1] == null)
         {
            return;
         }
         delete this._listeners[param1];
         if(this.ui == null)
         {
            return;
         }
         this.ui.removeEventListener(param1,this.selfHandler,param3);
      }
      
      public function removeAllEventListener() : void
      {
         // 先快照 key 再逐个注销：避免边遍历 _listeners 边 delete 造成漏项
         var _loc1_:Array = [];
         var _loc2_:* = undefined;
         for(_loc2_ in this._listeners)
         {
            _loc1_.push(_loc2_);
         }
         var _loc3_:int = 0;
         while(_loc3_ < _loc1_.length)
         {
            this.removeEventListener(_loc1_[_loc3_] as String,null);
            _loc3_++;
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

