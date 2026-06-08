package net.play5d.game.bvn.ui
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   
   public class MoveListSp extends Sprite
   {
      
      private var _picClass:Class = EmbeddedAssets.movelist_jpg;
      
      private var _pic:*;
      
      private var _btns:SetBtnGroup;
      
      public var onBackSelect:Function;
      
      public function MoveListSp()
      {
         super();
         this._pic = new this._picClass();
         this._pic.width = GameConfig.GAME_SIZE.x;
         this._pic.height = GameConfig.GAME_SIZE.y;
         addChild(this._pic);
         this._btns = new SetBtnGroup();
         this._btns.setBtnData([{
            "label":"BACK",
            "cn":"返回"
         }]);
         this._btns.addEventListener("SELECT",this.onSelect);
         this._btns.x = 250;
         this._btns.y = GameConfig.GAME_SIZE.y - 130;
         addChild(this._btns);
      }
      
      public function destory() : void
      {
         if(Boolean(this._btns))
         {
            this._btns.removeEventListener("SELECT",this.onSelect);
            this._btns.destory();
            this._btns = null;
         }
      }
      
      public function show() : void
      {
         this.visible = true;
         setTimeout(function():void
         {
            _btns.keyEnable = true;
         },100);
      }
      
      public function hide() : void
      {
         this._btns.keyEnable = false;
         this.visible = false;
      }
      
      private function onSelect(param1:Event) : void
      {
         if(this.onBackSelect != null)
         {
            this.onBackSelect();
         }
      }
   }
}

