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
      
      protected var _xadd:Number = -40;
      
      protected var _yadd:Number = 5;
      
      private var _btnIndex:int;
      
      private var _startPoint:Point;
      
      private var _btnHeight:Number = 0;
      
      private var _btns:Array = [];
      
      private var _showIngChildrenBtn:MenuBtn;
      
      public function MenuBtnGroup()
      {
         super();
         if(GameConfig.TOUCH_MODE)
         {
            this.scaleX = this.scaleY = 1.1;
         }
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
      
      public function fadIn(param1:Number = 0.5, param2:Number = 0.05) : void
      {
         var _loc3_:int = 0;
         var _loc4_:* = null;
         while(_loc3_ < this._btns.length)
         {
            _loc4_ = this._btns[_loc3_];
            _loc4_.ui.scaleX = 0.01;
            TweenLite.to(_loc4_.ui,param1,{
               "scaleX":1,
               "delay":_loc3_ * param2,
               "ease":Back.easeOut
            });
            _loc3_++;
         }
      }
      
      public function build() : void
      {
         var _loc1_:int = 0;
         var _loc2_:* = null;
         this.y -= 40;
         this._startPoint = new Point(x,y);
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
         this.setBtns(true,false);
         if(!GameConfig.TOUCH_MODE)
         {
            this.hoverBtn(this._btns[0]);
         }
         if(GameConfig.TOUCH_MODE)
         {
            this.y += 30;
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
            if(this._btnHeight == 0)
            {
               this._btnHeight = _loc7_.height;
            }
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
         if(!this._startPoint)
         {
            return;
         }
         var _loc1_:int = int(this._btns.length);
         if(Boolean(this._showIngChildrenBtn))
         {
            _loc1_ += this._showIngChildrenBtn.children.length;
         }
         if(_loc1_ < 5)
         {
            return;
         }
         var _loc2_:Number = Number(GameConfig.GAME_SIZE.y);
         var _loc3_:Number = this._startPoint.y + this.height;
         if(_loc3_ < _loc2_)
         {
            return;
         }
         var _loc4_:Number = _loc2_ - this._startPoint.y;
         var _loc5_:Number = _loc4_ / _loc1_;
         var _loc6_:Number = this._btnHeight + this._yadd;
         var _loc7_:int = int(this._btnIndex);
         if(Boolean(this._showIngChildrenBtn))
         {
            if(this._btnIndex < this._showIngChildrenBtn.children.length && Boolean(this._showIngChildrenBtn.children[this._btnIndex].isHover()))
            {
               _loc7_ = this._showIngChildrenBtn.index + 1 + this._btnIndex;
            }
            else if(this._btnIndex > this._showIngChildrenBtn.index)
            {
               _loc7_ = this._btnIndex + this._showIngChildrenBtn.children.length;
            }
         }
         var _loc8_:Number = _loc7_ * (_loc5_ - _loc6_) + this._startPoint.y;
         TweenLite.to(this,0.2,{"y":_loc8_});
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
               this.moveScroll();
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
         this.setBtns(true,true);
         param1.openChild();
         this.hoverBtn(param1.children[0]);
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
         if(param1)
         {
            this.setBtns(false,param2);
         }
      }
      
      private function setBtns(param1:Boolean, param2:Boolean = false) : void
      {
         var _loc3_:int = 0;
         var _loc4_:* = null;
         var _loc5_:int = 0;
         var _loc6_:* = null;
         var _loc7_:* = 0;
         var _loc8_:* = 0;
         while(_loc3_ < this._btns.length)
         {
            _loc4_ = this._btns[_loc3_];
            if(param2)
            {
               TweenLite.to(_loc4_.ui,0.2,{
                  "x":_loc7_,
                  "y":_loc8_
               });
            }
            else
            {
               _loc4_.ui.x = _loc7_;
               _loc4_.ui.y = _loc8_;
            }
            _loc7_ += this._xadd;
            _loc8_ += _loc4_.height + this._yadd;
            if(param1)
            {
               addChild(_loc4_.ui);
            }
            if(this._showIngChildrenBtn == _loc4_)
            {
               while(_loc5_ < _loc4_.children.length)
               {
                  _loc6_ = _loc4_.children[_loc5_];
                  _loc6_.ui.x = _loc7_;
                  _loc6_.ui.y = _loc8_;
                  if(param2)
                  {
                     _loc6_.ui.scaleX = 0.01;
                     TweenLite.to(_loc6_.ui,0.2,{
                        "scaleX":1,
                        "delay":_loc5_ * 0.04,
                        "ease":Back.easeOut
                     });
                  }
                  if(param1)
                  {
                     addChild(_loc6_.ui);
                  }
                  _loc7_ += this._xadd;
                  _loc8_ += _loc6_.height + this._yadd;
                  _loc5_++;
               }
            }
            _loc3_++;
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

