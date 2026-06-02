package net.play5d.game.bvn.stage
{
   import com.greensock.TweenLite;
   import com.greensock.easing.Back;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.utils.Dictionary;
   import flash.utils.setTimeout;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.ctrl.StateCtrl;
   import net.play5d.game.bvn.data.AssisterModel;
   import net.play5d.game.bvn.data.FighterModel;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.MessionModel;
   import net.play5d.game.bvn.data.SelectCharListConfigVO;
   import net.play5d.game.bvn.data.SelectCharListItemVO;
   import net.play5d.game.bvn.data.SelectStageConfigVO;
   import net.play5d.game.bvn.data.SelectVO;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.ui.select.MapSelectUI;
   import net.play5d.game.bvn.ui.select.SelectFighterItem;
   import net.play5d.game.bvn.ui.select.SelectUIFactory;
   import net.play5d.game.bvn.ui.select.SelectedFighterGroup;
   import net.play5d.game.bvn.ui.select.SelecterItemUI;
   import net.play5d.game.bvn.utils.KeyBoarder;
   import net.play5d.game.bvn.utils.ResUtils;
   import net.play5d.kyo.stage.Istage;
   import net.play5d.kyo.utils.ArrayMap;
   import net.play5d.kyo.utils.KyoRandom;
   
   public class SelectFighterStage implements Istage
   {
      
      public static var AUTO_FINISH:Boolean = true;
      
      private static const SELECT_STATE_FIGHTER:int = 0;
      
      private static const SELECT_STATE_ASSIST:int = 1;
      
      private static const SELECT_STATE_MAP:int = 2;
      
      private var _selectState:int;
      
      private var _ui:MovieClip;
      
      private var _fighterListUI:Sprite;
      
      private var _config:SelectStageConfigVO;
      
      private var _curListConfig:SelectCharListConfigVO;
      
      private var _itemObj:Object;
      
      private var _p1Slt:SelecterItemUI;
      
      private var _p2Slt:SelecterItemUI;
      
      private var _p1SelectedGroup:SelectedFighterGroup;
      
      private var _p2SelectedGroup:SelectedFighterGroup;
      
      private var _mapSelectUI:MapSelectUI;
      
      private var _curStep:int = 0;
      
      private const _tweenTime:int = 500;
      
      private var _twoPlayerSelectFin:Boolean;
      
      private var _moreFighterMap:Dictionary = new Dictionary();
      
      private var _moreFighterCache:Object = {};
      
      private var _listUI:Sprite;
      
      private var _closeDelay:int = 0;
      
      private var _keyDownDelay:int = 0;
      
      private var _switchIntervalFrame:int;
      
      public function SelectFighterStage()
      {
         super();
      }
      
      private static function renderRandom(param1:SelecterItemUI) : void
      {
         if(param1.randoms != null)
         {
            if(param1.randFrame > 0)
            {
               param1.randFrame = 0;
               return;
            }
            param1.randFrame++;
            if(param1.randoms.length == 0)
            {
               return;
            }
            param1.currentFighter = KyoRandom.getRandomInArray(param1.randoms,false);
            if(param1.group != null)
            {
               param1.group.updateFighter(param1.currentFighter);
            }
         }
      }
      
      private function getOtherSlt(param1:SelecterItemUI) : SelecterItemUI
      {
         return param1 == _p1Slt ? _p2Slt : _p1Slt;
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function build() : void
      {
         _ui = AssetManager.I.createObject(ResUtils.SELECT,"subswfs/select.swf") as MovieClip;
         var _loc1_:MovieClip = AssetManager.I.createObject("my_back","subswfs/back.swf") as MovieClip;
         if(_loc1_ != null)
         {
            _ui.addChild(_loc1_);
         }
         _listUI = new Sprite();
         _fighterListUI = new Sprite();
         _listUI.addChild(_fighterListUI);
         _ui.addChild(_listUI);
         _config = GameData.I.config.select_config;
         GameRender.add(render);
         GameInputer.focus();
         GameInputer.enabled = false;
         nextStep();
         SoundCtrl.I.BGM(AssetManager.I.getSound("select"));
         StateCtrl.I.clearTrans();
         KeyBoarder.focus();
         GameEvent.dispatchEvent("SELECT_FIGHTER");
      }
      
      private function initFighter() : void
      {
         var _loc1_:* = null;
         clear();
         _selectState = 0;
         if(GameData.I.isOpenEgg)
         {
            for each(_loc1_ in _config.charList.list)
            {
               if(_loc1_.fighterID == "random_god")
               {
                  _loc1_.fighterID = "xb_kenshin_sx";
                  break;
               }
            }
         }
         buildList(_config.charList);
         GameData.I.p1Select = new SelectVO();
         if(GameMode.isVsPeople() || GameMode.isVsCPU())
         {
            GameData.I.p2Select = new SelectVO();
         }
         GameInputer.enabled = false;
         setTimeout(initSelecter,500);
      }
      
      private function initAssist() : void
      {
         clear();
         _selectState = 1;
         buildList(_config.assistList);
         GameInputer.enabled = false;
         setTimeout(initSelecter,500);
      }
      
      private function fadOutList(param1:Function = null) : void
      {
         var _loc2_:Number = NaN;
         var _loc6_:int = 0;
         var _loc4_:SelectFighterItem = null;
         moveListUI(0,0);
         GameInputer.enabled = false;
         var _loc7_:Number = GameConfig.GAME_SIZE.x / 2 - 30;
         var _loc8_:Number = GameConfig.GAME_SIZE.y / 2 - 30;
         for each(var _loc5_ in _itemObj)
         {
            _loc2_ = Math.random() * 0.1;
            TweenLite.to(_loc5_.ui,0.2,{
               "x":_loc7_,
               "y":_loc8_,
               "scaleX":0,
               "scaleY":0,
               "delay":_loc2_
            });
         }
         for each(var _loc3_ in _moreFighterMap)
         {
            if(_loc3_)
            {
               _loc6_ = 0;
               while(_loc6_ < _loc3_.length)
               {
                  _loc4_ = _loc3_.getItemByIndex(_loc6_);
                  _loc4_.destory();
                  _loc6_++;
               }
               _moreFighterMap[_loc3_] = null;
            }
         }
         if(param1 != null)
         {
            TweenLite.delayedCall(0.3,param1);
         }
      }
      
      private function clear() : void
      {
         if(_itemObj)
         {
            for each(var _loc1_ in _itemObj)
            {
               _loc1_.removeEventListener("touchTap",selectFighterTouchHandler);
               _loc1_.removeEventListener("mouseOver",selectFighterMouseHandler);
               _loc1_.removeEventListener("click",selectFighterMouseHandler);
               _loc1_.removeEventListener("rightClick",selectFighterMouseHandler);
               _loc1_.destory();
            }
            _itemObj = null;
         }
         if(_p1Slt)
         {
            _p1Slt.destory();
            _p1Slt = null;
         }
         if(_p2Slt)
         {
            _p2Slt.destory();
            _p2Slt = null;
         }
         if(_mapSelectUI)
         {
            _mapSelectUI.destory();
            _mapSelectUI = null;
         }
         if(_p1SelectedGroup)
         {
            _p1SelectedGroup.destory();
            _p1SelectedGroup = null;
         }
         if(_p2SelectedGroup)
         {
            _p2SelectedGroup.destory();
            _p2SelectedGroup = null;
         }
      }
      
      private function buildList(param1:SelectCharListConfigVO) : void
      {
         var _loc9_:SelectFighterItem = null;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc13_:Number = _config.x + _config.left;
         var _loc12_:Number = _config.y + _config.top;
         var _loc4_:Number = param1.HCount > 1 ? (_config.width - _config.unitSize.x - _config.left - _config.right) / (param1.HCount - 1) : 0;
         var _loc6_:Number = param1.VCount > 1 ? (_config.height - _config.unitSize.y - _config.top - _config.bottom) / (param1.VCount - 1) : 0;
         var _loc11_:Array = param1.list;
         _curListConfig = param1;
         _itemObj = {};
         var _loc7_:Number = GameConfig.GAME_SIZE.x / 2 - 30;
         var _loc5_:Number = GameConfig.GAME_SIZE.y / 2 - 30;
         for each(var _loc8_ in _loc11_)
         {
            _loc9_ = addFighterItem(_loc8_);
            if(_loc9_)
            {
               _loc2_ = _loc13_ + _loc4_ * _loc9_.selectData.x;
               _loc3_ = _loc12_ + _loc6_ * _loc9_.selectData.y;
               if(_loc9_.selectData.offset)
               {
                  _loc2_ += _loc9_.selectData.offset.x;
                  _loc3_ += _loc9_.selectData.offset.y;
               }
               _loc9_.ui.scaleX = 0;
               _loc9_.ui.scaleY = 0;
               _loc9_.ui.x = _loc7_;
               _loc9_.ui.y = _loc5_;
               _loc10_ = Math.random() * (500 - 300) / 1000;
               TweenLite.to(_loc9_.ui,0.3,{
                  "x":_loc2_,
                  "y":_loc3_,
                  "delay":_loc10_,
                  "scaleX":1,
                  "scaleY":1,
                  "ease":Back.easeOut
               });
            }
         }
      }
      
      private function addFighterItem(param1:SelectCharListItemVO) : SelectFighterItem
      {
         if(!param1.fighterID)
         {
            return null;
         }
         var _loc2_:FighterVO = _selectState == 1 ? AssisterModel.I.getAssister(param1.fighterID) : FighterModel.I.getFighter(param1.fighterID);
         if(!_loc2_)
         {
            Debugger.log("SelectFighterStage.addFighterItem :: 未找到角色数据：" + param1.fighterID);
            return null;
         }
         var _loc3_:SelectFighterItem = new SelectFighterItem(_loc2_,param1);
         _loc2_.isBan = false;
         if(_loc2_.isGodLevel && GameMode.isVsPeople() && !GameData.I.config.isGodLevel && _loc2_.id.indexOf("placeholder") == -1 && _loc2_.id.indexOf("random") == -1)
         {
            setBanEnabled(_loc3_,true);
         }
         if(GameConfig.TOUCH_MODE)
         {
            _loc3_.addEventListener("touchTap",selectFighterTouchHandler);
         }
         else
         {
            _loc3_.addEventListener("mouseOver",selectFighterMouseHandler);
            _loc3_.addEventListener("click",selectFighterMouseHandler);
            _loc3_.addEventListener("rightClick",selectFighterMouseHandler);
         }
         _fighterListUI.addChild(_loc3_.ui);
         _itemObj[param1.x + "," + param1.y] = _loc3_;
         return _loc3_;
      }
      
      private function selectFighterMouseHandler(param1:String, param2:SelectFighterItem) : void
      {
         if(_keyDownDelay > 0)
         {
            return;
         }
         if(!param2 || !param2.selectData && !param2.isMore)
         {
            return;
         }
         switch(param1)
         {
            case "mouseOver":
               doHover(param2);
               break;
            case "click":
               doSelect(param2);
               break;
            case "rightClick":
               if(_p1Slt && _p1Slt.enabled)
               {
                  switchMoreFighters(_p1Slt);
               }
               if(_p2Slt && _p2Slt.enabled)
               {
                  switchMoreFighters(_p2Slt);
               }
         }
      }
      
      private function selectFighterTouchHandler(param1:String, param2:SelectFighterItem) : void
      {
         if(!param2 || !param2.selectData && !param2.isMore)
         {
            return;
         }
         var _loc3_:SelecterItemUI = null;
         if(_p1Slt && _p1Slt.enabled)
         {
            _loc3_ = _p1Slt;
         }
         if(!_loc3_ && (_p2Slt && _p2Slt.enabled))
         {
            _loc3_ = _p2Slt;
         }
         if(!_loc3_)
         {
            return;
         }
         if(_loc3_.touchHoverItem == param2)
         {
            doSelect(param2);
            _loc3_.touchHoverItem = null;
         }
         else
         {
            _loc3_.touchHoverItem = param2;
            doHover(param2);
            switchMoreFighters(_loc3_);
         }
      }
      
      private function doHover(param1:SelectFighterItem) : void
      {
         if(_p1Slt && _p1Slt.enabled)
         {
            if(_p1Slt.moreEnabled() && param1.isMore)
            {
               moveToSelectFighterMore(_p1Slt,param1);
               SoundCtrl.I.sndSelect();
               return;
            }
            if(checkSelected(_p1Slt,param1))
            {
               return;
            }
            moveToSelectFighter(_p1Slt,param1);
            SoundCtrl.I.sndSelect();
            return;
         }
         if(_p2Slt && _p2Slt.enabled)
         {
            if(_p2Slt.moreEnabled() && param1.isMore)
            {
               moveToSelectFighterMore(_p2Slt,param1);
               SoundCtrl.I.sndSelect();
               return;
            }
            if(checkSelected(_p2Slt,param1))
            {
               return;
            }
            moveToSelectFighter(_p2Slt,param1);
            SoundCtrl.I.sndSelect();
            return;
         }
      }
      
      private function checkSelected(param1:SelecterItemUI, param2:SelectFighterItem) : Boolean
      {
         var _loc4_:Boolean = false;
         var _loc5_:Boolean = false;
         var _loc3_:int = 0;
         if(!param2.selectData && !param2.fighterData)
         {
            return false;
         }
         if(!param2.selectData && param2.fighterData)
         {
            return param1.isSelected(param2.fighterData.id);
         }
         if(param2.selectData)
         {
            _loc4_ = param1.isSelected(param2.selectData.fighterID);
            _loc5_ = false;
            if(param2.selectData.alterFighterIDs && param2.selectData.alterFighterIDs.length > 0)
            {
               _loc3_ = 0;
               while(_loc3_ < param2.selectData.alterFighterIDs.length)
               {
                  if(param1.isSelected(param2.selectData.alterFighterIDs[_loc3_]))
                  {
                     _loc5_ = true;
                     break;
                  }
                  _loc3_++;
               }
            }
            return _loc4_ || _loc5_;
         }
         return param1.isSelected(param2.selectData.fighterID);
      }
      
      private function doSelect(param1:SelectFighterItem) : void
      {
         if(!checkFighterBasicRule(param1.fighterData))
         {
            return;
         }
         if(_p1Slt && _p1Slt.enabled)
         {
            if(checkSelected(_p1Slt,param1))
            {
               return;
            }
            if(!checkFighterBasicRule(_p1Slt.currentFighter))
            {
               return;
            }
            _p1Slt.select(playerSeltBack);
            checkOldDialog(_p1Slt);
            firstSelectBanAll(_p1Slt);
            doHover(param1);
            SoundCtrl.I.sndConfrim();
            return;
         }
         if(_p2Slt && _p2Slt.enabled)
         {
            if(checkSelected(_p2Slt,param1))
            {
               return;
            }
            if(!checkFighterBasicRule(_p2Slt.currentFighter))
            {
               return;
            }
            _p2Slt.select(playerSeltBack);
            checkOldDialog(_p2Slt);
            firstSelectBanAll(_p2Slt);
            doHover(param1);
            SoundCtrl.I.sndConfrim();
         }
      }
      
      private function getFighterItem(param1:int, param2:int) : SelectFighterItem
      {
         if(!_itemObj)
         {
            return null;
         }
         return _itemObj[param1 + "," + param2];
      }
      
      private function initSelecter() : void
      {
         GameInputer.enabled = true;
         if(GameMode.isVsPeople())
         {
            initSelecterP1();
            initSelecterP2();
            _twoPlayerSelectFin = false;
         }
         else
         {
            initSelecterP1();
         }
      }
      
      private function initSelecterP1() : void
      {
         _p1Slt = SelectUIFactory.createSelecter(1);
         _p1Slt.isSelectAssist = _selectState == 1;
         _p1Slt.selectTimesCount = (GameMode.isTeamMode() || GameMode.isMusouMode()) && !_p1Slt.isSelectAssist ? 3 : 1;
         _listUI.addChild(_p1Slt.ui);
         _ui.addChild(_p1Slt.group);
         moveSlt(_p1Slt,0,0);
      }
      
      private function initSelecterP2() : void
      {
         _p2Slt = SelectUIFactory.createSelecter(2);
         _p2Slt.isSelectAssist = _selectState == 1;
         _p2Slt.selectTimesCount = (GameMode.isTeamMode() || GameMode.isMusouMode()) && !_p2Slt.isSelectAssist ? 3 : 1;
         _listUI.addChild(_p2Slt.ui);
         _ui.addChild(_p2Slt.group);
         if(GameMode.isVsPeople())
         {
            moveSlt(_p2Slt,0,0);
            return;
         }
         moveSlt(_p2Slt,9,0);
      }
      
      private function moveSlt(param1:SelecterItemUI, param2:int, param3:int, param4:Boolean = true) : Boolean
      {
         var _loc10_:Boolean = false;
         var _loc11_:Boolean = false;
         var _loc12_:Boolean = false;
         var _loc7_:Boolean = false;
         var _loc9_:int = 0;
         var _loc8_:int = 0;
         var _loc6_:Boolean = false;
         var _loc5_:SelectFighterItem = getFighterItem(param2,param3);
         if(_loc5_ == null || _loc5_ && checkSelected(param1,_loc5_))
         {
            if(!param4)
            {
               return true;
            }
            if(param2 > param1.x)
            {
               _loc10_ = true;
               _loc8_ = 0;
               while(_loc8_ < _curListConfig.HCount)
               {
                  _loc9_ = param2 + _loc8_;
                  if(_loc9_ > _curListConfig.HCount - 1)
                  {
                     _loc9_ -= _curListConfig.HCount;
                  }
                  _loc5_ = getFighterItem(_loc9_,param1.y);
                  if(_loc5_ != null && !checkSelected(param1,_loc5_))
                  {
                     break;
                  }
                  _loc8_++;
               }
            }
            if(param2 < param1.x)
            {
               _loc7_ = true;
               _loc8_ = 0;
               while(_loc8_ < _curListConfig.HCount)
               {
                  _loc9_ = param2 - _loc8_;
                  if(_loc9_ < 0)
                  {
                     _loc9_ = _curListConfig.HCount + _loc9_;
                  }
                  _loc5_ = getFighterItem(_loc9_,param1.y);
                  if(_loc5_ != null && !checkSelected(param1,_loc5_))
                  {
                     break;
                  }
                  _loc8_++;
               }
            }
            if(param3 > param1.y)
            {
               _loc12_ = true;
               if(param3 > _curListConfig.VCount - 1)
               {
                  param3 = 0;
               }
               _loc8_ = param3;
               while(_loc8_ < _curListConfig.VCount)
               {
                  _loc5_ = getHLineFighter(param1.x,_loc8_);
                  if(_loc5_ != null)
                  {
                     break;
                  }
                  _loc8_++;
               }
            }
            if(param3 < param1.y)
            {
               _loc11_ = true;
               if(param3 < 0)
               {
                  param3 = _curListConfig.VCount - 1;
               }
               _loc8_ = param3;
               while(_loc8_ >= 0)
               {
                  _loc5_ = getHLineFighter(param1.x,_loc8_);
                  if(_loc5_ != null)
                  {
                     break;
                  }
                  _loc8_--;
               }
            }
         }
         if(_loc5_ == null)
         {
            return false;
         }
         param1.x = _loc5_.selectData.x;
         param1.y = _loc5_.selectData.y;
         if(checkSelected(param1,_loc5_))
         {
            if(_loc11_ || _loc12_)
            {
               _loc6_ = moveSlt(param1,param1.x + 1,param1.y);
               if(!_loc6_)
               {
                  if(_loc11_)
                  {
                     moveSlt(param1,param1.x,param1.y - 1);
                  }
                  if(_loc12_)
                  {
                     moveSlt(param1,param1.x,param1.y + 1);
                  }
               }
            }
            return true;
         }
         moveToSelectFighter(param1,_loc5_);
         return true;
      }
      
      private function isHoverFighter(param1:SelecterItemUI, param2:SelectFighterItem) : Boolean
      {
         if(!param2.selectData)
         {
            return false;
         }
         return param1.x == param2.selectData.x && param1.y == param2.selectData.y;
      }
      
      private function moveToSelectFighter(param1:SelecterItemUI, param2:SelectFighterItem) : void
      {
         var _loc8_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc4_:SelecterItemUI = null;
         if(param2 == null || param2.selectData == null)
         {
            return;
         }
         param1.randoms = null;
         param1.x = param2.selectData.x;
         param1.y = param2.selectData.y;
         var _loc6_:int = _config.charList.HCount;
         var _loc3_:Number = _fighterListUI.width;
         var _loc7_:Number = _loc3_ - GameConfig.GAME_SIZE.x;
         if(_loc7_ > 0)
         {
            _loc8_ = _loc7_ / (_loc6_ - 1);
            _loc4_ = getOtherSlt(param1);
            if(_loc4_ == null || _loc4_.selectFinish())
            {
               _loc5_ = _loc8_ * param1.x;
            }
            else if(param1 != null && _loc4_ != null && !param1.selectFinish() && !_loc4_.selectFinish())
            {
               _loc5_ = _loc8_ * (Math.min(param1.x,_loc4_.x) + Math.abs(param1.x - _loc4_.x) * 0.5);
            }
            moveListUI(-_loc5_,0);
         }
         param1.moveTo(param2.ui.x,param2.ui.y);
         param1.currentFighter = param2.fighterData;
         if(param1.group != null)
         {
            param1.group.updateFighter(param1.currentFighter);
         }
         checkRandom(param1);
         hideMoreFighters(param1);
         if(GameData.I.config.isAutoShowMore)
         {
            showMoreFighters(param1,param2);
         }
      }
      
      private function moveToSelectFighterMore(param1:SelecterItemUI, param2:SelectFighterItem) : void
      {
         param1.randoms = null;
         param1.moreX = param2.position.x;
         param1.moreY = param2.position.y;
         param1.moveTo(param2.ui.x,param2.ui.y);
         param1.currentFighter = param2.fighterData;
         if(param1.group)
         {
            param1.group.updateFighter(param1.currentFighter);
         }
         checkRandom(param1);
      }
      
      private function showMoreFighters(param1:SelecterItemUI, param2:SelectFighterItem) : void
      {
         var _loc7_:int = 0;
         var _loc3_:String = null;
         var _loc11_:FighterVO = null;
         var _loc5_:* = 0;
         var _loc10_:* = 0;
         var _loc12_:Point = null;
         var _loc4_:int = 0;
         var _loc19_:Point = null;
         var _loc8_:int = 0;
         var _loc14_:Point = null;
         var _loc18_:Number = NaN;
         var _loc17_:Number = NaN;
         var _loc15_:SelectFighterItem = null;
         var _loc6_:SelecterItemUI = getOtherSlt(param1);
         if(param1.showingMoreSelecter == param2)
         {
            return;
         }
         hideMoreFighters(param1);
         if(!param2.selectData.moreFighterIDs || param2.selectData.moreFighterIDs.length < 1)
         {
            return;
         }
         var _loc9_:ArrayMap = _moreFighterCache[param2.fighterData.id];
         if(_loc9_ != null && _loc9_.length > 0)
         {
            _moreFighterMap[param1] = _loc9_;
            param1.setMoreEnabled(true,param2);
            if(_loc6_ && _loc6_.showingMoreSelecter == param2)
            {
               return;
            }
            _loc7_ = 0;
            while(_loc7_ < _loc9_.length)
            {
               _loc15_ = _loc9_.getItemByIndex(_loc7_);
               _fighterListUI.addChild(_loc15_.ui);
               _loc15_.showMore(_loc7_ * 0.01);
               _loc7_++;
            }
            return;
         }
         var _loc16_:Array = param2.selectData.moreFighterIDs;
         _loc9_ = new ArrayMap();
         var _loc20_:Array = [new Point(0,-1),new Point(0,1),new Point(-1,0),new Point(1,0),new Point(-1,-1),new Point(1,-1),new Point(-1,1),new Point(1,1)];
         var _loc13_:int = 0;
         _loc7_ = 0;
         while(_loc7_ < _loc16_.length)
         {
            _loc3_ = _loc16_[_loc7_];
            _loc11_ = _selectState == 1 ? AssisterModel.I.getAssister(_loc3_) : FighterModel.I.getFighter(_loc3_);
            if(_loc11_ != null)
            {
               _loc5_ = 60;
               _loc10_ = 60;
               _loc12_ = null;
               _loc4_ = 0;
               _loc19_ = null;
               while(_loc12_ == null)
               {
                  _loc8_ = _loc13_ % 8;
                  _loc13_++;
                  _loc14_ = _loc20_[_loc8_] as Point;
                  if(_loc14_ != null)
                  {
                     _loc18_ = param2.ui.x + _loc14_.x * (_loc5_ + 5);
                     _loc17_ = param2.ui.y + _loc14_.y * (_loc10_ + 5);
                     if(!(_loc17_ < 0 || _loc17_ > GameConfig.GAME_SIZE.y))
                     {
                        _loc19_ = _loc14_.clone();
                        _loc12_ = new Point(_loc18_,_loc17_);
                     }
                  }
               }
               _loc15_ = new SelectFighterItem(_loc11_,null,true);
               _loc11_.isBan = false;
               if(_loc11_.isGodLevel && GameMode.isVsPeople() && !GameData.I.config.isGodLevel && _loc11_.id.indexOf("placeholder") == -1 && _loc11_.id.indexOf("random") == -1)
               {
                  setBanEnabled(_loc15_,true);
               }
               if(GameConfig.TOUCH_MODE)
               {
                  _loc15_.addEventListener("touchTap",selectFighterTouchHandler);
               }
               else
               {
                  _loc15_.addEventListener("mouseOver",selectFighterMouseHandler);
                  _loc15_.addEventListener("click",selectFighterMouseHandler);
               }
               _loc15_.position = _loc19_;
               _loc15_.initMoreTween(new Point(param2.ui.x,param2.ui.y),_loc12_);
               _fighterListUI.addChild(_loc15_.ui);
               _loc4_++;
               _loc15_.showMore(_loc4_ * 0.01);
               _loc9_.push(_loc15_.positionId,_loc15_);
               _moreFighterMap[param1] = _loc9_;
               _moreFighterCache[param2.fighterData.id] = _loc9_;
            }
            _loc7_++;
         }
         param1.setMoreEnabled(true,param2);
      }
      
      private function moveMoreSlt(param1:SelecterItemUI, param2:int, param3:int) : Boolean
      {
         var _loc4_:ArrayMap = _moreFighterMap[param1];
         if(_loc4_ == null || _loc4_.length < 1)
         {
            return false;
         }
         if(param2 == 0 && param3 == 0 && param1.showingMoreSelecter)
         {
            param1.moreX = 0;
            param1.moreY = 0;
            param1.moveTo(param1.showingMoreSelecter.ui.x,param1.showingMoreSelecter.ui.y);
            param1.currentFighter = param1.showingMoreSelecter.fighterData;
            if(param1.group)
            {
               param1.group.updateFighter(param1.currentFighter);
            }
            return true;
         }
         var _loc5_:String = SelectFighterItem.getIdByPoint(param2,param3);
         var _loc6_:SelectFighterItem = _loc4_.getItemById(_loc5_);
         if(_loc6_ == null)
         {
            return false;
         }
         if(param1.isSelected(_loc6_.fighterData.id))
         {
            return false;
         }
         param1.randoms = null;
         param1.moreX = _loc6_.position.x;
         param1.moreY = _loc6_.position.y;
         param1.moveTo(_loc6_.x,_loc6_.y);
         param1.currentFighter = _loc6_.fighterData;
         if(param1.group)
         {
            param1.group.updateFighter(param1.currentFighter);
         }
         return true;
      }
      
      private function checkRandom(param1:SelecterItemUI) : Boolean
      {
         var fighters:Vector.<FighterVO>;
         var levels:Array;
         var p1level:int;
         var validFighters:Vector.<FighterVO>;
         var fv:FighterVO;
         var fv2:FighterVO;
         var assists:Vector.<FighterVO>;
         var validAssists:Vector.<FighterVO>;
         var av:FighterVO;
         var av2:FighterVO;
         var slt:SelecterItemUI = param1;
         var commonFilter:* = function(param1:FighterVO):Boolean
         {
            if(param1.id.indexOf("random") != -1)
            {
               return false;
            }
            if(slt.selectVO.isSelected(param1.id))
            {
               return false;
            }
            if(param1.isZako)
            {
               return false;
            }
            if(isAssist)
            {
               return GameLogic.canSelectAssist(param1.id);
            }
            return GameLogic.canSelectFighter(param1.id);
         };
         var curfv:FighterVO = getFighterItem(slt.x,slt.y).fighterData;
         var isAssist:Boolean = _selectState == 1;
         if(curfv.id.indexOf("random") != -1)
         {
            switch(_selectState)
            {
               case 0:
                  fighters = null;
                  levels = ["random_low","random_medium","random_high","random_god"];
                  if(levels.indexOf(curfv.id) != -1)
                  {
                     fighters = FighterModel.I.getFightersByLevel(curfv.level,commonFilter);
                  }
                  else if(GameData.I.config.isAutoMathRandom && slt == _p2Slt && !GameMode.isVsPeople())
                  {
                     p1level = _p1Slt.currentFighter.level;
                     fighters = FighterModel.I.getFightersByLevel(p1level,commonFilter);
                  }
                  else
                  {
                     fighters = FighterModel.I.getFighters(curfv.comicType,commonFilter);
                  }
                  validFighters = new Vector.<FighterVO>();
                  if(fighters != null)
                  {
                     for each(fv in fighters)
                     {
                        if(checkFighterBasicRule(fv))
                        {
                           validFighters.push(fv);
                        }
                     }
                  }
                  if(validFighters.length == 0 && fighters != null)
                  {
                     for each(fv2 in fighters)
                     {
                        if(fv2 != null && !fv2.isPlaceholder)
                        {
                           validFighters.push(fv2);
                        }
                     }
                  }
                  slt.randoms = validFighters;
                  break;
               case 1:
                  assists = AssisterModel.I.getAssisters(curfv.comicType,function(param1:FighterVO):Boolean
                  {
                     if(param1.id.indexOf("random") != -1 || param1.id.indexOf("debug") != -1)
                     {
                        return false;
                     }
                     return GameLogic.canSelectAssist(param1.id);
                  });
                  validAssists = new Vector.<FighterVO>();
                  if(assists != null)
                  {
                     for each(av in assists)
                     {
                        if(checkFighterBasicRule(av))
                        {
                           validAssists.push(av);
                        }
                     }
                  }
                  if(validAssists.length == 0 && assists != null)
                  {
                     for each(av2 in assists)
                     {
                        if(av2 != null && !av2.isPlaceholder)
                        {
                           validAssists.push(av2);
                        }
                     }
                  }
                  slt.randoms = validAssists;
                  break;
               default:
                  return false;
            }
            if(slt.randoms == null || slt.randoms.length == 0)
            {
               Debugger.log("SelectFighterStage.checkRandom :: 随机池为空（所有角色已禁用）");
               return false;
            }
            renderRandom(slt);
            return true;
         }
         return false;
      }
      
      private function getHLineFighter(param1:int, param2:int) : SelectFighterItem
      {
         var _loc4_:int = 0;
         var _loc3_:SelectFighterItem = null;
         var _loc5_:int = 0;
         while(true)
         {
            _loc4_ = param1 + _loc5_;
            if(_loc4_ >= 0 && _loc4_ < _curListConfig.HCount)
            {
               _loc3_ = getFighterItem(_loc4_,param2);
               if(_loc3_ != null)
               {
                  break;
               }
            }
            if(_loc5_ == 0)
            {
               _loc5_ = 1;
            }
            else if(_loc5_ > 0)
            {
               _loc5_ *= -1;
            }
            else
            {
               if(_loc5_ < -_curListConfig.HCount)
               {
                  return null;
               }
               _loc5_ *= -1;
               _loc5_++;
            }
         }
         return _loc3_;
      }
      
      private function moveSelecter(param1:SelecterItemUI, param2:int, param3:int) : void
      {
         if(param1.moreEnabled())
         {
            if(moveMoreSlt(param1,param1.moreX + param2,param1.moreY + param3))
            {
               return;
            }
            param1.setMoreEnabled(false);
         }
         moveSlt(param1,param1.x + param2,param1.y + param3);
      }
      
      private function render() : void
      {
         var _loc1_:String = null;
         if(GameInputer.anyKey(1))
         {
            _keyDownDelay = 10;
         }
         if(_keyDownDelay > 0)
         {
            _keyDownDelay = _keyDownDelay - 1;
         }
         if(_switchIntervalFrame > 0)
         {
            _switchIntervalFrame = _switchIntervalFrame - 1;
         }
         if(GameInputer.back(1))
         {
            if(GameUI.showingDialog())
            {
               GameUI.cancelConfrim();
            }
            else
            {
               GameUI.confrim(GetLangText("game_ui.confrim.back_title.title"),GetLangText("game_ui.confrim.back_title.message"),MainGame.I.goMenu);
            }
         }
         if(GameUI.showingDialog())
         {
            _closeDelay = 5;
            return;
         }
         if(GameInputer.jump("P1",1))
         {
            if(_mapSelectUI && _mapSelectUI.enabled && _mapSelectUI.showRandomMap())
            {
               return;
            }
            GameUI.confrim(GetLangText("game_ui.confrim.reselect.title"),GetLangText("game_ui.confrim.reselect.message"),MainGame.I.goSelect);
         }
         if(_p2Slt && _p2Slt.enabled)
         {
            if(GameInputer.jump("P2",1))
            {
               if(_mapSelectUI && _mapSelectUI.enabled && _mapSelectUI.showRandomMap())
               {
                  return;
               }
               GameUI.confrim(GetLangText("game_ui.confrim.reselect.title"),GetLangText("game_ui.confrim.reselect.message"),MainGame.I.goSelect);
            }
         }
         if(_closeDelay > 0)
         {
            _closeDelay = _closeDelay - 1;
            return;
         }
         if(_p1Slt && _p1Slt.enabled)
         {
            checkRandom(_p1Slt);
            _loc1_ = _p1Slt.inputType;
            if(GameInputer.up(_loc1_,1))
            {
               moveSelecter(_p1Slt,0,-1);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.down(_loc1_,1))
            {
               moveSelecter(_p1Slt,0,1);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.left(_loc1_,1))
            {
               moveSelecter(_p1Slt,-1,0);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               moveSelecter(_p1Slt,1,0);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.attack(_loc1_,1))
            {
               if(!checkFighterBasicRule(_p1Slt.currentFighter))
               {
                  return;
               }
               _p1Slt.select(playerSeltBack);
               checkOldDialog(_p1Slt);
               firstSelectBanAll(_p1Slt);
               SoundCtrl.I.sndConfrim();
            }
            if(GameInputer.dash(_loc1_,1))
            {
               rollLevel(_p1Slt);
            }
            if(GameInputer.skill(_loc1_,1))
            {
               switchBanEnabled(_p1Slt);
            }
            if(GameInputer.special(_loc1_,1))
            {
               switchMoreFighters(_p1Slt);
            }
         }
         if(_p2Slt && _p2Slt.enabled)
         {
            checkRandom(_p2Slt);
            _loc1_ = _p2Slt.inputType;
            if(GameInputer.up(_loc1_,1))
            {
               moveSelecter(_p2Slt,0,-1);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.down(_loc1_,1))
            {
               moveSelecter(_p2Slt,0,1);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.left(_loc1_,1))
            {
               moveSelecter(_p2Slt,-1,0);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               moveSelecter(_p2Slt,1,0);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.attack(_loc1_,1))
            {
               if(!checkFighterBasicRule(_p2Slt.currentFighter))
               {
                  return;
               }
               _p2Slt.select(playerSeltBack);
               checkOldDialog(_p2Slt);
               firstSelectBanAll(_p2Slt);
               SoundCtrl.I.sndConfrim();
            }
            if(GameInputer.dash(_loc1_,1))
            {
               rollLevel(_p2Slt);
            }
            if(GameInputer.skill(_loc1_,1))
            {
               switchBanEnabled(_p2Slt);
            }
            if(GameInputer.special(_loc1_,1))
            {
               switchMoreFighters(_p2Slt);
            }
         }
         if(_mapSelectUI && _mapSelectUI.enabled)
         {
            _loc1_ = _mapSelectUI.inputType;
            if(GameInputer.left(_loc1_,1))
            {
               _mapSelectUI.prev();
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               _mapSelectUI.next();
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.attack(_loc1_,1))
            {
               _mapSelectUI.select(onMapSelect);
               SoundCtrl.I.sndConfrim();
            }
         }
      }
      
      public function get p1SelectFinish() : Boolean
      {
         return _p1Slt && _p1Slt.selectFinish();
      }
      
      public function get p2SelectFinish() : Boolean
      {
         return _p2Slt && _p2Slt.selectFinish();
      }
      
      public function setSelect(param1:int, param2:Array) : void
      {
         var _loc3_:SelecterItemUI = param1 == 1 ? _p1Slt : _p2Slt;
         _loc3_.setCurrentSelect(param2);
         _loc3_.removeSelecter();
         SoundCtrl.I.sndConfrim();
      }
      
      private function playerSeltBack(param1:SelecterItemUI) : void
      {
         var _loc2_:SelecterItemUI = null;
         var _loc3_:int = 0;
         if(param1.selectFinish())
         {
            if(GameMode.isVsPeople())
            {
               GameEvent.dispatchEvent("SELECT_FIGHTER_STEP",param1.getCurrentSelectes());
               _loc2_ = param1 == _p1Slt ? _p2Slt : _p1Slt;
               if(_loc2_ != null && _loc2_.selectFinish() && !_twoPlayerSelectFin)
               {
                  _twoPlayerSelectFin = true;
                  if(!AUTO_FINISH)
                  {
                     return;
                  }
                  nextStep();
               }
            }
            else
            {
               nextStep();
            }
            hideMoreFighters(param1);
            param1.destory(false);
         }
         else if(param1.randoms)
         {
            renderRandom(param1);
         }
         else
         {
            _loc3_ = param1 == _p1Slt == 1 ? 1 : -1;
            moveSlt(param1,param1.x + _loc3_,param1.y,true);
         }
      }
      
      public function nextStep() : void
      {
         switch(_curStep)
         {
            case 0:
               initFighter();
               _curStep = 1;
               break;
            case 1:
               if(GameMode.isVsCPU())
               {
                  _p1Slt.removeSelecter();
                  _p1Slt.enabled = false;
                  initSelecterP2();
                  _p2Slt.inputType = "P1";
                  _curStep = 2;
               }
               else if(GameMode.isMusouMode())
               {
                  fadOutList(initMap);
                  _curStep = 5;
               }
               else
               {
                  fadOutList(initAssist);
                  _curStep = 3;
               }
               break;
            case 2:
               if(GameMode.isMusouMode())
               {
                  fadOutList(initMap);
                  _curStep = 5;
               }
               else
               {
                  fadOutList(initAssist);
                  _curStep = 3;
               }
               break;
            case 3:
               if(GameMode.isVsCPU())
               {
                  _p1Slt.removeSelecter();
                  _p1Slt.enabled = false;
                  initSelecterP2();
                  _p2Slt.inputType = "P1";
                  _curStep = 4;
               }
               else if(GameMode.isVsCPU() || GameMode.isVsPeople())
               {
                  fadOutList(initMap);
                  _curStep = 5;
               }
               else
               {
                  if(GameMode.isAcrade())
                  {
                     startAcradeGame();
                  }
                  if(GameMode.currentMode == 100)
                  {
                     startMosouGame();
                  }
               }
               break;
            case 4:
               _curStep = 5;
               fadOutList(initMap);
               break;
            case 5:
               _curStep = 6;
               selectFinish();
         }
      }
      
      private function initMap() : void
      {
         var oldX:Number;
         var oldY:Number;
         GameEvent.dispatchEvent("SELECT_MAP");
         clear();
         GameInputer.enabled = false;
         _mapSelectUI = new MapSelectUI();
         _ui.addChild(_mapSelectUI);
         oldX = _mapSelectUI.x;
         oldY = _mapSelectUI.y;
         _mapSelectUI.scaleX = 0;
         _mapSelectUI.scaleY = 0;
         _mapSelectUI.x = GameConfig.GAME_SIZE.x * 0.5;
         _mapSelectUI.y = GameConfig.GAME_SIZE.y * 0.5;
         TweenLite.to(_mapSelectUI,0.3,{
            "x":oldX,
            "y":oldY,
            "scaleX":1,
            "scaleY":1,
            "ease":Back.easeOut,
            "onComplete":function():void
            {
               if(_mapSelectUI)
               {
                  _mapSelectUI.addMouseEvents(mapPrevHandler,mapNextHandler,mapConfrimHandler);
                  _mapSelectUI.inputType = "P1";
                  _mapSelectUI.enabled = true;
               }
               GameInputer.enabled = true;
            }
         });
      }
      
      private function mapPrevHandler() : void
      {
         _mapSelectUI.prev();
      }
      
      private function mapNextHandler() : void
      {
         _mapSelectUI.next();
      }
      
      private function mapConfrimHandler() : void
      {
         _mapSelectUI.select(onMapSelect);
      }
      
      private function onMapSelect() : void
      {
         nextStep();
      }
      
      private function startAcradeGame() : void
      {
         MessionModel.I.initMession();
         selectFinish();
      }
      
      private function startMosouGame() : void
      {
         selectFinish();
      }
      
      private function selectFinish() : void
      {
         GameEvent.dispatchEvent("SELECT_FIGHTER_FINISH");
         if(!AUTO_FINISH)
         {
            return;
         }
         goLoadGame();
      }
      
      private function hideMoreFighters(param1:SelecterItemUI) : void
      {
         var _loc5_:SelecterItemUI = getOtherSlt(param1);
         var _loc2_:ArrayMap = null;
         var _loc4_:int = 0;
         var _loc6_:int = 0;
         var _loc3_:SelectFighterItem = null;
         if(_loc5_ != null)
         {
            _loc2_ = _moreFighterMap[_loc5_];
         }
         var _loc7_:ArrayMap = _moreFighterMap[param1];
         if(_loc7_ != null && _loc7_.length > 0)
         {
            _loc4_ = 0;
            for(; _loc4_ < _loc7_.length; _loc4_++)
            {
               _loc3_ = _loc7_.getItemByIndex(_loc4_);
               if(_loc2_ && _loc2_.length)
               {
                  _loc6_ = 0;
                  while(true)
                  {
                     if(_loc6_ < _loc2_.length)
                     {
                        if(_loc3_ == _loc2_.getItemByIndex(_loc6_))
                        {
                           break;
                        }
                        _loc6_++;
                        continue;
                     }
                  }
                  continue;
               }
               _loc3_.hideMore();
            }
            _moreFighterMap[param1] = null;
         }
         param1.setMoreEnabled(false);
      }
      
      private function switchBanEnabled(param1:SelecterItemUI) : void
      {
         var _loc2_:SelectFighterItem = getFighterItem(param1.x,param1.y);
         if(_loc2_.fighterData.isGodLevel && GameMode.isVsPeople() && !GameData.I.config.isGodLevel || _loc2_.fighterData.id.indexOf("placeholder") != -1 || _loc2_.fighterData.id.indexOf("random") != -1)
         {
            return;
         }
         var _loc3_:Boolean = _loc2_.fighterData.isBan;
         setBanEnabled(_loc2_,!_loc3_);
         SoundCtrl.I.sndConfrim();
      }
      
      private function setBanEnabled(param1:SelectFighterItem, param2:Boolean) : void
      {
         param1.fighterData.isBan = param2;
         param1.setBan(param2,param2);
      }
      
      private function rollLevel(param1:SelecterItemUI) : void
      {
         if(param1.isSelectAssist)
         {
            return;
         }
         if(param1.selectTimes != 0)
         {
            return;
         }
         for each(var _loc2_ in _itemObj)
         {
            if(!(_loc2_.fighterData.isGodLevel || _loc2_.fighterData.id.indexOf("placeholder") != -1 || _loc2_.fighterData.id.indexOf("random") != -1))
            {
               setBanEnabled(_loc2_,false);
            }
         }
         var _loc3_:int = int(Math.random() * 3) + 1;
         for each(var _loc4_ in _itemObj)
         {
            if(!(_loc4_.fighterData.isGodLevel || _loc4_.fighterData.id.indexOf("placeholder") != -1 || _loc4_.fighterData.id.indexOf("random") != -1))
            {
               if(_loc4_.fighterData.level != _loc3_)
               {
                  setBanEnabled(_loc4_,true);
               }
            }
         }
         SoundCtrl.I.sndConfrim();
      }
      
      private function switchMoreFighters(param1:SelecterItemUI) : void
      {
         var _loc2_:SelectFighterItem = getFighterItem(param1.x,param1.y);
         if(_loc2_.selectData.moreFighterIDs && _loc2_.selectData.moreFighterIDs.indexOf(param1.currentFighter.id) != -1)
         {
            return;
         }
         if(_switchIntervalFrame > 0)
         {
            if(switchAlterFighters(param1))
            {
               return;
            }
         }
         _switchIntervalFrame = 6;
         if(_loc2_.selectData.moreFighterIDs && _loc2_.selectData.moreFighterIDs.length > 0)
         {
            if(param1.showingMoreSelecter)
            {
               hideMoreFighters(param1);
            }
            else
            {
               showMoreFighters(param1,_loc2_);
            }
            SoundCtrl.I.sndConfrim();
         }
      }
      
      private function switchAlterFighters(param1:SelecterItemUI) : Boolean
      {
         var _loc4_:Boolean = false;
         var _loc2_:FighterVO = null;
         hideMoreFighters(param1);
         var _loc3_:SelectFighterItem = getFighterItem(param1.x,param1.y);
         if(_loc3_.selectData.alterFighterIDs && _loc3_.selectData.alterFighterIDs.length > 0)
         {
            _loc4_ = _loc3_.fighterData.isBan;
            _loc2_ = _loc3_.updateAlter();
            param1.currentFighter = _loc2_;
            _loc2_.isBan = _loc4_;
            setBanEnabled(_loc3_,_loc2_.isBan);
            if(param1.group != null)
            {
               param1.group.updateFighter(param1.currentFighter);
            }
            SoundCtrl.I.sndConfrim();
            Trace("切换另我：" + _loc2_.id);
            return true;
         }
         return false;
      }
      
      private function firstSelectBanAll(param1:SelecterItemUI) : void
      {
         var _loc4_:Array = null;
         var _loc2_:SelectFighterItem = getFighterItem(param1.x,param1.y);
         if(_loc2_.fighterData.id.indexOf("random") != -1)
         {
            _loc4_ = ["random_low","random_medium","random_high","random_god"];
            if(_loc4_.indexOf(_loc2_.fighterData.id) == -1)
            {
               return;
            }
         }
         if(!GameData.I.config.isStandardLimit)
         {
            return;
         }
         if(!GameMode.isVsPeople())
         {
            return;
         }
         if(param1.isSelectAssist)
         {
            return;
         }
         if(param1.selectTimes != 1 || getOtherSlt(param1) != null && getOtherSlt(param1).selectTimes != 0)
         {
            return;
         }
         for each(var _loc3_ in _itemObj)
         {
            if(!(_loc3_.fighterData.id.indexOf("placeholder") != -1 || _loc3_.fighterData.id.indexOf("random") != -1))
            {
               if(_loc3_.fighterData.level != _loc2_.fighterData.level)
               {
                  setBanEnabled(_loc3_,true);
               }
            }
         }
      }
      
      private function checkOldDialog(param1:SelecterItemUI) : void
      {
         if(GameData.I.config.isOldDialog)
         {
            return;
         }
         if(!param1.currentFighter.isOld)
         {
            return;
         }
         var _loc2_:SelectFighterItem = getFighterItem(param1.x,param1.y);
         if(!_loc2_.selectData.moreFighterIDs || _loc2_.selectData.moreFighterIDs.length < 1)
         {
            return;
         }
         GameData.I.config.isOldDialog = true;
         GameData.I.saveData();
         GameUI.alert(GetLangText("game_ui.alert.old_dialog.title"),GetLangText("game_ui.alert.old_dialog.message"));
      }
      
      private function checkFighterBasicRule(param1:FighterVO) : Boolean
      {
         if(!param1)
         {
            return false;
         }
         if(param1.isPlaceholder)
         {
            return false;
         }
         if(param1.isBan)
         {
            return false;
         }
         return true;
      }
      
      public function goLoadGame() : void
      {
         StateCtrl.I.transIn(MainGame.I.loadGame);
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         clear();
         GameRender.remove(render);
         GameInputer.enabled = false;
         GameUI.closeConfrim();
      }
      
      private function moveListUI(param1:Number, param2:Number) : void
      {
         if(_listUI != null)
         {
            TweenLite.to(_listUI,0.2,{
               "x":param1,
               "y":param2
            });
         }
      }
   }
}

