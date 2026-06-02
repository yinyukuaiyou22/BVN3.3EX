package net.play5d.game.bvn.win.views
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.text.TextField;
   import flash.text.TextFormat;
   
   public class Watermark extends Sprite
   {
      
      private var watermark:TextField;
      
      public function Watermark()
      {
         super();
         watermark = new TextField();
         watermark.text = "概念测试版本  不代表最终品质";
         var _loc1_:TextFormat = new TextFormat();
         _loc1_.font = "KaiTi";
         _loc1_.size = 36;
         _loc1_.color = 16777215 * Math.random();
         _loc1_.bold = true;
         _loc1_.italic = false;
         watermark.setTextFormat(_loc1_);
         watermark.autoSize = "center";
         watermark.selectable = false;
         watermark.mouseEnabled = false;
         this.mouseChildren = false;
         this.mouseEnabled = false;
         watermark.alpha = 0.514;
         addChild(watermark);
         this.addEventListener("addedToStage",onAddedToStage);
      }
      
      private function onAddedToStage(param1:Event) : void
      {
         this.removeEventListener("addedToStage",onAddedToStage);
         positionWatermark();
      }
      
      private function positionWatermark() : void
      {
         watermark.x = (stage.stageWidth - watermark.width) / 2;
         watermark.y = (stage.stageHeight - watermark.height) / 2;
         watermark.x += Math.random() * 100 - 50;
         watermark.y += Math.random() * 400 - 200;
      }
   }
}

