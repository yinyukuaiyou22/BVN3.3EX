package net.play5d.game.bvn.data.mosou
{
   public class MosouMissionVO
   {
      
      public var id:String;
      
      public var name:String;
      
      public var map:String;
      
      public var time:int;
      
      public var enemyLevel:int;
      
      public var waves:Vector.<MosouWaveVO>;
      
      public var area:MosouWorldMapAreaVO;
      
      public function MosouMissionVO()
      {
         super();
      }
      
      public function initByJsonObject(param1:Object) : void
      {
         var _loc3_:int = 0;
         var _loc4_:MosouWaveVO = null;
         id = param1.id;
         map = param1.map;
         time = int(param1.time);
         enemyLevel = int(param1.enemyLevel);
         if(enemyLevel < 1)
         {
            enemyLevel = 1;
         }
         if(!map || time < 1)
         {
            throw new Error("init mousou stage error!");
         }
         var _loc2_:Array = param1.waves;
         waves = new Vector.<MosouWaveVO>();
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = MosouWaveVO.createByJSON(_loc2_[_loc3_]);
            addWave(_loc4_);
            _loc3_++;
         }
      }
      
      public function getAllEnemies() : Vector.<MosouEnemyVO>
      {
         var _loc3_:int = 0;
         var _loc1_:MosouWaveVO = null;
         var _loc2_:* = undefined;
         var _loc4_:Vector.<MosouEnemyVO> = new Vector.<MosouEnemyVO>();
         while(_loc3_ < waves.length)
         {
            _loc1_ = waves[_loc3_];
            _loc2_ = _loc1_.getAllEnemies();
            if(_loc2_)
            {
               _loc4_ = _loc4_.concat(_loc2_);
            }
            _loc3_++;
         }
         return _loc4_;
      }
      
      public function getAllEnemieIds() : Array
      {
         var _loc4_:* = undefined;
         var _loc1_:int = 0;
         var _loc3_:MosouWaveVO = null;
         var _loc2_:Array = [];
         while(_loc1_ < waves.length)
         {
            _loc3_ = waves[_loc1_];
            _loc4_ = _loc3_.getAllEnemieIds();
            if(_loc4_)
            {
               for each(var _loc5_ in _loc4_)
               {
                  if(_loc2_.indexOf(_loc5_) == -1)
                  {
                     _loc2_.push(_loc5_);
                  }
               }
            }
            _loc1_++;
         }
         return _loc2_;
      }
      
      public function getBossIds() : Array
      {
         var _loc1_:Vector.<MosouEnemyVO> = getBosses();
         var _loc2_:Array = [];
         for each(var _loc3_ in _loc1_)
         {
            if(_loc2_.indexOf(_loc3_.fighterID) == -1)
            {
               _loc2_.push(_loc3_.fighterID);
            }
         }
         return _loc2_;
      }
      
      public function getBosses() : Vector.<MosouEnemyVO>
      {
         var _loc3_:MosouWaveVO = null;
         var _loc4_:* = undefined;
         var _loc1_:int = 0;
         var _loc2_:Vector.<MosouEnemyVO> = new Vector.<MosouEnemyVO>();
         while(_loc1_ < waves.length)
         {
            _loc3_ = waves[_loc1_];
            _loc4_ = _loc3_.getBosses();
            if(_loc4_)
            {
               for each(var _loc5_ in _loc4_)
               {
                  if(_loc2_.indexOf(_loc5_) == -1)
                  {
                     _loc2_.push(_loc5_);
                  }
               }
            }
            _loc1_++;
         }
         return _loc2_;
      }
      
      public function addWave(param1:MosouWaveVO) : void
      {
         if(!waves)
         {
            waves = new Vector.<MosouWaveVO>();
         }
         param1.id = waves.length + 1;
         waves.push(param1);
      }
      
      public function bossCount() : int
      {
         var _loc1_:int = 0;
         var _loc3_:int = 0;
         var _loc2_:MosouWaveVO = null;
         while(_loc3_ < waves.length)
         {
            _loc2_ = waves[_loc3_];
            _loc1_ += _loc2_.bossCount();
            _loc3_++;
         }
         return _loc1_;
      }
   }
}

