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
   import net.play5d.game.bvn.data.AssisterModel;
   import net.play5d.game.bvn.data.FighterModel;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameRunFighterGroup;
   import net.play5d.game.bvn.data.MapModel;
   import net.play5d.game.bvn.data.SelectVO;
   import net.play5d.game.bvn.debug.Debugger;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.input.GameInputer;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.game.bvn.ui.select.SelectIndexUI;
   import net.play5d.kyo.stage.Istage;
   
   public class LoadingStage implements Istage
   {
      
      public static var AUTO_START_GAME:Boolean = true;
      
      private var _ui:MovieClip;
      
      private var _sltUI:MovieClip;
      
      private var _destoryed:Boolean;
      
      private var _loadFin:Boolean;
      
      private var _selectIndexUI:SelectIndexUI;
      
      private var _gameFinished:Boolean;
      
      private var _delayId:uint;
      
      public function LoadingStage()
      {
         super();
      }
      
      public static function gotoGame(param1:Array, param2:Array) : void
      {
         var _loc3_:GameRunFighterGroup = GameCtrl.I.gameRunData.p1FighterGroup;
         var _loc4_:GameRunFighterGroup = GameCtrl.I.gameRunData.p2FighterGroup;
         _loc3_.fighter1 = FighterModel.I.getFighter(param1[0],true);
         _loc3_.fighter2 = FighterModel.I.getFighter(param1[1],true);
         _loc3_.fighter3 = FighterModel.I.getFighter(param1[2],true);
         _loc3_.assister = AssisterModel.I.getAssister(GameData.I.p1Select.fuzhu,true);
         _loc4_.fighter1 = FighterModel.I.getFighter(param2[0],true);
         _loc4_.fighter2 = FighterModel.I.getFighter(param2[1],true);
         _loc4_.fighter3 = FighterModel.I.getFighter(param2[2],true);
         _loc4_.assister = AssisterModel.I.getAssister(GameData.I.p2Select.fuzhu,true);
         GameCtrl.I.gameRunData.map = MapModel.I.getMap(GameData.I.selectMap);
         GameEvent.dispatchEvent("FIGHT_LOADING_FINISH");
         StateCtrl.I.transIn(MainGame.I.goGame,false);
      }
      
      public function get display() : DisplayObject
      {
         return _ui;
      }
      
      public function p1SelectFinish() : Boolean
      {
         return _selectIndexUI.p1Finish();
      }
      
      public function p2SelectFinish() : Boolean
      {
         return _selectIndexUI.p2Finish();
      }
      
      public function selectFinish() : Boolean
      {
         return _selectIndexUI.isFinish();
      }
      
      public function getSort() : Array
      {
         return [_selectIndexUI.getP1Order(),_selectIndexUI.getP2Order()];
      }
      
      public function setOrder(param1:int, param2:Array) : void
      {
         if(param1 == 1)
         {
            _selectIndexUI.setP1Order(param2);
         }
         if(param1 == 2)
         {
            _selectIndexUI.setP2Order(param2);
         }
      }
      
      public function build() : void
      {
         GameEvent.dispatchEvent("FIGHT_LOADING_START");
         GameRender.add(render);
         GameInputer.focus();
         GameInputer.enabled = true;
         SoundCtrl.I.BGM(AssetManager.I.getSound("loading"));
         _ui = AssetManager.I.createObject("loading_fight_mc","assets/subswfs/loading.swf") as MovieClip;
         if(_ui != null && _ui.sltui != null)
         {
            _sltUI = _ui.sltui as MovieClip;
         }
         _selectIndexUI = new SelectIndexUI();
         _selectIndexUI.onFinish = finish;
         _sltUI.addChild(_selectIndexUI);
         var _loc6_:Array = [];
         var _loc3_:Array = [];
         var _loc5_:Array = [];
         var _loc4_:Array = [];
         _loc6_.push(GameData.I.selectMap);
         var _loc2_:SelectVO = GameData.I.p1Select;
         _loc3_.push(_loc2_.fighter1,_loc2_.fighter2,_loc2_.fighter3);
         var _loc1_:SelectVO = GameData.I.p2Select;
         _loc3_.push(_loc1_.fighter1,_loc1_.fighter2,_loc1_.fighter3);
         _loc5_.push(_loc2_.fuzhu,_loc1_.fuzhu);
         _loc4_ = _loc3_.concat([GameData.I.selectMap]);
         GameStageLoadCtrl.I.init(onLoadProcess,onLoadError);
         GameStageLoadCtrl.I.loadGame(_loc6_,_loc3_,_loc5_,_loc4_,onLoadFinish);
         GameEvent.dispatchEvent("FIGHT_LOADING");
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
               GameUI.confrim(GetLangText("game_ui.confrim.back_title.title"),GetLangText("game_ui.confrim.back_title.message"),MainGame.I.goMenu);
            }
         }
         if(!GameUI.showingDialog() && GameInputer.jump("P1",1))
         {
            GameUI.confrim(GetLangText("game_ui.confrim.back_select.title"),GetLangText("game_ui.confrim.back_select.message"),MainGame.I.goSelect);
         }
      }
      
      private function onLoadProcess(param1:String, param2:Number) : void
      {
         _sltUI.bar.txt.text = param1;
         _sltUI.bar.bar.scaleX = param2;
      }
      
      private function onLoadError(param1:String) : void
      {
         Debugger.errorMsg(param1);
      }
      
      private function onLoadFinish() : void
      {
         _loadFin = true;
         finish();
      }
      
      private function finish() : void
      {
         if(_destoryed)
         {
            return;
         }
         if(!_selectIndexUI.isFinish() || !_loadFin)
         {
            return;
         }
         if(!AUTO_START_GAME)
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
         var _loc1_:Array = _selectIndexUI.getP1Order();
         var _loc2_:Array = _selectIndexUI.getP2Order();
         gotoGame(_loc1_,_loc2_);
      }
      
      public function afterBuild() : void
      {
         StateCtrl.I.transOut();
      }
      
      public function destory(param1:Function = null) : void
      {
         _destoryed = true;
         if(_selectIndexUI)
         {
            _selectIndexUI.destory();
            _selectIndexUI = null;
         }
         SoundCtrl.I.BGM(null);
         GameInputer.clearInput();
         GameRender.remove(render);
         GameUI.closeConfrim();
      }
   }
}

