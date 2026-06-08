package net.play5d.game.bvn.views.effects
{
   import flash.display.*;
   import net.play5d.game.bvn.ctrl.*;
   
   public class BishaFaceEffectView
   {
      
      public var mc:MovieClip;
      
      private var _faceObj:Object = {};
      
      public function BishaFaceEffectView()
      {
         super();
         this.mc = AssetManager.I.getEffect("bisha_face_mc");
      }
      
      public function setFace(param1:int, param2:DisplayObject) : void
      {
         var _loc3_:MovieClip = this.mc["facemc" + param1];
         if(!_loc3_)
         {
            return;
         }
         this._faceObj[param1] = param2;
         param2.width = 254;
         param2.height = 180;
         _loc3_.addChild(param2);
      }
      
      public function fadIn() : void
      {
         this.mc.gotoAndPlay(2);
      }
      
      public function destory() : void
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in this._faceObj)
         {
            if(_loc1_ is Bitmap)
            {
               (_loc1_ as Bitmap).bitmapData.dispose();
            }
         }
      }
   }
}

