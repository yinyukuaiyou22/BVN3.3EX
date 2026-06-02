package net.play5d.game.bvn.mob.screenpad
{
   import flash.display.Bitmap;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.EventDispatcher;
   import flash.events.TouchEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.mob.GameInterfaceManager;
   import net.play5d.game.bvn.mob.events.ScreenPadEvent;
   import net.play5d.game.bvn.mob.input.ScreenPadInput;
   
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
      
      public function ScreenPadGame(param1:Stage)
      {
         super();
         _stage = param1;
         build();
      }
      
      public function onPause() : void
      {
         _downCache = {};
      }
      
      public function onResume() : void
      {
      }
      
      public function getBtns() : Vector.<ScreenPadBtnBase>
      {
         return _btns;
      }
      
      public function reBuild() : void
      {
         var _loc1_:int = 0;
         try
         {
            while(_loc1_ < _btns.length)
            {
               _stage.removeChild(_btns[_loc1_].display);
               _btns[_loc1_].onRemove();
               _loc1_++;
            }
         }
         catch(e:Error)
         {
         }
         build();
      }
      
      private function build() : void
      {
         W = launch.FULL_SCREEN_SIZE.x;
         H = launch.FULL_SCREEN_SIZE.y;
         _btns = new Vector.<ScreenPadBtnBase>();
         _autoHideSuperSkill = GameInterfaceManager.config.screenPadConfig.superSkillAutoHide;
         _autoHideSpecial = GameInterfaceManager.config.screenPadConfig.specialAutoHide;
         _autoHideWankai = GameInterfaceManager.config.screenPadConfig.wankaiAutoHide;
         _arrow = addArrow(["up","down","left","right"],ScreenPadAsset.arrow,0.2,0,0,0.2,0.5);
         switch(GameInterfaceManager.config.screenPadConfig.joyMode)
         {
            case 0:
               addBtnMode1();
               break;
            case 1:
               addBtnMode2();
         }
         var _loc1_:ScreenPadBtn = addBtn("back",ScreenPadAsset.pause,0,0,0,0.3,0.5);
         _loc1_.display.x = (W - _loc1_.display.width) / 2;
         var _loc2_:Object = GameInterfaceManager.config.screenPadConfig.joySet;
         if(_loc2_)
         {
            setBtnByConfig(_loc2_);
         }
         initBtns();
      }
      
      private function setBtnByConfig(param1:Object) : void
      {
         var _loc2_:Object = null;
         for each(var _loc3_ in _btns)
         {
            _loc2_ = param1[_loc3_.keyId];
            if(_loc2_)
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
         addBtn("jump",ScreenPadAsset.jump,0,0,0.1,0.1);
         addBtn("attack",ScreenPadAsset.attack,0,0,1.8,0.15,0.2);
         addBtn("skill",ScreenPadAsset.skill,0,0,1.3,1.4,0.2);
         addBtn("dash",ScreenPadAsset.dash,0,0,0.1,1.8,0.2);
         addBtn("superSkill",ScreenPadAsset.spskill,0,0,0.2,3.5,0.5);
         addBtn("special",ScreenPadAsset.special,0.2,0,0,3.2,0.5);
         addBtn("wankai",ScreenPadAsset.wanjie,0.2,0.5,0,0,0.5);
      }
      
      private function addBtnMode2() : void
      {
         addBtn("attack",ScreenPadAsset.attack,0,0,2.1,1,0.1);
         addBtn("jump",ScreenPadAsset.jump2,0,0,1.1,0.1,0.1);
         addBtn("dash",ScreenPadAsset.dash,0,0,0.1,1,0.1);
         addBtn("skill",ScreenPadAsset.skill,0,0,1.1,1.9,0.1);
         addBtn("superSkill",ScreenPadAsset.spskill,0,0,0.2,3.5,0.3);
         addBtn("special",ScreenPadAsset.special,0,0,2.3,3.5,0.3);
         addBtn("wankai",ScreenPadAsset.wanjie,0.1,0,0,3.5,0.3);
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
            _loc8_.display.x = W - _loc8_.display.width - ScreenPadUtils.cm2pixel(param5);
         }
         if(param6 != 0)
         {
            _loc8_.display.y = H - _loc8_.display.height - ScreenPadUtils.cm2pixel(param6);
         }
         _btns.push(_loc8_);
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
            _loc9_.display.x = W - _loc9_.display.width - ScreenPadUtils.cm2pixel(param5);
         }
         if(param6 != 0)
         {
            _loc9_.display.y = H - _loc9_.display.height - ScreenPadUtils.cm2pixel(param6);
         }
         _btns.push(_loc9_);
         return _loc9_;
      }
      
      private function initBtns() : void
      {
         for each(var _loc1_ in _btns)
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
         isShowing = true;
         while(_loc1_ < _btns.length)
         {
            _stage.addChild(_btns[_loc1_].display);
            _btns[_loc1_].onAdd();
            _loc1_++;
         }
      }
      
      public function hide() : void
      {
         var _loc2_:int = 0;
         isShowing = false;
         try
         {
            while(_loc2_ < _btns.length)
            {
               _stage.removeChild(_btns[_loc2_].display);
               _btns[_loc2_].onRemove();
               _loc2_++;
            }
         }
         catch(e:Error)
         {
         }
         for each(var _loc1_ in inputers)
         {
            _loc1_.clear();
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
            if(_autoHideSuperSkill)
            {
               setBtnVisible("superSkill",_loc1_.qi >= 100);
            }
            if(_autoHideSpecial)
            {
               setBtnVisible("special",specialEnabled(_loc1_));
            }
            if(_autoHideWankai)
            {
               setBtnVisible("wankai",_loc1_.qi >= 300 && _loc1_.hasWankai());
            }
         }
         catch(e:Error)
         {
            trace("ScreenPadGame.render",e);
         }
         renderTouch();
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
         while(_loc3_ < _btns.length)
         {
            if(_btns[_loc3_].keyId == param1)
            {
               _btns[_loc3_].setVisible(param2);
               return;
            }
            _loc3_++;
         }
      }
      
      public function touchHandler(param1:TouchEvent) : void
      {
         var _loc2_:int = param1.touchPointID;
         var _loc4_:Number = param1.stageX;
         var _loc3_:Number = param1.stageY;
         switch(param1.type)
         {
            case "touchBegin":
            case "touchMove":
               _downCache[_loc2_] = {
                  "x":_loc4_,
                  "y":_loc3_
               };
               break;
            case "touchEnd":
               delete _downCache[_loc2_];
         }
      }
      
      private function renderTouch() : void
      {
         var _loc7_:int = 0;
         var _loc2_:ScreenPadBtnBase = null;
         var _loc1_:Boolean = false;
         var _loc3_:Object = null;
         var _loc5_:Number = NaN;
         var _loc4_:Number = NaN;
         while(_loc7_ < _btns.length)
         {
            _loc2_ = _btns[_loc7_];
            _loc1_ = false;
            _loc2_.touchUP();
            setInputerDown(_loc2_.keyId,false);
            for(var _loc6_ in _downCache)
            {
               _loc3_ = _downCache[_loc6_];
               _loc5_ = Number(_loc3_.x);
               _loc4_ = Number(_loc3_.y);
               if(_loc2_.checkArea(_loc5_,_loc4_))
               {
                  _loc1_ = true;
                  _loc2_.touchDown(_loc5_,_loc4_);
                  if(_loc2_ == _arrow)
                  {
                     _arrow.touchMove(_loc5_,_loc4_);
                  }
               }
            }
            if(_loc2_ == _arrow)
            {
               if(_loc1_)
               {
                  setInputerDown(_arrow.keyId,true);
                  setInputerDown(_arrow.getNotDownKeyIds(),false);
               }
               else
               {
                  _arrow.clearKey();
                  setInputerDown(_arrow.getAllKeyIds(),false);
               }
            }
            else
            {
               setInputerDown(_loc2_.keyId,_loc1_);
            }
            _loc7_++;
         }
      }
      
      private function setInputerDown(param1:Object, param2:Boolean) : void
      {
         var _loc3_:ScreenPadInput = null;
         var _loc6_:int = 0;
         var _loc9_:int = 0;
         var _loc4_:Array = null;
         var _loc8_:String = null;
         var _loc7_:int = 0;
         var _loc5_:int = 0;
         if(param1 == null)
         {
            return;
         }
         if(menuInputer)
         {
            switch(param1)
            {
               case "attack":
               case "jump":
                  menuInputer.setDown("select",param2);
                  break;
               case "back":
                  menuInputer.setDown("back",param2);
            }
         }
         _loc5_ = int(inputers.length);
         _loc9_ = 0;
         while(_loc9_ < _loc5_)
         {
            _loc3_ = inputers[_loc9_];
            if(param1 is String)
            {
               _loc3_.setDown(param1 as String,param2);
            }
            if(param1 is Array)
            {
               _loc4_ = param1 as Array;
               _loc7_ = int(_loc4_.length);
               _loc6_ = 0;
               while(_loc6_ < _loc7_)
               {
                  _loc8_ = _loc4_[_loc6_];
                  _loc3_.setDown(_loc8_,param2);
                  _loc6_++;
               }
            }
            _loc9_++;
         }
      }
      
      public function getEditingBtn() : ScreenPadBtnBase
      {
         return _editingBtn;
      }
      
      public function showEditMode() : void
      {
         var _loc2_:int = 0;
         isShowing = true;
         while(_loc2_ < _btns.length)
         {
            _stage.addChild(_btns[_loc2_].display);
            _loc2_++;
         }
         for each(var _loc1_ in _btns)
         {
            _loc1_.display.alpha = 1;
         }
         launch.STAGE.addEventListener("touchBegin",btnTouchEditHandler);
         launch.STAGE.addEventListener("touchMove",btnTouchEditHandler);
         launch.STAGE.addEventListener("touchEnd",btnTouchEditHandler);
         _editStageView = new Sprite();
         _editStageView.mouseChildren = _editStageView.mouseChildren = false;
         launch.STAGE.addChild(_editStageView);
      }
      
      public function getBtnPosData() : Object
      {
         var _loc1_:Object = {};
         for each(var _loc2_ in _btns)
         {
            _loc1_[_loc2_.keyId] = _loc2_.getPosData();
         }
         return _loc1_;
      }
      
      public function destory() : void
      {
         isShowing = false;
         launch.STAGE.removeEventListener("touchBegin",btnTouchEditHandler);
         launch.STAGE.removeEventListener("touchMove",btnTouchEditHandler);
         launch.STAGE.removeEventListener("touchEnd",btnTouchEditHandler);
         if(_editStageView)
         {
            try
            {
               _editStageView.parent.removeChild(_editStageView);
            }
            catch(e:Error)
            {
               trace(e);
            }
            _editStageView = null;
         }
         if(_btns)
         {
            for each(var _loc1_ in _btns)
            {
               try
               {
                  _loc1_.display.removeEventListener("touchBegin",btnTouchEditHandler);
                  _loc1_.display.parent.removeChild(_loc1_.display);
                  _loc1_.onRemove();
                  _loc1_.display.bitmapData.dispose();
               }
               catch(e:Error)
               {
                  trace(e);
               }
            }
            _btns = null;
         }
      }
      
      private function btnTouchEditHandler(param1:TouchEvent) : void
      {
         switch(param1.type)
         {
            case "touchBegin":
               for each(var _loc2_ in _btns)
               {
                  if(_loc2_.checkArea(param1.stageX,param1.stageY))
                  {
                     _editingBtn = _loc2_;
                     _editingBtnDownPos = new Point(_loc2_.display.x,_loc2_.display.y);
                     _editingStageDownPos = new Point(param1.stageX,param1.stageY);
                     updateEditRect();
                     return;
                  }
               }
               break;
            case "touchEnd":
               if(_editingBtn)
               {
                  _editingBtn.initArea();
                  _editingBtnDownPos = null;
                  _editingStageDownPos = null;
                  updateEditRect();
                  dispatchEvent(new ScreenPadEvent("ScreenPadEvent_CUSTOM_SELECT",_editingBtn));
               }
               break;
            case "touchMove":
               if(_editingBtn && _editingBtnDownPos && _editingStageDownPos)
               {
                  _editingBtn.display.x = _editingBtnDownPos.x + (param1.stageX - _editingStageDownPos.x);
                  _editingBtn.display.y = _editingBtnDownPos.y + (param1.stageY - _editingStageDownPos.y);
                  updateEditRect();
                  dispatchEvent(new ScreenPadEvent("ScreenPadEvent_CUSTOM_MOVING",_editingBtn));
               }
         }
      }
      
      private function updateEditRect() : void
      {
         if(!_editStageView)
         {
            return;
         }
         _editStageView.graphics.clear();
         if(_editingBtn)
         {
            _editStageView.graphics.lineStyle(2,65535,1);
            _editStageView.graphics.drawRect(_editingBtn.display.x,_editingBtn.display.y,_editingBtn.display.width,_editingBtn.display.height);
            _editStageView.graphics.endFill();
         }
      }
   }
}

