package net.play5d.game.bvn.ui
{
   import com.greensock.TweenLite;
   import com.greensock.easing.Back;
   import flash.display.Sprite;
   import flash.geom.Point;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.MessionModel;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.utils.TouchMoveEvent;
   import net.play5d.game.bvn.utils.TouchUtils;
   import net.play5d.game.bvn.utils.URL;
   import net.play5d.game.bvn.win.utils.UpdateUtils;
   
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
            this.scaleY = 1.3;
            this.scaleX = 1.3;
            TouchUtils.I.listenOneFinger(MainGame.I.stage,touchMoveHandler,false,true);
         }
      }
      
      private function touchMoveHandler(param1:TouchMoveEvent) : void
      {
         var _loc2_:* = NaN;
         var _loc3_:Number = NaN;
         if(param1.type == "EVENT_TOUCH_MOVE")
         {
            this.y += param1.deltaY;
         }
         if(param1.type == "EVENT_TOUCH_END")
         {
            _loc2_ = -1;
            if(param1.endY > param1.startY)
            {
               if(this.y > _startPoint.y)
               {
                  _loc2_ = _startPoint.y;
               }
            }
            if(param1.endY < param1.startY)
            {
               _loc3_ = GameConfig.GAME_SIZE.y - this.height - 10;
               if(this.y < _loc3_)
               {
                  _loc2_ = _loc3_;
               }
            }
            if(_loc2_ != -1)
            {
               TweenLite.to(this,0.2,{"y":_loc2_});
            }
         }
      }
      
      public function destory() : void
      {
         GameRender.remove(render);
         TouchUtils.I.unlistenOneFinger(MainGame.I.stage);
         for each(var _loc1_ in _btns)
         {
            _loc1_.removeEventListener("touchTap",touchHandler);
            _loc1_.removeEventListener("click",mouseHandler);
            _loc1_.removeEventListener("mouseOver",mouseHandler);
            _loc1_.dispose();
         }
         _btns = null;
      }
      
      public function fadIn(param1:Number = 0.5, param2:Number = 0.05) : void
      {
         var _loc3_:int = 0;
         var _loc4_:* = null;
         while(_loc3_ < _btns.length)
         {
            _loc4_ = _btns[_loc3_];
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
         var _loc2_:Object = null;
         _startPoint = new Point(x,y);
         _btnConfig = GameInterface.instance.getGameMenu();
         if(!_btnConfig)
         {
            _btnConfig = GameInterface.getDefaultMenu();
         }
         _loc1_ = 0;
         while(_loc1_ < _btnConfig.length)
         {
            _loc2_ = _btnConfig[_loc1_];
            addMenuBtn(_loc2_);
            _loc1_++;
         }
         setBtns(true,false);
         if(!GameConfig.TOUCH_MODE)
         {
            hoverBtn(_btns[0]);
         }
         if(GameConfig.TOUCH_MODE)
         {
            this.y += 50;
         }
         GameRender.add(render);
      }
      
      private function addMenuBtn(param1:Object, param2:Boolean = false) : MenuBtn
      {
         var _loc5_:int = 0;
         var _loc6_:MenuBtn = null;
         var _loc7_:* = null;
         var _loc4_:MenuBtn = new MenuBtn(param1.txt,param1.cn,param1.func);
         if(GameConfig.TOUCH_MODE)
         {
            _loc4_.addEventListener("touchTap",touchHandler);
         }
         else
         {
            _loc4_.addEventListener("click",mouseHandler);
            _loc4_.addEventListener("mouseOver",mouseHandler);
         }
         if(!param2)
         {
            _loc4_.index = _btns.length;
            _btns.push(_loc4_);
            if(_btnHeight == 0)
            {
               _btnHeight = _loc4_.height;
            }
         }
         var _loc3_:Array = param1.children;
         if(_loc3_ != null)
         {
            _loc4_.children = [];
            _loc5_ = 0;
            while(_loc5_ < _loc3_.length)
            {
               _loc7_ = _loc3_[_loc5_];
               _loc6_ = addMenuBtn(_loc7_,true);
               _loc4_.children.push(_loc6_);
               _loc6_.childMode();
               _loc6_.index = _loc5_;
               _loc5_++;
            }
         }
         return _loc4_;
      }
      
      private function touchEndHandler() : void
      {
         if(!_startPoint || btnLength < 7)
         {
            return;
         }
         var _loc5_:Number = GameConfig.GAME_SIZE.y - 10;
         var _loc6_:Number = _startPoint.y + this.height;
         if(_loc6_ < _loc5_)
         {
            return;
         }
         var _loc4_:Number = _loc5_ - _startPoint.y;
         var _loc1_:Number = _loc4_ / btnLength;
         var _loc2_:Number = _btnHeight + _yadd;
         var _loc3_:Number = _btnIndex * (_loc1_ - _loc2_) + _startPoint.y;
         TweenLite.to(this,0.2,{"y":_loc3_});
      }
      
      protected function mouseHandler(param1:String, param2:MenuBtn) : void
      {
         if(!enabled)
         {
            return;
         }
         switch(param1)
         {
            case "mouseOver":
               hoverBtn(param2);
               break;
            case "click":
               selectBtn(param2);
         }
      }
      
      protected function touchHandler(param1:String, param2:MenuBtn) : void
      {
         if(TouchUtils.I.isDraging())
         {
            return;
         }
         if(param2.children && param2.children.length > 0)
         {
            hoverBtn(param2);
            selectBtn(param2);
            return;
         }
         if(!param2.isHover())
         {
            hoverBtn(param2,false);
         }
         else
         {
            selectBtn(param2);
         }
      }
      
      private function get btnLength() : int
      {
         var _loc1_:int = int(_btns.length);
         if(_showIngChildrenBtn)
         {
            _loc1_ += _showIngChildrenBtn.children.length;
         }
         return _loc1_;
      }
      
      private function moveScroll(param1:Boolean = false) : void
      {
         var _loc9_:int = 0;
         _loc9_ = 7;
         if(!_startPoint || btnLength < 7)
         {
            return;
         }
         var _loc6_:Number = GameConfig.GAME_SIZE.y - 10;
         var _loc7_:Number = _startPoint.y + this.height;
         var _loc12_:Number = GameConfig.GAME_SIZE.x - 20;
         var _loc14_:Number = _startPoint.x + this.width;
         if(_loc7_ < _loc6_ || _loc14_ < _loc12_)
         {
            return;
         }
         var _loc8_:Number = _loc6_ - _startPoint.y;
         var _loc15_:Number = _loc12_ - _startPoint.x;
         var _loc3_:Number = _loc15_ / (btnLength + 1);
         var _loc4_:Number = _loc8_ / (btnLength + 1);
         var _loc13_:Number = _xadd;
         var _loc5_:Number = _btnHeight + _yadd;
         var _loc2_:int = _btnIndex;
         if(_showIngChildrenBtn)
         {
            if(!param1)
            {
               return;
            }
            _loc2_ += _showIngChildrenBtn.index;
         }
         var _loc10_:Number = _loc2_ * -_loc13_ * (_showIngChildrenBtn ? 0.6 : 0.3) + _startPoint.x;
         var _loc11_:Number = _loc2_ * (_loc4_ - _loc5_) + _startPoint.y;
         TweenLite.to(this,0.15,{
            "x":_loc10_,
            "y":_loc11_
         });
      }
      
      private function hoverBtn(param1:MenuBtn, param2:Boolean = true) : void
      {
         var _loc5_:* = undefined;
         var _loc4_:int = 0;
         var _loc6_:* = null;
         var _loc3_:int = 0;
         while(_loc3_ < _btns.length)
         {
            _loc6_ = _btns[_loc3_];
            if(_loc6_ == param1)
            {
               _loc6_.hover();
               _btnIndex = _loc3_;
               if(param2)
               {
                  moveScroll();
               }
            }
            else
            {
               _loc6_.normal();
            }
            _loc3_++;
         }
         if(_showIngChildrenBtn)
         {
            _loc5_ = _showIngChildrenBtn.children;
            _loc4_ = 0;
            while(_loc4_ < _loc5_.length)
            {
               _loc6_ = _loc5_[_loc4_];
               if(_loc6_ == param1)
               {
                  _loc6_.hover();
                  _btnIndex = _loc4_;
                  if(param2)
                  {
                     moveScroll(true);
                  }
               }
               else
               {
                  _loc6_.normal();
               }
               _loc4_++;
            }
         }
      }
      
      protected function selectBtn(param1:MenuBtn) : void
      {
         var func:Function;
         var callFunc:Function;
         var target:MenuBtn = param1;
         if(target.children)
         {
            toogleChildren(target);
            return;
         }
         if(Boolean(target.func))
         {
            func = target.func;
         }
         else
         {
            func = getFucByLabel(target.label);
         }
         callFunc = function():void
         {
            if(func != null)
            {
               func();
            }
            mouseChildren = true;
            mouseEnabled = true;
            enabled = true;
         };
         enabled = false;
         target.select(callFunc);
      }
      
      private function getFucByLabel(param1:String) : Function
      {
         var label:String = param1;
         var func:Function = null;
         switch(label)
         {
            case "TEAM ARCADE":
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
                  GameEvent.dispatchEvent("ENTER_TEAM_STAGE");
               };
               break;
            case "TEAM VS PEOPLE":
               func = function():void
               {
                  GameMode.currentMode = 11;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_TEAM_STAGE");
               };
               break;
            case "TEAM VS CPU":
               func = function():void
               {
                  GameMode.currentMode = 12;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_TEAM_STAGE");
               };
               break;
            case "TEAM WATCH":
               func = function():void
               {
                  GameMode.currentMode = 13;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_TEAM_STAGE");
               };
               break;
            case "SINGLE ARCADE":
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
                  GameEvent.dispatchEvent("ENTER_SINGLE_STAGE");
               };
               break;
            case "SINGLE VS PEOPLE":
               func = function():void
               {
                  GameMode.currentMode = 21;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_SINGLE_STAGE");
               };
               break;
            case "SINGLE VS CPU":
               func = function():void
               {
                  GameMode.currentMode = 22;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_SINGLE_STAGE");
               };
               break;
            case "SINGLE WATCH":
               func = function():void
               {
                  GameMode.currentMode = 23;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_SINGLE_STAGE");
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
            case "MUSOU ARCADE":
               func = function():void
               {
                  GameMode.currentMode = 100;
                  MainGame.I.goWorldMap();
                  GameEvent.dispatchEvent("ENTER_MOSOU_STAGE");
               };
               break;
            case "MUSOU VS PEOPLE":
               func = function():void
               {
                  GameMode.currentMode = 101;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_TEAM_STAGE");
               };
               break;
            case "MUSOU VS CPU":
               func = function():void
               {
                  GameMode.currentMode = 102;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_TEAM_STAGE");
               };
               break;
            case "MUSOU WATCH":
               func = function():void
               {
                  GameMode.currentMode = 103;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_TEAM_STAGE");
               };
               break;
            case "MUSOU TRAINING":
               func = function():void
               {
                  GameMode.currentMode = 104;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_TEAM_STAGE");
               };
               break;
            case "TRAINING":
               func = function():void
               {
                  GameMode.currentMode = 40;
                  MainGame.I.goSelect();
                  GameEvent.dispatchEvent("ENTER_TRAIN_STAGE");
               };
               break;
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
            case "STAFF":
               func = function():void
               {
                  MainGame.I.goStaff();
               };
               break;
            case "UPDATE":
               func = function():void
               {
                  UpdateUtils.I.checkUpdate();
               };
               break;
            case "ISSUES":
               func = function():void
               {
                  URL.feedBack();
               };
         }
         return func;
      }
      
      private function toogleChildren(param1:MenuBtn) : void
      {
         var _loc2_:Boolean = false;
         if(_showIngChildrenBtn)
         {
            _loc2_ = param1 == _showIngChildrenBtn;
            if(!_loc2_)
            {
               _showIngChildrenBtn.normal();
            }
            closeChildren(_loc2_,_loc2_);
            if(_loc2_)
            {
               return;
            }
         }
         _showIngChildrenBtn = param1;
         setBtns(true,true);
         param1.openChild();
         hoverBtn(param1.children[0]);
      }
      
      private function closeChildren(param1:Boolean, param2:Boolean) : void
      {
         var _loc3_:int = 0;
         var _loc5_:* = null;
         var _loc4_:Array = _showIngChildrenBtn.children;
         _loc3_ = 0;
         while(_loc3_ < _loc4_.length)
         {
            _loc5_ = _loc4_[_loc3_];
            try
            {
               removeChild(_loc5_.ui);
            }
            catch(e:Error)
            {
            }
            _loc3_++;
         }
         _showIngChildrenBtn.closeChild();
         _showIngChildrenBtn = null;
         if(param1)
         {
            setBtns(false,param2);
         }
         moveScroll();
      }
      
      private function setBtns(param1:Boolean, param2:Boolean = false) : void
      {
         var _loc6_:int = 0;
         var _loc7_:* = null;
         var _loc4_:int = 0;
         var _loc8_:* = null;
         var _loc5_:* = 0;
         var _loc3_:* = 0;
         while(_loc6_ < _btns.length)
         {
            _loc7_ = _btns[_loc6_];
            if(param2)
            {
               TweenLite.to(_loc7_.ui,0.2,{
                  "x":_loc5_,
                  "y":_loc3_
               });
            }
            else
            {
               _loc7_.ui.x = _loc5_;
               _loc7_.ui.y = _loc3_;
            }
            _loc5_ += _xadd;
            _loc3_ += _loc7_.height + _yadd;
            if(param1)
            {
               addChild(_loc7_.ui);
            }
            if(_showIngChildrenBtn == _loc7_)
            {
               while(_loc4_ < _loc7_.children.length)
               {
                  _loc8_ = _loc7_.children[_loc4_];
                  _loc8_.ui.x = _loc5_;
                  _loc8_.ui.y = _loc3_;
                  if(param2)
                  {
                     _loc8_.ui.scaleX = 0.01;
                     TweenLite.to(_loc8_.ui,0.2,{
                        "scaleX":1,
                        "delay":_loc4_ * 0.04,
                        "ease":Back.easeOut
                     });
                  }
                  if(param1)
                  {
                     addChild(_loc8_.ui);
                  }
                  _loc5_ += _xadd;
                  _loc3_ += _loc8_.height + _yadd;
                  _loc4_++;
               }
            }
            _loc6_++;
         }
      }
      
      private function render() : void
      {
         if(!enabled)
         {
            return;
         }
         if(GameUI.showingDialog())
         {
            return;
         }
         var _loc1_:Array = _showIngChildrenBtn ? _showIngChildrenBtn.children : _btns;
         if(GameInputer.up("MENU",1))
         {
            _btnIndex = _btnIndex - 1;
            if(_btnIndex < 0)
            {
               _btnIndex = _loc1_.length - 1;
            }
            hoverBtn(_loc1_[_btnIndex]);
         }
         if(GameInputer.down("MENU",1))
         {
            _btnIndex = _btnIndex + 1;
            if(_btnIndex > _loc1_.length - 1)
            {
               _btnIndex = 0;
            }
            hoverBtn(_loc1_[_btnIndex]);
         }
         if(GameInputer.attack("MENU",1))
         {
            selectBtn(_loc1_[_btnIndex]);
         }
         if(GameInputer.back(1) || GameInputer.jump("MENU",1))
         {
            if(_showIngChildrenBtn)
            {
               _btnIndex = _showIngChildrenBtn.index;
               closeChildren(true,true);
            }
         }
      }
   }
}

