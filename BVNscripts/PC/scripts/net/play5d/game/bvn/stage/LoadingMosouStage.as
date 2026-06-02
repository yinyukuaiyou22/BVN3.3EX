package net.play5d.game.bvn.stage
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.ctrl.GameRender;
   import net.play5d.game.bvn.ctrl.SoundCtrl;
   import net.play5d.game.bvn.ctrl.StateCtrl;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.ctrl.game_stage_loader.GameStageLoadCtrl;
   import net.play5d.game.bvn.ctrl.mosou_ctrls.MosouLogic;
   import net.play5d.game.bvn.data.FighterModel;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.MapModel;
   import net.play5d.game.bvn.data.mosou.MosouMissionVO;
   import net.play5d.game.bvn.data.mosou.MosouModel;
   import net.play5d.game.bvn.data.mosou.player.MosouFighterVO;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.kyo.stage.Istage;
   
   public class LoadingMosouStage implements Istage
   {
      
      private var _ui:MovieClip;
      
      private var _destoryed:Boolean;
      
      private var _sltUI:MovieClip;
      
      private var _gameFinished:Boolean;
      
      public function LoadingMosouStage()
      {
         super();
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function build() : void
      {
         var _loc1_:int = 0;
         GameEvent.dispatchEvent("MOSOU_LOADING_START");
         GameRender.add(render);
         GameInputer.focus();
         GameInputer.enabled = true;
         SoundCtrl.I.BGM(AssetManager.I.getSound("loading"));
         _ui = AssetManager.I.createObject("loading_fight_mc","assets/subswfs/loading.swf") as MovieClip;
         _sltUI = _ui.sltui as MovieClip;
         var _loc2_:Array = [];
         var _loc5_:Array = [];
         var _loc6_:Array = [];
         var _loc3_:MosouMissionVO = MosouModel.I.currentMission;
         _loc2_.push(_loc3_.map);
         var _loc7_:Vector.<MosouFighterVO> = GameData.I.mosouData.getFighterTeam();
         while(_loc1_ < _loc7_.length)
         {
            _loc5_.push(_loc7_[_loc1_].id);
            _loc1_++;
         }
         var _loc4_:Array = _loc3_.getAllEnemieIds();
         _loc5_ = _loc5_.concat(_loc4_);
         var _loc8_:Array = _loc3_.getBossIds();
         _loc6_.push(_loc3_.map,_loc5_[0],_loc8_);
         _loc6_.push("boss_naruto","boss_bleach");
         GameStageLoadCtrl.I.init(onLoadProcess,onLoadError);
         GameStageLoadCtrl.I.loadGame(_loc2_,_loc5_,null,_loc6_,onLoadFinish);
      }
      
      private function onLoadProcess(param1:String, param2:Number) : void
      {
         _sltUI.bar.txt.text = param1;
         _sltUI.bar.bar.scaleX = param2;
         GameEvent.dispatchEvent("MOSOU_LOADING",{
            "msg":param1,
            "process":param2
         });
      }
      
      private function onLoadError(param1:String) : void
      {
         Debugger.errorMsg(param1);
      }
      
      private function onLoadFinish() : void
      {
         if(_destoryed)
         {
            return;
         }
         if(_gameFinished)
         {
            return;
         }
         _gameFinished = true;
         if(GameUI.showingDialog())
         {
            GameUI.cancelConfrim();
         }
         initGameRunData();
         StateCtrl.I.transIn(MainGame.I.goMosouGame,false);
         GameEvent.dispatchEvent("MOSOU_LOADING_FINISH");
      }
      
      private function render() : void
      {
         if(_gameFinished)
         {
            return;
         }
         if(GameInputer.back(1))
         {
            if(GameUI.showingDialog())
            {
               GameUI.cancelConfrim();
            }
            else
            {
               GameUI.confrim(GetLangText("game_ui.confrim.musou_back.title"),GetLangText("game_ui.confrim.musou_back.message"),function():void
               {
                  MainGame.I.goWorldMap();
                  GameEvent.dispatchEvent("MOSOU_BACK_MAP");
               });
            }
         }
      }
      
      private function initGameRunData() : void
      {
         var _loc2_:MosouMissionVO = MosouModel.I.currentMission;
         GameCtrl.I.initMosouGame();
         GameCtrl.I.getMosouCtrl().gameRunData.koNum = 0;
         MosouLogic.I.clearHits();
         GameCtrl.I.getMosouCtrl().gameRunData.gameTimeMax = _loc2_.time * 30;
         GameCtrl.I.getMosouCtrl().gameRunData.gameTime = _loc2_.time * 30;
         var _loc1_:Vector.<MosouFighterVO> = GameData.I.mosouData.getFighterTeam();
         GameCtrl.I.gameRunData.p1FighterGroup.fighter1 = FighterModel.I.getFighter(_loc1_[0].id);
         GameCtrl.I.gameRunData.p1FighterGroup.fighter2 = FighterModel.I.getFighter(_loc1_[1].id);
         GameCtrl.I.gameRunData.p1FighterGroup.fighter3 = FighterModel.I.getFighter(_loc1_[2].id);
         GameCtrl.I.gameRunData.map = MapModel.I.getMap(_loc2_.map);
      }
      
      public function afterBuild() : void
      {
         StateCtrl.I.transOut();
      }
      
      public function destory(param1:Function = null) : void
      {
         _destoryed = true;
         SoundCtrl.I.BGM(null);
         GameInputer.clearInput();
         GameRender.remove(render);
         GameUI.closeConfrim();
      }
   }
}

