package net.play5d.game.bvn.interfaces
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.media.SoundTransform;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.utils.MCUtils;
   import net.play5d.kyo.utils.KyoUtils;
   import net.play5d.kyo.utils.UUID;
   
   public class BaseGameSprite extends EventDispatcher implements IGameSprite
   {
      
      protected var _colorTransform:ColorTransform;
      
      public var isInAir:Boolean;
      
      public var isTouchBottom:Boolean;
      
      public var isAllowBeHit:Boolean = true;
      
      public var isCross:Boolean = false;
      
      public var isAlive:Boolean = true;
      
      public var isAllowLoseHP:Boolean = true;
      
      public var isApplyG:Boolean = true;
      
      private var _heavy:Number = 2;
      
      private var _hp:Number = 1000;
      
      private var _hpMax:Number = 1000;
      
      public var defense:Number = 0;
      
      public var isAllowCrossX:Boolean = false;
      
      public var isAllowCrossBottom:Boolean = false;
      
      public var isAllowCrossFloor:Boolean = false;
      
      private var _attackRate:Number = 1;
      
      private var _defenseRate:Number = 1;
      
      public var id:String = UUID.create();
      
      protected var _x:Number = 0;
      
      protected var _y:Number = 0;
      
      protected var _g:Number = 0;
      
      protected var _mainMc:MovieClip;
      
      protected var _isTouchSide:Boolean = false;
      
      protected var _isActive:Boolean = false;
      
      protected var _area:Rectangle;
      
      private var _direct:int = 1;
      
      private var _scale:Number = 1;
      
      private var _frameFuncs:Array = [];
      
      private var _frameAnimateFuncs:Array = [];
      
      private var _team:TeamVO;
      
      private var _speedPlus:Number = GameConfig.SPEED_PLUS;
      
      private var _dampingRate:Number = 1;
      
      private var _velocity:Point = new Point();
      
      private var _damping:Point = new Point();
      
      private var _velocity2:Point = new Point();
      
      private var _damping2:Point = new Point();
      
      protected var _destoryed:Boolean;
      
      protected var _renderFuncs:Vector.<Function>;
      
      protected var _renderFuncsFps:Vector.<Function>;
      
      protected var _renderFuncsGlobal:Vector.<Function>;
      
      protected var _renderFuncsInherit:Vector.<Function>;
      
      public function BaseGameSprite(param1:MovieClip)
      {
         super();
         _mainMc = param1;
         if(_mainMc != null)
         {
            _area = _mainMc.getBounds(_mainMc);
            GameRender.addAfter(renderRenderFuncsGlobal);
         }
      }
      
      public function get colorTransform() : ColorTransform
      {
         return _colorTransform;
      }
      
      public function set colorTransform(param1:ColorTransform) : void
      {
         _colorTransform = param1;
         _mainMc.transform.colorTransform = param1 ?? new ColorTransform();
      }
      
      public function getActive() : Boolean
      {
         return _isActive;
      }
      
      public function setActive(param1:Boolean) : void
      {
         _isActive = param1;
      }
      
      public function get heavy() : Number
      {
         return _heavy;
      }
      
      public function set heavy(param1:Number) : void
      {
         _heavy = param1;
      }
      
      public function get hp() : Number
      {
         return _hp;
      }
      
      public function set hp(param1:Number) : void
      {
         var _loc5_:String = null;
         var _loc2_:Number = param1 > hpMax ? hpMax : param1;
         var _loc3_:Number = _loc2_ - _hp;
         if(_loc3_ == 0)
         {
            return;
         }
         var _loc4_:Number = Math.abs(_loc3_);
         if(this is FighterMain)
         {
            _loc5_ = _loc3_ > 0 ? "ADD_HP" : "LOSE_HP";
         }
         _hp = param1;
         if(_hp > hpMax)
         {
            _hp = hpMax;
         }
         if(_hp < 0)
         {
            _hp = 0;
         }
         if(this is FighterMain)
         {
            FighterEventDispatcher.dispatchEvent(this,_loc5_,_loc4_);
         }
      }
      
      public function get hpMax() : Number
      {
         return _hpMax;
      }
      
      public function set hpMax(param1:Number) : void
      {
         _hpMax = param1;
      }
      
      public function get hpRate() : Number
      {
         return hp / hpMax;
      }
      
      public function get attackRate() : Number
      {
         return _attackRate;
      }
      
      public function set attackRate(param1:Number) : void
      {
         _attackRate = param1;
      }
      
      public function get defenseRate() : Number
      {
         return _defenseRate;
      }
      
      public function set defenseRate(param1:Number) : void
      {
         _defenseRate = param1;
      }
      
      public function get mc() : MovieClip
      {
         return _mainMc;
      }
      
      public function get x() : Number
      {
         return _x;
      }
      
      public function set x(param1:Number) : void
      {
         _x = param1;
         _mainMc.x = _x;
      }
      
      public function get y() : Number
      {
         return _y;
      }
      
      public function set y(param1:Number) : void
      {
         _y = param1;
         _mainMc.y = _y;
      }
      
      public function get scale() : Number
      {
         return _scale;
      }
      
      public function set scale(param1:Number) : void
      {
         _scale = param1;
         _mainMc.scaleX = _mainMc.scaleY = _scale;
      }
      
      public function get direct() : int
      {
         return _direct;
      }
      
      public function set direct(param1:int) : void
      {
         _direct = param1;
         _mainMc.scaleX = _direct * _scale;
      }
      
      public function get team() : TeamVO
      {
         return _team;
      }
      
      public function set team(param1:TeamVO) : void
      {
         _team = param1;
      }
      
      public function updatePosition() : void
      {
         if(_mainMc == null)
         {
            return;
         }
         _mainMc.x = _x;
         _mainMc.y = _y;
      }
      
      public function setVolume(param1:Number) : void
      {
         KyoUtils.setMcVolume(mc,param1);
      }
      
      public function isDestoryed() : Boolean
      {
         return _destoryed;
      }
      
      public function destory(param1:Boolean = true) : void
      {
         _destoryed = true;
         isAlive = false;
         isAllowBeHit = false;
         stopRenderSelf();
         if(param1)
         {
            if(_mainMc)
            {
               try
               {
                  _mainMc.stopAllMovieClips();
                  _mainMc.removeChildren();
               }
               catch(e:Error)
               {
               }
               _mainMc = null;
            }
         }
         _renderFuncs = null;
         _renderFuncsFps = null;
         GameRender.removeAfter(renderRenderFuncsGlobal);
         _renderFuncsGlobal = null;
         _renderFuncsInherit = null;
      }
      
      public function renderAnimate() : void
      {
         if(_destoryed)
         {
            return;
         }
         renderRenderFuncs();
         renderAnimateFrameOut();
      }
      
      public function renderRenderFuncs() : void
      {
         MCUtils.renderFunc(_renderFuncs);
      }
      
      public function renderRenderFuncsFps() : void
      {
         MCUtils.renderFunc(_renderFuncsFps);
      }
      
      public function renderRenderFuncsGlobal() : void
      {
         MCUtils.renderFunc(_renderFuncsGlobal);
      }
      
      public function render() : void
      {
         if(_destoryed)
         {
            return;
         }
         renderVelocity();
         renderFrameOut();
         updatePosition();
         if(mc == null)
         {
            return;
         }
         renderRenderFuncsFps();
         var _loc1_:Number = !GameConfig.IS_WIN_ACTIVATE ? 0 : GameData.I.config.soundVolume;
         var _loc2_:SoundTransform = mc.soundTransform;
         if(_loc2_ == null)
         {
            return;
         }
         if(_loc1_ == _loc2_.volume)
         {
            return;
         }
         setVolume(_loc1_);
      }
      
      public function renderAllChildren(param1:MovieClip) : void
      {
         MCUtils.renderAllChildren(param1);
      }
      
      public function getDisplay() : DisplayObject
      {
         return _mainMc;
      }
      
      public function move(param1:Number = 0, param2:Number = 0) : void
      {
         if(param1 != 0)
         {
            _x += param1 * _speedPlus;
         }
         if(param2 != 0)
         {
            _y += param2 * _speedPlus;
         }
      }
      
      public function setSpeedRate(param1:Number) : void
      {
         _speedPlus = param1;
         _dampingRate = param1;
      }
      
      public function getVelocity() : Point
      {
         return _velocity;
      }
      
      public function getVecX() : Number
      {
         return _velocity.x;
      }
      
      public function getVecY() : Number
      {
         return _velocity.y;
      }
      
      public function setVecX(param1:Number) : void
      {
         _velocity.x = param1;
      }
      
      public function setVecY(param1:Number) : void
      {
         _velocity.y = param1;
      }
      
      public function setVelocity(param1:Number = 0, param2:Number = 0) : void
      {
         _velocity.x = param1;
         _velocity.y = param2;
         setDamping(0,0);
      }
      
      public function addVelocity(param1:Number = 0, param2:Number = 0) : void
      {
         _velocity.x += param1;
         _velocity.y += param2;
      }
      
      public function setVec2(param1:Number = 0, param2:Number = 0, param3:Number = 0, param4:Number = 0) : void
      {
         _velocity2.x = param1;
         _velocity2.y = param2;
         _damping2.x = param3 * 6;
         _damping2.y = param4 * 6;
      }
      
      public function getVec2() : Point
      {
         return _velocity2;
      }
      
      public function getDampingX() : Number
      {
         return _damping.x;
      }
      
      public function getDampingY() : Number
      {
         return _damping.y;
      }
      
      public function setDampingX(param1:Number) : void
      {
         _damping.x = param1;
      }
      
      public function setDampingY(param1:Number) : void
      {
         _damping.y = param1;
      }
      
      public function setDamping(param1:Number = 0, param2:Number = 0) : void
      {
         _damping.x = param1 * 2;
         _damping.y = param2 * 2;
      }
      
      public function addDamping(param1:Number = 0, param2:Number = 0) : void
      {
         _damping.x += param1;
         _damping.y += param2;
      }
      
      private function renderVelocity() : void
      {
         var _loc6_:FighterMain = null;
         var _loc10_:FighterMain = null;
         var _loc2_:Rectangle = null;
         var _loc9_:Rectangle = null;
         var _loc8_:Boolean = false;
         var _loc7_:Boolean = false;
         var _loc3_:Number = NaN;
         var _loc5_:int = 0;
         var _loc1_:Number = 0;
         var _loc4_:Number = 0;
         if(_velocity.x != 0)
         {
            _loc1_ += _velocity.x;
            if(_damping.x > 0)
            {
               _velocity.x = KyoUtils.num_wake(_velocity.x,_damping.x * _dampingRate);
            }
         }
         if(_velocity.y != 0)
         {
            _loc4_ += _velocity.y;
            if(_damping.y > 0)
            {
               _velocity.y = KyoUtils.num_wake(_velocity.y,_damping.y * _dampingRate);
            }
         }
         if(this is FighterMain)
         {
            if(_velocity2.x != 0)
            {
               _loc1_ += _velocity2.x;
               if(_damping2.x > 0)
               {
                  _velocity2.x = KyoUtils.num_wake(_velocity2.x,_damping2.x * _dampingRate);
               }
            }
            if(_velocity2.y != 0)
            {
               _loc4_ += _velocity2.y;
               if(_damping2.y > 0)
               {
                  _velocity2.y = KyoUtils.num_wake(_velocity2.y,_damping2.y * _dampingRate);
               }
            }
         }
         if(this is FighterMain && (this as FighterMain).getCurrentTarget() && (this as FighterMain).getCurrentTarget() is FighterMain)
         {
            _loc6_ = this as FighterMain;
            _loc10_ = _loc6_.getCurrentTarget() as FighterMain;
            _loc2_ = _loc6_.getBodyArea();
            _loc9_ = _loc10_.getBodyArea();
            if(_loc2_ && _loc9_ && !_loc6_.isCross && !_loc10_.isCross && !_loc10_.getIsTouchSide())
            {
               _loc6_.targetXMove *= _speedPlus;
               _loc8_ = _x < _loc6_.targetX != _x + _loc1_ < _loc6_.targetX + _loc6_.targetXMove;
               _loc7_ = !(_loc2_.bottom < _loc9_.top || _loc2_.top > _loc9_.bottom);
               if(_loc8_ && _loc7_)
               {
                  _loc3_ = _loc6_.targetX - _x;
                  _loc5_ = _loc6_.targetX > _x ? 1 : -1;
                  if(_loc1_ == _loc6_.targetXMove)
                  {
                     _loc1_ = _loc3_ * 0.5;
                  }
                  else
                  {
                     _loc1_ = _loc3_ * _loc1_ / (_loc1_ - _loc6_.targetXMove);
                  }
                  _loc1_ -= 2 * _loc5_;
               }
            }
         }
         if(_loc1_ != 0 || _loc4_ != 0)
         {
            move(_loc1_,_loc4_);
         }
      }
      
      public function applayG(param1:Number) : void
      {
         var _loc2_:Number = NaN;
         if(!isApplyG)
         {
            _g = 0;
            return;
         }
         if(_velocity.y < 0)
         {
            _g = 0;
            return;
         }
         if(_g < param1)
         {
            _loc2_ = 1.2 * GameConfig.SPEED_PLUS;
            _g += _loc2_;
            if(_g > param1)
            {
               _g = param1;
            }
         }
         move(0,_g);
      }
      
      public function setInAir(param1:Boolean) : void
      {
         if(!param1)
         {
            _g = 4;
         }
         isInAir = param1;
      }
      
      public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         if(param1 == null || param2 == null || param2.getDisplay() == null)
         {
            return;
         }
         var _loc5_:DisplayObject = getDisplay();
         var _loc3_:DisplayObject = param2.getDisplay();
         if(_loc5_ == null || _loc3_ == null)
         {
            return;
         }
         if(_loc5_.parent == null || _loc5_.parent != _loc3_.parent)
         {
            return;
         }
         var _loc4_:DisplayObjectContainer = _loc5_.parent;
         var _loc6_:int = _loc4_.getChildIndex(_loc5_);
         var _loc7_:int = _loc4_.getChildIndex(_loc3_);
         if(_loc6_ != -1 && _loc7_ != -1 && _loc6_ < _loc7_)
         {
            _loc4_.setChildIndex(_loc3_,_loc6_);
            _loc4_.setChildIndex(_loc5_,_loc7_);
         }
      }
      
      public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
      }
      
      public function getCurrentHits() : Array
      {
         return null;
      }
      
      public function getArea() : Rectangle
      {
         if(!_area)
         {
            return null;
         }
         var _loc1_:Rectangle = _area.clone();
         _loc1_.x += _x;
         _loc1_.y += _y;
         return _loc1_;
      }
      
      public function getBodyArea() : Rectangle
      {
         return null;
      }
      
      public function allowCrossMapXY() : Boolean
      {
         return isAllowCrossX;
      }
      
      public function allowCrossMapBottom() : Boolean
      {
         return isAllowCrossBottom;
      }
      
      public function allowCrossFloor() : Boolean
      {
         return isAllowCrossFloor;
      }
      
      public function getIsTouchSide() : Boolean
      {
         return _isTouchSide;
      }
      
      public function setIsTouchSide(param1:Boolean) : void
      {
         _isTouchSide = param1;
      }
      
      public function addHp(param1:Number) : void
      {
         hp += param1;
      }
      
      public function loseHp(param1:Number) : Number
      {
         if(!isAllowLoseHP)
         {
            return 0;
         }
         var _loc3_:Number = 2 - defenseRate;
         if(_loc3_ < 0.1)
         {
            _loc3_ = 0.1;
         }
         if(_loc3_ > 1)
         {
            _loc3_ = 1;
         }
         var _loc2_:Number = param1 * _loc3_ - defense;
         if(_loc2_ < 0)
         {
            return 0;
         }
         hp -= _loc2_;
         return _loc2_;
      }
      
      public function delayCall(param1:Function, param2:int) : void
      {
         _frameFuncs.push({
            "func":param1,
            "frame":param2
         });
      }
      
      public function renderSelf() : void
      {
         GameRender.add(renderSelfEnterFrame,this);
      }
      
      private function renderSelfEnterFrame() : void
      {
         if(_destoryed)
         {
            return;
         }
         try
         {
            render();
            renderAnimate();
         }
         catch(e:Error)
         {
            Debugger.log("BaseGameSprite.renderSelfEnterFrame",e);
         }
      }
      
      public function stopRenderSelf() : void
      {
         GameRender.remove(renderSelfEnterFrame,this);
      }
      
      public function setAnimateFrameOut(param1:Function, param2:int) : void
      {
         _frameAnimateFuncs.push({
            "func":param1,
            "frame":param2
         });
      }
      
      private function renderAnimateFrameOut() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Object = null;
         if(_frameAnimateFuncs.length < 1)
         {
            return;
         }
         _loc1_ = 0;
         while(_loc1_ < _frameAnimateFuncs.length)
         {
            _loc2_ = _frameAnimateFuncs[_loc1_];
            _loc2_.frame--;
            if(_loc2_.frame < 1)
            {
               _loc2_.func();
               _frameAnimateFuncs.splice(_loc1_,1);
            }
            _loc1_++;
         }
      }
      
      private function renderFrameOut() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Object = null;
         if(_frameFuncs.length < 1)
         {
            return;
         }
         _loc1_ = 0;
         while(_loc1_ < _frameFuncs.length)
         {
            _loc2_ = _frameFuncs[_loc1_];
            _loc2_.frame--;
            if(_loc2_.frame < 1)
            {
               _loc2_.func();
               _frameFuncs.splice(_loc1_,1);
            }
            _loc1_++;
         }
      }
      
      public function addRenderFunc(param1:Function = null, param2:Object = null) : void
      {
         var func:Function = param1;
         var params:Object = param2;
         var addRender:* = function(param1:Vector.<Function>):void
         {
            var _loc2_:int = param1.indexOf(func);
            if(_loc2_ == -1)
            {
               param1.push(func);
            }
         };
         if(func == null)
         {
            return;
         }
         if(params != null)
         {
            if(params.isFollowFps)
            {
               if(params.isPermanent)
               {
                  if(_renderFuncsGlobal == null)
                  {
                     _renderFuncsGlobal = new Vector.<Function>();
                  }
                  addRender(_renderFuncsGlobal);
                  return;
               }
               if(_renderFuncsFps == null)
               {
                  _renderFuncsFps = new Vector.<Function>();
               }
               addRender(_renderFuncsFps);
               return;
            }
         }
         if(_renderFuncs == null)
         {
            _renderFuncs = new Vector.<Function>();
         }
         addRender(_renderFuncs);
      }
      
      public function removeRenderFunc(param1:Function = null) : void
      {
         var _loc3_:int = 0;
         if(param1 == null)
         {
            return;
         }
         var _loc2_:Vector.<Vector.<Function>> = new Vector.<Vector.<Function>>();
         _loc2_.push(_renderFuncs);
         _loc2_.push(_renderFuncsFps);
         _loc2_.push(_renderFuncsGlobal);
         for each(var _loc4_ in _loc2_)
         {
            if(_loc4_ != null)
            {
               _loc3_ = _loc4_.indexOf(param1);
               if(_loc3_ != -1)
               {
                  _loc4_.splice(_loc3_,1);
               }
            }
         }
         _loc2_ = null;
      }
      
      public function inheritRenderFunc(param1:Function = null) : void
      {
         if(_renderFuncsInherit == null)
         {
            _renderFuncsInherit = new Vector.<Function>();
         }
         var _loc2_:int = _renderFuncsInherit.indexOf(param1);
         if(_loc2_ == -1)
         {
            _renderFuncsInherit.push(param1);
         }
      }
      
      public function doInheritFunc(param1:BaseGameSprite) : void
      {
         for each(var _loc2_ in _renderFuncsInherit)
         {
            if(_renderFuncs != null && _renderFuncs.indexOf(_loc2_) != -1)
            {
               param1.addRenderFunc(_loc2_);
            }
            if(_renderFuncsFps != null && _renderFuncsFps.indexOf(_loc2_) != -1)
            {
               param1.addRenderFunc(_loc2_,{"isFollowFps":true});
            }
            if(_renderFuncsGlobal != null && _renderFuncsGlobal.indexOf(_loc2_) != -1)
            {
               param1.addRenderFunc(_loc2_,{
                  "isFollowFps":true,
                  "isPermanent":true
               });
            }
         }
      }
   }
}

