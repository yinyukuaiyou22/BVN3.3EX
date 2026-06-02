package net.play5d.game.bvn.map
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.filters.BlurFilter;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class MapLayer extends Sprite
   {
      
      public var enabled:Boolean = false;
      
      private var _view:DisplayObject;
      
      private var _blurBitmaps:Object = {};
      
      private var _smoothing:Boolean;
      
      private var _currentShow:DisplayObject;
      
      public function MapLayer(param1:DisplayObject)
      {
         super();
         if(param1 == null)
         {
            return;
         }
         enabled = true;
         initView(param1);
      }
      
      private static function checkHitGameSprite(param1:Rectangle, param2:Vector.<IGameSprite>) : Boolean
      {
         var _loc3_:Rectangle = null;
         for each(var _loc4_ in param2)
         {
            if(_loc4_ != null)
            {
               _loc3_ = _loc4_.getArea();
               if(_loc3_ != null)
               {
                  if(param1.intersects(_loc3_))
                  {
                     return true;
                  }
               }
            }
         }
         return false;
      }
      
      private function initView(param1:DisplayObject) : void
      {
         _view = param1;
         show(_view);
         this.x = param1.x;
         this.y = param1.y;
         param1.y = 0;
         param1.x = 0;
      }
      
      private function getBlurBitmap(param1:int = 5, param2:int = 0) : Bitmap
      {
         var _loc4_:String = param1 + "|" + param2;
         if(_blurBitmaps[_loc4_])
         {
            return _blurBitmaps[_loc4_];
         }
         var _loc5_:Bitmap = drawBitmap(true,0);
         var _loc3_:BlurFilter = new BlurFilter(param1,param2,1);
         _loc5_.bitmapData.applyFilter(_loc5_.bitmapData,_loc5_.bitmapData.rect,new Point(),_loc3_);
         _blurBitmaps[_loc4_] = _loc5_;
         return _loc5_;
      }
      
      public function normalize() : void
      {
         var _loc6_:Sprite = null;
         var _loc3_:int = 0;
         var _loc5_:int = 0;
         var _loc2_:DisplayObject = null;
         var _loc1_:MovieClip = null;
         var _loc4_:MovieClip = null;
         if(!_view)
         {
            return;
         }
         if(_view is Bitmap)
         {
            (_view as Bitmap).smoothing = GameData.I.config.quality == "best";
         }
         if(_view is Sprite)
         {
            _loc6_ = _view as Sprite;
            _loc3_ = _loc6_.numChildren;
            _loc5_ = 0;
            while(_loc5_ < _loc3_)
            {
               _loc2_ = _loc6_.getChildAt(_loc5_);
               if(_loc2_ is Bitmap)
               {
                  (_loc2_ as Bitmap).smoothing = GameData.I.config.quality == "best";
               }
               _loc5_++;
            }
            _loc1_ = _loc6_.getChildByName("logo4399") as MovieClip;
            _loc4_ = _loc6_.getChildByName("logo_mine") as MovieClip;
            if(_loc1_ != null)
            {
               _loc6_.removeChild(_loc1_);
            }
            if(_loc4_ != null)
            {
               _loc6_.removeChild(_loc4_);
            }
         }
      }
      
      public function renderOptical(param1:Vector.<IGameSprite>) : void
      {
         var _loc5_:int = 0;
         var _loc4_:DisplayObject = null;
         var _loc2_:Rectangle = null;
         if(_view == null)
         {
            return;
         }
         if(_smoothing)
         {
            return;
         }
         var _loc6_:Sprite = _view as Sprite;
         if(_loc6_ == null)
         {
            return;
         }
         var _loc3_:int = _loc6_.numChildren;
         if(_loc3_ < 1)
         {
            return;
         }
         _loc5_ = 0;
         while(_loc5_ < _loc3_)
         {
            _loc4_ = _loc6_.getChildAt(_loc5_);
            if(_loc4_ is MovieClip)
            {
               _loc2_ = _loc4_.getBounds(_loc6_);
               _loc2_.x += _loc6_.x + this.x;
               _loc2_.y += _loc6_.y + this.y;
               _loc4_.alpha = checkHitGameSprite(_loc2_,param1) ? 0.5 : 1;
            }
            _loc5_++;
         }
      }
      
      private function show(param1:DisplayObject) : void
      {
         if(_currentShow == param1)
         {
            return;
         }
         if(_currentShow != null)
         {
            try
            {
               removeChild(_currentShow);
            }
            catch(e:Error)
            {
            }
         }
         addChild(param1);
         _currentShow = param1;
      }
      
      private function drawBitmap(param1:Boolean = true, param2:uint = 0) : Bitmap
      {
         if(_view == null)
         {
            return null;
         }
         var _loc4_:BitmapData = new BitmapData(_view.width * 0.5,_view.height * 0.5,param1,param2);
         var _loc6_:Bitmap = new Bitmap(_loc4_);
         var _loc3_:Rectangle = _view.getBounds(_view);
         var _loc5_:Matrix = new Matrix(1,0,0,1,-_loc3_.x,-_loc3_.y);
         _loc5_.scale(0.5,0.5);
         _loc6_.bitmapData.draw(_view,_loc5_);
         _loc6_.x = _loc3_.x;
         _loc6_.y = _loc3_.y;
         _loc6_.scaleX = 2;
         _loc6_.scaleY = 2;
         return _loc6_;
      }
      
      public function destory() : void
      {
         if(_view != null && _view is Bitmap)
         {
            (_view as Bitmap).bitmapData.dispose();
            _view = null;
         }
         if(_currentShow != null)
         {
            _currentShow = null;
         }
         if(_blurBitmaps != null)
         {
            _blurBitmaps = null;
         }
      }
      
      public function setSmoothing(param1:Number = 0, param2:Number = 0) : void
      {
         var _loc3_:Bitmap = null;
         if(_view == null)
         {
            return;
         }
         try
         {
            if(param1 <= 0 && param2 <= 0)
            {
               show(_view);
               return;
            }
            if(GameCtrl.I.gameState.getMap().data.id == "fuinzo" && _view.name == "front_fix")
            {
               show(_view);
               return;
            }
            _loc3_ = getBlurBitmap(param1,param2);
            show(_loc3_);
         }
         catch(e:Error)
         {
         }
      }
   }
}

