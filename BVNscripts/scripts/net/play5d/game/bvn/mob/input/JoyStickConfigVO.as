package net.play5d.game.bvn.mob.input
{
   import net.play5d.kyo.utils.*;
   
   public class JoyStickConfigVO
   {
      
      public var deviceId:String;
      
      public var deviceIsSet:Boolean = false;
      
      // ===== Xbox Wireless Controller 实际布局映射（2026-08-15 日志确认）=====
      // control 0/1 = D-pad HAT 轴（AXIS_16 上下 / AXIS_15 左右）
      // control 8/9 = 左摇杆（AXIS_1=Y 正1=下拉 / AXIS_0=X）
      // control 13=A 14=B 15=X 16=Y 17=LB 18=RB 19=LS 21=Start 22=Select
      // 左摇杆（up2/down2/left2/right2）
      public var up2:JoyStickSetVO = new JoyStickSetVO(8,-0.5);
      
      public var down2:JoyStickSetVO = new JoyStickSetVO(8,0.5);
      
      public var left2:JoyStickSetVO = new JoyStickSetVO(9,-0.5);
      
      public var right2:JoyStickSetVO = new JoyStickSetVO(9,0.5);
      
      // D-pad（HAT 轴）
      public var up:JoyStickSetVO = new JoyStickSetVO(0,-0.5);
      
      public var down:JoyStickSetVO = new JoyStickSetVO(0,0.5);
      
      public var left:JoyStickSetVO = new JoyStickSetVO(1,-0.5);
      
      public var right:JoyStickSetVO = new JoyStickSetVO(1,0.5);
      
      // 按钮：A(13)=跳跃  B(14)=冲刺  X(15)=攻击  Y(16)=远攻
      // LB(17)=召唤辅助  RB(18)=必杀  LS(19)=卍解
      // Start(21)=暂停  Select(22)=确认
      public var attack:JoyStickSetVO = new JoyStickSetVO(15,1);
      
      public var jump:JoyStickSetVO = new JoyStickSetVO(13,1);
      
      public var dash:JoyStickSetVO = new JoyStickSetVO(14,1);
      
      public var skill:JoyStickSetVO = new JoyStickSetVO(16,1);
      
      public var superSkill:JoyStickSetVO = new JoyStickSetVO(18,1);
      
      public var special:JoyStickSetVO = new JoyStickSetVO(17,1);
      
      public var waikai:JoyStickSetVO = new JoyStickSetVO(19,1);
      
      public var back:JoyStickSetVO = new JoyStickSetVO(21,1);
      
      public var select:JoyStickSetVO = new JoyStickSetVO(22,1);
      
      public function JoyStickConfigVO()
      {
         super();
      }
      
      public function readObj(param1:Object) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:Object = null;
         for(_loc3_ in param1)
         {
            _loc2_ = param1[_loc3_];
            if(this.hasOwnProperty(_loc3_))
            {
               if(this[_loc3_] is JoyStickSetVO)
               {
                  // 防止存档脏数据：子字段为 null 时赋默认值 {id:0, value:0}，
                  // 避免 readObj 中 this.id = null.id 之类的语义错乱。
                  if(_loc2_ == null)
                  {
                     _loc2_ = {id: 0, value: 0};
                  }
                  (this[_loc3_] as JoyStickSetVO).readObj(_loc2_);
               }
               else
               {
                  this[_loc3_] = _loc2_;
               }
            }
         }
      }
      
      public function toObj() : Object
      {
         var _loc4_:* = undefined;
         var _loc1_:* = undefined;
         var _loc2_:Array = KyoUtils.getItemVaribles(this);
         var _loc3_:Object = {};
         for each(_loc4_ in _loc2_)
         {
            _loc1_ = this[_loc4_];
            if(_loc1_ is JoyStickSetVO)
            {
               _loc3_[_loc4_] = (this[_loc4_] as JoyStickSetVO).toObj();
            }
            else
            {
               _loc3_[_loc4_] = this[_loc4_];
            }
         }
         return _loc3_;
      }
   }
}

