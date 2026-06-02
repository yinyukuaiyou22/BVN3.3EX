package nagisa.events
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import nagisa.interfaces.IInstance;
   import nagisa.interfaces.INEventDispatcher;
   import nagisa.util.ClassUtil;
   
   use namespace NagisaEvent;
   
   public class NEventDispatcher extends EventDispatcher implements IInstance, INEventDispatcher
   {
      
      protected var _destoryed:Boolean = false;
      
      private var _listeners:Object;
      
      protected var _dispatcher:IEventDispatcher;
      
      public function NEventDispatcher(param1:IEventDispatcher = null)
      {
         super();
         NagisaEvent::_initialize(param1);
      }
      
      public function get dispatcher() : IEventDispatcher
      {
         return _dispatcher;
      }
      
      public function set dispatcher(param1:IEventDispatcher) : void
      {
         _dispatcher = param1;
      }
      
      public function get isActive() : Boolean
      {
         return false;
      }
      
      NagisaEvent function _initialize(param1:IEventDispatcher = null) : void
      {
         _destoryed = false;
         _dispatcher = param1;
         _listeners = {};
      }
      
      public function isDestoryed() : Boolean
      {
         return _destoryed;
      }
      
      public function destory(param1:Boolean = true) : void
      {
         if(param1)
         {
            removeAllListener();
            _listeners = null;
            _dispatcher = null;
         }
         _destoryed = true;
      }
      
      public function render() : void
      {
      }
      
      public function renderAnimate() : void
      {
      }
      
      public function listen(param1:String, param2:Function) : void
      {
         var _loc3_:Vector.<Function> = _listeners[param1] = _listeners[param1] || new Vector.<Function>();
         if(_loc3_.indexOf(param2) != -1)
         {
            return;
         }
         _loc3_[_loc3_.length] = param2;
         _addEventListener(param1,param2);
      }
      
      public function unlisten(param1:String, param2:Function) : void
      {
         var _loc4_:int = _has(param1,param2);
         if(_loc4_ < 0)
         {
            return;
         }
         var _loc3_:Vector.<Function> = _listeners[param1];
         _removeEventListener(param1,param2);
         _loc3_.splice(_loc4_,1);
         if(!_loc3_.length)
         {
            _listeners[param1] = null;
         }
      }
      
      public function removeAllListener(param1:String = null) : void
      {
         var _loc2_:* = undefined;
         if(!param1)
         {
            for(param1 in _listeners)
            {
               removeAllListener(param1);
            }
         }
         if(!hasListener(param1))
         {
            return;
         }
         _loc2_ = _listeners[param1];
         for each(var _loc3_ in _loc2_)
         {
            unlisten(param1,_loc3_);
         }
      }
      
      public function hasListener(param1:String, param2:Function = null) : Boolean
      {
         return _has(param1,param2) != -1;
      }
      
      private function _has(param1:String, param2:Function = null) : int
      {
         if(!_listeners)
         {
            return -1;
         }
         var _loc3_:Vector.<Function> = _listeners[param1];
         if(!_loc3_)
         {
            return -1;
         }
         if(param2 != null)
         {
            return _loc3_.indexOf(param2);
         }
         return -2;
      }
      
      public function dispatch(param1:*, param2:Object = null) : Boolean
      {
         if(param2)
         {
            param1 = new NEvent(param1,param2);
         }
         else
         {
            switch(ClassUtil.checkTargetType(param1,String,Event) - -1)
            {
               case 0:
                  throw new TypeError("NEventDispatcher.dispatch Error::param is out of range!");
               case 1:
                  param1 = new NEvent(param1);
            }
         }
         return _dispatchEvent(param1 as Event);
      }
      
      private function _addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(_dispatcher)
         {
            _dispatcher.addEventListener(param1,param2,param3,param4,param5);
            return;
         }
         super.addEventListener(param1,param2,param3,param4,param5);
      }
      
      private function _dispatchEvent(param1:Event) : Boolean
      {
         if(_dispatcher)
         {
            return _dispatcher.dispatchEvent(param1);
         }
         return super.dispatchEvent(param1);
      }
      
      private function _removeEventListener(param1:String, param2:Function, param3:Boolean = false) : void
      {
         if(_dispatcher)
         {
            _dispatcher.removeEventListener(param1,param2,param3);
            return;
         }
         super.removeEventListener(param1,param2,param3);
      }
   }
}

