package net.play5d.game.bvn.state
{
   import flash.display.DisplayObject;
   import flash.geom.*;
   import net.play5d.game.bvn.data.ConfigVO;
   import net.play5d.game.bvn.data.GameData;
   
   /**
    * 相机（几何计算器）：每帧把焦点包围盒换算成宿主的 scrollRect + scale，不持有任何显示对象。
    *
    * 2026-11-18：按 doc/37-extended/02-camera.md §6.4 把 3.7 的四个能力块**加法式**搬进来，
    * 全部由 GameData.I.config 的 cam* 开关门控（默认全 false ⇒ 与改动前逐帧一致）：
    *   块 1 距离档位   DISTANCE_ZOOMS / zoomForLevel() / setCloseZoom() / effectiveZoom()
    *   块 2 自动缩放   renderMulti() 全量 bbox + renderAutoZoom37() 夹取链
    *   块 3 留白钳制   keepFocusInFrame()（横 4.5% / 上 20% / 下 3%）
    *   块 4 震屏       trauma（平方 + 双正弦）+ punchZoom 弹簧 + zoomTweenSpd 缩放专用缓动
    * 主项目独有接口（destory / focus 第 3 参 owner / isSingleFocus / focusOwner / focusTarget /
    * singleFocusFrames / FOCUS_OWNER_*）原样保留 —— GameCameraCtrler 与 GameCameraFocusWatch 依赖它们。
    * 未搬（无调用者或依赖 FighterScaleModel，见 02-camera.md §6.1）：电影锁 setCinematicLock、
    * 单人 soloAutoZoom、closeUpZoom/closeUpZoomFor、getMaxFighterDistance。
    */
   public class GameCamera
   {
      
      /**
       * 聚焦发起方标记：
       *   FOCUS_OWNER_ENGINE = 引擎自己摆的镜头（开场 / KO / 胜利特写、cameraResume）。
       *   FOCUS_OWNER_BISHA  = 引擎发起的必杀/完凯特写。
       *   null               = 人物包/外部直调（老人物包是这么写的，必须原样支持）。
       * GameCameraFocusWatch 只接管 FOCUS_OWNER_BISHA —— 人物包自己摆的镜头由它自己收。
       */
      public static const FOCUS_OWNER_ENGINE:String = "engine";
      
      public static const FOCUS_OWNER_BISHA:String = "bisha";
      
      /**
       * 镜头距离四档（3.7 原名，只用于「定档」）：0=Far 1=Normal 2=Close 3=Very Close。
       * 把 config.camDistLevel 翻成一个缩放值送进 setCloseZoom()；运行时的连续缩放仍由包围盒反推。
       * 见 doc/37-extended/02-camera.md §4.5。
       */
      public static const DISTANCE_ZOOMS:Array = [1.8,2.3,2.8,3.4];
      
      /**
       * 距离档位是否受 camEnhance 总开关约束（任务卡内部冲突的唯一取舍点，改动只需翻转这里）：
       *   true  = 只在增强总开关打开时接管 autoZoomMin/Max（默认，保证默认值下行为与现状逐帧一致）；
       *   false = 只换取景、不看总开关（任务卡块 1 的字面要求，但默认 camDistLevel=1 会把
       *           区间从 [1,2.5] 改成 [2.3,2.875]，默认取景当场变化）。
       * 详见 refreshDistanceZoom() 的注释。
       */
      private static const DIST_LEVEL_RESPECTS_MASTER:Boolean = true;
      
      /** setCloseZoom() 里 max = min * 该比例（3.7 原值 1.25）。 */
      public var zoomMaxRatio:Number = 1.25;
      
      /** renderAutoZoom37() 的硬下界倍率（3.7 原值 0.6）。 */
      public var zoomHardMinRatio:Number = 0.6;
      
      /** 留白：左右各 4.5% 屏宽（3.7 原值）。 */
      public var framePaddingX:Number = 0.045;
      
      /** 留白：顶部 20% 屏高（3.7 原值，给跳跃/浮空）。 */
      public var frameHeadroom:Number = 0.2;
      
      /** 留白：底部 3% 屏高（3.7 原值，脚下几乎不留给空）。 */
      public var frameFootroom:Number = 0.03;
      
      /** 是否启用 keepFocusInFrame()（3.7 同名开关；真正的门控是 config.camFrameClamp）。 */
      public var keepFocusInView:Boolean = true;
      
      /** 震屏总开关（3.7 同名；真正的门控是 config.camShake）。 */
      public var shakeEnabled:Boolean = true;
      
      /** 震动最大位移振幅，世界单位（3.7 原值 24）。 */
      public var maxShakeOffset:Number = 24;
      
      /** 震动最大缩放振幅（3.7 原值 0.05）。 */
      public var maxShakeZoom:Number = 0.05;
      
      /** trauma 每帧线性衰减量（3.7 原值 0.035，60fps 下约 29 帧归零）。 */
      public var traumaDecay:Number = 0.035;
      
      /** 冲击缩放弹簧刚度（3.7 原值 0.22）。 */
      public var punchZoomStiffness:Number = 0.22;
      
      /** 冲击缩放弹簧阻尼（3.7 原值 0.62）。 */
      public var punchZoomDamping:Number = 0.62;
      
      /** 3.7 的「留白是否按角色缩放系数放大」。主项目无 FighterScaleModel，暂为占位（见 marginScaleOf）。 */
      public var scaleAwareFocus:Boolean = true;
      
      /** 3.7 的留白放大上限。主项目无 FighterScaleModel，暂为占位（见 marginScaleOf）。 */
      public var maxMarginScale:Number = 3;
      
      /**
       * 位置缓动除数（指数逼近，单位=帧）：>1 时 _rect += (目标-_rect)/tweenSpd，<=1 直接吸附。
       * 已知缺陷，见 doc/37-extended/02-camera.md §5.3，按用户要求暂不修：
       * 字段是 int —— 写 2.5 被截成 2、写 1.6 被截成 1；GameCtrl.slow(rate) 写 2.5*rate 时
       * 只要 rate<=0.4 就落到 <=1，setX/setY 走吸附分支（慢放期间镜头瞬移）。改类型会牵动全部缓动数值。
       */
      public var tweenSpd:int;
      
      public var stageSize:Point;
      
      public var focusX:Boolean = true;
      
      public var focusY:Boolean;
      
      public var offsetX:Number = 0;
      
      public var offsetY:Number = 0;
      
      public var autoZoom:Boolean = false;
      
      public var autoZoomMin:Number = 1;
      
      public var autoZoomMax:Number = 3;
      
      private var _zoom:Number = 1;
      
      private var _noTweenRect:Rectangle;
      
      private var _stage:DisplayObject;
      
      private var _stageBounds:Rectangle;
      
      private var _rect:Rectangle;
      
      private var _focus:Array;
      
      /**
       * 当前聚焦由谁发起（见 FOCUS_OWNER_ENGINE）。null = 人物包/外部直调。
       */
      private var _focusOwner:String;
      
      /**
       * 单人聚焦已持续的帧数。focus() 重新设置时归零，render() 每帧累加。
       * 注意 GameCameraFocusWatch 用的是自己的累计器，不靠这个做超时判断 ——
       * 有的包在 ENTER_FRAME 里每帧调 focus()，这个计数会一直是 0。
       */
      private var _singleFocusFrames:int;
      
      private var _point:Point;
      
      private var _stageScale:Number = 1;
      
      private var _fbR:Rectangle;
      
      private var _foffsetX:Number = 0;
      
      private var _foffsetY:Number = 0;
      
      private var _screenSize:Point;
   
      // ---------- 3.7 移植新增的状态（全部只在对应门控打开时才被写） ----------
      
      /** 缩放专用缓动覆盖值（3.7）：>=0 时覆盖 tweenSpd，-1 = 未覆盖。 */
      private var _zoomTweenSpdOverride:int = -1;
      
      /** 含震屏抖动的最终视口（3.7 的 _displayRect）；只在震屏门控触发时写入 stage。 */
      private var _displayRect:Rectangle;
      
      /** 含 punchZoom 与缩放抖动的最终缩放（3.7 的 _displayScale）。 */
      private var _displayScale:Number = 1;
      
      private var _trauma:Number = 0;
      
      private var _shakeTime:Number = 0;
      
      private var _shakeSeedX:Number = 0;
      
      private var _shakeSeedY:Number = 0;
      
      private var _punchZoomOffset:Number = 0;
      
      private var _punchZoomVel:Number = 0;
      
      /** 本帧是否真的写入了抖动（诊断用）。 */
      private var _shakeApplied:Boolean = false;
      
      /** 留白系数：最左 / 最右焦点的角色缩放系数（3.7）。 */
      private var _scL:Number = 1;
      
      private var _scR:Number = 1;
      
      /** 留白系数：全场最大角色缩放系数（3.7）。 */
      private var _scTop:Number = 1;
      
      /** effectiveZoom() 的角色缩放除数（3.7 取 FighterScaleModel.I.cameraDivisor，默认 1 = 直通）。 */
      private var _scaleDivisor:Number = 1;
      
      /** effectiveZoom() 的放宽下界（3.7 取 FighterScaleModel.I.cameraMinZoom，默认 1）。 */
      private var _scaleMinZoom:Number = 1;
      
      /** renderAutoZoom37() 的全局上限（3.7 取 FighterScaleModel.I.cameraMaxZoom，0 = 不启用）。 */
      private var _scaleMaxZoom:Number = 0;
      
      /** 距离档位懒应用：上次写入的档位与门控状态（-1 / false = 还没接管）。 */
      private var _distAppliedLevel:int = -1;
      
      private var _distAppliedGate:Boolean = false;
      
      /** 接管前的 autoZoomMin/Max（GameState.initCamera 按 cameraMaxSize 算的那份），关闭时要还原。 */
      private var _legacyAutoZoomMin:Number = 1;
      
      private var _legacyAutoZoomMax:Number = 3;
      
      public function GameCamera(param1:DisplayObject, param2:Point, param3:Point = null, param4:Boolean = false)
      {
         super();
         this._stage = param1;
         this._rect = new Rectangle(0,0,param2.x,param2.y);
         this._noTweenRect = new Rectangle(0,0,param2.x,param2.y);
         this._screenSize = new Point(param2.x,param2.y);
         this._displayRect = new Rectangle(0,0,param2.x,param2.y);
         if(param4)
         {
            this._fbR = new Rectangle();
         }
         this.stageSize = param3;
         if(!this.stageSize)
         {
            this.setStageSizeFromDisplay(this._stage);
         }
         this.setStageBounds();
         this._shakeSeedX = Math.random() * 1000;
         this._shakeSeedY = Math.random() * 1000;
      }
      
      public function destory() : void
      {
         // 2026-10-23：3.9 官方 GameCamera.destroy() 的等价实现（沿用本项目的 destory 命名）。
         this.stageSize = null;
         this._noTweenRect = null;
         this._stage = null;
         this._stageBounds = null;
         this._rect = null;
         this._focus = null;
         this._point = null;
         this._fbR = null;
         this._screenSize = null;
         this._focusOwner = null;
         this._displayRect = null;
         this._trauma = 0;
         this._punchZoomOffset = 0;
         this._punchZoomVel = 0;
         this._shakeApplied = false;
      }
      
      public function getScreenRect(param1:Boolean = false) : Rectangle
      {
         return param1 ? this._rect : this._noTweenRect;
      }
      
      public function updateNow() : void
      {
         // 3.7 的 applyInstant：位置缓动设为 0 才「立即到位」，
         // 缩放专用缓动覆盖（zoomTweenSpd >= 0）也必须临时清掉，否则这一帧缩放仍在缓动。
         var _loc1_:Number = this.tweenSpd;
         var _loc2_:int = this._zoomTweenSpdOverride;
         this.tweenSpd = 0;
         this._zoomTweenSpdOverride = -1;
         this.render();
         this.tweenSpd = _loc1_;
         this._zoomTweenSpdOverride = _loc2_;
      }
      
      public function setStageBounds(param1:Rectangle = null) : void
      {
         if(!param1)
         {
            this._stageBounds = this._stage.getBounds(this._stage);
         }
         else
         {
            this._stageBounds = param1;
         }
         this.setZoom(this._zoom);
      }
      
      public function setStageSizeFromDisplay(param1:DisplayObject) : void
      {
         this.stageSize = new Point(param1.width / param1.scaleX + this._stageBounds.x,param1.height / param1.scaleY + this._stageBounds.y);
      }
      
      public function getZoom(param1:Boolean = false) : Number
      {
         return param1 ? Number(this._stageScale) : Number(this._zoom);
      }
      
      public function setZoom(param1:Number) : void
      {
         this._zoom = param1;
         this._noTweenRect.width = this._screenSize.x / this._zoom;
         this._noTweenRect.height = this._screenSize.y / this._zoom;
         this._foffsetX = this._screenSize.x / 2 / this._zoom;
         this._foffsetY = this._screenSize.y / 2 / this._zoom;
         if(Boolean(this._fbR))
         {
            this._fbR.x = this._stageBounds.x * this._zoom;
            // 已知缺陷，见 doc/37-extended/02-camera.md §5.3，按用户要求暂不修：
            // 纵向下界乘了缩放（x 侧没乘），_stageBounds.y=-1000 时会随 zoom 放大到 -1800~-3400，
            // 拉近后镜头能滚出地图上方、露出空背景。保留 3.7 原写法，别在这里「顺手修正」。
            this._fbR.y = this._stageBounds.y * this._zoom;
            this._fbR.width = this._stageBounds.width - this._screenSize.x / this._zoom;
            this._fbR.height = this._stageBounds.height - this._screenSize.y / this._zoom;
         }
      }
      
      public function focus(param1:Array, param2:Boolean = false, param3:String = null) : void
      {
         var _loc3_:int = 0;
         this._focus = param1;
         this._focusOwner = param3;
         this._singleFocusFrames = 0;
         this._point = this._focus.length > 1 ? new Point() : null;
         if(param2)
         {
            _loc3_ = this.tweenSpd;
            this.tweenSpd = 0;
            this.render();
            this.tweenSpd = _loc3_;
         }
      }
      
      /**
       * 当前是否处于「单人特写」状态（focus 里只有一个目标）。
       */
      public function get isSingleFocus() : Boolean
      {
         return Boolean(this._focus) && this._focus.length == 1;
      }
      
      /**
       * 单人聚焦已持续帧数（focus 重设时归零）。仅供诊断，超时判断不用它。
       */
      public function get singleFocusFrames() : int
      {
         return this._singleFocusFrames;
      }
      
      /**
       * 当前聚焦发起方：FOCUS_OWNER_ENGINE = 引擎摆的镜头；null = 人物包/外部直调。
       */
      public function get focusOwner() : String
      {
         return this._focusOwner;
      }
      
      /**
       * 单人聚焦时的唯一目标；非单人状态返回 null。
       */
      public function get focusTarget() : DisplayObject
      {
         if(!this._focus || this._focus.length != 1)
         {
            return null;
         }
         return this._focus[0] as DisplayObject;
      }
      
      public function move(param1:Number, param2:Number) : void
      {
         this._focus = null;
         this._point = new Point(param1,param2);
      }
      
      public function moveCenter() : void
      {
         this._focus = null;
         this._point = new Point(this.stageSize.x / 2,this.stageSize.y / 2);
      }
      
      public function render() : void
      {
         if(!this._focus && !this._point)
         {
            return;
         }
         if(Boolean(this._focus) && this._focus.length == 1)
         {
            ++this._singleFocusFrames;
         }
         // 每帧只取一次配置（GameData.I.config 可能为 null ⇒ 全部门控按关闭处理）
         var _loc1_:ConfigVO = this.getCameraConfig();
         // 块 1：距离档位（懒应用，只在「门控 / 档位」变化时写 autoZoomMin/Max）
         this.refreshDistanceZoom(_loc1_);
         if(Boolean(this._focus) && this._focus.length > 1)
         {
            if(this.isAutoZoomEnhanceOn(_loc1_))
            {
               // 块 2 门控开：3.7 的全量 bbox 统计（3~4 人同框不再只盯首尾）
               this.renderMulti();
            }
            else
            {
               // 门控关：原版 renderTwo，逐帧与改动前一致（首尾取样 + *0.8 缩放需求）
               this.renderTwo(this._focus[0],this._focus[this._focus.length - 1]);
            }
         }
         if(this.focusX)
         {
            this.renderX();
         }
         if(this.focusY)
         {
            this.renderY();
         }
         if(this._stageScale != this._zoom)
         {
            this.renderZoom();
         }
         if(this.isFrameClampOn(_loc1_))
         {
            // 块 3：留白钳制（3.7 在 renderZoom 之后、applySet 之前，硬写 _rect 不缓动）
            this.keepFocusInFrame();
         }
         this.applySet(_loc1_);
      }
      
      /**
       * 写屏。原版只写 _rect / _stageScale；3.7 在此基础上叠 trauma 位移与 punchZoom 弹簧。
       * 门控（camEnhance && camShake）关闭、或本帧没有抖动时，仍然走原版那两行 —— 保证逐帧一致。
       */
      private function applySet(param1:ConfigVO) : void
      {
         if(this.isShakeOn(param1) && Boolean(this._displayRect))
         {
            this.updateTrauma();
            this.updatePunchSpring();
            var _loc2_:Number = this._trauma * this._trauma;
            var _loc3_:Number = 0;
            var _loc4_:Number = 0;
            var _loc5_:Number = 0;
            if(this.shakeEnabled && _loc2_ > 0)
            {
               // 两个正弦按 0.6 / 0.4 叠加 + 每帧推进的相位 ⇒ 连续噪声式抖动，不是固定频率摇晃
               _loc3_ = this.maxShakeOffset * _loc2_ * (Math.sin(this._shakeTime * 2.3 + this._shakeSeedX) * 0.6 + Math.sin(this._shakeTime * 4.1 + this._shakeSeedX * 1.7) * 0.4);
               _loc4_ = this.maxShakeOffset * _loc2_ * (Math.sin(this._shakeTime * 2.7 + this._shakeSeedY) * 0.6 + Math.sin(this._shakeTime * 3.3 + this._shakeSeedY * 1.9) * 0.4);
               _loc5_ = this.maxShakeZoom * _loc2_ * Math.sin(this._shakeTime * 5.2 + this._shakeSeedX + this._shakeSeedY);
            }
            if(_loc2_ > 0 || this._punchZoomOffset != 0)
            {
               this._displayScale = this._stageScale + this._punchZoomOffset + _loc5_;
               if(this._displayScale < 0.05)
               {
                  this._displayScale = 0.05;
               }
               this._displayRect.x = this._rect.x + _loc3_;
               this._displayRect.y = this._rect.y + _loc4_;
               this._displayRect.width = this._screenSize.x / this._displayScale + 1 >> 0;
               this._displayRect.height = this._screenSize.y / this._displayScale + 1 >> 0;
               this._stage.scrollRect = this._displayRect;
               this._stage.scaleX = this._stage.scaleY = this._displayScale;
               this._shakeApplied = true;
               return;
            }
            this._shakeApplied = false;
         }
         else if(this._shakeApplied)
         {
            // 门控被关掉：清空残留剂量，下次打开从零起算
            this.resetShakeState();
         }
         this._stage.scrollRect = this._rect;
         this._stage.scaleX = this._stage.scaleY = this._stageScale;
      }
      
      private function renderTwo(param1:DisplayObject, param2:DisplayObject) : void
      {
         var _loc3_:* = null;
         var _loc4_:* = null;
         var _loc5_:* = null;
         var _loc6_:* = null;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = 0;
         var _loc11_:Number = 0;
         if(this.focusX)
         {
            if(param1.x < param2.x)
            {
               _loc4_ = param1;
               _loc3_ = param2;
            }
            else
            {
               _loc4_ = param2;
               _loc3_ = param1;
            }
            _loc10_ = _loc3_.x - _loc4_.x;
            this._point.x = _loc4_.x + _loc10_ / 2;
         }
         if(this.focusY)
         {
            if(param1.y < param2.y)
            {
               _loc6_ = param1;
               _loc5_ = param2;
            }
            else
            {
               _loc6_ = param2;
               _loc5_ = param1;
            }
            _loc11_ = _loc5_.y - _loc6_.y;
            this._point.y = _loc6_.y + _loc11_ / 2;
         }
         if(this.autoZoom)
         {
            _loc7_ = Number(this._zoom);
            _loc8_ = Number(this._zoom);
            if(this.focusX)
            {
               _loc7_ = this._screenSize.x / _loc10_ * 0.8;
            }
            if(this.focusY)
            {
               _loc8_ = this._screenSize.y / _loc11_ * 0.8;
            }
            _loc9_ = Math.min(_loc7_,_loc8_);
            this.renderAutoZoom(_loc9_);
         }
      }
      
      /**
       * 原版夹取（只夹 [autoZoomMin, autoZoomMax]）—— 门控关闭时 renderTwo 用它，逐帧与改动前一致。
       * 3.7 那套带 effectiveZoom / zoomHardMinRatio 的夹取链在 renderAutoZoom37()。
       */
      private function renderAutoZoom(param1:Number) : void
      {
         if(param1 < this.autoZoomMin)
         {
            param1 = this.autoZoomMin;
         }
         if(param1 > this.autoZoomMax)
         {
            param1 = this.autoZoomMax;
         }
         this.setZoom(param1);
      }
      
      // ============================================================
      // 3.7 移植区（2026-11-18）
      // 源：BVNscripts/3.7扩展版参考/scripts/.../state/GameCamera.as
      // 拆解：doc/37-extended/02-camera.md §4.5~§4.8、§6.4
      // 约定：一律「加法」—— 原 renderTwo / renderAutoZoom / setX / setY 原样保留；
      //       每个块的入口都读 GameData.I.config（空判 = 全关），默认全 false 时行为不变。
      // ============================================================

      /**
       * 块 1（距离档位）：档位 → 目标缩放（3.7 原样），越界夹进 [0, DISTANCE_ZOOMS.length-1]。
       */
      public static function zoomForLevel(param1:int) : Number
      {
         if(param1 < 0)
         {
            param1 = 0;
         }
         if(param1 > DISTANCE_ZOOMS.length - 1)
         {
            param1 = DISTANCE_ZOOMS.length - 1;
         }
         return DISTANCE_ZOOMS[param1];
      }
      
      /**
       * 块 1：把目标缩放换成自动缩放区间（max = min * zoomMaxRatio，3.7 原样）。
       * 3.7 只在 initCamera() 里调一次；主项目 initCamera() 不在本次可改范围，
       * 改由 refreshDistanceZoom() 按 config.camDistLevel 懒调用。
       */
      public function setCloseZoom(param1:Number) : void
      {
         this.autoZoomMin = param1;
         this.autoZoomMax = param1 * this.zoomMaxRatio;
      }
      
      /**
       * 块 1（夹取链）：角色被放大过，镜头按同比例「放宽」（3.7 原样）。
       * 3.7 读 FighterScaleModel.I.cameraDivisor / cameraMinZoom；主项目没有该类
       * （doc/37-extended/02-camera.md §6.4 第 5 条），这里用本地字段 _scaleDivisor / _scaleMinZoom 代替，
       * 默认 1 / 1 ⇒ 走 3.7 的直通分支，结果完全等价；将来接 FighterScaleModel 只改这一处。
       */
      private function effectiveZoom(param1:Number) : Number
      {
         var _loc2_:Number = this._scaleDivisor;
         if(_loc2_ <= 0 || _loc2_ == 1 || _loc2_ == Number.POSITIVE_INFINITY)
         {
            return param1;
         }
         var _loc3_:Number = this._scaleMinZoom;
         if(_loc3_ <= 0)
         {
            _loc3_ = 1;
         }
         var _loc4_:Number = param1 / _loc2_;
         if(_loc4_ < _loc3_)
         {
            _loc4_ = _loc3_;
         }
         if(_loc4_ > param1)
         {
            _loc4_ = param1;
         }
         return _loc4_;
      }
      
      /**
       * 块 1：把 config.camDistLevel(0~3) 应用到 autoZoomMin/Max（3.7 在 initCamera 里做的事）。
       *
       * 门控取舍（任务卡内部冲突，务必留意）：
       *   · 块 1 的字面要求是「不受总开关约束，只换取景」；
       *   · 但同一张卡的硬约束是「四个门控默认全 false 时不得改变任何现有镜头行为」。
       * 而本档位默认 1 ⇒ setCloseZoom(2.3) 会把区间从 GameState.initCamera() 写的 [1,2.5]
       * 改成 [2.3,2.875]：双人相距 350~500 世界单位时画面会被明显裁切（视角宽度从 800 掉到 348）。
       * 两条要求无法同时成立，这里按硬约束优先：只在 camEnhance 打开时接管，关闭时还原接管前的区间。
       * 若要改成「只换取景、不看总开关」，把 DIST_LEVEL_RESPECTS_MASTER 改成 false（仅此一处判断）。
       *
       * 懒应用：只在「门控 / 档位」变化时写一次，不逐帧覆盖外部写入
       * （GameCameraCtrler.setAutoZoomMin/ setAutoZoomMax 仍可生效）。
       */
      private function refreshDistanceZoom(param1:ConfigVO) : void
      {
         var _loc2_:Boolean = Boolean(param1) && (DIST_LEVEL_RESPECTS_MASTER ? Boolean(param1.camEnhance) : true);
         if(_loc2_)
         {
            var _loc3_:int = int(param1.camDistLevel);
            if(this._distAppliedGate && _loc3_ == this._distAppliedLevel)
            {
               return;
            }
            if(!this._distAppliedGate)
            {
               this._legacyAutoZoomMin = this.autoZoomMin;
               this._legacyAutoZoomMax = this.autoZoomMax;
            }
            this.setCloseZoom(GameCamera.zoomForLevel(_loc3_));
            this._distAppliedLevel = _loc3_;
            this._distAppliedGate = true;
            return;
         }
         if(this._distAppliedGate)
         {
            this.autoZoomMin = this._legacyAutoZoomMin;
            this.autoZoomMax = this._legacyAutoZoomMax;
            this._distAppliedLevel = -1;
            this._distAppliedGate = false;
         }
      }
      
      /**
       * 块 2（自动缩放，门控 camEnhance && camAutoZoom）：3.7 的 renderMulti。
       * 与 renderTwo 的差别：统计**全部**焦点的 bbox（不是只取数组首尾），
       * 缩放需求用「bbox + 留白」反推（3.7 公式），而不是原版那个写死的 *0.8。
       */
      private function renderMulti() : void
      {
         var _loc1_:Number = Number.POSITIVE_INFINITY;
         var _loc2_:Number = Number.NEGATIVE_INFINITY;
         var _loc3_:Number = Number.POSITIVE_INFINITY;
         var _loc4_:Number = Number.NEGATIVE_INFINITY;
         var _loc5_:DisplayObject = null;
         var _loc6_:int = 0;
         var _loc7_:Number = 0;
         var _loc8_:Number = 0;
         var _loc9_:Number = Number(NaN);
         var _loc10_:Number = Number(NaN);
         while(_loc6_ < this._focus.length)
         {
            _loc5_ = this._focus[_loc6_] as DisplayObject;
            if(Boolean(_loc5_))
            {
               if(_loc5_.x < _loc1_)
               {
                  _loc1_ = _loc5_.x;
               }
               if(_loc5_.x > _loc2_)
               {
                  _loc2_ = _loc5_.x;
               }
               if(_loc5_.y < _loc3_)
               {
                  _loc3_ = _loc5_.y;
               }
               if(_loc5_.y > _loc4_)
               {
                  _loc4_ = _loc5_.y;
               }
            }
            _loc6_++;
         }
         if(_loc1_ > _loc2_)
         {
            return;
         }
         if(!this._point)
         {
            this._point = new Point();
         }
         _loc7_ = _loc2_ - _loc1_;
         _loc8_ = _loc4_ - _loc3_;
         if(this.focusX)
         {
            this._point.x = _loc1_ + _loc7_ / 2;
         }
         if(this.focusY)
         {
            this._point.y = _loc3_ + _loc8_ / 2;
         }
         if(this.autoZoom)
         {
            this.updateFocusScales();
            _loc9_ = this._zoom;
            _loc10_ = this._zoom;
            if(this.focusX)
            {
               _loc9_ = this._screenSize.x / (_loc7_ + (this._scL + this._scR) * this.framePaddingX * this._screenSize.x);
            }
            if(this.focusY)
            {
               _loc10_ = this._screenSize.y / (_loc8_ + (this.frameHeadroom * this._scTop + this.frameFootroom) * this._screenSize.y);
            }
            this.renderAutoZoom37(Math.min(_loc9_,_loc10_));
         }
      }
      
      /**
       * 块 2 的夹取链（3.7 的 renderAutoZoom）：
       * lo = effectiveZoom(autoZoomMin * zoomHardMinRatio)，hi = effectiveZoom(autoZoomMax)，
       * 若 _scaleMaxZoom>0（3.7 的 FighterScaleModel.cameraMaxZoom）再双向夹一次，最后 clamp(v,lo,hi)。
       * 原版 renderAutoZoom（只夹 [autoZoomMin, autoZoomMax]）保留不动，供门控关闭时的 renderTwo 使用。
       */
      private function renderAutoZoom37(param1:Number) : void
      {
         var _loc2_:Number = this.effectiveZoom(this.autoZoomMin * this.zoomHardMinRatio);
         var _loc3_:Number = this.effectiveZoom(this.autoZoomMax);
         var _loc4_:Number = this._scaleMaxZoom;
         if(_loc4_ > 0)
         {
            if(_loc3_ > _loc4_)
            {
               _loc3_ = _loc4_;
            }
            if(_loc2_ > _loc3_)
            {
               _loc2_ = _loc3_;
            }
         }
         if(param1 < _loc2_)
         {
            param1 = _loc2_;
         }
         if(param1 > _loc3_)
         {
            param1 = _loc3_;
         }
         this.setZoom(param1);
      }
      
      /**
       * 块 3（留白钳制，门控 camEnhance && camFrameClamp）：3.7 的 keepFocusInFrame。
       * 留白 = 横 4.5% / 上 20% / 下 3%（上都再乘角色缩放系数）；
       * 焦点装不下就居中，装得下但越界就顶住 —— 直接硬写 _rect（不缓动），末尾按 _fbR 再硬钳一次，
       * 与 setX/setY 的软钳形成双保险。
       */
      private function keepFocusInFrame() : void
      {
         if(!this.keepFocusInView || !this._focus || this._focus.length < 1)
         {
            return;
         }
         var _loc1_:Number = Number.POSITIVE_INFINITY;
         var _loc2_:Number = Number.NEGATIVE_INFINITY;
         var _loc3_:Number = Number.POSITIVE_INFINITY;
         var _loc4_:Number = Number.NEGATIVE_INFINITY;
         var _loc5_:DisplayObject = null;
         var _loc6_:int = 0;
         while(_loc6_ < this._focus.length)
         {
            _loc5_ = this._focus[_loc6_] as DisplayObject;
            if(Boolean(_loc5_))
            {
               if(_loc5_.x < _loc1_)
               {
                  _loc1_ = _loc5_.x;
               }
               if(_loc5_.x > _loc2_)
               {
                  _loc2_ = _loc5_.x;
               }
               if(_loc5_.y < _loc3_)
               {
                  _loc3_ = _loc5_.y;
               }
               if(_loc5_.y > _loc4_)
               {
                  _loc4_ = _loc5_.y;
               }
            }
            _loc6_++;
         }
         if(_loc1_ > _loc2_)
         {
            return;
         }
         var _loc7_:Number = this.framePaddingX * this._screenSize.x;
         this.updateFocusScales();
         var _loc8_:Number = this.frameHeadroom * this._screenSize.y * this._scTop;
         var _loc9_:Number = this.frameFootroom * this._screenSize.y;
         var _loc10_:Number = this._screenSize.x / this._stageScale;
         var _loc11_:Number = this._screenSize.y / this._stageScale;
         if(_loc2_ - _loc1_ + (_loc7_ * this._scL + _loc7_ * this._scR) >= _loc10_)
         {
            this._rect.x = (_loc1_ + _loc2_) / 2 + (_loc7_ * this._scR - _loc7_ * this._scL) / 2 - _loc10_ / 2;
         }
         else if(this._rect.x > _loc1_ - _loc7_ * this._scL)
         {
            this._rect.x = _loc1_ - _loc7_ * this._scL;
         }
         else if(this._rect.x + _loc10_ < _loc2_ + _loc7_ * this._scR)
         {
            this._rect.x = _loc2_ + _loc7_ * this._scR - _loc10_;
         }
         if(_loc4_ - _loc3_ + _loc8_ + _loc9_ >= _loc11_)
         {
            this._rect.y = (_loc3_ - _loc8_ + _loc4_ + _loc9_) / 2 - _loc11_ / 2;
         }
         else if(this._rect.y > _loc3_ - _loc8_)
         {
            this._rect.y = _loc3_ - _loc8_;
         }
         else if(this._rect.y + _loc11_ < _loc4_ + _loc9_)
         {
            this._rect.y = _loc4_ + _loc9_ - _loc11_;
         }
         if(Boolean(this._fbR))
         {
            if(this._rect.x < this._fbR.x)
            {
               this._rect.x = this._fbR.x;
            }
            if(this._rect.x > this._fbR.width)
            {
               this._rect.x = this._fbR.width;
            }
            if(this._rect.y < this._fbR.y)
            {
               this._rect.y = this._fbR.y;
            }
            if(this._rect.y > this._fbR.height)
            {
               this._rect.y = this._fbR.height;
            }
         }
      }
      
      /**
       * 3.7 原样：统计 _scTop（最大角色缩放系数）与 _scL/_scR（最左 / 最右焦点的系数）。
       * 只在 keepFocusInFrame() 与 renderMulti()（autoZoom 为真时）里被调。
       */
      private function updateFocusScales() : void
      {
         this._scL = 1;
         this._scR = 1;
         this._scTop = 1;
         if(!this.scaleAwareFocus || !this._focus)
         {
            return;
         }
         var _loc1_:Number = Number.POSITIVE_INFINITY;
         var _loc2_:Number = Number.NEGATIVE_INFINITY;
         var _loc3_:DisplayObject = null;
         var _loc4_:Number = 1;
         var _loc5_:int = 0;
         while(_loc5_ < this._focus.length)
         {
            _loc3_ = this._focus[_loc5_] as DisplayObject;
            if(Boolean(_loc3_))
            {
               _loc4_ = this.marginScaleOf(_loc3_);
               if(_loc4_ > this._scTop)
               {
                  this._scTop = _loc4_;
               }
               if(_loc3_.x < _loc1_)
               {
                  _loc1_ = _loc3_.x;
                  this._scL = _loc4_;
               }
               if(_loc3_.x > _loc2_)
               {
                  _loc2_ = _loc3_.x;
                  this._scR = _loc4_;
               }
            }
            _loc5_++;
         }
      }
      
      /**
       * 3.7 用 FighterScaleModel.I.scaleOfTarget(target) 取角色缩放系数并夹到 maxMarginScale。
       * 主项目没有 FighterScaleModel（02-camera.md §6.4 第 5 条：与 effectiveZoom 一起搬或不搬），
       * 拿不到逐角色系数 ⇒ 恒 1（留白不随角色体量放大）。结构保留，将来接入只改这一处。
       */
      private function marginScaleOf(param1:Object) : Number
      {
         return 1;
      }
      
      /**
       * 块 4（震屏，门控 camEnhance && camShake）：外部触发入口（3.7 原样 —— 剂量累加 + 重掷相位种子）。
       * 门控关闭时直接返回、不留状态，保证关掉增强后与现状一致。
       */
      public function shake(param1:Number) : void
      {
         if(!this.shakeEnabled || !this.isShakeOn(this.getCameraConfig()))
         {
            return;
         }
         this._trauma = Math.min(1,this._trauma + param1);
         this._shakeSeedX = Math.random() * 1000;
         this._shakeSeedY = Math.random() * 1000;
      }
      
      /**
       * 块 4：打击冲击缩放（3.7 原样）—— 往弹簧速度里加初速。
       */
      public function punchZoom(param1:Number) : void
      {
         if(!this.isShakeOn(this.getCameraConfig()))
         {
            return;
         }
         this._punchZoomVel += param1;
      }
      
      /**
       * 块 4：3.7 的 impact(0~1)—— 震屏与冲击缩放一起给（换人起手 / 落地 / 回合结束用）。
       */
      public function impact(param1:Number = 0.5) : void
      {
         param1 = param1 < 0 ? 0 : (param1 > 1 ? 1 : param1);
         this.shake(0.3 + param1 * 0.7);
         this.punchZoom(0.05 + param1 * 0.22);
      }
      
      /**
       * 当前震屏剂量 0~1（3.7 同名 getter，诊断用）。
       */
      public function get trauma() : Number
      {
         return this._trauma;
      }
      
      /**
       * 本帧是否真的把抖动写进了 scrollRect（诊断用）。
       */
      public function get isShaking() : Boolean
      {
         return this._shakeApplied;
      }
      
      /**
       * 3.7 原样：trauma 线性衰减，_shakeTime 每帧 +1（作相位，不会溢出到精度问题）。
       */
      private function updateTrauma() : void
      {
         this._shakeTime += 1;
         if(this._shakeTime > 100000)
         {
            this._shakeTime = 0;
         }
         if(this._trauma > 0)
         {
            this._trauma -= this.traumaDecay;
            if(this._trauma < 0)
            {
               this._trauma = 0;
            }
         }
      }
      
      /**
       * 3.7 原样：半隐式欧拉推进的欠阻尼弹簧（ζ≈0.66，会回弹一次再收敛）。
       */
      private function updatePunchSpring() : void
      {
         var _loc1_:Number = -this.punchZoomStiffness * this._punchZoomOffset - this.punchZoomDamping * this._punchZoomVel;
         this._punchZoomVel += _loc1_;
         this._punchZoomOffset += this._punchZoomVel;
         if(Math.abs(this._punchZoomOffset) < 0.0008 && Math.abs(this._punchZoomVel) < 0.0008)
         {
            this._punchZoomOffset = 0;
            this._punchZoomVel = 0;
         }
      }
      
      /**
       * 门控被关掉时清空震屏残留（剂量 / 弹簧 / 写屏标记）。
       */
      private function resetShakeState() : void
      {
         this._trauma = 0;
         this._punchZoomOffset = 0;
         this._punchZoomVel = 0;
         this._shakeApplied = false;
      }
      
      /**
       * 缩放专用缓动除数（3.7）：>= 0 时覆盖 tweenSpd，-1 = 未覆盖（回落到 tweenSpd）。
       * 已知缺陷，见 doc/37-extended/02-camera.md §5.3，按用户要求暂不修：
       * 与 tweenSpd 一样是 int —— 3.7 在 cameraFocusOne() 写 1.6/SPEED_PLUS_DEFAULT(=3.2) 会被截成 3。
       */
      public function get zoomTweenSpd() : int
      {
         return this._zoomTweenSpdOverride >= 0 ? this._zoomTweenSpdOverride : this.tweenSpd;
      }
      
      public function set zoomTweenSpd(param1:int) : void
      {
         this._zoomTweenSpdOverride = param1;
      }
      
      /**
       * 清掉缩放专用缓动的覆盖值（3.7：cameraResume / setCinematicLock(true) 时调）。
       */
      public function resetZoomTweenSpd() : void
      {
         this._zoomTweenSpdOverride = -1;
      }
      
      /**
       * 取镜头配置。GameData.I.config 在菜单 / 加载态可能为 null，
       * 这里做空判并返回 null —— 所有门控见 null 一律按「全关」处理。
       */
      private function getCameraConfig() : ConfigVO
      {
         var _loc1_:GameData = GameData.I;
         if(!_loc1_)
         {
            return null;
         }
         return _loc1_.config;
      }
      
      /** 门控（块 2）：自动缩放 = 增强总开关 && 自动缩放开关。 */
      private function isAutoZoomEnhanceOn(param1:ConfigVO) : Boolean
      {
         return Boolean(param1) && param1.camEnhance && param1.camAutoZoom;
      }
      
      /** 门控（块 3）：留白钳制 = 增强总开关 && 留白开关。 */
      private function isFrameClampOn(param1:ConfigVO) : Boolean
      {
         return Boolean(param1) && param1.camEnhance && param1.camFrameClamp;
      }
      
      /** 门控（块 4）：震屏 = 增强总开关 && 震屏开关。 */
      private function isShakeOn(param1:ConfigVO) : Boolean
      {
         return Boolean(param1) && param1.camEnhance && param1.camShake;
      }
      
      /**
       * 门控（缩放块）：缩放专用缓动 / 拉远限速。
       * 它属于「缩放」块，故跟 camEnhance && camAutoZoom（若要跟震屏块走，改这一行即可）。
       */
      private function isZoomEaseOn() : Boolean
      {
         var _loc1_:ConfigVO = this.getCameraConfig();
         return Boolean(_loc1_) && _loc1_.camEnhance && _loc1_.camAutoZoom;
      }
      
      private function renderX() : void
      {
         var _loc1_:Number = NaN;
         _loc1_ = Number(this._point ? this._point.x : this._focus[0].x);
         _loc1_ -= this._foffsetX + this.offsetX;
         this.setX(_loc1_);
      }
      
      private function renderY() : void
      {
         var _loc1_:Number = NaN;
         _loc1_ = Number(this._point ? this._point.y : this._focus[0].y);
         _loc1_ -= this._foffsetY + this.offsetY;
         this.setY(_loc1_);
      }
      
      public function setX(param1:Number) : void
      {
         if(Boolean(this._fbR))
         {
            if(param1 < this._fbR.x)
            {
               param1 = Number(this._fbR.x);
            }
            if(param1 > this._fbR.width)
            {
               param1 = Number(this._fbR.width);
            }
         }
         this._noTweenRect.x = param1;
         if(this.tweenSpd > 1)
         {
            this._rect.x += (param1 - this._rect.x) / this.tweenSpd;
         }
         else
         {
            this._rect.x = param1;
         }
      }
      
      public function setY(param1:Number) : void
      {
         if(Boolean(this._fbR))
         {
            if(param1 < this._fbR.y)
            {
               param1 = Number(this._fbR.y);
            }
            if(param1 > this._fbR.height)
            {
               param1 = Number(this._fbR.height);
            }
         }
         this._noTweenRect.y = param1;
         if(this.tweenSpd > 1)
         {
            this._rect.y += (param1 - this._rect.y) / this.tweenSpd;
         }
         else
         {
            this._rect.y = param1;
         }
      }
      
      /**
       * 推进 _stageScale。
       * 门控关（默认）：与原版逐字一致，用 tweenSpd。
       * 门控开：3.7 的缩放通道 —— zoomTweenSpd 覆盖值（默认回落到 tweenSpd）+ 拉远限速
       * （_zoom < _stageScale 且 spd > 2 时压到 2 ⇒ 推近慢、拉远快）。
       * 3.7 这里还有 !_cinematicLock 判断，电影锁属于「未搬」项（02-camera.md §6.1），故不保留。
       */
      private function renderZoom() : void
      {
         if(this._zoom <= 0)
         {
            throw new Error("zoom 不能 <= 0 !");
         }
         var _loc1_:int = 0;
         if(this.isZoomEaseOn())
         {
            _loc1_ = this.zoomTweenSpd;
            if(this._zoom < this._stageScale && _loc1_ > 2)
            {
               _loc1_ = 2;
            }
         }
         else
         {
            _loc1_ = this.tweenSpd;
         }
         if(_loc1_ > 1)
         {
            this._stageScale += (this._zoom - this._stageScale) / _loc1_;
         }
         else
         {
            this._stageScale = this._zoom;
         }
         this._rect.width = this._screenSize.x / this._stageScale + 1 >> 0;
         this._rect.height = this._screenSize.y / this._stageScale + 1 >> 0;
      }
   }
}

