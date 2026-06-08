package net.play5d.game.bvn.ui.select
{
   import com.greensock.*;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TouchEvent;
   import flash.geom.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.input.*;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.kyo.utils.*;
   
   public class SelectIndexUIGroup extends Sprite
   {
      
      public var isFinish:Boolean;
      
      public var fzx:Number = 0;
      
      public var fzy:Number = 325;
      
      public var onFinish:Function;
      
      public var fighterOffset:Point;
      
      private var _fighters:Vector.<SelectedFighterUI>;
      
      private var _fighterScale:Number = 1;
      
      private var _fzScale:Number = 1;
      
      private var _arrowOffset:Point;
      
      private var _arrow:DisplayObject;
      
      private var _selectIndex:int;
      
      private var _selectItem:SelectedFighterUI;
      
      private var _inputType:String;
      
      private var _currentSelectId:int = 1;
      
      private var _gy:int = 100;
      
      private var _fuzhu:SelectedFighterUI;
      
      public function SelectIndexUIGroup()
      {
         this.fighterOffset = new Point();
         this._arrowOffset = new Point();
         super();
      }
      
      private static function sortFighters(param1:SelectedFighterUI, param2:SelectedFighterUI) : int
      {
         var _loc3_:int = param1.getFighterIndex();
         var _loc4_:int = param2.getFighterIndex();
         if(_loc3_ == -1)
         {
            _loc3_ = 10;
         }
         if(_loc4_ == -1)
         {
            _loc4_ = 10;
         }
         if(_loc3_ > _loc4_)
         {
            return 1;
         }
         if(_loc3_ < _loc4_)
         {
            return -1;
         }
         return 0;
      }
      
      public function getOrder() : Array
      {
         var _loc1_:int = 0;
         var _loc2_:Array = [];
         this._fighters.sort(sortFighters);
         while(_loc1_ < this._fighters.length)
         {
            _loc2_.push(this._fighters[_loc1_].getFighter().id);
            _loc1_++;
         }
         return _loc2_;
      }
      
      public function setFighterScale(param1:Number) : void
      {
         var _loc2_:* = undefined;
         this._fighterScale = param1;
         for each(_loc2_ in this._fighters)
         {
            _loc2_.ui.scaleX = _loc2_.ui.scaleY = param1;
         }
      }
      
      public function setFZScale(param1:Number) : void
      {
         this._fzScale = param1;
         if(!this._fuzhu)
         {
            return;
         }
         this._fuzhu.ui.scaleX = this._fuzhu.ui.scaleY = param1;
      }
      
      public function setOrder(param1:Array) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         while(_loc2_ < this._fighters.length)
         {
            _loc3_ = param1.indexOf(this._fighters[_loc2_].getFighter().id);
            if(_loc3_ != -1)
            {
               this._fighters[_loc2_].setFighterIndex(_loc3_ + 1);
            }
            _loc2_++;
         }
         this.removeArrow();
         this.isFinish = true;
         this.updateOrder();
      }
      
      public function destory() : void
      {
         var _loc1_:* = undefined;
         this.removeArrow();
         if(Boolean(this._fighters))
         {
            for each(_loc1_ in this._fighters)
            {
               _loc1_.removeEventListener("mouseOver",this.selectFighterMouseHandler);
               _loc1_.removeEventListener("click",this.selectFighterMouseHandler);
               _loc1_.removeEventListener("touchTap",this.selectFighterTouchHandler);
               _loc1_.destory();
            }
            this._fighters = null;
         }
         if(Boolean(this._fuzhu))
         {
            this._fuzhu.destory();
            this._fuzhu = null;
         }
         this._selectItem = null;
      }
      
      public function build(param1:Class, param2:SelectVO) : void
      {
         var _loc3_:* = null;
         var _loc4_:int = 0;
         var _loc5_:Array = param2.getSelectFighters();
         this._fighters = new Vector.<SelectedFighterUI>();
         while(_loc4_ < _loc5_.length)
         {
            _loc3_ = new SelectedFighterUI(new param1());
            _loc3_.setFighter(FighterModel.I.getFighter(_loc5_[_loc4_]));
            _loc3_.mouseEnabled(true);
            if(_loc5_.length > 1)
            {
               if(GameConfig.TOUCH_MODE)
               {
                  _loc3_.addEventListener("touchTap",this.selectFighterTouchHandler);
               }
               else
               {
                  _loc3_.addEventListener("mouseOver",this.selectFighterMouseHandler);
                  _loc3_.addEventListener("click",this.selectFighterMouseHandler);
               }
            }
            _loc3_.ui.x = this.fighterOffset.x;
            _loc3_.ui.y = _loc4_ * this._gy + this.fighterOffset.y;
            _loc3_.trueY = _loc4_ * this._gy;
            if(this._fighterScale != 1)
            {
               _loc3_.ui.scaleX = _loc3_.ui.scaleY = this._fighterScale;
            }
            this._fighters.push(_loc3_);
            addChild(_loc3_.ui);
            _loc4_++;
         }
         if(Boolean(param2.fuzhu))
         {
            _loc3_ = new SelectedFighterUI(new param1());
            _loc3_.setFighter(AssisterModel.I.getAssister(param2.fuzhu));
            _loc3_.ui.x = this.fzx;
            _loc3_.ui.y = this.fzy;
            _loc3_.setAssister();
            if(this._fzScale != 1)
            {
               _loc3_.ui.scaleX = _loc3_.ui.scaleY = this._fzScale;
            }
            addChild(_loc3_.ui);
            this._fuzhu = _loc3_;
         }
      }
      
      private function selectFighterTouchHandler(param1:TouchEvent) : void
      {
         var _loc2_:SelectedFighterUI = param1.currentTarget as SelectedFighterUI;
         var _loc3_:int = int(this._fighters.indexOf(_loc2_));
         if(_loc3_ == -1)
         {
            return;
         }
         this.selectIndex(_loc3_);
         this.doConfrim();
      }
      
      private function selectFighterMouseHandler(param1:MouseEvent) : void
      {
         var _loc2_:SelectedFighterUI = param1.currentTarget as SelectedFighterUI;
         var _loc3_:int = int(this._fighters.indexOf(_loc2_));
         if(_loc3_ == -1 || this._arrow == null)
         {
            return;
         }
         switch(param1.type)
         {
            case "mouseOver":
               this.selectIndex(_loc3_);
               SoundCtrl.I.sndSelect();
               break;
            case "click":
               this.doConfrim();
         }
      }
      
      public function initArrow(param1:DisplayObject, param2:Point) : void
      {
         this._arrowOffset = param2;
         this._arrow = param1;
         this._arrow.x = param2.x;
         addChild(this._arrow);
         this.selectIndex(0);
      }
      
      public function selectIndex(param1:int, param2:int = 0) : void
      {
         if(param1 < 0)
         {
            param1 = this._fighters.length - 1;
         }
         if(param1 > this._fighters.length - 1)
         {
            param1 = 0;
         }
         var _loc3_:SelectedFighterUI = this._fighters[param1];
         if(_loc3_.getFighterIndex() != -1)
         {
            if(param2 != 0)
            {
               this.selectIndex(param1 + param2,param2);
            }
            return;
         }
         this._selectIndex = param1;
         this._selectItem = this._fighters[param1];
         try
         {
            this._arrow.y = this._selectItem.trueY + this._arrowOffset.y;
         }
         catch(e:Error)
         {
         }
      }
      
      public function setKey(param1:String) : void
      {
         this._inputType = param1;
         GameRender.add(this.render);
         GameInputer.focus();
      }
      
      public function autoSelect() : void
      {
         var _loc3_:int = 0;
         var _loc1_:* = null;
         var _loc2_:Array = [];
         for each(_loc1_ in this._fighters)
         {
            _loc2_.push(_loc1_);
         }
         KyoRandom.arraySortRandom(_loc2_);
         _loc3_ = 1;
         for each(_loc1_ in _loc2_)
         {
            _loc1_.setFighterIndex(_loc3_);
            _loc3_++;
         }
         this.selectFinish();
      }
      
      private function removeArrow() : void
      {
         if(Boolean(this._arrow))
         {
            try
            {
               removeChild(this._arrow);
            }
            catch(e:Error)
            {
            }
            this._arrow = null;
         }
         GameRender.remove(this.render);
      }
      
      private function render() : void
      {
         if(GameUI.showingDialog())
         {
            return;
         }
         if(GameInputer.up(this._inputType,1))
         {
            this.selectIndex(this._selectIndex - 1,-1);
            SoundCtrl.I.sndSelect();
         }
         if(GameInputer.down(this._inputType,1))
         {
            this.selectIndex(this._selectIndex + 1,1);
            SoundCtrl.I.sndSelect();
         }
         if(GameInputer.attack(this._inputType,1))
         {
            this.doConfrim();
         }
      }
      
      private function doConfrim() : void
      {
         if(Boolean(this._selectItem))
         {
            this._selectItem.setFighterIndex(this._currentSelectId);
            ++this._currentSelectId;
            if(this._currentSelectId > this._fighters.length - 1)
            {
               this.selectLast();
               this.selectFinish();
            }
            else
            {
               this.updateOrder();
               this.selectIndex(1,1);
            }
            SoundCtrl.I.sndConfrim();
         }
      }
      
      private function selectLast() : void
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in this._fighters)
         {
            if(_loc1_.getFighterIndex() == -1)
            {
               _loc1_.setFighterIndex(this._currentSelectId);
               return;
            }
         }
      }
      
      private function selectFinish() : void
      {
         this.removeArrow();
         this.isFinish = true;
         this.updateOrder();
         if(this.onFinish != null)
         {
            GameEvent.dispatchEvent("SELECT_FIGHTER_INDEX",this.getOrder());
            this.onFinish();
         }
      }
      
      private function updateOrder() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Number = NaN;
         var _loc3_:* = null;
         this._fighters.sort(sortFighters);
         while(_loc1_ < this._fighters.length)
         {
            _loc2_ = _loc1_ * this._gy;
            this._fighters[_loc1_].trueY = _loc2_;
            _loc3_ = this._fighters[_loc1_].ui;
            if(Math.abs(_loc2_ - _loc3_.y) > 2)
            {
               TweenLite.to(_loc3_,0.2,{"y":_loc2_});
            }
            _loc1_++;
         }
      }
   }
}

