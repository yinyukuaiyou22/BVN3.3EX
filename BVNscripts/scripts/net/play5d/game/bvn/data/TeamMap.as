package net.play5d.game.bvn.data
{
   public class TeamMap
   {
      
      public var teams:Vector.<TeamVO> = new Vector.<TeamVO>();
      
      private var _teamObj:Object = {};
      
      public function TeamMap()
      {
         super();
      }
      
      public function clear() : void
      {
         this._teamObj = {};
      }
      
      public function getTeam(param1:int) : TeamVO
      {
         return this._teamObj[param1];
      }
      
      public function getOtherTeams(param1:int) : Vector.<TeamVO>
      {
         var _loc3_:* = undefined;
         var _loc2_:Vector.<TeamVO> = new Vector.<TeamVO>();
         for each(_loc3_ in this._teamObj)
         {
            if(_loc3_.id != param1)
            {
               _loc2_.push(_loc3_);
            }
         }
         return _loc2_;
      }
      
      public function add(param1:TeamVO) : void
      {
         this._teamObj[param1.id] = param1;
         this.refreshTeams();
      }
      
      public function remove(param1:TeamVO) : void
      {
         delete this._teamObj[param1.id];
         this.refreshTeams();
      }
      
      private function refreshTeams() : void
      {
         var _loc1_:* = undefined;
         this.teams = new Vector.<TeamVO>();
         for each(_loc1_ in this._teamObj)
         {
            if(Boolean(_loc1_))
            {
               this.teams.push(_loc1_);
            }
         }
      }
   }
}

