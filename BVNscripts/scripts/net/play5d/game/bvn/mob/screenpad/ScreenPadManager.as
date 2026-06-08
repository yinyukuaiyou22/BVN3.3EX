package net.play5d.game.bvn.mob.screenpad
{
   import flash.display.DisplayObject;
   import flash.display.Stage;
   import flash.events.TouchEvent;
   import flash.geom.*;
   import flash.ui.*;
   import flash.utils.*;
   import net.play5d.game.bvn.*;
   import net.play5d.game.bvn.ctrl.*;
   import net.play5d.game.bvn.events.*;
   import net.play5d.game.bvn.mob.ctrls.*;
   import net.play5d.game.bvn.mob.input.*;
   import net.play5d.game.bvn.state.*;
   import net.play5d.kyo.stage.events.KyoStageEvent;
   
   public class ScreenPadManager
   {
      
      private static var _game:ScreenPadGame;
      
      private static var _selectFighter:ScreenPadSelectFighter;
      
      private static var _stage:Stage;
      
      private static var _curMode:int = -1;
      
      private static var _listened:Dictionary = new Dictionary();
      
      public function ScreenPadManager()
      {
         super();
      }
      
      public static function initlize(param1:Stage) : void
      {
         ScreenPadUtils.scale = launch.FULL_SCREEN_SIZE.y / GameConfig.GAME_SIZE.y;
         _stage = param1;
         GameEvent.addEventListener("PAUSE_GAME",pauseResumeHandler);
         GameEvent.addEventListener("RESUME_GAME",pauseResumeHandler);
         _game = new ScreenPadGame(param1);
         _game.inputers = new Vector.<ScreenPadInput>();
         _game.inputers.push(InputManager.I.screen_p1);
         _game.menuInputer = InputManager.I.screen_menu;
         _selectFighter = new ScreenPadSelectFighter(param1);
         _selectFighter.inputers = new Vector.<ScreenPadInput>();
         _selectFighter.inputers.push(InputManager.I.screen_menu,InputManager.I.screen_p1);
         Multitouch.inputMode = "touchPoint";
      }
      
      private static function pauseResumeHandler(param1:GameEvent) : void
      {
         if(param1.type == "PAUSE_GAME")
         {
            _game.onPause();
         }
         if(param1.type == "RESUME_GAME")
         {
            _game.onResume();
         }
      }
      
      public static function reBuild() : void
      {
         var _loc1_:int = int(_curMode);
         _curMode = 0;
         _game.reBuild();
         _selectFighter.reBuild();
         switch(_loc1_ - 1)
         {
            case 0:
               menuMode();
               break;
            case 1:
               gameMode();
               break;
            case 2:
               selectFighterMode();
         }
      }
      
      public static function listen() : void
      {
         MainGame.stageCtrl.addEventListener("CHANGE_STATE",stateChangeHandler);
         _stage.addEventListener("touchBegin",touchHandler);
         _stage.addEventListener("touchMove",touchHandler);
         _stage.addEventListener("touchEnd",touchHandler);
         GameEvent.addEventListener("PAUSE_GAME",onPauseGame);
         GameEvent.addEventListener("RESUME_GAME",onResumeGame);
         GameRender.add(render);
      }
      
      private static function stateChangeHandler(param1:KyoStageEvent) : void
      {
         if(param1.stage is GameState)
         {
            gameMode();
         }
         else if(param1.stage is SelectFighterStage)
         {
            selectFighterMode();
         }
         else
         {
            menuMode();
         }
      }
      
      private static function hideALL() : void
      {
         _curMode = 0;
         _game.hide();
         _selectFighter.hide();
      }
      
      private static function menuMode() : void
      {
         if(_curMode == 1)
         {
            return;
         }
         _curMode = 1;
         if(Boolean(_stage))
         {
            _stage.mouseChildren = true;
         }
         _game.hide();
         _selectFighter.hide();
      }
      
      private static function gameMode() : void
      {
         if(_curMode == 2)
         {
            return;
         }
         if(Boolean(_stage))
         {
            _stage.mouseChildren = false;
         }
         _curMode = 2;
         _selectFighter.hide();
         _game.show();
      }
      
      private static function selectFighterMode() : void
      {
         if(_curMode == 3)
         {
            return;
         }
         if(Boolean(_stage))
         {
            _stage.mouseChildren = true;
         }
         _curMode = 3;
         _game.hide();
         _selectFighter.show();
      }
      
      private static function touchHandler(param1:TouchEvent) : void
      {
         if(MobileCtrler.I.isAdPause)
         {
            MobileCtrler.I.adResume();
            return;
         }
         switch(_curMode - 1)
         {
            case 0:
               break;
            case 1:
               _game.touchHandler(param1);
               break;
            case 2:
               _selectFighter.touchHandler(param1);
         }
         listenTouchHandler(param1);
      }
      
      private static function onPauseGame(param1:GameEvent) : void
      {
         menuMode();
      }
      
      private static function onResumeGame(param1:GameEvent) : void
      {
         gameMode();
      }
      
      private static function render() : void
      {
         if(Boolean(_game) && Boolean(_game.isShowing))
         {
            _game.render();
         }
      }
      
      public static function testMode() : void
      {
         gameMode();
      }
      
      public static function addTouchListener(param1:DisplayObject, param2:Function) : void
      {
         _listened[param1] = param2;
      }
      
      public static function removeTouchListener(param1:DisplayObject) : void
      {
         delete _listened[param1];
      }
      
      public static function clearTouchListener() : void
      {
         _listened = new Dictionary();
      }
      
      private static function listenTouchHandler(param1:TouchEvent) : void
      {
         var _loc5_:* = undefined;
         var _loc2_:Point = null;
         var _loc3_:Rectangle = null;
         var _loc4_:String = param1.type;
         if("touchEnd" === _loc4_)
         {
            _loc2_ = new Point(param1.stageX,param1.stageY);
            for(_loc5_ in _listened)
            {
               if(Boolean(_loc5_.visible))
               {
                  if(!_loc5_ || !_listened[_loc5_])
                  {
                     delete _listened[_loc5_];
                  }
                  else
                  {
                     _loc3_ = _loc5_.getBounds(_stage);
                     if(_loc3_.containsPoint(_loc2_))
                     {
                        _listened[_loc5_](_loc5_);
                     }
                  }
               }
            }
         }
      }
   }
}

