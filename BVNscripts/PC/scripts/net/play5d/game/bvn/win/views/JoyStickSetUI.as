package net.play5d.game.bvn.win.views
{
   import com.greensock.TweenLite;
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.ui.GameInputDevice;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.interfaces.IInnerSetUI;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.ui.SetBtnDialog;
   import net.play5d.game.bvn.ui.SetBtnGroup;
   import net.play5d.game.bvn.win.GameInterfaceManager;
   import net.play5d.game.bvn.win.input.JoyStickConfigVO;
   import net.play5d.game.bvn.win.input.JoyStickSetVO;
   import net.play5d.game.bvn.win.input.JoySticker;
   
   public class JoyStickSetUI extends EventDispatcher implements IInnerSetUI
   {
      
      private var _btnGroup:SetBtnGroup;
      
      private var _player:int;
      
      private var _ui:Sprite;
      
      private var _bp:Bitmap;
      
      private var _joyConfig:JoyStickConfigVO;
      
      private var _tmpJoyConfig:JoyStickConfigVO;
      
      private var _deviceId:String;
      
      private var _setIndex:int;
      
      private var _mappings:Array;
      
      private var _dialog:SetBtnDialog;
      
      private var _startSet:Boolean;
      
      public function JoyStickSetUI()
      {
         super();
         _ui = new Sprite();
         var _loc1_:Class = AssetManager.I.getSWFEffectClass("setting_joy","subswfs/back.swf");
         _bp = new Bitmap(new _loc1_());
         _bp.x = 170;
         _bp.y = 250;
         _ui.addChild(_bp);
         _tmpJoyConfig = new JoyStickConfigVO();
         initKeyMapping();
      }
      
      private function subString(param1:String, param2:int) : String
      {
         if(!param1)
         {
            return null;
         }
         if(param1.length < param2)
         {
            return param1;
         }
         return param1.substr(0,param2) + "...";
      }
      
      private function initBtns() : void
      {
         var _loc3_:int = 0;
         var _loc4_:GameInputDevice = null;
         var _loc2_:Vector.<GameInputDevice> = JoySticker.getAllDevices();
         var _loc1_:Array = [{
            "label":GetLangText("game_ui.btn_data.set.none.label"),
            "cn":GetLangText("game_ui.btn_data.set.none.txt"),
            "value":null
         }];
         _loc3_ = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            _loc1_.push({
               "label":subString(_loc4_.name,15),
               "cn":subString(_loc4_.name,45),
               "value":_loc4_.id
            });
            _loc3_++;
         }
         _btnGroup = new SetBtnGroup();
         _btnGroup.startY = 30;
         _btnGroup.setBtnData([{
            "label":GetLangText("game_ui.btn_data.set.bound_joy.label"),
            "cn":GetLangText("game_ui.btn_data.set.bound_joy.txt"),
            "options":_loc1_,
            "optoinKey":"deviceId",
            "optionValue":_tmpJoyConfig.deviceId
         },{
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
         _btnGroup.addEventListener("SELECT",onBtnSelect);
         _btnGroup.addEventListener("OPTION_CHANGE",onOptoinChange);
         _ui.addChild(_btnGroup);
      }
      
      public function setConfig(param1:int, param2:JoyStickConfigVO) : void
      {
         _player = param1;
         _joyConfig = param2;
         _tmpJoyConfig.readObj(param2.toObj());
         _deviceId = _tmpJoyConfig.deviceId;
         initBtns();
      }
      
      private function onBtnSelect(param1:SetBtnEvent) : void
      {
         switch(param1.selectedLabel)
         {
            case GetLangText("game_ui.btn_data.set.set_all.label"):
               if(!JoySticker.isActive(_tmpJoyConfig.deviceId))
               {
                  GameUI.alert(GetLangText("game_ui.alert.no_joystick_connect.title"),GetLangText("game_ui.alert.no_joystick_connect.message"));
                  return;
               }
               _setIndex = -1;
               _btnGroup.keyEnable = false;
               _startSet = false;
               GameRender.add(renderSet);
               setNextKey();
               break;
            case GetLangText("game_ui.btn_data.set.set_default.label"):
               _tmpJoyConfig = new JoyStickConfigVO();
               _tmpJoyConfig.deviceId = _deviceId;
               GameUI.alert(GetLangText("game_ui.alert.set_joystick_default.title"),GetLangText("game_ui.alert.set_joystick_default.message"));
               break;
            case GetLangText("game_ui.btn_data.set.apply.label"):
               _btnGroup.keyEnable = false;
               _joyConfig.readObj(_tmpJoyConfig.toObj());
               if(_player == 1)
               {
                  GameInterfaceManager.config.updateJoyConfig();
               }
               dispatchEvent(new SetBtnEvent("APPLY_SET"));
               break;
            case GetLangText("game_ui.btn_data.set.cancel.label"):
               _btnGroup.keyEnable = false;
               dispatchEvent(new SetBtnEvent("CANCEL_SET"));
         }
      }
      
      private function onOptoinChange(param1:SetBtnEvent) : void
      {
         if(param1.optionKey == "deviceId")
         {
            _tmpJoyConfig.deviceId = param1.optionValue;
            _tmpJoyConfig.deviceIsSet = true;
            _deviceId = param1.optionValue;
         }
      }
      
      private function renderSet() : void
      {
         var _loc1_:* = null;
         if(!_startSet)
         {
            if(JoySticker.isDownAnyKey(_tmpJoyConfig.deviceId) == false)
            {
               _startSet = true;
            }
            return;
         }
         var _loc2_:JoyStickSetVO = JoySticker.getDownKey(_tmpJoyConfig.deviceId,true);
         if(_loc2_)
         {
            _loc1_ = _mappings[_setIndex];
            if(_loc1_)
            {
               _tmpJoyConfig[_loc1_.id] = _loc2_;
            }
            setNextKey();
         }
      }
      
      private function initKeyMapping() : void
      {
         _mappings = [{
            "id":"up2",
            "name":"UP roker",
            "cn":"上(摇杆)"
         },{
            "id":"down2",
            "name":"DOWN roker",
            "cn":"下(摇杆)"
         },{
            "id":"left2",
            "name":"LEFT roker",
            "cn":"左(摇杆)"
         },{
            "id":"right2",
            "name":"RIGHT roker",
            "cn":"右(摇杆)"
         },{
            "id":"up",
            "name":"UP button",
            "cn":"上(按钮)"
         },{
            "id":"down",
            "name":"DOWN button",
            "cn":"下(按钮)"
         },{
            "id":"left",
            "name":"LEFT button",
            "cn":"左(按钮)"
         },{
            "id":"right",
            "name":"RIGHT button",
            "cn":"右(按钮)"
         },{
            "id":"attack",
            "name":"ATTACK",
            "cn":"攻击"
         },{
            "id":"jump",
            "name":"JUMP",
            "cn":"跳跃"
         },{
            "id":"dash",
            "name":"DASH",
            "cn":"冲刺"
         },{
            "id":"skill",
            "name":"SKILL",
            "cn":"技能"
         },{
            "id":"superSkill",
            "name":"SUPER SKILL",
            "cn":"大招"
         },{
            "id":"assist",
            "name":"ASSIST",
            "cn":"辅助"
         },{
            "id":"special",
            "name":"SPECIAL",
            "cn":"特殊"
         },{
            "id":"waikai",
            "name":"BAN KAI",
            "cn":"卍解/变身"
         },{
            "id":"back",
            "name":"BACK",
            "cn":"返回键"
         },{
            "id":"select",
            "name":"SELECT",
            "cn":"确认键（菜单）"
         }];
      }
      
      private function setNextKey() : void
      {
         _setIndex = _setIndex + 1;
         var _loc1_:Object = _mappings[_setIndex];
         if(_loc1_)
         {
            if(!_dialog)
            {
               _dialog = new SetBtnDialog();
               _ui.addChild(_dialog.ui);
            }
            _dialog.show(_loc1_.name,_loc1_.cn);
         }
         else
         {
            _dialog.hide();
            _btnGroup.keyEnable = true;
            GameRender.remove(renderSet);
         }
      }
      
      public function fadIn() : void
      {
         _bp.y = 600;
         TweenLite.to(_bp,0.3,{"y":240});
      }
      
      public function fadOut() : void
      {
         TweenLite.to(_ui,0.3,{"y":600});
      }
      
      public function getUI() : DisplayObject
      {
         return _ui;
      }
      
      public function destory() : void
      {
         GameRender.remove(renderSet);
         if(_btnGroup)
         {
            try
            {
               _ui.removeChild(_btnGroup);
            }
            catch(e:Error)
            {
            }
            _btnGroup.destory();
            _btnGroup = null;
         }
      }
   }
}

