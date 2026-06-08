package net.play5d.game.bvn.views.effects
{
   import flash.geom.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.EffectVO;
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
                  EffectCtrl.I.shine(16776960,0.3);
               }
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

