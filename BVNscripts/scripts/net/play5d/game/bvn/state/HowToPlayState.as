package net.play5d.game.bvn.state
{
   import flash.display.DisplayObject;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.input.*;
   import net.play5d.kyo.stage.*;
   
   public class HowToPlayState implements Istage
   {
      
      private var _ui:*;
      
      public function HowToPlayState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         var kc:KeyConfigVO = null;
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.howtoplay,"movie_howtoplay");
         this._ui.addEventListener("complete",this.uiComplete);
         this._ui.gotoAndPlay(2);
         SoundCtrl.I.BGM(AssetManager.I.getSound("back"));
         kc = GameData.I.config.key_p1;
         this.setKeyText(this._ui.txt_up,kc.up);
         this.setKeyText(this._ui.txt_down,kc.down);
         this.setKeyText(this._ui.txt_left,kc.left);
         this.setKeyText(this._ui.txt_right,kc.right);
         this.setKeyText(this._ui.txt_attack,kc.attack);
         this.setKeyText(this._ui.txt_jump,kc.jump);
         this.setKeyText(this._ui.txt_dash,kc.dash);
         this.setKeyText(this._ui.txt_skill,kc.skill);
         this.setKeyText(this._ui.txt_bisha,kc.superKill);
         this.setKeyText(this._ui.txt_special,kc.beckons);
         setTimeout(function():void
         {
            GameRender.add(render);
            GameInputer.focus();
            GameInputer.enabled = true;
            _ui.skip_btn.addEventListener("click",skipBtnHandler);
         },1000);
      }
      
      private function render() : void
      {
         if(Boolean(GameInputer.back(1)) || Boolean(GameInputer.select("MENU",1)))
         {
            GameRender.remove(this.render);
            this._ui.gotoAndPlay("skip");
         }
      }
      
      private function skipBtnHandler(param1:MouseEvent) : void
      {
         GameRender.remove(this.render);
         this._ui.gotoAndPlay("skip");
      }
      
      private function uiComplete(param1:Event) : void
      {
         this._ui.removeEventListener("complete",this.uiComplete);
         MainGame.I.goSelect();
      }
      
      private function setKeyText(param1:TextField, param2:int) : void
      {
         var _loc3_:String = KyoKeyCode.code2name(param2);
         if(Boolean(_loc3_))
         {
            param1.text = _loc3_;
         }
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         SoundCtrl.I.BGM(null);
         GameRender.remove(this.render);
         this._ui.removeEventListener("complete",this.uiComplete);
         this._ui.gotoAndStop("destory");
      }
   }
}

