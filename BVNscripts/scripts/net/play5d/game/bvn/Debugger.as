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
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.geom.Rectangle;
   import flash.system.System;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.getTimer;
   import net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl;
   import net.play5d.game.bvn.data.GameMode;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.mob.input.*;
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

      private static var _logFile:File;
      
      private static var _logStream:FileStream;
      
      private static var _fileLogBuffer:String = "";
      
      private static var _hasEnterFrame:Boolean = false;

      private static const FILE_FLUSH_FRAMES:int = 5;  // write to file every N frames

      private static const MAX_QUEUE_SIZE:int = 300;

      private static const FLUSH_INTERVAL:int = 3;

       private static var _frameCounter:int = 0;

       // 批次6.8：标签过滤系统 — null = 不启用过滤（全部通过）；Object = 仅允许指定 tag 通过
       // 用法：Debugger.setTagFilter("SelectStage", "SetBtn", "Menu") 只输出这几个标签的 log
       private static var _enabledTags:Object = null;

       // 批次6.8：全局默认 tag（当调用 log(...) 不带 tag 时用）
       public static var defaultTag:String = "";

       public static const DRAW_AREA:Boolean = false;

      public static const SAFE_MODE:Boolean = false;

      public static const HIDE_MAP:Boolean = false;

      public static const HIDE_HITEFFECT:Boolean = false;

      /**
       * 2026-10-21：受击/灵爆相关的逐帧诊断日志总开关，默认 false。
       * 背景：Debugger.log() 每次调用都会 writeUTFBytes + flush（同步写 flash），
       * 受击期原先每帧 4 条、命中判定每帧 N 条，手机上光日志就能吃掉一大截帧时间。
       * 复现「受击灵爆卡死」时把它改成 true，再按下面的标记读日志：
       *   【受击进入】【渲染层受击】【灵压爆发】【灵压爆发检查】【僵直递减】【僵直归零】【判定时序】
       * 低频判据（【安全网】【钢体看门狗】）不受此开关控制，始终输出。
       */
      public static var DIAG_HURT:Boolean = false;

      // 批次 6.14：构建版本号（防止看串日志 / 排查"日志与 SWF 不匹配"）
      // 规范：<项目>-<批次>-<日期>-<时间>。
      // - 项目：固定 BVN-3.3EX
      // - 批次：当前批次号，重要修复时递增（手改）
      // - 日期：YYYY-MM-DD 格式（每次编译手动或脚本更新）
      // - 时间：HHMM 格式（每次编译手动或脚本更新）
      // 调用方：build.bat 可在编译前用 sed 替换 @BUILD_TAG@ 占位符。
      // 读取方：bvn_debug.log 第一行（=== BVN Debug Log ===）之后第二行即为 BUILD 行。
      public static const BUILD_TAG:String = "BVN-3.3EX-batch6.14-2026-10-23-0804";

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
      
       // 批次6.8：标签过滤判断。tag 为 null/空/_enabledTags 为 null 时一律通过。
       private static function _isTagEnabled(tag:String) : Boolean
       {
          if(_enabledTags == null) return true;
          if(tag == null || tag.length == 0) return false;
          return _enabledTags[tag] === true;
       }

       // 批次6.16：Error 对象自动展开堆栈。Debugger.log/error/warn 传 Error 对象时，
       // 自动附加 getStackTrace()（-debug=true 编译下有效），便于定位运行时异常来源。
       // 原写法只传 err.message 拿不到异常栈。
       private static function _flattenArgs(rest:Array) : String
       {
          var parts:Array = [];
          var i:int = 0;
          var arg:* = null;
          var e:Error = null;
          var st:String = null;
          while(i < rest.length)
          {
             arg = rest[i];
             if(arg == null)
             {
                parts.push("");
             }
             else if(arg is Error)
             {
                e = arg as Error;
                st = e.getStackTrace();
                parts.push(e.toString() + (st != null && st.length > 0 ? "\n" + st : ""));
             }
             else
             {
                parts.push(String(arg));
             }
             i++;
          }
          return parts.join(" ");
       }

       // 批次6.8：设置/清除标签过滤。传 null 清除（全部通过），传 "*" 等同 null。
       public static function setTagFilter(... tags) : void
       {
          if(tags == null || tags.length == 0)
          {
             _enabledTags = null;
             return;
          }
          if(tags.length == 1 && (tags[0] == null || tags[0] == "*" || tags[0] == ""))
          {
             _enabledTags = null;
             return;
          }
          _enabledTags = {};
          var i:int = 0;
          while(i < tags.length)
          {
             _enabledTags[String(tags[i])] = true;
             i++;
          }
       }

       public static function clearTagFilter() : void
       {
          _enabledTags = null;
       }

       public static function log(... rest) : void
       {
          var msg:String = _flattenArgs(rest);
          if(!msg || msg.length == 0)
          {
             return;
          }
          // 批次6.8：若第 1 参是合法 tag 且后面还有内容则剥离为 tag 前缀
          var tag:String = defaultTag;
          if(rest.length >= 2 && rest[0] is String)
          {
             var t:String = rest[0] as String;
             if(t.charAt(0) == "[" && t.charAt(t.length - 1) == "]")
             {
                tag = t.substr(1, t.length - 2);
                var tail:Array = rest.slice(1);
                msg = tag + " " + _flattenArgs(tail);
             }
          }
          if(!_isTagEnabled(tag))
          {
             return;
          }
                   trace(msg);
         // 文件日志：立即写入并 flush，避免主线程挂死时 ENTER_FRAME 不再触发而丢失缓冲日志
         if(_logStream)
         {
            try {
               _logStream.writeUTFBytes(_getTimeStamp() + " " + msg + "\n");
               _logStream.flush();
            } catch(e:Error) { }
         }
          if(!_debugEnabled)
          {
             return;
          }
          _queueLog(msg,false);
       }

       // 批次6.16：折叠日志。高频"正常路径"日志只累加计数，flushFold() 时按组输出一行汇总。
       // 背景：外部资源探测（ANEFileReader.exists / [EXT-RESOLVE]）、选中态刷新（[SelectedUI] setFighter）、
       // 按键边沿（INPUT/KEY_DOWN）会按文件、按帧逐条刷屏，把真正的问题淹没。
       // **失败与错误请继续用 error()/warn()**（或保留原样），它们每条单独输出、不参与折叠。
       private static var _foldCount:Object = {};
       private static var _foldLast:Object = {};

       public static function logFold(param1:String, param2:* = null) : void
       {
          var key:String = param1 == null || param1 == "" ? "?" : param1;
          _foldCount[key] = int(_foldCount[key]) + 1;
          if(param2 != null && param2 != "")
          {
             _foldLast[key] = param2;
          }
       }

       /** 输出所有折叠组的汇总（每组一行）并清零。在加载完成 / 场景切换等自然边界调用。 */
       public static function flushFold() : void
       {
          var key:String = null;
          var line:String = null;
          var any:Boolean = false;
          for(key in _foldCount)
          {
             any = true;
             line = "[FOLD] " + key + " x" + _foldCount[key] + (_foldLast[key] == null ? "" : " last=" + _foldLast[key]);
             trace(line);
             if(_logStream)
             {
                _fileLogBuffer += _getTimeStamp() + " " + line + "\n";
             }
          }
          if(any)
          {
             _foldCount = {};
             _foldLast = {};
          }
       }

       // 批次6.8：WARN 级别日志。带 [WARN] 前缀 + 黄色显示
       public static function warn(... rest) : void
       {
          var msg:String = "[WARN] " + _flattenArgs(rest);
          if(!_isTagEnabled(defaultTag))
          {
             return;
          }
          trace(msg);
          if(_logStream)
          {
             _fileLogBuffer += _getTimeStamp() + " " + msg + "\n";
          }
          if(!_debugEnabled)
          {
             return;
          }
          _queueLog(msg,false);
       }

       // 批次6.8：ERROR 级别日志。带 [ERROR] 前缀 + 红色显示 + 触发 onErrorMsgCall
       public static function error(... rest) : void
       {
          var msg:String = "[ERROR] " + _flattenArgs(rest);
          trace(msg);
          if(_logStream)
          {
             _fileLogBuffer += _getTimeStamp() + " " + msg + "\n";
          }
          if(!_debugEnabled)
          {
             return;
          }
          if(onErrorMsgCall != null)
          {
             onErrorMsgCall(msg);
          }
          _queueLog(msg,true);
       }

       // 保留旧 API（向兼容）：errorMsg(单字符串)
       public static function errorMsg(param1:String) : void
       {
          error(param1);
       }
      
      private static var _inited:Boolean = false;

      private static var _closeBtnSize:int = 0;

      /**
       * 仅初始化文件日志（不创建调试面板），供启动时无条件调用。
       * 日志写入应用私有目录 bvn_debug.log，不受面板开关与 logcat 屏蔽影响。
       * 读取方式（root/adb）：cat /data/data/<pkg>/<pkg>/Local Store/bvn_debug.log
       * 同时每帧轮询手柄输入变化（JOY_IN 日志）用于输入解析。
       */
      public static function initFileLog(param1:Stage) : void
      {
         if(_logStream)
         {
            return;
         }
         if(param1)
         {
            _stage = param1;
         }
         try
         {
            _logFile = File.applicationStorageDirectory.resolvePath("bvn_debug.log");
            _logStream = new FileStream();
            // 批次 6.14：使用 APPEND 模式保留历史日志 + 写入分隔符 + BUILD 标识 + 文件路径。
            // 每次启动日志结构示例：
            //   === BVN Debug Log ===
            //   === SESSION <DATE> <TIME> BUILD=<BUILD_TAG> ===
            //   initFileLog: <path>
            _logStream.open(_logFile, FileMode.APPEND);
            _logStream.writeUTFBytes("=== SESSION " + _getDateStamp() + " BUILD=" + BUILD_TAG + " ===\n");
            if(_logStream)
            {
               _logStream.writeUTFBytes("initFileLog: " + _logFile.nativePath + "\n");
            }
         }
         catch(e:Error)
         {
         }
         if(_stage && !_hasEnterFrame)
         {
            _stage.addEventListener(Event.ENTER_FRAME,_onEnterFrame);
            _hasEnterFrame = true;
         }
      }

      // 批次 6.14：会话级日期时间戳（YYYY-MM-DD HH:MM:SS），用于日志 SESSION 分隔。
      private static var _sessionTimeStamp:String;

      private static function _getDateStamp() : String
      {
         if(_sessionTimeStamp == null)
         {
            var d:Date = new Date();
            _sessionTimeStamp = d.getFullYear() + "-" +
               _pad2(d.getMonth() + 1) + "-" +
               _pad2(d.getDate()) + " " +
               _pad2(d.getHours()) + ":" +
               _pad2(d.getMinutes()) + ":" +
               _pad2(d.getSeconds());
         }
         return _sessionTimeStamp;
      }

      private static function _pad2(param1:int) : String
      {
         if(param1 < 10)
         {
            return "0" + param1;
         }
         return String(param1);
      }
      
      public static function initDebug(param1:Stage) : void
      {
         if (_inited) return;
         _inited = true;
         _stage = param1;
         _debugEnabled = true;

         // Mobile scaling: base on 480px reference for phone screens
         var screenW:Number = _stage.fullScreenWidth > 0 ? _stage.fullScreenWidth : _stage.stageWidth;
         var screenH:Number = _stage.fullScreenHeight > 0 ? _stage.fullScreenHeight : _stage.stageHeight;
         var baseDim:Number = Math.min(screenW, screenH);
         _scale = Math.max(1.0, baseDim / 480);
         if(_scale > 3.5) { _scale = 3.5; }
         if(_scale < 1.0) { _scale = 1.0; }

         PANEL_WIDTH = int(screenW * 0.45);
         TITLE_HEIGHT = int(28 * _scale);
         LOG_HEIGHT = int(screenH * 0.35);
         PERF_PANEL_WIDTH = int(200 * _scale);
         PERF_TITLE_HEIGHT = int(22 * _scale);
         PERF_BODY_HEIGHT = int(140 * _scale);
         GRAPH_WIDTH = int(60 * _scale);
         GRAPH_HEIGHT = int(40 * _scale);

         var logFontSize:int = int(12 * _scale);
         var titleFontSize:int = int(14 * _scale);
         var perfTitleFontSize:int = int(12 * _scale);
         var perfFontSize:int = int(10 * _scale);

         _closeBtnSize = int(14 * _scale);  // store for toggle redraw

         _fmtInfo = new TextFormat("_sans",logFontSize,65280);
         _fmtError = new TextFormat("_sans",logFontSize,16729156);
         _createPanel();
         _createPerfPanel();
         param1.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,_onUncaughtError);
         _stage.addEventListener(Event.ENTER_FRAME,_onEnterFrame);

         // Set up file logging — writes to app-private internal storage.
