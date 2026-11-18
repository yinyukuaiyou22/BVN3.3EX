package net.play5d.game.bvn.state
{
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
    * 相机与画质页（设置 → CAMERA SET，2026-11-18 新增）。
    * 与 RuleState 同构：换 UI 元件（Screen）+ 换数据源（getCameraMenu()）。
    * FLA 侧约定：元件 AS 链接名 Screen，内含角色 角色3，舞台实例名 yuna1。
    * 设计约束：camEnhance=false 时必须与改动前的镜头行为逐帧一致（可回退基线）；
    * 镜头算法本体在 state/GameCamera.as，本类只负责开关与存档，不碰算法。
    */
   public class CameraState implements Istage
   {
      
      private var _ui:*;
      
      private var _btnGroup:SetBtnGroup;
      
      private var _man:MovieClip;
      
      public function CameraState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         Debugger.log("[CameraState]","build() enter");
         this._ui = this.createCameraUI();
         if(!this._ui)
         {
            Debugger.log("[CameraState]","build() FAILED: Screen ui is null, back to menu");
            MainGame.I.goMenu();
            return;
         }
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.startY = 30;
         this._btnGroup.endY = 550;
         this._btnGroup.gap = 70;
         this._btnGroup.initCameraSet();
         this._btnGroup.initScroll(GameConfig.GAME_SIZE.x,600);
         this._btnGroup.enableScrollDrag();
         this._btnGroup.addEventListener("SELECT",this.onBtnSelect);
         this._btnGroup.addEventListener("OPTION_CHANGE",this.onOptionChange);
         this._ui.addChild(this._btnGroup);
         try
         {
            this._man = this._ui.yuna1 as MovieClip;
         }
         catch(e:Error)
         {
            this._man = null;
         }
         SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
         GameRender.add(this.render,this);
         Debugger.log("[CameraState]","build() done, man=",this._man != null ? "ok" : "NULL");
      }
      
      /**
       * 优先用 setting.swf 内的 Screen；取不到时回退常规设置 UI，保证界面仍可用。
       * ResUtils.getItemClass 走 ApplicationDomain.getDefinition，类不存在会抛 ReferenceError，必须 try/catch。
       */
      private function createCameraUI() : *
      {
         var _loc1_:* = null;
         try
         {
            _loc1_ = ResUtils.I.createDisplayObject(ResUtils.I.setting,ResUtils.SCREEN);
         }
         catch(e:Error)
         {
            _loc1_ = null;
         }
         if(Boolean(_loc1_))
         {
            return _loc1_;
         }
         Debugger.log("[CameraState]","Screen not found, fallback stg_set_ui");
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
         Debugger.log("[CameraState]","onBtnSelect label=",param1.selectedLabel);
         var _loc2_:ConfigVO = GameData.I.config;
         switch(param1.selectedLabel)
         {
            case "CAMERA SWITCH":
               this.switchAllCameraConfig(!_loc2_.camEnhance);
               if(Boolean(this._btnGroup))
               {
                  this._btnGroup.refreshOptionValues();
               }
               break;
            case "APPLY":
               this.applyConfig();
         }
      }
      
      /**
       * 一键切换：开=四项增强全开（总开关 + 自动缩放 + 震屏 + 留白钳制）；
       * 关=四项全关，回到原版镜头行为。camDistLevel 不受影响（它只换取景）。
       */
      private function switchAllCameraConfig(param1:Boolean) : void
      {
         var _loc2_:ConfigVO = GameData.I.config;
         _loc2_.camEnhance = param1;
         _loc2_.camAutoZoom = param1;
         _loc2_.camShake = param1;
         _loc2_.camFrameClamp = param1;
         Debugger.log("[CameraState]","switchAllCameraConfig ->",param1);
      }
      
      private function applyConfig() : void
      {
         GameData.I.saveData();
         GameData.I.config.applyConfig();
         GameInputer.updateConfig();
         MainGame.I.goMenu();
      }
      
      /** 返回键 / MENU 键：弹「保存并返回」确认框（与 RuleState 一致）。 */
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
         Debugger.log("[CameraState]","destory()");
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
