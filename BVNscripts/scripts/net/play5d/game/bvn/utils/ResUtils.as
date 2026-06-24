package net.play5d.game.bvn.utils
{
   import flash.display.*;
   import flash.events.*;
   import flash.media.SoundTransform;
   import flash.net.*;
   import flash.system.*;
   import flash.utils.*;
   import net.play5d.game.bvn.data.*;
   
   public class ResUtils
   {
      
      private static var _i:ResUtils;
      
      public static var SETTING:String = "stg_set_ui";
      
      public static var CONGRATULATIONS:String = "mc_congratulations";
      
      public static var WINNER:String = "winner_stg_mc";
      
      public static var TITLE:String = "stg_title";
      
      public static var GAME_OVER:String = "stg_gameover_mc";
      
      public static var SELECT:String = "stg_select";
      
      private static const SWF_LIST:Array = [{
         "key":"common_ui",
         "embed":EmbeddedAssets.common_ui_swf
      },{
         "key":"fight",
         "embed":EmbeddedAssets.fight_swf
      },{
         "key":"gameover",
         "embed":EmbeddedAssets.gameover_swf
      },{
         "key":"howtoplay",
         "embed":EmbeddedAssets.howtoplay_swf
      },{
         "key":"loading",
         "embed":EmbeddedAssets.loading_swf
      },{
         "key":"select",
         "embed":EmbeddedAssets.select_swf
      },{
         "key":"setting",
         "embed":EmbeddedAssets.setting_swf
      },{
         "key":"title",
         "embed":EmbeddedAssets.title_swf
      }];
      
      private var _swfPool:Dictionary;
      
      private var _initBack:Function;
      
      private var _initError:Function;
      
      private var _inited:Boolean;
      
      private var _initing:Boolean;
      
      public var common_ui:*;
      
      public var fight:*;
      
      public var gameover:*;
      
      public var howtoplay:*;
      
      public var loading:*;
      
      public var select:*;
      
      public var setting:*;
      
      public var title:*;
      
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
      
      public function initalize(param1:Function = null, param2:Function = null) : void
      {
         var total:int = 0;
         var loaded:int = 0;
         var item:Object = null;
         if(this._initing)
         {
            throw new Error("正在初始化过程中，不能再次初始化！");
         }
         if(this._inited)
         {
            if(param1 != null)
            {
               param1();
            }
            return;
         }
         this._inited = true;
         this._initing = true;
         this._swfPool = new Dictionary();
         this._initBack = param1;
         this._initError = param2;
         total = int(SWF_LIST.length);
         loaded = 0;
         for each(item in SWF_LIST)
         {
            this.loadOneSwf(item,function(domain:ApplicationDomain, key:String):void
            {
               I[key] = domain;
               ++loaded;
               if(loaded >= total)
               {
                  finish();
               }
            });
         }
      }
      
      private function loadOneSwf(item:Object, callback:Function) : void
      {
         var loader:Loader = new Loader();
         var ctx:LoaderContext = new LoaderContext(false,ApplicationDomain.currentDomain);
         ctx.allowCodeImport = true;
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void
         {
            var li:LoaderInfo = e.currentTarget as LoaderInfo;
            callback(li.applicationDomain,item.key);
         });
         var bytes:ByteArray = new (item.embed as Class)() as ByteArray;
         loader.loadBytes(bytes,ctx);
      }
      
      private function finish() : void
      {
         this._initing = false;
         if(this._initBack != null)
         {
            this._initBack();
            this._initBack = null;
         }
      }
      
      public function getItemClass(param1:*, param2:String) : Class
      {
         var domain:ApplicationDomain = param1 as ApplicationDomain;
         if(!domain)
         {
            return null;
         }
         return domain.getDefinition(param2) as Class;
      }
      
      public function createDisplayObject(param1:*, param2:String) : *
      {
         var obj:* = undefined;
         var sp:Sprite = null;
         var st:SoundTransform = null;
         var domain:ApplicationDomain = param1 as ApplicationDomain;
         if(!domain)
         {
            throw new Error("swf is undefined!");
         }
         var cls:Class = this.getItemClass(param1,param2);
         if(Boolean(cls))
         {
            obj = new cls();
            if(obj is Sprite)
            {
               sp = obj as Sprite;
               st = sp.soundTransform;
               st.volume = GameData.I.config.soundVolume;
               sp.soundTransform = st;
               return sp;
            }
            return obj;
         }
         return null;
      }
      
      public function createBitmapData(param1:*, param2:String, param3:int, param4:int) : BitmapData
      {
         var cls:Class = this.getItemClass(param1,param2);
         if(!cls)
         {
            return null;
         }
         return new cls(param3,param4);
      }
   }
}

