package net.play5d.game.bvn.mob.views.lan
{
   import flash.display.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.mob.ctrls.*;
   import net.play5d.game.bvn.ui.*;
   
   public class LANExitDialog extends Sprite
   {
      
      private var _bg:Sprite;
      
      private var _btnGroup:SetBtnGroup;
      
      public function LANExitDialog()
      {
         super();
         this._bg = new Sprite();
         this._bg.graphics.beginFill(0,0.5);
         this._bg.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         this._bg.graphics.endFill();
         addChild(this._bg);
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.setBtnData([{
            "label":"CONTINUE",
            "cn":"继续游戏"
         },{
            "label":"EXIT",
            "cn":"退出联机"
         }],0);
         this._btnGroup.addEventListener("SELECT",this.btnGroupSelectHandler);
         if(LANClientCtrl.I.active)
         {
            this._btnGroup.gameInputType = "P2";
         }
         if(LANServerCtrl.I.active)
         {
            this._btnGroup.gameInputType = "P1";
         }
         addChild(this._btnGroup);
      }
      
      public function destory() : void
      {
         if(Boolean(this._btnGroup))
         {
            this._btnGroup.removeEventListener("SELECT",this.btnGroupSelectHandler);
            this._btnGroup.destory();
            this._btnGroup = null;
         }
      }
      
      public function isShowing() : Boolean
      {
         return visible;
      }
      
      public function show() : void
      {
         this.visible = true;
         this._btnGroup.keyEnable = true;
         this._btnGroup.setArrowIndex(0);
      }
      
      public function hide() : void
      {
         this.visible = false;
         this._btnGroup.keyEnable = false;
      }
      
      private function btnGroupSelectHandler(param1:SetBtnEvent) : void
      {
         if(GameUI.showingDialog())
         {
            return;
         }
         switch(param1.selectedLabel)
         {
            case "EXIT":
               if(LANServerCtrl.I.active)
               {
                  LANServerCtrl.I.gameQuit();
               }
               if(LANClientCtrl.I.active)
               {
                  LANClientCtrl.I.gameEnd();
               }
               break;
            case "CONTINUE":
               this.hide();
         }
      }
   }
}

