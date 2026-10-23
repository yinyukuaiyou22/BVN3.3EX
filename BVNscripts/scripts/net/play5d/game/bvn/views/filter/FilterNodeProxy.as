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
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.utils.ByteArray;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.utils.BlendModeCompat;

   /**
    * 单个「带滤镜节点」的位图代理。
    *
    * 工作原理（实测依据见 tools/Test/_report/2026-10-23_GPU滤镜探针结论.md）：
    *   1. 源节点原地不动，只把 alpha 置 0 —— GPU 合成器就没东西可画了；
    *   2. 在**同一个父容器、紧跟源的 z 序**插一张 Bitmap；
    *   3. Bitmap 的像素 = 源节点在自身局部坐标系里 draw 的结果。
    *      draw() 会把源节点的 filters 一起烘进去（实测），所以**不要再 applyFilter**。
    *   4. 每帧只把 transform.matrix / alpha / visible / colorTransform / blendMode 拷给 Bitmap，
    *      形状没变就完全不动像素。
    *
    * 为什么是兄弟位图而不是镜像树：子节点的代理本身就是父节点的子显示对象，
    * 父级重烘时自动包含它，嵌套滤镜天然合成，不需要结构 diff、不需要重挂、不需要 hitTest 反算。
    */
   public class FilterNodeProxy
   {
      public static const PROXY_NAME:String = "__fproxy";

      public var target:DisplayObject;
      public var display:Bitmap;

      private var _pool:BitmapDataPool;

      private var _m:Matrix = new Matrix();
      private var _bounds:Rectangle = new Rectangle();
      private var _pad:int = 0;
      private var _frameKey:int = -1;
      private var _sig:uint = 0;
      private var _sigAlt:uint = 0;
      private var _epoch:int = 0;
      private var _bakedEpoch:int = -1;
      private var _wantedAlpha:Number = 1;
      private var _baked:Boolean = false;
      private var _failCount:int = 0;
      private var _lastBakeMs:int = 0;
      private var _bakeW:int = 0;
      private var _bakeScale:Number = 1;
      /**
       * 重节点（整屏级）标记。
       * GPU 模式下 draw() 整屏节点要回读纹理：实测 800x600 的地图层一次要 1.2 秒。
       * 所以「面积大」或「单次烘焙 > 60ms」的节点一律按重节点处理：
       * **只在建立/签名变化/显式 invalidate 时烘一次，绝不按帧刷新**。
       */
      private static const HEAVY_AREA:int = 200000;
      /** 单次烘焙 ≥ 一帧(60fps) 就不该逐帧刷 —— 去调试开销后按真机 17~29ms 标定 */
      private static const HEAVY_MS:int = 16;
      /** 单次烘焙 ≥ 3 帧就永不自动重烘（时停期间场景本来就是静止的） */
      private static const HEAVY_SLOW_MS:int = 120;
      /** 重节点的烘焙分辨率上限（长边），避免冻结 */
      private static const HEAVY_MAX_SIDE:int = 512;
      private var _heavy:Boolean = false;
      /** 单次烘焙超过这个耗时就不能再自动刷新了（否则就是周期性卡死） */
      private var _heavySlow:Boolean = false;
      private var _lastHeavyAt:int = -1000;
      public var frameNow:int = 0;
      private var _bakeH:int = 0;
      private var _lastWasEmpty:Boolean = false;
      private var _lastInkBounds:Rectangle;
      private var _hiding:Boolean = false;
      /** 诊断：烘焙结果中心像素 + 目标自身的 CT/blendMode，用来区分"烘出来就是黑的"还是"显示环节黑的" */
      public var diag:String = "";
      /** 调试：首次烘焙时把结果导成 PNG，给真机排查用（空串 = 不导） */
      public var debugDumpPath:String = "";

      public function FilterNodeProxy(param1:DisplayObject, param2:BitmapDataPool)
      {
         super();
         this.target = param1;
         this._pool = param2;
         this.display = new Bitmap(null,"auto",true);
         this.display.name = PROXY_NAME;
         this.display.smoothing = true;
      }

      // ------------------------------------------------------------------ 挂载

      public function attach() : Boolean
      {
         var par:DisplayObjectContainer = this.target.parent;
         if(par == null)
         {
            return false;
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
         return true;
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
            return true;
         }
         return false;
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
         return this._lastBakeMs;
      }

      // ------------------------------------------------------------------ 烘焙

      /**
       * 一次 draw 烘焙（draw 会把源节点的 filters 一起烘进来，不要再 applyFilter）。
       *
       * 超过纹理/像素上限时**不跳过，而是降采样**：整屏级的滤镜（时停给 _gameLayer
       * 加 ColorMatrix）动辄 800×600，跳过就等于让 GPU 把整个场景吞掉
       * （GPU 模式对带滤镜的对象完全不渲染）。
       *
       * @param maxPad  外扩上限
       * @param qCap    滤镜 quality 上限，仅用于 pad 估算
       * @param maxTex  单边纹理上限（GPU 模式常见 1024）
       * @param maxPx   单节点像素上限
       * @param verify  true = 烘完检查结果是否全透明；全透明视为失败，调用方不得隐藏源节点
       * @return 是否成功
       */
      public function bake(param1:int, param2:int, param3:int, param4:int = 400000,
                           param5:Boolean = false) : Boolean
      {
         if(this.target == null || this.target.stage == null)
         {
            return false;
         }
         var t0:int = 0;
         var fs:Array = this.target.filters;
         var pad:int = FilterPad.sumOf(fs,param2,param1);
         // 有 scrollRect 的节点（战斗相机就作用在 _gameLayer 上）只能烘可视区域：
         // 1) 全量烘会大到离谱；2) 代理是兄弟节点，拿不到祖先的裁剪
         var sr:Rectangle = this.target.scrollRect;
         var b:Rectangle = sr != null ? sr : this.target.getBounds(this.target);
         var fullW:Number = b.width + pad * 2;
         var fullH:Number = b.height + pad * 2;
         if(fullW < 2 || fullH < 2)
         {
            return false;
         }
         // 整屏级节点直接压到长边 512：GPU 模式下 draw() 的回读代价跟像素数强相关
         var side:int = param3;
         var budget:int = param4;
         if(fullW * fullH > HEAVY_AREA)
         {
            side = HEAVY_MAX_SIDE;
            budget = HEAVY_MAX_SIDE * HEAVY_MAX_SIDE;
         }
         // 先按单边限制缩，再按像素预算缩
         var s:Number = 1;
         if(fullW > side)
         {
            s = side / fullW;
         }
         if(fullH > side && side / fullH < s)
         {
            s = side / fullH;
         }
         var px:Number = fullW * fullH * s * s;
         if(px > budget)
         {
            s = s * Math.sqrt(budget / px);
         }
         if(s > 1)
         {
            s = 1;
         }
         if(s < 0.2)
         {
            s = 0.2;
         }
         var w:int = Math.ceil(fullW * s);
         var h:int = Math.ceil(fullH * s);
         if(w < 2 || h < 2)
         {
            return false;
         }
         t0 = getTimer();
         var bd:BitmapData = this._pool.acquire(w,h);
         bd.fillRect(bd.rect,0);
         this._m.identity();
         this._m.a = s;
         this._m.d = s;
         this._m.tx = (pad - b.x) * s;
         this._m.ty = (pad - b.y) * s;
         try
         {
            bd.draw(this.target,this._m,null,null,null,true);
         }
         catch(e:Error)
         {
            this._pool.release(bd);
            this._failCount++;
            return false;
         }
         if(param5)
         {
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
            this._lastInkBounds = used;
            // 诊断彻底隔离：默认零分配、零 IO、零回读。
            // 曾经因为 PNG 编码 + FUSE 写盘留在热路径里，单次烘焙从 17ms 涨到 1224ms。
            this.diag = GameConfig.FPROXY_DEBUG ? this.buildDiag(bd,used) : "";
         }
         if(this.display.bitmapData && this.display.bitmapData != bd)
         {
            this._pool.release(this.display.bitmapData);
         }
         this.display.bitmapData = bd;
         this._bounds.copyFrom(b);
         this._pad = pad;
         this._bakeScale = s;
         this._frameKey = FilterSignature.frameKey(this.target);
         this._bakedEpoch = this._epoch;
         this._baked = true;
         this._lastBakeMs = getTimer() - t0;
         this._bakeW = w;
         this._bakeH = h;
         // 注意：必须用**降采样前**的 fullW*fullH。用烘焙后的 w*h 时，
         // HEAVY_MAX_SIDE=512 会把整屏节点压到 512*273 < HEAVY_AREA，永远判不出重节点。
         this._heavy = (fullW * fullH >= HEAVY_AREA) || (this._lastBakeMs >= HEAVY_MS);
         this._heavySlow = this._lastBakeMs >= HEAVY_SLOW_MS;
         this._lastHeavyAt = this.frameNow;
         return true;
      }

      public function get bakeSize() : String
      {
         return this._bakeW + "x" + this._bakeH
            + (this._bakeScale < 0.999 ? "@" + int(this._bakeScale * 100) + "%" : "");
      }

      public function get lastWasEmpty() : Boolean
      {
         return this._lastWasEmpty;
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
         if(this._bakedEpoch != this._epoch)
         {
            return true;
         }
         if(this._heavy)
         {
            // 重节点：慢的（>200ms，比如整屏地图层）只烘一次；快的（比如 HUD）按 2fps 兜底刷新
            if(this._heavySlow)
            {
               return false;
            }
            return this.frameNow - this._lastHeavyAt >= 30;
         }
         return FilterSignature.frameKey(this.target) != this._frameKey;
      }

      // ------------------------------------------------------------------ 每帧同步

      /** 变换（含 rotation / 负缩放）直接由矩阵承担，不重烘。 */
      public function syncTransform() : void
      {
         if(this.display.bitmapData == null)
         {
            return;
         }
         var nm:Matrix = this.target.transform.matrix;
         var dx:Number = this._bounds.x - this._pad;
         var dy:Number = this._bounds.y - this._pad;
         // 烘焙时按 s 缩小过，显示时要把线性部分放大 1/s（平移部分由 T 承担，不参与缩放）
         var inv:Number = this._bakeScale > 0.0001 ? 1 / this._bakeScale : 1;
         this._m.a = nm.a * inv;
         this._m.b = nm.b * inv;
         this._m.c = nm.c * inv;
         this._m.d = nm.d * inv;
         this._m.tx = nm.a * dx + nm.c * dy + nm.tx;
         this._m.ty = nm.b * dx + nm.d * dy + nm.ty;
         this.display.transform.matrix = this._m;
      }

      /** alpha / visible / 染色 / 混合模式：捕获源上的写入，转嫁给代理位图。 */
      public function syncVisual() : void
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
         var a:Number = this.target.alpha;
         if(a != 0)
         {
            this._wantedAlpha = a;
         }
         if(!this._hiding)
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
            + " lum=" + avgLum + " cov=" + lumN;
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
