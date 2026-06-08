package net.play5d.game.bvn.ctrl
{
   import flash.media.*;
   import net.play5d.kyo.loader.*;
   import net.play5d.kyo.sound.*;
   import net.play5d.kyo.utils.*;
   
   public class SoundCtrl
   {
      
      private static var _i:SoundCtrl;
      
      private var _bgSound:KyoBGSounder;
      
      private var _soundLoader:KyoSoundLoader;
      
      private var _bgmObj:Object;
      
      private var _bgmPaused:Boolean = false;
      
      private var _waitingSound:Object;
      
      private var _sndTransform:SoundTransform = new SoundTransform();
      
      public function SoundCtrl()
      {
         super();
      }
      
      public static function get I() : SoundCtrl
      {
         if(!_i)
         {
            _i = new SoundCtrl();
         }
         return _i;
      }
      
      public function setSoundVolumn(param1:Number) : void
      {
         this._sndTransform.volume = param1;
      }
      
      public function setBgmVolumn(param1:Number) : void
      {
         if(!this._bgSound)
         {
            this._bgSound = new KyoBGSounder();
         }
         this._bgSound.volume = param1;
      }
      
      public function playAssetSound(param1:String, param2:Number = 1) : void
      {
         var _loc3_:SoundTransform = null;
         if(param1 == null)
         {
            return;
         }
         var _loc4_:Sound = AssetManager.I.getSound(param1);
         if(Boolean(_loc4_))
         {
            _loc3_ = this._sndTransform;
            if(param2 != 1)
            {
               _loc3_ = new SoundTransform(param2 * this._sndTransform.volume);
            }
            _loc4_.play(0,0,_loc3_);
         }
      }
      
      public function playEffectSound(param1:String, param2:Number = 1) : void
      {
         var _loc3_:SoundTransform = null;
         if(param1 == null)
         {
            return;
         }
         var _loc4_:Sound = AssetManager.I.getEffect(param1);
         if(Boolean(_loc4_))
         {
            _loc3_ = this._sndTransform;
            if(param2 != 1)
            {
               _loc3_ = new SoundTransform(param2 * this._sndTransform.volume);
            }
            _loc4_.play(0,0,_loc3_);
         }
      }
      
      public function playAssetSoundRandom(... rest) : void
      {
         var _loc2_:String = KyoRandom.getRandomInArray(rest);
         this.playAssetSound(_loc2_);
      }
      
      public function playSwcSound(param1:Class) : void
      {
         var _loc2_:Sound = new param1();
         _loc2_.play(0,0,this._sndTransform);
      }
      
      public function BGM(param1:Object) : void
      {
         if(this._bgmPaused)
         {
            this._waitingSound = param1;
            return;
         }
         if(!this._bgSound)
         {
            this._bgSound = new KyoBGSounder();
         }
         if(this._bgSound.sound == param1)
         {
            return;
         }
         if(this._bgSound.playing)
         {
            this._bgSound.stop();
         }
         if(Boolean(param1))
         {
            this._bgSound.play(param1);
         }
      }
      
      public function pauseBGM() : void
      {
         if(this._bgmPaused)
         {
            return;
         }
         this._bgmPaused = true;
         if(Boolean(this._bgSound))
         {
            this._bgSound.pause();
         }
      }
      
      public function resumeBGM() : void
      {
         if(!this._bgmPaused)
         {
            return;
         }
         this._bgmPaused = false;
         if(Boolean(this._waitingSound))
         {
            this.BGM(this._waitingSound);
            this._waitingSound = null;
            return;
         }
         if(Boolean(this._bgSound))
         {
            this._bgSound.resume();
         }
      }
      
      public function loadFightBGM(param1:Array, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         var o:Object = null;
         var curUrl:String = null;
         var sndLen:int = 0;
         var success:Function = null;
         var process:Function = null;
         var loadBack:* = undefined;
         var loadFail:* = undefined;
         var loadProcess:* = undefined;
         var urls:Array = null;
         var arr:Array = param1;
         success = param2;
         var fail:Function = param3;
         process = param4;
         var loadNext:* = function():void
         {
            if(urls.length < 1)
            {
               if(success != null)
               {
                  success();
               }
               return;
            }
            curUrl = urls.shift();
            AssetManager.I.loadSound(curUrl,loadBack,loadFail,loadProcess);
         };
         loadBack = function(param1:Sound):void
         {
            _soundLoader.addSound(curUrl,param1);
            loadNext();
         };
         loadFail = function():void
         {
            trace("SoundCtrl.loadFightBGM fail!",curUrl);
            loadNext();
         };
         loadProcess = function(param1:Number):void
         {
            var _loc2_:Number = NaN;
            var _loc3_:Number = NaN;
            if(process != null)
            {
               _loc2_ = sndLen - urls.length - 1 + param1;
               _loc3_ = _loc2_ / sndLen;
               process(param1);
            }
         };
         this._bgmObj = {};
         urls = [];
         for each(o in arr)
         {
            this._bgmObj[o.id] = o;
            urls.push(o.url);
         }
         this._soundLoader = new KyoSoundLoader();
         sndLen = int(urls.length);
         loadNext();
      }
      
      public function playFightBGM(param1:String) : void
      {
         var _loc2_:Object = this._bgmObj[param1];
         if(param1 == "map")
         {
            if(_loc2_ == null)
            {
               return;
            }
         }
         else
         {
            if(_loc2_ == null)
            {
               this.playFightBGM("map");
               return;
            }
            if(Math.random() > Number(_loc2_.rate))
            {
               this.playFightBGM("map");
               return;
            }
         }
         var _loc3_:Sound = this._soundLoader.getSound(_loc2_.url);
         this.BGM(_loc3_);
      }
      
      public function unloadFightBGM() : void
      {
         this.BGM(null);
         if(Boolean(this._soundLoader))
         {
            this._soundLoader.unload();
            this._soundLoader = null;
         }
      }
      
      public function sndSelect() : void
      {
         this.playSwcSound(snd_menu1);
      }
      
      public function sndConfrim() : void
      {
         this.playSwcSound(snd_menu2);
      }
   }
}

