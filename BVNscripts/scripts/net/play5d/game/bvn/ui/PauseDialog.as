package net.play5d.game.bvn.ui
{
   import flash.display.*;
   import flash.events.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
     import net.play5d.game.bvn.ui.dialog.*;
   import net.play5d.kyo.utils.*;
   
   public class PauseDialog extends Sprite
   {
      
      private var _bg:Sprite;
      
      private var _btnGroup:SetBtnGroup;
      
      private var _moveList:MoveListSp;
      
      private var _btnData:Array;
      
      private var _bIsOpenAI:Boolean;

        private var _restartConfirm:RestartConfirmUI;
      
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
            "label":"CONTINUE",
            "cn":"继续游戏"
         },{
             "label":"RESTART BATTLE",
             "cn":"重开对局"
          },{
            "label":"BERAK SELECT",
            "cn":"返回选人"
         }];
         this._btnGroup.setBtnData(this._btnData,this._btnData.length - 1);
         this._btnGroup.addEventListener("SELECT",this.btnGroupSelectHandler);
      }
      
      public function destory() : void
      {
           this.closeRestartConfirm();
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
           this.closeRestartConfirm();
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
             case "RESTART BATTLE":
                // 3.7 扩展移植：暂停菜单内“重开对局”入口，带 3.3 风格确认弹窗。
                this.showRestartConfirm();
                MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["restart_confirm"])));
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

        /**
         * 3.7 扩展移植：显示“重开对局”确认弹窗（3.3 风格）。
         * 弹窗期间保持暂停，PauseDialog 自身按钮全部禁用，防止误触。
         */
        private function showRestartConfirm() : void
        {
           if(Boolean(this._restartConfirm))
           {
              return;
           }
           this._btnGroup.keyEnable = false;
             // 确保弹窗期间全局暂停标志为 true（游戏逻辑保持暂停）。
             GameCtrl.I.pause(true);
           this._restartConfirm = new RestartConfirmUI();
           this._restartConfirm.yesBack = this.confirmRestartYes;
           this._restartConfirm.noBack = this.confirmRestartNo;
           MainGame.I.root.addChild(this._restartConfirm);
        }

        private function confirmRestartYes() : void
        {
           if(Boolean(this._restartConfirm))
           {
              this._restartConfirm.close();
              this._restartConfirm = null;
           }
           MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["restart_yes"])));
           // 执行局内重开：内部会保持 isPaused=true 直到重置完成，再恢复游戏。
           GameCtrl.I.restartBattle();
        }

        private function confirmRestartNo() : void
        {
           if(Boolean(this._restartConfirm))
           {
              this._restartConfirm.close();
              this._restartConfirm = null;
           }
           this._btnGroup.keyEnable = true;
           MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["restart_cancel"])));
        }

        private function closeRestartConfirm() : void
        {
           if(Boolean(this._restartConfirm))
           {
              this._restartConfirm.close();
              this._restartConfirm = null;
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

