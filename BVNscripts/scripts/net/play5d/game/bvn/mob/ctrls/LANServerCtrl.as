package net.play5d.game.bvn.mob.ctrls
{
   import flash.events.EventDispatcher;
   import flash.net.Socket;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.GameRunDataVO;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.mob.data.*;
   import net.play5d.game.bvn.mob.events.*;
   import net.play5d.game.bvn.mob.input.*;
   import net.play5d.game.bvn.mob.sockets.*;
   import net.play5d.game.bvn.mob.sockets.events.SocketEvent;
   import net.play5d.game.bvn.mob.sockets.udp.*;
   import net.play5d.game.bvn.mob.utils.*;
   import net.play5d.game.bvn.state.*;
   import net.play5d.game.bvn.ui.*;
import net.play5d.game.bvn.Debugger;
   
   public class LANServerCtrl extends EventDispatcher
   {
      
      private static var _i:LANServerCtrl;
      
      public var active:Boolean;
      
      private var _clientK:int;
      
      private var _serverK:int;
      
      private var _clients:Vector.<ClientVO> = new Vector.<ClientVO>();
      
      private var _udpClientIP:String;
      
      private var _host:HostVO;
      
      private var _renderFrame:uint;
      
      private var _renderFrameClient:uint;
      
      private var _renderNextFrame:uint;
      
      private var _renderSyncFrame:int;
      
      private var _sendUpdateFrame:int;
      
      private var _selectLogic:SelectFighterServerLogic;
      
      private var _connGameLogic:LockFrameServerLogic;
      
      private var _playerClient:ClientVO;
      
      private var _udpSocket:UDPSocket;
      
      public function LANServerCtrl()
      {
         super();
      }
      
      public static function get I() : LANServerCtrl
      {
         if(!_i)
         {
            _i = new LANServerCtrl();
         }
         return _i;
      }
      
      public function get host() : HostVO
      {
         return this._host;
      }
      
      public function startServer(param1:HostVO) : void
      {
         this._host = param1;
         SocketServer.I.bind(17511);
         SocketServer.I.addEventListener("SocketEvent_CLIENT_CONNECT",this.socketHandler);
         SocketServer.I.addEventListener("SocketEvent_CLIENT_DIS_CONNECT",this.socketHandler);
         SocketServer.I.addEventListener("SocketEvent_RECEIVE_DATA",this.socketDataHandler);
         this._udpSocket = new UDPSocket();
         this._udpSocket.listen(17477);
         this._udpSocket.addDataHandler(this.udpDataHandler);
      }
      
      public function stopServer() : void
      {
         this._host = null;
         SocketServer.I.close();
         SocketServer.I.removeEventListener("SocketEvent_CLIENT_CONNECT",this.socketHandler);
         SocketServer.I.removeEventListener("SocketEvent_CLIENT_DIS_CONNECT",this.socketHandler);
         SocketServer.I.removeEventListener("SocketEvent_RECEIVE_DATA",this.socketDataHandler);
         if(Boolean(this._udpSocket))
         {
            this._udpSocket.unListen();
            this._udpSocket.removeDataHandler(this.udpDataHandler);
            this._udpSocket = null;
         }
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
         this._clients = new Vector.<ClientVO>();
         this._host = null;
         this._udpClientIP = null;
      }
      
      private function udpDataHandler(param1:UDPDataVO) : void
      {
         var _loc2_:ByteArray = param1.getDataByteArray();
         if(Boolean(_loc2_) && _loc2_.readByte() == 20)
         {
            if(!this.active)
            {
               this._udpSocket.send(param1.fromIP,17478,SocketMsgFactory.createFindHostBackMsg());
            }
            return;
         }
         if(Boolean(this._connGameLogic) && Boolean(this._connGameLogic.receiveInput(_loc2_)))
         {
            this._udpClientIP = param1.fromIP;
            return;
         }
      }
      
      private function socketHandler(param1:SocketEvent) : void
      {
         Debugger.log(param1);
         switch(param1.type)
         {
            case "SocketEvent_CLIENT_CONNECT":
               break;
            case "SocketEvent_CLIENT_DIS_CONNECT":
               if(this.active)
               {
                  this.gameEnd();
                  GameUI.alert("PLAYER EXIT","玩家退出房间");
               }
               this._udpClientIP = null;
         }
      }
      
      private function socketDataHandler(param1:SocketEvent) : void
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
         var _loc3_:Object = JsonUtils.str2json(_loc2_);
         if(Boolean(_loc3_))
         {
            this.receiveJson(_loc3_,param1.clientSocket);
         }
      }
      
      private function receiveJson(param1:Object, param2:Socket) : void
      {
         switch(param1.type)
         {
            case "JOIN":
               this.receiveJoin(param1,param2);
               break;
            case "JOIN_IN":
         }
      }
      
      private function receiveJoin(param1:Object, param2:Socket) : void
      {
         if(this._clients.length > 0)
         {
            SocketServer.I.sendJson(param2,SocketMsgFactory.createJoinFailMsg("人数已满"));
            return;
         }
         var _loc3_:ClientVO = new ClientVO();
         _loc3_.ip = param2.remoteAddress;
         _loc3_.name = param1.name;
         _loc3_.socket = param2;
         this._clients.push(_loc3_);
         this._playerClient = _loc3_;
         SocketServer.I.sendJson(_loc3_.socket,SocketMsgFactory.createJoinSuccMsg());
         dispatchEvent(new LanEvent("CLIENT_JOIN_SUCCESS"));
      }
      
      private function findClient(param1:Socket) : ClientVO
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in this._clients)
         {
            if(_loc2_.socket == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      public function gameStart() : void
      {
         this.active = true;
         GameInterface.instance.updateInputConfig();
         LockFrameLogic.I.initServer();
         this._renderFrame = 1;
         this._selectLogic = new SelectFighterServerLogic();
         this._selectLogic.init();
         this._connGameLogic = new LockFrameServerLogic();
         this.initSyncEvent();
         LANGameCtrl.I.gameStart(this._host);
      }
      
      public function gameEnd() : void
      {
         this.active = false;
         GameInterface.instance.updateInputConfig();
         LockFrameLogic.I.dispose();
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
         this.disposeSyncEvent();
         LANGameCtrl.I.gameEnd();
         this.gameQuit();
      }
      
      public function gameQuit() : void
      {
         this.active = false;
         GameInterface.instance.updateInputConfig();
         LockFrameLogic.I.dispose();
         this.disposeSyncEvent();
         LanGameMenuCtrl.I.dispose();
         this.stopServer();
         MainGame.stageCtrl.goStage(new MenuState());
      }
      
      private function initSyncEvent() : void
      {
         GameEvent.addEventListener("ROUND_END",this.onGameRoundEnd);
         GameEvent.addEventListener("GAME_START",this.onGameStart);
         GameEvent.addEventListener("GAME_END",this.onGameEnd);
         GameEvent.addEventListener("ROUND_START",this.onRoundStart);
      }
      
      private function disposeSyncEvent() : void
      {
         GameEvent.removeEventListener("ROUND_END",this.onGameRoundEnd);
         GameEvent.removeEventListener("GAME_START",this.onGameStart);
         GameEvent.removeEventListener("GAME_END",this.onGameEnd);
         GameEvent.removeEventListener("ROUND_START",this.onRoundStart);
      }
      
      public function renderGame() : Boolean
      {
         if(MainGame.stageCtrl.currentStage is GameState)
         {
            return this._connGameLogic.render();
         }
         InputManager.I.socket_input_p1.freeRender();
         return true;
      }
      
      private function onGameStart(param1:GameEvent) : void
      {
         this._connGameLogic.enabled = true;
         this._connGameLogic.reset();
         var _loc2_:Array = ["SYNC",3];
         this.sendTCP(_loc2_);
      }
      
      private function onGameEnd(param1:GameEvent) : void
      {
         this._connGameLogic.enabled = false;
         this._connGameLogic.reset();
         var _loc2_:Array = ["SYNC",4];
         this.sendTCP(_loc2_);
      }
      
      private function onRoundStart(param1:GameEvent) : void
      {
         this._connGameLogic.enabled = true;
      }
      
      private function onGameRoundEnd(param1:GameEvent) : void
      {
         var _loc2_:GameRunDataVO = GameCtrl.I.gameRunData;
         var _loc3_:FighterMain = _loc2_.p1FighterGroup.currentFighter;
         var _loc4_:FighterMain = _loc2_.p2FighterGroup.currentFighter;
         var _loc5_:Array = ["SYNC",7,_loc2_.round,_loc2_.isTimerOver,_loc2_.isDrawGame,_loc3_.hp << 0,_loc4_.hp << 0];
         this.sendTCP(_loc5_);
         this._connGameLogic.enabled = false;
         this._connGameLogic.reset();
      }
      
      public function sendGameStart() : void
      {
         var _loc2_:* = undefined;
         var _loc1_:Object = SocketMsgFactory.createStartGame();
         for each(_loc2_ in this._clients)
         {
            SocketServer.I.sendJson(_loc2_.socket,_loc1_);
         }
      }
      
      public function sendTCP(param1:Object) : void
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in this._clients)
         {
            SocketServer.I.send(_loc2_.socket,param1);
         }
      }
      
      public function sendUDP(param1:Object) : void
      {
         if(Boolean(this._udpClientIP))
         {
            this._udpSocket.send(this._udpClientIP,17478,param1);
         }
      }
   }
}

