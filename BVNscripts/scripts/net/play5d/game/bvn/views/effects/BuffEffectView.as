package net.play5d.game.bvn.views.effects
{
   import flash.geom.*;
   import net.play5d.game.bvn.data.EffectVO;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.fighter.vos.FighterBuffVO;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public class BuffEffectView extends EffectView
   {
      
      private var _fighter:FighterMain;
      
      private var _buff:FighterBuffVO;
      
      public function BuffEffectView(param1:EffectVO)
      {
         super(param1);
         this.loopPlay = true;
      }
      
      public function setBuff(param1:FighterBuffVO) : void
      {
         this._buff = param1;
      }
      
      override public function setTarget(param1:IGameSprite) : void
      {
         var _loc2_:ColorTransform = null;
         super.setTarget(param1);
         if(param1 is FighterMain)
         {
            this._fighter = param1 as FighterMain;
         }
         if(Boolean(this._fighter) && Boolean(_data.targetColorOffset))
         {
            _loc2_ = new ColorTransform();
            _loc2_.redOffset = _data.targetColorOffset[0];
            _loc2_.greenOffset = _data.targetColorOffset[1];
            _loc2_.blueOffset = _data.targetColorOffset[2];
            this._fighter.changeColor(_loc2_);
         }
      }
      
      override public function render() : void
      {
         super.render();
         if(this._buff.finished)
         {
            if(Boolean(_data.targetColorOffset) && Boolean(this._fighter))
            {
               this._fighter.resumeColor();
            }
            remove();
         }
         else if(Boolean(this._fighter))
         {
            setPos(this._fighter.x,this._fighter.y);
         }
      }
   }
}

