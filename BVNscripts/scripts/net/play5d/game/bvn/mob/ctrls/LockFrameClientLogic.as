package net.play5d.game.bvn.mob.ctrls
{
   import flash.utils.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.mob.input.*;
   import net.play5d.game.bvn.mob.utils.*;
import net.play5d.game.bvn.Debugger;
   
   public class LockFrameClientLogic
   {
      
      public var enabled:Boolean = true;
      
      private var _updateCache:Object = {};
      
      private var _clientK:int;
      
      private var _serverK:int;
      
      private var _clientFrame:int;
      
      private var _serverFrame:int;
      
      private var _serverNextFrame:int;
      
      private var _lastSendK:int;
      
      private var _delayTimer:int = 0;
      
      private var _sendAnyWay:Boolean = false;
      
      private var _sendStartFrame:int = 0;
      
      public function LockFrameClientLogic()
      {
         super();
      }
      
      public function reset() : void
      {
         this._updateCache = {};
         this._clientK = 0;
         this._serverK = 0;
         this._clientFrame = 0;
         this._serverFrame = 0;
         this._serverNextFrame = 0;
         this._lastSendK = 0;
         this._sendStartFrame = 0;
      }
      
      public function dispose() : void
      {
         this._updateCache = {};
      }
      
      public function receiveUpdate(param1:ByteArray) : Boolean
      {
         if(!param1)
         {
            return false;
         }
         param1.position = 0;
         var _loc2_:int = param1.readByte();
         if(_loc2_ != 9)
         {
            return false;
         }
         this._serverFrame = param1.readShort();
         this._serverK = param1.readShort();
         this._clientK = param1.readShort();
         this._serverNextFrame = this._serverFrame + LANUtils.LOCK_KEYFRAME;
         this.cacheUpdate();
         var _loc3_:int = getTimer() - this._delayTimer;
         LANClientCtrl.I.updateDelay(_loc3_);
         this._delayTimer = getTimer();
         this._sendAnyWay = true;
         return true;
      }
      
      public function receiveSyncUpdate(param1:ByteArray) : Boolean
      {
         var _loc7_:int;
         var _loc10_:int;
         var _loc6_:int;
         var _loc9_:int;
         var _loc8_:int;
         var _loc11_:int;
         var _loc12_:int;
         var _loc15_:int;
         var _loc5_:int;
         var _loc2_:int;
         var _loc14_:int;
         var _loc13_:int;
         var _loc4_:FighterMain = null;
         var _loc3_:FighterMain = null;
         if(!param1)
         {
            return false;
         }
         param1.position = 0;
         _loc7_ = param1.readByte();
         if(_loc7_ != 10)
         {
            return false;
         }
         this._updateCache = {};
         _loc10_ = param1.readShort();
         _loc6_ = param1.readByte();
         _loc9_ = param1.readByte();
         _loc8_ = param1.readShort();
         _loc11_ = param1.readShort();
         _loc12_ = param1.readShort();
         _loc15_ = param1.readShort();
         _loc5_ = param1.readShort();
         _loc2_ = param1.readShort();
         _loc14_ = param1.readShort();
         _loc13_ = param1.readShort();
         this._serverFrame = _loc10_;
         try
         {
            if(GameCtrl.I.gameRunData.round != _loc6_)
            {
               LANClientCtrl.I.syncError(true);
               return true;
            }
            GameCtrl.I.gameRunData.gameTime = _loc9_;
            _loc4_ = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
            _loc3_ = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter;
            _loc4_.hp = _loc8_;
            _loc4_.qi = _loc11_;
            _loc4_.x = _loc12_;
            _loc4_.y = _loc15_;
            _loc3_.hp = _loc5_;
            _loc3_.qi = _loc2_;
            _loc3_.x = _loc14_;
            _loc3_.y = _loc13_;
            if(_loc4_.hp > 0 && !_loc4_.isAlive)
            {
               _loc4_.relive();
            }
            if(_loc3_.hp > 0 && !_loc4_.isAlive)
            {
               _loc3_.relive();
            }
            LANClientCtrl.I.resetSyncError();
         }
         catch(e:Error)
         {
            Debugger.log(e);
            LANClientCtrl.I.syncError(true);
         }
         return true;
      }
      
      public function render() : Boolean
      {
         var _loc1_:ByteArray = null;
         if(!this.enabled)
         {
            return true;
         }
         if(this._serverNextFrame == 0 && this._serverFrame == 0)
         {
            if(this._sendStartFrame++ == 0)
            {
               _loc1_ = new ByteArray();
               _loc1_.writeByte(8);
               _loc1_.writeShort(0);
               _loc1_.writeShort(0);
               LANClientCtrl.I.sendUDP(_loc1_);
            }
            else if(this._sendStartFrame > 5)
            {
               this._sendStartFrame = 0;
            }
            return false;
         }
         if(this._clientFrame < this._serverNextFrame)
         {
            this._clientFrame += 1;
            this.renderUpdate();
            InputManager.I.socket_input_p2.renderInput();
            if(this._clientFrame % 2 == 0)
            {
               this.sendCtrl();
            }
            return true;
         }
         return false;
      }
      
      private function sendCtrl() : void
      {
         var _loc1_:int = int(InputManager.I.socket_input_p2.getSocketData());
         if(this._lastSendK == _loc1_ && !this._sendAnyWay)
         {
            return;
         }
         this._sendAnyWay = false;
         InputManager.I.socket_input_p2.resetInput();
         var _loc2_:ByteArray = new ByteArray();
         _loc2_.writeByte(8);
         _loc2_.writeShort(this._clientFrame);
         _loc2_.writeShort(_loc1_);
         LANClientCtrl.I.sendUDP(_loc2_);
         this._lastSendK = _loc1_;
      }
      
      private function cacheUpdate() : void
      {
         var _loc1_:int = 0;
         _loc1_ = int(this._serverFrame);
         while(_loc1_ < this._serverNextFrame)
         {
            this._updateCache[_loc1_] = [this._serverK,this._clientK];
            _loc1_++;
         }
      }
      
      private function renderUpdate() : void
      {
         var _loc1_:Array = this._updateCache[this._clientFrame];
         if(Boolean(_loc1_))
         {
            InputManager.I.socket_input_p1.setSocketData(_loc1_[0]);
            InputManager.I.socket_input_p2.setSocketData(_loc1_[1]);
         }
      }
   }
}

