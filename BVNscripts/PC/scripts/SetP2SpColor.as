package
{
   import flash.geom.ColorTransform;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   
   public function SetP2SpColor(param1:*, param2:ColorTransform = null) : void
   {
      if(param1 == null || !(param1 is IGameSprite))
      {
         return;
      }
      if(param2 == null)
      {
         param2 = new ColorTransform();
         param2.greenOffset = -85;
      }
      (param1 as IGameSprite).colorTransform = param2;
   }
}

