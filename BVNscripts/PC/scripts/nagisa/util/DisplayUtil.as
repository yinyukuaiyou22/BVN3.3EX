package nagisa.util
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.IBitmapDrawable;
   import flash.display.LoaderInfo;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.filters.BlurFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import nagisa.data.BitmapDataCacheVO;
   import nagisa.data.DrawMovieClipCacheVO;
   import nagisa.debug.OutputMessage;
   
   public class DisplayUtil
   {
      
      public function DisplayUtil()
      {
         super();
      }
      
      public static function funcAllChildren(param1:DisplayObjectContainer, param2:Function) : void
      {
         var _loc5_:DisplayObject = null;
         var _loc4_:int = 0;
         var _loc3_:int = param1.numChildren;
         while(_loc4_ < _loc3_)
         {
            _loc5_ = param1.getChildAt(_loc4_);
            if(_loc5_)
            {
               if(param2(_loc5_))
               {
                  break;
               }
               if(_loc5_ is DisplayObjectContainer)
               {
                  funcAllChildren(_loc5_ as DisplayObjectContainer,param2);
               }
            }
            _loc4_++;
         }
      }
      
      public static function isParent(param1:DisplayObject, param2:DisplayObjectContainer) : Boolean
      {
         while(param1.parent)
         {
            if(param1.parent == param2)
            {
               return true;
            }
            param1 = param1.parent;
         }
         return false;
      }
      
      public static function getBoundsOff(param1:DisplayObject) : Point
      {
         var _loc2_:Rectangle = param1.getBounds(param1);
         return new Point(_loc2_.x,_loc2_.y);
      }
      
      public static function setDisplayRotaByVelocity(param1:DisplayObject, param2:Number, param3:Number) : void
      {
         param1.rotation = getDisplayRotaByVelocity(param1,param2,param3);
      }
      
      public static function getDisplayRotaByVelocity(param1:DisplayObject, param2:Number, param3:Number) : Number
      {
         var _loc5_:Number = NaN;
         var _loc4_:Number = param1.scaleX * param1.scaleY;
         return MathUtil.getRotationByXY(param2 * _loc4_,param3 * _loc4_);
      }
      
      public static function getPointByRadians(param1:Point, param2:Number, param3:Number = 1) : Point
      {
         var _loc4_:Point = new Point();
         _loc4_.x = (param1.x * Math.cos(param2) - param1.y * Math.sin(param2)) * param3;
         _loc4_.y = (param1.x * Math.sin(param2) + param1.y * Math.cos(param2)) * param3;
         return _loc4_;
      }
      
      public static function setDisplayIndex(param1:DisplayObject, param2:*) : void
      {
         var _loc3_:int = 0;
         if(!param1.parent)
         {
            return;
         }
         if(param2 is Number)
         {
            try
            {
               param1.parent.setChildIndex(param1,param2);
            }
            catch(e:Error)
            {
               trace(e);
            }
         }
         else if(param2 is String)
         {
            switch(param2)
            {
               case "top":
                  _loc3_ = param1.parent.numChildren - 1;
                  param1.parent.setChildIndex(param1,_loc3_);
                  break;
               case "bottom":
                  _loc3_ = 0;
                  param1.parent.setChildIndex(param1,_loc3_);
                  break;
               default:
                  trace("EffectView.setIndex Error::" + param2 + " type out of range!");
            }
         }
         else if(param2 is DisplayObject)
         {
            if((param2 as DisplayObject).parent != param1.parent)
            {
               trace("EffectView.setIndex Error::the display: " + param2.name + " \'s parent not is effectView \'s parent ");
               return;
            }
            _loc3_ = param1.parent.getChildIndex(param2 as DisplayObject);
            if(--_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            param1.parent.setChildIndex(param1,_loc3_);
         }
      }
      
      public static function removeChild(param1:DisplayObject) : void
      {
         if(!param1)
         {
            return;
         }
         if(param1.parent)
         {
            try
            {
               param1.parent.removeChild(param1);
            }
            catch(e:Error)
            {
            }
         }
      }
      
      public static function isMouseOver(param1:DisplayObject) : Boolean
      {
         var _loc2_:Rectangle = param1.getBounds(param1);
         return param1.mouseX >= _loc2_.left && param1.mouseX <= _loc2_.right && param1.mouseY >= _loc2_.top && param1.mouseY <= _loc2_.bottom;
      }
      
      public static function setBitmapDataScale(param1:BitmapData, param2:Number) : BitmapDataCacheVO
      {
         var _loc3_:Bitmap = new Bitmap(param1);
         return drawDisplayQuality(_loc3_,param2);
      }
      
      public static function drawDisplayQuality(param1:DisplayObject, param2:Number = 0, param3:Object = null) : BitmapDataCacheVO
      {
         var _loc7_:* = null;
         var _loc4_:* = null;
         var _loc8_:* = null;
         var _loc6_:BitmapDataCacheVO = null;
         if(!param1)
         {
            return null;
         }
         if(param2 < 0)
         {
            param2 = 0;
         }
         var _loc5_:DisplayObject = param1;
         if(!param3)
         {
            param3 = {};
         }
         if(!param2)
         {
            param2 = 1;
         }
         param3.scale = new Point(param2,param2);
         param3.isAdaptScale = true;
         _loc6_ = drawDisplay(_loc5_,param3);
         _loc6_.quality = param2;
         return _loc6_;
      }
      
      public static function drawDisplay(param1:IBitmapDrawable, param2:Object = null) : BitmapDataCacheVO
      {
         var _loc15_:Rectangle = null;
         param2 ||= {};
         var _loc14_:BitmapData = null;
         var _loc5_:Point = new Point(0,0);
         var _loc12_:Point = null;
         var _loc17_:Rectangle = null;
         var _loc6_:Rectangle = null;
         var _loc10_:Matrix = new Matrix();
         var _loc7_:int = 0;
         var _loc11_:Number = 0;
         var _loc8_:Point = new Point(1,1);
         var _loc4_:ColorTransform = null;
         var _loc13_:String = null;
         var _loc16_:Boolean = false;
         var _loc3_:BitmapDataCacheVO = null;
         var _loc9_:Boolean = false;
         _loc15_ = param1 is DisplayObject ? (param1 as DisplayObject).getBounds(param1 as DisplayObject) : new Rectangle(0,0,(param1 as BitmapData).width,(param1 as BitmapData).height);
         _loc14_ = ObjectUtil.getObjValue(param2,"bitmapData",_loc14_);
         _loc8_ = ObjectUtil.getObjValue(param2,"scale",_loc8_);
         _loc8_.x = ObjectUtil.getObjValue(param2,"scaleX",_loc8_.x);
         _loc8_.y = ObjectUtil.getObjValue(param2,"scaleY",_loc8_.y);
         _loc17_ = ObjectUtil.getObjValue(param2,"clipRect",new Rectangle(0,0,_loc15_.width * _loc8_.x,_loc15_.height * _loc8_.y));
         _loc12_ = ObjectUtil.getObjValue(param2,"fixPosition",new Point(0,0));
         _loc7_ = ObjectUtil.getObjValue(param2,"rotation",_loc7_);
         _loc11_ = ObjectUtil.getObjValue(param2,"radian",MathUtil.asRadian(_loc7_));
         _loc4_ = ObjectUtil.getObjValue(param2,"colorTransform",_loc4_);
         _loc13_ = ObjectUtil.getObjValue(param2,"blendMode",_loc13_);
         _loc16_ = ObjectUtil.getObjValue(param2,"smoothing",_loc16_);
         _loc9_ = ObjectUtil.getObjValue(param2,"isAdaptScale",_loc9_);
         _loc3_ = new BitmapDataCacheVO();
         _loc3_.offsetX = _loc15_.x;
         _loc3_.offsetY = _loc15_.y;
         _loc5_.x = _loc15_.x + _loc17_.x;
         _loc5_.y = _loc15_.y + _loc17_.y;
         _loc12_.x += _loc15_.x;
         _loc12_.y += _loc15_.y;
         NagisaUtil.rect_identity(_loc17_,true);
         if(!_loc17_.width || !_loc17_.height)
         {
            return _loc3_;
         }
         _loc10_.translate(-_loc12_.x,-_loc12_.y);
         _loc10_.scale(_loc8_.x,_loc8_.y);
         _loc10_.rotate(_loc11_);
         _loc10_.translate(_loc12_.x,_loc12_.y);
         if(!_loc14_)
         {
            _loc10_.translate(-_loc5_.x,-_loc5_.y);
         }
         _loc6_ = new Rectangle();
         _loc6_.width = _loc17_.width;
         _loc6_.height = _loc17_.height;
         if(_loc9_)
         {
            _loc10_.translate(MathUtil.sgn(_loc8_.x) < 0 ? _loc6_.width : 0,MathUtil.sgn(_loc8_.y) < 0 ? _loc6_.height : 0);
         }
         _loc14_ ||= new BitmapData(_loc6_.width,_loc6_.height,true,0);
         _loc14_.draw(param1,_loc10_,_loc4_,_loc13_,_loc6_,_loc16_);
         _loc3_.bitmapData = _loc14_;
         return _loc3_;
      }
      
      public static function drawDisplayBitmap(param1:DisplayObject, param2:Number = 0, param3:Object = null) : Bitmap
      {
         var _loc5_:Bitmap = new Bitmap();
         var _loc4_:BitmapDataCacheVO = drawDisplayQuality(param1,param2,param3);
         _loc5_.bitmapData = _loc4_.bitmapData;
         _loc5_.x = _loc4_.offsetX;
         _loc5_.y = _loc4_.offsetY;
         _loc5_.scaleX = _loc5_.scaleY = 1 / param2;
         return _loc5_;
      }
      
      public static function drawMovieClip(param1:MovieClip, param2:Number = 0, param3:Object = null) : DrawMovieClipCacheVO
      {
         var new_cache:BitmapDataCacheVO;
         var frameLabel:String;
         var mc:MovieClip = param1;
         var quality:Number = param2;
         var params:Object = param3;
         var cache:BitmapDataCacheVO = null;
         var frame:int = 1;
         var drawMc:DrawMovieClipCacheVO = new DrawMovieClipCacheVO();
         var scriptCache:Object = {};
         var bitmapDataCache:Vector.<BitmapDataCacheVO> = new Vector.<BitmapDataCacheVO>();
         var frameLabelCache:Object = {};
         var mc_nextFrame:Function = function():void
         {
            if(!mc)
            {
               return;
            }
            if(mc.currentFrame == mc.totalFrames)
            {
               return;
            }
            if("frameScript" in mc && mc.frameScript != null)
            {
               scriptCache[mc.currentFrame] = mc.frameScript;
               mc.frameScript = null;
            }
            mc.nextFrame();
            funcAllChildren(mc,function(param1:DisplayObject):Boolean
            {
               var _loc2_:MovieClip = param1 as MovieClip;
               if(!_loc2_)
               {
                  return false;
               }
               try
               {
                  _loc2_.currentFrame == _loc2_.totalFrames ? _loc2_.gotoAndStop(1) : _loc2_.nextFrame();
               }
               catch(e:Error)
               {
                  OutputMessage.ERROR("DisplayUtil","DrawMovieCLip","mc_nextFrame.funcAllChildren child " + param1 + " nextFrame() has Error!",e);
               }
               return false;
            });
         };
         mc.gotoAndStop(1);
         frame = mc.currentFrame;
         while(frame <= mc.totalFrames)
         {
            frameLabel = mc.currentFrameLabel;
            if(frameLabel != null)
            {
               frameLabelCache[mc.currentFrame] = frameLabel;
            }
            try
            {
               if("render" in mc)
               {
                  mc.render();
               }
               if("renderAnimate" in mc)
               {
                  mc.renderAnimate();
               }
            }
            catch(e:Error)
            {
               OutputMessage.ERROR("DisplayUtil","MovieClipToBitmapDatas","mc.render or renderAnimate has error",e,false);
            }
            if(mc.width < 1 || mc.height < 1)
            {
               bitmapDataCache.push(null);
            }
            else
            {
               new_cache = DisplayUtil.drawDisplayQuality(mc,quality,params);
               if(!new_cache)
               {
                  bitmapDataCache.push(null);
               }
               else if(BitmapDataCacheVO.isEqual(cache,new_cache,false))
               {
                  if(BitmapDataCacheVO.isEqual(cache,new_cache,true))
                  {
                     bitmapDataCache.push(cache);
                  }
                  else
                  {
                     if(cache)
                     {
                        new_cache.bitmapData.dispose();
                        new_cache.bitmapData = cache.bitmapData;
                     }
                     bitmapDataCache.push(new_cache);
                  }
               }
               else
               {
                  bitmapDataCache.push(cache = new_cache);
               }
            }
            mc_nextFrame();
            frame = frame + 1;
         }
         drawMc.bitmapDataCache = bitmapDataCache;
         drawMc.frameLabelCache = frameLabelCache;
         drawMc.scriptCache = scriptCache;
         cache = new_cache = null;
         cache = null;
         bitmapDataCache = null;
         frameLabelCache = scriptCache = null;
         return drawMc;
      }
      
      public static function drawRadialBlur(param1:DisplayObject, param2:Point, param3:Point, param4:int) : BitmapDataCacheVO
      {
         var _loc8_:Rectangle = null;
         var _loc13_:BitmapData = null;
         var _loc9_:int = 0;
         var _loc17_:Rectangle = param1.getBounds(param1);
         var _loc14_:Number = _loc17_.right - param2.x;
         var _loc12_:Number = _loc17_.left - param2.x;
         var _loc15_:Number = _loc17_.top - param2.y;
         var _loc5_:Number = _loc17_.bottom - param2.y;
         var _loc11_:BitmapDataCacheVO;
         var _loc6_:BitmapDataCacheVO = _loc11_ = drawDisplay(param1,{
            "fixPosition":param2,
            "scale":param3
         });
         var _loc7_:Point = _loc6_.offset;
         var _loc18_:BitmapData = _loc6_.bitmapData;
         var _loc16_:Number = 1;
         var _loc10_:BlurFilter = new BlurFilter();
         _loc13_ = _loc11_.bitmapData.clone();
         _loc9_ = param4;
         while(_loc9_ > 0)
         {
            _loc16_ = _loc9_ / param4;
            _loc8_ = NagisaUtil.rect_createByPoint(param2,_loc12_ * _loc16_,_loc14_ * _loc16_,_loc15_ * _loc16_,_loc5_ * _loc16_);
            _loc6_ = drawDisplay(_loc13_.clone(),{
               "bitmapData":_loc13_,
               "fixPosition":param2,
               "scale":param3,
               "clipRect":_loc8_
            });
            _loc9_--;
         }
         _loc11_.bitmapData = _loc13_;
         return _loc6_;
      }
      
      public static function BitmapDataColorFilter(param1:BitmapData, param2:uint, param3:Boolean = false) : BitmapData
      {
         var _loc4_:* = 0;
         var _loc7_:* = 0;
         var _loc8_:BitmapData = new BitmapData(param1.width,param1.height,true,0);
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         while(_loc5_ < param1.width)
         {
            _loc6_ = 0;
            while(_loc6_ < param1.height)
            {
               _loc4_ = param1.getPixel32(_loc5_,_loc6_);
               _loc7_ = ColorUtil.filterRGB(_loc4_,param2);
               _loc8_.setPixel32(_loc5_,_loc6_,_loc7_);
               _loc6_++;
            }
            _loc5_++;
         }
         return _loc8_;
      }
      
      public static function BitmapDataGetPixels(param1:BitmapData, param2:Rectangle) : Vector.<Vector.<uint>>
      {
         var _loc4_:* = undefined;
         var _loc3_:* = undefined;
         param2 = param2.intersection(param1.rect);
         if(!param2 || param2.isEmpty())
         {
            return null;
         }
         _loc4_ = new Vector.<Vector.<uint>>();
         var _loc5_:int = param2.x;
         var _loc6_:int = param2.y;
         while(_loc5_ < param2.right)
         {
            _loc6_ = 0;
            _loc3_ = _loc4_[_loc4_.length] = new Vector.<uint>();
            while(_loc6_ < param2.bottom)
            {
               _loc3_[_loc4_.length] = param1.getPixel32(_loc5_,_loc6_);
               _loc6_++;
            }
            _loc5_++;
         }
         return _loc4_;
      }
      
      public static function MovieClipToSprite(param1:MovieClip, param2:Sprite = null) : Sprite
      {
         var _loc3_:DisplayObject = null;
         param2 ||= new Sprite();
         while(param1.numChildren)
         {
            _loc3_ = param1.getChildAt(0);
            param2.addChild(_loc3_);
         }
         return param2;
      }
      
      public static function transformPosition(param1:DisplayObject, param2:DisplayObject, param3:Point = null) : Point
      {
         param3 ||= new Point(0,0);
         return param2.globalToLocal(param1.localToGlobal(param3));
      }
      
      public static function getClass(param1:DisplayObject, param2:String) : Class
      {
         var _loc4_:LoaderInfo = param1.loaderInfo;
         if(!_loc4_)
         {
            return null;
         }
         var _loc3_:ApplicationDomain = _loc4_.applicationDomain;
         if(_loc3_ == null)
         {
            return null;
         }
         if(!_loc3_.hasDefinition(param2))
         {
            return null;
         }
         return _loc3_.getDefinition(param2) as Class;
      }
   }
}

