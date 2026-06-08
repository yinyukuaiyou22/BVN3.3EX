package net.play5d.game.bvn.ui.select
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.geom.*;
   import flash.utils.*;
   import net.play5d.game.bvn.data.*;
   import net.play5d.game.bvn.utils.*;
   
   public class SelectIndexUI extends Sprite
   {
      
      public static var SHOW_MODE:int = 0;
      
      public var onFinish:Function;
      
      private var _p1Group:SelectIndexUIGroup;
      
      private var _p2Group:SelectIndexUIGroup;
      
      public function SelectIndexUI()
      {
         super();
         this.buildItems();
         this.initSelect();
      }
      
      public function getP1Order() : Array
      {
         return this._p1Group.getOrder();
      }
      
      public function getP2Order() : Array
      {
         return this._p2Group.getOrder();
      }
      
      public function setP1Order(param1:Array) : void
      {
         this._p1Group.setOrder(param1);
      }
      
      public function setP2Order(param1:Array) : void
      {
         this._p2Group.setOrder(param1);
      }
      
      public function p1Finish() : Boolean
      {
         return this._p1Group.isFinish;
      }
      
      public function p2Finish() : Boolean
      {
         return this._p2Group.isFinish;
      }
      
      public function isFinish() : Boolean
      {
         return Boolean(this._p1Group.isFinish) && Boolean(this._p2Group.isFinish);
      }
      
      public function destory() : void
      {
         if(Boolean(this._p1Group))
         {
            this._p1Group.destory();
            this._p1Group = null;
         }
         if(Boolean(this._p2Group))
         {
            this._p2Group.destory();
            this._p2Group = null;
         }
         this.onFinish = null;
      }
      
      private function buildItems() : void
      {
         this._p1Group = new SelectIndexUIGroup();
         this._p2Group = new SelectIndexUIGroup();
         if(SHOW_MODE == 1)
         {
            this._p1Group.x = 35;
            this._p2Group.x = 515;
            this._p1Group.setFighterScale(0.85);
            this._p2Group.setFighterScale(0.85);
            this._p1Group.fighterOffset.x = -5;
            this._p2Group.fighterOffset.x = 40;
            this._p1Group.fzx = -5;
            this._p2Group.fzx = 0;
         }
         else
         {
            this._p1Group.x = 70;
            this._p2Group.x = 480;
            this._p1Group.fzx = -30;
            this._p2Group.fzx = 45;
         }
         this._p1Group.y = 85;
         this._p2Group.y = 85;
         var _loc1_:Class = ResUtils.I.getItemClass(ResUtils.I.select,"selected_item_p1_mc");
         var _loc2_:Class = ResUtils.I.getItemClass(ResUtils.I.select,"selected_item_p2_mc");
         this._p1Group.build(_loc1_,GameData.I.p1Select);
         this._p2Group.build(_loc2_,GameData.I.p2Select);
         addChild(this._p1Group);
         addChild(this._p2Group);
      }
      
      private function initSelect() : void
      {
         switch(int(GameMode.currentMode) - 10)
         {
            case 0:
               this.initP1Group();
               this.initP2Group(null,true);
               break;
            case 1:
               this.initP1Group();
               this.initP2Group("P2",false);
               break;
            case 3:
            case 2:
               this.initP1Group(this.afterInitP1Group);
               break;
            default:
               this._p1Group.isFinish = true;
               this._p2Group.isFinish = true;
         }
      }
      
      private function afterInitP1Group() : void
      {
         this.initP2Group("P1",false);
         this.onSelectFinish();
      }
      
      private function initP1Group(finishBack:Function = null) : void
      {
         GameLoger.log("init p1");
         var arrow:DisplayObject = ResUtils.I.createDisplayObject(ResUtils.I.select,"select_arrow_mc_1");
         this._p1Group.initArrow(arrow,new Point(-10,30));
         this._p1Group.setKey("P1");
         if(finishBack != null)
         {
            this._p1Group.onFinish = finishBack;
         }
         else
         {
            this._p1Group.onFinish = this.onSelectFinish;
         }
      }
      
      private function initP2Group(param1:String, param2:Boolean) : void
      {
         GameLoger.log("init p2");
         var _loc3_:DisplayObject = ResUtils.I.createDisplayObject(ResUtils.I.select,"select_arrow_mc_2");
         this._p2Group.initArrow(_loc3_,new Point(260,30));
         if(param2)
         {
            this._p2Group.autoSelect();
         }
         else
         {
            this._p2Group.setKey(param1);
         }
         this._p2Group.onFinish = this.onSelectFinish;
      }
      
      private function onSelectFinish() : void
      {
         if(Boolean(this._p1Group.isFinish) && Boolean(this._p2Group.isFinish))
         {
            if(this.onFinish != null)
            {
               setTimeout(this.delayCall,200);
            }
            return;
         }
      }
      
      private function delayCall() : void
      {
         if(this.onFinish == null)
         {
            return;
         }
         this.onFinish();
         this.onFinish = null;
      }
   }
}

