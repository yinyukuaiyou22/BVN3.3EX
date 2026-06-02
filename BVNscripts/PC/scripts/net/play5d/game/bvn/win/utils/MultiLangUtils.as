package net.play5d.game.bvn.win.utils
{
   import flash.filesystem.File;
   import flash.system.Capabilities;
   import net.play5d.kyo.loader.KyoURLoader;
   import net.play5d.patchouli.utils.ClassUtil;
   
   public class MultiLangUtils
   {
      
      private static var _instance:MultiLangUtils;
      
      private const LANG_DIR:String = "lang/";
      
      private const SEPARATOR:String = ".";
      
      private const CHINESE_LANG:String = "zh-CN";
      
      public var lang:String;
      
      private var _langObj:Object;
      
      private var _cnLangObj:Object;
      
      private var _cacheObj:Object;
      
      public function MultiLangUtils()
      {
         super();
      }
      
      public static function get I() : MultiLangUtils
      {
         if(_instance == null)
         {
            _instance = new MultiLangUtils();
         }
         return _instance;
      }
      
      public function getLangPath() : String
      {
         return "lang/" + lang + ".json";
      }
      
      public function getCnLangPath() : String
      {
         return "lang/zh-CN.json";
      }
      
      public function initialize(param1:Function = null) : void
      {
         var back:Function = param1;
         var next:* = function():void
         {
            var langFile:File = File.applicationDirectory.resolvePath(getLangPath());
            if(!langFile.exists)
            {
               lang = "zh-CN";
               langFile = File.applicationDirectory.resolvePath(getLangPath());
               if(!langFile.exists)
               {
                  throw new Error("MultiLangUtils.initialize::中文语言文件不存在！");
               }
            }
            KyoURLoader.load(getLangPath(),function(param1:*):void
            {
               try
               {
                  _langObj = JSON.parse(String(param1));
               }
               catch(e:Error)
               {
                  throw new Error("MultiLangUtils.initialize::解析语言文件失败！");
               }
               if(back != null)
               {
                  back();
               }
            });
            if(!isChinese)
            {
               KyoURLoader.load(getCnLangPath(),function(param1:*):void
               {
                  try
                  {
                     _cnLangObj = JSON.parse(String(param1));
                  }
                  catch(e:Error)
                  {
                     throw new Error("MultiLangUtils.initialize::解析中文语言文件失败！");
                  }
                  if(back != null)
                  {
                     back();
                  }
               });
            }
         };
         lang = Capabilities.language;
         if(lang == "xu")
         {
            KyoURLoader.load("lang/extra.txt",function(param1:*):void
            {
               lang = param1 as String;
               next();
            });
         }
         else
         {
            next();
         }
      }
      
      public function getLangText(param1:String) : String
      {
         if(_langObj == null)
         {
            return null;
         }
         if(_cacheObj == null)
         {
            _cacheObj = {};
         }
         if(_cacheObj[param1])
         {
            return _cacheObj[param1];
         }
         var _loc2_:Array = param1.split(".");
         var _loc3_:String = ClassUtil.continuousAccess(_langObj,_loc2_);
         if(_loc3_ == null)
         {
            return null;
         }
         _cacheObj[param1] = _loc3_;
         return _loc3_;
      }
      
      public function getCnLangText(param1:String) : String
      {
         if(isChinese)
         {
            return getLangText(param1);
         }
         if(_cnLangObj == null)
         {
            return null;
         }
         var _loc2_:Array = param1.split(".");
         var _loc3_:String = ClassUtil.continuousAccess(_cnLangObj,_loc2_);
         if(_loc3_ == null)
         {
            return null;
         }
         return _loc3_;
      }
      
      public function getLangObj() : Object
      {
         return _langObj;
      }
      
      public function get isChinese() : Boolean
      {
         return lang == "zh-CN";
      }
   }
}

