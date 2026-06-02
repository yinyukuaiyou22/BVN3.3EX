package net.play5d.game.bvn.utils
{
   import flash.display.BitmapData;
   import flash.display.Sprite;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import flash.utils.describeType;
   import net.play5d.game.bvn.data.GameData;
   
   public class ResUtils
   {
      
      private static var _i:ResUtils;
      
      public static var SETTING:String = "stg_set_ui";
      
      public static var CONGRATULATIONS:String = "mc_congratulations";
      
      public static var WINNER:String = "winner_stg_mc";
      
      public static var TITLE:String = "stg_title";
      
      public static var GAME_OVER:String = "stg_gameover_mc";
      
      public static var SELECT:String = "stg_select";
      
      public static var MOSOU:String = "stg_mosou";
      
      public static var BIG_MAP:String = "big_map_mc";
      
      public static var RULE:String = "stg_rule_ui";
      
      public var extend:Class = extend_swf$d696c8e3e6cc86c3361d7e9d3995529d888166424;
      
      private var _defaultSave:Class = default_json$f8664e08c5894d8fb48c52af4f989c5e354272895;
      
      private var _swfPool:Dictionary;
      
      private var _initBack:Function;
      
      private var _initError:Function;
      
      private var _inited:Boolean;
      
      private var _initing:Boolean;
      
      public function ResUtils()
      {
         super();
      }
      
      public static function get I() : ResUtils
      {
         if(!_i)
         {
            _i = new ResUtils();
         }
         return _i;
      }
      
      public function getSaveData() : ByteArray
      {
         return new _defaultSave() as ByteArray;
      }
      
      public function initalize(param1:Function = null, param2:Function = null) : void
      {
         var _loc4_:InsSwf = null;
         var _loc7_:XMLList = null;
         var _loc8_:* = null;
         if(_initing)
         {
            throw new Error("正在初始化过程中，不能再次初始化！");
         }
         if(_inited)
         {
            if(param1 != null)
            {
               param1();
            }
            return;
         }
         _inited = true;
         _initing = true;
         _swfPool = new Dictionary();
         _initBack = param1;
         _initError = param2;
         var _loc6_:XML = describeType(this);
         var _loc3_:Boolean = false;
         for each(var _loc5_ in _loc6_.variable)
         {
            _loc3_ = true;
            _loc7_ = _loc5_.@name;
            _loc8_ = this[_loc7_];
            if(_loc8_ != null)
            {
               _loc4_ = new InsSwf(_loc8_);
               _loc4_.ready = swfReadyBack;
               _loc4_.error = swfErrorBack;
               _swfPool[_loc8_] = _loc4_;
            }
         }
         if(!_loc3_)
         {
            finish();
         }
      }
      
      private function swfReadyBack(param1:InsSwf) : void
      {
         for each(var _loc2_ in _swfPool)
         {
            if(!_loc2_.isReady)
            {
               return;
            }
         }
         finish();
      }
      
      private function swfErrorBack(param1:String) : void
      {
         if(_initError != null)
         {
            _initError();
         }
      }
      
      private function finish() : void
      {
         _initing = false;
         if(_initBack != null)
         {
            _initBack();
            _initBack = null;
         }
      }
      
      public function createDisplayObject(param1:Class, param2:String) : *
      {
         var _loc6_:* = undefined;
         var _loc4_:Sprite = null;
         var _loc3_:SoundTransform = null;
         var _loc5_:Class = getItemClass(param1,param2);
         if(_loc5_)
         {
            _loc6_ = new _loc5_();
            if(_loc6_ is Sprite)
            {
               _loc4_ = _loc6_ as Sprite;
               _loc3_ = _loc4_.soundTransform;
               _loc3_.volume = GameData.I.config.soundVolume;
               _loc4_.soundTransform = _loc3_;
               return _loc4_;
            }
            return _loc6_;
         }
      }
      
      public function createBitmapData(param1:Class, param2:String, param3:int, param4:int) : BitmapData
      {
         var _loc5_:Class = getItemClass(param1,param2);
         if(!_loc5_)
         {
            return null;
         }
         return new _loc5_(param3,param4);
      }
      
      public function getItemClass(param1:Class, param2:String) : Class
      {
         if(!_swfPool)
         {
            throw new Error("未进行初始化！");
         }
         var _loc3_:InsSwf = _swfPool[param1];
         if(!_loc3_)
         {
            throw new Error("swf is undefined!");
         }
         return _loc3_.getClass(param2);
      }
      
      public function getItemProperty(param1:Class, param2:String) : *
      {
         if(!_swfPool)
         {
            throw new Error("未进行初始化！");
         }
         var _loc3_:InsSwf = _swfPool[param1];
         if(!_loc3_)
         {
            throw new Error("swf is undefined!");
         }
         return _loc3_.getProperty(param2);
      }
      
      public function callSwfFunction(param1:Class, param2:String, param3:Array = null) : *
      {
         if(!_swfPool)
         {
            throw new Error("未进行初始化！");
         }
         var _loc4_:InsSwf = _swfPool[param1];
         if(!_loc4_)
         {
            throw new Error("swf is undefined!");
         }
         return _loc4_.call(param2,param3);
      }
   }
}

import flash.compiler.embed.EmbeddedMovieClip;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

class InsSwf
{
   
   private var _swf:EmbeddedMovieClip;
   
   private var _domain:ApplicationDomain;
   
   public var isReady:Boolean;
   
   public var ready:Function;
   
   public var error:Function;
   
   private var _content:DisplayObject;
   
   public function InsSwf(param1:Class)
   {
      var _loc3_:LoaderContext = null;
      super();
      _swf = new param1();
      var _loc2_:ByteArray = _swf.movieClipData;
      if(!_loc2_)
      {
         error("未发现swf的movieClipData!");
         throw new Error("未发现swf的movieClipData!");
      }
      var _loc4_:Loader = new Loader();
      _loc4_.contentLoaderInfo.addEventListener("complete",loadComplete,false,0,true);
      _loc3_ = new LoaderContext(false,ApplicationDomain.currentDomain);
      _loc3_.allowCodeImport = true;
      _loc4_.loadBytes(_loc2_,_loc3_);
   }
   
   public function getClass(param1:String) : Class
   {
      return _domain.getDefinition(param1) as Class;
   }
   
   public function getProperty(param1:String) : *
   {
      return _content[param1];
   }
   
   public function call(param1:String, param2:Array = null) : *
   {
      var _loc3_:* = null;
      if(!_content)
      {
         return null;
      }
      try
      {
         _loc3_ = _content[param1];
         return _loc3_.apply(null,param2);
      }
      catch(e:Error)
      {
         throw new Error("swf." + param1 + " call failed ! ");
      }
   }
   
   private function loadComplete(param1:Event) : void
   {
      var _loc2_:LoaderInfo = param1.currentTarget as LoaderInfo;
      _domain = _loc2_.applicationDomain;
      _content = _loc2_.content;
      isReady = true;
      if(ready != null)
      {
         ready(this);
         ready = null;
      }
   }
}
