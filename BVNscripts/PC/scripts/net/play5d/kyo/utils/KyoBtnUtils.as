package net.play5d.kyo.utils
{
   import com.greensock.TweenLite;
   import com.greensock.easing.Elastic;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.ColorTransform;
   import flash.utils.Dictionary;
   
   public class KyoBtnUtils
   {
      
      private static var _btnTween:TweenLite;
      
      private static var _curOnClick:Function;
      
      private static var _curOnClickParam:*;
      
      private static var _btnMap:Dictionary = new Dictionary();
      
      private static var _blackTransform:ColorTransform = new ColorTransform(1,1,1,1,-20,-20,-20);
      
      private static var _emptyTransform:ColorTransform = new ColorTransform();
      
      public function KyoBtnUtils()
      {
         super();
      }
      
      public static function initSampleBtn(param1:DisplayObject, param2:Function = null, param3:* = null) : void
      {
         _btnMap[param1] = {
            "x":param1.x,
            "y":param1.y,
            "scaleX":param1.scaleX,
            "scaleY":param1.scaleY,
            "click":param2,
            "clickParam":param3
         };
         if(param2 != null)
         {
            param1.addEventListener("click",sampleBtnHandler);
         }
      }
      
      public static function disposeSampleBtn(param1:DisplayObject) : void
      {
         if(param1 == null)
         {
            return;
         }
         _btnMap[param1] = null;
         param1.removeEventListener("click",sampleBtnHandler);
      }
      
      private static function sampleBtnHandler(param1:MouseEvent) : void
      {
         var _loc2_:Object = _btnMap[param1.currentTarget];
         if(_loc2_.click != null)
         {
            if(_loc2_.clickParam != null)
            {
               _loc2_.click(_loc2_.clickParam);
            }
            else
            {
               _loc2_.click();
            }
         }
      }
      
      public static function initBtn(param1:DisplayObject, param2:Function = null, param3:* = null, param4:int = 1) : void
      {
         if(param1 is Sprite)
         {
            (param1 as Sprite).mouseChildren = false;
            (param1 as Sprite).buttonMode = true;
         }
         _btnMap[param1] = {
            "x":param1.x,
            "y":param1.y,
            "scaleX":param1.scaleX,
            "scaleY":param1.scaleY,
            "effectType":param4,
            "click":param2,
            "clickParam":param3
         };
         param1.addEventListener("mouseDown",btnHandler);
         param1.addEventListener("mouseUp",btnHandler);
         if(param2 != null)
         {
            param1.addEventListener("click",btnHandler);
         }
      }
      
      public static function disposeBtn(param1:DisplayObject) : void
      {
         if(param1 == null)
         {
            return;
         }
         param1.removeEventListener("mouseDown",btnHandler);
         param1.removeEventListener("mouseUp",btnHandler);
         param1.removeEventListener("click",btnHandler);
         _btnMap[param1] = null;
      }
      
      private static function btnHandler(param1:MouseEvent) : void
      {
         var _loc2_:DisplayObject = param1.currentTarget as DisplayObject;
         var _loc3_:Object = _btnMap[_loc2_];
         switch(param1.type)
         {
            case "mouseDown":
               if(_btnTween && _btnTween.active)
               {
                  _btnTween.kill();
               }
               doBtnEffect(_loc2_,_loc3_,false);
               break;
            case "mouseUp":
               if(_btnTween && _btnTween.active)
               {
                  _btnTween.kill();
               }
               doBtnEffect(_loc2_,_loc3_,true);
               break;
            case "click":
               _curOnClick = _loc3_.click;
               _curOnClickParam = _loc3_.clickParam;
               if(_loc3_.effectType == 1)
               {
                  btnEffectFin();
               }
         }
      }
      
      private static function doBtnEffect(param1:DisplayObject, param2:Object, param3:Boolean = false) : void
      {
         switch(param2.effectType)
         {
            case 2:
               if(!param3)
               {
                  param1.y += 10;
                  param1.transform.colorTransform = _blackTransform;
               }
               else
               {
                  param1.transform.colorTransform = _emptyTransform;
                  _btnTween = TweenLite.to(param1,0.5,{
                     "y":param2.y,
                     "ease":Elastic.easeOut,
                     "onComplete":btnEffectFin
                  });
               }
               break;
            case 1:
               if(!param3)
               {
                  param1.transform.colorTransform = _blackTransform;
               }
               else
               {
                  param1.transform.colorTransform = _emptyTransform;
               }
         }
      }
      
      private static function btnEffectFin() : void
      {
         if(_curOnClick != null)
         {
            if(_curOnClickParam != null)
            {
               _curOnClick(_curOnClickParam);
            }
            else
            {
               _curOnClick();
            }
            _curOnClick = null;
            _curOnClickParam = null;
         }
      }
   }
}

