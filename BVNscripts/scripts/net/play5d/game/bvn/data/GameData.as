package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.interfaces.*;
import net.play5d.game.bvn.Debugger;
import net.play5d.game.bvn.mob.utils.ANEFileReader;

   public class GameData
   {
      
      private static var _i:GameData;
      
      public var config:ConfigVO = new ConfigVO();
      
      public var p1Select:SelectVO;
      
      public var p2Select:SelectVO;
      
      public var selectMap:String;
      
      public var score:int = 0;
      
      public var winnerId:String;
      
      public var isFristRun:Boolean = true;
      
      private const SAVE_ID:String = "bvn3.01";
      
      public function GameData()
      {
         super();
      }
      
      public static function get I() : GameData
      {
         if(!_i)
         {
            _i = new GameData();
         }
         return _i;
      }
      
      public function loadConfig(param1:Function, param2:Function = null) : void
      {
         var fail:Function = null;
         var loadAssetsBack:* = undefined;
         var loadSelectBack:* = undefined;
         var loadMapBack:* = undefined;
         var loadMessionBack:* = undefined;
         var loadAssisterFail:* = undefined;
         var loadSelectFail:* = undefined;
         var loadMapFail:* = undefined;
         var loadMessionFail:* = undefined;
         var back:Function = param1;
         fail = param2;

         // All platforms (PC + Mobile) use APK-internal-first loading.
         // External asset scanning is guarded by ANEFileReader.ANE_ENABLED.
         trace("[GameData] loadConfig start, loading fighter.xml...");
         var loadFighterBack:* = function(param1:XML):void
         {
            trace("[GameData] fighter.xml loaded");
            FighterModel.I.initByXML(param1);
            if (ANEFileReader.ANE_ENABLED) {
               trace("[GameData] scanning external assets...");
               GameLoader.scanExternalAssets();
            }
            trace("[GameData] loading assist.xml...");
            AssetManager.I.loadXML("assets/config/assist.xml",loadAssetsBack,loadAssisterFail);
         };
         loadAssetsBack = function(param1:XML):void
         {
            trace("[GameData] assist.xml loaded, loading select.xml...");
            AssisterModel.I.initByXML(param1);
            AssetManager.I.loadXML("assets/config/select.xml",loadSelectBack,loadSelectFail);
         };
         loadSelectBack = function(param1:XML):void
         {
            trace("[GameData] select.xml loaded, loading map.xml...");
            config.select_config.setByXML(param1);
            AssetManager.I.loadXML("assets/config/map.xml",loadMapBack,loadMapFail);
         };
         loadMapBack = function(param1:XML):void
         {
            trace("[GameData] map.xml loaded, loading mission.xml...");
            MapModel.I.initByXML(param1);
            AssetManager.I.loadXML("assets/config/mission.xml",loadMessionBack,loadMessionFail);
         };
         loadMessionBack = function(param1:String):void
         {
            trace("[GameData] mission.xml loaded" + (ANEFileReader.ANE_ENABLED ? ", loading external configs..." : ""));
            MessionModel.I.initByXML(new XML(param1));
            if (ANEFileReader.ANE_ENABLED) {
               GameLoader.loadExternalConfigs();
            }
            trace("[GameData] config loading complete");
            back();
         };
         var loadFighterFail:* = function():void
         {
            if (ANEFileReader.ANE_ENABLED) {
               Debugger.log("[GameData] fighter.xml not in APK, loading ALL configs from external...");
               GameLoader.loadExternalConfigsNow(back);
            } else {
               Debugger.log("[GameData] fighter.xml not in APK, ANE disabled — proceeding without configs");
               back();
            }
         };
         loadAssisterFail = function():void
         {
            Debugger.log("[GameData] assist.xml not in APK, will load from external");
            AssetManager.I.loadXML("assets/config/select.xml",loadSelectBack,loadSelectFail);
         };
         loadSelectFail = function():void
         {
            Debugger.log("[GameData] select.xml not in APK, will load from external");
            AssetManager.I.loadXML("assets/config/map.xml",loadMapBack,loadMapFail);
         };
         loadMapFail = function():void
         {
            Debugger.log("[GameData] map.xml not in APK, will load from external");
            AssetManager.I.loadXML("assets/config/mission.xml",loadMessionBack,loadMessionFail);
         };
         loadMessionFail = function():void
         {
            Debugger.log("[GameData] mission.xml not in APK" + (ANEFileReader.ANE_ENABLED ? ", will load from external" : ""));
            if (ANEFileReader.ANE_ENABLED) {
               GameLoader.loadExternalConfigs();
            }
            back();
         };
         AssetManager.I.loadXML("assets/config/fighter.xml",loadFighterBack,loadFighterFail);
      }
      
      public function saveData() : void
      {
         var _loc1_:Object = {};
         _loc1_.id = "bvn3.01";
         _loc1_.config = this.config.toSaveObj();
         GameInterface.instance.saveGame(_loc1_);
      }
      
      public function loadData() : void
      {
         var _loc1_:Object = GameInterface.instance.loadGame();
         if(!_loc1_ || _loc1_.id != "bvn3.01")
         {
            return;
         }
         this.config.readSaveObj(_loc1_.config);
      }
      
      public function loadSelect(param1:String) : void
      {
         var url:String = param1;
         AssetManager.I.loadXML(url,function(param1:XML):void
         {
            setSelectData(param1);
         },function():void
         {
            Debugger.log("loadSelect error!");
         });
      }
      
      public function setSelectData(param1:XML) : void
      {
         this.config.select_config.setByXML(param1);
      }
   }
}

