package net.play5d.game.bvn.fighter.ctrler
{
   import flash.media.Sound;
   import flash.media.SoundChannel;
   import flash.media.SoundTransform;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.kyo.utils.KyoRandom;
   
   public class FighterVoiceCtrler
   {
      
      private var _voiceObj:Object = {};
      
      private var _channel:SoundChannel;
      
      private var _curLength:int;
      
      private var _soundTransform:SoundTransform = new SoundTransform();
      
      public function FighterVoiceCtrler()
      {
         super();
         _soundTransform.volume = GameData.I.config.soundVolume;
      }
      
      public function destory() : void
      {
         if(_voiceObj != null)
         {
            _voiceObj = null;
         }
         if(_channel != null)
         {
            _channel.stop();
            _channel = null;
         }
      }
      
      public function setVoice(param1:int, param2:Array) : void
      {
         _voiceObj[param1] = param2;
      }
      
      public function playVoice(param1:int, param2:Number = 1) : void
      {
         var _loc6_:Class = null;
         var _loc5_:Sound = null;
         var _loc3_:Number = !GameConfig.IS_WIN_ACTIVATE ? 0 : GameData.I.config.soundVolume;
         _soundTransform.volume = _loc3_;
         if(_channel != null && _channel.position < _curLength)
         {
            return;
         }
         if(Math.random() > param2)
         {
            return;
         }
         var _loc4_:Array = _voiceObj[param1];
         if(_loc4_ != null && _loc4_.length > 0)
         {
            _loc6_ = (_loc4_.length > 1 ? KyoRandom.getRandomInArray(_loc4_) : _loc4_[0]) as Class;
            if(_loc6_ == null)
            {
               return;
            }
            _loc5_ = new _loc6_();
            _curLength = _loc5_.length;
            _channel = _loc5_.play(0,0,_soundTransform);
         }
      }
   }
}

