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
      
      /** 子列宽度（layoutChildColumn 后有效） */
      private var _childColW:Number = 0;
      
      private var _btnIndex:int;
      
      private var _btns:Array = [];
      
      private var _showIngChildrenBtn:MenuBtn;
      
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
         // 子列真放不下时由 layoutChildColumn() 压缩行距并在日志里留痕。
      }
      
      private function hoverBtn(param1:MenuBtn) : void
      {
         var _loc2_:* = null;
         var _loc3_:int = 0;
         var _loc4_:* = null;
         var _loc5_:int = 0;
         while(_loc3_ < this._btns.length)
         {
            _loc2_ = this._btns[_loc3_];
            if(_loc2_ == param1)
            {
               _loc2_.hover();
               this._btnIndex = _loc3_;
            }
            else
            {
               _loc2_.normal();
            }
            _loc3_++;
         }
         if(Boolean(this._showIngChildrenBtn))
         {
            _loc4_ = this._showIngChildrenBtn.children;
            while(_loc5_ < _loc4_.length)
            {
               _loc2_ = _loc4_[_loc5_];
               if(_loc2_ == param1)
               {
                  _loc2_.hover();
                  this._btnIndex = _loc5_;
               }
               else
               {
                  _loc2_.normal();
               }
               _loc5_++;
            }
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
      
      private function toogleChildren(param1:MenuBtn) : void
      {
         var _loc2_:* = false;
         if(Boolean(this._showIngChildrenBtn))
         {
            _loc2_ = param1 == this._showIngChildrenBtn;
            if(!_loc2_)
            {
               this._showIngChildrenBtn.normal();
            }
            this.closeChildren(_loc2_,_loc2_);
            if(Boolean(_loc2_))
            {
               return;
            }
         }
         this._showIngChildrenBtn = param1;
         param1.openChild();
         this.openChildren(param1);
         this.hoverBtn(param1.children[0]);
      }
      
      /**
       * 展开子列：子项挂到本组、排到父列右侧（父列位置不动），从左缘滑入 + 淡入。
       * 与旧实现的区别：旧实现把所有子项插进主列的同一条阶梯里续排，父列因此被挤走。
       */
      private function openChildren(param1:MenuBtn) : void
      {
         var _loc2_:int = 0;
         var _loc3_:MenuBtn = null;
         var _loc4_:Number = NaN;
         while(_loc2_ < param1.children.length)
         {
            _loc3_ = param1.children[_loc2_];
            _loc3_.ui.alpha = 0;
            if(!contains(_loc3_.ui))
            {
               addChild(_loc3_.ui);
            }
            _loc2_++;
         }
         // 先做一次「立即定位」（左缘对齐在 layoutChildColumn 里算），再统一从左侧滑入 + 淡入。
         // 不能像旧版那样自己写死初始 x：偏移量要由 bgOffsetX 决定，否则滑入起点会歪。
         this.layoutChildColumn(param1,false);
         _loc2_ = 0;
         while(_loc2_ < param1.children.length)
         {
            _loc4_ = param1.children[_loc2_].ui.x;
            param1.children[_loc2_].ui.x = _loc4_ - 20;
            TweenLite.to(param1.children[_loc2_].ui,0.2,{
               "x":_loc4_,
               "alpha":1,
               "delay":_loc2_ * 0.04
            });
            _loc2_++;
         }
      }
      
      private function closeChildren(param1:Boolean, param2:Boolean) : void
      {
         var _loc3_:int = 0;
         var _loc4_:* = null;
         var _loc5_:Array = this._showIngChildrenBtn.children;
         _loc3_ = 0;
         while(_loc3_ < _loc5_.length)
         {
            _loc4_ = _loc5_[_loc3_];
            if(Boolean(_loc4_) && Boolean(_loc4_.ui) && contains(_loc4_.ui))
            {
               removeChild(_loc4_.ui);
            }
            _loc3_++;
         }
         this._showIngChildrenBtn.closeChild();
         this._showIngChildrenBtn = null;
         // 父列位置从不改动，这里不需要重排；保留参数以兼容既有调用点
         if(param1)
         {
            this.layoutColumns(Boolean(param2));
         }
      }
      
      /**
       * 一级列排版：左侧竖列，x 恒定，列宽统一（按最宽标签 + 两侧内边距），文字靠左。
       * param1 = true 时用 tween 过渡，false 时立即赋值（build / 重置用）。
       */
      private function layoutColumns(param1:Boolean = false) : void
      {
         var _loc2_:int = 0;
         var _loc3_:MenuBtn = null;
         var _loc4_:Number = 0;
         var _loc5_:Number = 0;
         var _loc6_:Number = 0;
         var _loc7_:Number = 0;
         _loc2_ = 0;
         while(_loc2_ < this._btns.length)
         {
            _loc4_ = Math.max(_loc4_,this._btns[_loc2_].measuredWidth);
            _loc2_++;
         }
         this._colW = _loc4_ + MenuBtn.TEXT_PAD * 2;
         var _loc8_:Number = GameConfig.GAME_SIZE.x - MARGIN_LEFT * 2 - COL_GAP;
         if(this._colW > _loc8_)
         {
            this._colW = _loc8_;
         }
         if(this._colW < MenuBtn.TEXT_PAD * 2)
         {
            this._colW = MenuBtn.TEXT_PAD * 2;
         }
         _loc5_ = MARGIN_LEFT;
         _loc6_ = MARGIN_TOP;
         _loc2_ = 0;
         while(_loc2_ < this._btns.length)
         {
            _loc3_ = this._btns[_loc2_];
            _loc3_.setWidth(this._colW);
            _loc3_.alignLeft();
            if(!contains(_loc3_.ui))
            {
               addChild(_loc3_.ui);
            }
            // 按「背景条左缘」摆位：mc_wzbtn 是中心注册，直接给 MARGIN_LEFT 会让左半截出屏
            var _locX:Number = _loc5_ - _loc3_.bgOffsetX;
            if(param1)
            {
               TweenLite.to(_loc3_.ui,0.2,{
                  "x":_locX,
                  "y":_loc6_
               });
            }
            else
            {
               _loc3_.ui.x = _locX;
               _loc3_.ui.y = _loc6_;
            }
            _loc6_ += _loc3_.height + ROW_GAP;
            _loc2_++;
         }
         if(Boolean(this._showIngChildrenBtn))
         {
            this.layoutChildColumn(this._showIngChildrenBtn,param1);
         }
      }
      
      /**
       * 子列排版：父列右侧独立一列，列宽按子项最宽标签算并夹进屏幕；
       * 起点对齐父项 y，底端越界整列上移；仍放不下先压缩行距（最低 0.6×），再不行允许溢出并留日志。
       */
      private function layoutChildColumn(param1:MenuBtn, param2:Boolean = false) : void
      {
         var _loc3_:Array = param1.children;
         if(!_loc3_ || _loc3_.length < 1)
         {
            return;
         }
         var _loc4_:Number = 0;
         var _loc5_:int = 0;
         var _loc6_:Number = 0;
         var _loc7_:Number = 0;
         var _loc8_:Number = 0;
         _loc5_ = 0;
         while(_loc5_ < _loc3_.length)
         {
            _loc4_ = Math.max(_loc4_,_loc3_[_loc5_].measuredWidth);
            _loc5_++;
         }
         _loc6_ = _loc4_ + MenuBtn.TEXT_PAD * 2;
         var _loc9_:Number = MARGIN_LEFT + this._colW + COL_GAP;
         var _loc10_:Number = GameConfig.GAME_SIZE.x - _loc9_ - MARGIN_LEFT;
         if(_loc6_ > _loc10_)
         {
            _loc6_ = _loc10_;
         }
         if(_loc6_ < MenuBtn.TEXT_PAD * 2)
         {
            _loc6_ = MenuBtn.TEXT_PAD * 2;
         }
         this._childColW = _loc6_;
         // 2026-11-21：二级项在 2026-11-12 提到 80 高后，单列 8 项 = 680 > 可用 480，
         // 旧逻辑把行距压到 3 仍有 664，只能打日志放它越界 —— 真机上 TEAM TAG VS CPU（模式 17）
         // 整项落到屏外，触屏永远点不到（键盘/手柄靠 index 仍能选中，所以一直没被发现）。
         // 现在：单列放不下就改两列网格（列优先：前一半在左列、后一半在右列），
         // 行高/字号/行距一律不动，索引仍是 0..n-1 的一维顺序（导航语义不变）。
         var _loc11_:Number = GameConfig.GAME_SIZE.y - MARGIN_TOP - MARGIN_BOTTOM;
         var _loc14_:Number = 0;
         _loc5_ = 0;
         while(_loc5_ < _loc3_.length)
         {
            _loc14_ += _loc3_[_loc5_].height + ROW_GAP;
            _loc5_++;
         }
         var _loc15_:int = 1;
         var _loc16_:int = _loc3_.length;
         if(_loc14_ > _loc11_)
         {
            // 两列各用「单列标签宽」，两列 + 列间距要塞进父列右侧的可用宽度，否则退回单列并留日志
            if(_loc6_ * 2 + COL_GAP <= _loc10_)
            {
               _loc15_ = 2;
               _loc16_ = Math.ceil(_loc3_.length / 2);
            }
            else
            {
               Debugger.log("[MENU] child grid skipped: need=" + (_loc6_ * 2 + COL_GAP) + " avail=" + _loc10_);
            }
         }
         var _loc17_:Array = [];
         var _loc18_:Number = 0;
         _loc5_ = 0;
         while(_loc5_ < _loc16_)
         {
            _loc18_ = _loc3_[_loc5_].height;
            if(_loc15_ > 1 && _loc5_ + _loc16_ < _loc3_.length)
            {
               _loc18_ = Math.max(_loc18_,_loc3_[_loc5_ + _loc16_].height);
            }
            _loc17_.push(_loc18_);
            _loc5_++;
         }
         _loc7_ = ROW_GAP;
         _loc8_ = _loc16_ * _loc7_;
         _loc5_ = 0;
         while(_loc5_ < _loc16_)
         {
            _loc8_ += Number(_loc17_[_loc5_]);
            _loc5_++;
         }
         if(_loc8_ > _loc11_)
         {
            _loc7_ = Math.max(ROW_GAP * MIN_ROW_GAP_RATE,ROW_GAP - (_loc8_ - _loc11_) / _loc16_);
            _loc8_ = _loc16_ * _loc7_;
            _loc5_ = 0;
            while(_loc5_ < _loc16_)
            {
               _loc8_ += Number(_loc17_[_loc5_]);
               _loc5_++;
            }
         }
         var _loc12_:Number = param1.ui.y;
         if(_loc12_ + _loc8_ > GameConfig.GAME_SIZE.y - MARGIN_BOTTOM)
         {
            _loc12_ = GameConfig.GAME_SIZE.y - MARGIN_BOTTOM - _loc8_;
         }
         if(_loc12_ < MARGIN_TOP)
         {
            _loc12_ = MARGIN_TOP;
         }
         if(_loc12_ + _loc8_ > GameConfig.GAME_SIZE.y - MARGIN_BOTTOM)
         {
            Debugger.log("[MENU] child column overflow n=" + _loc3_.length + " h=" + _loc8_ + " gap=" + _loc7_ + " cols=" + _loc15_);
         }
         var _loc19_:int = 0;
         _loc5_ = 0;
         while(_loc5_ < _loc16_)
         {
            _loc19_ = 0;
            while(_loc19_ < _loc15_)
            {
               var _loc20_:int = _loc5_ + _loc19_ * _loc16_;
               if(_loc20_ < _loc3_.length)
               {
                  var _loc13_:MenuBtn = _loc3_[_loc20_];
                  _loc13_.setWidth(_loc6_);
                  _loc13_.alignLeft();
                  // 同样按背景条左缘摆位（子列也有自己的统一列宽与中心注册美术）
                  var _locX2:Number = _loc9_ + _loc19_ * (_loc6_ + COL_GAP) - _loc13_.bgOffsetX;
                  if(param2)
                  {
                     TweenLite.to(_loc13_.ui,0.2,{
                        "x":_locX2,
                        "y":_loc12_
                     });
                  }
                  else
                  {
                     _loc13_.ui.x = _locX2;
                     _loc13_.ui.y = _loc12_;
                  }
               }
               _loc19_++;
            }
            _loc12_ += Number(_loc17_[_loc5_]) + _loc7_;
            _loc5_++;
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
         var _loc1_:Array = this._showIngChildrenBtn ? this._showIngChildrenBtn.children : this._btns;
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
            if(Boolean(this._showIngChildrenBtn))
            {
               this._btnIndex = this._showIngChildrenBtn.index;
               this.closeChildren(true,true);
            }
         }
      }
   }
}

