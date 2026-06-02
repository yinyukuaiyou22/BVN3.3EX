package net.play5d.game.bvn.stage
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.media.SoundMixer;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import nagisa.filters.FilterManager;
   import nagisa.util.DisplayUtil;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.ctrl.EffectCtrl;
   import net.play5d.game.bvn.ctrl.GameLogic;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.FighterVO;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.data.GameRunFighterGroup;
   import net.play5d.game.bvn.events.GameEvent;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.ui.GameUI;
   import net.play5d.kyo.stage.Istage;
   import net.play5d.patchouli.utils.ClassUtil;
   
   public class GameStage extends Sprite implements Istage
   {
      
      private var _gameLayer:Sprite = new Sprite();
      
      private var _playerLayer:Sprite = new Sprite();
      
      private var _gameSprites:Vector.<IGameSprite> = new Vector.<IGameSprite>();
      
      private var _map:MapMain;
      
      public var camera:GameCamera;
      
      private var _cameraFocus:Array;
      
      public var gameUI:GameUI;
      
      private var _filterLayer:DisplayObjectContainer = this;
      
      private var _filterManager:FilterManager = new FilterManager(_filterLayer);
      
      public function GameStage()
      {
         super();
         _gameLayer.mouseEnabled = false;
         _gameLayer.mouseChildren = false;
      }
      
      public function get filterManager() : FilterManager
      {
         return _filterManager;
      }
      
      public function get gameLayer() : Sprite
      {
         return _gameLayer;
      }
      
      public function get playerLayer() : Sprite
      {
         return _playerLayer;
      }
      
      public function getMap() : MapMain
      {
         return _map;
      }
      
      public function toLocalPosition(param1:DisplayObject = null, param2:Point = null, param3:Number = 0, param4:Number = 0) : Point
      {
         if(!param1)
         {
            param1 = _gameLayer;
         }
         param2 ||= new Point();
         var _loc5_:Point = DisplayUtil.transformPosition(param1,this,param2);
         _loc5_.x = _loc5_.x + param3;
         _loc5_.y += param4;
         return _loc5_;
      }
      
      public function setVisibleByClass(param1:Class, param2:*) : void
      {
         var _loc4_:Class = null;
         var _loc5_:String = null;
         var _loc3_:* = null;
         for each(var _loc6_ in _gameSprites)
         {
            _loc5_ = getQualifiedClassName(_loc6_);
            _loc4_ = getDefinitionByName(_loc5_) as Class;
            if(_loc4_ == param1)
            {
               _loc6_.getDisplay().visible = param2;
            }
         }
      }
      
      public function getFighterByData(param1:FighterVO) : FighterMain
      {
         for each(var _loc2_ in _gameSprites)
         {
            if(_loc2_ is FighterMain && (_loc2_ as FighterMain).data == param1)
            {
               return _loc2_ as FighterMain;
            }
         }
         return null;
      }
      
      public function get display() : DisplayObject
      {
         return this;
      }
      
      public function getGameSpriteGlobalPosition(param1:IGameSprite, param2:Number = 0, param3:Number = 0) : Point
      {
         var _loc5_:Number = camera.getZoom(true);
         var _loc4_:Rectangle = camera.getScreenRect(true);
         return new Point((-_loc4_.x + param1.x + param2) * _loc5_,(-_loc4_.y + param1.y + param3) * _loc5_);
      }
      
      public function getGameSprites() : Vector.<IGameSprite>
      {
         return _gameSprites;
      }
      
      public function addGameSprite(param1:IGameSprite) : void
      {
         param1.setActive(true);
         if(_gameSprites.indexOf(param1) != -1)
         {
            return;
         }
         _gameSprites.push(param1);
         _playerLayer.addChild(param1.getDisplay());
         param1.setSpeedRate(GameConfig.SPEED_PLUS);
         param1.setVolume(GameData.I.config.soundVolume);
      }
      
      public function addGameSpriteAt(param1:IGameSprite, param2:int) : void
      {
         param1.setActive(true);
         if(_gameSprites.indexOf(param1) != -1)
         {
            return;
         }
         _gameSprites.push(param1);
         _playerLayer.addChildAt(param1.getDisplay(),param2);
         param1.setVolume(GameData.I.config.soundVolume);
      }
      
      public function removeGameSprite(param1:IGameSprite, param2:Boolean = false) : void
      {
         var _loc3_:* = undefined;
         if(param2)
         {
            _loc3_ = new Vector.<DisplayObject>();
            _loc3_.push(param1.getDisplay());
            if(param1 is FighterMain)
            {
               _loc3_.push((param1 as FighterMain).getMC().mc);
            }
            removeGameSpriteEventListener(param1,_loc3_);
            _loc3_ = null;
            param1.destory(true);
         }
         else
         {
            param1.setActive(false);
         }
         var _loc4_:int = _gameSprites.indexOf(param1);
         if(_loc4_ == -1)
         {
            return;
         }
         _gameSprites.splice(_loc4_,1);
         try
         {
            _playerLayer.removeChild(param1.getDisplay());
         }
         catch(e:Error)
         {
         }
      }
      
      private function removeGameSpriteEventListener(param1:IGameSprite, param2:Vector.<DisplayObject>) : void
      {
         if(param2 == null || param2.length < 1)
         {
            return;
         }
         for each(var _loc3_ in param2)
         {
            ClassUtil.removeAllEventListener(_loc3_);
         }
      }
      
      public function build() : void
      {
         GameCtrl.I.initlize(this);
         EffectCtrl.I.initlize(this,_playerLayer);
         gameUI = new GameUI();
         GameEvent.dispatchEvent("FIGHT_START");
      }
      
      public function initFight(param1:GameRunFighterGroup, param2:GameRunFighterGroup, param3:MapMain) : void
      {
         var _loc6_:Point = null;
         _map = param3;
         _map.gameState = this;
         if(_map.bgLayer)
         {
            addChild(_map.bgLayer);
         }
         addChild(_gameLayer);
         if(_map.mapLayer)
         {
            _gameLayer.addChild(_map.mapLayer);
         }
         _gameLayer.addChild(_playerLayer);
         if(_map.frontFixLayer)
         {
            _gameLayer.addChild(_map.frontFixLayer);
         }
         if(_map.frontLayer)
         {
            _gameLayer.addChild(_map.frontLayer);
         }
         _cameraFocus = [];
         var _loc4_:FighterMain = param1.currentFighter;
         var _loc5_:FighterMain = param2.currentFighter;
         if(_loc4_)
         {
            GameLogic.resetFighterHP(_loc4_);
            _loc4_.x = _map.p1pos.x;
            _loc4_.y = _map.p1pos.y;
            _loc4_.direct = 1;
            _loc4_.updatePosition();
            _cameraFocus.push(_loc4_.getDisplay());
         }
         if(_loc5_)
         {
            GameLogic.resetFighterHP(_loc5_);
            if(GameMode.isAcrade())
            {
               GameLogic.setMessionEnemyAttack(_loc5_);
            }
            _loc5_.x = _map.p2pos.x;
            _loc5_.y = _map.p2pos.y;
            _loc5_.direct = -1;
            _loc5_.updatePosition();
            _cameraFocus.push(_loc5_.getDisplay());
         }
         setP2Color(_loc4_,_loc5_);
         if(_map.mapLayer)
         {
            _loc6_ = new Point(_map.mapLayer.width,GameConfig.GAME_SIZE.y);
            initCamera();
            camera.focus(_cameraFocus);
            gameUI.initFight(param1,param2);
            addChild(gameUI.getUIDisplay());
            return;
         }
         throw new Error("map is error! :: mapLayer is null!");
      }
      
      private function setP2Color(param1:FighterMain, param2:FighterMain) : void
      {
         var _loc3_:ColorTransform = null;
         if(checkSameFighter(param1,param2))
         {
            _loc3_ = new ColorTransform();
            if(param1.data.id.indexOf("naruto") > -1)
            {
               _loc3_.blueOffset = 80;
            }
            _loc3_.greenOffset = -85;
            SetP2SpColor(param2,_loc3_);
         }
         else
         {
            param2.colorTransform = null;
         }
      }
      
      private function checkSameFighter(param1:FighterMain, param2:FighterMain) : Boolean
      {
         var _loc4_:String = param1.data.id;
         var _loc3_:String = param2.data.id;
         if(_loc4_ == _loc3_)
         {
            return true;
         }
         if(_loc4_ + "_old" == _loc3_)
         {
            return true;
         }
         if(_loc4_ == _loc3_ + "_old")
         {
            return true;
         }
         return false;
      }
      
      public function resetFight(param1:GameRunFighterGroup, param2:GameRunFighterGroup) : void
      {
         var _loc3_:FighterMain = param1.currentFighter;
         var _loc4_:FighterMain = param2.currentFighter;
         _cameraFocus = [];
         if(_loc3_)
         {
            GameLogic.resetFighterHP(_loc3_);
            _loc3_.x = _map.p1pos.x;
            _loc3_.y = _map.p1pos.y;
            _loc3_.direct = 1;
            _loc3_.idle();
            _loc3_.updatePosition();
            _loc3_.fzqi = 100;
            if(GameCtrl.I.gameRunData.p1FighterGroup.currentAssister)
            {
               GameCtrl.I.gameRunData.p1FighterGroup.currentAssister.getCtrler().enabled = true;
               GameCtrl.I.gameRunData.p1FighterGroup.currentAssister.getCtrler().useFzqi = true;
            }
            _cameraFocus.push(_loc3_.getDisplay());
         }
         if(_loc4_)
         {
            GameLogic.resetFighterHP(_loc4_);
            _loc4_.x = _map.p2pos.x;
            _loc4_.y = _map.p2pos.y;
            _loc4_.direct = -1;
            _loc4_.idle();
            _loc4_.updatePosition();
            _loc4_.fzqi = 100;
            if(GameCtrl.I.gameRunData.p2FighterGroup.currentAssister)
            {
               GameCtrl.I.gameRunData.p2FighterGroup.currentAssister.getCtrler().enabled = true;
               GameCtrl.I.gameRunData.p2FighterGroup.currentAssister.getCtrler().useFzqi = true;
            }
            _cameraFocus.push(_loc4_.getDisplay());
         }
         setP2Color(_loc3_,_loc4_);
         gameUI.initFight(param1,param2);
         cameraResume();
      }
      
      public function cameraFocusOne(param1:DisplayObject) : void
      {
         camera.focus([param1]);
         camera.setZoom(3.5);
         camera.tweenSpd = 2.5 / GameConfig.SPEED_PLUS_DEFAULT;
      }
      
      public function updateCameraFocus(param1:Array) : void
      {
         _cameraFocus = param1;
         camera.focus(param1);
         camera.setZoom(2);
         camera.tweenSpd = 2.5 / GameConfig.SPEED_PLUS_DEFAULT;
      }
      
      public function cameraResume() : void
      {
         camera.focus(_cameraFocus);
         if(_cameraFocus.length < 2)
         {
            camera.setZoom(2);
         }
         camera.tweenSpd = 2.5 / GameConfig.SPEED_PLUS_DEFAULT;
      }
      
      private function initCamera() : void
      {
         if(camera)
         {
            throw new Error("camera inited!");
         }
         var _loc3_:Point = _map.getStageSize();
         camera = new GameCamera(_gameLayer,GameConfig.GAME_SIZE,_loc3_,true);
         camera.focusX = true;
         camera.focusY = true;
         camera.offsetY = _map.getMapBottomDistance();
         camera.setStageBounds(new Rectangle(0,-1000,_loc3_.x,_loc3_.y));
         camera.autoZoom = true;
         camera.autoZoomMin = int(1 / GameData.I.config.cameraZoomRate * 100) / 100;
         camera.autoZoomMax = 2.5;
         camera.tweenSpd = 2.5 / GameConfig.SPEED_PLUS_DEFAULT;
         var _loc2_:Number = _loc3_.x - 350;
         var _loc1_:Number = _map.bottom - 200;
         camera.setZoom(2);
         camera.setX(-_loc2_);
         camera.setY(-_loc1_);
         camera.updateNow();
      }
      
      public function render() : void
      {
         var _loc1_:Rectangle = null;
         if(camera)
         {
            camera.render();
         }
         if(gameUI)
         {
            gameUI.render();
         }
         if(_map && camera)
         {
            _loc1_ = camera.getScreenRect(true);
            _map.render(-_loc1_.x,-_loc1_.y,camera.getZoom(true));
         }
         if(_filterManager)
         {
            _filterManager.scaleX = _filterManager.scaleY = camera.getZoom(true);
            _filterManager.render();
         }
      }
      
      public function drawGameRect(param1:Rectangle, param2:uint = 16711680, param3:Number = 0.5, param4:Boolean = false) : void
      {
         if(param4)
         {
            _gameLayer.graphics.clear();
         }
         _gameLayer.graphics.beginFill(param2,param3);
         _gameLayer.graphics.drawRect(param1.x,param1.y,param1.width,param1.height);
         _gameLayer.graphics.endFill();
      }
      
      public function clearDrawGameRect() : void
      {
         _gameLayer.graphics.clear();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         SoundMixer.stopAll();
         this.removeChildren();
         if(_gameSprites)
         {
            while(_gameSprites.length > 0)
            {
               removeGameSprite(_gameSprites.shift(),true);
            }
            _gameSprites = null;
         }
         if(_playerLayer)
         {
            _playerLayer.removeChildren();
            _playerLayer = null;
         }
         if(_gameLayer)
         {
            _gameLayer.removeChildren();
            _gameLayer = null;
         }
         if(camera)
         {
            camera = null;
         }
         if(gameUI)
         {
            gameUI.destory();
            gameUI = null;
         }
         EffectCtrl.I.destory();
         GameCtrl.I.destory();
         if(_map)
         {
            _map.destory();
            _map = null;
         }
      }
      
      public function initMosouFight(param1:GameRunFighterGroup, param2:MapMain) : void
      {
         var _loc3_:Point = null;
         _map = param2;
         _map.gameState = this;
         if(_map.bgLayer)
         {
            addChild(_map.bgLayer);
         }
         addChild(_gameLayer);
         if(_map.mapLayer)
         {
            _gameLayer.addChild(_map.mapLayer);
         }
         _gameLayer.addChild(_playerLayer);
         if(_map.frontFixLayer)
         {
            _gameLayer.addChild(_map.frontFixLayer);
         }
         if(_map.frontLayer)
         {
            _gameLayer.addChild(_map.frontLayer);
         }
         _cameraFocus = [];
         var _loc4_:FighterMain = param1.currentFighter;
         if(_loc4_)
         {
            _loc4_.x = _map.p1pos.x;
            _loc4_.y = _map.p1pos.y;
            _loc4_.direct = 1;
            _loc4_.updatePosition();
            _cameraFocus.push(_loc4_.getDisplay());
         }
         if(_map.mapLayer)
         {
            _loc3_ = new Point(_map.mapLayer.width,GameConfig.GAME_SIZE.y);
            initCamera();
            camera.focus(_cameraFocus);
            gameUI.initMission(param1);
            addChild(gameUI.getUIDisplay());
            return;
         }
         throw new Error("地图错误::mapLayer为空！");
      }
   }
}

