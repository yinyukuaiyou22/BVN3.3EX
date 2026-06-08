package net.play5d.game.bvn.fighter
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.fighter.ctrler.*;
   import net.play5d.game.bvn.fighter.models.FighterHitModel;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.fighter.utils.*;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class FighterAttacker extends BaseGameSprite
   {
      
      public var onRemove:Function;
      
      public var isAttacking:Boolean;
      
      private var _ctrler:FighterAttackerCtrler;
      
      private var _owner:IGameSprite;
      
      public var moveToTargetX:Boolean;
      
      public var moveToTargetY:Boolean;
      
      public var followTargetX:Boolean;
      
      public var followTargetY:Boolean;
      
      public var rangeX:Point;
      
      public var rangeY:Point;
      
      private var _startX:Number = 0;
      
      private var _startY:Number = 0;
      
      private var _hitAreaCache:McAreaCacher = new McAreaCacher("hit");
      
      private var _hitCheckAreaCache:McAreaCacher = new McAreaCacher("hit_check");
      
      private var _rectCache:Object = {};
      
      private var _mcOrgPoint:Point;
      
      private var _isRenderMainAnimate:Boolean = true;
      
      public function FighterAttacker(param1:MovieClip, param2:Object = null)
      {
         super(param1);
         this._mcOrgPoint = new Point(param1.x,param1.y);
         this._startX = this._mcOrgPoint.x;
         this._startY = this._mcOrgPoint.y;
         _x = this._startX;
         _y = this._startY;
         this._ctrler = new FighterAttackerCtrler(this);
         if(Boolean(param1.setAttackerCtrler))
         {
            param1.setAttackerCtrler(this._ctrler);
         }
         if(Boolean(param2))
         {
            if(param2.x != undefined)
            {
               if(param2.x is Number)
               {
                  this._startX = param2.x + this._mcOrgPoint.x;
               }
               else
               {
                  this.moveToTargetX = param2.x.moveToTarget == true;
                  this.followTargetX = param2.x.followTarget == true;
                  if(param2.x.offset != undefined)
                  {
                     this._startX = param2.x.offset;
                  }
                  if(param2.x.range != undefined && param2.x.range is Array)
                  {
                     this.rangeX = new Point(param2.x.range[0],param2.x.range[1]);
                  }
               }
            }
            if(param2.y != undefined)
            {
               if(param2.y is Number)
               {
                  this._startY = param2.y + this._mcOrgPoint.y;
               }
               else
               {
                  this.moveToTargetY = param2.y.moveToTarget == true;
                  this.followTargetY = param2.y.followTarget == true;
                  if(param2.y.offset != undefined)
                  {
                     this._startY = param2.y.offset;
                  }
                  if(param2.y.range != undefined && param2.y.range is Array)
                  {
                     this.rangeY = new Point(param2.y.range[0],param2.y.range[1]);
                  }
               }
            }
            if(param2.applyG != undefined)
            {
               isApplyG = param2.applyG == true;
            }
         }
      }
      
      public function getOwner() : IGameSprite
      {
         return this._owner;
      }
      
      public function get name() : String
      {
         return _mainMc.name;
      }
      
      public function getCtrler() : FighterAttackerCtrler
      {
         return this._ctrler;
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         if(Boolean(this._hitAreaCache))
         {
            this._hitAreaCache.destory();
            this._hitAreaCache = null;
         }
         if(Boolean(this._hitCheckAreaCache))
         {
            this._hitCheckAreaCache.destory();
            this._hitCheckAreaCache = null;
         }
         if(Boolean(this._ctrler))
         {
            this._ctrler.destory();
            this._ctrler = null;
         }
         this._rectCache = null;
         this._owner = null;
         this._mcOrgPoint = null;
         super.destory(true);
      }
      
      public function setOwner(param1:IGameSprite) : void
      {
         this._owner = param1;
         direct = param1.direct;
         if(this._owner is FighterMain)
         {
            this._ctrler.effect = (this._owner as FighterMain).getCtrler().getEffectCtrl();
         }
         if(this._owner is Assister)
         {
            this._ctrler.effect = (this._owner as Assister).getCtrler().effect;
         }
      }
      
      public function init() : void
      {
         var _loc1_:FighterMC = null;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         if(!this._owner)
         {
            return;
         }
         if(direct > 0)
         {
            _x = this._owner.x + this._startX;
         }
         else
         {
            _x = this._owner.x - this._startX;
         }
         _y += this._owner.y;
         if(this._owner is FighterMain)
         {
            _loc1_ = (this._owner as FighterMain).getMC();
            _x += _loc1_.x;
            _y += _loc1_.y;
         }
         if(!this.moveToTargetX && !this.moveToTargetY)
         {
            return;
         }
         var _loc6_:IGameSprite = this.getTarget();
         if(Boolean(_loc6_))
         {
            if(this.moveToTargetX)
            {
               _loc2_ = _loc6_.x + this._startX * direct;
               if(Boolean(this.rangeX))
               {
                  if(direct > 0)
                  {
                     _loc3_ = _loc2_ - this._owner.x;
                     if(_loc3_ < this.rangeX.x)
                     {
                        _loc2_ = this._owner.x + this.rangeX.x;
                     }
                     if(_loc3_ > this.rangeX.y)
                     {
                        _loc2_ = this._owner.x + this.rangeX.y;
                     }
                  }
                  else
                  {
                     _loc3_ = this._owner.x - _loc2_;
                     if(_loc3_ < this.rangeX.x)
                     {
                        _loc2_ = this._owner.x - this.rangeX.x;
                     }
                     if(_loc3_ > this.rangeX.y)
                     {
                        _loc2_ = this._owner.x - this.rangeX.y;
                     }
                  }
               }
               _x = _loc2_;
            }
            if(this.moveToTargetY)
            {
               _loc4_ = _loc6_.y + this._startY;
               if(Boolean(this.rangeY))
               {
                  _loc5_ = _loc4_ - this._owner.y;
                  if(_loc5_ < this.rangeY.x)
                  {
                     _loc4_ = _loc6_.y + this.rangeY.x;
                  }
                  if(_loc5_ > this.rangeY.y)
                  {
                     _loc4_ = _loc6_.y + this.rangeY.y;
                  }
               }
               _y = _loc4_;
            }
         }
         this.isAttacking = true;
      }
      
      override public function renderAnimate() : void
      {
         if(!this._isRenderMainAnimate)
         {
            return;
         }
         super.renderAnimate();
         mc.nextFrame();
         this.findHitArea();
         if(mc.currentFrame == mc.totalFrames - 1)
         {
            this.removeSelf();
         }
      }
      
      override public function render() : void
      {
         super.render();
         this._ctrler.render();
         this.renderFollowTarget();
      }
      
      public function stopFollowTarget() : void
      {
         this.followTargetX = false;
         this.followTargetY = false;
      }
      
      private function renderFollowTarget() : void
      {
         if(!this.followTargetX && !this.followTargetY)
         {
            return;
         }
         var _loc1_:IGameSprite = this.getTarget();
         if(!_loc1_)
         {
            return;
         }
         if(this.followTargetX)
         {
            _x = _loc1_.x + this._startX * direct;
         }
         if(this.followTargetY)
         {
            _y = _loc1_.y + this._startY;
         }
      }
      
      public function moveToTarget(param1:Number = NaN, param2:Number = NaN) : void
      {
         var _loc3_:IGameSprite = this.getTarget();
         if(!_loc3_)
         {
            return;
         }
         if(!isNaN(param1))
         {
            _x = _loc3_.x + param1 * direct;
         }
         if(!isNaN(param2))
         {
            _y = _loc3_.y + param2;
         }
      }
      
      public function stop() : void
      {
         this._isRenderMainAnimate = false;
      }
      
      public function gotoAndPlay(param1:String) : void
      {
         _mainMc.gotoAndStop(param1);
         this._isRenderMainAnimate = true;
      }
      
      public function gotoAndStop(param1:String) : void
      {
         _mainMc.gotoAndStop(param1);
         this._isRenderMainAnimate = false;
      }
      
      public function getTargets() : Vector.<IGameSprite>
      {
         if(this._owner is FighterMain)
         {
            return (this._owner as FighterMain).getTargets();
         }
         if(this._owner is Assister)
         {
            return (this._owner as Assister).getTargets();
         }
         return null;
      }
      
      private function getTarget() : IGameSprite
      {
         if(this._owner is FighterMain)
         {
            return (this._owner as FighterMain).getCurrentTarget();
         }
         if(this._owner is Assister)
         {
            return (this._owner as Assister).getCurrentTarget();
         }
         return null;
      }
      
      public function removeSelf() : void
      {
         if(this.onRemove != null)
         {
            this.onRemove(this);
         }
      }
      
      override public function getCurrentHits() : Array
      {
         var _loc1_:int = 0;
         var _loc2_:Object = null;
         var _loc3_:HitVO = null;
         var _loc4_:* = null;
         var _loc5_:Rectangle = null;
         var _loc6_:String = null;
         if(!this._hitAreaCache)
         {
            return null;
         }
         var _loc7_:Array = this._hitAreaCache.getAreaByFrame(_mainMc.currentFrame) as Array;
         if(!_loc7_ || _loc7_.length < 1)
         {
            return null;
         }
         var _loc8_:Array = [];
         while(_loc1_ < _loc7_.length)
         {
            _loc2_ = _loc7_[_loc1_];
            _loc6_ = _loc2_.name;
            _loc3_ = _loc2_.hitVO;
            if(Boolean(_loc3_))
            {
               _loc5_ = _loc2_.area;
               _loc3_.currentArea = this.getCurrentRect(_loc5_,"hit" + _loc1_);
               _loc8_.push(_loc3_);
            }
            _loc1_++;
         }
         return _loc8_;
      }
      
      public function getHitCheckRect(param1:String) : Rectangle
      {
         var _loc2_:Rectangle = this.getCheckHitRect(param1);
         if(_loc2_ == null)
         {
            return null;
         }
         return this.getCurrentRect(_loc2_,"hit_check");
      }
      
      public function getCheckHitRect(param1:String) : Rectangle
      {
         var _loc2_:DisplayObject = _mainMc.getChildByName(param1);
         if(!_loc2_)
         {
            return null;
         }
         var _loc3_:Object = this._hitCheckAreaCache.getAreaByDisplay(_loc2_);
         if(Boolean(_loc3_))
         {
            return _loc3_.area;
         }
         var _loc4_:Rectangle = _loc2_.getBounds(_mainMc);
         this._hitCheckAreaCache.cacheAreaByDisplay(_loc2_,_loc4_);
         return _loc4_;
      }
      
      private function getCurrentRect(param1:Rectangle, param2:String = null) : Rectangle
      {
         var _loc3_:Rectangle = null;
         if(param2 == null)
         {
            _loc3_ = new Rectangle();
         }
         else if(Boolean(this._rectCache[param2]))
         {
            _loc3_ = this._rectCache[param2];
         }
         else
         {
            _loc3_ = new Rectangle();
            this._rectCache[param2] = _loc3_;
         }
         _loc3_.x = param1.x * direct + _x;
         if(direct < 0)
         {
            _loc3_.x -= param1.width;
         }
         _loc3_.y = param1.y + _y;
         _loc3_.width = param1.width;
         _loc3_.height = param1.height;
         return _loc3_;
      }
      
      private function getHitModel() : FighterHitModel
      {
         if(this._owner is FighterMain)
         {
            return (this._owner as FighterMain).getCtrler().hitModel;
         }
         if(this._owner is Assister)
         {
            return (this._owner as Assister).getCtrler().hitModel;
         }
         throw new Error("不支持的owner类型!");
      }
      
      private function findHitArea() : void
      {
         var _loc1_:int = 0;
         var _loc2_:DisplayObject = null;
         var _loc3_:HitVO = null;
         var _loc4_:Object = null;
         var _loc5_:Rectangle = null;
         var _loc6_:Object = null;
         if(!this._hitAreaCache)
         {
            return;
         }
         var _loc7_:FighterHitModel = this.getHitModel();
         if(!_loc7_)
         {
            return;
         }
         if(this._hitAreaCache.areaFrameDefined(_mainMc.currentFrame))
         {
            return;
         }
         var _loc8_:Object = this._hitAreaCache.getAreaByFrame(_mainMc.currentFrame);
         if(_loc8_ != null)
         {
            return;
         }
         var _loc9_:Array = [];
         while(_loc1_ < _mainMc.numChildren)
         {
            _loc2_ = _mainMc.getChildAt(_loc1_);
            _loc3_ = _loc7_.getHitVOByDisplayName(_loc2_.name);
            if(!(_loc2_ == null || _loc3_ == null))
            {
               _loc4_ = this._hitAreaCache.getAreaByDisplay(_loc2_);
               if(_loc4_ == null)
               {
                  _loc5_ = _loc2_.getBounds(_mainMc);
                  _loc6_ = this._hitAreaCache.cacheAreaByDisplay(_loc2_,_loc5_,{"hitVO":_loc3_});
                  _loc9_.push(_loc6_);
               }
               else
               {
                  _loc9_.push(_loc4_);
               }
            }
            _loc1_++;
         }
         if(_loc9_.length < 1)
         {
            _loc9_ = null;
         }
         this._hitAreaCache.cacheAreaByFrame(_mainMc.currentFrame,_loc9_);
      }
      
      private function getOwnerFighter() : FighterMain
      {
         if(this._owner is FighterMain)
         {
            return this._owner as FighterMain;
         }
         if(this._owner is Assister)
         {
            return (this._owner as Assister).getOwner() as FighterMain;
         }
         return null;
      }
      
      override public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         var _loc3_:Number = NaN;
         var _loc4_:FighterMain = this.getOwnerFighter();
         if(Boolean(param2) && Boolean(_loc4_))
         {
            _loc3_ = this._owner is Assister ? 0.15 : 0.13;
            _loc4_.addQi(param1.power * _loc3_);
            GameLogic.hitTarget(param1,_loc4_,param2);
         }
      }
   }
}

