package nagisa.filters
{
   import flash.display.DisplayObject;
   import flash.filters.BitmapFilter;
   import nagisa.filters.ctrlers.DisplacementMapFilterCtrler;
   import nagisa.filters.ctrlers.NBitmapFilterCtrler;
   
   public class FilterManager
   {
      
      public static const DISPLACEMENT_MAP_FILTER:String = "DisplacementMapFilter";
      
      public var display:DisplayObject;
      
      public var scaleX:Number = 1;
      
      public var scaleY:Number = 1;
      
      private var _filter:Array;
      
      private var _filterCtrlers:Vector.<NBitmapFilterCtrler>;
      
      public function FilterManager(param1:DisplayObject)
      {
         super();
         _filter = [];
         _filterCtrlers = new Vector.<NBitmapFilterCtrler>();
         display = param1;
      }
      
      public function get filters() : Array
      {
         return _filter;
      }
      
      public function destory() : void
      {
         _filter = null;
         if(_filterCtrlers && _filterCtrlers.length)
         {
            removeFilterCtrler();
            _filterCtrlers = null;
         }
      }
      
      public function render() : void
      {
         for each(var _loc1_ in _filterCtrlers)
         {
            _loc1_.render();
            if(_loc1_.isAdapt)
            {
               _loc1_.adapt(scaleX,scaleY);
            }
         }
         applyFilterToDisplay();
      }
      
      public function applyFilterToDisplay(param1:DisplayObject = null) : void
      {
         param1 ||= this.display;
         if(!param1)
         {
            return;
         }
         param1.filters = _filter;
      }
      
      public function addFilter(param1:BitmapFilter) : Boolean
      {
         if(_filter.indexOf(param1) != -1)
         {
            return false;
         }
         _filter.push(param1);
         return true;
      }
      
      public function hasFilter(param1:BitmapFilter) : Boolean
      {
         if(_filter.indexOf(param1) == -1)
         {
            return false;
         }
         return true;
      }
      
      public function removeFilter(param1:BitmapFilter = null) : Boolean
      {
         if(!param1)
         {
            _filter = [];
            return true;
         }
         var _loc2_:int = _filter.indexOf(param1);
         if(_loc2_ == -1)
         {
            return false;
         }
         _filter.splice(_loc2_,1);
         return true;
      }
      
      public function addFilterCtrler(param1:String) : NBitmapFilterCtrler
      {
         var _loc2_:NBitmapFilterCtrler = null;
         var _loc3_:String = param1;
         if("DisplacementMapFilter" === _loc3_)
         {
            _loc2_ = new DisplacementMapFilterCtrler(this);
         }
         _filterCtrlers.push(_loc2_);
         addFilter(_loc2_.filter);
         return _loc2_;
      }
      
      public function getFilterCtrlerByName(param1:String) : NBitmapFilterCtrler
      {
         for each(var _loc2_ in _filterCtrlers)
         {
            if(_loc2_.name == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      public function removeFilterCtrler(param1:NBitmapFilterCtrler = null) : Boolean
      {
         if(!param1)
         {
            for each(param1 in _filterCtrlers)
            {
               param1.destory(true);
            }
            _filterCtrlers = new Vector.<NBitmapFilterCtrler>();
            return true;
         }
         var _loc2_:int = _filterCtrlers.indexOf(param1);
         if(_loc2_ == -1)
         {
            return false;
         }
         _filterCtrlers.splice(_loc2_,1);
         removeFilter(param1.filter);
         param1.destory(true);
         return true;
      }
      
      public function removeFilterCtrlerByName(param1:String) : Boolean
      {
         return removeFilterCtrler(getFilterCtrlerByName(param1));
      }
   }
}

