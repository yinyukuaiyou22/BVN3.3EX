package net.play5d.game.bvn.ui
{
   import flash.display.*;
   import flash.events.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.kyo.utils.*;
   
   public class PauseDialog extends Sprite
   {
      
      private var _bg:Sprite;
      
      private var _btnGroup:SetBtnGroup;
      
      private var _moveList:MoveListSp;
      
      private var _btnData:Array;
      
      private var _bIsOpenAI:Boolean;
      
      public function PauseDialog()
      {
         super();
         this._bg = new Sprite();
         this._bg.graphics.beginFill(0,0.5);
         this._bg.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         this._bg.graphics.endFill();
         addChild(this._bg);
         this.updateBtnData();
      }
      
      private function updateBtnData() : void
      {
         if(this._btnGroup != null)
         {
            removeChild(this._btnGroup);
            this._btnGroup.destory();
            this._btnGroup = null;
         }
         this._btnGroup = new SetBtnGroup();
         addChild(this._btnGroup);
         this._btnData = [{
            "label":"GAME TITLE",
            "cn":"返回标题"
         },{
            "label":"MOVE LIST",
            "cn":"出招表"
         },{
            "label":"CONTINUE",
            "cn":"继续游戏"
         },{
            "label":"BERAK SELECT",
            "cn":"返回选人"
         }];
         if(GameMode.currentMode == 40)
         {
            KyoUtils.array_pushAt(this._btnData,{
               "label":"P2 AI CTRLER-" + (this._bIsOpenAI ? "NO" : "OFF"),
               "cn":"P2 AI 控制:" + (this._bIsOpenAI ? "启用" : "关闭")
            },4);
         }
         this._btnGroup.setBtnData(this._btnData,this._btnData.length - 1);
         this._btnGroup.addEventListener("SELECT",this.btnGroupSelectHandler);
      }
      
      public function destory() : void
      {
         if(Boolean(this._btnGroup))
         {
            this._btnGroup.removeEventListener("SELECT",this.btnGroupSelectHandler);
            this._btnGroup.destory();
            this._btnGroup = null;
         }
         if(Boolean(this._moveList))
         {
            this._moveList.destory();
            this._moveList = null;
         }
      }
      
      public function isShowing() : Boolean
      {
         return visible;
      }
      
      public function show() : void
      {
         this.updateBtnData();
         this.visible = true;
         this._btnGroup.keyEnable = true;
         this._btnGroup.setArrowIndex(2);
      }
      
      public function hide() : void
      {
         this.visible = false;
         this._btnGroup.keyEnable = false;
         GameUI.closeConfrim();
      }
      
      private function btnGroupSelectHandler(e:SetBtnEvent) : void
      {
         var sel:String;
         if(GameUI.showingDialog())
         {
            return;
         }
         sel = e.selectedLabel;
         switch(sel)
         {
            case "GAME TITLE":
               this._btnGroup.keyEnable = false;
               GameUI.confrim("BACK TITLE?","返回到主菜单？",function():void
               {
                  EffectCtrl.I.endShake();
                  MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["back_title"])));
                  MainGame.I.goMenu();
               },function():void
               {
                  _btnGroup.keyEnable = true;
                  MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["back_title_cancel"])));
               });
               break;
            case "MOVE LIST":
               this.showMoveList();
               MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["move_list"])));
               break;
            case "BERAK SELECT":
               GameEvent.dispatchEvent("GAME_END");
               EffectCtrl.I.endShake();
               MainGame.I.goSelect();
               break;
            case "CONTINUE":
               GameCtrl.I.resume(true);
               break;
            default:
               if(sel.indexOf("P2 AI CTRLER-") == 0)
               {
                  this._bIsOpenAI = !this._bIsOpenAI;
                  GameCtrl.I.toggleFighterAI(GameCtrl.I.gameRunData.p2FighterGroup.currentFighter,2,this._bIsOpenAI);
                  GameCtrl.I.resume(true);
               }
         }
      }
      
      private function showMoveList() : void
      {
         if(!this._moveList)
         {
            this._moveList = new MoveListSp();
            this._moveList.onBackSelect = this.hideMoveList;
            addChild(this._moveList);
         }
         this._btnGroup.keyEnable = false;
         this._btnGroup.visible = false;
         this._moveList.show();
      }
      
      private function hideMoveList() : void
      {
         this._moveList.hide();
         this._btnGroup.visible = true;
         this._btnGroup.keyEnable = true;
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["move_list_cancel"])));
      }
   }
}

