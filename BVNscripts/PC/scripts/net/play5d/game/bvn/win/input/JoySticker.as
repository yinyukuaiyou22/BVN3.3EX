package net.play5d.game.bvn.win.input
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.GameInputEvent;
   import flash.ui.GameInput;
   import flash.ui.GameInputControl;
   import flash.ui.GameInputDevice;
   import net.play5d.game.bvn.win.GameInterfaceManager;
   
   public class JoySticker extends EventDispatcher
   {
      
      public static const DEVICE_LIST_CHANGED:String = "deviceListChanged";
      
      private static var _gameInput:GameInput;
      
      private static var _inited:Boolean;
      
      private static var _gameDeivces:Vector.<GameInputDevice>;
      
      private static var _deivceMap:Object;
      
      private static var _downKey:JoyStickSetVO;
      
      public static const instance:JoySticker = new JoySticker();
      
      public function JoySticker()
      {
         super();
      }
      
      public static function initlize() : void
      {
         if(_inited)
         {
            return;
         }
         if(!GameInput.isSupported)
         {
            return;
         }
         _inited = true;
         _gameDeivces = new Vector.<GameInputDevice>();
         _deivceMap = {};
         _gameInput = new GameInput();
         _gameInput.addEventListener("deviceAdded",joystickHandler);
         _gameInput.addEventListener("deviceRemoved",joystickHandler);
         _gameInput.addEventListener("deviceUnusable",joystickHandler);
      }
      
      public static function getAllDevices() : Vector.<GameInputDevice>
      {
         return _gameDeivces;
      }
      
      public static function getDeviceId(param1:int) : String
      {
         if(param1 >= _gameDeivces.length)
         {
            return null;
         }
         var _loc2_:GameInputDevice = _gameDeivces[param1];
         if(_loc2_)
         {
            return _loc2_.id;
         }
         return null;
      }
      
      public static function getDeviceIndex(param1:String) : int
      {
         return _gameDeivces.indexOf(getDevice(param1));
      }
      
      private static function joystickHandler(param1:GameInputEvent) : void
      {
         switch(param1.type)
         {
            case "deviceAdded":
               if(isVmulti(param1.device))
               {
                  return;
               }
               outputDeviceInfo(param1.device);
               if(GameInput.numDevices < 3)
               {
                  addDeivce(param1.device);
                  GameInterfaceManager.config.updateJoyConfig();
               }
               break;
            case "deviceRemoved":
               removeDevice(param1.device);
               break;
            case "deviceUnusable":
               removeDevice(param1.device);
         }
      }
      
      private static function outputDeviceInfo(param1:GameInputDevice) : void
      {
         var _loc2_:int = 0;
         var _loc3_:GameInputControl = null;
         _loc2_ = 0;
         while(_loc2_ < param1.numControls)
         {
            _loc3_ = param1.getControlAt(_loc2_);
            _loc2_++;
         }
      }
      
      private static function addDeivce(param1:GameInputDevice) : void
      {
         param1.enabled = true;
         _gameDeivces.push(param1);
         var _loc2_:String = param1.id;
         _deivceMap[_loc2_] = param1;
         JoySticker.instance.dispatchEvent(new Event("deviceListChanged"));
      }
      
      private static function removeDevice(param1:GameInputDevice) : void
      {
         param1.enabled = false;
         var _loc3_:int = _gameDeivces.indexOf(param1);
         if(_loc3_ != -1)
         {
            _gameDeivces.splice(_loc3_,1);
         }
         for(var _loc2_ in _deivceMap)
         {
            if(_deivceMap[_loc2_] == param1)
            {
               delete _deivceMap[_loc2_];
               break;
            }
         }
         JoySticker.instance.dispatchEvent(new Event("deviceListChanged"));
      }
      
      private static function getDevice(param1:String) : GameInputDevice
      {
         return _deivceMap[param1];
      }
      
      public static function isActive(param1:String) : Boolean
      {
         var _loc2_:GameInputDevice = getDevice(param1);
         return _loc2_ && _loc2_.enabled;
      }
      
      public static function isDown(param1:String, param2:JoyStickSetVO) : Boolean
      {
         var _loc4_:GameInputDevice = getDevice(param1);
         if(!_loc4_)
         {
            return false;
         }
         if(param2.id > _loc4_.numControls)
         {
            return false;
         }
         var _loc3_:GameInputControl = _loc4_.getControlAt(param2.id);
         if(_loc3_ == null)
         {
            return false;
         }
         if(param2.value > 0)
         {
            return _loc3_.value > 0.5;
         }
         if(param2.value < 0)
         {
            return _loc3_.value < -0.5;
         }
         return false;
      }
      
      public static function isDownAnyKey(param1:String) : Boolean
      {
         var _loc3_:int = 0;
         var _loc2_:GameInputDevice = getDevice(param1);
         if(!_loc2_)
         {
            return false;
         }
         while(_loc3_ < _loc2_.numControls)
         {
            if(checkDownValue(_loc2_,_loc3_))
            {
               return true;
            }
            _loc3_++;
         }
         return false;
      }
      
      public static function getDownKey(param1:String, param2:Boolean) : JoyStickSetVO
      {
         var _loc6_:int = 0;
         var _loc8_:int = 0;
         var _loc3_:String = null;
         var _loc5_:String = null;
         var _loc4_:* = null;
         var _loc7_:GameInputDevice = getDevice(param1);
         if(_loc7_ == null)
         {
            return null;
         }
         _loc6_ = 0;
         while(_loc6_ < _loc7_.numControls)
         {
            _loc8_ = checkDownValue(_loc7_,_loc6_);
            if(_loc8_ != 0)
            {
               if(_downKey)
               {
                  _loc3_ = _loc6_ + "_" + _loc8_;
                  _loc5_ = _downKey.id + "_" + _downKey.value;
                  if(_loc5_ == _loc3_)
                  {
                     return param2 ? null : _downKey;
                  }
               }
               return _downKey = new JoyStickSetVO(_loc6_,_loc8_);
            }
            _loc6_++;
         }
         return null;
      }
      
      private static function checkDownValue(param1:GameInputDevice, param2:int) : int
      {
         if(param2 > param1.numControls)
         {
            return 0;
         }
         var _loc3_:GameInputControl = param1.getControlAt(param2);
         if(_loc3_ == null)
         {
            return 0;
         }
         var _loc4_:Number = _loc3_.value;
         if(_loc4_ == 1 || _loc4_ > 0.5)
         {
            return 1;
         }
         if(_loc4_ < -0.5)
         {
            return -1;
         }
         return 0;
      }
      
      private static function isVmulti(param1:GameInputDevice) : Boolean
      {
         if(!param1)
         {
            return false;
         }
         var _loc2_:String = param1.name ? param1.name.toLowerCase() : "";
         if(_loc2_.indexOf("vmulti") != -1)
         {
            return true;
         }
         var _loc3_:String = param1.id ? param1.id.toLowerCase() : "";
         if(_loc3_.indexOf("vmulti") != -1)
         {
            return true;
         }
         return false;
      }
   }
}

