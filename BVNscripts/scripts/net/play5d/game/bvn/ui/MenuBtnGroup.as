package net.play5d.game.bvn.ui
{
   import com.greensock.*;
   import com.greensock.easing.*;
   import flash.display.Sprite;
   import flash.geom.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.*;
   
   public class MenuBtnGroup extends Sprite
   {
      
      public var enabled:Boolean = true;
      
      protected var _btnConfig:Array;
      
      // ===== 2026-10-27 排版参数（逻辑像素，800×600 坐标系）=====
      /** 一级列左缘 */
      private static const MARGIN_LEFT:Number = 24;
      /** 一级列顶部（6 项 ×80 + 80 = 560 = 600 − MARGIN_BOTTOM，刚好用满安全区） */
      private static const MARGIN_TOP:Number = 80;
      /** 底部安全区 */
      private static const MARGIN_BOTTOM:Number = 40;
      /** 父列右缘 → 子列左缘 */
      private static const COL_GAP:Number = 12;
      /** 行距 */
      private static const ROW_GAP:Number = 5;
      /** 子列超高时行距可压缩到的最小比例 */
      private static const MIN_ROW_GAP_RATE:Number = 0.6;
      
      /** 一级列宽（layoutColumns 后有效） */
      private var _colW:Number = 0;
      
      /** 最近一次排版的子列宽度（placeColumn 后有效） */
      private var _childColW:Number = 0;
      
      private var _btnIndex:int;
      
      private var _btns:Array = [];
      
      /** 已展开的层级（第 1 个 = 一级项的子项列，依次递进）；2026-11-21 由单层改为栈，支持三级 */
      private var _openLevels:Array = [];
      
      public function MenuBtnGroup()
      {
         super();
         // 2026-10-27 排版重做：主菜单**不再整体缩放**（原来 TOUCH_MODE 下整组 ×1.1）。
         // 原因：一级 6 项 × (75+5) = 480 逻辑像素，×1.1 就是 528，再加上顶部边距必然超出 600，
         // 旧版是靠「对角线错位 + 整组滚动」勉强绕过去的；改成规整竖列后必须让尺寸可静态推导。
         // 手机按钮不至于变小到难按：800×600 会被等比放大到设备屏（1080p 横屏约 ×2.4）。
         this.scaleX = this.scaleY = 1;
      }
      
      public function destory() : void
      {
         var _loc1_:* = undefined;
         // 展开层挂在组上的子项 ui 要先摘掉，否则 dispose 之后它们仍是本组的子节点
         var _lv:int = 0;
         while(_lv < this._openLevels.length)
         {
            var _list:Array = this._openLevels[_lv].children;
            var _j:int = 0;
            while(Boolean(_list) && _j < _list.length)
            {
               if(Boolean(_list[_j] && _list[_j].ui) && contains(_list[_j].ui))
               {
                  removeChild(_list[_j].ui);
               }
               _j++;
            }
            _lv++;
         }
         this._openLevels = [];
         GameRender.remove(this.render);
         for each(_loc1_ in this._btns)
         {
            _loc1_.removeEventListener("touchTap",this.touchHandler);
            _loc1_.removeEventListener("click",this.mouseHandler);
            _loc1_.removeEventListener("mouseOver",this.mouseHandler);
            _loc1_.dispose();
         }
         this._btns = null;
      }
      
      /**
       * 入场动画：从左缘滑入 + 淡入。
       * 原来是逐按钮 scaleX 0.01→1，缩放原点在按钮中心 —— 左对齐后动画期间左缘会先被推出去再弹回，
       * 视觉上「抖一下」。滑入 + 淡入没有原点问题，最终位置也不变。
       */
      public function fadIn(param1:Number = 0.5, param2:Number = 0.05) : void
      {
         var _loc3_:int = 0;
         var _loc4_:* = null;
         var _loc5_:Number = NaN;
         while(_loc3_ < this._btns.length)
         {
            _loc4_ = this._btns[_loc3_];
            _loc5_ = _loc4_.ui.x;
            _loc4_.ui.x = _loc5_ - 20;
            _loc4_.ui.alpha = 0;
            TweenLite.to(_loc4_.ui,param1,{
               "x":_loc5_,
               "alpha":1,
               "delay":_loc3_ * param2
            });
            _loc3_++;
         }
      }
      
      public function build() : void
      {
         var _loc1_:int = 0;
         var _loc2_:* = null;
         this._btnConfig = GameInterface.instance.getGameMenu();
         if(!this._btnConfig)
         {
            this._btnConfig = GameInterface.getDefaultMenu();
         }
         while(_loc1_ < this._btnConfig.length)
         {
            _loc2_ = this._btnConfig[_loc1_];
            this.addMenuBtn(_loc2_);
            _loc1_++;
         }
         // 2026-10-27 排版重做：位置由 layoutColumns() 完全决定（左侧竖列），
         // 不再有 y-=40 / y+=30 这类为「对角线阶梯 + 整组滚动」服务的补偿。
         this.layoutColumns(false);
         if(!GameConfig.TOUCH_MODE)
         {
            this.hoverBtn(this._btns[0]);
         }
         GameRender.add(this.render);
      }
      
      private function addMenuBtn(param1:Object, param2:Boolean = false) : MenuBtn
      {
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc5_:* = null;
         var _loc6_:* = null;
         var _loc7_:MenuBtn = new MenuBtn(param1.txt,param1.cn,param1.func);
         if(GameConfig.TOUCH_MODE)
         {
            _loc7_.addEventListener("touchTap",this.touchHandler);
         }
         else
         {
            _loc7_.addEventListener("click",this.mouseHandler);
            _loc7_.addEventListener("mouseOver",this.mouseHandler);
         }
         if(!param2)
         {
            _loc7_.index = this._btns.length;
            this._btns.push(_loc7_);
         }
         _loc3_ = param1.children;
         if(Boolean(_loc3_))
         {
            _loc7_.children = [];
            _loc4_ = 0;
            while(_loc4_ < _loc3_.length)
            {
               _loc5_ = _loc3_[_loc4_];
               _loc6_ = this.addMenuBtn(_loc5_,true);
               _loc7_.children.push(_loc6_);
               _loc6_.childMode();
               _loc6_.index = _loc4_;
               _loc4_++;
            }
         }
         return _loc7_;
      }
      
      protected function mouseHandler(param1:String, param2:MenuBtn) : void
      {
         if(!this.enabled)
         {
            return;
         }
         switch(param1)
         {
            case "mouseOver":
               this.hoverBtn(param2);
               break;
            case "click":
               this.selectBtn(param2);
         }
      }
      
      protected function touchHandler(param1:String, param2:MenuBtn) : void
      {
         if(Boolean(param2.children) && param2.children.length > 0)
         {
            this.hoverBtn(param2);
            this.selectBtn(param2);
            return;
         }
         if(!param2.isHover())
         {
            this.hoverBtn(param2);
         }
         else
         {
            this.selectBtn(param2);
         }
      }
      
      private function moveScroll() : void
      {
         // 2026-10-27 排版重做：整组滚动的唯一用途是「一条对角线长阶梯放不下」，
         // 改成左侧竖列 + 二级独立列后，一级 6×80 / 二级 7×60 都在可用高度内，
         // 滚动会算出错误位移，故停用（保留空实现，避免外部若有调用直接崩）。
         // 子列真放不下时由 placeColumn() 压缩行距并在日志里留痕。
      }
      
      private function hoverBtn(param1:MenuBtn) : void
      {
         var b:MenuBtn = null;
         var i:int = 0;
         i = 0;
         while(i < this._btns.length)
         {
            b = this._btns[i];
            if(b == param1)
            {
               b.hover();
               this._btnIndex = i;
            }
            else
            {
               b.normal();
            }
            i++;
         }
         var lv:int = 0;
         while(lv < this._openLevels.length)
         {
            var list:Array = this._openLevels[lv].children;
            i = 0;
            while(Boolean(list) && i < list.length)
            {
               b = list[i];
               if(b == param1)
               {
                  b.hover();
                  this._btnIndex = i;
               }
               else
               {
                  b.normal();
               }
               i++;
            }
            lv++;
         }
      }
      
      protected function selectBtn(param1:MenuBtn) : void
      {
         var callFunc:Function = null;
         var func:Function = null;
         func = null;
         var target:MenuBtn = param1;
         if(Boolean(target.children))
         {
            this.toogleChildren(target);
            return;
         }
         if(Boolean(target.func))
         {
            func = target.func;
         }
         else
         {
            func = this.getFucByLabel(target.label);
         }
         callFunc = function():void
         {
            if(func != null)
            {
               func();
            }
            this.mouseEnabled = this.mouseChildren = true;
            enabled = true;
         };
         this.enabled = false;
         target.select(callFunc);
      }
      
      private function getFucByLabel(param1:String) : Function
      {
         var func:Function = null;
         var label:String = param1;
         switch(label)
         {
            case "TEAM ACRADE":
               func = function():void
               {
                  GameMode.currentMode = 10;
                  MessionModel.I.reset();
                  if(GameConfig.SHOW_HOW_TO_PLAY)
                  {
                     MainGame.I.goHowToPlay();
                  }
                  else
                  {
                     MainGame.I.goSelect();
                  }
               };
               break;
            case "TEAM VS PEOPLE":
               func = function():void
               {
                  GameMode.currentMode = 11;
                  MainGame.I.goSelect();
               };
               break;
            case "TEAM VS CPU":
               func = function():void
               {
                  GameMode.currentMode = 12;
                  MainGame.I.goSelect();
               };
               break;
            case "TEAM WATCH":
               func = function():void
               {
                  GameMode.currentMode = 13;
                  MainGame.I.goSelect();
               };
               break;
            case "TEAM DUO":
               func = function():void
               {
                  GameMode.currentMode = 14;
                  MainGame.I.goSelect();
               };
               break;
            case "TEAM DUO WATCH":
               func = function():void
               {
                  GameMode.currentMode = 15;
                  MainGame.I.goSelect();
               };
               break;
            case "SINGLE ACRADE":
               func = function():void
               {
                  GameMode.currentMode = 20;
                  MessionModel.I.reset();
                  if(GameConfig.SHOW_HOW_TO_PLAY)
                  {
                     MainGame.I.goHowToPlay();
                  }
                  else
                  {
                     MainGame.I.goSelect();
                  }
               };
               break;
            case "SINGLE VS PEOPLE":
               func = function():void
               {
                  GameMode.currentMode = 21;
                  MainGame.I.goSelect();
               };
               break;
            case "SINGLE VS CPU":
               func = function():void
               {
                  GameMode.currentMode = 22;
                  MainGame.I.goSelect();
               };
               break;
            case "SINGLE WATCH":
               func = function():void
               {
                  GameMode.currentMode = 23;
                  MainGame.I.goSelect();
               };
               break;
            case "SINGLE VS DUO":
               func = function():void
               {
                  GameMode.currentMode = 24;
                  MainGame.I.goSelect();
               };
               break;
            case "SINGLE VS DUO WATCH":
               func = function():void
               {
                  GameMode.currentMode = 25;
                  MainGame.I.goSelect();
               };
               break;
            case "SURVIVOR":
               func = function():void
               {
                  GameMode.currentMode = 30;
                  MessionModel.I.reset();
                  MainGame.I.goSelect();
               };
               break;
            case "OPTION":
               func = function():void
               {
                  MainGame.I.goOption();
               };
               break;
            // OPTION 加了 children 后走子项分发，这里保留兜底
            case "GAME CFG":
               func = function():void
               {
                  MainGame.I.goOption();
               };
               break;
            case "RULE CFG":
               func = function():void
               {
                  MainGame.I.goRule();
               };
               break;
            case "CAMERA CFG":
               func = function():void
               {
                  MainGame.I.goCamera();
               };
               break;
            case "TRAINING":
               func = function():void
               {
                  GameMode.currentMode = 40;
                  MainGame.I.goSelect();
               };
               break;
            case "CREDITS":
               func = function():void
               {
                  MainGame.I.goCredits();
               };
               break;
            case "MORE GAMES":
               func = function():void
               {
                  MainGame.I.moreGames();
               };
         }
         return func;
      }
      
      /** 当前用键盘/手柄操作的那一层：最深展开层的子项；没有展开则一级列 */
      private function getActiveList() : Array
      {
         if(this._openLevels.length > 0)
         {
            return this._openLevels[this._openLevels.length - 1].children;
         }
         return this._btns;
      }
      
      /**
       * 展开 / 收起某一项。点已展开的项 = 收起它及其以下；点别的项 = 全部收起后只展开它。
       * 2026-11-21：由「只支持一层」改为层级栈，支持三级（TEAM PLAY → VS → PEOPLE 这种）。
       */
      private function toogleChildren(param1:MenuBtn) : void
      {
         var depth:int = this._openLevels.indexOf(param1);
         if(depth != -1)
         {
            this.closeFrom(depth);
            return;
         }
         this.closeFrom(0);
         this._openLevels.push(param1);
         param1.openChild();
         this.openChildren(param1);
         if(Boolean(param1.children) && param1.children.length > 0)
         {
            this._btnIndex = 0;
            this.hoverBtn(param1.children[0]);
         }
      }
      
      /**
       * 从第 param1 层开始收起（含该层及更深层），光标回到上一层里被收起的那一项。
       */
      private function closeFrom(param1:int) : void
      {
         if(param1 < 0)
         {
            param1 = 0;
         }
         var closing:MenuBtn = null;
         var backIndex:int = 0;
         var backList:Array = this._btns;
         if(param1 < this._openLevels.length)
         {
            closing = this._openLevels[param1];
            backList = param1 > 0 ? this._openLevels[param1 - 1].children : this._btns;
            backIndex = backList.indexOf(closing);
         }
         var i:int = this._openLevels.length - 1;
         while(i >= param1)
         {
            var lv:MenuBtn = this._openLevels[i];
            var j:int = 0;
            while(Boolean(lv.children) && j < lv.children.length)
            {
               var cb:MenuBtn = lv.children[j];
               if(Boolean(cb) && Boolean(cb.ui) && contains(cb.ui))
               {
                  removeChild(cb.ui);
                  cb.ui.alpha = 1;
               }
               j++;
            }
            lv.closeChild();
            this._openLevels.pop();
            i--;
         }
         if(param1 == 0)
         {
            this._openLevels = [];
         }
         this.layoutColumns(true);
         if(Boolean(closing) && backIndex >= 0)
         {
            this._btnIndex = backIndex;
            this.hoverBtn(closing);
         }
      }
      
      /**
       * 展开子列：子项挂到本组、按层级依次排到父列右侧，从左缘滑入 + 淡入。
       */
      private function openChildren(param1:MenuBtn) : void
      {
         var i:int = 0;
         var b:MenuBtn = null;
         while(i < param1.children.length)
         {
            b = param1.children[i];
            b.ui.alpha = 0;
            if(!contains(b.ui))
            {
               addChild(b.ui);
            }
            i++;
         }
         // 先立即定位（x 由 placeColumn 按累计层宽算），再统一从左侧滑入 + 淡入
         this.layoutColumns(false);
         i = 0;
         while(i < param1.children.length)
         {
            var tx:Number = param1.children[i].ui.x;
            param1.children[i].ui.x = tx - 20;
            TweenLite.to(param1.children[i].ui,0.2,{
               "x":tx,
               "alpha":1,
               "delay":i * 0.04
            });
            i++;
         }
      }
      
      /**
       * 全量排版：一级列 + 每一层展开列，从左往右依次紧排。
       * 列宽 / 行距 / 纵向夹取都在 placeColumn() 里算。
       */
      private function layoutColumns(param1:Boolean = false) : void
      {
         var i:int = 0;
         var mw:Number = 0;
         i = 0;
         while(i < this._btns.length)
         {
            mw = Math.max(mw,this._btns[i].measuredWidth);
            i++;
         }
         var w1:Number = mw + MenuBtn.TEXT_PAD * 2;
         var limit1:Number = GameConfig.GAME_SIZE.x - MARGIN_LEFT * 2 - COL_GAP;
         if(w1 > limit1)
         {
            w1 = limit1;
         }
         if(w1 < MenuBtn.TEXT_PAD * 2)
         {
            w1 = MenuBtn.TEXT_PAD * 2;
         }
         this._colW = w1;
         this.placeColumn(this._btns,MARGIN_LEFT,w1,MARGIN_TOP,param1);
         var x:Number = MARGIN_LEFT + w1 + COL_GAP;
         var lv:int = 0;
         while(lv < this._openLevels.length)
         {
            var btn:MenuBtn = this._openLevels[lv];
            var list:Array = btn.children;
            if(Boolean(list) && list.length > 0)
            {
               mw = 0;
               i = 0;
               while(i < list.length)
               {
                  mw = Math.max(mw,list[i].measuredWidth);
                  i++;
               }
               var w:Number = mw + MenuBtn.TEXT_PAD * 2;
               var avail:Number = GameConfig.GAME_SIZE.x - x - MARGIN_LEFT;
               if(w > avail)
               {
                  w = avail;
               }
               if(w < MenuBtn.TEXT_PAD * 2)
               {
                  w = MenuBtn.TEXT_PAD * 2;
               }
               this._childColW = w;
               this.placeColumn(list,x,w,btn.ui.y,param1);
               x = x + w + COL_GAP;
            }
            lv++;
         }
      }
      
      /**
       * 排一列：统一列宽、文字靠左、按背景条左缘摆位；纵向从 param4 起，
       * 越界先压行距（最低 0.6×），仍越界则整列上移并留日志。
       */
      private function placeColumn(param1:Array, param2:Number, param3:Number, param4:Number, param5:Boolean) : void
      {
         var n:int = Boolean(param1) ? int(param1.length) : 0;
         if(n < 1)
         {
            return;
         }
         var i:int = 0;
         var total:Number = 0;
         var availH:Number = GameConfig.GAME_SIZE.y - MARGIN_TOP - MARGIN_BOTTOM;
         while(i < n)
         {
            total += param1[i].height + ROW_GAP;
            i++;
         }
         var gap:Number = ROW_GAP;
         if(total > availH)
         {
            gap = Math.max(ROW_GAP * MIN_ROW_GAP_RATE,ROW_GAP - (total - availH) / n);
            total = 0;
            i = 0;
            while(i < n)
            {
               total += param1[i].height + gap;
               i++;
            }
         }
         var y:Number = param4;
         if(y + total > GameConfig.GAME_SIZE.y - MARGIN_BOTTOM)
         {
            y = GameConfig.GAME_SIZE.y - MARGIN_BOTTOM - total;
         }
         if(y < MARGIN_TOP)
         {
            y = MARGIN_TOP;
         }
         if(y + total > GameConfig.GAME_SIZE.y - MARGIN_BOTTOM)
         {
            Debugger.log("[MENU] column overflow n=" + n + " h=" + total + " gap=" + gap);
         }
         i = 0;
         while(i < n)
         {
            var b:MenuBtn = param1[i];
            b.setWidth(param3);
            b.alignLeft();
            // 2026-11-21：这里必须保证按钮已挂到本组（重构时漏过这一行，
            // 表现是 build() 正常、日志齐全，但一级菜单整个不显示 —— 因为按钮从未进显示列表）
            if(!contains(b.ui))
            {
               addChild(b.ui);
            }
            // 按背景条左缘摆位：mc_wzbtn 是中心注册，x 要给「目标左缘 − bgOffsetX」
            var tx:Number = param2 - b.bgOffsetX;
            if(param5)
            {
               TweenLite.to(b.ui,0.2,{
                  "x":tx,
                  "y":y
               });
            }
            else
            {
               b.ui.x = tx;
               b.ui.y = y;
            }
            y += b.height + gap;
            i++;
         }
      }
      
      private function render() : void
      {
         if(!this.enabled)
         {
            return;
         }
         if(GameUI.showingDialog())
         {
            return;
         }
         var _loc1_:Array = this.getActiveList();
         if(GameInputer.up("MENU",1))
         {
            --this._btnIndex;
            if(this._btnIndex < 0)
            {
               this._btnIndex = _loc1_.length - 1;
            }
            this.hoverBtn(_loc1_[this._btnIndex]);
         }
         if(GameInputer.down("MENU",1))
         {
            ++this._btnIndex;
            if(this._btnIndex > _loc1_.length - 1)
            {
               this._btnIndex = 0;
            }
            this.hoverBtn(_loc1_[this._btnIndex]);
         }
         if(GameInputer.select("MENU",1))
         {
            this.selectBtn(_loc1_[this._btnIndex]);
         }
         if(GameInputer.back(1))
         {
            // 三级时逐层回退：先收最深一层，再收上一层
            if(this._openLevels.length > 0)
            {
               this.closeFrom(this._openLevels.length - 1);
            }
         }
      }
   }
}

