package net.play5d.game.bvn.state
{
   import flash.display.*;
   import flash.text.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   
   public class MenuState extends Sprite implements Istage
   {
      
      private var _ui:*;
      
      private var _btnGroup:MenuBtnGroup;
      
      private var _versionTxt:TextField;
      
      public function MenuState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.title,ResUtils.TITLE);
         this._ui.gotoAndStop(1);
         GameInterface.instance.initTitleUI(this._ui);
         GameInputer.enabled = false;
         SoundCtrl.I.BGM(AssetManager.I.getSound("op"));
      }
      
      public function afterBuild() : void
      {
         this._ui.gotoAndPlay(2);
         setTimeout(function():void
         {
            _ui.buttonMode = true;
            _ui.useHandCursor = true;
            if(GameConfig.TOUCH_MODE)
            {
               _ui.addEventListener("touchTap",showBtns);
            }
            else
            {
               _ui.addEventListener("click",showBtns);
            }
            GameRender.add(render);
            GameInputer.focus();
            GameInputer.enabled = true;
         },500);
         this._versionTxt = new TextField();
         UIUtils.formatText(this._versionTxt,{
            "color":0,
            "size":18
         });
         this._versionTxt.text = "V3.3";
         this._versionTxt.autoSize = "left";
         this._versionTxt.x = GameConfig.GAME_SIZE.x - this._versionTxt.width - 15;
         this._versionTxt.y = GameConfig.GAME_SIZE.y - this._versionTxt.height - 10;
         this._ui.addChild(this._versionTxt);
         if(Boolean(GameData.I.isFristRun) && Boolean(MainGame.UPDATE_INFO))
         {
            GameData.I.isFristRun = false;
            GameUI.alert("UPDATE",MainGame.UPDATE_INFO);
         }
      }
      
      private function render() : void
      {
         if(GameInputer.anyKey(1))
         {
            this.showBtns();
         }
      }
      
      private function showBtns(... rest) : void
      {
         var ct:Sprite = null;
         var params:Array = rest;
         this._ui.removeEventListener("click",this.showBtns);
         this._ui.removeEventListener("touchTap",this.showBtns);
         GameRender.remove(this.render);
         this._ui.buttonMode = false;
         this._ui.useHandCursor = false;
         this._ui.gotoAndPlay("menu");
         SoundCtrl.I.playSwcSound(snd_menu5);
         this._btnGroup = new MenuBtnGroup();
         this._btnGroup.enabled = false;
         this._btnGroup.x = 470;
         this._btnGroup.y = 100;
         ct = this._ui.getChildByName("btnct") as Sprite;
         if(Boolean(ct))
         {
            ct.addChild(this._btnGroup);
         }
         else
         {
            this._ui.addChild(this._btnGroup);
         }
         this._btnGroup.build();
         this._btnGroup.fadIn(0.2,0.04);
         setTimeout(function():void
         {
            _btnGroup.enabled = true;
         },400);
      }
      
      public function destory(param1:Function = null) : void
      {
         if(Boolean(this._btnGroup))
         {
            try
            {
               this._btnGroup.parent.removeChild(this._btnGroup);
            }
            catch(e:Error)
            {
            }
            this._btnGroup.destory();
            this._btnGroup = null;
         }
         GameInputer.enabled = false;
      }
   }
}

