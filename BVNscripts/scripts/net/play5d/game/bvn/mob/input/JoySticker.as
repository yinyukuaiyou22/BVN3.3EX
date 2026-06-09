package net.play5d.game.bvn.mob.input
{
   import flash.events.GameInputEvent;
   import flash.ui.*;
   import net.play5d.game.bvn.mob.*;
import net.play5d.game.bvn.Debugger;
   
   public class JoySticker
   {
      
      private static var _gameInput:GameInput;
      
      private static var _inited:Boolean;
      
      private static var _gameDeivces:Vector.<GameInputDevice>;
      
      private static var _deivceMap:Object;
      
      private static var _downKey:JoyStickSetVO;
      
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
         Debugger.log("JoySticker.initlize");
         if(!GameInput.isSupported)
         {
            Debugger.log("该平台不支持手柄！");
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
      
      public static function getAllDeivces() : Vector.<GameInputDevice>
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
         if(Boolean(_loc2_))
         {
            return _loc2_.id;
         }
         return null;
      }
      
      private static function joystickHandler(param1:GameInputEvent) : void
      {
         switch(param1.type)
         {
            case "deviceAdded":
               Debugger.log("connected",param1.device,GameInput.numDevices);
               outputDeviceInfo(param1.device);
               if(GameInput.numDevices < 3)
               {
                  addDeivce(param1.device);
                  GameInterfaceManager.config.updateJoyConfig();
               }
               break;
            case "deviceRemoved":
               Debugger.log("disconnected",param1.device);
               removeDevice(param1.device);
               break;
            case "deviceUnusable":
               Debugger.log("unuse",param1.device);
               removeDevice(param1.device);
         }
      }
      
      private static function outputDeviceInfo(param1:GameInputDevice) : void
      {
         var _loc2_:int = 0;
         var _loc3_:GameInputControl = null;
         Debugger.log("device.enabled - " + param1.enabled);
         Debugger.log("device.id - " + param1.id);
         Debugger.log("device.name - " + param1.name);
         Debugger.log("device.numControls - " + param1.numControls);
         Debugger.log("device.sampleInterval - " + param1.sampleInterval);
         Debugger.log("device.MAX_BUFFER - 32000");
         Debugger.log("buttonNum",param1.numControls);
         while(_loc2_ < param1.numControls)
         {
            _loc3_ = param1.getControlAt(_loc2_);
            Debugger.log("button:" + _loc2_ + ":" + _loc3_.id);
            _loc2_++;
         }
      }
      
      private static function addDeivce(param1:GameInputDevice) : void
      {
         param1.enabled = true;
         _gameDeivces.push(param1);
         var _loc2_:String = param1.id;
         _deivceMap[_loc2_] = param1;
         Debugger.log("addDevice:" + _loc2_,":",param1.id);
      }
      
      private static function removeDevice(param1:GameInputDevice) : void
      {
         var _loc3_:* = undefined;
         param1.enabled = false;
         var _loc2_:int = int(_gameDeivces.indexOf(param1));
         if(_loc2_ != -1)
         {
            _gameDeivces.splice(_loc2_,1);
         }
         for(_loc3_ in _deivceMap)
         {
            if(_deivceMap[_loc3_] == param1)
            {
               delete _deivceMap[_loc3_];
            }
         }
      }
      
      private static function getDeive(param1:String) : GameInputDevice
      {
         return _deivceMap[param1];
      }
      
      public static function isActive(param1:String) : Boolean
      {
         var _loc2_:GameInputDevice = getDeive(param1);
         return Boolean(_loc2_) && _loc2_.enabled;
      }
      
      public static function isDown(param1:String, param2:JoyStickSetVO) : Boolean
      {
         var _loc3_:GameInputDevice = getDeive(param1);
         if(!_loc3_)
         {
            return false;
         }
         if(param2.id > _loc3_.numControls)
         {
            return false;
         }
         var _loc4_:GameInputControl = _loc3_.getControlAt(param2.id);
         if(!_loc4_)
         {
            return false;
         }
         if(param2.value > 0)
         {
            return _loc4_.value > 0.5;
         }
         if(param2.value < 0)
         {
            return _loc4_.value < -0.5;
         }
         return false;
      }
      
      public static function isDownAnyKey(param1:String) : Boolean
      {
         var _loc2_:int = 0;
         var _loc3_:GameInputDevice = getDeive(param1);
         if(!_loc3_)
         {
            return false;
         }
         while(_loc2_ < _loc3_.numControls)
         {
            if(Boolean(checkDownValue(_loc3_,_loc2_)))
            {
               return true;
            }
            _loc2_++;
         }
         return false;
      }
      
      public static function getDownKey(param1:String, param2:Boolean) : JoyStickSetVO
      {
         var _loc3_:int = 0;
         var _loc4_:Number = NaN;
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc7_:JoyStickSetVO = null;
         var _loc8_:GameInputDevice = getDeive(param1);
         if(!_loc8_)
         {
            return null;
         }
         while(_loc3_ < _loc8_.numControls)
         {
            _loc4_ = Number(checkDownValue(_loc8_,_loc3_));
            if(_loc4_ != 0)
            {
               if(Boolean(_downKey))
               {
                  _loc5_ = _loc3_ + "_" + _loc4_;
                  _loc6_ = _downKey.id + "_" + _downKey.value;
                  if(_loc6_ == _loc5_)
                  {
                     return param2 ? null : _downKey;
                  }
               }
               _downKey = _loc7_ = new JoyStickSetVO(_loc3_,_loc4_);
               Debugger.log("isDown",_loc7_.id + "_" + _loc7_.value);
               return _loc7_;
            }
            _loc3_++;
         }
         return null;
      }
      
      private static function checkDownValue(param1:GameInputDevice, param2:int) : Number
      {
         if(param2 > param1.numControls)
         {
            return 0;
         }
         var _loc3_:GameInputControl = param1.getControlAt(param2);
         if(!_loc3_)
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
   }
}

