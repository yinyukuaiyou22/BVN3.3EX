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
         _stage = param1;
         build();
      }
      
      public function reBuild() : void
      {
         var _loc1_:int = 0;
         try
         {
            while(_loc1_ < _btns.length)
            {
               _stage.removeChild(_btns[_loc1_].display);
               _btns[_loc1_].onRemove();
               _loc1_++;
            }
         }
         catch(e:Error)
         {
         }
         build();
      }
      
      private function build() : void
      {
         W = launch.FULL_SCREEN_SIZE.x;
         H = launch.FULL_SCREEN_SIZE.y;
         _btns = new Vector.<ScreenPadBtnBase>();
         addBtn("back",ScreenPadAsset.cancel,0,0,0,0,0);
         initBtns();
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
            _loc8_.display.x = W - _loc8_.display.width - ScreenPadUtils.cm2pixel(param5);
         }
         if(param6 != 0)
         {
            _loc8_.display.y = H - _loc8_.display.height - ScreenPadUtils.cm2pixel(param6);
         }
         _btns.push(_loc8_);
         return _loc8_;
      }
      
      private function initBtns() : void
      {
         for each(var _loc1_ in _btns)
         {
            _loc1_.initArea();
         }
      }
      
      public function show() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < _btns.length)
         {
            _stage.addChild(_btns[_loc1_].display);
            _btns[_loc1_].onAdd();
            _loc1_++;
         }
      }
      
      public function hide() : void
      {
         var _loc2_:int = 0;
         try
         {
            while(_loc2_ < _btns.length)
            {
               _stage.removeChild(_btns[_loc2_].display);
               _btns[_loc2_].onRemove();
               _loc2_++;
            }
         }
         catch(e:Error)
         {
         }
         for each(var _loc1_ in inputers)
         {
            _loc1_.clear();
         }
      }
      
      public function touchHandler(param1:TouchEvent) : void
      {
         var _loc3_:ScreenPadBtnBase = null;
         var _loc6_:int = 0;
         var _loc2_:int = param1.touchPointID;
         var _loc5_:Number = param1.stageX;
         var _loc4_:Number = param1.stageY;
         if(param1.type == "touchEnd")
         {
            if(_downCache[_loc2_])
            {
               _loc3_ = _downCache[_loc2_].btn;
               _loc3_.touchUP();
               setInputerDown(_downCache[_loc2_].key,false);
               delete _downCache[_loc2_];
            }
            return;
         }
         while(_loc6_ < _btns.length)
         {
            _loc3_ = _btns[_loc6_];
            var _loc7_:String = param1.type;
            if("touchBegin" === _loc7_)
            {
               if(_loc3_.checkArea(_loc5_,_loc4_))
               {
                  _loc3_.touchDown(_loc5_,_loc4_);
                  _downCache[_loc2_] = {
                     "btn":_loc3_,
                     "key":_loc3_.keyId
                  };
                  setInputerDown(_loc3_.keyId,true);
               }
            }
            _loc6_++;
         }
      }
      
      private function setInputerDown(param1:Object, param2:Boolean) : void
      {
         var _loc3_:ScreenPadInput = null;
         var _loc6_:int = 0;
         var _loc9_:int = 0;
         var _loc4_:Array = null;
         var _loc8_:String = null;
         var _loc7_:int = 0;
         var _loc5_:int = 0;
         if(param1 == null)
         {
            return;
         }
         _loc5_ = int(inputers.length);
         _loc9_ = 0;
         while(_loc9_ < _loc5_)
         {
            _loc3_ = inputers[_loc9_];
            if(param1 is String)
            {
               _loc3_.setDown(param1 as String,param2);
            }
            if(param1 is Array)
            {
               _loc4_ = param1 as Array;
               _loc7_ = int(_loc4_.length);
               _loc6_ = 0;
               while(_loc6_ < _loc7_)
               {
                  _loc8_ = _loc4_[_loc6_];
                  _loc3_.setDown(_loc8_,param2);
                  _loc6_++;
               }
            }
            _loc9_++;
         }
      }
   }
}

