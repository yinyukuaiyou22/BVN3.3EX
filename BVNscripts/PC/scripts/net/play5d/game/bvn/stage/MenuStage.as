package net.play5d.game.bvn.stage
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.text.TextField;
   import flash.utils.setTimeout;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.ui.MenuBtnGroup;
   import net.play5d.game.bvn.ui.UIUtils;
   import net.play5d.game.bvn.utils.ResUtils;
   import net.play5d.game.bvn.win.utils.UpdateUtils;
   import net.play5d.kyo.stage.Istage;
   
   public class MenuStage extends Sprite implements Istage
   {
      
      private var _ui:MovieClip;
      
      private var _btnGroup:MenuBtnGroup;
      
      private var _versionTxt:TextField;
      
      private var _destroyed:Boolean = false;
      
      public function MenuStage()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function build() : void
      {
         _ui = AssetManager.I.createObject(ResUtils.TITLE,"subswfs/title.swf") as MovieClip;
         _ui.gotoAndStop(1);
         GameInterface.instance.initTitleUI(_ui);
         GameInputer.enabled = true;
         SoundCtrl.I.BGM(AssetManager.I.getSound("op"));
      }
      
      public function afterBuild() : void
      {
         _ui.gotoAndPlay(2);
         _ui.addEventListener("complete",onComplete);
         _versionTxt = new TextField();
         UIUtils.formatText(_versionTxt,{
            "color":0,
            "size":16,
            "font":"Microsoft YaHei",
            "bold":true
         });
         _versionTxt.text = MainGame.I.VERSION;
         _versionTxt.autoSize = "left";
         _versionTxt.x = GameConfig.GAME_SIZE.x - _versionTxt.width - 15;
         _versionTxt.y = GameConfig.GAME_SIZE.y - _versionTxt.height - 10;
         _ui.addChild(_versionTxt);
      }
      
      private function showFirstRunDialog() : void
      {
         var time:Number;
         var funcYes:* = function():void
         {
            GameData.I.config.setAllRuleConfig(true);
         };
         var funcNo:* = function():void
         {
            GameData.I.config.setAllRuleConfig(false);
         };
         if(GameData.I.config.isFirstRun)
         {
            GameData.I.config.isFirstRun = false;
            GameData.I.saveData();
            GameUI.confrim(GetLangText("game_ui.confrim.first_run_switch.title"),GetLangText("game_ui.confrim.first_run_switch.message"),funcYes,funcNo);
         }
         else if(GameData.I.config.isAutoUpdateCheck)
         {
            time = new Date().time;
            if(time - GameData.I.config.latestUpdateTime > 3600000)
            {
               UpdateUtils.I.checkUpdate(true);
               GameData.I.config.latestUpdateTime = time;
               GameData.I.saveData();
            }
         }
      }
      
      private function onComplete(param1:Event) : void
      {
         _ui.removeEventListener("complete",onComplete);
         _ui.buttonMode = true;
         _ui.useHandCursor = true;
         _ui.addEventListener(GameConfig.TOUCH_MODE ? "touchTap" : "click",showBtns);
         GameRender.add(render);
         GameInputer.focus();
         GameInputer.enabled = true;
         showFirstRunDialog();
      }
      
      private function render() : void
      {
         if(_destroyed)
         {
            return;
         }
         if(GameInputer.anyKey(1))
         {
            showBtns();
         }
      }
      
      private function showBtns(... rest) : void
      {
         var ct:Sprite;
         if(_ui.hasEventListener("click"))
         {
            _ui.removeEventListener("click",showBtns);
         }
         if(_ui.hasEventListener("touchTap"))
         {
            _ui.removeEventListener("touchTap",showBtns);
         }
         GameRender.remove(render);
         _ui.buttonMode = false;
         _ui.useHandCursor = false;
         _ui.gotoAndPlay("menu");
         SoundCtrl.I.playAssetSound("menu5");
         _btnGroup = new MenuBtnGroup();
         _btnGroup.enabled = false;
         _btnGroup.x = 470;
         _btnGroup.y = 100;
         ct = _ui.getChildByName("btnct") as Sprite;
         if(ct)
         {
            ct.addChild(_btnGroup);
         }
         else
         {
            _ui.addChild(_btnGroup);
         }
         _btnGroup.build();
         _btnGroup.fadIn(0.2,0.04);
         setTimeout(function():void
         {
            _btnGroup.enabled = true;
         },400);
      }
      
      public function destory(param1:Function = null) : void
      {
         if(_destroyed)
         {
            return;
         }
         _destroyed = true;
         if(_btnGroup)
         {
            try
            {
               _btnGroup.parent.removeChild(_btnGroup);
            }
            catch(e:Error)
            {
            }
            _btnGroup.enabled = false;
            _btnGroup.destory();
            _btnGroup = null;
         }
         GameInputer.enabled = false;
      }
   }
}

