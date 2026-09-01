package net.play5d.game.bvn.mob.views
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.mob.*;
   import net.play5d.game.bvn.mob.input.JoyStickConfigVO;
   import net.play5d.game.bvn.mob.input.JoySticker;
   import net.play5d.game.bvn.state.*;
   import net.play5d.kyo.stage.Istage;

   public class ViewManager
   {

      private static var _i:ViewManager;

      /**
       * 双手柄缓存。
       *
       * 选人进入时由 SelectFighterStage.build() 调用 refreshMultiPadCache()
       * 刷新；GameInterfaceManager 菜单注册处读取此值决定 P2 改键入口是否显示。
       *
       * 设计取舍：
       * 1. 选人时检测一次，避免菜单打开时反复遍历设备列表（轻量）
       * 2. 不订阅设备热插拔事件——批次 4 范围明确不考虑
       * 3. 单手柄永远禁 joy_p2，缓存仅用于菜单 P2 入口的显隐判断
       */
      private var _multiPadCache:Boolean = false;

      public function ViewManager()
      {
         super();
      }

      public static function get I() : ViewManager
      {
         if(!_i)
         {
            _i = new ViewManager();
         }
         return _i;
      }

      public function goP1JoyStickSet() : void
      {
         this.goJoyStickSet(1,GameInterfaceManager.config.joy1Config);
      }

      /**
       * P2 改键入口（批次 4 新增）。
       *
       * 与 goP1JoyStickSet() 镜像，传入 playerNum=2 + joy2Config。
       * JoyStickSetUI.setConfig() 已是参数化多玩家接口，APPLY 分支
       * 已通过 if(this._player == 1) 区分：P1 调 updateJoyConfig() 同步
       * menu 设备号，P2 只 readObj 直存不调 updateJoyConfig。
       */
      public function goP2JoyStickSet() : void
      {
         this.goJoyStickSet(2,GameInterfaceManager.config.joy2Config);
      }

      private function goJoyStickSet(param1:int, param2:JoyStickConfigVO) : void
      {
         var _loc3_:Istage = MainGame.stageCtrl.currentStage;
         if(!_loc3_ is SettingState)
         {
            Debugger.log("goJoyStickSet: skip not-in-setting player=", param1, " stage=", _loc3_);
            return;
         }
         // 批次 5：进入改键页日志，标注玩家号与当前绑定的设备号，便于真机定位 P1/P2 改键分流。
         Debugger.log("goJoyStickSet: enter player=", param1, " deviceId=", param2 != null ? param2.deviceId : "null");
         var _loc4_:SettingState = _loc3_ as SettingState;
         var _loc5_:JoyStickSetUI = new JoyStickSetUI();
         _loc5_.setConfig(param1,param2);
         _loc4_.goInnerSetPage(_loc5_);
      }

      public function setScreenBtns() : void
      {
         var _loc1_:SetScreenBtnView = new SetScreenBtnView();
         launch.I.addChildToGameSprite(_loc1_);
      }

      /**
       * 是否当前为双手柄模式（批次 4 新增）。
       *
       * 读取 _multiPadCache 缓存值——不实时遍历设备。
       * 调用方：GameInterfaceManager 设置菜单注册处（决定 P2 入口是否显示）。
       */
      public function isMultiplePads() : Boolean
      {
         return this._multiPadCache;
      }

      /**
       * 刷新双手柄缓存（批次 4 新增）。
       *
       * 调用方：SelectFighterStage.build()（选人进入时检测一次）。
       *
       * 检测方案：JoySticker.getAllDeivces().length > 1
       * 注意：getAllDeivces 是反编译历史拼写错误，与 wankai/waikai 同处理——
       * 保留拼写，避免引入 ABI 变动。
       *
       * 单手柄时玩家用屏幕虚拟按键（screen_p1/screen_p2）操作，
       * 不需要特殊处理；缓存仅用于菜单 P2 入口显隐。
       */
      public function refreshMultiPadCache() : void
      {
         // 批次 6.9 修复：JoySticker.getAllDeivces() 返回 Vector.<GameInputDevice>，
         // 不能直接赋给 Array（#1006 "Call to a possibly undefined method"）。
         // 改用 * 通配类型，长度判断兼容 Array/Vector/null。
         var pads:* = JoySticker.getAllDeivces();
         var padCount:int = pads != null ? pads.length : 0;
         this._multiPadCache = padCount > 1;
         Debugger.log("refreshMultiPadCache: devices=", padCount, " multiPad=", this._multiPadCache);
      }
   }
}

