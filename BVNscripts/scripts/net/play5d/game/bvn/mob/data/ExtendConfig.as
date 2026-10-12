package net.play5d.game.bvn.mob.data
{
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.mob.input.*;
import net.play5d.game.bvn.Debugger;
   
   public class ExtendConfig implements IExtendConfig
   {
      
      // 键盘输入默认开启（原为 false）。原因：input/GameKeyInput 的 enabled 默认就是 true，
      // 键盘在"点 APPLY 之前"一直可用，而 APPLY 时 updateInputConfig() 会按本值把它同步关掉，
      // 表现为「设置里按 APPLY 退出后键盘突然失效、卡在菜单」。两者统一为"默认开"消除这个不一致。
      // 已知取舍：手柄 D-pad/按钮产生的 KeyboardEvent 同样会进入键盘通道；可在设置菜单「Keyboard Input」关闭。
      public var ENABLE_KEYBOARD:Boolean = true;
      
      public var INFINITE_ENERGY:Boolean = false;
      
      public var joyMenuConfig:JoyStickConfigVO = new JoyStickConfigVO();
      
      public var joy1Config:JoyStickConfigVO = new JoyStickConfigVO();

      // 2026-08-26 批次 2 新增：P2 玩家独立手柄配置。
      // 旧版 joy_p2 与 joy_p1 共享 joy1Config，导致 P2 玩家改键无法独立保存、设备重连时 P2 配置被 P1 覆盖。
      // 新版为 P2 单独持有配置（joy_p2 仍走单手柄模型路由，但配置/存档/设备分配完全独立）。
      public var joy2Config:JoyStickConfigVO = new JoyStickConfigVO();

      public var screenMode:int = 1;
      
      public var screenPadConfig:ScreenPadConfigVO = new ScreenPadConfigVO();

public var joyTarget:int = 0;

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
         // 2026-08-26 批次 2：P2 独立配置存档
         _loc1_.joy_p2 = this.joy2Config.toObj();
         _loc1_.screenMode = this.screenMode;
         _loc1_.screenPadConfig = this.screenPadConfig.toObj();
         _loc1_.ENABLE_KEYBOARD = this.ENABLE_KEYBOARD;
_loc1_.joyTarget = this.joyTarget;
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
         // 2026-08-26 批次 2：P2 独立配置读档。
         // 旧存档无 joy_p2 字段 → 守卫跳过 → joy2Config 保持默认空配置 → 下次 toSaveObj 自动写入。
         if(param1.joy_p2 != undefined)
         {
            this.joy2Config.readObj(param1.joy_p2);
         }
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
if(param1.joyTarget != undefined)
{
   this.joyTarget = int(param1.joyTarget);
}
this.updateJoyConfig();
      }
      
      public function updateJoyConfig() : void
      {
         this.initDefaultDevices();
         // 菜单手柄设备号跟随 P1（向后兼容批次 1 的设计：单手柄模型，菜单/P1 视为同一物理设备）。
         this.joyMenuConfig.deviceId = this.joy1Config.deviceId;
      }

      private function initDefaultDevices() : void
      {
         // 2026-08-16 修复：去掉 _isInitDefaultJoystick 一次性守卫。
         // 旧逻辑：读档时设备未连接 → deviceId 分配为 null 且守卫锁死 → 设备连接后 updateJoyConfig 直接 return → deviceId 永远 null → 手柄全面失效。
         // 新逻辑：每次调用都重试（setDefaultDevice 内部有 deviceIsSet/deviceId 有效守卫，已设置且有效则不覆盖）。
         // 2026-08-26 批次 2 + 批次 3 收尾：P2 独立设备分配（player=1 = 第 2 个设备的 index 1）。
         // 批次 3 决策：单手柄永远禁 joy_p2（refreshJoystickRouting 内部只动 enabled，不动 deviceId）。
         // joy2Config.deviceId 仍需保持有效——为存档独立性（玩家 P2 改键独立保存）+ 未来批次 4 P2 改键 UI 读取即时可用。
         Debugger.logFold("initDefaultDevices");
         this.setDefaultDevice(this.joy1Config,0);
         this.setDefaultDevice(this.joy2Config,1);
      }
      
      private function setDefaultDevice(param1:JoyStickConfigVO, param2:int) : void
      {
         // deviceId 为空或指向不存在/未启用的设备时，重新分配当前可用设备
         if(!param1.deviceIsSet && (param1.deviceId == null || !JoySticker.isActive(param1.deviceId)))
         {
            param1.deviceId = JoySticker.getDeviceId(param2);
         }
      }
   }
}

