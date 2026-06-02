package net.play5d.game.bvn.ctrl.game_ctrls
{
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.GameRunFighterGroup;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.Bullet;
   import net.play5d.game.bvn.fighter.FighterAttacker;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.events.FighterEvent;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class BaseFighterEventCtrl
   {
      
      private var _attackers:Array = [];
      
      public function BaseFighterEventCtrl()
      {
         super();
      }
      
      private static function fireBullet(param1:FighterEvent) : void
      {
         var _loc10_:String = null;
         var _loc9_:String = null;
         var _loc7_:IGameSprite = null;
         var _loc5_:Object = param1.params;
         if(_loc5_ == null || !_loc5_.mc)
         {
            return;
         }
         var _loc6_:Bullet = new Bullet(_loc5_.mc,_loc5_);
         _loc6_.onRemove = removeBullet;
         var _loc8_:HitVO = _loc5_.hitVO.clone();
         if(_loc5_.owner)
         {
            _loc8_.owner = _loc5_.owner;
         }
         _loc6_.setHitVO(_loc8_);
         var _loc2_:BaseGameSprite = param1.fighter as BaseGameSprite;
         var _loc4_:GameRunFighterGroup = GameCtrl.I.gameRunData.p1FighterGroup;
         var _loc3_:GameRunFighterGroup = GameCtrl.I.gameRunData.p2FighterGroup;
         if(_loc2_.team.id == 2 && GameMode.currentMode != 100)
         {
            if(_loc2_ is FighterMain)
            {
               _loc10_ = _loc4_.currentFighter.data.id;
               _loc9_ = _loc3_.currentFighter.data.id;
            }
            else if(_loc2_ is Assister)
            {
               _loc10_ = _loc4_.currentAssister.data.id;
               _loc9_ = _loc3_.currentAssister.data.id;
            }
            else if(_loc2_ is FighterAttacker)
            {
               _loc7_ = (_loc2_ as FighterAttacker).getOwner();
               if(_loc7_ is FighterMain)
               {
                  _loc10_ = _loc4_.currentFighter.data.id;
                  _loc9_ = _loc3_.currentFighter.data.id;
               }
               else if(_loc7_ is Assister)
               {
                  _loc10_ = _loc4_.currentAssister.data.id;
                  _loc9_ = _loc3_.currentAssister.data.id;
               }
            }
            if(_loc10_ != null && _loc9_ != null && _loc10_ == _loc9_)
            {
               SetP2SpColor(_loc6_);
            }
         }
         GameCtrl.I.addGameSprite(_loc2_.team.id,_loc6_);
      }
      
      private static function removeBullet(param1:Bullet) : void
      {
         GameCtrl.I.removeGameSprite(param1);
      }
      
      public function initialize() : void
      {
         FighterEventDispatcher.removeAllListeners();
         FighterEventDispatcher.addEventListener("FIRE_BULLET",fireBullet);
         FighterEventDispatcher.addEventListener("ADD_ATTACKER",addAttacker);
      }
      
      private function addAttacker(param1:FighterEvent) : void
      {
         var _loc8_:String = null;
         var _loc7_:String = null;
         var _loc6_:Object = param1.params;
         if(_loc6_ == null || !_loc6_.mc)
         {
            return;
         }
         var _loc2_:BaseGameSprite = param1.fighter as BaseGameSprite;
         var _loc4_:FighterAttacker = new FighterAttacker(_loc6_.mc,_loc6_,_loc2_);
         _loc4_.onRemove = removeAttacker;
         _loc4_.setOwner(_loc2_);
         _loc4_.init();
         var _loc5_:GameRunFighterGroup = GameCtrl.I.gameRunData.p1FighterGroup;
         var _loc3_:GameRunFighterGroup = GameCtrl.I.gameRunData.p2FighterGroup;
         if(_loc2_.team.id == 2 && GameMode.currentMode != 100)
         {
            if(_loc2_ is FighterMain)
            {
               _loc8_ = _loc5_.currentFighter.data.id;
               _loc7_ = _loc3_.currentFighter.data.id;
            }
            else if(_loc2_ is Assister)
            {
               _loc8_ = _loc5_.currentAssister.data.id;
               _loc7_ = _loc3_.currentAssister.data.id;
            }
            if(_loc8_ != null && _loc7_ != null && _loc8_ == _loc7_)
            {
               SetP2SpColor(_loc4_);
            }
         }
         _attackers.push(_loc4_);
         GameCtrl.I.addGameSprite(_loc2_.team.id,_loc4_);
      }
      
      private function removeAttacker(param1:FighterAttacker) : void
      {
         GameCtrl.I.removeGameSprite(param1);
         var _loc2_:int = _attackers.indexOf(param1);
         if(_loc2_ != -1)
         {
            _attackers.splice(_loc2_,1);
         }
      }
      
      public function getAttacker(param1:String, param2:int) : FighterAttacker
      {
         for each(var _loc3_ in _attackers)
         {
            if(_loc3_.name == param1 && _loc3_.team.id == param2)
            {
               return _loc3_;
            }
         }
         return null;
      }
      
      public function destory() : void
      {
         FighterEventDispatcher.removeAllListeners();
      }
   }
}

