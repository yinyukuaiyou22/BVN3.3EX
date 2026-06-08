package net.play5d.game.bvn.map
{
   import flash.display.*;
   import flash.geom.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.interfaces.IGameSprite;
   import net.play5d.game.bvn.state.GameState;
   import net.play5d.kyo.utils.*;
   
   public class MapMain
   {
      
      public var mapLayer:MovieClip;
      
      public var frontLayer:Sprite;
      
      public var frontFixLayer:Sprite;
      
      public var bgLayer:Bitmap;
      
      public var p1pos:Point;
      
      public var p2pos:Point;
      
      public var left:Number = 0;
      
      public var right:Number = 0;
      
      public var bottom:Number = 0;
      
      public var playerBottom:Number = 0;
      
      public var mapMc:Sprite;
      
      public var data:MapVO;
      
      public var gameState:GameState;
      
      private var _defaultFrontPos:Point;
      
      private var _floors:Array;
      
      public function MapMain(param1:Sprite)
      {
         super();
         this.mapMc = param1;
      }
      
      public function destory() : void
      {
         if(Boolean(this.mapMc))
         {
            try
            {
               if("stopAllMovieClips" in this.mapMc)
               {
                  (this.mapMc as Object).stopAllMovieClips();
               }
               this.mapMc.removeChildren();
            }
            catch(e:Error)
            {
               trace(e);
            }
            this.mapMc = null;
         }
         if(Boolean(this.mapLayer))
         {
            this.mapLayer = null;
         }
         if(Boolean(this.frontLayer))
         {
            this.frontLayer = null;
         }
         if(Boolean(this.frontFixLayer))
         {
            this.frontFixLayer = null;
         }
         if(Boolean(this.bgLayer))
         {
            this.bgLayer.bitmapData.dispose();
            this.bgLayer = null;
         }
      }
      
      public function setVisible(param1:Boolean) : void
      {
         if(false && param1)
         {
            return;
         }
         if(Boolean(this.mapLayer))
         {
            this.mapLayer.visible = param1;
         }
         if(Boolean(this.frontLayer))
         {
            this.frontLayer.visible = param1;
         }
         if(Boolean(this.frontFixLayer))
         {
            this.frontFixLayer.visible = param1;
         }
         if(Boolean(this.bgLayer))
         {
            this.bgLayer.visible = param1;
         }
      }
      
      public function initlize() : void
      {
         var _loc1_:DisplayObject = this.mapMc.getChildByName("line_left");
         var _loc2_:DisplayObject = this.mapMc.getChildByName("line_right");
         var _loc3_:DisplayObject = this.mapMc.getChildByName("line_bottom");
         var _loc4_:DisplayObject = this.mapMc.getChildByName("line_player_bottom");
         var _loc5_:Point = GameConfig.GAME_SIZE;
         if(Boolean(_loc1_))
         {
            this.left = _loc1_.x;
         }
         if(Boolean(_loc2_))
         {
            this.right = _loc2_.x;
         }
         if(Boolean(_loc3_))
         {
            this.bottom = _loc3_.y;
         }
         if(Boolean(_loc4_))
         {
            this.playerBottom = _loc4_.y;
         }
         var _loc6_:DisplayObject = this.mapMc.getChildByName("p1");
         var _loc7_:DisplayObject = this.mapMc.getChildByName("p2");
         if(Boolean(_loc6_))
         {
            this.p1pos = new Point(_loc6_.x,_loc6_.y);
         }
         if(Boolean(_loc7_))
         {
            this.p2pos = new Point(_loc7_.x,_loc7_.y);
         }
         this.mapLayer = this.mapMc.getChildByName("map") as MovieClip;
         this.frontLayer = this.mapMc.getChildByName("front") as Sprite;
         this.frontFixLayer = this.mapMc.getChildByName("front_fix") as Sprite;
         this.bgLayer = this.drawBitmap("bg",false,0);
         if(Boolean(this.bgLayer))
         {
            this.normalizeLayer(this.bgLayer);
         }
         var _loc8_:Number = _loc5_.y - this.bottom;
         if(Boolean(this.mapLayer))
         {
            this.normalizeLayer(this.mapLayer);
            this.mapLayer.y += _loc8_;
         }
         if(Boolean(this.frontLayer))
         {
            this.normalizeLayer(this.frontLayer);
            this.frontLayer.y += _loc8_;
            this._defaultFrontPos = new Point(this.frontLayer.x,this.frontLayer.y);
         }
         if(Boolean(this.frontFixLayer))
         {
            this.normalizeLayer(this.frontFixLayer);
            this.frontFixLayer.y += _loc8_;
         }
         this.playerBottom += _loc8_;
         this.bottom += _loc8_;
         if(Boolean(this.p1pos))
         {
            this.p1pos.y += _loc8_;
         }
         if(Boolean(this.p2pos))
         {
            this.p2pos.y += _loc8_;
         }
         this.initFloor(_loc8_);
      }
      
      private function drawBitmap(param1:String, param2:Boolean = true, param3:uint = 0) : Bitmap
      {
         var _loc4_:* = null;
         var _loc5_:DisplayObject = this.mapMc.getChildByName(param1);
         if(Boolean(_loc5_))
         {
            return KyoUtils.drawDisplay(_loc5_,true,param2,param3);
         }
         return null;
      }
      
      private function normalizeLayer(param1:DisplayObject) : void
      {
         var _loc2_:Sprite = null;
         var _loc3_:int = 0;
         var _loc4_:DisplayObject = null;
         var _loc5_:DisplayObject = null;
         if(param1 is Bitmap)
         {
            (param1 as Bitmap).smoothing = GameData.I.config.quality == "best";
         }
         if(param1 is Sprite)
         {
            _loc2_ = param1 as Sprite;
            while(_loc3_ < _loc2_.numChildren)
            {
               _loc4_ = _loc2_.getChildAt(_loc3_);
               if(_loc4_ is Bitmap)
               {
                  (_loc4_ as Bitmap).smoothing = GameData.I.config.quality == "best";
               }
               _loc3_++;
            }
            if(GameConfig.MAP_LOGO_STATE != 1)
            {
               _loc5_ = _loc2_.getChildByName("logo4399");
               if(Boolean(_loc5_))
               {
                  _loc5_.visible = false;
               }
            }
         }
      }
      
      public function getStageSize() : Point
      {
         return new Point(this.mapLayer.width,GameConfig.GAME_SIZE.y);
      }
      
      public function getMapBottomDistance() : Number
      {
         return this.bottom - this.playerBottom;
      }
      
      private function initFloor(param1:Number) : void
      {
         var _loc2_:int = 0;
         var _loc3_:DisplayObject = null;
         var _loc4_:FloorVO = null;
         this._floors = [];
         var _loc5_:Sprite = this.mapMc.getChildByName("floor") as Sprite;
         if(!_loc5_)
         {
            return;
         }
         while(_loc2_ < _loc5_.numChildren)
         {
            _loc3_ = _loc5_.getChildAt(_loc2_);
            if(Boolean(_loc3_))
            {
               _loc4_ = new FloorVO();
               _loc4_.xFrom = _loc5_.x + _loc3_.x;
               _loc4_.xTo = _loc5_.x + _loc3_.x + _loc3_.width;
               _loc4_.y = _loc5_.y + _loc3_.y + param1;
               this._floors.push(_loc4_);
            }
            _loc2_++;
         }
      }
      
      public function getFloorHitTest(param1:Number, param2:Number, param3:Number) : FloorVO
      {
         var _loc4_:int = 0;
         var _loc5_:FloorVO = null;
         while(_loc4_ < this._floors.length)
         {
            _loc5_ = this._floors[_loc4_];
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
         var _loc4_:* = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         if(Boolean(this.frontLayer))
         {
            _loc4_ = param1;
            _loc5_ = param2 + this.bottom;
            this.frontLayer.x = _loc4_ * 0.1 + this._defaultFrontPos.x;
            _loc6_ = Number(this._defaultFrontPos.y);
            _loc6_ = _loc5_ * 0.1 + this._defaultFrontPos.y;
            _loc6_ < this._defaultFrontPos.y && _loc6_;
            this.frontLayer.y = _loc6_;
            this.renderOptical(this.frontLayer);
         }
         if(Boolean(this.frontFixLayer))
         {
            this.renderOptical(this.frontFixLayer);
         }
      }
      
      private function renderOptical(param1:Sprite) : void
      {
         var _loc2_:Rectangle = null;
         var _loc3_:DisplayObject = null;
         var _loc4_:int = 0;
         if(!this.gameState)
         {
            return;
         }
         var _loc5_:int = param1.numChildren;
         if(_loc5_ < 1)
         {
            return;
         }
         var _loc6_:Vector.<IGameSprite> = this.gameState.getGameSprites();
         if(!_loc6_ || _loc6_.length < 1)
         {
            return;
         }
         while(_loc4_ < _loc5_)
         {
            _loc3_ = param1.getChildAt(_loc4_);
            if(_loc3_ is MovieClip != false)
            {
               _loc2_ = _loc3_.getBounds(param1);
               _loc2_.x += param1.x;
               _loc2_.y += param1.y;
               _loc3_.alpha = this.checkHitGameSprite(_loc2_,_loc6_) ? 0.5 : 1;
            }
            _loc4_++;
         }
      }
      
      private function checkHitGameSprite(param1:Rectangle, param2:Vector.<IGameSprite>) : Boolean
      {
         var _loc3_:int = 0;
         var _loc4_:IGameSprite = null;
         var _loc5_:Boolean = false;
         var _loc6_:Rectangle = null;
         while(_loc3_ < param2.length)
         {
            _loc4_ = param2[_loc3_];
            if(Boolean(_loc4_))
            {
               _loc6_ = _loc4_.getArea();
               if(Boolean(_loc6_))
               {
                  _loc5_ = param1.intersects(_loc6_);
                  if(_loc5_)
                  {
                     return true;
                  }
               }
            }
            _loc3_++;
         }
         return false;
      }
   }
}

