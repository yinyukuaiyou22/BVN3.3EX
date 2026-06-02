package net.play5d.game.bvn.data
{
   import flash.filesystem.File;
   import net.play5d.game.bvn.win.utils.FileUtils;
   import net.play5d.kyo.utils.KyoRandom;
   
   public class BgmModel
   {
      
      private static var _instance:BgmModel;
      
      private var _bgmObj:Object;
      
      private var _bgmCache:Vector.<BgmVO> = null;
      
      private var _randomBgmCache:Vector.<BgmVO> = null;
      
      public function BgmModel()
      {
         super();
      }
      
      public static function get I() : BgmModel
      {
         if(_instance == null)
         {
            _instance = new BgmModel();
         }
         return _instance;
      }
      
      public function getAllBgms() : Object
      {
         return _bgmObj;
      }
      
      public function getBgms() : Vector.<BgmVO>
      {
         if(_bgmCache == null)
         {
            _bgmCache = new Vector.<BgmVO>();
            for each(var _loc1_ in _bgmObj)
            {
               _bgmCache.push(_loc1_);
            }
         }
         return _bgmCache;
      }
      
      public function getBgm(param1:String) : BgmVO
      {
         return _bgmObj[param1];
      }
      
      public function getRandomBgm() : BgmVO
      {
         var _loc2_:* = undefined;
         var _loc5_:* = undefined;
         var _loc1_:Boolean = false;
         if(_randomBgmCache == null)
         {
            _loc2_ = getBgms();
            _loc5_ = FighterModel.I.getFighters();
            _randomBgmCache = new Vector.<BgmVO>();
            for each(var _loc3_ in _loc2_)
            {
               _loc1_ = true;
               for each(var _loc4_ in _loc5_)
               {
                  if(_loc3_.id == _loc4_.id)
                  {
                     _loc1_ = false;
                     break;
                  }
               }
               if(_loc1_)
               {
                  _randomBgmCache.push(_loc3_);
               }
            }
         }
         return KyoRandom.getRandomInArray(_randomBgmCache);
      }
      
      public function initByPath(param1:String) : void
      {
         var _loc10_:int = 0;
         var _loc8_:String = null;
         var _loc2_:String = null;
         var _loc3_:String = null;
         var _loc6_:BgmVO = null;
         var _loc12_:String = null;
         _bgmObj = {};
         var _loc7_:String = FileUtils.getAppFloderFileUrl(param1);
         var _loc5_:File = new File(_loc7_);
         if(!_loc5_.isDirectory)
         {
            throw new Error("BgmModel.initByPath::[" + _loc7_ + "]不是目录！");
         }
         var _loc11_:Array = ["mp3","wav"];
         var _loc9_:Array = _loc5_.getDirectoryListing();
         for each(var _loc4_ in _loc9_)
         {
            _loc10_ = _loc11_.indexOf(_loc4_.extension);
            if(_loc10_ != -1)
            {
               _loc8_ = _loc4_.name;
               _loc2_ = _loc11_[_loc10_];
               _loc3_ = _loc8_.substr(0,_loc8_.length - 1 - _loc2_.length);
               _loc6_ = new BgmVO();
               _loc6_.id = _loc3_;
               _loc6_.rate = 1;
               _loc12_ = param1.substr("assets/".length,param1.length - 1);
               _loc6_.url = _loc12_ + "/" + _loc8_;
               _bgmObj[_loc3_] = _loc6_;
            }
         }
      }
   }
}

