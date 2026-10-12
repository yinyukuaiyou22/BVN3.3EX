package net.play5d.game.bvn.ctrl
{
   import flash.media.*;
   import net.play5d.kyo.loader.*;
   import net.play5d.kyo.sound.*;
   import net.play5d.kyo.utils.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.game.bvn.Debugger;
   
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
      
      /** AS3 批量加载并发度：战斗 BGM 常为多首数 MB 的 MP3，3 路并发控制内存峰值 */
      private static const BGM_BATCH_CONCURRENCY:int = 3;
      
      public function loadFightBGM(param1:Array, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         var o:Object = null;
         var urls:Array = [];
         var arr:Array = param1;
         var success:Function = param2;
         var fail:Function = param3;
         var process:Function = param4;
         var self:SoundCtrl = this;
         this._bgmObj = {};
         for each(o in arr)
         {
            this._bgmObj[o.id] = o;
            urls.push(o.url);
         }
         this._soundLoader = new KyoSoundLoader();
         if(urls.length < 1)
         {
            if(success != null) success();
            return;
         }
         // AS3 批量加载：BGM 由逐个串行改为按并发度同时挂起（原实现每完成一首才发下一首）
         Debugger.log("[SoundCtrl] loadFightBGM n=" + urls.length + " urls=" + urls.join(","));
         var batch:AssetBatchLoader = new AssetBatchLoader();
         batch.load(urls,function(url:String, onDone:Function, onFail:Function, onProgress:Function):void
         {
            AssetManager.I.loadSound(url,function(param1:Sound):void
            {
               self._soundLoader.addSound(url,param1);
               onDone();
            },function():void
            {
               Debugger.log("SoundCtrl.loadFightBGM fail!",url);
               onFail();
            },onProgress);
          },function():void
          {
             Debugger.log("[SoundCtrl] loadFightBGM batch done");
             if(success != null) success();
          },process,BGM_BATCH_CONCURRENCY);
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

