package net.play5d.game.bvn.fighter
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.fighter.ctrler.AssisiterCtrler;
   import net.play5d.game.bvn.fighter.models.FighterHitModel;
   import net.play5d.game.bvn.fighter.models.HitVO;
   import net.play5d.game.bvn.fighter.utils.McAreaCacher;
   import net.play5d.game.bvn.interfaces.BaseGameSprite;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class Assister extends BaseGameSprite
   {
      
      public var enable:Boolean = true;
      
      public var useFzqi:Boolean = true;
      
      public var orgPos:Point = new Point(-30,0);
      
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
      
      public function Assister(param1:MovieClip, param2:IGameSprite)
      {
         super(param1);
         isAlive = false;
         var _loc3_:Function = _mainMc.setAssistCtrler as Function;
         if(_loc3_ == null)
         {
            throw new Error("Assister :: 辅助未定义setAssistCtrler()！");
         }
         _owner = param2;
         _ctrler = new AssisiterCtrler();
         _ctrler.initAssister(this);
         _loc3_(_ctrler);
      }
      
      public function getCurrentLabel() : String
      {
         return _mainMc.currentLabel;
      }
      
      public function get name() : String
      {
         return _mainMc.name;
      }
      
      public function getOwner() : IGameSprite
      {
         return _owner;
      }
      
      public function setOwner(param1:IGameSprite) : void
      {
         _owner = param1;
      }
      
      public function getCtrler() : AssisiterCtrler
      {
         return _ctrler;
      }
      
      public function goFight() : void
      {
         _renderFuncs = null;
         _renderFuncsFps = null;
         isAttacking = true;
         gotoAndPlay(2);
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         if(!param1)
         {
            return;
         }
         if(_hitAreaCache)
         {
            _hitAreaCache.destory();
            _hitAreaCache = null;
         }
         if(_hitCheckAreaCache)
         {
            _hitCheckAreaCache.destory();
            _hitCheckAreaCache = null;
         }
         if(_ctrler)
         {
            _ctrler.destory();
            _ctrler = null;
         }
         data = null;
         _rectCache = null;
         _mcOrgPoint = null;
         _owner = null;
         onRemove = null;
         super.destory(param1);
      }
      
      public function stop() : void
      {
         _isRenderMainAnimate = false;
      }
      
      public function gotoAndPlay(param1:Object) : void
      {
         _mainMc.gotoAndStop(param1);
         _isRenderMainAnimate = true;
      }
      
      public function gotoAndStop(param1:Object) : void
      {
         _mainMc.gotoAndStop(param1);
         _isRenderMainAnimate = false;
      }
      
      public function getTargets() : Vector.<IGameSprite>
      {
         if(!_owner is FighterMain)
         {
            return null;
         }
         return (_owner as FighterMain).getTargets();
      }
      
      public function removeSelf() : void
      {
         isAttacking = false;
         isAlive = false;
         if(onRemove != null)
         {
            onRemove(this);
         }
      }
      
      override public function render() : void
      {
         super.render();
         _ctrler.render();
      }
      
      override public function renderAnimate() : void
      {
         if(!_isRenderMainAnimate || mc == null)
         {
            return;
         }
         super.renderAnimate();
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
         findAImain();
         findHitArea();
         if(mc.currentFrame == mc.totalFrames - 1)
         {
            _ctrler.finish(true);
         }
      }
      
      public function getHitCheckRect(param1:String) : Rectangle
      {
         var _loc2_:Rectangle = getCheckHitRect(param1);
         if(_loc2_ == null)
         {
            return null;
         }
         return getCurrentRect(_loc2_,"hit_check");
      }
      
      public function getCheckHitRect(param1:String) : Rectangle
      {
         var _loc2_:DisplayObject = _mainMc.getChildByName(param1);
         if(!_loc2_)
         {
            return null;
         }
         var _loc3_:Object = _hitCheckAreaCache.getAreaByDisplay(_loc2_);
         if(_loc3_ != null)
         {
            return _loc3_.area;
         }
         var _loc4_:Rectangle = _loc2_.getBounds(_mainMc);
         _hitCheckAreaCache.cacheAreaByDisplay(_loc2_,_loc4_);
         return _loc4_;
      }
      
      public function getCurrentRect(param1:Rectangle, param2:String = null) : Rectangle
      {
         var _loc3_:* = null;
         if(param2 == null)
         {
            _loc3_ = new Rectangle();
         }
         else if(_rectCache[param2])
         {
            _loc3_ = _rectCache[param2];
         }
         else
         {
            _loc3_ = new Rectangle();
            _rectCache[param2] = _loc3_;
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
         var _loc6_:int = 0;
         var _loc4_:DisplayObject = null;
         var _loc8_:HitVO = null;
         var _loc5_:Object = null;
         var _loc9_:Rectangle = null;
         var _loc3_:Object = null;
         if(!_hitAreaCache)
         {
            return;
         }
         var _loc7_:FighterHitModel = _ctrler.hitModel;
         if(_loc7_ == null)
         {
            return;
         }
         if(_hitAreaCache.areaFrameDefined(_mainMc.currentFrame))
         {
            return;
         }
         var _loc1_:Object = _hitAreaCache.getAreaByFrame(_mainMc.currentFrame);
         if(_loc1_ != null)
         {
            return;
         }
         var _loc2_:Array = [];
         _loc6_ = 0;
         while(_loc6_ < _mainMc.numChildren)
         {
            _loc4_ = _mainMc.getChildAt(_loc6_);
            _loc8_ = _loc7_.getHitVO(_loc4_.name);
            if(!(_loc4_ == null || _loc8_ == null))
            {
               _loc5_ = _hitAreaCache.getAreaByDisplay(_loc4_);
               if(_loc5_ == null)
               {
                  _loc9_ = _loc4_.getBounds(_mainMc);
                  _loc3_ = _hitAreaCache.cacheAreaByDisplay(_loc4_,_loc9_,{"hitVO":_loc8_});
                  _loc2_.push(_loc3_);
               }
               else
               {
                  _loc2_.push(_loc5_);
               }
            }
            _loc6_++;
         }
         if(_loc2_.length < 1)
         {
            _loc2_ = null;
         }
         _hitAreaCache.cacheAreaByFrame(_mainMc.currentFrame,_loc2_);
      }
      
      private function findAImain() : void
      {
         var _loc5_:int = 0;
         var _loc3_:DisplayObject = null;
         var _loc1_:MovieClip = null;
         var _loc4_:FighterMC = (_owner as FighterMain).getMC();
         var _loc6_:Rectangle = _loc4_.getHitRange("assistmian");
         if(_loc6_ != null)
         {
            return;
         }
         var _loc2_:Boolean = false;
         _loc5_ = 0;
         while(_loc5_ < _mainMc.numChildren)
         {
            _loc3_ = _mainMc.getChildAt(_loc5_);
            if(_loc3_.name == "assistmian")
            {
               _loc1_ = _loc4_.getChildByName("AImain") as MovieClip;
               _loc3_.x -= 31;
               _loc3_.y += 24;
               _loc1_.gotoAndStop(2);
               _loc1_.addChildAt(_loc3_,0);
               _loc1_.gotoAndStop(1);
               _loc2_ = true;
               break;
            }
            _loc5_++;
         }
         _loc4_.initAssisterHitRange(_loc2_);
      }
      
      override public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         if(param2 && _owner is FighterMain)
         {
            if(param2 == _ctrler.getTarget())
            {
               (_owner as FighterMain).addQi(param1.power * 0.15);
            }
            GameLogic.hitTarget(param1,_owner,param2);
         }
      }
      
      override public function getCurrentHits() : Array
      {
         var _loc5_:int = 0;
         var _loc7_:Object = null;
         var _loc4_:HitVO = null;
         var _loc2_:Rectangle = null;
         if(!_hitAreaCache)
         {
            return null;
         }
         var _loc6_:Array = _hitAreaCache.getAreaByFrame(_mainMc.currentFrame) as Array;
         if(_loc6_ == null || _loc6_.length < 1)
         {
            return null;
         }
         var _loc1_:Array = [];
         var _loc3_:int = int(_loc6_.length);
         _loc5_ = 0;
         while(_loc5_ < _loc3_)
         {
            _loc7_ = _loc6_[_loc5_];
            _loc4_ = (_loc7_.hitVO as HitVO).clone();
            if(_loc4_)
            {
               _loc2_ = _loc7_.area;
               _loc4_.currentArea = getCurrentRect(_loc2_,"hit" + _loc5_);
               _loc1_.push(_loc4_);
            }
            _loc5_++;
         }
         return _loc1_;
      }
      
      public function getCurrentTarget() : IGameSprite
      {
         if(_owner is FighterMain)
         {
            return (_owner as FighterMain).getCurrentTarget();
         }
         return null;
      }
   }
}

