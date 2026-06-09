import net.play5d.game.bvn.GameConfig;
import net.play5d.game.bvn.state.SelectFighterStage;
import net.play5d.game.bvn.Debugger;
import flash.system.Capabilities;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.events.Event;

var isMobile:Boolean = Capabilities.version.indexOf("AND") != -1;

Debugger.log("[Pagination] init — isMobile:", isMobile, "TOUCH_MODE:", GameConfig.TOUCH_MODE);

// 从 SelectFighterStage 读取（延迟一帧等 buildList 初始化）
var pageHeight:Number = SelectFighterStage.PAGE_HEIGHT;
var totalPages:int = SelectFighterStage.TOTAL_PAGES;

Debugger.log("[Pagination] pageHeight:", pageHeight, "totalPages:", totalPages);

var arr: Array = [0];
for (var i: int = 1; i < totalPages; i++) {
    arr.push(i * -pageHeight);
}
Debugger.log("[Pagination] page positions:", arr);

// ---- 通用翻页逻辑 ----
function goNext():void {
    if (!enable) { Debugger.log("[Pagination] goNext BLOCKED (animating)"); return; }
    Debugger.log("[Pagination] goNext from page at bg.y=", bg.y);
    for (select = 0; select < arr.length; select++) {
        if (int(Math.abs(bg.y)) + pageHeight == int(Math.abs(arr[select]))) {
            Debugger.log("[Pagination] goNext target:", arr[select]);
            addEventListener(Event.ENTER_FRAME, Animate);
            return;
        }
    }
    Debugger.log("[Pagination] goNext: already at last page");
}

function goPrev():void {
    if (!enable) { Debugger.log("[Pagination] goPrev BLOCKED (animating)"); return; }
    Debugger.log("[Pagination] goPrev from page at bg.y=", bg.y);
    for (select = arr.length - 1; select >= 0; select--) {
        if (int(Math.abs(bg.y)) - pageHeight == int(Math.abs(arr[select]))) {
            Debugger.log("[Pagination] goPrev target:", arr[select]);
            addEventListener(Event.ENTER_FRAME, Animate);
            return;
        }
    }
    Debugger.log("[Pagination] goPrev: already at first page");
}

// ---- 键盘（PC） ----
stage.addEventListener(KeyboardEvent.KEY_DOWN, pagKeyHandler);
function pagKeyHandler(evt:KeyboardEvent):void {
    if (evt.keyCode == 69 || evt.keyCode == 107) { goNext(); }
    if (evt.keyCode == 81 || evt.keyCode == 109) { goPrev(); }
}

// ---- PC：鼠标 + 滚轮 ----
if (!isMobile) {
    Debugger.log("[Pagination] PC mode: MouseEvent.CLICK + MOUSE_WHEEL");
    down.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { Debugger.log("[Pagination] down CLICK"); goNext(); });
    up.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { Debugger.log("[Pagination] up CLICK"); goPrev(); });

    stage.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
    function onWheel(e:MouseEvent):void {
        if (SelectFighterStage._selectState == 1) return;
        if (e.delta > 0) { Debugger.log("[Pagination] wheel UP (delta=" + e.delta + ")"); goPrev(); }
        else if (e.delta < 0) { Debugger.log("[Pagination] wheel DOWN (delta=" + e.delta + ")"); goNext(); }
    }
}

// ---- 手机：TouchTap ----
if (isMobile) {
    Debugger.log("[Pagination] Mobile mode: TouchEvent.TOUCH_TAP");

    down.addEventListener(TouchEvent.TOUCH_TAP, onDownTap);
    function onDownTap(e:TouchEvent):void {
        Debugger.log("[Pagination] down TOUCH_TAP — stageX:", e.stageX, "stageY:", e.stageY);
        goNext();
    }

    up.addEventListener(TouchEvent.TOUCH_TAP, onUpTap);
    function onUpTap(e:TouchEvent):void {
        Debugger.log("[Pagination] up TOUCH_TAP — stageX:", e.stageX, "stageY:", e.stageY);
        goPrev();
    }

    Debugger.log("[Pagination] up visible:", up.visible, "down visible:", down.visible);
    Debugger.log("[Pagination] up xy:", up.x, up.y, "down xy:", down.x, down.y);
}

// ---- 翻页动画 ----
function Animate(e:Event):void {
    if (bg.y > arr[select]) {
        enable = false;
        bg.y -= speed;
    } else if (bg.y < arr[select]) {
        enable = false;
        bg.y += speed;
    } else {
        enable = true;
        bg.y = arr[select];
        Debugger.log("[Pagination] animation done, bg.y:", bg.y);
        removeEventListener(Event.ENTER_FRAME, Animate);
    }
}

// ---- 辅助界面时隐藏翻页按钮 ----
addEventListener(Event.ENTER_FRAME, clear);
function clear(e:Event):void {
    if (SelectFighterStage._selectState == 1) {
        if (up.visible || down.visible) {
            Debugger.log("[Pagination] assist mode → hide buttons");
        }
        bg.y = 0;
        up.visible = false;
        down.visible = false;
    } else {
        if (!up.visible || !down.visible) {
            Debugger.log("[Pagination] normal mode → show buttons");
        }
        up.visible = true;
        down.visible = true;
    }
}

Debugger.log("[Pagination] setup complete — waiting for input...");
stop();
