package net.play5d.game.bvn.state
{
   import com.greensock.*;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   
   /**
    * 规则设置界面（主菜单 OPTION → RULE CFG）。
    * 与 SettingState（GAME CFG）同源：换 UI 元件（rule_ui）+ 换选项数据源（getRuleMenu()）。
    * 参照 BVN 3.8 的 RuleStage 拆分方式，详解见 doc/38-rule-stage/rule-stage.md。
    */
   public class RuleState implements Istage
   {
      
      private var _ui:*;
      
      private var _btnGroup:SetBtnGroup;
      
      private var _man:MovieClip;
      
      public function RuleState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         Debugger.log("[RuleState]","build() enter");
         this._ui = this.createRuleUI();
         if(!this._ui)
         {
            // 没有可用 UI 就不要进这个场景，否则后续 addChild / render 全是空引用
            Debugger.log("[RuleState]","build() FAILED: rule ui is null, back to menu");
            MainGame.I.goMenu();
            return;
         }
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.startY = 30;
         this._btnGroup.endY = 550;
         this._btnGroup.gap = 70;
         this._btnGroup.initRuleSet();
         this._btnGroup.initScroll(GameConfig.GAME_SIZE.x,600);
         // 与 SettingState 同理：手机端没有虚拟方向键，必须开拖拽滚动才能滚到末尾的 APPLY
         this._btnGroup.enableScrollDrag();
         this._btnGroup.addEventListener("SELECT",this.onBtnSelect);
         this._btnGroup.addEventListener("OPTION_CHANGE",this.onOptionChange);
         this._ui.addChild(this._btnGroup);
         try
         {
            this._man = this._ui.yuna as MovieClip;
         }
         catch(e:Error)
         {
            this._man = null;
         }
         SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
         GameRender.add(this.render,this);
         Debugger.log("[RuleState]","build() done, man=",this._man != null ? "ok" : "NULL");
      }
      
      /**
       * 优先用 setting.swf 内的 rule_ui；取不到（SWF 未重新发布）时
       * 回退到常规设置 UI，保证界面仍可用。
       * 注意：ResUtils.getItemClass 走 ApplicationDomain.getDefinition，
       * 类不存在时会抛 ReferenceError，必须 try/catch。
       */
      private function createRuleUI() : *
      {
         var _loc1_:* = null;
         try
         {
            _loc1_ = ResUtils.I.createDisplayObject(ResUtils.I.setting,ResUtils.RULE);
         }
         catch(e:Error)
         {
            _loc1_ = null;
         }
         if(Boolean(_loc1_))
         {
            return _loc1_;
         }
         Debugger.log("[RuleState]","rule_ui not found, fallback stg_set_ui");
         try
         {
            _loc1_ = ResUtils.I.createDisplayObject(ResUtils.I.setting,ResUtils.SETTING);
         }
         catch(e:Error)
         {
            _loc1_ = null;
         }
         return _loc1_;
      }
      
      private function onOptionChange(param1:SetBtnEvent) : void
      {
         var _loc2_:ConfigVO = GameData.I.config;
         _loc2_.setValueByKey(param1.optionKey,param1.optionValue);
      }
      
      private function onBtnSelect(param1:SetBtnEvent) : void
      {
         Debugger.log("[RuleState]","onBtnSelect label=",param1.selectedLabel);
         switch(param1.selectedLabel)
         {
            case "RULE SWITCH":
               GameData.I.config.switchAllRuleConfig();
               // 一键切换只改内存，这里把各选项显示刷新为当前值（静默刷新，不会再派发 OPTION_CHANGE）
               if(Boolean(this._btnGroup))
               {
                  this._btnGroup.refreshOptionValues();
               }
               break;
            case "APPLY":
               this.applyConfig();
         }
      }
      
      private function applyConfig() : void
      {
         GameData.I.saveData();
         GameData.I.config.applyConfig();
         GameInputer.updateConfig();
         MainGame.I.goMenu();
      }
      
      /**
       * 返回键 / MENU 键：弹「保存并返回」确认框（SettingState 没有返回键处理，这里补上）。
       */
      private function render() : void
      {
         if(!this._btnGroup)
         {
            return;
         }
         if(GameInputer.back(1) || GameInputer.jump("MENU",1))
         {
            if(GameUI.showingDialog())
            {
               GameUI.closeConfrim();
               this._btnGroup.keyEnable = true;
               return;
            }
            this._btnGroup.keyEnable = false;
            GameUI.confrim("SAVE AND BACK","保存并返回？",this.applyConfig,function():void
            {
               if(Boolean(_btnGroup))
               {
                  _btnGroup.keyEnable = true;
               }
            });
         }
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         Debugger.log("[RuleState]","destory()");
         GameRender.remove(this.render,this);
         if(Boolean(this._btnGroup))
         {
            try
            {
               this._ui.removeChild(this._btnGroup);
            }
            catch(e:Error)
            {
            }
            this._btnGroup.removeEventListener("SELECT",this.onBtnSelect);
            this._btnGroup.removeEventListener("OPTION_CHANGE",this.onOptionChange);
            this._btnGroup.destory();
            this._btnGroup = null;
         }
         this._man = null;
      }
   }
}
