package net.play5d.game.bvn.mob.input
{
   import flash.display.Stage;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.mob.data.*;
import net.play5d.game.bvn.Debugger;
   
   public class GameSocketInput implements IGameInput
   {
      
      private var _data:SocketInputData;
      
      private var _enabled:Boolean = false;
      
      private var _inputers:Vector.<IGameInput>;
      
      private var _inputData:int = 0;
      
      private var _upK:int;
      
      private var _downK:int;
      
      private var _leftK:int;
      
      private var _rightK:int;
      
      private var _attackK:int;
      
      private var _jumpK:int;
      
      private var _dashK:int;
      
      private var _skillK:int;
      
      private var _bishaK:int;
      
      private var _specialK:int;
      
      public function GameSocketInput()
      {
         super();
         this.initK();
      }
      
      private function initK() : void
      {
         this._upK = parseInt("1000000000",2);
         this._downK = parseInt("0100000000",2);
         this._leftK = parseInt("0010000000",2);
         this._rightK = parseInt("0001000000",2);
         this._attackK = parseInt("0000100000",2);
         this._jumpK = parseInt("0000010000",2);
         this._dashK = parseInt("0000001000",2);
         this._skillK = parseInt("0000000100",2);
         this._bishaK = parseInt("0000000010",2);
         this._specialK = parseInt("0000000001",2);
      }
      
      public function get enabled() : Boolean
      {
         return this._enabled;
      }
      
      public function set enabled(param1:Boolean) : void
      {
         this._enabled = param1;
         if(param1)
         {
            this._data = new SocketInputData();
         }
         else
         {
            this._data = null;
         }
      }
      
      public function setInputers(param1:Array) : void
      {
         var _loc2_:* = undefined;
         this._inputers = new Vector.<IGameInput>();
         for each(_loc2_ in param1)
         {
            this._inputers.push(_loc2_);
         }
      }
      
      public function renderInput() : void
      {
         var _loc1_:int = 0;
         var _loc2_:IGameInput = null;
         if(!this._inputers || this._inputers.length < 1)
         {
            return;
         }
         var _loc3_:int = int(this._inputers.length);
         _loc1_ = 0;
         while(_loc1_ < _loc3_)
         {
            _loc2_ = this._inputers[_loc1_];
            _loc2_.up() && (this._inputData = this._inputData | this._upK);
            _loc2_.down() && (this._inputData = this._inputData | this._downK);
            _loc2_.left() && (this._inputData = this._inputData | this._leftK);
            _loc2_.right() && (this._inputData = this._inputData | this._rightK);
            _loc2_.attack() && (this._inputData = this._inputData | this._attackK);
            _loc2_.jump() && (this._inputData = this._inputData | this._jumpK);
            _loc2_.dash() && (this._inputData = this._inputData | this._dashK);
            _loc2_.skill() && (this._inputData = this._inputData | this._skillK);
            _loc2_.superSkill() && (this._inputData = this._inputData | this._bishaK);
            _loc2_.special() && (this._inputData = this._inputData | this._specialK);
            _loc1_++;
         }
      }
      
      public function freeRender() : void
      {
         var _loc1_:int = 0;
         var _loc2_:IGameInput = null;
         if(!this._inputers || this._inputers.length < 1)
         {
            return;
         }
         if(!this._data)
         {
            return;
         }
         this._data.clear();
         var _loc3_:int = int(this._inputers.length);
         _loc1_ = 0;
         while(_loc1_ < _loc3_)
         {
            _loc2_ = this._inputers[_loc1_];
            this._data.up = Boolean(this._data.up) || _loc2_.up();
            this._data.down = Boolean(this._data.down) || _loc2_.down();
            this._data.left = Boolean(this._data.left) || _loc2_.left();
            this._data.right = Boolean(this._data.right) || _loc2_.right();
            this._data.attack = Boolean(this._data.attack) || _loc2_.attack();
            this._data.jump = Boolean(this._data.jump) || _loc2_.jump();
            this._data.dash = Boolean(this._data.dash) || _loc2_.dash();
            this._data.skill = Boolean(this._data.skill) || _loc2_.skill();
            this._data.superSkill = Boolean(this._data.superSkill) || _loc2_.superSkill();
            this._data.special = Boolean(this._data.special) || _loc2_.special();
            this._data.select = Boolean(this._data.select) || _loc2_.select();
            this._data.back = Boolean(this._data.back) || _loc2_.back();
            _loc1_++;
         }
      }
      
      public function resetInput() : void
      {
         this._inputData = 0;
         this.renderInput();
      }
      
      public function setSocketData(param1:int) : void
      {
         if(!this._data)
         {
            Debugger.log("GameSocketInput.data is null!");
            return;
         }
         var _loc2_:String = param1.toString(2);
         var _loc3_:int = _loc2_.length;
         this._data.special = _loc2_.charAt(_loc3_ - 1) == "1";
         this._data.superSkill = _loc2_.charAt(_loc3_ - 2) == "1";
         this._data.skill = _loc2_.charAt(_loc3_ - 3) == "1";
         this._data.dash = _loc2_.charAt(_loc3_ - 4) == "1";
         this._data.jump = _loc2_.charAt(_loc3_ - 5) == "1";
         this._data.attack = _loc2_.charAt(_loc3_ - 6) == "1";
         this._data.right = _loc2_.charAt(_loc3_ - 7) == "1";
         this._data.left = _loc2_.charAt(_loc3_ - 8) == "1";
         this._data.down = _loc2_.charAt(_loc3_ - 9) == "1";
         this._data.up = _loc2_.charAt(_loc3_ - 10) == "1";
      }
      
      public function getSocketData() : int
      {
         return this._inputData;
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
      
      public function anyKey() : Boolean
      {
         return false;
      }
      
      public function back() : Boolean
      {
         return false;
      }
      
      public function select() : Boolean
      {
         return Boolean(this._data) && (Boolean(this._data.attack) || Boolean(this._data.select));
      }
      
      public function up() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.up);
      }
      
      public function down() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.down);
      }
      
      public function left() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.left);
      }
      
      public function right() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.right);
      }
      
      public function attack() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.attack);
      }
      
      public function jump() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.jump);
      }
      
      public function dash() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.dash);
      }
      
      public function skill() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.skill);
      }
      
      public function superSkill() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.superSkill);
      }
      
      public function special() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.special);
      }
      
      public function wankai() : Boolean
      {
         return Boolean(this._data) && Boolean(this._data.attack) && Boolean(this._data.jump);
      }
      
      public function clear() : void
      {
         this._data && this._data.clear();
         this.resetInput();
      }
   }
}

