package net.play5d.kyo.loader
{
   import flash.display.Loader;
   import flash.display.LoaderInfo;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.utils.Dictionary;
   
   public class KyoClassLoader extends EventDispatcher
   {
      
      private var _classes:Object = {};
      
      private var _urls:Array;
      
      private var _defaultId:String;
      
      private var _loadedAmount:int;
      
      private var _loadLength:int;
      
      private var _directory:Dictionary = new Dictionary();
      
      private var _loading:Boolean;
      
      public function KyoClassLoader()
      {
         super();
      }
      
      public function getClass(param1:String, param2:String = null) : Class
      {
         if(!param2)
         {
            param2 = _defaultId;
         }
         var _loc3_:ApplicationDomain = _classes[param2];
         if(!_loc3_)
         {
            throw new Error(param2 + "未加载!");
         }
         try
         {
            return _loc3_.getDefinition(param1) as Class;
         }
         catch(e:Error)
         {
            throw new Error("在 " + param2 + " 中找不到 " + param1 + " 的定义!");
         }
      }
      
      public function get loadedAmount() : int
      {
         return _loadedAmount;
      }
      
      public function load(param1:Object) : void
      {
         if(_loading)
         {
            throw new Error("不可以在没完成加载时继续调用此方法!");
         }
         if(param1 is String)
         {
            _urls = [param1];
         }
         if(param1 is Array)
         {
            _urls = param1 as Array;
         }
         _loadLength = _urls.length;
         _loadedAmount = 0;
         loadNext();
         _loading = true;
      }
      
      public function addSwf(param1:String, param2:Loader) : void
      {
         _classes[param1] = param2.contentLoaderInfo.applicationDomain;
         try
         {
            param2.unloadAndStop(true);
         }
         catch(e:Error)
         {
            param2.unload();
         }
      }
      
      private function loadNext() : Boolean
      {
         if(_urls.length < 1)
         {
            return false;
         }
         _loadedAmount = _loadedAmount + 1;
         var _loc1_:Loader = new Loader();
         _loc1_.contentLoaderInfo.addEventListener("complete",loadComplete);
         _loc1_.contentLoaderInfo.addEventListener("progress",loadProgress);
         _loc1_.contentLoaderInfo.addEventListener("ioError",loadError);
         var _loc2_:String = _urls.shift();
         _loc1_.load(new URLRequest(_loc2_));
         _directory[_loc1_] = _loc2_;
         return true;
      }
      
      private function removeLoader(param1:Loader) : void
      {
         param1.contentLoaderInfo.removeEventListener("complete",loadComplete);
         param1.contentLoaderInfo.removeEventListener("progress",loadProgress);
         param1.contentLoaderInfo.removeEventListener("ioError",loadError);
         try
         {
            param1.unloadAndStop(true);
         }
         catch(e:Error)
         {
            param1.unload();
         }
         param1 = null;
      }
      
      private function loadComplete(param1:Event) : void
      {
         var _loc3_:LoaderInfo = param1.currentTarget as LoaderInfo;
         var _loc2_:Loader = _loc3_.loader;
         var _loc4_:String = _directory[_loc2_];
         if(!_defaultId)
         {
            _defaultId = _loc4_;
         }
         _classes[_loc4_] = _loc3_.applicationDomain;
         removeLoader(_loc2_);
         checkComplete();
      }
      
      private function loadProgress(param1:ProgressEvent) : void
      {
         dispatchEvent(param1);
      }
      
      private function loadError(param1:IOErrorEvent) : void
      {
         var _loc3_:String = null;
         var _loc2_:Loader = (param1.currentTarget as LoaderInfo).loader;
         if(_loc2_ && _loc2_.loaderInfo)
         {
            _loc3_ = _loc2_.loaderInfo.loaderURL;
         }
         trace("loadError",_loc3_);
         dispatchEvent(param1);
         checkComplete();
      }
      
      private function checkComplete() : void
      {
         if(loadNext() == false)
         {
            _loading = false;
            dispatchEvent(new Event("complete"));
         }
      }
   }
}

