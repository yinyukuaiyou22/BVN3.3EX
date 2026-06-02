package net.play5d.game.bvn.ui
{
   import flash.display.Sprite;
   import flash.events.DataEvent;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.kyo.utils.KyoUtils;
   
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
         _bg = new Sprite();
         _bg.graphics.beginFill(0,0.5);
         _bg.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         _bg.graphics.endFill();
         addChild(_bg);
         updateBtnData();
      }
      
      private function updateBtnData() : void
      {
         if(_btnGroup != null)
         {
            removeChild(_btnGroup);
            _btnGroup.destory();
            _btnGroup = null;
         }
         _btnGroup = new SetBtnGroup();
         addChild(_btnGroup);
         _btnData = [{
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
            KyoUtils.array_pushAt(_btnData,{
               "label":"P2 AI CTRLER-" + (_bIsOpenAI ? "NO" : "OFF"),
               "cn":"P2 AI 控制:" + (_bIsOpenAI ? "启用" : "关闭")
            },4);
         }
         _btnGroup.setBtnData(_btnData,_btnData.length - 1);
         _btnGroup.addEventListener("SELECT",btnGroupSelectHandler);
      }
      
      public function destory() : void
      {
         if(_btnGroup)
         {
            _btnGroup.removeEventListener("SELECT",btnGroupSelectHandler);
            _btnGroup.destory();
            _btnGroup = null;
         }
         if(_moveList)
         {
            _moveList.destory();
            _moveList = null;
         }
      }
      
      public function isShowing() : Boolean
      {
         return visible;
      }
      
      public function show() : void
      {
         updateBtnData();
         this.visible = true;
         _btnGroup.keyEnable = true;
         _btnGroup.setArrowIndex(2);
      }
      
      public function hide() : void
      {
         this.visible = false;
         _btnGroup.keyEnable = false;
         GameUI.closeConfrim();
      }
      
      private function btnGroupSelectHandler(e:SetBtnEvent) : void
      {
         if(GameUI.showingDialog())
         {
            return;
         }
         var _loc3_:String = e.selectedLabel;
         switch(_loc3_)
         {
            case "GAME TITLE":
               §§push(0);
               break;
            case "MOVE LIST":
               §§push(1);
               break;
            case "BERAK SELECT":
               §§push(2);
               break;
            default:
               switch(_loc3_)
               {
                  case "P2 AI CTRLER-" + (_bIsOpenAI ? "NO" : "OFF"):
                     §§push(3);
                     break;
                  case "CONTINUE":
                     §§push(4);
                     break;
                  default:
                     §§push(-1);
               }
         }
         switch(§§pop())
         {
            case 0:
               _btnGroup.keyEnable = false;
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
            case 1:
               showMoveList();
               MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["move_list"])));
               break;
            case 2:
               GameEvent.dispatchEvent("GAME_END");
               EffectCtrl.I.endShake();
               MainGame.I.goSelect();
               break;
            case 3:
               _bIsOpenAI = !_bIsOpenAI;
               GameCtrl.I.setFighterActionCtrl(GameCtrl.I.gameRunData.p2FighterGroup.currentFighter,2,_bIsOpenAI);
            case 4:
               GameCtrl.I.resume(true);
         }
      }
      
      private function showMoveList() : void
      {
         if(!_moveList)
         {
            _moveList = new MoveListSp();
            _moveList.onBackSelect = hideMoveList;
            addChild(_moveList);
         }
         _btnGroup.keyEnable = false;
         _moveList.show();
      }
      
      private function hideMoveList() : void
      {
         _moveList.hide();
         _btnGroup.keyEnable = true;
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["move_list_cancel"])));
      }
   }
}

