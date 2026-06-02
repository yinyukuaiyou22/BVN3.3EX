package net.play5d.game.bvn.ui
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.kyo.display.bitmap.BitmapFontText;
   
   public class SetBtn extends Sprite
   {
      
      public var optionKey:String;
      
      public var onSelect:Function;
      
      public var func:Function;
      
      private var _label:BitmapFontText;
      
      private var _options:Array;
      
      private var _optionIndex:int;
      
      private var _optionTxt:BitmapFontText;
      
      private var _prevArrow:MovieClip;
      
      private var _nextArrow:MovieClip;
      
      private var _line:SetBtnLine;
      
      private var _cn:String;
      
      public function SetBtn(param1:String, param2:String)
      {
         super();
         this.buttonMode = true;
         _label = new BitmapFontText(AssetManager.I.getFont("font1"));
         _label.text = param1;
         _cn = param2;
         _line = new SetBtnLine();
         _line.y = _label.height;
         _line.hide();
         addChild(_line);
         addChild(_label);
      }
      
      public function get label() : String
      {
         return _label.text;
      }
      
      public function destory() : void
      {
         if(_label)
         {
            _label.dispose();
         }
      }
      
      public function hover() : void
      {
         updateLine();
         addChild(_line);
      }
      
      private function updateLine() : void
      {
         var _loc1_:Object = getOption();
         if(_loc1_)
         {
            _line.show(width,_cn + " - " + _loc1_.cn);
         }
         else
         {
            _line.show(width,_cn);
         }
      }
      
      public function hoverOut() : void
      {
         _line.hide();
         try
         {
            removeChild(_line);
         }
         catch(e:Error)
         {
         }
      }
      
      public function select() : void
      {
         var _loc1_:SetBtnEvent = new SetBtnEvent("SELECT");
         _loc1_.selectedLabel = label;
         if(func != null)
         {
            func();
         }
         dispatchEvent(_loc1_);
         SoundCtrl.I.sndConfrim();
      }
      
      public function setOption(param1:Array) : void
      {
         _options = param1;
         _prevArrow = AssetManager.I.createObject("txt_arrow_mc","subswfs/setting.swf") as MovieClip;
         _nextArrow = AssetManager.I.createObject("txt_arrow_mc","subswfs/setting.swf") as MovieClip;
         _prevArrow.name = "prevArrow";
         _nextArrow.name = "nextArrow";
         _nextArrow.scaleX = -1;
         _nextArrow.y = 17;
         _prevArrow.y = 17;
         _optionTxt = new BitmapFontText(AssetManager.I.getFont("font1"));
         addChild(_prevArrow);
         addChild(_nextArrow);
         addChild(_optionTxt);
         updateOption();
      }
      
      public function getOption() : Object
      {
         if(!_options)
         {
            return null;
         }
         return _options[_optionIndex];
      }
      
      public function nextOption() : void
      {
         if(!_options)
         {
            return;
         }
         var _loc1_:int = _optionIndex + 1;
         if(_loc1_ > _options.length - 1)
         {
            _loc1_ = 0;
         }
         changeOption(_loc1_);
         SoundCtrl.I.sndSelect();
      }
      
      public function prevOption() : void
      {
         if(!_options)
         {
            return;
         }
         var _loc1_:int = _optionIndex - 1;
         if(_loc1_ < 0)
         {
            _loc1_ = _options.length - 1;
         }
         changeOption(_loc1_);
         SoundCtrl.I.sndSelect();
      }
      
      public function setOptionByValue(param1:Object) : void
      {
         var _loc3_:int = 0;
         var _loc2_:* = null;
         while(_loc3_ < _options.length)
         {
            _loc2_ = _options[_loc3_];
            if(_loc2_.value == param1)
            {
               changeOption(_loc3_,false);
               return;
            }
            _loc3_++;
         }
      }
      
      private function changeOption(param1:int, param2:Boolean = true) : void
      {
         var _loc4_:SetBtnEvent = null;
         var _loc3_:Object = null;
         _optionIndex = param1;
         updateOption();
         updateLine();
         if(param2)
         {
            _loc4_ = new SetBtnEvent("OPTION_CHANGE");
            _loc3_ = getOption();
            if(_loc3_ != null)
            {
               _loc4_.optionKey = optionKey;
               _loc4_.optionValue = _loc3_.value;
               dispatchEvent(_loc4_);
            }
         }
      }
      
      private function updateOption() : void
      {
         var _loc1_:String = getOption().label;
         _optionTxt.text = _loc1_;
         _prevArrow.x = _label.x + _label.width + 50;
         _optionTxt.x = _prevArrow.x + 10;
         _nextArrow.x = _optionTxt.x + _optionTxt.width + 10;
      }
   }
}

