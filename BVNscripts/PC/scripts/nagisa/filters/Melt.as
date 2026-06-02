package nagisa.filters
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import nagisa.data.DrawMovieClipCacheVO;
   import nagisa.debug.OutputMessage;
   import nagisa.filters.ctrlers.DisplacementMapFilterCtrler;
   import nagisa.filters.melt.MeltMovieClip;
   import nagisa.interfaces.Instance;
   import nagisa.util.ClassUtil;
   import nagisa.util.DisplayUtil;
   import nagisa.util.ObjectUtil;
   
   public class Melt extends Instance
   {
      
      public var name:String = null;
      
      public var autoApplySet:Boolean = true;
      
      public var transformPosition:Function;
      
      private var _movieClip:MeltMovieClip;
      
      private var _filterCtrler:DisplacementMapFilterCtrler;
      
      private var _manager:FilterManager;
      
      private var _drawMc:DrawMovieClipCacheVO;
      
      private var _x:Number = 0;
      
      private var _y:Number = 0;
      
      private var _offsetX:Number = 0;
      
      private var _offsetY:Number = 0;
      
      public function Melt(param1:String)
      {
         super();
         this.name = param1;
      }
      
      public function get x() : Number
      {
         return _x;
      }
      
      public function set x(param1:Number) : void
      {
         _x = param1;
      }
      
      public function get y() : Number
      {
         return _y;
      }
      
      public function set y(param1:Number) : void
      {
         _y = param1;
      }
      
      public function get offsetX() : Number
      {
         return _offsetX;
      }
      
      public function set offsetX(param1:Number) : void
      {
         _offsetX = param1;
      }
      
      public function get offsetY() : Number
      {
         return _offsetY;
      }
      
      public function set offsetY(param1:Number) : void
      {
         _offsetY = param1;
      }
      
      public function get movieClip() : MeltMovieClip
      {
         return _movieClip;
      }
      
      public function get filterCtrler() : DisplacementMapFilterCtrler
      {
         return _filterCtrler;
      }
      
      public function initialize(param1:FilterManager, param2:*, param3:Object = null) : void
      {
         if(!param3)
         {
            param3 = {};
         }
         _manager = param1;
         switch(ClassUtil.checkTargetType(param2,MovieClip,DrawMovieClipCacheVO))
         {
            case 0:
               _drawMc = DisplayUtil.drawMovieClip(param2 as MovieClip,0,null);
               break;
            case 1:
               _drawMc = (param2 as DrawMovieClipCacheVO).clone();
               break;
            default:
               OutputMessage.ERROR("Melt","initialize","无法识别数据：" + param2 + " !");
         }
         _movieClip = new MeltMovieClip();
         _movieClip.initialize(_drawMc.bitmapDataCache,_drawMc.frameLabelCache);
         _movieClip.initScript(_drawMc.scriptCache);
         _filterCtrler = _manager.addFilterCtrler("DisplacementMapFilter") as DisplacementMapFilterCtrler;
         _filterCtrler.scaleX = ObjectUtil.getObjValue(param3,"scaleX",_filterCtrler.scaleX);
         _filterCtrler.scaleY = ObjectUtil.getObjValue(param3,"scaleY",_filterCtrler.scaleY);
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         if(_movieClip)
         {
            _movieClip.destory(param1);
            _movieClip = null;
         }
         if(_filterCtrler)
         {
            _manager.removeFilterCtrler(_filterCtrler);
            _filterCtrler = null;
         }
         if(_drawMc)
         {
            _drawMc.destory();
            _drawMc = null;
         }
         transformPosition = null;
         _manager = null;
         super.destory(param1);
      }
      
      override public function render() : void
      {
         super.render();
         if(autoApplySet)
         {
            applySet();
         }
      }
      
      private function _renderDisplay() : void
      {
      }
      
      override public function renderAnimate() : void
      {
         super.renderAnimate();
         _renderMovieClip();
      }
      
      private function _renderMovieClip() : void
      {
         if(!_movieClip)
         {
            return;
         }
         _movieClip.render();
         _movieClip.renderAnimate();
         if(_destoryed)
         {
            return;
         }
      }
      
      public function applySet() : void
      {
         var _loc2_:Number = _x + _offsetX;
         var _loc3_:Number = _y + _offsetY;
         var _loc1_:Point = null;
         _loc2_ += _movieClip.offsetX;
         _loc3_ += _movieClip.offsetY;
         _loc1_ = transformPosition != null ? transformPosition(_loc2_,_loc3_) : new Point(_loc2_,_loc3_);
         _filterCtrler.position = _loc1_;
         _filterCtrler.bitmapData = _movieClip.bitmapData;
      }
      
      public function start() : void
      {
         _movieClip.start();
      }
   }
}

