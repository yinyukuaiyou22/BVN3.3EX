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
      private var _longPressed:Boolean = false;      // 长按已触发（松手时屏蔽 touchTap）
      private var _pressStartTime:int = 0;
      private var _pressStartX:Number = 0;
      private var _pressStartY:Number = 0;
      private var _touching:Boolean = false;
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
            this.addEventListener(Event.ENTER_FRAME, this._refreshFace);
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
      private function _refreshFace(param1:Event) : void
      {
         if(!this.ui || !this.fighterData)
         {
            return;
         }
         var _loc2_:DisplayObject = AssetManager.I.getFighterFace(this.fighterData);
         if(Boolean(_loc2_))
         {
            // 移除占位 TextField（ui.ct 可能含 1 个 TextField）
            if(this.ui.ct.numChildren > 0)
            {
               while(this.ui.ct.numChildren > 0)
               {
                  this.ui.ct.removeChildAt(0);
               }
            }
            this.ui.ct.addChild(_loc2_);
            this.removeEventListener(Event.ENTER_FRAME, this._refreshFace);
            Debugger.log("[SelectFighterItem]", this.fighterData.id, "face REFRESHED (治本)");
         }
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
         if(!GameConfig.TOUCH_MODE || _longPressed) return;
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

      // 松手 — 若未到点则取消计时；长按已展开由 touchTapGuardHandler 屏蔽本次 touchTap
      private function touchLongPressEndHandler(param1:TouchEvent) : void
      {
         _touching = false;
         if(_longPressTimer && _longPressTimer.running)
         {
            _longPressTimer.stop();
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
         if(_longPressed)
         {
            _longPressed = false;
            param1.stopImmediatePropagation();
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
         onLongPress = null;
         if(Boolean(this.ui))
         {
            this.ui.removeEventListener("touchBegin",this.touchLongPressBeginHandler);
            this.ui.removeEventListener("touchMove",this.touchLongPressMoveHandler);
            this.ui.removeEventListener("touchEnd",this.touchLongPressEndHandler);
            this.ui.removeEventListener("touchTap",this.touchTapGuardHandler);
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
         // 批次6.7治本：清理 ENTER_FRAME 监听，避免 _refreshFace 在 destory 后还在轮询（内存泄漏）
         this.removeEventListener(Event.ENTER_FRAME, this._refreshFace);
      }
   }
}
