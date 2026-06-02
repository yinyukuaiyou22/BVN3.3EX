package net.play5d.kyo.sound
{
   import flash.events.Event;
   import flash.media.Sound;
   import flash.media.SoundChannel;
   import flash.media.SoundTransform;
   import flash.net.URLRequest;
   
   public class KyoBGSounder
   {
      
      private static var _i:KyoBGSounder;
      
      public var sound:Object;
      
      public var playing:Boolean;
      
      private var _snd:Sound;
      
      private var _channel:SoundChannel;
      
      private var _soundTransform:SoundTransform = new SoundTransform();
      
      private var _channelPausePosition:int;
      
      public function KyoBGSounder()
      {
         super();
      }
      
      public static function get I() : KyoBGSounder
      {
         if(!_i)
         {
            _i = new KyoBGSounder();
         }
         return _i;
      }
      
      public function get volume() : Number
      {
         return _soundTransform.volume;
      }
      
      public function set volume(param1:Number) : void
      {
         _soundTransform.volume = param1;
         if(_channel)
         {
            _channel.soundTransform = _soundTransform;
         }
      }
      
      public function play(param1:Object = null, param2:Boolean = true) : void
      {
         trace("bgm play");
         if(_snd)
         {
            return;
         }
         if(!param1)
         {
            param1 = sound;
         }
         if(param1)
         {
            sound = param1;
            if(sound is String)
            {
               _snd = new Sound(new URLRequest(sound as String));
            }
            if(sound is Class)
            {
               _snd = new sound();
            }
            if(sound is Sound)
            {
               _snd = sound as Sound;
            }
            playsnd(0,param2);
            playing = true;
            return;
         }
         trace("没有可播放的音乐");
      }
      
      public function stop() : void
      {
         trace("bgm stop");
         if(_channel)
         {
            _channel.stop();
            _channel = null;
         }
         if(_snd)
         {
            try
            {
               _snd.close();
            }
            catch(e:Error)
            {
               if(e.errorID != 2029)
               {
                  trace("KyoBGSounder",e);
               }
            }
            _snd = null;
         }
         playing = false;
      }
      
      public function pause() : void
      {
         trace("bgm pause");
         if(_channel)
         {
            _channelPausePosition = _channel.position;
            _channel.stop();
         }
      }
      
      public function resume() : void
      {
         trace("bgm resume");
         if(_channel)
         {
            playsnd(_channelPausePosition);
         }
      }
      
      public function toogle() : void
      {
         if(playing)
         {
            stop();
         }
         else
         {
            play();
         }
      }
      
      private function playsnd(param1:int = 0, param2:Boolean = true) : void
      {
         if(!_snd)
         {
            return;
         }
         _channel = _snd.play(param1,1,_soundTransform);
         if(!_channel)
         {
            return;
         }
         _channel.removeEventListener("soundComplete",playCompleteHandler);
         if(param2)
         {
            _channel.addEventListener("soundComplete",playCompleteHandler);
         }
      }
      
      private function playCompleteHandler(param1:Event) : void
      {
         if(_channel)
         {
            _channel.removeEventListener("soundComplete",playCompleteHandler);
            _channel = null;
         }
         playsnd(0);
      }
   }
}

