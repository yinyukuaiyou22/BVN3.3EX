package net.play5d.game.bvn.ui.dialog
{
   import com.greensock.*;
   import flash.display.*;
   import flash.events.*;
   import flash.text.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.kyo.display.bitmap.*;
   import net.play5d.kyo.display.shapes.*;

   /**
    * 重开对局确认弹窗（样式严格对齐3.3 ConfrimUI）。
    * 移植自3.7扩展分支的重开交互，但按钮文案、标题、触控热区按3.3规范重做。
    */
   public class RestartConfirmUI extends Sprite
   {

      private var _titleTxt:TextField;

      private var _msgTxt:TextField;

      private var _btnBox:Sprite;
        private var _btnGroup:SetBtnGroup;

      private var _lastTapBtn:Sprite;

      private var _lastTapTime:int = 0;

      public var yesBack:Function;

      public var noBack:Function;

      public function RestartConfirmUI()
      {
         super();
         this.build();
      }

      public function destory() : void
      {
         if(Boolean(this._btnBox))
         {
            this.detachBtnListeners();
              this.detachBtnListeners();
            if(Boolean(this._btnBox.parent))
              {
                 this._btnBox.parent.removeChild(this._btnBox);
              }
            this._btnBox = null;
         }
         if(Boolean(this._titleTxt))
         {
            this._titleTxt = null;
         }
         if(Boolean(this._msgTxt))
         {
            this._msgTxt = null;
         }
         this._lastTapBtn = null;
      }

      public function close() : void
      {
         try
         {
            if(Boolean(this.parent))
            {
               this.parent.removeChild(this);
            }
         }
         catch(e:Error)
         {
         }
         this.destory();
      }

      private function build() : void
      {
         // 全屏遮罩：与 ConfrimUI 相同的半透明黑底，但 mouseEnabled=true 以阻止点击穿透。
         var _loc1_:Sprite = new Sprite();
         _loc1_.graphics.beginFill(0,0.3);
         _loc1_.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         _loc1_.graphics.endFill();
         _loc1_.mouseEnabled = true;
         _loc1_.mouseChildren = false;
         addChild(_loc1_);

         var _loc2_:Box = new Box(GameConfig.GAME_SIZE.x,300,0,0.8);
         _loc2_.y = (GameConfig.GAME_SIZE.y - _loc2_.height) / 2;
         addChild(_loc2_);

         this._titleTxt = new TextField();
         UIUtils.formatText(this._titleTxt,{
            "color":16777215,
            "size":20,
            "align":"center"
         });
         this._titleTxt.width = GameConfig.GAME_SIZE.x;
         this._titleTxt.height = 30;
         this._titleTxt.text = "提示";
         this._titleTxt.mouseEnabled = false;
         this._titleTxt.y = 18;
         _loc2_.addChild(this._titleTxt);

         this._msgTxt = new TextField();
         UIUtils.formatText(this._msgTxt,{
            "color":16777215,
            "size":20,
            "align":"center"
         });
         this._msgTxt.width = GameConfig.GAME_SIZE.x;
         this._msgTxt.height = 100;
         this._msgTxt.text = "确定要重新开始当前对局吗？";
         this._msgTxt.mouseEnabled = false;
         this._msgTxt.y = this._titleTxt.y + this._titleTxt.height + 80;
         _loc2_.addChild(this._msgTxt);

           // 默认无焦点：不使用 SetBtnGroup 的键盘/两段式触控，改用下方 createBtn 直接创建中文按钮。
           this._btnBox = new Sprite();
           this._btnBox.addChild(this.createBtn("确定","confirm",0));
           this._btnBox.addChild(this.createBtn("取消","cancel",200));
           this.attachBtnListeners();
           this._btnBox.x = (GameConfig.GAME_SIZE.x - this._btnBox.width) / 2 + 30;
           this._btnBox.y = _loc2_.height - 80;
           _loc2_.addChild(this._btnBox);
           /*
            *  以下旧 SetBtnGroup 按钮创建代码已由 _btnBox 替代，保留为注释说明。
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.startX = this._btnGroup.startY = 0;
         this._btnGroup.direct = 0;
         this._btnGroup.gap = 200;
         this._btnGroup.setBtnData([{
            "label":"CONFIRM",
            "cn":"确定"
         },{
            "label":"CANCEL",
            "cn":"取消"
         }],0);
         // 默认无焦点：禁用键盘/内部触控处理（内部 touchHandler 为两段式，不适合确认弹窗），
         // 由下方 attachBtnListeners 直接绑定单击/触摸事件。
         this._btnGroup.keyEnable = false;
         this.hideArrow();
         this.attachBtnListeners();
         this._btnGroup.addEventListener("SELECT",this.selectHandler);
         this._btnGroup.x = (GameConfig.GAME_SIZE.x - this._btnGroup.width) / 2 + 30;
         this._btnGroup.y = _loc2_.height - 80;
         _loc2_.addChild(this._btnGroup);
           */

         var _loc3_:Number = _loc2_.y;
         _loc2_.y = GameConfig.GAME_SIZE.y;
         TweenLite.to(_loc2_,0.2,{"y":_loc3_});
      }

      /**
       * 隐藏 SetBtnGroup 默认的黄色箭头，达到“默认无焦点”的产品要求。
       * SetBtnGroup.setBtnData() 中箭头始终作为最后一个 child 加入，因此这里安全移除。
       */
      private function hideArrow() : void
      {
         var idx:int = this._btnGroup.numChildren - 1;
         if(idx < 0)
         {
            return;
         }
         var arrow:DisplayObject = this._btnGroup.getChildAt(idx);
         if(Boolean(arrow))
         {
            arrow.visible = false;
         }
      }

      /**
       * 为按钮补充直接 Touch/Click 事件。TouchEvent.TOUCH_TAP 与 MouseEvent.CLICK 同时绑定，
       * 触屏设备优先收到 TOUCH_TAP，桌面端收到 CLICK；通过 _lastTapTime 防止两者重复触发。
       */
      private function attachBtnListeners() : void
      {
           this.attachBoxListeners();
           return;
         var i:int = 0;
         while(i < this._btnGroup.numChildren)
         {
            var btn:SetBtn = this._btnGroup.getChildAt(i) as SetBtn;
            if(Boolean(btn))
            {
               // 注：本工程 AIR SDK 下 Sprite.touchEnabled 赋值抛 #1056；mouseEnabled（默认 true）
               // + graphics 透明矩形已足以命中触控事件，无需手动打开 touchEnabled。
               btn.mouseEnabled = true;
               btn.addEventListener(TouchEvent.TOUCH_TAP,this.touchHandler);
               btn.addEventListener(MouseEvent.CLICK,this.clickHandler);
            }
            i++;
         }
      }

        private function detachBtnListeners() : void
        {
             this.detachBoxListeners();
             return;
           var i:int = 0;
           while(i < this._btnGroup.numChildren)
           {
              var btn:SetBtn = this._btnGroup.getChildAt(i) as SetBtn;
              if(Boolean(btn))
              {
                 btn.removeEventListener(TouchEvent.TOUCH_TAP,this.touchHandler);
                 btn.removeEventListener(MouseEvent.CLICK,this.clickHandler);
              }
              i++;
           }
        }

        /**
         * 为 _btnBox 中的中文 TextField 按钮绑定单次点击/触摸事件。
         */
        private function attachBoxListeners() : void
        {
           var i:int = 0;
           while(i < this._btnBox.numChildren)
           {
              var btn:Sprite = this._btnBox.getChildAt(i) as Sprite;
              if(Boolean(btn))
              {
                 // 注：本工程 AIR SDK 下 Sprite.touchEnabled 赋值抛 #1056；mouseEnabled（默认 true）
                 // + graphics 透明矩形已足以命中触控事件，无需手动打开 touchEnabled。
                 btn.mouseEnabled = true;
                 btn.addEventListener(TouchEvent.TOUCH_TAP,this.boxTouchHandler);
                 btn.addEventListener(MouseEvent.CLICK,this.boxClickHandler);
              }
              i++;
           }
        }

        private function detachBoxListeners() : void
        {
           var i:int = 0;
           while(i < this._btnBox.numChildren)
           {
              var btn:Sprite = this._btnBox.getChildAt(i) as Sprite;
              if(Boolean(btn))
              {
                 btn.removeEventListener(TouchEvent.TOUCH_TAP,this.boxTouchHandler);
                 btn.removeEventListener(MouseEvent.CLICK,this.boxClickHandler);
              }
              i++;
           }
        }

        private function boxTouchHandler(param1:TouchEvent) : void
        {
           this.tapBox(param1.currentTarget as Sprite);
        }

        private function boxClickHandler(param1:MouseEvent) : void
        {
           this.tapBox(param1.currentTarget as Sprite);
        }

        private function tapBox(param1:Sprite) : void
        {
           if(!param1)
           {
              return;
           }
           var now:int = getTimer();
           // TouchEvent 与 MouseEvent 可能先后到达，同一按钮 600ms 内只触发一次。
           if(this._lastTapBtn == param1 && now - this._lastTapTime < 600)
           {
              return;
           }
           this._lastTapBtn = param1;
           this._lastTapTime = now;
           if(param1.name == "confirm")
           {
              if(this.yesBack != null)
              {
                 this.yesBack();
              }
           }
           else if(param1.name == "cancel")
           {
              if(this.noBack != null)
              {
                 this.noBack();
              }
           }
        }

        /**
         * 创建中文按钮：TextField + 透明热区（最小 48x44）。
         */
        private function createBtn(param1:String, param2:String, param3:Number) : Sprite
        {
           var btn:Sprite = new Sprite();
           btn.name = param2;
           btn.buttonMode = true;
           // 注：本工程 AIR SDK 下 Sprite.touchEnabled 赋值抛 #1056；mouseEnabled（默认 true）
           // + graphics 透明矩形已足以命中触控事件，无需手动打开 touchEnabled。
           btn.mouseEnabled = true;
           btn.graphics.beginFill(0,0);
           btn.graphics.drawRect(0,0,80,44);
           btn.graphics.endFill();
           var tf:TextField = new TextField();
           UIUtils.formatText(tf,{
              "color":16777215,
              "size":20,
              "align":"center"
           });
           tf.width = 80;
           tf.height = 30;
           tf.text = param1;
           tf.mouseEnabled = false;
           tf.x = 0;
           tf.y = 7;
           btn.addChild(tf);
           btn.x = param3;
           return btn;
        }

      private function touchHandler(param1:TouchEvent) : void
      {
         var btn:SetBtn = param1.currentTarget as SetBtn;
         this.tap(btn);
      }

      private function clickHandler(param1:MouseEvent) : void
      {
         var btn:SetBtn = param1.currentTarget as SetBtn;
         this.tap(btn);
      }

      private function tap(param1:SetBtn) : void
      {
         if(!param1)
         {
            return;
         }
         var now:int = getTimer();
         // TouchEvent 与 MouseEvent 可能先后到达，同一按钮 600ms 内只触发一次。
         if(this._lastTapBtn == param1 && now - this._lastTapTime < 600)
         {
            return;
         }
         this._lastTapBtn = param1;
         this._lastTapTime = now;
         param1.select();
      }

      private function selectHandler(param1:SetBtnEvent) : void
      {
         switch(param1.selectedLabel)
         {
            case "CONFIRM":
               if(this.yesBack != null)
               {
                  this.yesBack();
               }
               break;
            case "CANCEL":
               if(this.noBack != null)
               {
                  this.noBack();
               }
         }
      }
   }
}
