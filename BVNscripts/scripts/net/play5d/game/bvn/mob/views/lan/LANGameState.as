package net.play5d.game.bvn.mob.views.lan
{
   import com.greensock.*;
   import com.greensock.easing.*;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.mob.ctrls.*;
   import net.play5d.game.bvn.mob.data.*;
   import net.play5d.game.bvn.mob.events.LanEvent;
   import net.play5d.game.bvn.mob.screenpad.*;
   import net.play5d.game.bvn.mob.utils.*;
   import net.play5d.kyo.stage.*;
   import net.play5d.kyo.stage.effect.*;
   
   public class LANGameState implements Istage
   {
      
      private var _ui:MovieClip;
      
      public function LANGameState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         this._ui = UIAssetUtil.I.createDisplayObject("spr_lan");
         SoundCtrl.I.BGM(AssetManager.I.getSound("continue"));
         this.mainMenu();
      }
      
      private function mainMenu() : void
      {
         var initMainMenu:* = undefined;
         initMainMenu = function(param1:Event):void
         {
            _ui.removeEventListener("complete",initMainMenu);
            ScreenPadManager.addTouchListener(_ui.btn1,mainBtnHandler);
            ScreenPadManager.addTouchListener(_ui.btn2,mainBtnHandler);
            ScreenPadManager.addTouchListener(_ui.btn_back,mainBtnHandler);
         };
         this._ui.gotoAndPlay(1);
         this._ui.addEventListener("complete",initMainMenu);
      }
      
      private function btnTouchEffect(param1:DisplayObject, param2:Function = null, param3:Boolean = true) : void
      {
         if(!param1.visible)
         {
            return;
         }
         if(param3)
         {
            SoundCtrl.I.sndSelect();
         }
         var _loc4_:Number = param1.scaleX;
         var _loc5_:Number = param1.scaleY;
         var _loc6_:Number = param1.alpha;
         param1.scaleX = _loc4_ * 0.8;
         param1.scaleY = _loc5_ * 0.8;
         param1.alpha = _loc6_ * 0.8;
         TweenLite.to(param1,0.3,{
            "scaleX":_loc4_,
            "scaleY":_loc5_,
            "alpha":_loc6_,
            "ease":Back.easeOut,
            "onComplete":param2
         });
      }
      
      private function mainBtnHandler(param1:DisplayObject) : void
      {
         var target:DisplayObject = null;
         target = param1;
         var effectBack:* = function():void
         {
            switch(target)
            {
               case _ui.btn1:
                  showHostDialog();
                  break;
               case _ui.btn2:
                  runClient();
                  break;
               case _ui.btn_back:
                  MainGame.I.goMenu();
            }
         };
         this.btnTouchEffect(target,effectBack);
      }
      
      private function showHostDialog() : void
      {
         var dialog:LANHostCreateDialog = null;
         var onDialogClose:* = function():void
         {
            dialog = null;
            try
            {
               _ui.btn1.visible = true;
               _ui.btn2.visible = true;
               _ui.btn_back.visible = true;
               _ui.label_host.visible = true;
               _ui.label_client.visible = true;
               _ui.label_back.visible = true;
            }
            catch(e:Error)
            {
               trace(e);
            }
         };
         var onDialogOK:* = function():void
         {
            runHost(dialog.setting);
         };
         dialog = new LANHostCreateDialog();
         dialog.onOK = onDialogOK;
         dialog.onClose = onDialogClose;
         MainGame.stageCtrl.addLayer(dialog,30,100,false,new ZoomEffect());
         try
         {
            this._ui.btn1.visible = false;
            this._ui.btn2.visible = false;
            this._ui.btn_back.visible = false;
            this._ui.label_host.visible = false;
            this._ui.label_client.visible = false;
            this._ui.label_back.visible = false;
         }
         catch(e:Error)
         {
            trace(e);
         }
      }
      
      private function runHost(param1:Object) : void
      {
         var setting:Object = null;
         var hostCom1:* = undefined;
         var hostConnect:* = undefined;
         var hostCom2:* = undefined;
         setting = param1;
         hostCom1 = function(param1:Event):void
         {
            _ui.removeEventListener("complete",hostCom1);
            ScreenPadManager.addTouchListener(_ui.btn_back,backHandler);
            trace(setting);
            var _loc2_:HostVO = new HostVO();
            _loc2_.gameMode = setting.game_mode;
            _loc2_.gameTime = setting.game_time;
            _loc2_.hp = setting.hp;
            LANServerCtrl.I.startServer(_loc2_);
            LANServerCtrl.I.addEventListener("CLIENT_JOIN_SUCCESS",hostConnect);
         };
         hostConnect = function(param1:LanEvent):void
         {
            _ui.addEventListener("complete",hostCom2);
            _ui.gotoAndPlay("conn_host_ready");
         };
         hostCom2 = function(param1:Event):void
         {
            _ui.removeEventListener("complete",hostCom2);
            ScreenPadManager.addTouchListener(_ui.btn,startGameHost);
            ScreenPadManager.addTouchListener(_ui.btn_back,backHandler);
         };
         this._ui.addEventListener("complete",hostCom1);
         this._ui.gotoAndPlay("conn_host");
      }
      
      private function runClient() : void
      {
         var clientCom1:* = undefined;
         var findHostHandler:* = undefined;
         var joinHostBack:* = undefined;
         var clientCom2:* = undefined;
         clientCom1 = function(param1:Event):void
         {
            _ui.removeEventListener("complete",clientCom1);
            ScreenPadManager.addTouchListener(_ui.btn_back,backHandler);
            LANClientCtrl.I.initlize();
            LANClientCtrl.I.findHost(findHostHandler);
         };
         findHostHandler = function(param1:HostVO):void
         {
            LANClientCtrl.I.cancelFindHost();
            LANClientCtrl.I.join(param1,joinHostBack);
         };
         joinHostBack = function(param1:Boolean):void
         {
            if(param1)
            {
               clientConnect();
            }
            else
            {
               LANClientCtrl.I.findHost(findHostHandler);
            }
         };
         var clientConnect:* = function():void
         {
            _ui.addEventListener("complete",clientCom2);
            _ui.gotoAndPlay("conn_client_ready");
         };
         clientCom2 = function(param1:Event):void
         {
            _ui.removeEventListener("complete",clientCom2);
            ScreenPadManager.addTouchListener(_ui.btn_back,backHandler);
         };
         this._ui.addEventListener("complete",clientCom1);
         this._ui.gotoAndPlay("conn_client");
      }
      
      private function backHandler(param1:DisplayObject) : void
      {
         LANClientCtrl.I.dispose();
         LANServerCtrl.I.stopServer();
         ScreenPadManager.removeTouchListener(this._ui.btn_back);
         this.btnTouchEffect(param1,this.mainMenu);
      }
      
      private function startGameHost(param1:DisplayObject) : void
      {
         trace("startGameHost");
         this.btnTouchEffect(param1,null,false);
         SoundCtrl.I.sndConfrim();
         LANServerCtrl.I.sendGameStart();
         LANServerCtrl.I.gameStart();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         ScreenPadManager.clearTouchListener();
      }
   }
}

