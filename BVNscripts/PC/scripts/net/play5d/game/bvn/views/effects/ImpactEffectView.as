package net.play5d.game.bvn.views.effects
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObjectContainer;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.filters.BlurFilter;
   import flash.filters.ColorMatrixFilter;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.setTimeout;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   
   public class ImpactEffectView extends Sprite
   {
      
      private static const MATRIX_GRAY:Array = [0.3,0.59,0.11,0,0,0.3,0.59,0.11,0,0,0.3,0.59,0.11,0,0,0,0,0,1,0];
      
      public var holdFrames:int = 4;
      
      public var lineBase:int = 96;
      
      public var lineRand:int = 15;
      
      public var angleJitter:Number = 8;
      
      public var lineWidthMin:Number = 0.3;
      
      public var lineWidthMax:Number = 3;
      
      public var fadeStart:Number = 0;
      
      public var radialSteps:int = 20;
      
      public var maxBlur:Number = 25;
      
      public var blurXYRatio:Number = 0.15;
      
      public var glitchH:Number = 10;
      
      public var glitchSkip:int = 4;
      
      public var binarizeThreshold:int = 120;
      
      public var binarizeContrast:int = 90;
      
      private var _binaryFilters:Array;
      
      private var _target:DisplayObjectContainer;
      
      private var _frame:int = 0;
      
      private var _W:int;
      
      private var _H:int;
      
      private var _cx:Number;
      
      private var _cy:Number;
      
      private var _diag:Number;
      
      private var _captureBmpData:BitmapData;
      
      private var _captureBmp:Bitmap;
      
      private var _lineSprite:Sprite;
      
      private var _mainContainer:Sprite;
      
      private var _blurFilter:BlurFilter = new BlurFilter(0,0,1);
      
      private var _emptyFilters:Array = [];
      
      private var _origParent:DisplayObjectContainer;
      
      private var _origIndex:int;
      
      private var _isInit:Boolean = false;
      
      private var _isDispose:Boolean = false;
      
      private var _isRunning:Boolean = false;
      
      private var _matrix:Matrix = new Matrix();
      
      private var _glitchYList:Vector.<int> = new Vector.<int>();
      
      private var _glitchXList:Vector.<int> = new Vector.<int>();
      
      private var _tempRect:Rectangle = new Rectangle();
      
      private var _tempPoint:Point = new Point(0,0);
      
      private var _preRenderBmpData:BitmapData;
      
      public function ImpactEffectView()
      {
         super();
         mouseEnabled = false;
         mouseChildren = false;
         visible = false;
         _mainContainer = new Sprite();
         _mainContainer.mouseEnabled = false;
         addChild(_mainContainer);
      }
      
      private function getBinarizeMatrix() : Array
      {
         var _loc2_:int = Math.max(0,Math.min(255,binarizeThreshold));
         var _loc3_:int = Math.max(1,Math.min(100,binarizeContrast));
         var _loc1_:Number = -(_loc2_ * _loc3_ - 1);
         return [_loc3_,0,0,0,_loc1_,0,_loc3_,0,0,_loc1_,0,0,_loc3_,0,_loc1_,0,0,0,1,0];
      }
      
      private function getForceThresholdMatrix() : Array
      {
         return [2,0,0,0,-128,0,2,0,0,-128,0,0,2,0,-128,0,0,0,1,0];
      }
      
      public function init() : void
      {
         var _loc2_:Graphics = null;
         var _loc18_:int = 0;
         var _loc17_:Number = NaN;
         var _loc14_:Number = NaN;
         var _loc19_:Number = NaN;
         var _loc20_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc1_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc15_:Number = NaN;
         var _loc12_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc3_:int = 0;
         var _loc6_:int = 0;
         var _loc8_:Number = NaN;
         var _loc9_:int = 0;
         var _loc16_:int = 0;
         var _loc5_:ColorMatrixFilter = null;
         var _loc7_:ColorMatrixFilter = null;
         var _loc4_:ColorMatrixFilter = null;
         if(_isInit || _isDispose)
         {
            return;
         }
         try
         {
            _target = GameCtrl.I.gameState as DisplayObjectContainer;
            if(!_target || _target.width <= 0 || _target.height <= 0)
            {
               Trace("ImpactEffectView: 目标容器无效");
               safeDispose();
               return;
            }
            _W = _target.width;
            _H = _target.height;
            _cx = _W * 0.5;
            _cy = _H * 0.5;
            _diag = Math.sqrt(_W * _W + _H * _H);
            _lineSprite = new Sprite();
            _loc2_ = _lineSprite.graphics;
            _loc2_.clear();
            _loc18_ = lineBase + (int(Math.random() * lineRand * 2 - lineRand));
            _loc3_ = 0;
            while(_loc3_ < _loc18_)
            {
               _loc14_ = _loc3_ / _loc18_ * 3.141592653589793 * 2 + angleJitter * 3.141592653589793 / 180 * (Math.random() * 2 - 1);
               _loc6_ = radialSteps;
               _loc8_ = _diag / _loc6_;
               _loc9_ = 0;
               while(_loc9_ < _loc6_)
               {
                  _loc19_ = _loc9_ * _loc8_;
                  _loc20_ = (_loc9_ + 1) * _loc8_;
                  _loc10_ = _loc19_ / _diag;
                  _loc1_ = (_loc10_ - fadeStart) / (1 - fadeStart);
                  _loc1_ = Math.max(0,Math.min(1,_loc1_));
                  _loc17_ = lineWidthMin + (lineWidthMax - lineWidthMin) * _loc10_;
                  if(_loc17_ >= 0.2)
                  {
                     _loc2_.lineStyle(_loc17_,16777215,_loc1_);
                     _loc13_ = _cx + Math.cos(_loc14_) * _loc19_;
                     _loc11_ = _cy + Math.sin(_loc14_) * _loc19_;
                     _loc15_ = _cx + Math.cos(_loc14_) * _loc20_;
                     _loc12_ = _cy + Math.sin(_loc14_) * _loc20_;
                     _loc2_.moveTo(_loc13_,_loc11_);
                     _loc2_.lineTo(_loc15_,_loc12_);
                  }
                  _loc9_++;
               }
               _loc3_++;
            }
            _glitchYList.length = 0;
            _glitchXList.length = 0;
            _loc16_ = 0;
            while(_loc16_ < _H)
            {
               _glitchYList.push(_loc16_);
               _glitchXList.push(int(Math.random() * glitchH * 2 - glitchH));
               _loc16_ += glitchSkip;
            }
            _preRenderBmpData = new BitmapData(_W,_H,true,0);
            _preRenderBmpData.draw(_target);
            _captureBmpData = new BitmapData(_W,_H,true,0);
            _captureBmpData.copyPixels(_preRenderBmpData,new Rectangle(0,0,_W,_H),new Point(0,0));
            _loc5_ = new ColorMatrixFilter(MATRIX_GRAY);
            _loc7_ = new ColorMatrixFilter(getBinarizeMatrix());
            _loc4_ = new ColorMatrixFilter(getForceThresholdMatrix());
            _binaryFilters = [_loc5_,_loc7_,_loc4_];
            _captureBmp = new Bitmap(_captureBmpData);
            _captureBmp.filters = _binaryFilters;
            _mainContainer.addChild(_captureBmp);
            _mainContainer.addChild(_lineSprite);
            _origParent = _target.parent as DisplayObjectContainer;
            if(_origParent)
            {
               _origIndex = _origParent.getChildIndex(_target);
               _origParent.removeChild(_target);
               _origParent.addChildAt(this,_origIndex);
            }
            _isInit = true;
            _isRunning = true;
            visible = true;
         }
         catch(e:Error)
         {
            Trace("ImpactEffectView 初始化错误: " + e.message);
            safeDispose();
         }
      }
      
      public function renderImpact() : Boolean
      {
         var _loc7_:int = 0;
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         var _loc6_:int = 0;
         var _loc4_:Number = NaN;
         var _loc1_:Number = NaN;
         var _loc5_:Number = NaN;
         if(!_isRunning || _isDispose || !_target || !_captureBmpData)
         {
            safeDispose();
            return false;
         }
         try
         {
            if(_frame > 0)
            {
               _captureBmpData.draw(_target);
            }
            _loc7_ = int(_glitchYList.length);
            _loc6_ = 0;
            while(_loc6_ < _loc7_)
            {
               _loc3_ = _glitchYList[_loc6_];
               _loc2_ = _glitchXList[_loc6_];
               if(_loc2_ != 0)
               {
                  _tempRect.x = Math.abs(_loc2_);
                  _tempRect.y = _loc3_;
                  _tempRect.width = _W - _tempRect.x;
                  _tempRect.height = 1;
                  _tempPoint.x = _loc2_ < 0 ? Math.abs(_loc2_) : 0;
                  _tempPoint.y = _loc3_;
                  _captureBmpData.copyPixels(_captureBmpData,_tempRect,_tempPoint);
               }
               _loc6_++;
            }
            _loc4_ = _frame / holdFrames;
            _loc1_ = 1 + _loc4_ * 0.08;
            _matrix.identity();
            _matrix.translate(-_cx,-_cy);
            _matrix.scale(_loc1_,_loc1_);
            _matrix.translate(_cx,_cy);
            _mainContainer.transform.matrix = _matrix;
            _loc5_ = _loc4_ * maxBlur;
            _blurFilter.blurX = _loc5_ * blurXYRatio;
            _blurFilter.blurY = _loc5_;
            this.filters = [_blurFilter];
            _frame = _frame + 1;
            if(_frame >= holdFrames)
            {
               safeDispose();
               return false;
            }
            return true;
         }
         catch(e:Error)
         {
            Trace("ImpactEffectView 帧更新错误: " + e.message);
            safeDispose();
            var _loc11_:Boolean = false;
         }
         return _loc11_;
      }
      
      private function safeDispose() : void
      {
         if(_isDispose)
         {
            return;
         }
         _isDispose = true;
         _isRunning = false;
         try
         {
            if(_origParent && _target && !_origParent.contains(_target))
            {
               _origParent.addChildAt(_target,_origIndex);
            }
            this.filters = _emptyFilters;
            if(_captureBmp)
            {
               _captureBmp.filters = _emptyFilters;
            }
            setTimeout(function():void
            {
               if(_captureBmpData)
               {
                  _captureBmpData.dispose();
                  _captureBmpData = null;
               }
               if(_preRenderBmpData)
               {
                  _preRenderBmpData.dispose();
                  _preRenderBmpData = null;
               }
               _captureBmp = null;
               _lineSprite = null;
               _mainContainer = null;
               _target = null;
               _origParent = null;
               _glitchYList = null;
               _glitchXList = null;
            },16);
            visible = false;
         }
         catch(e:Error)
         {
            Trace("ImpactEffectView 释放错误: " + e.message);
         }
      }
      
      public function dispose() : void
      {
         safeDispose();
      }
      
      public function get isDispose() : Boolean
      {
         return _isDispose;
      }
   }
}