// 批次 6.14：使用 BUILD_TAG 标识 + APPEND 模式（避免覆盖历史会话日志）。
// Retrieve via: adb exec-out run-as air.com.bvn.yinyu cat /data/data/air.com.bvn.yinyu/air.com.bvn.yinyu/Local\ Store/bvn_debug.log
         try {
            _logFile = File.applicationStorageDirectory.resolvePath("bvn_debug.log");
            _logStream = new FileStream();
            _logStream.open(_logFile, FileMode.APPEND);
            _logStream.writeUTFBytes("=== SESSION " + _getDateStamp() + " BUILD=" + BUILD_TAG + " (initDebug) ===\n");
         } catch(e:Error) {}
      }

      /** Flush buffered log lines to file and close the stream. Safe to call anytime. */
      public static function flushLogFile() : void
      {
         if(_logStream && _fileLogBuffer.length > 0)
         {
            try { _logStream.writeUTFBytes(_fileLogBuffer); _fileLogBuffer = ""; _logStream.flush(); }
            catch(e:Error) {}
         }
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
         _logTf.selectable = false;
         _logTf.mouseEnabled = true;
         _logTf.wordWrap = true;
         _logTf.multiline = true;
         _logTf.width = int(PANEL_WIDTH * 0.95);
         _logTf.height = LOG_HEIGHT * 10;  // tall enough to hold all lines, scrolled by scrollRect
         _logTf.x = int(3 * _scale);
         _logTf.y = int(2 * _scale);
         _logContainer.addChild(_logTf);
         // Touch-scroll support: drag on log area scrolls content
         _logContainer.addEventListener(MouseEvent.MOUSE_DOWN, _onLogScrollStart);
         _stage.addEventListener(MouseEvent.MOUSE_UP, _onLogScrollEnd);
         _titleBar.addEventListener(MouseEvent.MOUSE_DOWN,_onDragStart);
         _stage.addEventListener(MouseEvent.MOUSE_UP,_onDragEnd);
         _stage.addChild(_panel);
      }

      private static var _logScrollStartY:Number;
      private static var _logScrollRectY:Number;
      private static var _logDragging:Boolean;

      private static function _onLogScrollStart(e:MouseEvent) : void
      {
         if(!_logContainer || !_logContainer.scrollRect) return;
         _logDragging = true;
         _logScrollStartY = e.stageY;
         _logScrollRectY = _logContainer.scrollRect.y;
         _stage.addEventListener(MouseEvent.MOUSE_MOVE, _onLogScrollMove);
         e.stopPropagation();
      }

      private static function _onLogScrollMove(e:MouseEvent) : void
      {
         if(!_logDragging || !_logContainer) return;
         var dy:Number = _logScrollStartY - e.stageY;
         var newY:Number = _logScrollRectY + dy;
         var maxY:Number = _logTf.textHeight - LOG_HEIGHT;
         if(newY < 0) newY = 0;
         if(newY > maxY) newY = maxY;
         _logContainer.scrollRect = new Rectangle(0, newY, PANEL_WIDTH, LOG_HEIGHT);
      }

      private static function _onLogScrollEnd(e:MouseEvent) : void
      {
         _logDragging = false;
         try { _stage.removeEventListener(MouseEvent.MOUSE_MOVE, _onLogScrollMove); } catch(e2:Error) {}
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
         closeBtn.addEventListener(MouseEvent.CLICK,_togglePerfBody);
         _perfTitleBar.addChild(closeBtn);
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
            if(btn) { btn.graphics.clear(); btn.graphics.beginFill(0x00AA00); btn.graphics.drawRect(0,0,_closeBtnSize,_closeBtnSize); btn.graphics.endFill(); }
         }
         else
         {
            _panel.graphics.clear();
            _panel.graphics.beginFill(0,0.85);
            _panel.graphics.drawRect(0,0,PANEL_WIDTH,TITLE_HEIGHT);
            _panel.graphics.endFill();
            if(btn) { btn.graphics.clear(); btn.graphics.beginFill(0xCC0000); btn.graphics.drawRect(0,0,_closeBtnSize,_closeBtnSize); btn.graphics.endFill(); }
         }
      }

      private static function _togglePerfBody(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         _perfBodyVisible = !_perfBodyVisible;
         _perfTf.visible = _perfBodyVisible;
         _perfFpsGraph.visible = _perfBodyVisible;
         _perfMemGraph.visible = _perfBodyVisible;
         var btn:Sprite = param1.currentTarget as Sprite;
         if(_perfBodyVisible)
         {
            _perfPanel.graphics.clear();
            _perfPanel.graphics.beginFill(0,0.85);
            _perfPanel.graphics.drawRect(0,0,PERF_PANEL_WIDTH,PERF_TITLE_HEIGHT + PERF_BODY_HEIGHT);
            _perfPanel.graphics.endFill();
            if(btn) { btn.graphics.clear(); btn.graphics.beginFill(0x00AA00); btn.graphics.drawRect(0,0,_closeBtnSize,_closeBtnSize); btn.graphics.endFill(); }
         }
         else
         {
            _perfPanel.graphics.clear();
            _perfPanel.graphics.beginFill(0,0.85);
            _perfPanel.graphics.drawRect(0,0,PERF_PANEL_WIDTH,PERF_TITLE_HEIGHT);
            _perfPanel.graphics.endFill();
            if(btn) { btn.graphics.clear(); btn.graphics.beginFill(0xCC0000); btn.graphics.drawRect(0,0,_closeBtnSize,_closeBtnSize); btn.graphics.endFill(); }
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
                  // 卡死诊断：暴露 _hurtHoldFrame / _hurtStuckFrame / isHurting（仅读取）
                  try {
                     var _mc1:* = f1.getCtrler() ? f1.getCtrler().getMcCtrl() : null;
                     if(_mc1) {
                        info += "    [受击诊断] holdFrame=" + _mc1.getHurtHoldFrame() + " stuckFrame=" + _mc1.getHurtStuckFrame() + " isHurting=" + _mc1.getIsHurting() + "\n";
                     }
                  } catch(_e1:Error) {}
               }
               if(fighter2 && fighter2.currentFighter)
               {
                  f2 = fighter2.currentFighter;
                  info += "P2: " + (f2.data ? f2.data.id : "??") + " HP:" + f2.hp.toFixed(0) + "/" + f2.hpMax.toFixed(0);
                  info += " QI:" + f2.qi.toFixed(0) + " ST:" + f2.actionState + "\n";
                  info += "    x:" + f2.x.toFixed(0) + " y:" + f2.y.toFixed(0) + " dir:" + f2.direct + "\n";
                  try {
                     var _mc2:* = f2.getCtrler() ? f2.getCtrler().getMcCtrl() : null;
                     if(_mc2) {
                        info += "    [受击诊断] holdFrame=" + _mc2.getHurtHoldFrame() + " stuckFrame=" + _mc2.getHurtStuckFrame() + " isHurting=" + _mc2.getIsHurting() + "\n";
                     }
                  } catch(_e2:Error) {}
               }
            }
         }
         catch(e:Error)
         {
            info += "(waiting for game...)\n";
         }
          info += "--------------------------------\n";
          // 手柄调试：实时显示所有激活的 control（index:id:value）
          try
          {
             var _jd:String = "";
             var _im:* = InputManager.I;
             if(_im && _im.joy_p1)
             {
                _jd = _im.joy_p1.getDeviceId();
                if(_jd) info += "JOY: " + JoySticker.getControlValuesDebug(_jd) + "\n";
                else info += "JOY: (no device)\n";
             }
          }
          catch(e2:Error) { }
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
         // 手柄输入变化轮询（仅文件日志开启时，记录 JOY_IN 按下/松开边沿）
         if(_logStream)
         {
            JoySticker.pollInputLog();
         }
         if(_frameCounter >= FLUSH_INTERVAL && _logQueue.length > 0)
         {
            for each(var item:Object in _logQueue)
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
               // Buffer for file output
               _fileLogBuffer += line;
            }
            _logQueue.length = 0;
            // Only auto-scroll to bottom if user is not currently dragging
            if(!_logDragging && _logTf.textHeight > LOG_HEIGHT)
            {
               var offset:Number = _logTf.textHeight - LOG_HEIGHT;
               _logContainer.scrollRect = new Rectangle(0, offset, PANEL_WIDTH, LOG_HEIGHT);
            }
         }
         // Flush accumulated log lines to file every FILE_FLUSH_FRAMES
         if(_logStream && (_frameCounter % FILE_FLUSH_FRAMES == 0) && _fileLogBuffer.length > 0)
         {
            try {
               _logStream.writeUTFBytes(_fileLogBuffer);
               _fileLogBuffer = "";
               _logStream.flush();
            } catch(e:Error) {}
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
      
       // 批次6.8：时间戳增强 — 加毫秒段 [HH:MM:SS.mmm] 便于精确定位帧间隔
       private static function _getTimeStamp() : String
       {
          var d:Date = new Date();
          var h:String = ("0" + d.hours).substr(-2);
          var m:String = ("0" + d.minutes).substr(-2);
          var s:String = ("0" + d.seconds).substr(-2);
          var ms:String = ("00" + d.milliseconds).substr(-3);
          return "[" + h + ":" + m + ":" + s + "." + ms + "]";
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

