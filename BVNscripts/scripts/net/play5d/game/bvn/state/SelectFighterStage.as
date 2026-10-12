package net.play5d.game.bvn.state
{
   import com.greensock.*;
   import com.greensock.easing.*;
   import flash.display.DisplayObject;
   import flash.events.*;
   import flash.geom.Point;
   import flash.system.Capabilities;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.ui.select.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   import net.play5d.kyo.utils.*;
import net.play5d.game.bvn.Debugger;
import net.play5d.game.bvn.mob.views.ViewManager;
   
   public class SelectFighterStage implements Istage
   {
      
      public static var AUTO_FINISH:Boolean = true;

      /** 当前选人阶段（0=角色选人, 1=辅助选人）— 供 select.swf 帧脚本 clear() 判断（辅助阶段移除翻页按钮） */
      public static var SELECT_STATE:int = 0;

      /** 当前每页高度（buildList 时动态计算） */
      public static var PAGE_HEIGHT:Number = 600;
      /** 当前总页数 */
      public static var TOTAL_PAGES:int = 5;
      /** 当前页号（0-based，用于翻页动画） */
      public static var CURRENT_PAGE:int = 0;

      /**
       * 选人角色格的物理占位尺寸（单个格子多大，**不是**「一行几个」）。
       * 2026-10-10：新增。用于把「每页几行」从硬编码改为按视口推导：
       *   rowsPerPage = floor((可用视口高 - CELL_SIZE.y) / CELL_SIZE.y) + 1
       * 取值 60 与 SelectStageConfigVO.unitSize 的兜底值、SelectFighterItem 内多处 60 兜底一致
       * （slt_item_mc ≈60，face 渲染 50×50）。
       */
      private static const CELL_SIZE:Point = new Point(60, 60);
      
      private static const SELECT_STATE_FIGHTER:int = 0;
      
      private static const SELECT_STATE_ASSIST:int = 1;
      
      private static const SELECT_STATE_MAP:int = 2;
      
      public var _selectState:int;
      
      private var _ui:*;
      
      private var _config:SelectStageConfigVO;
      
      private var _curListConfig:SelectCharListConfigVO;
      
      private var _itemObj:Object;
      
      private var _p1Slt:SelecterItemUI;
      
      private var _p2Slt:SelecterItemUI;
      
      private var _p1SelectedGroup:SelectedFighterGroup;
      
      private var _p2SelectedGroup:SelectedFighterGroup;
      
      private var _mapSelectUI:MapSelectUI;
      
      private var _curStep:int = 0;
      
      private var _tweenTime:int = 500;
      
      private var _twoPlayerSelectFin:Boolean;

      // 批次6.8（方案B）：人物子框 — 当前展开子框的角色 + 手柄在子框网格中的焦点
      public var p1ShowingPlugin:SelectFighterItem;
      public var p2ShowingPlugin:SelectFighterItem;
      public var p1PlugPoint:Point;
      public var p2PlugPoint:Point;

      // 分页控制
      private var _pagEnabled:Boolean = true;
      private var _pagSelect:int = 0;
      private var _pagSpeed:int = 100;
      private var _pagArr:Array = [];
      private var _pagInitialized:Boolean = false;

      public function SelectFighterStage()
      {
         super();
         this.p1PlugPoint = new Point(0,0);
         this.p2PlugPoint = new Point(0,0);
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.select,ResUtils.SELECT);
         this._config = GameData.I.config.select_config;
         GameRender.add(this.render);
         GameInputer.focus();
         GameInputer.enabled = false;
         this.initPagination();
         this.nextStep();
         SoundCtrl.I.BGM(AssetManager.I.getSound("select"));
         StateCtrl.I.clearTrans();
         KeyBoarder.focus();
         // 批次 6.12 修复：移除 MainGame.I.stage.dispatchEvent(DataEvent)（#1006 风险源）
         // 改为 GameEvent 单例派发（更安全，无 stage 依赖）
         try { GameEvent.dispatchEvent("SELECT_FIGHTER", null, false, false); } catch(_e:Error) {}
         // 批次 6.12 修复：refreshMultiPadCache 内部已用 var pads:* 修 #1006（批次 6.9）
         try { ViewManager.I.refreshMultiPadCache(); } catch(_e:Error) {}
      }
      
      private function initFighter() : void
      {
         Debugger.log("初始化选人");
         this.clear();
         this._selectState = 0;
         SELECT_STATE = 0;   // 批次6.10/6.11：静态状态恒为 0（select.swf 帧脚本 clear() 读取；设 1 会触发每帧 removeChild → #2025 刷屏，见 initAssist 注释）
         // 重置分页状态
         CURRENT_PAGE = 0;
         if(this._ui && this._ui.hasOwnProperty("bg") && this._ui.bg)
         {
            this._ui.bg.y = 0;
         }
         this.buildList(this._config.charList);
         GameData.I.p1Select = new SelectVO();
         if(Boolean(GameMode.isVsPeople()) || Boolean(GameMode.isVsCPU()))
         {
            GameData.I.p2Select = new SelectVO();
         }
         GameInputer.enabled = false;
         setTimeout(this.initSelecter,this._tweenTime);
      }
      
      private function initAssist() : void
      {
         Debugger.log("初始化辅助");
         this.clear();
         this._selectState = 1;
         // 批次6.11：不再设置 SELECT_STATE=1 —— select.swf 帧脚本 clear() 每帧 removeChild(up/down)，
         // 第二次起抛 ArgumentError #2025 刷屏（帧脚本无 contains 守卫，编译产物不可改）。
         // 保持 SELECT_STATE=0 → clear() 跳过移除；辅助界面翻页由主程序 render 分页段支持（批次 6.8 设计）。
         // 重置分页状态
         CURRENT_PAGE = 0;
         if(this._ui && this._ui.hasOwnProperty("bg") && this._ui.bg)
         {
            this._ui.bg.y = 0;
         }
         this.buildList(this._config.assistList);
         GameInputer.enabled = false;
         setTimeout(this.initSelecter,this._tweenTime);
      }
      
      private function fadOutList(param1:Function = null) : void
      {
         var _loc5_:* = undefined;
         var _loc2_:Number = NaN;
         GameInputer.enabled = false;
         var _loc3_:Number = GameConfig.GAME_SIZE.x / 2 - 30;
         var _loc4_:Number = GameConfig.GAME_SIZE.y / 2 - 30;
         for each(_loc5_ in this._itemObj)
         {
            _loc2_ = Math.random() * 0.1;
            TweenLite.to(_loc5_.ui,0.2,{
               "x":_loc3_,
               "y":_loc4_,
               "scaleX":0,
               "scaleY":0,
               "delay":_loc2_
            });
         }
         if(param1 != null)
         {
            TweenLite.delayedCall(0.3,param1);
         }
      }
      
      private function clear() : void
      {
         var _loc1_:* = undefined;
         // 批次6.8（方案B）：收起并清空当前展开的人物子框
         if(this.p1ShowingPlugin)
         {
            try { this.p1ShowingPlugin.closePlugins(); } catch(e:Error) {}
            this.p1ShowingPlugin = null;
         }
         if(this.p2ShowingPlugin)
         {
            try { this.p2ShowingPlugin.closePlugins(); } catch(e:Error) {}
            this.p2ShowingPlugin = null;
         }
         this.p1PlugPoint = new Point(0,0);
         this.p2PlugPoint = new Point(0,0);
         if(Boolean(this._itemObj))
         {
            for each(_loc1_ in this._itemObj)
            {
               _loc1_.removeEventListener("mouseOver",this.selectFighterMouseHandler);
               _loc1_.removeEventListener("click",this.selectFighterMouseHandler);
               _loc1_.removeEventListener("touchTap",this.selectFighterTouchHandler);
               _loc1_.destory();
            }
            this._itemObj = null;
         }
         if(Boolean(this._p1Slt))
         {
            this._p1Slt.destory();
            this._p1Slt = null;
         }
         if(Boolean(this._p2Slt))
         {
            this._p2Slt.destory();
            this._p2Slt = null;
         }
         if(Boolean(this._mapSelectUI))
         {
            this._mapSelectUI.destory();
            this._mapSelectUI = null;
         }
         if(Boolean(this._p1SelectedGroup))
         {
            this._p1SelectedGroup.destory();
            this._p1SelectedGroup = null;
         }
         if(Boolean(this._p2SelectedGroup))
         {
            this._p2SelectedGroup.destory();
            this._p2SelectedGroup = null;
         }
      }
      
      private function buildList(param1:SelectCharListConfigVO) : void
      {
         var _loc2_:int = 0;
         var _loc3_:SelectCharListItemVO = null;
         var _loc4_:SelectFighterItem = null;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = this._config.x + this._config.left;
         var _loc9_:Number = this._config.y + this._config.top;
         // 网格步距（自由网格模式，取自 3.9 的自适应公式；实际赋值见下方 displayedVCount 之后）
         var _loc10_:Number = 45;
         var _loc11_:Number = 60;
         var _loc12_:Array = param1.list;
         this._curListConfig = param1;
         this._itemObj = {};
         var _loc13_:Number = GameConfig.GAME_SIZE.x / 2 - 30;
         var _loc14_:Number = GameConfig.GAME_SIZE.y / 2 - 30;

         // ===== 页高 / 每页行数：全部由 select.xml 的 layout 推导，代码里没有固定值 =====
         // 2026-10-10 修复「行间距相当大」：原实现把 rowsPerPage 写死为 6，行距却用整幅画布高 layout.height 计算：
         //   gapY = (layout.height - unitSize.y - top - bottom) / (rowsPerPage - 1)
         // 当外部 select.xml 把 layout.height 写成 1380（整幅画布高）时，
         // gapY = (1380 - 60 - 50 - 110) / 5 = 232，而视口只有 600 高 → 一屏最多看到 2 行、行间大片空白。
         //
         // 现行模型（把「页」的尺寸交给 XML 决定，程序自己识别）：
         //   页高 PAGE_HEIGHT = min(layout.height, GameConfig.GAME_SIZE.y)
         //     —— 上限取视口高：翻页滑动步长 bg.y 只有落在视口高以内，每页内容才完整可见且翻页能对齐
         //        （步长 > 视口时，第 2 页起的内容会滚出屏幕，末行永久看不到）。
         //   每页行数 = 可用页高 / 单个格子高
         //   ✅ 想让每页多/少几行、或想调行距：只改 select.xml 的 layout height/top/bottom，本函数自动跟随。
         var viewportH:Number = Math.min(this._config.height, GameConfig.GAME_SIZE.y);
         var usableH:Number = viewportH - this._config.top - this._config.bottom;
         if(usableH < CELL_SIZE.y) { usableH = CELL_SIZE.y; }
         var rowsPerPage:int = Math.floor(usableH / CELL_SIZE.y);
         if(rowsPerPage < 1) { rowsPerPage = 1; }

         var maxY:int = 0;
         for each(var _itemVO:SelectCharListItemVO in _loc12_)
         {
            if(_itemVO.y > maxY) { maxY = _itemVO.y; }
         }
         // 实际参与垂直布局的行数：取「列表声明行数、每页行数、实际最大行号 + 1」三者最小
         var displayedVCount:int = Math.min(param1.VCount, rowsPerPage, maxY + 1);
         if(displayedVCount < 1) { displayedVCount = 1; }
         
         // ===== 自由网格：列距/行距按「页」尺寸与行列数自适应 =====
         // 列距：HCount 列在 layout 可用宽内均匀铺开（item.x 是列号）
         _loc10_ = param1.HCount > 1 ? (this._config.width - this._config.unitSize.x - this._config.left - this._config.right) / (param1.HCount - 1) : 0;
         // 行距：只由「可见行数 + 页高」推导。
         // ⚠️ 不要改回 3.9 的整幅 layout.height 公式：3.9 是整列直排（layout.height = 全部行铺满所需高度），
         //    本项目是分页（每页只显示 rowsPerPage 行），两者不是同一个量。
         // 不变量：间距*行数 + 末行格高 = 页高 - 顶边距 - 底边距（末行完整落在视口内，底边距得以保留）
         _loc11_ = displayedVCount > 1 ? (viewportH - this._config.unitSize.y - this._config.top - this._config.bottom) / (displayedVCount - 1) : CELL_SIZE.y;
         if(_loc10_ < 0) { _loc10_ = 0; }
         if(_loc11_ < CELL_SIZE.y) { _loc11_ = CELL_SIZE.y; }
         
         // 2026-10-10：PAGE_HEIGHT 改为由 layout 推导（不再是硬编码 600），并与容器定位共用同一个量，
         // 避免「行距用一个高、页号偏移用另一个高」的错位。
         // ⚠️ select.swf 内嵌帧脚本（DoABC）在加载时**各读一次** PAGE_HEIGHT / TOTAL_PAGES 并缓存到局部
         //    （见 tools/script/patch_pagination.as），因此本值在选人界面构建时必须已稳定；
         //    改这里只影响同一套 select.xml 配置下的一致性，跨配置切换需重启应用。
         PAGE_HEIGHT = viewportH;
         // 页数按"行数 / 每页行数"算——原来用 maxY * 行距 / PAGE_HEIGHT，行距一改页数就跟着变
         // （自适应行距把 assist_list 多算出一个空页），与本函数的网格步距解耦。
         TOTAL_PAGES = Math.max(1, Math.ceil((maxY + 1) / rowsPerPage));
         CURRENT_PAGE = 0;
         Debugger.log("[SelectFighterStage] pages:", TOTAL_PAGES, "pageHeight:", PAGE_HEIGHT, "rowsPerPage:", rowsPerPage,
                      "layoutH:", this._config.height, "usableH:", usableH,
                      "HCount:", param1.HCount, "VCount:", param1.VCount, "gapX:", _loc10_, "gapY:", _loc11_);

         while(_loc2_ < _loc12_.length)
         {
            _loc3_ = _loc12_[_loc2_];
            _loc4_ = this.addFighterItem(_loc3_);
            if(Boolean(_loc4_))
            {
               _loc5_ = _loc8_ + _loc10_ * (_loc4_.selectData.x);
               var pageIdx:int = int(_loc4_.selectData.y / rowsPerPage);
               var yInPage:int = int(_loc4_.selectData.y % rowsPerPage);
               _loc6_ = _loc9_ + _loc11_ * yInPage + pageIdx * PAGE_HEIGHT;
               if(Boolean(_loc4_.selectData.offset))
               {
                  _loc5_ += _loc4_.selectData.offset.x;
                  _loc6_ += _loc4_.selectData.offset.y;
               }
               _loc4_.ui.scaleX = 0;
               _loc4_.ui.scaleY = 0;
               _loc4_.ui.x = _loc13_;
               _loc4_.ui.y = _loc14_;
               _loc7_ = Math.random() * (this._tweenTime - 300) / 1000;
               TweenLite.to(_loc4_.ui,0.3,{
                  "x":_loc5_,
                  "y":_loc6_,
                  "delay":_loc7_,
                  "scaleX":1,
                  "scaleY":1,
                  "ease":Back.easeOut
               });
               // 批次6.8（方案B）：构建人物子框（plugin 角色）— 8 方位 gridOffset 环绕主角色
               var mainFighterVO:FighterVO = this._selectState == 1 ? AssisterModel.I.getAssister(_loc3_.fighterID) : FighterModel.I.getFighter(_loc3_.fighterID);
               if(mainFighterVO && mainFighterVO.pluginIDs && mainFighterVO.pluginIDs.length > 0)
               {
                  _loc4_.pluginFighters = new Vector.<SelectFighterItem>();
                  var i:int = 0;
                  while(i < mainFighterVO.pluginIDs.length)
                  {
                     var pluginId:String = mainFighterVO.pluginIDs[i];
                     if(pluginId && pluginId != "")
                     {
                        var pListItemVO:SelectCharListItemVO = new SelectCharListItemVO(_loc3_.x,_loc3_.y,pluginId,_loc3_.offset);
                        var pItem:SelectFighterItem = this.addFighterItem(pListItemVO,true,_loc4_,i);
                        if(pItem)
                        {
                           var offsets:Array = [new Point(0,-1),new Point(0,1),new Point(1,0),new Point(-1,0),new Point(1,1),new Point(-1,1),new Point(-1,-1),new Point(1,-1)];
                           var offsetRatio:Point = offsets[i % offsets.length];
                           pItem.gridOffset = offsetRatio.clone();
                           var pX:Number = _loc5_ + offsetRatio.x * _loc10_;
                           var pY:Number = _loc6_ + offsetRatio.y * _loc11_;
                           pItem.ui.x = _loc5_;
                           pItem.ui.y = _loc6_;
                           pItem.ui.scaleX = 0;
                           pItem.ui.scaleY = 0;
                           pItem.ui.alpha = 0;
                           pItem.pendingTweenParams = {
                              "x":pX,
                              "y":pY,
                              "delay":_loc7_ + 0.05
                           };
                           pItem.pendingBack = {
                              "x":_loc5_,
                              "y":_loc6_,
                              "delay":_loc7_ + 0.05
                           };
                        }
                     }
                     i++;
                  }
                  _loc4_.updateBadge(mainFighterVO.pluginIDs.length);
               }
               else
               {
                  _loc4_.updateBadge(0);
               }
            }
            _loc2_++;
         }
         // 重新计算分页位置
         _pagArr = [0];
         for (var pi:int = 1; pi < TOTAL_PAGES; pi++) {
            _pagArr.push(pi * -PAGE_HEIGHT);
         }
         CURRENT_PAGE = 0;
         // 不覆盖 goNext/goPrev（stg_select 类方法是 final 的不可运行时替换）
         // 2026-10-10 更正：帧脚本实际读的是 SelectFighterStage.PAGE_HEIGHT（构建期已由 layout 推导覆盖），
         // 旧注释里的「静态默认值 500」是历史遗留，当前静态默认值与推导口径见文件头 PAGE_HEIGHT 声明。
         Debugger.log("[SelectFighterStage] pagination pages:", TOTAL_PAGES, "pageHeight:", PAGE_HEIGHT, "positions:", _pagArr);
      }

      // 批次6.8（方案B）：addFighterItem 扩展 — isPlugin/parentItem/pluginIndex 用于构建人物子框
      private function addFighterItem(param1:SelectCharListItemVO, isPlugin:Boolean = false, parentItem:SelectFighterItem = null, pluginIndex:int = 0) : SelectFighterItem
      {
         if(!param1.fighterID)
         {
            return null;
         }
         var _loc2_:FighterVO = this._selectState == 1 ? AssisterModel.I.getAssister(param1.fighterID) : FighterModel.I.getFighter(param1.fighterID);
         if(!_loc2_)
         {
            Debugger.log("SelectFighterStage.addFighterItem :: 未找到角色数据：" + param1.fighterID);
            return null;
         }
         var _loc3_:Number = 60;
         var _loc4_:Number = 60;
         var _loc5_:SelectFighterItem = new SelectFighterItem(_loc2_,param1);
         if(GameConfig.TOUCH_MODE)
         {
            _loc5_.addEventListener("touchTap",this.selectFighterTouchHandler);
            // 批次6.9：触屏长按展开子框回调注入（plugin 子角色同样适用）
            _loc5_.onLongPress = this.touchLongPressHandler;
         }
         else
         {
            _loc5_.addEventListener("mouseOver",this.selectFighterMouseHandler);
            _loc5_.addEventListener("click",this.selectFighterMouseHandler);
            _loc5_.addEventListener("rightClick",this.selectFighterMouseHandler);
         }
         if(this._ui && this._ui.bg)
         {
            this._ui.bg.addChild(_loc5_.ui);
         }
         else
         {
            this._ui.addChild(_loc5_.ui);
         }
         var baseKey:String = param1.x + "," + param1.y;
         if(isPlugin && parentItem != null)
         {
            var pKey:String = baseKey + "." + (pluginIndex + 1);
            this._itemObj[pKey] = _loc5_;
            parentItem.pluginFighters.push(_loc5_);
         }
         else
         {
            this._itemObj[baseKey] = _loc5_;
         }
         return _loc5_;
      }
      
      private function selectFighterMouseHandler(param1:String, param2:SelectFighterItem) : void
      {
         if(!param2 || !param2.selectData)
         {
            return;
         }
         switch(param1)
         {
            case "mouseOver":
               this.doHover(param2);
               break;
            case "click":
               this.doSelect(param2);
               break;
            case "rightClick":
               this.doShow(param2);
               break;
         }
      }
      
      private function selectFighterTouchHandler(param1:String, param2:SelectFighterItem) : void
      {
         if(!param2 || !param2.selectData)
         {
            return;
         }
         var _loc3_:SelecterItemUI = null;
         if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
         {
            _loc3_ = this._p1Slt;
         }
         if(!_loc3_ && (Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled)))
         {
            _loc3_ = this._p2Slt;
         }
         if(!_loc3_)
         {
            return;
         }
         if(this.isHoverFighter(_loc3_,param2))
         {
            this.doSelect(param2);
         }
         else
         {
            this.doHover(param2);
         }
      }
      
      // 批次6.8（方案B）：判断目标角色是否属于当前展开的 plugin 组（含主角色本身）
      private function isBelongToPluginGroup(showingPlugin:SelectFighterItem, targetItem:SelectFighterItem) : Boolean
      {
         if(!showingPlugin) return false;
         if(showingPlugin == targetItem) return true;
         if(showingPlugin.pluginFighters)
         {
            for(var i:int = 0; i < showingPlugin.pluginFighters.length; i++)
            {
               if(showingPlugin.pluginFighters[i] == targetItem) return true;
            }
         }
         return false;
      }

      private function doHover(param1:SelectFighterItem) : void
      {
         if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
         {
            // 批次6.8（方案B）：hover 到 plugin 组外角色时收起子框
            if(this.p1ShowingPlugin != null && !this.isBelongToPluginGroup(this.p1ShowingPlugin,param1))
            {
               this.p1ShowingPlugin.closePlugins();
               this.p1ShowingPlugin = null;
            }
            if(this._p1Slt.isSelected(param1.selectData.fighterID))
            {
               return;
            }
            this.moveToSelectFighter(this._p1Slt,param1);
            SoundCtrl.I.sndSelect();
            return;
         }
         if(Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled))
         {
            if(this.p2ShowingPlugin != null && !this.isBelongToPluginGroup(this.p2ShowingPlugin,param1))
            {
               this.p2ShowingPlugin.closePlugins();
               this.p2ShowingPlugin = null;
            }
            if(this._p2Slt.isSelected(param1.selectData.fighterID))
            {
               return;
            }
            this.moveToSelectFighter(this._p2Slt,param1);
            SoundCtrl.I.sndSelect();
            return;
         }
      }

      // 批次6.8（方案B）：展开人物子框（右键或手柄 special 触发）
      private function doShow(param2:SelectFighterItem, pW:String = "") : void
      {
         if(!param2)
         {
            return;
         }
         if(pW == "") this.doHover(param2);
         param2.showPlugins();
         if(pW == "")
         {
            if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
            {
               this.p1ShowingPlugin = param2;
               this.p1PlugPoint.x = 0;
               this.p1PlugPoint.y = 0;
            }
            else if(Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled))
            {
               this.p2ShowingPlugin = param2;
               this.p2PlugPoint.x = 0;
               this.p2PlugPoint.y = 0;
            }
         }
         else if(pW == "P1")
         {
            this.p1ShowingPlugin = param2;
            this.p1PlugPoint.x = 0;
            this.p1PlugPoint.y = 0;
         }
         else if(pW == "P2")
         {
            this.p2ShowingPlugin = param2;
            this.p2PlugPoint.x = 0;
            this.p2PlugPoint.y = 0;
         }
      }

      // 批次6.9：触屏长按 → 展开子框（归属当前启用玩家）
      private function touchLongPressHandler(param1:SelectFighterItem) : void
      {
         if(!param1 || !param1.pluginFighters || param1.pluginFighters.length < 1)
         {
            return;   // 无子框的角色长按无效果
         }
         Debugger.log("[Plugin]", param1.fighterData ? param1.fighterData.id : "?", "long press expand");
         this.doShow(param1);
         SoundCtrl.I.sndConfrim();
      }

      // 批次6.8（方案B）：手柄方向键在子框网格间移动（0,0=主角色，其余=8 方位子角色）
      private function movePluginSelect(params1:SelecterItemUI, plug:String, direction:String) : void
      {
         var showingPlugin:SelectFighterItem = plug == "P1" ? this.p1ShowingPlugin : this.p2ShowingPlugin;
         if(!showingPlugin) return;
         var plugPoint:Point = plug == "P1" ? this.p1PlugPoint : this.p2PlugPoint;
         var targetOffX:int = plugPoint.x;
         var targetOffY:int = plugPoint.y;
         switch(direction)
         {
            case "up": targetOffY -= 1; break;
            case "down": targetOffY += 1; break;
            case "left": targetOffX -= 1; break;
            case "right": targetOffX += 1; break;
         }
         if(targetOffX == 0 && targetOffY == 0)
         {
            if(!params1.isSelected(showingPlugin.selectData.fighterID))
            {
               this.moveToSelectFighter(params1,showingPlugin);
               plugPoint.x = 0; plugPoint.y = 0;
               return;
            }
         }
         else if(showingPlugin.pluginFighters)
         {
            for(var j:int = 0; j < showingPlugin.pluginFighters.length; j++)
            {
               var childOff:Point = showingPlugin.pluginFighters[j].gridOffset;
               if(childOff.x == targetOffX && childOff.y == targetOffY)
               {
                  var targetChild:SelectFighterItem = showingPlugin.pluginFighters[j];
                  if(!params1.isSelected(targetChild.selectData.fighterID))
                  {
                     this.moveToSelectFighter(params1,targetChild);
                     plugPoint.x = targetOffX; plugPoint.y = targetOffY;
                     return;
                  }
                  break;
               }
            }
         }
         // 目标方位无子角色：收起子框并沿方向移动到相邻主网格
         showingPlugin.closePlugins();
         plugPoint.x = 0; plugPoint.y = 0;
         if(plug == "P1") this.p1ShowingPlugin = null;
         else this.p2ShowingPlugin = null;
         var px:int = showingPlugin.selectData.x;
         var py:int = showingPlugin.selectData.y;
         switch(direction)
         {
            case "up": this.moveSlt(params1,px,py - 1); break;
            case "down": this.moveSlt(params1,px,py + 1); break;
            case "left": this.moveSlt(params1,px - 1,py); break;
            case "right": this.moveSlt(params1,px + 1,py); break;
         }
      }

      private function doSelect(param1:SelectFighterItem) : void
      {
         if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
         {
            if(this._p1Slt.isSelected(param1.selectData.fighterID))
            {
               return;
            }
            // 批次6.8（方案B）：选中角色时收起其子框
            if(this.p1ShowingPlugin)
            {
               this.p1ShowingPlugin.closePlugins();
               this.p1ShowingPlugin = null;
            }
            this._p1Slt.select(this.playerSeltBack);
            SoundCtrl.I.sndConfrim();
            return;
         }
         if(Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled))
         {
            if(this._p2Slt.isSelected(param1.selectData.fighterID))
            {
               return;
            }
            if(this.p2ShowingPlugin)
            {
               this.p2ShowingPlugin.closePlugins();
               this.p2ShowingPlugin = null;
            }
            this._p2Slt.select(this.playerSeltBack);
            SoundCtrl.I.sndConfrim();
            return;
         }
      }
      
      private function getFighterItem(param1:int, param2:int) : SelectFighterItem
      {
         if(!this._itemObj)
         {
            return null;
         }
         return this._itemObj[param1 + "," + param2];
      }
      
      private function initSelecter() : void
      {
         GameInputer.enabled = true;
         if(GameMode.isVsPeople())
         {
            this.initSelecterP1();
            this.initSelecterP2();
            this._twoPlayerSelectFin = false;
         }
         else
         {
            this.initSelecterP1();
         }
      }
      
      private function initSelecterP1() : void
      {
         this._p1Slt = SelectUIFactory.createSelecter(1);
         this._p1Slt.isSelectAssist = this._selectState == 1;
         this._p1Slt.selectTimesCount = this._p1Slt.isSelectAssist ? 1 : GameMode.getSelectCount(1);
         this._ui.addChild(this._p1Slt.ui);
         this._ui.addChild(this._p1Slt.group);
         this.moveSlt(this._p1Slt,0,0);
      }

      private function initSelecterP2() : void
      {
         this._p2Slt = SelectUIFactory.createSelecter(2);
         this._p2Slt.isSelectAssist = this._selectState == 1;
         this._p2Slt.selectTimesCount = this._p2Slt.isSelectAssist ? 1 : GameMode.getSelectCount(2);
         this._ui.addChild(this._p2Slt.ui);
         this._ui.addChild(this._p2Slt.group);
         this.moveSlt(this._p2Slt,9,0);
      }
      
      private function moveSlt(param1:SelecterItemUI, param2:int, param3:int, param4:Boolean = true) : Boolean
      {
         var _loc5_:Boolean = false;
         var _loc6_:Boolean = false;
         var _loc7_:Boolean = false;
         var _loc8_:Boolean = false;
         var _loc9_:int = 0;
         var _loc10_:* = 0;
         var _loc11_:Boolean = false;
         var _loc12_:SelectFighterItem = this.getFighterItem(param2,param3);
         if(!_loc12_ || Boolean(_loc12_) && Boolean(param1.isSelected(_loc12_.selectData.fighterID)))
         {
            if(!param4)
            {
               return true;
            }
            if(param2 > param1.x)
            {
               _loc5_ = true;
               _loc10_ = 0;
               while(_loc10_ < this._curListConfig.HCount)
               {
                  _loc9_ = param2 + _loc10_;
                  if(_loc9_ > this._curListConfig.HCount - 1)
                  {
                     _loc9_ -= this._curListConfig.HCount;
                  }
                  _loc12_ = this.getFighterItem(_loc9_,param1.y);
                  if(Boolean(_loc12_) && !param1.isSelected(_loc12_.selectData.fighterID))
                  {
                     break;
                  }
                  _loc10_++;
               }
            }
            if(param2 < param1.x)
            {
               _loc8_ = true;
               _loc10_ = 0;
               while(_loc10_ < this._curListConfig.HCount)
               {
                  _loc9_ = param2 - _loc10_;
                  if(_loc9_ < 0)
                  {
                     _loc9_ = this._curListConfig.HCount + _loc9_;
                  }
                  _loc12_ = this.getFighterItem(_loc9_,param1.y);
                  if(Boolean(_loc12_) && !param1.isSelected(_loc12_.selectData.fighterID))
                  {
                     break;
                  }
                  _loc10_++;
               }
            }
            if(param3 > param1.y)
            {
               _loc7_ = true;
               if(param3 > this._curListConfig.VCount - 1)
               {
                  param3 = 0;
               }
               _loc10_ = param3;
               while(_loc10_ < this._curListConfig.VCount)
               {
                  _loc12_ = this.getHLineFighter(param1.x,_loc10_);
                  if(Boolean(_loc12_))
                  {
                     break;
                  }
                  _loc10_++;
               }
            }
            if(param3 < param1.y)
            {
               _loc6_ = true;
               if(param3 < 0)
               {
                  param3 = this._curListConfig.VCount - 1;
               }
               _loc10_ = param3;
               while(_loc10_ >= 0)
               {
                  _loc12_ = this.getHLineFighter(param1.x,_loc10_);
                  if(Boolean(_loc12_))
                  {
                     break;
                  }
                  _loc10_--;
               }
            }
         }
         if(!_loc12_)
         {
            return false;
         }
         param1.x = _loc12_.selectData.x;
         param1.y = _loc12_.selectData.y;
         if(param1.isSelected(_loc12_.selectData.fighterID))
         {
            if(_loc6_ || _loc7_)
            {
               _loc11_ = Boolean(this.moveSlt(param1,param1.x + 1,param1.y));
               if(!_loc11_)
               {
                  if(_loc6_)
                  {
                     this.moveSlt(param1,param1.x,param1.y - 1);
                  }
                  if(_loc7_)
                  {
                     this.moveSlt(param1,param1.x,param1.y + 1);
                  }
               }
            }
            return true;
         }
         this.moveToSelectFighter(param1,_loc12_);
         return true;
      }
      
      private function isHoverFighter(param1:SelecterItemUI, param2:SelectFighterItem) : Boolean
      {
         if(param1.x != param2.selectData.x || param1.y != param2.selectData.y)
         {
            return false;
         }
         // 2026-09-29 扩展格触屏修复：扩展格创建时复用主角色网格坐标（批次6.8），
         // 坐标相同时若 param2 不是自己坐标格的格子主（_itemObj["x,y"] 里存的是主角色），
         // 说明它是扩展格 → 必须再校验 fighterVO 身份，否则点扩展格会误判"已悬停"，
         // 直接 doSelect 选中光标上的主角色。普通格子（含随机角色）不受影响。
         if(this._itemObj && this._itemObj[param2.selectData.x + "," + param2.selectData.y] != param2)
         {
            return param1.currentFighter == param2.fighterData;
         }
         return true;
      }
      
      private function moveToSelectFighter(param1:SelecterItemUI, param2:SelectFighterItem) : void
      {
         param1.randoms = null;
         param1.x = param2.selectData.x;
         param1.y = param2.selectData.y;
         // 考虑背景容器的偏移，确保选择框正确跟随角色
         var bgOffsetY:Number = 0;
         if(this._ui && this._ui.bg && this._ui.bg.hasOwnProperty("y"))
         {
            bgOffsetY = this._ui.bg.y;
         }
         param1.moveTo(param2.ui.x,param2.ui.y + bgOffsetY);
         param1.currentFighter = param2.fighterData;
         if(Boolean(param1.group))
         {
            param1.group.updateFighter(param1.currentFighter);
         }
         this.checkRandom(param1);
      }
      
      private function checkRandom(param1:SelecterItemUI) : Boolean
      {
         var slt:SelecterItemUI = null;
         slt = param1;
         if(slt.currentFighter.id.indexOf("random") != -1)
         {
            switch(this._selectState)
            {
               case 0:
                  slt.randoms = FighterModel.I.getFighters(slt.currentFighter.comicType,function(param1:FighterVO):Boolean
                  {
                     return param1.id.indexOf("random") == -1 && Boolean(GameLogic.canSelectFighter(param1.id)) && !slt.selectVO.isSelected(param1.id);
                  });
                  break;
               case 1:
                  slt.randoms = AssisterModel.I.getAssisters(slt.currentFighter.comicType,function(param1:FighterVO):Boolean
                  {
                     return param1.id.indexOf("random") == -1 && Boolean(GameLogic.canSelectAssist(param1.id));
                  });
                  break;
               default:
                  return false;
            }
            slt.randFrame = 0;
            this.renderRandom(slt);
            return true;
         }
         return false;
      }
      
      private function getHLineFighter(param1:int, param2:int) : SelectFighterItem
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:SelectFighterItem = null;
         while(true)
         {
            _loc4_ = param1 + _loc3_;
            if(_loc4_ >= 0 && _loc4_ < this._curListConfig.HCount)
            {
               _loc5_ = this.getFighterItem(_loc4_,param2);
               if(Boolean(_loc5_))
               {
                  break;
               }
            }
            if(_loc3_ == 0)
            {
               _loc3_ = 1;
            }
            else if(_loc3_ > 0)
            {
               _loc3_ *= -1;
            }
            else
            {
               if(_loc3_ < -this._curListConfig.HCount)
               {
                  return null;
               }
               _loc3_ *= -1;
               _loc3_++;
            }
         }
         return _loc5_;
      }
      
      private function renderRandom(param1:SelecterItemUI) : void
      {
         if(Boolean(param1.randoms))
         {
            if(param1.randFrame > 0)
            {
               param1.randFrame = 0;
               return;
            }
            ++param1.randFrame;
            param1.currentFighter = KyoRandom.getRandomInArray(param1.randoms,false);
            if(Boolean(param1.group))
            {
               param1.group.updateFighter(param1.currentFighter);
            }
         }
      }
      
      private function render() : void
      {
         // 分页：辅助界面不归位，允许翻页；仅每帧保底解锁 enable
         if (_pagInitialized && this._ui) {
            if (this._ui.hasOwnProperty("enable")) this._ui["enable"] = true;

            // FLA 翻页动画控制 bg.y，render 不参与 bg.y 操作
            // 仅更新选择框位置适配当前 bg.y 偏移
            if(this._ui.hasOwnProperty("bg") && this._ui.bg)
            {
               if(Boolean(this._p1Slt) && this._p1Slt.enabled)
               {
                  // 批次6.10：子框展开期间不吸附回主网格（否则 hover 子框会被弹回主体）
                  var p1FocusedOnPlugin:Boolean = false;
                  if(this.p1ShowingPlugin != null)
                  {
                     var p1Cur:SelectFighterItem = this.getFighterItem(this._p1Slt.x,this._p1Slt.y);
                     if(p1Cur != null && this.isBelongToPluginGroup(this.p1ShowingPlugin,p1Cur))
                     {
                        p1FocusedOnPlugin = true;
                     }
                  }
                  if(!p1FocusedOnPlugin)
                  {
                     var p1Item:SelectFighterItem = this.getFighterItem(this._p1Slt.x,this._p1Slt.y);
                     if(p1Item)
                     {
                        this.moveToSelectFighter(this._p1Slt,p1Item);
                     }
                  }
               }
               if(Boolean(this._p2Slt) && this._p2Slt.enabled)
               {
                  // 批次6.10：子框展开期间不吸附回主网格
                  var p2FocusedOnPlugin:Boolean = false;
                  if(this.p2ShowingPlugin != null)
                  {
                     var p2Cur:SelectFighterItem = this.getFighterItem(this._p2Slt.x,this._p2Slt.y);
                     if(p2Cur != null && this.isBelongToPluginGroup(this.p2ShowingPlugin,p2Cur))
                     {
                        p2FocusedOnPlugin = true;
                     }
                  }
                  if(!p2FocusedOnPlugin)
                  {
                     var p2Item:SelectFighterItem = this.getFighterItem(this._p2Slt.x,this._p2Slt.y);
                     if(p2Item)
                     {
                        this.moveToSelectFighter(this._p2Slt,p2Item);
                     }
                  }
               }
            }
         }

         var _loc1_:String = null;
         if(GameInputer.back(1))
         {
            if(GameUI.showingDialog())
            {
               GameUI.closeConfrim();
            }
            else
            {
               GameUI.confrim("BACK TITLE?","返回到主菜单？",MainGame.I.goMenu);
            }
         }
         if(GameUI.showingDialog())
         {
            return;
         }
         if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
         {
            // 批次6.8（方案B）：子框展开时方向键走 movePluginSelect 子框导航
            var plugP1:String = this.p1ShowingPlugin != null ? "P1" : "";
            this.renderRandom(this._p1Slt);
            _loc1_ = this._p1Slt.inputType;
            if(GameInputer.up(_loc1_,1))
            {
               if(plugP1 == "") this.moveSlt(this._p1Slt,this._p1Slt.x,this._p1Slt.y - 1);
               else this.movePluginSelect(this._p1Slt,plugP1,"up");
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.down(_loc1_,1))
            {
               if(plugP1 == "") this.moveSlt(this._p1Slt,this._p1Slt.x,this._p1Slt.y + 1);
               else this.movePluginSelect(this._p1Slt,plugP1,"down");
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.left(_loc1_,1))
            {
               if(plugP1 == "") this.moveSlt(this._p1Slt,this._p1Slt.x - 1,this._p1Slt.y);
               else this.movePluginSelect(this._p1Slt,plugP1,"left");
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               if(plugP1 == "") this.moveSlt(this._p1Slt,this._p1Slt.x + 1,this._p1Slt.y);
               else this.movePluginSelect(this._p1Slt,plugP1,"right");
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.select(_loc1_,1))
            {
               this._p1Slt.select(this.playerSeltBack);
               // 批次6.8（方案B）：选中后收起子框
               if(this.p1ShowingPlugin)
               {
                  this.p1ShowingPlugin.closePlugins();
                  this.p1ShowingPlugin = null;
               }
               SoundCtrl.I.sndConfrim();
            }
            // 批次6.8（方案B）：手柄 special（LB）展开当前选中角色的子框
            if(plugP1 == "" && GameInputer.special(_loc1_,1))
            {
               var tarP1:String = this._p1Slt.x + "," + this._p1Slt.y;
               this.doShow(this._itemObj[tarP1],_loc1_);
               SoundCtrl.I.sndConfrim();
            }
         }
         if(Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled))
         {
            _loc1_ = this._p2Slt.inputType;
            var plugP2:String = this.p2ShowingPlugin != null ? "P2" : "";
            this.renderRandom(this._p2Slt);
            if(GameInputer.up(_loc1_,1))
            {
               if(plugP2 == "") this.moveSlt(this._p2Slt,this._p2Slt.x,this._p2Slt.y - 1);
               else this.movePluginSelect(this._p2Slt,plugP2,"up");
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.down(_loc1_,1))
            {
               if(plugP2 == "") this.moveSlt(this._p2Slt,this._p2Slt.x,this._p2Slt.y + 1);
               else this.movePluginSelect(this._p2Slt,plugP2,"down");
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.left(_loc1_,1))
            {
               if(plugP2 == "") this.moveSlt(this._p2Slt,this._p2Slt.x - 1,this._p2Slt.y);
               else this.movePluginSelect(this._p2Slt,plugP2,"left");
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               if(plugP2 == "") this.moveSlt(this._p2Slt,this._p2Slt.x + 1,this._p2Slt.y);
               else this.movePluginSelect(this._p2Slt,plugP2,"right");
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.select(_loc1_,1))
            {
               this._p2Slt.select(this.playerSeltBack);
               if(this.p2ShowingPlugin)
               {
                  this.p2ShowingPlugin.closePlugins();
                  this.p2ShowingPlugin = null;
               }
               SoundCtrl.I.sndConfrim();
            }
            // 批次6.8（方案B）：手柄 special（LB）展开当前选中角色的子框
            if(plugP2 == "" && GameInputer.special(_loc1_,1))
            {
               var tarP2:String = this._p2Slt.x + "," + this._p2Slt.y;
               this.doShow(this._itemObj[tarP2],_loc1_);
               SoundCtrl.I.sndConfrim();
            }
         }
         if(Boolean(this._mapSelectUI) && Boolean(this._mapSelectUI.enabled))
         {
            _loc1_ = this._mapSelectUI.inputType;
            if(GameInputer.left(_loc1_,1))
            {
               this._mapSelectUI.prev();
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               this._mapSelectUI.next();
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.select(_loc1_,1))
            {
               this._mapSelectUI.select(this.onMapSelect);
               SoundCtrl.I.sndConfrim();
            }
         }
      }
      
      public function get p1SelectFinish() : Boolean
      {
         return Boolean(this._p1Slt) && Boolean(this._p1Slt.selectFinish());
      }
      
      public function get p2SelectFinish() : Boolean
      {
         return Boolean(this._p2Slt) && Boolean(this._p2Slt.selectFinish());
      }
      
      public function setSelect(param1:int, param2:Array) : void
      {
         var _loc3_:SelecterItemUI = param1 == 1 ? this._p1Slt : this._p2Slt;
         _loc3_.setCurrentSelect(param2);
         _loc3_.removeSelecter();
         SoundCtrl.I.sndConfrim();
      }
      
      private function playerSeltBack(param1:SelecterItemUI) : void
      {
         var _loc2_:SelecterItemUI = null;
         var _loc3_:int = 0;
         if(param1.selectFinish())
         {
            if(GameMode.isVsPeople())
            {
               GameEvent.dispatchEvent("SELECT_FIGHTER_STEP",param1.getCurrentSelectes());
               _loc2_ = param1 == this._p1Slt ? this._p2Slt : this._p1Slt;
               if(Boolean(_loc2_) && Boolean(_loc2_.selectFinish()) && !this._twoPlayerSelectFin)
               {
                  this._twoPlayerSelectFin = true;
                  if(!AUTO_FINISH)
                  {
                     return;
                  }
                  this.nextStep();
               }
            }
            else
            {
               this.nextStep();
            }
            param1.destory();
         }
         else if(!param1.randoms)
         {
            _loc3_ = param1 == this._p1Slt == 1 ? 1 : -1;
            this.moveSlt(param1,param1.x + _loc3_,param1.y,true);
         }
      }
      
      public function nextStep() : void
      {
         switch(this._curStep)
         {
            case 0:
               this.initFighter();
               this._curStep = 1;
               break;
            case 1:
               if(GameMode.isVsCPU())
               {
                  this._p1Slt.removeSelecter();
                  this._p1Slt.enabled = false;
                  this.initSelecterP2();
                  this._p2Slt.inputType = "P1";
                  this._curStep = 2;
               }
               else
               {
                  this.fadOutList(this.initAssist);
                  this._curStep = 3;
               }
               break;
            case 2:
               this.fadOutList(this.initAssist);
               this._curStep = 3;
               break;
            case 3:
               if(GameMode.isVsCPU())
               {
                  this._p1Slt.removeSelecter();
                  this._p1Slt.enabled = false;
                  this.initSelecterP2();
                  this._p2Slt.inputType = "P1";
                  this._curStep = 4;
               }
               else if(Boolean(GameMode.isVsCPU()) || Boolean(GameMode.isVsPeople()))
               {
                  this.fadOutList(this.initMap);
                  this._curStep = 5;
               }
               else
               {
                  this.startAcradeGame();
               }
               break;
            case 4:
               this._curStep = 5;
               this.fadOutList(this.initMap);
               break;
            case 5:
               this.selectFinish();
         }
      }
      
      private function initMap() : void
      {
         var oldX:Number = NaN;
         var oldY:Number = NaN;
         Debugger.log("选择地图");
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["select_map"])));
         this.clear();
         GameInputer.enabled = false;
         this._mapSelectUI = new MapSelectUI();
         this._ui.addChild(this._mapSelectUI);
         oldX = Number(this._mapSelectUI.x);
         oldY = Number(this._mapSelectUI.y);
         this._mapSelectUI.scaleX = 0;
         this._mapSelectUI.scaleY = 0;
         this._mapSelectUI.x = GameConfig.GAME_SIZE.x / 2;
         this._mapSelectUI.y = GameConfig.GAME_SIZE.y / 2;
         TweenLite.to(this._mapSelectUI,0.3,{
            "x":oldX,
            "y":oldY,
            "scaleX":1,
            "scaleY":1,
            "ease":Back.easeOut,
            "onComplete":function():void
            {
               if(Boolean(_mapSelectUI))
               {
                  _mapSelectUI.addMouseEvents(mapPrevHandler,mapNextHandler,mapConfrimHandler);
                  _mapSelectUI.inputType = "P1";
                  _mapSelectUI.enabled = true;
               }
               GameInputer.enabled = true;
            }
         });
      }
      
      private function mapPrevHandler() : void
      {
         this._mapSelectUI.prev();
      }
      
      private function mapNextHandler() : void
      {
         this._mapSelectUI.next();
      }
      
      private function mapConfrimHandler() : void
      {
         this._mapSelectUI.select(this.onMapSelect);
      }
      
      private function onMapSelect() : void
      {
         this.nextStep();
      }
      
      private function startAcradeGame() : void
      {
         MessionModel.I.initMession();
         this.selectFinish();
      }
      
      private function selectFinish() : void
      {
         GameEvent.dispatchEvent("SELECT_FIGHTER_FINISH");
         if(!AUTO_FINISH)
         {
            return;
         }
         this.goLoadGame();
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["select_finish"])));
      }
      
      public function goLoadGame() : void
      {
         Debugger.log("开始游戏");
         StateCtrl.I.transIn(MainGame.I.loadGame);
      }
      
      public function afterBuild() : void
      {
      }

      // ================================================================
      // 分页 — select.swf 内嵌帧脚本（DoABC）在加载时各读一次 PAGE_HEIGHT / TOTAL_PAGES
      // 并缓存到局部变量（源码留档见 tools/script/patch_pagination.as），随后：
      //   pageHeight 作为 bg.y 的每页滑动步长（speed=100 逐帧逼近，步长÷100 = 到位帧数）
      //   arr 作为各页目标位置
      // 因此 buildList 里 PAGE_HEIGHT 由 select.xml 的 layout 推导（= min(layout.height, 视口高)），
      // 与帧脚本共用同一个量，避免「行距用一个高、页号偏移用另一个高」造成翻页错位。
      // render() 处理辅助界面归位（隐藏按钮 + bg.y=0）
      // ================================================================

      private function initPagination() : void
      {
         _pagInitialized = true;
      }

      public function destory(param1:Function = null) : void
      {
         this.clear();
         GameRender.remove(this.render);
         GameInputer.enabled = false;
         SoundCtrl.I.BGM(null);
         GameUI.closeConfrim();
      }
   }
}

