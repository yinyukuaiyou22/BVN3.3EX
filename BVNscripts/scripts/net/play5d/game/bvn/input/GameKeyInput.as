package net.play5d.game.bvn.input
{
   import flash.display.Stage;
   import flash.events.KeyboardEvent;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.utils.*;
   
   public class GameKeyInput implements IGameInput
   {
      
      private var _config:KeyConfigVO;
      
      private var _downKeys:Object = {};
      
      private var _enabled:Boolean = true;
      
      public function GameKeyInput()
      {
         super();
      }
      
      public function initlize(param1:Stage) : void
      {
         KeyBoarder.initlize(param1);
         KeyBoarder.listen(this.keyBoardHandler);
      }
      
      public function get enabled() : Boolean
      {
         return this._enabled;
      }
      
      public function set enabled(param1:Boolean) : void
      {
         this._enabled = param1;
      }
      
      public function setConfig(param1:Object) : void
      {
         this._config = param1 as KeyConfigVO;
      }
      
      public function focus() : void
      {
         KeyBoarder.focus();
      }
      
      public function anyKey() : Boolean
      {
         var _loc1_:* = undefined;
         for(_loc1_ in this._downKeys)
         {
            if(this._downKeys[_loc1_] == 1)
            {
               return true;
            }
         }
         return false;
      }
      
      public function back() : Boolean
      {
         return this.isDown(27);
      }
      
      public function select() : Boolean
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in this._config.selects)
         {
            if(this.isDown(_loc1_))
            {
               return true;
            }
         }
         return false;
      }
      
      public function up() : Boolean
      {
         return this.isDown(this._config.up);
      }
      
      public function down() : Boolean
      {
         return this.isDown(this._config.down);
      }
      
      public function left() : Boolean
      {
         return this.isDown(this._config.left);
      }
      
      public function right() : Boolean
      {
         return this.isDown(this._config.right);
      }
      
      public function attack() : Boolean
      {
         return this.isDown(this._config.attack);
      }
      
      public function jump() : Boolean
      {
         return this.isDown(this._config.jump);
      }
      
      public function dash() : Boolean
      {
         return this.isDown(this._config.dash);
      }
      
      public function skill() : Boolean
      {
         return this.isDown(this._config.skill);
      }
      
      public function superSkill() : Boolean
      {
         return this.isDown(this._config.superKill);
      }
      
      public function special() : Boolean
      {
         return this.isDown(this._config.beckons);
      }
      
      public function wankai() : Boolean
      {
         return Boolean(this.isDown(this._config.attack)) && Boolean(this.isDown(this._config.jump));
      }
      
      public function clear() : void
      {
         this._downKeys = {};
      }
      
      private function keyBoardHandler(param1:KeyboardEvent) : void
      {
         switch(param1.type)
         {
            case "keyDown":
               this._downKeys[param1.keyCode] = 1;
               break;
            case "keyUp":
               this._downKeys[param1.keyCode] = 0;
         }
      }
      
      public function setKeyState(keyCode:uint, isDown:Boolean) : void
      {
         this._downKeys[keyCode] = isDown ? 1 : 0;
      }
      
      private function isDown(param1:uint) : Boolean
      {
         return this._downKeys[param1] == 1;
      }
   }
}

