package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.Debugger;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.interfaces.IExtendConfig;
   import net.play5d.kyo.utils.KyoUtils;
   
   public class ConfigVO
   {
      
      public const key_menu:KeyConfigVO = new KeyConfigVO(0);
      
      public const key_p1:KeyConfigVO = new KeyConfigVO(1);
      
      public const key_p2:KeyConfigVO = new KeyConfigVO(2);
      
      public var select_config:SelectStageConfigVO = new SelectStageConfigVO();
      
      public var AI_level:int = 1;
      
      public var fighterHP:Number = 1;
      
      public var fightTime:int = 60;
      
      public var quality:String = "medium";
      
      public var soundVolume:Number = 0.7;
      
      public var bgmVolume:Number = 0.7;
      
      public var keyInputMode:int = 1;
      
      public var INFINITE_ENERGY:Boolean = false;
      
      public var extendConfig:IExtendConfig;
      
      public function ConfigVO()
      {
         super();
         extendConfig = GameInterface.instance.getConfigExtend();
         setDefaultConfig(key_menu);
         setDefaultConfig(key_p1);
         setDefaultConfig(key_p2);
         Debugger.log("[ConfigVO] 构造函数执行，INFINITE_ENERGY 初始值 = " + INFINITE_ENERGY);
      }
      
      public function setDefaultConfig(param1:KeyConfigVO) : void
      {
         switch(param1.id)
         {
            case 0:
               param1.setKeys(87,83,65,68,74,75,76,85,73,79);
               param1.selects = [74,75,76,85,73,79];
               break;
            case 1:
               param1.setKeys(87,83,65,68,74,75,76,85,73,79);
               break;
            case 2:
               param1.setKeys(38,40,37,39,97,98,99,100,101,102);
         }
      }
      
      public function toSaveObj() : Object
      {
         var _loc1_:Object = {};
         _loc1_.key_p1 = key_p1.toSaveObj();
         _loc1_.key_p2 = key_p2.toSaveObj();
         _loc1_.AI_level = AI_level;
         _loc1_.fighterHP = fighterHP;
         _loc1_.fightTime = fightTime;
         _loc1_.quality = quality;
         _loc1_.keyInputMode = keyInputMode;
         _loc1_.soundVolume = soundVolume;
         _loc1_.bgmVolume = bgmVolume;
         _loc1_.INFINITE_ENERGY = INFINITE_ENERGY;
         if(extendConfig)
         {
            _loc1_.extend_config = extendConfig.toSaveObj();
         }
         Debugger.log("[ConfigVO] toSaveObj() - INFINITE_ENERGY = " + INFINITE_ENERGY);
         return _loc1_;
      }
      
      public function readSaveObj(param1:Object) : void
      {
         key_p1.readSaveObj(param1.key_p1);
         key_p2.readSaveObj(param1.key_p2);
         if(param1.extend_config && extendConfig)
         {
            extendConfig.readSaveObj(param1.extend_config);
         }
         delete param1["key_p1"];
         delete param1["key_p2"];
         delete param1["extend_config"];
         KyoUtils.setValueByObject(this,param1);
         Debugger.log("[ConfigVO] readSaveObj() - 加载后 INFINITE_ENERGY = " + INFINITE_ENERGY);
      }
      
      public function getValueByKey(param1:String) : *
      {
         if(this.hasOwnProperty(param1))
         {
            return this[param1];
         }
         if(extendConfig)
         {
            try
            {
               return extendConfig[param1];
            }
            catch(e:Error)
            {
               Debugger.log(e.toString());
            }
         }
         return null;
      }
      
      public function setValueByKey(param1:String, param2:*) : void
      {
         Debugger.log("[ConfigVO] setValueByKey - key = " + param1 + ", value = " + param2);
         if(this.hasOwnProperty(param1))
         {
            this[param1] = param2;
            switch(param1)
            {
               case "bgmVolume":
                  SoundCtrl.I.setBgmVolumn(bgmVolume);
                  break;
               case "soundVolume":
                  SoundCtrl.I.setSoundVolumn(soundVolume);
                  break;
               case "INFINITE_ENERGY":
                  GameConfig.INFINITE_ENERGY = param2;
                  if(extendConfig)
                  {
                     try
                     {
                        extendConfig["INFINITE_ENERGY"] = param2;
                     }
                     catch(e:Error)
                     {
                        Debugger.log(e.toString());
                     }
                  }
                  Debugger.log("[ConfigVO] 无限气设置已更新为 " + param2);
            }
            return;
         }
         if(extendConfig)
         {
            try
            {
               extendConfig[param1] = param2;
               Debugger.log("[ConfigVO] 设置到 extendConfig[" + param1 + "] = " + param2);
            }
            catch(e:Error)
            {
               Debugger.log(e.toString());
            }
         }
      }
      
      public function applyConfig() : void
      {
         Debugger.log("[ConfigVO] applyConfig() 开始，当前 INFINITE_ENERGY = " + INFINITE_ENERGY);
         switch(quality)
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
               EffectCtrl.EFFECT_SMOOTHING = true;
               break;
            case "higher":
               MainGame.I.stage.quality = "high";
               GameConfig.setGameFps(90);
               GameConfig.FPS_SHINE_EFFECT = 60;
               EffectCtrl.EFFECT_SMOOTHING = true;
               break;
            case "best":
               MainGame.I.stage.quality = "high";
               GameConfig.setGameFps(120);
               GameConfig.FPS_SHINE_EFFECT = 60;
               EffectCtrl.EFFECT_SMOOTHING = true;
         }
         GameInterface.instance.applyConfig(this);
         SoundCtrl.I.setBgmVolumn(bgmVolume);
         SoundCtrl.I.setSoundVolumn(soundVolume);
         Debugger.log("[ConfigVO] applyConfig() 完成，最终 GameConfig.INFINITE_ENERGY = " + GameConfig.INFINITE_ENERGY);
      }
   }
}

