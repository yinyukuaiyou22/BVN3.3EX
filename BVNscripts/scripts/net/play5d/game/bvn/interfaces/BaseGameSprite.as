package net.play5d.game.bvn.interfaces
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.geom.*;
   import flash.media.SoundTransform;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.kyo.utils.*;
   
   public class BaseGameSprite extends EventDispatcher implements IGameSprite
   {
      
      public var isInAir:Boolean;
      
      public var isTouchBottom:Boolean;
      
      public var isAllowBeHit:Boolean = true;
      
      public var isCross:Boolean = false;
      
      public var isAlive:Boolean = true;
      
      public var isAllowLoseHP:Boolean = true;
      
      public var isApplyG:Boolean = true;
      
      public var heavy:Number = 2;
      
      public var hp:Number = 1000;
      
      public var hpMax:Number = 1000;
      
      public var defense:Number = 0;
      
      public var isAllowCrossX:Boolean = false;
      
      public var isAllowCrossBottom:Boolean = false;
      
      private var _attackRate:Number = 1;
      
      private var _defenseRate:Number = 1;
      
      public var id:String = UUID.create();
      
      protected var _x:Number = 0;
      
      protected var _y:Number = 0;
      
      protected var _g:Number = 0;
      
      protected var _mainMc:MovieClip;
      
      protected var _isTouchSide:Boolean = false;
      
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
      
      public function BaseGameSprite(param1:MovieClip)
      {
         super();
         this._mainMc = param1;
         if(Boolean(this._mainMc))
         {
            this._area = this._mainMc.getBounds(this._mainMc);
         }
      }
      
      public function get attackRate() : Number
      {
         return this._attackRate;
      }
      
      public function set attackRate(param1:Number) : void
      {
         this._attackRate = param1;
      }
      
      public function get defenseRate() : Number
      {
         return this._defenseRate;
      }
      
      public function set defenseRate(param1:Number) : void
      {
         this._defenseRate = param1;
      }
      
      public function get mc() : MovieClip
      {
         return this._mainMc;
      }
      
      public function get x() : Number
      {
         return this._x;
      }
      
      public function set x(param1:Number) : void
      {
         this._x = param1;
      }
      
      public function get y() : Number
      {
         return this._y;
      }
      
      public function set y(param1:Number) : void
      {
         this._y = param1;
      }
      
      public function get scale() : Number
      {
         return this._scale;
      }
      
      public function set scale(param1:Number) : void
      {
         this._scale = param1;
         this._mainMc.scaleX = this._mainMc.scaleY = param1;
      }
      
      public function get direct() : int
      {
         return this._direct;
      }
      
      public function set direct(param1:int) : void
      {
         this._direct = param1;
         this._mainMc.scaleX = this._direct * this._scale;
      }
      
      public function get team() : TeamVO
      {
         return this._team;
      }
      
      public function set team(param1:TeamVO) : void
      {
         this._team = param1;
      }
      
      public function updatePosition() : void
      {
         this._mainMc.x = this._x;
         this._mainMc.y = this._y;
      }
      
      public function setVolume(param1:Number) : void
      {
         var _loc2_:SoundTransform = null;
         if(Boolean(this._mainMc))
         {
            _loc2_ = this._mainMc.soundTransform;
            if(Boolean(_loc2_))
            {
               _loc2_.volume = param1;
               this._mainMc.soundTransform = _loc2_;
            }
         }
      }
      
      public function isDestoryed() : Boolean
      {
         return this._destoryed;
      }
      
      public function destory(param1:Boolean = true) : void
      {
         this._destoryed = true;
         this.isAlive = false;
         this.isAllowBeHit = false;
         this.stopRenderSelf();
         if(param1)
         {
            if(Boolean(this._mainMc))
            {
               try
               {
                  this._mainMc.stopAllMovieClips();
               }
               catch(e:Error)
               {
                  trace(e);
               }
               this._mainMc = null;
            }
         }
      }
      
      public function renderAnimate() : void
      {
         if(this._destoryed)
         {
            return;
         }
         this.renderAnimateFrameOut();
      }
      
      public function render() : void
      {
         if(this._destoryed)
         {
            return;
         }
         this.renderVelocity();
         this.renderFrameOut();
         this._mainMc.x = this._x;
         this._mainMc.y = this._y;
      }
      
      public function getDisplay() : DisplayObject
      {
         return this._mainMc;
      }
      
      public function move(param1:Number = 0, param2:Number = 0) : void
      {
         if(param1 != 0)
         {
            this._x += param1 * this._speedPlus;
         }
         if(param2 != 0)
         {
            this._y += param2 * this._speedPlus;
         }
      }
      
      public function setSpeedRate(param1:Number) : void
      {
         this._speedPlus = param1;
         this._dampingRate = param1 / GameConfig.SPEED_PLUS_DEFAULT;
      }
      
      public function getVelocity() : Point
      {
         return this._velocity;
      }
      
      public function getVecX() : Number
      {
         return this._velocity.x;
      }
      
      public function getVecY() : Number
      {
         return this._velocity.y;
      }
      
      public function setVecX(param1:Number) : void
      {
         this._velocity.x = param1;
      }
      
      public function setVecY(param1:Number) : void
      {
         this._velocity.y = param1;
      }
      
      public function setVelocity(param1:Number = 0, param2:Number = 0) : void
      {
         this._velocity.x = param1;
         this._velocity.y = param2;
         this.setDamping(0,0);
      }
      
      public function addVelocity(param1:Number = 0, param2:Number = 0) : void
      {
         this._velocity.x += param1;
         this._velocity.y += param2;
      }
      
      public function setVec2(param1:Number = 0, param2:Number = 0, param3:Number = 0, param4:Number = 0) : void
      {
         this._velocity2.x = param1;
         this._velocity2.y = param2;
         this._damping2.x = param3 * GameConfig.SPEED_PLUS_DEFAULT * 6;
         this._damping2.y = param4 * GameConfig.SPEED_PLUS_DEFAULT * 6;
      }
      
      public function getVec2() : Point
      {
         return this._velocity2;
      }
      
      public function getDampingX() : Number
      {
         return this._damping.x;
      }
      
      public function getDampingY() : Number
      {
         return this._damping.y;
      }
      
      public function setDampingX(param1:Number) : void
      {
         this._damping.x = param1;
      }
      
      public function setDampingY(param1:Number) : void
      {
         this._damping.y = param1;
      }
      
      public function setDamping(param1:Number = 0, param2:Number = 0) : void
      {
         this._damping.x = param1 * GameConfig.SPEED_PLUS_DEFAULT * 2;
         this._damping.y = param2 * GameConfig.SPEED_PLUS_DEFAULT * 2;
      }
      
      public function addDamping(param1:Number = 0, param2:Number = 0) : void
      {
         this._damping.x += param1;
         this._damping.y += param2;
      }
      
      private function renderVelocity() : void
      {
         var _loc1_:Number = 0;
         var _loc2_:Number = 0;
         if(this._velocity.x != 0)
         {
            _loc1_ += this._velocity.x;
            if(this._damping.x > 0)
            {
               this._velocity.x = KyoUtils.num_wake(this._velocity.x,this._damping.x * this._dampingRate);
            }
         }
         if(this._velocity.y != 0)
         {
            _loc2_ += this._velocity.y;
            if(this._damping.y > 0)
            {
               this._velocity.y = KyoUtils.num_wake(this._velocity.y,this._damping.y * this._dampingRate);
            }
         }
         if(this._velocity2.x != 0)
         {
            _loc1_ += this._velocity2.x;
            if(this._damping2.x > 0)
            {
               this._velocity2.x = KyoUtils.num_wake(this._velocity2.x,this._damping2.x * this._dampingRate);
            }
         }
         if(this._velocity2.y != 0)
         {
            _loc2_ += this._velocity2.y;
            if(this._damping2.y > 0)
            {
               this._velocity2.y = KyoUtils.num_wake(this._velocity2.y,this._damping2.y * this._dampingRate);
            }
         }
         if(_loc1_ != 0 || _loc2_ != 0)
         {
            this.move(_loc1_,_loc2_);
         }
      }
      
      public function applayG(param1:Number) : void
      {
         var _loc2_:Number = NaN;
         if(!this.isApplyG)
         {
            this._g = 0;
            return;
         }
         if(this._velocity.y < 0)
         {
            this._g = 0;
            return;
         }
         if(this._g < param1)
         {
            _loc2_ = 1.2 * GameConfig.SPEED_PLUS;
            this._g += _loc2_;
            if(this._g > param1)
            {
               this._g = param1;
            }
         }
         this.move(0,this._g);
      }
      
      public function setInAir(param1:Boolean) : void
      {
         if(!param1)
         {
            this._g = 4;
         }
         this.isInAir = param1;
      }
      
      public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         var _loc3_:DisplayObject = null;
         var _loc4_:DisplayObject = null;
         var _loc5_:DisplayObjectContainer = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         if(Boolean(param2) && Boolean(param2.getDisplay()))
         {
            _loc3_ = this.getDisplay();
            _loc4_ = param2.getDisplay();
            if(Boolean(_loc3_ && _loc4_) && Boolean(_loc3_.parent) && _loc3_.parent == _loc4_.parent)
            {
               _loc5_ = _loc3_.parent;
               _loc6_ = _loc5_.getChildIndex(_loc3_);
               _loc7_ = _loc5_.getChildIndex(_loc4_);
               if(_loc6_ != -1 && _loc7_ != -1 && _loc6_ < _loc7_)
               {
                  _loc5_.setChildIndex(_loc4_,_loc6_);
                  _loc5_.setChildIndex(_loc3_,_loc7_);
               }
            }
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
         if(!this._area)
         {
            return null;
         }
         var _loc1_:Rectangle = this._area.clone();
         _loc1_.x += this._x;
         _loc1_.y += this._y;
         return _loc1_;
      }
      
      public function getBodyArea() : Rectangle
      {
         return null;
      }
      
      public function allowCrossMapXY() : Boolean
      {
         return this.isAllowCrossX;
      }
      
      public function allowCrossMapBottom() : Boolean
      {
         return this.isAllowCrossBottom;
      }
      
      public function getIsTouchSide() : Boolean
      {
         return this._isTouchSide;
      }
      
      public function setIsTouchSide(param1:Boolean) : void
      {
         this._isTouchSide = param1;
      }
      
      public function addHp(param1:Number) : void
      {
         this.hp += param1;
         if(this.hp > this.hpMax)
         {
            this.hp = this.hpMax;
         }
      }
      
      public function loseHp(param1:Number) : void
      {
         if(!this.isAllowLoseHP)
         {
            return;
         }
         var _loc2_:Number = 2 - this.defenseRate;
         if(_loc2_ < 0.1)
         {
            _loc2_ = 0.1;
         }
         if(_loc2_ > 1)
         {
            _loc2_ = 1;
         }
         var _loc3_:Number = param1 * _loc2_ - this.defense;
         if(_loc3_ < 0)
         {
            return;
         }
         this.hp -= _loc3_;
         if(this.hp < 0)
         {
            this.hp = 0;
         }
      }
      
      public function delayCall(param1:Function, param2:int) : void
      {
         this._frameFuncs.push({
            "func":param1,
            "frame":param2
         });
      }
      
      public function renderSelf() : void
      {
         GameRender.add(this.renderSelfEnterFrame,this);
      }
      
      private function renderSelfEnterFrame() : void
      {
         if(this._destoryed)
         {
            return;
         }
         try
         {
            this.render();
            this.renderAnimate();
         }
         catch(e:Error)
         {
            Debugger.log("BaseGameSprite.renderSelfEnterFrame",e);
         }
      }
      
      public function stopRenderSelf() : void
      {
         GameRender.remove(this.renderSelfEnterFrame,this);
      }
      
      public function setAnimateFrameOut(param1:Function, param2:int) : void
      {
         this._frameAnimateFuncs.push({
            "func":param1,
            "frame":param2
         });
      }
      
      private function renderAnimateFrameOut() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Object = null;
         if(this._frameAnimateFuncs.length < 1)
         {
            return;
         }
         while(_loc1_ < this._frameAnimateFuncs.length)
         {
            _loc2_ = this._frameAnimateFuncs[_loc1_];
            --_loc2_.frame;
            if(_loc2_.frame < 1)
            {
               _loc2_.func();
               this._frameAnimateFuncs.splice(_loc1_,1);
            }
            _loc1_++;
         }
      }
      
      private function renderFrameOut() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Object = null;
         if(this._frameFuncs.length < 1)
         {
            return;
         }
         while(_loc1_ < this._frameFuncs.length)
         {
            _loc2_ = this._frameFuncs[_loc1_];
            --_loc2_.frame;
            if(_loc2_.frame < 1)
            {
               _loc2_.func();
               this._frameFuncs.splice(_loc1_,1);
            }
            _loc1_++;
         }
      }
   }
}

