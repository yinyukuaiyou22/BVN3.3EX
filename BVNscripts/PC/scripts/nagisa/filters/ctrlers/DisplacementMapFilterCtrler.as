package nagisa.filters.ctrlers
{
   import flash.display.BitmapData;
   import flash.filters.BitmapFilter;
   import flash.filters.DisplacementMapFilter;
   import flash.geom.Point;
   import nagisa.filters.FilterManager;
   import nagisa.util.DisplayUtil;
   
   public class DisplacementMapFilterCtrler extends NBitmapFilterCtrler
   {
      
      public var filterManager:FilterManager;
      
      private var _mapFilter:DisplacementMapFilter;
      
      private var _bitmapData:BitmapData;
      
      private var _scaleX:Number = 32;
      
      private var _scaleY:Number = 32;
      
      private var _isHide:Boolean = false;
      
      public function DisplacementMapFilterCtrler(param1:FilterManager = null)
      {
         super();
         filterManager = param1;
         _mapFilter = new DisplacementMapFilter();
         _mapFilter.componentX = 2;
         _mapFilter.componentY = 4;
         _mapFilter.mode = "clamp";
      }
      
      public function get scaleY() : Number
      {
         return _scaleY;
      }
      
      public function set scaleY(param1:Number) : void
      {
         _scaleY = param1;
      }
      
      public function get scaleX() : Number
      {
         return _scaleX;
      }
      
      public function set scaleX(param1:Number) : void
      {
         _scaleX = param1;
      }
      
      override public function get filter() : BitmapFilter
      {
         return _mapFilter;
      }
      
      public function get mapFilter() : DisplacementMapFilter
      {
         return _mapFilter;
      }
      
      public function get bitmapData() : BitmapData
      {
         return _bitmapData;
      }
      
      public function set bitmapData(param1:BitmapData) : void
      {
         _bitmapData = param1;
      }
      
      public function get mapBitmap() : BitmapData
      {
         return _mapFilter.mapBitmap;
      }
      
      public function set mapBitmap(param1:BitmapData) : void
      {
         _mapFilter.mapBitmap = param1;
      }
      
      public function get position() : Point
      {
         return _mapFilter.mapPoint;
      }
      
      public function set position(param1:Point) : void
      {
         _mapFilter.mapPoint = param1;
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         _mapFilter = null;
      }
      
      override public function render() : void
      {
         super.render();
      }
      
      override public function renderAnimate() : void
      {
         super.renderAnimate();
      }
      
      public function hide() : void
      {
         _isHide = true;
         _mapFilter.mapBitmap = new BitmapData(1,1,false,8421504);
      }
      
      public function show() : void
      {
         _isHide = false;
      }
      
      override public function adapt(param1:Number, param2:Number) : void
      {
         super.adapt(param1,param2);
         _mapFilter.scaleX = _scaleX * param1;
         _mapFilter.scaleY = _scaleY * param2;
         if(_isHide)
         {
            return;
         }
         if(!_bitmapData)
         {
            return;
         }
         _mapFilter.mapBitmap = DisplayUtil.drawDisplay(_bitmapData,{
            "scale":new Point(param1,param2),
            "isAdaptScale":true
         }).bitmapData;
      }
   }
}

