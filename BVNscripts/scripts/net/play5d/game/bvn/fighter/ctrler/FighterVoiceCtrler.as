package net.play5d.game.bvn.fighter.ctrler
{
   import flash.media.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.kyo.utils.*;
   
   public class FighterVoiceCtrler
   {
      
      private var _voiceObj:Object = {};
      
      private var _channel:SoundChannel;
      
      private var _curLength:int;
      
      private var _soundTransform:SoundTransform;
      
      public function FighterVoiceCtrler()
      {
         super();
         this._soundTransform = new SoundTransform();
         this._soundTransform.volume = GameData.I.config.soundVolume;
      }
      
      public function destory() : void
      {
         if(Boolean(this._voiceObj))
         {
            this._voiceObj = null;
         }
         if(Boolean(this._channel))
         {
            this._channel.stop();
            this._channel = null;
         }
      }
      
      public function setVoice(param1:int, param2:Array) : void
      {
         this._voiceObj[param1] = param2;
      }
      
      public function playVoice(param1:int, param2:Number = 1) : void
      {
         var _loc3_:Class = null;
         var _loc4_:Sound = null;
         if(Boolean(this._channel) && this._channel.position < this._curLength)
         {
            return;
         }
         if(Math.random() > param2)
         {
            return;
         }
         var _loc5_:Array = this._voiceObj[param1];
         if(Boolean(_loc5_) && _loc5_.length > 0)
         {
            _loc3_ = _loc5_.length > 1 ? KyoRandom.getRandomInArray(_loc5_) : _loc5_[0];
            if(Boolean(_loc3_))
            {
               _loc4_ = new _loc3_();
               this._curLength = _loc4_.length;
               this._channel = _loc4_.play(0,0,this._soundTransform);
            }
         }
      }
   }
}

