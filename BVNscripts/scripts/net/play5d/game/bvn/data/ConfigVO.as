package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.kyo.utils.*;
   import net.play5d.game.bvn.Debugger;
   
   public class ConfigVO
   {
      
      public const key_menu:KeyConfigVO = new KeyConfigVO(0);
      
      public const key_p1:KeyConfigVO = new KeyConfigVO(1);
      
      public const key_p2:KeyConfigVO = new KeyConfigVO(2);
      
      public var select_config:SelectStageConfigVO = new SelectStageConfigVO();
      
      public var AI_level:int = 4;
      
      public var fighterHP:Number = 1;
      
      public var fightTime:int = 60;
      
      public var quality:String = "low";
      
      public var soundVolume:Number = 0.3;
      
      public var bgmVolume:Number = 0.3;
      
      public var keyInputMode:int = 1;
      
      public var INFINITE_ENERGY:Boolean = false;
      
      public var extendConfig:IExtendConfig;
      
      public function ConfigVO()
      {
         super();
         this.extendConfig = GameInterface.instance.getConfigExtend();
         this.setDefaultConfig(this.key_menu);
         this.setDefaultConfig(this.key_p1);
         this.setDefaultConfig(this.key_p2);
      }
      
      public function setDefaultConfig(keyConfig:KeyConfigVO) : void
      {
         switch(keyConfig.id)
         {
            case 0:
               keyConfig.setKeys(87,83,65,68,74,75,76,85,73,79);
               keyConfig.selects = [74,75,76,85,73,79];
               break;
            case 1:
               keyConfig.setKeys(87,83,65,68,74,75,76,85,73,79);
               break;
            case 2:
               keyConfig.setKeys(38,40,37,39,97,98,99,100,101,102);
         }
      }
      
      public function toSaveObj() : Object
      {
         var o:* = {};
         o.key_p1 = this.key_p1.toSaveObj();
         o.key_p2 = this.key_p2.toSaveObj();
         o.AI_level = this.AI_level;
         o.fighterHP = this.fighterHP;
         o.fightTime = this.fightTime;
         o.quality = this.quality;
         o.keyInputMode = this.keyInputMode;
         o.soundVolume = this.soundVolume;
         o.bgmVolume = this.bgmVolume;
         o.INFINITE_ENERGY = this.INFINITE_ENERGY;
         if(Boolean(this.extendConfig))
         {
            o.extend_config = this.extendConfig.toSaveObj();
         }
         return o;
      }
      
      public function readSaveObj(o:Object) : void
      {
         this.key_p1.readSaveObj(o.key_p1);
         this.key_p2.readSaveObj(o.key_p2);
         if(Boolean(o.extend_config) && Boolean(this.extendConfig))
         {
            this.extendConfig.readSaveObj(o.extend_config);
         }
         delete o["key_p1"];
         delete o["key_p2"];
         delete o["extend_config"];
         KyoUtils.setValueByObject(this,o);
      }
      
      public function getValueByKey(key:String) : *
      {
         if(key in this)
         {
            return this[key];
         }
         if(Boolean(this.extendConfig))
         {
            try
            {
               return this.extendConfig[key];
            }
            catch(e:Error)
            {
               Debugger.log(e.getStackTrace());
            }
         }
         return null;
      }
      
      public function setValueByKey(key:String, value:*) : void
      {
         if(key in this)
         {
            this[key] = value;
            switch(key)
            {
               case "bgmVolume":
                  SoundCtrl.I.setBgmVolumn(this.bgmVolume);
                  break;
               case "soundVolume":
                  SoundCtrl.I.setSoundVolumn(this.soundVolume);
            }
            return;
         }
         if(Boolean(this.extendConfig))
         {
            try
            {
               this.extendConfig[key] = value;
            }
            catch(e:Error)
            {
               Debugger.log(e);
            }
         }
      }
      
      public function applyConfig() : void
      {
         switch(this.quality)
         {
            case "low":
               MainGame.I.stage.quality = "low";
               GameConfig.setGameFps(30);
               GameConfig.FPS_SHINE_EFFECT = 15;
               EffectCtrl.EFFECT_SMOOTHING = false;
               break;
            case "medium":
               MainGame.I.stage.quality = "low";
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 30;
               EffectCtrl.EFFECT_SMOOTHING = false;
               break;
            case "high":
               MainGame.I.stage.quality = "medium";
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 30;
               EffectCtrl.EFFECT_SMOOTHING = false;
               break;
            case "higher":
               MainGame.I.stage.quality = "high";
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 30;
               EffectCtrl.EFFECT_SMOOTHING = true;
               break;
            case "best":
               MainGame.I.stage.quality = "high";
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 60;
               EffectCtrl.EFFECT_SMOOTHING = true;
         }
         GameConfig.INFINITE_ENERGY = this.INFINITE_ENERGY;
         GameInterface.instance.applyConfig(this);
         SoundCtrl.I.setBgmVolumn(this.bgmVolume);
         SoundCtrl.I.setSoundVolumn(this.soundVolume);
      }
   }
}

