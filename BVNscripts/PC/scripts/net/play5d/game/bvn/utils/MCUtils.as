package net.play5d.game.bvn.utils
{
   import flash.display.DisplayObject;
   import flash.display.FrameLabel;
   import flash.display.MovieClip;
   import flash.filters.ColorMatrixFilter;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.data.GameData;
   import net.play5d.kyo.utils.KyoUtils;
   
   public class MCUtils
   {
      
      private static var _matrix:Array = null;
      
      private static var _filter:ColorMatrixFilter = null;
      
      public function MCUtils()
      {
         super();
      }
      
      public static function hasFrameLabel(param1:MovieClip, param2:String) : Boolean
      {
         var _loc4_:Array = param1.currentLabels;
         for each(var _loc3_ in _loc4_)
         {
            if(_loc3_.name == param2)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function renderFunc(param1:Vector.<Function>) : void
      {
         if(param1 == null || param1.length < 1)
         {
            return;
         }
         for each(var _loc2_ in param1)
         {
            _loc2_();
         }
      }
      
      public static function renderAllChildren(param1:MovieClip, param2:Boolean = true, param3:int = -1) : void
      {
         var _loc6_:int = 0;
         var _loc8_:MovieClip = null;
         var _loc4_:Number = NaN;
         var _loc5_:String = null;
         var _loc9_:int = 0;
         var _loc7_:String = null;
         if(param1 == null)
         {
            return;
         }
         _loc6_ = 0;
         for(; _loc6_ < param1.numChildren; _loc6_++)
         {
            try
            {
               _loc8_ = param1.getChildAt(_loc6_) as MovieClip;
               if(_loc8_ == null)
               {
                  continue;
               }
               _loc4_ = !GameConfig.IS_WIN_ACTIVATE ? 0 : GameData.I.config.soundVolume;
               KyoUtils.setMcVolume(_loc8_,_loc4_);
               if(param2)
               {
                  _loc5_ = _loc8_.name;
                  if(_loc5_ == "AImain" || _loc5_ == "bdmn" || _loc5_.indexOf("atm") != -1)
                  {
                     continue;
                  }
               }
               _loc9_ = _loc8_.totalFrames;
               if(_loc9_ == 1)
               {
                  continue;
               }
               _loc7_ = _loc8_.currentFrameLabel;
               if(_loc7_ != "stop")
               {
                  if(_loc8_.currentFrame == _loc9_)
                  {
                     _loc8_.gotoAndStop(1);
                  }
                  else
                  {
                     _loc8_.nextFrame();
                  }
                  if(param3 == -1)
                  {
                     renderAllChildren(_loc8_,false);
                  }
                  else if(param3 - 1 >= 0)
                  {
                     renderAllChildren(_loc8_,false,param3 - 1);
                  }
               }
            }
            catch(e:Error)
            {
            }
         }
      }
      
      public static function setHUE(param1:DisplayObject, param2:Number = 0) : void
      {
         var _loc3_:ColorMatrixFilter = null;
         if(param2 == 0)
         {
            param1.filters = null;
         }
         else
         {
            _loc3_ = createHueFilter(param2);
            param1.filters = [_loc3_];
         }
      }
      
      private static function createHueFilter(param1:Number) : ColorMatrixFilter
      {
         var _loc2_:Number = NaN;
         _loc2_ = 0.213;
         var _loc5_:Number = NaN;
         _loc5_ = 0.715;
         var _loc3_:Number = NaN;
         _loc3_ = 0.072;
         if(_filter != null && _matrix != null)
         {
            return _filter;
         }
         var _loc4_:Number = Math.cos(param1 * 3.141592653589793 / 180);
         var _loc6_:Number = Math.sin(param1 * 3.141592653589793 / 180);
         _matrix = [];
         _matrix.concat([0.213 + _loc4_ * (1 - 0.213) + _loc6_ * (0 - 0.213),0.715 + _loc4_ * (0 - 0.715) + _loc6_ * (0 - 0.715),0.072 + _loc4_ * (0 - 0.072) + _loc6_ * (1 - 0.072),0,0]);
         _matrix.concat([0.213 + _loc4_ * (0 - 0.213) + _loc6_ * 0.143,0.715 + _loc4_ * (1 - 0.715) + _loc6_ * 0.14,0.072 + _loc4_ * (0 - 0.072) + _loc6_ * -0.283,0,0]);
         _matrix.concat([0.213 + _loc4_ * (0 - 0.213) + _loc6_ * -0.787,0.715 + _loc4_ * (0 - 0.715) + _loc6_ * 0.715,0.072 + _loc4_ * (1 - 0.072) + _loc6_ * 0.072,0,0]);
         _matrix.concat([0,0,0,1,0]);
         _filter = new ColorMatrixFilter(_matrix);
         return _filter;
      }
   }
}

