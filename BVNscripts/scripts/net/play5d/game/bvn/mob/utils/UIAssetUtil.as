package net.play5d.game.bvn.mob.utils
{
   import flash.display.BitmapData;
   import flash.utils.*;
   
   public class UIAssetUtil
   {
      
      private static var _i:UIAssetUtil;
      
      public var win_ui:Class = EmbeddedAssets.mob_ui_swf_data;
      
      private var _swfPool:Dictionary;
      
      private var _initBack:Function;
      
      private var _inited:Boolean;
      
      private var _initing:Boolean;
      
      public function UIAssetUtil()
      {
         super();
      }
      
      public static function get I() : UIAssetUtil
      {
         if(!_i)
         {
            _i = new UIAssetUtil();
         }
         return _i;
      }
      
      public function initalize(param1:Function = null) : void
      {
         var _loc7_:* = undefined;
         var _loc2_:String = null;
         var _loc3_:Class = null;
         var _loc4_:InsSwf = null;
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
         var _loc5_:XML = describeType(this);
         var _loc6_:Object = {};
         for each(_loc7_ in _loc5_.variable)
         {
            _loc2_ = _loc7_.@name;
            _loc3_ = this[_loc2_];
            _loc4_ = new InsSwf(_loc3_);
            _loc4_.ready = this.swfReadyBack;
            this._swfPool[_loc3_] = _loc4_;
         }
      }
      
      private function swfReadyBack(param1:InsSwf) : void
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in this._swfPool)
         {
            if(!_loc2_.isReady)
            {
               return;
            }
         }
         this.finish();
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
      
      public function createDisplayObject(param1:String) : *
      {
         var _loc2_:Class = this.getItemClass(param1);
         if(Boolean(_loc2_))
         {
            return new _loc2_();
         }
      }
      
      public function createBitmapData(param1:String, param2:int, param3:int) : BitmapData
      {
         var _loc4_:Class = this.getItemClass(param1);
         if(!_loc4_)
         {
            return null;
         }
         return new _loc4_(param2,param3);
      }
      
      public function getItemClass(param1:String) : Class
      {
         if(!this._swfPool)
         {
            throw new Error("未进行初始化！");
         }
         var _loc2_:InsSwf = this._swfPool[this.win_ui];
         if(!_loc2_)
         {
            throw new Error("swf is undefined!");
         }
         return _loc2_.getClass(param1);
      }
   }
}

import flash.display.*;
import flash.events.Event;
import flash.system.*;
import flash.utils.*;

class InsSwf
{
   
   private var _swf:*;
   
   private var _domain:ApplicationDomain;
   
   public var isReady:Boolean;
   
   public var ready:Function;
   
   public function InsSwf(param1:Class)
   {
      super();
      this._swf = new param1();
      var _loc2_:ByteArray = this._swf as ByteArray;
      if(!_loc2_ || _loc2_.length == 0)
      {
         throw new Error("未发现swf数据!");
      }
      var _loc3_:Loader = new Loader();
      _loc3_.contentLoaderInfo.addEventListener("complete",this.loadComplete,false,0,true);
      var _loc4_:LoaderContext = new LoaderContext(false,ApplicationDomain.currentDomain);
      _loc4_.allowCodeImport = true;
      _loc3_.loadBytes(_loc2_,_loc4_);
   }
   
   public function getClass(param1:String) : Class
   {
      return this._domain.getDefinition(param1) as Class;
   }
   
   private function loadComplete(param1:Event) : void
   {
      var _loc2_:LoaderInfo = param1.currentTarget as LoaderInfo;
      this._domain = _loc2_.applicationDomain;
      this.isReady = true;
      if(this.ready != null)
      {
         this.ready(this);
         this.ready = null;
      }
   }
}
