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
      
      /** 统一列宽时，文字距背景条左缘的间距（MenuBtnGroup 排版用） */
      public static const TEXT_PAD:Number = 16;
      
      private var _bitmapText:BitmapFontText;
      
      private var _cnTxt:BitmapText;
      
      private var _listeners:Object = {};
      
      private var _isOpen:Boolean;
      
      /** 背景条原始美术宽度（构造时测量，用于统一列宽的等比拉伸） */
      private var _orgBgW:Number = 0;
      
      /** 背景条原始左缘（ui 坐标系，构造时测量，此时 bg 里还没有副标题） */
      private var _orgBgLeft:Number = 0;
      
      /** 当前背景条左缘，文字靠左对齐的基准 */
      private var _bgLeft:Number = 0;
      
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
         // 统一列宽需要在构造时量到「纯美术框」的宽与左缘：此刻 bg 里还没塞中文副标题，
         // 晚一步量到的 bounds 会被字宽撑大。左缘随 scaleX 线性变化，所以只需记一次基准值。
         this._orgBgW = this.ui.bg.width;
         this._orgBgLeft = this.ui.bg.getBounds(this.ui).left;
         this._bgLeft = this._orgBgLeft;
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
         // 2026-11-12：展开子列时隐藏中文副标题。
         // 子列起点就是父项的 y，而父项的 cn 固定在 y=45，两者必然撞在一起
         // （真机表现：OPTION 底下的「设置」和第一项 GAME CFG 糊成一团）。
         if(Boolean(this._cnTxt))
         {
            this._cnTxt.visible = false;
         }
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
         // 与 openChild() 配对：收起后把中文副标题显示回来
         if(Boolean(this._cnTxt))
         {
            this._cnTxt.visible = true;
         }
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
         // 宽度与文字位置统一交给 setWidth()/alignLeft() 负责（列宽是整列算出来的，不在这里定）
         this.ui.bg.scaleY = 0.75;
         this.ui.bg.gotoAndStop(2);
         // 2026-11-12：子项高度必须容得下 y=45 处的中文副标题。
         // 原值 55 只够背景条（80×0.75=60 已超出），中文副标题一压上去就和
         // 下一项贴在一起（真机表现为二级菜单「拥挤、字挤在一起」）。
         // 66 给到「背景条 60 + 6 呼吸」，行距 ROW_GAP 之外还有余量。
         this.height = 66;
      }
      
      /**
       * 统一列宽：把背景条等比拉到 param1，并把文字重新靠左对齐。
       * param1 <= 0 表示不做统一宽度（退回「各自宽度 + 左缘对齐」模式，用于美术被拉花的退路）。
       */
      public function setWidth(param1:Number) : void
      {
         if(param1 <= 0 || !Boolean(this.ui) || !Boolean(this.ui.bg) || this._orgBgW <= 0)
         {
            return;
         }
         this.ui.bg.width = param1;
         // 左缘随 scaleX 线性位移：左对齐锚点得到 0，居中锚点得到 -w/2，无需假设注册点在哪
         this._bgLeft = this._orgBgLeft * (param1 / this._orgBgW);
         this.alignLeft();
      }
      
      /** 文字靠左：英文标签与中文副标题都对齐到背景条左缘 + TEXT_PAD */
      public function alignLeft() : void
      {
         if(Boolean(this._bitmapText))
         {
            this._bitmapText.x = this._bgLeft + TEXT_PAD;
         }
         if(Boolean(this._cnTxt))
         {
            this._cnTxt.x = this._bgLeft + TEXT_PAD;
         }
      }
      
      /**
       * 背景条左缘相对 ui 原点的 X 偏移。
       *
       * `mc_wzbtn` 是**中心注册**的美术：按钮放在 x=24 时，按钮中心在 24，左半截会跑到屏幕外
       * （本次「按钮一半卡在左边」的成因）。排版要的是「背景条左缘对齐 MARGIN_LEFT」，
       * 所以摆位时用 `x = 目标左缘 - bgOffsetX`（居中注册点为 −w/2，左对齐注册点为 0，自适应）。
       */
      public function get bgOffsetX() : Number
      {
         return this._bgLeft;
      }
      
      /** 标签宽度（已包含 childMode 的 0.75 缩放），供 MenuBtnGroup 量列宽 */
      public function get measuredWidth() : Number
      {
         return Boolean(this._bitmapText) ? this._bitmapText.width : 0;
      }
   }
}

