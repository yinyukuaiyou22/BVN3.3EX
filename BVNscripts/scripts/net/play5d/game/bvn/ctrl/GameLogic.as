package net.play5d.game.bvn.ctrl
{
   import flash.geom.Rectangle;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.events.*;
   import net.play5d.game.bvn.Debugger;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.map.FloorVO;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.state.GameCamera;
   import net.play5d.game.bvn.ui.select.*;
   import net.play5d.game.bvn.utils.*;
   
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
         if(!_map)
         {
            Debugger.log("error:map is null!");
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
         var _loc2_:* = param1.getVecY() < 5 * GameConfig.SPEED_PLUS;
         if(!_loc2_)
         {
            return true;
         }
         var _loc3_:Number = 10 * GameConfig.SPEED_PLUS_DEFAULT;
         var _loc4_:FloorVO = _floorContact[param1];
         if(Boolean(_loc4_))
         {
            if(_loc4_.hitTest(param1.x,param1.y,_loc3_))
            {
               param1.y = _loc4_.y;
               return false;
            }
            delete _floorContact[param1];
            return true;
         }
         _loc4_ = _map.getFloorHitTest(param1.x,param1.y,_loc3_);
         if(Boolean(_loc4_))
         {
            param1.y = _loc4_.y;
            _floorContact[param1] = _loc4_;
            return false;
         }
         return true;
      }
      
      public static function isTouchBottomFloor(param1:IGameSprite) : Boolean
      {
         if(!_map)
         {
            Debugger.log("error:map is null!");
            return false;
         }
         return param1.y > _map.playerBottom;
      }
      
      public static function isOutRange(param1:IGameSprite) : Boolean
      {
         if(!_map)
         {
            Debugger.log("error:map is null!");
            return false;
         }
         var _loc2_:int = 20;
         return param1.x > _map.right + _loc2_ || param1.x < _map.left - _loc2_ || param1.y > _map.bottom + _loc2_;
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
         ++_hitsObj[param1].hits;
         return _hitsObj[param1].hits;
      }
      
      public static function clearHits(param1:Object) : void
      {
         _hitsObj[param1].hits = 0;
         _hitsObj[param1].targetID = null;
         _hitsObj[param1].uiID = null;
      }
      
      public static function getHitsObj(param1:Object) : Object
      {
         return _hitsObj[param1];
      }
      
      public static function getHitsObjByTargetId(param1:Object) : Object
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in _hitsObj)
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
         var _loc2_:* = undefined;
         for(_loc2_ in _hitsObj)
         {
            if(_hitsObj[_loc2_].targetID == param1)
            {
               delete _hitsObj[_loc2_];
            }
         }
      }
      
      public static function checkFighterDie(param1:FighterMain) : Boolean
      {
         if(GameMode.currentMode == 40)
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
         var _loc2_:int = 0;
         var _loc3_:* = _loc2_ = param1.power;
         if(param1.isBisha())
         {
            _loc3_ = _loc2_ * 2;
         }
         if(param1.id == "sh1" || param1.id == "sh2")
         {
            _loc3_ += 500;
         }
         if(param1.isBreakDef)
         {
            _loc3_ += 200;
         }
         if(param1.hurtType == 1)
         {
            _loc3_ += 200;
         }
         var _loc4_:Object = getHitsObj(1);
         var _loc5_:int = int(_loc4_ ? _loc4_.hits : 0);
         if(_loc5_ < 4)
         {
            _loc3_ += _loc5_ * 50;
         }
         else
         {
            _loc3_ += _loc5_ * 100;
         }
         addScore(_loc3_);
         GameEvent.dispatchEvent("SCORE_UPDATE");
      }
      
      public static function addScoreByKO() : void
      {
         var _loc1_:int = 0;
         if(Boolean(GameCtrl.I.gameRunData.p1FighterGroup.currentFighter.lastHitVO) && Boolean(GameCtrl.I.gameRunData.p1FighterGroup.currentFighter.lastHitVO.isBisha()))
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
         if(GameMode.currentMode == 10 && GameCtrl.I.gameRunData.p1FighterGroup.currentFighter == GameCtrl.I.gameRunData.p1FighterGroup.fighter1)
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
         var _loc2_:* = NaN;
         var _loc3_:* = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:Rectangle = null;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Boolean = false;
         if(param1.allowCrossMapXY() == false)
         {
            _loc2_ = _map.left + 10;
            _loc3_ = _map.right - 10;
            _loc4_ = 10;
            _loc5_ = Number(_camera.getZoom());
            _loc6_ = _camera.getScreenRect();
            if(param1 is FighterMain)
            {
               if((param1 as FighterMain).getVecX() != 0)
               {
                  if(_loc5_ == _camera.autoZoomMin)
                  {
                     _loc7_ = _loc6_.x / _loc5_ + _loc4_;
                     _loc8_ = _loc7_ + _loc6_.width - _loc4_;
                     if(_loc2_ < _loc7_)
                     {
                        _loc2_ = _loc7_;
                     }
                     if(_loc3_ > _loc8_)
                     {
                        _loc3_ = _loc8_;
                     }
                  }
               }
            }
            _loc9_ = false;
            if(param1.x <= _loc2_)
            {
               param1.x = _loc2_;
               _loc9_ = true;
            }
            if(param1.x >= _loc3_)
            {
               param1.x = _loc3_;
               _loc9_ = true;
            }
            param1.setIsTouchSide(_loc9_);
         }
         if(param1.allowCrossMapBottom() == false)
         {
            if(param1.y > _map.bottom)
            {
               param1.y = _map.bottom;
            }
         }
      }
      
      public static function resetFighterHP(param1:FighterMain) : void
      {
         var _loc2_:Number = 1;
         if(Boolean(GameMode.isAcrade()) && Boolean(MessionModel.I.getCurrentMessionStage()))
         {
            _loc2_ = Number(MessionModel.I.getCurrentMessionStage().hpRate);
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
         if(Boolean(_loc2_))
         {
            param1.attackRate = _loc2_.attackRate;
         }
      }
      
      public static function canSelectFighter(param1:String) : Boolean
      {
         var _loc3_:* = undefined;
         var _loc2_:SelectCharListConfigVO = GameData.I.config.select_config.charList;
         for each(_loc3_ in _loc2_.list)
         {
            if(_loc3_.fighterID == param1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function canSelectAssist(param1:String) : Boolean
      {
         var _loc3_:* = undefined;
         var _loc2_:SelectCharListConfigVO = GameData.I.config.select_config.assistList;
         for each(_loc3_ in _loc2_.list)
         {
            if(_loc3_.fighterID == param1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function setGameMode(param1:int) : void
      {
         if(param1 == 1)
         {
            GameData.I.loadSelect("assets/config/salect.xml");
            ResUtils.WINNER = "winner_stg_mc2";
            SelectIndexUI.SHOW_MODE = 1;
         }
         else
         {
            GameData.I.loadSelect("assets/config/select.xml");
            ResUtils.WINNER = "winner_stg_mc";
            SelectIndexUI.SHOW_MODE = 0;
         }
      }
   }
}

