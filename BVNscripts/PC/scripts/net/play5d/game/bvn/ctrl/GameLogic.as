package net.play5d.game.bvn.ctrl
{
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameEndCtrl;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.MessionModel;
   import net.play5d.game.bvn.data.MessionStageVO;
   import net.play5d.game.bvn.data.SelectCharListConfigVO;
   import net.play5d.game.bvn.data.SelectCharListItemVO;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.map.FloorVO;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.stage.GameCamera;
   import net.play5d.game.bvn.ui.select.SelectIndexUI;
   import net.play5d.game.bvn.utils.ResUtils;
   
   public class GameLogic
   {
      
      private static var _map:MapMain;
      
      private static var _camera:GameCamera;
      
      private static var _floorContact:Dictionary = new Dictionary();
      
      private static var _hitsObj:Object = {};
      
      public function GameLogic()
      {
         super();
      }
      
      public static function initGameLogic(param1:MapMain, param2:GameCamera) : void
      {
         _map = param1;
         _camera = param2;
      }
      
      public static function clear() : void
      {
         _map = null;
         _camera = null;
      }
      
      public static function isInAir(param1:BaseGameSprite) : Boolean
      {
         var _loc4_:Number = NaN;
         var _loc3_:FloorVO = null;
         if(!_map)
         {
            return false;
         }
         if(param1.getVecY() < 0)
         {
            param1.isTouchBottom = false;
            return true;
         }
         if(param1.y > _map.playerBottom - 12)
         {
            param1.y = _map.playerBottom;
            param1.isTouchBottom = true;
            return false;
         }
         param1.isTouchBottom = false;
         if(GameConfig.SPEED_PLUS_DEFAULT == 0.5 && param1.getVecY() >= 5 && param1.getVecY() < 5.5 && _floorContact[param1] != null)
         {
            param1.setVecY(5.5);
            delete _floorContact[param1];
         }
         var _loc2_:Boolean = param1.getVecY() < 5;
         if(!_loc2_)
         {
            return true;
         }
         if(!param1.allowCrossFloor())
         {
            _loc4_ = 10 * GameConfig.SPEED_PLUS_DEFAULT;
            _loc3_ = _floorContact[param1];
            if(_loc3_)
            {
               if(_loc3_.hitTest(param1.x,param1.y,_loc4_))
               {
                  param1.y = _loc3_.y;
                  return false;
               }
               delete _floorContact[param1];
               return true;
            }
            _loc3_ = _map.getFloorHitTest(param1.x,param1.y,_loc4_);
            if(_loc3_)
            {
               param1.y = _loc3_.y;
               _floorContact[param1] = _loc3_;
               return false;
            }
         }
         return true;
      }
      
      public static function isTouchBottomFloor(param1:IGameSprite) : Boolean
      {
         if(_map == null)
         {
            return false;
         }
         return param1.y >= _map.playerBottom;
      }
      
      public static function isOutRange(param1:IGameSprite) : Boolean
      {
         if(_map == null)
         {
            return false;
         }
         return param1.x > _map.right + 200 || param1.x < _map.left - 200 || param1.y > _map.bottom + 20;
      }
      
      public static function addHits(param1:Object, param2:Object, param3:int) : int
      {
         if(_hitsObj[param1] == undefined)
         {
            _hitsObj[param1] = {
               "hits":0,
               "targetID":param2,
               "uiID":param3
            };
         }
         _hitsObj[param1].targetID = param2;
         _hitsObj[param1].hits++;
         return _hitsObj[param1].hits;
      }
      
      public static function clearHits(param1:Object) : void
      {
         if(_hitsObj[param1] != undefined)
         {
            _hitsObj[param1].hits = 0;
            _hitsObj[param1].targetID = null;
            _hitsObj[param1].uiID = null;
            delete _hitsObj[param1];
         }
      }
      
      public static function getHitsObj(param1:Object) : Object
      {
         return _hitsObj[param1];
      }
      
      public static function getHitsObjByTargetId(param1:Object) : Object
      {
         for each(var _loc2_ in _hitsObj)
         {
            if(_loc2_.targetID == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      public static function clearHitsByTargetId(param1:Object) : void
      {
         for(var _loc2_ in _hitsObj)
         {
            if(_hitsObj[_loc2_].targetID == param1)
            {
               delete _hitsObj[_loc2_];
            }
         }
      }
      
      public static function checkFighterDie(param1:FighterMain) : Boolean
      {
         if(GameMode.isTraining())
         {
            return false;
         }
         return param1.hp <= 0;
      }
      
      public static function hitTarget(param1:HitVO, param2:IGameSprite, param3:IGameSprite) : void
      {
         if(!param2 || !param3)
         {
            return;
         }
         if(param2 is FighterMain == false)
         {
            return;
         }
         if(param3 is FighterMain == false)
         {
            return;
         }
         if((param3 as FighterMain).actionState != 21 && (param3 as FighterMain).actionState != 22)
         {
            return;
         }
         var _loc4_:Object = {};
         _loc4_.target = param3;
         _loc4_.hitvo = param1;
         FighterEventDispatcher.dispatchEvent(param2 as FighterMain,"HIT_TARGET",_loc4_);
      }
      
      public static function addScoreByHitTarget(param1:HitVO) : void
      {
         var _loc4_:int = 0;
         var _loc2_:* = _loc4_ = param1.power;
         if(param1.isBisha())
         {
            _loc2_ = int(_loc4_ * 2);
         }
         if(param1.id == "sh1" || param1.id == "sh2")
         {
            _loc2_ += 500;
         }
         if(param1.isBreakDef)
         {
            _loc2_ += 200;
         }
         if(param1.hurtType == 1)
         {
            _loc2_ += 200;
         }
         var _loc5_:Object = getHitsObj(1);
         var _loc3_:int = int(_loc5_ ? _loc5_.hits : 0);
         if(_loc3_ < 4)
         {
            _loc2_ += _loc3_ * 50;
         }
         else
         {
            _loc2_ += _loc3_ * 100;
         }
         addScore(_loc2_);
         GameEvent.dispatchEvent("SCORE_UPDATE");
      }
      
      public static function addScoreByKO() : void
      {
         if(GameCtrl.I.gameRunData.p1FighterGroup.currentFighter.lastHitVO && GameCtrl.I.gameRunData.p1FighterGroup.currentFighter.lastHitVO.isBisha())
         {
            addScore(2000);
         }
         if(GameCtrl.I.gameRunData.p1FighterGroup.currentFighter.hp == GameCtrl.I.gameRunData.p1FighterGroup.currentFighter.hpMax)
         {
            addScore(20000);
         }
         else
         {
            addScore(3000);
         }
         GameEvent.dispatchEvent("SCORE_UPDATE");
      }
      
      public static function addScoreByPassMission() : void
      {
         if(GameMode.currentMode == 10 && GameCtrl.I.gameRunData.p1FighterGroup.currentFighterVO == GameCtrl.I.gameRunData.p1FighterGroup.fighter1)
         {
            addScore(15000);
         }
         else
         {
            addScore(5000);
         }
      }
      
      private static function addScore(param1:int) : void
      {
         var _loc2_:Number = GameData.I.config.keyInputMode == 0 ? 1 : 0.8;
         GameData.I.score += param1 * _loc2_;
      }
      
      public static function loseScoreByContinue() : void
      {
         GameData.I.score -= 10000;
         if(GameData.I.score < 0)
         {
            GameData.I.score = 0;
         }
      }
      
      public static function fixGameSpritePosition(param1:IGameSprite) : void
      {
         fixGameSpritePositionX(param1);
         fixGameSpritePositionY(param1);
      }
      
      public static function fixGameSpritePositionX(param1:IGameSprite) : void
      {
         var _loc4_:* = undefined;
         var _loc8_:* = undefined;
         var _loc13_:* = undefined;
         var _loc7_:* = undefined;
         var _loc3_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc9_:Rectangle = null;
         var _loc2_:Number = NaN;
         var _loc11_:Number = NaN;
         if(param1.isDestoryed())
         {
            return;
         }
         if(param1.allowCrossMapXY())
         {
            return;
         }
         var _loc10_:Number = _map.left + 10;
         var _loc6_:Number = _map.right - 10;
         var _loc12_:Boolean = false;
         var _loc14_:Boolean = false;
         if(param1 is FighterMain)
         {
            _loc4_ = param1 as FighterMain;
            _loc8_ = _loc4_.getCurrentTarget();
            if(_loc8_ && _loc8_ is FighterMain)
            {
               _loc8_ = _loc8_ as FighterMain;
               if([22,23,24].indexOf(_loc8_.actionState) != -1)
               {
                  _loc8_.ticksAtCorner = 0;
               }
               if(_loc4_.x < _loc10_ + 50 || _loc4_.x > _loc6_ - 50)
               {
                  _loc13_ = _loc4_.getBodyArea();
                  _loc7_ = _loc8_.getBodyArea();
                  if(!_loc4_.isCross && _loc13_)
                  {
                     if(_loc4_.ticksAtCorner < _loc8_.ticksAtCorner && Math.abs(_loc4_.y - _loc8_.y) < 45)
                     {
                        _loc12_ = true;
                        _loc10_ += 8;
                        _loc6_ -= 8;
                     }
                  }
                  if(_loc4_.ticksAtCorner && _loc4_.isInAir && Math.abs(_loc4_.y - _loc8_.y) < 63)
                  {
                     _loc14_ = true;
                  }
                  if(_loc4_.actionState == 15 || _loc4_.isCross || !_loc13_)
                  {
                     if(!(_loc4_.actionState == 15 && _loc8_.actionState == 21) && [22,23,24].indexOf(_loc4_.actionState) == -1)
                     {
                        _loc14_ = true;
                     }
                  }
               }
            }
            _loc3_ = 10;
            _loc5_ = _camera.getZoom();
            _loc9_ = _camera.getScreenRect();
            if((param1 as FighterMain).getVecX() != 0 || (param1 as FighterMain).getCtrler().getMcCtrl().getAction().airMove)
            {
               if(_loc5_ == _camera.autoZoomMin)
               {
                  _loc2_ = _loc9_.x + _loc3_;
                  _loc11_ = _loc2_ + _loc9_.width - _loc3_;
                  if(_loc10_ < _loc2_)
                  {
                     _loc10_ = _loc2_;
                  }
                  if(_loc6_ > _loc11_)
                  {
                     _loc6_ = _loc11_;
                  }
               }
            }
         }
         var _loc15_:Boolean = false;
         if(param1.x <= _loc10_)
         {
            param1.x = _loc10_;
            _loc15_ = true;
            if(param1 is FighterMain && (param1 as FighterMain).getCurrentTarget().x < param1.x)
            {
               _loc15_ = false;
            }
         }
         if(param1.x >= _loc6_)
         {
            param1.x = _loc6_;
            _loc15_ = true;
            if(param1 is FighterMain && (param1 as FighterMain).getCurrentTarget().x > param1.x)
            {
               _loc15_ = false;
            }
         }
         if(param1 is FighterMain)
         {
            _loc4_ = param1 as FighterMain;
            if(_loc15_ && !_loc12_)
            {
               ++_loc4_.ticksAtCorner;
               if(_loc14_)
               {
                  (_loc4_.getCurrentTarget() as FighterMain).ticksAtCorner = 0;
               }
            }
            else
            {
               _loc4_.ticksAtCorner = 0;
            }
         }
         param1.setIsTouchSide(_loc15_ && !_loc12_);
      }
      
      public static function fixGameSpritePositionY(param1:IGameSprite) : void
      {
         if(param1.isDestoryed())
         {
            return;
         }
         if(param1.allowCrossMapBottom())
         {
            return;
         }
         if(param1.y > _map.playerBottom)
         {
            param1.y = _map.playerBottom;
         }
      }
      
      public static function resetFighterHP(param1:FighterMain) : void
      {
         var _loc2_:* = 1;
         if(GameMode.isAcrade() && MessionModel.I.getCurrentMessionStage())
         {
            _loc2_ = MessionModel.I.getCurrentMessionStage().hpRate;
         }
         if(param1.customHpMax > 0)
         {
            param1.hp = param1.hpMax = param1.customHpMax * GameData.I.config.fighterHP * _loc2_;
         }
         else
         {
            param1.hp = param1.hpMax = 1000 * GameData.I.config.fighterHP * _loc2_;
         }
         param1.isAlive = true;
      }
      
      public static function setMessionEnemyAttack(param1:FighterMain) : void
      {
         var _loc2_:MessionStageVO = MessionModel.I.getCurrentMessionStage();
         if(_loc2_)
         {
            param1.attackRate = _loc2_.attackRate;
         }
      }
      
      public static function canSelectFighter(param1:String) : Boolean
      {
         var _loc3_:SelectCharListConfigVO = GameData.I.config.select_config.charList;
         for each(var _loc2_ in _loc3_.list)
         {
            if(_loc2_.fighterID == param1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function canSelectAssist(param1:String) : Boolean
      {
         var _loc3_:SelectCharListConfigVO = GameData.I.config.select_config.assistList;
         for each(var _loc2_ in _loc3_.list)
         {
            if(_loc2_.fighterID == param1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function setGameMode(param1:int) : void
      {
         switch(param1 - 1)
         {
            case 0:
               GameData.I.loadSelect("config/salect.xml");
               SelectIndexUI.SHOW_MODE = 1;
               GameConfig.SHOW_UI_STATUS = 1;
               GameEndCtrl.SHOW_CONTINUE = true;
               break;
            case 1:
               GameData.I.loadDebugSelect("salect.xml");
               SelectIndexUI.SHOW_MODE = 1;
               GameConfig.SHOW_UI_STATUS = 1;
               GameEndCtrl.SHOW_CONTINUE = true;
               break;
            default:
               GameData.I.loadSelect("config/select.xml");
               ResUtils.WINNER = "winner_stg_mc";
               SelectIndexUI.SHOW_MODE = 0;
               GameConfig.SHOW_UI_STATUS = 0;
               GameEndCtrl.SHOW_CONTINUE = false;
         }
      }
   }
}

