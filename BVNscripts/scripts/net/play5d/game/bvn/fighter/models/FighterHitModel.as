package net.play5d.game.bvn.fighter.models
{
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class FighterHitModel
   {
      
      private var _hitObj:Object = {};
      
      private var _fighter:IGameSprite;
      
      public function FighterHitModel(param1:IGameSprite)
      {
         super();
         this._fighter = param1;
      }
      
      public function destory() : void
      {
         this._hitObj = null;
         this._fighter = null;
      }
      
      public function clear() : void
      {
         this._hitObj = {};
      }
      
      public function getHitVO(param1:String) : HitVO
      {
         return this._hitObj[param1];
      }
      
      public function getHitVOLike(param1:String) : Vector.<HitVO>
      {
         var _loc3_:* = undefined;
         var _loc2_:Vector.<HitVO> = new Vector.<HitVO>();
         for(_loc3_ in this._hitObj)
         {
            if(_loc3_.indexOf(param1) != -1)
            {
               _loc2_.push(this._hitObj[_loc3_]);
            }
         }
         return _loc2_;
      }
      
      public function getHitVOByDisplayName(param1:String) : HitVO
      {
         var _loc2_:HitVO = this.getHitVO(param1);
         if(Boolean(_loc2_))
         {
            return _loc2_;
         }
         if(param1.indexOf("atm") == -1)
         {
            return null;
         }
         var _loc3_:String = param1.replace("atm","");
         return this.getHitVO(_loc3_);
      }
      
      public function addHitVO(param1:String, param2:Object) : void
      {
         var _loc3_:HitVO = new HitVO(param2);
         _loc3_.owner = this._fighter;
         _loc3_.id = param1;
         this._hitObj[param1] = _loc3_;
      }
      
      public function setPowerRate(param1:Number) : void
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in this._hitObj)
         {
            _loc2_.powerRate = param1;
         }
      }
   }
}

