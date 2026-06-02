package net.play5d.game.bvn.stage.base
{
   import com.greensock.TweenLite;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.data.ConfigVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.KeyConfigVO;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.interfaces.IInnerSetUI;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.ui.SetBtnGroup;
   import net.play5d.game.bvn.ui.SetCtrlBtnUI;
   import net.play5d.kyo.stage.Istage;
   
   public class SettingStageBase implements Istage
   {
      
      protected var _ui:MovieClip;
      
      protected var _btnGroup:SetBtnGroup;
      
      protected var _innerSetUI:IInnerSetUI;
      
      protected var _man:MovieClip;
      
      public function SettingStageBase()
      {
         super();
      }
      
      protected static function onOptionChange(param1:SetBtnEvent) : void
      {
         var _loc2_:ConfigVO = GameData.I.config;
         _loc2_.setValueByKey(param1.optionKey,param1.optionValue);
      }
      
      protected static function applyConfig() : void
      {
         GameData.I.saveData();
         GameData.I.config.applyConfig();
         GameInputer.updateConfig();
         MainGame.I.goMenu();
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function build() : void
      {
         GameRender.add(render);
      }
      
      protected function onBtnSelect(param1:SetBtnEvent) : void
      {
         switch(param1.selectedLabel)
         {
            case GetLangText("stage_settings.p1_key_set.label"):
               goKeyConfig(1,GameData.I.config.key_p1);
               break;
            case GetLangText("stage_settings.p2_key_set.label"):
               goKeyConfig(2,GameData.I.config.key_p2);
               break;
            case GetLangText("game_ui.btn_data.general.apply.label"):
               applyConfig();
         }
      }
      
      protected function goKeyConfig(param1:int, param2:KeyConfigVO) : void
      {
         var _loc3_:SetCtrlBtnUI = new SetCtrlBtnUI();
         _loc3_.setKey(param2);
         goInnerSetPage(_loc3_);
      }
      
      public function goInnerSetPage(param1:IInnerSetUI) : void
      {
         var innerUI:IInnerSetUI = param1;
         var tweenComplete:* = function():void
         {
            _btnGroup.visible = false;
         };
         destoryInnerSetUI();
         _innerSetUI = innerUI;
         innerUI.addEventListener("APPLY_SET",innerSetHandler);
         innerUI.addEventListener("CANCEL_SET",innerSetHandler);
         _ui.addChild(innerUI.getUI());
         innerUI.fadIn();
         TweenLite.to(_btnGroup,0.2,{
            "y":-GameConfig.GAME_SIZE.y,
            "onComplete":tweenComplete
         });
         _btnGroup.keyEnable = false;
         _man.gotoAndPlay("key_fadin");
      }
      
      protected function destoryInnerSetUI() : void
      {
         GameRender.remove(render);
         if(_innerSetUI)
         {
            try
            {
               _ui.removeChild(_innerSetUI.getUI());
            }
            catch(e:Error)
            {
            }
            _innerSetUI.removeEventListener("APPLY_SET",innerSetHandler);
            _innerSetUI.removeEventListener("CANCEL_SET",innerSetHandler);
            _innerSetUI.destory();
            _innerSetUI = null;
         }
      }
      
      protected function goMainSetting() : void
      {
         var tweenComplete:* = function():void
         {
            _btnGroup.keyEnable = true;
         };
         TweenLite.to(_btnGroup,0.2,{
            "y":0,
            "onComplete":tweenComplete,
            "delay":0.1
         });
         _btnGroup.visible = true;
         if(_innerSetUI)
         {
            _innerSetUI.fadOut();
            _innerSetUI.removeEventListener("APPLY_SET",innerSetHandler);
            _innerSetUI.removeEventListener("CANCEL_SET",innerSetHandler);
         }
         _man.gotoAndPlay("key_fadout");
      }
      
      protected function innerSetHandler(param1:String) : void
      {
         goMainSetting();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         if(_btnGroup)
         {
            try
            {
               _ui.removeChild(_btnGroup);
            }
            catch(e:Error)
            {
            }
            _btnGroup.removeEventListener("SELECT",onBtnSelect);
            _btnGroup.removeEventListener("OPTION_CHANGE",onOptionChange);
            _btnGroup.destory();
            _btnGroup = null;
            _man = null;
         }
         destoryInnerSetUI();
      }
      
      protected function render() : void
      {
         if(GameInputer.back(1) || GameInputer.jump("MENU",1))
         {
            if(GameUI.showingDialog())
            {
               GameUI.cancelConfrim();
               _btnGroup.keyEnable = true;
            }
            else
            {
               _btnGroup.keyEnable = false;
               GameUI.confrim(GetLangText("game_ui.confrim.save_and_back_title.title"),GetLangText("game_ui.confrim.save_and_back_title.message"),applyConfig,function():void
               {
                  _btnGroup.keyEnable = true;
               });
            }
         }
      }
   }
}

