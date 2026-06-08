package net.play5d.game.bvn.utils
{
   import flash.utils.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.views.effects.*;
   
   public class EffectManager
   {
      
      private var _viewCache:Dictionary = new Dictionary();
      
      private var _hitCache:Dictionary = new Dictionary();
      
      private var _shineCache:Vector.<ShineEffectView> = new Vector.<ShineEffectView>();
      
      public function EffectManager()
      {
         super();
      }
      
      public function destory() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:* = undefined;
         var _loc3_:* = undefined;
         for each(_loc1_ in this._viewCache)
         {
            for each(_loc3_ in _loc1_)
            {
               _loc3_.destory();
            }
         }
         for each(_loc2_ in this._shineCache)
         {
            _loc2_.destory();
         }
         this._viewCache = null;
         this._hitCache = null;
         this._shineCache = null;
      }
      
      public function getEffectVOByHitVO(param1:HitVO) : EffectVO
      {
         if(this._hitCache[param1] != undefined)
         {
            return this._hitCache[param1];
         }
         var _loc2_:EffectVO = EffectModel.I.getHitEffect(param1.hitType);
         if(!_loc2_)
         {
            this._hitCache[param1] = null;
            return null;
         }
         _loc2_ = _loc2_.clone();
         if(Boolean(_loc2_.shake))
         {
            if(_loc2_.shake.pow != undefined && _loc2_.shake.pow != 0)
            {
               _loc2_.shake.y = _loc2_.shake.pow;
            }
            if(_loc2_.shake.x == 0 && _loc2_.shake.y == 0)
            {
               _loc2_.shake.x = 3;
            }
         }
         this._hitCache[param1] = _loc2_;
         return _loc2_;
      }
      
      public function getEffectView(param1:EffectVO) : EffectView
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:EffectView = null;
         var _loc5_:Vector.<EffectView> = this._viewCache[param1];
         if(Boolean(_loc5_))
         {
            _loc2_ = int(_loc5_.length);
            while(_loc3_ < _loc2_)
            {
               if(!_loc5_[_loc3_].isActive)
               {
                  return _loc5_[_loc3_];
               }
               _loc3_++;
            }
         }
         else
         {
            _loc5_ = new Vector.<EffectView>();
            this._viewCache[param1] = _loc5_;
         }
         if(param1.isSpecial)
         {
            _loc4_ = new SpecialEffectView(param1);
         }
         else if(param1.isBuff)
         {
            _loc4_ = new BuffEffectView(param1);
         }
         else if(param1.isSteelHit)
         {
            _loc4_ = new SteelHitEffect(param1);
         }
         else
         {
            _loc4_ = new EffectView(param1);
         }
         _loc5_.push(_loc4_);
         return _loc4_;
      }
      
      public function getShine() : ShineEffectView
      {
         var _loc1_:int = 0;
         var _loc2_:int = int(this._shineCache.length);
         while(_loc1_ < _loc2_)
         {
            if(!this._shineCache[_loc1_].isActive)
            {
               return this._shineCache[_loc1_];
            }
            _loc1_++;
         }
         var _loc3_:ShineEffectView = new ShineEffectView();
         this._shineCache.push(_loc3_);
         return _loc3_;
      }
   }
}

