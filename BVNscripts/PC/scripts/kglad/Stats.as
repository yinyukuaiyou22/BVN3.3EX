package kglad
{
   import flash.display.BitmapData;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.system.System;
   import flash.text.StyleSheet;
   import flash.text.TextField;
   import flash.utils.getTimer;
   
   public class Stats extends Sprite
   {
      
      protected const WIDTH:uint = 70;
      
      protected const HEIGHT:uint = 100;
      
      protected var xml:XML = <xml>
			<fps>FPS:</fps>
			<ms>MS:</ms>
			<mem>MEM:</mem>
			<memMax>MAX:</memMax>
		</xml>;
      
      protected var text:TextField = new TextField();
      
      protected var style:StyleSheet = new StyleSheet();
      
      protected var timer:uint;
      
      protected var fps:uint;
      
      protected var ms:uint;
      
      protected var ms_prev:uint;
      
      protected var mem:Number;
      
      protected var mem_max:Number = 0;
      
      protected var graph:BitmapData;
      
      protected var rectangle:Rectangle;
      
      protected var fps_graph:uint;
      
      protected var mem_graph:uint;
      
      protected var mem_max_graph:uint;
      
      protected var colors:Colors = new Colors();
      
      public function Stats()
      {
         super();
         style.setStyle("xml",{
            "fontSize":"9px",
            "fontFamily":"_sans",
            "leading":"-2px"
         });
         style.setStyle("fps",{"color":hex2css(colors.fps)});
         style.setStyle("ms",{"color":hex2css(colors.ms)});
         style.setStyle("mem",{"color":hex2css(colors.mem)});
         style.setStyle("memMax",{"color":hex2css(colors.memmax)});
         text.width = 70;
         text.height = 50;
         text.styleSheet = style;
         text.condenseWhite = true;
         text.selectable = false;
         text.mouseEnabled = false;
         rectangle = new Rectangle(70 - 1,0,1,100 - 50);
         addEventListener("addedToStage",init,false,0,true);
         addEventListener("removedFromStage",destroy,false,0,true);
      }
      
      private static function hex2css(param1:int) : String
      {
         return "#" + param1.toString(16);
      }
      
      private function init(param1:Event) : void
      {
         graphics.beginFill(colors.bg);
         graphics.drawRect(0,0,70,100);
         graphics.endFill();
         addChild(text);
         graph = new BitmapData(70,100 - 50,false,colors.bg);
         graphics.beginBitmapFill(graph,new Matrix(1,0,0,1,0,50));
         graphics.drawRect(0,50,70,100 - 50);
         addEventListener("click",onClick);
         addEventListener("enterFrame",update);
      }
      
      private function destroy(param1:Event) : void
      {
         graphics.clear();
         while(numChildren > 0)
         {
            removeChildAt(0);
         }
         graph.dispose();
         removeEventListener("click",onClick);
         removeEventListener("enterFrame",update);
      }
      
      private function update(param1:Event) : void
      {
         timer = getTimer();
         if(timer - 1000 > ms_prev)
         {
            ms_prev = timer;
            mem = Number((System.totalMemory * 9.54e-7).toFixed(3));
            mem_max = mem_max > mem ? mem_max : mem;
            fps_graph = Math.min(graph.height,fps / stage.frameRate * graph.height);
            mem_graph = Math.min(graph.height,Math.sqrt(Math.sqrt(mem * 5000))) - 2;
            mem_max_graph = Math.min(graph.height,Math.sqrt(Math.sqrt(mem_max * 5000))) - 2;
            graph.scroll(-1,0);
            graph.fillRect(rectangle,colors.bg);
            graph.setPixel(graph.width - 1,graph.height - fps_graph,colors.fps);
            graph.setPixel(graph.width - 1,graph.height - (timer - ms >> 1),colors.ms);
            graph.setPixel(graph.width - 1,graph.height - mem_graph,colors.mem);
            graph.setPixel(graph.width - 1,graph.height - mem_max_graph,colors.memmax);
            xml.fps = "FPS: " + fps + " / " + stage.frameRate;
            xml.mem = "MEM: " + mem;
            xml.memMax = "MAX: " + mem_max;
            fps = 0;
         }
         fps = fps + 1;
         xml.ms = "MS: " + (timer - ms);
         ms = timer;
         text.htmlText = xml;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         if(mouseY / height > 0.5)
         {
            --stage.frameRate;
         }
         else
         {
            ++stage.frameRate;
         }
         xml.fps = "FPS: " + fps + " / " + stage.frameRate;
         text.htmlText = xml;
      }
   }
}

class Colors
{
   
   public var bg:uint = 3355443;
   
   public var fps:uint = 16776960;
   
   public var ms:uint = 65280;
   
   public var mem:uint = 65535;
   
   public var memmax:uint = 16711792;
   
   public function Colors()
   {
      super();
   }
}
