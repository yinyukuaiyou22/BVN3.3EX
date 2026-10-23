package net.play5d.game.bvn.views.filter
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Stage;
   import flash.geom.Rectangle;
   import flash.events.Event;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import net.play5d.game.bvn.Debugger;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.EffectCtrl;

   /**
    * 滤镜位图代理的管理器：扫描 / 注册 / 每帧驱动 / 预算 / 自愈。
    *
    * 驱动挂在本类自建的 stage.ENTER_FRAME 上，并用**极低优先级**注册，
    * 保证排在 GameRender 的渲染回调之后 —— 否则读到的是上一帧的 x/y，
    * 快速移动时代理位图会和角色差一帧。
    */
   public class FilterProxyManager
   {
      private static var _i:FilterProxyManager;

      public static function get I() : FilterProxyManager
      {
         if(_i == null)
         {
            _i = new FilterProxyManager();
         }
         return _i;
      }

      private const _roots:Vector.<DisplayObjectContainer> = new Vector.<DisplayObjectContainer>();
      private const _proxies:Dictionary = new Dictionary(true);
      private const _order:Vector.<FilterNodeProxy> = new Vector.<FilterNodeProxy>();
      /** 首次烘焙队列（FIFO）。与 _order 语义分开：_order 是"已接管显示的稳态代理" */
      private const _pending:Vector.<FilterNodeProxy> = new Vector.<FilterNodeProxy>();
      private const _blocked:Dictionary = new Dictionary(true);
      private const _excluded:Dictionary = new Dictionary(true);
      private const _stackNode:Vector.<DisplayObject> = new Vector.<DisplayObject>();
      private const _stackDepth:Vector.<int> = new Vector.<int>();

      private var _pool:BitmapDataPool = new BitmapDataPool(24,32);
      private var _stage:Stage;
      private var _frame:int = 0;
      private var _lastFullScan:int = -100000;
      private var _paused:Boolean = false;
      private var _maxDepth:int = 5;
      private var _qCap:int = 3;
      private var _statBakes:int = 0;
      private var _statSkips:int = 0;
      private var _warnedLimit:Boolean = false;
      private var _scanSeen:int = 0;
      private var _dumpSeq:int = 0;
      private var _dumpDir:String = "/storage/emulated/0/Android/media/air.com.bvn.yy798/fproxy";
      private var _scanHit:int = 0;

      public function FilterProxyManager()
      {
         super();
         this._maxDepth = GameConfig.FPROXY_MAX_DEPTH;
         this._qCap = GameConfig.FPROXY_BLUR_QUALITY_CAP;
      }

      // ------------------------------------------------------------------ 根

      public function registerRoot(param1:DisplayObjectContainer) : void
      {
         if(param1 == null || this._roots.indexOf(param1) >= 0)
         {
            return;
         }
         this._roots.push(param1);
         this._lastFullScan = -100000;
         this.hookStage(param1);
         Debugger.log("[FPROXY] registerRoot " + describe(param1)
                      + " stage=" + (param1.stage != null)
                      + " depth=" + this._maxDepth + " maxProxies=" + GameConfig.FPROXY_MAX_PROXIES);
      }

      public function unregisterRoot(param1:DisplayObjectContainer) : void
      {
         var idx:int = this._roots.indexOf(param1);
         if(idx >= 0)
         {
            this._roots.splice(idx,1);
         }
         if(this._roots.length == 0)
         {
            this.dispose();
         }
      }

      private function hookStage(param1:DisplayObjectContainer) : void
      {
         var st:Stage = param1.stage;
         if(st == null)
         {
            param1.addEventListener(Event.ADDED_TO_STAGE,this.onRootAdded,false,0,true);
            return;
         }
         this.bind(st);
      }

      private function onRootAdded(param1:Event) : void
      {
         var c:DisplayObjectContainer = param1.target as DisplayObjectContainer;
         if(c)
         {
            c.removeEventListener(Event.ADDED_TO_STAGE,this.onRootAdded);
         }
         if(c && c.stage)
         {
            this.bind(c.stage);
         }
      }

      private function bind(param1:Stage) : void
      {
         if(this._stage == param1)
         {
            return;
         }
         this.unbind();
         this._stage = param1;
         this._stage.addEventListener(Event.ENTER_FRAME,this.onEnterFrame,false,-1000000);
      }

      private function unbind() : void
      {
         if(this._stage)
         {
            this._stage.removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
            this._stage = null;
         }
      }

      // ------------------------------------------------------------------ 显式注册（UI）

      /** 不经过扫描，直接给某个节点挂代理（例如选人界面的一次性高亮）。 */
      public function attachTo(param1:DisplayObject) : Boolean
      {
         if(param1 == null || this._proxies[param1] != null)
         {
            return false;
         }
         if(this._order.length + this._pending.length >= GameConfig.FPROXY_MAX_PROXIES)
         {
            return false;
         }
         var p:FilterNodeProxy = new FilterNodeProxy(param1,this._pool);
         // 调试导出必须受开关控制：encode PNG + 写 FUSE 单次数百毫秒，绝不能留在热路径
         if(GameConfig.FPROXY_DEBUG)
         {
            this._dumpSeq++;
            p.debugDumpPath = this._dumpDir + "/fp" + this._dumpSeq + ".png";
         }
         if(!p.attach())
         {
            return false;
         }
         if(!p.bake(GameConfig.FPROXY_MAX_PAD,this._qCap,
                    GameConfig.FPROXY_MAX_TEXTURE,GameConfig.FPROXY_MAX_NODE_PIXELS))
         {
            p.detach();
            p.dispose();
            return false;
         }
         this._proxies[param1] = p;
         this._order.push(p);
         p.syncVisual();
         this.invalidateAncestors(param1);
         return true;
      }

      public function detach(param1:DisplayObject) : void
      {
         var p:FilterNodeProxy = this._proxies[param1] as FilterNodeProxy;
         if(p == null)
         {
            return;
         }
         this.kill(p);
      }

      /**
       * 把一整棵子树排除在代理之外。
       * 典型用途：战斗 HUD（血条/名字/连击数）。它是 2D 文字与位图拼接，
       * 烘成一张图既糊又不会跟着数值刷新，而且代理一旦挂在 HUD 根上、包的滤镜
       * 又没被清掉，HUD 就会永久停在「源 alpha=0 + 替身不可见」的状态。
       */
      public function excludeSubtree(param1:DisplayObject) : void
      {
         if(param1 == null)
         {
            return;
         }
         this._excluded[param1] = true;
         var i:int = this._order.length - 1;
         while(i >= 0)
         {
            var p:FilterNodeProxy = this._order[i];
            if(this.isDescendant(p.target,param1))
            {
               this.kill(p);
            }
            i--;
         }
      }

      public function isExcluded(param1:DisplayObject) : Boolean
      {
         var n:DisplayObject = param1;
         var guard:int = 0;
         while(n && guard < 64)
         {
            if(this._excluded[n] != null)
            {
               return true;
            }
            n = n.parent;
            guard++;
         }
         return false;
      }

      public function isProxied(param1:DisplayObject) : Boolean
      {
         return this._proxies[param1] != null;
      }

      public function get proxyCount() : int
      {
         return this._order.length;
      }

      // ------------------------------------------------------------------ 释放

      public function releaseSubtree(param1:DisplayObject) : void
      {
         if(param1 == null)
         {
            return;
         }
         var i:int = this._order.length - 1;
         while(i >= 0)
         {
            var p:FilterNodeProxy = this._order[i];
            if(p.target == param1 || this.isDescendant(p.target,param1))
            {
               this.kill(p);
            }
            i--;
         }
         this.forgetBlocked(param1);
      }

      private function isDescendant(param1:DisplayObject, param2:DisplayObject) : Boolean
      {
         var n:DisplayObject = param1;
         var guard:int = 0;
         while(n && guard < 32)
         {
            if(n == param2)
            {
               return true;
            }
            n = n.parent;
            guard++;
         }
         return false;
      }

      public function invalidateAll() : void
      {
         var i:int = 0;
         while(i < this._order.length)
         {
            this._order[i].markDirty();
            i++;
         }
      }

      public function invalidate(param1:DisplayObject) : void
      {
         var p:FilterNodeProxy = this._proxies[param1] as FilterNodeProxy;
         if(p)
         {
            p.markDirty();
         }
      }

      public function setPaused(param1:Boolean) : void
      {
         this._paused = param1;
      }

      public function dispose() : void
      {
         this.unbind();
         while(this._order.length > 0)
         {
            this.kill(this._order[this._order.length - 1]);
         }
         this._pool.dispose();
         this._pending.length = 0;
         this._roots.length = 0;
         this._stackNode.length = 0;
         this._stackDepth.length = 0;
         this._lastFullScan = -100000;
         var k:String = null;
         for(k in this._excluded)
         {
            delete this._excluded[k];
         }
      }

      // ------------------------------------------------------------------ 画质档位

      public function applyQualityPreset(param1:String) : void
      {
         switch(param1)
         {
            case "best":
            case "high":
               GameConfig.FPROXY_MAX_PROXIES = 16;
               GameConfig.FPROXY_MAX_BAKE_PER_FRAME = 3;
               GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME = 900000;
               this._qCap = 3;
               GameConfig.FPROXY_SCAN_NODES_PER_FRAME = 32;
               break;
            case "low":
               GameConfig.FPROXY_MAX_PROXIES = 4;
               GameConfig.FPROXY_MAX_BAKE_PER_FRAME = 1;
               GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME = 300000;
               this._qCap = 1;
               GameConfig.FPROXY_SCAN_NODES_PER_FRAME = 16;
               break;
            default:
               GameConfig.FPROXY_MAX_PROXIES = 12;
               GameConfig.FPROXY_MAX_BAKE_PER_FRAME = 2;
               GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME = 600000;
               this._qCap = 2;
               GameConfig.FPROXY_SCAN_NODES_PER_FRAME = 24;
         }
         this._maxDepth = GameConfig.FPROXY_MAX_DEPTH;
         if(this._order.length > GameConfig.FPROXY_MAX_PROXIES)
         {
            while(this._order.length + this._pending.length > GameConfig.FPROXY_MAX_PROXIES)
            {
               if(this._order.length > 0)
               {
                  this.kill(this._order[this._order.length - 1]);
               }
               else
               {
                  this.kill(this._pending[this._pending.length - 1]);
               }
            }
         }
         this.invalidateAll();
         this._pool.trim();
      }

      // ------------------------------------------------------------------ 每帧

      private function onEnterFrame(param1:Event) : void
      {
         this._frame++;
         if(this._paused || !GameConfig.GPU_FILTER_PROXY)
         {
            return;
         }
         this.pumpScan();
         this.tickProxies();
         if((this._frame % 120) == 0)
         {
            this.dumpLive();
         }
         if((this._frame % 300) == 0 && this._scanSeen > 0)
         {
            Debugger.log("[FPROXY] scan seen=" + this._scanSeen + " hit=" + this._scanHit
                         + " stack=" + this._stackNode.length
                         + " proxies=" + this._order.length
                         + " pending=" + this._pending.length);
         }
         if(GameConfig.FPROXY_DEBUG && this._order.length > 0 && (this._frame % 600) == 0)
         {
            Debugger.log(this.dumpState());
         }
      }

      private function pumpScan() : void
      {
         var budget:int = GameConfig.FPROXY_SCAN_NODES_PER_FRAME;
         var guard:int = 0;
         while(budget > 0 && guard < 4096)
         {
            guard++;
            if(this._stackNode.length == 0)
            {
               if(this._frame - this._lastFullScan < GameConfig.FPROXY_SCAN_INTERVAL)
               {
                  return;
               }
               this._lastFullScan = this._frame;
               this.pushRoots();
               if(this._stackNode.length == 0)
               {
                  return;
               }
            }
            var node:DisplayObject = this._stackNode.pop();
            var depth:int = this._stackDepth.pop();
            budget--;
            this.consider(node,depth);
         }
      }

      private function pushRoots() : void
      {
         var i:int = 0;
         while(i < this._roots.length)
         {
            this._stackNode.push(this._roots[i]);
            this._stackDepth.push(0);
            i++;
         }
      }

      private function consider(param1:DisplayObject, param2:int) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(param1.name == FilterNodeProxy.PROXY_NAME)
         {
            return;
         }
         if(this._proxies[param1] != null)
         {
            return;
         }
         if(this.isExcluded(param1))
         {
            return;
         }
         var blockedAt:* = this._blocked[param1];
         if(blockedAt != null && this._frame - int(blockedAt) < 600)
         {
            return;
         }
         var fs:Array = null;
         try
         {
            fs = param1.filters;
         }
         catch(e:Error)
         {
            return;
         }
         this._scanSeen++;
         if(fs != null && fs.length > 0)
         {
            this._scanHit++;
            this.register(param1);
         }
         if(param2 < this._maxDepth)
         {
            var c:DisplayObjectContainer = param1 as DisplayObjectContainer;
            if(c)
            {
               var n:int = c.numChildren;
               var i:int = n - 1;
               while(i >= 0)
               {
                  this._stackNode.push(c.getChildAt(i));
                  this._stackDepth.push(param2 + 1);
                  i--;
               }
            }
         }
      }

      /**
       * 只登记 + 入队，**不同步烘焙**。
       *
       * 之前这里直接 bake()，绕过了 FPROXY_MAX_BAKE_PER_FRAME / 像素预算
       * （那两个只作用于 tickProxies 的稳态刷新），一次扫描发现 4 个整屏节点
       * 就同一帧全烘完 —— 单帧 77ms，就是"滤镜一出现就卡一下"。
       */
      private function register(param1:DisplayObject) : void
      {
         // pending 也占并发额度，否则一次扫描可以挂出 2 倍上限的代理
         if(this._order.length + this._pending.length >= GameConfig.FPROXY_MAX_PROXIES)
         {
            if(!this._warnedLimit)
            {
               this._warnedLimit = true;
               Debugger.warn("[FPROXY] 并发代理已达上限 " + GameConfig.FPROXY_MAX_PROXIES + "，后续节点跳过");
            }
            this._blocked[param1] = this._frame;
            return;
         }
         if(EffectCtrl.I != null && EffectCtrl.I.isFilterTarget(param1))
         {
            this._blocked[param1] = this._frame;
            return;
         }
         var p:FilterNodeProxy = new FilterNodeProxy(param1,this._pool);
         // 调试导出必须受开关控制：encode PNG + 写 FUSE 单次数百毫秒
         if(GameConfig.FPROXY_DEBUG)
         {
            this._dumpSeq++;
            p.debugDumpPath = this._dumpDir + "/fp" + this._dumpSeq + ".png";
         }
         if(!p.attach())
         {
            this._blocked[param1] = this._frame;
            return;
         }
         // 此刻 display.bitmapData == null → syncVisual() 会 showSource() 且**不会**
         // 执行 target.alpha = 0，所以"源可见、尚未接管"是安全状态
         this._proxies[param1] = p;
         this._pending.push(p);
         p.syncVisual();
      }

      private function tickProxies() : void
      {
         if(this._order.length == 0 && this._pending.length == 0)
         {
            return;
         }
         var t0:int = getTimer();
         var bakes:int = 0;
         var pixels:int = 0;
         var budgetOut:Boolean = false;

         // ---------------- 第一段：首次烘焙队列（FIFO，先发现先补齐）----------------
         while(this._pending.length > 0)
         {
            // bakes == 0 是反饥饿：设备本身跑不到 60fps 时也要保证每帧至少烘一个
            if(bakes > 0 && this.overBakeBudget(t0))
            {
               break;
            }
            if(GameConfig.FPROXY_MAX_BAKE_PER_FRAME > 0
               && bakes >= GameConfig.FPROXY_MAX_BAKE_PER_FRAME)
            {
               break;
            }
            if(pixels >= GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME)
            {
               break;
            }
            var q:FilterNodeProxy = this._pending.shift();
            var qt:DisplayObject = q.target;
            var qf:Array = null;
            try
            {
               qf = qt ? qt.filters : null;
            }
            catch(qe:Error)
            {
               qf = null;
            }
            if(qt == null || qt.stage == null || qf == null || qf.length == 0
               || (EffectCtrl.I != null && EffectCtrl.I.isFilterTarget(qt)))
            {
               this.kill(q);
               continue;
            }
            if(q.detached && !q.attach())
            {
               this.kill(q);
               continue;
            }
            // frameNow 必须在 bake 之前写：bake 会用它记 _lastHeavyAt
            q.frameNow = this._frame;
            if(!q.bake(GameConfig.FPROXY_MAX_PAD,this._qCap,
                       GameConfig.FPROXY_MAX_TEXTURE,GameConfig.FPROXY_MAX_NODE_PIXELS,true))
            {
               var wasEmpty:Boolean = q.lastWasEmpty;
               this.kill(q);
               // 空结果多半是「这一刻还没内容」，短冷却后再试；尺寸超限才是长冷却
               this._blocked[qt] = this._frame - (wasEmpty ? 540 : 0);
               Debugger.warn("[FPROXY] 跳过 " + describe(qt)
                             + (wasEmpty ? " 烘焙结果全透明（稍后重试）" : " 尺寸/纹理超限"));
               continue;
            }
            bakes++;
            this._statBakes++;
            if(q.display.bitmapData)
            {
               pixels += q.display.bitmapData.width * q.display.bitmapData.height;
            }
            // 只有烘成功之后才允许把源 alpha 置 0
            q.syncVisual();
            q.syncTransform();
            this.invalidateAncestors(qt);
            this._order.push(q);
            Debugger.log("[FPROXY] + " + describe(qt) + " bake=" + q.bakeSize
                         + " filters=" + qt.filters.length + " ms=" + q.lastBakeMs + q.diag);
         }

         if(this._order.length == 0)
         {
            return;
         }

         // ---------------- 第二段：稳态刷新 ----------------
         var i:int = this._order.length - 1;
         while(i >= 0)
         {
            var p:FilterNodeProxy = this._order[i];
            p.frameNow = this._frame;
            var t:DisplayObject = p.target;
            if(t == null || t.stage == null)
            {
               this.kill(p);
               i--;
               continue;
            }
            if(EffectCtrl.I != null && EffectCtrl.I.isFilterTarget(t))
            {
               this._blocked[t] = this._frame;
               this.kill(p);
               i--;
               continue;
            }
            if(p.detached && !p.attach())
            {
               this.kill(p);
               i--;
               continue;
            }
            this.fixZOrder(p);
            var fs:Array = null;
            try
            {
               fs = t.filters;
            }
            catch(e:Error)
            {
               fs = null;
            }
            if(fs == null || fs.length == 0)
            {
               this.kill(p);
               i--;
               continue;
            }
            if(p.refreshFilters(fs))
            {
               p.markDirty();
            }
            p.syncVisual();
            if(p.needsBake())
            {
               if(!budgetOut
                  && (GameConfig.FPROXY_MAX_BAKE_PER_FRAME <= 0
                      || bakes < GameConfig.FPROXY_MAX_BAKE_PER_FRAME)
                  && pixels < GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME
                  && (bakes == 0 || !this.overBakeBudget(t0)))
               {
                  if(p.bake(GameConfig.FPROXY_MAX_PAD,this._qCap,
                            GameConfig.FPROXY_MAX_TEXTURE,GameConfig.FPROXY_MAX_NODE_PIXELS))
                  {
                     bakes++;
                     this._statBakes++;
                     if(p.display.bitmapData)
                     {
                        pixels += p.display.bitmapData.width * p.display.bitmapData.height;
                     }
                  }
                  else
                  {
                     budgetOut = true;
                     this._statSkips++;
                  }
               }
               else
               {
                  budgetOut = true;
                  this._statSkips++;
               }
            }
            // 预算耗尽也必须同步变换，否则快速移动时后面的代理会拖影
            p.syncTransform();
            i--;
         }
      }

      private function overBakeBudget(param1:int) : Boolean
      {
         if(GameConfig.FPROXY_BAKE_BUDGET_MS <= 0)
         {
            return false;
         }
         return getTimer() - param1 >= GameConfig.FPROXY_BAKE_BUDGET_MS;
      }

      private function fixZOrder(param1:FilterNodeProxy) : void
      {
         var t:DisplayObject = param1.target;
         var par:DisplayObjectContainer = t.parent;
         if(par == null || param1.display.parent != par)
         {
            return;
         }
         var want:int = par.getChildIndex(t) + 1;
         if(want >= par.numChildren)
         {
            want = par.numChildren - 1;
         }
         if(par.getChildIndex(param1.display) != want)
         {
            par.setChildIndex(param1.display,want);
         }
      }

      private function kill(param1:FilterNodeProxy) : void
      {
         var t:DisplayObject = param1.target;
         var pi:int = this._pending.indexOf(param1);
         if(pi >= 0)
         {
            this._pending.splice(pi,1);
         }
         var idx:int = this._order.indexOf(param1);
         if(idx >= 0)
         {
            this._order.splice(idx,1);
         }
         if(t)
         {
            delete this._proxies[t];
         }
         var wasHiding:Boolean = param1.hiding;
         param1.dispose();
         if(t)
         {
            this.invalidateAncestors(t);
         }
         if(param1.baked)
         {
            Debugger.log("[FPROXY] - " + describe(t) + " restored=" + wasHiding
                         + " nodeAlpha=" + (t ? t.alpha : -1));
         }
      }

      private function invalidateAncestors(param1:DisplayObject) : void
      {
         var n:DisplayObject = param1 ? param1.parent : null;
         var guard:int = 0;
         while(n && guard < 16)
         {
            var up:FilterNodeProxy = this._proxies[n] as FilterNodeProxy;
            if(up)
            {
               up.markDirty();
            }
            n = n.parent;
            guard++;
         }
      }

      private function dumpLive() : void
      {
         var i:int = 0;
         while(i < this._order.length)
         {
            var p:FilterNodeProxy = this._order[i];
            var d:DisplayObject = p.display;
            var dbd:BitmapData = p.display ? p.display.bitmapData : null;
            var info:String = "[FPROXY] live " + describe(p.target)
               + " inTree=" + (d.parent != null)
               + " idx=" + (d.parent ? d.parent.getChildIndex(d) : -1)
               + " a=" + d.alpha + " v=" + d.visible + " bm=" + d.blendMode
               + " sc=" + (dbd ? dbd.width + "x" + dbd.height : "null")
               + " m=" + d.scaleX.toFixed(2) + "/" + d.scaleY.toFixed(2)
               + " xy=" + int(d.x) + "," + int(d.y)
               + " srcA=" + p.target.alpha;
            try
            {
               // 代理应该和源节点在屏幕上占据同一个矩形；不一致就说明变换算错了
               var bb:Rectangle = d.getBounds(this._stage);
               var tb:Rectangle = p.target.getBounds(this._stage);
               info += " screen=" + int(bb.x) + "," + int(bb.y)
                  + " " + int(bb.width) + "x" + int(bb.height)
                  + " target=" + int(tb.x) + "," + int(tb.y)
                  + " " + int(tb.width) + "x" + int(tb.height)
                  + " dxy=" + int(bb.x - tb.x) + "," + int(bb.y - tb.y)
                  + " dwh=" + int(bb.width - tb.width) + "," + int(bb.height - tb.height);
            }
            catch(be:Error)
            {
            }
            Debugger.log(info);
            i++;
         }
      }

      private function describe(param1:DisplayObject) : String
      {
         var s:String = "";
         var n:DisplayObject = param1;
         var guard:int = 0;
         while(n && guard < 4)
         {
            s = (n.name ? n.name : getQualifiedClassName(n).split("::").pop()) + (s ? "/" + s : "");
            n = n.parent;
            guard++;
         }
         return s;
      }

      private function forgetBlocked(param1:DisplayObject) : void
      {
         if(param1 == null)
         {
            return;
         }
         delete this._blocked[param1];
         var c:DisplayObjectContainer = param1 as DisplayObjectContainer;
         if(c)
         {
            var i:int = 0;
            while(i < c.numChildren)
            {
               this.forgetBlocked(c.getChildAt(i));
               i++;
            }
         }
      }

      // ------------------------------------------------------------------ 诊断

      public function dumpState() : String
      {
         var s:String = "[FPROXY] proxies=" + this._order.length
            + " bakes=" + this._statBakes + " skipped=" + this._statSkips
            + " poolLive=" + this._pool.liveCount
            + " poolMB=" + (Math.round(this._pool.totalBytes / 104857.6) / 10)
            + " qCap=" + this._qCap + " frame=" + this._frame;
         return s;
      }
   }
}
