package net.play5d.game.bvn.ui.select
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.game.bvn.utils.*;
   import net.play5d.kyo.display.*;
   import net.play5d.kyo.utils.*;
   
   public class MapSelectUI extends Sprite
   {
      
      public var enabled:Boolean = false;
      
      public var inputType:String;
      
      private var _mapmc:*;
      
      private var _txtmc:*;
      
      private var _txt:BitmapText;
      
      private var _maps:Array;
      
      private var _curId:int;
      
      private var _picCache:Object = {};
      
      private var _prevListener:Function;
      
      private var _nextListener:Function;
      
      private var _confrimListener:Function;
      
      public function MapSelectUI()
      {
         super();
         this.build();
      }
      
      public function addMouseEvents(param1:Function, param2:Function, param3:Function) : void
      {
         this._mapmc.left_arrow.buttonMode = true;
         this._mapmc.right_arrow.buttonMode = true;
         this._mapmc.kuang.buttonMode = true;
         this._prevListener = param1;
         this._nextListener = param2;
         this._confrimListener = param3;
         this._mapmc.left_arrow.addEventListener("mouseOver",this.mouseHandler);
         this._mapmc.right_arrow.addEventListener("mouseOver",this.mouseHandler);
         this._mapmc.kuang.addEventListener("mouseOver",this.mouseHandler);
         this._mapmc.left_arrow.addEventListener("click",this.mouseHandler);
         this._mapmc.right_arrow.addEventListener("click",this.mouseHandler);
         this._mapmc.kuang.addEventListener("click",this.mouseHandler);
      }
      
      private function mouseHandler(param1:MouseEvent) : void
      {
         if(param1.type == "mouseOver")
         {
            SoundCtrl.I.sndSelect();
            return;
         }
         switch(param1.currentTarget)
         {
            case this._mapmc.left_arrow:
               if(this._prevListener != null)
               {
                  this._prevListener();
               }
               break;
            case this._mapmc.right_arrow:
               if(this._nextListener != null)
               {
                  this._nextListener();
               }
               break;
            case this._mapmc.kuang:
               if(this._confrimListener != null)
               {
                  this._confrimListener();
               }
         }
         SoundCtrl.I.sndConfrim();
      }
      
      private function build() : void
      {
         this._mapmc = ResUtils.I.createDisplayObject(ResUtils.I.select,"select_map_mc");
         this._maps = MapModel.I.getAllMaps();
         this._mapmc.x = (GameConfig.GAME_SIZE.x - this._mapmc.bg.width) / 2;
         this._mapmc.y = GameConfig.GAME_SIZE.y * 0.25;
         this._mapmc.ct.x -= 2;
         addChild(this._mapmc);
         if(GameUI.SHOW_CN_TEXT)
         {
            this._txtmc = ResUtils.I.createDisplayObject(ResUtils.I.select,"select_map_txt_mc");
            this._txtmc.x = (GameConfig.GAME_SIZE.x - this._txtmc.width) / 2;
            this._txtmc.y = GameConfig.GAME_SIZE.y - this._txtmc.height - 35;
            addChild(this._txtmc);
            this._txt = new BitmapText(true,16777215,[new GlowFilter(0,1,3,3,3)]);
            UIUtils.formatText(this._txt.textfield,{
               "color":16777215,
               "size":14,
               "align":"center"
            });
            this._txt.width = this._txtmc.width;
            this._txtmc.addChild(this._txt);
         }
         this.showMap(0);
      }
      
      public function destory() : void
      {
         this._prevListener = null;
         this._nextListener = null;
         this._confrimListener = null;
         if(Boolean(this._mapmc))
         {
            this._mapmc.left_arrow.removeEventListener("mouseOver",this.mouseHandler);
            this._mapmc.right_arrow.removeEventListener("mouseOver",this.mouseHandler);
            this._mapmc.kuang.removeEventListener("mouseOver",this.mouseHandler);
            this._mapmc.left_arrow.removeEventListener("click",this.mouseHandler);
            this._mapmc.right_arrow.removeEventListener("click",this.mouseHandler);
            this._mapmc.kuang.removeEventListener("click",this.mouseHandler);
         }
         if(Boolean(this.parent))
         {
            try
            {
               this.parent.removeChild(this);
            }
            catch(e:Error)
            {
            }
         }
         if(Boolean(this._txt))
         {
            this._txt.destory();
            this._txt = null;
         }
      }
      
      public function select(param1:Function) : void
      {
         var _loc2_:MapVO = this._maps[this._curId];
         if(Boolean(_loc2_))
         {
            while(_loc2_.id == "random")
            {
               _loc2_ = KyoRandom.getRandomInArray(this._maps);
            }
            GameData.I.selectMap = _loc2_.id;
            this.enabled = false;
            if(param1 != null)
            {
               param1();
            }
         }
      }
      
      public function prev() : void
      {
         var _loc1_:int = this._curId - 1;
         if(_loc1_ < 0)
         {
            _loc1_ = this._maps.length - 1;
         }
         this.showMap(_loc1_);
      }
      
      public function next() : void
      {
         var _loc1_:int = this._curId + 1;
         if(_loc1_ > this._maps.length - 1)
         {
            _loc1_ = 0;
         }
         this.showMap(_loc1_);
      }
      
      private function showMap(param1:int) : void
      {
         this._curId = param1;
         var _loc2_:MapVO = this._maps[param1];
         var _loc3_:DisplayObject = this.getPic(_loc2_);
         this._mapmc.ct.removeChildren();
         if(Boolean(_loc3_))
         {
            this._mapmc.ct.addChild(_loc3_);
         }
         if(Boolean(this._txt))
         {
            this._txt.text = _loc2_.name;
         }
      }
      
      private function getPic(param1:MapVO) : DisplayObject
      {
         var _loc2_:DisplayObject = this._picCache[param1.id];
         if(Boolean(_loc2_))
         {
            return _loc2_;
         }
         _loc2_ = AssetManager.I.getMapPic(param1);
         this._picCache[param1.id] = _loc2_;
         return _loc2_;
      }
   }
}

