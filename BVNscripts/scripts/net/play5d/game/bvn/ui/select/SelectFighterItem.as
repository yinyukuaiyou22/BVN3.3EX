package net.play5d.game.bvn.ui.select
{
   import com.greensock.TweenLite;
   import com.greensock.easing.Back;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.TimerEvent;
   import flash.events.TouchEvent;
   import flash.filters.GlowFilter;
   import flash.geom.*;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFieldAutoSize;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.SelectCharListItemVO;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.Debugger;

   public class SelectFighterItem extends EventDispatcher
   {

      public var selectData:SelectCharListItemVO;

      public var fighterData:FighterVO;

      // 批次6：人物子框 plugin ID 列表（透传自 SelectCharListItemVO，用于子框 UI 展开）
      public var pluginIDs:Array;

      public var ui:* = ResUtils.I.createDisplayObject(ResUtils.I.select,"slt_item_mc");

      public var position:Point = new Point();

      private var faceSize:Point = new Point(50,50);

      // 批次6.8（方案B）：人物子框 — 子框角色集合 + 8 方位网格偏移 + 展开/收起动画参数
      public var pluginFighters:Vector.<SelectFighterItem> = null;
      public var gridOffset:Point = new Point();
      public var pendingTweenParams:Object = null;
      public var pendingBack:Object = null;

      private var _badge:TextField;
      private var _badgeVisible:Boolean = false;
      private var _isBadgeAnimating:Boolean = false;

      private var _listeners:Object = {};

      // 批次6.9：触屏长按展开子框（毫秒）
      private static const LONG_PRESS_MS:int = 1200;
      private var _longPressTimer:Timer = null;
      private var _longPressed:Boolean = false;      // 长按已触发（本次手势内有效，松手即清）
      private var _pressStartTime:int = 0;
      private var _pressStartX:Number = 0;
      private var _pressStartY:Number = 0;
      private var _touching:Boolean = false;
      
      /**
       * 2026-09-29 触屏点按修复：长按后屏蔽 touchTap 的一次性标志 + 生效时间窗。
       * 原实现把屏蔽寄托在 _longPressed 上、且只在 touchTap 派发时才消费它：
       * 真机长按手指常有漂移，一旦超过 AIR 的 tap slop，touchTap 根本不派发，
       * _longPressed 就会残留到下一次手势，把之后第一次正常点按吃掉（表现为"点一下没反应"）。
       * 改为：touchEnd 时结算成一次性标志并立刻清 _longPressed，
       * guard 消费时再用 800ms 时间窗兜底（touchTap 不派发时标志最多存活 0.8s）。
       */
      private var _suppressTapOnce:Boolean = false;
      private var _suppressTapTime:Number = 0;
      private static const SUPPRESS_TAP_WINDOW_MS:int = 800;
      /** 批次6.9：长按展开回调（由 SelectFighterStage 注入，参数=本 item） */
      public var onLongPress:Function = null;

      public function SelectFighterItem(param1:FighterVO, param2:SelectCharListItemVO)
      {
         super();
         this.selectData = param2;
         this.fighterData = param1;
         this.pluginIDs = param2 ? param2.pluginIDs : null;
         if(this.pluginIDs != null && this.pluginIDs.length > 0)
         {
            Debugger.log("[SelectFighterItem]", this.fighterData.id, "plugins:", this.pluginIDs);
         }
         var _loc3_:DisplayObject = AssetManager.I.getFighterFace(param1);
         if(Boolean(_loc3_))
         {
            this.ui.ct.addChild(_loc3_);
         }
         else
         {
            // 批次6.7：face 加载失败时打印诊断 + 用角色名占位（治标）
            Debugger.log("[SelectFighterItem]", this.fighterData.id, "face MISS → use name placeholder");
            var _loc3a_:TextField = new TextField();
            _loc3a_.text = this.fighterData.id;
            _loc3a_.width = 60;
            _loc3a_.height = 30;
            _loc3a_.textColor = 0xFFFFFF;
            _loc3a_.autoSize = TextFieldAutoSize.CENTER;
            this.ui.ct.addChild(_loc3a_);
            // 批次6.7治本：face 资源未缓存时挂 ENTER_FRAME 监听，缓存就绪后自动刷新
            // 2026-10-10 修复 #1063：改挂 this.ui —— 本类的 addEventListener/removeEventListener 重写
            // 都把 selfHandler 挂在 ui 上，只有注册与注销目标一致才能删得掉；挂在 this（EventDispatcher）上
            // 会让 destory() 的注销成为空操作，监听永久残留。
            if(this.ui)
            {
               this.addEventListener(Event.ENTER_FRAME, this._refreshFace);
            }
         }
         this.ui.mouseChildren = false;
         this.ui.buttonMode = true;
         // 批次6.8（方案B）：构造 badge 角标（plugin 数量徽标）
         this.initBadge();
         // 批次6.9：触屏长按展开子框 — 原生监听 touch（不走 override addEventListener）
         if(GameConfig.TOUCH_MODE)
         {
            this.ui.addEventListener("touchBegin",this.touchLongPressBeginHandler);
            this.ui.addEventListener("touchMove",this.touchLongPressMoveHandler);
            this.ui.addEventListener("touchEnd",this.touchLongPressEndHandler);
            this.ui.addEventListener("touchTap",this.touchTapGuardHandler);
         }
      }

      // 批次6.7治本：ENTER_FRAME 轮询，命中 _cacheObj 后移除占位 + addChild 真实 face
      // ===== 2026-10-10 修复 #1063 → #1034（本函数的签名必须与「派发契约」逐参对齐）=====
      // 派发契约：本类重写的 addEventListener 把外部回调转挂到 selfHandler，
      //           selfHandler 按 selfHandler(param1.type, this) 调用，
      //           即第一个实参恒为 **String 事件类型**（ENTER_FRAME → "enterFrame"），第二个为 this。
      //           既有正确范例：SelectFighterStage.selectFighterMouseHandler(param1:String, param2:SelectFighterItem)
      // 历史错误①：#1063 —— 原签名只声明 1 个参数，派发传 2 个 → ArgumentError（参数个数不匹配）。
      // 历史错误②：#1034 —— 补成 2 参时把首参类型写成 Event，而实际传入的是 String
      //           → TypeError: cannot convert "enterFrame" to flash.events.Event。
      //           ⚠️ AS3 在进入函数体**之前**就完成形参类型转换，因此异常会打断整个回调：
      //              face 替换逻辑永不执行（占位文字一直留着），且方法开头的解绑也执行不到，
      //              ENTER_FRAME 监听永久残留 → 每帧抛错 + 每帧无谓轮询。
      // 正确写法：首参类型必须是 String（本函数不使用该参数，仅作签名占位）。
      //           其它任何注册进本类 addEventListener 的回调，首参也必须是 String。
      private function _refreshFace(param1:String, param2:Object = null) : void
      {
         if(!this.ui || !this.fighterData)
         {
            return;
         }
         var _loc2_:DisplayObject = AssetManager.I.getFighterFace(this.fighterData);
         if(!_loc2_)
         {
            return;   // 面图尚未就绪：保留 ENTER_FRAME 监听，下一帧继续轮询
         }
         // face 已就绪：先解绑（成功只执行一次），再替换占位
         this.removeEventListener(Event.ENTER_FRAME, this._refreshFace);
         // 移除占位 TextField（ui.ct 只含 1 个占位 TextField）
         while(this.ui.ct.numChildren > 0)
         {
            this.ui.ct.removeChildAt(0);
         }
         this.ui.ct.addChild(_loc2_);
         Debugger.log("[SelectFighterItem]", this.fighterData.id, "face REFRESHED (治本)");
      }

      // ============ 批次6.8（方案B）：badge 角标 + 子框展开/收起 ============

      private function initBadge() : void
      {
         _badge = new TextField();
         _badge.autoSize = TextFieldAutoSize.CENTER;
         // 2026-09-01: 数字显示样式统一调整为冷色调 #b8e6e6
         // 字色: 纯白(0xFFFFFF) → 冷浅青(0xB8E6E6)
         // 描边色: 纯黑(0x000000) → 深青绿(0x1A4040), 保持黑底高对比
         _badge.textColor = 0xB8E6E6;
         _badge.selectable = false;
         _badge.mouseEnabled = false;
         var fmt:TextFormat = new TextFormat();
         fmt.size = 14;
         fmt.bold = true;
         fmt.font = "Arial";
         _badge.defaultTextFormat = fmt;
         _badge.setTextFormat(fmt);
         var stroke:GlowFilter = new GlowFilter(0x1A4040,1,1.5,1.5,3,1,false);
         _badge.filters = [stroke];
         _badge.alpha = 0;
         _badge.visible = true;
         _badgeVisible = false;
         if(this.ui)
         {
            var uiWidth:Number = this.ui.width ? Number(this.ui.width) : 60;
            _badge.x = uiWidth - _badge.width - 8;
            _badge.y = -2;
            this.ui.addChild(_badge);
         }
      }

      public function updateBadge(count:int) : void
      {
         var uiWidth:Number;
         if(!_badge) return;
         if(_isBadgeAnimating)
         {
            TweenLite.killTweensOf(_badge);
            _isBadgeAnimating = false;
         }
         if(count > 0)
         {
            _badge.text = count + "+";
            _badgeVisible = true;
            if(this.ui)
            {
               uiWidth = this.ui.width ? Number(this.ui.width) : 60;
               _badge.x = uiWidth - _badge.width - 10;
               _badge.y = -5;
            }
            _badge.alpha = 0;
            _badge.visible = true;
            _isBadgeAnimating = true;
            TweenLite.to(_badge,0.3,{
               "alpha":1,
               "onComplete":function():void { _isBadgeAnimating = false; }
            });
         }
         else
         {
            _badgeVisible = false;
            if(_badge.visible && _badge.alpha > 0)
            {
               _isBadgeAnimating = true;
               TweenLite.to(_badge,0.2,{
                  "alpha":0,
                  "onComplete":function():void
                  {
                     _badge.visible = false;
                     _isBadgeAnimating = false;
                  }
               });
            }
            else
            {
               _badge.visible = false;
               _badge.alpha = 0;
            }
         }
      }

      public function hideBadge() : void
      {
         if(!_badge || !_badgeVisible) return;
         if(_isBadgeAnimating)
         {
            TweenLite.killTweensOf(_badge);
            _isBadgeAnimating = false;
         }
         if(_badge.visible && _badge.alpha > 0)
         {
            _isBadgeAnimating = true;
            TweenLite.to(_badge,0.2,{
               "alpha":0,
               "onComplete":function():void
               {
                  _badge.visible = false;
                  _isBadgeAnimating = false;
               }
            });
         }
         else
         {
            _badge.visible = false;
            _badge.alpha = 0;
         }
      }

      public function showBadge() : void
      {
         if(!_badge || !_badgeVisible) return;
         if(_isBadgeAnimating)
         {
            TweenLite.killTweensOf(_badge);
            _isBadgeAnimating = false;
         }
         _badge.alpha = 0;
         _badge.visible = true;
         _isBadgeAnimating = true;
         TweenLite.to(_badge,0.3,{
            "alpha":1,
            "onComplete":function():void { _isBadgeAnimating = false; }
         });
      }

      private function applyGlow(target:DisplayObject) : void
      {
         if(!target) return;
         // 2026-09-01: 子框角色整体高亮白光 → 冷浅青 #b8e6e6, 与 badge 角标色系统一
         var glow:GlowFilter = new GlowFilter(0xB8E6E6,0.8,8,8,3);
         target.filters = [glow];
      }

      private function removeGlow(target:DisplayObject) : void
      {
         if(!target) return;
         target.filters = [];
      }

      // 展开子框：子框角色显示 + 白色高亮 + TweenLite 弹到目标网格位
      public function showPlugins() : void
      {
         if(!pluginFighters) return;
         hideBadge();
         var i:int = 0;
         while(i < pluginFighters.length)
         {
            var plugin:SelectFighterItem = pluginFighters[i];
            plugin.ui.visible = true;
            applyGlow(plugin.ui);
            if(plugin.ui.parent)
            {
               plugin.ui.parent.setChildIndex(plugin.ui,plugin.ui.parent.numChildren - 1);
            }
            if(plugin.pendingTweenParams)
            {
               var p:Object = plugin.pendingTweenParams;
               TweenLite.to(plugin.ui,0.3,{
                  "x":p.x,
                  "y":p.y,
                  "delay":p.delay,
                  "alpha":1,
                  "scaleX":1,
                  "scaleY":1,
                  "ease":Back.easeOut
               });
            }
            i++;
         }
      }

      // 收起子框：子框角色收回原位 + 清光 + 恢复 badge
      public function closePlugins() : void
      {
         if(!pluginFighters) return;
         var i:int = 0;
         while(i < pluginFighters.length)
         {
            var plugin:SelectFighterItem = pluginFighters[i];
            removeGlow(plugin.ui);
            if(plugin.pendingBack)
            {
               var p:Object = plugin.pendingBack;
               TweenLite.to(plugin.ui,0.3,{
                  "x":p.x,
                  "y":p.y,
                  "delay":p.delay,
                  "alpha":0,
                  "scaleX":0,
                  "scaleY":0,
                  "ease":Back.easeOut
               });
            }
            i++;
         }
         showBadge();
      }

      // ============ 批次6.9：触屏长按展开子框 ============

      // 按下启动 1.3s 计时
      private function touchLongPressBeginHandler(param1:TouchEvent) : void
      {
         // 2026-09-29：早退条件去掉 _longPressed（残留会阻塞后续长按计时），
         // 长按是否已成立改由 touchEnd 结算的一次性标志 _suppressTapOnce 承载
         if(!GameConfig.TOUCH_MODE) return;
         _touching = true;
         _pressStartTime = getTimer();
         _pressStartX = param1.stageX;
         _pressStartY = param1.stageY;
         if(!_longPressTimer)
         {
            _longPressTimer = new Timer(LONG_PRESS_MS,1);
            _longPressTimer.addEventListener(TimerEvent.TIMER,longPressTimerHandler);
         }
         _longPressTimer.reset();
         _longPressTimer.start();
      }

      // 长按中手指滑出阈值 → 取消计时（防误触）
      private function touchLongPressMoveHandler(param1:TouchEvent) : void
      {
         if(!_touching || !_longPressTimer || !_longPressTimer.running) return;
         var dx:Number = param1.stageX - _pressStartX;
         var dy:Number = param1.stageY - _pressStartY;
         if(dx * dx + dy * dy > 400)   // 20px 阈值
         {
            _longPressTimer.stop();
            _touching = false;
         }
      }

      // 松手 — 取消计时；本次手势若已长按展开，结算成一次性标志交给 touchTapGuardHandler
      private function touchLongPressEndHandler(param1:TouchEvent) : void
      {
         _touching = false;
         if(_longPressTimer && _longPressTimer.running)
         {
            _longPressTimer.stop();
         }
         // 2026-09-29：手势结束即结算 —— 不再让 _longPressed 跨手势残留
         if(_longPressed)
         {
            _suppressTapOnce = true;
            _suppressTapTime = getTimer();
            _longPressed = false;
         }
      }

      // 计时到点 → 展开子框 + 通知 Stage 记录归属
      private function longPressTimerHandler(param1:TimerEvent) : void
      {
         _longPressed = true;
         _touching = false;
         if(this.onLongPress != null)
         {
            try { this.onLongPress(this); } catch(e:Error) {}
         }
         else
         {
            // 兜底：无回调时直接自展开
            this.showPlugins();
         }
      }

      // 长按展开后，屏蔽本次松手的 touchTap（防误选中）
      private function touchTapGuardHandler(param1:TouchEvent) : void
      {
         // 2026-09-29：消费一次性标志；加 800ms 时间窗兜底 —— 若长按后手指漂移导致 touchTap
         // 延迟很久才来（或根本不来），标志不会一路吃掉之后久远的正常点击
         if(_suppressTapOnce)
         {
            _suppressTapOnce = false;
            if(getTimer() - _suppressTapTime < SUPPRESS_TAP_WINDOW_MS)
            {
               param1.stopImmediatePropagation();
            }
         }
      }

      // 批次6.15 修复：原判据 ui.hasEventListener(type) 会被构造器直挂的长按监听
      // （touchBegin/touchMove/touchEnd/touchTap）误判为"已注册"而静默 return，
      // 导致 SelectFighterStage 的 touchTap 回调（角色格唯一触摸入口）从未挂上，单击格子无反应。
      // 改为以本类登记表 _listeners 为判据：selfHandler 每类型只挂一次，外部回调每次覆盖记录。
      override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(this._listeners[param1] == null)
         {
            this.ui.addEventListener(param1,this.selfHandler,param3,param4,param5);
         }
         this._listeners[param1] = param2;
      }
      
      // 批次6.15 修复：补对称注销。原实现缺本重写，挂在 ui 上的是 selfHandler 而非外部回调，
      // 导致 _refreshFace 的 removeEventListener(ENTER_FRAME) 落到 EventDispatcher 自身成为空操作，
      // 于是 face 就绪后仍每帧清空 ui.ct 重加 face + 每帧写一条日志（选人界面卡顿/日志刷屏根因）。
      // 2026-10-10：加 ui 空值守卫 —— destory() 会先置 this.ui = null，而本方法随后仍可能被调用
      // （见 destory 末尾的 ENTER_FRAME 清理），不加守卫会抛 #1009 空对象引用。
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
      
      public function destory() : void
      {
         // 批次6.9：清理触屏长按计时器与监听
         if(_longPressTimer)
         {
            _longPressTimer.stop();
            _longPressTimer.removeEventListener(TimerEvent.TIMER,longPressTimerHandler);
            _longPressTimer = null;
         }
         _touching = false;
         _longPressed = false;
         _suppressTapOnce = false;
         onLongPress = null;
         if(Boolean(this.ui))
         {
            this.ui.removeEventListener("touchBegin",this.touchLongPressBeginHandler);
            this.ui.removeEventListener("touchMove",this.touchLongPressMoveHandler);
            this.ui.removeEventListener("touchEnd",this.touchLongPressEndHandler);
            this.ui.removeEventListener("touchTap",this.touchTapGuardHandler);
            // 2026-10-10：ENTER_FRAME 清理必须在 this.ui = null 之前 —— 本方法下面会先置 ui = null，
            // 而重写后的 removeEventListener 需要 ui 才能删掉挂在 ui 上的 selfHandler；
            // 放在末尾（原位置）会因 ui 已为 null 而删不掉，_refreshFace 在 destory 后仍会每帧轮询。
            this.removeEventListener(Event.ENTER_FRAME, this._refreshFace);
            this.removeAllEventListener();
         }
         // 批次6.8（方案B）：清理 badge 角标（含未完成动画）
         if(Boolean(_badge))
         {
            TweenLite.killTweensOf(_badge);
            if(Boolean(this.ui) && Boolean(this.ui.contains(_badge)))
            {
               this.ui.removeChild(_badge);
            }
            _badge = null;
            _badgeVisible = false;
            _isBadgeAnimating = false;
         }
         if(Boolean(this.ui) && Boolean(this.ui.parent))
         {
            try
            {
               this.ui.parent.removeChild(this.ui);
            }
            catch(e:Error)
            {
            }
            this.ui = null;
         }
         // 批次6.8（方案B）：清理子框角色引用
         this.pluginFighters = null;
         this.pendingTweenParams = null;
         this.pendingBack = null;
         // 批次6.7治本：ENTER_FRAME 清理已上移到 this.ui = null 之前（见上），此处不再重复注销
      }
   }
}
