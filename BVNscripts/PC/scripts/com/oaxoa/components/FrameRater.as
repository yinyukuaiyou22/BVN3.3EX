package com.oaxoa.components
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.filters.DropShadowFilter;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.Timer;
   
   public class FrameRater extends Sprite
   {
      
      private var _timer:Timer;
      
      private var _text:TextField;
      
      private var _tf:TextFormat;
      
      private var _c:uint = 0;
      
      private var _dropShadow:DropShadowFilter;
      
      private var _graph:Sprite;
      
      private var _graphBox:Sprite;
      
      private var _graphCounter:uint;
      
      private var _showGraph:Boolean;
      
      private var _graphColor:uint;
      
      public function FrameRater(param1:uint = 0, param2:Boolean = false, param3:Boolean = true, param4:uint = 16711680)
      {
         super();
         _showGraph = param3;
         _graphColor = param4;
         if(_showGraph)
         {
            initGraph();
         }
         _dropShadow = new DropShadowFilter(1,90,0,1,2,2);
         _tf = new TextFormat();
         _tf.color = param1;
         _tf.font = "Microsoft YaHei";
         _tf.size = 11;
         _text = new TextField();
         _text.width = 100;
         _text.height = 20;
         _text.x = 3;
         _text.setTextFormat(_tf);
         if(param2)
         {
            _text.filters = [_dropShadow];
         }
         addChild(_text);
         _timer = new Timer(1000);
         _timer.addEventListener("timer",onTimer);
         _timer.start();
         addEventListener("enterFrame",onFrame);
      }
      
      private function onTimer(param1:TimerEvent) : void
      {
         var _loc2_:Number = computeTime();
         _text.text = Math.floor(_loc2_).toString() + " fps";
         _text.setTextFormat(_tf);
         _text.autoSize = "left";
         if(_showGraph)
         {
            updateGraph(_loc2_);
         }
      }
      
      private function onFrame(param1:Event) : void
      {
         _c = _c + 1;
      }
      
      public function computeTime() : Number
      {
         var _loc1_:uint = _c;
         _c = 0;
         return _loc1_ - 1;
      }
      
      public function updateGraph(param1:Number) : void
      {
         if(_graphCounter > 30)
         {
            _graph.x--;
         }
         _graphCounter = _graphCounter + 1;
         _graph.graphics.lineTo(_graphCounter,1 + (stage.frameRate - param1) / 3);
      }
      
      private function initGraph() : void
      {
         _graphCounter = 0;
         _graph = new Sprite();
         _graphBox = new Sprite();
         _graphBox.graphics.beginFill(16711680);
         _graphBox.graphics.drawRect(0,0,36,100);
         _graphBox.graphics.endFill();
         _graph.mask = _graphBox;
         _graph.x = _graphBox.x = 5;
         _graph.y = _graphBox.y = 20;
         _graph.graphics.lineStyle(1,_graphColor);
         addChild(_graph);
         addChild(_graphBox);
      }
   }
}

