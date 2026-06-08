package net.play5d.game.bvn.mob.views.lan
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.mob.screenpad.*;
   import net.play5d.game.bvn.mob.utils.*;
   import net.play5d.kyo.stage.*;
   import net.play5d.kyo.stage.effect.*;
   
   public class LANHostCreateDialog implements Istage
   {
      
      private var _ui:MovieClip;
      
      private var _settingData:Array = [{
         "title":"游戏模式",
         "en":"Game Mode",
         "key":"game_mode",
         "options":[{
            "name":"小队",
            "en":"Team vs",
            "value":1
         },{
            "name":"单人",
            "en":"Single vs",
            "value":2
         }]
      },{
         "title":"回合时间",
         "en":"Game Time",
         "key":"game_time",
         "options":[{
            "name":"60",
            "en":"60",
            "value":60
         },{
            "name":"90",
            "en":"90",
            "value":90
         }]
      },{
         "title":"人物血量",
         "en":"HP",
         "key":"hp",
         "options":[{
            "name":"100%",
            "en":"100%",
            "value":1
         },{
            "name":"200%",
            "en":"200%",
            "value":2
         }]
      }];
      
      private var _setItems:Array;
      
      public var onClose:Function;
      
      public var onOK:Function;
      
      public var setting:Object = {};
      
      private var _isOK:Boolean;
      
      public function LANHostCreateDialog()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function close() : void
      {
         MainGame.stageCtrl.removeLayer(this,new ZoomEffect(0.2),function():void
         {
            if(_isOK)
            {
               if(onOK != null)
               {
                  onOK();
               }
            }
            if(onClose != null)
            {
               onClose();
            }
         });
      }
      
      public function build() : void
      {
         this._ui = UIAssetUtil.I.createDisplayObject("dialog_host");
         this.buildItems();
         ScreenPadManager.addTouchListener(this._ui.btn_ok,this.okHandler);
         ScreenPadManager.addTouchListener(this._ui.btn_back,this.backHandler);
      }
      
      private function buildItems() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Object = null;
         var _loc3_:HostDialogItem = null;
         this._setItems = [];
         while(_loc1_ < this._settingData.length)
         {
            _loc2_ = this._settingData[_loc1_];
            _loc3_ = new HostDialogItem(_loc2_);
            _loc3_.ui.x = 100;
            _loc3_.ui.y = 50 + _loc1_ * 100;
            this._ui.addChild(_loc3_.ui);
            this._setItems.push(_loc3_);
            _loc1_++;
         }
      }
      
      private function okHandler(param1:DisplayObject) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:Object = null;
         for each(_loc3_ in this._setItems)
         {
            _loc2_ = _loc3_.getSelectData();
            this.setting[_loc2_.key] = _loc2_.value;
         }
         this._isOK = true;
         SoundCtrl.I.sndConfrim();
         this.close();
      }
      
      private function backHandler(param1:DisplayObject) : void
      {
         SoundCtrl.I.sndSelect();
         this.close();
      }
      
      private function checkHandler(param1:Event) : void
      {
         this._ui.txt_pass.visible = this._ui.check_pass.selected;
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         ScreenPadManager.removeTouchListener(this._ui.btn_ok);
         ScreenPadManager.removeTouchListener(this._ui.btn_back);
      }
   }
}

