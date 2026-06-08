package net.play5d.game.bvn.ui.dialog
{
   import com.greensock.*;
   import flash.display.*;
   import flash.text.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.events.SetBtnEvent;
   import net.play5d.game.bvn.ui.*;
   import net.play5d.kyo.display.bitmap.*;
   import net.play5d.kyo.display.shapes.*;
   
   public class ConfrimUI extends Sprite
   {
      
      private var _enTxt:BitmapFontText;
      
      private var _cnTxt:TextField;
      
      private var _btnGroup:SetBtnGroup;
      
      public var yesBack:Function;
      
      public var noBack:Function;
      
      public function ConfrimUI()
      {
         super();
         this.build();
      }
      
      public function destory() : void
      {
         if(Boolean(this._enTxt))
         {
            this._enTxt.dispose();
            this._enTxt = null;
         }
         if(Boolean(this._btnGroup))
         {
            this._btnGroup.removeEventListener("SELECT",this.selectHandler);
            this._btnGroup.destory();
            this._btnGroup = null;
         }
      }
      
      private function build() : void
      {
         var _loc1_:Sprite = new Sprite();
         _loc1_.graphics.beginFill(0,0.3);
         _loc1_.graphics.drawRect(0,0,GameConfig.GAME_SIZE.x,GameConfig.GAME_SIZE.y);
         _loc1_.graphics.endFill();
         addChild(_loc1_);
         var _loc2_:Box = new Box(GameConfig.GAME_SIZE.x,300,0,0.8);
         _loc2_.y = (GameConfig.GAME_SIZE.y - _loc2_.height) / 2;
         addChild(_loc2_);
         this._enTxt = new BitmapFontText(AssetManager.I.getFont("font1"));
         this._enTxt.y = 18;
         _loc2_.addChild(this._enTxt);
         if(GameUI.SHOW_CN_TEXT)
         {
            this._cnTxt = new TextField();
            UIUtils.formatText(this._cnTxt,{
               "color":16777215,
               "size":20,
               "align":"center"
            });
            this._cnTxt.y = this._enTxt.y + this._enTxt.height + 80;
            this._cnTxt.width = GameConfig.GAME_SIZE.x;
            this._cnTxt.height = 100;
            this._cnTxt.mouseEnabled = false;
            _loc2_.addChild(this._cnTxt);
         }
         this._btnGroup = new SetBtnGroup();
         this._btnGroup.startX = this._btnGroup.startY = 0;
         this._btnGroup.direct = 0;
         this._btnGroup.gap = 200;
         this._btnGroup.setBtnData([{
            "label":"YES",
            "cn":"是"
         },{
            "label":"NO",
            "cn":"否"
         }],1);
         this._btnGroup.addEventListener("SELECT",this.selectHandler);
         this._btnGroup.x = (GameConfig.GAME_SIZE.x - this._btnGroup.width) / 2 + 30;
         this._btnGroup.y = _loc2_.height - 80;
         _loc2_.addChild(this._btnGroup);
         var _loc3_:Number = _loc2_.y;
         _loc2_.y = GameConfig.GAME_SIZE.y;
         TweenLite.to(_loc2_,0.2,{"y":_loc3_});
      }
      
      private function selectHandler(param1:SetBtnEvent) : void
      {
         switch(param1.selectedLabel)
         {
            case "YES":
               if(this.yesBack != null)
               {
                  this.yesBack();
               }
               break;
            case "NO":
               if(this.noBack != null)
               {
                  this.noBack();
               }
         }
      }
      
      public function setMsg(param1:String = null, param2:String = null) : void
      {
         this._enTxt.text = param1 ? param1 : "";
         this._enTxt.x = (GameConfig.GAME_SIZE.x - this._enTxt.width) / 2;
         if(Boolean(this._cnTxt))
         {
            this._cnTxt.text = param2 ? param2 : "";
         }
      }
   }
}

