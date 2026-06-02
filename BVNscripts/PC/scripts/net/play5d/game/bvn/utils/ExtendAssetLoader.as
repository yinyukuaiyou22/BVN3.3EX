package net.play5d.game.bvn.utils
{
   import flash.system.ApplicationDomain;
   import net.play5d.game.bvn.interfaces.IAssetLoader;
   
   public class ExtendAssetLoader implements IAssetLoader
   {
      
      private var _extend:*;
      
      public function ExtendAssetLoader(param1:*)
      {
         super();
         if(!param1)
         {
            throw new Error("extend is null !");
         }
         _extend = param1;
      }
      
      public function loadXML(param1:String, param2:Function, param3:Function = null) : void
      {
         _extend.loadXML(param1,param2,param3);
      }
      
      public function loadJSON(param1:String, param2:Function, param3:Function = null) : void
      {
         _extend.loadJSON(param1,param2,param3);
      }
      
      public function loadSwf(param1:String, param2:Function, param3:Function = null, param4:Function = null, param5:ApplicationDomain = null) : void
      {
         _extend.loadSwf(param1,param2,param3,param4,param5);
      }
      
      public function loadSound(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         _extend.loadSound(param1,param2,param3,param4);
      }
      
      public function loadBitmap(param1:String, param2:Function, param3:Function = null, param4:Function = null) : void
      {
         _extend.loadBitmap(param1,param2,param3,param4);
      }
      
      public function dispose(param1:String) : void
      {
         _extend.dispose(param1);
      }
      
      public function needPreLoad() : Boolean
      {
         return _extend.needPreLoad();
      }
      
      public function loadPreLoad(param1:Function, param2:Function = null, param3:Function = null) : void
      {
         _extend.loadPreLoad(param1,param2,param3);
      }
   }
}

