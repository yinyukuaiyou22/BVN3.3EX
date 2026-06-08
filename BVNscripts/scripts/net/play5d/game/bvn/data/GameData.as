package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.interfaces.*;
   
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
         var loadFighterBack:* = function(param1:XML):void
         {
            FighterModel.I.initByXML(param1);
            AssetManager.I.loadXML("assets/config/assist.xml",loadAssetsBack,loadAssisterFail);
         };
         loadAssetsBack = function(param1:XML):void
         {
            AssisterModel.I.initByXML(param1);
            AssetManager.I.loadXML("assets/config/select.xml",loadSelectBack,loadSelectFail);
         };
         loadSelectBack = function(param1:XML):void
         {
            config.select_config.setByXML(param1);
            AssetManager.I.loadXML("assets/config/map.xml",loadMapBack,loadMapFail);
         };
         loadMapBack = function(param1:XML):void
         {
            MapModel.I.initByXML(param1);
            AssetManager.I.loadXML("assets/config/mission.xml",loadMessionBack,loadMessionFail);
         };
         loadMessionBack = function(param1:String):void
         {
            MessionModel.I.initByXML(new XML(param1));
            back();
         };
         var loadFighterFail:* = function():void
         {
            Debugger.log("读取人物数据出错");
            if(fail != null)
            {
               fail("读取人物数据出错");
            }
         };
         loadAssisterFail = function():void
         {
            Debugger.log("读取辅助角色数据出错");
            if(fail != null)
            {
               fail("读取辅助角色数据出错");
            }
         };
         loadSelectFail = function():void
         {
            Debugger.log("读取选人场景数据出错");
            if(fail != null)
            {
               fail("读取选人场景数据出错");
            }
         };
         loadMapFail = function():void
         {
            Debugger.log("读取地图场景数据出错");
            if(fail != null)
            {
               fail("读取地图场景数据出错");
            }
         };
         loadMessionFail = function():void
         {
            Debugger.log("读取头卡数据出错");
            if(fail != null)
            {
               fail("读取地图场景数据出错");
            }
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
            trace("loadSelect error!");
         });
      }
      
      public function setSelectData(param1:XML) : void
      {
         this.config.select_config.setByXML(param1);
      }
   }
}

