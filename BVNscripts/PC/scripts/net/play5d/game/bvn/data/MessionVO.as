package net.play5d.game.bvn.data
{
   public class MessionVO
   {
      
      public var comicType:int;
      
      public var gameMode:int;
      
      public var stageList:Vector.<MessionStageVO>;
      
      public function MessionVO()
      {
         super();
      }
      
      public function initByXML(param1:XML) : void
      {
         var _loc2_:int = 0;
         var _loc5_:MessionStageVO = null;
         var _loc4_:XML = null;
         var _loc3_:XMLList = null;
         comicType = param1.@comicType;
         gameMode = param1.@gameMode;
         stageList = new Vector.<MessionStageVO>();
         while(_loc2_ < param1.stage.length())
         {
            _loc5_ = new MessionStageVO();
            _loc4_ = param1.stage[_loc2_];
            _loc3_ = _loc4_.@fighter;
            _loc5_.mession = this;
            _loc5_.assister = _loc4_.@assister;
            _loc5_.fighters = _loc3_.split(",");
            _loc5_.map = _loc4_.@map;
            _loc5_.hpRate = Number(_loc4_.@hpRate) > 0 ? Number(_loc4_.@hpRate) : 1;
            _loc5_.attackRate = Number(_loc4_.@attackRate) > 0 ? Number(_loc4_.@attackRate) : 1;
            stageList.push(_loc5_);
            _loc2_++;
         }
      }
   }
}

