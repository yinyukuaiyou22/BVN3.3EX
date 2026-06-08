package net.play5d.game.bvn.ui
{
   import com.greensock.*;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TouchEvent;
   import flash.geom.*;
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
      
      public function SetBtnGroup()
      {
         super();
         if(GameConfig.TOUCH_MODE)
         {
            this.scaleX = this.scaleY = 1.1;
         }
      }
      
      public function initScroll(param1:Number, param2:Number) : void
      {
         this._scrollRect = new Rectangle(0,0,param1,param2);
         this.scrollRect = this._scrollRect;
      }
      
      public function initMainSet() : void
      {
         this.initMainBtns();
         this.initArrow();
         GameRender.add(this.render,this);
         GameInputer.focus();
         GameInputer.enabled = true;
      }
      
      public function initKeySet() : void
      {
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
      
      public function setBtnData(param1:Array, param2:int = 0) : void
      {
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
         GameInputer.focus();
         GameInputer.enabled = true;
      }
      
      public function destory() : void
      {
         var _loc1_:* = undefined;
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
      }
      
      private function initMainBtns() : void
      {
         var _loc1_:SetBtn = null;
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         this._btns = new Vector.<SetBtn>();
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
         var _loc5_:ConfigVO = GameData.I.config;
         while(_loc2_ < _loc4_.length)
         {
            _loc3_ = _loc4_[_loc2_];
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
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         if(!this._scrollRect)
         {
            return;
         }
         if(this.direct == 1)
         {
            if(this._btns.length < 8)
            {
               return;
            }
            _loc1_ = this.endY != 0 ? this.endY : Number(this._scrollRect.height);
            _loc2_ = this.height;
            if(_loc2_ < _loc1_)
            {
               return;
            }
            _loc3_ = _loc1_ - this.startY;
            _loc4_ = _loc3_ / this._btns.length;
            _loc5_ = -this._arrowIndex * (_loc4_ - this.gap);
            TweenLite.to(this._scrollRect,0.2,{
               "y":_loc5_,
               "onUpdate":this.updateScroll
            });
         }
      }
      
      private function updateScroll() : void
      {
         this.scrollRect = this._scrollRect;
      }
      
      private function render() : void
      {
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
         if(_loc2_.onSelect != null)
         {
            _loc2_.onSelect();
         }
         dispatchEvent(param1.newEvent());
      }
   }
}

