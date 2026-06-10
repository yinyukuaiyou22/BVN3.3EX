package net.play5d.game.bvn.ctrl
{
   import flash.display.*;
   import flash.utils.ByteArray;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.fighter.*;
   import net.play5d.game.bvn.map.*;
   import flash.filesystem.File;
import net.play5d.game.bvn.mob.utils.ANEFileReader;
import net.play5d.game.bvn.Debugger;
   
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
            Debugger.log("GameLoader.loadFighter :: ID不存在:",fighterId);
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
            Debugger.log("GameLoader.loadAssister :: ID不存在:",fighterId);
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
            Debugger.log("GameLoader.loadMap :: ID不存在:",mapId);
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
               Debugger.log("GameLoader ::",e);
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

      /** Scan external app-storage://BVN/assets/fighter/ and register in FighterModel (appended after built-in) */
      public static function scanExternalFighters() : void
      {
         var basePath:String = ANEFileReader.resolveExternalPath("fighter") + "/";
         Debugger.log("[GameLoader] Scanning external fighters:", basePath);
         if(!ANEFileReader.I.exists(basePath))
         {
            Debugger.log("[GameLoader] External fighter path not found, skipping.");
            return;
         }
         var files:Array = ANEFileReader.I.listDir(basePath);
         if(!files || files.length == 0)
         {
            Debugger.log("[GameLoader] No external fighters found.");
            return;
         }
         for each(var fileName:String in files)
         {
            if(fileName.indexOf(".swf") == -1) continue;
            var fighterId:String = fileName.replace(".swf", "");
            var fullPath:String = basePath + fileName;
            // check if already registered (built-in takes precedence)
            var existing:FighterVO = FighterModel.I.getFighter(fighterId);
            if(existing)
            {
               Debugger.log("[GameLoader] External fighter skipped (already registered):", fighterId);
               continue;
            }
            // create minimal FighterVO for external fighter
            var vo:FighterVO = new FighterVO();
            vo.id = fighterId;
            vo.name = fighterId;
            vo.comicType = 0;
            vo.fileUrl = fullPath;
            vo.startFrame = 1;
            vo.faceUrl = "";
            vo.faceBigUrl = "";
            vo.faceBarUrl = "";
            vo.faceWinUrl = "";
            vo.contactFriends = [];
            vo.contactEnemys = [];
            vo.says = [];
            vo.bgm = "";
            vo.bgmRate = 0;
            // register in model (appended after built-in)
            var allFighters:Object = FighterModel.I.getAllFighters();
            allFighters[fighterId] = vo;
            Debugger.log("[GameLoader] Registered external fighter:", fighterId, "from", fullPath);
         }
         Debugger.log("[GameLoader] External fighter scan complete. Found:", files.length, "files");
      }

      /** Scan external app-storage://BVN/assets/map/ and register in MapModel (appended after built-in) */
      public static function scanExternalMaps() : void
      {
         var basePath:String = ANEFileReader.resolveExternalPath("map") + "/";
         Debugger.log("[GameLoader] Scanning external maps:", basePath);
         if(!ANEFileReader.I.exists(basePath))
         {
            Debugger.log("[GameLoader] External map path not found, skipping.");
            return;
         }
         var files:Array = ANEFileReader.I.listDir(basePath);
         if(!files || files.length == 0)
         {
            Debugger.log("[GameLoader] No external maps found.");
            return;
         }
         var mapArray:Array = MapModel.I.getAllMaps();
         for each(var fileName:String in files)
         {
            if(fileName.indexOf(".swf") == -1) continue;
            var mapId:String = fileName.replace(".swf", "");
            var fullPath:String = basePath + fileName;
            // check if already registered
            var existing:MapVO = MapModel.I.getMap(mapId);
            if(existing)
            {
               Debugger.log("[GameLoader] External map skipped (already registered):", mapId);
               continue;
            }
            var mv:MapVO = new MapVO();
            mv.id = mapId;
            mv.name = mapId;
            mv.fileUrl = fullPath;
            mv.picUrl = "";
            mv.bgm = "";
            mapArray.push(mv);
            Debugger.log("[GameLoader] Registered external map:", mapId, "from", fullPath);
         }
         Debugger.log("[GameLoader] External map scan complete.");
      }

      /** Ensure external asset directory structure exists (create if missing) */
      public static function ensureExternalDirs() : void
      {
         var base:File = File.applicationStorageDirectory.resolvePath("BVN/assets");
         var dirs:Array = ["fighter", "map", "face", "bgm", "config"];
         for each(var d:String in dirs)
         {
            var dir:File = base.resolvePath(d);
            if(!dir.exists)
            {
               try { dir.createDirectory(); } catch(e:Error) {}
            }
         }
         Debugger.log("[GameLoader] External dirs ensured at:", base.nativePath);
      }

      /** Unified entry: scan all external assets on SD card (called at startup) */
      public static function scanExternalAssets() : void
      {
         ensureExternalDirs();
         scanExternalFighters();
         scanExternalMaps();
      }

      /** Load and merge external config XMLs from app-storage://BVN/assets/config/ */
      public static function loadExternalConfigs() : void
      {
         var basePath:String = ANEFileReader.resolveExternalPath("config") + "/";
         Debugger.log("[GameLoader] Loading external configs from:", basePath);
         if(!ANEFileReader.I.exists(basePath))
         {
            Debugger.log("[GameLoader] External config path not found, skipping.");
            return;
         }
         // Try to load and merge each config XML
         tryLoadExternalXML("fighter.xml", function(xml:XML):void {
            FighterModel.I.mergeByXML(xml);
            Debugger.log("[GameLoader] External fighter.xml merged.");
         });
         tryLoadExternalXML("assist.xml", function(xml:XML):void {
            AssisterModel.I.mergeByXML(xml);
            Debugger.log("[GameLoader] External assist.xml merged.");
         });
         tryLoadExternalXML("map.xml", function(xml:XML):void {
            MapModel.I.mergeByXML(xml);
            Debugger.log("[GameLoader] External map.xml merged.");
         });
         tryLoadExternalXML("mission.xml", function(xml:XML):void {
            MessionModel.I.mergeByXML(xml);
            Debugger.log("[GameLoader] External mission.xml merged.");
         });
      }

      /** Helper: load a single external XML and call back, silently skip if missing */
      private static function tryLoadExternalXML(fileName:String, back:Function) : void
      {
         var fullPath:String = basePath + fileName;
         if(!ANEFileReader.I.exists(fullPath))
         {
            return;
         }
         try
         {
            var ba:ByteArray = ANEFileReader.I.readBytes(fullPath);
            if(ba && ba.length > 0)
            {
               var xmlStr:String = ba.readUTFBytes(ba.length);
               var xml:XML = new XML(xmlStr);
               back(xml);
               Debugger.log("[GameLoader] External config loaded:", fileName);
            }
         }
         catch(e:Error)
         {
            Debugger.log("[GameLoader] Failed to parse external config:", fileName, e.message);
         }
      }

      /** Load fighter from absolute file path via ANEFileReader */
      public static function loadFighterFromPath(path:String, back:Function, fail:Function = null) : void
      {
         Debugger.log("[GameLoader.loadFighterFromPath]", path);
         var ba:ByteArray = ANEFileReader.I.readBytes(path);
         if(!ba)
         {
            Debugger.log("[GameLoader.loadFighterFromPath] FAILED: null bytes");
            if(fail != null) fail("File not found: " + path);
            return;
         }
         Debugger.log("[GameLoader.loadFighterFromPath] loaded", ba.length, "bytes");
         var loader:Loader = new Loader();
         loader.contentLoaderInfo.addEventListener("complete", function(e:*):void
         {
            var mc:MovieClip = loader.content as MovieClip;
            var fm:FighterMain = new FighterMain(mc);
            Debugger.log("[GameLoader.loadFighterFromPath] SWF parsed, FighterMain created");
            if(back != null) back(fm);
         });
         loader.loadBytes(ba);
         _loaderCache.push(loader);
      }
   }
}

