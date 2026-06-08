package net.play5d.game.bvn.mob.input
{
   import flash.display.Stage;
   import net.play5d.game.bvn.input.*;
   
   public class ScreenPadInput implements IGameInput
   {
      
      private var isDownObj:Object = {};
      
      private var _enabled:Boolean = true;
      
      public function ScreenPadInput()
      {
         super();
      }
      
      public function get enabled() : Boolean
      {
         return this._enabled;
      }
      
      public function set enabled(param1:Boolean) : void
      {
         this._enabled = param1;
         if(!param1)
         {
            this.isDownObj = {};
         }
      }
      
      public function initlize(param1:Stage) : void
      {
      }
      
      public function setConfig(param1:Object) : void
      {
      }
      
      public function focus() : void
      {
      }
      
      public function setDown(param1:String, param2:Boolean) : void
      {
         this.isDownObj[param1] = param2;
      }
      
      public function anyKey() : Boolean
      {
         return Boolean(this.isDownObj["select"]) || Boolean(this.isDownObj["back"]);
      }
      
      public function back() : Boolean
      {
         return this.isDownObj["back"];
      }
      
      public function select() : Boolean
      {
         return this.isDownObj["select"];
      }
      
      public function up() : Boolean
      {
         return this.isDownObj["up"];
      }
      
      public function down() : Boolean
      {
         return this.isDownObj["down"];
      }
      
      public function left() : Boolean
      {
         return this.isDownObj["left"];
      }
      
      public function right() : Boolean
      {
         return this.isDownObj["right"];
      }
      
      public function attack() : Boolean
      {
         return this.isDownObj["attack"];
      }
      
      public function jump() : Boolean
      {
         return this.isDownObj["jump"];
      }
      
      public function dash() : Boolean
      {
         return this.isDownObj["dash"];
      }
      
      public function skill() : Boolean
      {
         return this.isDownObj["skill"];
      }
      
      public function superSkill() : Boolean
      {
         return this.isDownObj["superSkill"];
      }
      
      public function special() : Boolean
      {
         return this.isDownObj["special"];
      }
      
      public function wankai() : Boolean
      {
         return this.isDownObj["wankai"];
      }
      
      public function clear() : void
      {
         this.isDownObj = {};
      }
   }
}

