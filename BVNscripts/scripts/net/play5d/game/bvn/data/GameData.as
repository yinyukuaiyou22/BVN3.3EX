package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.interfaces.*;
import net.play5d.game.bvn.Debugger;
import net.play5d.game.bvn.mob.utils.ANEFileReader;
import net.play5d.game.bvn.utils.*;

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
         var back:Function = param1;
         var fail:Function = param2;
         // All platforms (PC + Mobile) use APK-internal-first loading.
         // External asset scanning is guarded by ANEFileReader.EXTERNAL_ENABLED.
         // AS3 批量加载：5 个配置 XML 一次并行发起，全部 settle 后按固定顺序应用，
         // 使原先的"一条回调链等一条链"改为单次往返（应用顺序与合并时机保持不变）。
         trace("[GameData] loadConfig start (batch XML)");
         var xmls:Object = {};
         var batch:AssetBatchLoader = new AssetBatchLoader();
         batch.load(["fighter","assist","select","map","mission"],function(key:String, onDone:Function, onFail:Function, onProgress:Function):void
         {
            AssetManager.I.loadXML("assets/config/" + key + ".xml",function(param1:XML):void
            {
               xmls[key] = param1;
               onDone();
            },function():void
            {
               Debugger.log("[GameData] " + key + ".xml 未从内置加载");
               onFail();
            });
         },function():void
         {
            applyConfigXMLs(xmls,back);
         });
      }
      
      /** 按原串行链的固定顺序应用已加载的配置 XML：fighter → assist → select → map → mission，
       *  最后合并外置配置。fighter.xml 缺失时保持原语义：直接转为从外置加载全部配置。 */
      private function applyConfigXMLs(param1:Object, param2:Function) : void
      {
         var xmls:Object = param1;
         var back:Function = param2;
         var fighterXML:XML = xmls["fighter"];
         var assistXML:XML = xmls["assist"];
         var selectXML:XML = xmls["select"];
         var mapXML:XML = xmls["map"];
         var missionXML:XML = xmls["mission"];
         if(fighterXML)
         {
            trace("[GameData] fighter.xml loaded");
            FighterModel.I.initByXML(fighterXML);
            if(ANEFileReader.EXTERNAL_ENABLED)
            {
               trace("[GameData] scanning external assets...");
               GameLoader.scanExternalAssets();
            }
         }
         else
         {
            // 原 loadFighterFail 语义：内置 fighter.xml 缺失 → 全部配置改由外置提供
            Debugger.log("[GameData] fighter.xml not in APK, loading ALL configs from external...");
            if(ANEFileReader.EXTERNAL_ENABLED)
            {
               GameLoader.loadExternalConfigsNow(back);
               return;
            }
            Debugger.log("[GameData] fighter.xml not in APK, ANE disabled — proceeding without configs");
            if(back != null) back();
            return;
         }
         if(assistXML)
         {
            trace("[GameData] assist.xml loaded");
            AssisterModel.I.initByXML(assistXML);
         }
         else
         {
            Debugger.log("[GameData] assist.xml not in APK, will load from external");
         }
         if(selectXML)
         {
            trace("[GameData] select.xml loaded");
            config.select_config.setByXML(selectXML);
         }
         else
         {
            Debugger.log("[GameData] select.xml not in APK, will load from external");
         }
         if(mapXML)
         {
            trace("[GameData] map.xml loaded");
            MapModel.I.initByXML(mapXML);
         }
         else
         {
            Debugger.log("[GameData] map.xml not in APK, will load from external");
         }
         if(missionXML)
         {
            trace("[GameData] mission.xml loaded");
            MessionModel.I.initByXML(new XML(missionXML));
         }
         else
         {
            Debugger.log("[GameData] mission.xml not in APK" + (ANEFileReader.EXTERNAL_ENABLED ? ", will load from external" : ""));
         }
         if(ANEFileReader.EXTERNAL_ENABLED)
         {
            // External fighter.xml and select.xml must be merged before the
            // select stage builds its list. A delayed merge is too late.
            trace("[GameData] loading external assets before startup completes...");
            GameLoader.loadExternalConfigsNow(back);
            return;
         }
         trace("[GameData] config loading complete");
         if(back != null) back();
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
