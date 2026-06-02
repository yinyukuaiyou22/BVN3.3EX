package net.play5d.game.bvn.data.mosou
{
   public class MosouWaveVO
   {
      
      public var id:int;
      
      public var enemies:Vector.<MosouEnemyVO>;
      
      public var repeats:Vector.<MosouWaveRepeatVO>;
      
      public var hold:int;
      
      public function MosouWaveVO()
      {
         super();
      }
      
      public static function createByJSON(param1:Object) : MosouWaveVO
      {
         var _loc2_:int = 0;
         var _loc3_:MosouWaveRepeatVO = null;
         var _loc6_:* = null;
         var _loc4_:int = 0;
         var _loc7_:MosouWaveVO = new MosouWaveVO();
         _loc7_.hold = int(param1.hold);
         var _loc5_:Array = param1.enemies;
         _loc2_ = 0;
         while(_loc2_ < _loc5_.length)
         {
            _loc7_.addEnemy(MosouEnemyVO.createByJSON(_loc5_[_loc2_]));
            _loc2_++;
         }
         if(param1.repeat)
         {
            _loc7_.repeats = new Vector.<MosouWaveRepeatVO>();
            _loc3_ = new MosouWaveRepeatVO();
            _loc3_.type = param1.repeat.type;
            _loc3_.hold = param1.repeat.hold;
            _loc6_ = param1.repeat.enemies;
            _loc4_ = 0;
            while(_loc4_ < _loc6_.length)
            {
               _loc3_.addEnemy(MosouEnemyVO.createByJSON(_loc6_[_loc4_]));
               _loc4_++;
            }
            _loc7_.repeats.push(_loc3_);
         }
         return _loc7_;
      }
      
      public function getAllEnemies() : Vector.<MosouEnemyVO>
      {
         if(!repeats)
         {
            return enemies;
         }
         var _loc2_:Vector.<MosouEnemyVO> = enemies.concat();
         for each(var _loc1_ in repeats)
         {
            if(_loc1_.enemies)
            {
               _loc2_ = _loc2_.concat(_loc1_.enemies);
            }
         }
         return _loc2_;
      }
      
      public function getAllEnemieIds() : Array
      {
         var _loc2_:Array = [];
         var _loc3_:Vector.<MosouEnemyVO> = getAllEnemies();
         for each(var _loc1_ in _loc3_)
         {
            if(_loc2_.indexOf(_loc1_.fighterID) == -1)
            {
               _loc2_.push(_loc1_.fighterID);
            }
         }
         return _loc2_;
      }
      
      public function getBosses() : Vector.<MosouEnemyVO>
      {
         var _loc2_:Vector.<MosouEnemyVO> = new Vector.<MosouEnemyVO>();
         var _loc3_:Vector.<MosouEnemyVO> = getAllEnemies();
         for each(var _loc1_ in _loc3_)
         {
            if(_loc1_.isBoss)
            {
               if(_loc2_.indexOf(_loc1_) == -1)
               {
                  _loc2_.push(_loc1_);
               }
            }
         }
         return _loc2_;
      }
      
      public function addEnemy(param1:Vector.<MosouEnemyVO>) : void
      {
         if(!enemies)
         {
            enemies = new Vector.<MosouEnemyVO>();
         }
         for each(var _loc2_ in param1)
         {
            _loc2_.wave = this;
            enemies.push(_loc2_);
         }
      }
      
      public function addRepeat(param1:MosouWaveRepeatVO) : void
      {
         if(!repeats)
         {
            repeats = new Vector.<MosouWaveRepeatVO>();
         }
         param1.wave = this;
         repeats.push(param1);
      }
      
      public function bossCount() : int
      {
         var _loc2_:int = 0;
         for each(var _loc1_ in enemies)
         {
            if(_loc1_.isBoss)
            {
               _loc2_++;
            }
         }
         return _loc2_;
      }
   }
}

