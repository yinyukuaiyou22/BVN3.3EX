package net.play5d.game.bvn.ctrl
{
   import flash.display.*;
   import flash.geom.*;
   import flash.media.Sound;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.interfaces.IAssetLoader;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.bitmap.*;
   import net.play5d.kyo.loader.*;
   import net.play5d.game.bvn.Debugger;
   import net.play5d.kyo.utils.*;
   
   public class AssetManager
   {
      
      private static var _i:AssetManager;
      
      private var _swfLoader:KyoClassLoader = new KyoClassLoader();
      
      private var _soundLoader:KyoSoundLoader = new KyoSoundLoader();
      
      private var _bitmapLoader:BitmapAssetLoader = new BitmapAssetLoader();
      
      private var _bitmapFontLoader:BitmapFontLoader = new BitmapFontLoader();
      
      private var _assetLoader:IAssetLoader = new AssetLoader();
      
      private const _effectSwfPath:String = "assets/effect.swf";
      
      private var _fighterFaceCache:Object = {};
      
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
      
      public function getFont(param1:String) : BitmapFont
      {
         return this._bitmapFontLoader.getFont(param1);
      }
      
      public function setAssetLoader(param1:IAssetLoader) : void
      {
         this._assetLoader = param1;
      }
      
      public function loadBasic(param1:Function, param2:Function = null) : void
      {
         trace("[AssetManager] loadBasic start");
         var type:String = null;
         var back:Function = null;
         var process:Function = null;
         var loadProcess:* = undefined;
         var loadNext:* = undefined;
         var loadStep:int = 0;
         var loadCount:int = 0;
         back = param1;
         process = param2;
         loadProcess = function(param1:Number):void
         {
            if(process != null)
            {
               process(param1,type,loadStep,loadCount);
            }
         };
         loadNext = function():void
         {
            switch(loadStep)
            {
               case 0:
                  trace("[AssetManager] step 0: loading sounds...");
                  loadPreLoadSounds(loadNext,loadProcess);
                  type = "声音";
                  loadProcess(0);
                  break;
               case 1:
                  trace("[AssetManager] step 1: loading effect.swf...");
                  loadGraphics(["assets/effect.swf"],loadNext,loadProcess);
                  type = "特效";
                  loadProcess(0);
                  break;
               case 2:
                  trace("[AssetManager] step 2: loading fonts...");
                  loadFonts(loadNext,loadProcess);
                  type = "字体";
                  loadProcess(0);
                  break;
               case 3:
                  trace("[AssetManager] step 3: loading bitmaps...");
                  loadBitmaps(loadNext,loadProcess);
                  type = "图片";
                  loadProcess(0);
                  break;
               case 4:
                  trace("[AssetManager] step 4: init complete");
                  initAssets();
                  if(back != null)
                  {
                     back();
                  }
            }
            ++loadStep;
         };
         loadStep = 0;
         loadCount = 4;
         loadNext();
      }
      
      private function loadPreLoadSounds(param1:Function, param2:Function) : void
      {
         var back:Function = null;
         var process:Function = null;
         back = param1;
         process = param2;
         this._assetLoader.loadXML("assets/config/preload.xml",function(param1:XML):void
         {
            var _loc5_:* = undefined;
            var _loc6_:* = undefined;
            var _loc2_:Array = [];
            var _loc3_:String = param1.bgm.@path;
            var _loc4_:String = param1.sound.@path;
            for each(_loc5_ in param1.bgm.item)
            {
               _loc2_.push(_loc3_ + "/" + _loc5_.toString());
            }
            for each(_loc6_ in param1.sound.item)
            {
               _loc2_.push(_loc4_ + "/" + _loc6_.toString());
            }
            loadSnds(_loc2_,back,process);
         });
      }
      
      private function loadSnds(param1:Array, param2:Function, param3:Function) : void
      {
         var curUrl:String = null;
         var back:Function = null;
         var process:Function = null;
         var loadCom:* = undefined;
         var loadErr:* = undefined;
         var loadProcess:* = undefined;
         var snds:Array = null;
         var sndLen:int = 0;
         var sounds:Array = param1;
         back = param2;
         process = param3;
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
         loadCom = function(param1:Sound):void
         {
            _soundLoader.addSound(curUrl,param1);
            _assetLoader.dispose(curUrl);
            loadNext();
         };
         loadErr = function():void
         {
            Debugger.log("加载声音失败 : " + curUrl);
            loadNext();
         };
         loadProcess = function(param1:Number):void
         {
            var _loc2_:Number = NaN;
            var _loc3_:Number = NaN;
            if(process != null)
            {
               _loc2_ = sndLen - snds.length - 1 + param1;
               _loc3_ = _loc2_ / sndLen;
               process(_loc3_);
            }
         };
         snds = sounds.concat();
         sndLen = int(snds.length);
         loadNext();
      }
      
      private function initAssets() : void
      {
         var _loc1_:BitmapFont = this.getFont("font1");
         if(Boolean(_loc1_))
         {
            _loc1_.charGap = -8;
            _loc1_.spaceGap = 10;
            _loc1_.offsetY = -5;
         }
      }
      
      public function getEffect(param1:String) : *
      {
         var _loc2_:Class = this._swfLoader.getClass(param1,"assets/effect.swf");
         return new _loc2_();
      }
      
      public function getSound(param1:String) : Sound
      {
         return this._soundLoader.getSound(param1);
      }
      
      public function getFighterFace(param1:FighterVO, param2:Point = null) : DisplayObject
      {
         var _loc3_:Bitmap = this._bitmapLoader.getBitmap(param1.faceUrl);
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
         var _loc3_:Bitmap = this._bitmapLoader.getBitmap(param1.faceBigUrl);
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
         var _loc3_:Bitmap = this._bitmapLoader.getBitmap(param1.faceBarUrl);
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
         if(!param1) { return null; }
         if(!param1.faceWinUrl)
         {
            return null;
         }
         var _loc3_:Bitmap = this._bitmapLoader.getBitmap(param1.faceWinUrl);
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
         var _loc3_:Bitmap = this._bitmapLoader.getBitmap(param1.picUrl);
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
      
      public function loadXML(param1:String, param2:Function, param3:Function) : void
      {
         this._assetLoader.loadXML(param1,param2,param3);
      }
      
      public function loadSWF(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         this._assetLoader.loadSwf(param1,param2,param3,param4);
      }
      
      public function loadSound(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         this._assetLoader.loadSound(param1,param2,param3,param4);
      }
      
      public function loadBitmap(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         this._assetLoader.loadBitmap(param1,param2,param3,param4);
      }
      
      public function disposeAsset(param1:String) : void
      {
         this._assetLoader.dispose(param1);
      }
      
      private function loadGraphics(param1:Array, param2:Function = null, param3:Function = null) : void
      {
         var loadedAmount:int = 0;
         var curUrl:String = null;
         var back:Function = null;
         var process:Function = null;
         var loadCom:* = undefined;
         var loadFail:* = undefined;
         var loads:Array = null;
         var loadarray:Array = param1;
         back = param2;
         process = param3;
         var loadNext:* = function():void
         {
            if(loads.length < 1)
            {
               if(back != null)
               {
                  back();
               }
               return;
            }
            curUrl = loads.shift();
            _assetLoader.loadSwf(curUrl,loadCom,loadFail,process);
         };
         loadCom = function(param1:Loader):void
         {
            ++loadedAmount;
            _swfLoader.addSwf(curUrl,param1);
            _assetLoader.dispose(curUrl);
            loadNext();
         };
         loadFail = function():void
         {
            Debugger.log("Error :: " + curUrl + " load fail!");
            loadNext();
         };
         loads = loadarray.concat();
         loadNext();
      }
      
      private function loadBitmaps(param1:Function = null, param2:Function = null) : void
      {
         var _loc3_:Array = this.getFighterFaceUrls(FighterModel.I.getAllFighters(),true,true);
         _loc3_ = _loc3_.concat(this.getFighterFaceUrls(AssisterModel.I.getAllAssisters()));
         _loc3_ = _loc3_.concat(this.getMapPicUrls(MapModel.I.getAllMaps()));
         KyoUtils.array_deleteSames(_loc3_);
         this._bitmapLoader.loadQueue(_loc3_,param1,param2);
      }
      
      private function loadFonts(param1:Function = null, param2:Function = null) : void
      {
         var fontXML:XML = null;
         var fontBitmapUrl:String = null;
         var back:Function = null;
         var bitmapCom:* = undefined;
         var bitmapFail:* = undefined;
         var url:String = null;
         back = param1;
         var process:Function = param2;
         var loadXMLCom:* = function(param1:XML):void
         {
            fontXML = param1;
            var _loc2_:String = param1.pages.page.@file;
            var _loc3_:String = url.substr(0,url.lastIndexOf("/") + 1);
            fontBitmapUrl = _loc3_ + _loc2_;
            _assetLoader.loadBitmap(fontBitmapUrl,bitmapCom,bitmapFail);
         };
         bitmapCom = function(param1:DisplayObject):void
         {
            var _loc2_:Bitmap = param1 as Bitmap;
            _bitmapFontLoader.addFont(fontXML,_loc2_.bitmapData);
            _assetLoader.dispose(fontBitmapUrl);
            if(back != null)
            {
               back();
            }
         };
         bitmapFail = function():void
         {
            Debugger.log("字体图片加载失败",url);
         };
         var loadXMLFail:* = function():void
         {
            Debugger.log("字体XML加载失败",url);
         };
         url = "assets/font/font1.xml";
         this._assetLoader.loadXML(url,loadXMLCom,loadXMLFail);
      }
      
      private function getFighterFaceUrls(param1:Object, param2:Boolean = false, param3:Boolean = false) : Array
      {
         var _loc5_:* = undefined;
         var _loc4_:Array = [];
         for each(_loc5_ in param1)
         {
            if(Boolean(_loc5_.faceUrl))
            {
               _loc4_.push(_loc5_.faceUrl);
            }
            if(Boolean(_loc5_.faceBigUrl))
            {
               _loc4_.push(_loc5_.faceBigUrl);
            }
            if(param2 && Boolean(_loc5_.faceBarUrl))
            {
               _loc4_.push(_loc5_.faceBarUrl);
            }
            if(param3 && Boolean(_loc5_.faceWinUrl))
            {
               _loc4_.push(_loc5_.faceWinUrl);
            }
         }
         return _loc4_;
      }
      
      private function getMapPicUrls(param1:Object) : Array
      {
         var _loc3_:* = undefined;
         var _loc2_:Array = [];
         for each(_loc3_ in param1)
         {
            _loc2_.push(_loc3_.picUrl);
         }
         return _loc2_;
      }
      
      public function needPreLoad() : Boolean
      {
         return this._assetLoader.needPreLoad();
      }
      
      public function loadPreLoad(param1:Function, param2:Function = null, param3:Function = null) : void
      {
         this._assetLoader.loadPreLoad(param1,param2,param3);
      }
   }
}

