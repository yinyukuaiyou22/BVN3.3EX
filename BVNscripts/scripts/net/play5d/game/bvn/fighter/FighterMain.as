package net.play5d.game.bvn.fighter
{
   import flash.display.MovieClip;
   import flash.geom.*;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
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
      
      /** 拼招判定压制剩余帧：窗口内自身与攻击体的判定一律失效（防止「输了还打中」）。 */
      private var _clashGuardFrame:int = 0;
      
      /** 本帧是否已参与过拼招裁决（帧号，-1 = 未参与），保证每角色每帧最多一次。 */
      public var clashResolvedFrame:int = -1;

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
      
      /** 2026-10-27：气/能量条推进异常的“只记一次”标记（避免每帧刷屏） */
      private var _energyErrLogged:Boolean = false;
      
      private var _replaceSkillFrame:int;
      
      /** 换人模式(TAG)：切出无敌的剩余帧数（在 renderAnimate 里递减，单位 = 30Hz 帧） */
      private var _tagInvincibleFrame:int = 0;
      
      /** 换人无敌闪烁：暗态透明度与半周期帧数（30Hz 下 4 帧 ≈ 每秒闪 3.75 次） */
      private static const TAG_BLINK_ALPHA:Number = 0.45;
      private static const TAG_BLINK_FRAME:int = 4;
      
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
         // 换人模式(TAG)：后备角色会被预先初始化，之后 addFighter 换回来时又会调一次 initlize，
         // 必须幂等 —— 否则每次换人都新建一套 FighterCtrler/FighterBuffCtrler，旧控制链泄漏且
         // 旧 MC 上的 ctrler 引用全部失效。
         if(Boolean(this._fighterCtrl))
         {
            return;
         }
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
         if(this._clashGuardFrame > 0)
         {
            --this._clashGuardFrame;
         }
         // 2026-10-27：这两行排在三个计时器之前，任何一处抛异常都会把「僵直 / 钢体 / 换人无敌」
         // 一起停摆 —— 正是历史上 render/renderAnimate 共用 try 的那个坑（见 CLAUDE.md 受击状态机）。
         // 单独兜底并只记一次，保证计时器永远能推进。
         try
         {
            this.renderEnergy();
            this.renderFzQi();
         }
         catch(eEnergy:Error)
         {
            if(!this._energyErrLogged)
            {
               this._energyErrLogged = true;
               try { Debugger.log("FIGHTER_ENERGY_ERR id=" + this.id + " :", eEnergy); } catch(_e:Error) {}
            }
         }
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
         // 换人无敌窗口：**不再改写 isAllowBeHit**。
         // 该标志只在「状态切换」时被控制器赋值（dash/dashStop/idle/doAction…），并不每帧刷新；
         // 我们若强制写 false，窗口结束后没有任何人写回 true ⇒ 角色只要不进入新状态就永久不可被打
         // （实测：切人后站着不动就一直无敌，一移动/出招才恢复）。
         // 现在换人无敌改用 TAG 自己的谓词（tagInvincibleFrame），由 checkHit 读取。
         if(this._tagInvincibleFrame > 0)
         {
            --this._tagInvincibleFrame;
            // 2026-10-30 用户定：无敌期用透明度闪烁表示，「不闪了就等于无敌结束」。
            this.updateTagInvincibleBlink();
            if(this._tagInvincibleFrame <= 0)
            {
               this.clearTagInvincible();
            }
         }
      }
      
      /**
       * 换人无敌的透明度闪烁：每 TAG_BLINK_FRAME 个 animate 帧切换一次 alpha。
       * 只改显示对象自身的 alpha，不碰判定；闪烁只在 renderAnimate 的 30Hz 节奏上跑。
       */
      private function updateTagInvincibleBlink() : void
      {
         var _loc1_:* = this.getDisplay();
         if(!Boolean(_loc1_))
         {
            return;
         }
         var _loc2_:int = int(this._tagInvincibleFrame / TAG_BLINK_FRAME);
         try
         {
            _loc1_.alpha = _loc2_ % 2 == 0 ? TAG_BLINK_ALPHA : 1;
         }
         catch(eBlink:Error)
         {
         }
      }
      
      /**
       * 清掉换人无敌：计时归零 + 透明度恢复 1。
       * 换下/离场/重开都必须走这里，否则"闪到一半被换下"会留下永久半透明的角色。
       */
      public function clearTagInvincible() : void
      {
         this._tagInvincibleFrame = 0;
         var _loc1_:* = this.getDisplay();
         if(!Boolean(_loc1_))
         {
            return;
         }
         try
         {
            _loc1_.alpha = 1;
         }
         catch(eClear:Error)
         {
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
         if(this._clashGuardFrame > 0)
         {
            return null;
         }
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
         if(this.fzqi < this.fzqiMax)
         {
            // 换人模式(TAG)：辅助槽兼作换人槽，回复速度用 TAG_FUZHU_ADD_PERFRAME（0.8/帧 ≈ 4.2 秒满）
            this.fzqi += GameMode.isTagMode() ? GameConfig.TAG_FUZHU_ADD_PERFRAME : GameConfig.FUZHU_QU_ADD_PERFRAME;
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
      private function getMcCtrler() : FighterMcCtrler
      {
         return Boolean(this._fighterCtrl) ? this._fighterCtrl.getMcCtrl() : null;
      }
      
      public function grantClashLink() : void
      {
         var _loc1_:FighterMcCtrler = this.getMcCtrler();
         if(_loc1_ != null)
         {
            _loc1_.grantClashLink();
         }
      }
      
      public function doClashGuard(param1:HitVO, param2:Rectangle) : void
      {
         var _loc3_:FighterMcCtrler = this.getMcCtrler();
         if(_loc3_ != null)
         {
            _loc3_.doClashGuard(param1,param2);
         }
      }
      
      public function doClashRecoil(param1:FighterMain, param2:Rectangle, param3:HitVO) : void
      {
         var _loc4_:FighterMcCtrler = this.getMcCtrler();
         if(_loc4_ != null)
         {
            _loc4_.doClashRecoil(param1,param2,param3);
         }
      }
      
      public function lockClashGuard(param1:int) : void
      {
         if(param1 > this._clashGuardFrame)
         {
            this._clashGuardFrame = param1;
         }
      }
      
      public function isClashGuardLocked() : Boolean
      {
         return this._clashGuardFrame > 0;
      }
      
      public function getActionStartFrame() : int
      {
         if(!this._fighterCtrl)
         {
            return 0;
         }
         var _loc1_:FighterMcCtrler = this._fighterCtrl.getMcCtrl();
         return _loc1_ != null ? _loc1_.getActionStartFrame() : 0;
      }
      
      /** 回合重置 / 离场 / 重开：清掉拼招纽带窗口与判定压制，别把状态带进下一场。 */
      public function resetClashState() : void
      {
         this._clashGuardFrame = 0;
         this.clashResolvedFrame = -1;
         if(Boolean(this._fighterCtrl))
         {
            var _loc1_:FighterMcCtrler = this._fighterCtrl.getMcCtrl();
            if(_loc1_ != null)
            {
               _loc1_.clearClashLink();
            }
         }
      }
      
      public function resetExplodeState() : void
      {
         this.resetClashState();
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
         this.clearTagInvincible();
         this._explodeHitVO = null;
      }
      
      /**
       * 换人模式(TAG)：切出角色无敌。
       * param1 的单位是 renderAnimate 的帧（30Hz）—— 1 秒要传 1 * GameConfig.FPS_ANIMATE（=30），
       * 不能用 FPS_GAME（60fps 下那样会变成 2 倍时长）。
       *
       * 注意：这里**不再**写 `isAllowBeHit = false`。那个标志只在状态切换时被控制器赋值，
       * 窗口结束后无人复位 ⇒ 会把角色永久锁成"不可被打"。无敌判定改由 checkHit 读
       * `tagInvincibleFrame`（本类自己的谓词），与共享标志解耦。
       */
      public function startTagInvincible(param1:int) : void
      {
         this._tagInvincibleFrame = param1;
         // 立刻进入暗态：闪烁本身就是"无敌中"的提示，不能等下一帧才开始
         this.updateTagInvincibleBlink();
         Debugger.log("[TAG] 切出无敌 id=" + this.id + " frames=" + param1);
      }
      
      public function get tagInvincibleFrame() : int
      {
         return this._tagInvincibleFrame;
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
