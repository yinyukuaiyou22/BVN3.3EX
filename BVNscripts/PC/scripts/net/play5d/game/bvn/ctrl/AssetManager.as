package net.play5d.game.bvn.ctrl
{
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.geom.Point;
   import flash.media.Sound;
   import flash.system.ApplicationDomain;
   import flash.system.System;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.AIModel;
   import net.play5d.game.bvn.data.AssisterModel;
   import net.play5d.game.bvn.data.FighterModel;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.MapModel;
   import net.play5d.game.bvn.data.MapVO;
   import net.play5d.game.bvn.data.PluginModel;
   import net.play5d.game.bvn.interfaces.IAssetLoader;
   import net.play5d.game.bvn.utils.BitmapAssetLoader;
   import net.play5d.game.bvn.utils.ExtendAssetLoader;
   import net.play5d.game.bvn.utils.ResUtils;
   import net.play5d.game.bvn.utils.ZipAssetLoader;
   import net.play5d.kyo.display.bitmap.BitmapFont;
   import net.play5d.kyo.display.bitmap.BitmapFontLoader;
   import net.play5d.kyo.loader.KyoClassLoader;
   import net.play5d.kyo.loader.KyoSoundLoader;
   import net.play5d.kyo.utils.KyoUtils;
   
   public class AssetManager
   {
      
      private static var _i:AssetManager;
      
      private var _swfLoader:KyoClassLoader = new KyoClassLoader();
      
      private var _soundLoader:KyoSoundLoader = new KyoSoundLoader();
      
      private var _bitmapLoader:BitmapAssetLoader = new BitmapAssetLoader();
      
      private var _bitmapFontLoader:BitmapFontLoader = new BitmapFontLoader();
      
      private var _assetLoader:IAssetLoader = null;
      
      public const ASSETS_DIR:String = "assets/";
      
      public const ZIP_FILE_DIR:String = "assets/zips/";
      
      public const fontZipPath:String = "assets/zips/font.zip";
      
      public const libsZipPath:String = "assets/zips/libs.zip";
      
      public const soundsZipPath:String = "assets/zips/sounds.zip";
      
      public const effectSwfPath:String = "effect.swf";
      
      public const bitmapSwfPath:String = "bitmap.swf";
      
      public const PLUGIN_SWF_NAME:String = "plugin";
      
      public const PLUGIN_SWF_DIR:String = "plugin/";
      
      public const AI_SWF_NAME:String = "ai";
      
      public const AI_SWF_DIR:String = "ai/";
      
      public const LIB_SWF_DIR:String = "libs/";
      
      public const textLayoutSwfPath:String = "libs/textLayout.swf";
      
      public const uiSwfPath:String = "libs/User Interface.swf";
      
      public const evalSwfPath:String = "libs/EvalES4.swf";
      
      public const SUB_SWF_DIR:String = "subswfs/";
      
      public const loadingSwfPath:String = "assets/subswfs/loading.swf";
      
      public const backSwfPath:String = "subswfs/back.swf";
      
      public const howToPlaySwfPath:String = "subswfs/howtoplay.swf";
      
      public const bigMapSwfPath:String = "subswfs/bigmap.swf";
      
      public const commonSwfPath:String = "subswfs/common_ui.swf";
      
      public const titleSwfPath:String = "subswfs/title.swf";
      
      public const fightSwfPath:String = "subswfs/fight.swf";
      
      public const settingSwfPath:String = "subswfs/setting.swf";
      
      public const winuiSwfPath:String = "subswfs/win_ui.swf";
      
      public const ruleSwfPath:String = "subswfs/rule.swf";
      
      public const gameoverSwfPath:String = "subswfs/gameover.swf";
      
      public const selectSwfPath:String = "subswfs/select.swf";
      
      public const dialoguiSwfPath:String = "subswfs/dialog_ui.swf";
      
      public const musouSwfPath:String = "subswfs/musou.swf";
      
      private var _fighterFaceCache:Object = {};
      
      public var pluginSwf:Array = [];
      
      public var aiSwf:Array = [];
      
      private var _loadLibPath:Array = ["libs/textLayout.swf","libs/User Interface.swf","libs/EvalES4.swf"];
      
      public var loadSubSwfPath:Array = ["effect.swf","subswfs/back.swf","subswfs/howtoplay.swf","subswfs/bigmap.swf","subswfs/common_ui.swf","subswfs/title.swf","subswfs/fight.swf","subswfs/setting.swf","subswfs/win_ui.swf","subswfs/rule.swf","subswfs/gameover.swf","subswfs/select.swf","subswfs/dialog_ui.swf","subswfs/musou.swf"];
      
      public function AssetManager()
      {
         super();
      }
      
      public static function get I() : AssetManager
      {
         if(!_i)
         {
            _i = new AssetManager();
         }
         return _i;
      }
      
      private static function getMapPicUrls(param1:Object) : Array
      {
         var _loc3_:Array = [];
         for each(var _loc2_ in param1)
         {
            _loc3_.push(_loc2_.picUrl);
         }
         return _loc3_;
      }
      
      public function init(param1:Function) : void
      {
         var back:Function = param1;
         var next:* = function():void
         {
            var loadLoadingSucc:* = function(param1:Event):void
            {
               _swfLoader.removeEventListener("complete",loadLoadingSucc);
               _swfLoader.removeEventListener("ioError",loadLoadingFail);
               back();
            };
            var loadLoadingFail:* = function(param1:IOErrorEvent):void
            {
               throw new Error("加载【加载UI】失败！");
            };
            _swfLoader.addEventListener("complete",loadLoadingSucc);
            _swfLoader.addEventListener("ioError",loadLoadingFail);
            _swfLoader.load("assets/subswfs/loading.swf");
         };
         if(_assetLoader != null)
         {
            return;
         }
         _assetLoader = new ExtendAssetLoader(ResUtils.I.getItemProperty(ResUtils.I.extend,"assetLoader"));
         next();
      }
      
      public function getFont(param1:String) : BitmapFont
      {
         return _bitmapFontLoader.getFont(param1);
      }
      
      public function setAssetLoader(param1:IAssetLoader) : void
      {
         _assetLoader = param1;
      }
      
      public function loadBasic(param1:Function, param2:Function = null) : void
      {
         var type:String;
         var back:Function = param1;
         var process:Function = param2;
         var loadProcess:* = function(param1:Number):void
         {
            if(process != null)
            {
               process(param1,type,loadStep,loadCount);
            }
         };
         var loadNext:* = function():void
         {
            var _loc1_:Function = null;
            switch(loadStep)
            {
               case 0:
                  loadPreLoadSounds(loadNext,loadProcess);
                  type = GetLangText("stage_loading.preload.type.sounds");
                  loadProcess(0);
                  break;
               case 1:
                  loadLibrary(_loadLibPath,loadNext,loadProcess);
                  type = GetLangText("stage_loading.preload.type.library");
                  loadProcess(0);
                  break;
               case 2:
                  if(GameConfig.IS_QUICK_LOAD)
                  {
                     loadSubSwfPath.push("bitmap.swf");
                  }
                  loadGraphics(loadSubSwfPath,loadNext,loadProcess);
                  type = GetLangText("stage_loading.preload.type.effect");
                  loadProcess(0);
                  break;
               case 3:
                  loadFonts(loadNext,loadProcess);
                  type = GetLangText("stage_loading.preload.type.fonts");
                  loadProcess(0);
                  break;
               case 4:
                  type = GetLangText("stage_loading.preload.type.bitmaps");
                  _loc1_ = GameConfig.IS_QUICK_LOAD ? loadBitmapsByClass : loadBitmaps;
                  _loc1_(loadNext,loadProcess);
                  loadProcess(0);
                  break;
               case 5:
                  initAssets();
                  if(back != null)
                  {
                     back();
                  }
            }
            loadStep = loadStep + 1;
         };
         var loadStep:int = 0;
         var loadCount:int = 5;
         loadNext();
      }
      
      private function loadPreLoadSounds(param1:Function, param2:Function) : void
      {
         var back:Function = param1;
         var process:Function = param2;
         _assetLoader.loadXML("config/preload.xml",function(param1:XML):void
         {
            var bgm:XML;
            var sound:XML;
            var config:XML = param1;
            var soundPaths1:Array = [];
            var soundPaths2:Array = [];
            var bgmDir:String = config.bgm.@path;
            var soundDir:String = config.sound.@path;
            for each(bgm in config.bgm.item)
            {
               soundPaths1.push(bgmDir + "/" + bgm.toString());
            }
            for each(sound in config.sound.item)
            {
               soundPaths2.push(soundDir + "/" + sound.toString());
            }
            System.disposeXML(config);
            loadSnds(soundPaths1,function():void
            {
               var next:* = function(param1:ZipAssetLoader, param2:String, param3:Function, param4:Function, param5:Function):void
               {
                  param1.loadSound(param2,param3,param4,param5);
               };
               var com:* = function(param1:String, param2:Sound):void
               {
                  _soundLoader.addSound(param1,param2);
               };
               ZipAssetLoader.loadGeneral("assets/zips/sounds.zip",soundPaths2,next,com,back,process,0.5,0.5);
            },process);
         });
      }
      
      private function loadSnds(param1:Array, param2:Function, param3:Function) : void
      {
         var curUrl:String;
         var sounds:Array = param1;
         var back:Function = param2;
         var process:Function = param3;
         var loadNext:* = function():void
         {
            if(snds.length < 1)
            {
               if(back != null)
               {
                  back();
               }
               return;
            }
            curUrl = snds.shift();
            _assetLoader.loadSound(curUrl,loadCom,loadErr,loadProcess);
         };
         var loadCom:* = function(param1:Sound):void
         {
            _soundLoader.addSound(curUrl,param1);
            _assetLoader.dispose(curUrl);
            loadNext();
         };
         var loadErr:* = function():void
         {
            loadNext();
         };
         var loadProcess:* = function(param1:Number):void
         {
            var _loc3_:Number = NaN;
            var _loc2_:Number = NaN;
            if(process != null)
            {
               _loc3_ = sndLen - snds.length - 1 + param1;
               _loc2_ = _loc3_ / sndLen;
               process(_loc2_ * 0.5);
            }
         };
         var snds:Array = sounds.concat();
         var sndLen:int = int(snds.length);
         loadNext();
      }
      
      private function initAssets() : void
      {
         var _loc1_:BitmapFont = getFont("font1");
         if(_loc1_ == null)
         {
            return;
         }
         _loc1_.charGap = -8;
         _loc1_.spaceGap = 10;
         _loc1_.offsetY = -5;
      }
      
      public function getSWFEffectClass(param1:String, param2:String) : Class
      {
         var _loc3_:Class = _swfLoader.getClass(param1,param2);
         if(_loc3_ == null)
         {
            throw new Error("AssetManager::getSWFEffectClass出错！没有找到" + param1 + "的定义！");
         }
         return _loc3_;
      }
      
      public function createObject(param1:String, param2:String) : *
      {
         var _loc3_:Class = getSWFEffectClass(param1,param2);
         if(_loc3_ == null)
         {
            throw new Error("AssetManager::createObject出错！没有找到" + param1 + "的定义！");
         }
         return new _loc3_();
      }
      
      public function getEffect(param1:String) : *
      {
         var _loc2_:Class = _swfLoader.getClass(param1,"effect.swf");
         return new _loc2_();
      }
      
      public function getSound(param1:String) : Sound
      {
         return _soundLoader.getSound(param1);
      }
      
      public function getFighterFace(param1:FighterVO, param2:Point = null) : DisplayObject
      {
         var _loc3_:Bitmap = _bitmapLoader.getBitmap(param1.faceUrl);
         if(!_loc3_)
         {
            return null;
         }
         if(!param2)
         {
            param2 = new Point(50,50);
         }
         _loc3_.width = param2.x;
         _loc3_.height = param2.y;
         return _loc3_;
      }
      
      public function getFighterFaceBig(param1:FighterVO, param2:Point = null) : DisplayObject
      {
         var _loc3_:Bitmap = _bitmapLoader.getBitmap(param1.faceBigUrl);
         if(!_loc3_)
         {
            return null;
         }
         if(!param2)
         {
            param2 = new Point(245,62);
         }
         _loc3_.width = param2.x;
         _loc3_.height = param2.y;
         return _loc3_;
      }
      
      public function getFighterFaceBar(param1:FighterVO, param2:Point = null) : DisplayObject
      {
         var _loc3_:Bitmap = _bitmapLoader.getBitmap(param1.faceBarUrl);
         if(!_loc3_)
         {
            return null;
         }
         if(!param2)
         {
            param2 = new Point(102,64);
         }
         _loc3_.width = param2.x;
         _loc3_.height = param2.y;
         return _loc3_;
      }
      
      public function getFighterFaceWin(param1:FighterVO, param2:Point = null) : DisplayObject
      {
         if(!param1)
         {
            return null;
         }
         if(!param1.faceWinUrl)
         {
            return null;
         }
         var _loc3_:Bitmap = _bitmapLoader.getBitmap(param1.faceWinUrl);
         if(!_loc3_)
         {
            return null;
         }
         if(!param2)
         {
            param2 = new Point(300,250);
         }
         _loc3_.width = param2.x;
         _loc3_.height = param2.y;
         return _loc3_;
      }
      
      public function getMapPic(param1:MapVO, param2:Point = null) : DisplayObject
      {
         var _loc3_:Bitmap = _bitmapLoader.getBitmap(param1.picUrl);
         if(!_loc3_)
         {
            return null;
         }
         if(!param2)
         {
            param2 = new Point(450,240);
         }
         _loc3_.width = param2.x;
         _loc3_.height = param2.y;
         return _loc3_;
      }
      
      public function loadXML(param1:String, param2:Function, param3:Function = null) : void
      {
         _assetLoader.loadXML(param1,param2,param3);
      }
      
      public function loadJSON(param1:String, param2:Function, param3:Function = null) : void
      {
         _assetLoader.loadJSON(param1,param2,param3);
      }
      
      public function loadSwf(param1:String, param2:Function, param3:Function = null, param4:Function = null, param5:ApplicationDomain = null) : void
      {
         _assetLoader.loadSwf(param1,param2,param3,param4,param5);
      }
      
      public function loadSound(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         _assetLoader.loadSound(param1,param2,param3,param4);
      }
      
      public function loadBitmap(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         _assetLoader.loadBitmap(param1,param2,param3,param4);
      }
      
      public function disposeAsset(param1:String) : void
      {
         _assetLoader.dispose(param1);
      }
      
      private function loadLibrary(param1:Array, param2:Function = null, param3:Function = null) : void
      {
         var loadArray:Array = param1;
         var back:Function = param2;
         var process:Function = param3;
         var next:* = function(param1:ZipAssetLoader, param2:String, param3:Function, param4:Function, param5:Function):void
         {
            param1.loadSwf(param2,param3,param4,param5,ApplicationDomain.currentDomain);
         };
         var com:* = function(param1:String, param2:Loader):void
         {
            _swfLoader.addSwf(param1,param2);
         };
         ZipAssetLoader.loadGeneral("assets/zips/libs.zip",loadArray,next,com,back,process);
      }
      
      private function loadGraphics(param1:Array, param2:Function = null, param3:Function = null) : void
      {
         var curUrl:String;
         var loadArray:Array = param1;
         var back:Function = param2;
         var process:Function = param3;
         var loadNext:* = function():void
         {
            if(loads.length < 1)
            {
               PluginModel.I.initBySwfIdArray(pluginSwf);
               AIModel.I.initBySwfIdArray(aiSwf);
               if(back != null)
               {
                  back();
               }
               return;
            }
            curUrl = loads.shift();
            if(curUrl.indexOf("plugin/") != -1)
            {
               pluginSwf.push(curUrl);
            }
            if(curUrl.indexOf("ai/") != -1)
            {
               aiSwf.push(curUrl);
            }
            _assetLoader.loadSwf(curUrl,loadCom,loadFail,loadProcess);
         };
         var loadCom:* = function(param1:Loader):void
         {
            loadedAmount = loadedAmount + 1;
            _swfLoader.addSwf(curUrl,param1);
            _assetLoader.dispose(curUrl);
            loadNext();
         };
         var loadFail:* = function():void
         {
            loadNext();
         };
         var loadProcess:* = function(param1:Number):void
         {
            var _loc2_:Number = NaN;
            if(process != null)
            {
               _loc2_ = queueLength - loads.length - 1 + param1;
               process(_loc2_ / queueLength);
            }
         };
         var loadedAmount:int = 0;
         var loads:Array = loadArray.concat();
         var queueLength:int = int(loads.length);
         loadNext();
      }
      
      private function loadBitmaps(param1:Function = null, param2:Function = null) : void
      {
         var _loc3_:Array = getFighterFaceUrls(FighterModel.I.getAllFighters(),true,true);
         _loc3_ = _loc3_.concat(getFighterFaceUrls(AssisterModel.I.getAllAssisters()));
         _loc3_ = _loc3_.concat(getMapPicUrls(MapModel.I.getAllMaps()));
         KyoUtils.array_deleteSames(_loc3_);
         _bitmapLoader.loadQueue(_loc3_,param1,param2);
      }
      
      private function loadBitmapsByClass(param1:Function = null, param2:Function = null) : void
      {
         var _loc3_:Array = getFighterFaceClass(FighterModel.I.getAllFighters());
         _loc3_ = _loc3_.concat(getFighterFaceClass(AssisterModel.I.getAllAssisters()));
         _loc3_ = _loc3_.concat(getMapPicUrls(MapModel.I.getAllMaps()));
         KyoUtils.array_deleteSames(_loc3_);
         _bitmapLoader.loadQueue(_loc3_,param1,param2);
      }
      
      private function loadFonts(param1:Function = null, param2:Function = null) : void
      {
         var back:Function = param1;
         var process:Function = param2;
         var next:* = function():void
         {
            var loadCom:* = function(param1:XML):void
            {
               var fontXml:XML = param1;
               var bitmapCom:* = function(param1:Bitmap):void
               {
                  var _loc2_:Bitmap = param1 as Bitmap;
                  _bitmapFontLoader.addFont(fontXml,_loc2_.bitmapData);
                  _assetLoader.dispose(fontBitmapUrl);
                  fontZip.destory();
                  fontZip = null;
                  System.disposeXML(fontXml);
                  if(back != null)
                  {
                     back();
                  }
               };
               var bitmapFail:* = function():void
               {
               };
               var filePath:String = fontXml.pages.page.@file;
               var fileFolder:String = url.substr(0,url.lastIndexOf("/") + 1);
               var fontBitmapUrl:String = fileFolder + filePath;
               fontZip.loadBitmap(fontBitmapUrl,bitmapCom,bitmapFail,process);
            };
            var loadFail:* = function():void
            {
            };
            fontZip.loadXML(url,loadCom,loadFail);
         };
         var fail:* = function():void
         {
         };
         var url:String = "font/font1.xml";
         var fontZip:ZipAssetLoader = new ZipAssetLoader("assets/zips/font.zip",next,fail);
      }
      
      private function getFighterFaceUrls(param1:Object, param2:Boolean = false, param3:Boolean = false) : Array
      {
         var _loc5_:Array = [];
         for each(var _loc4_ in param1)
         {
            if(_loc4_.faceUrl)
            {
               _loc5_.push(_loc4_.faceUrl);
            }
            if(_loc4_.faceBigUrl)
            {
               _loc5_.push(_loc4_.faceBigUrl);
            }
            if(param2 && _loc4_.faceBarUrl)
            {
               _loc5_.push(_loc4_.faceBarUrl);
            }
            if(param3 && _loc4_.faceWinUrl)
            {
               _loc5_.push(_loc4_.faceWinUrl);
            }
         }
         return _loc5_;
      }
      
      private function getFighterFaceClass(param1:Object) : Array
      {
         var FACE:String;
         var i:FighterVO;
         var fighters:Object = param1;
         var push:* = function(param1:String):void
         {
            var _loc4_:int = param1.indexOf(".");
            var _loc2_:int = _loc4_ - "face/".length;
            var _loc3_:String = param1.substr("face/".length,_loc2_);
            ra.push(param1 + "|" + _loc3_);
         };
         var ra:Array = [];
         for each(i in fighters)
         {
            if(i.faceUrl)
            {
               push(i.faceUrl);
            }
            if(i.faceBigUrl)
            {
               push(i.faceBigUrl);
            }
            if(i.faceBarUrl)
            {
               push(i.faceBarUrl);
            }
            if(i.faceWinUrl)
            {
               push(i.faceWinUrl);
            }
         }
         return ra;
      }
      
      public function needPreLoad() : Boolean
      {
         return _assetLoader.needPreLoad();
      }
      
      public function loadPreLoad(param1:Function, param2:Function = null, param3:Function = null) : void
      {
         _assetLoader.loadPreLoad(param1,param2,param3);
      }
   }
}

