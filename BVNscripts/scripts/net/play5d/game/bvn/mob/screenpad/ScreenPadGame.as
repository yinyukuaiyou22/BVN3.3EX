package net.play5d.game.bvn.mob.screenpad
{
   import flash.display.*;
   import flash.events.EventDispatcher;
   import flash.events.TouchEvent;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.mob.*;
   import net.play5d.game.bvn.mob.events.*;
   import net.play5d.game.bvn.mob.input.ScreenPadInput;
   import net.play5d.game.bvn.utils.KeyBoarder;
import net.play5d.game.bvn.Debugger;
   
   public class ScreenPadGame extends EventDispatcher
   {
      
      public var inputers:Vector.<ScreenPadInput>;
      
      public var menuInputer:ScreenPadInput;
      
      public var isShowing:Boolean;
      
      private var _arrow:ScreenPadArrow;
      
      private var _stage:Stage;
      
      private var _listened:Boolean;
      
      private var _downCache:Object = {};
      
      private var W:Number;
      
      private var H:Number;
      
      private var _btns:Vector.<ScreenPadBtnBase>;
      
      private var _autoHideSpecial:Boolean;
      
      private var _autoHideSuperSkill:Boolean;
      
      private var _autoHideWankai:Boolean;
      
      private var _editingBtn:ScreenPadBtnBase;
      
      private var _editingBtnDownPos:Point;
      
      private var _editingStageDownPos:Point;
      
      private var _editStageView:Sprite;

      private var _playerSwitchBtn:ScreenPadBtn;

      private var _controllingP1:Boolean = true;

      private var _p1p2WasDown:Boolean = false;

      public function ScreenPadGame(param1:Stage)
      {
         super();
         this._stage = param1;
         this.build();
      }
      
      public function onPause() : void
      {
         this._downCache = {};
      }
      
      public function onResume() : void
      {
      }
      
      public function getBtns() : Vector.<ScreenPadBtnBase>
      {
         return this._btns;
      }
      
      public function reBuild() : void
      {
         var _loc1_:int = 0;
         try
         {
            while(_loc1_ < this._btns.length)
            {
               this._stage.removeChild(this._btns[_loc1_].display);
               this._btns[_loc1_].onRemove();
               _loc1_++;
            }
         }
         catch(e:Error)
         {
         }
         this.build();
      }
      
      private function build() : void
      {
         this.W = launch.FULL_SCREEN_SIZE.x;
         this.H = launch.FULL_SCREEN_SIZE.y;
         this._btns = new Vector.<ScreenPadBtnBase>();
         this._autoHideSuperSkill = GameInterfaceManager.config.screenPadConfig.superSkillAutoHide;
         this._autoHideSpecial = GameInterfaceManager.config.screenPadConfig.specialAutoHide;
         this._autoHideWankai = GameInterfaceManager.config.screenPadConfig.wankaiAutoHide;
         this._arrow = this.addArrow(["up","down","left","right"],ScreenPadAsset.arrow,0.2,0,0,0.2,0.5);
         switch(GameInterfaceManager.config.screenPadConfig.joyMode)
         {
            case 0:
               this.addBtnMode1();
               break;
            case 1:
               this.addBtnMode2();
         }
         var _loc1_:ScreenPadBtn = this.addBtn("back",ScreenPadAsset.pause,0,0,0,0.3,0.5);
         _loc1_.display.x = (this.W - _loc1_.display.width) / 2;
         // P1/P2 切换按钮（右上角）
         this._playerSwitchBtn = this.addBtn("p1p2", ScreenPadAsset.p1, 0, 0.05, 0.3, 0, 0.3);
         this._playerSwitchBtn.display.x = this.W - this._playerSwitchBtn.display.width * 2 - 20;
         this._playerSwitchBtn.display.y = 10 + this._playerSwitchBtn.display.height;
         // 键盘 P 键切换 — 用 KeyBoarder.listen（与游戏输入系统一致）
         KeyBoarder.listen(function(e:*):void {
            if (e.keyCode == 80 && e.type == "keyDown") { _switchPlayer(); }
         });
         var _loc2_:Object = GameInterfaceManager.config.screenPadConfig.joySet;
         if(Boolean(_loc2_))
         {
            this.setBtnByConfig(_loc2_);
         }
         this.initBtns();
      }
      
      private function setBtnByConfig(param1:Object) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:Object = null;
         for each(_loc3_ in this._btns)
         {
            _loc2_ = param1[_loc3_.keyId];
            if(Boolean(_loc2_))
            {
               if(_loc2_.scale != undefined)
               {
                  _loc3_.setScale(_loc2_.scale);
               }
               if(_loc2_.x != undefined)
               {
                  _loc3_.display.x = _loc2_.x;
               }
               if(_loc2_.y != undefined)
               {
                  _loc3_.display.y = _loc2_.y;
               }
            }
         }
      }
      
      private function addBtnMode1() : void
      {
         this.addBtn("jump",ScreenPadAsset.jump,0,0,0.1,0.1);
         this.addBtn("attack",ScreenPadAsset.attack,0,0,1.8,0.15,0.2);
         this.addBtn("skill",ScreenPadAsset.skill,0,0,1.3,1.4,0.2);
         this.addBtn("dash",ScreenPadAsset.dash,0,0,0.1,1.8,0.2);
         this.addBtn("superSkill",ScreenPadAsset.spskill,0,0,0.2,3.5,0.5);
         this.addBtn("special",ScreenPadAsset.special,0.2,0,0,3.2,0.5);
         this.addBtn("wankai",ScreenPadAsset.wanjie,0.2,0.5,0,0,0.5);
      }
      
      private function addBtnMode2() : void
      {
         this.addBtn("attack",ScreenPadAsset.attack,0,0,2.1,1,0.1);
         this.addBtn("jump",ScreenPadAsset.jump2,0,0,1.1,0.1,0.1);
         this.addBtn("dash",ScreenPadAsset.dash,0,0,0.1,1,0.1);
         this.addBtn("skill",ScreenPadAsset.skill,0,0,1.1,1.9,0.1);
         this.addBtn("superSkill",ScreenPadAsset.spskill,0,0,0.2,3.5,0.3);
         this.addBtn("special",ScreenPadAsset.special,0,0,2.3,3.5,0.3);
         this.addBtn("wankai",ScreenPadAsset.wanjie,0.1,0,0,3.5,0.3);
      }
      
      private function addArrow(param1:Array, param2:Class, param3:Number = 0, param4:Number = 0, param5:Number = 0, param6:Number = 0, param7:Number = 0) : ScreenPadArrow
      {
         var _loc8_:ScreenPadArrow = ScreenPadUtils.getArrow(param2);
         _loc8_.moveAble = true;
         _loc8_.keyId = "arrow";
         _loc8_.setKeyIds(param1[0],param1[1],param1[2],param1[3]);
         _loc8_.areaAdd = ScreenPadUtils.cm2pixel(param7);
         if(param3 != 0)
         {
            _loc8_.display.x = ScreenPadUtils.cm2pixel(param3);
         }
         if(param4 != 0)
         {
            _loc8_.display.y = ScreenPadUtils.cm2pixel(param4);
         }
         if(param5 != 0)
         {
            _loc8_.display.x = this.W - _loc8_.display.width - ScreenPadUtils.cm2pixel(param5);
         }
         if(param6 != 0)
         {
            _loc8_.display.y = this.H - _loc8_.display.height - ScreenPadUtils.cm2pixel(param6);
         }
         this._btns.push(_loc8_);
         return _loc8_;
      }
      
      private function addBtn(param1:String, param2:Class, param3:Number = 0, param4:Number = 0, param5:Number = 0, param6:Number = 0, param7:Number = 0, param8:Point = null) : ScreenPadBtn
      {
         var _loc9_:ScreenPadBtn = ScreenPadUtils.getButton(param2,param8);
         _loc9_.moveAble = true;
         _loc9_.keyId = param1;
         _loc9_.areaAdd = ScreenPadUtils.cm2pixel(param7);
         if(param3 != 0)
         {
            _loc9_.display.x = ScreenPadUtils.cm2pixel(param3);
         }
         if(param4 != 0)
         {
            _loc9_.display.y = ScreenPadUtils.cm2pixel(param4);
         }
         if(param5 != 0)
         {
            _loc9_.display.x = this.W - _loc9_.display.width - ScreenPadUtils.cm2pixel(param5);
         }
         if(param6 != 0)
         {
            _loc9_.display.y = this.H - _loc9_.display.height - ScreenPadUtils.cm2pixel(param6);
         }
         this._btns.push(_loc9_);
         return _loc9_;
      }
      
      private function initBtns() : void
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in this._btns)
         {
            _loc1_.initArea();
         }
      }
      
      private function getBtnArea(param1:Bitmap) : Rectangle
      {
         var _loc2_:Rectangle = new Rectangle();
         _loc2_.x = param1.x;
         _loc2_.y = param1.y;
         _loc2_.width = param1.width;
         _loc2_.height = param1.height;
         return _loc2_;
      }
      
      public function show() : void
      {
         var _loc1_:int = 0;
         this.isShowing = true;
         while(_loc1_ < this._btns.length)
         {
            this._stage.addChild(this._btns[_loc1_].display);
            this._btns[_loc1_].onAdd();
            _loc1_++;
         }
      }
      
      public function hide() : void
      {
         var _loc2_:* = undefined;
         var _loc1_:int = 0;
         this.isShowing = false;
         try
         {
            while(_loc1_ < this._btns.length)
            {
               this._stage.removeChild(this._btns[_loc1_].display);
               this._btns[_loc1_].onRemove();
               _loc1_++;
            }
         }
         catch(e:Error)
         {
         }
         for each(_loc2_ in this.inputers)
         {
            _loc2_.clear();
         }
      }
      
      public function render() : void
      {
         var _loc1_:FighterMain = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
         if(!_loc1_)
         {
            return;
         }
         try
         {
            if(this._autoHideSuperSkill)
            {
               this.setBtnVisible("superSkill",_loc1_.qi >= 100);
            }
            if(this._autoHideSpecial)
            {
               this.setBtnVisible("special",this.specialEnabled(_loc1_));
            }
            if(this._autoHideWankai)
            {
               this.setBtnVisible("wankai",_loc1_.qi >= 300 && _loc1_.hasWankai());
            }
         }
         catch(e:Error)
         {
            Debugger.log("ScreenPadGame.render",e);
         }
         this.renderTouch();
      }
      
      private function specialEnabled(param1:FighterMain) : Boolean
      {
         if(param1.actionState == 21)
         {
            return param1.qi >= 100 && param1.hasEnergy(50);
         }
         return param1.fzqi == 100;
      }
      
      private function setBtnVisible(param1:String, param2:Boolean) : void
      {
         var _loc3_:int = 0;
         while(_loc3_ < this._btns.length)
         {
            if(this._btns[_loc3_].keyId == param1)
            {
               this._btns[_loc3_].setVisible(param2);
               return;
            }
            _loc3_++;
         }
      }
      
      public function touchHandler(param1:TouchEvent) : void
      {
         var _loc2_:int = param1.touchPointID;
         var _loc3_:Number = param1.stageX;
         var _loc4_:Number = param1.stageY;
         switch(param1.type)
         {
            case "touchBegin":
            case "touchMove":
               this._downCache[_loc2_] = {
                  "x":_loc3_,
                  "y":_loc4_
               };
               break;
            case "touchEnd":
               delete this._downCache[_loc2_];
         }
      }
      
      private function renderTouch() : void
      {
         var _loc7_:* = undefined;
         var _loc1_:int = 0;
         var _loc2_:ScreenPadBtnBase = null;
         var _loc3_:Boolean = false;
         var _loc4_:Object = null;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         while(_loc1_ < this._btns.length)
         {
            _loc2_ = this._btns[_loc1_];
            _loc3_ = false;
            _loc2_.touchUP();
            this.setInputerDown(_loc2_.keyId,false);
            for(_loc7_ in this._downCache)
            {
               _loc4_ = this._downCache[_loc7_];
               _loc5_ = Number(_loc4_.x);
               _loc6_ = Number(_loc4_.y);
               if(_loc2_.checkArea(_loc5_,_loc6_))
               {
                  _loc3_ = true;
                  _loc2_.touchDown(_loc5_,_loc6_);
                  if(_loc2_ == this._arrow)
                  {
                     this._arrow.touchMove(_loc5_,_loc6_);
                  }
               }
            }
            if(_loc2_ == this._arrow)
            {
               if(_loc3_)
               {
                  this.setInputerDown(this._arrow.keyId,true);
                  this.setInputerDown(this._arrow.getNotDownKeyIds(),false);
               }
               else
               {
                  this._arrow.clearKey();
                  this.setInputerDown(this._arrow.getAllKeyIds(),false);
               }
            }
            else
            {
               this.setInputerDown(_loc2_.keyId,_loc3_);
            }
            _loc1_++;
         }
      }
      
      private function setInputerDown(param1:Object, param2:Boolean) : void
      {
         var _loc3_:ScreenPadInput = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Array = null;
         var _loc7_:String = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         if(param1 == null)
         {
            return;
         }
         // P1/P2 切换按钮：仅 touchUp 瞬间触发（从 true→false 变化时）
         if (param1 == "p1p2") {
            if (param2) {
               _p1p2WasDown = true;
            } else if (_p1p2WasDown) {
               _p1p2WasDown = false;
               this._switchPlayer();
            }
            return;
         }
         if(Boolean(this.menuInputer))
         {
            switch(param1)
            {
               case "attack":
               case "jump":
                  this.menuInputer.setDown("select",param2);
                  break;
               case "back":
                  this.menuInputer.setDown("back",param2);
            }
         }
         _loc9_ = int(this.inputers.length);
         _loc5_ = 0;
         while(_loc5_ < _loc9_)
         {
            _loc3_ = this.inputers[_loc5_];
            if(param1 is String)
            {
               _loc3_.setDown(param1 as String,param2);
            }
            if(param1 is Array)
            {
               _loc6_ = param1 as Array;
               _loc8_ = int(_loc6_.length);
               _loc4_ = 0;
               while(_loc4_ < _loc8_)
               {
                  _loc7_ = _loc6_[_loc4_];
                  _loc3_.setDown(_loc7_,param2);
                  _loc4_++;
               }
            }
            _loc5_++;
         }
      }
      
      public function getEditingBtn() : ScreenPadBtnBase
      {
         return this._editingBtn;
      }
      
      public function showEditMode() : void
      {
         var _loc2_:* = undefined;
         var _loc1_:int = 0;
         this.isShowing = true;
         while(_loc1_ < this._btns.length)
         {
            this._stage.addChild(this._btns[_loc1_].display);
            _loc1_++;
         }
         for each(_loc2_ in this._btns)
         {
            _loc2_.display.alpha = 1;
         }
         launch.STAGE.addEventListener("touchBegin",this.btnTouchEditHandler);
         launch.STAGE.addEventListener("touchMove",this.btnTouchEditHandler);
         launch.STAGE.addEventListener("touchEnd",this.btnTouchEditHandler);
         this._editStageView = new Sprite();
         this._editStageView.mouseChildren = this._editStageView.mouseChildren = false;
         launch.STAGE.addChild(this._editStageView);
      }
      
      public function getBtnPosData() : Object
      {
         var _loc2_:* = undefined;
         var _loc1_:Object = {};
         for each(_loc2_ in this._btns)
         {
            _loc1_[_loc2_.keyId] = _loc2_.getPosData();
         }
         return _loc1_;
      }
      
      public function destory() : void
      {
         var _loc1_:* = undefined;
         this.isShowing = false;
         launch.STAGE.removeEventListener("touchBegin",this.btnTouchEditHandler);
         launch.STAGE.removeEventListener("touchMove",this.btnTouchEditHandler);
         launch.STAGE.removeEventListener("touchEnd",this.btnTouchEditHandler);
         if(Boolean(this._editStageView))
         {
            try
            {
               this._editStageView.parent.removeChild(this._editStageView);
            }
            catch(e:Error)
            {
               Debugger.log(e);
            }
            this._editStageView = null;
         }
         if(Boolean(this._btns))
         {
            for each(_loc1_ in this._btns)
            {
               try
               {
                  _loc1_.display.removeEventListener("touchBegin",this.btnTouchEditHandler);
                  _loc1_.display.parent.removeChild(_loc1_.display);
                  _loc1_.onRemove();
                  _loc1_.display.bitmapData.dispose();
               }
               catch(e:Error)
               {
                  Debugger.log(e);
               }
            }
            this._btns = null;
         }
      }
      
      private function btnTouchEditHandler(param1:TouchEvent) : void
      {
         var _loc2_:* = undefined;
         switch(param1.type)
         {
            case "touchBegin":
               for each(_loc2_ in this._btns)
               {
                  if(Boolean(_loc2_.checkArea(param1.stageX,param1.stageY)))
                  {
                     this._editingBtn = _loc2_;
                     this._editingBtnDownPos = new Point(_loc2_.display.x,_loc2_.display.y);
                     this._editingStageDownPos = new Point(param1.stageX,param1.stageY);
                     this.updateEditRect();
                     return;
                  }
               }
               break;
            case "touchEnd":
               if(Boolean(this._editingBtn))
               {
                  this._editingBtn.initArea();
                  this._editingBtnDownPos = null;
                  this._editingStageDownPos = null;
                  this.updateEditRect();
                  dispatchEvent(new ScreenPadEvent("ScreenPadEvent_CUSTOM_SELECT",this._editingBtn));
               }
               break;
            case "touchMove":
               if(Boolean(this._editingBtn) && Boolean(this._editingBtnDownPos) && Boolean(this._editingStageDownPos))
               {
                  this._editingBtn.display.x = this._editingBtnDownPos.x + (param1.stageX - this._editingStageDownPos.x);
                  this._editingBtn.display.y = this._editingBtnDownPos.y + (param1.stageY - this._editingStageDownPos.y);
                  this.updateEditRect();
                  dispatchEvent(new ScreenPadEvent("ScreenPadEvent_CUSTOM_MOVING",this._editingBtn));
               }
         }
      }
      
      private function updateEditRect() : void
      {
         if(!this._editStageView)
         {
            return;
         }
         this._editStageView.graphics.clear();
         if(Boolean(this._editingBtn))
         {
            this._editStageView.graphics.lineStyle(2,65535,1);
            this._editStageView.graphics.drawRect(this._editingBtn.display.x,this._editingBtn.display.y,this._editingBtn.display.width,this._editingBtn.display.height);
            this._editStageView.graphics.endFill();
         }
      }

      private function _switchPlayer() : void
      {
         if (GameMode.currentMode != 40 && !GameMode.isVsPeople()) {
            return;
         }
         _controllingP1 = !_controllingP1;
         GameCtrl.I.switchControlPlayer(_controllingP1);
         if (_playerSwitchBtn) {
            if (_controllingP1) {
               _playerSwitchBtn.display.bitmapData = (new ScreenPadAsset.p1() as Bitmap).bitmapData;
            } else {
               _playerSwitchBtn.display.bitmapData = (new ScreenPadAsset.p2() as Bitmap).bitmapData;
            }
         }
      }
   }
}

