package net.play5d.game.bvn.data
{
   import flash.filesystem.File;
   import flash.filesystem.FileStream;
   import flash.system.System;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.data.mosou.MosouFighterModel;
   import net.play5d.game.bvn.data.mosou.MosouFighterSellVO;
   import net.play5d.game.bvn.data.mosou.MosouMissionVO;
   import net.play5d.game.bvn.data.mosou.MosouModel;
   import net.play5d.game.bvn.data.mosou.MosouWorldMapAreaVO;
   import net.play5d.game.bvn.data.mosou.MosouWorldMapVO;
   import net.play5d.game.bvn.data.mosou.player.MosouPlayerData;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.utils.ResUtils;
   import net.play5d.game.bvn.win.GameInterfaceManager;
   import net.play5d.game.bvn.win.utils.UpdateUtils;
   import net.play5d.kyo.loader.KyoURLoader;
   
   public class GameData
   {
      
      private static var _i:GameData;
      
      public var config:ConfigVO = new ConfigVO();
      
      public var record:RecordVO = new RecordVO();
      
      public var mosouData:MosouPlayerData = new MosouPlayerData();
      
      public var p1Select:SelectVO;
      
      public var p2Select:SelectVO;
      
      public var selectMap:String;
      
      public var score:int = 0;
      
      public var winnerId:String;
      
      private const SAVE_ID:String = "BVN_SPORTS_SAVE";
      
      private const __MOSOU_DATA_ENABLED:Boolean = true;
      
      public var isOpenEgg:Boolean = false;
      
      public var tempInfo:Object;
      
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
      
      public static function releaseSaveData(param1:Boolean = false) : void
      {
         var _loc3_:ByteArray = ResUtils.I.getSaveData();
         if(_loc3_ == null)
         {
            return;
         }
         var _loc2_:File = File.applicationStorageDirectory.resolvePath(GameInterfaceManager.getSaveFilePath());
         if(param1 && Boolean(_loc2_.exists))
         {
            return;
         }
         var _loc4_:FileStream = new FileStream();
         _loc2_ = new File(File.applicationStorageDirectory.resolvePath(GameInterfaceManager.getSaveFilePath()).nativePath);
         _loc4_.open(_loc2_,"write");
         _loc4_.writeUTFBytes(_loc3_.readUTFBytes(_loc3_.bytesAvailable));
         _loc4_.close();
      }
      
      private static function validateMusouData() : void
      {
         var _loc2_:MosouWorldMapVO = null;
         var _loc12_:String = null;
         var _loc14_:MapVO = null;
         var _loc6_:Array = null;
         var _loc10_:FighterVO = null;
         var _loc15_:FighterVO = null;
         var _loc7_:String = null;
         var _loc3_:Object = MosouModel.I.getAllMap();
         for(var _loc11_ in _loc3_)
         {
            _loc2_ = _loc3_[_loc11_] as MosouWorldMapVO;
            for each(var _loc1_ in _loc2_.areas)
            {
               for each(var _loc4_ in _loc1_.missions)
               {
                  _loc12_ = _loc2_.id + " - " + _loc1_.id + " - " + _loc4_.id;
                  _loc14_ = MapModel.I.getMap(_loc4_.map);
                  if(_loc14_ == null)
                  {
                     throw new Error("musou[" + _loc12_ + "]验证失败！未找到map: " + _loc4_.map);
                  }
                  _loc6_ = _loc4_.getAllEnemieIds();
                  for each(var _loc13_ in _loc6_)
                  {
                     _loc10_ = FighterModel.I.getFighter(_loc13_);
                     if(_loc10_ == null)
                     {
                        throw new Error("musou[" + _loc12_ + "]验证失败！未找到fighter: " + _loc13_);
                     }
                  }
               }
            }
         }
         var _loc9_:Array = [];
         var _loc8_:Vector.<MosouFighterSellVO> = MosouFighterModel.I.fighters;
         for each(var _loc5_ in _loc8_)
         {
            _loc15_ = FighterModel.I.getFighter(_loc5_.id);
            if(!_loc15_ && _loc9_.indexOf(_loc5_.id) == -1)
            {
               _loc9_.push(_loc5_.id);
            }
         }
         if(_loc9_.length > 0)
         {
            _loc7_ = "";
            if(_loc9_.length > 0)
            {
               _loc7_ += "fighter:" + _loc9_.join(" , ") + " ; ";
            }
            throw new Error("FighterModel 验证失败！ [" + _loc7_ + "]");
         }
      }
      
      public function loadConfig(param1:Function, param2:Function = null) : void
      {
         var back:Function = param1;
         var fail:Function = param2;
         var loadFighterBack:* = function(param1:XML):void
         {
            FighterModel.I.initByXML(param1);
            System.disposeXML(param1);
            AssetManager.I.loadXML("config/assist.xml",loadAssetsBack,loadAssisterFail);
         };
         var loadAssetsBack:* = function(param1:XML):void
         {
            AssisterModel.I.initByXML(param1);
            System.disposeXML(param1);
            AssetManager.I.loadXML("config/select.xml",loadSelectBack,loadSelectFail);
         };
         var loadSelectBack:* = function(param1:XML):void
         {
            config.select_config.setByXML(param1);
            System.disposeXML(param1);
            AssetManager.I.loadXML("config/map.xml",loadMapBack,loadMapFail);
         };
         var loadMapBack:* = function(param1:XML):void
         {
            MapModel.I.initByXML(param1);
            System.disposeXML(param1);
            AssetManager.I.loadXML("config/mission.xml",loadMissionBack,loadMissionFail);
         };
         var loadMissionBack:* = function(param1:String):void
         {
            var _loc2_:XML = new XML(param1);
            MessionModel.I.initByXML(_loc2_);
            System.disposeXML(_loc2_);
            MosouModel.I.loadMapData(loadMosouDataBack,loadMosouFail);
         };
         var loadMosouDataBack:* = function():void
         {
            MosouFighterModel.I.init();
            validateSelect();
            validateMissionData();
            validateMusouData();
            if(back != null)
            {
               back();
            }
         };
         var loadFighterFail:* = function():void
         {
            Debugger.log("读取人物数据出错");
            if(fail != null)
            {
               fail("读取人物数据出错");
            }
         };
         var loadAssisterFail:* = function():void
         {
            Debugger.log("读取辅助角色数据出错");
            if(fail != null)
            {
               fail("读取辅助角色数据出错");
            }
         };
         var loadSelectFail:* = function():void
         {
            Debugger.log("读取选人场景数据出错");
            if(fail != null)
            {
               fail("读取选人场景数据出错");
            }
         };
         var loadMapFail:* = function():void
         {
            Debugger.log("读取地图场景数据出错");
            if(fail != null)
            {
               fail("读取地图场景数据出错");
            }
         };
         var loadMissionFail:* = function():void
         {
            Debugger.log("读取关卡数据出错");
            if(fail != null)
            {
               fail("读取关卡数据出错");
            }
         };
         var loadMosouFail:* = function():void
         {
            Debugger.log("读取无双数据出错");
            if(fail != null)
            {
               fail("读取无双数据出错");
            }
         };
         BgmModel.I.initByPath("assets/bgm/character");
         PluginModel.I.initByPath("assets/" + "plugin");
         AIModel.I.initByPath("assets/" + "ai");
         UpdateUtils.I.updateVersionText();
         AssetManager.I.loadXML("config/fighter.xml",loadFighterBack,loadFighterFail);
      }
      
      public function initData() : void
      {
         mosouData.init();
         GameData.I.loadSaveData();
      }
      
      public function saveData() : void
      {
         var _loc1_:Object = {};
         _loc1_.id = "BVN_SPORTS_SAVE";
         _loc1_.config = config.toSaveObj();
         _loc1_.mosou = mosouData.toSaveObj();
         GameInterface.instance.saveGame(_loc1_);
      }
      
      private function loadSaveData(param1:Boolean = false) : void
      {
         var _loc3_:Object = GameInterface.instance.loadGame();
         var _loc4_:Object = GameInterface.instance.loadRecord();
         var _loc2_:Boolean = _loc3_ == null || _loc3_.id != "BVN_SPORTS_SAVE";
         if(param1)
         {
            if(_loc2_)
            {
               throw new Error("GameData.loadSaveData::损坏的存档！");
            }
         }
         else if(_loc2_)
         {
            releaseSaveData();
            loadSaveData(true);
            return;
         }
         if(_loc3_.config)
         {
            config.readSaveObj(_loc3_.config);
         }
         if(_loc3_.mosou)
         {
            mosouData.readSaveObj(_loc3_.mosou);
         }
         if(_loc4_)
         {
            record.readSaveObj(_loc4_);
         }
      }
      
      public function loadSelect(param1:String) : void
      {
         var url:String = param1;
         AssetManager.I.loadXML(url,function(param1:XML):void
         {
            setSelectData(param1);
         });
      }
      
      public function loadDebugSelect(param1:String) : void
      {
         var url:String = param1;
         KyoURLoader.load(url,function(param1:String):void
         {
            setSelectData(new XML(param1));
         });
      }
      
      public function setSelectData(param1:XML) : void
      {
         config.select_config.setByXML(param1);
      }
      
      private function validateSelect() : void
      {
         var _loc1_:FighterVO = null;
         _loc1_ = null;
         var _loc2_:String = null;
         var _loc5_:Array = [];
         var _loc3_:Array = [];
         for each(var _loc6_ in config.select_config.charList.list)
         {
            for each(var _loc4_ in _loc6_.getAllFighterIDs())
            {
               _loc1_ = FighterModel.I.getFighter(_loc4_);
               if(_loc1_ == null)
               {
                  if(_loc5_.indexOf(_loc4_) == -1)
                  {
                     _loc5_.push(_loc4_);
                  }
               }
            }
         }
         for each(_loc6_ in config.select_config.assistList.list)
         {
            for each(_loc4_ in _loc6_.getAllFighterIDs())
            {
               _loc1_ = AssisterModel.I.getAssister(_loc4_);
               if(_loc1_ == null)
               {
                  if(_loc3_.indexOf(_loc4_) == -1)
                  {
                     _loc3_.push(_loc4_);
                  }
               }
            }
         }
         if(_loc5_.length > 0 || _loc3_.length > 0)
         {
            _loc2_ = "";
            if(_loc5_.length > 0)
            {
               _loc2_ += "fighter:" + _loc5_.join(" , ") + " ; ";
            }
            if(_loc3_.length > 0)
            {
               _loc2_ += "assister:" + _loc3_.join(" , ") + " ; ";
            }
            throw new Error("select.xml验证失败！ [" + _loc2_ + "]");
         }
      }
      
      private function validateMissionData() : void
      {
         var _loc11_:* = undefined;
         var _loc7_:FighterVO = null;
         var _loc2_:MapVO = null;
         var _loc3_:FighterVO = null;
         var _loc5_:String = null;
         var _loc6_:Array = [];
         var _loc1_:Array = [];
         var _loc9_:Array = [];
         var _loc4_:Array = MessionModel.I.getAllMissions();
         for each(var _loc8_ in _loc4_)
         {
            _loc11_ = _loc8_.stageList;
            for each(var _loc12_ in _loc11_)
            {
               for each(var _loc10_ in _loc12_.fighters)
               {
                  _loc7_ = FighterModel.I.getFighter(_loc10_);
                  if(_loc7_ == null)
                  {
                     if(_loc6_.indexOf(_loc10_) == -1)
                     {
                        _loc6_.push(_loc10_);
                     }
                  }
               }
               _loc2_ = MapModel.I.getMap(_loc12_.map);
               if(_loc2_ == null)
               {
                  if(_loc1_.indexOf(_loc12_.map) == -1)
                  {
                     _loc1_.push(_loc12_.map);
                  }
               }
               _loc3_ = AssisterModel.I.getAssister(_loc12_.assister);
               if(_loc3_ == null)
               {
                  if(_loc9_.indexOf(_loc12_.assister) == -1)
                  {
                     _loc9_.push(_loc12_.assister);
                  }
               }
            }
         }
         if(_loc6_.length > 0 || _loc9_.length > 0 || _loc1_.length > 0)
         {
            _loc5_ = "";
            if(_loc6_.length > 0)
            {
               _loc5_ += "fighter:" + _loc6_.join(" , ") + " ; ";
            }
            if(_loc9_.length > 0)
            {
               _loc5_ += "assister:" + _loc9_.join(" , ") + " ; ";
            }
            if(_loc1_.length > 0)
            {
               _loc5_ += "map:" + _loc1_.join(" , ") + " ; ";
            }
            throw new Error("mission.xml验证失败！ [" + _loc5_ + "]");
         }
      }
   }
}

