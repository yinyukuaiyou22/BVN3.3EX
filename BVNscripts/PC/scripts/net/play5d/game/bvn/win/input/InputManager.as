package net.play5d.game.bvn.win.input
{
   import flash.events.Event;
   import flash.ui.GameInputDevice;
   import net.play5d.game.bvn.input.GameKeyInput;
   import net.play5d.game.bvn.win.GameInterfaceManager;
   
   public class InputManager
   {
      
      private static var _i:InputManager;
      
      public var key_menu:GameKeyInput = new GameKeyInput();
      
      public var key_p1:GameKeyInput = new GameKeyInput();
      
      public var key_p2:GameKeyInput = new GameKeyInput();
      
      public var joy_menu:GameJoystickInput = new GameJoystickInput(1);
      
      public var joy_p1:GameJoystickInput = new GameJoystickInput(1);
      
      public var joy_p2:GameJoystickInput = new GameJoystickInput(2);
      
      public var socket_input_p1:GameSocketInput = new GameSocketInput();
      
      public var socket_input_p2:GameSocketInput = new GameSocketInput();
      
      public function InputManager()
      {
         super();
         joy_menu.setConfig(new JoyStickConfigVO());
         joy_p1.setConfig(new JoyStickConfigVO());
         joy_p2.setConfig(new JoyStickConfigVO());
         joy_p2.setDeviceId(null);
         JoySticker.instance.addEventListener("deviceListChanged",onDevicesChanged);
      }
      
      public static function get I() : InputManager
      {
         if(!_i)
         {
            _i = new InputManager();
         }
         return _i;
      }
      
      private function onDevicesChanged(param1:Event) : void
      {
         var _loc3_:Vector.<GameInputDevice> = JoySticker.getAllDevices();
         var _loc6_:JoyStickConfigVO = GameInterfaceManager.config.joy1Config;
         var _loc2_:JoyStickConfigVO = GameInterfaceManager.config.joy2Config;
         var _loc5_:GameInputDevice = findDeviceById(_loc3_,_loc6_.archiveDeviceId);
         var _loc7_:GameInputDevice = findDeviceById(_loc3_,_loc2_.archiveDeviceId);
         var _loc4_:Vector.<GameInputDevice> = new Vector.<GameInputDevice>();
         for each(var _loc8_ in _loc3_)
         {
            if(_loc8_ != _loc5_ && _loc8_ != _loc7_)
            {
               _loc4_.push(_loc8_);
            }
         }
         if(!_loc6_.deviceId && !_loc5_ && _loc4_.length > 0)
         {
            _loc5_ = _loc4_.shift();
         }
         if(!_loc2_.deviceId && !_loc7_ && _loc4_.length > 0)
         {
            _loc7_ = _loc4_.shift();
         }
         joy_p1.setDeviceId(_loc5_ ? _loc5_.id : null);
         joy_p2.setDeviceId(_loc7_ ? _loc7_.id : null);
         joy_menu.setDeviceId(_loc5_ ? _loc5_.id : null);
         JoyRumble.init();
      }
      
      private function findDeviceById(param1:Vector.<GameInputDevice>, param2:String) : GameInputDevice
      {
         if(!param2)
         {
            return null;
         }
         for each(var _loc3_ in param1)
         {
            if(_loc3_.id == param2)
            {
               return _loc3_;
            }
         }
         return null;
      }
   }
}

