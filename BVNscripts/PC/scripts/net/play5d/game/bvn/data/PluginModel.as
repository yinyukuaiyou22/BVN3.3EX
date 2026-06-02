package net.play5d.game.bvn.data
{
   import flash.display.MovieClip;
   import flash.filesystem.File;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.win.utils.FileUtils;
   
   public class PluginModel
   {
      
      private static var _instance:PluginModel;
      
      private var _pluginObj:Object;
      
      private var _pluginCache:Vector.<PluginVO> = null;
      
      public function PluginModel()
      {
         super();
      }
      
      public static function get I() : PluginModel
      {
         if(_instance == null)
         {
            _instance = new PluginModel();
         }
         return _instance;
      }
      
      public function getAllPlugins() : Object
      {
         return _pluginObj;
      }
      
      public function getPlugins() : Vector.<PluginVO>
      {
         if(_pluginCache == null)
         {
            _pluginCache = new Vector.<PluginVO>();
            for each(var _loc1_ in _pluginObj)
            {
               _pluginCache.push(_loc1_);
            }
         }
         return _pluginCache;
      }
      
      public function getPlugin(param1:String) : PluginVO
      {
         return _pluginObj[param1];
      }
      
      public function initByPath(param1:String) : void
      {
         var _loc2_:String = null;
         var _loc5_:String = null;
         var _loc9_:String = null;
         var _loc8_:String = null;
         _pluginObj = {};
         var _loc4_:String = FileUtils.getAppFloderFileUrl(param1);
         var _loc7_:File = new File(_loc4_);
         if(!_loc7_.isDirectory)
         {
            throw new Error("PluginModel.initByPath::[" + _loc4_ + "]不是目录！");
         }
         var _loc6_:Array = _loc7_.getDirectoryListing();
         for each(var _loc3_ in _loc6_)
         {
            _loc2_ = "swf";
            if(_loc3_.extension == _loc2_)
            {
               _loc5_ = _loc3_.name;
               _loc9_ = param1.substr("assets/".length,param1.length - 1);
               _loc8_ = _loc9_ + "/" + _loc5_;
               AssetManager.I.loadSubSwfPath.push(_loc8_);
            }
         }
      }
      
      public function initBySwfIdArray(param1:Array) : void
      {
         var _loc4_:Class = null;
         var _loc2_:MovieClip = null;
         var _loc3_:PluginVO = null;
         var _loc5_:String = null;
         if(param1 == null)
         {
            return;
         }
         for each(var _loc6_ in param1)
         {
            try
            {
               _loc4_ = AssetManager.I.getSWFEffectClass("PluginMain",_loc6_);
               _loc2_ = new _loc4_() as MovieClip;
               if(_loc2_.CONFIG.isNeedDebug)
               {
                  _loc2_ = null;
               }
               else
               {
                  _loc3_ = new PluginVO();
                  _loc5_ = _loc2_.CONFIG.id;
                  _loc3_.id = _loc5_;
                  _loc3_.name = _loc2_.CONFIG.name;
                  _loc3_.author = _loc2_.CONFIG.author;
                  _loc3_.isRunBack = _loc2_.CONFIG.isRunBack;
                  _loc3_.cls = _loc4_;
                  _pluginObj[_loc5_] = _loc3_;
                  _loc2_ = null;
               }
            }
            catch(e:Error)
            {
            }
         }
      }
   }
}

