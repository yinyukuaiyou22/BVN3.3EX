package net.play5d.game.bvn.mob.screenpad
{
   import flash.display.Stage;
   import flash.events.TouchEvent;
   import net.play5d.game.bvn.mob.input.ScreenPadInput;
   
   public class ScreenPadSelectFighter
   {
      
      public var inputers:Vector.<ScreenPadInput>;
      
      private var _stage:Stage;
      
      private var _listened:Boolean;
      
      private var _downCache:Object = {};
      
      private var _btns:Vector.<ScreenPadBtnBase>;
      
      private var W:Number;
      
      private var H:Number;
      
      public function ScreenPadSelectFighter(param1:Stage)
      {
         super();
         this._stage = param1;
         this.build();
      }
      
      public function reBuild() : void
      {
         var _loc1_:int = 0;
         try
         {
            while(_loc1_ < this._btns.length)
            {
               this._stage.removeChild(this._btns[_loc1_].display);
               this._btns[_loc1_].onRemove();
               _loc1_++;
            }
         }
         catch(e:Error)
         {
         }
         this.build();
      }
      
      private function build() : void
      {
         this.W = launch.FULL_SCREEN_SIZE.x;
         this.H = launch.FULL_SCREEN_SIZE.y;
         this._btns = new Vector.<ScreenPadBtnBase>();
         this.addBtn("back",ScreenPadAsset.cancel,0,0,0,0,0);
         this.initBtns();
      }
      
      private function addBtn(param1:String, param2:Class, param3:Number = 0, param4:Number = 0, param5:Number = 0, param6:Number = 0, param7:Number = 0) : ScreenPadBtn
      {
         var _loc8_:ScreenPadBtn = ScreenPadUtils.getButton(param2);
         _loc8_.moveAble = false;
         _loc8_.keyId = param1;
         _loc8_.areaAdd = ScreenPadUtils.cm2pixel(param7);
         if(param3 != 0)
         {
            _loc8_.display.x = ScreenPadUtils.cm2pixel(param3);
         }
         if(param4 != 0)
         {
            _loc8_.display.y = ScreenPadUtils.cm2pixel(param4);
         }
         if(param5 != 0)
         {
            _loc8_.display.x = this.W - _loc8_.display.width - ScreenPadUtils.cm2pixel(param5);
         }
         if(param6 != 0)
         {
            _loc8_.display.y = this.H - _loc8_.display.height - ScreenPadUtils.cm2pixel(param6);
         }
         this._btns.push(_loc8_);
         return _loc8_;
      }
      
      private function initBtns() : void
      {
         var _loc1_:* = undefined;
         for each(_loc1_ in this._btns)
         {
            _loc1_.initArea();
         }
      }
      
      public function show() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this._btns.length)
         {
            this._stage.addChild(this._btns[_loc1_].display);
            this._btns[_loc1_].onAdd();
            _loc1_++;
         }
      }
      
      public function hide() : void
      {
         var _loc2_:* = undefined;
         var _loc1_:int = 0;
         try
         {
            while(_loc1_ < this._btns.length)
            {
               this._stage.removeChild(this._btns[_loc1_].display);
               this._btns[_loc1_].onRemove();
               _loc1_++;
            }
         }
         catch(e:Error)
         {
         }
         for each(_loc2_ in this.inputers)
         {
            _loc2_.clear();
         }
      }
      
      public function touchHandler(param1:TouchEvent) : void
      {
         var _loc7_:String = null;
         var _loc2_:ScreenPadBtnBase = null;
         var _loc3_:int = 0;
         var _loc4_:int = param1.touchPointID;
         var _loc5_:Number = param1.stageX;
         var _loc6_:Number = param1.stageY;
         if(param1.type == "touchEnd")
         {
            if(Boolean(this._downCache[_loc4_]))
            {
               _loc2_ = this._downCache[_loc4_].btn;
               _loc2_.touchUP();
               this.setInputerDown(this._downCache[_loc4_].key,false);
               delete this._downCache[_loc4_];
            }
            return;
         }
         while(_loc3_ < this._btns.length)
         {
            _loc2_ = this._btns[_loc3_];
            _loc7_ = param1.type;
            if("touchBegin" === _loc7_)
            {
               if(_loc2_.checkArea(_loc5_,_loc6_))
               {
                  _loc2_.touchDown(_loc5_,_loc6_);
                  this._downCache[_loc4_] = {
                     "btn":_loc2_,
                     "key":_loc2_.keyId
                  };
                  this.setInputerDown(_loc2_.keyId,true);
               }
            }
            _loc3_++;
         }
      }
      
      private function setInputerDown(param1:Object, param2:Boolean) : void
      {
         var _loc3_:ScreenPadInput = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Array = null;
         var _loc7_:String = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         if(param1 == null)
         {
            return;
         }
         _loc9_ = int(this.inputers.length);
         _loc5_ = 0;
         while(_loc5_ < _loc9_)
         {
            _loc3_ = this.inputers[_loc5_];
            if(param1 is String)
            {
               _loc3_.setDown(param1 as String,param2);
            }
            if(param1 is Array)
            {
               _loc6_ = param1 as Array;
               _loc8_ = int(_loc6_.length);
               _loc4_ = 0;
               while(_loc4_ < _loc8_)
               {
                  _loc7_ = _loc6_[_loc4_];
                  _loc3_.setDown(_loc7_,param2);
                  _loc4_++;
               }
            }
            _loc5_++;
         }
      }
   }
}

