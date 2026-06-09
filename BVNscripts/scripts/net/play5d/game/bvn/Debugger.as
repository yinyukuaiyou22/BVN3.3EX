package net.play5d.game.bvn
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.events.UncaughtErrorEvent;
   import flash.geom.Rectangle;
   import flash.system.System;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.getTimer;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.kyo.input.KyoKeyCode;
   
   public class Debugger
   {
      
      public static var onErrorMsgCall:Function;
      
      private static var _stage:Stage;
      
      private static var _panel:Sprite;
      
      private static var _titleBar:Sprite;
      
      private static var _logContainer:Sprite;
      
      private static var _logTf:TextField;
      
      private static var _dragOffsetX:Number;
      
      private static var _dragOffsetY:Number;
      
      private static var _fmtInfo:TextFormat;
      
      private static var _fmtError:TextFormat;
      
      private static var _perfPanel:Sprite;
      
      private static var _perfTitleBar:Sprite;
      
      private static var _perfTf:TextField;
      
      private static var _perfFpsGraph:Bitmap;
      
      private static var _perfFpsBmd:BitmapData;
      
      private static var _perfMemGraph:Bitmap;
      
      private static var _perfMemBmd:BitmapData;
      
      private static var _debugEnabled:Boolean = false;

      private static var _logQueue:Array = [];

      private static const MAX_QUEUE_SIZE:int = 300;

      private static const FLUSH_INTERVAL:int = 3;

      private static var _frameCounter:int = 0;

      public static const DRAW_AREA:Boolean = false;

      public static const SAFE_MODE:Boolean = false;

      public static const HIDE_MAP:Boolean = false;

      public static const HIDE_HITEFFECT:Boolean = false;

      private static var _scale:Number = 1.0;

      private static var PANEL_WIDTH:int = 400;

      private static var TITLE_HEIGHT:int = 30;

      private static var LOG_HEIGHT:int = 180;
      
      private static var _lastPerfTimer:int = 0;
      
      private static var _fpsCurrent:Number = 0;
      
      private static var _fpsMin:Number = 999;
      
      private static var _fpsMax:Number = 0;
      
      private static var _fpsSampleCount:int = 0;
      
      private static var _fpsAccum:Number = 0;
      
      private static var _fpsAvg:Number = 0;
      
      private static var _perfFrameCount:int = 0;
      
      private static var _perfUpdateInterval:int = 10;
      
      private static var PERF_PANEL_WIDTH:int = 200;

      private static var PERF_TITLE_HEIGHT:int = 22;

      private static var PERF_BODY_HEIGHT:int = 120;

      private static var GRAPH_WIDTH:int = 60;

      private static var GRAPH_HEIGHT:int = 40;
      
      private static var _logBodyVisible:Boolean = true;

      private static var _perfBodyVisible:Boolean = true;
      
      public function Debugger()
      {
         super();
      }
      
      public static function log(... rest) : void
      {
         if(!_debugEnabled)
         {
            return;
         }
         var msg:String = rest.join(" ");
         if(!msg || msg.length == 0)
         {
            return;
         }
         _queueLog(msg,false);
      }
      
      public static function errorMsg(param1:String) : void
      {
         if(!_debugEnabled)
         {
            return;
         }
         if(onErrorMsgCall != null)
         {
            onErrorMsgCall(param1);
         }
         _queueLog("[ERROR] " + param1,true);
      }
      
      public static function initDebug(param1:Stage) : void
      {
         _stage = param1;
         _debugEnabled = true;

         // Mobile scaling: base on 800px desktop reference
         var screenW:Number = _stage.fullScreenWidth > 0 ? _stage.fullScreenWidth : _stage.stageWidth;
         var screenH:Number = _stage.fullScreenHeight > 0 ? _stage.fullScreenHeight : _stage.stageHeight;
         _scale = Math.max(1.0, Math.min(screenW, screenH) / 600);
         if(_scale > 2.5) { _scale = 2.5; }
         if(_scale < 1.0) { _scale = 1.0; }

         PANEL_WIDTH = int(400 * _scale);
         TITLE_HEIGHT = int(30 * _scale);
         LOG_HEIGHT = int(220 * _scale);
         PERF_PANEL_WIDTH = int(200 * _scale);
         PERF_TITLE_HEIGHT = int(22 * _scale);
         PERF_BODY_HEIGHT = int(140 * _scale);
         GRAPH_WIDTH = int(60 * _scale);
         GRAPH_HEIGHT = int(40 * _scale);

         var logFontSize:int = int(12 * _scale);
         var titleFontSize:int = int(14 * _scale);
         var perfTitleFontSize:int = int(12 * _scale);
         var perfFontSize:int = int(10 * _scale);

         _fmtInfo = new TextFormat("_sans",logFontSize,65280);
         _fmtError = new TextFormat("_sans",logFontSize,16729156);
         _createPanel();
         _createPerfPanel();
         param1.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,_onUncaughtError);
         _stage.addEventListener(Event.ENTER_FRAME,_onEnterFrame);
      }
      
      public static function addChild(param1:DisplayObject) : void
      {
         if(_stage)
         {
            _stage.addChild(param1);
         }
      }
      
      public static function runScriect(param1:Stage, param2:Function) : void
      {
         var _keyIndex:int;
         var _successed:Boolean;
         var stage:Stage = param1;
         var success:Function = param2;
         var _scriect:Array = [KyoKeyCode.P,KyoKeyCode.L,KyoKeyCode.A,KyoKeyCode.Y];
         stage.addEventListener("keyDown",function(param1:KeyboardEvent):void
         {
            if(_successed)
            {
               return;
            }
            if(param1.keyCode == _scriect[_keyIndex].code)
            {
               ++_keyIndex;
               if(_keyIndex >= _scriect.length)
               {
                  _successed = true;
                  success();
               }
            }
            else
            {
               _keyIndex = 0;
            }
         },false,0,true);
      }
      
      private static function _createPanel() : void
      {
         if(!_stage)
         {
            return;
         }
         _panel = new Sprite();
         _panel.x = int(10 * _scale);
         _panel.y = int(_stage.stageHeight * 0.15);
         _panel.graphics.beginFill(0,0.85);
         _panel.graphics.drawRect(0,0,PANEL_WIDTH,TITLE_HEIGHT + LOG_HEIGHT);
         _panel.graphics.endFill();
         _titleBar = new Sprite();
         _titleBar.graphics.beginFill(2236962);
         _titleBar.graphics.drawRect(0,0,PANEL_WIDTH,TITLE_HEIGHT);
         _titleBar.graphics.endFill();
         _panel.addChild(_titleBar);
         var titleFmt:TextFormat = new TextFormat("_sans",int(14 * _scale),13421772,true);
         var titleTf:TextField = new TextField();
         titleTf.defaultTextFormat = titleFmt;
         titleTf.selectable = false;
         titleTf.text = "DEBUG LOG";
         titleTf.width = PANEL_WIDTH - int(10 * _scale);
         titleTf.height = TITLE_HEIGHT;
         titleTf.x = int(5 * _scale);
         titleTf.y = int(5 * _scale);
         _titleBar.addChild(titleTf);
         var cbSize:int = int(14 * _scale);
         var logCloseBtn:Sprite = new Sprite();
         logCloseBtn.x = PANEL_WIDTH - int(18 * _scale);
         logCloseBtn.y = int((TITLE_HEIGHT - cbSize) / 2);
         logCloseBtn.graphics.beginFill(0x00AA00);
         logCloseBtn.graphics.drawRect(0,0,cbSize,cbSize);
         logCloseBtn.graphics.endFill();
         logCloseBtn.addEventListener(MouseEvent.CLICK,_toggleLogBody);
         _titleBar.addChild(logCloseBtn);
         _logContainer = new Sprite();
         _logContainer.x = 0;
         _logContainer.y = TITLE_HEIGHT;
         _logContainer.scrollRect = new Rectangle(0,0,PANEL_WIDTH,LOG_HEIGHT);
         _panel.addChild(_logContainer);
         _logTf = new TextField();
         _logTf.defaultTextFormat = _fmtInfo;
         _logTf.selectable = true;
         _logTf.mouseEnabled = true;
         _logTf.wordWrap = true;
         _logTf.multiline = true;
         _logTf.width = PANEL_WIDTH - int(10 * _scale);
         _logTf.height = LOG_HEIGHT;
         _logTf.x = int(5 * _scale);
         _logTf.y = int(2 * _scale);
         _logContainer.addChild(_logTf);
         _titleBar.addEventListener(MouseEvent.MOUSE_DOWN,_onDragStart);
         _stage.addEventListener(MouseEvent.MOUSE_UP,_onDragEnd);
         _stage.addChild(_panel);
      }
      
      private static function _createPerfPanel() : void
      {
         if(!_stage)
         {
            return;
         }
         _perfPanel = new Sprite();
         _perfPanel.x = int(10 * _scale);
         _perfPanel.y = TITLE_HEIGHT + LOG_HEIGHT + int(55 * _scale);
         _perfPanel.graphics.beginFill(0,0.85);
         _perfPanel.graphics.drawRect(0,0,PERF_PANEL_WIDTH,PERF_TITLE_HEIGHT + PERF_BODY_HEIGHT);
         _perfPanel.graphics.endFill();
         _perfTitleBar = new Sprite();
         _perfTitleBar.graphics.beginFill(3355443);
         _perfTitleBar.graphics.drawRect(0,0,PERF_PANEL_WIDTH,PERF_TITLE_HEIGHT);
         _perfTitleBar.graphics.endFill();
         var titleFmt:TextFormat = new TextFormat("_sans",int(12 * _scale),13421772,true);
         var titleTf:TextField = new TextField();
         titleTf.defaultTextFormat = titleFmt;
         titleTf.selectable = false;
         titleTf.text = "PERF MONITOR";
         titleTf.width = int(150 * _scale);
         titleTf.height = PERF_TITLE_HEIGHT;
         titleTf.x = int(5 * _scale);
         titleTf.y = int(3 * _scale);
         _perfTitleBar.addChild(titleTf);
         var cbSize:int = int(14 * _scale);
         var closeBtn:Sprite = new Sprite();
         closeBtn.x = PERF_PANEL_WIDTH - int(18 * _scale);
         closeBtn.y = int(4 * _scale);
         closeBtn.graphics.beginFill(10027008);
         closeBtn.graphics.drawRect(0,0,cbSize,cbSize);
         closeBtn.graphics.endFill();
         _perfTitleBar.addChild(closeBtn);
         closeBtn.addEventListener(MouseEvent.CLICK,_togglePerfBody);
         _perfPanel.addChild(_perfTitleBar);
         _perfTf = new TextField();
         _perfTf.defaultTextFormat = new TextFormat("_sans",int(10 * _scale),65280);
         _perfTf.selectable = false;
         _perfTf.wordWrap = false;
         _perfTf.multiline = true;
         _perfTf.width = PERF_PANEL_WIDTH - int(10 * _scale);
         _perfTf.height = PERF_BODY_HEIGHT;
         _perfTf.x = int(5 * _scale);
         _perfTf.y = PERF_TITLE_HEIGHT + int(2 * _scale);
         _perfPanel.addChild(_perfTf);
         _perfFpsBmd = new BitmapData(GRAPH_WIDTH,GRAPH_HEIGHT,true,0);
         _perfFpsGraph = new Bitmap(_perfFpsBmd);
         _perfFpsGraph.x = PERF_PANEL_WIDTH - GRAPH_WIDTH - int(5 * _scale);
         _perfFpsGraph.y = PERF_TITLE_HEIGHT + int(2 * _scale);
         _perfPanel.addChild(_perfFpsGraph);
         _perfMemBmd = new BitmapData(GRAPH_WIDTH,GRAPH_HEIGHT,true,0);
         _perfMemGraph = new Bitmap(_perfMemBmd);
         _perfMemGraph.x = PERF_PANEL_WIDTH - GRAPH_WIDTH - int(5 * _scale);
         _perfMemGraph.y = PERF_TITLE_HEIGHT + GRAPH_HEIGHT + int(4 * _scale);
         _perfPanel.addChild(_perfMemGraph);
         _perfTitleBar.addEventListener(MouseEvent.MOUSE_DOWN,_onPerfDragStart);
         _stage.addEventListener(MouseEvent.MOUSE_UP,_onPerfDragEnd);
         _stage.addChild(_perfPanel);
      }
      
      private static function _toggleLogBody(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         _logBodyVisible = !_logBodyVisible;
         _logContainer.visible = _logBodyVisible;
         var btn:Sprite = param1.currentTarget as Sprite;
         if(_logBodyVisible)
         {
            _panel.graphics.clear();
            _panel.graphics.beginFill(0,0.85);
            _panel.graphics.drawRect(0,0,PANEL_WIDTH,TITLE_HEIGHT + LOG_HEIGHT);
            _panel.graphics.endFill();
            if(btn) { btn.graphics.clear(); btn.graphics.beginFill(0x00AA00); btn.graphics.drawRect(0,0,btn.width,btn.height); btn.graphics.endFill(); }
         }
         else
         {
            _panel.graphics.clear();
            _panel.graphics.beginFill(0,0.85);
            _panel.graphics.drawRect(0,0,PANEL_WIDTH,TITLE_HEIGHT);
            _panel.graphics.endFill();
            if(btn) { btn.graphics.clear(); btn.graphics.beginFill(0xCC0000); btn.graphics.drawRect(0,0,btn.width,btn.height); btn.graphics.endFill(); }
         }
      }

      private static function _togglePerfBody(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         _perfBodyVisible = !_perfBodyVisible;
         _perfTf.visible = _perfBodyVisible;
         _perfFpsGraph.visible = _perfBodyVisible;
         _perfMemGraph.visible = _perfBodyVisible;
         if(_perfBodyVisible)
         {
            _perfPanel.graphics.clear();
            _perfPanel.graphics.beginFill(0,0.85);
            _perfPanel.graphics.drawRect(0,0,PERF_PANEL_WIDTH,PERF_TITLE_HEIGHT + PERF_BODY_HEIGHT);
            _perfPanel.graphics.endFill();
         }
         else
         {
            _perfPanel.graphics.clear();
            _perfPanel.graphics.beginFill(0,0.85);
            _perfPanel.graphics.drawRect(0,0,PERF_PANEL_WIDTH,PERF_TITLE_HEIGHT);
            _perfPanel.graphics.endFill();
         }
      }
      
      private static function _onPerfDragStart(e:MouseEvent) : void
      {
         _dragOffsetX = _perfPanel.mouseX;
         _dragOffsetY = _perfPanel.mouseY;
         _stage.addEventListener(MouseEvent.MOUSE_MOVE,_onPerfDrag);
      }
      
      private static function _onPerfDrag(e:MouseEvent) : void
      {
         _perfPanel.x = _stage.mouseX - _dragOffsetX;
         _perfPanel.y = _stage.mouseY - _dragOffsetY;
      }
      
      private static function _onPerfDragEnd(e:MouseEvent) : void
      {
         _stage.removeEventListener(MouseEvent.MOUSE_MOVE,_onPerfDrag);
      }
      
      private static function _updatePerfMonitor() : void
      {
         var elapsed:int;
         var mem:Number;
         var memStr:String;
         var info:String;
         var mode:int;
         var modeName:String;
         var gc:*;
         var fighter1:*;
         var fighter2:*;
         var f1:FighterMain;
         var f2:FighterMain;
         var now:int = getTimer();
         if(_lastPerfTimer == 0)
         {
            _lastPerfTimer = now;
            return;
         }
         elapsed = now - _lastPerfTimer;
         if(elapsed <= 0)
         {
            return;
         }
         _lastPerfTimer = now;
         _fpsCurrent = 1000 * _perfUpdateInterval / elapsed;
         if(_fpsCurrent < _fpsMin)
         {
            _fpsMin = _fpsCurrent;
         }
         if(_fpsCurrent > _fpsMax)
         {
            _fpsMax = _fpsCurrent;
         }
         _fpsAccum += _fpsCurrent;
         ++_fpsSampleCount;
         _fpsAvg = _fpsAccum / _fpsSampleCount;
         _drawFpsGraph();
         _drawMemGraph();
         mem = System.totalMemory;
         memStr = _byteToString(mem);
         info = "";
         info += "FPS: " + _fpsCurrent.toFixed(1);
         info += "  AVG: " + _fpsAvg.toFixed(1);
         info += "  MIN: " + _fpsMin.toFixed(1);
         info += "  MAX: " + _fpsMax.toFixed(1) + "\n";
         info += "MEM: " + memStr + "\n";
         info += "--------------------------------\n";
         try
         {
            mode = GameMode.currentMode;
            modeName = _getModeName(mode);
            info += "MODE: " + modeName + " (" + mode + ")\n";
            gc = GameCtrl.I;
            if(gc && gc.gameState)
            {
               fighter1 = gc.gameRunData.p1FighterGroup;
               fighter2 = gc.gameRunData.p2FighterGroup;
               if(fighter1 && fighter1.currentFighter)
               {
                  f1 = fighter1.currentFighter;
                  info += "P1: " + (f1.data ? f1.data.id : "??") + " HP:" + f1.hp.toFixed(0) + "/" + f1.hpMax.toFixed(0);
                  info += " QI:" + f1.qi.toFixed(0) + " ST:" + f1.actionState + "\n";
                  info += "    x:" + f1.x.toFixed(0) + " y:" + f1.y.toFixed(0) + " dir:" + f1.direct + "\n";
               }
               if(fighter2 && fighter2.currentFighter)
               {
                  f2 = fighter2.currentFighter;
                  info += "P2: " + (f2.data ? f2.data.id : "??") + " HP:" + f2.hp.toFixed(0) + "/" + f2.hpMax.toFixed(0);
                  info += " QI:" + f2.qi.toFixed(0) + " ST:" + f2.actionState + "\n";
                  info += "    x:" + f2.x.toFixed(0) + " y:" + f2.y.toFixed(0) + " dir:" + f2.direct + "\n";
               }
            }
         }
         catch(e:Error)
         {
            info += "(waiting for game...)\n";
         }
         info += "--------------------------------\n";
         info += "VER: " + "V3.3" + "\n";
         info += "STAGE FPS: " + _stage.frameRate;
         _perfTf.text = info;
      }
      
      private static function _drawFpsGraph() : void
      {
         if(!_perfFpsBmd)
         {
            return;
         }
         _perfFpsBmd.scroll(-1,0);
         var maxFps:Number = _stage ? _stage.frameRate : 60;
         var ratio:Number = _fpsCurrent / maxFps;
         if(ratio > 1)
         {
            ratio = 1;
         }
         if(ratio < 0)
         {
            ratio = 0;
         }
         var barH:int = int(ratio * GRAPH_HEIGHT);
         var i:int = 0;
         while(i < GRAPH_HEIGHT)
         {
            _perfFpsBmd.setPixel32(GRAPH_WIDTH - 1,i,855638016);
            i++;
         }
         if(ratio > 0.8)
         {
            var color:uint = 4278255360;
         }
         else if(ratio > 0.5)
         {
            color = 4294967040;
         }
         else
         {
            color = 4294901760;
         }
         i = GRAPH_HEIGHT - barH;
         while(i < GRAPH_HEIGHT)
         {
            _perfFpsBmd.setPixel32(GRAPH_WIDTH - 1,i,color);
            i++;
         }
      }
      
      private static function _drawMemGraph() : void
      {
         if(!_perfMemBmd)
         {
            return;
         }
         _perfMemBmd.scroll(-1,0);
         var maxMem:Number = 300 * 1024 * 1024;
         var mem:Number = System.totalMemory;
         var ratio:Number = mem / maxMem;
         if(ratio > 1)
         {
            ratio = 1;
         }
         if(ratio < 0)
         {
            ratio = 0;
         }
         var barH:int = int(ratio * GRAPH_HEIGHT);
         var i:int = 0;
         while(i < GRAPH_HEIGHT)
         {
            _perfMemBmd.setPixel32(GRAPH_WIDTH - 1,i,855638016);
            i++;
         }
         i = GRAPH_HEIGHT - barH;
         while(i < GRAPH_HEIGHT)
         {
            _perfMemBmd.setPixel32(GRAPH_WIDTH - 1,i,4278233855);
            i++;
         }
      }
      
      private static function _byteToString(param1:Number) : String
      {
         if(param1 < 1024)
         {
            return param1.toFixed(0) + " B";
         }
         if(param1 < 1024 * 1024)
         {
            return (param1 / 1024).toFixed(1) + " KB";
         }
         return (param1 / (1024 * 1024)).toFixed(2) + " MB";
      }
      
      private static function _getModeName(param1:int) : String
      {
         switch(param1)
         {
            case 10:
               return "TEAM_ACRADE";
            case 11:
               return "TEAM_VS_PPL";
            case 12:
               return "TEAM_VS_CPU";
            case 13:
               return "TEAM_WATCH";
            case 14:
               return "TEAM_DUO";
            case 15:
               return "TEAM_DUO_WATCH";
            case 20:
               return "SINGLE_ACRADE";
            case 21:
               return "SINGLE_VS_PPL";
            case 22:
               return "SINGLE_VS_CPU";
            case 23:
               return "SINGLE_WATCH";
            case 24:
               return "SINGLE_VS_DUO";
            case 25:
               return "SINGLE_VS_DUO_W";
            case 30:
               return "SURVIVOR";
            case 40:
               return "TRAINING";
            default:
               return "UNKNOWN";
         }
      }
      
      private static function _onDragStart(e:MouseEvent) : void
      {
         _dragOffsetX = _panel.mouseX;
         _dragOffsetY = _panel.mouseY;
         _stage.addEventListener(MouseEvent.MOUSE_MOVE,_onDrag);
      }
      
      private static function _onDrag(e:MouseEvent) : void
      {
         _panel.x = _stage.mouseX - _dragOffsetX;
         _panel.y = _stage.mouseY - _dragOffsetY;
      }
      
      private static function _onDragEnd(e:MouseEvent) : void
      {
         _stage.removeEventListener(MouseEvent.MOUSE_MOVE,_onDrag);
      }
      
      private static function _queueLog(message:String, isError:Boolean) : void
      {
         _logQueue.push({
            "msg":message,
            "isError":isError
         });
         if(_logQueue.length > MAX_QUEUE_SIZE)
         {
            _logQueue.shift();
         }
      }
      
      private static function _onEnterFrame(e:Event) : void
      {
         ++_frameCounter;
         if(_frameCounter >= FLUSH_INTERVAL && _logQueue.length > 0)
         {
            for each(var item in _logQueue)
            {
               var time:String = _getTimeStamp();
               var line:String = time + " " + item.msg + "\n";
               _logTf.appendText(line);
               if(item.isError)
               {
                  _logTf.setTextFormat(_fmtError,_logTf.length - line.length,_logTf.length);
               }
               else
               {
                  _logTf.setTextFormat(_fmtInfo,_logTf.length - line.length,_logTf.length);
               }
            }
            _logQueue.length = 0;
            if(_logTf.textHeight > LOG_HEIGHT)
            {
               var offset:Number = _logTf.textHeight - LOG_HEIGHT;
               _logContainer.scrollRect = new Rectangle(0,offset,PANEL_WIDTH,LOG_HEIGHT);
               _logTf.scrollV = _logTf.maxScrollV;
            }
         }
         if(_perfPanel)
         {
            ++_perfFrameCount;
            if(_perfFrameCount >= _perfUpdateInterval)
            {
               _updatePerfMonitor();
               _perfFrameCount = 0;
               _lastPerfTimer = getTimer();
            }
         }
         if(_frameCounter >= FLUSH_INTERVAL)
         {
            _frameCounter = 0;
         }
      }
      
      private static function _getTimeStamp() : String
      {
         var d:Date = new Date();
         var h:String = ("0" + d.hours).substr(-2);
         var m:String = ("0" + d.minutes).substr(-2);
         var s:String = ("0" + d.seconds).substr(-2);
         return "[" + h + ":" + m + ":" + s + "]";
      }
      
      private static function _onUncaughtError(e:UncaughtErrorEvent) : void
      {
         if(e.error is Error)
         {
            var msg:String = (e.error as Error).getStackTrace();
         }
         else
         {
            msg = e.error.toString();
         }
         _queueLog("[UNCAUGHT] " + msg,true);
      }
   }
}

