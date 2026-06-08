package net.play5d.game.bvn.mob.views
{
   import com.greensock.*;
   import flash.display.*;
   import flash.events.EventDispatcher;
   import flash.ui.GameInputDevice;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.mob.*;
   import net.play5d.game.bvn.mob.input.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   
   public class JoyStickSetUI extends EventDispatcher implements IInnerSetUI
   {
      
      private var _joybitmap:Class = EmbeddedAssets.setting_joy_png;
      
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
         this._ui = new Sprite();
         this._bp = new this._joybitmap();
         this._bp.x = 170;
         this._bp.y = 250;
         this._ui.addChild(this._bp);
         this._tmpJoyConfig = new JoyStickConfigVO();
         this.initKeyMapping();
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
         var _loc1_:int = 0;
         var _loc2_:GameInputDevice = null;
         var _loc3_:Vector.<GameInputDevice> = JoySticker.getAllDeivces();
         var _loc4_:Array = [{
            "label":"NONE",
            "cn":"不使用",
            "value":null
         }];
         while(_loc1_ < _loc3_.length)
         {
            _loc2_ = _loc3_[_loc1_];
            _loc4_.push({
               "label":this.subString(_loc2_.name,15),
               "cn":this.subString(_loc2_.name,45),
               "value":_loc2_.id
            });
            _loc1_++;
         }
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.startY = 30;
         this._btnGroup.setBtnData([{
            "label":"USE JOY",
            "cn":"绑定手柄",
            "options":_loc4_,
            "optoinKey":"deviceId",
            "optionValue":this._tmpJoyConfig.deviceId
         },{
            "label":"SET ALL",
            "cn":"设置全部"
         },{
            "label":"SET DEFAULT",
            "cn":"还原默认按键"
         },{
            "label":"BUY JOY",
            "cn":"购买推荐手柄"
         },{
            "label":"APPLY",
            "cn":"应用"
         },{
            "label":"CANCEL",
            "cn":"取消"
         }]);
         this._btnGroup.addEventListener("SELECT",this.onBtnSelect);
         this._btnGroup.addEventListener("OPTION_CHANGE",this.onOptoinChange);
         this._ui.addChild(this._btnGroup);
      }
      
      public function setConfig(param1:int, param2:JoyStickConfigVO) : void
      {
         this._player = param1;
         this._joyConfig = param2;
         this._tmpJoyConfig.readObj(param2.toObj());
         this._deviceId = this._tmpJoyConfig.deviceId;
         this.initBtns();
      }
      
      private function onBtnSelect(param1:SetBtnEvent) : void
      {
         switch(param1.selectedLabel)
         {
            case "SET ALL":
               if(!JoySticker.isActive(this._tmpJoyConfig.deviceId))
               {
                  GameUI.alert("NO JOYSTICK CONNECT","未检测到可用的手柄");
                  return;
               }
               this._setIndex = -1;
               this._btnGroup.keyEnable = false;
               this._startSet = false;
               GameRender.add(this.renderSet);
               this.setNextKey();
               break;
            case "SET DEFAULT":
               this._tmpJoyConfig = new JoyStickConfigVO();
               this._tmpJoyConfig.deviceId = this._deviceId;
               GameUI.alert("SET JOYSTICK DEFAULT SUCCESS","已设置为默认按键");
               break;
            case "BUY JOY":
               URL.buyJoystick();
               break;
            case "APPLY":
               this._joyConfig.readObj(this._tmpJoyConfig.toObj());
               if(this._player == 1)
               {
                  GameInterfaceManager.config.updateJoyConfig();
               }
               dispatchEvent(new SetBtnEvent("APPLY_SET"));
               break;
            case "CANCEL":
               dispatchEvent(new SetBtnEvent("CANCEL_SET"));
         }
      }
      
      private function onOptoinChange(param1:SetBtnEvent) : void
      {
         if(param1.optionKey == "deviceId")
         {
            this._tmpJoyConfig.deviceId = param1.optionValue;
            this._tmpJoyConfig.deviceIsSet = true;
            this._deviceId = param1.optionValue;
         }
      }
      
      private function renderSet() : void
      {
         var _loc1_:Object = null;
         if(!this._startSet)
         {
            if(JoySticker.isDownAnyKey(this._tmpJoyConfig.deviceId) == false)
            {
               this._startSet = true;
            }
            return;
         }
         var _loc2_:JoyStickSetVO = JoySticker.getDownKey(this._tmpJoyConfig.deviceId,true);
         if(Boolean(_loc2_))
         {
            _loc1_ = this._mappings[this._setIndex];
            if(Boolean(_loc1_))
            {
               this._tmpJoyConfig[_loc1_.id] = _loc2_;
            }
            this.setNextKey();
         }
      }
      
      private function initKeyMapping() : void
      {
         this._mappings = [{
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
            "id":"special",
            "name":"SPECIAL",
            "cn":"特殊"
         },{
            "id":"waikai",
            "name":"BANN KAI",
            "cn":"卍解"
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
         this._setIndex += 1;
         var _loc1_:Object = this._mappings[this._setIndex];
         if(Boolean(_loc1_))
         {
            if(!this._dialog)
            {
               this._dialog = new SetBtnDialog();
               this._ui.addChild(this._dialog.ui);
            }
            this._dialog.show(_loc1_.name,_loc1_.cn);
         }
         else
         {
            this._dialog.hide();
            this._btnGroup.keyEnable = true;
            GameRender.remove(this.renderSet);
         }
      }
      
      public function fadIn() : void
      {
         this._bp.y = 600;
         TweenLite.to(this._bp,0.3,{"y":240});
      }
      
      public function fadOut() : void
      {
         TweenLite.to(this._ui,0.3,{"y":600});
      }
      
      public function getUI() : DisplayObject
      {
         return this._ui;
      }
      
      public function destory() : void
      {
         GameRender.remove(this.renderSet);
         if(Boolean(this._btnGroup))
         {
            try
            {
               this._ui.removeChild(this._btnGroup);
            }
            catch(e:Error)
            {
            }
            this._btnGroup.destory();
            this._btnGroup = null;
         }
      }
   }
}

