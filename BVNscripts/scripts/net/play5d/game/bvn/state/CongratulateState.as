package net.play5d.game.bvn.state
{
   import flash.display.*;
   import flash.events.Event;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.bitmap.*;
   import net.play5d.kyo.stage.*;
   
   public class CongratulateState implements Istage
   {
      
      private var _mainUI:Sprite;
      
      private var _ui:Sprite;
      
      private var _exitHeight:Number = 0;
      
      private var _btngroup:SetBtnGroup;
      
      private var _bg:Bitmap;
      
      public function CongratulateState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._mainUI;
      }
      
      public function get innerUI() : Sprite
      {
         return this._ui;
      }
      
      public function build() : void
      {
         this._mainUI = new Sprite();
         var _loc1_:BitmapData = ResUtils.I.createBitmapData(ResUtils.I.common_ui,"cover_bgimg",GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         this._bg = new Bitmap(_loc1_);
         this._mainUI.addChild(this._bg);
         this._bg.alpha = -1;
         this._ui = new Sprite();
         this._mainUI.addChild(this._ui);
         var _loc2_:* = ResUtils.I.createDisplayObject(ResUtils.I.common_ui,ResUtils.CONGRATULATIONS);
         this._ui.addChild(_loc2_);
         _loc2_.addEventListener("complete",this.playComplete,false,0,true);
         _loc2_.gotoAndPlay(2);
         SoundCtrl.I.BGM(AssetManager.I.getSound("congratulation"));
      }
      
      public function getBtnY() : Number
      {
         return this._btngroup.y;
      }
      
      private function playComplete(param1:Event) : void
      {
         var _loc2_:* = ResUtils.I.createDisplayObject(ResUtils.I.common_ui,"mc_win_all");
         _loc2_.y = GameConfig.GAME_SIZE.y;
         this._ui.addChild(_loc2_);
         GameRender.add(this.render);
         var _loc3_:BitmapFontText = new BitmapFontText(AssetManager.I.getFont("font1"));
         _loc3_.text = "FINAL SCORE " + GameData.I.score;
         _loc3_.x = (GameConfig.GAME_SIZE.x - _loc3_.width) / 2;
         _loc3_.y = _loc2_.y + _loc2_.height + 100;
         this._ui.addChild(_loc3_);
         this._exitHeight = _loc3_.y - 320;
         this._btngroup = new SetBtnGroup();
         this._btngroup.x = 230;
         this._btngroup.y = _loc3_.y + _loc3_.height + 100;
         this._btngroup.setBtnData([{
            "label":"BACK",
            "cn":"返回"
         }]);
         this._btngroup.addEventListener("SELECT",this.selectBtnHandler);
         this._btngroup.keyEnable = false;
         this._ui.addChild(this._btngroup);
         GameEvent.dispatchEvent("GAME_PASS_ALL");
      }
      
      private function render() : void
      {
         if(GameInputer.back(1))
         {
            this._ui.y = -this._exitHeight;
            SoundCtrl.I.sndSelect();
         }
         this._ui.y -= 1;
         this._bg.alpha += 0.005;
         if(this._ui.y < -this._exitHeight)
         {
            GameRender.remove(this.render);
            this._bg.alpha = 1;
            this._btngroup.keyEnable = true;
         }
      }
      
      private function selectBtnHandler(param1:SetBtnEvent) : void
      {
         MainGame.I.goLogo();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         GameRender.remove(this.render);
         if(Boolean(this._btngroup))
         {
            this._btngroup.destory();
            this._btngroup.removeEventListener("SELECT",this.selectBtnHandler);
            this._btngroup = null;
         }
      }
   }
}

