package net.play5d.game.bvn.ui.select
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.filters.GlowFilter;
   import flash.geom.*;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.SelectCharListItemVO;
   import net.play5d.game.bvn.utils.*;
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

      // 批次6.2：人物子框容器（plugin 子 Sprite 集合）+ 墨绿色光常量
      private var _pluginContainer:Sprite;
      private static const _PLUGIN_GLOW_COLOR:uint = 0x1B5E20;
      private static const _PLUGIN_SUB_SIZE:int = 18;
      private static const _PLUGIN_SUB_GAP:int = 2;

      private var _listeners:Object = {};

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
         // 批次6.2：构造 plugin 子框 UI（仅在 pluginIDs 非空时）
         this._initPluginSubUI();
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

      // 批次6.2/6.3：构建 plugin 子框 UI 资源（仅准备，默认隐藏；6.3 起由 show/hide 控制）
      private function _initPluginSubUI() : void
      {
         if(!this.pluginIDs || this.pluginIDs.length < 1)
         {
            return;
         }
         // 1. 构造 plugin 子 Sprite 容器（沿主 ui 右侧排列，y 偏移 3px 形成"子框"错位感）
         this._pluginContainer = new Sprite();
         this._pluginContainer.x = 3;
         this._pluginContainer.y = 3;
         this._pluginContainer.mouseEnabled = false;
         this._pluginContainer.mouseChildren = false;
         var _loc3_:int = 0;
         while(_loc3_ < this.pluginIDs.length)
         {
            var _loc4_:Sprite = new Sprite();
            _loc4_.x = _loc3_ * (_PLUGIN_SUB_SIZE + _PLUGIN_SUB_GAP);
            _loc4_.y = 0;
            // 子框背景（深墨绿半透 0x1B5E20 alpha 0.35）
            _loc4_.graphics.beginFill(_PLUGIN_GLOW_COLOR,0.35);
            _loc4_.graphics.drawRect(0,0,_PLUGIN_SUB_SIZE,_PLUGIN_SUB_SIZE);
            _loc4_.graphics.endFill();
            // 子框边框（墨绿实线 1px）
            _loc4_.graphics.lineStyle(1,_PLUGIN_GLOW_COLOR,1);
            _loc4_.graphics.drawRect(0,0,_PLUGIN_SUB_SIZE,_PLUGIN_SUB_SIZE);
            this._pluginContainer.addChild(_loc4_);
            _loc3_++;
         }
         // 6.3：默认隐藏，等 SelectFighterStage.doHover/doSelect 触发
      }

      // 批次6.3：展开 plugin 子框（墨绿光 + 容器可见）
      public function showPluginSub() : void
      {
         if(!this._pluginContainer || !this.pluginIDs || this.pluginIDs.length < 1)
         {
            return;
         }
         if(this.ui.filters == null || this.ui.filters.length < 1)
         {
            this.ui.filters = [new GlowFilter(_PLUGIN_GLOW_COLOR,0.85,5,5,2,1,false,false)];
         }
         if(!this.ui.contains(this._pluginContainer))
         {
            this.ui.addChild(this._pluginContainer);
            Debugger.log("[Plugin]", this.fighterData ? this.fighterData.id : "?", "plugin show, count=" + this.pluginIDs.length);
         }
      }

      // 批次6.3：收起 plugin 子框（清光 + 容器从 ui 移除）
      public function hidePluginSub() : void
      {
         if(!this.pluginIDs || this.pluginIDs.length < 1)
         {
            return;
         }
         Debugger.log("[Plugin]", this.fighterData ? this.fighterData.id : "?", "plugin hide");
         // 批次6.5：精细清空 - 只移除我们加的 GlowFilter（color=_PLUGIN_GLOW_COLOR），保留其他 filter（避免误伤主 ui 的高亮/变色 filter）
         if(this.ui.filters != null && this.ui.filters.length > 0)
         {
            var _loc5_:Array = [];
            var _loc6_:int = 0;
            while(_loc6_ < this.ui.filters.length)
            {
               var _loc7_:* = this.ui.filters[_loc6_];
               if(_loc7_ is GlowFilter && (_loc7_ as GlowFilter).color == _PLUGIN_GLOW_COLOR)
               {
                  // 跳过 plugin 自己的 GlowFilter
               }
               else
               {
                  _loc5_.push(_loc7_);
               }
               _loc6_++;
            }
            this.ui.filters = _loc5_;
         }
         if(Boolean(this._pluginContainer) && this.ui.contains(this._pluginContainer))
         {
            this.ui.removeChild(this._pluginContainer);
         }
      }

      // 批次6.4：判断 plugin 子框是否已展开（用于肩键 toggle）
      public function isPluginSubVisible() : Boolean
      {
         if(!this._pluginContainer)
         {
            return false;
         }
         return this.ui.contains(this._pluginContainer);
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
         if(Boolean(this.ui))
         {
            this.removeAllEventListener();
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
         // 批次6.2：清理 plugin 子框容器
         if(Boolean(this._pluginContainer))
         {
            while(this._pluginContainer.numChildren > 0)
            {
               this._pluginContainer.removeChildAt(0);
            }
            this._pluginContainer = null;
         }
         // 批次6.7治本：清理 ENTER_FRAME 监听，避免 _refreshFace 在 destory 后还在轮询（内存泄漏）
         this.removeEventListener(Event.ENTER_FRAME, this._refreshFace);
      }
   }
}

