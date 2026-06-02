package net.play5d.game.bvn.data.mosou
{
   import net.play5d.game.bvn.data.FighterModel;
   import net.play5d.game.bvn.data.FighterVO;
   
   public class MosouFighterModel
   {
      
      private static var _i:MosouFighterModel;
      
      public var fighters:Vector.<MosouFighterSellVO>;
      
      private var _inited:Boolean = false;
      
      public function MosouFighterModel()
      {
         super();
      }
      
      public static function get I() : MosouFighterModel
      {
         if(!_i)
         {
            _i = new MosouFighterModel();
         }
         return _i;
      }
      
      public function init() : void
      {
         if(!_inited)
         {
            initFighters();
            _inited = true;
         }
      }
      
      public function allCustom() : void
      {
         fighters = new Vector.<MosouFighterSellVO>();
         _inited = true;
      }
      
      private function initFighters() : void
      {
         var _loc3_:Array = null;
         var _loc9_:String = null;
         var _loc4_:int = 0;
         var _loc8_:* = 0;
         var _loc6_:MosouFighterSellVO = null;
         var _loc7_:Object = FighterModel.I.getAllFighters();
         var _loc2_:Array = [];
         for each(var _loc1_ in _loc7_)
         {
            _loc9_ = _loc1_.id;
            _loc4_ = _loc1_.money;
            if(!(_loc1_.isZako || _loc9_.indexOf("random") != -1 || _loc1_.isActivities))
            {
               _loc3_ = [_loc9_,_loc4_];
               _loc2_.push(_loc3_);
            }
         }
         _loc2_.sort();
         var _loc5_:uint = _loc2_.length;
         fighters = new Vector.<MosouFighterSellVO>();
         _loc8_ = 0;
         while(_loc8_ < _loc5_)
         {
            _loc3_ = _loc2_[_loc8_] as Array;
            _loc6_ = new MosouFighterSellVO(_loc3_[0],_loc3_[1]);
            fighters.push(_loc6_);
            _loc8_++;
         }
      }
      
      public function addFighter(param1:String, param2:int) : void
      {
         if(containsFighter(param1))
         {
            return;
         }
         fighters.push(new MosouFighterSellVO(param1,param2));
      }
      
      private function containsFighter(param1:String) : Boolean
      {
         for each(var _loc2_ in fighters)
         {
            if(_loc2_.id == param1)
            {
               return true;
            }
         }
         return false;
      }
   }
}

