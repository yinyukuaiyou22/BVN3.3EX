package net.play5d.kyo.loader
{
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.media.Sound;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   
   public class KyoSoundLoader
   {
      
      private var _urls:Array;
      
      private var _curUrl:String;
      
      private var _soundObj:Object = {};
      
      private var _loadBack:Function;
      
      private var _loadProcess:Function;
      
      private var _loadLength:int;
      
      public function KyoSoundLoader()
      {
         super();
      }
      
      public function unload() : void
      {
         if(_soundObj)
         {
            for each(var _loc1_ in _soundObj)
            {
               _loc1_.close();
            }
            _soundObj = {};
         }
      }
      
      public function loadSounds(param1:Array, param2:Function = null, param3:Function = null) : void
      {
         _loadBack = param2;
         _loadProcess = param3;
         _urls = param1.concat();
         _loadLength = param1.length;
         loadNext();
      }
      
      public function getSound(param1:String) : Sound
      {
         var _loc2_:String = null;
         if(_soundObj[param1])
         {
            return _soundObj[param1];
         }
         for(var _loc3_ in _soundObj)
         {
            _loc2_ = _loc3_.substr(_loc3_.lastIndexOf("/") + 1);
            _loc2_ = _loc2_.substr(0,_loc2_.lastIndexOf("."));
            if(_loc2_ == param1)
            {
               return _soundObj[_loc3_];
            }
         }
         return null;
      }
      
      public function addSound(param1:String, param2:Sound) : void
      {
         _soundObj[param1] = param2;
      }
      
      private function loadNext() : void
      {
         var _loc2_:String = _urls.shift();
         _curUrl = _loc2_;
         var _loc1_:Sound = new Sound(new URLRequest(_loc2_));
         _loc1_.addEventListener("complete",loadCom);
         _loc1_.addEventListener("progress",loadProcess);
         _loc1_.addEventListener("ioError",loadErr);
      }
      
      private function loadProcess(param1:ProgressEvent) : void
      {
         var _loc4_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc2_:Number = NaN;
         if(_loadProcess != null)
         {
            _loc4_ = param1.bytesLoaded / param1.bytesTotal;
            _loc3_ = _loadLength - _urls.length - 1 + _loc4_;
            _loc2_ = _loc3_ / _loadLength;
            _loadProcess(_loc2_);
         }
      }
      
      private function loadCom(param1:Event) : void
      {
         var _loc2_:Sound = param1.currentTarget as Sound;
         _loc2_.removeEventListener("complete",loadCom);
         _loc2_.removeEventListener("ioError",loadErr);
         _loc2_.removeEventListener("progress",loadProcess);
         _soundObj[_curUrl] = _loc2_;
         if(_urls.length < 1)
         {
            loadFin();
         }
         else
         {
            loadNext();
         }
      }
      
      private function loadErr(param1:IOErrorEvent) : void
      {
         var _loc2_:Sound = param1.currentTarget as Sound;
         _loc2_.removeEventListener("complete",loadCom);
         _loc2_.removeEventListener("ioError",loadErr);
         _loc2_.removeEventListener("progress",loadProcess);
         trace("KyoSoundLoader.loadErr :: 加载声音失败 : " + _loc2_.url);
         if(_urls.length < 1)
         {
            loadFin();
         }
         else
         {
            loadNext();
         }
      }
      
      private function loadFin() : void
      {
         if(_loadBack != null)
         {
            _loadBack();
            _loadBack = null;
         }
      }
      
      public function loadPath(param1:String, param2:String, param3:Function = null) : void
      {
         var path:String = param1;
         var listXML:String = param2;
         var back:Function = param3;
         var l:URLLoader = new URLLoader(new URLRequest(path + "/" + listXML));
         l.addEventListener("complete",function(param1:Event):void
         {
            var _loc3_:XML = new XML(l.data);
            var _loc2_:Array = [];
            for each(var _loc4_ in _loc3_.children())
            {
               _loc2_.push(path + "/" + _loc4_.toString());
            }
            loadSounds(_loc2_,back);
         });
      }
   }
}

