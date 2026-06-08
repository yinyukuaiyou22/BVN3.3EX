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
      
      private var _loadQueue:Array;
      
      private var _curMsg:String;
      
      private var _loadCount:int;
      
      private var _destoryed:Boolean;
      
      private var _loadFin:Boolean;
      
      private var _selectIndexUI:SelectIndexUI;
      
      private var _loadedFighterCache:Object = {};
      
      private var _currentLoadBack:Function;
      
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
         this._loadQueue = [];
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
         fightBGMs = [];
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
                     fightBGMs.push({
                        "id":fighter.id,
                        "url":fighter.bgm,
                        "rate":fighter.bgmRate
                     });
                  }
                  fighterName = fighter.name;
               }
               this._loadQueue.push({
                  "msg":"正在加载角色：" + fighterName,
                  "func":GameLoader.loadFighter,
                  "params":[o.id,function(param1:FighterMain, param2:Object):void
                  {
                     cacheFighter(param1,param2.id,param1.data.id);
                     loadNext();
                  },this.loadFail,this.loadProcess,o.runobj]
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
               this._loadQueue.push({
                  "msg":"正在加载辅助角色：" + fighterName,
                  "func":GameLoader.loadAssister,
                  "params":[o.id,function(param1:Assister, param2:Object):void
                  {
                     GameCtrl.I.gameRunData[param2.group][param2.id] = param1;
                     loadNext();
                  },this.loadFail,this.loadProcess,o.runobj]
               });
            }
            i++;
         }
         map = MapModel.I.getMap(GameData.I.selectMap);
         mapName = map ? map.name : GameData.I.selectMap;
         this._loadQueue.push({
            "msg":"正在加载场景：" + mapName,
            "func":GameLoader.loadMap,
            "params":[GameData.I.selectMap,function(param1:MapMain):void
            {
               if(Boolean(param1.data) && Boolean(param1.data.bgm))
               {
                  fightBGMs.push({
                     "id":"map",
                     "url":param1.data.bgm,
                     "rate":1
                  });
               }
               GameCtrl.I.gameRunData.map = param1;
               loadNext();
            },this.loadFail]
         });
         if(fightBGMs.length > 0)
         {
            this._loadQueue.push({
               "msg":"正在加载BGM",
               "func":SoundCtrl.I.loadFightBGM,
               "params":[fightBGMs,this.loadNext,this.loadFail,this.loadProcess]
            });
         }
         this._loadCount = this._loadQueue.length;
         setTimeout(this.loadNext,1000);
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
      
      private function loadNext() : void
      {
         if(this._loadQueue.length < 1)
         {
            this.loadFin();
            return;
         }
         var _loc1_:Object = this._loadQueue.shift();
         this.updateMsg(_loc1_.msg);
         this._currentLoadBack = _loc1_.back;
         _loc1_.func.apply(null,_loc1_.params);
      }
      
      private function loadFighterComplete(param1:FighterMain) : void
      {
         if(Boolean(this._currentLoadBack))
         {
            this._currentLoadBack(param1);
            this._currentLoadBack = null;
         }
         this.loadNext();
      }
      
      private function loadFin() : void
      {
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
         this._sltUI.bar.bar.scaleX = param1;
      }
      
      private function updateMsg(param1:String = null) : void
      {
         if(Boolean(param1))
         {
            this._curMsg = param1;
         }
         var _loc2_:int = this._loadCount - this._loadQueue.length;
         this._sltUI.bar.txt.text = this._curMsg + "(" + _loc2_ + "/" + this._loadCount + ")";
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
         this._loadQueue = null;
         GameInputer.clearInput();
         GameRender.remove(this.render);
         GameUI.closeConfrim();
      }
   }
}

