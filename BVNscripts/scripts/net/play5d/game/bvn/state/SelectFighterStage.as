package net.play5d.game.bvn.state
{
   import com.greensock.*;
   import com.greensock.easing.*;
   import flash.display.DisplayObject;
   import flash.events.*;
   import flash.system.Capabilities;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.ui.select.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   import net.play5d.kyo.utils.*;
import net.play5d.game.bvn.Debugger;
   
   public class SelectFighterStage implements Istage
   {
      
      public static var AUTO_FINISH:Boolean = true;

      /** 当前每页高度（buildList 时动态计算） */
      public static var PAGE_HEIGHT:Number = 600;
      /** 当前总页数 */
      public static var TOTAL_PAGES:int = 5;
      /** 当前页号（0-based，用于翻页动画） */
      public static var CURRENT_PAGE:int = 0;
      
      private static const SELECT_STATE_FIGHTER:int = 0;
      
      private static const SELECT_STATE_ASSIST:int = 1;
      
      private static const SELECT_STATE_MAP:int = 2;
      
      public var _selectState:int;
      
      private var _ui:*;
      
      private var _config:SelectStageConfigVO;
      
      private var _curListConfig:SelectCharListConfigVO;
      
      private var _itemObj:Object;
      
      private var _p1Slt:SelecterItemUI;
      
      private var _p2Slt:SelecterItemUI;
      
      private var _p1SelectedGroup:SelectedFighterGroup;
      
      private var _p2SelectedGroup:SelectedFighterGroup;
      
      private var _mapSelectUI:MapSelectUI;
      
      private var _curStep:int = 0;
      
      private var _tweenTime:int = 500;
      
      private var _twoPlayerSelectFin:Boolean;

      // 分页控制
      private var _pagEnabled:Boolean = true;
      private var _pagSelect:int = 0;
      private var _pagSpeed:int = 100;
      private var _pagArr:Array = [];
      private var _pagInitialized:Boolean = false;

      public function SelectFighterStage()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function build() : void
      {
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.select,ResUtils.SELECT);
         this._config = GameData.I.config.select_config;
         GameRender.add(this.render);
         GameInputer.focus();
         GameInputer.enabled = false;
         this.initPagination();
         this.nextStep();
         SoundCtrl.I.BGM(AssetManager.I.getSound("select"));
         StateCtrl.I.clearTrans();
         KeyBoarder.focus();
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["select_fighter"])));
      }
      
      private function initFighter() : void
      {
         Debugger.log("初始化选人");
         this.clear();
         this._selectState = 0;
         this.buildList(this._config.charList);
         GameData.I.p1Select = new SelectVO();
         if(Boolean(GameMode.isVsPeople()) || Boolean(GameMode.isVsCPU()))
         {
            GameData.I.p2Select = new SelectVO();
         }
         GameInputer.enabled = false;
         setTimeout(this.initSelecter,this._tweenTime);
      }
      
      private function initAssist() : void
      {
         Debugger.log("初始化辅助");
         this.clear();
         this._selectState = 1;
         this.buildList(this._config.assistList);
         GameInputer.enabled = false;
         setTimeout(this.initSelecter,this._tweenTime);
      }
      
      private function fadOutList(param1:Function = null) : void
      {
         var _loc5_:* = undefined;
         var _loc2_:Number = NaN;
         GameInputer.enabled = false;
         var _loc3_:Number = GameConfig.GAME_SIZE.x / 2 - 30;
         var _loc4_:Number = GameConfig.GAME_SIZE.y / 2 - 30;
         for each(_loc5_ in this._itemObj)
         {
            _loc2_ = Math.random() * 0.1;
            TweenLite.to(_loc5_.ui,0.2,{
               "x":_loc3_,
               "y":_loc4_,
               "scaleX":0,
               "scaleY":0,
               "delay":_loc2_
            });
         }
         if(param1 != null)
         {
            TweenLite.delayedCall(0.3,param1);
         }
      }
      
      private function clear() : void
      {
         var _loc1_:* = undefined;
         if(Boolean(this._itemObj))
         {
            for each(_loc1_ in this._itemObj)
            {
               _loc1_.removeEventListener("mouseOver",this.selectFighterMouseHandler);
               _loc1_.removeEventListener("click",this.selectFighterMouseHandler);
               _loc1_.removeEventListener("touchTap",this.selectFighterTouchHandler);
               _loc1_.destory();
            }
            this._itemObj = null;
         }
         if(Boolean(this._p1Slt))
         {
            this._p1Slt.destory();
            this._p1Slt = null;
         }
         if(Boolean(this._p2Slt))
         {
            this._p2Slt.destory();
            this._p2Slt = null;
         }
         if(Boolean(this._mapSelectUI))
         {
            this._mapSelectUI.destory();
            this._mapSelectUI = null;
         }
         if(Boolean(this._p1SelectedGroup))
         {
            this._p1SelectedGroup.destory();
            this._p1SelectedGroup = null;
         }
         if(Boolean(this._p2SelectedGroup))
         {
            this._p2SelectedGroup.destory();
            this._p2SelectedGroup = null;
         }
      }
      
      private function buildList(param1:SelectCharListConfigVO) : void
      {
         var _loc2_:int = 0;
         var _loc3_:SelectCharListItemVO = null;
         var _loc4_:SelectFighterItem = null;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = this._config.x + this._config.left;
         var _loc9_:Number = this._config.y + this._config.top;
         var _loc10_:Number = param1.HCount > 1 ? 1.35 * (this._config.width - this._config.unitSize.x - this._config.left - this._config.right) / (param1.HCount - 1) : 0;
         var _loc11_:Number = param1.VCount > 1 ? (this._config.height - this._config.unitSize.y - this._config.top - this._config.bottom) / (param1.VCount - 1) : 0;
         var _loc12_:Array = param1.list;
         this._curListConfig = param1;
         this._itemObj = {};
         var _loc13_:Number = GameConfig.GAME_SIZE.x / 2 - 30;
         var _loc14_:Number = GameConfig.GAME_SIZE.y / 2 - 30;

         // 分页: 每页最多 ROWS_PER_PAGE 行，页高 = 实际行数 * 行间距
         var rowsPerPage:int = 8;
         if(rowsPerPage < 1) { rowsPerPage = 1; }
         var maxY:int = 0;
         for each(var _itemVO:SelectCharListItemVO in _loc12_)
         {
            if(_itemVO.y > maxY) { maxY = _itemVO.y; }
         }
         // 重算 VCount 为实际每页行数，用于垂直间距计算
         var displayedVCount:int = param1.VCount;
         if(displayedVCount > rowsPerPage) { displayedVCount = rowsPerPage; }
         if(displayedVCount > 1)
         {
            _loc11_ = (this._config.height - this._config.unitSize.y - this._config.top - this._config.bottom) / (displayedVCount - 1);
         }
         var pageHeight:Number = rowsPerPage * _loc11_;
         PAGE_HEIGHT = pageHeight;
         TOTAL_PAGES = Math.max(1, Math.ceil((maxY + 1) / rowsPerPage));
         CURRENT_PAGE = 0;
         Debugger.log("[SelectFighterStage] pages:", TOTAL_PAGES, "pageHeight:", PAGE_HEIGHT, "rowsPerPage:", rowsPerPage);

         while(_loc2_ < _loc12_.length)
         {
            _loc3_ = _loc12_[_loc2_];
            _loc4_ = this.addFighterItem(_loc3_);
            if(Boolean(_loc4_))
            {
               _loc5_ = _loc8_ + _loc10_ * (_loc4_.selectData.x);
               var pageIdx:int = int(_loc4_.selectData.y / rowsPerPage);
               var yInPage:int = int(_loc4_.selectData.y % rowsPerPage);
               _loc6_ = _loc9_ + _loc11_ * yInPage + pageIdx * pageHeight;
               if(Boolean(_loc4_.selectData.offset))
               {
                  _loc5_ += _loc4_.selectData.offset.x;
                  _loc6_ += _loc4_.selectData.offset.y;
               }
               _loc4_.ui.scaleX = 0;
               _loc4_.ui.scaleY = 0;
               _loc4_.ui.x = _loc13_;
               _loc4_.ui.y = _loc14_;
               _loc7_ = Math.random() * (this._tweenTime - 300) / 1000;
               TweenLite.to(_loc4_.ui,0.3,{
                  "x":_loc5_,
                  "y":_loc6_,
                  "delay":_loc7_,
                  "scaleX":1,
                  "scaleY":1,
                  "ease":Back.easeOut
               });
            }
            _loc2_++;
         }
         // 重新计算分页位置
         _pagArr = [0];
         for (var pi:int = 1; pi < TOTAL_PAGES; pi++) {
            _pagArr.push(pi * -PAGE_HEIGHT);
         }
         CURRENT_PAGE = 0;
         Debugger.log("[SelectFighterStage] pagination pages:", TOTAL_PAGES, "positions:", _pagArr);
      }

      private function addFighterItem(param1:SelectCharListItemVO) : SelectFighterItem
      {
         if(!param1.fighterID)
         {
            return null;
         }
         var _loc2_:FighterVO = this._selectState == 1 ? AssisterModel.I.getAssister(param1.fighterID) : FighterModel.I.getFighter(param1.fighterID);
         if(!_loc2_)
         {
            Debugger.log("SelectFighterStage.addFighterItem :: 未找到角色数据：" + param1.fighterID);
            return null;
         }
         var _loc3_:Number = 60;
         var _loc4_:Number = 60;
         var _loc5_:SelectFighterItem = new SelectFighterItem(_loc2_,param1);
         if(GameConfig.TOUCH_MODE)
         {
            _loc5_.addEventListener("touchTap",this.selectFighterTouchHandler);
         }
         else
         {
            _loc5_.addEventListener("mouseOver",this.selectFighterMouseHandler);
            _loc5_.addEventListener("click",this.selectFighterMouseHandler);
         }
         if(this._ui && this._ui.bg)
         {
            this._ui.bg.addChild(_loc5_.ui);
         }
         else
         {
            this._ui.addChild(_loc5_.ui);
         }
         this._itemObj[param1.x + "," + param1.y] = _loc5_;
         return _loc5_;
      }
      
      private function selectFighterMouseHandler(param1:String, param2:SelectFighterItem) : void
      {
         if(!param2 || !param2.selectData)
         {
            return;
         }
         switch(param1)
         {
            case "mouseOver":
               this.doHover(param2);
               break;
            case "click":
               this.doSelect(param2);
         }
      }
      
      private function selectFighterTouchHandler(param1:String, param2:SelectFighterItem) : void
      {
         if(!param2 || !param2.selectData)
         {
            return;
         }
         var _loc3_:SelecterItemUI = null;
         if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
         {
            _loc3_ = this._p1Slt;
         }
         if(!_loc3_ && (Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled)))
         {
            _loc3_ = this._p2Slt;
         }
         if(!_loc3_)
         {
            return;
         }
         if(this.isHoverFighter(_loc3_,param2))
         {
            this.doSelect(param2);
         }
         else
         {
            this.doHover(param2);
         }
      }
      
      private function doHover(param1:SelectFighterItem) : void
      {
         if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
         {
            if(this._p1Slt.isSelected(param1.selectData.fighterID))
            {
               return;
            }
            this.moveToSelectFighter(this._p1Slt,param1);
            SoundCtrl.I.sndSelect();
            return;
         }
         if(Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled))
         {
            if(this._p2Slt.isSelected(param1.selectData.fighterID))
            {
               return;
            }
            this.moveToSelectFighter(this._p2Slt,param1);
            SoundCtrl.I.sndSelect();
            return;
         }
      }
      
      private function doSelect(param1:SelectFighterItem) : void
      {
         if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
         {
            if(this._p1Slt.isSelected(param1.selectData.fighterID))
            {
               return;
            }
            this._p1Slt.select(this.playerSeltBack);
            SoundCtrl.I.sndConfrim();
            return;
         }
         if(Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled))
         {
            if(this._p2Slt.isSelected(param1.selectData.fighterID))
            {
               return;
            }
            this._p2Slt.select(this.playerSeltBack);
            SoundCtrl.I.sndConfrim();
            return;
         }
      }
      
      private function getFighterItem(param1:int, param2:int) : SelectFighterItem
      {
         if(!this._itemObj)
         {
            return null;
         }
         return this._itemObj[param1 + "," + param2];
      }
      
      private function initSelecter() : void
      {
         GameInputer.enabled = true;
         if(GameMode.isVsPeople())
         {
            this.initSelecterP1();
            this.initSelecterP2();
            this._twoPlayerSelectFin = false;
         }
         else
         {
            this.initSelecterP1();
         }
      }
      
      private function initSelecterP1() : void
      {
         this._p1Slt = SelectUIFactory.createSelecter(1);
         this._p1Slt.isSelectAssist = this._selectState == 1;
         this._p1Slt.selectTimesCount = Boolean(GameMode.isTeamMode()) && !this._p1Slt.isSelectAssist ? 3 : 1;
         this._ui.addChild(this._p1Slt.ui);
         this._ui.addChild(this._p1Slt.group);
         this.moveSlt(this._p1Slt,0,0);
      }
      
      private function initSelecterP2() : void
      {
         this._p2Slt = SelectUIFactory.createSelecter(2);
         this._p2Slt.isSelectAssist = this._selectState == 1;
         this._p2Slt.selectTimesCount = Boolean(GameMode.isTeamMode()) && !this._p2Slt.isSelectAssist ? 3 : 1;
         this._ui.addChild(this._p2Slt.ui);
         this._ui.addChild(this._p2Slt.group);
         this.moveSlt(this._p2Slt,9,0);
      }
      
      private function moveSlt(param1:SelecterItemUI, param2:int, param3:int, param4:Boolean = true) : Boolean
      {
         var _loc5_:Boolean = false;
         var _loc6_:Boolean = false;
         var _loc7_:Boolean = false;
         var _loc8_:Boolean = false;
         var _loc9_:int = 0;
         var _loc10_:* = 0;
         var _loc11_:Boolean = false;
         var _loc12_:SelectFighterItem = this.getFighterItem(param2,param3);
         if(!_loc12_ || Boolean(_loc12_) && Boolean(param1.isSelected(_loc12_.selectData.fighterID)))
         {
            if(!param4)
            {
               return true;
            }
            if(param2 > param1.x)
            {
               _loc5_ = true;
               _loc10_ = 0;
               while(_loc10_ < this._curListConfig.HCount)
               {
                  _loc9_ = param2 + _loc10_;
                  if(_loc9_ > this._curListConfig.HCount - 1)
                  {
                     _loc9_ -= this._curListConfig.HCount;
                  }
                  _loc12_ = this.getFighterItem(_loc9_,param1.y);
                  if(Boolean(_loc12_) && !param1.isSelected(_loc12_.selectData.fighterID))
                  {
                     break;
                  }
                  _loc10_++;
               }
            }
            if(param2 < param1.x)
            {
               _loc8_ = true;
               _loc10_ = 0;
               while(_loc10_ < this._curListConfig.HCount)
               {
                  _loc9_ = param2 - _loc10_;
                  if(_loc9_ < 0)
                  {
                     _loc9_ = this._curListConfig.HCount + _loc9_;
                  }
                  _loc12_ = this.getFighterItem(_loc9_,param1.y);
                  if(Boolean(_loc12_) && !param1.isSelected(_loc12_.selectData.fighterID))
                  {
                     break;
                  }
                  _loc10_++;
               }
            }
            if(param3 > param1.y)
            {
               _loc7_ = true;
               if(param3 > this._curListConfig.VCount - 1)
               {
                  param3 = 0;
               }
               _loc10_ = param3;
               while(_loc10_ < this._curListConfig.VCount)
               {
                  _loc12_ = this.getHLineFighter(param1.x,_loc10_);
                  if(Boolean(_loc12_))
                  {
                     break;
                  }
                  _loc10_++;
               }
            }
            if(param3 < param1.y)
            {
               _loc6_ = true;
               if(param3 < 0)
               {
                  param3 = this._curListConfig.VCount - 1;
               }
               _loc10_ = param3;
               while(_loc10_ >= 0)
               {
                  _loc12_ = this.getHLineFighter(param1.x,_loc10_);
                  if(Boolean(_loc12_))
                  {
                     break;
                  }
                  _loc10_--;
               }
            }
         }
         if(!_loc12_)
         {
            return false;
         }
         param1.x = _loc12_.selectData.x;
         param1.y = _loc12_.selectData.y;
         if(param1.isSelected(_loc12_.selectData.fighterID))
         {
            if(_loc6_ || _loc7_)
            {
               _loc11_ = Boolean(this.moveSlt(param1,param1.x + 1,param1.y));
               if(!_loc11_)
               {
                  if(_loc6_)
                  {
                     this.moveSlt(param1,param1.x,param1.y - 1);
                  }
                  if(_loc7_)
                  {
                     this.moveSlt(param1,param1.x,param1.y + 1);
                  }
               }
            }
            return true;
         }
         this.moveToSelectFighter(param1,_loc12_);
         return true;
      }
      
      private function isHoverFighter(param1:SelecterItemUI, param2:SelectFighterItem) : Boolean
      {
         return param1.x == param2.selectData.x && param1.y == param2.selectData.y;
      }
      
      private function moveToSelectFighter(param1:SelecterItemUI, param2:SelectFighterItem) : void
      {
         param1.randoms = null;
         param1.x = param2.selectData.x;
         param1.y = param2.selectData.y;
         param1.moveTo(param2.ui.x,param2.ui.y);
         param1.currentFighter = param2.fighterData;
         if(Boolean(param1.group))
         {
            param1.group.updateFighter(param1.currentFighter);
         }
         this.checkRandom(param1);
      }
      
      private function checkRandom(param1:SelecterItemUI) : Boolean
      {
         var slt:SelecterItemUI = null;
         slt = param1;
         if(slt.currentFighter.id.indexOf("random") != -1)
         {
            switch(this._selectState)
            {
               case 0:
                  slt.randoms = FighterModel.I.getFighters(slt.currentFighter.comicType,function(param1:FighterVO):Boolean
                  {
                     return param1.id.indexOf("random") == -1 && Boolean(GameLogic.canSelectFighter(param1.id)) && !slt.selectVO.isSelected(param1.id);
                  });
                  break;
               case 1:
                  slt.randoms = AssisterModel.I.getAssisters(slt.currentFighter.comicType,function(param1:FighterVO):Boolean
                  {
                     return param1.id.indexOf("random") == -1 && Boolean(GameLogic.canSelectAssist(param1.id));
                  });
                  break;
               default:
                  return false;
            }
            slt.randFrame = 0;
            this.renderRandom(slt);
            return true;
         }
         return false;
      }
      
      private function getHLineFighter(param1:int, param2:int) : SelectFighterItem
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:SelectFighterItem = null;
         while(true)
         {
            _loc4_ = param1 + _loc3_;
            if(_loc4_ >= 0 && _loc4_ < this._curListConfig.HCount)
            {
               _loc5_ = this.getFighterItem(_loc4_,param2);
               if(Boolean(_loc5_))
               {
                  break;
               }
            }
            if(_loc3_ == 0)
            {
               _loc3_ = 1;
            }
            else if(_loc3_ > 0)
            {
               _loc3_ *= -1;
            }
            else
            {
               if(_loc3_ < -this._curListConfig.HCount)
               {
                  return null;
               }
               _loc3_ *= -1;
               _loc3_++;
            }
         }
         return _loc5_;
      }
      
      private function renderRandom(param1:SelecterItemUI) : void
      {
         if(Boolean(param1.randoms))
         {
            if(param1.randFrame > 0)
            {
               param1.randFrame = 0;
               return;
            }
            ++param1.randFrame;
            param1.currentFighter = KyoRandom.getRandomInArray(param1.randoms,false);
            if(Boolean(param1.group))
            {
               param1.group.updateFighter(param1.currentFighter);
            }
         }
      }
      
      private function render() : void
      {
         // 分页：辅助界面时隐藏按钮并归位
         if (_pagInitialized && this._ui) {
            if (this._selectState == 1) {
               if (this._ui.bg) this._ui.bg.y = 0;
               if (this._ui.up) this._ui.up.visible = false;
               if (this._ui.down) this._ui.down.visible = false;
            } else {
               if (this._ui.up) this._ui.up.visible = true;
               if (this._ui.down) this._ui.down.visible = true;
            }
         }

         var _loc1_:String = null;
         if(GameInputer.back(1))
         {
            if(GameUI.showingDialog())
            {
               GameUI.closeConfrim();
            }
            else
            {
               GameUI.confrim("BACK TITLE?","返回到主菜单？",MainGame.I.goMenu);
            }
         }
         if(GameUI.showingDialog())
         {
            return;
         }
         if(Boolean(this._p1Slt) && Boolean(this._p1Slt.enabled))
         {
            this.renderRandom(this._p1Slt);
            _loc1_ = this._p1Slt.inputType;
            if(GameInputer.up(_loc1_,1))
            {
               this.moveSlt(this._p1Slt,this._p1Slt.x,this._p1Slt.y - 1);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.down(_loc1_,1))
            {
               this.moveSlt(this._p1Slt,this._p1Slt.x,this._p1Slt.y + 1);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.left(_loc1_,1))
            {
               this.moveSlt(this._p1Slt,this._p1Slt.x - 1,this._p1Slt.y);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               this.moveSlt(this._p1Slt,this._p1Slt.x + 1,this._p1Slt.y);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.select(_loc1_,1))
            {
               this._p1Slt.select(this.playerSeltBack);
               SoundCtrl.I.sndConfrim();
            }
         }
         if(Boolean(this._p2Slt) && Boolean(this._p2Slt.enabled))
         {
            _loc1_ = this._p2Slt.inputType;
            this.renderRandom(this._p2Slt);
            if(GameInputer.up(_loc1_,1))
            {
               this.moveSlt(this._p2Slt,this._p2Slt.x,this._p2Slt.y - 1);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.down(_loc1_,1))
            {
               this.moveSlt(this._p2Slt,this._p2Slt.x,this._p2Slt.y + 1);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.left(_loc1_,1))
            {
               this.moveSlt(this._p2Slt,this._p2Slt.x - 1,this._p2Slt.y);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               this.moveSlt(this._p2Slt,this._p2Slt.x + 1,this._p2Slt.y);
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.select(_loc1_,1))
            {
               this._p2Slt.select(this.playerSeltBack);
               SoundCtrl.I.sndConfrim();
            }
         }
         if(Boolean(this._mapSelectUI) && Boolean(this._mapSelectUI.enabled))
         {
            _loc1_ = this._mapSelectUI.inputType;
            if(GameInputer.left(_loc1_,1))
            {
               this._mapSelectUI.prev();
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.right(_loc1_,1))
            {
               this._mapSelectUI.next();
               SoundCtrl.I.sndSelect();
            }
            if(GameInputer.select(_loc1_,1))
            {
               this._mapSelectUI.select(this.onMapSelect);
               SoundCtrl.I.sndConfrim();
            }
         }
      }
      
      public function get p1SelectFinish() : Boolean
      {
         return Boolean(this._p1Slt) && Boolean(this._p1Slt.selectFinish());
      }
      
      public function get p2SelectFinish() : Boolean
      {
         return Boolean(this._p2Slt) && Boolean(this._p2Slt.selectFinish());
      }
      
      public function setSelect(param1:int, param2:Array) : void
      {
         var _loc3_:SelecterItemUI = param1 == 1 ? this._p1Slt : this._p2Slt;
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
               _loc2_ = param1 == this._p1Slt ? this._p2Slt : this._p1Slt;
               if(Boolean(_loc2_) && Boolean(_loc2_.selectFinish()) && !this._twoPlayerSelectFin)
               {
                  this._twoPlayerSelectFin = true;
                  if(!AUTO_FINISH)
                  {
                     return;
                  }
                  this.nextStep();
               }
            }
            else
            {
               this.nextStep();
            }
            param1.destory();
         }
         else if(!param1.randoms)
         {
            _loc3_ = param1 == this._p1Slt == 1 ? 1 : -1;
            this.moveSlt(param1,param1.x + _loc3_,param1.y,true);
         }
      }
      
      public function nextStep() : void
      {
         switch(this._curStep)
         {
            case 0:
               this.initFighter();
               this._curStep = 1;
               break;
            case 1:
               if(GameMode.isVsCPU())
               {
                  this._p1Slt.removeSelecter();
                  this._p1Slt.enabled = false;
                  this.initSelecterP2();
                  this._p2Slt.inputType = "P1";
                  this._curStep = 2;
               }
               else
               {
                  this.fadOutList(this.initAssist);
                  this._curStep = 3;
               }
               break;
            case 2:
               this.fadOutList(this.initAssist);
               this._curStep = 3;
               break;
            case 3:
               if(GameMode.isVsCPU())
               {
                  this._p1Slt.removeSelecter();
                  this._p1Slt.enabled = false;
                  this.initSelecterP2();
                  this._p2Slt.inputType = "P1";
                  this._curStep = 4;
               }
               else if(Boolean(GameMode.isVsCPU()) || Boolean(GameMode.isVsPeople()))
               {
                  this.fadOutList(this.initMap);
                  this._curStep = 5;
               }
               else
               {
                  this.startAcradeGame();
               }
               break;
            case 4:
               this._curStep = 5;
               this.fadOutList(this.initMap);
               break;
            case 5:
               this.selectFinish();
         }
      }
      
      private function initMap() : void
      {
         var oldX:Number = NaN;
         var oldY:Number = NaN;
         Debugger.log("选择地图");
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["select_map"])));
         this.clear();
         GameInputer.enabled = false;
         this._mapSelectUI = new MapSelectUI();
         this._ui.addChild(this._mapSelectUI);
         oldX = Number(this._mapSelectUI.x);
         oldY = Number(this._mapSelectUI.y);
         this._mapSelectUI.scaleX = 0;
         this._mapSelectUI.scaleY = 0;
         this._mapSelectUI.x = GameConfig.GAME_SIZE.x / 2;
         this._mapSelectUI.y = GameConfig.GAME_SIZE.y / 2;
         TweenLite.to(this._mapSelectUI,0.3,{
            "x":oldX,
            "y":oldY,
            "scaleX":1,
            "scaleY":1,
            "ease":Back.easeOut,
            "onComplete":function():void
            {
               if(Boolean(_mapSelectUI))
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
         this._mapSelectUI.prev();
      }
      
      private function mapNextHandler() : void
      {
         this._mapSelectUI.next();
      }
      
      private function mapConfrimHandler() : void
      {
         this._mapSelectUI.select(this.onMapSelect);
      }
      
      private function onMapSelect() : void
      {
         this.nextStep();
      }
      
      private function startAcradeGame() : void
      {
         MessionModel.I.initMession();
         this.selectFinish();
      }
      
      private function selectFinish() : void
      {
         GameEvent.dispatchEvent("SELECT_FIGHTER_FINISH");
         if(!AUTO_FINISH)
         {
            return;
         }
         this.goLoadGame();
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["select_finish"])));
      }
      
      public function goLoadGame() : void
      {
         Debugger.log("开始游戏");
         StateCtrl.I.transIn(MainGame.I.loadGame);
      }
      
      public function afterBuild() : void
      {
      }

      // ================================================================
      // 分页控制 — 复用 timeline 的 goNext/goPrev/Animate
      // 只做三件事：① 修 speed=页高（一帧到位防震荡）② 加键盘/滚轮输入 ③ 辅助界面归位
      // ================================================================

      private function initPagination() : void
      {
         if (_pagInitialized) return;
         _pagInitialized = true;
         var isMobile:Boolean = Capabilities.version.indexOf("AND") != -1;
         Debugger.log("[SelectFighterStage] initPagination — isMobile:", isMobile);

         // ① 复用 timeline 翻页，修 speed = 页高（520 → 一帧翻到位，避免震荡）
         if (this._ui && this._ui.hasOwnProperty("speed")) {
            this._ui["speed"] = PAGE_HEIGHT;
            Debugger.log("[SelectFighterStage] timeline speed set to PAGE_HEIGHT:", PAGE_HEIGHT);
         }

         // ② 键盘翻页（Q/E 或 +/-）→ 调 timeline 的 goNext/goPrev
         MainGame.I.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void {
            if (GameUI.showingDialog()) return;
            if (_selectState == 1) return;
            if (_ui && _ui.hasOwnProperty("goNext")) {
               if (e.keyCode == 69 || e.keyCode == 107) { _ui.goNext(); }
               if (e.keyCode == 81 || e.keyCode == 109) { _ui.goPrev(); }
            }
         });

         // PC：鼠标滚轮 → 调 timeline 的 goNext/goPrev
         if (!isMobile) {
            MainGame.I.stage.addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):void {
               if (GameUI.showingDialog()) return;
               if (_selectState == 1) return;
               if (!_ui || !_ui.hasOwnProperty("goNext")) return;
               if (e.delta > 0) { _ui.goPrev(); }
               else if (e.delta < 0) { _ui.goNext(); }
            });
            Debugger.log("[SelectFighterStage] pagination: keyboard + mouse wheel enabled");
         }
      }

      public function destory(param1:Function = null) : void
      {
         this.clear();
         GameRender.remove(this.render);
         GameInputer.enabled = false;
         SoundCtrl.I.BGM(null);
         GameUI.closeConfrim();
      }
   }
}

