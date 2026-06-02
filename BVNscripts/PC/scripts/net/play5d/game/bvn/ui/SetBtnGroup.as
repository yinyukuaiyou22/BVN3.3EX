package net.play5d.game.bvn.ui
{
   import com.greensock.TweenLite;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TouchEvent;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.data.ConfigVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.utils.TouchMoveEvent;
   import net.play5d.game.bvn.utils.TouchUtils;
   
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
      
      private var _arrow:MovieClip;
      
      private var _arrowIndex:int = -1;
      
      private var _scrollRect:Rectangle;
      
      private var _isConfigState:Boolean;
      
      public function SetBtnGroup(param1:Boolean = false)
      {
         super();
         _isConfigState = param1;
         if(GameConfig.TOUCH_MODE)
         {
            this.scaleY = 1.1;
            this.scaleX = 1.1;
            TouchUtils.I.listenOneFinger(this,touchMoveHandler,false,true);
         }
      }
      
      private function touchMoveHandler(param1:TouchMoveEvent) : void
      {
         var _loc2_:* = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         if(!_scrollRect)
         {
            return;
         }
         if(param1.type == "EVENT_TOUCH_MOVE")
         {
            _scrollRect.y -= param1.deltaY;
            updateScroll();
         }
         if(param1.type == "EVENT_TOUCH_END")
         {
            _loc2_ = -1;
            if(param1.endY > param1.startY)
            {
               if(_scrollRect.y < 0)
               {
                  _loc2_ = 0;
               }
            }
            if(param1.endY < param1.startY)
            {
               _loc3_ = endY != 0 ? endY : _scrollRect.height;
               _loc4_ = GameConfig.GAME_SIZE.y - _loc3_ + 100;
               if(_scrollRect.y > _loc4_)
               {
                  _loc2_ = _loc4_;
               }
            }
            if(_loc2_ != -1)
            {
               TweenLite.to(_scrollRect,0.2,{
                  "y":_loc2_,
                  "onUpdate":updateScroll
               });
            }
         }
      }
      
      public function initScroll(param1:Number, param2:Number) : void
      {
         _scrollRect = new Rectangle(0,0,param1,param2);
         this.scrollRect = _scrollRect;
      }
      
      public function initMainSet() : void
      {
         GameUI.registerSetBtnGroup(this);
         initMainBtns();
         initArrow();
         GameRender.add(render,this);
         GameInputer.focus();
         GameInputer.enabled = true;
      }
      
      public function initKeySet() : void
      {
         GameUI.registerSetBtnGroup(this);
         setBtnData([{
            "label":GetLangText("game_ui.btn_data.set.set_all.label"),
            "cn":GetLangText("game_ui.btn_data.set.set_all.txt")
         },{
            "label":GetLangText("game_ui.btn_data.set.set_default.label"),
            "cn":GetLangText("game_ui.btn_data.set.set_default.txt")
         },{
            "label":GetLangText("game_ui.btn_data.set.apply.label"),
            "cn":GetLangText("game_ui.btn_data.set.apply.txt")
         },{
            "label":GetLangText("game_ui.btn_data.set.cancel.label"),
            "cn":GetLangText("game_ui.btn_data.set.cancel.txt")
         }]);
      }
      
      public function setBtnData(param1:Array, param2:int = 0) : void
      {
         var _loc5_:SetBtn = null;
         var _loc3_:int = 0;
         var _loc4_:* = null;
         _btns = new Vector.<SetBtn>();
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1[_loc3_];
            _loc5_ = addBtn(_loc4_.label,_loc4_.cn,_loc4_.options);
            if(_loc4_.optoinKey != undefined)
            {
               _loc5_.optionKey = _loc4_.optoinKey;
            }
            if(_loc4_.optionValue != undefined)
            {
               _loc5_.setOptionByValue(_loc4_.optionValue);
            }
            _loc3_++;
         }
         initArrow(param2);
         GameRender.add(render,this);
         GameInputer.focus();
         GameInputer.enabled = true;
      }
      
      public function pauseRender() : void
      {
         GameRender.remove(render,this);
      }
      
      public function resumeRender() : void
      {
         GameRender.add(render,this);
      }
      
      public function destory() : void
      {
         if(_btns)
         {
            for each(var _loc1_ in _btns)
            {
               _loc1_.destory();
               _loc1_.removeEventListener("touchTap",touchHandler);
               _loc1_.removeEventListener("mouseOver",mouseHandler);
               _loc1_.removeEventListener("click",mouseHandler);
               _loc1_.removeEventListener("OPTION_CHANGE",onChangeOption);
               _loc1_.removeEventListener("SELECT",onSelect);
            }
            _btns = null;
         }
         GameRender.remove(render,this);
         TouchUtils.I.unlistenOneFinger(this);
      }
      
      private function initMainBtns() : void
      {
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc9_:Object = null;
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc1_:Object = null;
         var _loc8_:SetBtn = null;
         _btns = new Vector.<SetBtn>();
         var _loc7_:Array = GameInterface.instance.getSettingMenu();
         if(_isConfigState)
         {
            _loc3_ = [];
            _loc4_ = 0;
            while(_loc4_ <= 60)
            {
               _loc9_ = {
                  "label":_loc4_.toString(),
                  "cn":_loc4_ + GetLangText("stage_rule.substitution_frame.frame"),
                  "value":_loc4_
               };
               _loc3_.push(_loc9_);
               _loc4_++;
            }
            _loc5_ = [{
               "label":GetLangText("stage_settings.abled.enabled.label"),
               "cn":GetLangText("stage_settings.abled.enabled.txt"),
               "value":true
            },{
               "label":GetLangText("stage_settings.abled.disabled.label"),
               "cn":GetLangText("stage_settings.abled.disabled.txt"),
               "value":false
            }];
            _loc7_ = [{
               "txt":GetLangText("stage_rule.switch.label"),
               "cn":GetLangText("stage_rule.switch.txt"),
               "func":GameData.I.config.switchAllRuleConfig
            },{
               "txt":GetLangText("stage_rule.bankai.label"),
               "cn":GetLangText("stage_rule.bankai.txt"),
               "options":_loc5_,
               "optoinKey":"isBankai"
            },{
               "txt":GetLangText("stage_rule.god_level.label"),
               "cn":GetLangText("stage_rule.god_level.txt"),
               "options":_loc5_,
               "optoinKey":"isGodLevel"
            },{
               "txt":GetLangText("stage_rule.exact_moving.label"),
               "cn":GetLangText("stage_rule.exact_moving.txt"),
               "options":_loc5_,
               "optoinKey":"isExactMoving"
            },{
               "txt":GetLangText("stage_rule.infinite_atk_chk.label"),
               "cn":GetLangText("stage_rule.infinite_atk_chk.txt"),
               "options":_loc5_,
               "optoinKey":"isInfiniteAttack"
            },{
               "txt":GetLangText("stage_rule.standard_limit.label"),
               "cn":GetLangText("stage_rule.standard_limit.txt"),
               "options":_loc5_,
               "optoinKey":"isStandardLimit"
            },{
               "txt":GetLangText("stage_rule.auto_direct.label"),
               "cn":GetLangText("stage_rule.auto_direct.txt"),
               "options":_loc5_,
               "optoinKey":"isAutoDirect"
            },{
               "txt":GetLangText("stage_rule.combo_burden.label"),
               "cn":GetLangText("stage_rule.combo_burden.txt"),
               "options":_loc5_,
               "optoinKey":"isComboBurden"
            },{
               "txt":GetLangText("stage_rule.original_qi.label"),
               "cn":GetLangText("stage_rule.original_qi.txt"),
               "options":[{
                  "label":GetLangText("stage_rule.original_qi.child.p0.label"),
                  "cn":GetLangText("stage_rule.original_qi.child.p0.txt"),
                  "value":0
               },{
                  "label":GetLangText("stage_rule.original_qi.child.p100.label"),
                  "cn":GetLangText("stage_rule.original_qi.child.p100.txt"),
                  "value":100
               },{
                  "label":GetLangText("stage_rule.original_qi.child.p200.label"),
                  "cn":GetLangText("stage_rule.original_qi.child.p200.txt"),
                  "value":200
               },{
                  "label":GetLangText("stage_rule.original_qi.child.p300.label"),
                  "cn":GetLangText("stage_rule.original_qi.child.p300.txt"),
                  "value":300
               }],
               "optoinKey":"originalQi"
            },{
               "txt":GetLangText("stage_rule.original_assist.label"),
               "cn":GetLangText("stage_rule.original_assist.txt"),
               "options":_loc5_,
               "optoinKey":"originalAssist"
            },{
               "txt":GetLangText("stage_rule.ghost_step.label"),
               "cn":GetLangText("stage_rule.ghost_step.txt"),
               "options":_loc5_,
               "optoinKey":"isGhostStep"
            },{
               "txt":GetLangText("stage_rule.special_skill.label"),
               "cn":GetLangText("stage_rule.special_skill.txt"),
               "options":_loc5_,
               "optoinKey":"isSpecialSkill"
            },{
               "txt":GetLangText("stage_rule.replace_special.label"),
               "cn":GetLangText("stage_rule.replace_special.txt"),
               "options":_loc5_,
               "optoinKey":"isReplaceSpecial"
            },{
               "txt":GetLangText("stage_rule.special_mis_prot.label"),
               "cn":GetLangText("stage_rule.special_mis_prot.txt"),
               "options":_loc5_,
               "optoinKey":"isSpecialMisProt"
            },{
               "txt":GetLangText("stage_rule.camera_zoom_rate.label"),
               "cn":GetLangText("stage_rule.camera_zoom_rate.txt"),
               "options":[{
                  "label":GetLangText("stage_rule.camera_zoom_rate.child.p50.label"),
                  "cn":GetLangText("stage_rule.camera_zoom_rate.child.p50.txt"),
                  "value":0.5
               },{
                  "label":GetLangText("stage_rule.camera_zoom_rate.child.p60.label"),
                  "cn":GetLangText("stage_rule.camera_zoom_rate.child.p60.txt"),
                  "value":0.6
               },{
                  "label":GetLangText("stage_rule.camera_zoom_rate.child.p70.label"),
                  "cn":GetLangText("stage_rule.camera_zoom_rate.child.p70.txt"),
                  "value":0.7
               },{
                  "label":GetLangText("stage_rule.camera_zoom_rate.child.p80.label"),
                  "cn":GetLangText("stage_rule.camera_zoom_rate.child.p80.txt"),
                  "value":0.8
               },{
                  "label":GetLangText("stage_rule.camera_zoom_rate.child.p90.label"),
                  "cn":GetLangText("stage_rule.camera_zoom_rate.child.p90.txt"),
                  "value":0.9
               },{
                  "label":GetLangText("stage_rule.camera_zoom_rate.child.p100.label"),
                  "cn":GetLangText("stage_rule.camera_zoom_rate.child.p100.txt"),
                  "value":1
               }],
               "optoinKey":"cameraZoomRate"
            },{
               "txt":GetLangText("stage_rule.upload_record.label"),
               "cn":GetLangText("stage_rule.upload_record.txt"),
               "options":_loc5_,
               "optoinKey":"isUploadRecord"
            }];
         }
         var _loc2_:ConfigVO = GameData.I.config;
         _loc6_ = 0;
         while(_loc6_ < _loc7_.length)
         {
            _loc1_ = _loc7_[_loc6_];
            _loc8_ = addBtn(_loc1_.txt,_loc1_.cn,_loc1_.options);
            if(_loc1_.select != null)
            {
               _loc8_.onSelect = _loc1_.select;
            }
            if(_loc1_.func != null)
            {
               _loc8_.func = _loc1_.func;
            }
            _loc8_.optionKey = _loc1_.optoinKey;
            if(_loc8_.optionKey)
            {
               _loc8_.setOptionByValue(_loc2_.getValueByKey(_loc8_.optionKey));
            }
            _loc6_++;
         }
         addBtn(GetLangText("game_ui.btn_data.general.apply.label"),GetLangText("game_ui.btn_data.general.apply.txt"));
         this.graphics.beginFill(0,0);
         this.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,_btns[_btns.length - 1].y + 300);
         this.graphics.endFill();
      }
      
      private function addBtn(param1:String, param2:String, param3:Array = null) : SetBtn
      {
         var _loc4_:SetBtn = new SetBtn(param1,param2);
         if(GameConfig.TOUCH_MODE)
         {
            _loc4_.addEventListener("touchTap",touchHandler);
         }
         else
         {
            _loc4_.addEventListener("mouseOver",mouseHandler);
            _loc4_.addEventListener("click",mouseHandler);
         }
         switch(direct)
         {
            case 0:
               _loc4_.x = startX + gap * _btns.length;
               _loc4_.y = startY;
               break;
            case 1:
               _loc4_.x = startX;
               _loc4_.y = startY + gap * _btns.length;
         }
         addChild(_loc4_);
         if(param3)
         {
            _loc4_.setOption(param3);
            _loc4_.addEventListener("OPTION_CHANGE",onChangeOption);
         }
         else
         {
            _loc4_.addEventListener("SELECT",onSelect);
         }
         _btns.push(_loc4_);
         return _loc4_;
      }
      
      private function touchHandler(param1:TouchEvent) : void
      {
         if(!keyEnable)
         {
            return;
         }
         var _loc4_:SetBtn = param1.currentTarget as SetBtn;
         var _loc2_:int = _btns.indexOf(_loc4_);
         if(_loc2_ == -1)
         {
            return;
         }
         var _loc3_:Object = _loc4_.getOption();
         if(_loc2_ == _arrowIndex)
         {
            if(_loc3_ != null)
            {
               _loc4_.nextOption();
            }
            else
            {
               _loc4_.select();
            }
            return;
         }
         setArrowIndex(_loc2_,true,false);
      }
      
      private function mouseHandler(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         if(!keyEnable)
         {
            return;
         }
         var _loc3_:SetBtn = param1.currentTarget as SetBtn;
         switch(param1.type)
         {
            case "mouseOver":
               _loc2_ = _btns.indexOf(_loc3_);
               if(_loc2_ != -1)
               {
                  setArrowIndex(_loc2_);
               }
               break;
            case "click":
               if(_loc3_.getOption() == null)
               {
                  _loc3_.select();
                  break;
               }
               if(param1.target)
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
         _arrow = AssetManager.I.createObject("select_arrow_mc","subswfs/common_ui.swf") as MovieClip;
         addChild(_arrow);
         setArrowIndex(param1);
      }
      
      public function setArrowIndex(param1:int, param2:Boolean = true, param3:Boolean = true) : void
      {
         var btn:SetBtn;
         var id:int = param1;
         var sound:Boolean = param2;
         var isScroll:Boolean = param3;
         if(_arrowIndex == id)
         {
            return;
         }
         if(id < 0)
         {
            id = _btns.length - 1;
         }
         if(id > _btns.length - 1)
         {
            id = 0;
         }
         btn = _btns[id];
         _arrowIndex = id;
         _arrow.x = btn.x - 10;
         _arrow.y = btn.y + 15;
         _btns.every(function(param1:SetBtn, param2:int, param3:Vector.<SetBtn>):Boolean
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
         if(isScroll)
         {
            moveScroll();
         }
      }
      
      private function moveScroll() : void
      {
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         if(!_scrollRect)
         {
            return;
         }
         if(direct == 1)
         {
            if(_btns.length < 8)
            {
               return;
            }
            _loc4_ = endY != 0 ? endY : _scrollRect.height;
            _loc5_ = this.height;
            if(_loc5_ < _loc4_)
            {
               return;
            }
            _loc3_ = _loc4_ - startY;
            _loc1_ = _loc3_ / _btns.length;
            _loc2_ = -_arrowIndex * (_loc1_ - gap);
            TweenLite.to(_scrollRect,0.2,{
               "y":_loc2_,
               "onUpdate":updateScroll
            });
         }
      }
      
      private function updateScroll() : void
      {
         this.scrollRect = _scrollRect;
      }
      
      private function render() : void
      {
         if(!keyEnable)
         {
            return;
         }
         if(!_btns || _btns.length < 1)
         {
            return;
         }
         var _loc1_:SetBtn = _btns[_arrowIndex];
         if(GameInputer.up(gameInputType,1))
         {
            if(direct == 1)
            {
               setArrowIndex(_arrowIndex - 1);
            }
         }
         if(GameInputer.down(gameInputType,1))
         {
            if(direct == 1)
            {
               setArrowIndex(_arrowIndex + 1);
            }
         }
         if(GameInputer.left(gameInputType,1))
         {
            if(direct == 0)
            {
               setArrowIndex(_arrowIndex - 1);
            }
            if(direct == 1)
            {
               _loc1_.prevOption();
            }
         }
         if(GameInputer.right(gameInputType,1))
         {
            if(direct == 0)
            {
               setArrowIndex(_arrowIndex + 1);
            }
            if(direct == 1)
            {
               _loc1_.nextOption();
            }
         }
         if(GameInputer.attack(gameInputType,1))
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

