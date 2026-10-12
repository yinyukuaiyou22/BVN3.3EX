package net.play5d.game.bvn.mob.input
{
   import flash.desktop.NativeApplication;
   import flash.display.Stage;
   import flash.events.GameInputEvent;
   import flash.events.KeyboardEvent;
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
      
      private static var _prevValues:Object = {};
      
      private static var _isDownLogFrame:int = 0;

      private static var _noDeviceLogged:Boolean = false;
      
      public function JoySticker()
      {
         super();
      }
      
      /**
       * 轮询所有已连接设备的 control 值变化，边沿（按下/松开）时输出 JOY_IN 日志。
       * 由 Debugger._onEnterFrame 每帧调用，仅文件日志开启时生效。
       * 用于分析手柄输入是否被正确识别（control index 与 value）。
       */
      public static function pollInputLog() : void
      {
         if(!_gameDeivces)
         {
            return;
         }
         var _loc1_:int = 0;
         var _loc2_:String = null;
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc5_:Number = NaN;
         var _loc6_:String = null;
         while(_loc1_ < _gameDeivces.length)
         {
            _loc2_ = _gameDeivces[_loc1_].id;
            _loc3_ = _prevValues[_loc2_] as Array;
            if(!_loc3_)
            {
               _loc3_ = [];
               _prevValues[_loc2_] = _loc3_;
            }
            _loc4_ = 0;
            while(_loc4_ < _gameDeivces[_loc1_].numControls)
            {
               _loc5_ = checkDownValue(_gameDeivces[_loc1_],_loc4_);
               if(_loc3_[_loc4_] == undefined)
               {
                  _loc3_[_loc4_] = _loc5_;
               }
               else if(_loc3_[_loc4_] != _loc5_)
               {
                  _loc6_ = _loc5_ != 0 ? "DOWN" : "UP";
                  Debugger.log("JOY_IN: " + _loc6_ + " device=" + _loc2_ + " control=" + _loc4_ + " value=" + _loc5_);
                  _loc3_[_loc4_] = _loc5_;
               }
               _loc4_++;
            }
            _loc1_++;
         }
      }
      
      public static function initlize() : void
      {
         var _loc1_:Stage = null;
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
         
         // 屏蔽手柄 Back/Start 键的 Android 系统默认行为
         // Xbox Back(8)=keyCode 167, Start(9) 在某些设备触发多任务
         // D-pad 在某些设备产生方向键事件
         try
         {
            NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, onPreventDefaultKeys);
         }
         catch(e:Error)
         {
         }
      }
      
      /**
       * 拦截手柄对应按键的底层键盘事件，防止 Android 系统处理。
       * 手柄 GameInput API 与 KeyboardEvent 是独立通道，
       * 屏蔽 KeyboardEvent 不影响 GameInputControl.value 读取。
       */
      private static function onPreventDefaultKeys(param1:KeyboardEvent) : void
      {
         // 记录手柄产生的键盘事件（低频，按键才触发），用于排查系统默认行为（如 B 键返回桌面）
         // 手柄按键事件，改为折叠计数（排查系统默认行为时看 flushFold 的汇总行即可）
         Debugger.logFold("KEY_DOWN", "code=" + param1.keyCode);
         switch(param1.keyCode)
         {
            // 167 = Xbox Back (MENU) → 阻止 Android BACK 行为
            // 165 = MediaPlay / Start 在某些映射
            // 97/108/109 = BUTTON_B / BUTTON_START / BUTTON_SELECT → 阻止系统震动反馈与键盘污染
            // 4 = KEYCODE_BACK / 3 = KEYCODE_HOME → 阻止手柄键触发系统返回/桌面
            // 19-22 = DPAD_UP/DOWN/LEFT/RIGHT → 阻止 D-pad 方向键污染键盘通道
            case 167:
            case 165:
            case 97:
            case 108:
            case 109:
            case 4:
            case 3:
            case 19:
            case 20:
            case 21:
            case 22:
               param1.preventDefault();
               break;
         }
      }
      
      public static function getAllDeivces() : Vector.<GameInputDevice>
      {
         return _gameDeivces;
      }
      
      public static function getDeviceId(param1:int) : String
      {
         if(!_gameDeivces || param1 >= _gameDeivces.length)
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
         if(!_deivceMap)
           {
              return null;
           }
           return _deivceMap[param1];
      }
      
      public static function isActive(param1:String) : Boolean
      {
         var _loc2_:GameInputDevice = getDeive(param1);
         return Boolean(_loc2_) && _loc2_.enabled;
      }
      
      /**
       * 扫描所有 control 的当前值，返回调试字符串。
       * 只包含值非零的 control，格式："index:id:value ..."
       */
      public static function getControlValuesDebug(param1:String) : String
      {
         var _loc2_:GameInputDevice = getDeive(param1);
         if(!_loc2_) return "(no device)";
         var _loc3_:String = "";
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.numControls)
         {
            var _loc5_:GameInputControl = _loc2_.getControlAt(_loc4_);
            if(_loc5_)
            {
               var _loc6_:Number = _loc5_.value;
               if(_loc6_ > 0.5 || _loc6_ < -0.5)
               {
                  _loc3_ += _loc4_ + ":" + _loc5_.id + ":" + _loc6_.toFixed(1) + "  ";
               }
               else if(_loc6_ != 0)
               {
                  _loc3_ += _loc4_ + ":" + _loc5_.id + ":" + _loc6_.toFixed(2) + "  ";
               }
            }
            _loc4_++;
         }
         if(_loc3_.length == 0) return "(idle)";
         return _loc3_;
      }
      
      public static function isDown(param1:String, param2:JoyStickSetVO) : Boolean
      {
         var _loc3_:GameInputDevice = getDeive(param1);
         if(!_loc3_)
         {
            if(!_noDeviceLogged)
            {
               Debugger.log("[JoySticker] isDown: no device for dev=" + param1 + " (id=" + param2.id + " val=" + param2.value + "). PC 端未连接手柄，后续调用静默。");
               _noDeviceLogged = true;
            }
            return false;
         }
         if(param2.id >= _loc3_.numControls)
         {
            return false;
         }
         var _loc4_:GameInputControl = _loc3_.getControlAt(param2.id);
         if(!_loc4_)
         {
            return false;
         }
         // 节流日志：每 60 帧记录一次 isDown 调用参数与读取值（排查 joy_p1 未命中）
         if(++_isDownLogFrame % 60 == 0)
         {
            Debugger.log("JOY_ISDOWN: dev=" + param1 + " id=" + param2.id + " cfgVal=" + param2.value + " ctrlVal=" + _loc4_.value.toFixed(2) + " numCtrl=" + _loc3_.numControls);
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
         if(param2 >= param1.numControls)
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

