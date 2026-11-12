package net.play5d.game.bvn.views.filter
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Stage;
   import flash.geom.Matrix;
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
    * 驱动是**两段式**，都挂在本类自建的 stage.ENTER_FRAME 上：
    *   - `onFramePre`  优先级 +1000000，排在 GameRender（默认 0）之前 ——
    *     把每个代理的源 alpha 还原成"游戏想要的显示值"；
    *   - `onEnterFrame` 优先级 -1000000，排在游戏逻辑之后、渲染之前 ——
    *     读回游戏这一帧写的真值（含 0），再把源藏成 0。
    *
    * 为什么非得分两段：代理靠 `target.alpha = 0` 藏源，可 alpha 是**同一个槽位**，
    * 游戏里的 `alpha -= x` 这类递减写会读到自己被写成的 0，于是永远停在 0；
    * 而帧末读到的 0 又被当成"我这只写的 0"忽略掉 → `_wantedAlpha` 冻在最后一个
    * 非零值 → 效果淡出完毕、甚至节点已经该消失了，代理位图仍以那个 alpha 挂在场上。
    * 观感就是"发光/模糊这类滤镜效果残留很久消不掉"。帧初还原 + 帧末照抄 0 才治本。
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
      /** 稳态刷新用的快照（复用，避免每帧分配；kill 会改 _order，不能边遍历边索引） */
      private const _tick:Vector.<FilterNodeProxy> = new Vector.<FilterNodeProxy>();
      /** 本帧待烘：普通通道 / 高频通道（HF 有独立额度，不占普通额度） */
      private const _dueNormal:Vector.<FilterNodeProxy> = new Vector.<FilterNodeProxy>();
      private const _dueHf:Vector.<FilterNodeProxy> = new Vector.<FilterNodeProxy>();
      private const _blocked:Dictionary = new Dictionary(true);
      private const _excluded:Dictionary = new Dictionary(true);
      /** _excluded 的条目数（isExcluded 的空表短路用） */
      private var _excludedCount:int = 0;
      private const _stackNode:Vector.<DisplayObject> = new Vector.<DisplayObject>();
      private const _stackDepth:Vector.<int> = new Vector.<int>();

      /** 池上限 12：超采样后单张位图是 1× 时的 2.25~4 倍大，24 张会顶到几十 MB。
       *  分桶 16（原来是 32）：一块 493×187 的文本面板因此从 512×192 降到 496×192，
       *  别小看这 3%，它和"每 2 帧上传一次纹理"乘在一起就是白白多传的带宽。 */
      private var _pool:BitmapDataPool = new BitmapDataPool(8,16);
      private var _stage:Stage;
      private var _frame:int = 0;
      private var _lastFullScan:int = -100000;
      private var _paused:Boolean = false;
      /** setEnabled() 的幂等镜像，初值与 GameConfig.GPU_FILTER_PROXY 一致 */
      private var _enabled:Boolean = true;
      private var _maxDepth:int = 5;
      private var _qCap:int = 3;
      private var _statBakes:int = 0;
      private var _statSkips:int = 0;
      private var _warnedLimit:Boolean = false;
      private var _scanSeen:int = 0;
      private var _dumpSeq:int = 0;
      private var _dumpDir:String = "/storage/emulated/0/Android/media/air.com.bvn.yy798/fproxy";
      private var _scanHit:int = 0;
      /** 上一次 tickProxies 的墙钟耗时（ms）。诊断用：它就是"代理层每帧的税" */
      private var _lastTickMs:int = 0;
      /** 最近一次 Event.RENDER 落在哪一帧。-1 = 从没来过（此时不延后藏源） */
      private var _renderSeenFrame:int = -1;

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
         this._stage.addEventListener(Event.ENTER_FRAME,this.onFramePre,false,1000000);
         this._stage.addEventListener(Event.ENTER_FRAME,this.onEnterFrame,false,-1000000);
         // 第三段：Event.RENDER 在**所有** ENTER_FRAME 监听跑完之后、合成之前触发。
         // 人物包自带的 enterFrame 帧脚本、TweenLite 都挂在各自的对象上，
         // 它们的执行时机不在 stage 的优先级体系里 —— 只有 RENDER 能兜住
         // "游戏在 post-tick 之后又写了 alpha"这一帧。
         this._stage.addEventListener(Event.RENDER,this.onRenderPhase,false,0,true);
      }

      private function unbind() : void
      {
         if(this._stage)
         {
            this._stage.removeEventListener(Event.ENTER_FRAME,this.onFramePre);
            this._stage.removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
            this._stage.removeEventListener(Event.RENDER,this.onRenderPhase);
            this._stage = null;
         }
      }

      /** 本帧是否真的在驱动代理。暂停（菜单/切后台）时**不还原** alpha，画面就该冻住。 */
      private function isDriving() : Boolean
      {
         return !this._paused && GameConfig.GPU_FILTER_PROXY;
      }

      /**
       * 本帧能不能把"藏源"推迟到 Event.RENDER。
       *
       * 延后藏源的价值：脚本期源始终是游戏自己的 alpha，任何 `alpha -= x` 的补间
       * 都读到真值（不延后的话它读到我们写的 0，永远淡不出去 → 滤镜残影）。
       * 前提是 RENDER 真的会来：上一帧来过、本帧 pre 又 invalidate 过，才算数。
       * 从没来过（老设备 / invalidate 无效）就退回"post-tick 当场藏"，行为与旧版一致。
       */
      private function canDeferHide() : Boolean
      {
         return this._renderSeenFrame >= 0 && this._renderSeenFrame >= this._frame - 1;
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
         p.syncVisual(false);
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
         this._excludedCount++;
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
         // 全仓只有 HUD 一处登记过排除。没有登记时整段跳过 —— 这一条每帧要过
         // 24~40 个扫描节点，白走 64 级父链是纯浪费。
         if(this._excludedCount <= 0)
         {
            return false;
         }
         var n:DisplayObject = param1;
         var guard:int = 0;
         while(n && guard < 16)
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

      /**
       * 手机端「滤镜效果（实验功能）」总开关（2026-11-12）。
       *
       * 关闭：立刻撤掉全部代理。`kill()` 会 dispose 代理并把被藏的源节点 alpha/visible 还原，
       * 同时丢弃未完成的扫描队列 —— 只停扫描不回收，源会永远停在 alpha=0（隐形角色）。
       * 打开：重置全量扫描游标，下一帧重新走既有的注册/预算机制。
       * 幂等：同值重复调用直接返回，APPLY 连点不会反复拆装。
       */
      public function setEnabled(param1:Boolean) : void
      {
         if(this._enabled == param1 && GameConfig.GPU_FILTER_PROXY == param1)
         {
            return;
         }
         this._enabled = param1;
         GameConfig.GPU_FILTER_PROXY = param1;
         // 无论开还是关，都让下一次扫描从头开始（关→开时旧游标会让扫描"以为扫完了"）
         this._lastFullScan = -100000;
         if(!param1)
         {
            this.killAll();
            this._pending.length = 0;
            this._stackNode.length = 0;
            this._stackDepth.length = 0;
            Debugger.log("[FPROXY] disabled by config, proxies released");
         }
         else
         {
            Debugger.log("[FPROXY] enabled by config");
         }
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
         this._renderSeenFrame = -1;
         var k:String = null;
         for(k in this._excluded)
         {
            delete this._excluded[k];
         }
         this._excludedCount = 0;
      }

      /** 撤掉所有代理（保留池与根）。运行中关开关 / 换画质档位时用。 */
      private function killAll() : void
      {
         while(this._pending.length > 0)
         {
            this.kill(this._pending[this._pending.length - 1]);
         }
         while(this._order.length > 0)
         {
            this.kill(this._order[this._order.length - 1]);
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
               GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME = 2200000;
               GameConfig.FPROXY_BAKE_SCALE_MAX = 2;
               this._qCap = 3;
               GameConfig.FPROXY_SCAN_NODES_PER_FRAME = 32;
               break;
            case "low":
               GameConfig.FPROXY_MAX_PROXIES = 4;
               GameConfig.FPROXY_MAX_BAKE_PER_FRAME = 1;
               GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME = 450000;
               GameConfig.FPROXY_BAKE_SCALE_MAX = 1;
               this._qCap = 1;
               GameConfig.FPROXY_SCAN_NODES_PER_FRAME = 16;
               break;
            default:
               GameConfig.FPROXY_MAX_PROXIES = 12;
               GameConfig.FPROXY_MAX_BAKE_PER_FRAME = 2;
               GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME = 1200000;
               GameConfig.FPROXY_BAKE_SCALE_MAX = 1.5;
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

      /**
       * 帧初：把源 alpha 还原成游戏想要的显示值。
       *
       * 必须排在游戏逻辑之前（优先级 +1000000，GameRender 是默认 0），
       * 这样游戏这一帧无论读还是写 alpha，拿到的都是真值。
       * 合成前还有第三段（onRenderPhase）负责把源藏回 0，屏幕上看不到源。
       */
      private function onFramePre(param1:Event) : void
      {
         if(!this.isDriving() || this._order.length == 0)
         {
            return;
         }
         var i:int = 0;
         var n:int = this._order.length;
         while(i < n)
         {
            this._order[i].unhideSourceAlpha();
            i++;
         }
         // 让本帧一定会派发 Event.RENDER（第三段收尾）
         try
         {
            if(this._stage != null)
            {
               this._stage.invalidate();
            }
         }
         catch(ie:Error)
         {
         }
      }

      /**
       * 第三段：合成前最后一道。
       *
       * 走到这里时，所有 ENTER_FRAME 监听（含人物包自己的帧脚本、TweenLite）都跑完了。
       * 做两件事：抄下这一帧**最终**的 alpha（含 0），再把源藏回 0。
       * 纯粹是加法 —— RENDER 不来（老设备 / invalidate 失效）就整段跳过，
       * 藏源退回 post-tick 那段做，行为与旧版等价，不会比现在更差。
       */
      private function onRenderPhase(param1:Event) : void
      {
         var defer:Boolean = this.canDeferHide();
         if(this.isDriving() && this._order.length > 0)
         {
            var i:int = 0;
            var n:int = this._order.length;
            while(i < n)
            {
               this._order[i].reassertHidden(defer);
               i++;
            }
         }
         this._renderSeenFrame = this._frame;
      }

      private function onEnterFrame(param1:Event) : void
      {
         this._frame++;
         if(this._paused)
         {
            return;
         }
         if(!GameConfig.GPU_FILTER_PROXY)
         {
            // 运行中被关掉开关：代理不再驱动，必须立刻全部撤掉。
            // 否则源节点的 alpha 永远停在 0（源被藏、替身也不再更新）。
            this.killAll();
            return;
         }
         this.pumpScan();
         var tTick:int = getTimer();
         this.tickProxies();
         this._lastTickMs = getTimer() - tTick;
         if((this._frame % 120) == 0)
         {
            this.dumpLive();
         }
         if((this._frame % 300) == 0 && this._scanSeen > 0)
         {
            Debugger.log("[FPROXY] scan seen=" + this._scanSeen + " hit=" + this._scanHit
                         + " stack=" + this._stackNode.length
                         + " proxies=" + this._order.length
                         + " pending=" + this._pending.length
                         + " bakes=" + this._statBakes);
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
         var blockedUntil:* = this._blocked[param1];
         // 语义是"到期帧"（不是"起始帧"）：不同原因给的冷却长短差很多 ——
         // 钢身/金身占用只是暂时状态（30 帧），烘焙失败才是长冷却（600 帧）。
         // 旧实现写死"从登记起 600 帧"，钢身一用完，带滤镜的角色会**十秒不渲染**。
         if(blockedUntil != null && this._frame < int(blockedUntil))
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
            this._blocked[param1] = this._frame + 120;
            return;
         }
         if(EffectCtrl.I != null && EffectCtrl.I.isFilterTarget(param1))
         {
            // 钢身/金身只是暂时占用这个节点，短冷却就够；用 600 帧会让辉光结束后
            // 带滤镜的角色卡在"没有代理 → GPU 不渲染"里十秒。
            this._blocked[param1] = this._frame + 30;
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
            this._blocked[param1] = this._frame + 600;
            return;
         }
         // 此刻 display.bitmapData == null → syncVisual() 会 showSource() 且**不会**
         // 执行 target.alpha = 0，所以"源可见、尚未接管"是安全状态
         this._proxies[param1] = p;
         this._pending.push(p);
         p.syncVisual(false);
      }

      private function tickProxies() : void
      {
         // 上一帧若有异常路径导致没清，这里兜一层（两个数组都只在单帧内有效）
         this._dueNormal.length = 0;
         this._dueHf.length = 0;
         if(this._order.length == 0 && this._pending.length == 0)
         {
            return;
         }
         var t0:int = getTimer();
         var bakes:int = 0;
         var pixels:int = 0;
         var deferHide:Boolean = this.canDeferHide();

         // ---------------- 第一段：首次烘焙队列（FIFO，先发现先补齐）----------------
         while(this._pending.length > 0)
         {
            // bakes == 0 是反饥饿：设备本身跑不到 60fps 时也要保证每帧至少烘一个
            if(!this.canAfford(t0,this._pending[0],bakes))
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
            if(q.needsReattach && !q.attach())
            {
               this.kill(q);
               continue;
            }
            if(!q.bake(GameConfig.FPROXY_MAX_PAD,this._qCap,
                       GameConfig.FPROXY_MAX_TEXTURE,GameConfig.FPROXY_MAX_NODE_PIXELS,true,qf))
            {
               var wasEmpty:Boolean = q.lastWasEmpty;
               this.kill(q);
               // 空结果多半是「这一刻还没内容」，短冷却后再试；尺寸超限才是长冷却
               this._blocked[qt] = this._frame + (wasEmpty ? 60 : 600);
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
            q.syncVisual(deferHide);
            q.syncTransform();
            this.invalidateAncestors(qt);
            this._order.push(q);
            Debugger.log("[FPROXY] + " + describe(qt) + " bake=" + q.bakeSize
                         + " filters=" + qt.filters.length + " ms=" + q.lastBakeMs
                         + " cost=" + q.costMs
                         + " edge=" + (q.edge == "" ? "-" : q.edge) + q.diag);
         }

         if(this._order.length == 0)
         {
            return;
         }

         // ---------------- 第二段：稳态刷新 ----------------
         // 快照 + 轮转起点：带滤镜补间的节点每帧都抢预算，固定从末尾遍历会让排在前面的
         // 节点永远轮不到（表现为"某些节点的滤镜只出第一帧"）。
         this._tick.length = 0;
         var n:int = this._order.length;
         var j:int = 0;
         while(j < n)
         {
            this._tick.push(this._order[j]);
            j++;
         }
         var start:int = n > 0 ? this._frame % n : 0;
         var step:int = 0;
         while(step < n)
         {
            var i:int = start - step;
            if(i < 0)
            {
               i += n;
            }
            step++;
            var p:FilterNodeProxy = this._tick[i];
            var t:DisplayObject = p.target;
            if(t == null || t.stage == null)
            {
               this.kill(p);
               continue;
            }
            // 2026-11-12：源节点父链变换失效时放弃代理（详见 isTargetTransformSane）。
            // 不拦这一条，代理会按错误矩阵把一张大位图贴在屏幕中间，而且长期 live。
            // 冷却必须给足：这类废弃元件是常驻的，只 kill 不加冷却的话下一轮扫描
            // 会立刻重新发现它，变成「每帧 kill + 重建」的空转。
            if(!this.isTargetTransformSane(t))
            {
               this._blocked[t] = this._frame + 300;
               this.kill(p);
               continue;
            }
            if(EffectCtrl.I != null && EffectCtrl.I.isFilterTarget(t))
            {
               // 短冷却：辉光一结束必须能立刻重新接管（详见 register() 同一处注释）
               this._blocked[t] = this._frame + 30;
               this.kill(p);
               continue;
            }
            if(p.needsReattach && !p.attach())
            {
               this.kill(p);
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
               continue;
            }
            if(p.refreshFilters(fs))
            {
               p.markDirty();
            }
            p.syncVisual(deferHide);
            if(p.needsBake())
            {
               // 只登记，不在遍历里烘：烘要按预算调度，而且高频节点有自己的通道。
               if(p.isHf)
               {
                  this._dueHf.push(p);
               }
               else
               {
                  this._dueNormal.push(p);
               }
            }
            // 预算耗尽也必须同步变换，否则快速移动时后面的代理会拖影
            p.syncTransform();
         }

         if(this._dueNormal.length > 0 || this._dueHf.length > 0)
         {
            this.bakeQueued(t0,bakes,pixels,deferHide);
         }
      }

      /**
       * 按预算服务两个烘焙通道。
       *
       * 旧实现用 `budgetOut` 做"本帧弃疗"标志：任一节点超预算或烘失败，**本帧后面
       * 所有代理都不再烘**。一个每帧都在变的文本面板可以把额度吃干净，别的滤镜
       * 就停在旧像素上（表现为"其他滤镜也变慢/滞后"）。现在改成逐节点预测：
       * 超预算只跳过**自己**，不连坐。
       *
       * 通道拆分：高频节点（HF）走独立额度 `FPROXY_HF_BAKE_PER_FRAME`，**不从
       * `bakes` 里扣** —— 这样它再活跃也挤不掉普通节点。
       */
      private function bakeQueued(param1:int, param2:int, param3:int, param4:Boolean) : void
      {
         var bakes:int = param2;
         var pixels:int = param3;
         var i:int = 0;
         var n:int = this._dueNormal.length;
         while(i < n)
         {
            var p:FilterNodeProxy = this._dueNormal[i];
            i++;
            if(GameConfig.FPROXY_MAX_BAKE_PER_FRAME > 0
               && bakes >= GameConfig.FPROXY_MAX_BAKE_PER_FRAME)
            {
               break;
            }
            if(pixels >= GameConfig.FPROXY_MAX_BAKE_PIXELS_PER_FRAME)
            {
               break;
            }
            if(!this.canAfford(param1,p,bakes))
            {
               this._statSkips++;
               continue;
            }
            bakes++;
            if(p.bake(GameConfig.FPROXY_MAX_PAD,this._qCap,
                      GameConfig.FPROXY_MAX_TEXTURE,GameConfig.FPROXY_MAX_NODE_PIXELS,false))
            {
               this._statBakes++;
               if(p.display.bitmapData)
               {
                  pixels += p.display.bitmapData.width * p.display.bitmapData.height;
               }
               p.syncVisual(param4);
               p.syncTransform();
            }
            else
            {
               // 只影响自己：失败也不许把本帧其他节点一起掐死
               this._statSkips++;
            }
         }

         var hf:int = 0;
         var j:int = 0;
         var m:int = this._dueHf.length;
         while(j < m)
         {
            var h:FilterNodeProxy = this._dueHf[j];
            j++;
            if(GameConfig.FPROXY_HF_BAKE_PER_FRAME > 0
               && hf >= GameConfig.FPROXY_HF_BAKE_PER_FRAME)
            {
               break;
            }
            if(!this.canAfford(param1,h,bakes + hf))
            {
               this._statSkips++;
               continue;
            }
            hf++;
            if(h.bake(GameConfig.FPROXY_MAX_PAD,this._qCap,
                      GameConfig.FPROXY_MAX_TEXTURE,GameConfig.FPROXY_MAX_NODE_PIXELS,false))
            {
               this._statBakes++;
               if(h.display.bitmapData)
               {
                  pixels += h.display.bitmapData.width * h.display.bitmapData.height;
               }
               h.syncVisual(param4);
               h.syncTransform();
            }
            else
            {
               this._statSkips++;
            }
         }

         this._dueNormal.length = 0;
         this._dueHf.length = 0;
      }

      /**
       * 单节点预算预测：这一张烘下去会不会把本帧烘焙时间用爆。
       *
       * 用 `costEma`（实测总成本）而不是拍脑袋的常量；还没烘过的节点用
       * `FPROXY_FIRST_COST_GUESS_MS` 占位。
       * 反饥饿：本帧一张都没烘过时无条件放行 —— 设备跑不到满帧也要有进展。
       */
      private function canAfford(param1:int, param2:FilterNodeProxy, param3:int) : Boolean
      {
         if(GameConfig.FPROXY_BAKE_BUDGET_MS <= 0 || param3 <= 0)
         {
            return true;
         }
         var est:int = param2.costEma > 0
            ? param2.costEma
            : GameConfig.FPROXY_FIRST_COST_GUESS_MS;
         return (getTimer() - param1) + est <= GameConfig.FPROXY_BAKE_BUDGET_MS;
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
         // dispose() 会把 _baked 置 false —— 必须在它之前取，否则 `-` 行永远不打印
         // （2026-10-26：真机 13 次回收一条 `-` 都没有，就是踩了这个）
         var wasBaked:Boolean = param1.baked;
         param1.dispose();
         if(t)
         {
            this.invalidateAncestors(t);
         }
         if(wasBaked)
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

      /**
       * 源节点的变换是否可信（2026-11-12，第二版判据）。
       *
       * 外部角色包里普遍存在「定义了但从未真正上场」的元件。实测对象是孙悟空包的
       * jingubang（金箍棒），两批日志分别来自不同局：
       *   [FPROXY] live .../jingubang sc=288x240 screen=208,299 720x600
       *            target=-25165212,25166579 0x0  dxy=25165421,-25166279
       *   [FPROXY] live .../jingubang sc=336x320 screen=50,184 840x800
       *            target=-25165276,25166616 0x0  dwh=840,800
       *
       * 决定性的细节是 `target` 的**宽高为 0**：getBounds 拿到空矩形，那个
       * -25165276 只是空矩形带出来的垃圾坐标。源节点自身的 concatenatedMatrix
       * 是正常的，所以第一版只查 cm.tx 完全拦不住 —— 代理照样烘一张 840x800
       * 挂在屏幕上不动，源帧号不变又不会重烘，于是**特效永远播不完、永久残留**。
       *
       * 因此判据是双条件（见函数内注释）：空内容 + 舞台坐标越界。
       */
      private function isTargetTransformSane(param1:DisplayObject) : Boolean
      {
         var cm:Matrix = null;
         try
         {
            cm = param1.transform.concatenatedMatrix;
         }
         catch(ce:Error)
         {
            return false;
         }
         if(cm == null)
         {
            return false;
         }
         // NaN != NaN，用自比抓 NaN（矩阵未初始化时常见）
         if(cm.tx != cm.tx || cm.ty != cm.ty)
         {
            return false;
         }
         if(!isFinite(cm.tx) || !isFinite(cm.ty))
         {
            return false;
         }
         if(Math.abs(cm.tx) > 100000 || Math.abs(cm.ty) > 100000)
         {
            return false;
         }
         // 第三版判据（2026-11-12）：只看**舞台坐标**，不再拿本地 bounds 当门槛。
         //
         // 第二版用「本地 bounds 宽高 <= 0」做前置条件，实测会漏 jingubang：
         // 它的代理能烘出 336x320 的位图，说明**本地 bounds 是非空的**；
         // 真正为 0 的是舞台坐标系下的 bounds —— 日志里
         //   target=-25165276,25166616 0x0   （= getBounds(stage)，宽高 0）
         //   dwh=840,800                     （= 代理 840x800 − 源 0x0）
         // 那个 0x0 就是它。本地非空 ⇒ 第二版的条件永不成立 ⇒ 一条都没拦住。
         //
         // 所以门槛换到 stage 坐标：屏幕只有 1600x900，10 万 ≈ 60 个屏宽，
         // 任何超出这个量级的舞台坐标都必然是坏变换（空矩形带出来的垃圾值）。
         // 只查坐标不会误杀角色过渡帧（过渡帧的舞台坐标仍在屏幕附近）。
         var sb:Rectangle = null;
         try
         {
            sb = param1.getBounds(param1.stage);
         }
         catch(se:Error)
         {
            return false;
         }
         if(sb == null)
         {
            return false;
         }
         if(sb.x != sb.x || sb.y != sb.y || sb.width != sb.width || sb.height != sb.height)
         {
            return false;
         }
         if(Math.abs(sb.x) > 100000 || Math.abs(sb.y) > 100000)
         {
            Debugger.log("[FPROXY] reject bad-stage-transform " + describe(param1)
                         + " sb=" + int(sb.x) + "," + int(sb.y)
                         + " " + int(sb.width) + "x" + int(sb.height));
            return false;
         }
         return true;
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
               + " s=" + p.bakeScale.toFixed(2)
               + " ms=" + p.drawMs + " minMs=" + p.minInterval
               + " cost=" + p.costMs + " ema=" + p.costEma
               + (p.isHf ? " hf=true" : " hf=false")
               + " m=" + d.scaleX.toFixed(2) + "/" + d.scaleY.toFixed(2)
               + " xy=" + int(d.x) + "," + int(d.y)
               + " srcA=" + p.target.alpha
               + " wa=" + p.wantedAlpha;
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
            + " tick=" + this._lastTickMs
            + " poolLive=" + this._pool.liveCount
            + " poolMB=" + (Math.round(this._pool.totalBytes / 104857.6) / 10)
            + " qCap=" + this._qCap + " frame=" + this._frame;
         return s;
      }
   }
}
