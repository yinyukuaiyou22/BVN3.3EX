package net.play5d.game.bvn.ctrl.game_ctrls
{
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.events.*;
   import net.play5d.game.bvn.interfaces.*;
   
   public class FighterEventCtrl
   {
      
      private var _attackers:Array = [];
      
      public function FighterEventCtrl()
      {
         super();
      }
      
      public function initlize() : void
      {
         FighterEventDispatcher.removeAllListeners();
         FighterEventDispatcher.addEventListener("FIRE_BULLET",this.fireBullet);
         FighterEventDispatcher.addEventListener("ADD_ATTACKER",this.addAttacker);
         FighterEventDispatcher.addEventListener("ADD_ASSISTER",this.addAssister);
         FighterEventDispatcher.addEventListener("HIT_TARGET",this.onHitTarget);
         FighterEventDispatcher.addEventListener("HURT_RESUME",this.onHurtResume);
         FighterEventDispatcher.addEventListener("HURT_DOWN",this.onHurtDown);
         FighterEventDispatcher.addEventListener("DIE",this.onDie);
      }
      
      public function destory() : void
      {
         FighterEventDispatcher.removeAllListeners();
      }
      
      private function fireBullet(param1:FighterEvent) : void
      {
         var _loc2_:Object = param1.params;
         if(!_loc2_ || !_loc2_.mc)
         {
            return;
         }
         var _loc3_:Bullet = new Bullet(_loc2_.mc,_loc2_);
         _loc3_.onRemove = this.removeBullet;
         _loc3_.setHitVO(_loc2_.hitVO);
         GameCtrl.I.addGameSprite(param1.fighter.team.id,_loc3_);
      }
      
      private function removeBullet(param1:Bullet) : void
      {
         GameCtrl.I.removeGameSprite(param1);
      }
      
      private function addAttacker(param1:FighterEvent) : void
      {
         var _loc2_:Object = param1.params;
         if(!_loc2_ || !_loc2_.mc)
         {
            return;
         }
         var _loc3_:FighterAttacker = new FighterAttacker(_loc2_.mc,_loc2_);
         _loc3_.onRemove = this.removeAttacker;
         _loc3_.setOwner(param1.fighter);
         _loc3_.init();
         this._attackers.push(_loc3_);
         GameCtrl.I.addGameSprite(param1.fighter.team.id,_loc3_);
      }
      
      private function addAssister(param1:FighterEvent) : void
      {
         var _loc2_:FighterMain = param1.fighter as FighterMain;
         var _loc3_:GameRunFighterGroup = _loc2_.team.id == 1 ? GameCtrl.I.gameRunData.p1FighterGroup : GameCtrl.I.gameRunData.p2FighterGroup;
         var _loc4_:Assister = _loc3_.fuzhu;
         _loc4_.setOwner(_loc2_);
         _loc4_.direct = _loc2_.direct;
         _loc4_.x = _loc2_.x - 30 * _loc4_.direct;
         _loc4_.y = _loc2_.y;
         _loc4_.onRemove = this.removeAssister;
         GameCtrl.I.addGameSprite(param1.fighter.team.id,_loc4_);
         EffectCtrl.I.assisterEffect(_loc4_);
         _loc4_.goFight();
      }
      
      private function removeAssister(param1:Assister) : void
      {
         GameCtrl.I.removeGameSprite(param1);
      }
      
      private function removeAttacker(param1:FighterAttacker) : void
      {
         GameCtrl.I.removeGameSprite(param1);
         var _loc2_:int = int(this._attackers.indexOf(param1));
         if(_loc2_ != -1)
         {
            this._attackers.splice(_loc2_,1);
         }
      }
      
      public function getAttacker(param1:String, param2:int) : FighterAttacker
      {
         var _loc3_:* = undefined;
         for each(_loc3_ in this._attackers)
         {
            if(_loc3_.name == param1 && _loc3_.team.id == param2)
            {
               return _loc3_;
            }
         }
         return null;
      }
      
      private function onHitTarget(param1:FighterEvent) : void
      {
         this.addHits(param1.fighter as FighterMain,param1.params.target);
         if(Boolean(GameMode.isAcrade()) && param1.fighter.team.id == 1)
         {
            GameLogic.addScoreByHitTarget(param1.params.hitvo);
         }
      }
      
      private function onHurtResume(param1:FighterEvent) : void
      {
         this.removeHits(param1.fighter.id);
      }
      
      private function onHurtDown(param1:FighterEvent) : void
      {
         this.removeHits(param1.fighter.id);
      }
      
      private function addHits(param1:FighterMain, param2:IGameSprite) : void
      {
         var _loc3_:String = Boolean(param2) && param2 is BaseGameSprite ? (param2 as BaseGameSprite).id : null;
         var _loc4_:int = 1;
         switch(param1.team.id - 1)
         {
            case 0:
               _loc4_ = 1;
               break;
            case 1:
               _loc4_ = 2;
         }
         var _loc5_:int = int(GameLogic.addHits(param1.id,_loc3_,_loc4_));
         if(_loc5_ > 1)
         {
            GameCtrl.I.gameState.gameUI.getUI().showHits(_loc5_,_loc4_);
         }
      }
      
      private function removeHits(param1:String) : void
      {
         var _loc2_:Object = GameLogic.getHitsObjByTargetId(param1);
         if(Boolean(_loc2_))
         {
            GameCtrl.I.gameState.gameUI.getUI().hideHits(_loc2_.uiID);
         }
         GameLogic.clearHitsByTargetId(param1);
      }
      
      private function onDie(param1:FighterEvent) : void
      {
         var _loc5_:* = undefined;
         var _loc2_:FighterMain = null;
         var _loc3_:FighterMain = param1.fighter as FighterMain;
         var _loc4_:TeamVO = GameCtrl.I.getEnemyTeam(param1.fighter);

         // 2v2/1v2: 检查死亡方是否还有存活队友
         if (GameMode.isDuoMode() || GameMode.is1v2Mode()) {
            var _team:TeamVO = _loc3_.team;
            var _hasSurvivor:Boolean = false;
            if (Boolean(_team)) {
               for each(var _child:* in _team.children) {
                  if (_child is FighterMain && (_child as FighterMain).isAlive && _child != _loc3_) {
                     _hasSurvivor = true;
                     break;
                  }
               }
            }
            if (_hasSurvivor) {
               _loc3_.isAlive = false;
               return;  // 不结束回合，队友继续战斗
            }
         }

         if(Boolean(_loc4_))
         {
            for each(_loc5_ in _loc4_.children)
            {
               if(_loc5_ is FighterMain)
               {
                  _loc2_ = _loc5_ as FighterMain;
                  break;
               }
            }
         }
         GameCtrl.I.gameEnd(_loc2_,_loc3_);
      }
   }
}

