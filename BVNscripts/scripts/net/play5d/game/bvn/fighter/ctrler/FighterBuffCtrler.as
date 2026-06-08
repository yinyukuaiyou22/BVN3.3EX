package net.play5d.game.bvn.fighter.ctrler
{
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.vos.*;
   
   public class FighterBuffCtrler
   {
      
      private var _fighter:FighterMain;
      
      private var _speed:Number = 0;
      
      private var _attackRate:Number = 0;
      
      private var _buffObj:Object = {};
      
      public function FighterBuffCtrler(param1:FighterMain)
      {
         super();
         this._fighter = param1;
      }
      
      public function destory() : void
      {
         this._fighter = null;
      }
      
      public function speedUp(param1:Number = 0, param2:Number = 5) : void
      {
         var _loc3_:FighterBuffVO = this.addBuff("speed",param1,param2);
         if(!_loc3_)
         {
            return;
         }
         EffectCtrl.I.doEffectById("buff_effect_speed",this._fighter.x,this._fighter.y);
         EffectCtrl.I.doBuffEffect("buff_speed",this._fighter,_loc3_);
      }
      
      public function attackUp(param1:Number = 0, param2:Number = 5) : void
      {
         var _loc3_:FighterBuffVO = this.addBuff("attackRate",param1,param2);
         if(!_loc3_)
         {
            return;
         }
         EffectCtrl.I.doEffectById("buff_effect_power",this._fighter.x,this._fighter.y);
         EffectCtrl.I.doBuffEffect("buff_power",this._fighter,_loc3_);
      }
      
      public function defenseUp(param1:Number = 0, param2:Number = 5) : void
      {
         var _loc3_:FighterBuffVO = this.addBuff("defenseRate",param1,param2);
         if(!_loc3_)
         {
            return;
         }
         EffectCtrl.I.doEffectById("buff_effect_defense",this._fighter.x,this._fighter.y);
         EffectCtrl.I.doBuffEffect("buff_defense",this._fighter,_loc3_);
      }
      
      public function speedDown(param1:Number = 0, param2:Number = 5) : void
      {
         this.addBuff("speed",-param1,param2);
      }
      
      public function attackDown(param1:Number = 0, param2:Number = 5) : void
      {
         this.addBuff("attackRate",param1,param2);
      }
      
      public function defenseDown(param1:Number = 0, param2:Number = 5) : void
      {
         this.addBuff("defense",-param1,param2);
      }
      
      private function addBuff(param1:String, param2:*, param3:Number) : FighterBuffVO
      {
         var _loc7_:* = undefined;
         var _loc4_:FighterBuffVO = null;
         try
         {
            _loc4_ = this._buffObj[param1];
            if(!_loc4_)
            {
               _loc4_ = new FighterBuffVO(param1,param3);
               this._buffObj[param1] = _loc4_;
               _loc4_.resumeValue = this._fighter[param1];
            }
            else
            {
               _loc4_.setHold(param3);
            }
            this._fighter[param1] = _loc4_.resumeValue + param2;
            return _loc4_;
         }
         catch(e:Error)
         {
            trace(e);
            _loc7_ = null;
         }
         return _loc7_;
      }
      
      public function render() : void
      {
         var _loc2_:* = undefined;
         var _loc1_:FighterBuffVO = null;
         for(_loc2_ in this._buffObj)
         {
            _loc1_ = this._buffObj[_loc2_];
            if(_loc1_.render())
            {
               this._fighter[_loc1_.param] = _loc1_.resumeValue;
               delete this._buffObj[_loc2_];
            }
         }
      }
   }
}

