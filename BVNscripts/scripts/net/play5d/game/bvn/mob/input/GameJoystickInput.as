package net.play5d.game.bvn.mob.input
{
   import flash.display.Stage;
   import flash.utils.Dictionary;
   import net.play5d.game.bvn.input.*;
   
   public class GameJoystickInput implements IGameInput
   {
      
      public var player:int;
      
      private var _enabled:Boolean = true;
      
      private var _config:JoyStickConfigVO;

      // 设备级按下历史：key = "dev:"+deviceId+":ctrl:"+controlId+":"+keyName,
      // value = true(上一帧按下)/false(上一帧松开或从未查询)。
      // 用途：批次 5 设备事件日志 + 跨实例隔离（joy_p1 / joy_p2 各自维护），
      // 避免 JoySticker._prevValues 按 deviceId 共享时双实例互相污染。
      // 注意：本字段只用于"边沿事件日志"和"防同帧重复触发"，不影响 attack()/jump() 等
      // 方法的返回值（保持"当前帧按住"语义，避免与 GameInputer.isJustDownDelay 冲突）。
      private var _prevKeys:Dictionary = new Dictionary();

      public function GameJoystickInput(param1:int)
      {
         super();
         this.player = param1;
      }
      
      public function get enabled() : Boolean
      {
         return this._enabled;
      }
      
      public function set enabled(param1:Boolean) : void
      {
         this._enabled = param1;
      }
      
      public function getDeviceId() : String
      {
         return this._config.deviceId;
      }
      
      public function setDeviceId(param1:String) : void
      {
         this._config.deviceId = param1;
      }
      
      public function initlize(param1:Stage) : void
      {
         JoySticker.initlize();
      }
      
      public function setConfig(param1:Object) : void
      {
         this._config = param1 as JoyStickConfigVO;
      }
      
      public function focus() : void
      {
      }
      
      public function anyKey() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDownAnyKey(this._config.deviceId);
         // 批次 5：任意键边沿接入 _checkEdge，用 "any" 语义 key + 独立设备键位，补齐无具体键名时的边沿日志。
         this._checkEdge("any", [], _r);
         return _r;
      }
      
      /**
       * 调试辅助：读取当前按下的 control 索引和值
       */
      private function _joyLog(param1:String, param2:Boolean) : void
      {
         if(!param2) return;
         var _d:String = this._config.deviceId;
         var _ctrlIdx:int = 0;
         var _dev:* = JoySticker.getAllDeivces();
         if(!_dev || _dev.length == 0) return;
         // 设备切换感知：优先取与当前 config.deviceId 匹配的设备，找不到则回退第一个。
         // 批次 5 修复：此前固定取 _dev[0]，P1/P2 配置不同设备时日志会错乱。
         var _dObj:* = _dev[0];
         var _di:int = 0;
         while(_di < _dev.length)
         {
            if(_dev[_di].id == _d)
            {
               _dObj = _dev[_di];
               break;
            }
            _di++;
         }
         var _logStr:String = "JOY:P" + this.player + " " + param1 + " dev=" + _d;
         while(_ctrlIdx < _dObj.numControls)
         {
            var _c:* = _dObj.getControlAt(_ctrlIdx);
            if(_c && (_c.value > 0.5 || _c.value < -0.5))
            {
               _logStr += " [" + _ctrlIdx + ":" + _c.id + "=" + _c.value.toFixed(1) + "]";
            }
            _ctrlIdx++;
         }
         if(_logStr.length > ("JOY:P" + this.player + " " + param1).length)
         {
            Debugger.log(_logStr);
         }
      }
      
      /**
       * 设备级边沿检测：记录每个按键上一帧状态，仅用于日志/防同帧重复触发。
       * 不修改 _r 的语义（保持"当前帧按住"），避免与 GameInputer.isJustDownDelay 冲突。
       * @param keyName 语义键名（"attack"/"jump"/"up" 等）
       * @param setVOs 可变参数：参与该按键的 JoyStickSetVO 列表（含双 setVO 方向键）
       * @param currentDown 当前帧该按键是否按下
       */
      private function _checkEdge(param1:String, param2:Array, param3:Boolean) : void
      {
         if(this._config == null) return;
         var _deviceId:String = this._config.deviceId;
         // key 设计：dev:deviceId:ctrl0_id+ctrl1_id+...:keyName
         // 即使两个 setVO 共享 controlId 也不冲突（按顺序连接）
         var _ctrlKey:String = "";
         var _i:int = 0;
         while(_i < param2.length)
         {
            var _s:* = param2[_i];
            if(_s != null) _ctrlKey += String(_s.id) + ",";
            _i++;
         }
         var _k:String = "dev:" + _deviceId + ":ctrl:" + _ctrlKey + ":" + param1;
         var _prev:Boolean = this._prevKeys[_k] == true;
         if(!_prev && param3)
         {
            // 按下边沿（批次 5：统一带 ctrl 组合，便于对照 JoyStickConfigVO）
            Debugger.log("JOY:P" + this.player + " EDGE DOWN key=" + param1 + " dev=" + _deviceId + " ctrl=" + _ctrlKey);
         }
         else if(_prev && !param3)
         {
            // 松开边沿
            Debugger.log("JOY:P" + this.player + " EDGE UP   key=" + param1 + " dev=" + _deviceId + " ctrl=" + _ctrlKey);
         }
         this._prevKeys[_k] = param3;
      }

      public function back() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = Boolean(JoySticker.isDown(this._config.deviceId,this._config.back)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.select));
         this._checkEdge("back", [this._config.back, this._config.select], _r);
         this._joyLog("back",_r);
         return _r;
      }
      
      public function select() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDown(this._config.deviceId,this._config.select);
         this._checkEdge("select", [this._config.select], _r);
         this._joyLog("select",_r);
         return _r;
      }

      public function up() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = Boolean(JoySticker.isDown(this._config.deviceId,this._config.up)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.up2));
         this._checkEdge("up", [this._config.up, this._config.up2], _r);
         this._joyLog("up",_r);
         return _r;
      }

      public function down() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = Boolean(JoySticker.isDown(this._config.deviceId,this._config.down)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.down2));
         this._checkEdge("down", [this._config.down, this._config.down2], _r);
         this._joyLog("down",_r);
         return _r;
      }

      public function left() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = Boolean(JoySticker.isDown(this._config.deviceId,this._config.left)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.left2));
         this._checkEdge("left", [this._config.left, this._config.left2], _r);
         this._joyLog("left",_r);
         return _r;
      }

      public function right() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = Boolean(JoySticker.isDown(this._config.deviceId,this._config.right)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.right2));
         this._checkEdge("right", [this._config.right, this._config.right2], _r);
         this._joyLog("right",_r);
         return _r;
      }
      
      public function attack() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDown(this._config.deviceId,this._config.attack);
         this._checkEdge("attack", [this._config.attack], _r);
         this._joyLog("attack",_r);
         return _r;
      }

      public function jump() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDown(this._config.deviceId,this._config.jump);
         this._checkEdge("jump", [this._config.jump], _r);
         this._joyLog("jump",_r);
         return _r;
      }

      public function dash() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDown(this._config.deviceId,this._config.dash);
         this._checkEdge("dash", [this._config.dash], _r);
         this._joyLog("dash",_r);
         return _r;
      }

      public function skill() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDown(this._config.deviceId,this._config.skill);
         this._checkEdge("skill", [this._config.skill], _r);
         this._joyLog("skill",_r);
         return _r;
      }

      public function superSkill() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDown(this._config.deviceId,this._config.superSkill);
         this._checkEdge("superSkill", [this._config.superSkill], _r);
         this._joyLog("superSkill",_r);
         return _r;
      }

      public function special() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDown(this._config.deviceId,this._config.special);
         this._checkEdge("special", [this._config.special], _r);
         this._joyLog("special",_r);
         return _r;
      }

      public function wankai() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         var _r:Boolean = JoySticker.isDown(this._config.deviceId,this._config.waikai);
         this._checkEdge("wankai", [this._config.waikai], _r);
         this._joyLog("waikai",_r);
         return _r;
      }

      public function clear() : void
      {
         // 清空设备级按下历史，避免 GameInputer.clearInput() 链路被调用后状态错乱
         for(var _k:String in this._prevKeys)
         {
            delete this._prevKeys[_k];
         }
      }
   }
}

