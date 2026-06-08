package net.play5d.kyo.utils
{
   import flash.display.*;
   import flash.events.*;
   
   public function setFrameOut(param1:Function, param2:int, param3:DisplayObject = null) : void
   {
      var ii:int = 0;
      var _mc:DisplayObject = null;
      var mx:int = 0;
      var onEnterframe:Function = null;
      _mc = null;
      mx = 0;
      onEnterframe = null;
      var fun:Function = param1;
      var frame:int = param2;
      var mc:DisplayObject = param3;
      onEnterframe = function(param1:Event):void
      {
         if(++ii > mx)
         {
            fun();
            _mc.removeEventListener(Event.ENTER_FRAME,onEnterframe);
            _mc = null;
         }
      };
      _mc = mc;
      _mc ||= new Sprite();
      _mc.addEventListener(Event.ENTER_FRAME,onEnterframe);
      ii = 0;
      mx = frame;
   }
}

