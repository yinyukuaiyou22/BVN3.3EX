package net.play5d.game.bvn.fighter.models
{
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.fighter.Bullet;
   import net.play5d.game.bvn.fighter.FighterAttacker;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.kyo.utils.KyoUtils;
   
   public class HitVO
   {
      
      public var id:String;
      
      public var owner:IGameSprite;
      
      public var power:Number = 0;
      
      public var powerAdd:Number = 0;
      
      public var powerRate:Number = 1;
      
      public var hitType:int = 1;
      
      public var isBreakDef:Boolean = false;
      
      public var hitx:Number = 0;
      
      public var hitxDef:Number = 0;
      
      public var hity:Number = 0;
      
      public var hurtTime:Number = 300;
      
      public var hurtType:int = 0;
      
      public var slowDown:Number = 0;
      
      public var holdTime:Number = 0;
      
      public var checkDirect:Boolean = true;
      
      public var focusTarget:Boolean;
      
      public var isWeak:Boolean;
      
      public var onHit:Function;
      
      public var currentArea:Rectangle;
      
      public var lastDamage:Number = 0;
      
      private var _cloneKey:Array = ["id","owner","power","powerAdd","powerRate","hitType","isBreakDef","hitx","hitxDef","hity","hurtTime","hurtType","slowDown","holdTime","checkDirect","focusTarget","isWeak","onHit","currentArea","lastDamage"];
      
      public function HitVO(param1:Object = null)
      {
         super();
         if(param1)
         {
            KyoUtils.setValueByObject(this,param1);
         }
         if(hitType == 1)
         {
            if(hurtTime < 100)
            {
               hurtTime = 100;
            }
         }
      }
      
      public function clone() : HitVO
      {
         var _loc1_:HitVO = new HitVO();
         KyoUtils.cloneValue(_loc1_,this,_cloneKey);
         return _loc1_;
      }
      
      public function isBisha() : Boolean
      {
         if(id == null)
         {
            return false;
         }
         return id.indexOf("bs") != -1 || id.indexOf("sbs") != -1 || id.indexOf("cbs") != -1 || id.indexOf("kbs") != -1;
      }
      
      public function isSkill() : Boolean
      {
         if(id == null)
         {
            return false;
         }
         return id.indexOf("tz") != -1 || id.indexOf("kj") != -1 || id.indexOf("zh") != -1 || id.indexOf("sh") != -1;
      }
      
      public function isCatch() : Boolean
      {
         return hitType == 11 && isBreakDef;
      }
      
      public function getDamage() : int
      {
         var _loc1_:Number = power * (powerAdd * 0.01);
         var _loc2_:Number = (power + _loc1_) * powerRate;
         return _loc2_ * (1 - limitRate);
      }
      
      public function get limitRate() : Number
      {
         if(!GameData.I.config.isStandardLimit)
         {
            return 0;
         }
         var _loc1_:int = 0;
         if(owner == null)
         {
            _loc1_ = 0;
         }
         else if(owner.team == null)
         {
            _loc1_ = 0;
         }
         else
         {
            if(owner.team.id == 1)
            {
               _loc1_ = GameCtrl.I.gameRunData.p1FighterGroup.limitLevel;
            }
            if(owner.team.id == 2)
            {
               _loc1_ = GameCtrl.I.gameRunData.p2FighterGroup.limitLevel;
            }
         }
         switch(_loc1_)
         {
            case 0:
               return 0;
            case 1:
               return 0.3;
            case 2:
               return 0.6;
            case 3:
               return 1;
            default:
               return 1;
         }
      }
      
      public function isWeakHit() : Boolean
      {
         if(!owner)
         {
            return false;
         }
         if(isWeak || (hitType == 1 || hitType == 2 || hitType == 4) && hurtType == 0)
         {
            if(owner is FighterMain)
            {
               return checkEnemyFighter(owner as FighterMain);
            }
            if(owner is Bullet)
            {
               return checkEnemyFighter((owner as Bullet).owner as FighterMain);
            }
            if(owner is FighterAttacker)
            {
               return checkEnemyFighter((owner as FighterAttacker).getOwner() as FighterMain);
            }
         }
         return false;
      }
      
      private function checkEnemyFighter(param1:FighterMain) : Boolean
      {
         return param1 && param1.mosouEnemyData && !param1.mosouEnemyData.isBoss;
      }
   }
}

