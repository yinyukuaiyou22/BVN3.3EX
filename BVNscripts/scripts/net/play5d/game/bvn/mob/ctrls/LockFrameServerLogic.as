package net.play5d.game.bvn.mob.ctrls
{
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.GameRunDataVO;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.mob.input.*;
   import net.play5d.game.bvn.mob.utils.*;
   import net.play5d.game.bvn.state.*;
   import net.play5d.kyo.stage.Istage;
   
   public class LockFrameServerLogic
   {
      
      public var enabled:Boolean = true;
      
      private var _clientFrame:int;
      
      private var _renderFrame:int;
      
      private var _renderNextFrame:int;
      
      private var _renderSyncFrame:int;
      
      private var _clientK:int = -1;
      
      private var _serverK:int = 0;
      
      private var _syncUpdateArr:ByteArray;
      
      private var _sendUpdateFrame:int;
      
      private var _sendUpdateSyncFrame:int;
      
      private var _updateCache:Object = {};
      
      public function LockFrameServerLogic()
      {
         super();
      }
      
      public function reset() : void
      {
         this._renderFrame = 0;
         this._renderNextFrame = 0;
         this._clientK = -1;
         this._serverK = 0;
         this._syncUpdateArr = null;
         this._sendUpdateFrame = 0;
      }
      
      public function dispose() : void
      {
      }
      
      public function render() : Boolean
      {
         if(!this.enabled)
         {
            return true;
         }
         if(this._clientK == -1)
         {
            return false;
         }
         if(this._renderFrame > this._clientFrame + LANUtils.LOCK_KEYFRAME)
         {
            if(this._sendUpdateFrame == 0)
            {
               this.sendUpdate();
            }
            if(this._sendUpdateSyncFrame == 0)
            {
               this.sendSyncUpdate();
            }
            if(++this._sendUpdateFrame > LANUtils.LOCK_KEYFRAME)
            {
               this._sendUpdateFrame = 0;
            }
            if(++this._sendUpdateSyncFrame > LANUtils.SYNC_GAP)
            {
               this._sendUpdateSyncFrame = 0;
            }
            return false;
         }
         InputManager.I.socket_input_p1.renderInput();
         if(this._renderFrame % LANUtils.LOCK_KEYFRAME == 0)
         {
            if(Boolean(this._syncUpdateArr))
            {
               this.sendSyncUpdate();
               this._renderSyncFrame = 0;
               this._syncUpdateArr = null;
            }
            this.sendUpdate();
         }
         this._renderFrame += 1;
         this._renderSyncFrame += 1;
         this.renderUpdate();
         if(this._renderSyncFrame > LANUtils.SYNC_GAP)
         {
            this._syncUpdateArr = this.getSyncUpdate();
         }
         return true;
      }
      
      private function sendStart() : void
      {
         var _loc1_:Array = [this._serverK,0];
         LANServerCtrl.I.sendTCP(_loc1_);
      }
      
      public function receiveInput(param1:ByteArray) : Boolean
      {
         if(!param1)
         {
            return false;
         }
         param1.position = 0;
         var _loc2_:int = param1.readByte();
         if(_loc2_ != 8)
         {
            return false;
         }
         this._clientFrame = param1.readShort();
         this._clientK = param1.readShort();
         return true;
      }
      
      private function sendUpdate() : void
      {
         this._renderNextFrame = this._renderFrame + LANUtils.LOCK_KEYFRAME;
         this._serverK = InputManager.I.socket_input_p1.getSocketData();
         InputManager.I.socket_input_p1.resetInput();
         var _loc1_:ByteArray = new ByteArray();
         _loc1_.writeByte(9);
         _loc1_.writeShort(this._renderFrame);
         _loc1_.writeShort(this._serverK);
         _loc1_.writeShort(this._clientK);
         LANServerCtrl.I.sendUDP(_loc1_);
         this.cacheUpdate();
      }
      
      private function sendSyncUpdate() : void
      {
         if(!this._syncUpdateArr)
         {
            return;
         }
         this._updateCache = {};
         LANServerCtrl.I.sendUDP(this._syncUpdateArr);
      }
      
      private function getSyncUpdate() : ByteArray
      {
         var _loc1_:GameRunDataVO = null;
         var _loc2_:FighterMain = null;
         var _loc3_:FighterMain = null;
         var _loc4_:ByteArray = null;
         var _loc5_:Istage = MainGame.stageCtrl.currentStage;
         if(_loc5_ is GameState)
         {
            if(GameCtrl.I.actionEnable)
            {
               _loc1_ = GameCtrl.I.gameRunData;
               _loc2_ = _loc1_.p1FighterGroup.currentFighter;
               _loc3_ = _loc1_.p2FighterGroup.currentFighter;
               _loc4_ = new ByteArray();
               _loc4_.writeByte(10);
               _loc4_.writeShort(this._renderFrame);
               _loc4_.writeByte(_loc1_.round);
               _loc4_.writeByte(_loc1_.gameTime);
               _loc4_.writeShort(_loc2_.hp << 0);
               _loc4_.writeShort(_loc2_.qi << 0);
               _loc4_.writeShort(_loc2_.x << 0);
               _loc4_.writeShort(_loc2_.y << 0);
               _loc4_.writeShort(_loc3_.hp << 0);
               _loc4_.writeShort(_loc3_.qi << 0);
               _loc4_.writeShort(_loc3_.x << 0);
               _loc4_.writeShort(_loc3_.y << 0);
               return _loc4_;
            }
         }
         return null;
      }
      
      private function cacheUpdate() : void
      {
         var _loc1_:int = 0;
         _loc1_ = int(this._renderFrame);
         while(_loc1_ < this._renderNextFrame)
         {
            this._updateCache[_loc1_] = [this._serverK,this._clientK];
            _loc1_++;
         }
      }
      
      private function renderUpdate() : void
      {
         var _loc1_:Array = this._updateCache[this._renderFrame];
         if(Boolean(_loc1_))
         {
            InputManager.I.socket_input_p1.setSocketData(_loc1_[0]);
            InputManager.I.socket_input_p2.setSocketData(_loc1_[1]);
         }
      }
   }
}

