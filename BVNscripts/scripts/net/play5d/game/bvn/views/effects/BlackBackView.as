package net.play5d.game.bvn.views.effects
{
   import flash.display.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   
   public class BlackBackView extends Sprite
   {
      
      private var _bishaFace:BishaFaceEffectView;
      
      private var isRenderFadIn:Boolean;
      
      private var isRenderFadOut:Boolean;
      
      private var _bg:Bitmap;
      
      public function BlackBackView()
      {
         super();
         var _loc1_:BitmapData = new BitmapData(GameConfig.GAME_SIZE.x / 10,GameConfig.GAME_SIZE.y / 10,false,0);
         this._bg = new Bitmap(_loc1_);
         this._bg.width = GameConfig.GAME_SIZE.x;
         this._bg.height = GameConfig.GAME_SIZE.y;
         addChild(this._bg);
      }
      
      public function destory() : void
      {
         if(Boolean(this._bg))
         {
            try
            {
               removeChild(this._bg);
            }
            catch(e:Error)
            {
            }
            this._bg.bitmapData.dispose();
            this._bg = null;
         }
         this.removeBishaFace();
      }
      
      public function renderAnimate() : void
      {
      }
      
      public function fadIn() : void
      {
      }
      
      public function fadOut() : void
      {
         this.removeBishaFace();
         try
         {
            parent.removeChild(this);
         }
         catch(e:Error)
         {
         }
      }
      
      public function showBishaFace(param1:int, param2:DisplayObject) : void
      {
         var _loc3_:Number = NaN;
         if(!this._bishaFace)
         {
            this._bishaFace = new BishaFaceEffectView();
            _loc3_ = 1;
            if(Boolean(GameCtrl.I) && Boolean(GameCtrl.I.gameState) && Boolean(GameCtrl.I.gameState.camera))
            {
               _loc3_ = Number(GameCtrl.I.gameState.camera.getZoom());
            }
            this._bishaFace.mc.y = 100 + 100 / _loc3_;
            addChild(this._bishaFace.mc);
         }
         this._bishaFace.setFace(param1,param2);
         this._bishaFace.fadIn();
      }
      
      private function removeBishaFace() : void
      {
         if(Boolean(this._bishaFace))
         {
            this._bishaFace.destory();
            this._bishaFace = null;
         }
      }
   }
}

