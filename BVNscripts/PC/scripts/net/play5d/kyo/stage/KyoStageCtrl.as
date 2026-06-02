package net.play5d.kyo.stage
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.utils.getQualifiedClassName;
   import flash.utils.setTimeout;
   import net.play5d.kyo.stage.effect.IStageFadEffect;
   import net.play5d.kyo.stage.events.KyoStageEvent;
   
   public class KyoStageCtrl extends EventDispatcher
   {
      
      private var _mainStage:Sprite;
      
      private var _curStage:Istage;
      
      public var changeStateMouseGap:int = 0;
      
      private var _layers:Array = [];
      
      public function KyoStageCtrl(param1:Sprite)
      {
         super();
         _mainStage = param1;
      }
      
      public function get currentStage() : Istage
      {
         return _curStage;
      }
      
      public function goStage(param1:Istage, param2:Boolean = false, param3:Boolean = false) : Boolean
      {
         var classname:String;
         var classname2:String;
         var stg:Istage = param1;
         var sameChange:Boolean = param2;
         var buildAfterDestory:Boolean = param3;
         var detoryComplete:* = function():void
         {
            if(_curStage.display != null)
            {
               try
               {
                  _mainStage.removeChild(_curStage.display);
               }
               catch(e:Error)
               {
                  trace("KyoStageCtrl: goStage:",e);
               }
            }
            _curStage = null;
            newStage();
         };
         var newStage:* = function():void
         {
            if(changeStateMouseGap > 0)
            {
               stageMouseChildren = false;
               setTimeout(function():void
               {
                  stageMouseChildren = true;
               },changeStateMouseGap);
            }
            _curStage = stg;
            _curStage.build();
            _mainStage.addChild(_curStage.display);
            _curStage.afterBuild();
         };
         if(!sameChange)
         {
            classname = getQualifiedClassName(stg);
            classname2 = getQualifiedClassName(_curStage);
            if(classname == classname2)
            {
               return false;
            }
         }
         if(_curStage)
         {
            if(buildAfterDestory)
            {
               _curStage.destory(detoryComplete);
            }
            else
            {
               _curStage.destory();
               detoryComplete();
            }
         }
         else
         {
            newStage();
         }
         dispatchEvent(new KyoStageEvent("CHANGE_STATE",stg));
         return true;
      }
      
      public function addLayer(param1:Istage, param2:Number = 0, param3:Number = 0, param4:Boolean = false, param5:IStageFadEffect = null, param6:Function = null) : void
      {
         var sw:Number;
         var sh:Number;
         var dw:Number;
         var dh:Number;
         var layer:Istage = param1;
         var x:Number = param2;
         var y:Number = param3;
         var removeElse:Boolean = param4;
         var effect:IStageFadEffect = param5;
         var addBack:Function = param6;
         var effectBack:* = function():void
         {
            layer.afterBuild();
            if(addBack != null)
            {
               addBack();
            }
         };
         if(removeElse)
         {
            removeAllLayer();
         }
         layer.build();
         sw = _mainStage.stage.stageWidth;
         sh = _mainStage.stage.stageHeight;
         dw = layer.display.width * _mainStage.scaleX;
         dh = layer.display.height * _mainStage.scaleY;
         if(isNaN(x))
         {
            layer.display.x = (sw - dw) / 2;
         }
         else
         {
            layer.display.x = x;
         }
         if(isNaN(y))
         {
            layer.display.y = (sh - dh) / 2;
         }
         else
         {
            layer.display.y = y;
         }
         _mainStage.addChild(layer.display);
         if(effect)
         {
            effect.fadIn(layer,effectBack);
         }
         else
         {
            effectBack();
         }
         _layers.push(layer);
      }
      
      public function hasLayer(param1:Object) : Boolean
      {
         var _loc2_:Class = null;
         for each(var _loc3_ in _layers)
         {
            if(param1 is Istage)
            {
               if(_loc3_ == param1)
               {
                  return true;
               }
            }
            if(param1 is Class)
            {
               _loc2_ = param1 as Class;
               if(_loc3_ is _loc2_)
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      public function get noneLayer() : Boolean
      {
         return _layers.length == 0;
      }
      
      public function removeLayer(param1:Istage, param2:IStageFadEffect = null, param3:Function = null) : void
      {
         var layer:Istage = param1;
         var effect:IStageFadEffect = param2;
         var removeBack:Function = param3;
         var effectFin:* = function():void
         {
            try
            {
               _mainStage.removeChild(layer.display);
               layer.destory();
            }
            catch(e:Error)
            {
               trace("KyoStageCtrl: removeLayer:",e);
            }
            var _loc1_:int = _layers.indexOf(layer);
            if(_loc1_ != -1)
            {
               _layers.splice(_loc1_,1);
            }
            if(removeBack != null)
            {
               removeBack();
            }
         };
         if(effect)
         {
            effect.fadOut(layer,effectFin);
         }
         else
         {
            effectFin();
         }
      }
      
      public function removeAllLayer() : void
      {
         for each(var _loc1_ in _layers)
         {
            removeLayer(_loc1_);
         }
         _layers = [];
      }
      
      public function clean(param1:Boolean = true) : void
      {
         if(param1)
         {
            removeAllLayer();
         }
         if(_curStage)
         {
            _curStage.destory();
            _mainStage.removeChild(_curStage.display);
            _curStage = null;
         }
      }
      
      private function set stageMouseChildren(param1:Boolean) : void
      {
         if(_mainStage.stage)
         {
            _mainStage.stage.mouseChildren = param1;
         }
      }
   }
}

