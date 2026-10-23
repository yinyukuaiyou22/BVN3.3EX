package net.play5d.game.bvn
{
   import flash.geom.*;
   
   public class GameConfig
   {
      
      public static var TOUCH_MODE:Boolean = true;
      
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

      /** 并发代理上限 */
      public static var FPROXY_MAX_PROXIES:int = 12;

      /** 每帧最多烘几个节点（0 = 不限，仅调试用） */
      public static var FPROXY_MAX_BAKE_PER_FRAME:int = 2;

      /** 每帧烘焙像素总预算 */
      public static var FPROXY_MAX_BAKE_PIXELS_PER_FRAME:int = 1000000;

      /**
       * 每帧烘焙**时间**预算（ms）。0 = 不限制（仅调试用）。
       *
       * 只约束「同帧叠加」：单次 BitmapData.draw() 不可分割，
       * 所以单帧峰值 ≈ max(单节点最大耗时, 本预算)，不可能压到预算以内。
       * 实测（真机 09:55 会话，无调试开销）：4 个整屏节点合计 77ms，
       * 单节点最大 29ms —— 8ms 预算下会摊到 3~4 帧。
       */
      public static var FPROXY_BAKE_BUDGET_MS:int = 8;

      /** 每帧扫描节点预算 */
      public static var FPROXY_SCAN_NODES_PER_FRAME:int = 40;

      /** 全量重扫间隔（帧）。新出现的滤镜节点最迟这么久被发现 */
      public static var FPROXY_SCAN_INTERVAL:int = 10;

      /** 扫描深度上限 */
      public static var FPROXY_MAX_DEPTH:int = 8;

      /** Blur/Glow 的 quality 上限，只用于估算外扩量 */
      public static var FPROXY_BLUR_QUALITY_CAP:int = 2;

      /** 单节点像素上限（超过就不代理，保留原样，避免 GPU 纹理炸掉） */
      public static var FPROXY_MAX_NODE_PIXELS:int = 1100000;

      /** 单边纹理上限（GPU 模式常见 1024） */
      public static var FPROXY_MAX_TEXTURE:int = 1024;

      /** 外扩像素上限 */
      public static var FPROXY_MAX_PAD:int = 64;

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

