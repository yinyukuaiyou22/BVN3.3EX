package net.play5d.game.bvn.mob.ctrls
{
   import flash.events.TimerEvent;
   import flash.text.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.mob.data.*;
   import net.play5d.game.bvn.mob.input.*;
   import net.play5d.game.bvn.mob.sockets.*;
   import net.play5d.game.bvn.mob.sockets.events.SocketEvent;
   import net.play5d.game.bvn.mob.sockets.udp.*;
   import net.play5d.game.bvn.mob.utils.*;
   import net.play5d.game.bvn.state.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.kyo.utils.*;
import net.play5d.game.bvn.Debugger;
   
   public class LANClientCtrl
   {
      
      private static var _i:LANClientCtrl;
      
      public var active:Boolean;
      
      private var _delayText:TextField;
      
      private var _socket:SocketClient;
      
      private var _udpSocket:UDPSocket;
      
      private var _host:HostVO;
      
      private var _joinBack:Function;
      
      private var _syncErrorTimes:int;
      
      private var _selectLogic:SelectFighterClientLogic;
      
      private var _connGameLogic:LockFrameClientLogic;
      
      private var _delayCache:Array = [];
      
      private var _syncRoundFinishInt:int;
      
      private var _syncGameFinishInt:int;
      
      private var _syncGameStartInt:int;
      
      private var _onFindHostBack:Function;
      
      private var _findHostTimer:Timer;
      
      public function LANClientCtrl()
      {
         super();
      }
      
      public static function get I() : LANClientCtrl
      {
         if(!_i)
         {
            _i = new LANClientCtrl();
         }
         return _i;
      }
      
      public function initlize() : void
      {
         if(!this._udpSocket)
         {
            this._udpSocket = new UDPSocket();
            this._udpSocket.listen(17478);
            this._udpSocket.addDataHandler(this.udpDataHandler);
         }
      }
      
      public function findHost(param1:Function) : void
      {
         this._onFindHostBack = param1;
         if(!this._findHostTimer)
         {
            this._findHostTimer = new Timer(2000);
            this._findHostTimer.addEventListener("timer",this.findHostTimerHandler);
         }
         this._findHostTimer.reset();
         this._findHostTimer.start();
         this.findHostTimerHandler(null);
      }
      
      public function cancelFindHost() : void
      {
         this._onFindHostBack = null;
         if(Boolean(this._findHostTimer))
         {
            this._findHostTimer.stop();
            this._findHostTimer.removeEventListener("timer",this.findHostTimerHandler);
            this._findHostTimer = null;
         }
      }
      
      private function findHostTimerHandler(param1:TimerEvent) : void
      {
         this._udpSocket.sendBroadcast(17477,SocketMsgFactory.createFindHostMsg());
      }
      
      private function receiveHostHandler(param1:UDPDataVO) : Boolean
      {
         var _loc2_:HostVO = null;
         if(!this._findHostTimer)
         {
            return false;
         }
         var _loc3_:ByteArray = param1.getDataByteArray();
         if(Boolean(_loc3_) && _loc3_.readByte() != 21)
         {
            return false;
         }
         if(this._onFindHostBack != null)
         {
            _loc2_ = new HostVO();
            _loc2_.readByteArray(_loc3_);
            _loc2_.ip = param1.fromIP;
            this._onFindHostBack(_loc2_);
         }
         return true;
      }
      
      private function udpDataHandler(param1:UDPDataVO) : void
      {
         if(this.receiveHostHandler(param1))
         {
            return;
         }
         if(Boolean(this._connGameLogic))
         {
            if(this._connGameLogic.receiveSyncUpdate(param1.getDataByteArray()))
            {
               return;
            }
            if(this._connGameLogic.receiveUpdate(param1.getDataByteArray()))
            {
               return;
            }
         }
      }
      
      public function updateDelay(param1:int) : void
      {
         var _loc5_:* = undefined;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:* = 0;
         if(!this._delayText)
         {
            return;
         }
         this._delayCache.push(param1);
         if(this._delayCache.length >= 10)
         {
            _loc2_ = 0;
            for each(_loc5_ in this._delayCache)
            {
               _loc2_ += _loc5_;
            }
            _loc3_ = _loc2_ / this._delayCache.length;
            _loc3_ -= 200;
            if(_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            this._delayCache = [];
            _loc4_ = 16711680;
            if(_loc3_ < 200)
            {
               _loc4_ = 65280;
            }
            else if(_loc3_ < 500)
            {
               _loc4_ = 16776960;
            }
            this._delayText.text = _loc3_ + " ms";
            this._delayText.textColor = _loc4_;
         }
      }
      
      public function join(param1:HostVO, param2:Function) : void
      {
         this._host = param1;
         this._joinBack = param2;
         this.initTcp(param1);
      }
      
      private function initTcp(param1:HostVO) : void
      {
         if(Boolean(this._socket))
         {
            this.dispose();
         }
         this._socket = new SocketClient();
         this._socket.addEventListener("SocketEvent_CLIENT_CONNECT",this.socketHandler);
         this._socket.addEventListener("SocketEvent_CLOSE",this.socketHandler);
         this._socket.addEventListener("SocketEvent_RECEIVE_DATA",this.socketHandler);
         this._socket.connect(param1.ip,17511);
      }
      
      public function sendJoinIn() : void
      {
         this._socket.sendJSON(SocketMsgFactory.createJoinInMsg());
      }
      
      public function dispose() : void
      {
         this.cancelFindHost();
         this.disposeTcp();
         this.disposeUdp();
         GameEvent.removeEventListener("GAME_START",this.onRoundStart);
      }
      
      private function disposeTcp() : void
      {
         if(Boolean(this._socket))
         {
            this._socket.removeEventListener("SocketEvent_CLIENT_CONNECT",this.socketHandler);
            this._socket.removeEventListener("SocketEvent_CLOSE",this.socketHandler);
            this._socket.removeEventListener("SocketEvent_RECEIVE_DATA",this.socketHandler);
            this._socket.close();
            this._socket = null;
         }
      }
      
      private function disposeUdp() : void
      {
         if(Boolean(this._udpSocket))
         {
            this._udpSocket.unListen();
            this._udpSocket.removeDataHandler(this.udpDataHandler);
            this._udpSocket = null;
         }
      }
      
      private function socketHandler(param1:SocketEvent) : void
      {
         switch(param1.type)
         {
            case "SocketEvent_CLIENT_CONNECT":
               this._socket.sendJSON(SocketMsgFactory.createJoinMsg());
               break;
            case "SocketEvent_CLOSE":
               if(this.active)
               {
                  this.gameEnd();
                  GameUI.alert("DISCONNECT","与主机断开连接");
               }
               else
               {
                  this.dispose();
               }
               break;
            case "SocketEvent_RECEIVE_DATA":
               this.onReceiveData(param1);
         }
      }
      
      private function onReceiveData(param1:SocketEvent) : void
      {
         var _loc2_:Object = param1.getDataObject();
         if(!_loc2_)
         {
            return;
         }
         if(Boolean(this._selectLogic) && Boolean(this._selectLogic.receiveSelect(_loc2_)))
         {
            return;
         }
         if(this.receiveSync(_loc2_))
         {
            return;
         }
         var _loc3_:Object = JsonUtils.str2json(_loc2_);
         if(Boolean(_loc3_))
         {
            this.receiveJson(_loc3_);
         }
      }
      
      private function receiveJson(param1:Object) : void
      {
         var _loc2_:Boolean = false;
         switch(param1.type)
         {
            case "JOIN_BACK":
               _loc2_ = Boolean(param1.success);
               if(this._joinBack != null)
               {
                  this._joinBack(_loc2_);
                  this._joinBack = null;
               }
               if(!_loc2_)
               {
                  this.dispose();
               }
               break;
            case "START_GAME":
               this.gameStart(this._host);
         }
      }
      
      public function sendTCP(param1:Object) : void
      {
         if(Boolean(this._socket))
         {
            this._socket.send(param1);
         }
      }
      
      public function sendUDP(param1:Object) : void
      {
         if(Boolean(this._udpSocket))
         {
            this._udpSocket.send(this._host.ip,17477,param1);
         }
      }
      
      public function gameStart(param1:HostVO) : void
      {
         this.active = true;
         this._delayText = new TextField();
         this._delayText.text = "0ms";
         var _loc2_:TextFormat = new TextFormat();
         _loc2_.color = 16777215;
         _loc2_.size = 16;
         this._delayText.defaultTextFormat = _loc2_;
         MainGame.I.stage.addChild(this._delayText);
         this._selectLogic = new SelectFighterClientLogic();
         this._selectLogic.init();
         this._connGameLogic = new LockFrameClientLogic();
         GameCtrl.I.autoEndRoundAble = false;
         GameCtrl.I.autoStartAble = false;
         SelectFighterStage.AUTO_FINISH = false;
         LoadingState.AUTO_START_GAME = false;
         GameInterface.instance.updateInputConfig();
         LockFrameLogic.I.initClient();
         GameEvent.addEventListener("ROUND_START",this.onRoundStart);
         LANGameCtrl.I.gameStart(param1);
      }
      
      private function onRoundStart(param1:GameEvent) : void
      {
         this._connGameLogic.enabled = true;
      }
      
      public function gameEnd() : void
      {
         this.active = false;
         if(Boolean(this._selectLogic))
         {
            this._selectLogic.dispose();
            this._selectLogic = null;
         }
         if(Boolean(this._connGameLogic))
         {
            this._connGameLogic.dispose();
            this._connGameLogic = null;
         }
         if(Boolean(this._delayText))
         {
            try
            {
               this._delayText.parent.removeChild(this._delayText);
            }
            catch(e:Error)
            {
               Debugger.log(e);
            }
            this._delayText = null;
         }
         GameCtrl.I.autoEndRoundAble = true;
         GameCtrl.I.autoStartAble = true;
         SelectFighterStage.AUTO_FINISH = true;
         LoadingState.AUTO_START_GAME = true;
         GameInterface.instance.updateInputConfig();
         LockFrameLogic.I.dispose();
         this.dispose();
         LANGameCtrl.I.gameEnd();
      }
      
      public function renderGame() : Boolean
      {
         if(MainGame.stageCtrl.currentStage is GameState)
         {
            return this._connGameLogic.render();
         }
         InputManager.I.socket_input_p2.freeRender();
         return true;
      }
      
      private function receiveSync(param1:Object) : Boolean
      {
         var arr:Array = null;
         var type:int = 0;
         var o:Object = param1;
         if(o is Array)
         {
            arr = o as Array;
            if(arr[0] == "SYNC")
            {
               Debugger.log("receiveSync",JSON.stringify(o));
               type = int(arr[1]);
               switch(type - 3)
               {
                  case 0:
                     this.syncStartGame();
                     break;
                  case 1:
                     this.syncGameFinish();
                     break;
                  case 4:
                     this._connGameLogic.enabled = false;
                     this._connGameLogic.reset();
                     setFrameOut(function():void
                     {
                        syncRoundFinish(arr);
                     },1,MainGame.I.stage);
               }
               return true;
            }
         }
         return false;
      }
      
      private function syncStartGame() : void
      {
         try
         {
            GameCtrl.I.doStartGame();
            this._syncErrorTimes = 0;
            this._connGameLogic.enabled = true;
            this._connGameLogic.reset();
         }
         catch(e:Error)
         {
            Debugger.log("LanSyncType.GAME_START",e);
            syncError(true);
            clearTimeout(_syncGameStartInt);
            _syncGameStartInt = setTimeout(syncStartGame,500);
         }
      }
      
      private function syncRoundFinish(param1:Array) : void
      {
         var _loc7_:FighterMain = null;
         var _loc5_:FighterMain = null;
         var _loc3_:FighterMain = null;
         var _loc9_:FighterMain = null;
         var _loc10_:int = int(param1[2]);
         var _loc4_:Boolean = Boolean(param1[3]);
         var _loc6_:Boolean = Boolean(param1[4]);
         var _loc2_:int = int(param1[5]);
         var _loc8_:int = int(param1[6]);
         try
         {
            if(GameCtrl.I.gameRunData.round != _loc10_)
            {
               this.syncError(true);
               clearTimeout(this._syncRoundFinishInt);
               this._syncRoundFinishInt = setTimeout(this.syncRoundFinish,500,param1);
               return;
            }
            if(_loc4_)
            {
               GameCtrl.I.gameRunData.isTimerOver = true;
               GameCtrl.I.gameRunData.gameTime = 0;
            }
            _loc7_ = GameCtrl.I.gameRunData.p1FighterGroup.currentFighter;
            _loc5_ = GameCtrl.I.gameRunData.p2FighterGroup.currentFighter;
            _loc7_.hp = _loc2_;
            _loc5_.hp = _loc8_;
            if(_loc6_)
            {
               GameCtrl.I.drawGame();
            }
            else
            {
               if(_loc7_.hp > _loc5_.hp)
               {
                  _loc9_ = _loc7_;
                  _loc3_ = _loc5_;
               }
               else
               {
                  _loc9_ = _loc5_;
                  _loc3_ = _loc7_;
               }
               if(!_loc4_)
               {
                  _loc3_.die();
               }
               GameCtrl.I.doGameEnd(_loc9_,_loc3_);
            }
            this._syncErrorTimes = 0;
         }
         catch(e:Error)
         {
            Debugger.log(e);
            syncError(true);
            clearTimeout(_syncRoundFinishInt);
            _syncRoundFinishInt = setTimeout(syncRoundFinish,500,param1);
         }
      }
      
      private function syncGameFinish() : void
      {
         this._connGameLogic.enabled = false;
         this._connGameLogic.reset();
         if(!GameCtrl.I.fightFinished)
         {
            try
            {
               GameCtrl.I.fightFinish();
            }
            catch(e:Error)
            {
               syncError(true);
               clearTimeout(_syncGameFinishInt);
               _syncGameFinishInt = setTimeout(syncGameFinish,500);
            }
         }
      }
      
      public function resetSyncError() : void
      {
         this._syncErrorTimes = 0;
      }
      
      public function syncError(param1:Boolean = false) : void
      {
         if(!param1)
         {
            this.gameEnd();
            GameUI.alert("DISCONNECT","发生异常");
            return;
         }
         this._syncErrorTimes += 1;
         if(this._syncErrorTimes > 10)
         {
            this.gameEnd();
            GameUI.alert("DISCONNECT","发生异常");
         }
      }
   }
}

