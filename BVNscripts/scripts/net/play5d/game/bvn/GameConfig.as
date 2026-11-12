package net.play5d.game.bvn
{
   import flash.geom.*;
   import flash.system.Capabilities;
   
   public class GameConfig
   {
      
      public static var TOUCH_MODE:Boolean = true;

      /**
       * 是否运行在移动端（Android/iOS）。按 Capabilities.version 判定，类初始化即可用。
       * 注意：TOUCH_MODE 在 PC 上也是 true（触控版 UI 也在桌面跑），**不能**当平台判据。
       */
      public static var IS_MOBILE:Boolean = Capabilities.version.indexOf("AND") !== -1
                                            || Capabilities.version.indexOf("IOS") !== -1;
      
      public static var INFINITE_ENERGY:Boolean = false;
      
      public static const G:Number = 12;
      
      public static const G_ADD:Number = 1.2;
      
      public static const G_ON_FLOOR:Number = 4;
      
      public static var FPS_GAME:int = 60;
      
      public static const FPS_UI:int = 30;
      
      public static const FPS_ANIMATE:int = 30;
      
      public static var FPS_SHINE_EFFECT:int = 15;
      
      public static var SHOW_HOW_TO_PLAY:Boolean = true;
      
      public static const BULLET_HOLD_FRAME_PLUS:Number = 2;
      
      public static const JUMP_DELAY_FRAME:int = 2;
      
      public static const JUMP_DELAY_FRAME_AIR:int = 1;
      
      public static const JUMP_DAMPING:Number = 0.5;
      
      public static const HURT_JUMP_FRAME:int = 15;
      
      public static const HURT_GAP_FRAME:int = 4;
      
      public static const BREAK_DEF_GAP_FRAME:int = 4;
      
      public static const BREAK_DEF_DOWN_GAP_FRAME:int = 10;
      
      public static const BREAK_DEF_HOLD_FRAME:int = 42;
      
      public static const DEFENSE_GAP_FRAME:int = 4;
      
      public static const DEFENSE_DAMPING_X:Number = 1;
      
      public static const DEFENSE_GAP_FRAME_DOWN:int = 8;
      
      public static const DEFENSE_LOSE_HP_RATE:Number = 0.05;
      
      public static const DEFENSE_HOLD_FRAME_MIN:int = 5;
      
      public static const DEFENSE_HOLD_FRAME_MAX:int = 10;
      
      public static const DEFENSE_HOLD_FRAME_DOWN:int = 10;
      
      public static const HURT_DAMPING_X:Number = 0.1;
      
      public static const HURT_DAMPING_Y:Number = 0.5;
      
      public static const HURT_Y_ADD_INAIR:Number = 3;
      
      public static const HURT_Y_ADD:Number = 6;
      
      public static const STEEL_HURT_GAP_FRAME:int = 4;
      
      public static const STEEL_HURT_DOWN_GAP_FRAME:int = 10;
      
      public static const STEEL_HURT_HP_PERCENT:Number = 0.65;
      
      public static const STEEL_SUPER_HURT_HP_PERCENT:Number = 0.3;
      
      public static const HURT_FLY_DAMPING_X:Number = 0;
      
      public static const HURT_FLY_DAMPING_Y:Number = 0.5;
      
      public static const HIT_FLOOR_DAMPING_X:Number = 2;
      
      public static const HIT_FLOOR_DAMPING_X_HEAVY:Number = 4;
      
      public static const HIT_FLOOR_TAN_Y_MIN:Number = 3;
      
      public static const HIT_FLOOR_TAN_Y_MAX:Number = 8;
      
      public static const HIT_DOWN_FRAME:int = 15;
      
      public static const HIT_DOWN_FRAME_HEAVY:int = 30;
      
      public static const HIT_DOWN_BY_HITY:int = 5;
      
      public static const NO_TOUCH_BAN_ON_VECY:int = 5;
      
      public static var HURT_FRAME_OFFSET:int = 3;
      
      public static const X_SIDE_OFFSET:int = 10;
      
      public static const HURT_DOWN_JUMP_FRAME:int = 20;
      
      public static const HURT_DOWN_JUMP_DAMPING:int = 1;
      
      public static const USE_ENERGY_CD:Number = 0.8;
      
      public static const ENERGY_ADD_NORMAL:Number = 2;
      
      public static const ENERGY_ADD_DEFENSE:Number = 0.8;
      
      public static const ENERGY_ADD_ATTACKING:Number = 1.1;
      
      public static const ENERGY_ADD_OVER_LOAD_PERFRAME:Number = 0.6;
      
      public static const ENERGY_ADD_OVER_LOAD_RESUME:Number = 30;
      
      public static const QI_ADD_HIT_BISHA_RATE:Number = 0;
      
      public static const QI_ADD_HIT_RATE:Number = 0.17;
      
      public static const QI_ADD_HIT_BULLET_RATE:Number = 0.1;
      
      public static const QI_ADD_HIT_ATTACKER_RATE:Number = 0.13;
      
      public static const QI_ADD_HIT_ASSISTER_RATE:Number = 0.15;
      
      public static const QI_ADD_HIT_MAX:Number = 15;
      
      public static const QI_ADD_HURT_RATE:Number = 0.08;
      
      public static const QI_ADD_HURT_MAX:Number = 20;
      
      public static const FUZHU_QU_ADD_PERFRAME:Number = 0.2;

      // ===== 换人模式（TAG，模式 16/17）参数 =====
      /** 换人槽每帧回复量。0.8/帧 @30Hz ⇒ 100/0.8 = 125 帧 ≈ 4.2 秒回满（原辅助槽是 0.2 ⇒ 16.7 秒，换人太迟钝） */
      public static const TAG_FUZHU_ADD_PERFRAME:Number = 0.8;

      /**
       * 切出的角色无敌时长（秒）。注意：计时在 renderAnimate 里递减，单位是 30Hz 帧，别用 FPS_GAME 换。
       * 2026-10-30 用户实测后**减半**：2 秒 → 1 秒（30 帧）。
       * 原因：无敌期没有任何闪烁/半透明提示，2 秒内对手打不动会被当成"打不到"的 bug。
       */
      public static const TAG_INVINCIBLE_SECONDS:Number = 1;

      /** 空中换人额外消耗的气（与鬼步的 qi 价一致） */
      public static const TAG_AIR_SWITCH_QI:Number = 60;

      /** 空中换人的时停时长（秒），与鬼步一致：0.4s */
      public static const TAG_FREEZE_SECONDS:Number = 0.4;

      /**
       * 空中换人时继承「向上」速度的系数（0 = 完全不继承上升）。
       * 换人后会整池继承离场者的速度，若原角色正在上升，新角色会继续往上飘 ——
       * 用户 2026-10-30 反馈「空中换人往上漂浮」，故把向上分量按此系数衰减。
       */
      public static const TAG_AIR_SWITCH_UP_KEEP:Number = 0.25;

      /** 空中换人时停期间额外施加的 Y 轴阻力（越大沉降越快；时停结束会清零，不影响后续正常重力） */
      public static const TAG_AIR_SWITCH_Y_DAMPING:Number = 0.8;

      public static const CAMERA_TWEEN_SPD:Number = 2.5;
      
      public static const FIGHTER_HP_MAX:int = 1000;
      
      public static var MAP_LOGO_STATE:int = 0;
      
      public static const GAME_SIZE:Point = new Point(800,600);
      
      public static var SPEED_PLUS:Number = SPEED_PLUS_DEFAULT;

      // ================================================================
      // GPU 滤镜位图代理层（2026-10-23）
      //
      // 背景：renderMode=gpu 下合成器**完全不渲染** DisplayObject.filters
      // （实测见 tools/Test/_report/2026-10-23_GPU滤镜探针结论.md），
      // 而 BitmapData.draw() 会连滤镜一起烘出来，所以在节点旁边挂一张代理位图。
      //
      // 这些是派生的运行时策略，唯一权威来源是 ConfigVO.quality（玩家可见档位），
      // 由 FilterProxyManager.applyQualityPreset 覆盖；**不进存档**。
      // ================================================================

      /** 总开关。false = 完全回到没有兼容层的行为（用于 A/B 排查） */
      public static var GPU_FILTER_PROXY:Boolean = true;

      /**
       * 钢身/金身轮廓滤镜（EffectCtrl.startFilter → BitmapFilterView）总开关。
       * 2026-11-12：手机端由「滤镜效果（实验功能）」写入；PC 端保持 true 不变。
       * 关闭时只省略轮廓视图，钢身状态位与判定照常。
       */
      public static var FILTER_EFFECT_ENABLED:Boolean = true;

      /** 并发代理上限 */
      public static var FPROXY_MAX_PROXIES:int = 12;

      /** 每帧最多烘几个节点（0 = 不限，仅调试用） */
      public static var FPROXY_MAX_BAKE_PER_FRAME:int = 2;

      /** 每帧烘焙像素总预算（要 ≥ 2× 单张上限，否则等价于"每帧只烘 1 张"） */
      public static var FPROXY_MAX_BAKE_PIXELS_PER_FRAME:int = 2200000;

      /**
       * 超采样上限：烘焙倍率 = min(节点在屏幕上的实际缩放, 本值)。
       *
       * 背景：游戏是 800×600 逻辑空间，`_gameSprite` 再放大到设备像素
       * （1080p 竖屏 ≈ 1.8×），相机还叠 1~2.5 的 zoom。按 1:1 烘出来的位图
       * 上屏时被放大 1.8~4.5 倍 —— 这就是"滤镜让图变糊/像被压缩"的根因。
       * 本值由 applyQualityPreset 按画质档位覆盖（low=1 / medium=1.5 / high,best=2）。
       */
      public static var FPROXY_BAKE_SCALE_MAX:Number = 2;

      /**
       * **滤镜补间期间**的烘焙倍率上限（0 = 不特殊处理，沿用 FPROXY_BAKE_SCALE_MAX）。
       *
       * 滤镜值一变就要重烘，补间那几帧是每帧一次 draw。像素数按倍率平方涨，
       * 1.5×→1× 就是 ×0.44，光栅化 / 高斯 pass / 纹理上传一起省。
       * 补间期间画面本来就是糊的，降这一档基本看不出来；补间结束后
       * `_wantScale` 取的是钳后值，needsBake 的倍率差会自动触发一次满倍率重烘。
       */
      public static var FPROXY_TWEEN_SCALE_MAX:Number = 1;

      /**
       * 单节点两次重烘的最小间隔（ms）下限。0 = 不限。
       *
       * 只对"烘焙本身较贵"的节点生效（draw ≤4ms 的便宜节点仍然按帧刷），
       * 用来替代原来"重节点 30 帧刷一次 / 超 120ms 永久冻结"的粗暴规则：
       * 旧规则会让带滤镜补间的节点停在某一帧。
       */
      public static var FPROXY_MIN_REFRESH_MS:int = 34;

      /** 烘焙区域的余量（逻辑像素）。防止 getBounds 的浮点/抗锯齿边被削掉。 */
      public static var FPROXY_BOUNDS_SLACK:int = 2;

      /**
       * 每帧烘焙**时间**预算（ms）。0 = 不限制（仅调试用）。
       *
       * 只约束「同帧叠加」：单次 BitmapData.draw() 不可分割，
       * 所以单帧峰值 ≈ max(单节点最大耗时, 本预算)，不可能压到预算以内。
       * 实测（真机 09:55 会话，无调试开销）：4 个整屏节点合计 77ms，
       * 单节点最大 29ms —— 6ms 预算下会摊到 5~6 帧。
       *
       * 2026-10-25：8 → 6。压尖峰靠的是逐节点成本预测（FilterProxyManager.canAfford），
       * 不是把这个值砍到很小 —— 砍到 4 只会让多节点场景排队更久。
       */
      public static var FPROXY_BAKE_BUDGET_MS:int = 6;

      // ---------------- 成本自适应（2026-10-25：治"高频变化节点"卡顿） ----------------
      //
      // 背景：纽带（debug.swf）面板上的 TextField 每帧都在变，代理层只能靠轮询发现。
      // 它的烘焙是 493×187@150%（池 512×192），单次 6~10ms；而在 60fps 下
      // FPROXY_MIN_REFRESH_MS=34 等于"每 2 帧就烘一次" —— 每次还要换一张 Bitmap
      // 并上传 393KB 纹理。结果就是"每 2 帧抖一下"。
      //
      // 对策不是简单降频（用户要低延迟），而是：把单次成本压到可测量、把刷新率
      // 按**实测成本**反推（占用固定比例的帧时间），并给高频节点单独一条通道。

      /**
       * 烘焙期把 Glow/Blur 的 quality 临时降到这个上限（0 = 关闭）。
       *
       * 只在**本帧 draw() 窗口内**替换 filters，finally 立即还原 —— 不改 SWF、不写资源。
       * 默认 0：先上主程序侧优化，实测 cost 仍偏高再打开（6~10ms → 3.5~6ms，辉光略"硬"）。
       */
      public static var FPROXY_GLOW_QUALITY_MAX:int = 0;

      /** 实测总成本 ≤ 此值的节点视为"便宜节点"，不限刷（0 = 全部限刷） */
      public static var FPROXY_CHEAP_COST_MS:int = 3;

      /** 重烘间隔 = 实测总成本 × 本系数（≈"占用 1/N 帧"），再夹到 [MIN_REFRESH_MS, MAX_REFRESH_MS] */
      public static var FPROXY_COST_FACTOR:Number = 4;

      /** 重烘间隔上限（ms）。永不封死 —— 再贵也按这个频率走 */
      public static var FPROXY_MAX_REFRESH_MS:int = 200;

      /** 判"贵节点"（_big）的成本阈值（ms）。按成本判、与画质档无关 */
      public static var FPROXY_HEAVY_COST_MS:int = 8;

      /** 预算预测的首帧估值（ms）：还没实测过成本的节点按这个占位 */
      public static var FPROXY_FIRST_COST_GUESS_MS:int = 8;

      /** 高频变化节点（HF）每帧独占的烘焙张数。**不占** FPROXY_MAX_BAKE_PER_FRAME 的额度 */
      public static var FPROXY_HF_BAKE_PER_FRAME:int = 1;

      /** HF 节点的重烘间隔下限（ms）。50 → 最多 20 次/秒；实际间隔取 max(本值, 成本×12) */
      public static var FPROXY_HF_MIN_MS:int = 50;

      /** 判定 HF 的滑动窗口（帧） */
      public static var FPROXY_HF_WINDOW:int = 10;

      /** 窗口内"内容变化"次数达到本值就判为 HF */
      public static var FPROXY_HF_HITS:int = 3;

      /** 连续这么多帧没变化就退出 HF（回到通用判据） */
      public static var FPROXY_HF_IDLE_FRAMES:int = 60;

      /**
       * 单次成本超过本值不允许进 HF。
       *
       * 20ms 而不是 6ms：纽带这类面板实测就是 6~10ms，门槛设低了等于整个机制不生效。
       * 20ms 以上基本只剩"整屏级"节点，它们进 HF 只会更糟（而且它们本来就不是文本）。
       */
      public static var FPROXY_HF_MAX_COST_MS:int = 20;

      /** 非 HF 的文本节点心跳重烘间隔（ms）。补 htmlText 只改样式时的检测盲区；0 = 关闭 */
      public static var FPROXY_TEXT_HEARTBEAT_MS:int = 500;

      /** 每帧扫描节点预算 */
      public static var FPROXY_SCAN_NODES_PER_FRAME:int = 40;

      /** 全量重扫间隔（帧）。新出现的滤镜节点最迟这么久被发现 */
      public static var FPROXY_SCAN_INTERVAL:int = 10;

      /** 扫描深度上限 */
      public static var FPROXY_MAX_DEPTH:int = 8;

      /** Blur/Glow 的 quality 上限，只用于估算外扩量 */
      public static var FPROXY_BLUR_QUALITY_CAP:int = 2;

      /** 单节点**像素**上限（超限时降采样，不是不代理 —— 不代理 = GPU 下该节点整个不渲染） */
      public static var FPROXY_MAX_NODE_PIXELS:int = 1100000;

      /** 单边纹理上限。实测 2048 可用但单帧成本翻倍会掉帧，维持 1024：整屏级节点落在 57~64% */
      public static var FPROXY_MAX_TEXTURE:int = 1024;

      /** 外扩像素上限（多滤镜串联时求和后的截断值） */
      public static var FPROXY_MAX_PAD:int = 96;

      /** 诊断输出（每 600 帧一条 dumpState） */
      public static var FPROXY_DEBUG:Boolean = false;

      public function GameConfig()
      {
         super();
      }
      
      public static function setGameFps(param1:int) : void
      {
         FPS_GAME = param1;
         SPEED_PLUS = SPEED_PLUS_DEFAULT;
      }
      
      public static function get SPEED_PLUS_DEFAULT() : Number
      {
         return 30 / FPS_GAME;
      }
   }
}

