package net.play5d.game.bvn.ui
{
   import flash.display.Sprite;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.bitmap.*;
   
   public class SetBtn extends Sprite
   {
      
      public var optionKey:String;
      
      public var onSelect:Function;
      
      /**
       * 选项区右边界（由 SetBtnGroup 下发；<=0 表示沿用旧的"按标签宽度顺排"，兼容独立使用）
       */
      public var rightX:Number = 0;
      
      /** 选项值/箭头之间的间距 */
      private static const OPTION_GAP:Number = 10;
      
      private var _label:BitmapFontText;
      
      private var _options:Array;
      
      private var _optionIndex:int;
      
      private var _optionTxt:BitmapFontText;
      
      private var _prevArrow:*;
      
      private var _nextArrow:*;
      
      private var _line:SetBtnLine;
      
      private var _cn:String;
      
      public function SetBtn(param1:String, param2:String)
      {
         super();
         this.buttonMode = true;
         this._label = new BitmapFontText(AssetManager.I.getFont("font1"));
         this._label.text = param1;
         this._cn = param2;
         this._line = new SetBtnLine();
         this._line.y = this._label.height;
         this._line.hide();
         addChild(this._line);
         addChild(this._label);
           // 3.7 重开迁移：保证触控热区最小 48x44（透明图形，不影响视觉）。
           // 注：SetBtn 继承 Sprite（sealed），运行时 touchEnabled 报 #1056；AIR 的触控命中
           // 已由 mouseEnabled（默认 true）+ graphics 透明矩形承担，无需额外打开 touchEnabled。
           this.graphics.beginFill(0,0);
           this.graphics.drawRect(0,0,Math.max(this._label.width,48),Math.max(this._label.height,44));
           this.graphics.endFill();
      }
      
      public function get label() : String
      {
         return this._label.text;
      }
      
      public function destory() : void
      {
         if(Boolean(this._label))
         {
            this._label.dispose();
         }
      }
      
      public function hover() : void
      {
         this.updateLine();
         addChild(this._line);
      }
      
      private function updateLine() : void
      {
         var _loc1_:Object = this.getOption();
         if(Boolean(_loc1_))
         {
            this._line.show(width,this._cn + " - " + _loc1_.cn);
         }
         else
         {
            this._line.show(width,this._cn);
         }
      }
      
      public function hoverOut() : void
      {
         this._line.hide();
         try
         {
            removeChild(this._line);
         }
         catch(e:Error)
         {
         }
      }
      
      public function select() : void
      {
         var _loc1_:SetBtnEvent = new SetBtnEvent("SELECT");
         _loc1_.selectedLabel = this.label;
         dispatchEvent(_loc1_);
         SoundCtrl.I.sndConfrim();
      }
      
      public function setOption(param1:Array) : void
      {
         this._options = param1;
         this._prevArrow = ResUtils.I.createDisplayObject(ResUtils.I.setting,"txt_arrow_mc");
         this._nextArrow = ResUtils.I.createDisplayObject(ResUtils.I.setting,"txt_arrow_mc");
         this._prevArrow.name = "prevArrow";
         this._nextArrow.name = "nextArrow";
         this._nextArrow.scaleX = -1;
         this._prevArrow.y = this._nextArrow.y = 17;
         this._optionTxt = new BitmapFontText(AssetManager.I.getFont("font1"));
         addChild(this._prevArrow);
         addChild(this._nextArrow);
         addChild(this._optionTxt);
         this.updateOption();
      }
      
      public function getOption() : Object
      {
         if(!this._options)
         {
            return null;
         }
         return this._options[this._optionIndex];
      }
      
      public function nextOption() : void
      {
         if(!this._options)
         {
            return;
         }
         var _loc1_:int = this._optionIndex + 1;
         if(_loc1_ > this._options.length - 1)
         {
            _loc1_ = 0;
         }
         this.changeOption(_loc1_);
         SoundCtrl.I.sndSelect();
      }
      
      public function prevOption() : void
      {
         if(!this._options)
         {
            return;
         }
         var _loc1_:int = this._optionIndex - 1;
         if(_loc1_ < 0)
         {
            _loc1_ = this._options.length - 1;
         }
         this.changeOption(_loc1_);
         SoundCtrl.I.sndSelect();
      }
      
      public function setOptionByValue(param1:Object) : void
      {
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         while(_loc2_ < this._options.length)
         {
            _loc3_ = this._options[_loc2_];
            if(_loc3_.value == param1)
            {
               this.changeOption(_loc2_,false);
               return;
            }
            _loc2_++;
         }
      }
      
      private function changeOption(param1:int, param2:Boolean = true) : void
      {
         var _loc3_:SetBtnEvent = null;
         var _loc4_:Object = null;
         this._optionIndex = param1;
         this.updateOption();
         this.updateLine();
         if(param2)
         {
            _loc3_ = new SetBtnEvent("OPTION_CHANGE");
            _loc4_ = this.getOption();
            if(Boolean(_loc4_))
            {
               _loc3_.optionKey = this.optionKey;
               _loc3_.optionValue = _loc4_.value;
               dispatchEvent(_loc3_);
            }
         }
      }
      
      public function setRightX(param1:Number) : void
      {
         this.rightX = param1;
      }
      
      private function updateOption() : void
      {
         var _loc1_:String = this.getOption().label;
         this._optionTxt.text = _loc1_;
         if(this.rightX > 0)
         {
            // 右对齐：右箭头贴右边界，选项值与左箭头依次往左排。
            // 旧实现按 label 宽度顺排且没有右边界，长标签行会越过 800×600 画布被裁掉。
            this._nextArrow.x = this.rightX - this._nextArrow.width;
            this._optionTxt.x = this._nextArrow.x - OPTION_GAP - this._optionTxt.width;
            this._prevArrow.x = this._optionTxt.x - OPTION_GAP - this._prevArrow.width;
            // 极端长标签兜底：右排后若与标签重叠，退回顺排（宁可溢出也不叠字）
            if(this._prevArrow.x < this._label.x + this._label.width + 10)
            {
               this._prevArrow.x = this._label.x + this._label.width + 50;
               this._optionTxt.x = this._prevArrow.x + OPTION_GAP;
               this._nextArrow.x = this._optionTxt.x + this._optionTxt.width + OPTION_GAP;
            }
         }
         else
         {
            this._prevArrow.x = this._label.x + this._label.width + 50;
            this._optionTxt.x = this._prevArrow.x + OPTION_GAP;
            this._nextArrow.x = this._optionTxt.x + this._optionTxt.width + OPTION_GAP;
         }
      }
   }
}

