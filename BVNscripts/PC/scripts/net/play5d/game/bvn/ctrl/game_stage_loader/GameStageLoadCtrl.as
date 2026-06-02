package net.play5d.game.bvn.ctrl.game_stage_loader
{
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.system.ApplicationDomain;
   import net.play5d.game.bvn.ctrl.GameLoader;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.data.AssisterModel;
   import net.play5d.game.bvn.data.BgmModel;
   import net.play5d.game.bvn.data.BgmVO;
   import net.play5d.game.bvn.data.FighterModel;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.MapModel;
   import net.play5d.game.bvn.data.MapVO;
   
   public class GameStageLoadCtrl extends EventDispatcher
   {
      
      private static var _i:GameStageLoadCtrl;
      
      private var _loadingType:int;
      
      private var _fighterCache:Object;
      
      private var _assisterCache:Object;
      
      private var _mapCache:Object;
      
      private var _processCallBack:Function;
      
      private var _errorCallBack:Function;
      
      private var _loadStep:int;
      
      private var _loadStepLength:int;
      
      private var _curLoadStep:int;
      
      private var _curLoadStepLength:int;
      
      private var _curLoadName:String;
      
      public function GameStageLoadCtrl()
      {
         super();
      }
      
      public static function get I() : GameStageLoadCtrl
      {
         if(!_i)
         {
            _i = new GameStageLoadCtrl();
         }
         return _i;
      }
      
      public function init(param1:Function = null, param2:Function = null) : void
      {
         _fighterCache = {};
         _assisterCache = {};
         _mapCache = {};
         _loadStep = 0;
         _curLoadStep = 0;
         _processCallBack = param1;
         _errorCallBack = param2;
      }
      
      public function dispose() : void
      {
         _fighterCache = null;
         _assisterCache = null;
         _mapCache = null;
      }
      
      public function getFighterMc(param1:String, param2:String) : MovieClip
      {
         var _loc5_:Class = null;
         var _loc3_:Object = _fighterCache[param1];
         var _loc4_:ApplicationDomain = _loc3_.domain;
         if(_loc4_ == null)
         {
            return null;
         }
         try
         {
            _loc5_ = _loc4_.getDefinition("main_mc") as Class;
            return new _loc5_();
         }
         catch(e:Error)
         {
            if(param2 == "1" && _loc3_.mc != null)
            {
               return _loc3_.mc;
            }
            var _loc10_:* = _loc3_.mcSlave;
         }
         return _loc10_;
      }
      
      public function getAssisterMc(param1:String, param2:String) : MovieClip
      {
         var _loc5_:Class = null;
         var _loc3_:Object = _assisterCache[param1];
         var _loc4_:ApplicationDomain = _loc3_.domain;
         if(_loc4_ == null)
         {
            return null;
         }
         try
         {
            _loc5_ = _loc4_.getDefinition("main_mc") as Class;
            return new _loc5_();
         }
         catch(e:Error)
         {
            if(param2 == "1" && _loc3_.mc != null)
            {
               return _loc3_.mc;
            }
            var _loc10_:* = _loc3_.mcSlave;
         }
         return _loc10_;
      }
      
      public function getMapMc(param1:String) : MovieClip
      {
         return _mapCache[param1];
      }
      
      public function loadGame(param1:Array, param2:Array, param3:Array, param4:Array, param5:Function = null) : void
      {
         var id:String;
         var mv:MapVO;
         var fv:FighterVO;
         var av:FighterVO;
         var bHasLocalMusic:Boolean;
         var bv:BgmVO;
         var id_truncated:String;
         var maps:Array = param1;
         var fighters:Array = param2;
         var assisters:Array = param3;
         var bgms:Array = param4;
         var finishBack:Function = param5;
         _loadStep = 0;
         _loadStepLength = 0;
         var mapDatas:Vector.<MapVO> = null;
         var fighterDatas:Vector.<FighterVO> = null;
         var assisterDatas:Vector.<FighterVO> = null;
         var bgmDatas:Vector.<BgmVO> = null;
         _loadStepLength = _loadStepLength + 1;
         if(maps != null)
         {
            maps = unique(maps);
            mapDatas = new Vector.<MapVO>();
            for each(id in maps)
            {
               mv = MapModel.I.getMap(id);
               if(!mv)
               {
                  throw new Error("获取地图数据失败！");
               }
               mapDatas.push(mv);
            }
         }
         _loadStepLength = _loadStepLength + 1;
         if(fighters != null)
         {
            fighters = unique(fighters);
            fighterDatas = new Vector.<FighterVO>();
            for each(id in fighters)
            {
               fv = FighterModel.I.getFighter(id);
               if(!fv)
               {
                  throw new Error("获取角色数据失败！");
               }
               fighterDatas.push(fv);
            }
         }
         _loadStepLength = _loadStepLength + 1;
         if(assisters != null)
         {
            assisters = unique(assisters);
            assisterDatas = new Vector.<FighterVO>();
            for each(id in assisters)
            {
               av = AssisterModel.I.getAssister(id);
               if(!av)
               {
                  throw new Error("获取辅助角色数据失败！");
               }
               assisterDatas.push(av);
            }
         }
         _loadStepLength = _loadStepLength + 1;
         if(bgms != null)
         {
            bgms = unique(bgms);
            bHasLocalMusic = BgmModel.I.getBgms().length > 0;
            bgmDatas = new Vector.<BgmVO>();
            if(bHasLocalMusic && !GameData.I.config.isClassicalBgm)
            {
               bgmDatas = BgmModel.I.getBgms();
               for each(id in bgms)
               {
                  bv = BgmModel.I.getBgm(id);
                  if(!bv)
                  {
                     id_truncated = id.split("_")[0];
                     bv = BgmModel.I.getBgm(id_truncated);
                     if(bv)
                     {
                        bv = bv.clone();
                        bv.id = id;
                        bgmDatas.push(bv);
                     }
                     else
                     {
                        bv = BgmModel.I.getRandomBgm();
                        if(bv)
                        {
                           bv = bv.clone();
                           if(MapModel.I.isMap(id))
                           {
                              bv.id = "map";
                           }
                           else
                           {
                              bv.id = id;
                           }
                        }
                        if(!bv)
                        {
                           bv = FighterModel.I.getFighterBGM(id);
                        }
                        if(!bv)
                        {
                           bv = MapModel.I.getMapBGM(id);
                        }
                        if(!bv)
                        {
                           bv = FighterModel.I.getFighterBGM(id);
                        }
                        if(!bv)
                        {
                           bv = FighterModel.I.getBossBGM(id);
                        }
                        if(bv)
                        {
                           bgmDatas.push(bv);
                        }
                     }
                  }
               }
            }
            else
            {
               for each(id in bgms)
               {
                  bv = FighterModel.I.getFighterBGM(id);
                  if(!bv)
                  {
                     bv = MapModel.I.getMapBGM(id);
                  }
                  if(!bv)
                  {
                     bv = FighterModel.I.getFighterBGM(id);
                  }
                  if(!bv)
                  {
                     bv = FighterModel.I.getBossBGM(id);
                  }
                  if(bv)
                  {
                     bgmDatas.push(bv);
                  }
               }
            }
         }
         _loadStep = 1;
         loadMaps(convertLoadAssets(mapDatas,{
            "id":"id",
            "name":"name",
            "url":"fileUrl"
         }),function():void
         {
            loadFighters(convertLoadAssets(fighterDatas,{
               "id":"id",
               "name":"name",
               "url":"fileUrl"
            }),function():void
            {
               loadAssisters(convertLoadAssets(assisterDatas,{
                  "id":"id",
                  "name":"name",
                  "url":"fileUrl"
               }),function():void
               {
                  loadBgms(bgmDatas,function():void
                  {
                     if(finishBack != null)
                     {
                        finishBack();
                     }
                  });
               });
            });
         });
      }
      
      private function loadMaps(param1:Vector.<LoadAssetVO>, param2:Function) : void
      {
         var maps:Vector.<LoadAssetVO> = param1;
         var callback:Function = param2;
         var load:* = function(param1:LoadAssetVO, param2:Function):void
         {
            var lv:LoadAssetVO = param1;
            var succBack:Function = param2;
            var loadSucc:* = function(param1:Loader):void
            {
               _mapCache[lv.url] = param1.content;
               disposeLoader(param1);
               succBack();
            };
            GameLoader.loadSWF(lv.url,loadSucc,onLoadError,onLoadProcess);
         };
         _loadingType = 0;
         loadAssets(maps,load,callback);
      }
      
      private function loadFighters(param1:Vector.<LoadAssetVO>, param2:Function) : void
      {
         var fighters:Vector.<LoadAssetVO> = param1;
         var callback:Function = param2;
         var load:* = function(param1:LoadAssetVO, param2:Function):void
         {
            var lv:LoadAssetVO = param1;
            var succBack:Function = param2;
            var loadSucc:* = function(param1:Loader):void
            {
               _fighterCache[lv.url] = {
                  "domain":param1.contentLoaderInfo.applicationDomain,
                  "mc":null
               };
               disposeLoader(param1);
               succBack();
            };
            GameLoader.loadSWF(lv.url,loadSucc,onLoadError,onLoadProcess);
         };
         _loadingType = 1;
         loadAssets(fighters,load,callback);
      }
      
      private function loadAssisters(param1:Vector.<LoadAssetVO>, param2:Function) : void
      {
         var assissters:Vector.<LoadAssetVO> = param1;
         var callback:Function = param2;
         var load:* = function(param1:LoadAssetVO, param2:Function):void
         {
            var lv:LoadAssetVO = param1;
            var succBack:Function = param2;
            var loadSucc:* = function(param1:Loader):void
            {
               _assisterCache[lv.url] = {
                  "domain":param1.contentLoaderInfo.applicationDomain,
                  "mc":null
               };
               disposeLoader(param1);
               succBack();
            };
            GameLoader.loadSWF(lv.url,loadSucc,onLoadError,onLoadProcess);
         };
         _loadingType = 2;
         loadAssets(assissters,load,callback);
      }
      
      private function loadBgms(param1:Vector.<BgmVO>, param2:Function) : void
      {
         var bgms:Vector.<BgmVO> = param1;
         var callback:Function = param2;
         var succBack:* = function():void
         {
            _loadStep = _loadStep + 1;
            _curLoadName = null;
            callback();
         };
         if(!bgms)
         {
            callback();
            return;
         }
         _loadingType = 3;
         _curLoadStep = 0;
         _curLoadStepLength = 1;
         SoundCtrl.I.loadFightBGM(bgms,succBack,callback,onLoadProcess);
      }
      
      private function onLoadProcess(param1:Number) : void
      {
         var _loc4_:String = null;
         switch(_loadingType)
         {
            case 0:
               _loc4_ = GetLangText("stage_loading.load_fighter.type.maps");
               break;
            case 1:
               _loc4_ = GetLangText("stage_loading.load_fighter.type.fighter");
               break;
            case 2:
               _loc4_ = GetLangText("stage_loading.load_fighter.type.assistant");
               break;
            case 3:
               _loc4_ = GetLangText("stage_loading.load_fighter.type.bgm");
               break;
            default:
               _loc4_ = GetLangText("stage_loading.load_fighter.type.undefined");
         }
         var _loc2_:String = GetLangText("stage_loading.load_fighter.loading_tip") + " - " + _loc4_;
         if(_curLoadName)
         {
            _loc2_ += " : " + _curLoadName;
         }
         _loc2_ += " (" + _loadStep + "/" + _loadStepLength + ")";
         var _loc3_:Number = (_curLoadStep + param1) / _curLoadStepLength;
         if(_loadingType == 3)
         {
            _loc3_ = 1;
         }
         _processCallBack(_loc2_,_loc3_);
      }
      
      private function onLoadError(param1:String) : void
      {
         _errorCallBack(param1);
      }
      
      private function disposeLoader(param1:Loader) : void
      {
         try
         {
            param1.unloadAndStop(true);
         }
         catch(e:Error)
         {
            try
            {
               param1.unload();
            }
            catch(e2:Error)
            {
            }
         }
      }
      
      private function unique(param1:*) : Array
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Array = [];
         _loc2_ = 0;
         while(_loc2_ < param1.length)
         {
            if(!(param1[_loc2_] === null || param1[_loc2_] === undefined))
            {
               _loc3_ = _loc2_ + 1;
               while(_loc3_ < param1.length)
               {
                  if(param1[_loc2_] == param1[_loc3_])
                  {
                     _loc2_++;
                  }
                  _loc3_++;
               }
               _loc4_.push(param1[_loc2_]);
            }
            _loc2_++;
         }
         return _loc4_;
      }
      
      private function loadAssets(param1:Vector.<LoadAssetVO>, param2:Function, param3:Function) : void
      {
         var currentAsset:LoadAssetVO;
         var assets:Vector.<LoadAssetVO> = param1;
         var loadFunc:Function = param2;
         var callback:Function = param3;
         var loadNext:* = function():void
         {
            if(assets.length < 1)
            {
               _loadStep = _loadStep + 1;
               _curLoadName = null;
               callback();
               return;
            }
            var _loc1_:LoadAssetVO = assets.shift();
            currentAsset = _loc1_;
            _curLoadName = _loc1_.name;
            loadFunc(_loc1_,loadSucess);
         };
         var loadSucess:* = function():void
         {
            _curLoadStep = _curLoadStep + 1;
            loadNext();
         };
         if(!assets)
         {
            callback();
            return;
         }
         _curLoadStep = 0;
         _curLoadStepLength = assets.length;
         loadNext();
      }
      
      private function convertLoadAssets(param1:*, param2:Object) : Vector.<LoadAssetVO>
      {
         var _loc6_:LoadAssetVO = null;
         var _loc8_:String = null;
         var _loc3_:Vector.<LoadAssetVO> = new Vector.<LoadAssetVO>();
         var _loc4_:Object = {};
         for each(var _loc5_ in param1)
         {
            _loc6_ = new LoadAssetVO();
            for(var _loc7_ in param2)
            {
               _loc8_ = String(param2[_loc7_]);
               _loc6_[_loc7_] = _loc5_[_loc8_];
            }
            if(!_loc4_[_loc6_.url])
            {
               _loc4_[_loc6_.url] = _loc6_;
               _loc3_.push(_loc6_);
            }
         }
         return _loc3_;
      }
   }
}

class LoadAssetVO
{
   
   public var id:String;
   
   public var url:String;
   
   public var name:String;
   
   public function LoadAssetVO()
   {
      super();
   }
}
