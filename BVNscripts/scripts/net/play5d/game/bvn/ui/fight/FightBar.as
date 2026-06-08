package net.play5d.game.bvn.ui.fight
{
   import flash.display.*;
   import flash.events.Event;
   import flash.geom.*;
   import net.play5d.game.bvn.data.GameRunFighterGroup;
   import net.play5d.game.bvn.fighter.FighterMain;
   import net.play5d.game.bvn.ui.*;
   
   public class FightBar
   {
      
      private var _ui:*;
      
      private var _faceGroup1:FightFaceGroup;
      
      private var _faceGroup2:FightFaceGroup;
      
      private var _hpBar1:FighterHpBar;
      
      private var _hpBar2:FighterHpBar;
      
      private var _energyBar1:EnergyBar;
      
      private var _energyBar2:EnergyBar;
      
      private var _score:FightScoreUI;
      
      private var _isFadIn:Boolean;
      
      private var _timerMc:FightTimeUI;
      
      private var _winUI1:WinUI;
      
      private var _winUI2:WinUI;
      
      private var _isRenderAnimate:Boolean = false;
      
      private var _bp:Bitmap;
      
      private var _parent:DisplayObjectContainer;
      
      private var _children:Vector.<DisplayObject>;
      
      private var _drawMatrix:Matrix;
      
      private var _empytBd:BitmapData;
      
      public function FightBar(param1:*)
      {
         super();
         this._ui = param1;
         this._faceGroup1 = new FightFaceGroup(this._ui.face1);
         this._faceGroup2 = new FightFaceGroup(this._ui.face2);
         this._faceGroup2.setDirect(-1);
         this._hpBar1 = new FighterHpBar(this._ui.bar1);
         this._hpBar2 = new FighterHpBar(this._ui.bar2);
         this._energyBar1 = new EnergyBar(this._ui.energy1);
         this._energyBar2 = new EnergyBar(this._ui.energy2);
         this._energyBar2.setDirect(-1);
         this._winUI1 = new WinUI(this._ui.win_p1,1);
         this._winUI2 = new WinUI(this._ui.win_p2,2);
         this._timerMc = new FightTimeUI(this._ui.timemc);
         if(GameUI.BITMAP_UI)
         {
            this.initBitmapUI();
         }
         else
         {
            this._ui.scoremc.visible = false;
         }
         this._ui.addEventListener("complete",this.uiPlayComplete);
      }
      
      public function get ui() : DisplayObject
      {
         return this._ui;
      }
      
      private function initBitmapUI() : void
      {
         this._ui.gotoAndStop("fadin_fin");
         this._parent = this._ui.parent;
         try
         {
            this._parent.removeChild(this._ui);
         }
         catch(e:Error)
         {
         }
         var _loc1_:Rectangle = this._ui.getBounds(this._ui);
         this._drawMatrix = new Matrix(1,0,0,1,-_loc1_.x,-_loc1_.y);
         this._children = new Vector.<DisplayObject>();
         this._bp = new Bitmap();
         this._bp.bitmapData = new BitmapData(this._ui.width,this._ui.height,true,0);
         this._bp.x = _loc1_.x;
         this._bp.y = _loc1_.y;
         this._empytBd = new BitmapData(this._ui.width,this._ui.height,true,0);
         this.addChildren(this._hpBar1.ui);
         this.addChildren(this._hpBar2.ui);
         this.addChildren(this._energyBar1.ui);
         this.addChildren(this._energyBar2.ui);
         this.addChildren(this._bp);
         if(Boolean(this._timerMc.timeUI))
         {
            this.addChildren(this._timerMc.timeUI);
         }
         this.addChildren(this._winUI1.ui);
         this.addChildren(this._winUI2.ui);
         this.addChildren(this._ui.scoremc);
         this.updateBitmap();
         this.setChildrenVisible(false);
      }
      
      private function setChildrenPosition(param1:DisplayObject) : void
      {
         var _loc2_:DisplayObjectContainer = param1.parent;
         while(Boolean(_loc2_) && _loc2_ != this._ui)
         {
            param1.x += _loc2_.x;
            param1.y += _loc2_.y;
            _loc2_ = _loc2_.parent;
         }
         param1.x += this._ui.x;
         param1.y += this._ui.y;
      }
      
      private function addChildren(param1:DisplayObject, param2:int = -1) : void
      {
         this.setChildrenPosition(param1);
         if(param2 == -1)
         {
            this._parent.addChild(param1);
         }
         else
         {
            this._parent.addChildAt(param1,param2);
         }
         this._children.push(param1);
      }
      
      private function setChildrenVisible(param1:Boolean) : void
      {
         var _loc2_:* = undefined;
         for each(_loc2_ in this._children)
         {
            _loc2_.visible = param1;
         }
      }
      
      public function destory() : void
      {
         var _loc1_:* = undefined;
         if(Boolean(this._ui))
         {
            this._ui.removeEventListener("complete",this.uiPlayComplete);
            this._ui.gotoAndStop("destory");
            this._ui = null;
         }
         if(Boolean(this._hpBar1))
         {
            this._hpBar1.destory();
            this._hpBar1 = null;
         }
         if(Boolean(this._hpBar2))
         {
            this._hpBar2.destory();
            this._hpBar2 = null;
         }
         if(Boolean(this._energyBar1))
         {
            this._energyBar1.destory();
            this._energyBar1 = null;
         }
         if(Boolean(this._energyBar2))
         {
            this._energyBar2.destory();
            this._energyBar2 = null;
         }
         if(GameUI.BITMAP_UI)
         {
            if(Boolean(this._bp))
            {
               this._bp.bitmapData.dispose();
               this._bp = null;
            }
            if(Boolean(this._empytBd))
            {
               this._empytBd.dispose();
               this._empytBd = null;
            }
            this._drawMatrix = null;
            for each(_loc1_ in this._children)
            {
               try
               {
                  this._parent.removeChild(_loc1_);
               }
               catch(e:Error)
               {
               }
            }
            this._children = null;
         }
      }
      
      private function uiPlayComplete(param1:Event) : void
      {
         if(this._isFadIn)
         {
            this._ui.visible = true;
         }
         else
         {
            this._ui.visible = false;
         }
      }
      
      public function initScore() : void
      {
         if(!GameUI.BITMAP_UI)
         {
            this._ui.scoremc.visible = true;
         }
         this._score = new FightScoreUI(this._ui.scoremc);
      }
      
      public function setScore(param1:int) : void
      {
         if(Boolean(this._score))
         {
            this._score.setScore(param1);
         }
      }
      
      public function showWin(param1:FighterMain, param2:int) : void
      {
         var _loc3_:WinUI = null;
         if(!param1)
         {
            return;
         }
         if(param2 < 0 || param2 > 2)
         {
            return;
         }
         switch(param1.team.id - 1)
         {
            case 0:
               _loc3_ = this._winUI1;
               break;
            case 1:
               _loc3_ = this._winUI2;
         }
         if(!_loc3_)
         {
            return;
         }
         _loc3_.show(param1.data,param2);
      }
      
      public function setFighter(param1:GameRunFighterGroup = null, param2:GameRunFighterGroup = null) : void
      {
         if(Boolean(param1))
         {
            this._faceGroup1.setFighter(param1);
            if(Boolean(param1.currentFighter))
            {
               this._hpBar1.setFighter(param1.currentFighter);
               this._energyBar1.setFighter(param1.currentFighter);
            }
         }
         if(Boolean(param2))
         {
            this._faceGroup2.setFighter(param2);
            if(Boolean(param2.currentFighter))
            {
               this._hpBar2.setFighter(param2.currentFighter);
               this._energyBar2.setFighter(param2.currentFighter);
            }
         }
         if(GameUI.BITMAP_UI)
         {
            this.updateBitmap();
         }
      }
      
      private function updateBitmap() : void
      {
         this._bp.bitmapData.copyPixels(this._empytBd,new Rectangle(0,0,this._empytBd.width,this._empytBd.height),new Point());
         this._bp.bitmapData.draw(this._ui,this._drawMatrix);
      }
      
      public function render() : void
      {
         this._hpBar1.render();
         this._hpBar2.render();
         this._energyBar1.render();
         this._energyBar2.render();
         this._timerMc.render();
      }
      
      public function fadIn(param1:Boolean) : void
      {
         if(this._isFadIn)
         {
            return;
         }
         this._isFadIn = true;
         if(GameUI.BITMAP_UI)
         {
            this.setChildrenVisible(true);
            return;
         }
         this._ui.visible = true;
         if(param1)
         {
            this._ui.gotoAndStop("fadin");
            this._isRenderAnimate = true;
         }
         else
         {
            this._ui.gotoAndStop("fadin_fin");
         }
      }
      
      public function fadOut(param1:Boolean) : void
      {
         if(!this._isFadIn)
         {
            return;
         }
         this._isFadIn = false;
         if(GameUI.BITMAP_UI)
         {
            this.setChildrenVisible(false);
            return;
         }
         if(param1)
         {
            this._ui.gotoAndStop("fadout");
            this._isRenderAnimate = true;
         }
         else
         {
            this._ui.visible = false;
         }
      }
      
      public function renderAnimate() : void
      {
         if(!this._isRenderAnimate)
         {
            return;
         }
         var _loc1_:String = this._ui.currentFrameLabel;
         if(_loc1_ == "fadin_fin" || _loc1_ == "fadout_fin")
         {
            this._isRenderAnimate = false;
            return;
         }
         this._ui.nextFrame();
      }
   }
}

