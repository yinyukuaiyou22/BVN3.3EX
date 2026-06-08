package net.play5d.game.bvn.mob.input
{
   import flash.display.Stage;
   import net.play5d.game.bvn.input.*;
   
   public class GameJoystickInput implements IGameInput
   {
      
      public var player:int;
      
      private var _enabled:Boolean = true;
      
      private var _config:JoyStickConfigVO;
      
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
         return JoySticker.isDownAnyKey(this._config.deviceId);
      }
      
      public function back() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return Boolean(JoySticker.isDown(this._config.deviceId,this._config.back)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.select));
      }
      
      public function select() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return JoySticker.isDown(this._config.deviceId,this._config.jump);
      }
      
      public function up() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return Boolean(JoySticker.isDown(this._config.deviceId,this._config.up)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.up2));
      }
      
      public function down() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return Boolean(JoySticker.isDown(this._config.deviceId,this._config.down)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.down2));
      }
      
      public function left() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return Boolean(JoySticker.isDown(this._config.deviceId,this._config.left)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.left2));
      }
      
      public function right() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return Boolean(JoySticker.isDown(this._config.deviceId,this._config.right)) || Boolean(JoySticker.isDown(this._config.deviceId,this._config.right2));
      }
      
      public function attack() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return JoySticker.isDown(this._config.deviceId,this._config.attack);
      }
      
      public function jump() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return JoySticker.isDown(this._config.deviceId,this._config.jump);
      }
      
      public function dash() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return JoySticker.isDown(this._config.deviceId,this._config.dash);
      }
      
      public function skill() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return JoySticker.isDown(this._config.deviceId,this._config.skill);
      }
      
      public function superSkill() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return JoySticker.isDown(this._config.deviceId,this._config.superSkill);
      }
      
      public function special() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return JoySticker.isDown(this._config.deviceId,this._config.special);
      }
      
      public function wankai() : Boolean
      {
         if(!this._enabled)
         {
            return false;
         }
         return JoySticker.isDown(this._config.deviceId,this._config.waikai);
      }
      
      public function clear() : void
      {
      }
   }
}

