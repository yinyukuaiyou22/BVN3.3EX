package net.play5d.game.bvn.views.effects
{
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.EffectVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class SteelHitEffect extends EffectView
   {
      
      private var _fighter:FighterMain;
      
      public function SteelHitEffect(param1:EffectVO)
      {
         super(param1);
      }
      
      override public function setTarget(param1:IGameSprite) : void
      {
         var ct:ColorTransform = null;
         var v:IGameSprite = param1;
         super.setTarget(v);
         if(v is FighterMain)
         {
            this._fighter = v as FighterMain;
            if(this._fighter.isSteelBody)
            {
               ct = new ColorTransform();
               ct.redOffset = 150;
               ct.greenOffset = 150;
               ct.blueOffset = 150;
               if(this._fighter.isSuperSteelBody)
               {
                  ct.blueOffset = 0;
                  if(GameData.I.config.isSteelBodyFreeze)
                  {
                     EffectCtrl.I.shine(16776960,0.3);
                  }
               }
               // 2026-11-12：恢复 3.3 原版行为 —— 上色与「冻结结束恢复颜色」必须成对，
               // 只在刚身停顿（isSteelBodyFreeze）开启时才执行。原先是无条件执行：
               // 而 EffectCtrl.doSteelHitEffect 在冻结关闭时会把 EffectVO.freeze 置 0，
               // renderFreeze() 便永远走不到 _onFreezeOver，resumeColor() 永不执行，
               // 金身上色就永久残留（真机表现：刚身闪光上色不消失）。
               if(GameData.I.config.isSteelBodyFreeze)
               {
                  this._fighter.changeColor(ct);
                  EffectCtrl.I.setOnFreezeOver(function():void
                  {
                     _fighter.resumeColor();
                  });
               }
            }
         }
      }
   }
}
