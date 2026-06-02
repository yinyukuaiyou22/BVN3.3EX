package nagisa.filters.ctrlers
{
   import flash.events.Event;
   import nagisa.filters.FilterManager;
   import nagisa.filters.Melt;
   import nagisa.filters.melt.MeltMovieClip;
   import nagisa.interfaces.Instance;
   import nagisa.util.ArrayUtil;
   
   public class MeltCtrler extends Instance
   {
      
      private var _manager:FilterManager;
      
      private var _melts:Vector.<Melt>;
      
      public var transfromPosition:Function;
      
      public function MeltCtrler()
      {
         super();
      }
      
      public function initialize(param1:FilterManager, param2:Function = null) : void
      {
         _melts = new Vector.<Melt>();
         _manager = param1;
         this.transfromPosition = param2;
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         if(_melts)
         {
            removeMelt();
            _melts = null;
         }
         super.destory(param1);
      }
      
      override public function render() : void
      {
         super.render();
         for each(var _loc1_ in _melts)
         {
            if(!_loc1_.isDestoryed())
            {
               _loc1_.render();
            }
         }
      }
      
      override public function renderAnimate() : void
      {
         super.renderAnimate();
         for each(var _loc1_ in _melts)
         {
            if(!_loc1_.isDestoryed())
            {
               _loc1_.renderAnimate();
            }
         }
      }
      
      public function addMelt(param1:String, param2:*, param3:Object = null) : Melt
      {
         if(!param3)
         {
            param3 = {};
         }
         var _loc4_:Melt = new Melt(param1);
         _loc4_.initialize(_manager,param2,param3);
         _loc4_.transformPosition = transfromPosition;
         _loc4_.movieClip.listen("play_end",_onMovieClipPlayEnd);
         ArrayUtil.addItem(_melts,_loc4_);
         _loc4_.start();
         return _loc4_;
      }
      
      public function removeMelt(param1:Melt = null) : void
      {
         ArrayUtil.removeItem(_melts,param1,true,true);
      }
      
      public function getMelt(param1:String) : Melt
      {
         return ArrayUtil.getItemBy(_melts,"name",param1);
      }
      
      private function _onMovieClipPlayEnd(param1:Event) : void
      {
         var _loc3_:Melt = null;
         var _loc2_:MeltMovieClip = param1.target as MeltMovieClip;
         _loc2_.unlisten(param1.type,_onMovieClipPlayEnd);
         _loc3_ = ArrayUtil.getItemBy(_melts,"movieClip",_loc2_);
         _loc2_.stop();
         removeMelt(_loc3_);
      }
   }
}

