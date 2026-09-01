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

      /** 按 comicType 回退查找可用的 mission：优先精确匹配 gameMode，
       *  否则取该 comicType 下任意 design，再不行取全局第一个可用 design。
       *  解决随机角色/无精确匹配关卡时 _curMession=null 导致误判通关的问题。 */
      public function getMessionFallback(param1:int, param2:int) : MessionVO
      {
         var anyInComic:MessionVO = null;
         if(!this._messions) { return null; }
         for each(var vo:MessionVO in this._messions)
         {
            if(vo.comicType == param1)
            {
               if(anyInComic == null) { anyInComic = vo; }
               if(vo.gameMode == param2) { return vo; }
            }
         }
         if(anyInComic != null) { return anyInComic; }
         if(this._messions.length > 0) { return this._messions[0]; }
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
         if(!_loc2_) { Debugger.log("[MessionModel] initMession FAILED: fighter not found"); return; }
         var _loc3_:int = GameMode.isTeamMode() ? 0 : 1;
         var _loc4_:MessionVO = this.getMession(_loc2_.comicType,_loc3_);
         if(!_loc4_)
         {
            // 无精确匹配关卡（如随机角色 comic_type=-1 等）→ 回退到配置里可用的关卡，避免 _curMession=null 误判通关
            _loc4_ = this.getMessionFallback(_loc2_.comicType,_loc3_);
            if(_loc4_)
            {
               Debugger.log("[MessionModel] 无精确 mission，回退 comicType=" + _loc4_.comicType + " gameMode=" + _loc4_.gameMode);
            }
            else
            {
               Debugger.log("[MessionModel] initMession FAILED: no mission at all");
               return;
            }
         }
         this._curMession = _loc4_;
         // 若选中的 design 关卡为空，回退到配置里第一个有 stageList 的可用 design
         if(!this._curMession.stageList || this._curMession.stageList.length == 0)
         {
            var _fb:MessionVO = this.getMessionFallback(_loc2_.comicType,_loc3_);
            if(_fb && _fb.stageList && _fb.stageList.length > 0)
            {
               Debugger.log("[MessionModel] 空 stageList，回退到可用关卡");
               this._curMession = _fb;
            }
         }
         if(!this._curMession.stageList || this._curMession.stageList.length == 0)
         {
            Debugger.log("[MessionModel] initMession FAILED: empty stageList");
            this._curMession = null;
            return;
         }
         this._curStage = this._curMession.stageList[this._curStageId];
         if(!this._curStage) { Debugger.log("[MessionModel] initMession FAILED: stage index out of range"); return; }
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
         if(!this._curMession || !this._curMession.stageList || this._curMession.stageList.length == 0)
         {
            Debugger.log("[MessionModel] messionComplete: 异常状态，本次不推进");
            return;
         }
         ++this._curStageId;
         if (this._curStageId > this._curMession.stageList.length - 1)
         {
            this._curStageId = this._curMession.stageList.length - 1;
         }
         this.initMession();
         if(GameMode.isAcrade())
         {
            GameLogic.addScoreByPassMission();
         }
      }
      
      public function missionAllComplete() : Boolean
      {
         if(!this._curMession || !this._curMession.stageList || this._curMession.stageList.length == 0)
         {
            Debugger.log("[MessionModel] missionAllComplete: 无有效关卡数据，视为未通关");
            return false;
         }
         return this._curStageId >= this._curMession.stageList.length - 1;
      }
   }
}

