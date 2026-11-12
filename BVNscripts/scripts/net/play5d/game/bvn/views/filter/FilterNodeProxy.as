package net.play5d.game.bvn.views.filter
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.PNGEncoderOptions;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.utils.ByteArray;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import net.play5d.game.bvn.Debugger;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.utils.BlendModeCompat;

   /**
    * 单个「带滤镜节点」的位图代理。
    *
    * 工作原理（实测依据见 tools/Test/_report/2026-10-23_GPU滤镜探针结论.md）：
    *   1. 源节点原地不动，只把 alpha 置 0 —— GPU 合成器就没东西可画了；
    *   2. 在**同一个父容器、紧跟源的 z 序**插一张 Bitmap；
    *   3. Bitmap 的像素 = 源节点 draw 的结果（draw 会把 filters 一起烘进去，所以**不要再 applyFilter**）；
    *   4. 每帧只把 transform.matrix / alpha / visible / colorTransform / blendMode 拷给 Bitmap，
    *      形状没变就完全不动像素。
    *
    * 为什么是兄弟位图而不是镜像树：子节点的代理本身就是父节点的子显示对象，
    * 父级重烘时自动包含它，嵌套滤镜天然合成，不需要结构 diff、不需要重挂、不需要 hitTest 反算。
    *
    * === 2026-10-23 第二轮修正（清晰度 / 裁切 / 补间 / 平滑）===
    *   A. 烘焙倍率不再恒 1：按节点在屏幕上的实际缩放超采样（上限 FPROXY_BAKE_SCALE_MAX），
    *      否则 800×600 逻辑空间烘出来的图会被 `_gameSprite`(≈1.8) × 相机 zoom(1~2.5) 放大后发糊。
    *   B. 外扩 pad 加余量（FPROXY_BOUNDS_SLACK）并把上限提到 96，多滤镜串联不再被 64 截断。
    *   C. 平滑跟源：找目标里最近的 Bitmap 用它的 smoothing，找不到 = false（角色是位图填充
    *      Shape，天然 false，正是"角色滤镜不做平滑"的要求）。
    *   D. 刷新节奏按**实测 draw 耗时**自适应，删掉"重节点 30 帧一次 / 超 120ms 永久冻结"，
    *      带滤镜补间的节点不再停在某一帧。
    *   E. 重烘换**新的 Bitmap 对象**（doc/runtime-pitfalls.md §2.1：只换 bitmapData 不保证刷纹理）。
    */
   public class FilterNodeProxy
   {
      public static const PROXY_NAME:String = "__fproxy";

      public var target:DisplayObject;
      public var display:Bitmap;

      private var _pool:BitmapDataPool;

      private var _m:Matrix = new Matrix();
      /** 内容区，**目标局部空间**。
       *  draw() 不套用目标自身的 transform（工程里 KyoUtils/ShadowEffectView 都靠这一点定位），
       *  所以这里必须用 getBounds(target) 的局部值，再由 syncTransform 叠加 nm 上屏。 */
      private var _bounds:Rectangle = new Rectangle();
      /** 位图四周的透明边（像素） */
      private var _padPx:int = 0;
      private var _frameKey:int = -1;
      /** 内容签名（结构 + 文本），小节点靠它实现"每帧按真实情况呈现" */
      private var _contentSig:uint = 0;
      /**
       * 大节点：一次 draw 太贵（成本 ≥ FPROXY_HEAVY_COST_MS，或逻辑面积 ≥ HEAVY_LOGICAL_PX）。
       * 这类节点不能逐帧做内容签名重烘（会直接掉帧），改按 frameKey 判脏。
       *
       * **但"不看文本"是绝对禁止的** —— high 档超采样 2× 时 224×224 逻辑就会越线，
       * 一旦按纯 frameKey 判，文本面板会永久定格。见 needsBake 里 `_textOnly` 分支优先。
       */
      private var _big:Boolean = false;
      private static const HEAVY_LOGICAL_PX:int = 120000;
      /** 子树里是否有 TextField（attach 时扫一次） */
      private var _hasText:Boolean = false;
      /**
       * "文本主导节点"：目标本身就是 TextField，或只有 ≤2 个子节点的薄容器。
       *
       * 只有这种节点才配走轻签名（contentText）与 HF 通道。
       * **不能只看 `_hasText`**：角色/特效 MC 里挂一个文字牌也会让 `_hasText` 为真，
       * 而它们的动画要靠 `content()` 的帧号/坐标扫描 —— 一旦误判成文本节点，动画会冻。
       */
      private var _textOnly:Boolean = false;
      /** 缓存的 TextField 列表（≤8），轻签名的输入。纽带是 txt1..txt8 共 8 行 */
      private var _textNodes:Vector.<TextField>;
      /** 上次扫描时的子节点数；变了就重扫（覆盖延迟创建的 TextField） */
      private var _textScanCount:int = -1;
      /** 文本轻签名 */
      private var _textSig:uint = 0;
      /** 最近 FPROXY_HF_WINDOW 帧"内容变了"的位图 */
      private var _dirtyMask:uint = 0;
      /** 连续无变化帧数（用于退出 HF） */
      private var _idleFrames:int = 0;
      /** 是否已判为"高频变化节点"（HF）：走独立额度 + 周期重烘 */
      private var _hf:Boolean = false;
      /** 上次心跳重烘的时刻 */
      private var _lastHeartbeatAt:int = 0;
      /** needsBake() 算出的签名，供同帧的 bake() 复用（避免第二次 DFS） */
      private var _evalSig:uint = 0;
      private var _evalSigValid:Boolean = false;
      private var _sig:uint = 0;
      private var _sigAlt:uint = 0;
      private var _epoch:int = 0;
      private var _bakedEpoch:int = -1;
      /** 诊断：本轮「滤镜值在变」里变了几帧 / 实际烘了几次。变化停止时汇总成一行（仅 FPROXY_DEBUG） */
      private var _chg:int = 0;
      private var _bakes:int = 0;
      /** 是否处在「滤镜值连续在变」的补间里（决定要不要降倍率烘） */
      private var _tweening:Boolean = false;
      private var _wantedAlpha:Number = 1;
      /**
       * "这一帧的 alpha 还没读过"。
       *
       * 两段式驱动下，帧初还原 → 游戏逻辑写 → 帧末读，**一帧只能读一次**：
       * 读完之后源已经被置 0，同一帧再读一次就会把自己写的 0 当成游戏的值
       * （新代理首帧正好踩这个坑：pending 烘完 syncVisual 一次，稳态 tick 又 syncVisual 一次）。
       */
      private var _readPending:Boolean = true;

      private var _baked:Boolean = false;
      private var _failCount:int = 0;
      /** 只覆盖 acquire→draw 的耗时，仅用于日志 `ms=`（与历史可比）；节流/判档请用 _costEma */
      private var _drawMs:int = 0;
      /** 一次 bake() 的**真实总成本**（ms）：getBounds/displayScale/填充/draw/换图全算，不含 verify 回读 */
      private var _costMs:int = 0;
      /**
       * 总成本的 EMA（0 = 还没测过）。节流门与"贵节点"判定都用它。
       *
       * 为什么不能用 `_drawMs`：它只覆盖 acquire→draw，漏掉 getBounds、displayScale、
       * swapDisplay（换 Bitmap + 重新挂载）—— 实测低估 1.3~1.6 倍，导致节流门永远偏松。
       */
      private var _costEma:int = 0;
      /**
       * 烘焙期临时使用的低 quality 滤镜副本。
       *
       * 只在 `FPROXY_GLOW_QUALITY_MAX > 0` 时才建；`bake()` 里临时替换、`finally` 立即还原。
       * 绝不做两件事：① 原地改 `gf.quality`（FilterSignature 读的是同一个对象）；
       * ② 把替换状态留到 draw 之外（SWF 自己的 filters 永远说了算）。
       */
      private var _altFilters:Array;

      private var _bakeW:int = 0;
      private var _bakeH:int = 0;
      private var _bakeScale:Number = 1;
      /** 烘焙时的"目标倍率"（预算收紧前的 displayScale）。
       *  不能拿 _bakeScale 比：预算把倍率压下来后，两者永远不等 → 会每帧判脏。 */
      private var _wantScale:Number = 1;
      /** 两次重烘的最小间隔（ms）。0 = 便宜节点，随便刷。 */
      private var _minIntervalMs:int = 0;
      /** 上次成功烘焙的时刻（getTimer） */
      private var _lastBakeAt:int = 0;
      private var _lastWasEmpty:Boolean = false;
      private var _hiding:Boolean = false;
      /** 从源继承来的平滑开关（角色/位图填充 = false） */
      private var _smoothing:Boolean = false;
      private var _smoothingReady:Boolean = false;
      /** 诊断：首次烘焙时内容是否贴到某条边（L/T/R/B），用于定位"边界被裁" */
      private var _edge:String = "";
      /** 诊断：烘焙结果中心像素 + 目标自身的 CT/blendMode，用来区分"烘出来就是黑的"还是"显示环节黑的" */
      public var diag:String = "";
      /** 调试：首次烘焙时把结果导成 PNG，给真机排查用（空串 = 不导） */
      public var debugDumpPath:String = "";

      public function FilterNodeProxy(param1:DisplayObject, param2:BitmapDataPool)
      {
         super();
         this.target = param1;
         this._pool = param2;
         this.display = new Bitmap(null,"auto",false);
         this.display.name = PROXY_NAME;
         this.display.smoothing = false;
      }

      // ------------------------------------------------------------------ 挂载

      public function attach() : Boolean
      {
         var par:DisplayObjectContainer = this.target.parent;
         if(par == null)
         {
            return false;
         }
         // 平滑只算一次，钉在挂载时：子代理时有时无会让 DFS 结果漂移
         if(!this._smoothingReady)
         {
            this._smoothing = this.inheritSmoothing();
            this._smoothingReady = true;
            this.display.smoothing = this._smoothing;
         }
         var idx:int = par.getChildIndex(this.target) + 1;
         if(idx > par.numChildren)
         {
            idx = par.numChildren;
         }
         if(this.display.parent != par)
         {
            if(this.display.parent)
            {
               this.display.parent.removeChild(this.display);
            }
            par.addChildAt(this.display,idx);
         }
         else if(par.getChildIndex(this.display) != idx)
         {
            par.setChildIndex(this.display,idx);
         }
         this.scanTextNodes();
         return true;
      }

      /**
       * 扫一遍子树找 TextField（≤24 节点 / 深度 3），结果缓存给轻签名用。
       *
       * 只在挂载时与 `numChildren` 变化时跑：纽带那类面板的目标**本身**就是一个 TextField，
       * 旧路径每帧对整棵树做 24 节点 DFS，只为发现"一行数字变了"，纯浪费。
       * 深度留到 3 是为了兼容"目标是个容器、TextField 在里面两层"的包。
       */
      private function scanTextNodes() : void
      {
         this._textNodes = null;
         this._hasText = false;
         this._textOnly = false;
         if(this.target == null)
         {
            this._textScanCount = -1;
            return;
         }
         var asContainer:DisplayObjectContainer = this.target as DisplayObjectContainer;
         this._textScanCount = asContainer != null ? asContainer.numChildren : -1;
         var stack:Vector.<DisplayObject> = new Vector.<DisplayObject>();
         var dep:Vector.<int> = new Vector.<int>();
         stack.push(this.target);
         dep.push(0);
         var seen:int = 0;
         while(stack.length > 0 && seen < 24)
         {
            var d:DisplayObject = stack.pop();
            var dd:int = dep.pop();
            seen++;
            if(d == null)
            {
               continue;
            }
            var tf:TextField = d as TextField;
            if(tf != null)
            {
               if(this._textNodes == null)
               {
                  this._textNodes = new Vector.<TextField>();
               }
               if(this._textNodes.length < 8)
               {
                  this._textNodes.push(tf);
               }
               this._hasText = true;
               continue;
            }
            var c:DisplayObjectContainer = d as DisplayObjectContainer;
            if(c == null || dd >= 3)
            {
               continue;
            }
            var i:int = 0;
            while(i < c.numChildren)
            {
               stack.push(c.getChildAt(i));
               dep.push(dd + 1);
               i++;
            }
         }
         // 只有"文本主导"的节点才走轻签名 / HF：目标本身是 TextField，
         // 或者是个只有 1~2 个子节点的薄容器（TextField 套一层 frame 的情况）。
         // 2026-10-26 按实物修正：纽带的 txt 是 MovieClip + txt1..txt8 共 8 个 TextField。
         // 只按"子节点 ≤2"判会把这种最典型的文本面板排除掉，所以补一条"文本框 ≥2 个"。
         this._textOnly = this._hasText
            && (this.target is TextField
                || (this._textNodes != null && this._textNodes.length >= 2)
                || (asContainer != null && asContainer.numChildren <= 2));
      }

      public function detach() : void
      {
         if(this.display.parent)
         {
            this.display.parent.removeChild(this.display);
         }
         this.showSource();
      }

      public function dispose() : void
      {
         this.detach();
         if(this.display.bitmapData)
         {
            this._pool.release(this.display.bitmapData);
            this.display.bitmapData = null;
         }
         this._baked = false;
      }

      public function get detached() : Boolean
      {
         return this.display.parent == null;
      }

      /**
       * 是否**需要重新挂载**。true 有两种情况：
       *   1. 代理位图被摘掉了（parent == null）；
       *   2. 源节点换了父容器（换层 / 重挂 / 对象池复用）。
       *
       * 旧实现只判第 1 种，第 2 种会让代理位图留在**旧父容器**里，而 syncTransform()
       * 又按新父容器的矩阵逐帧搬运 —— 画面上就是一张不跟手的老图挂在那儿（残影）。
       */
      public function get needsReattach() : Boolean
      {
         if(this.display.parent == null)
         {
            return true;
         }
         return this.display.parent != this.target.parent;
      }

      // ------------------------------------------------------------------ 脏标记

      /** 返回 true 表示 filters 数组变了（需要重烘）。 */
      public function refreshFilters(param1:Array) : Boolean
      {
         var s:uint = FilterSignature.compute(param1);
         var a:uint = FilterSignature.computeAlt(param1);
         if(s != this._sig || a != this._sigAlt)
         {
            this._sig = s;
            this._sigAlt = a;
            this.rebuildAltFilters(param1);
            this._tweening = true;
            this._chg++;
            return true;
         }
         if(this._chg > 0)
         {
            // 变化刚停：chg≈bakes ⇒ 补间每帧都烘上了；chg 远大于 bakes ⇒ 还有环节在丢帧；
            // chg=1 而画面中间帧没变化 ⇒ 值源本身没变（不是代理层的事）。
            if(GameConfig.FPROXY_DEBUG)
            {
               Debugger.log("[FTWEEN] chg=" + this._chg + " bakes=" + this._bakes
                            + " minMs=" + this._minIntervalMs + " cost=" + this._costEma
                            + " s=" + this._bakeScale.toFixed(2)
                            + " node=" + (this.target ? getQualifiedClassName(this.target) : "null"));
            }
            this._tweening = false;
            this._chg = 0;
            this._bakes = 0;
         }
         return false;
      }

      /**
       * 建"低 quality 滤镜副本"（仅 FPROXY_GLOW_QUALITY_MAX > 0 时）。
       *
       * 只在签名变化时重建 —— 每帧 new 一个 GlowFilter 反而比省下来的高斯 pass 更贵。
       * 只克隆不原地改：`FilterSignature` 与 SWF 手里握的都是原对象。
       */
      private function rebuildAltFilters(param1:Array) : void
      {
         this._altFilters = null;
         var cap:int = GameConfig.FPROXY_GLOW_QUALITY_MAX;
         if(cap <= 0 || param1 == null || param1.length == 0)
         {
            return;
         }
         var out:Array = null;
         var i:int = 0;
         while(i < param1.length)
         {
            var gf:GlowFilter = param1[i] as GlowFilter;
            if(gf != null && gf.quality > cap)
            {
               if(out == null)
               {
                  out = param1.slice();
               }
               out[i] = new GlowFilter(gf.color,gf.alpha,gf.blurX,gf.blurY,
                                       gf.strength,cap,gf.inner,gf.knockout);
            }
            i++;
         }
         this._altFilters = out;
      }

      public function markDirty() : void
      {
         this._epoch++;
      }

      public function get baked() : Boolean
      {
         return this._baked;
      }

      public function get lastBakeMs() : int
      {
         return this._drawMs;
      }

      public function get bakeScale() : Number
      {
         return this._bakeScale;
      }

      /** 上一次 draw 的耗时（ms），不含非空校验的回读 */
      public function get drawMs() : int
      {
         return this._drawMs;
      }

      /** 当前的最小重烘间隔（ms）。0 = 不限 */
      public function get minInterval() : int
      {
         return this._minIntervalMs;
      }

      /** 实测总成本的 EMA（ms）。0 = 还没烘过。调度层用它做单帧预算预测 */
      public function get costEma() : int
      {
         return this._costEma;
      }

      /** 上一次烘焙的真实总成本（ms，不含 verify 回读） */
      public function get costMs() : int
      {
         return this._costMs;
      }

      // ------------------------------------------------------------------ 烘焙

      /**
       * 一次 draw 烘焙（draw 会把源节点的 filters 一起烘进来，不要再 applyFilter）。
       *
       * 超过纹理/像素上限时**不跳过，而是降采样**：整屏级的滤镜（时停给 _gameLayer
       * 加 ColorMatrix）动辄 800×600，跳过就等于让 GPU 把整个场景吞掉
       * （GPU 模式对带滤镜的对象完全不渲染）。
       *
       * @param maxPad  外扩上限（逻辑像素）
       * @param qCap    滤镜 quality 上限，仅用于 pad 估算
       * @param maxTex  单边纹理上限（GPU 模式常见 1024）
       * @param maxPx   单节点像素上限
       * @param verify  true = 烘完检查结果是否全透明；全透明视为失败，调用方不得隐藏源节点
       * @param fs      调用方刚读到的 filters（复用，省一次数组分配）。null = 自己读
       * @return 是否成功
       */
      public function bake(param1:int, param2:int, param3:int, param4:int = 400000,
                           param5:Boolean = false, param6:Array = null) : Boolean
      {
         if(this.target == null || this.target.stage == null)
         {
            return false;
         }
         // 计时从**入口**开始：getBounds/displayScale/pad 估算都在里面。
         // 旧实现从 acquire 才开始计，漏掉了这些，`_minIntervalMs` 因此永远偏松。
         var tEnter:int = getTimer();
         var fs:Array = param6 != null ? param6 : this.target.filters;
         var pad:int = FilterPad.sumOf(fs,param2,param1,
            this._altFilters != null ? GameConfig.FPROXY_GLOW_QUALITY_MAX : 0);
         var b:Rectangle = this.computeBounds();
         if(b == null || b.width < 1 || b.height < 1)
         {
            return false;
         }
         var slack:int = GameConfig.FPROXY_BOUNDS_SLACK;
         if(slack < 0)
         {
            slack = 0;
         }
         var padAll:Number = pad + slack;
         var fullW:Number = b.width + padAll * 2;
         var fullH:Number = b.height + padAll * 2;
         // 倍率一次算完：超采样基准 → 单边纹理 → 像素预算，只缩不放。
         var s:Number = this.displayScale();
         // 滤镜补间期间不超采样：每帧都要重烘，像素数是平方级的成本（1.5×→1× 只剩 0.44）。
         // `wantScale` 取**钳后**值，所以补间结束那一帧 |displayScale - _wantScale| ≥ 0.25
         // 会命中 needsBake 末尾的倍率检查，自动补一次满倍率重烘，不会一直停在低倍率。
         if(this._tweening && GameConfig.FPROXY_TWEEN_SCALE_MAX > 0
            && s > GameConfig.FPROXY_TWEEN_SCALE_MAX)
         {
            s = GameConfig.FPROXY_TWEEN_SCALE_MAX;
         }
         var wantScale:Number = s;
         var byTex:Number = Math.min(param3 / fullW,param3 / fullH);
         if(byTex < s)
         {
            s = byTex;
         }
         if(fullW * fullH > 0.001)
         {
            var byPx:Number = Math.sqrt(param4 / (fullW * fullH));
            if(byPx < s)
            {
               s = byPx;
            }
         }
         if(s < 0.2)
         {
            s = 0.2;
         }
         var padPx:int = Math.ceil(padAll * s);
         var w:int = Math.ceil(fullW * s);
         var h:int = Math.ceil(fullH * s);
         if(w > param3)
         {
            w = param3;
         }
         if(h > param3)
         {
            h = param3;
         }
         if(w < 2 || h < 2)
         {
            return false;
         }
         var t0:int = getTimer();
         var bd:BitmapData = this._pool.acquire(w,h);
         bd.fillRect(bd.rect,0);
         this._m.identity();
         this._m.a = s;
         this._m.d = s;
         this._m.tx = padPx - b.x * s;
         this._m.ty = padPx - b.y * s;
         // 放大用最近邻（保住像素画的硬边），缩小必须平滑（否则丢采样点）
         var drawSmooth:Boolean = s < 0.999 ? true : this._smoothing;
         // 可选：本帧临时把 Glow/Blur 降到 FPROXY_GLOW_QUALITY_MAX 再 draw（省高斯 pass）。
         // 只在 draw 窗口内生效，finally 无条件还原 —— 源对象的 filters 最终仍由游戏决定。
         var alt:Array = this._altFilters;
         if(alt != null)
         {
            try
            {
               this.target.filters = alt;
            }
            catch(se:Error)
            {
               alt = null;
            }
         }
         var drawFailed:Boolean = false;
         try
         {
            bd.draw(this.target,this._m,null,null,null,drawSmooth);
         }
         catch(e:Error)
         {
            drawFailed = true;
         }
         finally
         {
            // 还原是硬约束：异常路径也必须走。`fs` 为 null 时绝不写回
            // （写 null 等于把游戏的滤镜抹掉，那是永久伤害）。
            if(alt != null && fs != null)
            {
               try
               {
                  this.target.filters = fs;
               }
               catch(re:Error)
               {
               }
            }
         }
         if(drawFailed)
         {
            this._pool.release(bd);
            this._failCount++;
            return false;
         }
         this._drawMs = getTimer() - t0;
         var verifyMs:int = 0;
         if(param5)
         {
            var tv:int = getTimer();
            // 安全不变量：没有内容就绝不能接管显示，否则源被藏、替身又是空的 = 角色凭空消失
            var used:Rectangle = bd.getColorBoundsRect(0xFF000000,0x00000000,false);
            if(used.isEmpty())
            {
               this._pool.release(bd);
               this._failCount++;
               this._lastWasEmpty = true;
               return false;
            }
            this._lastWasEmpty = false;
            // 贴边检测：用**请求的 w/h**，不是 bd.width（池按 32 上取整，会永远判不出右/下）
            this._edge = "";
            if(used.x <= 0)
            {
               this._edge += "L";
            }
            if(used.y <= 0)
            {
               this._edge += "T";
            }
            if(used.right >= w)
            {
               this._edge += "R";
            }
            if(used.bottom >= h)
            {
               this._edge += "B";
            }
            // 诊断彻底隔离：默认零分配、零 IO、零回读。
            // 曾经因为 PNG 编码 + FUSE 写盘留在热路径里，单次烘焙从 17ms 涨到 1224ms。
            this.diag = GameConfig.FPROXY_DEBUG ? this.buildDiag(bd,used) : "";
            verifyMs = getTimer() - tv;
         }
         this.swapDisplay(bd,this._smoothing || wantScale > s * 1.05);
         this._bounds.copyFrom(b);
         this._padPx = padPx;
         this._bakeScale = s;
         this._wantScale = wantScale;
         this._frameKey = FilterSignature.frameKey(this.target);
         // 签名复用：needsBake() 同一帧已经算过，这里再来一次纯属白做
         if(this._textOnly)
         {
            this._textSig = this._evalSigValid
               ? this._evalSig
               : FilterSignature.contentText(this._textNodes,this.target);
         }
         else
         {
            this._contentSig = this._evalSigValid
               ? this._evalSig
               : FilterSignature.content(this.target);
         }
         this._evalSigValid = false;
         // 判"贵节点"：**面积优先**（与画质档解耦的逻辑像素），成本只作高门槛补充。
         // 成本项故意取 2× 阈值：中等面积的辉光角色常有 8~10ms，一旦被误判成 _big
         // 就只能按 frameKey 判脏，AS3 驱动的动画会冻结 —— 那个回归比省下的 DFS 贵得多。
         this._big = (fullW * fullH >= HEAVY_LOGICAL_PX)
                  || (this._costEma >= GameConfig.FPROXY_HEAVY_COST_MS * 2);
         this._bakedEpoch = this._epoch;
         this._baked = true;
         this._bakes++;
         this._bakeW = w;
         this._bakeH = h;
         this._lastBakeAt = getTimer();
         this._lastHeartbeatAt = this._lastBakeAt;
         // 真实总成本：不含 verify 的像素回读（那一笔只在首烘/自校准跑，不能污染节流门）
         this._costMs = this._lastBakeAt - tEnter - verifyMs;
         if(this._costMs < 1)
         {
            this._costMs = 1;
         }
         this._costEma = this._costEma <= 0
            ? this._costMs
            : int(this._costEma * 0.7 + this._costMs * 0.3);
         this.refreshIntervalByCost();
         return true;
      }

      /**
       * 按**实测总成本**反推重烘间隔（占用固定比例的帧时间）。
       *
       * 旧公式用被低估的 `_drawMs × 3`，且写死 200 上限 —— 6~10ms 的面板在 60fps 下
       * 落到 34ms，等于每 2 帧就烘一次。现在：
       *   cost ≤ CHEAP(3ms)  → 0（不限刷）
       *   否则               → clamp(cost × FACTOR, MIN, MAX)
       * 每次成功烘焙都重算 → 成本掉下来后**自动回升**刷新率，不会只降不升。
       */
      private function refreshIntervalByCost() : void
      {
         var c:int = this._costEma > 0 ? this._costEma : this._costMs;
         if(this._hf)
         {
            // 高频节点：按"占用 1/12 帧时间"反推，下限 FPROXY_HF_MIN_MS(50ms ≈ 20 次/秒)
            var hf:Number = c * 12;
            if(hf < GameConfig.FPROXY_HF_MIN_MS)
            {
               hf = GameConfig.FPROXY_HF_MIN_MS;
            }
            if(hf > GameConfig.FPROXY_MAX_REFRESH_MS)
            {
               hf = GameConfig.FPROXY_MAX_REFRESH_MS;
            }
            this._minIntervalMs = int(hf);
            return;
         }
         if(c <= GameConfig.FPROXY_CHEAP_COST_MS)
         {
            this._minIntervalMs = 0;
            return;
         }
         var v:Number = c * GameConfig.FPROXY_COST_FACTOR;
         if(v < GameConfig.FPROXY_MIN_REFRESH_MS)
         {
            v = GameConfig.FPROXY_MIN_REFRESH_MS;
         }
         if(v > GameConfig.FPROXY_MAX_REFRESH_MS)
         {
            v = GameConfig.FPROXY_MAX_REFRESH_MS;
         }
         this._minIntervalMs = int(v);
      }

      /**
       * 换一张新 Bitmap 承载新像素。
       *
       * doc/runtime-pitfalls.md §2.1 实测：GPU 模式下只改 display.bitmapData 不保证刷新纹理，
       * 必须换掉整个 Bitmap 对象 —— 不换的后果就是"滤镜补间只出第一帧"。
       *
       * @param param2 上屏平滑。= 源是否平滑 || 预算把倍率压下去导致还要放大
       *               （不放大时用源的值：角色/像素画 → false，保持硬边）
       */
      private function swapDisplay(param1:BitmapData, param2:Boolean) : void
      {
         var old:Bitmap = this.display;
         if(old == null || old.bitmapData == null || old.parent == null)
         {
            if(old != null)
            {
               if(old.bitmapData != null && old.bitmapData != param1)
               {
                  this._pool.release(old.bitmapData);
               }
               old.bitmapData = param1;
               old.smoothing = param2;
            }
            return;
         }
         var par:DisplayObjectContainer = old.parent;
         var bmp:Bitmap = new Bitmap(param1,"auto",param2);
         bmp.name = PROXY_NAME;
         bmp.smoothing = param2;
         var idx:int = par.getChildIndex(old);
         par.addChildAt(bmp,idx);
         bmp.transform.matrix = old.transform.matrix;
         bmp.visible = old.visible;
         bmp.alpha = old.alpha;
         bmp.blendMode = old.blendMode;
         bmp.transform.colorTransform = old.transform.colorTransform;
         par.removeChild(old);
         if(old.bitmapData != null && old.bitmapData != param1)
         {
            this._pool.release(old.bitmapData);
         }
         old.bitmapData = null;
         this.display = bmp;
      }

      public function get bakeSize() : String
      {
         var p:int = int(Math.round(this._bakeScale * 100));
         return this._bakeW + "x" + this._bakeH + (p != 100 ? "@" + p + "%" : "");
      }

      public function get lastWasEmpty() : Boolean
      {
         return this._lastWasEmpty;
      }

      /** 首次烘焙时内容贴到哪几条边（L/T/R/B），空串 = 没贴边（没被裁） */
      public function get edge() : String
      {
         return this._edge;
      }

      public function get hasBitmap() : Boolean
      {
         return this.display.bitmapData != null;
      }

      public function needsBake() : Boolean
      {
         if(!this._baked)
         {
            return true;
         }
         // 滤镜值真的变了（时间轴滤镜补间 / AS3 每帧改 filters）—— 这是**事件**，不是轮询，
         // 必须排在节奏门**之前**。门关着的那些帧不会排队，变化直接丢：`_epoch` 只是个脏位，
         // 不存中间值。34~200ms 的门会把一个 3~6 帧的补间压成一两帧，
         // 观感就是"只有关键帧上的 blurX/blurY 生效"（2026-10-26 真机反馈）。
         // "一帧最多一烘"由调用方保证（tickProxies 每帧只问一次），全局预算另算。
         if(this._bakedEpoch != this._epoch)
         {
            return true;
         }
         // 节奏门从此只管"内容变没变"这类轮询判据（frameKey / 内容签名 / 文本心跳）。
         if(this._minIntervalMs > 0 && getTimer() - this._lastBakeAt < this._minIntervalMs)
         {
            return false;
         }
         // 还没找到 TextField 时，子节点数变了就重扫一次（覆盖延迟创建的文本框）。
         // 一旦找到就冻结列表：避免"每帧增删子节点"的容器把这里变成每帧 DFS。
         if(!this._hasText)
         {
            var cc:DisplayObjectContainer = this.target as DisplayObjectContainer;
            var nc:int = cc != null ? cc.numChildren : -1;
            if(nc != this._textScanCount)
            {
               this.scanTextNodes();
            }
         }
         // 已经完全透明（淡出结束 / 节点被藏起来）：烘了也看不见，别再花预算。
         // 注意位置必须放在 epoch 之后 —— 显式 markDirty（父级重烘、换画质）仍然要立刻生效。
         if(this._wantedAlpha <= 0.001)
         {
            this.trackChurn(false);
            return false;
         }

         var changed:Boolean = false;
         if(this._textOnly)
         {
            // 文本节点优先：**任何**情况下都不许走"只认帧号"那条路
            // （high 档超采样后 224×224 逻辑就会被判成 _big，一判就永久定格）。
            var ts:uint = FilterSignature.contentText(this._textNodes,this.target);
            this._evalSig = ts;
            this._evalSigValid = true;
            changed = (ts != this._textSig);
         }
         else if(this._big)
         {
            // 大节点：一次 20~30ms，只认帧号，别逐帧重来
            changed = (FilterSignature.frameKey(this.target) != this._frameKey);
         }
         else
         {
            // 小节点：结构 + 文本签名。文本框（辅助/调试面板）不走时间轴，
            // 只认帧号会让位图停在第一帧 —— 这里每帧比对，变了就重烘。
            var cs:uint = FilterSignature.content(this.target);
            this._evalSig = cs;
            this._evalSigValid = true;
            changed = (cs != this._contentSig);
         }

         if(!changed && this._textOnly && !this._hf && GameConfig.FPROXY_TEXT_HEARTBEAT_MS > 0
            && getTimer() - this._lastHeartbeatAt >= GameConfig.FPROXY_TEXT_HEARTBEAT_MS)
         {
            // 心跳：htmlText 只改样式（颜色/字体）时 text 不变，签名看不见。
            // 高频节点靠周期重烘天然覆盖；非高频文本节点靠这一条兜底。
            changed = true;
         }

         this.trackChurn(changed);
         if(!changed)
         {
            // 相机 zoom / 角色缩放变化后，旧倍率的位图会重新变糊，够一档就重烘
            if(GameConfig.FPROXY_BAKE_SCALE_MAX > 1
               && Math.abs(this.displayScale() - this._wantScale) >= 0.25)
            {
               return true;
            }
            return false;
         }
         return true;
      }

      // ------------------------------------------------------------------ 高频节点（HF）

      /**
       * 维护"内容变化"的滑动窗口，并据此判定 / 退出高频节点。
       *
       * 窗口的单位是**判定次数**，不是绝对帧号：被 `_minIntervalMs` 挡住的帧不会走到
       * 这里（否则为了判频就得每帧轮询，等于白做优化）。所以 FPROXY_HF_WINDOW=10
       * 在 34ms 门限下约等于 0.1~0.2 秒，足够识别"每帧都在变"的面板。
       *
       * 判据只看**行为**（窗口内变了几次），不看名字、不看 id —— 引擎不知道谁是
       * debug.swf，也不该知道。纽带的特征是"几乎每次都变"，血条/分数牌达不到；
       * 再加一条成本门槛（贵节点进周期档只会更糟），避免误伤时停那种整屏节点。
       */
      private function trackChurn(param1:Boolean) : void
      {
         var win:int = GameConfig.FPROXY_HF_WINDOW;
         if(win < 2)
         {
            win = 2;
         }
         if(win > 24)
         {
            win = 24;
         }
         var mask:uint = (uint(1) << win) - 1;
         this._dirtyMask = ((this._dirtyMask << 1) | (param1 ? 1 : 0)) & mask;

         if(!this._hf)
         {
            if(this._textOnly && this.popCount(this._dirtyMask) >= GameConfig.FPROXY_HF_HITS
               && (this._costEma <= 0 || this._costEma <= GameConfig.FPROXY_HF_MAX_COST_MS))
            {
               this._hf = true;
               this._idleFrames = 0;
               this.refreshIntervalByCost();
            }
            return;
         }
         if(param1)
         {
            this._idleFrames = 0;
         }
         else
         {
            this._idleFrames++;
         }
         if(this._idleFrames >= GameConfig.FPROXY_HF_IDLE_FRAMES)
         {
            this._hf = false;
            this._idleFrames = 0;
            this._dirtyMask = 0;
            this.refreshIntervalByCost();
         }
      }

      private function popCount(param1:uint) : int
      {
         var v:uint = param1;
         var n:int = 0;
         while(v != 0)
         {
            v &= v - 1;
            n++;
         }
         return n;
      }

      /** 是否被判定为"高频变化节点"（调度层给它一条独立额度） */
      public function get isHf() : Boolean
      {
         return this._hf;
      }

      // ------------------------------------------------------------------ 每帧同步

      /**
       * 变换（含 rotation / 负缩放）直接由矩阵承担，不重烘。
       *
       * 像素 → 局部：local = (u - padPx)/s + bounds
       * 局部 → 父空间：nm
       * 所以显示矩阵 = nm ∘ (T(bounds - padPx/s) · S(1/s))。
       */
      public function syncTransform() : void
      {
         if(this.display.bitmapData == null)
         {
            return;
         }
         var nm:Matrix = this.target.transform.matrix;
         // 烘焙时按 s 缩放过，显示时要把线性部分放大 1/s（平移部分由 T 承担，不参与缩放）
         var inv:Number = this._bakeScale > 0.0001 ? 1 / this._bakeScale : 1;
         var dx:Number = this._bounds.x - this._padPx * inv;
         var dy:Number = this._bounds.y - this._padPx * inv;
         this._m.a = nm.a * inv;
         this._m.b = nm.b * inv;
         this._m.c = nm.c * inv;
         this._m.d = nm.d * inv;
         this._m.tx = nm.a * dx + nm.c * dy + nm.tx;
         this._m.ty = nm.b * dx + nm.d * dy + nm.ty;
         this.display.transform.matrix = this._m;
      }

      /**
       * 帧初把源 alpha 还原成"游戏想要的显示值"。
       *
       * 与 syncVisual() 配对，由 FilterProxyManager 的两段式驱动调用：
       * 帧初（游戏逻辑之前）还原 → 游戏里的 `alpha -= x` / `alpha = 0` 都读到真值、
       * 写到真值 → 帧末读回真值、再把源藏成 0。
       *
       * 少了这一步，递减型 alpha 永远读到自己被写成的 0，效果永远淡不出去；
       * 帧末读到的 0 又会被当成"我这只写的 0"忽略 → 代理位图以最后一个非零 alpha
       * 永久挂在场上（"滤镜残影"）。还原只发生在脚本期，渲染期前又被置 0，
       * 所以这一帧合成器仍然看不到源节点。
       */
      public function unhideSourceAlpha() : void
      {
         this._readPending = true;
         if(!this._hiding || this.target == null)
         {
            return;
         }
         try
         {
            this.target.alpha = this._wantedAlpha;
         }
         catch(e:Error)
         {
         }
      }

      /**
       * 合成前的最后一道：抄下这一帧**最终**的 alpha，再把源藏回 0。
       *
       * 为什么需要：源节点用 `alpha=0` 藏起来，而人物包的 enterFrame 帧脚本、TweenLite
       * 都挂在各自的对象上，执行时机不在 stage 的优先级体系里 —— post-tick 之后仍可能
       * 有人把 alpha 写回来。不管这一帧就是"源（无滤镜）+ 代理（滤镜）"的双影。
       * Event.RENDER 是合成前唯一能兜住的时机。
       *
       * @param param1 true = 本帧 post-tick **没有**藏源（藏源也延后到这里），
       *               此刻读到 0 就是游戏真的要 0，必须照抄；
       *               false = post-tick 已经藏过，0 可能是我自己写的，只认非零值。
       */
      public function reassertHidden(param1:Boolean) : void
      {
         if(this.target == null || this.display.bitmapData == null)
         {
            return;
         }
         try
         {
            var a:Number = this.target.alpha;
            if(param1 || a != 0)
            {
               this._wantedAlpha = a;
            }
            this.target.alpha = 0;
            this._hiding = true;
            this._readPending = false;
            this.display.alpha = this._wantedAlpha;
            this.display.visible = this.target.visible;
         }
         catch(e:Error)
         {
         }
      }

      /**
       * @param param1 true = 把"藏源"推迟到 Event.RENDER 再做。
       *   脚本期源保持游戏自己的 alpha，`alpha -= x` 之类递减补间才能读到真值；
       *   合成前一律由 reassertHidden() 藏回 0，屏幕上看不到源。
       */
      public function syncVisual(param1:Boolean = false) : void
      {
         if(this.target == null)
         {
            return;
         }
         // 安全不变量：没有可显示的替身就绝不藏源。
         // 否则一旦烘焙失败，源节点 alpha=0 + 替身空 = 角色凭空消失（2026-10-23 实测踩到）。
         if(this.display.bitmapData == null)
         {
            this.showSource();
            this.display.visible = false;
            return;
         }
         // 顺序很重要：DisplayObject.alpha 与 transform.colorTransform.alphaMultiplier
         // 是同一个值。**必须在把源 alpha 置 0 之前**读取颜色变换，否则读到的是
         // alphaMultiplier=0，赋给代理就等于把代理也变透明 —— 烘得再对也看不见。
         var ct:ColorTransform = this.target.transform.colorTransform;
         // 两段式驱动下这里读到的是游戏这一帧写的**真值**（帧初已还原），
         // 所以 0 也要照抄：既可能是"效果真的淡出到 0"，也可能是"节点该消失了"。
         // 旧代码 `if(a != 0)` 把 0 一律当成自己的写回，代理就永远停在最后一个非零 alpha。
         // `_readPending` 保证一帧只读一次（读完之后源已经是 0，再读就是读自己的写回）。
         if(this._readPending || !this._hiding)
         {
            this._wantedAlpha = this.target.alpha;
            this._readPending = false;
         }
         if(!this._hiding && !param1)
         {
            this.target.alpha = 0;
            this._hiding = true;
         }
         this.display.visible = this.target.visible;
         this.display.blendMode = BlendModeCompat.map(this.target.blendMode);
         if(ct)
         {
            // alpha 统一由 display.alpha 承担，避免 CT 把它覆盖成 0
            ct.alphaMultiplier = 1;
            this.display.transform.colorTransform = ct;
         }
         this.display.alpha = this._wantedAlpha;
      }

      /** 撤销对源节点的 alpha 接管（内部用；detach 也会调）。 */
      private function showSource() : void
      {
         if(!this._hiding)
         {
            return;
         }
         try
         {
            if(this.target)
            {
               this.target.alpha = this._wantedAlpha;
            }
         }
         catch(e:Error)
         {
         }
         this._hiding = false;
      }

      public function get hiding() : Boolean
      {
         return this._hiding;
      }

      /** 代理当前照抄的 alpha（源的"真值"）。诊断用：它应该跟着游戏淡入淡出，不该冻住。 */
      public function get wantedAlpha() : Number
      {
         return this._wantedAlpha;
      }

      // ------------------------------------------------------------------ 几何 / 平滑

      /**
       * 目标"一个逻辑单位"对应多少个**设备像素**。
       *
       * 用目标自己的 concatenatedMatrix：父链的 `_gameSprite`(≈1.8) 与相机 zoom 全在里面，
       * 自身 transform 也在里面（漏掉自身 scale 会超采样不足）。
       * 取 4 个线性元素的最大值 —— 45° 旋转时 |a|/|d| 会低估 1.41 倍。
       * 量化到 0.25 步长：相机 zoom 是逐帧插值的，不量化会让 BitmapDataPool 的分桶每帧换。
       */
      private function displayScale() : Number
      {
         var k:Number = 1;
         if(this.target != null)
         {
            try
            {
               var m:Matrix = this.target.transform.concatenatedMatrix;
               if(m != null)
               {
                  k = Math.max(Math.max(Math.abs(m.a),Math.abs(m.b)),
                               Math.max(Math.abs(m.c),Math.abs(m.d)));
               }
            }
            catch(e:Error)
            {
               k = 1;
            }
         }
         if(!(k > 0) || k > 100)
         {
            return 1;
         }
         k = Math.round(k * 4) / 4;
         if(k < 1)
         {
            k = 1;
         }
         var cap:Number = GameConfig.FPROXY_BAKE_SCALE_MAX;
         if(cap < 1)
         {
            cap = 1;
         }
         if(k > cap)
         {
            k = cap;
         }
         return k;
      }

      /**
       * 内容区，**目标局部空间**（draw 不吃目标自身 transform，见 `_bounds` 的注释）。
       *
       * 带 scrollRect 的（战斗相机作用在 _gameLayer 上）只能烘可视区域：
       * 1) 全量烘会大到离谱；2) 代理是兄弟节点，拿不到祖先的裁剪。
       */
      private function computeBounds() : Rectangle
      {
         var sr:Rectangle = this.target.scrollRect;
         if(sr != null)
         {
            return sr;
         }
         return this.target.getBounds(this.target);
      }

      /**
       * 平滑跟源，不默认开。
       *
       * 有界 DFS 找最近的 Bitmap，用它的 smoothing；找不到 = false。
       * 角色是 SWF 里的**位图填充 Shape**（没有 Bitmap 对象），所以天然走 false ——
       * 正是"至少角色滤镜不能平滑处理"的要求。
       * 跳过 __fproxy：子代理的位图不是源美术，继承它会让父节点清晰度随机漂移。
       */
      private function inheritSmoothing() : Boolean
      {
         if(this.target == null)
         {
            return false;
         }
         var stack:Vector.<DisplayObject> = new Vector.<DisplayObject>();
         var depth:Vector.<int> = new Vector.<int>();
         stack.push(this.target);
         depth.push(0);
         var seen:int = 0;
         while(stack.length > 0 && seen < 48)
         {
            var n:DisplayObject = stack.pop();
            var d:int = depth.pop();
            seen++;
            if(n == null)
            {
               continue;
            }
            var bmp:Bitmap = n as Bitmap;
            if(bmp != null)
            {
               if(bmp.name == PROXY_NAME)
               {
                  continue;
               }
               return bmp.smoothing;
            }
            var c:DisplayObjectContainer = n as DisplayObjectContainer;
            if(c == null || d >= 3)
            {
               continue;
            }
            var i:int = 0;
            while(i < c.numChildren)
            {
               stack.push(c.getChildAt(i));
               depth.push(d + 1);
               i++;
            }
         }
         return false;
      }

      /**
       * 仅 GameConfig.FPROXY_DEBUG 时调用。
       * 内容 = 原来的亮度采样 + PNG 导出 + 全字段诊断串，全部搬出热路径。
       * 用局部变量拼、最后一次赋值，避免原来的 `this.diag = ...` 把前面拼好的内容冲掉。
       */
      private function buildDiag(param1:BitmapData, param2:Rectangle) : String
      {
         var out:String = "";
         // 16x16 网格平均亮度
         var lumSum:Number = 0;
         var lumN:int = 0;
         var gy:int = 0;
         while(gy < 16)
         {
            var gx:int = 0;
            while(gx < 16)
            {
               var sx:int = param2.x + int(param2.width * (gx + 0.5) / 16);
               var sy:int = param2.y + int(param2.height * (gy + 0.5) / 16);
               var pk:uint = param1.getPixel32(sx,sy);
               if((pk >>> 24) != 0)
               {
                  lumSum += (((pk >> 16) & 0xFF) * 0.3
                          + ((pk >> 8) & 0xFF) * 0.59
                          + (pk & 0xFF) * 0.11);
                  lumN++;
               }
               gx++;
            }
            gy++;
         }
         var avgLum:int = lumN > 0 ? int(lumSum / lumN) : -1;
         if(this.debugDumpPath != "")
         {
            try
            {
               var png:ByteArray = param1.encode(param1.rect,new PNGEncoderOptions(false));
               var f:File = new File(this.debugDumpPath);
               var fst:FileStream = new FileStream();
               fst.open(f,FileMode.WRITE);
               fst.writeBytes(png);
               fst.close();
               out += " png=" + f.name;
            }
            catch(pe:Error)
            {
               out += " pngErr=" + pe.errorID;
            }
         }
         out += " ink=" + int(param2.width) + "x" + int(param2.height)
            + " lum=" + avgLum + " cov=" + lumN
            + " edge=" + (this._edge == "" ? "-" : this._edge)
            + " draw=" + this._drawMs;
         var cx:int = param2.x + int(param2.width * 0.5);
         var cy:int = param2.y + int(param2.height * 0.5);
         var qx:int = param2.x + int(param2.width * 0.25);
         var qy:int = param2.y + int(param2.height * 0.25);
         var ct0:ColorTransform = this.target.transform.colorTransform;
         out += " px=" + hex32(param1.getPixel32(cx,cy))
            + " p1=" + hex32(param1.getPixel32(qx,qy))
            + " srcA=" + this.target.alpha
            + " srcV=" + this.target.visible
            + " bm=" + this.target.blendMode
            + " ctMul=" + ct0.redMultiplier + "," + ct0.greenMultiplier + "," + ct0.blueMultiplier
            + "," + ct0.alphaMultiplier
            + " ctOff=" + ct0.redOffset + "," + ct0.greenOffset + "," + ct0.blueOffset
            + " f=" + FilterSignature.describe(this.target.filters)
            + " idx=" + (this.target.parent ? this.target.parent.getChildIndex(this.target) : -1)
            + " nc=" + (this.target is DisplayObjectContainer
                        ? (this.target as DisplayObjectContainer).numChildren : -1)
            + " mc=" + (this.target is MovieClip)
            + " sr=" + (this.target.scrollRect != null)
            + " cn=" + getQualifiedClassName(this.target).split("::").pop();
         return out;
      }

      private function hex32(param1:uint) : String
      {
         var v:String = param1.toString(16).toUpperCase();
         while(v.length < 8)
         {
            v = "0" + v;
         }
         return v;
      }

      public function get failCount() : int
      {
         return this._failCount;
      }
   }
}
