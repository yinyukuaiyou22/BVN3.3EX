package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.interfaces.GameInterface;
   import net.play5d.game.bvn.interfaces.IExtendConfig;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.kyo.input.KyoKeyCode;
   import net.play5d.kyo.utils.KyoUtils;
   import net.play5d.patchouli.utils.ClassUtil;
   
   public class ConfigVO implements ISaveData
   {
      
      private const KEY_MENU:int = 0;
      
      private const KEY_P1:int = 1;
      
      private const KEY_P2:int = 2;
      
      public const key_menu:KeyConfigVO = new KeyConfigVO(0);
      
      public const key_p1:KeyConfigVO = new KeyConfigVO(1);
      
      public const key_p2:KeyConfigVO = new KeyConfigVO(2);
      
      public var select_config:SelectStageConfigVO = new SelectStageConfigVO();
      
      public var AI_level:int = 6;
      
      public var fighterHP:Number = 2;
      
      public var fightTime:int = -1;
      
      public var quality:String = "low";
      
      public var soundVolume:Number = 0.5;
      
      public var bgmVolume:Number = 0.5;
      
      public var keyInputMode:int = 1;
      
      public var isSmoothLowQuality:Boolean = true;
      
      public var isClassicalBgm:Boolean = false;
      
      public var isSkipStart:Boolean = false;
      
      public var isSteelBodyFreeze:Boolean = true;
      
      public var isSlowDown:Boolean = true;
      
      public var isAutoMathRandom:Boolean = true;
      
      public var isRandomOldFighter:Boolean = true;
      
      public var isAutoShowMore:Boolean = false;
      
      public var isShowFPS:Boolean = true;
      
      public var isAutoUpdateCheck:Boolean = true;
      
      public var isBankai:Boolean = false;
      
      public var isGodLevel:Boolean = false;
      
      public var isExactMoving:Boolean = false;
      
      public var isInfiniteAttack:Boolean = true;
      
      public var isStandardLimit:Boolean = true;
      
      public var isAutoDirect:Boolean = false;
      
      public var isComboBurden:Boolean = false;
      
      public var originalQi:Number = 100;
      
      public var originalAssist:Boolean = false;
      
      public var isGhostStep:Boolean = true;
      
      public var isSpecialSkill:Boolean = true;
      
      public var isReplaceSpecial:Boolean = false;
      
      public var isSpecialMisProt:Boolean = true;
      
      public var cameraZoomRate:Number = 0.6;
      
      public var isUploadRecord:Boolean = true;
      
      public var isFirstRun:Boolean = true;
      
      public var isOldDialog:Boolean = false;
      
      public var latestUpdateTime:Number = 0;
      
      public var latestNoticeID:String = "19700101-1";
      
      public var enableCurAI:String = "default";
      
      public var extendConfig:IExtendConfig = GameInterface.instance.getConfigExtend();
      
      public function ConfigVO()
      {
         super();
         setDefaultConfig(key_menu);
         setDefaultConfig(key_p1);
         setDefaultConfig(key_p2);
      }
      
      public function setDefaultConfig(param1:KeyConfigVO) : void
      {
         switch(param1.id)
         {
            case 0:
               param1.setKeys(KyoKeyCode.W.code,KyoKeyCode.S.code,KyoKeyCode.A.code,KyoKeyCode.D.code,KyoKeyCode.J.code,KyoKeyCode.K.code,KyoKeyCode.L.code,KyoKeyCode.U.code,KyoKeyCode.I.code,KyoKeyCode.O.code,KyoKeyCode.P.code);
               param1.selects = [KyoKeyCode.J.code,KyoKeyCode.K.code,KyoKeyCode.L.code,KyoKeyCode.U.code,KyoKeyCode.I.code,KyoKeyCode.O.code,KyoKeyCode.P.code];
               break;
            case 1:
               param1.setKeys(KyoKeyCode.W.code,KyoKeyCode.S.code,KyoKeyCode.A.code,KyoKeyCode.D.code,KyoKeyCode.J.code,KyoKeyCode.K.code,KyoKeyCode.L.code,KyoKeyCode.U.code,KyoKeyCode.I.code,KyoKeyCode.O.code,KyoKeyCode.P.code);
               break;
            case 2:
               param1.setKeys(KyoKeyCode.UP.code,KyoKeyCode.DOWN.code,KyoKeyCode.LEFT.code,KyoKeyCode.RIGHT.code,KyoKeyCode.Num1.code,KyoKeyCode.Num2.code,KyoKeyCode.Num3.code,KyoKeyCode.Num4.code,KyoKeyCode.Num5.code,KyoKeyCode.Num6.code,KyoKeyCode.Plus.code);
         }
      }
      
      public function toSaveObj() : Object
      {
         var _loc4_:Object = {};
         var _loc2_:Array = ClassUtil.getClassProperty(ConfigVO);
         var _loc1_:Array = ["select_config","extendConfig"];
         if(_loc2_ == null)
         {
            throw new Error("指定类没有公开属性！");
         }
         _loc4_.key_p1 = key_p1.toSaveObj();
         _loc4_.key_p2 = key_p2.toSaveObj();
         for each(var _loc3_ in _loc2_)
         {
            if(_loc1_.indexOf(_loc3_) == -1)
            {
               _loc4_[_loc3_] = this[_loc3_];
            }
         }
         if(extendConfig != null)
         {
            _loc4_.extend_config = extendConfig.toSaveObj();
         }
         return _loc4_;
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
      }
      
      public function getValueByKey(param1:String) : *
      {
         if(this.hasOwnProperty(param1))
         {
            return this[param1];
         }
         if(extendConfig != null)
         {
            try
            {
               return extendConfig[param1];
            }
            catch(e:Error)
            {
            }
         }
         return null;
      }
      
      public function setValueByKey(param1:String, param2:*) : void
      {
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
            }
            return;
         }
         if(extendConfig != null)
         {
            try
            {
               extendConfig[param1] = param2;
            }
            catch(e:Error)
            {
            }
         }
      }
      
      public function applyConfig() : void
      {
         GameConfig.IS_LOW_QUALITY = false;
         switch(quality)
         {
            case "low":
               GameConfig.QUALITY_GAME = isSmoothLowQuality ? "medium" : "low";
               GameConfig.setGameFps(isExactMoving ? 60 : 30);
               GameConfig.IS_LOW_QUALITY = true;
               GameConfig.FPS_SHINE_EFFECT = 15;
               EffectCtrl.EFFECT_SMOOTHING = false;
               break;
            case "medium":
               GameConfig.QUALITY_GAME = isSmoothLowQuality ? "medium" : "low";
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 30;
               EffectCtrl.EFFECT_SMOOTHING = false;
               break;
            case "high":
               GameConfig.QUALITY_GAME = "medium";
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 30;
               EffectCtrl.EFFECT_SMOOTHING = false;
               break;
            case "higher":
               GameConfig.QUALITY_GAME = "high";
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 30;
               EffectCtrl.EFFECT_SMOOTHING = true;
               break;
            case "best":
               GameConfig.QUALITY_GAME = "high";
               GameConfig.setGameFps(60);
               GameConfig.FPS_SHINE_EFFECT = 60;
               EffectCtrl.EFFECT_SMOOTHING = true;
         }
         GameInterface.instance.applyConfig(this);
         SoundCtrl.I.setBgmVolumn(bgmVolume);
         SoundCtrl.I.setSoundVolumn(soundVolume);
      }
      
      public function switchAllRuleConfig() : void
      {
         var _loc1_:Boolean = true;
         if(isSportsEnabled())
         {
            _loc1_ = false;
         }
         setAllRuleConfig(_loc1_);
      }
      
      public function setAllRuleConfig(param1:Boolean) : void
      {
         isBankai = !param1;
         isGodLevel = !param1;
         isInfiniteAttack = param1;
         isStandardLimit = param1;
         isAutoDirect = !param1;
         if(param1)
         {
            isComboBurden = false;
         }
         if(param1)
         {
            isSpecialSkill = true;
         }
         if(param1)
         {
            originalQi = 100;
         }
         cameraZoomRate = param1 ? 0.6 : 1;
         originalAssist = !param1;
         isUploadRecord = param1;
         GameData.I.saveData();
         GameUI.alert(GetLangText("game_ui.alert.switch_rule.title"),GetLangText("game_ui.alert.switch_rule.message") + (param1 ? GetLangText("game_ui.alert.switch_rule.yes") : GetLangText("game_ui.alert.switch_rule.no")),MainGame.I.goMenu);
      }
      
      public function isSportsEnabled(param1:Boolean = false) : Boolean
      {
         if(isBankai)
         {
            return false;
         }
         if(!isInfiniteAttack)
         {
            return false;
         }
         if(!isStandardLimit)
         {
            return false;
         }
         if(isComboBurden)
         {
            return false;
         }
         if(param1)
         {
            if(isAutoDirect)
            {
               return false;
            }
            if(originalQi != 100)
            {
               return false;
            }
            if(originalAssist)
            {
               return false;
            }
            if(fighterHP != 2)
            {
               return false;
            }
         }
         return true;
      }
   }
}

