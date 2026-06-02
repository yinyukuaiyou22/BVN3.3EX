package net.play5d.game.bvn.ctrl.game_ctrls
{
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.GameRunFighterGroup;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.ctrler.FighterKeyCtrl;
   import net.play5d.game.bvn.fighter.events.FighterEvent;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IFighterActionCtrl;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class FighterEventCtrl extends BaseFighterEventCtrl
   {
      
      public function FighterEventCtrl()
      {
         super();
      }
      
      private static function addAssister(param1:FighterEvent) : void
      {
         var _loc5_:FighterMain = param1.fighter as FighterMain;
         if(_loc5_.actionState != 0 && _loc5_.actionState != 20)
         {
            return;
         }
         if(GameMode.isMusouMode())
         {
            if(_loc5_.fzqi == 100)
            {
               _loc5_.fzqi = 0;
               changeFighter(_loc5_);
            }
            return;
         }
         var _loc2_:GameRunFighterGroup = _loc5_.team.id == 1 ? GameCtrl.I.gameRunData.p1FighterGroup : GameCtrl.I.gameRunData.p2FighterGroup;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc7_:Assister = _loc2_.currentAssister;
         if(_loc7_.getCtrler().useFzqi && _loc5_.fzqi < 100)
         {
            return;
         }
         var _loc3_:Object = _loc5_.getCtrler().getMcCtrl().getAction().specialAssistAction;
         if(_loc3_ != null)
         {
            _loc5_.getCtrler().getMcCtrl().doActionFlexible(_loc3_);
            if(_loc7_.getCtrler().useFzqi)
            {
               _loc5_.fzqi = 0;
            }
            return;
         }
         if(_loc7_ && !_loc7_.getCtrler().enabled)
         {
            return;
         }
         if(_loc7_.getCtrler().useFzqi)
         {
            _loc5_.fzqi = 0;
         }
         _loc7_.setOwner(_loc5_);
         _loc7_.direct = _loc5_.direct;
         _loc7_.x = _loc5_.x + _loc7_.orgPos.x * _loc7_.direct;
         _loc7_.y = _loc5_.y + _loc7_.orgPos.y;
         _loc7_.onRemove = removeAssister;
         var _loc8_:String = GameCtrl.I.gameRunData.p1FighterGroup.currentAssister.data.id;
         var _loc6_:String = GameCtrl.I.gameRunData.p2FighterGroup.currentAssister.data.id;
         if(_loc5_.team.id == 2 && _loc8_ == _loc6_)
         {
            SetP2SpColor(_loc7_);
         }
         if(_loc7_.data.hurtless == 0)
         {
            _loc5_ = param1.fighter as FighterMain;
            if((_loc5_.getCurrentTarget() as FighterMain).actionState == 21)
            {
               _loc5_.limitLevel++;
            }
         }
         var _loc4_:IFighterActionCtrl = _loc5_.getCtrler().getMcCtrl().getActionCtrler();
         if(_loc4_ is FighterKeyCtrl)
         {
            (_loc4_ as FighterKeyCtrl).justAssistFrame = 24;
         }
         GameCtrl.I.addGameSprite(param1.fighter.team.id,_loc7_);
         EffectCtrl.I.assisterEffect(_loc7_);
         _loc7_.goFight();
      }
      
      private static function changeFighter(param1:FighterMain) : void
      {
         var _loc4_:FighterMain = param1;
         var _loc5_:GameRunFighterGroup = _loc4_.team.id == 1 ? GameCtrl.I.gameRunData.p1FighterGroup : GameCtrl.I.gameRunData.p2FighterGroup;
         var _loc2_:GameRunFighterGroup = _loc4_.team.id != 1 ? GameCtrl.I.gameRunData.p1FighterGroup : GameCtrl.I.gameRunData.p2FighterGroup;
         if(_loc4_ != _loc5_.currentFighter)
         {
            return;
         }
         var _loc3_:FighterMain = _loc5_.getNextAliveFighter();
         if(_loc3_ == null)
         {
            return;
         }
         EffectCtrl.I.slowDownResume();
         _loc4_.needStopEffects = true;
         GameCtrl.I.removeFighter(_loc4_);
         _loc3_.x = _loc4_.x;
         _loc3_.y = _loc4_.y;
         _loc3_.fzqi = 0;
         _loc3_.hpMax = _loc4_.hpMax;
         _loc3_.hp = _loc4_.hp;
         _loc3_.qi = _loc4_.qi;
         _loc3_.energy = _loc3_.energyMax;
         _loc3_.energyOverLoad = false;
         _loc3_.direct = _loc4_.direct;
         if(_loc3_.initlized())
         {
            GameCtrl.I.addGameSprite(_loc3_.team.id,_loc3_);
         }
         else
         {
            GameCtrl.I.addFighter(_loc3_,_loc4_.team.id,false);
         }
         _loc5_.currentFighter = _loc3_;
         EffectCtrl.I.doEffectById("team_change",_loc3_.x,_loc3_.y);
         _loc3_.updatePosition();
         _loc3_.idle();
         GameCtrl.I.gameState.updateCameraFocus([_loc3_.getDisplay(),_loc2_.currentFighter.getDisplay()]);
         if(_loc4_.team.id == 1)
         {
            GameCtrl.I.gameState.gameUI.initFight(_loc5_,_loc2_);
         }
         else
         {
            GameCtrl.I.gameState.gameUI.initFight(_loc2_,_loc5_);
         }
      }
      
      private static function removeAssister(param1:Assister) : void
      {
         GameCtrl.I.removeGameSprite(param1);
      }
      
      public static function getAssister(param1:int) : Assister
      {
         var _loc4_:Assister = null;
         var _loc2_:Vector.<IGameSprite> = GameCtrl.I.gameState.getGameSprites();
         if(_loc2_ == null)
         {
            return null;
         }
         for each(var _loc3_ in _loc2_)
         {
            if(_loc3_ is Assister)
            {
               _loc4_ = _loc3_ as Assister;
               if(_loc4_.team.id == param1)
               {
                  return _loc4_;
               }
            }
         }
         return null;
      }
      
      private static function onHitTarget(param1:FighterEvent) : void
      {
         addHits(param1.fighter as FighterMain,param1.params.target);
         if(GameMode.isAcrade() && param1.fighter.team.id == 1)
         {
            GameLogic.addScoreByHitTarget(param1.params.hitvo);
         }
      }
      
      private static function onHurtResume(param1:FighterEvent) : void
      {
         removeHits(param1.fighter);
      }
      
      private static function onDead(param1:FighterEvent) : void
      {
         removeHits(param1.fighter);
      }
      
      private static function onIdle(param1:FighterEvent) : void
      {
         removeHits(param1.fighter);
      }
      
      private static function addHits(param1:FighterMain, param2:IGameSprite) : void
      {
         var _loc4_:String = param2 && param2 is BaseGameSprite ? (param2 as BaseGameSprite).id : null;
         var _loc5_:int = 1;
         switch(param1.team.id - 1)
         {
            case 0:
               _loc5_ = 1;
               break;
            case 1:
               _loc5_ = 2;
         }
         var _loc3_:int = GameLogic.addHits(param1.team.id,_loc4_,_loc5_);
         if(_loc3_ > 1)
         {
            GameCtrl.I.gameState.gameUI.getUI().showHits(_loc3_,_loc5_);
         }
      }
      
      private static function removeHits(param1:BaseGameSprite) : void
      {
         var uiID:int;
         var fighter:BaseGameSprite = param1;
         var delayCall:* = function():void
         {
            removeHits(fighter);
         };
         var id:String = fighter.id;
         var fighterMain:FighterMain = fighter as FighterMain;
         var _loc2_:Object = GameLogic.getHitsObjByTargetId(id);
         if(_loc2_)
         {
            uiID = int(_loc2_.uiID);
            if(uiID != 1 && uiID != 2)
            {
               fighterMain.delayCall(delayCall,1);
            }
            else
            {
               GameCtrl.I.gameState.gameUI.getUI().hideHits(_loc2_.uiID);
            }
         }
         GameLogic.clearHitsByTargetId(id);
      }
      
      private static function onDie(param1:FighterEvent) : void
      {
         GameCtrl.onFighterDie(param1.fighter as FighterMain);
      }
      
      override public function initialize() : void
      {
         super.initialize();
         FighterEventDispatcher.addEventListener("DO_SPECIAL",addAssister);
         FighterEventDispatcher.addEventListener("HIT_TARGET",onHitTarget);
         FighterEventDispatcher.addEventListener("HURT_RESUME",onHurtResume);
         FighterEventDispatcher.addEventListener("DEAD",onDead);
         FighterEventDispatcher.addEventListener("IDLE",onIdle);
         FighterEventDispatcher.addEventListener("DIE",onDie);
      }
   }
}

