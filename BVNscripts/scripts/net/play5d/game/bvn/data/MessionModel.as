package net.play5d.game.bvn.data
{
   import net.play5d.game.bvn.ctrl.*;
import net.play5d.game.bvn.Debugger;
   
   public class MessionModel
   {
      
      private static var _i:MessionModel;
      
      public var AI_LEVEL:int = 6;
      
      private var _curMession:MessionVO;
      
      private var _curStageId:int;
      
      private var _curStage:MessionStageVO;
      
      private var _messions:Array;
      
      public function MessionModel()
      {
         super();
      }
      
      public static function get I() : MessionModel
      {
         if(!_i)
         {
            _i = new MessionModel();
         }
         return _i;
      }
      
      public function initByXML(param1:XML) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:MessionVO = null;
         this._messions = [];
         for each(_loc3_ in param1.design)
         {
            _loc2_ = new MessionVO();
            _loc2_.initByXML(_loc3_);
            this._messions.push(_loc2_);
         }
      }

      /** Ensure backing store is initialized (safe to call before any operations) */
      public function ensureInit() : void
      {
         if(!this._messions) { this._messions = []; }
      }

      /** Merge missions from external XML (append only, skip duplicates by comicType+gameMode) */
      public function mergeByXML(param1:XML) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:MessionVO = null;
         if(!this._messions)
         {
            this._messions = [];
         }
         for each(_loc3_ in param1.design)
         {
            _loc2_ = new MessionVO();
            _loc2_.initByXML(_loc3_);
            var dup:Boolean = false;
            for each(var existing:* in this._messions)
            {
               if(existing.comicType == _loc2_.comicType && existing.gameMode == _loc2_.gameMode)
               {
                  dup = true;
                  break;
               }
            }
            if(!dup)
            {
               this._messions.push(_loc2_);
            }
         }
      }
      
      public function getMession(param1:int, param2:int) : MessionVO
      {
         var _loc3_:* = undefined;
         for each(_loc3_ in this._messions)
         {
            if(_loc3_.comicType == param1 && _loc3_.gameMode == param2)
            {
               return _loc3_;
            }
         }
         return null;
      }
      
      public function getCurrentMessionStage() : MessionStageVO
      {
         return this._curStage;
      }
      
      public function initMession() : void
      {
         var _loc1_:int = 0;
         var _loc2_:FighterVO = FighterModel.I.getFighter(GameData.I.p1Select.fighter1);
         var _loc3_:int = GameMode.isTeamMode() ? 0 : 1;
         var _loc4_:MessionVO = this.getMession(_loc2_.comicType,_loc3_);
         this._curMession = _loc4_;
         this._curStage = _loc4_.stageList[this._curStageId];
         GameData.I.p2Select = GameData.I.p2Select || new SelectVO();
         var _loc5_:Array = this._curStage.getFighters();
         while(_loc1_ < _loc5_.length)
         {
            GameData.I.p2Select["fighter" + (_loc1_ + 1)] = _loc5_[_loc1_];
            _loc1_++;
         }
         GameData.I.p2Select.fuzhu = this._curStage.assister;
         GameData.I.selectMap = this._curStage.map;
         this.AI_LEVEL = GameData.I.config.AI_level;
         Debugger.log("p1::",GameData.I.p1Select.toString());
         Debugger.log("p2::",GameData.I.p2Select.toString());
      }
      
      public function reset() : void
      {
         this._curStageId = 0;
         this._curStage = null;
         this._curMession = null;
         GameData.I.score = 0;
      }
      
      public function messionComplete() : void
      {
         if(this.missionAllComplete())
         {
            Debugger.log("mission all over!!!");
            return;
         }
         ++this._curStageId;
         this.initMession();
         if(GameMode.isAcrade())
         {
            GameLogic.addScoreByPassMission();
         }
      }
      
      public function missionAllComplete() : Boolean
      {
         return this._curStageId >= this._curMession.stageList.length - 1;
      }
   }
}

