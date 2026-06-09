package net.play5d.game.bvn.ctrl
{
   import flash.display.*;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.map.*;
   import net.play5d.game.bvn.mob.utils.ANEFileReader;
   
   public class GameLoader
   {
      
      private static var _loaderCache:Vector.<Loader> = new Vector.<Loader>();
      
      public function GameLoader()
      {
         super();
      }
      
      public static function loadFighter(fighterId:String, back:Function, fail:Function = null, process:Function = null, customBackParam:Object = null) : void
      {
         var fv:FighterVO = null;
         var loadComplete:* = function(param1:DisplayObject):void
         {
            var _loc2_:FighterMain = new FighterMain(param1 as MovieClip);
            _loc2_.data = fv;
            if(back != null)
            {
               if(Boolean(customBackParam))
               {
                  back(_loc2_,customBackParam);
               }
               else
               {
                  back(_loc2_);
               }
               back = null;
            }
         };
         fv = FighterModel.I.getFighter(fighterId,true);
         if(!fv)
         {
            trace("GameLoader.loadFighter :: ID不存在:",fighterId);
            if(fail != null)
            {
               fail("角色ID错误");
            }
            return;
         }
         loadSWF(fv.fileUrl,loadComplete,fail,process);
      }
      
      public static function loadAssister(fighterId:String, back:Function, fail:Function = null, process:Function = null, customBackParam:Object = null) : void
      {
         var fv:FighterVO = null;
         var loadComplete:* = function(param1:DisplayObject):void
         {
            var _loc2_:Assister = new Assister(param1 as MovieClip);
            _loc2_.data = fv;
            if(back != null)
            {
               if(Boolean(customBackParam))
               {
                  back(_loc2_,customBackParam);
               }
               else
               {
                  back(_loc2_);
               }
               back = null;
            }
         };
         fv = AssisterModel.I.getAssister(fighterId,true);
         if(!fv)
         {
            trace("GameLoader.loadAssister :: ID不存在:",fighterId);
            if(fail != null)
            {
               fail("角色ID错误");
            }
            return;
         }
         loadSWF(fv.fileUrl,loadComplete,fail,process);
      }
      
      public static function loadMap(mapId:String, back:Function, fail:Function = null, process:Function = null, customBackParam:Object = null) : void
      {
         var mv:MapVO = null;
         var loadComplete:* = function(param1:DisplayObject):void
         {
            var _loc2_:MapMain = new MapMain(param1 as Sprite);
            _loc2_.data = mv;
            if(back != null)
            {
               if(Boolean(customBackParam))
               {
                  back(_loc2_,customBackParam);
               }
               else
               {
                  back(_loc2_);
               }
               back = null;
            }
         };
         mv = MapModel.I.getMap(mapId);
         if(!mv)
         {
            trace("GameLoader.loadMap :: ID不存在:",mapId);
            if(fail != null)
            {
               fail("场景ID错误");
            }
            return;
         }
         loadSWF(mv.fileUrl,loadComplete,fail,process);
      }
      
      public static function dispose() : void
      {
         var _loc1_:* = undefined;
         _loc1_ = null;
         while(Boolean(_loaderCache.length))
         {
            _loc1_ = _loaderCache.shift();
            try
            {
               _loc1_.unloadAndStop(true);
            }
            catch(e:Error)
            {
               trace("GameLoader ::",e);
               _loc1_.unload();
            }
         }
      }
      
      private static function loadSWF(url:String, back:Function, fail:Function = null, process:Function = null) : void
      {
         var loadComplete:* = function(param1:Loader):void
         {
            if(back != null)
            {
               back(param1.content);
               back = null;
            }
            _loaderCache.push(param1);
         };
         var loadIOError:* = function():void
         {
            Debugger.log("GameLoader.loadSWF :: 找不到文件:",url);
            if(fail != null)
            {
               fail("加载场景文件错误");
            }
         };
         AssetManager.I.loadSWF(url,loadComplete,loadIOError,process);
      }

      /** Load fighter from absolute file path via ANEFileReader */
      public static function loadFighterFromPath(path:String, back:Function, fail:Function = null) : void
      {
         trace("[GameLoader.loadFighterFromPath]", path);
         var ba:ByteArray = ANEFileReader.I.readBytes(path);
         if(!ba)
         {
            trace("[GameLoader.loadFighterFromPath] FAILED: null bytes");
            if(fail != null) fail("File not found: " + path);
            return;
         }
         trace("[GameLoader.loadFighterFromPath] loaded", ba.length, "bytes");
         var loader:Loader = new Loader();
         loader.contentLoaderInfo.addEventListener("complete", function(e:*):void
         {
            var mc:MovieClip = loader.content as MovieClip;
            var fm:FighterMain = new FighterMain(mc);
            trace("[GameLoader.loadFighterFromPath] SWF parsed, FighterMain created");
            if(back != null) back(fm);
         });
         loader.loadBytes(ba);
         _loaderCache.push(loader);
      }
   }
}

