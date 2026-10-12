package net.play5d.game.bvn.fighter.ctrler.ai
{
   import flash.display.*;
   import flash.geom.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   
   public class FighterAILogicBase
   {
      
      protected var AILevel:int;
      
      protected var _fighter:*;
      
      protected var _fighterAction:*;
      
      protected var _target:*;
      
      protected var _targetFighter:*;
      
      protected var _isConting:Boolean;
      
      private var _breakActCache:Object = {};
      
      private var _hitDownActCache:Object = {};
      
      private var _contOrder:Array = [];
      
      private var _AImain:MovieClip = null;
      
      /**
       * 是否为 CRAZY 档（设置项 AI_level = 7，菜单 "CRAZY"/"疯狂"）。
       *
       * 改造前 getAIResult() 的 switch 只有 case 0~5，等级 6（HELL）与 7（CRAZY）
       * 一起落进 default 分支读同一个 param6，两者行为完全相同，"疯狂"并不比"地狱"难。
       * 现在等级 6 显式走 case 6，等级 7 及以上走 default 读第 7 个参数 param7。
       *
       * 兼容性：概率表仍是 6 元素数组时，getAIByFighterState() 传回 NaN，
       * getAIResult() 会把 param7 回落成 param6 —— 即"没写第 7 列 = CRAZY 沿用 HELL"。
       * 因此只有显式补了第 7 列的决策点，CRAZY 才会与 HELL 分档；
       * 等级 1~6 的取值与改造前逐位一致。
       */
      protected function get isCrazy() : Boolean
      {
         return this.AILevel >= 7;
      }
      
      public function FighterAILogicBase(param1:int, param2:*)
      {
         super();
         this.AILevel = param1;
         this._fighter = param2;
      }
      
      public function destory() : void
      {
         this._fighter = null;
         this._fighterAction = null;
         this._target = null;
         this._targetFighter = null;
         this._breakActCache = null;
         this._hitDownActCache = null;
      }
      
      protected function addContOrder(param1:String, param2:int) : void
      {
         var _loc3_:int = int(this._contOrder.indexOf(param1));
         if(_loc3_ != -1)
         {
            this._contOrder[_loc3_].order = param2;
         }
         else
         {
            this._contOrder.push({
               "id":param1,
               "order":param2 + Math.floor(Math.random() * 10)
            });
         }
      }
      
      protected function updateConting() : void
      {
         this._isConting = this._fighter.actionState == 10 || this._fighter.actionState == 11 || this._fighter.actionState == 12 || this._fighter.actionState == 13;
      }
      
      public function render() : void
      {
         this._target = this._fighter.getCurrentTarget();
         this._targetFighter = this._target;
         this.updateConting();
         if(!this._fighterAction)
         {
            this._fighterAction = this._fighter.getCtrler().getMcCtrl().getAction();
         }
         this.updateActionAI();
         this.updateContOrder();
      }
      
      private function updateContOrder() : void
      {
         var _loc1_:int = 0;
         var _loc2_:* = null;
         if(this._contOrder.length < 1)
         {
            return;
         }
         this._contOrder.sortOn("order",2 | 0x10);
         _loc1_ = 1;
         while(_loc1_ < this._contOrder.length)
         {
            _loc2_ = this._contOrder[_loc1_].id;
            this[_loc2_] = false;
            _loc1_++;
         }
         this._contOrder = [];
      }
      
      protected function updateActionAI() : void
      {
      }
      
      protected function getAIByFighterState(param1:Object) : Boolean
      {
         var _loc2_:* = null;
         var _loc3_:Array = param1.defult;
         var _loc4_:int = int(this._targetFighter ? this._targetFighter.actionState : -1);
         _loc2_ = Boolean(param1) && Boolean(param1[_loc4_]) ? param1[_loc4_] : _loc3_;
         return this.getAIResult(_loc2_[0],_loc2_[1],_loc2_[2],_loc2_[3],_loc2_[4],_loc2_[5],_loc2_.length > 6 ? Number(_loc2_[6]) : NaN);
      }
      
      /**
       * 概率表取档。param1~param6 依次对应 AI 等级 1~6 的触发概率（取值域 0~10，
       * 每帧重掷一次 0~10 的随机数），param7 是新增的 CRAZY（等级 7 及以上）列。
       *
       * param7 省略或 NaN 时回落为 param6，保证未补第 7 列的调用点行为不变。
       */
      protected function getAIResult(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number, param7:Number = NaN) : Boolean
      {
         var _loc7_:Number = Math.random() * 10;
         if(isNaN(param7))
         {
            param7 = param6;
         }
         switch(int(this.AILevel))
         {
            case 0:
            case 1:
               return _loc7_ < param1;
            case 2:
               return _loc7_ < param2;
            case 3:
               return _loc7_ < param3;
            case 4:
               return _loc7_ < param4;
            case 5:
               return _loc7_ < param5;
            case 6:
               return _loc7_ < param6;
            default:
               return _loc7_ < param7;
         }
      }
      
      protected function getTargetDistance(param1:*) : Point
      {
         var _loc2_:Number = Math.abs(param1.x - this._fighter.x);
         var _loc3_:Number = Math.abs(param1.y - this._fighter.y);
         return new Point(_loc2_,_loc3_);
      }
      
      protected function targetInDistance(param1:*, param2:Number, param3:Number) : Boolean
      {
         var _loc4_:Point = null;
         _loc4_ = this.getTargetDistance(param1);
         return _loc4_.x <= param2 && _loc4_.y <= param3;
      }
      
      protected function targetInRange(param1:String) : Boolean
      {
         var _loc2_:Rectangle = this._target.getBodyArea();
         if(!_loc2_)
         {
            return false;
         }
         var _loc3_:Rectangle = this._fighter.getHitRange(param1);
         if(!_loc3_)
         {
            return false;
         }
         return _loc2_.intersection(_loc3_).isEmpty() == false;
      }
      
      protected function get AImain() : MovieClip
      {
         if(Boolean(this._AImain))
         {
            return this._AImain;
         }
         var fighterMC:* = this._fighter.getMC();
         if(!fighterMC)
         {
            return null;
         }
         return this._AImain = fighterMC.getChildByName("AImain") as MovieClip;
      }
      
      protected function setAIByMain(param1:Object, param2:String) : void
      {
         var currentAI:Object = null;
         var i:Object = null;
         if(Boolean(this.AImain) && Boolean(this.AImain.getActionAI) && !!(currentAI = this.AImain.getActionAI(param2)))
         {
            for(i in currentAI)
            {
               param1[i] = currentAI[i];
            }
         }
      }
      
      protected function mergeRateObject(param1:Object, param2:Object) : void
      {
         var _loc3_:* = undefined;
         var _loc4_:int = 0;
         for(_loc3_ in param2)
         {
            if(param1[_loc3_] == undefined)
            {
               param1[_loc3_] = param2[_loc3_];
            }
            else
            {
               // _loc4_ 必须按每个 key 复位：原先只在函数开头初始化一次，
               // 第二个 key 起会带着上一个 key 的越界下标继续比对，等于漏比前几档。
               _loc4_ = 0;
               while(_loc4_ < param2[_loc3_].length)
               {
                  if(param1[_loc3_][_loc4_] < param2[_loc3_][_loc4_])
                  {
                     param1[_loc3_][_loc4_] = param2[_loc3_][_loc4_];
                  }
                  _loc4_++;
               }
            }
         }
      }
      
      protected function isBreakAct(param1:String) : Boolean
      {
         var _loc2_:* = undefined;
         if(this._breakActCache[param1] != undefined)
         {
            return this._breakActCache[param1];
         }
         var _loc3_:Vector.<*> = this._fighter.getCtrler().hitModel.getHitVOLike(param1);
         for each(_loc2_ in _loc3_)
         {
            if(Boolean(_loc2_.isBreakDef))
            {
               this._breakActCache[param1] = true;
               return true;
            }
         }
         this._breakActCache[param1] = false;
         return false;
      }
      
      protected function isHitDownAct(param1:String) : Boolean
      {
         var _loc2_:* = undefined;
         if(this._hitDownActCache[param1] != undefined)
         {
            return this._hitDownActCache[param1];
         }
         var _loc3_:Vector.<*> = this._fighter.getCtrler().hitModel.getHitVOLike(param1);
         for each(_loc2_ in _loc3_)
         {
            if(_loc2_.hurtType == 1)
            {
               this._hitDownActCache[param1] = true;
               return true;
            }
         }
         this._hitDownActCache[param1] = false;
         return false;
      }
      
      protected function targetCanBeHit() : Boolean
      {
         if(!this._target)
         {
            return false;
         }
         if(Boolean(this._targetFighter))
         {
            return this._targetFighter.isAllowBeHit;
         }
         return this._target.getBodyArea() != null;
      }
      
      /**
       * CRAZY 档使用的命中判定（targetCanBeHit() 的修正版）。
       *
       * 为什么不能直接复用 targetCanBeHit()：
       * isAllowBeHit 声明在 BaseGameSprite.as:23（`public var isAllowBeHit:Boolean = true;`），
       * Assister / FighterAttacker 都 extends BaseGameSprite 因而继承该字段且默认为 true；
       * 只有 Bullet 是 `implements IGameSprite`，没有这个字段。
       *
       * 而本工程 render() 里写的是 `this._targetFighter = this._target;`
       * （3.7 参考工程写的是 `this._targetFighter = this._target as FighterMain;`，
       * 主项目少了那个类型转换）。于是当目标是 Bullet 时 _targetFighter 也非 null，
       * targetCanBeHit() 会走进 `_targetFighter.isAllowBeHit` 分支取到 undefined，
       * Boolean(undefined) 为 false ⇒ 该目标被误判成"不可命中"。
       *
       * 这里按参考工程的语义补回 FighterMain 类型判断：只有目标确实是 FighterMain 时才看
       * 无敌帧 isAllowBeHit，其余目标退回"有身体判定框即可打"。
       *
       * 量级说明：FighterMain.getCurrentTarget() 的择优顺序把存活的 FighterMain 排在最前
       * （FighterMain.as:222 order 0），且 Bullet 不是 TeamVO 的子节点，所以正常对局里
       * _target 几乎总是对方 FighterMain，本方法与 targetCanBeHit() 的实际差别只会在
       * "当前目标退化为 Bullet"这种边缘情况下体现。写成本方法是为了语义与参考工程一致，
       * 不是因为现网经常踩到。
       *
       * 刻意不改 targetCanBeHit() 本身：它还被 updateCache() 的投技判定使用，
       * 改掉会连带改变 HELL 及以下等级的行为，违背"等级 1~6 不变"的约束。
       */
      protected function canHitTarget() : Boolean
      {
         if(!this._target)
         {
            return false;
         }
         if(this._targetFighter is FighterMain)
         {
            return this._targetFighter.isAllowBeHit;
         }
         return this._target.getBodyArea() != null;
      }
   }
}

