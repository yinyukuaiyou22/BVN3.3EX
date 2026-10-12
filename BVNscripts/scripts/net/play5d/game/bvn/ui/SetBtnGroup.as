package net.play5d.game.bvn.ui
{
   import com.greensock.*;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TouchEvent;
   import flash.geom.*;
   import flash.system.Capabilities;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.utils.*;
   
   public class SetBtnGroup extends Sprite
   {
      
      public var keyEnable:Boolean = true;
      
      /** 触屏模式全局缩放（设置页/规则页/子页/覆盖层共用；MenuBtnGroup 亦复用此常量） */
      public static const TOUCH_SCALE:Number = 1.1;
      
      /**
       * 静态输入仲裁栈：谁最后注册谁收键（覆盖层压住下层），被释放后自动回退到下一个仍 keyEnable 的组。
       * 背景：GameInputer.isJustDown 的按下边沿表是进程级静态（input/GameInputer.as），
       * 谁先渲染谁抢到 true；子页/覆盖层与下层菜单会同时消费同一次按下
       * → 表现成「翻菜单音效响了，但可见页不动」。
       */
      private static var _regGroups:Array = [];
      
      /** 当前唯一收键者：栈顶（最后注册）且 keyEnable=true 且仍在显示列表上的组；都没有则无人收键 */
      public static function get inputOwner() : SetBtnGroup
      {
         var _loc1_:int = _regGroups.length - 1;
         while(_loc1_ >= 0)
         {
            var _loc2_:SetBtnGroup = _regGroups[_loc1_];
            if(Boolean(_loc2_) && _loc2_.keyEnable && Boolean(_loc2_.stage))
            {
               return _loc2_;
            }
            _loc1_--;
         }
         return null;
      }
      
      private function claimInput() : void
      {
         if(_regGroups.indexOf(this) == -1)
         {
            _regGroups.push(this);
         }
      }
      
      private function releaseInput() : void
      {
         var _loc1_:int = int(_regGroups.indexOf(this));
         if(_loc1_ != -1)
         {
            _regGroups.splice(_loc1_,1);
         }
      }
      
      public var startX:Number = 100;
      
      public var startY:Number = 50;
      
      public var endY:Number = 0;
      
      public var gap:Number = 75;
      
      public var direct:int = 1;
      
      public var gameInputType:String = "MENU";
      
      private var _btns:Vector.<SetBtn>;
      
      private var _arrow:*;
      
      private var _arrowIndex:int = -1;
      
      private var _scrollRect:Rectangle;
      
      // ===== 批次6.15：设置界面触屏拖拽滚动 =====
      // 背景：滚动原先只由 _arrowIndex 驱动（moveScroll），而手机端设置界面没有虚拟方向键
      // （ScreenPadManager 对非 GameState/SelectFighterStage 一律 menuMode → hide 游戏触屏盘），
      // _arrowIndex 只能靠"点击一个已可见的行"移动；视口外的行被 scrollRect 裁掉且不可命中，
      // 于是 16~17 行的设置列表永远滚不到末尾的 APPLY（也是唯一保存+退出入口）。
      /** 是否已启用拖拽滚动（仅设置主界面调用 enableScrollDrag，避免影响 SetScreenBtnView 等其它使用者） */
      public var dragScrollEnabled:Boolean = false;
      
      private var _dragTouchId:int = -1;
      
      private var _dragStartStageY:Number = 0;
      
      private var _dragStartScrollY:Number = 0;
      
      /** 本次手势是否已判定为拖拽 → touchHandler 据此屏蔽"拖完误触发的点击" */
      private var _dragMoved:Boolean = false;
      
      /**
       * 2026-09-29 触屏点按修复：本次手势被判定为拖拽后，供随后的 touchTap 消费的一次性标志。
       * 背景：AIR 的 touchTap 在 touchEnd **之后** 派发，所以不能在 touchEnd 里直接把
       * _dragMoved 置 false（那样门闸失效），也不能让它跨手势残留（会吞掉之后的正常点击）。
       * 改为 touchEnd 结算一次、touchTap 消费一次，用完即清。
       */
      private var _suppressTapOnce:Boolean = false;
      
      /**
       * 拖拽判定阈值：改用物理尺寸（0.4cm）按 screenDPI 换算。
       * 原值为固定 12 stage 像素 —— 在 1080p+ 屏上约 1mm，真机手指点按的天然抖动就会超过，
       * 于是「AIR 仍判定为 tap 并派发 touchTap」却被门闸当成拖拽吞掉，表现为「要点好几次才生效」。
       * 400dpi 下约 63px：远高于点按抖动，低于有意滚动的位移。
       */
      private static const DRAG_THRESHOLD_CM:Number = 0.4;
      
      private function get dragThreshold() : Number
      {
         var _loc1_:Number = Number(Capabilities.screenDPI);
         if(_loc1_ <= 0)
         {
            _loc1_ = 160;
         }
         return _loc1_ / 2.54 * DRAG_THRESHOLD_CM;
      }
      
      /** 单行触控热区高度，用于估算内容总高（与 SetBtn 的最小热区 48x44 对应） */
      private static const ROW_HIT_HEIGHT:Number = 44;
      
      /** 选项区右对齐时距离右边界的留白（本地单位） */
      private static const RIGHT_MARGIN:Number = 30;
      
      /**
       * 选项区右边界（SetBtn 本地坐标）。
       * 画布只有 800×600，而本对象在触屏模式下整体 scale=1.1 且原点在 (0,0)，
       * 可用本地宽只有 800/1.1≈727；若不右对齐，长标签行（如规则页的 CHANGE SPECIAL KEY）
       * 的取值与右箭头会越过 800 被 root.scrollRect 裁掉。
       */
      private function getOptionRightX() : Number
      {
         var _loc1_:Number = this.scaleX == 0 ? 1 : this.scaleX;
         return GameConfig.GAME_SIZE.x / _loc1_ - this.startX - RIGHT_MARGIN;
      }
      
      /**
       * 滚到底时末尾行下方保留的呼吸间距（本地单位）。
       * 2026-09-29：12 → 44（一整行）。原因：12 太紧，末行（APPLY）虽然"算得出来在屏内"，
       * 但行自身还有下划线/中文提示等额外高度，实测滚到底只露一半；
       * 留一整行后末行完整可见，且这个余量对拖拽与方向键两条路径同时生效。
       */
      private static const BOTTOM_MARGIN:Number = 44;
      
      public function SetBtnGroup()
      {
         super();
         if(GameConfig.TOUCH_MODE)
         {
            this.scaleX = this.scaleY = TOUCH_SCALE;
         }
      }
      
      public function initScroll(param1:Number, param2:Number) : void
      {
         this._scrollRect = new Rectangle(0,0,param1,param2);
         this.scrollRect = this._scrollRect;
      }
      
      /**
       * 批次6.15：启用拖拽滚动。必须在 initScroll 之后、且按钮已创建之后调用。
       * 铺一张与视口等大的透明热区（alpha=0 的填充在 Flash 中照样参与命中测试），
       * 这样从空白处起手的拖动也能被本对象接到，而不必恰好按在某个 SetBtn 上。
       */
      public function enableScrollDrag() : void
      {
         var _loc1_:Number = this._scrollRect ? this._scrollRect.width : GameConfig.GAME_SIZE.x;
         var _loc2_:Number = this._scrollRect ? this._scrollRect.height : GameConfig.GAME_SIZE.y;
         this.graphics.clear();
         this.graphics.beginFill(0,0);
         this.graphics.drawRect(0,0,_loc1_,_loc2_);
         this.graphics.endFill();
         this.addEventListener("touchBegin",this.scrollDragBegin);
         this.addEventListener("touchMove",this.scrollDragMove);
         this.addEventListener("touchEnd",this.scrollDragEnd);
         if(Boolean(launch.STAGE))
         {
            launch.STAGE.addEventListener("mouseWheel",this.scrollWheelHandler);
         }
         this.dragScrollEnabled = true;
         Debugger.log("[SetBtnGroup]","enableScrollDrag viewport=",_loc1_,"x",_loc2_);
         // [SCROLLDIAG] 滚动手感排查：确认有效视口高 / 末行位置 / 可滚上界是否符合预期
         // （末行应满足 lastRowY + 44 <= maxY + effViewH，否则末尾行仍在屏幕外）
         Debugger.log("[SCROLLDIAG] btns=",_btns ? _btns.length : -1,
            " rectH=",_scrollRect ? _scrollRect.height : -1,
            " scaleY=",this.scaleY,
            " gameH=",GameConfig.GAME_SIZE.y,
            " effViewH=",getEffectiveViewportHeight(),
            " lastRowY=",(_btns && _btns.length > 0 ? this.startY + this.gap * (_btns.length - 1) : -1),
            " contentBottom=",getContentBottomY(),
            " maxY=",getScrollMaxY());
      }
      
      /**
       * 可滚动上界。scrollRect.y 的方向语义：增大 = 显示更靠下的内容，
       * 因此合法区间是 [0, 内容底部 + BOTTOM_MARGIN - 有效视口高度]。
       * 拖拽(scrollDragMove)、滚轮(scrollWheelHandler)、方向键(moveScroll→getScrollIntoViewY)
       * 三条路径**全部**经此上限收口——历史上方向键那条是自己算公式且不 clamp，
       * 导致滚到底时末行 APPLY 只露一半。
       */
      /**
       * 有效视口高度（本地单位）——**不能直接用 _scrollRect.height**。
       * _scrollRect.height 是本地尺寸，而本对象在 TOUCH_MODE 下 scale=1.1：
       * 本地 600 渲染后是 660 游戏单位，超出 600 的那 ~55 本地单位被屏幕裁掉，
       * 真正看得见的只有 GAME_SIZE.y / scaleY ≈ 545 本地单位。
       * 若按 600 计算可滚动距离，末尾行的底部会被留在屏幕外
       * （真机现象：设置列表只能拖到"镜头大小"，下面的 APPLY 不可见）。
       *
       * 注意**不要**用 launch.FULL_SCREEN_SIZE.y —— 那是设备像素，与本地单位不同量纲
       * （它只参与 _gameSprite 的像素级缩放）。_gameSprite 把整个 800x600 游戏空间映射到屏幕，
       * Fill(0)/Center(1) 两种 screenMode 下游戏空间的完整高度都可见，
       * 所以"屏幕可视的游戏单位高度"恒为 GameConfig.GAME_SIZE.y。
       */
      private function getEffectiveViewportHeight() : Number
      {
         if(!this._scrollRect)
         {
            return 0;
         }
         var _loc1_:Number = this.scaleY == 0 ? 1 : this.scaleY;
         return Math.min(this._scrollRect.height,GameConfig.GAME_SIZE.y / _loc1_);
      }
      
      private function getScrollMaxY() : Number
      {
         if(!this._scrollRect || !this._btns || this._btns.length < 1)
         {
            return 0;
         }
         var _loc1_:Number = this.getContentBottomY();
         return Math.max(0,_loc1_ + BOTTOM_MARGIN - this.getEffectiveViewportHeight());
      }
      
      /**
       * 内容底部（本地单位）：末行自身 y + 它的实际高度。
       * 不再用 `startY + gap*(n-1) + ROW_HIT_HEIGHT` 估算 —— 末行下划线/中文提示会让实际高度更大，
       * 估算值偏小 → 滚到底时 APPLY 只露一半。
       */
      private function getContentBottomY() : Number
      {
         if(!this._btns || this._btns.length < 1)
         {
            return this.startY;
         }
         var _loc1_:SetBtn = this._btns[this._btns.length - 1];
         var _loc2_:Number = Math.max(ROW_HIT_HEIGHT,_loc1_.height);
         return _loc1_.y + _loc2_;
      }
      
      /**
       * 让第 param1 行完整落在可视区内所需的 scrollRect.y（已 clamp 到 [0, maxY]）。
       * 原方向键路径用自造公式 `-arrowIndex * (step - gap)` 且**没有 clamp**，
       * 比拖拽路径的上限少算十几本地单位 —— 表现为"方向键走到末尾，APPLY 只显示一半"。
       */
      private function getScrollIntoViewY(param1:int) : Number
      {
         if(!this._scrollRect || !this._btns || param1 < 0 || param1 > this._btns.length - 1)
         {
            return this._scrollRect ? this._scrollRect.y : 0;
         }
         var _loc2_:Number = this.getEffectiveViewportHeight();
         var _loc3_:Number = this._btns[param1].y;
         var _loc4_:Number = Math.max(ROW_HIT_HEIGHT,this._btns[param1].height);
         var _loc5_:Number = this._scrollRect.y;
         // 行底越过视口下沿 → 往下滚；行顶高出视口上沿 → 往上滚
         if(_loc3_ + _loc4_ + BOTTOM_MARGIN > _loc5_ + _loc2_)
         {
            _loc5_ = _loc3_ + _loc4_ + BOTTOM_MARGIN - _loc2_;
         }
         if(_loc3_ < _loc5_)
         {
            _loc5_ = _loc3_ - BOTTOM_MARGIN;
         }
         var _loc6_:Number = this.getScrollMaxY();
         if(_loc5_ < 0)
         {
            _loc5_ = 0;
         }
         if(_loc5_ > _loc6_)
         {
            _loc5_ = _loc6_;
         }
         return _loc5_;
      }
      
      private function applyScrollY(param1:Number) : void
      {
         if(!this._scrollRect)
         {
            return;
         }
         var _loc2_:Number = this.getScrollMaxY();
         if(param1 < 0)
         {
            param1 = 0;
         }
         if(param1 > _loc2_)
         {
            param1 = _loc2_;
         }
         this._scrollRect.y = param1;
         this.updateScroll();
      }
      
      private function scrollDragBegin(param1:TouchEvent) : void
      {
         if(!this.dragScrollEnabled || !this.keyEnable || !this._scrollRect)
         {
            return;
         }
         TweenLite.killTweensOf(this._scrollRect);
         this._dragTouchId = param1.touchPointID;
         this._dragStartStageY = param1.stageY;
         this._dragStartScrollY = this._scrollRect.y;
         this._dragMoved = false;
      }
      
      private function scrollDragMove(param1:TouchEvent) : void
      {
         if(!this.dragScrollEnabled || !this.keyEnable || !this._scrollRect)
         {
            return;
         }
         if(param1.touchPointID != this._dragTouchId)
         {
            return;
         }
         var _loc1_:Number = param1.stageY - this._dragStartStageY;
         if(!this._dragMoved)
         {
            if(Math.abs(_loc1_) < this.dragThreshold)
            {
               return;
            }
            this._dragMoved = true;
         }
         // 自然滚动：手指下拉 → 内容跟手向下 → 显示更靠上的内容 → scrollRect.y 减小
         // stageY 是全屏坐标，_scrollRect 是本地坐标 → 需除以本对象缩放
         var _loc2_:Number = this.scaleY == 0 ? 1 : this.scaleY;
         this.applyScrollY(this._dragStartScrollY - _loc1_ / _loc2_);
      }
      
      private function scrollDragEnd(param1:TouchEvent) : void
      {
         if(param1.touchPointID != this._dragTouchId)
         {
            return;
         }
         // 2026-09-29 触屏点按修复：手势结束即结算 —— 把"本次是否拖拽"交给随后派发的 touchTap
         // 消费一次，同时立刻复位 _dragMoved，避免状态跨手势残留吞掉之后的正常点击。
         this._suppressTapOnce = this._dragMoved;
         this._dragMoved = false;
         this._dragTouchId = -1;
      }
      
      private function scrollWheelHandler(param1:MouseEvent) : void
      {
         if(!this.dragScrollEnabled || !this.keyEnable || !this._scrollRect)
         {
            return;
         }
         TweenLite.killTweensOf(this._scrollRect);
         this.applyScrollY(this._scrollRect.y + (param1.delta > 0 ? 40 : -40));
      }
      
      public function initMainSet() : void
      {
         Debugger.log("[SetBtnGroup]","initMainSet()");
         this.initMainBtns();
         this.initArrow();
         GameRender.add(this.render,this);
         this.claimInput();
         GameInputer.focus();
         GameInputer.enabled = true;
      }
      
      /**
       * 规则设置页（RULE CFG）专用入口，与 initMainSet() 的区别只有数据源：
       * 走 GameInterface.instance.getRuleMenu() 而不是 getSettingMenu()。
       */
      public function initRuleSet() : void
      {
         Debugger.log("[SetBtnGroup]","initRuleSet()");
         this.buildBtnsByData(GameInterface.instance.getRuleMenu());
         this.initArrow();
         GameRender.add(this.render,this);
         this.claimInput();
         GameInputer.focus();
         GameInputer.enabled = true;
      }
      
      /**
       * 一键切换规则后，把每个选项的显示刷新为 ConfigVO 的当前值。
       * setOptionByValue 走静默分支，不会再派发 OPTION_CHANGE。
       */
      public function refreshOptionValues() : void
      {
         if(!this._btns)
         {
            return;
         }
         var _loc1_:ConfigVO = GameData.I.config;
         for each(var _loc2_:SetBtn in this._btns)
         {
            if(Boolean(_loc2_.optionKey) && _loc2_.getOption() != null)
            {
               _loc2_.setOptionByValue(_loc1_.getValueByKey(_loc2_.optionKey));
            }
         }
      }
      
      public function initKeySet() : void
      {
         Debugger.log("[SetBtnGroup]","initKeySet()");
         this.setBtnData([{
            "label":"SET ALL",
            "cn":"设置全部"
         },{
            "label":"SET DEFAULT",
            "cn":"还原默认按键"
         },{
            "label":"APPLY",
            "cn":"应用"
         },{
            "label":"CANCEL",
            "cn":"取消"
         }]);
      }
      
      public function initControlSet() : void
      {
         Debugger.log("[SetBtnGroup]","initControlSet()");
         var _loc1_:ConfigVO = GameData.I.config;
         this.setBtnData([{
            "label":"Screen Button",
            "cn":"屏幕按钮设置"
         },{
            "label":"Joy Target",
            "cn":"手柄控制权",
            "options":[{
               "label":"Follow Switch",
               "cn":"跟随切换",
               "value":0
            },{
               "label":"P1",
               "cn":"1P",
               "value":1
            },{
               "label":"P2",
               "cn":"2P",
               "value":2
            }],
            "optoinKey":"joyTarget",
            "optionValue":_loc1_.getValueByKey("joyTarget")
         },{
            "label":"Keyboard Input",
            "cn":"键盘输入",
            "options":[{
               "label":"ON",
               "cn":"开",
               "value":true
            },{
               "label":"OFF",
               "cn":"关",
               "value":false
            }],
            "optoinKey":"ENABLE_KEYBOARD",
            "optionValue":_loc1_.getValueByKey("ENABLE_KEYBOARD")
         },{
            "label":"BACK",
            "cn":"返回"
         }]);
      }
      
      public function setBtnData(param1:Array, param2:int = 0) : void
      {
         Debugger.log("[SetBtnGroup]","setBtnData count=",param1.length);
         var _loc3_:SetBtn = null;
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         this._btns = new Vector.<SetBtn>();
         while(_loc4_ < param1.length)
         {
            _loc5_ = param1[_loc4_];
            _loc3_ = this.addBtn(_loc5_.label,_loc5_.cn,_loc5_.options);
            if(_loc5_.optoinKey != undefined)
            {
               _loc3_.optionKey = _loc5_.optoinKey;
            }
            if(_loc5_.optionValue != undefined)
            {
               _loc3_.setOptionByValue(_loc5_.optionValue);
            }
            _loc4_++;
         }
         this.initArrow(param2);
         GameRender.add(this.render,this);
         this.claimInput();
         GameInputer.focus();
         GameInputer.enabled = true;
      }
      
      public function destory() : void
      {
         var _loc1_:* = undefined;
         // 批次6.15：注销拖拽滚动监听（含挂到 stage 上的滚轮监听）
         this.removeEventListener("touchBegin",this.scrollDragBegin);
         this.removeEventListener("touchMove",this.scrollDragMove);
         this.removeEventListener("touchEnd",this.scrollDragEnd);
         if(Boolean(launch.STAGE))
         {
            try
            {
               launch.STAGE.removeEventListener("mouseWheel",this.scrollWheelHandler);
            }
            catch(e:Error)
            {
            }
         }
         this.dragScrollEnabled = false;
         if(Boolean(this._btns))
         {
            for each(_loc1_ in this._btns)
            {
               _loc1_.destory();
               _loc1_.removeEventListener("touchTap",this.touchHandler);
               _loc1_.removeEventListener("mouseOver",this.mouseHandler);
               _loc1_.removeEventListener("click",this.mouseHandler);
               _loc1_.removeEventListener("OPTION_CHANGE",this.onChangeOption);
               _loc1_.removeEventListener("SELECT",this.onSelect);
            }
            this._btns = null;
         }
         GameRender.remove(this.render,this);
         this.releaseInput();
      }
      
      private function initMainBtns() : void
      {
         var _loc4_:* = GameInterface.instance.getSettingMenu();
         if(!_loc4_)
         {
            _loc4_ = [{
               "txt":"P1 KEY SET",
               "cn":"玩家1 按键设置"
            },{
               "txt":"P2 KEY SET",
               "cn":"玩家2 按键设置"
            },{
               "txt":"COM LEVEL",
               "cn":"电脑等级",
               "options":[{
                  "label":"VERY EASY",
                  "cn":"非常简单",
                  "value":1
               },{
                  "label":"EASY",
                  "cn":"简单",
                  "value":2
               },{
                  "label":"NORMAL",
                  "cn":"正常",
                  "value":3
               },{
                  "label":"HARD",
                  "cn":"困难",
                  "value":4
               },{
                  "label":"VERY HARD",
                  "cn":"非常困难",
                  "value":5
               },{
                  "label":"HELL",
                  "cn":"地狱",
                  "value":6
               }],
               "optoinKey":"AI_level"
            },{
               "txt":"OPERATE MODE",
               "cn":"按键操作模式",
               "options":[{
                  "label":"NORMAL",
                  "cn":"正常模式",
                  "value":0
               },{
                  "label":"CLASSIC",
                  "cn":"经典模式",
                  "value":1
               }],
               "optoinKey":"keyInputMode"
            },{
               "txt":"LIFE",
               "cn":"生命值",
               "options":[{
                  "label":"50%",
                  "cn":"50%",
                  "value":0.5
               },{
                  "label":"100%",
                  "cn":"100%",
                  "value":1
               },{
                  "label":"200%",
                  "cn":"200%",
                  "value":2
               },{
                  "label":"300%",
                  "cn":"300%",
                  "value":3
               },{
                  "label":"500%",
                  "cn":"500%",
                  "value":5
               }],
               "optoinKey":"fighterHP"
            },{
               "txt":"TIME",
               "cn":"对战时间",
               "options":[{
                  "label":"30s",
                  "cn":"30秒",
                  "value":30
               },{
                  "label":"60s",
                  "cn":"60秒",
                  "value":60
               },{
                  "label":"90s",
                  "cn":"90秒",
                  "value":90
               },{
                  "label":"∞",
                  "cn":"无限制",
                  "value":-1
               }],
               "optoinKey":"fightTime"
            },{
               "txt":"SOUND",
               "cn":"游戏音效",
               "options":[{
                  "label":"0%",
                  "cn":"0%",
                  "value":0
               },{
                  "label":"10%",
                  "cn":"10%",
                  "value":0.1
               },{
                  "label":"30%",
                  "cn":"30%",
                  "value":0.3
               },{
                  "label":"50%",
                  "cn":"50%",
                  "value":0.5
               },{
                  "label":"70%",
                  "cn":"70%",
                  "value":0.7
               },{
                  "label":"100%",
                  "cn":"100%",
                  "value":1
               }],
               "optoinKey":"soundVolume"
            },{
               "txt":"BGM",
               "cn":"背景音乐",
               "options":[{
                  "label":"0%",
                  "cn":"0%",
                  "value":0
               },{
                  "label":"10%",
                  "cn":"10%",
                  "value":0.1
               },{
                  "label":"30%",
                  "cn":"30%",
                  "value":0.3
               },{
                  "label":"50%",
                  "cn":"50%",
                  "value":0.5
               },{
                  "label":"70%",
                  "cn":"70%",
                  "value":0.7
               },{
                  "label":"100%",
                  "cn":"100%",
                  "value":1
               }],
               "optoinKey":"bgmVolume"
            },{
               "txt":"QUALITY",
               "cn":"画质等级",
               "options":[{
                  "label":"LOW",
                  "cn":"低",
                  "value":"low"
               },{
                  "label":"MEDIUM",
                  "cn":"中",
                  "value":"medium"
               },{
                  "label":"HIGH",
                  "cn":"高",
                  "value":"high"
               },{
                  "label":"BEST",
                  "cn":"最高",
                  "value":"best"
               }],
               "optoinKey":"quality"
            }];
         }
         this.buildBtnsByData(_loc4_);
      }
      
      /**
       * 按数据数组装配按钮并在末尾追加 APPLY，initMainBtns / initRuleSet 共用。
       */
      private function buildBtnsByData(param1:Array) : void
      {
         var _loc1_:SetBtn = null;
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         this._btns = new Vector.<SetBtn>();
         var _loc5_:ConfigVO = GameData.I.config;
         while(_loc2_ < param1.length)
         {
            _loc3_ = param1[_loc2_];
            // 批次 6.13 修复：菜单数组可能在单手柄时返回含 null 元素的数组（P2 改键入口），此处需过滤避免 #1009
            if(_loc3_ == null)
            {
               _loc2_++;
               continue;
            }
            _loc1_ = this.addBtn(_loc3_.txt,_loc3_.cn,_loc3_.options);
            if(Boolean(_loc3_.select))
            {
               _loc1_.onSelect = _loc3_.select;
            }
            _loc1_.optionKey = _loc3_.optoinKey;
            if(Boolean(_loc1_.optionKey))
            {
               _loc1_.setOptionByValue(_loc5_.getValueByKey(_loc1_.optionKey));
            }
            _loc2_++;
         }
         this.addBtn("APPLY","应用");
      }
      
      private function addBtn(param1:String, param2:String, param3:Array = null) : SetBtn
      {
         var _loc4_:SetBtn = new SetBtn(param1,param2);
         if(GameConfig.TOUCH_MODE)
         {
            _loc4_.addEventListener("touchTap",this.touchHandler);
         }
         else
         {
            _loc4_.addEventListener("mouseOver",this.mouseHandler);
            _loc4_.addEventListener("click",this.mouseHandler);
         }
         switch(this.direct)
         {
            case 0:
               _loc4_.x = this.startX + this.gap * this._btns.length;
               _loc4_.y = this.startY;
               break;
            case 1:
               _loc4_.x = this.startX;
               _loc4_.y = this.startY + this.gap * this._btns.length;
         }
         addChild(_loc4_);
         if(Boolean(param3))
         {
            // 先下发右边界，setOption → updateOption 才会按右对齐排选项与箭头
            _loc4_.setRightX(this.getOptionRightX());
            _loc4_.setOption(param3);
            _loc4_.addEventListener("OPTION_CHANGE",this.onChangeOption);
         }
         else
         {
            _loc4_.addEventListener("SELECT",this.onSelect);
         }
         this._btns.push(_loc4_);
         return _loc4_;
      }
      
      private function touchHandler(param1:TouchEvent) : void
      {
         if(!this.keyEnable)
         {
            return;
         }
         // 批次6.15：本次手势已判定为拖拽滚动 → 不当作点击，避免拖完列表误切换选项/误触发 APPLY
         // 2026-09-29：改为一次性标志，吞完即清，绝不残留到下一个手势
         if(this._suppressTapOnce)
         {
            this._suppressTapOnce = false;
            return;
         }
         var _loc2_:SetBtn = param1.currentTarget as SetBtn;
         var _loc3_:int = int(this._btns.indexOf(_loc2_));
         if(_loc3_ == -1)
         {
            return;
         }
         var _loc4_:Object = _loc2_.getOption();
         if(_loc3_ == this._arrowIndex)
         {
            if(_loc4_ != null)
            {
               _loc2_.nextOption();
            }
            else
            {
               _loc2_.select();
            }
            return;
         }
         this.setArrowIndex(_loc3_,true);
      }
      
      private function mouseHandler(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         if(!this.keyEnable)
         {
            return;
         }
         var _loc3_:SetBtn = param1.currentTarget as SetBtn;
         switch(param1.type)
         {
            case "mouseOver":
               _loc2_ = int(this._btns.indexOf(_loc3_));
               if(_loc2_ != -1)
               {
                  this.setArrowIndex(_loc2_);
               }
               break;
            case "click":
               if(_loc3_.getOption() == null)
               {
                  _loc3_.select();
               }
               else if(Boolean(param1.target))
               {
                  switch(param1.target.name)
                  {
                     case "prevArrow":
                        _loc3_.prevOption();
                        break;
                     case "nextArrow":
                        _loc3_.nextOption();
                  }
               }
         }
      }
      
      private function initArrow(param1:int = 0) : void
      {
         this._arrow = ResUtils.I.createDisplayObject(ResUtils.I.common_ui,"select_arrow_mc");
         addChild(this._arrow);
         this.setArrowIndex(param1);
      }
      
      public function setArrowIndex(param1:int, param2:Boolean = true) : void
      {
         var btn:SetBtn = null;
         var id:int = param1;
         var sound:Boolean = param2;
         if(this._arrowIndex == id)
         {
            return;
         }
         if(id < 0)
         {
            id = this._btns.length - 1;
         }
         if(id > this._btns.length - 1)
         {
            id = 0;
         }
         btn = this._btns[id];
         this._arrowIndex = id;
         this._arrow.x = btn.x - 10;
         this._arrow.y = btn.y + 15;
         this._btns.every(function(param1:SetBtn, param2:int, param3:Vector.<SetBtn>):Boolean
         {
            if(btn == param1)
            {
               param1.hover();
            }
            else
            {
               param1.hoverOut();
            }
            return true;
         });
         if(sound)
         {
            SoundCtrl.I.sndSelect();
         }
         this.moveScroll();
      }
      
      private function moveScroll() : void
      {
         if(!this._scrollRect || this.direct != 1)
         {
            return;
         }
         if(!this._btns || this._btns.length < 1)
         {
            return;
         }
         // 与拖拽/滚轮同一条 clamp 路径（getScrollIntoViewY 内部按 getScrollMaxY 收口），
         // 不再各自算一套公式 —— 这正是末行只露一半的来源。
         var _loc1_:Number = this.getScrollIntoViewY(this._arrowIndex);
         TweenLite.to(this._scrollRect,0.2,{
            "y":_loc1_,
            "onUpdate":this.updateScroll
         });
      }
      
      private function updateScroll() : void
      {
         this.scrollRect = this._scrollRect;
      }
      
      private function render() : void
      {
         // 输入仲裁：只有当前唯一 owner 才消费按下边沿。
         // 否则下层菜单会先抢走同一次按下（渲染顺序由 GameRender 的字典遍历决定，不保证），
         // 表现为「翻菜单音效响了但可见页不动」。
         if(inputOwner != this)
         {
            return;
         }
         if(!this.keyEnable)
         {
            return;
         }
         if(!this._btns || this._btns.length < 1)
         {
            return;
         }
         var _loc1_:SetBtn = this._btns[this._arrowIndex];
         if(GameInputer.up(this.gameInputType,1))
         {
            if(this.direct == 1)
            {
               this.setArrowIndex(this._arrowIndex - 1);
            }
         }
         if(GameInputer.down(this.gameInputType,1))
         {
            if(this.direct == 1)
            {
               this.setArrowIndex(this._arrowIndex + 1);
            }
         }
         if(GameInputer.left(this.gameInputType,1))
         {
            if(this.direct == 0)
            {
               this.setArrowIndex(this._arrowIndex - 1);
            }
            if(this.direct == 1)
            {
               _loc1_.prevOption();
            }
         }
         if(GameInputer.right(this.gameInputType,1))
         {
            if(this.direct == 0)
            {
               this.setArrowIndex(this._arrowIndex + 1);
            }
            if(this.direct == 1)
            {
               _loc1_.nextOption();
            }
         }
         if(GameInputer.select(this.gameInputType,1))
         {
            _loc1_.select();
         }
      }
      
      private function onChangeOption(param1:SetBtnEvent) : void
      {
         dispatchEvent(param1.newEvent());
      }
      
      private function onSelect(param1:SetBtnEvent) : void
      {
         var _loc2_:SetBtn = param1.currentTarget as SetBtn;
         Debugger.log("[SetBtnGroup]","onSelect label=",_loc2_ != null ? _loc2_.label : "?");
         if(_loc2_.onSelect != null)
         {
            _loc2_.onSelect();
         }
         dispatchEvent(param1.newEvent());
      }
   }
}