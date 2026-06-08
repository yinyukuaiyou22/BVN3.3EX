package net.play5d.game.bvn.fighter
{
   import flash.display.*;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.fighter.ctrler.*;
   import net.play5d.game.bvn.fighter.models.FighterHitModel;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.fighter.utils.*;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class Assister extends BaseGameSprite
   {
      
      public var onRemove:Function;
      
      public var data:FighterVO;
      
      public var isAttacking:Boolean;
      
      private var _hitAreaCache:McAreaCacher = new McAreaCacher("hit");
      
      private var _hitCheckAreaCache:McAreaCacher = new McAreaCacher("hit_check");
      
      private var _rectCache:Object = {};
      
      private var _mcOrgPoint:Point;
      
      private var _owner:IGameSprite;
      
      private var _isRenderMainAnimate:Boolean = true;
      
      private var _ctrler:AssisiterCtrler;
      
      public function Assister(param1:MovieClip)
      {
         super(param1);
         isAlive = false;
         if(Boolean(_mainMc.setAssistCtrler))
         {
            this._ctrler = new AssisiterCtrler();
            this._ctrler.initAssister(this);
            _mainMc.setAssistCtrler(this._ctrler);
            return;
         }
         throw new Error("初始化失败，SWF未定义setAssistCtrler()");
      }
      
      public function get name() : String
      {
         return _mainMc.name;
      }
      
      public function getOwner() : IGameSprite
      {
         return this._owner;
      }
      
      public function setOwner(param1:IGameSprite) : void
      {
         this._owner = param1;
      }
      
      public function getCtrler() : AssisiterCtrler
      {
         return this._ctrler;
      }
      
      public function goFight() : void
      {
         this.gotoAndPlay(2);
         this.isAttacking = true;
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         if(!param1)
         {
            return;
         }
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
         this.data = null;
         this._rectCache = null;
         this._mcOrgPoint = null;
         this._owner = null;
         super.destory(param1);
      }
      
      public function stop() : void
      {
         this._isRenderMainAnimate = false;
      }
      
      public function gotoAndPlay(param1:Object) : void
      {
         _mainMc.gotoAndStop(param1);
         this._isRenderMainAnimate = true;
      }
      
      public function gotoAndStop(param1:Object) : void
      {
         _mainMc.gotoAndStop(param1);
         this._isRenderMainAnimate = false;
      }
      
      public function getTargets() : Vector.<IGameSprite>
      {
         if(!this._owner is FighterMain)
         {
            return null;
         }
         return (this._owner as FighterMain).getTargets();
      }
      
      public function removeSelf() : void
      {
         this.isAttacking = false;
         isAlive = false;
         if(this.onRemove != null)
         {
            this.onRemove(this);
         }
      }
      
      override public function render() : void
      {
         super.render();
         this._ctrler.render();
      }
      
      override public function renderAnimate() : void
      {
         if(!this._isRenderMainAnimate)
         {
            return;
         }
         super.renderAnimate();
         this.renderChildren();
         mc.nextFrame();
         this.findHitArea();
         if(mc.currentFrame == mc.totalFrames - 1)
         {
            this._ctrler.finish(true);
         }
      }
      
      private function renderChildren() : void
      {
         var _loc5_:* = undefined;
         var _loc1_:int = 0;
         var _loc2_:MovieClip = null;
         var _loc3_:String = null;
         var _loc4_:int = 0;
         while(_loc1_ < _mainMc.numChildren)
         {
            _loc2_ = _mainMc.getChildAt(_loc1_) as MovieClip;
            if(Boolean(_loc2_))
            {
               _loc3_ = _loc2_.name;
               if(!(_loc3_ == "bdmn" || _loc3_.indexOf("atm") != -1))
               {
                  _loc4_ = _loc2_.totalFrames;
                  if(_loc4_ >= 2)
                  {
                     _loc5_ = _loc2_.currentFrameLabel;
                     if("stop" !== _loc5_)
                     {
                        if(_loc2_.currentFrame == _loc4_)
                        {
                           _loc2_.gotoAndStop(1);
                        }
                        else
                        {
                           _loc2_.nextFrame();
                        }
                     }
                  }
               }
            }
            _loc1_++;
         }
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
         if(this._hitAreaCache.areaFrameDefined(_mainMc.currentFrame))
         {
            return;
         }
         var _loc7_:Object = this._hitAreaCache.getAreaByFrame(_mainMc.currentFrame);
         if(_loc7_ != null)
         {
            return;
         }
         var _loc8_:FighterHitModel = this._ctrler.hitModel;
         var _loc9_:Array = [];
         while(_loc1_ < _mainMc.numChildren)
         {
            _loc2_ = _mainMc.getChildAt(_loc1_);
            _loc3_ = _loc8_.getHitVO(_loc2_.name);
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
      
      override public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         if(Boolean(param2) && Boolean(this._owner) && this._owner is FighterMain)
         {
            (this._owner as FighterMain).addQi(param1.power * 0.15);
            GameLogic.hitTarget(param1,this._owner,param2);
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
      
      public function getCurrentTarget() : IGameSprite
      {
         if(this._owner is FighterMain)
         {
            return (this._owner as FighterMain).getCurrentTarget();
         }
         return null;
      }
   }
}

