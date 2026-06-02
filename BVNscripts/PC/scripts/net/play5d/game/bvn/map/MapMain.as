package net.play5d.game.bvn.map
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.MapVO;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.stage.GameStage;
   
   public class MapMain
   {
      
      public var mapLayer:MapLayer;
      
      public var frontLayer:MapLayer;
      
      public var frontFixLayer:MapLayer;
      
      public var bgLayer:MapLayer;
      
      public var p1pos:Point;
      
      public var p2pos:Point;
      
      public var left:Number = 0;
      
      public var right:Number = 0;
      
      public var bottom:Number = 0;
      
      public var playerBottom:Number = 0;
      
      public var mapMc:Sprite;
      
      public var data:MapVO;
      
      public var gameState:GameStage;
      
      private var _defaultFrontPos:Point;
      
      private var _smoothing:Point = new Point();
      
      private var _floors:Array;
      
      private var _colorTransform:ColorTransform = new ColorTransform();
      
      public function MapMain(param1:Sprite)
      {
         super();
         mapMc = param1;
      }
      
      public function destory() : void
      {
         if(mapMc)
         {
            try
            {
               mapMc.stopAllMovieClips();
               mapMc.removeChildren();
            }
            catch(e:Error)
            {
            }
            mapMc = null;
         }
         if(mapLayer)
         {
            mapLayer.destory();
            mapLayer = null;
         }
         if(frontLayer)
         {
            frontLayer.destory();
            frontLayer = null;
         }
         if(frontFixLayer)
         {
            frontFixLayer.destory();
            frontFixLayer = null;
         }
         if(bgLayer)
         {
            bgLayer.destory();
            bgLayer = null;
         }
      }
      
      public function setVisible(param1:Boolean) : void
      {
         if(mapLayer && mapLayer.enabled)
         {
            mapLayer.visible = param1;
         }
         if(frontLayer && frontLayer.enabled)
         {
            frontLayer.visible = param1;
         }
         if(frontFixLayer && frontFixLayer.enabled)
         {
            frontFixLayer.visible = param1;
         }
         if(bgLayer && bgLayer.enabled)
         {
            bgLayer.visible = param1;
         }
      }
      
      public function setColorTransform(param1:ColorTransform) : void
      {
         _colorTransform = param1;
         if(mapLayer && mapLayer.enabled)
         {
            mapLayer.transform.colorTransform = _colorTransform;
         }
         if(frontLayer && frontLayer.enabled)
         {
            frontLayer.transform.colorTransform = _colorTransform;
         }
         if(frontFixLayer && frontFixLayer.enabled)
         {
            frontFixLayer.transform.colorTransform = _colorTransform;
         }
         if(bgLayer && bgLayer.enabled)
         {
            bgLayer.transform.colorTransform = _colorTransform;
         }
      }
      
      public function getColorTransform() : ColorTransform
      {
         return _colorTransform;
      }
      
      public function resetColorTransform() : void
      {
         _colorTransform = new ColorTransform();
         setColorTransform(_colorTransform);
      }
      
      public function getSmoothing() : Point
      {
         return _smoothing;
      }
      
      public function setSmoothing(param1:Number = 0, param2:Number = 0) : void
      {
         _smoothing.x = param1;
         _smoothing.y = param2;
         if(mapLayer && mapLayer.enabled)
         {
            mapLayer.setSmoothing(param1,param2);
         }
         if(bgLayer && bgLayer.enabled)
         {
            bgLayer.setSmoothing(param1 * 3,param2 * 3);
         }
         if(frontLayer && frontLayer.enabled)
         {
            frontLayer.setSmoothing(param1 * 2,param2 * 2);
         }
         if(frontFixLayer && frontFixLayer.enabled)
         {
            frontFixLayer.setSmoothing(param1 * 2,param2 * 2);
         }
      }
      
      public function initlize() : void
      {
         var _loc4_:DisplayObject = mapMc.getChildByName("line_left");
         var _loc3_:DisplayObject = mapMc.getChildByName("line_right");
         var _loc2_:DisplayObject = mapMc.getChildByName("line_bottom");
         var _loc7_:DisplayObject = mapMc.getChildByName("line_player_bottom");
         var _loc6_:Point = GameConfig.GAME_SIZE;
         if(_loc4_)
         {
            left = _loc4_.x;
         }
         if(_loc3_)
         {
            right = _loc3_.x;
         }
         if(_loc2_)
         {
            bottom = _loc2_.y;
         }
         if(_loc7_)
         {
            playerBottom = _loc7_.y;
         }
         var _loc5_:DisplayObject = mapMc.getChildByName("p1");
         var _loc1_:DisplayObject = mapMc.getChildByName("p2");
         if(_loc5_)
         {
            p1pos = new Point(_loc5_.x,_loc5_.y);
         }
         if(_loc1_)
         {
            p2pos = new Point(_loc1_.x,_loc1_.y);
         }
         mapLayer = new MapLayer(mapMc.getChildByName("map"));
         frontLayer = new MapLayer(mapMc.getChildByName("front"));
         frontFixLayer = new MapLayer(mapMc.getChildByName("front_fix"));
         bgLayer = new MapLayer(mapMc.getChildByName("bg"));
         if(bgLayer.enabled)
         {
            bgLayer.normalize();
            mapMc.addChild(bgLayer);
         }
         var _loc8_:Number = _loc6_.y - bottom;
         if(mapLayer.enabled)
         {
            mapLayer.normalize();
            mapLayer.y += _loc8_;
            mapMc.addChild(mapLayer);
         }
         if(frontLayer.enabled)
         {
            frontLayer.normalize();
            frontLayer.y += _loc8_;
            _defaultFrontPos = new Point(frontLayer.x,frontLayer.y);
            mapMc.addChild(frontLayer);
         }
         if(frontFixLayer.enabled)
         {
            frontFixLayer.normalize();
            frontFixLayer.y += _loc8_;
            mapMc.addChild(frontFixLayer);
         }
         playerBottom += _loc8_;
         bottom += _loc8_;
         if(p1pos)
         {
            p1pos.y += _loc8_;
         }
         if(p2pos)
         {
            p2pos.y += _loc8_;
         }
         initFloor(_loc8_);
         resetColorTransform();
      }
      
      public function getStageSize() : Point
      {
         return new Point(mapLayer.width,GameConfig.GAME_SIZE.y);
      }
      
      public function getMapBottomDistance() : Number
      {
         return bottom - playerBottom;
      }
      
      private function initFloor(param1:Number) : void
      {
         var _loc2_:int = 0;
         var _loc3_:DisplayObject = null;
         var _loc4_:FloorVO = null;
         _floors = [];
         var _loc5_:Sprite = mapMc.getChildByName("floor") as Sprite;
         if(!_loc5_)
         {
            return;
         }
         while(_loc2_ < _loc5_.numChildren)
         {
            _loc3_ = _loc5_.getChildAt(_loc2_);
            if(_loc3_)
            {
               _loc4_ = new FloorVO();
               _loc4_.xFrom = _loc5_.x + _loc3_.x;
               _loc4_.xTo = _loc5_.x + _loc3_.x + _loc3_.width;
               _loc4_.y = _loc5_.y + _loc3_.y + param1;
               _floors.push(_loc4_);
            }
            _loc2_++;
         }
      }
      
      public function getFloorHitTest(param1:Number, param2:Number, param3:Number) : FloorVO
      {
         var _loc4_:int = 0;
         var _loc5_:* = null;
         while(_loc4_ < _floors.length)
         {
            _loc5_ = _floors[_loc4_];
            if(_loc5_.hitTest(param1,param2,param3))
            {
               return _loc5_;
            }
            _loc4_++;
         }
         return null;
      }
      
      public function render(param1:Number, param2:Number, param3:Number) : void
      {
         var _loc5_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc4_:Vector.<IGameSprite> = gameState.getGameSprites();
         if(_loc4_ == null || _loc4_.length < 1)
         {
            return;
         }
         if(frontLayer && frontLayer.enabled)
         {
            _loc5_ = param1;
            _loc7_ = param2 + bottom;
            frontLayer.x = _loc5_ * 0.1 + _defaultFrontPos.x;
            _loc6_ = _defaultFrontPos.y;
            _loc6_ = _loc7_ * 0.1 + _defaultFrontPos.y;
            _loc6_ < _defaultFrontPos.y && (_loc6_);
            frontLayer.y = _loc6_;
            frontLayer.renderOptical(_loc4_);
         }
         if(frontFixLayer && frontFixLayer.enabled)
         {
            frontFixLayer.renderOptical(_loc4_);
         }
      }
   }
}

