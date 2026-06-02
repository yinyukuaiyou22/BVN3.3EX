package net.play5d.game.bvn.ui.bigmap
{
   import flash.display.MovieClip;
   import net.play5d.game.bvn.ctrl.AssetManager;
   
   public class CloudView
   {
      
      public var speed:Number = 0;
      
      public var mc:MovieClip;
      
      public function CloudView(param1:Number, param2:Number)
      {
         super();
         var _loc3_:Class = AssetManager.I.getSWFEffectClass("cloud_mc","subswfs/bigmap.swf");
         mc = new _loc3_() as MovieClip;
         mc.x = param1;
         mc.y = param2;
         mc.alpha = 0.2 + Math.random() * 0.3;
         mc.gotoAndStop(1 + int(Math.random() * mc.totalFrames));
         speed = 0.02 + Math.random() * 0.1;
      }
      
      public function render() : Boolean
      {
         mc.y -= speed;
         return mc.y < -mc.height + 30;
      }
   }
}

