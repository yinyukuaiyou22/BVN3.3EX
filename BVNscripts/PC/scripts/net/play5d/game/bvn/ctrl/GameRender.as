package net.play5d.game.bvn.ctrl
{
   import flash.display.Stage;
   import flash.events.Event;
   import flash.utils.Dictionary;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.GameData;
   
   public class GameRender
   {
      
      private static var _stage:Stage;
      
      public static var isRender:Boolean = true;
      
      private static var _beforeFuncs:Vector.<Function>;
      
      private static var _afterFuncs:Vector.<Function>;
      
      private static var _funcs:Dictionary = new Dictionary();
      
      public function GameRender()
      {
         super();
      }
      
      public static function initlize(param1:Stage) : void
      {
         param1.addEventListener("enterFrame",render);
         _stage = param1;
      }
      
      public static function addBefore(param1:Function) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(_beforeFuncs == null)
         {
            _beforeFuncs = new Vector.<Function>();
         }
         var _loc2_:int = _beforeFuncs.indexOf(param1);
         if(_loc2_ != -1)
         {
            return;
         }
         _beforeFuncs.push(param1);
      }
      
      public static function add(param1:Function, param2:* = null) : void
      {
         if(param2 == null)
         {
            param2 = "anyone";
         }
         if(_funcs[param2] != null && _funcs[param2].indexOf(param1) != -1)
         {
            return;
         }
         if(_funcs[param2] == null)
         {
            _funcs[param2] = new Vector.<Function>();
         }
         _funcs[param2].push(param1);
      }
      
      public static function addAfter(param1:Function) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(_afterFuncs == null)
         {
            _afterFuncs = new Vector.<Function>();
         }
         var _loc2_:int = _afterFuncs.indexOf(param1);
         if(_loc2_ != -1)
         {
            return;
         }
         _afterFuncs.push(param1);
      }
      
      public static function removeBefore(param1:Function) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(_beforeFuncs == null)
         {
            return;
         }
         var _loc2_:int = _beforeFuncs.indexOf(param1);
         if(_loc2_ == -1)
         {
            return;
         }
         _beforeFuncs.splice(_loc2_,1);
         if(_beforeFuncs.length == 0)
         {
            _beforeFuncs = null;
         }
      }
      
      public static function remove(param1:Function, param2:* = null) : void
      {
         if(param2 == null)
         {
            param2 = "anyone";
         }
         if(_funcs[param2] == null)
         {
            return;
         }
         var _loc3_:int = int(_funcs[param2].indexOf(param1));
         if(_loc3_ == -1)
         {
            return;
         }
         _funcs[param2].splice(_loc3_,1);
      }
      
      public static function removeAfter(param1:Function) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(_afterFuncs == null)
         {
            return;
         }
         var _loc2_:int = _afterFuncs.indexOf(param1);
         if(_loc2_ == -1)
         {
            return;
         }
         _afterFuncs.splice(_loc2_,1);
         if(_afterFuncs.length == 0)
         {
            _afterFuncs = null;
         }
      }
      
      public static function render(param1:Event = null) : void
      {
         if(GameConfig.IS_SINGLE_STEP && param1 != null)
         {
            try
            {
               _stage.removeEventListener("enterFrame",render);
               _stage.addEventListener("enterFrame",resume);
               return;
            }
            catch(e:Error)
            {
            }
         }
         if(!isRender)
         {
            return;
         }
         if(_beforeFuncs != null && _beforeFuncs.length > 0)
         {
            for each(var _loc2_ in _beforeFuncs)
            {
               _loc2_();
            }
         }
         for each(var _loc5_ in _funcs)
         {
            for each(var _loc3_ in _loc5_)
            {
               _loc3_();
               if(GameConfig.IS_LOW_QUALITY && GameData.I.config.isExactMoving)
               {
                  _loc3_();
               }
            }
         }
         if(_afterFuncs != null && _afterFuncs.length > 0)
         {
            for each(var _loc4_ in _afterFuncs)
            {
               _loc4_();
            }
         }
      }
      
      private static function resume(param1:Event) : void
      {
         if(GameConfig.IS_SINGLE_STEP)
         {
            return;
         }
         try
         {
            _stage.addEventListener("enterFrame",render);
            _stage.removeEventListener("enterFrame",resume);
         }
         catch(e:Error)
         {
         }
      }
   }
}

