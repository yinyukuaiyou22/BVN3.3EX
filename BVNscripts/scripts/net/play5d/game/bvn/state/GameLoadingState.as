package net.play5d.game.bvn.state
{
   import flash.display.DisplayObject;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   
   public class GameLoadingState implements Istage
   {
      
      private var _ui:*;
      
      private var _initBack:Function;
      
      private var _initFail:Function;
      
      public function GameLoadingState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.loading,"loading_cover_mc");
      }
      
      public function loadGame(param1:Function, param2:Function) : void
      {
         this._initBack = param1;
         this._initFail = param2;
         if(AssetManager.I.needPreLoad())
         {
            AssetManager.I.loadPreLoad(this.loadPreloadBack,this.loadPreloadFail,this.loadPreloadProcess);
            this.msg("游戏初始化：准备游戏资源");
         }
         else
         {
            this.loadPreloadBack();
         }
      }
      
      private function loadPreloadBack() : void
      {
         GameData.I.loadConfig(this.loadConfigBack,this.loadConfigFail);
         this.msg("游戏初始化：正在加载配置文件");
      }
      
      private function loadPreloadFail(param1:String = null) : void
      {
         Debugger.log("游戏初始化失败：准备游戏资源失败：",param1);
         this.msg("游戏初始化失败：准备游戏资源失败!");
         if(this._initFail != null)
         {
            this._initFail(param1);
         }
      }
      
      private function loadPreloadProcess(param1:Number) : void
      {
         if(param1 > 1)
         {
            param1 = 1;
         }
         this._ui.bar.bar.scaleX = param1;
      }
      
      private function loadConfigFail(param1:String) : void
      {
         Debugger.log("游戏初始化失败：加载配置文件失败：",param1);
         this.msg("游戏初始化失败：加载配置文件失败!");
         if(this._initFail != null)
         {
            this._initFail(param1);
         }
      }
      
      private function loadConfigBack() : void
      {
         AssetManager.I.loadBasic(this.loadAssetBack,this.loadAssetProcess);
         this.msg("游戏初始化：正在加载游戏资源");
      }
      
      private function loadAssetProcess(param1:Number, param2:String, param3:int, param4:int) : void
      {
         if(param1 > 1)
         {
            trace(param2 + "::进度超过100%");
            param1 = 1;
         }
         this._ui.bar.bar.scaleX = param1;
         this.msg("游戏初始化：正在加载" + param2 + "资源(" + param3 + "/" + param4 + ")");
      }
      
      private function loadAssetBack() : void
      {
         if(this._initBack != null)
         {
            this._initBack();
            this._initBack = null;
         }
         this._initFail = null;
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
      }
      
      private function msg(param1:String) : void
      {
         this._ui.bar.txt.text = param1;
      }
   }
}

