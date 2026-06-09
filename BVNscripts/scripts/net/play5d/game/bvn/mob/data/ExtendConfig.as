package net.play5d.game.bvn.mob.data
{
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.mob.input.*;
import net.play5d.game.bvn.Debugger;
   
   public class ExtendConfig implements IExtendConfig
   {
      
      public var ENABLE_KEYBOARD:Boolean = true;
      
      public var INFINITE_ENERGY:Boolean = false;
      
      public var joyMenuConfig:JoyStickConfigVO = new JoyStickConfigVO();
      
      public var joy1Config:JoyStickConfigVO = new JoyStickConfigVO();
      
      public var screenMode:int = 1;
      
      public var screenPadConfig:ScreenPadConfigVO = new ScreenPadConfigVO();
      
      private var _isInitDefaultJoystick:Boolean;
      
      public function ExtendConfig()
      {
         super();
      }
      
      public function toSaveObj() : Object
      {
         var _loc1_:Object = {};
         _loc1_.joy_menu = this.joyMenuConfig.toObj();
         _loc1_.joy_p1 = this.joy1Config.toObj();
         _loc1_.screenMode = this.screenMode;
         _loc1_.screenPadConfig = this.screenPadConfig.toObj();
         _loc1_.ENABLE_KEYBOARD = this.ENABLE_KEYBOARD;
         return _loc1_;
      }
      
      public function readSaveObj(param1:Object) : void
      {
         if(!param1)
         {
            return;
         }
         this.joyMenuConfig.readObj(param1.joy_menu);
         this.joy1Config.readObj(param1.joy_p1);
         if(param1.screenMode != undefined)
         {
            this.screenMode = param1.screenMode;
         }
         if(param1.screenPadConfig != undefined)
         {
            this.screenPadConfig.readObj(param1.screenPadConfig);
         }
         if(param1.ENABLE_KEYBOARD != undefined)
         {
            this.ENABLE_KEYBOARD = param1.ENABLE_KEYBOARD;
         }
         this.updateJoyConfig();
      }
      
      public function updateJoyConfig() : void
      {
         this.initDefaultDevices();
         this.joyMenuConfig.deviceId = this.joy1Config.deviceId;
      }
      
      private function initDefaultDevices() : void
      {
         if(this._isInitDefaultJoystick)
         {
            return;
         }
         Debugger.log("initDefaultDevices");
         this._isInitDefaultJoystick = true;
         this.setDefaultDevice(this.joy1Config,0);
      }
      
      private function setDefaultDevice(param1:JoyStickConfigVO, param2:int) : void
      {
         if(!param1.deviceIsSet && param1.deviceId == null)
         {
            param1.deviceId = JoySticker.getDeviceId(param2);
         }
      }
   }
}

