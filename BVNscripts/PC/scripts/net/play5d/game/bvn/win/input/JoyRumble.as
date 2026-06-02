package net.play5d.game.bvn.win.input
{
   import flash.desktop.NativeApplication;
   import flash.desktop.NativeProcess;
   import flash.desktop.NativeProcessStartupInfo;
   import flash.errors.IOError;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.filesystem.File;
   import flash.net.Socket;
   import net.play5d.game.bvn.win.GameInterfaceManager;
   
   public class JoyRumble
   {
      
      private static var _i:JoyRumble;
      
      private static const HOST:String = "127.0.0.1";
      
      private static const PORT:int = 29378;
      
      private static var _sock:Socket;
      
      private static var _proc:NativeProcess;
      
      private var _command:String;
      
      public function JoyRumble()
      {
         super();
      }
      
      public static function get I() : JoyRumble
      {
         if(!_i)
         {
            _i = new JoyRumble();
         }
         return _i;
      }
      
      public static function init() : void
      {
         if(!GameInterfaceManager.config.joyRumble)
         {
            return;
         }
         if(JoySticker.getAllDevices().length == 0)
         {
            return;
         }
         launchBridge();
         _sock = new Socket();
         _sock.addEventListener("ioError",function(param1:IOErrorEvent):void
         {
            Trace("Rumble：Socket 连接失败:",param1.text);
         });
         NativeApplication.nativeApplication.addEventListener("exiting",function(param1:Event):void
         {
            shutdown();
         });
      }
      
      private static function launchBridge() : void
      {
         var _loc1_:File = File.applicationDirectory.resolvePath("assets/bridge/JoyBridge.exe");
         if(!_loc1_.exists)
         {
            Trace("Rumble：JoyBridge 不存在，未实现静默启动");
            return;
         }
         var _loc2_:NativeProcessStartupInfo = new NativeProcessStartupInfo();
         _loc2_.executable = _loc1_;
         _loc2_.workingDirectory = _loc1_.parent;
         _proc = new NativeProcess();
         _proc.start(_loc2_);
         Trace("Rumble：NativeProcess 已启动");
      }
      
      private static function getRumbleCommand(param1:int, param2:uint = 0, param3:uint = 0, param4:int = 0, param5:int = 0) : String
      {
         return param1 + "," + param2 + "," + param3 + "," + param4 + "," + param5;
      }
      
      private static function shutdown() : void
      {
         if(_sock && _sock.connected)
         {
            try
            {
               _sock.writeUTFBytes("STOP");
               _sock.flush();
            }
            catch(error:IOError)
            {
               Trace("Rumble：错误: 无法发送 STOP 指令，守护进程可能未运行。",error);
            }
         }
         if(_sock)
         {
            try
            {
               if(_sock.connected)
               {
                  _sock.close();
               }
            }
            catch(error:IOError)
            {
               Trace("Rumble：错误: 无法关闭 Socket。",error);
            }
         }
         if(_proc && _proc.running)
         {
            try
            {
               _proc.exit(true);
            }
            catch(error:Error)
            {
               Trace("Rumble：错误: 无法终止守护进程。",error);
            }
         }
      }
      
      private function addRumbleCommand(param1:String) : void
      {
         if(_command == null)
         {
            _command = "";
         }
         if(_command.length != 0)
         {
            _command += "|";
         }
         _command += param1;
      }
      
      public function addRumble(param1:int = -1, param2:uint = 0, param3:uint = 0, param4:int = 0, param5:int = 0) : void
      {
         var _loc6_:int = 0;
         if(!GameInterfaceManager.config.joyRumble)
         {
            return;
         }
         if(!_sock)
         {
            return;
         }
         if(param1 == 1)
         {
            _loc6_ = JoySticker.getDeviceIndex(InputManager.I.joy_p1.getDeviceId());
            addRumbleCommand(getRumbleCommand(_loc6_,param2,param3,param4,param5));
         }
         if(param1 == 2)
         {
            _loc6_ = JoySticker.getDeviceIndex(InputManager.I.joy_p2.getDeviceId());
            addRumbleCommand(getRumbleCommand(_loc6_,param2,param3,param4,param5));
         }
         if(param1 == -1)
         {
            _loc6_ = JoySticker.getDeviceIndex(InputManager.I.joy_p1.getDeviceId());
            addRumbleCommand(getRumbleCommand(_loc6_,param2,param3,param4,param5));
            _loc6_ = JoySticker.getDeviceIndex(InputManager.I.joy_p2.getDeviceId());
            addRumbleCommand(getRumbleCommand(_loc6_,param2,param3,param4,param5));
         }
      }
      
      public function doRumble() : void
      {
         if(!GameInterfaceManager.config.joyRumble)
         {
            _command = null;
            return;
         }
         if(!_sock)
         {
            return;
         }
         if(!_sock.connected)
         {
            _sock.connect("127.0.0.1",29378);
         }
         if(_command == null)
         {
            return;
         }
         _sock.writeUTFBytes(_command);
         _sock.flush();
         _command = null;
      }
   }
}

