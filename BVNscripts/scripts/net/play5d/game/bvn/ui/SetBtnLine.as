package net.play5d.game.bvn.ui
{
   import com.greensock.*;
   import flash.display.*;
   import flash.text.*;
   
   public class SetBtnLine extends Sprite
   {
      
      private var _txt:TextField;
      
      private var _line:Sprite;
      
      public function SetBtnLine()
      {
         super();
         mouseChildren = mouseEnabled = false;
         this._line = new Sprite();
         addChild(this._line);
         if(GameUI.SHOW_CN_TEXT)
         {
            this._txt = new TextField();
            UIUtils.formatText(this._txt,{
               "color":16641381,
               "size":20,
               "font":"楷体",
               "align":"right"
            });
            this._txt.y = 4;
            addChild(this._txt);
         }
      }
      
      public function show(param1:Number, param2:String) : void
      {
         this._line.graphics.clear();
         this._line.graphics.lineStyle(1,16641381,1);
         this._line.graphics.lineTo(param1,0);
         this._line.scaleX = 0.1;
         TweenLite.to(this._line,0.3,{"scaleX":1});
         this.visible = true;
         if(Boolean(this._txt))
         {
            this._txt.width = param1;
            this._txt.text = param2;
         }
      }
      
      public function hide() : void
      {
         this.visible = false;
         if(Boolean(this._txt))
         {
            this._txt.text = "";
         }
      }
   }
}

