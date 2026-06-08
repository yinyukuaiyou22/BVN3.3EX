package net.play5d.game.bvn.ui.select
{
   import flash.display.*;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.filters.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.*;
   
   public class SelectedFighterUI extends EventDispatcher
   {
      
      public var ui:Sprite;
      
      public var trueY:Number = 0;
      
      private var _fighterIndex:int = -1;
      
      private var _face:DisplayObject;
      
      private var _fighter:FighterVO;
      
      private var _text:BitmapText;
      
      private var _uiWidth:Number;
      
      public function SelectedFighterUI(param1:Sprite)
      {
         super();
         this.ui = param1;
         param1.mouseChildren = false;
         if(GameUI.SHOW_CN_TEXT)
         {
            this._text = new BitmapText(true,16777215,[new GlowFilter(0,1,3,3,3)]);
            if(param1 is ResUtils.I.getItemClass(ResUtils.I.select,"selected_item_p1_mc"))
            {
               UIUtils.formatText(this._text.textfield,{
                  "color":16777215,
                  "size":14,
                  "align":"right"
               });
               this._text.width = param1.width - 10;
            }
            else
            {
               UIUtils.formatText(this._text.textfield,{
                  "color":16777215,
                  "size":14,
                  "align":"left"
               });
               this._text.x = 10;
               this._text.width = param1.width - 10;
            }
            this._text.y = param1.height - 25;
            param1.addChild(this._text);
         }
      }
      
      public function mouseEnabled(param1:Boolean) : void
      {
         if(param1)
         {
            if(GameConfig.TOUCH_MODE)
            {
               this.ui.addEventListener("touchTap",this.mouseHandler);
            }
            else
            {
               this.ui.buttonMode = true;
               this.ui.addEventListener("mouseOver",this.mouseHandler);
               this.ui.addEventListener("click",this.mouseHandler);
            }
         }
         else
         {
            this.ui.buttonMode = false;
            this.ui.removeEventListener("touchTap",this.mouseHandler);
            this.ui.removeEventListener("mouseOver",this.mouseHandler);
            this.ui.removeEventListener("click",this.mouseHandler);
         }
      }
      
      private function mouseHandler(param1:Event) : void
      {
         dispatchEvent(param1);
      }
      
      public function destory() : void
      {
         if(Boolean(this.ui))
         {
            this.ui.removeEventListener("touchTap",this.mouseHandler);
            this.ui.removeEventListener("mouseOver",this.mouseHandler);
            this.ui.removeEventListener("click",this.mouseHandler);
         }
         if(Boolean(this._text))
         {
            this._text.destory();
            this._text = null;
         }
      }
      
      public function setFighter(param1:FighterVO) : void
      {
         var _loc2_:DisplayObject = null;
         if(!param1)
         {
            return;
         }
         this._fighter = param1;
         if(Boolean(this._text))
         {
            this._text.text = param1.name;
         }
         var _loc3_:* = this.ui.getChildByName("ct");
         var _loc4_:Sprite = _loc3_ ? _loc3_.getChildByName("ct") as Sprite : null;
         if(Boolean(_loc4_))
         {
            if(Boolean(this._face))
            {
               try
               {
                  _loc4_.removeChild(this._face);
               }
               catch(e:Error)
               {
               }
            }
            _loc2_ = AssetManager.I.getFighterFaceBig(param1);
            if(Boolean(_loc2_))
            {
               this._face = _loc2_;
               _loc4_.addChild(_loc2_);
            }
         }
      }
      
      public function getFighter() : FighterVO
      {
         return this._fighter;
      }
      
      public function getFighterIndex() : int
      {
         return this._fighterIndex;
      }
      
      public function setFighterIndex(param1:int) : void
      {
         this._fighterIndex = param1;
         var _loc2_:* = ResUtils.I.createDisplayObject(ResUtils.I.select,"seltwzmc");
         _loc2_.gotoAndStop(param1);
         this.ui.addChild(_loc2_);
         if(this.ui is ResUtils.I.getItemClass(ResUtils.I.select,"selected_item_p1_mc"))
         {
            _loc2_.x = -8;
         }
         else
         {
            _loc2_.x = 252 - _loc2_.width;
         }
         _loc2_.y = -5;
         this.mouseEnabled(false);
      }
      
      public function setAssister() : void
      {
         var _loc1_:* = ResUtils.I.createDisplayObject(ResUtils.I.select,"seltwzmc");
         _loc1_.gotoAndStop(4);
         this.ui.addChild(_loc1_);
         if(this.ui is ResUtils.I.getItemClass(ResUtils.I.select,"selected_item_p1_mc"))
         {
            _loc1_.x = -8;
         }
         else
         {
            _loc1_.x = 176;
         }
         _loc1_.y = -5;
      }
   }
}

