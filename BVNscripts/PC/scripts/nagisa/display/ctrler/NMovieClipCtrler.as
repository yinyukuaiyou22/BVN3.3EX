package nagisa.display.ctrler
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.FrameLabel;
   import flash.display.MovieClip;
   import flash.geom.Rectangle;
   import nagisa.debug.OutputMessage;
   import nagisa.events.NEventDispatcher;
   import nagisa.util.ArrayUtil;
   import nagisa.util.ClassUtil;
   import nagisa.util.DisplayUtil;
   import nagisa.util.MathUtil;
   import nagisa.util.NagisaUtil;
   
   public class NMovieClipCtrler extends NEventDispatcher
   {
      
      public static const PLAY_END:String = "play_end";
      
      public var isLoop:Boolean = false;
      
      protected var _isEnd:Boolean = false;
      
      protected var _player:Object;
      
      protected var _isPlaying:Boolean;
      
      protected var _frameCount:int = 0;
      
      protected var _playDirect:int = 1;
      
      protected var _currentFrame:int = 1;
      
      protected var _currentFrameLabel:String = null;
      
      protected var _currentLabel:String = null;
      
      protected var _totalFrames:int = 1;
      
      protected var _frameLabels:Object;
      
      protected var _playRate:Number = 1;
      
      private var _pointFrame:Number = 0;
      
      protected var _inited:Boolean = false;
      
      private var _scripts:Boolean;
      
      public function NMovieClipCtrler()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return _player as DisplayObject;
      }
      
      public function get movieClip() : MovieClip
      {
         return _player as MovieClip;
      }
      
      public function get isPlaying() : Boolean
      {
         return _isPlaying;
      }
      
      public function get label() : String
      {
         return _currentLabel;
      }
      
      public function get frameLabel() : String
      {
         return _currentFrameLabel;
      }
      
      public function get frame() : int
      {
         return _currentFrame;
      }
      
      public function get totalFrames() : int
      {
         return _totalFrames;
      }
      
      public function get frameCount() : int
      {
         return _frameCount;
      }
      
      public function get frameLabels() : Object
      {
         return _frameLabels;
      }
      
      public function get playDirect() : int
      {
         return _playDirect;
      }
      
      public function set playDirect(param1:int) : void
      {
         if(!param1)
         {
            return;
         }
         _playDirect = MathUtil.sgn(param1);
      }
      
      public function get playRate() : Number
      {
         return _playRate;
      }
      
      public function set playRate(param1:Number) : void
      {
         if(isNaN(param1))
         {
            return;
         }
         _playRate = param1;
      }
      
      public function isInited() : Boolean
      {
         return _inited;
      }
      
      public function getChildByName(param1:String) : DisplayObject
      {
         if(!_player)
         {
            return null;
         }
         if(!(_player is DisplayObjectContainer))
         {
            return null;
         }
         return _player.getChildByName(param1);
      }
      
      public function getChildBounds(param1:DisplayObject) : Rectangle
      {
         if(!_player)
         {
            return null;
         }
         if(!(_player is DisplayObject))
         {
            return null;
         }
         return param1.getBounds(_player as DisplayObject);
      }
      
      public function getIsEnd() : Boolean
      {
         return _isEnd;
      }
      
      public function initialize(param1:* = null, param2:Object = null, param3:int = 0) : void
      {
         _inited = true;
         _frameLabels = {};
         if(param1)
         {
            switch(ClassUtil.checkTargetType(param1,MovieClip,Vector.<*>,Array))
            {
               case 0:
                  _player = param1;
                  for each(var _loc4_ in _player.currentLabels)
                  {
                     _frameLabels[_loc4_.frame] = _loc4_.name;
                  }
                  _totalFrames = _player.totalFrames;
                  break;
               case 1:
               case 2:
                  _totalFrames = param1.length;
                  break;
               default:
                  _player = param1;
                  _frameLabels = _player.frameLabels || _frameLabels;
                  _totalFrames = _player.totalFrames;
            }
         }
         else
         {
            if(!param3)
            {
               OutputMessage.ERROR("NMovieClipCtrler","initialize","没有传入参数 totalFrames",null,true);
            }
            _frameLabels = param2 || {};
            _totalFrames = param3;
         }
      }
      
      public function initScript(param1:Object) : void
      {
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         _inited = false;
         isLoop = false;
         _currentFrame = 1;
         _currentFrameLabel = null;
         _currentLabel = null;
         _frameCount = 0;
         _inited = false;
         _isEnd = false;
         _isPlaying = false;
         _playDirect = 1;
         _playRate = 1;
         _pointFrame = 0;
         _totalFrames = 0;
         if(_player)
         {
            NagisaUtil.destory(_player,param1);
            _player = null;
         }
         _frameLabels = null;
         super.destory(param1);
      }
      
      override public function render() : void
      {
         if(_destoryed)
         {
            return;
         }
         super.render();
      }
      
      override public function renderAnimate() : void
      {
         if(_destoryed)
         {
            return;
         }
         super.renderAnimate();
         _renderAnimateMainMc();
         _frameCount = _frameCount + 1;
         _renderChildren();
      }
      
      protected function _renderAnimateMainMc() : void
      {
         var _loc1_:int = _currentFrame;
         if(_isPlaying)
         {
            _playDirect > 0 ? nextFrame() : prevFrame();
         }
         if(_loc1_ != _currentFrame && _currentFrame == (_playDirect > 0 ? _totalFrames : 1))
         {
            _isEnd = true;
            dispatch("play_end",{"dispatcher":this});
         }
      }
      
      private function _renderChildren() : void
      {
         if(!_player)
         {
            return;
         }
         if(!(_player is DisplayObjectContainer))
         {
            return;
         }
         DisplayUtil.funcAllChildren(_player as DisplayObjectContainer,_renderChild);
      }
      
      public function nextFrame() : void
      {
         _doFrame(1);
      }
      
      public function prevFrame() : void
      {
         _doFrame(-1);
      }
      
      public function play() : void
      {
         _isPlaying = true;
      }
      
      public function stop() : void
      {
         _isPlaying = false;
      }
      
      public function gotoAndPlay(param1:Object) : void
      {
         _goFrame(param1,true);
      }
      
      public function gotoAndStop(param1:Object) : void
      {
         _goFrame(param1,false);
      }
      
      public function loop() : void
      {
         _goto(_playDirect > 0 ? 1 : _totalFrames);
      }
      
      protected function _goFrame(param1:Object, param2:Boolean) : void
      {
         _isPlaying = param2;
         _frameCount = 0;
         _goto(param1);
         _stopChildren();
      }
      
      protected function _renderChild(param1:DisplayObject) : Boolean
      {
         var _loc2_:MovieClip = param1 as MovieClip;
         if(!_loc2_)
         {
            return false;
         }
         if(_loc2_.totalFrames < 2)
         {
            return false;
         }
         try
         {
            _loc2_.currentFrame == _loc2_.totalFrames ? _loc2_.gotoAndStop(1) : _loc2_.nextFrame();
         }
         catch(e:Error)
         {
            OutputMessage.ERROR("NMovieClipCtrler","_renderChildren","child script have error",e,true);
         }
         return false;
      }
      
      protected function _stopChildren() : void
      {
         if(!_player)
         {
            return;
         }
         if(!(_player is DisplayObjectContainer))
         {
            return;
         }
         if(_player.numChildren < 1)
         {
            return;
         }
         DisplayUtil.funcAllChildren(_player as DisplayObjectContainer,function(param1:DisplayObject):Boolean
         {
            if(param1 is MovieClip)
            {
               (param1 as MovieClip).stop();
            }
            return false;
         });
      }
      
      protected function _doFrame(param1:Number = 1) : void
      {
         param1 *= _playRate;
         if(!param1)
         {
            return;
         }
         param1 += _pointFrame;
         if(!int(param1))
         {
            _pointFrame = param1 - int(param1);
            return;
         }
         param1 = int(param1);
         switch(param1)
         {
            case 1:
               _nextFrame();
               break;
            case -1:
               _prevFrame();
               break;
            default:
               _goto(ArrayUtil.getInArray(_currentFrame + param1,1,_totalFrames));
         }
         _stopChildren();
         _pointFrame = param1 - int(param1);
      }
      
      private function _nextFrame() : void
      {
         if(_currentFrame == _totalFrames)
         {
            isLoop ? _goto(1) : stop();
            return;
         }
         try
         {
            if(_player && "nextFrame" in _player)
            {
               _player.nextFrame();
            }
            _setFrame(_currentFrame + 1);
         }
         catch(e:Error)
         {
            OutputMessage.ERROR("NMovieClipCtrler","_nextFrame","mc script have error",e,true);
         }
      }
      
      private function _prevFrame() : void
      {
         if(_currentFrame == 1)
         {
            isLoop ? _goto(_totalFrames) : stop();
            return;
         }
         try
         {
            if(_player && "prevFrame" in _player)
            {
               _player.prevFrame();
            }
            _setFrame(_currentFrame - 1);
         }
         catch(e:Error)
         {
            OutputMessage.ERROR("NMovieClipCtrler","_prevFrame","mc script have error",e,true);
         }
      }
      
      private function _goto(param1:Object) : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:String = null;
         if(!param1)
         {
            OutputMessage.ERROR("NMovieClipCtrler","_goto","参数为null");
            return;
         }
         if(param1 is Number)
         {
            _loc3_ = Number(param1);
         }
         if(param1 is String)
         {
            _loc2_ = String(param1);
         }
         if(isLoop)
         {
            if(_loc3_)
            {
               if(_loc3_ > _totalFrames)
               {
                  param1 = _loc3_ -= _totalFrames;
               }
               else if(_loc3_ < 1)
               {
                  param1 = _loc3_ = _totalFrames - _loc3_;
               }
            }
         }
         try
         {
            if(_player && "gotoAndStop" in _player)
            {
               _player.gotoAndStop(param1);
            }
            _setFrame(param1);
         }
         catch(e:Error)
         {
            OutputMessage.ERROR("NMovieClipCtrler","_goto","mc " + frame + " script have error",e,true);
         }
      }
      
      private function _setFrame(param1:Object) : void
      {
         var _loc2_:int = 0;
         if(param1 is String)
         {
            _loc2_ = hasLabel(param1 as String);
         }
         else if(param1 is Number)
         {
            _loc2_ = param1 as int;
            if(_loc2_ <= 0 || _loc2_ > _totalFrames)
            {
               OutputMessage.ERROR("NMovieClipCtrler","_setFrame","无法跳转到 " + param1 + " !");
               return;
            }
         }
         else
         {
            OutputMessage.ERROR("NMovieClipCtrler","_setFrame","frame: " + param1 + " 既不是String也不是Number",null,true);
         }
         if(!_loc2_)
         {
            OutputMessage.ERROR("NMovieClipCtrler","_setFrame","无法跳转到 " + param1 + " !",null,true);
         }
         _currentFrame = _loc2_;
         _currentFrameLabel = _frameLabels[_currentFrame];
         _setCurrentLabel(_currentFrame);
         _applyScript();
      }
      
      public function hasLabel(param1:String) : int
      {
         for(var _loc2_ in _frameLabels)
         {
            if(param1 == _frameLabels[_loc2_])
            {
               return int(_loc2_);
            }
         }
         return 0;
      }
      
      private function _setCurrentLabel(param1:int) : void
      {
         var _loc2_:int = 0;
         var _loc3_:String = null;
         for(var _loc4_ in _frameLabels)
         {
            _loc2_ = _loc4_ as int;
            if(_frameLabels[_loc2_])
            {
               _loc3_ = _frameLabels[_loc2_];
            }
            if(_loc2_ > param1)
            {
               break;
            }
            _currentLabel = _loc3_;
         }
      }
      
      private function _applyScript() : void
      {
         if(!_scripts)
         {
            return;
         }
         var _loc1_:Function = _scripts[_currentFrame] as Function;
         if(_loc1_ == null)
         {
            return;
         }
         _loc1_(this);
      }
   }
}

