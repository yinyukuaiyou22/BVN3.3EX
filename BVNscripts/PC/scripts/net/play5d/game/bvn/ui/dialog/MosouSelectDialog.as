package net.play5d.game.bvn.ui.dialog
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.mosou_ctrls.MosouLogic;
   import net.play5d.game.bvn.data.FighterModel;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.mosou.MosouFighterSellVO;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.ui.Text;
   import net.play5d.game.bvn.ui.dialog.select.DotsGroupUI;
   import net.play5d.game.bvn.ui.dialog.select.SelectFighterList;
   import net.play5d.game.bvn.ui.dialog.select.SelectFighterUI;
   import net.play5d.game.bvn.ui.mosou.CoinUI;
   import net.play5d.game.bvn.utils.BtnUtils;
   
   public class MosouSelectDialog extends BaseDialog
   {
      
      private var _chooseBtn:SimpleButton;
      
      private var _buyBtn:SimpleButton;
      
      private var _coinClearBtn:SimpleButton;
      
      private var _selectFighterList:SelectFighterList;
      
      private var _fighterIndex:int;
      
      private var _nameText:Text;
      
      private var _infoText:Text;
      
      private var _curFighterUI:SelectFighterUI;
      
      private var _coinUI:CoinUI;
      
      private var _selectFace:DisplayObject;
      
      private var _dotGroup:DotsGroupUI;
      
      private var _coinico:Sprite;
      
      public function MosouSelectDialog(param1:int)
      {
         super();
         width = 741;
         height = 478;
         offsetY = 20;
         _fighterIndex = param1;
         _ui = AssetManager.I.createObject("dialog_select_fighter","subswfs/dialog_ui.swf") as Sprite;
         _dialogUI = _ui;
         _coinUI = new CoinUI(_ui.getChildByName("coinmc") as MovieClip);
         _chooseBtn = _ui.getChildByName("change") as SimpleButton;
         _buyBtn = _ui.getChildByName("buy") as SimpleButton;
         _coinClearBtn = _ui.getChildByName("nocoin") as SimpleButton;
         _coinico = AssetManager.I.createObject("coin_icon_mc","subswfs/dialog_ui.swf") as Sprite;
         BtnUtils.initBtn(_chooseBtn,btnHandler);
         BtnUtils.initBtn(_buyBtn,btnHandler);
         BtnUtils.initBtn(_coinClearBtn,btnHandler);
         _nameText = new Text(16777215);
         _nameText.width = 299;
         _nameText.align = "center";
         _nameText.font = "Microsoft YaHei";
         var _loc2_:MovieClip = _ui.getChildByName("ct_name") as MovieClip;
         if(_loc2_)
         {
            _loc2_.addChild(_nameText);
         }
         _infoText = new Text();
         var _loc4_:MovieClip = _ui.getChildByName("ct_money") as MovieClip;
         if(_loc4_)
         {
            _loc4_.addChild(_infoText);
         }
         _selectFighterList = new SelectFighterList();
         _selectFighterList.x = -5;
         _selectFighterList.y = -10;
         _selectFighterList.onSelectFighter = onSelectFighter;
         _selectFighterList.onChangePage = onListPageChange;
         var _loc3_:MovieClip = _ui.getChildByName("ct_list") as MovieClip;
         if(_loc3_)
         {
            _loc3_.addChild(_selectFighterList);
         }
         _dotGroup = new DotsGroupUI();
         _dotGroup.x = 10;
         _dotGroup.y = 10;
         _dotGroup.onDotClick = onDotClick;
         var _loc5_:MovieClip = _ui.getChildByName("ct_dots") as MovieClip;
         if(_loc5_)
         {
            _loc5_.addChild(_dotGroup);
         }
         _dotGroup.update(_selectFighterList.getTotalPage());
      }
      
      private function onDotClick(param1:int) : void
      {
         _selectFighterList.setPage(param1);
      }
      
      private function onListPageChange() : void
      {
         _dotGroup.updateByPage(_selectFighterList.getPage());
      }
      
      private function updateSelectFace(param1:MosouFighterSellVO) : void
      {
         var _loc3_:MovieClip = _ui.getChildByName("ct_face") as MovieClip;
         if(_selectFace)
         {
            try
            {
               _loc3_.removeChild(_selectFace);
            }
            catch(e:Error)
            {
            }
            _selectFace = null;
         }
         var _loc2_:FighterVO = FighterModel.I.getFighter(param1.id);
         _selectFace = AssetManager.I.getFighterFaceWin(_loc2_);
         if(_selectFace)
         {
            _loc3_.addChildAt(_selectFace,0);
         }
      }
      
      private function onSelectFighter(param1:SelectFighterUI) : void
      {
         _curFighterUI = param1;
         _nameText.text = FighterModel.I.getFighterName(param1.sellData.id);
         updateSelectFace(param1.sellData);
         var _loc2_:MovieClip = _ui.getChildByName("ct_money") as MovieClip;
         if(param1.isBought())
         {
            _chooseBtn.visible = true;
            _buyBtn.visible = false;
            _infoText.text = "Lv." + param1.getLevel();
            if(_coinico)
            {
               try
               {
                  _loc2_.removeChild(_coinico);
               }
               catch(e:Error)
               {
               }
            }
            _infoText.x = 0;
         }
         else
         {
            _chooseBtn.visible = false;
            _buyBtn.visible = true;
            _infoText.text = param1.sellData.getPrice().toString();
            if(_coinico)
            {
               _loc2_.addChild(_coinico);
               _infoText.x = _coinico.width;
            }
         }
      }
      
      private function btnHandler(param1:SimpleButton) : void
      {
         var b:SimpleButton = param1;
         switch(b)
         {
            case _chooseBtn:
               if(!_curFighterUI)
               {
                  return;
               }
               GameData.I.mosouData.setFighterTeam(_fighterIndex,_curFighterUI.sellData.id);
               GameData.I.saveData();
               closeSelf();
               break;
            case _buyBtn:
               if(!_curFighterUI)
               {
                  return;
               }
               MosouLogic.I.buyFighter(_curFighterUI.sellData,function():void
               {
                  _selectFighterList.update();
                  onSelectFighter(_curFighterUI);
               });
               break;
            case _coinClearBtn:
               GameUI.confrim(GetLangText("game_ui.confrim.musou_clear_coin.title"),GetLangText("game_ui.confrim.musou_clear_coin.message"),function():void
               {
                  GameData.I.mosouData.loseMoney(GameData.I.mosouData.getMoney());
               },null,true);
         }
      }
      
      override protected function onDestory() : void
      {
         super.onDestory();
         if(_coinUI)
         {
            _coinUI.destory();
            _coinUI = null;
         }
         if(_dotGroup)
         {
            _dotGroup.destory();
            _dotGroup = null;
         }
         if(_selectFighterList)
         {
            _selectFighterList.destory();
            _selectFighterList = null;
         }
      }
   }
}

