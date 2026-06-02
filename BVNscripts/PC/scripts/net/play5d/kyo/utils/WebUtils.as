package net.play5d.kyo.utils
{
   import flash.display.Stage;
   import flash.events.TimerEvent;
   import flash.external.ExternalInterface;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   import flash.text.TextField;
   import flash.utils.Timer;
   import flash.utils.clearInterval;
   import flash.utils.setInterval;
   
   public class WebUtils
   {
      
      private static var _url:String;
      
      public function WebUtils()
      {
         super();
      }
      
      public static function getURL(param1:String, param2:String = "_blank") : void
      {
         if(!param1)
         {
            trace("getURL: url is null");
            return;
         }
         try
         {
            navigateToURL(new URLRequest(param1),param2);
         }
         catch(e:Error)
         {
            trace(e);
         }
      }
      
      public static function addJSCallBack(param1:String, param2:Function, param3:String = null, param4:TextField = null) : void
      {
         var timer:Timer;
         var functionName:String = param1;
         var closure:Function = param2;
         var jsReady:String = param3;
         var debugTxt:TextField = param4;
         if(jsReady == null)
         {
            try
            {
               ExternalInterface.addCallback(functionName,closure);
            }
            catch(e:Error)
            {
               trace(e);
            }
         }
         else
         {
            timer = new Timer(100);
            timer.addEventListener("timer",function(param1:TimerEvent):void
            {
               var _loc2_:Boolean = false;
               try
               {
                  _loc2_ = ExternalInterface.call(jsReady);
               }
               catch(e:Error)
               {
                  trace(e);
                  timer.stop();
                  timer = null;
               }
               if(debugTxt != null)
               {
                  debugTxt.text = _loc2_.toString();
               }
               if(_loc2_)
               {
                  addJSCallBack(functionName,closure);
                  timer.stop();
                  timer = null;
               }
            });
            timer.start();
         }
      }
      
      public static function checkLockedURL(... rest) : Boolean
      {
         for each(var _loc2_ in rest)
         {
            if(_loc2_ is Array)
            {
               for each(var _loc3_ in _loc2_)
               {
                  if(!checkURL(_loc3_))
                  {
                     return false;
                  }
               }
            }
            else if(!checkURL(_loc2_ as String))
            {
               return false;
            }
         }
         return true;
      }
      
      private static function checkURL(param1:String) : Boolean
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         if(_url == null)
         {
            try
            {
               _url = ExternalInterface.call("eval","window.location.href");
            }
            catch(e:Error)
            {
               trace(e);
               return false;
            }
            _loc2_ = _url.indexOf("//") + 2;
            _loc3_ = _url.indexOf("/",_loc2_);
            _loc3_ = int(_loc3_ == -1 ? 2147483647 : _loc3_ - _loc2_);
            _url = _url.substr(_loc2_,_loc3_);
         }
         return _url.indexOf(param1) != -1;
      }
      
      public static function getParameters(param1:Stage, param2:String, param3:Function, param4:int = 0) : void
      {
         var stage:Stage = param1;
         var checkVar:String = param2;
         var back:Function = param3;
         var timeout:int = param4;
         var loadp:* = function():void
         {
            var _loc1_:Object = stage.loaderInfo.parameters[checkVar];
            if(loadTimes > 0)
            {
               loadTimes = loadTimes - 1;
            }
            if(_loc1_ || loadTimes == 0)
            {
               clearInterval(loadint);
               if(back != null)
               {
                  back(stage.loaderInfo.parameters);
               }
            }
         };
         var loadint:int = int(setInterval(loadp,300));
         var loadTimes:int = timeout == 0 ? -1 : Math.ceil(timeout / 300);
      }
      
      public static function getLocalUrl(param1:Stage) : String
      {
         var _loc3_:String = param1.loaderInfo.url;
         var _loc2_:int = _loc3_.lastIndexOf("/");
         return _loc3_.substr(0,_loc2_ + 1);
      }
      
      public static function replaceUrl(param1:String, param2:String, param3:String) : String
      {
         var _loc4_:String = param1.replace(param2,param2 + param3);
         return _loc4_.replace(param3 + "http://","http://");
      }
      
      public static function getUrlFloder(param1:String) : String
      {
         var _loc2_:int = param1.lastIndexOf("/");
         return param1.substr(0,_loc2_ + 1);
      }
      
      public static function getLocalFloder(param1:String) : String
      {
         var _loc2_:int = param1.lastIndexOf("\\");
         return param1.substr(0,_loc2_ + 1);
      }
      
      public static function getFileName(param1:Stage) : String
      {
         var _loc3_:String = param1.loaderInfo.url;
         var _loc2_:int = _loc3_.lastIndexOf("/");
         return _loc3_.substr(_loc2_ + 1);
      }
      
      public static function getStageUrlFloder(param1:Stage) : String
      {
         var _loc2_:String = param1.loaderInfo.url;
         return getUrlFloder(_loc2_);
      }
      
      public static function refresh() : void
      {
         getURL("javascript:location.reload();","_self");
      }
      
      public static function alert(param1:String) : void
      {
         getURL("javascript:alert(\"" + param1 + "\");","_self");
      }
   }
}

