package net.play5d.game.bvn.data
{
   import flash.display.MovieClip;
   import flash.filesystem.File;
   import net.play5d.game.bvn.ctrl.AssetManager;
   import net.play5d.game.bvn.win.utils.FileUtils;
   
   public class AIModel
   {
      
      private static var _instance:AIModel;
      
      private var _AIObject:Object;
      
      private var _AICache:Vector.<AIVO> = null;
      
      public function AIModel()
      {
         super();
      }
      
      public static function get I() : AIModel
      {
         if(_instance == null)
         {
            _instance = new AIModel();
         }
         return _instance;
      }
      
      public function getAllAI() : Object
      {
         return _AIObject;
      }
      
      public function getAIs() : Vector.<AIVO>
      {
         if(_AICache == null)
         {
            _AICache = new Vector.<AIVO>();
            for each(var _loc1_ in _AIObject)
            {
               _AICache.push(_loc1_);
            }
         }
         return _AICache;
      }
      
      public function getAI(param1:String) : AIVO
      {
         return _AIObject[param1];
      }
      
      public function initByPath(param1:String) : void
      {
         var _loc2_:String = null;
         var _loc5_:String = null;
         var _loc9_:String = null;
         var _loc8_:String = null;
         _AIObject = {};
         var _loc7_:String = FileUtils.getAppFloderFileUrl(param1);
         var _loc3_:File = new File(_loc7_);
         if(!_loc3_.isDirectory)
         {
            throw new Error("AIModel.initByPath::[" + _loc7_ + "]不是目录！");
         }
         var _loc6_:Array = _loc3_.getDirectoryListing();
         for each(var _loc4_ in _loc6_)
         {
            _loc2_ = "swf";
            if(_loc4_.extension == _loc2_)
            {
               _loc5_ = _loc4_.name;
               _loc9_ = param1.substr("assets/".length,param1.length - 1);
               _loc8_ = _loc9_ + "/" + _loc5_;
               AssetManager.I.loadSubSwfPath.push(_loc8_);
            }
         }
      }
      
      public function initBySwfIdArray(param1:Array) : void
      {
         var _loc6_:Class = null;
         var _loc3_:MovieClip = null;
         var _loc8_:AIVO = null;
         var _loc5_:String = null;
         var _loc7_:Function = null;
         if(param1 == null)
         {
            return;
         }
         var _loc4_:AIVO = new AIVO();
         _loc4_.id = "default";
         _loc4_.name = "默认人机";
         _loc4_.author = "5dplay";
         _AIObject["default"] = _loc4_;
         for each(var _loc2_ in param1)
         {
            try
            {
               _loc6_ = AssetManager.I.getSWFEffectClass("AIMain",_loc2_);
               _loc3_ = new _loc6_() as MovieClip;
               _loc8_ = new AIVO();
               _loc5_ = _loc3_.CONFIG.id;
               _loc7_ = _loc3_.getCustomAIClass as Function;
               _loc8_.id = _loc5_;
               _loc8_.name = _loc3_.CONFIG.name;
               _loc8_.author = _loc3_.CONFIG.author;
               _loc8_.cls = _loc7_() as Class;
               _AIObject[_loc5_] = _loc8_;
               _loc3_ = null;
            }
            catch(e:Error)
            {
            }
         }
      }
   }
}

