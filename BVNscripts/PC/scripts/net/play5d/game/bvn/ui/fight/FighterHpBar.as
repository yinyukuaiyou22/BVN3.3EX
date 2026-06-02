package net.play5d.game.bvn.ui.fight
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.text.TextField;
   import net.play5d.game.bvn.GameConfig;
   import net.play5d.game.bvn.MainGame;
   import net.play5d.game.bvn.fighter.FighterActionState;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.fighter.events.FighterEvent;
   import net.play5d.game.bvn.fighter.events.FighterEventDispatcher;
   
   public class FighterHpBar
   {
      
      private var HIDE_DELAY:int = 30;
      
      private var _ui:MovieClip;
      
      private var _bar:DisplayObject;
      
      private var _redbar:DisplayObject;
      
      private var _fighter:FighterMain;
      
      private var _hprate:Number = 1;
      
      private var _redBarMoving:Boolean;
      
      private var _redBarMoveDelay:int;
      
      private var _justHurtFly:Boolean;
      
      private var _hpTxtMc:DisplayObject;
      
      private var _hpText:TextField;
      
      private var _add:Number = 0;
      
      private var _addTxtMc:MovieClip;
      
      private var _addText:TextField;
      
      private var _damage:Number = 0;
      
      private var _damageTxtMc:MovieClip;
      
      private var _damageText:TextField;
      
      private var _teamTxtMc:MovieClip;
      
      private var _teamText:TextField;
      
      private var _addShow:Boolean = false;
      
      private var _addHideDelay:int = 0;
      
      private var _damageShow:Boolean = false;
      
      private var _damageHideDelay:int = 0;
      
      private var _direct:int;
      
      public function FighterHpBar(param1:MovieClip)
      {
         super();
         _ui = param1;
         _bar = _ui.bar;
         _redbar = _ui.redbar;
         _hpTxtMc = _ui.hptxt;
         _hpText = (_hpTxtMc as MovieClip).mc.txt;
         _addTxtMc = _ui.getChildByName("addtxt") as MovieClip;
         _addText = _addTxtMc.mc.txt;
         _damageTxtMc = _ui.getChildByName("damagetxt") as MovieClip;
         _damageText = _damageTxtMc.mc.txt;
         _teamTxtMc = _ui.getChildByName("teamtxt") as MovieClip;
         _teamText = _teamTxtMc.mc.txt;
         hideAdd();
         hideDamge();
         FighterEventDispatcher.addEventListener("ADD_HP",onAddHp);
         FighterEventDispatcher.addEventListener("LOSE_HP",onLoseHp);
      }
      
      public function get ui() : DisplayObject
      {
         return _ui;
      }
      
      public function setDirect(param1:int) : void
      {
         _direct = param1;
         if(param1 < 0)
         {
            if(_hpTxtMc != null)
            {
               (_hpTxtMc as MovieClip).gotoAndStop(2);
               _hpText = (_hpTxtMc as MovieClip).mc.txt;
            }
            if(_addTxtMc != null)
            {
               _addTxtMc.gotoAndStop(2);
               _addText = _addTxtMc.mc.txt;
            }
            if(_damageTxtMc != null)
            {
               _damageTxtMc.gotoAndStop(2);
               _damageText = _damageTxtMc.mc.txt;
            }
            if(_teamTxtMc != null)
            {
               _teamTxtMc.gotoAndStop(2);
               _teamText = _teamTxtMc.mc.txt;
            }
            hideAdd();
            hideDamge();
         }
      }
      
      public function destory() : void
      {
         _fighter = null;
         _bar = null;
         _redbar = null;
         _hpTxtMc = null;
         _hpText = null;
         _addTxtMc = null;
         _addText = null;
         _damageTxtMc = null;
         _damageText = null;
         _teamTxtMc = null;
         _teamText = null;
         _ui = null;
         FighterEventDispatcher.removeEventListener("ADD_HP",onAddHp);
         FighterEventDispatcher.removeEventListener("LOSE_HP",onLoseHp);
      }
      
      public function setFighter(param1:FighterMain) : void
      {
         _fighter = param1;
      }
      
      public function render() : void
      {
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc2_:Number = _fighter.hpRate;
         if(_redBarMoving && _loc2_ != _hprate)
         {
            _redbar.scaleX = _hprate;
            _redBarMoving = false;
         }
         _hprate = _loc2_;
         var _loc1_:Number = _hprate - _bar.scaleX;
         var _loc5_:Number = _loc1_ < 0 ? 0.4 : 0.04;
         if(Math.abs(_loc1_) < 0.01)
         {
            _bar.scaleX = _hprate;
         }
         else
         {
            _bar.scaleX += _loc1_ * _loc5_;
         }
         switch(_fighter.actionState - 21)
         {
            case 0:
            case 1:
               _redBarMoveDelay = 100;
               break;
            case 2:
            case 3:
               if(_redBarMoveDelay > 0)
               {
                  if(!_justHurtFly)
                  {
                     _redBarMoveDelay = 1.5 * GameConfig.FPS_GAME;
                     _justHurtFly = true;
                     break;
                  }
                  if(_redBarMoveDelay > 0)
                  {
                     _redBarMoveDelay = _redBarMoveDelay - 1;
                  }
               }
               break;
            default:
               _redBarMoveDelay = 0;
               _justHurtFly = false;
         }
         if(_redBarMoveDelay <= 0)
         {
            _loc3_ = _hprate - _redbar.scaleX;
            _loc4_ = _loc3_ < 0 ? 0.1 : 0.02;
            if(Math.abs(_loc3_) < 0.01)
            {
               _redbar.scaleX = _hprate;
               _redBarMoving = false;
            }
            else
            {
               _redbar.scaleX += _loc3_ * _loc4_;
               _redBarMoving = true;
            }
         }
         if(_hpText != null)
         {
            _hpText.text = int(_fighter.hp).toString();
         }
         if(_addText && _addShow)
         {
            _addText.text = _add > 0 ? "+" + _add.toString() : "";
            _addHideDelay = _addHideDelay - 1;
            if(isHurting() || _addHideDelay <= 0)
            {
               hideAdd();
            }
         }
         if(_damageText && _damageShow)
         {
            _damageText.text = _damage > 0 ? "-" + _damage.toString() : "";
            _damageHideDelay = _damageHideDelay - 1;
            if(_damageHideDelay <= 0 && !FighterActionState.isHurting(_fighter.actionState))
            {
               hideDamge();
            }
         }
      }
      
      public function setTeamName(param1:String) : void
      {
         _teamText.text = param1;
      }
      
      private function showAdd() : void
      {
         _addTxtMc.visible = _addShow = true;
      }
      
      private function hideAdd() : void
      {
         _addText.text = "";
         _add = 0;
         _addTxtMc.visible = _addShow = false;
      }
      
      private function showDamage() : void
      {
         _damageTxtMc.visible = _damageShow = true;
      }
      
      private function hideDamge() : void
      {
         _damageText.text = "";
         _damage = 0;
         _damageTxtMc.visible = _damageShow = false;
      }
      
      private function onAddHp(param1:FighterEvent) : void
      {
         HIDE_DELAY = MainGame.I.getFPS();
         var _loc2_:FighterMain = param1.fighter as FighterMain;
         if(_loc2_ != null && _loc2_ != _fighter)
         {
            return;
         }
         var _loc3_:Number = param1.params as Number;
         _addHideDelay = HIDE_DELAY;
         _add += _loc3_;
         if(_add > 0)
         {
            showAdd();
         }
      }
      
      private function onLoseHp(param1:FighterEvent) : void
      {
         HIDE_DELAY = MainGame.I.getFPS();
         var _loc3_:FighterMain = param1.fighter as FighterMain;
         if(_loc3_ != null && _loc3_ != _fighter)
         {
            return;
         }
         var _loc2_:Number = param1.params as Number;
         _damageHideDelay = HIDE_DELAY;
         _damage += _loc2_;
         if(_damage > 0)
         {
            showDamage();
         }
      }
      
      private function isHurting() : Boolean
      {
         return FighterActionState.isHurting(_fighter.actionState) && _damage > 0;
      }
   }
}

