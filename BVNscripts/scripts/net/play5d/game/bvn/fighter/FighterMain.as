package net.play5d.game.bvn.fighter
{
   import flash.display.MovieClip;
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.TeamVO;
   import net.play5d.game.bvn.fighter.ctrler.*;
   import net.play5d.game.bvn.fighter.models.*;
   import net.play5d.game.bvn.interfaces.*;
import net.play5d.game.bvn.Debugger;
   
   public class FighterMain extends BaseGameSprite
   {
      
       // 2026-09-09 竞技规则移植：初始气量由设置 initialQi 决定（fork 默认 100）
       public var qi:Number = GameData.I.config.initialQi;
      
      public const qiMax:Number = 300;
      
      public var energy:Number = 100;
      
      public var energyMax:Number = 100;
      
      public var energyOverLoad:Boolean = false;
      
      public var customHpMax:int = 0;
      
      public var fzqi:Number = 100;
      
      public const fzqiMax:Number = 100;
      
      public var speed:Number = 6;
      
      public var jumpPower:Number = 15;
      
      public var isSteelBody:Boolean = false;
      
      public var isSuperSteelBody:Boolean = false;
      
      public var data:FighterVO;

      public var initFailed:Boolean = false;
      
      public var airHitTimes:int = 1;
      
      public var jumpTimes:int = 2;
      
      public var actionState:int = 0;
      
      public var defenseType:int = 0;
      
      public var lastHitVO:HitVO;
      
      private var _buffCtrler:FighterBuffCtrler;
      
      private var _currentHurts:Vector.<HitVO>;
      
      public var hurtHit:HitVO;
      
      public var defenseHit:HitVO;
      
      public var targetTeams:Vector.<TeamVO>;
      
      private var _currentTarget:IGameSprite;
      
      private var _fighterCtrl:FighterCtrler;
      
      private var _energyAddGap:int;
      
      private var _explodeHitVO:HitVO;
      
      private var _explodeHitFrame:int;
      
      private var _explodeSteelFrame:int;
      
      // 2026-10-21 卡死修复：灵爆窗口的幂等标记与钢体看门狗（详见 renderAnimate）
      private var _explodeIdled:Boolean = false;
      
      private var _explodeSteelWatchdog:int = 0;
      
      private var _animErrLogged:Boolean = false;
      
      private var _replaceSkillFrame:int;
      
      private var _speedBack:Number = 0;
      
      private var _colorTransform:ColorTransform;
      
      public function FighterMain(param1:MovieClip)
      {
         super(param1);
         _area = null;
      }
      
      public function get colorTransform() : ColorTransform
      {
         return this._colorTransform;
      }
      
      public function set colorTransform(param1:ColorTransform) : void
      {
         this._colorTransform = param1;
         _mainMc.transform.colorTransform = param1 ? param1 : new ColorTransform();
      }
      
      public function changeColor(param1:ColorTransform) : void
      {
         _mainMc.transform.colorTransform = param1;
      }
      
      public function resumeColor() : void
      {
         _mainMc.transform.colorTransform = this._colorTransform ? this._colorTransform : new ColorTransform();
      }
      
      override public function destory(param1:Boolean = true) : void
      {
         if(!param1)
         {
            return;
         }
         // 2026-10-21：先解除金身辉光并清掉灵爆窗口。
         // 角色若在灵爆 60 帧窗口（或替身术 30 帧）内被换人/KO，会先被移出 gameState 的渲染列表，
         // renderAnimate 不再驱动 -> 计数器永久冻结 -> setSteelBody(false) 永不执行 ->
         // GlowFilter 对应的 BitmapFilterView（独立 game sprite）会留下一尊永久的黄色残像。
         this.resetExplodeState();
         this.isAllowBeHit = false;
         if(Boolean(this._fighterCtrl))
         {
            this._fighterCtrl.destory();
            this._fighterCtrl = null;
         }
         if(Boolean(_mainMc))
         {
            _mainMc.filters = null;
            _mainMc.gotoAndStop(1);
         }
         if(Boolean(this._buffCtrler))
         {
            this._buffCtrler.destory();
            this._buffCtrler = null;
         }
         this.targetTeams = null;
         this._currentTarget = null;
         this._currentHurts = null;
         super.destory(param1);
      }
      
      override public function set attackRate(param1:Number) : void
      {
         super.attackRate = param1;
         if(Boolean(this._fighterCtrl) && Boolean(this._fighterCtrl.hitModel))
         {
            this._fighterCtrl.hitModel.setPowerRate(param1);
         }
      }
      
      public function currentHurtDamage() : int
      {
         var _loc1_:* = undefined;
         if(!this._currentHurts)
         {
            return 0;
         }
         var _loc2_:int = 0;
         for each(_loc1_ in this._currentHurts)
         {
            _loc2_ += _loc1_.getDamage();
         }
         return _loc2_;
      }
      
      public function getLastHurtHitVO() : HitVO
      {
         if(!this._currentHurts)
         {
            return null;
         }
         return this._currentHurts[this._currentHurts.length - 1];
      }
      
      public function hurtBreakHit() : Boolean
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in this._currentHurts)
         {
            if(Boolean(_loc1_.isBreakDef))
            {
               return true;
            }
         }
         return false;
      }
      
      public function clearHurtHits() : void
      {
         this._currentHurts = null;
      }
      
      public function getCtrler() : FighterCtrler
      {
         return this._fighterCtrl;
      }
      
      public function getBuffCtrl() : FighterBuffCtrler
      {
         return this._buffCtrler;
      }
      
      public function getCurrentTarget() : IGameSprite
      {
         var _loc1_:* = undefined;
         if(Boolean(this._currentTarget))
         {
            if(this._currentTarget is BaseGameSprite && Boolean((this._currentTarget as BaseGameSprite).isAlive))
            {
               return this._currentTarget;
            }
         }
         var _loc2_:Vector.<IGameSprite> = this.getTargets();
         var _loc3_:Array = [];
         if(Boolean(_loc2_) && _loc2_.length > 0)
         {
            for each(_loc1_ in _loc2_)
            {
               if(_loc1_.getBodyArea() == null)
               {
                  _loc3_.push({
                     "fighter":_loc1_,
                     "order":5
                  });
               }
               else if(_loc1_ is FighterMain && Boolean((_loc1_ as FighterMain).isAlive))
               {
                  _loc3_.push({
                     "fighter":_loc1_,
                     "order":0
                  });
               }
               else if(_loc1_ is BaseGameSprite && Boolean((_loc1_ as BaseGameSprite).isAlive))
               {
                  _loc3_.push({
                     "fighter":_loc1_,
                     "order":1
                  });
               }
               else
               {
                  _loc3_.push({
                     "fighter":_loc1_,
                     "order":2
                  });
               }
            }
            _loc3_.sortOn("order",16);
            this._currentTarget = _loc3_[0].fighter;
         }
         return this._currentTarget;
      }
      
      public function getTargets() : Vector.<IGameSprite>
      {
         var _loc1_:int = 0;
         if(!this.targetTeams || this.targetTeams.length < 1)
         {
            return null;
         }
         var _loc2_:Vector.<IGameSprite> = new Vector.<IGameSprite>();
         while(_loc1_ < this.targetTeams.length)
         {
            _loc2_ = _loc2_.concat(this.targetTeams[_loc1_].getAliveChildren());
            _loc1_++;
         }
         return _loc2_;
      }
      
      public function getMC() : FighterMC
      {
         if(!this._fighterCtrl)
         {
            return null;
         }
         if(!this._fighterCtrl.getMcCtrl())
         {
            return null;
         }
         return this._fighterCtrl.getMcCtrl().getFighterMc();
      }
      
      public function setActionCtrl(param1:IFighterActionCtrl) : void
      {
         if(Boolean(this._fighterCtrl))
         {
            this._fighterCtrl.setActionCtrl(param1);
            param1.initlize();
         }
      }
      
      public function initlize() : void
      {
         this._fighterCtrl = new FighterCtrler();
         if(Boolean(_mainMc.setFighterCtrler))
         {
            _mainMc.setFighterCtrler(this._fighterCtrl);
            this._fighterCtrl.initFighter(this);
            this._buffCtrler = new FighterBuffCtrler(this);
            _mainMc.gotoAndStop(this.data ? this.data.startFrame + 1 : 2);
            return;
         }
         // —— 3.6+ 新式 main_mc 人物包兼容:无 setFighterCtrler 但有 initFighter({...}) 单函数注入 ——
         if(Boolean(_mainMc.initFighter))
         {
            this._fighterCtrl.initFighter(this);
            this._buffCtrler = new FighterBuffCtrler(this);
            _mainMc.gotoAndStop(this.data ? this.data.startFrame + 1 : 2);
            return;
         }
         this.initFailed = true;
         if(Boolean(_mainMc.setAssistCtrler))
         {
            Debugger.log("[FighterMain] 配置错误：该角色SWF是辅助(含setAssistCtrler)，不应作为人物加载: " + (this.data ? this.data.id : "unknown"));
         }
         else
         {
            Debugger.log("[FighterMain] 此角色不可用 — SWF缺少setFighterCtrler/initFighter: " + (this.data ? this.data.id : "unknown"));
         }
      }
      
      override public function renderAnimate() : void
      {
         super.renderAnimate();
         if(_destoryed)
         {
            return;
         }
         this.renderEnergy();
         this.renderFzQi();
         if(Boolean(this._fighterCtrl))
         {
            // 2026-10-21：控制器动画链单独兜底。它内部会走到 renderHurtAnimate / idle / MC 子元件推进，
            // 任何一处抛异常都会把下面三个计时器一起跳过 —— 那正是「永久受击 + 永久金身」的成因。
            // 这里保证：即使控制器链崩了，灵爆窗口照样按帧推进、照样能自行结束。
            try
            {
               this._fighterCtrl.renderAnimate();
            }
            catch(e:Error)
            {
               if(!this._animErrLogged)
               {
                  this._animErrLogged = true;
                  try { Debugger.log("FIGHTER_ANIM_ERR id=" + this.id + " :", e, e.getStackTrace()); } catch(_e:Error) {}
               }
            }
         }
         if(this._explodeHitFrame > 0)
         {
            if(Debugger.DIAG_HURT)
            {
               try { Debugger.log("【灵压爆发】id=" + this.id + " _explodeHitFrame(递减前)=" + (this._explodeHitFrame + 1) + " _explodeSteelFrame=" + this._explodeSteelFrame + " isAllowBeHit=" + isAllowBeHit + " actionState=" + this.actionState); } catch (e:Error) {}
            }
            --this._explodeHitFrame;
            // 2026-10-21：原来是 ==8 的等值门，一旦该计数器被跳过（render 抛异常等）就永远不回 idle()。
            // 改成「<=8 且未走过」的幂等门：无论中间漏了几帧，都会补一次恢复。
            if(this._explodeHitFrame <= 8 && !this._explodeIdled)
            {
               this._explodeIdled = true;
               try { this.idle(); } catch(e:Error) { try { Debugger.log("【灵爆 idle 异常】id=" + this.id + " :", e); } catch(_e:Error) {} }
               isAllowBeHit = false;
            }
            if(this._explodeHitFrame <= 0)
            {
               this._explodeHitVO = null;
               isAllowBeHit = true;
            }
         }
         if(this._explodeSteelFrame > 0)
         {
            --this._explodeSteelFrame;
            // 2026-10-21：钢体看门狗。正常 60 帧（约 2s）结束；若因为任何原因越界超时，
            // 强制解除金身并在日志里留痕（这条是低频判据，不受 DIAG_HURT 控制）。
            ++this._explodeSteelWatchdog;
            var mcCtrl:FighterMcCtrler = Boolean(this._fighterCtrl) ? this._fighterCtrl.getMcCtrl() : null;
            if(this._explodeSteelWatchdog > 150 || !mcCtrl)
            {
               try { Debugger.log("【钢体看门狗】强制解除金身 id=" + this.id + " 已过帧=" + this._explodeSteelWatchdog + " 剩余=" + this._explodeSteelFrame + " mcCtrl=" + (mcCtrl ? "ok" : "null")); } catch (e:Error) {}
               this._explodeSteelFrame = 0;
               this._explodeSteelWatchdog = 0;
               if(Boolean(mcCtrl))
               {
                  mcCtrl.setSteelBody(false);
               }
            }
            else
            {
               mcCtrl.setSteelBody(true,true);
               if(this._explodeSteelFrame <= 0)
               {
                  this._explodeSteelWatchdog = 0;
                  mcCtrl.setSteelBody(false);
               }
            }
         }
         else
         {
            this._explodeSteelWatchdog = 0;
         }
         if(this._replaceSkillFrame > 0)
         {
            --this._replaceSkillFrame;
            if(this._replaceSkillFrame <= 0)
            {
               isAllowBeHit = true;
            }
         }
      }
      
      override public function render() : void
      {
         super.render();
         if(_destoryed)
         {
            return;
         }
         if(Boolean(this._fighterCtrl))
         {
            this._fighterCtrl.render();
         }
         if(Boolean(this._buffCtrler))
         {
            this._buffCtrler.render();
         }
         if(hp < 0)
         {
            hp = 0;
         }
         if(hp > hpMax)
         {
            hp = hpMax;
         }
         if(this.qi < 0)
         {
            this.qi = 0;
         }
         if(this.qi > 300)
         {
            this.qi = 300;
         }
         if(this.fzqi < 0)
         {
            this.fzqi = 0;
         }
         if(this.fzqi > 100)
         {
            this.fzqi = 100;
         }
      }
      
      public function jump() : void
      {
         _g = 0;
         setVelocity(0,-this.jumpPower);
         setDamping(0,0.5);
      }
      
      override public function getCurrentHits() : Array
      {
         if(Boolean(this._explodeHitVO) && this._explodeHitFrame < 8)
         {
            return [this._explodeHitVO];
         }
         return this._fighterCtrl.getCurrentHits();
      }
      
      override public function getBodyArea() : Rectangle
      {
         if(!this._fighterCtrl)
         {
            return null;
         }
         return this._fighterCtrl.getBodyArea();
      }
      
      override public function hit(param1:HitVO, param2:IGameSprite) : void
      {
         super.hit(param1,param2);
         this.lastHitVO = param1;
         var _loc3_:* = 0;
         if(param2 is FighterMain)
         {
            if(param1.isBisha())
            {
               _loc3_ = Number(param1.power * 0);
            }
            else
            {
               _loc3_ = Number(param1.power * 0.17);
            }
            if(_loc3_ > 15)
            {
               _loc3_ = 15;
            }
         }
         this.addQi(_loc3_);
         GameLogic.hitTarget(param1,this,param2);
      }
      
      override public function beHit(param1:HitVO, param2:Rectangle = null) : void
      {
         if(!isAllowBeHit)
         {
            return;
         }
         super.beHit(param1,param2);
         this._fighterCtrl.getMcCtrl().beHit(param1,param2);
         var _loc3_:* = Number(param1.power * 0.08);
         if(_loc3_ > 20)
         {
            _loc3_ = 20;
         }
         this.addQi(_loc3_);
         if(this.actionState == 21 || this.actionState == 22)
         {
            if(!this._currentHurts)
            {
               this._currentHurts = new Vector.<HitVO>();
            }
            this._currentHurts.push(param1);
         }
      }
      
      private function renderEnergy() : void
      {
         if(this._energyAddGap > 0)
         {
            --this._energyAddGap;
            return;
         }
         if(this.energy < this.energyMax)
         {
            if(this.energyOverLoad)
            {
               this.energy += 0.6;
               if(this.energy > 30)
               {
                  this.energyOverLoad = false;
               }
            }
            else if(this.actionState == 20)
            {
               this.energy += 0.8;
            }
            else if(FighterActionState.isAttacking(this.actionState))
            {
               this.energy += 1.1;
            }
            else
            {
               this.energy += 2;
            }
         }
      }
      
      private function renderFzQi() : void
      {
         if(this.fzqi < 100)
         {
            this.fzqi += 0.2;
         }
      }
      
      public function hasEnergy(param1:Number, param2:Boolean = false) : Boolean
      {
         if(this.energy >= param1)
         {
            return true;
         }
         if(param2)
         {
            if(!this.energyOverLoad)
            {
               return true;
            }
         }
         return false;
      }
      
      public function useEnergy(param1:Number) : void
      {
         this.energy -= param1;
         this._energyAddGap = 0.8 * 30;
         if(this.energy < 0)
         {
            this.energy = 0;
            this.energyOverLoad = true;
         }
      }
      
      public function useQi(param1:Number) : Boolean
      {
         if(this.qi < param1)
         {
            return false;
         }
         this.qi -= param1;
         return true;
      }
      
      public function addQi(param1:Number) : void
      {
         this.qi += param1;
         if(this.qi > 300)
         {
            this.qi = 300;
         }
      }
      
      public function sayIntro() : void
      {
         this._fighterCtrl.getMcCtrl().sayIntro();
      }
      
      public function win() : void
      {
         this._fighterCtrl.getMcCtrl().doWin();
      }
      
      public function idle() : void
      {
         this._fighterCtrl.getMcCtrl().idle();
      }
      
      public function lose() : void
      {
         this._fighterCtrl.getMcCtrl().doLose();
      }
      
      public function getHitRange(param1:String) : Rectangle
      {
         return this._fighterCtrl.getHitRange(param1);
      }
      
      public function energyExplode() : void
      {
         this._fighterCtrl.getEffectCtrl().energyExplode();
         this._fighterCtrl.getMcCtrl().setSteelBody(true,true);
         this._explodeHitVO = new HitVO();
         var _loc1_:Rectangle = new Rectangle(-100,-200,200,210);
         this._explodeHitVO.currentArea = this._fighterCtrl.getCurrentRect(_loc1_);
         this._explodeHitVO.power = 50;
         this._explodeHitVO.hitx = 15 * direct;
         this._explodeHitVO.hitType = 5;
         this._explodeHitVO.hurtType = 1;
         this._explodeHitFrame = 10;
         this._explodeSteelFrame = 60;
         this._explodeIdled = false;
         this._explodeSteelWatchdog = 0;
         isAllowBeHit = false;
      }
      
      public function get explodeSteelFrame() : int
      {
         return this._explodeSteelFrame;
      }
      
      /** 2026-10-21：灵爆的「命中判定窗口」帧数（安全网用它当门控，替代原来的 explodeSteelFrame） */
      public function get explodeHitFrame() : int
      {
         return this._explodeHitFrame;
      }
      
      /**
       * 2026-10-21：解除金身辉光并清空灵爆/替身术窗口。
       * 供 destory() 与「把角色移出渲染列表」的路径调用 —— 计数器只靠 renderAnimate() 递减，
       * 一旦角色不再被渲染，setSteelBody(false) 就永远等不到，辉光会以独立 sprite 的形式永久残留。
       */
      public function resetExplodeState() : void
      {
         // 注意：endGlow() 会走到 EffectCtrl.endFilter -> GameCtrl.removeGameSprite -> gameState，
         // 而 GameCtrl.destory() 是先置空 gameState 再 destoryFighters()，此时解辉光会 #1009。
         // 这里吞掉即可：角色都要销毁了，残留的 BitmapFilterView 会随 GameState 一起被回收。
         if(Boolean(this._fighterCtrl) && Boolean(this._fighterCtrl.getMcCtrl()))
         {
            try { this._fighterCtrl.getMcCtrl().setSteelBody(false); } catch(e:Error) {}
         }
         this._explodeHitFrame = 0;
         this._explodeSteelFrame = 0;
         this._explodeSteelWatchdog = 0;
         this._explodeIdled = false;
         this._replaceSkillFrame = 0;
         this._explodeHitVO = null;
      }
      
      public function replaceSkill() : void
      {
         this._fighterCtrl.getEffectCtrl().replaceSkill();
         move(250 * direct);
         this.idle();
         isAllowBeHit = false;
         super.render();
         this.renderAnimate();
         this._fighterCtrl.setDirectToTarget();
         this._replaceSkillFrame = 30;
      }
      
      override public function getArea() : Rectangle
      {
         if(!_area)
         {
            _area = this.getBodyArea();
         }
         return _area;
      }
      
      public function hasWankai() : Boolean
      {
         var mc:FighterMC = this.getMC();
         if(!mc)
         {
            return false;
         }
         return mc.checkFrame("万解");
      }
      
      public function die() : void
      {
         hp = 0;
         isAlive = false;
         if(!FighterActionState.isHurting(this.actionState) && this.actionState != 30)
         {
            var mc:FighterMC = this.getMC();
            if(mc)
            {
               mc.playHurtDown();
            }
         }
      }
      
      public function relive() : void
      {
         isAlive = true;
         this.idle();
      }
      
      // 2026-09-09 竞技规则移植：防重复连依赖——暴露当前动作快照（fork 3.3竞技项 同名方法）
      public function getDoingAction() : Object
      {
         if(!this._fighterCtrl || !this._fighterCtrl.getMcCtrl() || !this.getMC() || !this.data)
         {
            return null;
         }
         return {
            "action":this.getMC().currentFrameName + "_" + this.getMC().getCurrentFrame().toString() + "_" + this.data.id,
            "times":this._fighterCtrl.getMcCtrl().doActionTimes
         };
      }
   }
}
