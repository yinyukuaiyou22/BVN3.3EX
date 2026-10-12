package net.play5d.game.bvn.state
{
   import com.greensock.*;
   import flash.display.DisplayObject;
   import flash.events.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.Assister;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.ui.select.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.stage.*;
   
   public class LoadingState implements Istage
   {
      
      public static var AUTO_START_GAME:Boolean = true;
      
      private var _ui:*;
      
      private var _sltUI:*;
      
      /** AS3 批量加载并发度：角色/辅助 SWF 体积大（外置可达数 MB），3 路并发控制内存峰值 */
      private static const SWF_BATCH_CONCURRENCY:int = 3;
      
      private var _loadItems:Array;
      
      private var _fightBGMs:Array;
      
      private var _mapBgm:Object;
      
      private var _curMsg:String;
      
      private var _loadCount:int;
      
      private var _loadDone:int;
      
      private var _destoryed:Boolean;
      
      private var _loadFin:Boolean;
      
      private var _selectIndexUI:SelectIndexUI;
      
      private var _loadedFighterCache:Object = {};
      
      private var _gameFinished:Boolean;
      
      public function LoadingState()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return this._ui;
      }
      
      public function p1SelectFinish() : Boolean
      {
         return this._selectIndexUI.p1Finish();
      }
      
      public function p2SelectFinish() : Boolean
      {
         return this._selectIndexUI.p2Finish();
      }
      
      public function selectFinish() : Boolean
      {
         return this._selectIndexUI.isFinish();
      }
      
      public function getSort() : Array
      {
         return [this._selectIndexUI.getP1Order(),this._selectIndexUI.getP2Order()];
      }
      
      public function setOrder(param1:int, param2:Array) : void
      {
         if(param1 == 1)
         {
            this._selectIndexUI.setP1Order(param2);
         }
         if(param1 == 2)
         {
            this._selectIndexUI.setP2Order(param2);
         }
      }
      
      public function build() : void
      {
         var p1selt:SelectVO = null;
         var p2selt:SelectVO = null;
         var fighters:Array = null;
         var assisters:Array = null;
         var fighter:FighterVO = null;
         var fighterName:String = null;
         var o:Object = null;
         var fightBGMs:Array = null;
         var i:int = 0;
         var map:MapVO = null;
         var mapName:String = null;
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["loading_start"])));
         GameRender.add(this.render);
         GameInputer.focus();
         GameInputer.enabled = true;
         SoundCtrl.I.BGM(AssetManager.I.getSound("loading"));
         this._ui = ResUtils.I.createDisplayObject(ResUtils.I.fight,"loading_fight_mc");
         this._sltUI = this._ui.sltui;
         this._selectIndexUI = new SelectIndexUI();
         this._selectIndexUI.onFinish = this.finish;
         this._sltUI.addChild(this._selectIndexUI);
         p1selt = GameData.I.p1Select;
         p2selt = GameData.I.p2Select;
         this._loadItems = [];
         this._fightBGMs = [];
         this._mapBgm = null;
         fighters = [{
            "id":p1selt.fighter1,
            "runobj":{"id":"p1"}
         },{
            "id":p1selt.fighter2,
            "runobj":{"id":"p1"}
         },{
            "id":p1selt.fighter3,
            "runobj":{"id":"p1"}
         },{
            "id":p2selt.fighter1,
            "runobj":{"id":"p2"}
         },{
            "id":p2selt.fighter2,
            "runobj":{"id":"p2"}
         },{
            "id":p2selt.fighter3,
            "runobj":{"id":"p2"}
         }];
         assisters = [{
            "id":p1selt.fuzhu,
            "runobj":{
               "group":"p1FighterGroup",
               "id":"fuzhu"
            }
         },{
            "id":p2selt.fuzhu,
            "runobj":{
               "group":"p2FighterGroup",
               "id":"fuzhu"
            }
         }];
         while(i < fighters.length)
         {
            o = fighters[i];
            if(Boolean(o.id))
            {
               fighterName = o.id;
               fighter = FighterModel.I.getFighter(o.id);
               if(Boolean(fighter))
               {
                  if(Boolean(fighter.bgm))
                  {
                     this._fightBGMs.push({
                     "id":fighter.id,
                     "url":fighter.bgm,
                     "rate":fighter.bgmRate
                     });
                  }
                  fighterName = fighter.name;
               }
               this._loadItems.push({
               "type":"fighter",
               "id":o.id,
               "runobj":o.runobj,
               "msg":"正在加载角色：" + fighterName
               });
            }
            i++;
         }
         i = 0;
         while(i < assisters.length)
         {
            o = assisters[i];
            if(Boolean(o.id))
            {
               fighter = FighterModel.I.getFighter(o.id);
               fighterName = fighter ? fighter.name : o.id;
               this._loadItems.push({
               "type":"assister",
               "id":o.id,
               "runobj":o.runobj,
               "msg":"正在加载辅助角色：" + fighterName
               });
            }
            i++;
         }
         map = MapModel.I.getMap(GameData.I.selectMap);
         mapName = map ? map.name : GameData.I.selectMap;
         this._loadItems.push({
         "type":"map",
         "id":GameData.I.selectMap,
         "runobj":null,
         "msg":"正在加载场景：" + mapName
         });
         this._loadCount = this._loadItems.length;
         this._loadDone = 0;
         // AS3 批量加载：角色/辅助/场景互不依赖，一次按并发度同时挂起多路，替代原先的逐个串行队列
         setTimeout(this.startLoad,1000);
      }
      
      private function render() : void
      {
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
      }
      
      private function startLoad() : void
      {
         if(this._destoryed) return;
         var batch:AssetBatchLoader = new AssetBatchLoader();
         batch.load(this._loadItems,this.loadOneItem,this.onLoadItemsDone,this.loadProcess,SWF_BATCH_CONCURRENCY);
      }
      
      private function loadOneItem(param1:Object, param2:Function, param3:Function, param4:Function) : void
      {
         var item:Object = param1;
         var onDone:Function = param2;
         var onFail:Function = param3;
         var onProgress:Function = param4;
         this.updateMsg(item.msg);
         // 结算包装：计数 + 文案；单项失败同样计数，避免失败项卡死整批（原实现会停在队列里）
         var itemDone:Function = function() : void
         {
            _loadDone++;
            updateMsg();
            onDone();
         };
         var itemFail:Function = function(msg:String = null) : void
         {
            _loadDone++;
            updateMsg();
            if(msg != null) loadFail(msg);
            onFail();
         };
         if(item.type == "fighter")
         {
            GameLoader.loadFighter(item.id,function(param1:FighterMain, param2:Object):void
            {
               cacheFighter(param1,param2.id,param1.data.id);
               itemDone();
            },itemFail,onProgress,item.runobj);
         }
         else if(item.type == "assister")
         {
            GameLoader.loadAssister(item.id,function(param1:Assister, param2:Object):void
            {
               GameCtrl.I.gameRunData[param2.group][param2.id] = param1;
               itemDone();
            },itemFail,onProgress,item.runobj);
         }
         else
         {
            GameLoader.loadMap(item.id,function(param1:MapMain):void
            {
               if(Boolean(param1.data) && Boolean(param1.data.bgm))
               {
                  _mapBgm = {
                  "id":"map",
                  "url":param1.data.bgm,
                  "rate":1
                  };
               }
               GameCtrl.I.gameRunData.map = param1;
               itemDone();
            },itemFail,onProgress,item.runobj);
         }
      }
      
      private function onLoadItemsDone() : void
      {
         if(this._destoryed) return;
         if(this._mapBgm != null)
         {
            this._fightBGMs.push(this._mapBgm);
         }
         Debugger.log("[LoadingState] onLoadItemsDone fightBGMs=" + this._fightBGMs.length + " mapBgm=" + (this._mapBgm != null ? this._mapBgm.url : "null"));
         if(this._fightBGMs.length > 0)
         {
            this._loadCount = this._loadCount + 1;
            this.updateMsg("正在加载BGM");
            SoundCtrl.I.loadFightBGM(this._fightBGMs,this.onBgmDone,this.loadFail,this.loadProcess);
            return;
         }
         Debugger.log("[LoadingState] no fightBGM, loadFin directly");
         this.loadFin();
      }
      
      private function onBgmDone() : void
      {
         if(this._destoryed) return;
         Debugger.log("[LoadingState] onBgmDone");
         this._loadDone++;
         this.updateMsg();
         this.loadFin();
      }
      
      private function loadFin() : void
      {
         Debugger.log("[LoadingState] loadFin");
         var delayCall:* = undefined;
         delayCall = function():void
         {
            _loadFin = true;
            finish();
         };
         TweenLite.to(this._sltUI,1,{
            "y":80,
            "onComplete":function():void
            {
               setTimeout(delayCall,2000);
            }
         });
      }
      
      private function finish() : void
      {
         if(this._destoryed)
         {
            return;
         }
         if(!this._selectIndexUI.isFinish() || !this._loadFin)
         {
            Debugger.log("[LoadingState] finish NOT ready: isFinish=" + this._selectIndexUI.isFinish() + " loadFin=" + this._loadFin);
            return;
         }
         if(!AUTO_START_GAME)
         {
            return;
         }
         if(this._gameFinished)
         {
            return;
         }
         this._gameFinished = true;
         var _loc1_:Array = this._selectIndexUI.getP1Order();
         var _loc2_:Array = this._selectIndexUI.getP2Order();
         this.gotoGame(_loc1_,_loc2_);
      }
      
      public function gotoGame(param1:Array, param2:Array) : void
      {
         Debugger.log("[LoadingState] gotoGame enter");
         var _loc3_:GameRunFighterGroup = GameCtrl.I.gameRunData.p1FighterGroup;
         var _loc4_:GameRunFighterGroup = GameCtrl.I.gameRunData.p2FighterGroup;
         _loc3_.fighter1 = this.getCacheFighter("p1",param1[0]);
         _loc3_.fighter2 = this.getCacheFighter("p1",param1[1]);
         _loc3_.fighter3 = this.getCacheFighter("p1",param1[2]);
         _loc4_.fighter1 = this.getCacheFighter("p2",param2[0]);
         _loc4_.fighter2 = this.getCacheFighter("p2",param2[1]);
         _loc4_.fighter3 = this.getCacheFighter("p2",param2[2]);
         _loc3_.currentFighter = _loc3_.fighter1;
         _loc4_.currentFighter = _loc4_.fighter1;
         MainGame.I.stage.dispatchEvent(new DataEvent("5d_message",false,false,JSON.stringify(["loading_finish"])));
         StateCtrl.I.transIn(MainGame.I.goGame,false);
      }
      
      private function getCacheFighter(param1:String, param2:String) : FighterMain
      {
         if(param2 == null)
         {
            return null;
         }
         var _loc3_:String = param1 + "_" + param2;
         var _loc4_:FighterMain = this._loadedFighterCache[_loc3_];
         if(!_loc4_)
         {
            throw new Error("未找到fighter:" + _loc3_);
         }
         return _loc4_;
      }
      
      private function cacheFighter(param1:FighterMain, param2:String, param3:String) : void
      {
         var _loc4_:String = param2 + "_" + param3;
         this._loadedFighterCache[_loc4_] = param1;
      }
      
      private function loadFail(param1:String) : void
      {
         Debugger.errorMsg(param1);
      }
      
      private function loadProcess(param1:Number) : void
      {
         // 防御：进战 BGM 批次中 _sltUI.bar.bar 可能为 undefined，
         // 直接访问 scaleX 会抛 Error #1010，使 AssetBatchLoader.onDone 在
         // settle 之后、checkFinish 之前中断，整批永远不完成，卡加载。
         if(Boolean(this._sltUI) && Boolean(this._sltUI.bar) && Boolean(this._sltUI.bar.bar))
         {
            this._sltUI.bar.bar.scaleX = param1;
         }
      }
      
      private function updateMsg(param1:String = null) : void
      {
         if(Boolean(param1))
         {
            this._curMsg = param1;
         }
         this._sltUI.bar.txt.text = this._curMsg + "(" + this._loadDone + "/" + this._loadCount + ")";
      }
      
      public function afterBuild() : void
      {
         StateCtrl.I.transOut();
      }
      
      public function destory(param1:Function = null) : void
      {
         this._destoryed = true;
         if(Boolean(this._selectIndexUI))
         {
            this._selectIndexUI.destory();
            this._selectIndexUI = null;
         }
         SoundCtrl.I.BGM(null);
         this._loadedFighterCache = null;
         this._loadItems = null;
      this._fightBGMs = null;
         GameInputer.clearInput();
         GameRender.remove(this.render);
         GameUI.closeConfrim();
      }
   }
}

