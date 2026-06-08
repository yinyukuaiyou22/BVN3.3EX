package net.play5d.game.bvn.fighter
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.geom.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.utils.*;
   
   public class Bullet implements IGameSprite
   {
      
      public var speed:Point = new Point(5,0);
      
      public var hp:int = 100;
      
      public var hpMax:int = 100;
      
      public var addSpeed:Point = new Point();
      
      public var maxSpeed:Point = new Point(999,999);
      
      public var minSpeed:Point = new Point(-999,-999);
      
      public var hitSpeed:Point = new Point(NaN,NaN);
      
      public var holdFrame:int = -1;
      
      public var onRemove:Function;
      
      public var mc:MovieClip;
      
      public var hitTimes:int = -1;
      
      public var owner:IGameSprite;
      
      private var _area:Rectangle;
      
      private var _orgScale:Point;
      
      private var _orgRotate:int;
      
      private var _team:TeamVO;
      
      private var _isHit:Boolean;
      
      private var _isTimeout:Boolean;
      
      private var _bulletArea:Rectangle;
      
      private var _hitVO:HitVO;
      
      private var _loopFrame:Object;
      
      private var _hitAble:Boolean = true;
      
      private var _speedPlus:Number = GameConfig.SPEED_PLUS;
      
      private var _destoryed:Boolean;
      
      private var _direct:int;
      
      private var _currentRect:Rectangle = new Rectangle();
      
      public function Bullet(param1:MovieClip, param2:Object = null)
      {
         super();
         this.mc = param1;
         this._orgScale = new Point(param1.scaleX,param1.scaleY);
         this._orgRotate = param1.rotation;
         if(Boolean(param2))
         {
            if(Boolean(param2.x))
            {
               if(param2.x is Number)
               {
                  this.speed.x = param2.x;
               }
               else
               {
                  if(param2.x.start != undefined)
                  {
                     this.speed.x = param2.x.start;
                  }
                  if(param2.x.add != undefined)
                  {
                     this.addSpeed.x = param2.x.add * 2;
                  }
                  if(param2.x.max != undefined)
                  {
                     this.maxSpeed.x = param2.x.max;
                  }
                  if(param2.x.min != undefined)
                  {
                     this.minSpeed.x = param2.x.min;
                  }
                  if(param2.x.hit != undefined)
                  {
                     this.hitSpeed.x = param2.x.hit;
                  }
               }
            }
            if(Boolean(param2.y))
            {
               if(param2.y is Number)
               {
                  this.speed.y = param2.y;
               }
               else
               {
                  if(param2.y.start != undefined)
                  {
                     this.speed.y = param2.y.start;
                  }
                  if(param2.y.add != undefined)
                  {
                     this.addSpeed.y = param2.y.add * 2;
                  }
                  if(param2.y.max != undefined)
                  {
                     this.maxSpeed.y = param2.y.max;
                  }
                  if(param2.y.min != undefined)
                  {
                     this.minSpeed.y = param2.y.min;
                  }
                  if(param2.y.hit != undefined)
                  {
                     this.hitSpeed.y = param2.y.hit;
                  }
               }
            }
            if(Boolean(param2.hold))
            {
               if(param2.hold == -1)
               {
                  this.holdFrame = -1;
               }
               else
               {
                  this.holdFrame = param2.hold * GameConfig.FPS_GAME;
               }
            }
            if(Boolean(param2.hits))
            {
               this.hitTimes = param2.hits;
            }
            if(Boolean(param2.hp))
            {
               this.hp = this.hpMax = param2.hp;
            }
         }
      }
      
      public function get x() : Number
      {
         return this.mc.x;
      }
      
      public function set x(param1:Number) : void
      {
         this.mc.x = param1;
      }
      
      public function get y() : Number
      {
         return this.mc.y;
      }
      
      public function set y(param1:Number) : void
      {
         this.mc.y = param1;
      }
      
      public function get team() : TeamVO
      {
         return this._team;
      }
      
      public function set team(param1:TeamVO) : void
      {
         this._team = param1;
      }
      
      public function isAttacking() : Boolean
      {
         return this._hitAble;
      }
      
      public function setSpeedRate(param1:Number) : void
      {
         this._speedPlus = param1;
      }
      
      public function setVolume(param1:Number) : void
      {
         KyoUtils.setMcVolume(this.mc,param1);
      }
      
      public function get direct() : int
      {
         return this._direct;
      }
      
      public function set direct(param1:int) : void
      {
         this._direct = param1;
         this.mc.scaleX = this._orgScale.x * this._direct;
         this.mc.rotation = this._orgRotate * this._direct;
         this.mc.x *= this._direct;
         this.speed.x *= param1;
         this.addSpeed.x *= param1;
         if(!isNaN(this.hitSpeed.x))
         {
            this.hitSpeed.x *= param1;
         }
      }
      
      public function setHitVO(param1:HitVO) : void
      {
         var _loc2_:FighterMC = null;
         this.owner = param1.owner;
         this._hitVO = param1.clone();
         this._hitVO.owner = this;
         var _loc3_:DisplayObject = this.mc.getChildByName("main");
         var _loc4_:DisplayObject = this.owner.getDisplay();
         if(Boolean(_loc3_))
         {
            this._bulletArea = _loc3_.getBounds(_loc4_);
            this._bulletArea.x -= this.mc.x;
            this._bulletArea.y -= this.mc.y;
         }
         else
         {
            this._bulletArea = this.mc.getBounds(_loc4_);
            this._bulletArea.x -= this.mc.x;
            this._bulletArea.y -= this.mc.y;
         }
         this.direct = this.owner.direct;
         this.mc.x += this.owner.x;
         this.mc.y += this.owner.y;
         if(this.owner is FighterMain)
         {
            _loc2_ = (this.owner as FighterMain).getMC();
            this.mc.x += _loc2_.x;
            this.mc.y += _loc2_.y;
            this._bulletArea.x -= _loc2_.x;
            this._bulletArea.y -= _loc2_.y;
         }
      }
      
      public function destory(param1:Boolean = true) : void
      {
         this._destoryed = true;
         if(Boolean(this.mc))
         {
            this.mc.stopAllMovieClips();
            this.mc = null;
         }
         this.speed = null;
         this.addSpeed = null;
         this.maxSpeed = null;
         this.minSpeed = null;
         this.hitSpeed = null;
         this.owner = null;
         this._area = null;
         this._orgScale = null;
         this._team = null;
         this._bulletArea = null;
         this._hitVO = null;
      }
      
      public function isDestoryed() : Boolean
      {
         return this._destoryed;
      }
      
      public function renderAnimate() : void
      {
         this.mc.nextFrame();
         var _loc1_:String = this.mc.currentLabel;
         switch(_loc1_)
         {
            case "loop":
               if(this._loopFrame == null)
               {
                  if(MCUtils.hasFrameLabel(this.mc,"loop_start"))
                  {
                     this._loopFrame = "loop_start";
                  }
                  else
                  {
                     this._loopFrame = 1;
                  }
               }
               this.mc.gotoAndStop(this._loopFrame);
               break;
            case "remove":
               this.removeSelf();
               break;
            case "hit_over":
               this._hitAble = false;
               break;
            default:
               if(this.mc.currentFrame == this.mc.totalFrames - 1)
               {
                  this.removeSelf();
               }
         }
      }
      
      public function render() : void
      {
         if(this._isHit)
         {
            return;
         }
         this.mc.x += this.speed.x * this._speedPlus;
         this.mc.y += this.speed.y * this._speedPlus;
         this.speed.x += this.addSpeed.x * this._speedPlus;
         this.speed.y += this.addSpeed.y * this._speedPlus;
         if(this._direct > 0)
         {
            if(this.speed.x > this.maxSpeed.x)
            {
               this.speed.x = this.maxSpeed.x;
            }
            if(this.speed.x < this.minSpeed.x)
            {
               this.speed.x = this.minSpeed.x;
            }
         }
         else
         {
            if(this.speed.x < -this.maxSpeed.x)
            {
               this.speed.x = -this.maxSpeed.x;
            }
            if(this.speed.x > -this.minSpeed.x)
            {
               this.speed.x = -this.minSpeed.x;
            }
         }
         if(this.speed.y > this.maxSpeed.y)
         {
            this.speed.y = this.maxSpeed.y;
         }
         if(this.speed.y < this.minSpeed.y)
         {
            this.speed.y = this.minSpeed.y;
         }
         if(this.holdFrame != -1 && !this._isTimeout)
         {
            --this.holdFrame;
            if(this.holdFrame <= 0)
            {
               if(!MCUtils.hasFrameLabel(this.mc,"timeout"))
               {
                  this.removeSelf();
                  return;
               }
               this._isTimeout = true;
               this.mc.gotoAndStop("timeout");
            }
         }
         if(GameLogic.isTouchBottomFloor(this))
         {
            this.hit(this._hitVO,null);
            EffectCtrl.I.shake(0,1,200);
            return;
         }
         if(GameLogic.isOutRange(this))
         {
            this.removeSelf();
         }
      }
      
      public function getDisplay() : DisplayObject
      {
         return this.mc;
      }
      
      private function removeSelf() : void
      {
         if(this.onRemove != null)
         {
            this.onRemove(this);
         }
      }
      
      private function doHit() : void
      {
         if(!this._isHit)
         {
            try
            {
               this.mc.gotoAndStop("hit");
            }
            catch(e:Error)
            {
               trace("Bullet",e);
            }
         }
         this._isHit = true;
         this._hitAble = false;
      }
      
      public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         if(param2 is Bullet)
         {
            if(!isNaN(this.hitSpeed.x))
            {
               this.speed.x = this.hitSpeed.x;
            }
            if(!isNaN(this.hitSpeed.y))
            {
               this.speed.y = this.hitSpeed.y;
            }
            return;
         }
         if(this.hitTimes != -1)
         {
            if(--this.hitTimes <= 0)
            {
               this.doHit();
            }
         }
         if(Boolean(param2) && Boolean(this.owner) && this.owner is FighterMain)
         {
            (this.owner as FighterMain).addQi(param1.power * 0.1);
            GameLogic.hitTarget(param1,this.owner,param2);
         }
         if(Boolean(param2))
         {
            if(this.hitSpeed.x == 0 && this.hitSpeed.y == 0)
            {
               return;
            }
            if(param2 is BaseGameSprite && Boolean((param2 as BaseGameSprite).getIsTouchSide()))
            {
               if(isNaN(this.hitSpeed.x))
               {
                  this.hitSpeed.x = this.speed.x;
               }
               if(isNaN(this.hitSpeed.y))
               {
                  this.hitSpeed.y = this.speed.y;
               }
               this.hitSpeed.x = Math.abs(this.hitSpeed.x) < 1 ? 0 : this.hitSpeed.x * 0.5;
               this.hitSpeed.y = Math.abs(this.hitSpeed.y) < 1 ? 0 : this.hitSpeed.y * 0.5;
            }
            if(!isNaN(this.hitSpeed.x))
            {
               this.speed.x = this.hitSpeed.x;
            }
            if(!isNaN(this.hitSpeed.y))
            {
               this.speed.y = this.hitSpeed.y;
            }
         }
      }
      
      public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
         if(Boolean(param1.owner) && param1.owner is Bullet)
         {
            this.hp -= (param1.owner as Bullet).hpMax;
         }
         else
         {
            this.hp -= param1.power;
         }
         if(this.hp <= 0)
         {
            this.doHit();
         }
      }
      
      public function getCurrentHits() : Array
      {
         if(!this._hitVO || !this._bulletArea || !this._hitAble)
         {
            return null;
         }
         this._hitVO.currentArea = this.getCurrentRect(this._bulletArea);
         return [this._hitVO];
      }
      
      public function getArea() : Rectangle
      {
         if(!this._bulletArea)
         {
            return null;
         }
         return this.getCurrentRect(this._bulletArea);
      }
      
      public function getBodyArea() : Rectangle
      {
         if(!this._bulletArea)
         {
            return null;
         }
         return this.getCurrentRect(this._bulletArea);
      }
      
      private function getCurrentRect(param1:Rectangle) : Rectangle
      {
         var _loc2_:Rectangle = this._currentRect;
         _loc2_.x = param1.x * this._direct + this.mc.x;
         if(this._direct < 0)
         {
            _loc2_.x -= param1.width;
         }
         _loc2_.y = param1.y + this.mc.y;
         _loc2_.width = param1.width;
         _loc2_.height = param1.height;
         return _loc2_;
      }
      
      public function allowCrossMapXY() : Boolean
      {
         return true;
      }
      
      public function allowCrossMapBottom() : Boolean
      {
         return false;
      }
      
      public function getIsTouchSide() : Boolean
      {
         return false;
      }
      
      public function setIsTouchSide(param1:Boolean) : void
      {
      }
   }
}

