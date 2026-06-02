package net.play5d.game.bvn.win.ctrls
{
   import flash.utils.ByteArray;
   import flash.utils.getTimer;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.win.input.InputManager;
   import net.play5d.game.bvn.win.utils.LANUtils;
   
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
      
      public function LockFrameClientLogic()
      {
         super();
      }
      
      public function reset() : void
      {
         _updateCache = {};
         _clientK = 0;
         _serverK = 0;
         _clientFrame = 0;
         _serverFrame = 0;
         _serverNextFrame = 0;
         _lastSendK = 0;
      }
      
      public function dispose() : void
      {
         _updateCache = {};
      }
      
      public function receiveUpdate(param1:ByteArray) : Boolean
      {
         if(!param1)
         {
            return false;
         }
         param1.position = 0;
         var _loc3_:int = param1.readByte();
         if(_loc3_ != 9)
         {
            return false;
         }
         _serverFrame = param1.readShort();
         _serverK = param1.readShort();
         _clientK = param1.readShort();
         _serverNextFrame = _serverFrame + LANUtils.LOCK_KEYFRAME;
         cacheUpdate();
         var _loc2_:int = getTimer() - _delayTimer;
         LANClientCtrl.I.updateDelay(_loc2_);
         _delayTimer = getTimer();
         _sendAnyWay = true;
         return true;
      }
      
      public function receiveSyncUpdate(param1:ByteArray) : Boolean
      {
         var _loc6_:int = 0;
         var _loc8_:FighterMain = null;
         var _loc9_:FighterMain = null;
         if(!param1)
         {
            return false;
         }
         param1.position = 0;
         _loc6_ = param1.readByte();
         if(_loc6_ != 10)
         {
            return false;
         }
         _updateCache = {};
         var _loc12_:int = param1.readShort();
         var _loc3_:int = param1.readByte();
         var _loc2_:int = param1.readByte();
         var _loc5_:int = param1.readShort();
         var _loc13_:int = param1.readShort();
         var _loc10_:int = param1.readShort();
         var _loc15_:int = param1.readShort();
         var _loc4_:int = param1.readShort();
         var _loc7_:int = param1.readShort();
         var _loc14_:int = param1.readShort();
         var _loc11_:int = param1.readShort();
         _serverFrame = _loc12_;
         try
         {
            if(GameCtrl.I.gameRunData.round != _loc3_)
            {
               LANClientCtrl.I.syncError(true);
               return true;
            }
            GameCtrl.I.gameRunData.gameTime = _loc2_;
            _loc8_ = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
            _loc9_ = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter;
            _loc8_.hp = _loc5_;
            _loc8_.qi = _loc13_;
            _loc8_.x = _loc10_;
            _loc8_.y = _loc15_;
            _loc9_.hp = _loc4_;
            _loc9_.qi = _loc7_;
            _loc9_.x = _loc14_;
            _loc9_.y = _loc11_;
            if(_loc8_.hp > 0 && !_loc8_.isAlive)
            {
               _loc8_.relive();
            }
            if(_loc9_.hp > 0 && !_loc8_.isAlive)
            {
               _loc9_.relive();
            }
            LANClientCtrl.I.resetSyncError();
         }
         catch(e:Error)
         {
            LANClientCtrl.I.syncError(true);
         }
         return true;
      }
      
      public function render() : Boolean
      {
         var _loc1_:ByteArray = null;
         if(!enabled)
         {
            return true;
         }
         if(_serverNextFrame == 0 && _serverFrame == 0)
         {
            _loc1_ = new ByteArray();
            _loc1_.writeByte(8);
            _loc1_.writeShort(0);
            _loc1_.writeShort(0);
            LANClientCtrl.I.sendUDP(_loc1_);
            return false;
         }
         if(_clientFrame < _serverNextFrame)
         {
            _clientFrame = _clientFrame + 1;
            renderUpdate();
            InputManager.I.socket_input_p2.renderInput();
            if(_clientFrame % 2 == 0)
            {
               sendCtrl();
            }
            return true;
         }
         return false;
      }
      
      private function sendCtrl() : void
      {
         var _loc1_:int = InputManager.I.socket_input_p2.getSocketData();
         if(_lastSendK == _loc1_ && !_sendAnyWay)
         {
            return;
         }
         _sendAnyWay = false;
         InputManager.I.socket_input_p2.resetInput();
         var _loc2_:ByteArray = new ByteArray();
         _loc2_.writeByte(8);
         _loc2_.writeShort(_clientFrame);
         _loc2_.writeShort(_loc1_);
         LANClientCtrl.I.sendUDP(_loc2_);
         _lastSendK = _loc1_;
      }
      
      private function cacheUpdate() : void
      {
         var _loc1_:int = 0;
         _loc1_ = _serverFrame;
         while(_loc1_ < _serverNextFrame)
         {
            _updateCache[_loc1_] = [_serverK,_clientK];
            _loc1_++;
         }
      }
      
      private function renderUpdate() : void
      {
         var _loc1_:Array = _updateCache[_clientFrame];
         if(_loc1_)
         {
            InputManager.I.socket_input_p1.setSocketData(_loc1_[0]);
            InputManager.I.socket_input_p2.setSocketData(_loc1_[1]);
         }
      }
   }
}

