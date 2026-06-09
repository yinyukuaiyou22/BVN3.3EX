package net.play5d.game.bvn.mob.views
{
   import flash.display.Sprite;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.mob.*;
   import net.play5d.game.bvn.mob.data.ScreenPadConfigVO;
   import net.play5d.game.bvn.ui.*;
import net.play5d.game.bvn.Debugger;
   
   public class SetScreenBtnView extends Sprite
   {
      
      private var _btnGroup:SetBtnGroup;
      
      public function SetScreenBtnView()
      {
         super();
         this.graphics.beginFill(0,0.8);
         this.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         this.graphics.endFill();
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.startY = 30;
         this._btnGroup.endY = 550;
         this._btnGroup.gap = 70;
         var _loc1_:ScreenPadConfigVO = GameInterfaceManager.config.screenPadConfig;
         this._btnGroup.setBtnData([{
            "label":"PREINSTALL",
            "cn":"预置位置",
            "options":[{
               "label":"TYPE 1",
               "cn":"设定1",
               "value":0
            },{
               "label":"TYPE 2",
               "cn":"设定2",
               "value":1
            }],
            "optoinKey":"joyMode",
            "optionValue":_loc1_.joyMode
         },{
            "label":"ALPHA",
            "cn":"按钮透明度",
            "options":[{
               "label":"0%",
               "cn":"0%",
               "value":0
            },{
               "label":"10%",
               "cn":"10%",
               "value":0.1
            },{
               "label":"30%",
               "cn":"30%",
               "value":0.3
            },{
               "label":"50%",
               "cn":"50%",
               "value":0.5
            },{
               "label":"70%",
               "cn":"70%",
               "value":0.7
            },{
               "label":"100%",
               "cn":"100%",
               "value":1
            }],
            "optoinKey":"joyAlpha",
            "optionValue":_loc1_.joyAlpha
         },{
            "label":"SP SKILL",
            "cn":"必杀按键",
            "options":[{
               "label":"AUTO",
               "cn":"自动显示/隐藏",
               "value":true
            },{
               "label":"ALWAYS",
               "cn":"总是显示",
               "value":false
            }],
            "optoinKey":"superSkillAutoHide",
            "optionValue":_loc1_.superSkillAutoHide
         },{
            "label":"WANKAI",
            "cn":"卍解按键",
            "options":[{
               "label":"AUTO",
               "cn":"自动显示/隐藏",
               "value":true
            },{
               "label":"ALWAYS",
               "cn":"总是显示",
               "value":false
            }],
            "optoinKey":"wankaiAutoHide",
            "optionValue":_loc1_.wankaiAutoHide
         },{
            "label":"SPECIAL",
            "cn":"辅助/灵爆/替身术按键",
            "options":[{
               "label":"AUTO",
               "cn":"自动显示/隐藏",
               "value":true
            },{
               "label":"ALWAYS",
               "cn":"总是显示",
               "value":false
            }],
            "optoinKey":"specialAutoHide",
            "optionValue":_loc1_.specialAutoHide
         },{
            "label":"CUSTOM",
            "cn":"自定义"
         },{
            "label":"APPLY",
            "cn":"确定"
         }]);
         this._btnGroup.initScroll(launch.FULL_SCREEN_SIZE.x,launch.FULL_SCREEN_SIZE.y);
         this._btnGroup.addEventListener("SELECT",this.onBtnSelect);
         this._btnGroup.addEventListener("OPTION_CHANGE",this.onOptionChange);
         this.addChild(this._btnGroup);
      }
      
      private function onBtnSelect(param1:SetBtnEvent) : void
      {
         var _loc2_:CustomScreenBtnView = null;
         switch(param1.selectedLabel)
         {
            case "CUSTOM":
               _loc2_ = new CustomScreenBtnView();
               launch.I.addChild(_loc2_.getDisplay());
               break;
            case "APPLY":
               this.closeSelf();
         }
      }
      
      private function onOptionChange(param1:SetBtnEvent) : void
      {
         var config:ScreenPadConfigVO = null;
         var e:SetBtnEvent = null;
         e = param1;
         if(e.optionKey == "joyMode")
         {
            if(Boolean(GameInterfaceManager.config.screenPadConfig.joySet))
            {
               GameUI.confrim("Custom already set, are you sure ?","自定义按钮已设定，改变此项将丢失自定义按钮设定，确定要改变？",function():void
               {
                  GameInterfaceManager.config.screenPadConfig.joySet = null;
                  var _loc1_:ScreenPadConfigVO = GameInterfaceManager.config.screenPadConfig;
                  _loc1_.setValueByKey(e.optionKey,e.optionValue);
               });
               return;
            }
         }
         config = GameInterfaceManager.config.screenPadConfig;
         config.setValueByKey(e.optionKey,e.optionValue);
      }
      
      private function closeSelf() : void
      {
         if(Boolean(this._btnGroup))
         {
            try
            {
               this._btnGroup.destory();
               this.removeChild(this._btnGroup);
               this._btnGroup = null;
            }
            catch(e:Error)
            {
               Debugger.log(e);
            }
         }
         try
         {
            this.parent.removeChild(this);
         }
         catch(e:Error)
         {
            Debugger.log(e);
         }
      }
   }
}

