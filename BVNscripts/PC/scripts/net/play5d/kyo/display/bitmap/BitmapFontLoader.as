package net.play5d.kyo.display.bitmap
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.events.Event;
   import net.play5d.kyo.loader.BitmapLoader;
   import net.play5d.kyo.loader.KyoURLoader;
   
   public class BitmapFontLoader
   {
      
      private var _urls:Array;
      
      private var _fontObj:Object = {};
      
      private var _loadAmount:int;
      
      private var _loadBack:Function;
      
      private var _loadProcess:Function;
      
      public function BitmapFontLoader()
      {
         super();
      }
      
      public function clear() : void
      {
         _fontObj = {};
      }
      
      public function loadFonts(param1:Array, param2:Function = null, param3:Function = null) : void
      {
         _loadBack = param2;
         _loadProcess = param3;
         _urls = param1;
         _loadAmount = param1.length;
         loadNext();
      }
      
      public function loadFont(param1:String, param2:XML, param3:Function = null, param4:Function = null) : void
      {
         var _loc5_:String = param2.pages.page.@file;
         var _loc7_:String = param1.substr(0,param1.lastIndexOf("/") + 1);
         var _loc6_:String = _loc7_ + _loc5_;
         loadBitmapData(_loc6_,param2,param3,param4);
      }
      
      public function addFont(param1:XML, param2:BitmapData) : void
      {
         var _loc3_:String = param1.info.@face;
         _fontObj[_loc3_] = new BitmapFont(param1,param2);
      }
      
      public function getFont(param1:String) : BitmapFont
      {
         return _fontObj[param1];
      }
      
      private function loadComplete() : void
      {
         if(_loadBack != null)
         {
            _loadBack();
            _loadBack = null;
         }
         _loadProcess = null;
      }
      
      private function loadNext() : void
      {
         var cur:int;
         var url:String;
         var loadXMLFin:* = function(param1:String):void
         {
            var _loc2_:XML = new XML(param1);
            var _loc3_:String = _loc2_.pages.page.@file;
            var _loc5_:String = url.substr(0,url.lastIndexOf("/") + 1);
            var _loc4_:String = _loc5_ + _loc3_;
            loadBitmapData(_loc4_,_loc2_,loadNext,loadNext);
         };
         var loadXMLFail:* = function():void
         {
            trace("BitmapFontLoader.loadXMLFail::" + url);
            loadNext();
         };
         if(_loadProcess != null)
         {
            cur = _loadAmount - _urls.length;
            _loadProcess(cur / _loadAmount);
         }
         if(_urls.length < 1)
         {
            loadComplete();
            return;
         }
         url = _urls.shift();
         KyoURLoader.load(url,loadXMLFin,loadXMLFail);
      }
      
      private function loadBitmapData(param1:String, param2:XML, param3:Function = null, param4:Function = null) : void
      {
         var bpurl:String = param1;
         var xml:XML = param2;
         var back:Function = param3;
         var fail:Function = param4;
         var loadBpComplete:* = function(param1:Bitmap):void
         {
            _fontObj[fontid] = new BitmapFont(xml,param1.bitmapData);
            if(back != null)
            {
               back();
            }
         };
         var loadBpFail:* = function(param1:Event):void
         {
            trace("BitmapFontLoader.loadBpFail::" + bpurl);
            if(fail != null)
            {
               fail();
            }
         };
         var fontid:String = xml.info.@face;
         var loader:BitmapLoader = new BitmapLoader();
         loader.load(bpurl,loadBpComplete,loadBpFail);
      }
   }
}

