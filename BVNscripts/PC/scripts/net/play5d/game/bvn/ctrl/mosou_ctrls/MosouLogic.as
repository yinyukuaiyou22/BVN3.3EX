package net.play5d.game.bvn.ctrl.mosou_ctrls
{
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.mosou.MosouEnemyVO;
   import net.play5d.game.bvn.data.mosou.MosouFighterSellVO;
   import net.play5d.game.bvn.data.mosou.MosouMissionVO;
   import net.play5d.game.bvn.data.mosou.MosouModel;
   import net.play5d.game.bvn.data.mosou.MosouWorldMapAreaVO;
   import net.play5d.game.bvn.data.mosou.MosouWorldMapVO;
   import net.play5d.game.bvn.data.mosou.player.MosouMissionPlayerVO;
   import net.play5d.game.bvn.data.mosou.player.MosouPlayerData;
   import net.play5d.game.bvn.data.mosou.player.MosouWorldMapAreaPlayerVO;
   import net.play5d.game.bvn.data.mosou.player.MosouWorldMapPlayerVO;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.ui.GameUI;
   
   public class MosouLogic
   {
      
      private static var _i:MosouLogic;
      
      private var _hitNum:int;
      
      private var _hitTargets:Vector.<FighterMain> = new Vector.<FighterMain>();
      
      public function MosouLogic()
      {
         super();
      }
      
      public static function get I() : MosouLogic
      {
         if(!_i)
         {
            _i = new MosouLogic();
         }
         return _i;
      }
      
      public static function checkCurrentArea(param1:String) : Boolean
      {
         var _loc2_:MosouPlayerData = GameData.I.mosouData;
         if(_loc2_.getCurrentArea() == null)
         {
            return false;
         }
         return _loc2_.getCurrentArea().id == param1;
      }
      
      public static function checkAreaIsOpen(param1:String) : Boolean
      {
         var _loc2_:MosouPlayerData = GameData.I.mosouData;
         var _loc3_:MosouWorldMapPlayerVO = _loc2_.getCurrentMap();
         return _loc3_.getOpenArea(param1) != null;
      }
      
      public static function getNextMission(param1:MosouWorldMapAreaVO) : MosouMissionVO
      {
         var _loc5_:MosouPlayerData = GameData.I.mosouData;
         var _loc6_:MosouWorldMapPlayerVO = _loc5_.getCurrentMap();
         var _loc2_:MosouWorldMapAreaPlayerVO = _loc6_.getOpenArea(param1.id);
         if(_loc2_ == null)
         {
            return null;
         }
         var _loc3_:MosouMissionPlayerVO = _loc2_.getLastPassedMission();
         if(_loc3_ == null)
         {
            return param1.missions[0];
         }
         var _loc4_:MosouMissionVO = param1.getNextMission(_loc3_.id);
         if(_loc4_ != null)
         {
            return _loc4_;
         }
         return param1.missions[param1.missions.length - 1];
      }
      
      public static function getAreaPercent(param1:String) : Number
      {
         var _loc3_:MosouPlayerData = GameData.I.mosouData;
         var _loc5_:MosouWorldMapPlayerVO = _loc3_.getCurrentMap();
         var _loc2_:MosouWorldMapAreaPlayerVO = _loc5_.getOpenArea(param1);
         if(_loc2_ == null)
         {
            return 0;
         }
         var _loc4_:MosouWorldMapAreaVO = MosouModel.I.getMapArea(_loc5_.id,_loc2_.id);
         if(_loc4_ == null || _loc4_.missions == null)
         {
            return 0;
         }
         return _loc2_.getPassedMissionAmount() / _loc4_.missions.length;
      }
      
      public static function openMapArea(param1:String, param2:String) : void
      {
         var _loc3_:MosouPlayerData = GameData.I.mosouData;
         var _loc4_:MosouWorldMapPlayerVO = _loc3_.getMapById(param1);
         _loc4_.openArea(param2);
      }
      
      public static function passMission(param1:MosouMissionVO) : void
      {
         var _loc3_:MosouPlayerData = GameData.I.mosouData;
         var _loc2_:MosouWorldMapAreaPlayerVO = _loc3_.getCurrentArea();
         _loc3_.addMoney(_loc2_.passMission(param1.id) ? 800 : 100);
         updateMapAreas();
         GameData.I.saveData();
      }
      
      public static function updateMapAreas() : void
      {
         var _loc5_:Boolean = false;
         var _loc2_:MosouPlayerData = GameData.I.mosouData;
         var _loc3_:MosouWorldMapPlayerVO = _loc2_.getCurrentMap();
         var _loc6_:MosouWorldMapVO = MosouModel.I.getMap(_loc3_.id);
         for each(var _loc4_ in _loc6_.areas)
         {
            if(_loc4_.preOpens && _loc4_.preOpens.length > 0)
            {
               _loc5_ = true;
               for each(var _loc1_ in _loc4_.preOpens)
               {
                  if(!canPassNextArea(_loc1_.id))
                  {
                     _loc5_ = false;
                     break;
                  }
               }
               if(_loc5_)
               {
                  openMapArea(_loc3_.id,_loc4_.id);
               }
            }
         }
      }
      
      private static function canPassNextArea(param1:String) : Boolean
      {
         return getAreaPercent(param1) > 0.6;
      }
      
      public static function initEnemyProps(param1:FighterMain) : void
      {
         var _loc7_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:MosouEnemyVO = param1.mosouEnemyData;
         if(_loc4_ == null)
         {
            return;
         }
         var _loc6_:MosouMissionVO = MosouModel.I.currentMission;
         if(_loc6_ == null)
         {
            return;
         }
         var _loc8_:int = _loc6_.enemyLevel;
         _loc4_.level = _loc8_;
         if(_loc4_.isBoss)
         {
            if(_loc4_.maxHp > 0)
            {
               param1.hpMax = _loc4_.maxHp;
            }
            else
            {
               param1.hpMax = 1000 + _loc8_ * 400;
            }
            param1.energy = param1.energyMax = 80 + _loc8_ * 10;
            _loc7_ = _loc8_ * 13;
            _loc5_ = _loc8_ * 14;
            _loc2_ = _loc8_ * 15;
            param1.initAttackAddDmg(_loc7_,_loc5_,_loc2_);
         }
         else
         {
            if(_loc4_.maxHp > 0)
            {
               param1.hp = param1.hpMax = _loc4_.maxHp;
            }
            else
            {
               _loc3_ = 1 + (_loc8_ - 1) * 0.08;
               if(_loc3_ > 1)
               {
                  param1.hp = param1.hpMax = param1.hp * _loc3_;
               }
            }
            _loc7_ = _loc8_ * 5;
            _loc5_ = _loc8_ * 10;
            _loc2_ = _loc8_ * 20;
            param1.initAttackAddDmg(_loc7_,_loc5_,_loc2_);
         }
      }
      
      public function buyFighter(param1:MosouFighterSellVO, param2:Function = null) : void
      {
         var data:MosouFighterSellVO = param1;
         var succback:Function = param2;
         var mosouData:MosouPlayerData = GameData.I.mosouData;
         if(mosouData.getMoney() < data.getPrice())
         {
            GameUI.alert(GetLangText("game_ui.alert.musou_money_not_enough.title"),GetLangText("game_ui.alert.musou_money_not_enough.message_prefix") + data.getPrice() + GetLangText("game_ui.alert.musou_money_not_enough.message_suffix"),null,true);
            return;
         }
         GameUI.confrim(GetLangText("game_ui.confrim.musou_buy.title"),GetLangText("game_ui.confrim.musou_buy.message_prefix") + data.getPrice() + GetLangText("game_ui.confrim.musou_buy.message_suffix"),function():void
         {
            mosouData.loseMoney(data.getPrice());
            mosouData.addFighter(data.id);
            GameData.I.saveData();
            if(succback != null)
            {
               succback();
            }
         },null,true);
      }
      
      public function addHits(param1:FighterMain) : int
      {
         if(_hitTargets.indexOf(param1) == -1)
         {
            _hitTargets.push(param1);
         }
         _hitNum = _hitNum + 1;
         if(_hitNum > 1 && GameUI.I.getUI())
         {
            GameUI.I.getUI().showHits(_hitNum,1);
         }
         return _hitNum;
      }
      
      public function removeHitTarget(param1:FighterMain) : void
      {
         var _loc2_:int = _hitTargets.indexOf(param1);
         if(_loc2_ == -1)
         {
            return;
         }
         _hitTargets.splice(_loc2_,1);
         if(_hitTargets.length < 1)
         {
            _hitNum = 0;
            if(GameUI.I && GameUI.I.getUI())
            {
               GameUI.I.getUI().hideHits(1);
            }
         }
      }
      
      public function clearHits() : void
      {
         _hitNum = 0;
         _hitTargets = new Vector.<FighterMain>();
      }
   }
}

