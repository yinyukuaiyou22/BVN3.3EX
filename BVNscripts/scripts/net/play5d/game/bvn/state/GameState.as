package net.play5d.game.bvn.state
{
   import flash.display.*;
   import flash.geom.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.ctrl.game_ctrls.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.interfaces.*;
   import net.play5d.game.bvn.map.MapMain;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.kyo.stage.*;
   
   public class GameState extends Sprite implements Istage
   {
      
      private var _gameLayer:Sprite = new Sprite();
      
      private var _playerLayer:Sprite = new Sprite();
      
      private var _gameSprites:Vector.<IGameSprite> = new Vector.<IGameSprite>();
      
      private var _map:MapMain;
      
      public var camera:GameCamera;
      
      private var _cameraFocus:Array;
      
      public var gameUI:GameUI;
      
      public function GameState()
      {
         super();
         this._gameLayer.mouseChildren = this._gameLayer.mouseEnabled = false;
      }
      
      public function get gameLayer() : Sprite
      {
         return this._gameLayer;
      }
      
      public function getMap() : MapMain
      {
         return this._map;
      }
      
      public function setVisibleByClass(param1:Class, param2:*) : void
      {
         var _loc5_:* = undefined;
         var _loc3_:String = null;
         var _loc4_:Class = null;
         for each(_loc5_ in this._gameSprites)
         {
            _loc3_ = getQualifiedClassName(_loc5_);
            _loc4_ = getDefinitionByName(_loc3_) as Class;
            if(_loc4_ == param1)
            {
               _loc5_.getDisplay().visible = param2;
            }
         }
      }
      
      public function get display() : DisplayObject
      {
         return this;
      }
      
      public function getGameSpriteGlobalPosition(param1:IGameSprite, param2:Number = 0, param3:Number = 0) : Point
      {
         var _loc4_:Number = this.camera.getZoom(true);
         var _loc5_:Rectangle = this.camera.getScreenRect(true);
         return new Point((-_loc5_.x + param1.x + param2) * _loc4_,(-_loc5_.y + param1.y + param3) * _loc4_);
      }
      
      public function getGameSprites() : Vector.<IGameSprite>
      {
         return this._gameSprites;
      }
      
      public function addGameSprite(param1:IGameSprite) : void
      {
         if(this._gameSprites.indexOf(param1) != -1)
         {
            return;
         }
         this._gameSprites.push(param1);
         this._playerLayer.addChild(param1.getDisplay());
         param1.setVolume(GameData.I.config.soundVolume);
      }
      
      public function addGameSpriteAt(param1:IGameSprite, param2:int) : void
      {
         if(this._gameSprites.indexOf(param1) != -1)
         {
            return;
         }
         this._gameSprites.push(param1);
         this._playerLayer.addChildAt(param1.getDisplay(),param2);
         param1.setVolume(GameData.I.config.soundVolume);
      }
      
      public function removeGameSprite(param1:IGameSprite) : void
      {
         var _loc2_:int = int(this._gameSprites.indexOf(param1));
         if(_loc2_ == -1)
         {
            return;
         }
         this._gameSprites.splice(_loc2_,1);
         try
         {
            this._playerLayer.removeChild(param1.getDisplay());
         }
         catch(e:Error)
         {
         }
      }
      
      public function build() : void
      {
         GameCtrl.I.initlize(this);
         EffectCtrl.I.initlize(this,this._playerLayer);
         this.gameUI = new GameUI();
      }
      
      public function initFight(param1:GameRunFighterGroup, param2:GameRunFighterGroup, param3:MapMain) : void
      {
         var _loc4_:Point = null;
         this._map = param3;
         this._map.gameState = this;
         if(Boolean(this._map.bgLayer))
         {
            addChild(this._map.bgLayer);
         }
         addChild(this._gameLayer);
         if(Boolean(this._map.mapLayer))
         {
            this._gameLayer.addChild(this._map.mapLayer);
         }
         this._gameLayer.addChild(this._playerLayer);
         if(Boolean(this._map.frontFixLayer))
         {
            this._gameLayer.addChild(this._map.frontFixLayer);
         }
         if(Boolean(this._map.frontLayer))
         {
            this._gameLayer.addChild(this._map.frontLayer);
         }
         this._cameraFocus = [];
         var _isDuo:Boolean = GameMode.isDuoMode() || GameMode.is1v2Mode();
         var _loc5_:FighterMain = param1.currentFighter;
         var _loc6_:FighterMain = param2.currentFighter;
         if(Boolean(_loc5_))
         {
            GameLogic.resetFighterHP(_loc5_);
            _loc5_.x = this._map.p1pos.x;
            _loc5_.y = this._map.p1pos.y;
            _loc5_.direct = 1;
            _loc5_.updatePosition();
            this._cameraFocus.push(_loc5_.getDisplay());
         }
         if(Boolean(_loc6_))
         {
            GameLogic.resetFighterHP(_loc6_);
            if(GameMode.isAcrade())
            {
               GameLogic.setMessionEnemyAttack(_loc6_);
            }
            _loc6_.x = this._map.p2pos.x;
            _loc6_.y = this._map.p2pos.y;
            _loc6_.direct = -1;
            _loc6_.updatePosition();
            this._cameraFocus.push(_loc6_.getDisplay());
         }
         // 2v2/1v2: 额外 fighter 也加入摄像机追踪
         if (_isDuo) {
            if (param1.fighter2 && param1.fighter2.isAlive) {
               this._cameraFocus.push(param1.fighter2.getDisplay());
            }
            if (param2.fighter2 && param2.fighter2.isAlive) {
               this._cameraFocus.push(param2.fighter2.getDisplay());
            }
         }
         if(Boolean(this._map.mapLayer))
         {
            _loc4_ = new Point(this._map.mapLayer.width,GameConfig.GAME_SIZE.y);
            this.initCamera();
            this.camera.focus(this._cameraFocus);
            this.gameUI.initFight(param1,param2);
            addChild(this.gameUI.getUIDisplay());
            return;
         }
         throw new Error("map is error! :: mapLayer is null!");
      }
      
      public function resetFight(param1:GameRunFighterGroup, param2:GameRunFighterGroup) : void
      {
         var _loc3_:FighterMain = param1.currentFighter;
         var _loc4_:FighterMain = param2.currentFighter;
         this._cameraFocus = [];
         if(Boolean(_loc3_))
         {
            GameLogic.resetFighterHP(_loc3_);
            _loc3_.x = this._map.p1pos.x;
            _loc3_.y = this._map.p1pos.y;
            _loc3_.direct = 1;
            _loc3_.idle();
            _loc3_.updatePosition();
            this._cameraFocus.push(_loc3_.getDisplay());
         }
         if(Boolean(_loc4_))
         {
            GameLogic.resetFighterHP(_loc4_);
            _loc4_.x = this._map.p2pos.x;
            _loc4_.y = this._map.p2pos.y;
            _loc4_.direct = -1;
            _loc4_.idle();
            _loc4_.updatePosition();
            this._cameraFocus.push(_loc4_.getDisplay());
         }
         this.gameUI.initFight(param1,param2);
         this.cameraResume();
      }
      
      public function cameraFocusOne(param1:DisplayObject) : void
      {
         this.camera.focus([param1]);
         this.camera.setZoom(3.5);
         this.camera.tweenSpd = 2.5 / GameConfig.SPEED_PLUS_DEFAULT;
      }
      
      public function cameraResume() : void
      {
         this.camera.focus(this._cameraFocus);
         this.camera.tweenSpd = 2.5 / GameConfig.SPEED_PLUS_DEFAULT;
      }
      
      private function initCamera() : void
      {
         if(Boolean(this.camera))
         {
            throw new Error("camera inited!");
         }
         var _loc1_:Point = this._map.getStageSize();
         this.camera = new GameCamera(this._gameLayer,GameConfig.GAME_SIZE,_loc1_,true);
         this.camera.focusX = true;
         this.camera.focusY = true;
         this.camera.offsetY = this._map.getMapBottomDistance();
         this.camera.setStageBounds(new Rectangle(0,-1000,_loc1_.x,_loc1_.y));
         this.camera.autoZoom = true;
         this.camera.autoZoomMin = 1;
         this.camera.autoZoomMax = 2.5;
         this.camera.tweenSpd = 2.5 / GameConfig.SPEED_PLUS_DEFAULT;
         var _loc2_:Number = 2;
         var _loc3_:Number = _loc1_.x / 2 * _loc2_ - 350;
         var _loc4_:Number = this._map.bottom - 200;
         this.camera.setZoom(_loc2_);
         this.camera.setX(-_loc3_);
         this.camera.setY(-_loc4_);
         this.camera.updateNow();
      }
      
      public function render() : void
      {
         var _loc1_:Rectangle = null;
         if(Boolean(this.camera))
         {
            this.camera.render();
         }
         if(Boolean(this.gameUI))
         {
            this.gameUI.render();
         }
         if(Boolean(this._map) && Boolean(this.camera))
         {
            _loc1_ = this.camera.getScreenRect(true);
            this._map.render(-_loc1_.x,-_loc1_.y,this.camera.getZoom(true));
         }
      }
      
      public function drawGameRect(param1:Rectangle, param2:uint = 16711680, param3:Number = 0.5, param4:Boolean = false) : void
      {
         if(param4)
         {
            this._gameLayer.graphics.clear();
         }
         this._gameLayer.graphics.beginFill(param2,param3);
         this._gameLayer.graphics.drawRect(param1.x,param1.y,param1.width,param1.height);
         this._gameLayer.graphics.endFill();
      }
      
      public function clearDrawGameRect() : void
      {
         this._gameLayer.graphics.clear();
      }
      
      public function afterBuild() : void
      {
      }
      
      public function destory(param1:Function = null) : void
      {
         this.removeChildren();
         if(Boolean(this._gameSprites))
         {
            while(this._gameSprites.length > 0)
            {
               this.removeGameSprite(this._gameSprites.shift());
            }
            this._gameSprites = null;
         }
         if(Boolean(this._playerLayer))
         {
            this._playerLayer.removeChildren();
            this._playerLayer = null;
         }
         if(Boolean(this._gameLayer))
         {
            this._gameLayer.removeChildren();
            this._gameLayer = null;
         }
         if(Boolean(this.camera))
         {
            this.camera = null;
         }
         if(Boolean(this.gameUI))
         {
            this.gameUI.destory();
            this.gameUI = null;
         }
         EffectCtrl.I.destory();
         GameCtrl.I.destory();
         if(Boolean(this._map))
         {
            this._map.destory();
            this._map = null;
         }
      }
   }
}

