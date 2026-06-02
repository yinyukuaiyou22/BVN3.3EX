package net.play5d.game.bvn.ui.dialog.select
{
   import com.greensock.TweenLite;
   import flash.display.*;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.game.bvn.data.mosou.MosouFighterModel;
   import net.play5d.game.bvn.data.mosou.MosouFighterSellVO;
   import net.play5d.game.bvn.utils.BtnUtils;
   import net.play5d.game.bvn.utils.TouchMoveEvent;
   import net.play5d.game.bvn.utils.TouchUtils;
   
   public class SelectFighterList extends Sprite
   {
      
      private var _fighterItems:Vector.<SelectFighterUI>;
      
      public var onSelectFighter:Function;
      
      public var onChangePage:Function;
      
      private var _scrollY:Number = 0;
      
      private var _width:Number = 385;
      
      private var _height:Number = 405;
      
      private var _listHeight:Number = 0;
      
      private var _listCt:Sprite;
      
      private var _curPage:int;
      
      private var _totalPage:int;
      
      public function SelectFighterList()
      {
         super();
         with(this.graphics)
         {
            beginBitmapFill(new BitmapData(1,1,true,0));
            drawRect(0,0,_width,_height);
            endFill();
         }
         _listCt = new Sprite();
         addChild(_listCt);
         _listCt.scrollRect = new Rectangle(0,0,_width,_height);
         build();
         listenEvents();
      }
      
      private function build() : void
      {
         var _loc7_:int = 0;
         var _loc2_:MosouFighterSellVO = null;
         var _loc3_:Boolean = false;
         var _loc4_:SelectFighterUI = null;
         var _loc9_:int = 0;
         var _loc12_:Vector.<MosouFighterSellVO> = MosouFighterModel.I.fighters;
         var _loc11_:Array = GameData.I.mosouData.getFighterTeamIds();
         _fighterItems = new Vector.<SelectFighterUI>();
         _loc7_ = 0;
         while(_loc7_ < _loc12_.length)
         {
            _loc2_ = _loc12_[_loc7_];
            _loc3_ = false;
            if(_loc11_.indexOf(_loc2_.id) == -1)
            {
               _loc4_ = new SelectFighterUI(_loc2_);
               BtnUtils.btnMode(_loc4_.ui);
               BtnUtils.initBtn(_loc4_.ui,selectHandler,_loc4_);
               _fighterItems.push(_loc4_);
               _listCt.addChild(_loc4_.ui);
            }
            _loc7_++;
         }
         var _loc5_:Array = [];
         var _loc10_:Array = [];
         for each(var _loc1_ in _fighterItems)
         {
            if(_loc1_.isBought())
            {
               _loc5_.push(_loc1_);
            }
            else
            {
               _loc10_.push(_loc1_);
            }
         }
         _loc5_.sort();
         _loc5_.sort();
         _loc10_.sort();
         _loc10_.sort();
         _fighterItems = Vector.<SelectFighterUI>(_loc5_.concat(_loc10_));
         _loc5_ = null;
         _loc10_ = null;
         var _loc6_:int = 10;
         var _loc8_:int = 10;
         _totalPage = 1;
         _curPage = 1;
         _loc9_ = 0;
         while(_loc9_ < _fighterItems.length)
         {
            _fighterItems[_loc9_].ui.x = _loc6_ + _width * (_totalPage - 1);
            _fighterItems[_loc9_].ui.y = _loc8_;
            _loc6_ += 80;
            if(_loc6_ > _width)
            {
               _loc6_ = 10;
               _loc8_ += 80;
            }
            if(_loc8_ > _height - 10)
            {
               _totalPage = _totalPage + 1;
               _loc6_ = 10;
               _loc8_ = 10;
            }
            _loc9_++;
         }
         _listHeight = _loc8_;
      }
      
      public function destory() : void
      {
         this.removeEventListener("mouseWheel",mouseHandler);
         TouchUtils.I.unlistenOneFinger(this);
      }
      
      private function listenEvents() : void
      {
         if(GameConfig.TOUCH_MODE)
         {
            TouchUtils.I.listenOneFinger(this,touchHandler,true,false);
         }
         else
         {
            this.addEventListener("mouseWheel",mouseHandler);
         }
      }
      
      public function update() : void
      {
         for each(var _loc1_ in _fighterItems)
         {
            _loc1_.updateUI();
         }
      }
      
      private function scroll(param1:Number) : void
      {
         scrollTo(_scrollY + param1);
      }
      
      private function scrollTo(param1:Number) : void
      {
         var v:Number = param1;
         var obj:Object = {
            "x":_listCt.scrollRect.x,
            "y":0
         };
         TweenLite.to(obj,0.3,{
            "x":v,
            "onUpdate":function():void
            {
               _listCt.scrollRect = new Rectangle(obj.x,obj.y,_width,_height);
            }
         });
      }
      
      private function selectHandler(param1:SelectFighterUI) : void
      {
         var _loc2_:Boolean = false;
         for each(var _loc3_ in _fighterItems)
         {
            _loc2_ = _loc3_ == param1;
            _loc3_.select(_loc2_);
            if(_loc2_ && onSelectFighter != null)
            {
               onSelectFighter(_loc3_);
            }
         }
      }
      
      private function mouseHandler(param1:MouseEvent) : void
      {
         if(param1.delta < 0)
         {
            setPage(_curPage + 1);
         }
         else
         {
            setPage(_curPage - 1);
         }
      }
      
      private function touchHandler(param1:TouchMoveEvent) : void
      {
         if(param1.type == "EVENT_TOUCH_END")
         {
            if(param1.distanceX > 50)
            {
               setPage(_curPage - 1);
            }
            if(param1.distanceX < -50)
            {
               setPage(_curPage + 1);
            }
         }
      }
      
      public function getPage() : int
      {
         return _curPage;
      }
      
      public function setPage(param1:int) : void
      {
         if(param1 < 1)
         {
            return;
         }
         if(param1 > getTotalPage())
         {
            return;
         }
         _curPage = param1;
         scrollTo((param1 - 1) * _width);
         if(onChangePage != null)
         {
            onChangePage();
         }
      }
      
      public function getTotalPage() : int
      {
         return _totalPage;
      }
   }
}

