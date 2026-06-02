package net.play5d.game.bvn.utils
{
   import flash.utils.Dictionary;
   import net.play5d.game.bvn.data.EffectModel;
   import net.play5d.game.bvn.data.EffectVO;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.views.effects.BuffEffectView;
   import net.play5d.game.bvn.views.effects.EffectView;
   import net.play5d.game.bvn.views.effects.ShineEffectView;
   import net.play5d.game.bvn.views.effects.SpecialEffectView;
   import net.play5d.game.bvn.views.effects.SteelHitEffect;
   
   public class EffectManager
   {
      
      private var _viewCache:Dictionary = new Dictionary();
      
      private var _hitCache:Dictionary = new Dictionary();
      
      private var _defCache:Dictionary = new Dictionary();
      
      private var _shineCache:Vector.<ShineEffectView> = new Vector.<ShineEffectView>();
      
      public function EffectManager()
      {
         super();
      }
      
      public function destory() : void
      {
         for each(var _loc3_ in _viewCache)
         {
            for each(var _loc2_ in _loc3_)
            {
               _loc2_.destory();
            }
         }
         for each(var _loc1_ in _shineCache)
         {
            _loc1_.destory();
         }
         _viewCache = null;
         _hitCache = null;
         _defCache = null;
         _shineCache = null;
      }
      
      public function getHitEffectVOByHitVO(param1:HitVO, param2:IGameSprite = null) : EffectVO
      {
         var _loc6_:FighterMain = null;
         var _loc3_:EffectCacheVO = _hitCache[param1];
         var _loc4_:Boolean = false;
         if(param2 && param2 is FighterMain)
         {
            _loc6_ = param2 as FighterMain;
            _loc4_ = _loc6_.isMosouEnemy();
         }
         if(_loc3_)
         {
            if(_loc4_ && _loc3_.mosouEnemy)
            {
               return _loc3_.mosouEnemy;
            }
            if(!_loc4_ && _loc3_.normal)
            {
               return _loc3_.normal;
            }
         }
         var _loc5_:EffectVO = _loc4_ ? EffectModel.I.getMosouEnemyHitEffect(param1.hitType) : EffectModel.I.getHitEffect(param1.hitType);
         if(_loc5_ == null)
         {
            _hitCache[param1] = null;
            return null;
         }
         _loc5_ = _loc5_.clone();
         if(_loc5_.shake)
         {
            if(_loc5_.shake.pow != undefined && _loc5_.shake.pow != 0)
            {
               _loc5_.shake.y = _loc5_.shake.pow;
            }
            if(_loc5_.shake.x == 0 && _loc5_.shake.y == 0)
            {
               _loc5_.shake.x = 3;
            }
         }
         _loc3_ = new EffectCacheVO();
         if(_loc4_)
         {
            _loc3_.mosouEnemy = _loc5_;
         }
         else
         {
            _loc3_.normal = _loc5_;
         }
         _hitCache[param1] = _loc3_;
         return _loc5_;
      }
      
      public function getDefenseEffectVOByHitVO(param1:HitVO, param2:int, param3:IGameSprite = null) : EffectVO
      {
         var _loc7_:FighterMain = null;
         var _loc6_:EffectCacheVO = _defCache[param1];
         var _loc4_:Boolean = false;
         if(param3 && param3 is FighterMain)
         {
            _loc7_ = param3 as FighterMain;
            _loc4_ = _loc7_.isMosouEnemy();
         }
         if(_loc6_)
         {
            if(_loc4_ && _loc6_.mosouEnemy)
            {
               return _loc6_.mosouEnemy;
            }
            if(!_loc4_ && _loc6_.normal)
            {
               return _loc6_.normal;
            }
         }
         var _loc5_:EffectVO = _loc4_ ? EffectModel.I.getMosouEnemyDefenseEffect(param1.hitType,param2) : EffectModel.I.getDefenseEffect(param1.hitType,param2);
         if(_loc5_ == null)
         {
            _defCache[param1] = null;
            return null;
         }
         _loc5_ = _loc5_.clone();
         _loc6_ = new EffectCacheVO();
         if(_loc4_)
         {
            _loc6_.mosouEnemy = _loc5_;
         }
         else
         {
            _loc6_.normal = _loc5_;
         }
         _defCache[param1] = _loc6_;
         return _loc5_;
      }
      
      public function getEffectView(param1:EffectVO) : EffectView
      {
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         var _loc5_:* = null;
         var _loc3_:Vector.<EffectView> = _viewCache[param1];
         if(_loc3_)
         {
            _loc4_ = int(_loc3_.length);
            while(_loc2_ < _loc4_)
            {
               if(!_loc3_[_loc2_].isActive)
               {
                  return _loc3_[_loc2_];
               }
               _loc2_++;
            }
         }
         else
         {
            _loc3_ = new Vector.<EffectView>();
            _viewCache[param1] = _loc3_;
         }
         if(param1.isSpecial)
         {
            _loc5_ = new SpecialEffectView(param1);
         }
         else if(param1.isBuff)
         {
            _loc5_ = new BuffEffectView(param1);
         }
         else if(param1.isSteelHit)
         {
            _loc5_ = new SteelHitEffect(param1);
         }
         else
         {
            _loc5_ = new EffectView(param1);
         }
         _loc3_.push(_loc5_);
         return _loc5_;
      }
      
      public function getShine() : ShineEffectView
      {
         var _loc3_:int = 0;
         var _loc2_:int = int(_shineCache.length);
         while(_loc3_ < _loc2_)
         {
            if(!_shineCache[_loc3_].isActive)
            {
               return _shineCache[_loc3_];
            }
            _loc3_++;
         }
         var _loc1_:ShineEffectView = new ShineEffectView();
         _shineCache.push(_loc1_);
         return _loc1_;
      }
   }
}

