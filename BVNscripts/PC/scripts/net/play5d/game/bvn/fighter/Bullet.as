package net.play5d.game.bvn.fighter
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.media.SoundTransform;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.utils.MCUtils;
   import net.play5d.kyo.utils.KyoUtils;
   
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
      
      public var owner:IGameSprite = null;
      
      public var orgPoint:Point;
      
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
      
      private var _effect:Object;
      
      private var _isActive:Boolean;
      
      private var _destoryed:Boolean;
      
      private var _direct:int;
      
      private var _currentRect:Rectangle = new Rectangle();
      
      private var _ownerDoingAction:Object = null;
      
      private var _colorTransform:ColorTransform;
      
      private var _renderFuncs:Vector.<Function>;
      
      private var _renderFuncsFps:Vector.<Function>;
      
      private var _renderFuncsGlobal:Vector.<Function>;
      
      public function Bullet(param1:MovieClip, param2:Object = null)
      {
         super();
         this.mc = param1;
         orgPoint = new Point(param1.x,param1.y);
         var _loc3_:Function = param1.initBullet;
         if(_loc3_ != null)
         {
            _loc3_(this);
         }
         _orgScale = new Point(param1.scaleX,param1.scaleY);
         _orgRotate = param1.rotation;
         if(param2)
         {
            if(param2.x)
            {
               if(param2.x is Number)
               {
                  speed.x = param2.x;
               }
               else
               {
                  if(param2.x.start != undefined)
                  {
                     speed.x = param2.x.start;
                  }
                  if(param2.x.add != undefined)
                  {
                     addSpeed.x = param2.x.add * 2;
                  }
                  if(param2.x.max != undefined)
                  {
                     maxSpeed.x = param2.x.max;
                  }
                  if(param2.x.min != undefined)
                  {
                     minSpeed.x = param2.x.min;
                  }
                  if(param2.x.hit != undefined)
                  {
                     hitSpeed.x = param2.x.hit;
                  }
               }
            }
            if(param2.y)
            {
               if(param2.y is Number)
               {
                  speed.y = param2.y;
               }
               else
               {
                  if(param2.y.start != undefined)
                  {
                     speed.y = param2.y.start;
                  }
                  if(param2.y.add != undefined)
                  {
                     addSpeed.y = param2.y.add * 2;
                  }
                  if(param2.y.max != undefined)
                  {
                     maxSpeed.y = param2.y.max;
                  }
                  if(param2.y.min != undefined)
                  {
                     minSpeed.y = param2.y.min;
                  }
                  if(param2.y.hit != undefined)
                  {
                     hitSpeed.y = param2.y.hit;
                  }
               }
            }
            if(param2.hold)
            {
               if(param2.hold == -1)
               {
                  holdFrame = -1;
               }
               else
               {
                  holdFrame = param2.hold * GameConfig.FPS_GAME;
               }
            }
            if(param2.hits)
            {
               hitTimes = param2.hits;
            }
            if(param2.hp)
            {
               hp = hpMax = param2.hp;
            }
            if(param2.effect)
            {
               _effect = param2.effect;
            }
         }
         start();
         GameRender.addAfter(renderRenderFuncsGlobal);
      }
      
      public function get colorTransform() : ColorTransform
      {
         return _colorTransform;
      }
      
      public function set colorTransform(param1:ColorTransform) : void
      {
         _colorTransform = param1;
         mc.transform.colorTransform = param1 ?? new ColorTransform();
      }
      
      public function getActive() : Boolean
      {
         return _isActive;
      }
      
      public function setActive(param1:Boolean) : void
      {
         _isActive = param1;
      }
      
      public function get x() : Number
      {
         if(mc == null)
         {
            return NaN;
         }
         return mc.x;
      }
      
      public function set x(param1:Number) : void
      {
         mc.x = param1;
      }
      
      public function get y() : Number
      {
         if(mc == null)
         {
            return NaN;
         }
         return mc.y;
      }
      
      public function set y(param1:Number) : void
      {
         mc.y = param1;
      }
      
      public function get team() : TeamVO
      {
         return _team;
      }
      
      public function set team(param1:TeamVO) : void
      {
         _team = param1;
      }
      
      public function get isAttacking() : Boolean
      {
         return _hitAble;
      }
      
      public function set isAttacking(param1:Boolean) : void
      {
         _hitAble = param1;
      }
      
      public function setSpeedRate(param1:Number) : void
      {
         _speedPlus = param1;
      }
      
      public function setVolume(param1:Number) : void
      {
         KyoUtils.setMcVolume(mc,param1);
      }
      
      public function get direct() : int
      {
         return _direct;
      }
      
      public function set direct(param1:int) : void
      {
         _direct = param1;
         mc.scaleX = _orgScale.x * _direct;
         mc.rotation = _orgRotate * _direct;
         mc.x *= _direct;
         speed.x *= param1;
         addSpeed.x *= param1;
         if(!isNaN(hitSpeed.x))
         {
            hitSpeed.x *= param1;
         }
      }
      
      public function setHitVO(param1:HitVO) : void
      {
         var _loc2_:FighterMC = null;
         owner = param1.owner;
         _hitVO = param1.clone();
         _hitVO.owner = this;
         updateBulletArea();
         direct = owner.direct;
         mc.x += owner.x;
         mc.y += owner.y;
         if(owner is FighterMain)
         {
            _loc2_ = (owner as FighterMain).getMC();
            mc.x += _loc2_.x;
            mc.y += _loc2_.y;
            _ownerDoingAction = (owner as FighterMain).getDoingAction();
         }
         else if(owner is FighterAttacker)
         {
            owner = (owner as FighterAttacker).getOwner();
         }
         else if(owner is Assister)
         {
            owner = (owner as Assister).getOwner();
         }
      }
      
      private function updateBulletArea() : void
      {
         var _loc1_:DisplayObject = mc.getChildByName("main");
         if(_loc1_ == null && _bulletArea != null)
         {
            return;
         }
         _loc1_ ||= mc;
         _bulletArea = _loc1_.getBounds(mc);
      }
      
      public function getDoingAction() : Object
      {
         return _ownerDoingAction;
      }
      
      public function destory(param1:Boolean = true) : void
      {
         _destoryed = true;
         if(_effect)
         {
            if(_effect.shadow)
            {
               EffectCtrl.I.endShadow(mc);
            }
            _effect = null;
         }
         if(mc)
         {
            try
            {
               mc.stopAllMovieClips();
               mc.removeChildren();
            }
            catch(e:Error)
            {
            }
            mc = null;
         }
         _renderFuncs = null;
         _renderFuncsFps = null;
         GameRender.removeAfter(renderRenderFuncsGlobal);
         _renderFuncsGlobal = null;
         speed = null;
         addSpeed = null;
         maxSpeed = null;
         minSpeed = null;
         hitSpeed = null;
         owner = null;
         _area = null;
         _orgScale = null;
         _team = null;
         _bulletArea = null;
         _hitVO = null;
      }
      
      public function isDestoryed() : Boolean
      {
         return _destoryed;
      }
      
      public function renderAnimate() : void
      {
         if(_destoryed)
         {
            return;
         }
         renderRenderFuncs();
         if(mc == null)
         {
            return;
         }
         mc.nextFrame();
         if(mc == null)
         {
            return;
         }
         renderAllChildren(mc);
         var _loc1_:String = mc.currentLabel;
         switch(_loc1_)
         {
            case "loop":
               if(_loopFrame == null)
               {
                  if(MCUtils.hasFrameLabel(mc,"loop_start"))
                  {
                     _loopFrame = "loop_start";
                  }
                  else
                  {
                     _loopFrame = 1;
                  }
               }
               mc.gotoAndStop(_loopFrame);
               break;
            case "remove":
               removeSelf();
               break;
            case "hit_over":
               _hitAble = false;
               break;
            default:
               if(mc.currentFrame == mc.totalFrames - 1)
               {
                  removeSelf();
               }
         }
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
         if(_isHit)
         {
            return;
         }
         mc.x += speed.x * _speedPlus;
         mc.y += speed.y * _speedPlus;
         speed.x += addSpeed.x * _speedPlus;
         speed.y += addSpeed.y * _speedPlus;
         if(_direct > 0)
         {
            if(speed.x > maxSpeed.x)
            {
               speed.x = maxSpeed.x;
            }
            if(speed.x < minSpeed.x)
            {
               speed.x = minSpeed.x;
            }
         }
         else
         {
            if(speed.x < -maxSpeed.x)
            {
               speed.x = -maxSpeed.x;
            }
            if(speed.x > -minSpeed.x)
            {
               speed.x = -minSpeed.x;
            }
         }
         if(speed.y > maxSpeed.y)
         {
            speed.y = maxSpeed.y;
         }
         if(speed.y < minSpeed.y)
         {
            speed.y = minSpeed.y;
         }
         if(holdFrame != -1 && !_isTimeout)
         {
            holdFrame = holdFrame - 1;
            if(holdFrame <= 0)
            {
               if(!MCUtils.hasFrameLabel(mc,"timeout"))
               {
                  removeSelf();
                  return;
               }
               _isTimeout = true;
               mc.gotoAndStop("timeout");
            }
         }
         if(GameLogic.isTouchBottomFloor(this))
         {
            hit(_hitVO,null);
            EffectCtrl.I.shake(0,1,200);
            return;
         }
         if(GameLogic.isOutRange(this))
         {
            removeSelf();
         }
         if(mc == null)
         {
            return;
         }
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
         return mc;
      }
      
      private function removeSelf() : void
      {
         if(onRemove != null)
         {
            onRemove(this);
         }
      }
      
      private function doHit() : void
      {
         if(!_isHit)
         {
            try
            {
               mc.gotoAndStop("hit");
            }
            catch(e:Error)
            {
            }
         }
         _isHit = true;
         _hitAble = false;
      }
      
      public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         if(param2 is Bullet)
         {
            if(!(param2 as Bullet).isAttacking)
            {
               return;
            }
            if(!isNaN(hitSpeed.x))
            {
               speed.x = hitSpeed.x;
            }
            if(!isNaN(hitSpeed.y))
            {
               speed.y = hitSpeed.y;
            }
            return;
         }
         if(_effect)
         {
            if(_effect.shadow)
            {
               EffectCtrl.I.endShadow(mc);
            }
         }
         if(hitTimes != -1)
         {
            if(--hitTimes <= 0)
            {
               doHit();
            }
         }
         if(param2 && owner && owner is FighterMain)
         {
            if(!param1.isBisha())
            {
               if(param2 == (owner as FighterMain).getCurrentTarget())
               {
                  (owner as FighterMain).addQi(param1.power * 0.1);
               }
            }
            GameLogic.hitTarget(param1,owner,param2);
         }
         if(param2)
         {
            if(hitSpeed.x == 0 && hitSpeed.y == 0)
            {
               return;
            }
            if(param2 is BaseGameSprite && (param2 as BaseGameSprite).getIsTouchSide())
            {
               if(isNaN(hitSpeed.x))
               {
                  hitSpeed.x = speed.x;
               }
               if(isNaN(hitSpeed.y))
               {
                  hitSpeed.y = speed.y;
               }
               hitSpeed.x = Math.abs(hitSpeed.x) < 1 ? 0 : hitSpeed.x * 0.5;
               hitSpeed.y = Math.abs(hitSpeed.y) < 1 ? 0 : hitSpeed.y * 0.5;
            }
            if(!isNaN(hitSpeed.x))
            {
               speed.x = hitSpeed.x;
            }
            if(!isNaN(hitSpeed.y))
            {
               speed.y = hitSpeed.y;
            }
         }
      }
      
      public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
         if(param1.onHit != null)
         {
            param1.onHit(this);
         }
         if(param1.owner && param1.owner is Bullet)
         {
            hp -= (param1.owner as Bullet).hpMax;
         }
         else
         {
            hp -= param1.getDamage() * 2;
         }
         if(hp <= 0)
         {
            doHit();
         }
      }
      
      public function getCurrentHits() : Array
      {
         if(!_hitVO || !_bulletArea || !_hitAble)
         {
            return null;
         }
         updateBulletArea();
         _hitVO.currentArea = getCurrentRect(_bulletArea);
         return [_hitVO];
      }
      
      public function getArea() : Rectangle
      {
         if(!_bulletArea)
         {
            return null;
         }
         updateBulletArea();
         return getCurrentRect(_bulletArea);
      }
      
      public function getBodyArea() : Rectangle
      {
         if(_bulletArea == null)
         {
            return null;
         }
         updateBulletArea();
         return getCurrentRect(_bulletArea);
      }
      
      private function getCurrentRect(param1:Rectangle) : Rectangle
      {
         var _loc13_:Number = param1.x;
         var _loc11_:Number = param1.y;
         var _loc10_:Number = param1.width;
         var _loc4_:Number = param1.height;
         var _loc6_:Matrix = mc.transform.matrix;
         var _loc12_:Point = _loc6_.transformPoint(new Point(_loc13_,_loc11_));
         var _loc14_:Point = _loc6_.transformPoint(new Point(_loc13_ + _loc10_,_loc11_));
         var _loc5_:Point = _loc6_.transformPoint(new Point(_loc13_,_loc11_ + _loc4_));
         var _loc7_:Point = _loc6_.transformPoint(new Point(_loc13_ + _loc10_,_loc11_ + _loc4_));
         var _loc9_:Number = Math.min(_loc12_.x,_loc14_.x,_loc5_.x,_loc7_.x);
         var _loc8_:Number = Math.min(_loc12_.y,_loc14_.y,_loc5_.y,_loc7_.y);
         var _loc3_:Number = Math.max(_loc12_.x,_loc14_.x,_loc5_.x,_loc7_.x);
         var _loc2_:Number = Math.max(_loc12_.y,_loc14_.y,_loc5_.y,_loc7_.y);
         _currentRect.x = _loc9_;
         _currentRect.y = _loc8_;
         _currentRect.width = _loc3_ - _loc9_;
         _currentRect.height = _loc2_ - _loc8_;
         return _currentRect;
      }
      
      public function allowCrossMapXY() : Boolean
      {
         return true;
      }
      
      public function allowCrossMapBottom() : Boolean
      {
         return false;
      }
      
      public function allowCrossFloor() : Boolean
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
      
      private function start() : void
      {
         var _loc1_:* = 0;
         var _loc3_:* = 0;
         var _loc2_:* = 0;
         if(_effect != null && _effect.shadow != null)
         {
            _loc1_ = uint(_effect.shadow[0] ? _effect.shadow[0] : 0);
            _loc3_ = uint(_effect.shadow[1] ? _effect.shadow[1] : 0);
            _loc2_ = uint(_effect.shadow[2] ? _effect.shadow[2] : 0);
            EffectCtrl.I.startShadow(mc,_loc1_,_loc3_,_loc2_);
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
            if(_loc4_ == null)
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
      }
      
      public function doInheritFunc(param1:BaseGameSprite) : void
      {
      }
   }
}

